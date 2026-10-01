#!/usr/bin/env Rscript
# Priority 1 type I-E CRISPR-Cas machinery candidate annotation audit.
#
# This audit applies the exact defence-machinery contract to two exact NCBI
# proteomes.  It assesses only proteins: a CRISPR array is a repeat-spacer
# genomic feature and is deliberately neither searched nor inferred here.
#
# Usage:
#   Rscript manuscript/analysis/16-priority1-type-ie-crispr-annotation.R \
#     --proteomes=manuscript/analysis/.cache/prospective/type-ie-crispr/proteomes \
#     [--database=inst/extdata/gifter.sqlite] \
#     [--output=manuscript/analysis/prospective/type-ie-crispr-annotation-audit]

suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
option <- function(name, default = NULL) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (!length(hit)) return(default)
  sub(paste0("^--", name, "="), "", hit[[1L]])
}

path_or_stop <- function(path, label) {
  if (!file.exists(path)) stop(label, " does not exist: ", path, call. = FALSE)
  normalizePath(path, mustWork = TRUE)
}

sha256 <- function(path) {
  output <- system2("shasum", c("-a", "256", path), stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status")
  if (!is.null(status) && status != 0L) stop("Could not calculate SHA-256 for ", path, call. = FALSE)
  value <- sub("[[:space:]].*$", "", output[[1L]])
  if (!grepl("^[0-9a-f]{64}$", value)) stop("Invalid SHA-256 output for ", path, call. = FALSE)
  value
}

run_or_stop <- function(command, arguments, stdout = NULL) {
  status <- system2(command, arguments, stdout = stdout, stderr = NULL)
  if (!identical(status, 0L)) {
    stop("Command failed: ", command, " ", paste(arguments, collapse = " "), call. = FALSE)
  }
  invisible(NULL)
}

read_tblout <- function(path) {
  empty <- data.frame(
    gene_id = character(), profile_name = character(), profile_accession = character(),
    sequence_score = numeric(), domain_score = numeric(), stringsAsFactors = FALSE
  )
  lines <- grep("^#", readLines(path, warn = FALSE), value = TRUE, invert = TRUE)
  lines <- lines[nzchar(trimws(lines))]
  if (!length(lines)) return(empty)
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

write_tsv <- function(x, path) {
  utils::write.table(x, path, sep = "\t", row.names = FALSE, quote = FALSE, na = "")
  invisible(path)
}

collapse_or_empty <- function(x) {
  x <- sort(unique(as.character(x[!is.na(x) & nzchar(x)])))
  if (length(x)) paste(x, collapse = ";") else ""
}

read_fasta_gz <- function(path) {
  fasta <- tempfile(fileext = ".faa")
  source <- gzfile(path, open = "rt")
  on.exit(close(source), add = TRUE)
  writeLines(readLines(source, warn = FALSE), fasta, useBytes = TRUE)
  fasta
}

extract_kofam_model <- function(hmmfetch, library, accession, directory) {
  out <- file.path(directory, paste0(accession, ".hmm"))
  run_or_stop(hmmfetch, c(library, accession), stdout = out)
  if (!file.exists(out) || !file.size(out)) stop("Could not extract KOfam model ", accession, call. = FALSE)
  out
}

gift_call <- function(result, gift_id) {
  call <- result$gifts[result$gifts$gift_id == gift_id, , drop = FALSE]
  if (nrow(call) != 1L) stop("Pinned database does not contain ", gift_id, call. = FALSE)
  call
}

root <- getwd()
gift_id <- "type_i_e_crispr_cas_machinery"
candidates_path <- path_or_stop(
  file.path(root, "manuscript/analysis/prospective/type-ie-crispr-candidates.tsv"),
  "type I-E CRISPR-Cas candidate roster"
)
inputs_path <- path_or_stop(
  file.path(root, "manuscript/analysis/prospective/type-ie-crispr-annotation-inputs.tsv"),
  "type I-E CRISPR-Cas annotation input manifest"
)
database_path <- path_or_stop(option("database", "inst/extdata/gifter.sqlite"), "database")
proteome_dir <- normalizePath(option(
  "proteomes", "manuscript/analysis/.cache/prospective/type-ie-crispr/proteomes"
), mustWork = FALSE)
output_dir <- normalizePath(option(
  "output", "manuscript/analysis/prospective/type-ie-crispr-annotation-audit"
), mustWork = FALSE)
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

profile_dir <- path_or_stop("manuscript/analysis/.cache/annotation/profiles", "annotation profile directory")
kofam_library <- path_or_stop(file.path(profile_dir, "curated-ko.hmm"), "curated KOfam library")
kofam_thresholds <- path_or_stop(file.path(profile_dir, "ko_list.gz"), "KOfam threshold table")
hmmfetch <- Sys.which("hmmfetch")
hmmsearch <- Sys.which("hmmsearch")
if (!nzchar(hmmfetch) || !nzchar(hmmsearch)) {
  stop("HMMER 3 tools hmmfetch and hmmsearch must be on PATH", call. = FALSE)
}

candidates <- utils::read.delim(candidates_path, stringsAsFactors = FALSE, check.names = FALSE)
inputs <- utils::read.delim(inputs_path, stringsAsFactors = FALSE, check.names = FALSE)
required_candidates <- c("candidate_id", "status", "role", "organism", "strain", "assembly_accession")
required_inputs <- c("candidate_id", "assembly_accession", "protein_fasta_url")
if (!all(required_candidates %in% names(candidates))) stop("Candidate roster has changed columns", call. = FALSE)
if (!all(required_inputs %in% names(inputs))) stop("Input manifest has changed columns", call. = FALSE)
candidates <- candidates[candidates$status == "candidate", required_candidates, drop = FALSE]
if (!nrow(candidates) || anyDuplicated(candidates$candidate_id)) stop("Candidate roster must have unique candidate rows", call. = FALSE)
if (!setequal(candidates$candidate_id, inputs$candidate_id)) stop("Input manifest and candidate roster disagree", call. = FALSE)
candidates$protein_fasta_url <- inputs$protein_fasta_url[match(candidates$candidate_id, inputs$candidate_id)]
if (any(candidates$assembly_accession != inputs$assembly_accession[match(candidates$candidate_id, inputs$candidate_id)])) {
  stop("Input manifest and candidate roster disagree on assembly accession", call. = FALSE)
}
if (nrow(candidates) != 2L || !setequal(candidates$role, c("specific-positive", "incomplete-machinery control"))) {
  stop("Candidate roster must contain one specific-positive and one incomplete-machinery control", call. = FALSE)
}
proteome_paths <- file.path(proteome_dir, paste0(candidates$assembly_accession, ".faa.gz"))
if (any(!file.exists(proteome_paths))) {
  missing <- candidates$protein_fasta_url[!file.exists(proteome_paths)]
  stop(
    "Exact NCBI protein FASTA input(s) are absent. Download only these URLs into ", proteome_dir,
    ": ", paste(missing, collapse = "; "), call. = FALSE
  )
}

connection <- gifter_db_connect(database_path)
on.exit(gifter_db_disconnect(connection), add = TRUE)
database_version <- gifter_db_version(connection)$gifter_db_version[[1L]]
machinery <- as.data.frame(get_gift_machinery(gift_id, db = connection))
if (!all(machinery$namespace == "KO")) stop("Pinned type I-E machinery no longer uses only KO markers", call. = FALSE)
required_kos <- sort(unique(machinery$accession[machinery$required]))
accessory_kos <- sort(unique(machinery$accession[!machinery$required]))
audit_kos <- sort(unique(machinery$accession))
expected_required <- c("K07012", "K19046", "K19123", "K19124", "K19125", "K19126")
expected_accessory <- c("K09951", "K15342")
if (!setequal(required_kos, expected_required) || !setequal(accessory_kos, expected_accessory)) {
  stop("Pinned database no longer has the expected type I-E Cascade, Cas3 and accessory contract", call. = FALSE)
}
marker_metadata <- unique(machinery[c("accession", "function_id", "component_id", "required", "evidence_type", "confidence")])

if (!file.exists(paste0(kofam_library, ".ssi"))) run_or_stop(hmmfetch, c("--index", kofam_library))
model_dir <- tempfile("type-ie-crispr-models-")
dir.create(model_dir)
on.exit(unlink(model_dir, recursive = TRUE), add = TRUE)
model_paths <- vapply(audit_kos, function(accession)
  extract_kofam_model(hmmfetch, kofam_library, accession, model_dir), character(1))
combined_kofam <- file.path(model_dir, "type-ie-crispr.hmm")
writeLines(unlist(lapply(model_paths, readLines, warn = FALSE)), combined_kofam, useBytes = TRUE)

ko_list <- utils::read.delim(gzfile(kofam_thresholds), quote = "", comment.char = "",
                             stringsAsFactors = FALSE)
names(ko_list)[[1L]] <- "accession"
ko_list <- ko_list[ko_list$accession %in% audit_kos, c("accession", "threshold", "score_type"), drop = FALSE]
ko_list$threshold <- suppressWarnings(as.numeric(ko_list$threshold))
if (!setequal(ko_list$accession, audit_kos) || anyNA(ko_list$threshold) ||
    any(!ko_list$score_type %in% c("full", "domain"))) {
  stop("KOfam threshold table does not provide valid rules for the type I-E markers", call. = FALSE)
}

hmmsearch_help <- system2(hmmsearch, "-h", stdout = TRUE)
hmmsearch_version <- sub("^#[[:space:]]*", "", grep("^#[[:space:]]*HMMER[[:space:]]", hmmsearch_help,
                                                         value = TRUE)[[1L]])
run_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

all_hits <- list()
audit_rows <- list()
trace_rows <- list()
for (i in seq_len(nrow(candidates))) {
  candidate <- candidates[i, , drop = FALSE]
  proteome <- proteome_paths[[i]]
  fasta <- read_fasta_gz(proteome)
  on.exit(unlink(fasta), add = TRUE)
  tblout <- tempfile(fileext = ".tblout")
  run_or_stop(hmmsearch, c("--noali", "--cpu", "2", "-T", "0", "--tblout", tblout,
                           combined_kofam, fasta))
  hits <- read_tblout(tblout)
  unlink(tblout)
  hits$namespace <- "KO"
  hits$accession <- hits$profile_name
  hits$threshold <- ko_list$threshold[match(hits$accession, ko_list$accession)]
  hits$score_type <- ko_list$score_type[match(hits$accession, ko_list$accession)]
  hits$called <- ifelse(
    hits$score_type == "domain", hits$domain_score >= hits$threshold,
    hits$sequence_score >= hits$threshold
  )
  metadata_index <- match(hits$accession, marker_metadata$accession)
  hits$function_id <- marker_metadata$function_id[metadata_index]
  hits$component_id <- marker_metadata$component_id[metadata_index]
  hits$component_required <- marker_metadata$required[metadata_index]
  hits$evidence_type <- marker_metadata$evidence_type[metadata_index]
  hits$confidence <- marker_metadata$confidence[metadata_index]
  hits$candidate_id <- candidate$candidate_id
  hits$assembly_accession <- candidate$assembly_accession
  all_hits[[i]] <- hits[c("candidate_id", "assembly_accession", "gene_id", "namespace", "accession",
                          "profile_name", "profile_accession", "sequence_score", "domain_score",
                          "threshold", "score_type", "called", "function_id", "component_id",
                          "component_required", "evidence_type", "confidence")]

  annotations <- hits[hits$called, c("gene_id", "namespace", "accession"), drop = FALSE]
  result <- evaluate_gifts(annotations, db = connection, max_genes = Inf)
  call <- gift_call(result, gift_id)
  required_present <- sort(unique(annotations$accession[annotations$accession %in% required_kos]))
  accessory_present <- sort(unique(annotations$accession[annotations$accession %in% accessory_kos]))
  marker_class <- if (isTRUE(call$complete[[1L]])) {
    "complete_type_i_e_machinery_evidence"
  } else if (length(accessory_present) || length(required_present)) {
    "incomplete_machinery_evidence"
  } else {
    "no_relevant_marker"
  }
  if (candidate$role[[1L]] == "specific-positive" && !isTRUE(call$complete[[1L]])) {
    stop("Specific-positive candidate lacks complete type I-E machinery evidence", call. = FALSE)
  }
  if (candidate$role[[1L]] == "incomplete-machinery control" &&
      (isTRUE(call$complete[[1L]]) || !length(accessory_present) ||
       length(required_present) >= length(required_kos))) {
    stop("Incomplete-machinery control does not retain the intended generic/incomplete contrast", call. = FALSE)
  }

  trace <- trace_gift(result, gift_id)
  trace$candidate_id <- candidate$candidate_id
  trace$assembly_accession <- candidate$assembly_accession
  trace_rows[[i]] <- trace
  audit_rows[[i]] <- data.frame(
    candidate_id = candidate$candidate_id,
    role = candidate$role,
    organism = candidate$organism,
    strain = candidate$strain,
    assembly_accession = candidate$assembly_accession,
    protein_fasta_url = candidate$protein_fasta_url,
    protein_fasta_sha256 = sha256(proteome),
    annotation_run_utc = run_at,
    database_version = database_version,
    hmmsearch_version = hmmsearch_version,
    required_cascade_marker_genes = collapse_or_empty(hits$gene_id[hits$called &
      hits$accession %in% setdiff(required_kos, "K07012")]),
    fused_cas3_k07012_genes = collapse_or_empty(hits$gene_id[hits$called & hits$accession == "K07012"]),
    generic_cas1_k15342_genes = collapse_or_empty(hits$gene_id[hits$called & hits$accession == "K15342"]),
    generic_cas2_k09951_genes = collapse_or_empty(hits$gene_id[hits$called & hits$accession == "K09951"]),
    required_marker_accessions_present = collapse_or_empty(required_present),
    required_marker_accessions_missing = collapse_or_empty(setdiff(required_kos, required_present)),
    accessory_marker_accessions_present = collapse_or_empty(accessory_present),
    marker_evidence_class = marker_class,
    type_i_e_crispr_cas_machinery_complete = call$complete[[1L]],
    minimum_missing_requirements = call$minimum_missing_requirements[[1L]],
    record_status = "candidate_annotation_audit_not_prospective_observation",
    stringsAsFactors = FALSE
  )
}

model_rules <- vapply(audit_kos, function(accession) {
  row <- ko_list[match(accession, ko_list$accession), , drop = FALSE]
  paste0(row$score_type, " score >= ", row$threshold)
}, character(1))
manifest <- data.frame(
  input_kind = c(rep("proteome", nrow(candidates)), "KOfam_library", "KOfam_threshold_table",
                 rep("KOfam_model", length(audit_kos)), "database"),
  identifier = c(candidates$assembly_accession, "curated-ko.hmm", "ko_list.gz", audit_kos, database_version),
  source = c(candidates$protein_fasta_url,
             "https://www.genome.jp/ftp/db/kofam/profiles.tar.gz",
             "https://www.genome.jp/ftp/db/kofam/ko_list.gz",
             rep("extracted from curated-ko.hmm", length(audit_kos)), normalizePath(database_path)),
  sha256 = c(vapply(proteome_paths, sha256, character(1)), sha256(kofam_library),
             sha256(kofam_thresholds), vapply(model_paths, sha256, character(1)), sha256(database_path)),
  call_rule = c(rep("exact NCBI protein FASTA", nrow(candidates)),
                "content-addressed source library", "KOfam adaptive threshold table", model_rules,
                "gifter database used for final machinery call"),
  stringsAsFactors = FALSE
)

write_tsv(do.call(rbind, audit_rows), file.path(output_dir, "candidate-annotation-audit.tsv"))
write_tsv(do.call(rbind, all_hits), file.path(output_dir, "candidate-marker-hits.tsv"))
write_tsv(do.call(rbind, trace_rows), file.path(output_dir, "type-ie-crispr-gift-traces.tsv"))
write_tsv(manifest, file.path(output_dir, "input-manifest.tsv"))

cat("Priority 1 type I-E CRISPR-Cas machinery candidate annotation audit\n")
cat("------------------------------------------------------------------\n")
cat("  database version: ", database_version, "\n", sep = "")
cat("  candidate assemblies: ", nrow(candidates), "\n", sep = "")
cat("  output: ", output_dir, "\n", sep = "")
cat("  status: candidate annotation audit only; no CRISPR array or prospective assay observation was read.\n")
