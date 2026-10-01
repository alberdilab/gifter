#!/usr/bin/env Rscript
# Priority 1 aspartate-chemoreception candidate annotation audit.
#
# This evaluates the exact candidate assemblies under the regulatory circuit
# contract. It separately records generic MCP evidence (KO:K03406), which may
# support the core chemotaxis circuit but must never complete the Tar-dependent
# aspartate claim. The output contains no phenotype observation.
#
# Usage:
#   Rscript manuscript/analysis/14-priority1-aspartate-chemoreception-annotation.R \
#     --proteomes=manuscript/analysis/.cache/prospective/aspartate/proteomes \
#     [--database=inst/extdata/gifter.sqlite] \
#     [--output=manuscript/analysis/prospective/aspartate-chemoreception-annotation-audit]

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

root <- getwd()
candidates_path <- path_or_stop(
  file.path(root, "manuscript/analysis/prospective/aspartate-chemoreception-candidates.tsv"),
  "aspartate candidate roster"
)
inputs_path <- path_or_stop(
  file.path(root, "manuscript/analysis/prospective/aspartate-chemoreception-annotation-inputs.tsv"),
  "aspartate annotation input manifest"
)
database_path <- path_or_stop(option("database", "inst/extdata/gifter.sqlite"), "database")
proteome_dir <- normalizePath(option(
  "proteomes", "manuscript/analysis/.cache/prospective/aspartate/proteomes"
), mustWork = FALSE)
output_dir <- normalizePath(option(
  "output", "manuscript/analysis/prospective/aspartate-chemoreception-annotation-audit"
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
machinery <- get_gift_machinery("aspartate_chemoreception", db = connection)
required_kos <- sort(unique(machinery$accession[machinery$namespace == "KO"]))
broad_mcp <- "K03406"
audit_kos <- sort(unique(c(required_kos, broad_mcp)))
if (broad_mcp %in% required_kos || length(required_kos) != 6L) {
  stop("Pinned database no longer has the expected Tar-specific circuit contract", call. = FALSE)
}

if (!file.exists(paste0(kofam_library, ".ssi"))) run_or_stop(hmmfetch, c("--index", kofam_library))
model_dir <- tempfile("aspartate-chemoreception-models-")
dir.create(model_dir)
on.exit(unlink(model_dir, recursive = TRUE), add = TRUE)
model_paths <- vapply(audit_kos, function(accession)
  extract_kofam_model(hmmfetch, kofam_library, accession, model_dir), character(1))
combined_kofam <- file.path(model_dir, "aspartate-chemoreception.hmm")
writeLines(unlist(lapply(model_paths, readLines, warn = FALSE)), combined_kofam, useBytes = TRUE)

ko_list <- utils::read.delim(gzfile(kofam_thresholds), quote = "", comment.char = "",
                             stringsAsFactors = FALSE)
names(ko_list)[[1L]] <- "accession"
ko_list <- ko_list[ko_list$accession %in% audit_kos, c("accession", "threshold", "score_type"), drop = FALSE]
ko_list$threshold <- suppressWarnings(as.numeric(ko_list$threshold))
if (!setequal(ko_list$accession, audit_kos) || anyNA(ko_list$threshold) ||
    any(!ko_list$score_type %in% c("full", "domain"))) {
  stop("KOfam threshold table does not provide valid rules for this circuit", call. = FALSE)
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
  hits$namespace <- rep("KO", nrow(hits))
  hits$accession <- hits$profile_name
  hits$threshold <- ko_list$threshold[match(hits$accession, ko_list$accession)]
  hits$score_type <- ko_list$score_type[match(hits$accession, ko_list$accession)]
  hits$called <- ifelse(
    hits$score_type == "domain", hits$domain_score >= hits$threshold,
    hits$sequence_score >= hits$threshold
  )
  hits$candidate_id <- candidate$candidate_id
  hits$assembly_accession <- candidate$assembly_accession
  all_hits[[i]] <- hits[c("candidate_id", "assembly_accession", "gene_id", "namespace", "accession",
                          "profile_name", "profile_accession", "sequence_score", "domain_score",
                          "threshold", "score_type", "called")]

  annotations <- hits[hits$called, c("gene_id", "namespace", "accession"), drop = FALSE]
  result <- evaluate_gifts(annotations, db = connection, max_genes = Inf)
  aspartate <- result$gifts[result$gifts$gift_id == "aspartate_chemoreception", , drop = FALSE]
  core <- result$gifts[result$gifts$gift_id == "chemotaxis_signal_transduction", , drop = FALSE]
  if (nrow(aspartate) != 1L || nrow(core) != 1L) stop("Pinned database lacks a required chemotaxis GIFT", call. = FALSE)
  marker_class <- if (isTRUE(aspartate$complete[[1L]])) "specific_evidence" else if (
    any(hits$called & hits$accession == broad_mcp)
  ) {
    "broad_marker_only"
  } else {
    "no_relevant_marker"
  }
  for (gift_id in c("aspartate_chemoreception", "chemotaxis_signal_transduction")) {
    trace <- trace_gift(result, gift_id)
    trace$candidate_id <- candidate$candidate_id
    trace$assembly_accession <- candidate$assembly_accession
    trace_rows[[paste(candidate$candidate_id, gift_id, sep = "::")]] <- trace
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
    tar_k05875_genes = collapse_or_empty(hits$gene_id[hits$called & hits$accession == "K05875"]),
    generic_mcp_k03406_genes = collapse_or_empty(hits$gene_id[hits$called & hits$accession == broad_mcp]),
    required_circuit_marker_genes = collapse_or_empty(hits$gene_id[hits$called & hits$accession %in% required_kos]),
    marker_evidence_class = marker_class,
    aspartate_chemoreception_complete = aspartate$complete[[1L]],
    aspartate_minimum_missing_requirements = aspartate$minimum_missing_requirements[[1L]],
    chemotaxis_core_complete = core$complete[[1L]],
    chemotaxis_core_minimum_missing_requirements = core$minimum_missing_requirements[[1L]],
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
                "content-addressed source library", "Kofam adaptive threshold table", model_rules,
                "gifter database used for final circuit calls"),
  stringsAsFactors = FALSE
)

write_tsv(do.call(rbind, audit_rows), file.path(output_dir, "candidate-annotation-audit.tsv"))
write_tsv(do.call(rbind, all_hits), file.path(output_dir, "candidate-marker-hits.tsv"))
write_tsv(manifest, file.path(output_dir, "input-manifest.tsv"))
write_tsv(do.call(rbind, trace_rows), file.path(output_dir, "chemotaxis-gift-traces.tsv"))

cat("Priority 1 aspartate-chemoreception candidate annotation audit\n")
cat("---------------------------------------------------------------\n")
cat("  database version: ", database_version, "\n", sep = "")
cat("  candidate assemblies: ", nrow(candidates), "\n", sep = "")
cat("  output: ", output_dir, "\n", sep = "")
cat("  status: candidate annotation audit only; no prospective assay observation was read.\n")
