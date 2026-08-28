#!/usr/bin/env Rscript
# Does context license filling a gap? The panel estimate.
#
# A MAG that is 80% complete has not been shown to lack anything, and R4's
# assessability layer says so with a blunt instrument: below a declared
# completeness, every absence in the genome becomes indeterminate. That is
# defensible and it is also wasteful. Some absences are far more likely to be
# artefacts than others, and the difference is measurable.
#
# The intuition. If a system's other components are all present and, across a
# panel of complete genomes, that component is essentially never absent when the
# others are there, then its absence here is more likely a gap in the assembly
# than a fact about the organism. If instead it is absent from a fifth of the
# genomes carrying the same context, its absence here is ordinary biological
# variation and nothing licenses filling it.
#
# The estimand, stated before anything is computed, because the two halves are
# usually conflated:
#
#   pi    P(target supported | the rest of its context supported), on the panel.
#         This is what licenses filling.
#   lift  pi / P(target supported). A marker that is simply common earns a high
#         pi for free; only lift >> 1 means the context is predicting the target
#         rather than the base rate reasserting itself.
#
# and the decision quantity they feed, with d = P(gene unobserved | truly
# present) ~ 1 - completeness:
#
#   P(truly present | not observed, context) = d*pi / (d*pi + (1 - pi))
#
# At d = 0.2 -- a genome 80% complete -- that posterior
# reaches 0.9 only at pi >= 0.978. So the question this script answers is not
# "can gaps be filled" but "how many curated contexts are tight enough that
# filling one would be defensible at all". If the answer is a handful, the whole
# idea is a footnote; if it is hundreds, it is a layer.
#
# What this script does NOT do. It fills nothing, and it changes no call.
# Invariant 21 stands: nothing may convert an unsupported GIFT into a supported
# one. This measures the distribution of pi so that the design decision can be
# taken on evidence. Calibrating a posterior against known truth is the drop
# simulation's job, not this one's.
#
# Two contexts are estimated, both of which gifter's hierarchy hands over for
# free -- which is the point, because a flat co-occurrence model has to guess
# its conditioning set:
#
#   component  P(component | the other components of its system). Subunits of
#              one complex, the tightest context there is.
#   unit       P(required reaction | the other required reactions of its route),
#              and the same for a defense function within a mechanism, a
#              structural function within an architecture, a regulatory function
#              within a circuit. All four layers are one query with four
#              table names.
#
# Panel caveats, all of which bound the result rather than decorate it:
#
#   * Phylogeny. Co-occurrence across a panel is mostly shared ancestry. Every
#     pi is therefore reported twice, once over the whole panel and once over
#     one genome per genus. Where the two diverge, ancestry was doing the work.
#   * The panel is KEGG's genome set, which is not all closed genomes. A draft
#     assembly in the panel carries the very artefact being modelled, and biases
#     pi downward. This is the weakest assumption here and it is not fixable
#     from the cached matrix alone.
#   * KO only. A component whose evidence is a CAZy family is unreachable, and a
#     context containing one is dropped entirely rather than scored with a
#     guaranteed absence in it. Section 2 counts what that costs.
#
# Usage:
#   Rscript manuscript/analysis/09-cooccurrence.R [--completeness=0.8] [--min-n=50]
#
# Needs the KO cache from 01-marker-matrix.R. Runs in about a minute once warm.

source("manuscript/analysis/_common.R")

args <- commandArgs(trailingOnly = TRUE)
opt <- function(name, default) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit) == 0) default else sub(paste0("^--", name, "="), "", hit[[1]])
}
completeness <- as.numeric(opt("completeness", "0.8"))
min_n        <- as.integer(opt("min-n", "50"))
dropout      <- 1 - completeness
out_dir      <- "manuscript/analysis/output"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

con <- gifter_db()

# The posterior, and the pi that clears a given posterior. Both are one line and
# both are used in the reporting, so neither is written twice.
posterior  <- function(pi, d) d * pi / (d * pi + (1 - pi))
pi_needed  <- function(target, d) target / (d + target - d * target)

# Wilson, 95%. A pi of 1.000 over eleven genomes is not the same claim as a pi
# of 0.98 over six thousand, and a point estimate cannot tell them apart. Every
# threshold below is applied to the lower bound, not to pi.
wilson_lower <- function(hits, n, z = 1.959964) {
  p <- ifelse(n > 0, hits / n, NA_real_)
  out <- (p + z^2 / (2 * n) - z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2))) /
    (1 + z^2 / n)
  ifelse(n > 0, pmax(0, out), NA_real_)
}

# --------------------------------------------------------------- 1. the panel
rule("1. The panel")
genome_set <- read.delim(file.path(out_dir, "kegg-genome-set.tsv"),
                         stringsAsFactors = FALSE)
genome_set <- genome_set[genome_set$prokaryote & genome_set$markers >= 20, ]
genomes <- genome_set$org
kv("prokaryote genomes carrying >= 20 curated markers", length(genomes))

# One genome per genus, the phylogeny control. The most marker-rich member is
# taken rather than a random one: the panel wants complete genomes, and among
# congeners the marker count is the only completeness proxy this table carries.
genome_set$genus <- sub(" .*", "", genome_set$binomial)
ranked <- genome_set[order(genome_set$genus, -genome_set$markers, genome_set$org), ]
derep <- ranked$org[!duplicated(ranked$genus)]
kv("genera represented", length(derep))

kos <- dbGetQuery(con, "select distinct accession from marker where namespace = 'KO'")$accession
annotation <- kegg_annotation_table(kos)
gi <- match(annotation$genome_id, genomes)
ki <- match(annotation$accession, kos)
ok <- !is.na(gi) & !is.na(ki)
M <- matrix(FALSE, length(genomes), length(kos), dimnames = list(genomes, kos))
M[cbind(gi[ok], ki[ok])] <- TRUE
in_derep <- genomes %in% derep
kv("KO markers in the matrix", length(kos))
kv("genome-marker observations", sum(M))
rm(annotation, gi, ki, ok); invisible(gc(FALSE))

# --------------------------------------------------- 2. the hierarchy, generically
rule("2. Components and units")
# Four GIFT types, one shape. gift -> container -> unit -> system -> component
# -> marker, where the container is a route, mechanism, architecture or circuit
# and the unit is a reaction or a function. Writing this as four table names
# rather than four queries is the same rule the package itself follows: general
# operations over the hierarchy, never per-type logic.
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

component_rows <- list(); membership_rows <- list()
for (layer in names(LAYERS)) {
  L <- LAYERS[[layer]]
  component_rows[[layer]] <- cbind(layer = layer, dbGetQuery(con, sprintf("
    select c.component_id, s.system_id, u.%s as unit_id, m.namespace, m.accession
    from %s c
    join %s s on s.system_pk = c.system_pk
    join %s u on u.%s = s.%s
    join %s cm on cm.component_pk = c.component_pk
    join marker m on m.marker_pk = cm.marker_pk",
    L$unit_id, L$component, L$system, L$unit, L$unit_pk, L$unit_pk, L$marker_link)))
  membership_rows[[layer]] <- cbind(layer = layer, dbGetQuery(con, sprintf("
    select g.gift_id, g.gift_type, ct.%s as container_id, u.%s as unit_id, l.required
    from gift g
    join %s ct on ct.gift_pk = g.gift_pk
    join %s l on l.%s = ct.%s
    join %s u on u.%s = l.%s",
    L$container_id, L$unit_id, L$container, L$link, L$container_pk, L$container_pk,
    L$unit, L$unit_pk, L$unit_pk)))
}
component_markers <- do.call(rbind, component_rows)
membership <- do.call(rbind, membership_rows)
# Identifiers are unique within a layer, not necessarily across layers.
component_markers$system_id <- paste(component_markers$layer, component_markers$system_id, sep = ":")
component_markers$unit_id   <- paste(component_markers$layer, component_markers$unit_id, sep = ":")
component_markers$component_id <- paste(component_markers$layer, component_markers$component_id, sep = ":")
membership$unit_id      <- paste(membership$layer, membership$unit_id, sep = ":")
membership$container_id <- paste(membership$layer, membership$container_id, sep = ":")

components <- unique(component_markers[, c("layer", "component_id", "system_id", "unit_id")])
kv("components across all four layers", nrow(components))

# A component is reachable only if some KO is accepted for it. One that is not
# would be absent from every genome in the panel, and a context containing it
# would score a guaranteed zero that says nothing about biology.
ko_markers <- component_markers[component_markers$namespace == "KO", ]
reachable <- unique(ko_markers$component_id)
kv("reachable by a KO marker", length(reachable))
kv("unreachable, so excluded with their contexts", nrow(components) - length(reachable))

# Support, per component: does the genome carry any of its accepted KOs?
support <- matrix(FALSE, length(genomes), length(reachable),
                  dimnames = list(NULL, reachable))
by_component <- split(ko_markers$accession, ko_markers$component_id)
for (cid in reachable) {
  idx <- match(unique(by_component[[cid]]), kos)
  idx <- idx[!is.na(idx)]
  if (length(idx)) support[, cid] <- rowSums(M[, idx, drop = FALSE]) > 0
}
kv("component-support cells computed", length(support))

# --------------------------------------------------- 3. the two context levels
rule("3. Contexts")
# The estimator, written once and applied to both levels. `target` is the
# column being predicted; `context` is the conjunction of the others. n is how
# many panel genomes satisfy the context at all, which is what makes a pi
# readable -- a pi over nine genomes is a curiosity.
estimate <- function(target, context) {
  hit_all <- sum(context & target); n_all <- sum(context)
  d_ctx <- context & in_derep
  hit_d <- sum(d_ctx & target); n_d <- sum(d_ctx)
  data.frame(
    n_context = n_all, n_supported = hit_all,
    gaps_in_panel = n_all - hit_all,
    pi = if (n_all > 0) hit_all / n_all else NA_real_,
    pi_lower = wilson_lower(hit_all, n_all),
    base_rate = mean(target),
    n_context_genus = n_d,
    pi_genus = if (n_d > 0) hit_d / n_d else NA_real_,
    pi_genus_lower = wilson_lower(hit_d, n_d),
    stringsAsFactors = FALSE)
}

# Which GIFTs a unit serves, and therefore which a component serves. Many-to-one
# in both directions, so it is carried as a count plus the list rather than
# flattened into a single attribution that would be wrong for shared chemistry.
unit_gifts <- tapply(membership$gift_id, membership$unit_id,
                     function(x) paste(sort(unique(x)), collapse = ";"))

rows <- list()

# --- level one: a component within its system -------------------------------
sys_components <- split(components$component_id, components$system_id)
sys_kept <- 0L; sys_dropped <- 0L
for (sid in names(sys_components)) {
  members <- sys_components[[sid]]
  if (length(members) < 2) next
  if (!all(members %in% reachable)) { sys_dropped <- sys_dropped + 1L; next }
  sys_kept <- sys_kept + 1L
  for (cid in members) {
    others <- setdiff(members, cid)
    context <- rowSums(support[, others, drop = FALSE]) == length(others)
    unit <- components$unit_id[match(cid, components$component_id)]
    rows[[length(rows) + 1L]] <- cbind(
      data.frame(level = "component", layer = sub(":.*", "", cid),
                 context_id = sid, target_id = cid,
                 context_size = length(others),
                 gift_ids = unname(unit_gifts[unit] %||% NA_character_),
                 stringsAsFactors = FALSE),
      estimate(support[, cid], context))
  }
}
kv("multi-component systems scored", sys_kept)
kv("  dropped, a component has no KO evidence", sys_dropped)

# --- level two: a required unit within its container -------------------------
# A unit is supported when any one of its systems is complete: all of that
# system's components supported. That is the reaction layer of the evaluator,
# recomputed here over the panel rather than re-evaluating 11 949 genomes.
unit_ids <- unique(components$unit_id)
unit_support <- matrix(FALSE, length(genomes), length(unit_ids),
                       dimnames = list(NULL, unit_ids))
unit_reachable <- logical(length(unit_ids)); names(unit_reachable) <- unit_ids
for (uid in unit_ids) {
  systems <- unique(components$system_id[components$unit_id == uid])
  complete_any <- rep(FALSE, length(genomes)); any_scorable <- FALSE
  for (sid in systems) {
    members <- sys_components[[sid]]
    if (!all(members %in% reachable)) next
    any_scorable <- TRUE
    complete_any <- complete_any |
      (rowSums(support[, members, drop = FALSE]) == length(members))
  }
  unit_support[, uid] <- complete_any
  unit_reachable[uid] <- any_scorable
}
kv("units with at least one KO-scorable system", sum(unit_reachable))

required <- membership[membership$required == 1, ]
cont_units <- split(required$unit_id, required$container_id)
cont_kept <- 0L; cont_dropped <- 0L
for (kid in names(cont_units)) {
  members <- unique(cont_units[[kid]])
  members <- members[members %in% unit_ids]
  if (length(members) < 2) next
  if (!all(unit_reachable[members])) { cont_dropped <- cont_dropped + 1L; next }
  cont_kept <- cont_kept + 1L
  gifts <- paste(sort(unique(required$gift_id[required$container_id == kid])), collapse = ";")
  for (uid in members) {
    others <- setdiff(members, uid)
    context <- rowSums(unit_support[, others, drop = FALSE]) == length(others)
    rows[[length(rows) + 1L]] <- cbind(
      data.frame(level = "unit", layer = sub(":.*", "", uid),
                 context_id = kid, target_id = uid,
                 context_size = length(others), gift_ids = gifts,
                 stringsAsFactors = FALSE),
      estimate(unit_support[, uid], context))
  }
}
kv("multi-unit containers scored", cont_kept)
kv("  dropped, a unit has no KO-scorable system", cont_dropped)

ctx <- do.call(rbind, rows)
ctx$lift <- ctx$pi / pmax(ctx$base_rate, 1e-9)
# The posterior is taken from the lower bound, never the point estimate: filling
# a gap on a pi of 1.000 over eleven genomes is exactly the mistake this column
# exists to prevent.
ctx$posterior <- posterior(ctx$pi_lower, dropout)
ctx$posterior_genus <- posterior(ctx$pi_genus_lower, dropout)

# ------------------------------------------------------------ 4. the answer
rule("4. How tight are the contexts?")
threshold <- pi_needed(0.9, dropout)
kv("completeness assumed", sprintf("%.2f  (d = %.2f)", completeness, dropout))
kv("pi needed for a posterior of 0.90", sprintf("%.4f", threshold))
kv("contexts scored", nrow(ctx))

usable <- ctx[!is.na(ctx$pi) & ctx$n_context >= min_n, ]
kv(paste0("contexts with n >= ", min_n), nrow(usable))
cat("\n  pi over the whole panel, by level:\n\n")
for (lv in unique(usable$level)) {
  q <- quantile(usable$pi[usable$level == lv], c(0, .25, .5, .75, .9, 1))
  cat(sprintf("    %-10s n=%4d   min %.3f  q1 %.3f  med %.3f  q3 %.3f  p90 %.3f  max %.3f\n",
              lv, sum(usable$level == lv), q[1], q[2], q[3], q[4], q[5], q[6]))
}

cat("\n  contexts clearing the bar, counted on the Wilson lower bound:\n\n")
tiers <- data.frame(
  level = character(), n = integer(), clears = integer(),
  clears_genus = integer(), lift_ge_2 = integer(), stringsAsFactors = FALSE)
for (lv in unique(usable$level)) {
  s <- usable[usable$level == lv, ]
  clears <- s$pi_lower >= threshold
  tiers <- rbind(tiers, data.frame(
    level = lv, n = nrow(s), clears = sum(clears),
    clears_genus = sum(clears & !is.na(s$pi_genus_lower) & s$pi_genus_lower >= threshold),
    lift_ge_2 = sum(clears & s$lift >= 2), stringsAsFactors = FALSE))
}
print(tiers, row.names = FALSE)
cat("\n    clears        pi_lower >= the bar on the whole panel\n",
    "   clears_genus  and still clears it on one genome per genus\n",
    "   lift_ge_2     and the context at least doubles the base rate\n", sep = "")

rule("5. What the two controls remove")
clears <- usable[usable$pi_lower >= threshold, ]
lost_phylo <- sum(!is.na(clears$pi_genus_lower) & clears$pi_genus_lower < threshold)
kv("contexts clearing on the full panel", nrow(clears))
kv("  of those, failing once dereplicated by genus",
   sprintf("%d (%.0f%%)", lost_phylo, 100 * lost_phylo / max(nrow(clears), 1)))
kv("  of those, with lift < 2 -- the base rate was doing the work",
   sum(clears$lift < 2))
kv("surviving both controls", sum(clears$pi_genus_lower >= threshold & clears$lift >= 2,
                                  na.rm = TRUE))
kv("gaps in the panel among surviving contexts",
   sum(clears$gaps_in_panel[clears$pi_genus_lower >= threshold & clears$lift >= 2],
       na.rm = TRUE))
cat("\n  That last number is complete genomes that satisfy a context and lack the\n",
    "  target anyway. It is the irreducible false-fill rate: real biological\n",
    "  variation that no amount of panel size removes, and the reason the\n",
    "  posterior is bounded well below 1 even in the tightest contexts.\n", sep = "")

rule("6. The tightest contexts")
best <- clears[order(-clears$pi_lower, -clears$n_context), ]
best <- best[!is.na(best$pi_genus_lower) & best$pi_genus_lower >= threshold & best$lift >= 2, ]
show <- head(best, 15)
if (nrow(show)) {
  print(data.frame(
    level = show$level, target = substr(show$target_id, 1, 44),
    n = show$n_context, pi = round(show$pi, 4), lower = round(show$pi_lower, 4),
    lift = round(pmin(show$lift, 999), 1), post = round(show$posterior, 3),
    row.names = NULL), right = FALSE)
} else {
  cat("  none survived both controls at this completeness and n.\n")
}

rule("7. Sensitivity to the completeness assumed")
# The uncomfortable direction, reported rather than buried: a more incomplete
# genome makes filling *easier* to license, because dropout explains more. Every
# bit of the work is being done by the prior, which is why pi's quality is the
# whole argument.
grid <- do.call(rbind, lapply(c(0.95, 0.9, 0.8, 0.7, 0.5), function(q) {
  bar <- pi_needed(0.9, 1 - q)
  data.frame(completeness = q, pi_needed = round(bar, 4),
             contexts_clearing = sum(usable$pi_lower >= bar, na.rm = TRUE))
}))
print(grid, row.names = FALSE)

rule("8. Writing")
write.table(ctx, file.path(out_dir, "cooccurrence-contexts.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
write.table(tiers, file.path(out_dir, "cooccurrence-summary.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
kv("cooccurrence-contexts.tsv", nrow(ctx))
kv("cooccurrence-summary.tsv", nrow(tiers))
