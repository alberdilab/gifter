#!/usr/bin/env Rscript
# Probe the candidate genome-phenotype references and regenerate every figure in
# inst/doc/proposal-phenotype-validation.md.
#
# The assessment asks whether gifter can be validated against observed
# phenotypes, and its answer turns entirely on quantities: how many strains
# carry both a genome and a measured phenotype, how many of those observations
# reach a curated GIFT, and how much of the catalogue is left untouched. This
# script measures them, so that a later reader can re-check the assessment
# rather than believe it.
#
# It is a feasibility probe, not a screen. It produces no curation reference
# table and nothing here is admitted as evidence for a call. Two of the four
# resources it measures are refused by the assessment; their numbers are printed
# because a refusal without its evidence is an opinion.
#
# Sources, all probed live:
#
#   BacDive     https://api.bacdive.dsmz.de/v2/fetch/{id}   CC BY 4.0, no auth
#   MediaDive   https://mediadive.dsmz.de/rest/             open
#   Madin       bacteria-archaea-traits condensed_traits_NCBI.csv
#   KEGG        https://rest.kegg.jp/list/genome            academic use
#
# Usage:
#   Rscript data-raw/phenotype_reference_probe.R [--cache=DIR] [--db=PATH]
#           [--bacdive-n=400] [--mediadive-n=12] [--seed=11] [--offline]
#
# Downloads are cached and never committed. Sampling is seeded, so the counts
# quoted in the assessment are reproducible; a different seed moves them by a
# few percent and must not be quoted as if it were the same measurement.

suppressWarnings(suppressMessages({
  library(DBI)
  library(RSQLite)
  library(jsonlite)
}))

args <- commandArgs(trailingOnly = TRUE)
opt <- function(name, default) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit) == 0) default else sub(paste0("^--", name, "="), "", hit[[1]])
}
cache_dir   <- opt("cache", "data-raw/reference/.cache")
db_path     <- opt("db", "inst/extdata/gifter.sqlite")
bacdive_n   <- as.integer(opt("bacdive-n", "400"))
mediadive_n <- as.integer(opt("mediadive-n", "12"))
seed        <- as.integer(opt("seed", "11"))
offline     <- "--offline" %in% args
dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)

`%||%` <- function(a, b) if (is.null(a)) b else a

rule <- function(title) cat("\n", title, "\n", strrep("-", nchar(title)), "\n", sep = "")
kv   <- function(label, value) cat(sprintf("  %-58s %s\n", label, format(value)))

fetch <- function(url, dest, binary = FALSE) {
  path <- file.path(cache_dir, dest)
  if (!file.exists(path)) {
    if (offline) stop("missing from cache and --offline given: ", dest)
    utils::download.file(url, path, quiet = TRUE, mode = if (binary) "wb" else "w")
  }
  path
}

# ---------------------------------------------------------------- the catalogue
# What is there to validate, and how much of it is reachable from KO markers
# alone -- which decides whether the annotation-free KEGG route can carry the
# benchmark (assessment section 7.2).

rule("1. The catalogue under test")
con <- dbConnect(SQLite(), db_path)
on.exit(dbDisconnect(con), add = TRUE)

release <- dbGetQuery(con, "select gifter_db_version, schema_version from database_release")
gifts   <- dbGetQuery(con, "select gift_id, gift_type, mode from gift")
anchors <- dbGetQuery(con, "select anchor_id, chebi_id from anchor")
ecs     <- dbGetQuery(con, "select accession from reaction_xref where namespace = 'EC'")
profile <- dbGetQuery(con, "select gift_id, mode, substrate_class, auxotrophy_indicator from gift_profile")

kv("database", paste0(release$gifter_db_version, ", schema ", release$schema_version))
kv("GIFTs", nrow(gifts))
print(table(gifts$gift_type, gifts$mode, useNA = "ifany"))
kv("anchors carrying a ChEBI identifier",
   sprintf("%d of %d", sum(!is.na(anchors$chebi_id) & anchors$chebi_id != ""), nrow(anchors)))
kv("distinct EC accessions cross-referenced from reactions", length(unique(ecs$accession)))

bounded <- profile[profile$auxotrophy_indicator == 1 & profile$mode == "anabolic", ]
kv("biomass_essential_anabolism members (the bounded frame)", nrow(bounded))
print(table(bounded$substrate_class))

ferment <- dbGetQuery(con, "
  select count(distinct g.gift_id) n from gift g
  join gift_facet gf on gf.gift_pk = g.gift_pk
  where gf.facet = 'physiological_role' and gf.value = 'fermentative_end_product'")
kv("GIFTs facetted as a fermentative end product", ferment$n)

# Evaluate the whole marker vocabulary, then the KO subset of it. A GIFT that
# stays complete in the second pass has a KO-only implementation and is
# reachable from KEGG's own per-genome annotation without running an annotator.
if (requireNamespace("devtools", quietly = TRUE)) {
  suppressMessages(devtools::load_all(".", quiet = TRUE))
  mk <- dbGetQuery(con, "select namespace, accession from marker")
  mk$gene_id <- paste0("probe_gene_", seq_len(nrow(mk)))
  all_call <- evaluate_gifts(mk, max_genes = Inf)$gifts
  ko_call  <- evaluate_gifts(mk[mk$namespace == "KO", ], max_genes = Inf)$gifts
  needs    <- setdiff(all_call$gift_id[all_call$complete], ko_call$gift_id[ko_call$complete])
  kv("GIFTs complete on the full marker vocabulary", sum(all_call$complete))
  kv("GIFTs complete on KO markers alone", sum(ko_call$complete))
  kv("GIFTs requiring a non-KO namespace", paste(needs, collapse = ", "))
}

# ------------------------------------------------------------------- 2. BacDive
# Coverage is the whole question: a strain is only usable when it carries both a
# genome and an observation. Sampling is the only way to measure that, because
# the API answers per strain.

rule("2. BacDive")
set.seed(seed)
ids <- sample.int(180000L, bacdive_n)
as_list <- function(x) if (is.null(x)) list() else if (is.data.frame(x)) split(x, seq_len(nrow(x))) else if (is.list(x) && !is.null(names(x))) list(x) else x

records <- list()
for (id in ids) {
  path <- file.path(cache_dir, "bacdive", paste0(id, ".json"))
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  if (!file.exists(path)) {
    if (offline) next
    ok <- tryCatch({
      utils::download.file(sprintf("https://api.bacdive.dsmz.de/v2/fetch/%d", id),
                           path, quiet = TRUE)
      TRUE
    }, error = function(e) FALSE)
    if (!ok) next
  }
  parsed <- tryCatch(fromJSON(path, simplifyVector = FALSE), error = function(e) NULL)
  res <- parsed$results
  if (length(res)) records[[length(records) + 1]] <- res[[1]]
}

has_field <- function(rec, section, field) !is.null(rec[[section]][[field]])
n_valid   <- length(records)
n_genome  <- sum(vapply(records, has_field, logical(1), "Sequence information", "Genome sequences"))
n_pheno   <- sum(vapply(records, function(r)
  has_field(r, "Physiology and metabolism", "metabolite utilization") ||
  has_field(r, "Physiology and metabolism", "metabolite production"), logical(1)))
n_enzyme  <- sum(vapply(records, has_field, logical(1), "Physiology and metabolism", "enzymes"))
n_both    <- sum(vapply(records, function(r)
  has_field(r, "Sequence information", "Genome sequences") &&
  (has_field(r, "Physiology and metabolism", "metabolite utilization") ||
   has_field(r, "Physiology and metabolism", "metabolite production") ||
   has_field(r, "Physiology and metabolism", "enzymes")), logical(1)))

kv("IDs sampled", bacdive_n)
kv("valid records", n_valid)
kv("with a linked genome", sprintf("%d (%.0f%%)", n_genome, 100 * n_genome / max(n_valid, 1)))
kv("with metabolite utilisation or production", sprintf("%d (%.0f%%)", n_pheno, 100 * n_pheno / max(n_valid, 1)))
kv("with enzyme activities", sprintf("%d (%.0f%%)", n_enzyme, 100 * n_enzyme / max(n_valid, 1)))
n_motile <- sum(vapply(records, function(r) {
  rows <- as_list(r[["Morphology"]][["cell morphology"]])
  has_field(r, "Sequence information", "Genome sequences") &&
    any(vapply(rows, function(x) !is.null(x$motility), logical(1)), na.rm = TRUE)
}, logical(1)))
kv("with a genome AND phenotype data", sprintf("%d (%.1f%%)", n_both, 100 * n_both / max(n_valid, 1)))
kv("with a genome AND a motility call", sprintf("%d (%.1f%%)", n_motile, 100 * n_motile / max(n_valid, 1)))
kv("implied strains in the database (valid IDs x sampled share)",
   sprintf("~%s", format(round(180000 * n_valid / bacdive_n, -3), big.mark = " ")))
kv("implied genome-backed phenotyped strains",
   sprintf("~%s", format(round(180000 * n_both / bacdive_n, -3), big.mark = " ")))

collect <- function(section, field, pick) {
  out <- list()
  for (r in records) {
    rows <- as_list(r[[section]][[field]])
    genome <- has_field(r, "Sequence information", "Genome sequences")
    for (row in rows) {
      value <- pick(row)
      if (!is.null(value) && !is.na(value)) out[[length(out) + 1]] <- list(value = value, genome = genome)
    }
  }
  out
}
tally <- function(rows) {
  if (!length(rows)) return(data.frame())
  v <- vapply(rows, function(x) as.character(x$value), character(1))
  g <- vapply(rows, function(x) isTRUE(x$genome), logical(1))
  frame <- data.frame(v = v, records = 1L, genome_backed = as.integer(g))
  d <- aggregate(cbind(records, genome_backed) ~ v, frame, sum)
  d[order(-d$records), ]
}

mets  <- tally(collect("Physiology and metabolism", "metabolite utilization", function(x) x$metabolite))
kinds <- tally(collect("Physiology and metabolism", "metabolite utilization", function(x) x[["kind of utilization tested"]]))
prod  <- tally(collect("Physiology and metabolism", "metabolite production", function(x) x$metabolite))
enz   <- tally(collect("Physiology and metabolism", "enzymes", function(x) x$ec))

cat("\n  kind of utilisation tested:\n"); print(utils::head(kinds, 12), row.names = FALSE)
cat("\n  most-recorded metabolites (genome_backed = strains that also have a genome):\n")
print(utils::head(mets, 25), row.names = FALSE)
cat("\n  metabolite production:\n"); print(utils::head(prod, 10), row.names = FALSE)

# Which observed EC activities land on a reaction gifter curates. This is the
# component-layer test set, and it needs no phenotype caveat: an enzyme assay
# is an observation about an enzyme.
if (nrow(enz)) {
  hit <- dbGetQuery(con, sprintf("
    select distinct rx.accession ec, g.gift_id
    from reaction_xref rx
    join reaction r on r.reaction_pk = rx.reaction_pk
    join route_reaction rr on rr.reaction_pk = r.reaction_pk
    join gift_route gr on gr.route_pk = rr.route_pk
    join gift g on g.gift_pk = gr.gift_pk
    where rx.namespace = 'EC' and rx.accession in (%s)",
    paste(sprintf("'%s'", unique(enz$v)), collapse = ", ")))
  cat("\n  observed EC activities that reach a curated GIFT:\n")
  print(merge(hit, enz, by.x = "ec", by.y = "v")[, c("ec", "gift_id", "records", "genome_backed")],
        row.names = FALSE)
  kv("observed EC activities with no curated reaction", length(setdiff(enz$v, hit$ec)))
}

# The metabolite join is not ChEBI equality: gifter anchors are Rhea-style
# charged species and BacDive records parent neutral terms.
chebi_seen <- unique(unlist(lapply(records, function(r)
  vapply(as_list(r[["Physiology and metabolism"]][["metabolite utilization"]]),
         function(x) as.character(x[["Chebi-ID"]] %||% NA), character(1)))))
anchor_chebi <- sub("CHEBI:", "", anchors$chebi_id)
matched <- intersect(chebi_seen, anchor_chebi)
kv("sampled metabolite ChEBI identifiers", length(chebi_seen))
kv("of those matching an anchor ChEBI exactly", length(matched))
if (length(matched)) {
  named <- anchors$anchor_id[match(matched, anchor_chebi)]
  cat("    matched anchors:", paste(sort(named), collapse = ", "), "\n")
}

# ----------------------------------------------------------------- 3. MediaDive
# The only resource that reaches the anabolic half. What matters is how many
# media are chemically defined, and how many strains each defined medium links.

rule("3. MediaDive")
media <- fromJSON(fetch("https://mediadive.dsmz.de/rest/media", "mediadive-media.json"))$data
kv("media", nrow(media))
kv("chemically defined (complex_medium == 0)", sum(media$complex_medium == 0))

defined <- media[media$complex_medium == 0, ]
set.seed(1)
samp <- defined[sample.int(nrow(defined), min(mediadive_n, nrow(defined))), ]
links <- 0
resolvable <- 0
for (id in samp$id) {
  path <- file.path(cache_dir, "mediadive", paste0(id, ".json"))
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  if (!file.exists(path)) {
    if (offline) next
    tryCatch(utils::download.file(
      sprintf("https://mediadive.dsmz.de/rest/medium-strains/%s", id), path, quiet = TRUE),
      error = function(e) NULL)
  }
  if (!file.exists(path)) next
  n <- tryCatch(fromJSON(path)$count, error = function(e) 0)
  resolvable <- resolvable + 1
  links <- links + (if (is.null(n)) 0 else n)
}
kv("sampled defined media with a medium-strains endpoint",
   sprintf("%d of %d", resolvable, nrow(samp)))
kv("strain links across those media", links)
if (resolvable) kv("projected strain links over all defined media",
                   sprintf("~%d", round(sum(media$complex_medium == 0) * links / resolvable)))

# --------------------------------------------------------------- 4. Madin, KEGG
# Two axes survive the assessment -- motility and carbon substrates -- and both
# need a genome. KEGG's genome list is the cheapest source of one.

rule("4. Madin et al., joined to KEGG genomes")
madin <- read.csv(fetch(paste0("https://raw.githubusercontent.com/bacteria-archaea-traits/",
                               "bacteria-archaea-traits/master/output/condensed_traits_NCBI.csv"),
                        "madin-condensed-traits.csv"), stringsAsFactors = FALSE)
madin <- madin[madin$superkingdom %in% c("Bacteria", "Archaea"), ]
kv("records", nrow(madin))
kv("species", length(unique(madin$species)))
for (column in c("carbon_substrates", "pathways", "motility", "metabolism")) {
  filled <- madin[[column]] != "" & !is.na(madin[[column]])
  kv(sprintf("%s: records / species", column),
     sprintf("%d / %d", sum(filled), length(unique(madin$species[filled]))))
}
cat("\n  pathways by upstream source (the FAPROTAX share is why the column is dropped):\n")
print(sort(table(madin$data_source[madin$pathways != ""]), decreasing = TRUE))

kegg <- readLines(fetch("https://rest.kegg.jp/list/genome", "kegg-genome-list.tsv"))
name <- sub(" [(].*", "", sub("^[^\t]+\t[a-z0-9]+; ", "", kegg))
binomial <- vapply(strsplit(name, " "), function(x) paste(x[1:2], collapse = " "), character(1))
shared <- intersect(unique(binomial), unique(madin$species))
kv("KEGG genome entries", length(kegg))
kv("distinct KEGG binomials", length(unique(binomial)))
kv("species shared with Madin", length(shared))
kv("KEGG genomes falling in shared species", sum(binomial %in% shared))

substrate_species <- function(pattern) {
  hit <- madin[grepl(pattern, madin$carbon_substrates, fixed = TRUE), ]
  length(unique(hit$species[hit$species %in% shared]))
}
# "gulcosamine" is misspelled at source; matching the spelling in the data is
# deliberate, and correcting it silently would drop 129 species.
terms <- c("arabinose", "galactose", "xylose", "gulcosamine", "citrate", "rhamnose",
           "glycogen", "dextrin", "fucose", "histidine", "phenylacetate",
           "galacturonic", "trimethylamine", "methylamine", "urea", "tryptophan",
           "glucose", "maltose", "sucrose", "lactose", "cellobiose", "trehalose", "mannitol")
counts <- data.frame(substrate = terms,
                     genome_backed_species = vapply(terms, substrate_species, integer(1)))
cat("\n  substrate terms, species with a KEGG genome behind them:\n")
print(counts[order(-counts$genome_backed_species), ], row.names = FALSE)

motile <- madin[madin$motility != "" & madin$species %in% shared, ]
kv("species with a motility call and a KEGG genome", length(unique(motile$species)))

rule("Done")
cat("Every figure in inst/doc/proposal-phenotype-validation.md is above.\n",
    "Seed ", seed, ", BacDive sample ", bacdive_n, ".\n", sep = "")
