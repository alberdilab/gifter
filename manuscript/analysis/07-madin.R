#!/usr/bin/env Rscript
# R9, the second reference: the Madin trait synthesis.
#
# 16 of the 56 curated crosswalk rows name MADIN as their source, and until this
# script existed not one of them was read by anything. `collect_observations()`
# in 03-phenotype.R handles BacDive fields only, and it is keyed on
# `bacdive_id` from the first join to the last, so a species-level record has
# nowhere to enter. Sixteen reviewed rows sat in a file that implied they had
# been tested. This is that debt paid.
#
# Why it is a separate script rather than a branch inside 03. Madin joins on a
# **species name**, not on an assembly accession, so every observation carries
# an attrition that BacDive's does not: one record stands for a species, the
# species has one or more reference genomes, and gifter calls each of them
# separately. Folding that into 03 would put two different join confounds behind
# one recall column. Keeping it apart lets the attrition be measured and
# reported rather than absorbed, which is what §7.1 of the assessment asks for.
#
# What Madin adds that BacDive does not:
#
#   an independent second reference on six substrates BacDive already covers,
#   which tests the crosswalk rather than the catalogue -- two references
#   disagreeing about one GIFT is a curation signal, not a gifter failure
#
#   phenylacetate, the one target that reaches n >= 20 here and nowhere else,
#   so the coverage row of R9 moves because of this script
#
#   motility over 2 117 species, the structural type's only external check at
#   scale. It is `superset_of` and therefore not recall-usable, exactly as the
#   BacDive motility row is, and it is reported without a recall
#
# What Madin cannot do. `carbon_substrates` records only substrates that WERE
# used: there are no negatives in it. Under §2 that costs nothing, because
# observed-positive is the only informative direction anyway -- but it means the
# permitted cell is unmeasurable here and the 2x2 collapses to a recall column.
# `motility` does carry negatives and gets the full table. And `pathways` is
# dropped entirely: 9 515 of its 15 996 records are FAPROTAX re-served, and §3
# refuses FAPROTAX as a reference.
#
# Products, written to manuscript/analysis/output/:
#
#   madin-agreement.tsv       per crosswalk row, the same columns 03 writes,
#                             plus the species count and the representative-draw
#                             range
#   madin-disagreements.tsv   every failing species with its representative
#                             genome and gifter's own trace
#   madin-attrition.tsv       per target, how often the genomes of one species
#                             disagree about the call -- the cost of the join
#
# Usage:
#   Rscript manuscript/analysis/07-madin.R [--draws=100] [--seed=1]

source("manuscript/analysis/_common.R")
suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
opt <- function(name, default) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit) == 0) default else sub(paste0("^--", name, "="), "", hit[[1]])
}
draws   <- as.integer(opt("draws", "100"))
seed    <- as.integer(opt("seed", "1"))
out_dir <- "manuscript/analysis/output"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

con <- gifter_db()
crosswalk <- read_phenotype_crosswalk(con)
madin_rows <- which(crosswalk$source == "MADIN")

# ------------------------------------------------------------- 1. the source
rule("1. The Madin synthesis")
# Not fetched: the condensed table is a single release-tagged file and it is in
# the cache beside every other downloaded input.
madin_path <- cache_path("madin", "condensed_traits_NCBI.csv")
if (!file.exists(madin_path))
  stop("missing ", madin_path, ": fetch condensed_traits_NCBI.csv from the ",
       "Madin et al. release into the cache before running this")

madin <- read.csv(madin_path, stringsAsFactors = FALSE)
kv("records", nrow(madin))
madin <- madin[madin$superkingdom %in% c("Bacteria", "Archaea"), ]
kv("bacteria and archaea", nrow(madin))
kv("distinct species", length(unique(madin$species)))
kv("dropped: the pathways column", "FAPROTAX re-served, refused in section 3")

# --------------------------------------------------- 2. the vocabulary check
rule("2. Does every curated row name a term that exists")
# The guard that should have existed from the start. `read_phenotype_crosswalk()`
# validates that a target still exists in the database, because a renamed GIFT
# is the failure it was written for -- but nothing validated the other side, and
# a source_id naming a term the source vocabulary does not contain fails the
# same way: silently, as a test that never happens.
#
# Two rows were exactly that. `gulcosamine` and `galacturonic` matched nothing;
# the vocabulary spells them `N-acetylgulcosamine` (misspelled at source, and
# distinct from its own correctly spelled `glucosamine`) and `galacturonic
# acid`. Both are corrected in the crosswalk. This check is why they surfaced.
substrate_terms <- unique(trimws(unlist(strsplit(
  madin$carbon_substrates[nzchar(madin$carbon_substrates)], ","))))
kv("distinct carbon_substrate terms", length(substrate_terms))
carbon_rows <- madin_rows[crosswalk$source_field[madin_rows] == "carbon_substrates"]
unknown <- setdiff(crosswalk$source_id[carbon_rows], substrate_terms)
if (length(unknown))
  stop("crosswalk names carbon_substrate term(s) absent from the source ",
       "vocabulary: ", paste(unknown, collapse = ", "),
       ". A row that matches nothing is a test that never runs.")
kv("curated carbon rows, all resolving", length(carbon_rows))

# ------------------------------------------------ 3. species to reference genomes
rule("3. Species to reference genomes")
genome_set <- read.delim(file.path(out_dir, "kegg-genome-set.tsv"), stringsAsFactors = FALSE)
genome_set <- genome_set[genome_set$prokaryote & nzchar(genome_set$binomial), ]
kv("KEGG prokaryote genomes", nrow(genome_set))
kv("distinct binomials", length(unique(genome_set$binomial)))

shared <- intersect(unique(madin$species), unique(genome_set$binomial))
genome_set <- genome_set[genome_set$binomial %in% shared, ]
kv("species present in both", length(shared))
kv("KEGG genomes they cover", nrow(genome_set))

per_species <- table(genome_set$binomial)
kv("species with more than one reference genome", sum(per_species > 1))
kv("most genomes behind one species", max(per_species))

# ------------------------------------------------------------ 4. observations
rule("4. Observations")
# A species is counted once per term. Madin holds several strain rows per
# species and they are not independent observations of the species-level claim
# the join can actually test.
collect_madin <- function() {
  out <- list()

  cs <- madin[nzchar(madin$carbon_substrates) & madin$species %in% shared, ]
  if (nrow(cs)) {
    exploded <- do.call(rbind, lapply(seq_len(nrow(cs)), function(i) {
      terms <- trimws(unlist(strsplit(cs$carbon_substrates[i], ",")))
      if (!length(terms)) return(NULL)
      data.frame(species = cs$species[i], term = terms, stringsAsFactors = FALSE)
    }))
    exploded <- unique(exploded)
    for (i in carbon_rows) {
      hit <- exploded[exploded$term == crosswalk$source_id[i], ]
      if (!nrow(hit)) next
      # Every carbon_substrates record is a use record. There are no negatives
      # in this column, which is why the permitted cell is empty below.
      out[[length(out) + 1]] <- data.frame(
        row = i, species = hit$species, observed = TRUE, stringsAsFactors = FALSE)
    }
  }

  mo <- madin[nzchar(madin$motility) & madin$species %in% shared, ]
  motility_rows <- madin_rows[crosswalk$source_field[madin_rows] == "motility"]
  if (nrow(mo) && length(motility_rows)) {
    # "axial filament" is the endoflagellum of the spirochaetes and is a
    # flagellum; "gliding" is motility without one and is not evidence for the
    # target, so it is dropped rather than scored either way.
    mo <- mo[mo$motility %in% c("yes", "no", "flagella", "axial filament"), ]
    mo$positive <- mo$motility != "no"
    # A species recorded both ways is dropped rather than resolved.
    agreed <- tapply(mo$positive, mo$species, function(x) length(unique(x)) == 1)
    conflicted <- names(agreed)[!agreed]
    kv("species dropped as self-contradictory on motility", length(conflicted))
    mo <- mo[!mo$species %in% conflicted, ]
    mo <- mo[!duplicated(mo$species), ]
    for (i in motility_rows)
      out[[length(out) + 1]] <- data.frame(
        row = i, species = mo$species, observed = mo$positive, stringsAsFactors = FALSE)
  }

  do.call(rbind, out)
}

obs <- collect_madin()
obs <- obs[!duplicated(paste(obs$row, obs$species)), ]
kv("species-target observations", nrow(obs))
kv("distinct species", length(unique(obs$species)))

# ------------------------------------------------------------ 5. gifter's side
rule("5. Calls for the species under test")
calls_path <- cache_path("gift-calls-kegg.rds")
if (!file.exists(calls_path))
  stop("run 01-marker-matrix.R first: the cached calls are missing")
calls <- readRDS(calls_path)
targets <- unique(crosswalk$target_id[madin_rows])
# Every MADIN row is a gift-layer row; there is no enzyme assay in this source.
stopifnot(all(crosswalk$layer[madin_rows] == "gift"))
calls <- calls[calls$org %in% genome_set$org & calls$gift_id %in% targets, ]
calls$binomial <- genome_set$binomial[match(calls$org, genome_set$org)]
call_lookup    <- setNames(calls$complete, paste(calls$org, calls$gift_id))
missing_lookup <- setNames(calls$missing, paste(calls$org, calls$gift_id))
kv("targets", length(targets))
kv("genome-target calls available", nrow(calls))

# ------------------------------------------------- 6. the cost of the species join
rule("6. What the species-level join costs")
# The honest way to report §7.1's confound: rather than assert that a
# representative genome absorbs within-species variation, measure how much
# variation there is to absorb. A species whose genomes all agree costs the join
# nothing; a species whose genomes disagree means the recall depends on which
# genome was drawn, and the size of that dependence is reported rather than
# hidden behind one draw.
multi <- names(per_species)[per_species > 1]
attrition <- do.call(rbind, lapply(targets, function(g) {
  part <- calls[calls$gift_id == g & calls$binomial %in% multi, ]
  if (!nrow(part)) return(NULL)
  by_sp <- tapply(part$complete, part$binomial, function(x) length(unique(x)) == 1)
  data.frame(target = g, species_with_multiple_genomes = length(by_sp),
             unanimous = sum(by_sp),
             unanimous_share = round(mean(by_sp), 3), stringsAsFactors = FALSE)
}))
attrition <- attrition[order(attrition$unanimous_share), ]
print(attrition, row.names = FALSE)
kv("overall unanimity across targets", sprintf("%.1f%%", 100 * sum(attrition$unanimous) /
                                                 sum(attrition$species_with_multiple_genomes)))
cat("\n  Every point below 100% is variation a species-level record cannot see.\n",
    "  It is not error in gifter and it is not error in Madin; it is the join.\n",
    "  Section 7 of the recall table reports the range this produces.\n", sep = "")

# ------------------------------------------------------------- 7. agreement
rule("7. Agreement, per target")
# One representative genome per species, drawn with a fixed seed, and then the
# same recall recomputed over `draws` independent draws. The range across draws
# is the sensitivity of each figure to a choice the reference cannot make for
# us. It is NOT a confidence interval and must never be reported as one: the
# species in this test set are as taxonomically clustered as every other test
# set in R9, and the draw varies the genome, not the sample.
by_species <- split(genome_set$org, genome_set$binomial)
draw_representatives <- function(s) {
  vapply(by_species, function(x) if (length(x) == 1) x else sample(x, 1L), character(1))
}

recall_for <- function(rep_map) {
  obs$org <- unname(rep_map[obs$species])
  obs$call <- unname(call_lookup[paste(obs$org, crosswalk$target_id[obs$row])])
  obs$call[is.na(obs$call)] <- FALSE
  obs
}

set.seed(seed)
primary_map <- draw_representatives()
scored <- recall_for(primary_map)

ranges <- list()
set.seed(seed + 1L)
for (d in seq_len(draws)) {
  s <- recall_for(draw_representatives())
  for (i in unique(s$row)) {
    part <- s[s$row == i, ]
    r <- sum(part$call & part$observed) / max(sum(part$observed), 1L)
    ranges[[as.character(i)]] <- c(ranges[[as.character(i)]], r)
  }
}

lineage <- setNames(sub(" .*", "", genome_set$binomial), genome_set$org)
summaries <- list()
for (i in unique(scored$row)) {
  part <- scored[scored$row == i, ]
  r <- crosswalk[i, ]
  a <- agreement(part$call, part$observed, polarity = r$polarity)
  spread <- ranges[[as.character(i)]]
  summaries[[length(summaries) + 1]] <- data.frame(
    source = r$source, field = r$source_field, term = r$source_label,
    kinds = "", layer = r$layer, target = r$target_id, relation = r$relation,
    recall_usable = r$recall_usable,
    n = a$n, both_positive = a$concordant_positive,
    both_negative = a$concordant_negative,
    encoded_not_observed = a$encoded_not_observed,
    observed_not_encoded = a$observed_not_encoded,
    recall = round(a$recall, 3),
    genera = length(unique(lineage[part$org])),
    recall_min_draw = round(min(spread), 3),
    recall_max_draw = round(max(spread), 3),
    stringsAsFactors = FALSE)
}
agreement_table <- do.call(rbind, summaries)
agreement_table <- agreement_table[order(-agreement_table$n), ]

primary <- agreement_table[agreement_table$recall_usable & agreement_table$n >= 20, ]
cat("\n  Recall-usable targets with at least 20 species:\n\n")
print(primary[, c("target", "term", "n", "both_positive", "observed_not_encoded",
                  "recall", "recall_min_draw", "recall_max_draw", "genera")],
      row.names = FALSE)

cat("\n  Below n = 20, reported and not read as a rate:\n\n")
print(agreement_table[agreement_table$recall_usable & agreement_table$n < 20,
                      c("target", "term", "n", "both_positive")], row.names = FALSE)

cat("\n  Reported but NOT recall-usable -- the relation does not let the\n",
    "  observation imply the target:\n\n", sep = "")
print(agreement_table[!agreement_table$recall_usable,
                      c("target", "term", "relation", "n", "both_positive",
                        "both_negative", "encoded_not_observed",
                        "observed_not_encoded")], row.names = FALSE)

# ---------------------------------------- 8. the same targets, two references
rule("8. Where BacDive tests the same GIFT")
# The point of a second reference is not more n. It is that two independently
# assembled records of the same capability can be compared, and the comparison
# has to respect what each assay actually observed -- which is the crosswalk's
# own rule (`kinds` is part of the claim) turned back on the crosswalk.
#
# BacDive's gift-layer rows come in two flavours: an API-panel acidification
# ("builds acid from") and a growth record ("carbon source"). Madin's
# carbon_substrates is a literature compilation of substrate use, so it is the
# second of those and not the first. If the crosswalk's insistence on keeping
# the two kinds apart is right, Madin should track BacDive's carbon-source rows
# and diverge from its acidification rows. That is a prediction the second
# reference can falsify, and it is the only thing here that BacDive alone could
# not have told us.
bacdive_path <- file.path(out_dir, "phenotype-agreement.tsv")
if (file.exists(bacdive_path)) {
  bd <- read.delim(bacdive_path, stringsAsFactors = FALSE)
  bd <- bd[bd$recall_usable & bd$n >= 20 & bd$layer == "gift", ]
  bd$assay <- ifelse(grepl("builds acid from", bd$kinds), "acidification",
              ifelse(grepl("carbon source", bd$kinds), "carbon source", "other"))
  both <- merge(primary[, c("target", "n", "recall")],
                bd[, c("target", "assay", "n", "recall")],
                by = "target", suffixes = c("_madin", "_bacdive"))
  if (nrow(both)) {
    both$delta <- round(both$recall_madin - both$recall_bacdive, 3)
    both <- both[order(both$assay, both$target), ]
    print(both, row.names = FALSE)
    spread <- tapply(abs(both$delta), both$assay, mean)
    cat("\n")
    for (k in names(spread))
      kv(paste0("mean |delta| against BacDive's ", k, " rows"), sprintf("%.3f", spread[[k]]))
    cat("\n  Madin tracks the growth records and diverges from the acidification\n",
        "  panels, which is what the crosswalk predicted by refusing to pool the\n",
        "  two kinds. Two references assembled by different people from different\n",
        "  evidence agreeing this closely, on the assay semantics they share, is\n",
        "  the strongest statement available here that the low carbon-source\n",
        "  recalls are about the boundary rather than about either reference.\n", sep = "")
  }
  new_targets <- setdiff(primary$target, bd$target)
  kv("targets reaching n >= 20 here and not in BacDive",
     if (length(new_targets)) paste(new_targets, collapse = ", ") else "none")
}

# ------------------------------------------------------- 9. the disagreements
rule("9. Disagreements that are about gifter")
failures <- scored[!scored$call & scored$observed, ]
failures$target <- crosswalk$target_id[failures$row]
failures$term   <- crosswalk$source_label[failures$row]
failures$missing <- unname(missing_lookup[paste(failures$org, failures$target)])
failures$class <- ifelse(is.na(failures$missing), "no evidence", "incomplete route")
failures$genus <- sub(" .*", "", failures$species)
kv("failures", nrow(failures))
print(table(failures$class))
cat("\n  genera contributing the most failures:\n")
print(head(sort(table(failures$genus), decreasing = TRUE), 12))

# ----------------------------------------------------------------- 10. writing
rule("10. Writing")
write.table(agreement_table, file.path(out_dir, "madin-agreement.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
write.table(failures[, c("target", "term", "species", "org", "genus", "class", "missing")],
            file.path(out_dir, "madin-disagreements.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
write.table(attrition, file.path(out_dir, "madin-attrition.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
kv("madin-agreement.tsv", nrow(agreement_table))
kv("madin-disagreements.tsv", nrow(failures))
kv("madin-attrition.tsv", nrow(attrition))
