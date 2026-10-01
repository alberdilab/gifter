#!/usr/bin/env Rscript
# Priority 1 collagen candidate annotation audit.
#
# This is deliberately outside the prospective registry: it evaluates exact
# assembly/protein inputs and records the M9-marker contrast, but contains no
# biological assay observation.  It writes a content-addressed manifest, all
# retained marker hits, and gifter's complete evidence trace for every exact
# candidate assembly.  The PAO1 broad-protease control is established from the
# named protein in its exact NCBI FASTA header; it is never supplied to gifter
# as collagen evidence and does not substitute for the M9 domain check.
#
# Usage:
#   Rscript manuscript/analysis/12-priority1-collagen-annotation.R \
#     --proteomes=manuscript/analysis/.cache/prospective/collagen/proteomes \
#     [--database=inst/extdata/gifter.sqlite] \
#     [--output=manuscript/analysis/prospective/collagen-annotation-audit]

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

fasta_headers_gz <- function(path) {
  source <- gzfile(path, open = "rt")
  on.exit(close(source), add = TRUE)
  grep("^>", readLines(source, warn = FALSE), value = TRUE)
}

extract_kofam_model <- function(hmmfetch, library, accession, directory) {
  out <- file.path(directory, paste0(accession, ".hmm"))
  run_or_stop(hmmfetch, c(library, accession), stdout = out)
  if (!file.exists(out) || !file.size(out)) stop("Could not extract KOfam model ", accession, call. = FALSE)
  out
}

root <- getwd()
inputs_path <- path_or_stop(
  file.path(root, "manuscript/analysis/prospective/collagen-annotation-inputs.tsv"),
  "collagen annotation input manifest"
)
candidates_path <- path_or_stop(
  file.path(root, "manuscript/analysis/prospective/collagen-specificity-candidates.tsv"),
  "collagen candidate roster"
)
database_path <- path_or_stop(option("database", "inst/extdata/gifter.sqlite"), "database")
proteome_dir <- normalizePath(option(
  "proteomes", "manuscript/analysis/.cache/prospective/collagen/proteomes"
), mustWork = FALSE)
output_dir <- normalizePath(option(
  "output", "manuscript/analysis/prospective/collagen-annotation-audit"
), mustWork = FALSE)
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

profile_dir <- path_or_stop("manuscript/analysis/.cache/annotation/profiles", "annotation profile directory")
kofam_library <- path_or_stop(file.path(profile_dir, "curated-ko.hmm"), "curated KOfam library")
kofam_thresholds <- path_or_stop(file.path(profile_dir, "ko_list.gz"), "KOfam threshold table")
pfam_m9 <- path_or_stop(file.path(profile_dir, "pfam-PF01752.hmm"), "Pfam M9 model")
hmmfetch <- Sys.which("hmmfetch")
hmmsearch <- Sys.which("hmmsearch")
if (!nzchar(hmmfetch) || !nzchar(hmmsearch)) {
  stop("HMMER 3 tools hmmfetch and hmmsearch must be on PATH", call. = FALSE)
}

candidates <- utils::read.delim(candidates_path, stringsAsFactors = FALSE, check.names = FALSE)
inputs <- utils::read.delim(inputs_path, stringsAsFactors = FALSE, check.names = FALSE)
required_candidates <- c("candidate_id", "status", "role", "organism", "strain", "assembly_accession")
required_inputs <- c("candidate_id", "assembly_accession", "protein_fasta_url",
                     "broad_control_protein_accession", "broad_control_header_pattern")
if (!all(required_candidates %in% names(candidates))) stop("Candidate roster has changed columns", call. = FALSE)
if (!all(required_inputs %in% names(inputs))) stop("Input manifest has changed columns", call. = FALSE)
candidates <- candidates[candidates$status == "candidate", required_candidates, drop = FALSE]
if (!nrow(candidates) || anyDuplicated(candidates$candidate_id)) stop("Candidate roster must have unique candidate rows", call. = FALSE)
if (!setequal(candidates$candidate_id, inputs$candidate_id)) stop("Input manifest and candidate roster disagree", call. = FALSE)
candidates$protein_fasta_url <- inputs$protein_fasta_url[match(candidates$candidate_id, inputs$candidate_id)]
candidates$broad_control_protein_accession <- inputs$broad_control_protein_accession[
  match(candidates$candidate_id, inputs$candidate_id)
]
candidates$broad_control_header_pattern <- inputs$broad_control_header_pattern[
  match(candidates$candidate_id, inputs$candidate_id)
]
if (any(candidates$assembly_accession != inputs$assembly_accession[match(candidates$candidate_id, inputs$candidate_id)])) {
  stop("Input manifest and candidate roster disagree on assembly accession", call. = FALSE)
}

proteome_paths <- file.path(proteome_dir, paste0(candidates$assembly_accession, ".faa.gz"))
if (any(!file.exists(proteome_paths))) {
  missing <- candidates$protein_fasta_url[!file.exists(proteome_paths)]
  stop(
    "Exact NCBI protein FASTA input(s) are absent. Download only these URLs into ", proteome_dir,
    ": ", paste(missing, collapse = "; "), call. = FALSE
  )
}

# KOfam uses model-specific adaptive thresholds.  Index the existing immutable
# input once, extract the M9 model, then apply the threshold to the score type
# named in ko_list.  The broad PAO1 control is deliberately not in this library:
# K01399 is not a gifter collagen marker and is checked by its named NCBI protein.
if (!file.exists(paste0(kofam_library, ".ssi"))) run_or_stop(hmmfetch, c("--index", kofam_library))
model_dir <- tempfile("collagen-models-")
dir.create(model_dir)
on.exit(unlink(model_dir, recursive = TRUE), add = TRUE)
kofam_models <- "K01387"
model_paths <- vapply(kofam_models, function(accession)
  extract_kofam_model(hmmfetch, kofam_library, accession, model_dir), character(1))
combined_kofam <- file.path(model_dir, "K01387.hmm")
writeLines(unlist(lapply(model_paths, readLines, warn = FALSE)), combined_kofam, useBytes = TRUE)

ko_list <- utils::read.delim(gzfile(kofam_thresholds), quote = "", comment.char = "",
                             stringsAsFactors = FALSE)
names(ko_list)[[1L]] <- "accession"
ko_list <- ko_list[ko_list$accession %in% kofam_models, c("accession", "threshold", "score_type"), drop = FALSE]
ko_list$threshold <- suppressWarnings(as.numeric(ko_list$threshold))
if (!setequal(ko_list$accession, kofam_models) || anyNA(ko_list$threshold) ||
    any(!ko_list$score_type %in% c("full", "domain"))) {
  stop("KOfam threshold table does not provide valid rules for the audit models", call. = FALSE)
}

connection <- gifter_db_connect(database_path)
on.exit(gifter_db_disconnect(connection), add = TRUE)
database_version <- gifter_db_version(connection)$gifter_db_version[[1L]]
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
  control_header <- ""
  control_accession <- candidate$broad_control_protein_accession[[1L]]
  control_pattern <- candidate$broad_control_header_pattern[[1L]]
  if (!is.na(control_accession) && nzchar(control_accession) &&
      control_accession != "not_applicable") {
    headers <- fasta_headers_gz(proteome)
    control_header <- headers[startsWith(headers, paste0(">", control_accession))]
    if (length(control_header) != 1L || !nzchar(control_pattern) ||
        !grepl(control_pattern, control_header, fixed = TRUE)) {
      stop("The named broad-control protein was not found in the exact FASTA for ",
           candidate$candidate_id, call. = FALSE)
    }
  }
  fasta <- read_fasta_gz(proteome)
  on.exit(unlink(fasta), add = TRUE)

  ko_tbl <- tempfile(fileext = ".tblout")
  run_or_stop(hmmsearch, c("--noali", "--cpu", "2", "-T", "0", "--tblout", ko_tbl,
                           combined_kofam, fasta))
  ko_hits <- read_tblout(ko_tbl)
  unlink(ko_tbl)
  ko_hits$namespace <- rep("KO", nrow(ko_hits))
  ko_hits$accession <- ko_hits$profile_name
  ko_hits$threshold <- ko_list$threshold[match(ko_hits$accession, ko_list$accession)]
  ko_hits$score_type <- ko_list$score_type[match(ko_hits$accession, ko_list$accession)]
  ko_hits$called <- ifelse(
    ko_hits$score_type == "domain", ko_hits$domain_score >= ko_hits$threshold,
    ko_hits$sequence_score >= ko_hits$threshold
  )

  pfam_tbl <- tempfile(fileext = ".tblout")
  run_or_stop(hmmsearch, c("--noali", "--cpu", "2", "--cut_ga", "--tblout", pfam_tbl,
                           pfam_m9, fasta))
  pfam_hits <- read_tblout(pfam_tbl)
  unlink(pfam_tbl)
  pfam_hits$namespace <- rep("PFAM", nrow(pfam_hits))
  pfam_hits$accession <- rep("PF01752", nrow(pfam_hits))
  pfam_hits$threshold <- rep(NA_real_, nrow(pfam_hits))
  pfam_hits$score_type <- rep("Pfam_GA", nrow(pfam_hits))
  pfam_hits$called <- rep(TRUE, nrow(pfam_hits))

  hits <- rbind(
    ko_hits[c("gene_id", "namespace", "accession", "profile_name", "profile_accession",
              "sequence_score", "domain_score", "threshold", "score_type", "called")],
    pfam_hits[c("gene_id", "namespace", "accession", "profile_name", "profile_accession",
                "sequence_score", "domain_score", "threshold", "score_type", "called")]
  )
  hits$candidate_id <- candidate$candidate_id
  hits$assembly_accession <- candidate$assembly_accession
  all_hits[[i]] <- hits[c("candidate_id", "assembly_accession", "gene_id", "namespace", "accession",
                          "profile_name", "profile_accession", "sequence_score", "domain_score",
                          "threshold", "score_type", "called")]

  annotations <- hits[hits$called & hits$accession %in% c("K01387", "PF01752"),
                      c("gene_id", "namespace", "accession"), drop = FALSE]
  result <- evaluate_gifts(annotations, db = connection, max_genes = Inf)
  collagen <- result$gifts[result$gifts$gift_id == "collagen_cleavage", , drop = FALSE]
  if (nrow(collagen) != 1L) stop("Pinned database does not contain collagen_cleavage", call. = FALSE)
  m9_called <- isTRUE(collagen$complete[[1L]])
  evidence_class <- if (m9_called) "specific_evidence" else if (nzchar(control_header)) {
    "broad_marker_only"
  } else {
    "no_relevant_marker"
  }
  trace <- trace_gift(result, "collagen_cleavage")
  if (nrow(trace)) {
    trace$candidate_id <- candidate$candidate_id
    trace$assembly_accession <- candidate$assembly_accession
    trace_rows[[i]] <- trace
  }

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
    m9_ko_k01387_genes = collapse_or_empty(hits$gene_id[hits$called & hits$accession == "K01387"]),
    m9_pfam_pf01752_genes = collapse_or_empty(hits$gene_id[hits$called & hits$accession == "PF01752"]),
    broad_control_named_protein = control_header,
    marker_evidence_class = evidence_class,
    collagen_cleavage_complete = m9_called,
    best_route = collagen$best_implementation[[1L]],
    minimum_missing_requirements = collagen$minimum_missing_requirements[[1L]],
    record_status = "candidate_annotation_audit_not_prospective_observation",
    stringsAsFactors = FALSE
  )
}

manifest <- data.frame(
  input_kind = c("proteome", "proteome", "KOfam_library", "KOfam_threshold_table",
                 "KOfam_model", "Pfam_model", "database"),
  identifier = c(candidates$assembly_accession, "curated-ko.hmm", "ko_list.gz",
                 "K01387", "PF01752.24", database_version),
  source = c(candidates$protein_fasta_url,
             "https://www.genome.jp/ftp/db/kofam/profiles.tar.gz",
             "https://www.genome.jp/ftp/db/kofam/ko_list.gz",
             "extracted from curated-ko.hmm",
             "https://www.ebi.ac.uk/interpro/entry/pfam/PF01752/",
             normalizePath(database_path)),
  sha256 = c(vapply(proteome_paths, sha256, character(1)), sha256(kofam_library),
             sha256(kofam_thresholds), vapply(model_paths, sha256, character(1)),
             sha256(pfam_m9), sha256(database_path)),
  call_rule = c(rep("exact NCBI protein FASTA", 2L),
                "content-addressed source library", "Kofam adaptive threshold table",
                paste0(ko_list$score_type[[1L]], " score >= ", ko_list$threshold[[1L]]),
                "HMMER --cut_ga", "gifter database used for the final call"),
  stringsAsFactors = FALSE
)

write_tsv(do.call(rbind, audit_rows), file.path(output_dir, "candidate-annotation-audit.tsv"))
write_tsv(do.call(rbind, all_hits), file.path(output_dir, "candidate-marker-hits.tsv"))
write_tsv(manifest, file.path(output_dir, "input-manifest.tsv"))
if (length(trace_rows)) {
  write_tsv(do.call(rbind, trace_rows), file.path(output_dir, "collagen-gift-trace.tsv"))
} else {
  write_tsv(data.frame(candidate_id = character(), assembly_accession = character()),
            file.path(output_dir, "collagen-gift-trace.tsv"))
}

cat("Priority 1 collagen candidate annotation audit\n")
cat("---------------------------------------------\n")
cat("  database version: ", database_version, "\n", sep = "")
cat("  candidate assemblies: ", nrow(candidates), "\n", sep = "")
cat("  output: ", output_dir, "\n", sep = "")
cat("  status: candidate annotation audit only; no prospective assay observation was read.\n")
