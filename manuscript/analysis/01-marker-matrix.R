#!/usr/bin/env Rscript
# The reference genome set, and what gifter calls on it.
#
# R7, R8 and R9 all need the same thing first: a large set of genomes whose
# markers are known, joined to identifiers an external record can reach. KEGG
# supplies both at once. Its 11 949 genome entries carry an NCBI taxon and a
# GenBank assembly accession, and one request per curated marker returns every
# genome carrying it -- so the marker matrix costs about 750 requests rather
# than 11 949 annotation runs.
#
# Two things must be said plainly about what that buys.
#
# It is KEGG's own per-genome assignment, not the output of the annotator a user
# would run. That makes every call here an **upper bound**: the evidence is as
# good as it gets, and the gap between this and a pinned KofamScan run is a
# number R9 should report rather than hide.
#
# It is also KO-only. gifter curates 520 CAZy markers, 57 NCBIfam profiles and a
# handful of Pfam and TIGRFAM rows, and none of them are reachable this way. 150
# of the 153 GIFTs have at least one complete route made of KO markers alone, so
# the catalogue is reachable in principle -- but a GIFT whose usual evidence is
# a CAZy family will under-call here, and section 6 counts which ones.
#
# Products, all written to manuscript/analysis/output/:
#
#   kegg-genome-set.tsv    every KEGG genome with its taxon, assembly and
#                          assembly-derived quality, the join key for R9
#   gift-prevalence.tsv    per GIFT, how many of the genomes carry a complete
#                          implementation, by evidence confidence
#   marker-reach.tsv       per curated marker, how many genomes carry it, and
#                          whether the namespace is reachable at all
#
# The KO x genome matrix itself is NOT committed. KEGG's REST service is
# licensed for academic use and its derived tables may not be redistributed, so
# the matrix stays in the cache and only summaries leave it.
#
# Usage:
#   Rscript manuscript/analysis/01-marker-matrix.R [--no-evaluate] [--chunk=500]
#
# First run fetches about 750 requests and evaluates 11 949 genomes; budget an
# hour. Everything is cached, and the evaluation is stored as an RDS, so a
# second run is minutes.

source("manuscript/analysis/_common.R")
suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
opt <- function(name, default) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit) == 0) default else sub(paste0("^--", name, "="), "", hit[[1]])
}
chunk_size <- as.integer(opt("chunk", "500"))
evaluate   <- !("--no-evaluate" %in% args)
out_dir    <- "manuscript/analysis/output"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

con <- gifter_db()

# ------------------------------------------------------- 1. the marker vocabulary
rule("1. The curated marker vocabulary")
markers <- dbGetQuery(con, "select namespace, accession from marker")
print(table(markers$namespace))
kos <- sort(unique(markers$accession[markers$namespace == "KO"]))
kv("KO markers, one request each", length(kos))
kv("markers unreachable through KEGG genomes", sum(markers$namespace != "KO"))

# ------------------------------------------------------------- 2. the KO matrix
rule("2. Fetching the KO x genome matrix")
invisible(cached_get_many(paste0("https://rest.kegg.jp/link/genes/ko:", kos),
                          file.path("kegg", "ko", paste0(kos, ".tsv"))))

annotation <- kegg_annotation_table(kos)
kv("marker observations", nrow(annotation))
kv("genomes carrying at least one curated marker", length(unique(annotation$genome_id)))

reach <- as.data.frame(table(annotation$accession), stringsAsFactors = FALSE)
names(reach) <- c("accession", "observations")
per_genome <- tapply(annotation$genome_id, annotation$accession,
                     function(x) length(unique(x)))
reach$genomes <- as.integer(per_genome[reach$accession])
reach$namespace <- "KO"
absent <- setdiff(kos, reach$accession)
if (length(absent))
  reach <- rbind(reach, data.frame(accession = absent, observations = 0L,
                                   genomes = 0L, namespace = "KO"))
unreachable <- unique(markers[markers$namespace != "KO", ])
reach <- rbind(reach, data.frame(accession = unreachable$accession,
                                 observations = NA_integer_, genomes = NA_integer_,
                                 namespace = unreachable$namespace))
kv("KO markers matching no KEGG genome", length(absent))

# ------------------------------------------------------------- 3. the genome set
rule("3. The genome set")
genomes <- kegg_genome_list()
meta <- kegg_genome_metadata(genomes$tnumber)
genome_set <- merge(genomes, meta, by = "tnumber", all.x = TRUE)
genome_set$markers <- as.integer(table(annotation$genome_id)[genome_set$org])
genome_set$markers[is.na(genome_set$markers)] <- 0L

kv("genome entries", nrow(genome_set))
kv("with an NCBI taxon", sum(!is.na(genome_set$taxid)))
kv("with a GenBank assembly", sum(!is.na(genome_set$assembly)))
kv("carrying no curated marker at all", sum(genome_set$markers == 0))

# Eukaryotic entries are in the list and are not what gifter is for. They are
# kept in the table with a flag rather than dropped, because R7 and R8 will want
# to state their own exclusions rather than inherit an invisible one.
genome_set$prokaryote <- !grepl("^(Homo|Mus|Rattus|Danio|Drosophila|Caenorhabditis|Saccharomyces|Arabidopsis)",
                                genome_set$name)
kv("flagged prokaryote", sum(genome_set$prokaryote))

# ----------------------------------------------------------- 4. calls, in chunks
calls_path <- cache_path("gift-calls-kegg.rds")
if (evaluate && !file.exists(calls_path)) {
  rule("4. Evaluating every genome")
  orgs <- sort(unique(annotation$genome_id))
  chunks <- split(orgs, ceiling(seq_along(orgs) / chunk_size))
  message("  ", length(orgs), " genomes with evidence, in ", length(chunks), " chunks")

  parts <- vector("list", length(chunks))
  for (i in seq_along(chunks)) {
    subset <- annotation[annotation$genome_id %in% chunks[[i]], ]
    # workers = 1L deliberately: the community evaluator parallelises by
    # forking, and a child inheriting this script's SQLite handle aborts the
    # session with no traceback.
    community <- evaluate_gifts_community(subset, genome_id = "genome_id",
                                          gene_id = "gene_id", max_genes = Inf,
                                          workers = 1L)
    # Keep the calls, discard the evidence chains. Retaining 11 949 full results
    # is the same mistake as retaining every parsed BacDive record.
    parts[[i]] <- do.call(rbind, lapply(names(community$results), function(g) {
      row <- community$results[[g]]$gifts
      data.frame(org = g, gift_id = row$gift_id, complete = row$complete,
                 confidence = row$evidence_confidence,
                 missing = row$minimum_missing_requirements,
                 stringsAsFactors = FALSE)
    }))
    rm(community); gc(FALSE)
    message("  chunk ", i, "/", length(chunks))
  }
  saveRDS(do.call(rbind, parts), calls_path)
}

# ------------------------------------------------------------- 5. what it calls
prevalence <- data.frame()
if (file.exists(calls_path)) {
  rule("5. Prevalence over the genome set")
  calls <- readRDS(calls_path)
  denominator <- sum(genome_set$prokaryote)

  supported <- calls[calls$complete, ]
  prevalence <- as.data.frame(table(supported$gift_id), stringsAsFactors = FALSE)
  names(prevalence) <- c("gift_id", "genomes")
  gifts <- dbGetQuery(con, "select gift_id, gift_type, mode, name from gift")
  prevalence <- merge(gifts, prevalence, by = "gift_id", all.x = TRUE)
  prevalence$genomes[is.na(prevalence$genomes)] <- 0L
  # The denominator is every prokaryotic genome in the set, not every genome
  # with evidence. A GIFT absent from a genome that carries no marker is still
  # absent, and counting only the evidenced genomes would inflate every row.
  prevalence$denominator <- denominator
  prevalence$proportion <- round(prevalence$genomes / denominator, 4)

  by_conf <- table(supported$gift_id, supported$confidence)
  for (level in colnames(by_conf))
    prevalence[[paste0("conf_", level)]] <-
      as.integer(by_conf[match(prevalence$gift_id, rownames(by_conf)), level])

  prevalence <- prevalence[order(-prevalence$genomes), ]
  kv("denominator (prokaryotic genome entries)", denominator)
  kv("GIFTs supported in no genome", sum(prevalence$genomes == 0))
  kv("GIFTs supported in over half the set", sum(prevalence$proportion > 0.5))
  cat("\n  most and least prevalent:\n")
  print(head(prevalence[, c("gift_id", "gift_type", "genomes", "proportion")], 8), row.names = FALSE)
  print(tail(prevalence[, c("gift_id", "gift_type", "genomes", "proportion")], 8), row.names = FALSE)
}

# ------------------------------------------------- 6. what this set cannot say
rule("6. The KO-only ceiling")
# A component with no KO marker cannot be evidenced here at all, whatever the
# rest of its system looks like. Counting them says which parts of the catalogue
# this genome set systematically under-calls -- which is a property of the
# reference set, not a gifter failure, and R9 must not read it as one.
gap <- dbGetQuery(con, "
  select g.gift_id, g.gift_type,
         count(distinct ec.component_pk) components,
         sum(case when ko.n is null then 1 else 0 end) without_ko
  from gift g
  join gift_route gr on gr.gift_pk = g.gift_pk
  join route_reaction rr on rr.route_pk = gr.route_pk
  join enzyme_system es on es.reaction_pk = rr.reaction_pk
  join enzyme_component ec on ec.system_pk = es.system_pk
  left join (
    select cm.component_pk, count(*) n
    from component_marker cm join marker m on m.marker_pk = cm.marker_pk
    where m.namespace = 'KO' group by cm.component_pk) ko
    on ko.component_pk = ec.component_pk
  group by g.gift_id, g.gift_type
  having without_ko > 0
  order by without_ko desc")
kv("GIFTs with at least one component no KO can evidence", nrow(gap))
if (nrow(gap)) print(head(gap, 12), row.names = FALSE)

# ------------------------------------------------------------------- 7. outputs
rule("7. Writing")
write.table(genome_set[, c("org", "tnumber", "name", "binomial", "taxid",
                           "assembly", "prokaryote", "markers")],
            file.path(out_dir, "kegg-genome-set.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
write.table(reach, file.path(out_dir, "marker-reach.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
if (nrow(prevalence))
  write.table(prevalence, file.path(out_dir, "gift-prevalence.tsv"),
              sep = "\t", quote = FALSE, row.names = FALSE, na = "")

kv("kegg-genome-set.tsv", nrow(genome_set))
kv("marker-reach.tsv", nrow(reach))
kv("gift-prevalence.tsv", nrow(prevalence))
cat("\nThe KO x genome matrix stays in the cache: KEGG's derived tables may not\n",
    "be redistributed. Only the summaries above are committed.\n", sep = "")
