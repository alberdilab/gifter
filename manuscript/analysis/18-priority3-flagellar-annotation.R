#!/usr/bin/env Rscript
# Priority 3 structural-pilot flagellar-apparatus annotation audit.
#
# This checksum-pinned audit reads one deposited protein FASTA. It does not read
# microscopy, culture, motility, assay, or prospective-registry observations.
# A complete call supports only the encoded structural apparatus.

suppressMessages(devtools::load_all(".", quiet = TRUE))
args <- commandArgs(trailingOnly = TRUE)
option <- function(name, default) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (!length(hit)) return(default)
  sub(paste0("^--", name, "="), "", hit[[1L]])
}
must_path <- function(path, label) {
  if (!file.exists(path)) stop(label, " does not exist: ", path, call. = FALSE)
  normalizePath(path, mustWork = TRUE)
}
hash <- function(path) {
  out <- system2("shasum", c("-a", "256", path), stdout = TRUE, stderr = TRUE)
  if (!is.null(attr(out, "status")) && attr(out, "status") != 0L) stop("Cannot hash ", path, call. = FALSE)
  out <- sub("[[:space:]].*$", "", out[[1L]])
  if (!grepl("^[0-9a-f]{64}$", out)) stop("Invalid SHA-256 for ", path, call. = FALSE)
  out
}
run <- function(command, arguments, stdout = NULL) {
  if (!identical(system2(command, arguments, stdout = stdout, stderr = NULL), 0L))
    stop("Command failed: ", command, call. = FALSE)
}
write_tsv <- function(x, path) utils::write.table(x, path, sep = "\t", row.names = FALSE, quote = FALSE, na = "")
collapse <- function(x) {
  x <- sort(unique(as.character(x[!is.na(x) & nzchar(x)])))
  if (length(x)) paste(x, collapse = ";") else ""
}
tblout <- function(path) {
  lines <- grep("^#", readLines(path, warn = FALSE), value = TRUE, invert = TRUE)
  lines <- lines[nzchar(trimws(lines))]
  if (!length(lines)) return(data.frame(gene_id = character(), profile_name = character(),
    profile_accession = character(), sequence_score = numeric(), domain_score = numeric()))
  fields <- strsplit(trimws(lines), "[[:space:]]+")
  data.frame(
    gene_id = vapply(fields, `[`, character(1), 1L),
    profile_name = vapply(fields, `[`, character(1), 3L),
    profile_accession = vapply(fields, `[`, character(1), 4L),
    sequence_score = as.numeric(vapply(fields, `[`, character(1), 6L)),
    domain_score = as.numeric(vapply(fields, `[`, character(1), 9L)),
    stringsAsFactors = FALSE
  )
}
inflate_fasta <- function(path) {
  out <- tempfile(fileext = ".faa")
  con <- gzfile(path, "rt")
  on.exit(close(con), add = TRUE)
  writeLines(readLines(con, warn = FALSE), out, useBytes = TRUE)
  out
}
extract_model <- function(accession, hmmfetch, library, directory) {
  path <- file.path(directory, paste0(accession, ".hmm"))
  run(hmmfetch, c(library, accession), stdout = path)
  if (!file.exists(path) || !file.size(path)) stop("Could not extract KOfam model ", accession, call. = FALSE)
  path
}

root <- getwd()
gift_id <- "flagellar_apparatus"
candidates_path <- must_path(file.path(root, "manuscript/analysis/prospective/priority-3-flagellar-candidates.tsv"),
                             "Priority 3 candidate roster")
inputs_path <- must_path(file.path(root, "manuscript/analysis/prospective/priority-3-flagellar-annotation-inputs.tsv"),
                         "Priority 3 input manifest")
database_path <- must_path(option("database", "inst/extdata/gifter.sqlite"), "database")
proteome_dir <- normalizePath(option("proteomes", "manuscript/analysis/.cache/prospective/priority-3-flagellar/proteomes"),
                               mustWork = FALSE)
output_dir <- normalizePath(option("output", "manuscript/analysis/prospective/priority-3-flagellar-annotation-audit"),
                            mustWork = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

candidates <- utils::read.delim(candidates_path, stringsAsFactors = FALSE, check.names = FALSE)
inputs <- utils::read.delim(inputs_path, stringsAsFactors = FALSE, check.names = FALSE)
need_candidate <- c("candidate_id", "status", "role", "organism", "strain", "assembly_accession")
need_input <- c("candidate_id", "assembly_accession", "protein_fasta_url", "expected_protein_sha256")
if (!all(need_candidate %in% names(candidates)) || !all(need_input %in% names(inputs)))
  stop("Priority 3 candidate/input columns have changed", call. = FALSE)
candidates <- candidates[candidates$status %in% c("candidate", "excluded"), need_candidate, drop = FALSE]
if (nrow(candidates) != 1L || candidates$role[[1L]] != "microscopy candidate")
  stop("Priority 3 needs exactly one structural microscopy candidate or documented exclusion", call. = FALSE)
input <- inputs[match(candidates$candidate_id, inputs$candidate_id), , drop = FALSE]
if (nrow(input) != 1L || candidates$assembly_accession[[1L]] != input$assembly_accession[[1L]])
  stop("Priority 3 candidate/input identities disagree", call. = FALSE)
proteome <- file.path(proteome_dir, paste0(candidates$assembly_accession[[1L]], ".faa.gz"))
if (!file.exists(proteome)) stop("Exact NCBI protein FASTA is absent. Download only: ", input$protein_fasta_url[[1L]], call. = FALSE)
proteome_hash <- hash(proteome)
if (!identical(tolower(proteome_hash), tolower(input$expected_protein_sha256[[1L]])))
  stop("Protein FASTA does not match its pre-recorded SHA-256", call. = FALSE)

profile_dir <- must_path("manuscript/analysis/.cache/annotation/profiles", "annotation profile directory")
library <- must_path(file.path(profile_dir, "curated-ko.hmm"), "curated KOfam library")
threshold_path <- must_path(file.path(profile_dir, "ko_list.gz"), "KOfam threshold table")
hmmfetch <- Sys.which("hmmfetch")
hmmsearch <- Sys.which("hmmsearch")
if (!nzchar(hmmfetch) || !nzchar(hmmsearch)) stop("HMMER 3 tools must be on PATH", call. = FALSE)

db <- gifter_db_connect(database_path)
on.exit(gifter_db_disconnect(db), add = TRUE)
database_version <- gifter_db_version(db)$gifter_db_version[[1L]]
machinery <- as.data.frame(get_gift_machinery(gift_id, db = db))
if (!nrow(machinery) || any(machinery$namespace != "KO") || any(!machinery$required))
  stop("Pinned flagellar marker contract is no longer all-required KO evidence", call. = FALSE)
markers <- sort(unique(machinery$accession))
expected <- c("K02387", "K02388", "K02390", "K02391", "K02392", "K02393", "K02394", "K02396", "K02397",
              "K02400", "K02401", "K02406", "K02407", "K02408", "K02409", "K02410", "K02411", "K02412",
              "K02416", "K02417", "K02419", "K02420", "K02421", "K02556", "K02557", "K13820")
if (!setequal(markers, expected)) stop("Pinned flagellar marker list changed", call. = FALSE)
if (!file.exists(paste0(library, ".ssi"))) run(hmmfetch, c("--index", library))
models_dir <- tempfile("priority-3-flagellar-models-")
dir.create(models_dir)
on.exit(unlink(models_dir, recursive = TRUE), add = TRUE)
models <- vapply(markers, extract_model, character(1), hmmfetch = hmmfetch, library = library, directory = models_dir)
combined <- file.path(models_dir, "flagellar.hmm")
writeLines(unlist(lapply(models, readLines, warn = FALSE)), combined, useBytes = TRUE)
thresholds <- utils::read.delim(gzfile(threshold_path), quote = "", comment.char = "", stringsAsFactors = FALSE)
names(thresholds)[[1L]] <- "accession"
thresholds <- thresholds[thresholds$accession %in% markers, c("accession", "threshold", "score_type"), drop = FALSE]
thresholds$threshold <- suppressWarnings(as.numeric(thresholds$threshold))
if (!setequal(thresholds$accession, markers) || anyNA(thresholds$threshold) ||
    any(!thresholds$score_type %in% c("full", "domain"))) stop("Invalid KOfam rules", call. = FALSE)

hmmsearch_help <- system2(hmmsearch, "-h", stdout = TRUE)
hmmsearch_version <- sub("^#[[:space:]]*", "", grep("^#[[:space:]]*HMMER[[:space:]]", hmmsearch_help, value = TRUE)[[1L]])
fasta <- inflate_fasta(proteome)
on.exit(unlink(fasta), add = TRUE)
output <- tempfile(fileext = ".tblout")
run(hmmsearch, c("--noali", "--cpu", "2", "-T", "0", "--tblout", output, combined, fasta))
hits <- tblout(output)
unlink(output)
hits$namespace <- "KO"
hits$accession <- hits$profile_name
hits$threshold <- thresholds$threshold[match(hits$accession, thresholds$accession)]
hits$score_type <- thresholds$score_type[match(hits$accession, thresholds$accession)]
hits$called <- ifelse(hits$score_type == "domain", hits$domain_score >= hits$threshold, hits$sequence_score >= hits$threshold)
hits$candidate_id <- candidates$candidate_id[[1L]]
hits$assembly_accession <- candidates$assembly_accession[[1L]]
hits <- hits[, c("candidate_id", "assembly_accession", "gene_id", "namespace", "accession", "profile_name",
                 "profile_accession", "sequence_score", "domain_score", "threshold", "score_type", "called")]
annotations <- hits[hits$called, c("gene_id", "namespace", "accession"), drop = FALSE]
result <- evaluate_gifts(annotations, db = db, max_genes = Inf)
call <- result$structural$gifts[result$structural$gifts$gift_id == gift_id, , drop = FALSE]
present <- sort(unique(annotations$accession))
missing <- setdiff(markers, present)
if (nrow(call) != 1L) stop("Pinned database does not contain flagellar_apparatus", call. = FALSE)
trace <- trace_gift(result, gift_id)
trace$candidate_id <- candidates$candidate_id[[1L]]
trace$assembly_accession <- candidates$assembly_accession[[1L]]
if (isTRUE(call$complete[[1L]]) && (!all(trace$component_supported[trace$required]) ||
                                    call$minimum_missing_functions[[1L]] != 0L))
  stop("Complete structural call has contradictory component evidence", call. = FALSE)

audit <- data.frame(
  candidate_id = candidates$candidate_id, role = candidates$role, organism = candidates$organism, strain = candidates$strain,
  assembly_accession = candidates$assembly_accession, protein_fasta_url = input$protein_fasta_url,
  protein_fasta_sha256 = proteome_hash, annotation_run_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  database_version = database_version, hmmsearch_version = hmmsearch_version,
  curated_marker_accessions_present = collapse(present), curated_marker_accessions_without_hit = collapse(missing),
  required_marker_gene_count = length(unique(annotations$gene_id)), complete_architectures = call$number_of_complete_architectures,
  best_architecture = call$best_architecture, flagellar_apparatus_complete = call$complete,
  minimum_missing_functions = call$minimum_missing_functions,
  annotation_evidence_class = if (isTRUE(call$complete[[1L]])) "complete_structural_marker_evidence" else "incomplete_structural_marker_evidence",
  record_status = "candidate_annotation_audit_not_microscopy_motility_or_prospective_observation", stringsAsFactors = FALSE
)
rules <- vapply(markers, function(marker) {
  row <- thresholds[match(marker, thresholds$accession), , drop = FALSE]
  paste0(row$score_type, " score >= ", row$threshold)
}, character(1))
manifest <- data.frame(
  input_kind = c("proteome", "KOfam_library", "KOfam_threshold_table", rep("KOfam_model", length(markers)), "database"),
  identifier = c(candidates$assembly_accession, "curated-ko.hmm", "ko_list.gz", markers, database_version),
  source = c(input$protein_fasta_url, "https://www.genome.jp/ftp/db/kofam/profiles.tar.gz", "https://www.genome.jp/ftp/db/kofam/ko_list.gz",
             rep("extracted from curated-ko.hmm", length(markers)), normalizePath(database_path)),
  sha256 = c(proteome_hash, hash(library), hash(threshold_path), vapply(models, hash, character(1)), hash(database_path)),
  call_rule = c("exact NCBI protein FASTA; SHA-256 must match pre-recorded pin", "content-addressed source library",
                "KOfam adaptive threshold table", rules, "gifter database used for final structural call"), stringsAsFactors = FALSE
)
write_tsv(audit, file.path(output_dir, "candidate-annotation-audit.tsv"))
write_tsv(hits, file.path(output_dir, "candidate-marker-hits.tsv"))
write_tsv(trace, file.path(output_dir, "flagellar-gift-trace.tsv"))
write_tsv(manifest, file.path(output_dir, "input-manifest.tsv"))
cat("Priority 3 flagellar structural candidate annotation audit\n")
cat("  database version: ", database_version, "\n", sep = "")
cat("  complete structural architectures: ", call$number_of_complete_architectures[[1L]], "\n", sep = "")
cat("  status: annotation evidence only; no microscopy, motility, assay, or prospective observation was read.\n")
