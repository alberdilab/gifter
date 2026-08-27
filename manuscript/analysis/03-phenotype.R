#!/usr/bin/env Rscript
# R9: agreement between gifter calls and observed phenotypes.
#
# The design is argued in inst/doc/proposal-phenotype-validation.md and is not
# an accuracy benchmark. Under invariant 15 a positive call is a necessary, not
# sufficient, condition for a phenotype, so the two disagreements mean different
# things: an organism that encodes a capability but does not show it is
# permitted, while an organism that shows one its genome does not encode is a
# failure of the model. Only the second cell is a result about gifter, and the
# statistic that reads it is recall against observed positives. There is no
# accuracy, precision, F1 or AUC here, and agreement() will not compute one.
#
# Three things are reported for every target, and the third is the point:
#
#   the two-by-two, with the permitted cell labelled as permitted
#   recall, with its denominator and the taxonomic spread of the test set
#   the disagreements, classified by gifter's own trace
#
# Two layers are tested, because BacDive reaches two. An EC-resolved enzyme
# assay is an observation about a curated reaction and needs no phenotype
# caveat; a substrate-use record is an observation about a GIFT and needs the
# whole argument above. tryptophan_degradation_indole is testable both ways
# against independent observations, which is what bounds the reference itself.
#
# Depends on 01-marker-matrix.R having produced the genome set and the cached
# calls. The auxotrophy half of R9 -- MediaDive defined media against the
# bounded anabolic frames, where the polarity inverts and a positive call
# becomes falsifiable -- is not here; it is 04-auxotrophy.R and it is the
# remaining piece.
#
# Usage:
#   Rscript manuscript/analysis/03-phenotype.R [--bacdive-max=180000]

source("manuscript/analysis/_common.R")
suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
opt <- function(name, default) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit) == 0) default else sub(paste0("^--", name, "="), "", hit[[1]])
}
bacdive_max <- as.integer(opt("bacdive-max", "180000"))
out_dir <- "manuscript/analysis/output"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

con <- gifter_db()
crosswalk <- read_phenotype_crosswalk(con)
alias     <- read_chebi_aliases()

# --------------------------------------------------------------- 1. the inputs
rule("1. Inputs")
genome_set <- read.delim(file.path(out_dir, "kegg-genome-set.tsv"), stringsAsFactors = FALSE)
calls_path <- cache_path("gift-calls-kegg.rds")
if (!file.exists(calls_path))
  stop("run 01-marker-matrix.R first: the cached calls are missing")
calls <- readRDS(calls_path)
genome_set$assembly_base <- sub("[.].*", "", genome_set$assembly)

kv("genomes in the reference set", nrow(genome_set))
kv("cached calls", nrow(calls))
kv("crosswalk rows", nrow(crosswalk))
kv("of those usable for recall", sum(crosswalk$recall_usable))

# ------------------------------------------------------------ 2. BacDive sweep
rule("2. BacDive")
observed <- bacdive_reduce(seq_len(bacdive_max), list(
  assemblies  = bd_assemblies,
  utilisation = bd_utilisation,
  production  = bd_production,
  enzymes     = bd_enzymes,
  motility    = bd_motility))
kv("records read", attr(observed, "records"))
for (n in names(observed)) kv(paste0("  ", n, " rows"), nrow(observed[[n]]))

# ------------------------------------------------------- 3. strains to genomes
rule("3. Strain to genome")
assemblies <- observed$assemblies
assemblies <- assemblies[!is.na(assemblies$assembly), ]
assemblies$assembly_base <- sub("[.].*", "", assemblies$assembly)
# Keep the best-scoring assembly per strain, and refuse a pairing where one
# genome is claimed by more than one strain: a silent many-to-one would make a
# single genome answer for several organisms' phenotypes.
assemblies <- assemblies[order(assemblies$bacdive_id, -assemblies$score), ]
assemblies <- assemblies[!duplicated(assemblies$bacdive_id), ]
joined <- merge(assemblies, genome_set[, c("org", "assembly_base", "binomial", "name")],
                by = "assembly_base")
ambiguous <- unique(joined$org[duplicated(joined$org)])
joined <- joined[!joined$org %in% ambiguous, ]
kv("strains with an assembly", nrow(assemblies))
kv("matched to a reference genome", nrow(joined))
kv("dropped as ambiguous", length(ambiguous))

strain_genome <- setNames(joined$org, joined$bacdive_id)
lineage <- setNames(sub(" .*", "", joined$binomial), joined$org)

# --------------------------------------------------- 4. observations to targets
# One row per (strain, crosswalk row): what was observed, and what gifter says
# about the thing the crosswalk points at.
rule("4. Matching observations to crosswalk targets")

as_logical_activity <- function(x) ifelse(x == "+", TRUE, ifelse(x == "-", FALSE, NA))

collect_observations <- function() {
  out <- list()

  metabolite <- function(rows, field, has_kinds) {
    if (!nrow(rows)) return(NULL)
    rows$anchor <- resolve_chebi(alias, rows$chebi_id)
    rows
  }

  # metabolite utilisation: the kind of test is part of the claim, so a row
  # matches only when the recorded kind is one the crosswalk row accepts.
  u <- observed$utilisation
  if (nrow(u)) {
    u$observed <- as_logical_activity(u$activity)
    u <- u[!is.na(u$observed), ]
    u$chebi_full <- paste0("CHEBI:", u$chebi)
    for (i in which(crosswalk$source_field == "metabolite utilization")) {
      r <- crosswalk[i, ]
      hit <- u[u$chebi_full == r$source_id & u$kind %in% r$kinds[[1]], ]
      if (!nrow(hit)) next
      out[[length(out) + 1]] <- data.frame(
        row = i, source = "BACDIVE", layer = r$layer, target = r$target_id,
        relation = r$relation, bacdive_id = hit$bacdive_id,
        observed = hit$observed, stringsAsFactors = FALSE)
    }
  }

  p <- observed$production
  if (nrow(p)) {
    p$observed <- p$produced %in% c("yes", "+")
    p$chebi_full <- paste0("CHEBI:", p$chebi)
    for (i in which(crosswalk$source_field == "metabolite production")) {
      r <- crosswalk[i, ]
      hit <- p[p$chebi_full == r$source_id, ]
      if (!nrow(hit)) next
      out[[length(out) + 1]] <- data.frame(
        row = i, source = "BACDIVE", layer = r$layer, target = r$target_id,
        relation = r$relation, bacdive_id = hit$bacdive_id,
        observed = hit$observed, stringsAsFactors = FALSE)
    }
  }

  e <- observed$enzymes
  if (nrow(e)) {
    e$observed <- as_logical_activity(e$activity)
    e <- e[!is.na(e$observed) & !is.na(e$ec), ]
    for (i in which(crosswalk$source_field == "enzymes")) {
      r <- crosswalk[i, ]
      hit <- e[paste0("EC:", e$ec) == r$source_id, ]
      if (!nrow(hit)) next
      out[[length(out) + 1]] <- data.frame(
        row = i, source = "BACDIVE", layer = r$layer, target = r$target_id,
        relation = r$relation, bacdive_id = hit$bacdive_id,
        observed = hit$observed, stringsAsFactors = FALSE)
    }
  }

  m <- observed$motility
  if (nrow(m)) {
    m$observed <- m$motility %in% c("yes", "flagella")
    for (i in which(crosswalk$source_field == "cell morphology")) {
      r <- crosswalk[i, ]
      out[[length(out) + 1]] <- data.frame(
        row = i, source = "BACDIVE", layer = r$layer, target = r$target_id,
        relation = r$relation, bacdive_id = m$bacdive_id,
        observed = m$observed, stringsAsFactors = FALSE)
    }
  }

  do.call(rbind, out)
}

obs <- collect_observations()
obs$org <- unname(strain_genome[obs$bacdive_id])
obs <- obs[!is.na(obs$org), ]
# A strain contributing two contradictory records for one target is dropped
# rather than resolved: nothing here is entitled to pick the convenient one.
key <- paste(obs$row, obs$org)
conflicted <- unique(key[duplicated(key) & !duplicated(paste(key, obs$observed))])
obs <- obs[!key %in% conflicted, ]
obs <- obs[!duplicated(paste(obs$row, obs$org)), ]
kv("strain-target observations with a genome", nrow(obs))
kv("dropped as self-contradictory", length(conflicted))

# ------------------------------------------------------------ 5. gifter's side
rule("5. Calls for the test set")
test_orgs <- sort(unique(obs$org))
kv("genomes under test", length(test_orgs))

gift_call <- calls[calls$org %in% test_orgs, ]
gift_lookup <- setNames(gift_call$complete, paste(gift_call$org, gift_call$gift_id))
missing_lookup <- setNames(gift_call$missing, paste(gift_call$org, gift_call$gift_id))

# The reaction layer needs reaction support, not the GIFT call above it: an
# enzyme assay is evidence about one reaction, and reading it against the whole
# GIFT would fail every strain whose route is incomplete elsewhere.
reaction_targets <- unique(obs$target[obs$layer == "reaction"])
reaction_lookup <- character(0)
if (length(reaction_targets)) {
  kos <- dbGetQuery(con, "select distinct m.accession from marker m where m.namespace = 'KO'")$accession
  annotation <- kegg_annotation_table(kos)
  annotation <- annotation[annotation$genome_id %in% test_orgs, ]
  parts <- list()
  chunks <- split(test_orgs, ceiling(seq_along(test_orgs) / 250))
  for (i in seq_along(chunks)) {
    for (g in chunks[[i]]) {
      rows <- annotation[annotation$genome_id == g, ]
      if (!nrow(rows)) next
      res <- evaluate_reactions(rows[, c("namespace", "accession")])$reactions
      res <- res[res$reaction_id %in% reaction_targets, ]
      if (nrow(res)) parts[[length(parts) + 1]] <-
        data.frame(org = g, reaction_id = res$reaction_id,
                   supported = res$supported, stringsAsFactors = FALSE)
    }
    message("  reaction chunk ", i, "/", length(chunks))
  }
  rx <- do.call(rbind, parts)
  reaction_lookup <- setNames(rx$supported, paste(rx$org, rx$reaction_id))
}

obs$call <- ifelse(obs$layer == "reaction",
                   reaction_lookup[paste(obs$org, obs$target)],
                   gift_lookup[paste(obs$org, obs$target)])
# A genome absent from a lookup carries no evidence for that target, which is an
# unsupported call rather than a missing one.
obs$call[is.na(obs$call)] <- FALSE
obs$call <- as.logical(obs$call)

# -------------------------------------------------------------- 6. agreement
rule("6. Agreement, per target")
summaries <- list()
for (i in unique(obs$row)) {
  part <- obs[obs$row == i, ]
  r <- crosswalk[i, ]
  a <- agreement(part$call, part$observed, polarity = r$polarity)
  genera <- length(unique(lineage[part$org]))
  summaries[[length(summaries) + 1]] <- data.frame(
    source = r$source, field = r$source_field, term = r$source_label,
    kinds = paste(r$kinds[[1]], collapse = ";"),
    layer = r$layer, target = r$target_id, relation = r$relation,
    recall_usable = r$recall_usable,
    n = a$n, both_positive = a$concordant_positive,
    both_negative = a$concordant_negative,
    encoded_not_observed = a$encoded_not_observed,
    observed_not_encoded = a$observed_not_encoded,
    recall = round(a$recall, 3), genera = genera,
    stringsAsFactors = FALSE)
}
agreement_table <- do.call(rbind, summaries)
agreement_table <- agreement_table[order(-agreement_table$n), ]

primary <- agreement_table[agreement_table$recall_usable & agreement_table$n >= 20, ]
cat("\n  Recall-usable targets with at least 20 paired observations:\n\n")
print(primary[, c("target", "layer", "term", "n", "both_positive",
                  "observed_not_encoded", "recall", "genera")], row.names = FALSE)

cat("\n  Reported but NOT recall-usable -- the relation does not let the\n",
    "  observation imply the target. Shown so the mapping stays visible:\n\n", sep = "")
print(agreement_table[!agreement_table$recall_usable,
                      c("target", "term", "relation", "n")], row.names = FALSE)

# ------------------------------------------------------- 7. the disagreements
rule("7. Disagreements that are about gifter")
failures <- obs[!obs$call & obs$observed, ]
failures$target_term <- crosswalk$source_label[failures$row]
failures$binomial <- joined$binomial[match(failures$bacdive_id, joined$bacdive_id)]
failures$genus <- sub(" .*", "", failures$binomial)
failures$missing <- missing_lookup[paste(failures$org, failures$target)]
# Two classes, and they mean different things: a genome with no evidence at all
# may be an annotation gap or a real negative deposit, while a genome that has
# markers and still fails names the step that failed.
failures$class <- ifelse(is.na(failures$missing), "no evidence", "incomplete route")
kv("failures", nrow(failures))
print(table(failures$class))
cat("\n  genera contributing the most failures:\n")
print(head(sort(table(failures$genus), decreasing = TRUE), 12))

# ---------------------------------------------------------------- 8. coverage
rule("8. Coverage of the catalogue")
gifts <- dbGetQuery(con, "select gift_id, gift_type from gift")
# A reaction-layer test is still a test of the GIFT that reaction belongs to,
# so counting only layer == "gift" would undercount the catalogue's coverage.
usable <- agreement_table[agreement_table$recall_usable & agreement_table$n >= 20, ]
via_reaction <- dbGetQuery(con, "
  select distinct r.reaction_id, g.gift_id from reaction r
  join route_reaction rr on rr.reaction_pk = r.reaction_pk
  join gift_route gr on gr.route_pk = rr.route_pk
  join gift g on g.gift_pk = gr.gift_pk")
tested <- unique(c(usable$target[usable$layer == "gift"],
                   via_reaction$gift_id[via_reaction$reaction_id %in%
                                          usable$target[usable$layer == "reaction"]]))
frame_only <- dbGetQuery(con, "select gift_id from gift_profile
                               where auxotrophy_indicator = 1 and mode = 'anabolic'")$gift_id
frame_only <- setdiff(frame_only, tested)
untested <- setdiff(gifts$gift_id, c(tested, frame_only))
kv("individually tested here", sprintf("%d (%.0f%%)", length(tested), 100 * length(tested) / nrow(gifts)))
kv("testable only as a bounded-frame aggregate", sprintf("%d (%.0f%%)", length(frame_only),
   100 * length(frame_only) / nrow(gifts)))
kv("no phenotype reference of any kind", sprintf("%d (%.0f%%)", length(untested),
   100 * length(untested) / nrow(gifts)))
cat("\n  The third row is not a gap to close by finding another database. It is\n",
    "  the aromatic and amino-acid catabolic layers, the cofactor interior, and\n",
    "  every regulatory and defense GIFT. R9 states it rather than hiding it.\n", sep = "")

# ----------------------------------------------------------------- 9. outputs
rule("9. Writing")
write.table(agreement_table, file.path(out_dir, "phenotype-agreement.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
write.table(failures[, c("source", "target", "target_term", "org", "binomial",
                         "class", "missing")],
            file.path(out_dir, "phenotype-disagreements.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
kv("phenotype-agreement.tsv", nrow(agreement_table))
kv("phenotype-disagreements.tsv", nrow(failures))
