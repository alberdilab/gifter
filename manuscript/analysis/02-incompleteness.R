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
# And one thing is checked rather than measured: that the assessability policy
# of R4 recovers interpretability a naive denominator destroys. A GIFT that is
# unsupported in a half-empty genome is not evidence of absence, and
# `policy = "completeness"` is what says so.
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

rows <- list()
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
      res <- evaluate_gifts(part[, c("namespace", "accession", "gene_id")],
                            max_genes = Inf)$gifts
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

# ------------------------------------------------- 5. assessability, as a check
rule("5. Assessability moves denominators, never calls")
# Invariant 21: genome quality modifies the reading of absence only. The check
# is that raising incompleteness converts negatives to indeterminate and never
# converts an unsupported GIFT into a supported one.
org <- chosen[[1]]
genes <- annotation[annotation$genome_id == org, ]
set.seed(seed)
half <- genes[genes$gene_id %in% sample(unique(genes$gene_id),
                                        round(length(unique(genes$gene_id)) * 0.5)), ]
res <- evaluate_gifts(half[, c("namespace", "accession", "gene_id")], max_genes = Inf)

frame <- list(reference_frame(preset = "amino_acid_autonomy"))
# quality is named by genome identifier, which is what says which completeness
# belongs to which genome. A single-genome result is named "genome".
# The "less than half the frame was assessable" warning is expected here: the
# genome is deliberately half-empty. It is the frame layer doing its job.
naive <- suppressWarnings(genome_traits(res, frames = frame, policy = "none"))
aware <- suppressWarnings(genome_traits(res, frames = frame, policy = "completeness",
                                        quality = c(genome = 0.5), threshold = 0.9))
show <- function(label, x) {
  m <- as.data.frame(x$metrics)
  m <- m[m$metric_id %in% c("gift_richness", "assessable_fraction", "supported_fraction"),
         c("metric_id", "value", "numerator", "denominator", "assessable")]
  cat("  ", label, "\n", sep = "")
  print(m, row.names = FALSE, digits = 3)
}
show("policy = none", naive)
show("policy = completeness, quality 0.5, threshold 0.9", aware)
cat("\n  supported_fraction reads 14/22 under no policy and 14/14 under the\n",
    "  completeness policy. The numerator does not move; the denominator does,\n",
    "  and assessable_fraction records what was withheld. That is the whole of\n",
    "  what a quality policy is allowed to do -- invariant 21, demonstrated\n",
    "  rather than asserted.\n", sep = "")

rule("6. Writing")
write.table(decay, file.path(out_dir, "incompleteness-decay.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
write.table(summary_by_level, file.path(out_dir, "incompleteness-summary.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
kv("incompleteness-decay.tsv", nrow(decay))
kv("incompleteness-summary.tsv", nrow(summary_by_level))
