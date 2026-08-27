#!/usr/bin/env Rscript
# R7: how a route-based call degrades as a genome loses genes.
#
# This is the reviewer's first question about any tool that reads MAGs, and it
# is the paper's submission blocker. The claim under test is not that gifter
# scores higher than a percentage. It is that the two degrade *differently* --
# a route-based call is conservative and, when it fails, names the reaction that
# was lost, while a percentage decays smoothly and says nothing about which step
# went. A number that cannot be acted on is the thing the abstraction exists to
# avoid, so the result is the shape of the decay plus what survives it.
#
# Design. Take complete reference genomes, drop genes at random to simulate the
# incompleteness of a recovered genome, and re-evaluate at each level. Three
# things are measured:
#
#   retention   of the GIFTs called at full gene content, what fraction survive
#   fullness    the same genomes under a marker-fraction score, for contrast
#   missing     the distribution of minimum_missing_requirements among the
#               calls that were lost -- the information a percentage discards
#
# And a fourth, which is R7's second panel: that the assessability policy of R4
# recovers interpretability a naive denominator destroys. A GIFT that is
# unsupported in a half-empty genome is not evidence of absence, and
# `policy = "completeness"` is what says so. It is measured on the same
# subsamples, across three bounded frames, and invariant 21 -- that a quality
# policy moves a denominator and never a call -- is checked on every cell rather
# than asserted.
#
# Genes, not markers, are dropped. A MAG loses genes; the markers follow. That
# distinction matters because a multi-subunit system loses its components
# together with the genes that encode them, which is the failure mode the
# five-layer model is built to see.
#
# Usage:
#   Rscript manuscript/analysis/02-incompleteness.R [--genomes=120]
#           [--replicates=3] [--seed=1]

source("manuscript/analysis/_common.R")
suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
opt <- function(name, default) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit) == 0) default else sub(paste0("^--", name, "="), "", hit[[1]])
}
n_genomes   <- as.integer(opt("genomes", "120"))
replicates  <- as.integer(opt("replicates", "3"))
seed        <- as.integer(opt("seed", "1"))
levels_kept <- c(1.00, 0.90, 0.80, 0.70, 0.60, 0.50)
out_dir     <- "manuscript/analysis/output"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

con <- gifter_db()

# --------------------------------------------------------------- 1. the genomes
rule("1. Reference genomes")
genome_set <- read.delim(file.path(out_dir, "kegg-genome-set.tsv"), stringsAsFactors = FALSE)
kos <- dbGetQuery(con, "select distinct accession from marker where namespace = 'KO'")$accession
annotation <- kegg_annotation_table(kos)

# Genomes are sampled across the marker-count distribution rather than from its
# top: a set of unusually complete organisms would make the decay look gentler
# than it is for the assemblies gifter is actually used on.
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
chosen <- head(chosen, n_genomes)
kv("eligible genomes", nrow(eligible))
kv("sampled, stratified by marker count", length(chosen))
kv("marker count range in the sample",
   paste(range(eligible$markers[eligible$org %in% chosen]), collapse = " to "))

# --------------------------------------------------------------- 2. the decay
rule("2. Dropping genes")
# The percentage baseline: for each GIFT, the fraction of its curated markers
# the genome carries. This is the abstraction gifter replaced, and it is
# computed here rather than cited so the comparison is like for like.
marker_of_gift <- dbGetQuery(con, "
  select distinct g.gift_id, m.accession
  from gift g
  join gift_route gr on gr.gift_pk = g.gift_pk
  join route_reaction rr on rr.route_pk = gr.route_pk
  join enzyme_system es on es.reaction_pk = rr.reaction_pk
  join enzyme_component ec on ec.system_pk = es.system_pk
  join component_marker cm on cm.component_pk = ec.component_pk
  join marker m on m.marker_pk = cm.marker_pk
  where m.namespace = 'KO'")
gift_marker_n <- table(marker_of_gift$gift_id)

fullness <- function(accessions) {
  present <- marker_of_gift[marker_of_gift$accession %in% accessions, ]
  hit <- table(present$gift_id)
  out <- setNames(rep(0, length(gift_marker_n)), names(gift_marker_n))
  out[names(hit)] <- as.numeric(hit)
  out / as.numeric(gift_marker_n)
}

# ------------------------------------------------ the bounded frames of R4
# Only bounded frames. A proportion is emitted against a frame only because
# curation declares its coverage complete, so an unbounded frame has no honest
# denominator to protect in the first place and nothing here would mean anything.
frames <- lapply(c("amino_acid_autonomy", "nucleotide_autonomy", "cofactor_autonomy"),
                 function(x) reference_frame(preset = x))
frame_metrics <- function(evaluated, org, keep, rep) {
  pull <- function(x, policy) {
    m <- as.data.frame(x$metrics)
    m <- m[m$metric_id %in% c("supported_fraction", "assessable_fraction"), ]
    data.frame(org = org, kept = keep, replicate = rep, policy = policy,
               frame = m$reference_frame, metric = m$metric_id,
               value = m$value, numerator = m$numerator,
               denominator = m$denominator, stringsAsFactors = FALSE)
  }
  # The "less than half the frame was assessable" warning is expected at the low
  # levels: the genome is deliberately half-empty and the frame layer is saying
  # so. Suppressed here because it fires 120 times a level, not because it is
  # noise -- section 5 reports exactly what it warns about.
  naive <- suppressWarnings(genome_traits(evaluated, frames = frames, policy = "none"))
  aware <- suppressWarnings(genome_traits(evaluated, frames = frames,
                                          policy = "completeness",
                                          quality = c(genome = keep), threshold = 0.9))
  rbind(pull(naive, "none"), pull(aware, "completeness"))
}

rows <- list()
assess <- list()
for (i in seq_along(chosen)) {
  org <- chosen[[i]]
  genes <- annotation[annotation$genome_id == org, ]
  all_genes <- unique(genes$gene_id)
  baseline <- evaluate_gifts(genes[, c("namespace", "accession", "gene_id")],
                             max_genes = Inf)$gifts
  supported_at_full <- baseline$gift_id[baseline$complete]
  full_fullness <- fullness(unique(genes$accession))

  for (keep in levels_kept) {
    reps <- if (keep == 1) 1L else replicates
    for (rep in seq_len(reps)) {
      set.seed(seed + rep)
      kept_genes <- if (keep == 1) all_genes else
        sample(all_genes, max(1L, round(length(all_genes) * keep)))
      part <- genes[genes$gene_id %in% kept_genes, ]
      evaluated <- evaluate_gifts(part[, c("namespace", "accession", "gene_id")],
                                  max_genes = Inf)
      res <- evaluated$gifts
      # The second half of R7, measured on the same subsample rather than
      # demonstrated once. `policy = "none"` divides by the whole frame, which
      # is the naive denominator; `policy = "completeness"` divides by what the
      # genome could speak to, and records the rest as unassessed.
      assess[[length(assess) + 1L]] <- frame_metrics(evaluated, org, keep, rep)
      still <- res$gift_id[res$complete]
      lost <- setdiff(supported_at_full, still)
      missing <- res$minimum_missing_requirements[res$gift_id %in% lost]
      f <- fullness(unique(part$accession))
      rows[[length(rows) + 1]] <- data.frame(
        org = org, kept = keep, replicate = rep,
        supported_at_full = length(supported_at_full),
        retained = length(intersect(supported_at_full, still)),
        gained = length(setdiff(still, supported_at_full)),
        mean_fullness = mean(f[supported_at_full]),
        mean_fullness_full = mean(full_fullness[supported_at_full]),
        median_missing = if (length(missing)) median(missing, na.rm = TRUE) else NA_real_,
        one_reaction_short = if (length(missing)) sum(missing == 1, na.rm = TRUE) else 0L,
        lost = length(lost),
        stringsAsFactors = FALSE)
    }
  }
  if (i %% 20 == 0) message("  ", i, "/", length(chosen), " genomes")
}
decay <- do.call(rbind, rows)
decay$retention <- decay$retained / pmax(decay$supported_at_full, 1)
decay$fullness_ratio <- decay$mean_fullness / pmax(decay$mean_fullness_full, 1e-9)

rule("3. Call retention against gene content")
summary_by_level <- aggregate(cbind(retention, fullness_ratio) ~ kept, decay, mean)
summary_by_level$lost_calls <- aggregate(lost ~ kept, decay, mean)$lost
summary_by_level$one_reaction_short <- aggregate(one_reaction_short ~ kept, decay, mean)$one_reaction_short
print(summary_by_level, row.names = FALSE, digits = 3)

cat("\n  A call is lost outright; a fullness score is only reduced. At the same\n",
    "  gene content the two numbers say different things, and only one of them\n",
    "  can be acted on -- which is what the next block reports.\n", sep = "")

rule("4. What a lost call still tells you")
lost_rows <- decay[decay$kept < 1 & decay$lost > 0, ]
kv("genome-levels where at least one call was lost", nrow(lost_rows))
kv("median missing reactions among lost calls", median(lost_rows$median_missing, na.rm = TRUE))
share <- sum(lost_rows$one_reaction_short) / sum(lost_rows$lost)
kv("lost calls that are exactly one reaction short", sprintf("%.1f%%", 100 * share))
cat("\n  That percentage is the result. A percentage-based score at the same\n",
    "  gene content reports a smaller number and cannot name the reaction; the\n",
    "  route-based call reports which step went missing, which is what makes a\n",
    "  negative result reviewable rather than merely smaller.\n", sep = "")

# ------------------------------------------- 5. assessability, the second panel
rule("5. Assessability moves denominators, never calls")
# Invariant 21: genome quality modifies the reading of absence only. A GIFT that
# is unsupported in a half-empty genome is not evidence of absence, and this is
# what says so.
#
# The claim has two halves and both are measured across every genome and level
# rather than shown once. First, the numerator never moves: a quality policy may
# not turn an unsupported call into a supported one, and if it ever did the
# policy would be manufacturing capability out of missing data. Second, the
# naive denominator is what destroys interpretability -- dividing by the whole
# frame makes an incomplete genome look like an organism that lost capabilities,
# where dividing by what the genome could speak to says the honest thing and
# reports the withheld remainder separately.
assessability <- do.call(rbind, assess)

supported <- assessability[assessability$metric == "supported_fraction", ]
wide <- reshape(supported[, c("org", "kept", "replicate", "frame", "policy",
                              "value", "numerator", "denominator")],
                idvar = c("org", "kept", "replicate", "frame"),
                timevar = "policy", direction = "wide")

# The invariant, checked rather than asserted. Numerators must be identical
# wherever both policies emit one.
#
# The absent ones are not an inconvenience to skip past, and a check that only
# compared the cells that happen to line up would pass even if every cell had
# gone missing. Where nothing in a frame is assessable at all, the policy emits
# no supported_fraction -- not NA, not zero, absent -- because there is no
# denominator to divide by. Those cells are counted separately and confirmed to
# be exactly the ones where the assessable numerator is zero.
comparable <- !is.na(wide$numerator.none) & !is.na(wide$numerator.completeness)
withheld <- wide[is.na(wide$numerator.completeness), ]
moved <- which(wide$numerator.none[comparable] != wide$numerator.completeness[comparable])
kv("frame-genome-level cells measured", nrow(wide))
kv("cells where both policies emit a supported count", sum(comparable))
kv("cells where the policy emits none at all", nrow(withheld))
kv("cells where the policy moved the numerator", length(moved))
if (length(moved))
  stop("invariant 21 violated: the completeness policy changed a supported ",
       "count in ", length(moved), " cells. A quality policy may move a ",
       "denominator and nothing else.")

zero_assessable <- assessability[assessability$metric == "assessable_fraction" &
                                   assessability$policy == "completeness" &
                                   assessability$numerator == 0, ]
if (nrow(withheld) != nrow(zero_assessable))
  stop("a supported_fraction went missing in ", nrow(withheld), " cells but ",
       nrow(zero_assessable), " had nothing assessable. The metric may only be ",
       "withheld when there is no denominator for it.")
kv("  all of them have nothing assessable", nrow(zero_assessable))

cat("\n  supported_fraction, mean across genomes, by gene content:\n\n")
by_level <- aggregate(cbind(value.none, value.completeness) ~ kept + frame, wide, mean)
by_level <- by_level[order(by_level$frame, -by_level$kept), ]
names(by_level) <- c("kept", "frame", "naive_denominator", "assessability_policy")
print(by_level, row.names = FALSE, digits = 3)

assessable <- assessability[assessability$metric == "assessable_fraction" &
                              assessability$policy == "completeness", ]
cat("\n  assessable_fraction under the policy -- what the genome could speak to:\n\n")
print(aggregate(value ~ kept + frame, assessable, mean), row.names = FALSE, digits = 3)

# What the policy actually does below the threshold, stated rather than
# summarised. `quality = keep` against `threshold = 0.9` makes 0.9 and 1.0 the
# only levels at or above it, so this is a step and not a slope -- and the step
# is a parameter choice, not a property of the data.
below <- wide[wide$kept < 0.9, ]
scored <- below[!is.na(below$numerator.completeness), ]
kv("cells below the quality threshold", nrow(below))
kv("of those, the policy emits a supported_fraction", nrow(scored))
kv("  of those, it is exactly 1.000",
   sum(scored$numerator.completeness == scored$denominator.completeness))
kv("  of those, the numerator is zero", sum(scored$numerator.completeness == 0))

cat("\n  Read this carefully, because it is not the shape the design expected.\n",
    "  Above the threshold nothing is withheld and the two policies agree to the\n",
    "  digit. Below it every unsupported member is withheld, so the denominator\n",
    "  collapses onto the numerator and supported_fraction reads 1.000 by\n",
    "  construction -- and where not even one member is assessable the metric is\n",
    "  not emitted at all. The policy does not produce a better proportion; it\n",
    "  refuses to produce one, and assessable_fraction reports how much it\n",
    "  refused.\n\n",
    "  That is the correct behaviour under invariant 21 -- an unsupported call in\n",
    "  a genome this incomplete is not evidence of absence, so there is no honest\n",
    "  denominator to divide by -- but it means supported_fraction under this\n",
    "  policy must never be read without assessable_fraction beside it. The\n",
    "  numerator is what does not move, and the check above is what proves it.\n",
    sep = "")

rule("6. Writing")
write.table(decay, file.path(out_dir, "incompleteness-decay.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
write.table(summary_by_level, file.path(out_dir, "incompleteness-summary.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
write.table(assessability, file.path(out_dir, "incompleteness-assessability.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
kv("incompleteness-decay.tsv", nrow(decay))
kv("incompleteness-summary.tsv", nrow(summary_by_level))
kv("incompleteness-assessability.tsv", nrow(assessability))
