#!/usr/bin/env Rscript
# What a gene's neighbours say about whether it was really lost.
#
# 09-cooccurrence.R found that 43 of 718 curated contexts are tight enough that
# filling a gap in them would be defensible at 80% completeness, and that 17 of
# those 43 belong to the flagellar apparatus. That concentration is the warning,
# not the result. The posterior it used assumes independent dropout:
#
#     P(present | not observed, context) = d*pi / (d*pi + (1 - pi)),  d = 1 - q
#
# and d = 1 - q is only right if losing one gene tells you nothing about whether
# its neighbour was lost. Genes are not lost that way. A recovered genome is
# missing contigs, and a contig is a run of adjacent genes, so the flagellar
# operon is present or absent almost as a unit. Conditional on seeing the rest
# of the context, the region was recovered -- which makes the *conditional*
# dropout rate of the one missing member far below the genome-wide 1 - q, and
# the posterior correspondingly lower. The independent model over-licenses
# hardest exactly where it fires most.
#
# So the assumption is replaced by a measurement. The quantity is
#
#     d_cond = P(target unobserved | target truly present, context still observed)
#
# estimated by dropping contiguous runs of genes from complete reference genomes
# whose gene coordinates are known, and re-reading the hierarchy on what
# survives. Setting the mean run length to one gene reproduces the unlinked
# model exactly, so the two are measured on the same genomes, the same contexts
# and the same replicates, and the ratio between them is the whole answer.
#
# Then every posterior from 09 is recomputed with the measured d_cond in place
# of 1 - q, and the survivors are recounted. That is the deliverable: not
# whether linkage matters in principle, but how many contexts remain fillable
# once it is accounted for.
#
# Gene order comes from KEGG's per-organism gene list, which carries a replicon
# and coordinates for every gene -- one request per genome. Runs are clipped at
# replicon boundaries, because a contig does not span two chromosomes.
#
# Usage:
#   Rscript manuscript/analysis/10-block-drop.R [--genomes=500] [--completeness=0.8]
#           [--replicates=5] [--blocks=1,5,20,50] [--seed=1] [--min-n=30]
#
# Needs the KO cache from 01-marker-matrix.R and the contexts from
# 09-cooccurrence.R. First run fetches one gene list per sampled genome.

source("manuscript/analysis/_common.R")

args <- commandArgs(trailingOnly = TRUE)
opt <- function(name, default) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit) == 0) default else sub(paste0("^--", name, "="), "", hit[[1]])
}
n_genomes    <- as.integer(opt("genomes", "500"))
completeness <- as.numeric(opt("completeness", "0.8"))
replicates   <- as.integer(opt("replicates", "5"))
block_means  <- as.numeric(strsplit(opt("blocks", "1,5,20,50"), ",")[[1]])
seed         <- as.integer(opt("seed", "1"))
min_n        <- as.integer(opt("min-n", "30"))
out_dir      <- "manuscript/analysis/output"

posterior <- function(pi, d) d * pi / (d * pi + (1 - pi))
pi_needed <- function(target, d) target / (d + target - d * target)
bar <- pi_needed(0.9, 1 - completeness)

con <- gifter_db()

# ------------------------------------------------------- 1. contexts to re-test
rule("1. The contexts under test")
ctx <- read.delim(file.path(out_dir, "cooccurrence-contexts.tsv"), stringsAsFactors = FALSE)
candidates <- ctx[!is.na(ctx$pi_lower) & ctx$n_context >= 50 & ctx$pi_lower >= bar, ]
kv("completeness assumed", sprintf("%.2f", completeness))
kv("pi bar for a posterior of 0.90 under independence", sprintf("%.4f", bar))
kv("contexts clearing that bar in 09", nrow(candidates))

# The same generic walk 09 uses. Reproduced rather than imported because the two
# scripts must be able to disagree: if the hierarchy changes underneath them,
# two independent readings of it will not silently agree.
LAYERS <- list(
  metabolic = list(container = "gift_route", container_pk = "route_pk",
                   container_id = "route_id", link = "route_reaction",
                   unit = "reaction", unit_pk = "reaction_pk", unit_id = "reaction_id",
                   system = "enzyme_system", component = "enzyme_component",
                   marker_link = "component_marker"),
  defense = list(container = "gift_mechanism", container_pk = "mechanism_pk",
                 container_id = "mechanism_id", link = "mechanism_function",
                 unit = "defense_function", unit_pk = "function_pk", unit_id = "function_id",
                 system = "defense_system", component = "defense_component",
                 marker_link = "defense_component_marker"),
  structural = list(container = "gift_architecture", container_pk = "architecture_pk",
                    container_id = "architecture_id", link = "architecture_function",
                    unit = "structural_function", unit_pk = "function_pk", unit_id = "function_id",
                    system = "structural_system", component = "structural_component",
                    marker_link = "structural_component_marker"),
  regulatory = list(container = "gift_circuit", container_pk = "circuit_pk",
                    container_id = "circuit_id", link = "circuit_function",
                    unit = "regulatory_function", unit_pk = "function_pk", unit_id = "function_id",
                    system = "regulatory_system", component = "regulatory_component",
                    marker_link = "regulatory_component_marker"))

cm_rows <- list(); mem_rows <- list()
for (layer in names(LAYERS)) {
  L <- LAYERS[[layer]]
  cm_rows[[layer]] <- cbind(layer = layer, dbGetQuery(con, sprintf("
    select c.component_id, s.system_id, u.%s as unit_id, m.namespace, m.accession
    from %s c join %s s on s.system_pk = c.system_pk
    join %s u on u.%s = s.%s
    join %s cm on cm.component_pk = c.component_pk
    join marker m on m.marker_pk = cm.marker_pk",
    L$unit_id, L$component, L$system, L$unit, L$unit_pk, L$unit_pk, L$marker_link)))
  mem_rows[[layer]] <- cbind(layer = layer, dbGetQuery(con, sprintf("
    select g.gift_id, ct.%s as container_id, u.%s as unit_id, l.required
    from gift g join %s ct on ct.gift_pk = g.gift_pk
    join %s l on l.%s = ct.%s
    join %s u on u.%s = l.%s",
    L$container_id, L$unit_id, L$container, L$link, L$container_pk, L$container_pk,
    L$unit, L$unit_pk, L$unit_pk)))
}
cmk <- do.call(rbind, cm_rows); mem <- do.call(rbind, mem_rows)
for (col in c("system_id", "unit_id", "component_id"))
  cmk[[col]] <- paste(cmk$layer, cmk[[col]], sep = ":")
for (col in c("unit_id", "container_id"))
  mem[[col]] <- paste(mem$layer, mem[[col]], sep = ":")

components <- unique(cmk[, c("component_id", "system_id", "unit_id")])
sys_components <- split(components$component_id, components$system_id)
unit_systems <- split(unique(cmk[, c("system_id", "unit_id")])$system_id,
                      unique(cmk[, c("system_id", "unit_id")])$unit_id)
required <- mem[mem$required == 1, ]
cont_units <- lapply(split(required$unit_id, required$container_id), unique)

# ------------------------------------------------------------------ 2. genomes
rule("2. Genomes with coordinates")
genome_set <- read.delim(file.path(out_dir, "kegg-genome-set.tsv"), stringsAsFactors = FALSE)
kos <- dbGetQuery(con, "select distinct accession from marker where namespace = 'KO'")$accession
annotation <- kegg_annotation_table(kos)
carried <- table(annotation$genome_id)
eligible <- genome_set[genome_set$prokaryote & genome_set$org %in% names(carried), ]
eligible$markers <- as.integer(carried[eligible$org])
eligible <- eligible[eligible$markers >= 20, ]
set.seed(seed)
strata <- cut(eligible$markers, quantile(eligible$markers, probs = seq(0, 1, 0.25)),
              include.lowest = TRUE, labels = FALSE)
per_stratum <- ceiling(n_genomes / max(strata))
chosen <- unlist(lapply(split(eligible$org, strata),
                        function(x) sample(x, min(per_stratum, length(x)))))
chosen <- head(sort(chosen), n_genomes)
kv("genomes sampled, stratified by marker count", length(chosen))

# One request per genome. The gene list carries a replicon and coordinates for
# every gene in the organism, not only the ones bearing a curated marker, which
# is what makes adjacency real: contiguity among curated genes alone is not
# contiguity on a chromosome.
paths <- cached_get_many(
  paste0("https://rest.kegg.jp/list/", chosen),
  file.path("kegg", "genes", paste0(chosen, ".tsv")), host_con = 4L)

read_order <- function(path) {
  if (is.na(path)) return(NULL)
  lines <- readLines(path, warn = FALSE)
  lines <- lines[nzchar(lines)]
  f <- strsplit(lines, "\t", fixed = TRUE)
  keep <- lengths(f) >= 3
  if (!any(keep)) return(NULL)
  f <- f[keep]
  gene <- vapply(f, `[`, character(1), 1L)
  pos  <- vapply(f, `[`, character(1), 3L)
  # "I:complement(235..402)" -> replicon "I", start 235. A gene with no parsable
  # coordinate cannot be placed and is dropped from the ordering; it is still
  # absent from every simulated assembly, which would fabricate a loss, so it is
  # excluded from the genome entirely.
  replicon <- ifelse(grepl(":", pos, fixed = TRUE), sub(":.*", "", pos), "")
  coord <- sub(".*:", "", pos)
  start <- suppressWarnings(as.numeric(sub("^[^0-9]*([0-9]+).*", "\\1", coord)))
  ok <- !is.na(start)
  if (!any(ok)) return(NULL)
  o <- order(replicon[ok], start[ok])
  data.frame(gene_id = gene[ok][o], replicon = replicon[ok][o],
             stringsAsFactors = FALSE)
}

orders <- lapply(paths, read_order)
names(orders) <- chosen
have <- !vapply(orders, is.null, logical(1))
chosen <- chosen[have]; orders <- orders[have]
kv("genomes with a parsed gene order", length(chosen))
kv("median genes per genome", median(vapply(orders, nrow, integer(1))))

# ------------------------------------------- 3. the hierarchy as column indices
rule("3. Indexing")
ko_idx <- setNames(seq_along(kos), kos)
comp_ids <- unique(components$component_id)
comp_idx <- setNames(seq_along(comp_ids), comp_ids)
ko_component <- cmk[cmk$namespace == "KO", ]
incidence <- matrix(FALSE, length(kos), length(comp_ids),
                    dimnames = list(NULL, comp_ids))
ii <- ko_idx[ko_component$accession]; jj <- comp_idx[ko_component$component_id]
ok <- !is.na(ii) & !is.na(jj)
incidence[cbind(ii[ok], jj[ok])] <- TRUE

# Each context becomes a target predicate and a set of member predicates, both
# expressed as component column indices, so that reading the hierarchy after a
# drop is matrix work rather than a walk.
unit_comp_sets <- lapply(unit_systems, function(sids)
  lapply(sids, function(s) unname(comp_idx[sys_components[[s]]])))

plan <- vector("list", nrow(candidates))
for (i in seq_len(nrow(candidates))) {
  row <- candidates[i, ]
  if (row$level == "component") {
    members <- sys_components[[row$context_id]]
    plan[[i]] <- list(kind = "component",
                      target = unname(comp_idx[row$target_id]),
                      members = unname(comp_idx[setdiff(members, row$target_id)]))
  } else {
    members <- cont_units[[row$context_id]]
    others <- setdiff(members, row$target_id)
    plan[[i]] <- if (!all(c(row$target_id, others) %in% names(unit_comp_sets))) NULL else
      list(kind = "unit", target = unit_comp_sets[[row$target_id]],
           members = unname(unit_comp_sets[others]))
  }
}
usable <- !vapply(plan, function(p)
  is.null(p) || is.null(p$target) || anyNA(unlist(p$target)) ||
    length(p$members) == 0 || anyNA(unlist(p$members)), logical(1))
candidates <- candidates[usable, ]; plan <- plan[usable]
kv("contexts resolvable to component indices", nrow(candidates))

needed <- sort(unique(unlist(lapply(plan, function(p) unlist(c(p$target, p$members))))))
kv("distinct components they depend on", length(needed))

# Every index in `plan` is rewritten to a position within `needed`, so that an
# observation vector can be subscripted by position. Indexing a named vector by
# a component number instead of its name is the bug this removes: it would
# silently read the wrong component and every result after it would be wrong.
seat <- setNames(seq_along(needed), as.character(needed))
reseat <- function(x) unname(seat[as.character(x)])
plan <- lapply(plan, function(p) {
  if (p$kind == "component") {
    p$target <- reseat(p$target); p$members <- reseat(p$members)
  } else {
    p$target <- lapply(p$target, reseat)
    p$members <- lapply(p$members, function(sys) lapply(sys, reseat))
  }
  p
})

# A unit is observed when any one of its systems has all components observed;
# a component when any of its accepted KOs survives.
unit_observed <- function(systems, obs) {
  for (s in systems) if (all(obs[s])) return(TRUE)
  FALSE
}
holds <- function(p, obs) {
  if (p$kind == "component")
    return(c(target = obs[[p$target]], context = all(obs[p$members])))
  c(target = unit_observed(p$target, obs),
    context = all(vapply(p$members, unit_observed, logical(1), obs = obs)))
}

# --------------------------------------------------------------- 4. the drop
rule("4. Dropping contiguous runs")
# Runs of adjacent genes, clipped at replicon boundaries, until the target loss
# is reached. mean_len = 1 is the unlinked model, and it is run through exactly
# the same code so that the comparison is not between a simulation and an
# assumption.
drop_blocks <- function(n, replicon, keep, mean_len) {
  want <- round(n * (1 - keep))
  dropped <- logical(n)
  if (want <= 0) return(dropped)
  # A mean run of one gene is sampling genes independently, so it is done that
  # way rather than as a loop of length-one runs: same distribution, and the
  # comparison run is the cheapest of the four.
  if (mean_len <= 1) { dropped[sample.int(n, want)] <- TRUE; return(dropped) }
  lost <- 0L; guard <- 0L
  while (lost < want && guard < 20L * n) {
    guard <- guard + 1L
    start <- sample.int(n, 1L)
    len <- if (mean_len <= 1) 1L else 1L + stats::rgeom(1L, 1 / mean_len)
    end <- min(n, start + len - 1L)
    # clip to the replicon the run started on
    same <- replicon[start:end] == replicon[start]
    end <- start + sum(cumprod(same)) - 1L
    idx <- start:end
    lost <- lost + sum(!dropped[idx])
    dropped[idx] <- TRUE
  }
  dropped
}

# Per genome, the (gene position, KO column) pairs, so a surviving gene set maps
# to a surviving KO set in one subscript.
gene_ko <- split(annotation[annotation$genome_id %in% chosen,
                            c("gene_id", "accession")],
                 annotation$genome_id[annotation$genome_id %in% chosen])

pos_ko <- list(); baseline <- list(); placed <- integer(0)
for (org in chosen) {
  ord <- orders[[org]]
  g <- gene_ko[[org]]
  if (is.null(g) || !nrow(g)) next
  p <- match(g$gene_id, ord$gene_id); k <- ko_idx[g$accession]
  ok <- !is.na(p) & !is.na(k)
  if (!any(ok)) next
  pos_ko[[org]] <- cbind(pos = p[ok], ko = unname(k[ok]))
  placed[[org]] <- sum(ok)
  baseline[[org]] <- colSums(
    incidence[unique(pos_ko[[org]][, "ko"]), needed, drop = FALSE]) > 0
}
# A genome whose curated genes could not be placed on its own gene order cannot
# be dropped from coherently, and keeping it would count every one of its
# markers as lost at every level.
chosen <- chosen[chosen %in% names(pos_ko)]
kv("genomes with markers placed on their gene order", length(chosen))
kv("median curated marker genes placed per genome", median(placed))

observed_after <- function(org, dropped) {
  pk <- pos_ko[[org]]
  surv <- unique(pk[!dropped[pk[, "pos"]], "ko"])
  if (!length(surv)) return(rep(FALSE, length(needed)))
  colSums(incidence[surv, needed, drop = FALSE]) > 0
}

# Eligibility, once: a context can only measure a dropout among genomes where
# the target and its whole context are there to begin with.
full <- matrix(FALSE, length(chosen), nrow(candidates),
               dimnames = list(chosen, NULL))
for (gi in seq_along(chosen)) {
  obs <- baseline[[chosen[gi]]]
  for (ci in seq_len(nrow(candidates))) {
    h <- holds(plan[[ci]], obs)
    full[gi, ci] <- h[["target"]] && h[["context"]]
  }
}
kv("median genomes per context carrying the whole context", median(colSums(full)))

hits <- array(0L, c(nrow(candidates), length(block_means), 2),
              dimnames = list(NULL, as.character(block_means),
                              c("context_held", "target_lost")))
marginal <- array(0L, c(nrow(candidates), length(block_means), 2),
                  dimnames = list(NULL, as.character(block_means),
                                  c("trials", "target_lost")))
set.seed(seed)
for (bi in seq_along(block_means)) {
  L <- block_means[[bi]]
  for (rep in seq_len(replicates)) {
    for (gi in seq_along(chosen)) {
      org <- chosen[[gi]]
      if (!any(full[gi, ])) next
      ord <- orders[[org]]
      dropped <- drop_blocks(nrow(ord), ord$replicon, completeness, L)
      obs <- observed_after(org, dropped)
      for (ci in which(full[gi, ])) {
        h <- holds(plan[[ci]], obs)
        marginal[ci, bi, "trials"] <- marginal[ci, bi, "trials"] + 1L
        if (!h[["target"]]) marginal[ci, bi, "target_lost"] <-
          marginal[ci, bi, "target_lost"] + 1L
        if (h[["context"]]) {
          hits[ci, bi, "context_held"] <- hits[ci, bi, "context_held"] + 1L
          if (!h[["target"]]) hits[ci, bi, "target_lost"] <-
            hits[ci, bi, "target_lost"] + 1L
        }
      }
    }
  }
  message("  block mean ", L, " genes: done")
}

# ------------------------------------------------------- 5. what was measured
rule("5. Conditional dropout against the independent assumption")
res <- do.call(rbind, lapply(seq_along(block_means), function(bi) {
  data.frame(
    block_mean = block_means[[bi]],
    level = candidates$level, layer = candidates$layer,
    context_id = candidates$context_id, target_id = candidates$target_id,
    gift_ids = candidates$gift_ids, pi = candidates$pi,
    pi_lower = candidates$pi_lower, lift = candidates$lift,
    pi_genus_lower = candidates$pi_genus_lower,
    n_context_held = hits[, bi, "context_held"],
    n_target_lost_in_context = hits[, bi, "target_lost"],
    n_trials = marginal[, bi, "trials"],
    n_target_lost = marginal[, bi, "target_lost"],
    stringsAsFactors = FALSE)
}))
res$d_conditional <- ifelse(res$n_context_held > 0,
                            res$n_target_lost_in_context / res$n_context_held, NA_real_)
res$d_marginal <- ifelse(res$n_trials > 0, res$n_target_lost / res$n_trials, NA_real_)
res$posterior_assumed  <- posterior(res$pi_lower, 1 - completeness)
res$posterior_measured <- posterior(res$pi_lower, res$d_conditional)

ok <- !is.na(res$d_conditional) & res$n_context_held >= min_n
cat("\n  d, mean over contexts with at least ", min_n, " conditioned trials:\n\n", sep = "")
tab <- do.call(rbind, lapply(block_means, function(L) {
  s <- res[ok & res$block_mean == L, ]
  data.frame(block_mean = L, contexts = nrow(s),
             d_marginal = round(mean(s$d_marginal), 4),
             d_conditional = round(mean(s$d_conditional), 4),
             ratio = round(mean(s$d_conditional) / max(mean(s$d_marginal), 1e-9), 3))
}))
print(tab, row.names = FALSE)
cat("\n  d_marginal is what the genome lost overall; d_conditional is what it lost\n",
    "  in the one place the posterior asks about.\n\n",
    "  The two do not coincide even at a block mean of one gene, and the reason is\n",
    "  not linkage. Genomes differ in how much redundancy backs a component -- gene\n",
    "  copies, alternative accepted markers, alternative systems under a unit -- and\n",
    "  a redundant genome both holds the context more often and loses the target\n",
    "  less often. Conditioning therefore selects redundant genomes, and d falls\n",
    "  even under independent loss. That offset is a property of the estimator, so\n",
    "  comparing d_conditional against d_marginal would attribute it to linkage.\n\n",
    "  The comparison that isolates linkage holds the estimator and the conditioning\n",
    "  fixed and moves only the run length: d_conditional at a block mean of one gene\n",
    "  against the same quantity at a longer one, context by context.\n", sep = "")

# Matched by context, so the ratio is not contaminated by which contexts each
# block length happened to have enough trials for.
base <- res[res$block_mean == min(block_means) & ok, c("context_id", "target_id", "d_conditional")]
names(base)[3] <- "d_unlinked"
matched <- merge(res[ok, ], base, by = c("context_id", "target_id"))
cat("\n  d_conditional relative to the unlinked run, matched context by context:\n\n")
print(do.call(rbind, lapply(block_means, function(L) {
  m <- matched[matched$block_mean == L, ]
  data.frame(block_mean = L, contexts = nrow(m),
             median_ratio = round(median(m$d_conditional / pmax(m$d_unlinked, 1e-9)), 3))
})), row.names = FALSE)

rule("6. Survivors, recounted")
# The 09 survivor rule, with d supplied rather than assumed: the posterior must
# clear 0.90 on the panel and on the genus-dereplicated estimate, and the
# context must at least double the base rate.
survives <- function(s, d) {
  posterior(s$pi_lower, d) >= 0.9 &
    !is.na(s$pi_genus_lower) & posterior(s$pi_genus_lower, d) >= 0.9 &
    s$lift >= 2
}
recount <- do.call(rbind, lapply(block_means, function(L) {
  s <- res[ok & res$block_mean == L, ]
  measured <- survives(s, s$d_conditional)
  data.frame(block_mean = L, contexts_tested = nrow(s),
             survivors_assumed = sum(survives(s, 1 - completeness), na.rm = TRUE),
             survivors_measured = sum(measured, na.rm = TRUE),
             flagellar_measured = sum(measured &
                                        grepl("flagellar_apparatus", s$gift_ids),
                                      na.rm = TRUE))
}))
print(recount, row.names = FALSE)
cat("\n  survivors_assumed is 09's count restricted to the contexts this script\n",
    "  could test, so the two columns differ only in where d came from.\n", sep = "")

rule("7. Writing")
write.table(res, file.path(out_dir, "block-drop-contexts.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
summary_table <- merge(tab, recount, by = "block_mean")
write.table(summary_table, file.path(out_dir, "block-drop-summary.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
kv("block-drop-contexts.tsv", nrow(res))
kv("block-drop-summary.tsv", nrow(summary_table))
