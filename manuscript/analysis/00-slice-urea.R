#!/usr/bin/env Rscript
# R9 vertical slice: urea_hydrolysis, end to end, on one capability.
#
# The point of a slice is to find out whether the three joins hold before
# spending curation on a crosswalk that assumes they do. urea_hydrolysis is the
# candidate that exercises all of them at once:
#
#   * BacDive records urea utilisation with ChEBI:16199, which is one of the few
#     metabolites whose identifier matches a gifter anchor outright -- so this
#     slice tests the join without also testing the anomer bridge that the sugar
#     substrates will need;
#   * BacDive separately records urease activity as EC 3.5.1.5, which gifter
#     cross-references on RHEA:20557, so the same GIFT is testable at two layers
#     against two independent observations;
#   * the Madin synthesis records urea as a carbon substrate, giving a second,
#     species-level reference to compare the strain-level one against;
#   * the route is one reaction over a three-component urease, with K14048
#     covering two of the components as a fused protein -- so a correct call
#     exercises AND across components and OR across alternative markers.
#
# What this script does NOT do is decide anything. It reports the two-by-two of
# section 2 with the asymmetric labels intact, and lists every disagreement with
# gifter's own trace attached, because the classification of the failures is the
# result and the ratio is only its summary.
#
# Usage:
#   Rscript manuscript/analysis/00-slice-urea.R [--bacdive-max=20000]
#           [--kegg-metadata=all|N] [--offline]
#
# First run fetches roughly 1 400 requests and takes about ten minutes; the KEGG
# genome metadata is the bulk of it and is reused by R7 and R8.

source("manuscript/analysis/_common.R")
suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
opt <- function(name, default) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit) == 0) default else sub(paste0("^--", name, "="), "", hit[[1]])
}
bacdive_max   <- as.integer(opt("bacdive-max", "20000"))
kegg_metadata <- opt("kegg-metadata", "all")

GIFT      <- "urea_hydrolysis"
UREA      <- "16199"      # ChEBI, as BacDive records it and as the anchor holds it
UREASE_EC <- "3.5.1.5"

con <- gifter_db()

# ----------------------------------------------------------- 1. what is claimed
rule("1. The capability under test")
markers <- gift_markers(con, GIFT)
kos <- unique(markers$accession[markers$namespace == "KO"])
kv("GIFT", GIFT)
kv("components", length(unique(markers$component_id)))
kv("KO markers", paste(kos, collapse = ", "))
anchor <- dbGetQuery(con, "
  select a.anchor_id, a.chebi_id, ga.role from gift g
  join gift_anchor ga on ga.gift_pk = g.gift_pk
  join anchor a on a.anchor_pk = ga.anchor_pk
  where g.gift_id = :g", params = list(g = GIFT))
print(anchor, row.names = FALSE)

# ------------------------------------------------------- 2. the marker evidence
rule("2. Marker evidence over KEGG genomes")
genomes <- kegg_genome_list()
kv("KEGG genome entries", nrow(genomes))

annotation <- kegg_annotation_table(kos)
kv("genomes carrying at least one urease marker", length(unique(annotation$genome_id)))

# Evaluation is deferred until the test set is known. Calling every KEGG genome
# would evaluate the whole 153-GIFT catalogue thousands of times to answer a
# question about one capability in a few hundred organisms; the test set is
# always small relative to the genome collection, and building it first is what
# keeps a slice iterable.

# ------------------------------------------------------- 3. the genome ↔ strain join
rule("3. Joining KEGG genomes to BacDive strains")
tnumbers <- if (identical(kegg_metadata, "all")) genomes$tnumber else
  head(genomes$tnumber, as.integer(kegg_metadata))
meta <- kegg_genome_metadata(tnumbers)
kv("KEGG genomes with an assembly accession", sum(!is.na(meta$assembly)))
meta <- merge(meta, genomes[, c("tnumber", "org", "binomial")], by = "tnumber")

# One pass over the sweep, keeping rows rather than records: holding 100 000
# parsed BacDive records in memory kills the session well before the sweep ends.
observed <- bacdive_reduce(seq_len(bacdive_max), list(
  assemblies  = bd_assemblies,
  utilisation = bd_utilisation,
  enzymes     = bd_enzymes))
kv("BacDive records read", attr(observed, "records"))

assemblies <- observed$assemblies
if (!nrow(assemblies)) stop("no BacDive assemblies fetched -- check the cache")
assemblies <- assemblies[!is.na(assemblies$assembly), ]
assemblies$assembly_base <- sub("[.].*", "", assemblies$assembly)
kv("strains with a genome assembly", length(unique(assemblies$bacdive_id)))

# One strain can list several assemblies and one assembly can be listed by
# several strains. Keep the best-scoring assembly per strain, and refuse to
# invent a pairing where a genome is claimed by more than one strain.
assemblies <- assemblies[order(assemblies$bacdive_id, -assemblies$score), ]
assemblies <- assemblies[!duplicated(assemblies$bacdive_id), ]

joined <- merge(assemblies, meta[, c("org", "assembly_base", "binomial")],
                by = "assembly_base")
ambiguous <- joined$org[duplicated(joined$org)]
joined <- joined[!joined$org %in% ambiguous, ]
kv("strains matched to a KEGG genome by assembly", nrow(joined))
kv("dropped as an ambiguous genome-strain pairing", length(ambiguous))

rule("3b. Evaluating the test set")
test_orgs <- unique(joined$org)
subset <- annotation[annotation$genome_id %in% test_orgs, ]
kv("genomes in the test set", length(test_orgs))
kv("of those, carrying at least one urease marker", length(unique(subset$genome_id)))

calls <- data.frame()
if (nrow(subset)) {
  # Single-threaded on purpose. evaluate_gifts_community() parallelises by
  # forking, and a child that inherits this script's open SQLite handle aborts
  # the session outright -- silently, with no traceback. The test set is a few
  # hundred genomes, so the parallelism buys a minute and costs a crash.
  community <- evaluate_gifts_community(subset, genome_id = "genome_id",
                                        gene_id = "gene_id", max_genes = Inf,
                                        workers = 1L)
  calls <- do.call(rbind, lapply(names(community$results), function(g) {
    row <- community$results[[g]]$gifts
    row <- row[row$gift_id == GIFT, ]
    if (!nrow(row)) return(NULL)
    # missing_reactions_best_route is a list column and is empty for a complete
    # call, so it is flattened rather than indexed.
    gone <- row$missing_reactions_best_route[[1]]
    data.frame(org = g, complete = row$complete,
               confidence = row$evidence_confidence,
               missing = row$minimum_missing_requirements,
               missing_reactions = if (length(gone)) paste(gone, collapse = "; ") else "",
               stringsAsFactors = FALSE)
  }))
}

# A test genome carrying none of the markers is called unsupported without being
# evaluated. That is not a shortcut: with no marker there is no evidence path,
# and materialising the negative is what keeps the denominator honest.
call_of <- setNames(rep(FALSE, length(test_orgs)), test_orgs)
if (nrow(calls)) call_of[calls$org] <- calls$complete
kv("called supported", sum(call_of))
kv("called unsupported", sum(!call_of))

# ----------------------------------------------- 4. layer one: the GIFT call
rule("4. GIFT layer -- urea utilisation against the call")
util <- observed$utilisation
util <- util[!is.na(util$chebi) & util$chebi == UREA, ]
kv("urea utilisation records", nrow(util))
if (nrow(util)) print(table(util$kind, util$activity, useNA = "ifany"))

# "+/-" is a recorded ambiguity, not a weak positive, and is dropped rather than
# rounded. Rounding it in either direction would manufacture agreement.
util <- util[util$activity %in% c("+", "-"), ]
util$observed <- util$activity == "+"
util <- unique(util[, c("bacdive_id", "observed")])
conflict <- util$bacdive_id[duplicated(util$bacdive_id)]
util <- util[!util$bacdive_id %in% conflict, ]
kv("strains with an unambiguous urea observation", nrow(util))
kv("dropped for contradicting themselves across references", length(unique(conflict)))

gift_layer <- merge(util, joined[, c("bacdive_id", "org", "binomial")], by = "bacdive_id")
gift_layer$call <- unname(call_of[gift_layer$org])
kv("strains with both a call and an observation", nrow(gift_layer))

if (nrow(gift_layer)) {
  cat("\n")
  print(agreement(gift_layer$call, gift_layer$observed, polarity = "necessary"))
  failures <- gift_layer[!gift_layer$call & gift_layer$observed, ]
  if (nrow(failures)) {
    cat("\n  observed, not encoded -- the rows that are about gifter:\n")
    failures <- merge(failures, calls[, c("org", "missing", "missing_reactions")],
                      by = "org", all.x = TRUE)
    print(failures[, c("org", "binomial", "missing", "missing_reactions")], row.names = FALSE)
  }
}

# ------------------------------------------- 5. layer two: the reaction call
rule("5. Reaction layer -- urease activity against the same call")
enz <- observed$enzymes
enz <- enz[!is.na(enz$ec) & enz$ec == UREASE_EC & enz$activity %in% c("+", "-"), ]
enz$observed <- enz$activity == "+"
enz <- unique(enz[, c("bacdive_id", "observed")])
enz <- enz[!enz$bacdive_id %in% enz$bacdive_id[duplicated(enz$bacdive_id)], ]
kv("strains with an unambiguous urease assay", nrow(enz))

enzyme_layer <- merge(enz, joined[, c("bacdive_id", "org", "binomial")], by = "bacdive_id")
enzyme_layer$call <- unname(call_of[enzyme_layer$org])
kv("strains with both a call and an assay", nrow(enzyme_layer))
if (nrow(enzyme_layer)) {
  cat("\n")
  print(agreement(enzyme_layer$call, enzyme_layer$observed, polarity = "necessary"))
}

both <- merge(gift_layer[, c("org", "observed")], enzyme_layer[, c("org", "observed")],
              by = "org", suffixes = c("_utilisation", "_enzyme"))
if (nrow(both)) {
  rule("5b. Do the two observations agree with each other?")
  kv("strains carrying both observations", nrow(both))
  print(table(utilisation = both$observed_utilisation, enzyme = both$observed_enzyme))
  cat("\n  Disagreement here is a property of the reference, not of gifter, and\n",
      "  bounds how well any caller could possibly score.\n", sep = "")
}

# --------------------------------------------- 6. the species-level cross-check
rule("6. Madin cross-check, species level")
madin_path <- cached_get(paste0("https://raw.githubusercontent.com/bacteria-archaea-traits/",
                                "bacteria-archaea-traits/master/output/condensed_traits_NCBI.csv"),
                         "madin/condensed_traits_NCBI.csv")
if (!is.na(madin_path)) {
  madin <- read.csv(madin_path, stringsAsFactors = FALSE)
  madin <- madin[grepl("urea", madin$carbon_substrates, fixed = TRUE), ]
  species <- unique(madin$species)
  hit <- genomes[genomes$binomial %in% species, ]
  # Marker presence stands in for the call here: these genomes are outside the
  # strain-matched test set, and re-evaluating them would cost more than the
  # cross-check is worth. A genome carrying no urease marker cannot be called
  # supported, so the count below is an upper bound on agreement.
  hit$call <- hit$org %in% annotation$genome_id
  kv("species recorded as using urea", length(species))
  kv("KEGG genomes in those species", nrow(hit))
  kv("of those, carrying urease markers (upper bound on the call)", sum(hit$call))
  cat("\n  Madin records no negatives, so only the positive direction exists here;\n",
      "  the unsupported rows are the ones worth reading, one species at a time.\n", sep = "")
  if (any(!hit$call)) print(head(hit[!hit$call, c("org", "name")], 20), row.names = FALSE)
}

rule("Done")
cat("Nothing above is a manuscript claim yet. It is the slice that says whether\n",
    "the crosswalk is worth curating.\n", sep = "")
