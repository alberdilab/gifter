#!/usr/bin/env Rscript
# Priority 1 starch-specificity candidate annotation audit.
#
# This audit evaluates the exact candidate proteomes with the published KOfam
# and dbCAN filters.  It keeps two gifter inputs: all marker rows that map to
# the curated route, and the subset whose curated confidence is resolving
# (high-confidence or curated).  The second is a diagnostic, not a replacement
# evaluator.  Comparing them makes it explicit whether broad CAZy evidence is
# currently able to license the named starch claim.
#
# Usage:
#   Rscript manuscript/analysis/15-priority1-starch-annotation.R \
#     --proteomes=manuscript/analysis/.cache/prospective/starch/proteomes \
#     [--database=inst/extdata/gifter.sqlite] \
#     [--output=manuscript/analysis/prospective/starch-annotation-audit]

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

# hmmsearch writes the sequence first and the query profile in field 4 of a
# domain table. Coverage is consequently over the profile (column 6), exactly as in the
# published dbCAN filter used by manuscript/analysis/05-annotation-route.R.
read_domtblout <- function(path) {
  empty <- data.frame(
    gene_id = character(), profile_name = character(), profile_accession = character(),
    sequence_score = numeric(), domain_score = numeric(), i_evalue = numeric(),
    model_length = numeric(), hmm_from = numeric(), hmm_to = numeric(), stringsAsFactors = FALSE
  )
  lines <- grep("^#", readLines(path, warn = FALSE), value = TRUE, invert = TRUE)
  lines <- lines[nzchar(trimws(lines))]
  if (!length(lines)) return(empty)
  fields <- strsplit(trimws(lines), "[[:space:]]+")
  data.frame(
    gene_id = vapply(fields, `[`, character(1), 1L),
    profile_name = sub("[.]hmm$", "", sub("[|].*$", "", vapply(fields, `[`, character(1), 4L))),
    profile_accession = vapply(fields, `[`, character(1), 5L),
    sequence_score = as.numeric(vapply(fields, `[`, character(1), 8L)),
    domain_score = as.numeric(vapply(fields, `[`, character(1), 14L)),
    i_evalue = as.numeric(vapply(fields, `[`, character(1), 13L)),
    model_length = as.numeric(vapply(fields, `[`, character(1), 6L)),
    hmm_from = as.numeric(vapply(fields, `[`, character(1), 16L)),
    hmm_to = as.numeric(vapply(fields, `[`, character(1), 17L)),
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

component_marker_summary <- function(marker_rows) {
  keys <- unique(marker_rows[c("namespace", "accession")])
  do.call(rbind, lapply(seq_len(nrow(keys)), function(i) {
    rows <- marker_rows[
      marker_rows$namespace == keys$namespace[[i]] &
        marker_rows$accession == keys$accession[[i]], , drop = FALSE
    ]
    data.frame(
      namespace = keys$namespace[[i]],
      accession = keys$accession[[i]],
      component_ids = collapse_or_empty(rows$component_id),
      evidence_types = collapse_or_empty(rows$evidence_type),
      confidences = collapse_or_empty(rows$confidence),
      stringsAsFactors = FALSE
    )
  }))
}

gift_call <- function(result, gift_id) {
  call <- result$gifts[result$gifts$gift_id == gift_id, , drop = FALSE]
  if (nrow(call) != 1L) stop("Pinned database does not contain ", gift_id, call. = FALSE)
  call
}

root <- getwd()
gift_id <- "starch_degradation"
candidates_path <- path_or_stop(
  file.path(root, "manuscript/analysis/prospective/starch-specificity-candidates.tsv"),
  "starch candidate roster"
)
inputs_path <- path_or_stop(
  file.path(root, "manuscript/analysis/prospective/starch-annotation-inputs.tsv"),
  "starch annotation input manifest"
)
database_path <- path_or_stop(option("database", "inst/extdata/gifter.sqlite"), "database")
proteome_dir <- normalizePath(option(
  "proteomes", "manuscript/analysis/.cache/prospective/starch/proteomes"
), mustWork = FALSE)
output_dir <- normalizePath(option(
  "output", "manuscript/analysis/prospective/starch-annotation-audit"
), mustWork = FALSE)
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

profile_dir <- path_or_stop("manuscript/analysis/.cache/annotation/profiles", "annotation profile directory")
kofam_library <- path_or_stop(file.path(profile_dir, "curated-ko.hmm"), "curated KOfam library")
kofam_thresholds <- path_or_stop(file.path(profile_dir, "ko_list.gz"), "KOfam threshold table")
dbcan_family <- path_or_stop(file.path(profile_dir, "dbcan-family.hmm"), "dbCAN family library")
dbcan_sub <- path_or_stop(file.path(profile_dir, "dbcan-sub.hmm"), "dbCAN subfamily library")
dbcan_sizes_path <- path_or_stop(file.path(profile_dir, "dbcan-library-sizes.tsv"), "dbCAN library-size table")
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
if (nrow(candidates) != 2L || !setequal(candidates$role, c("specific-positive", "broad-marker control"))) {
  stop("Candidate roster must contain one specific-positive and one broad-marker control", call. = FALSE)
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
routes <- get_gift_routes(gift_id, db = connection)
reactions <- get_gift_reactions(gift_id, db = connection)
if (nrow(routes) != 1L || sum(reactions$required == 1L) != 2L) {
  stop("Pinned database no longer has the expected two-reaction starch route", call. = FALSE)
}

# The audit reads the compiled database rather than duplicating an evidence
# list. This keeps route, component, marker, confidence and trace vocabulary
# bound to exactly the database whose call is reported.
marker_rows <- DBI::dbGetQuery(connection, paste(
  "SELECT DISTINCT gr.route_id, r.reaction_id, ec.component_id,",
  "m.namespace, m.accession, cm.evidence_type, cm.confidence",
  "FROM gift g",
  "JOIN gift_route gr ON gr.gift_pk = g.gift_pk",
  "JOIN route_reaction rr ON rr.route_pk = gr.route_pk",
  "JOIN reaction r ON r.reaction_pk = rr.reaction_pk",
  "JOIN enzyme_system es ON es.reaction_pk = r.reaction_pk",
  "JOIN enzyme_component ec ON ec.system_pk = es.system_pk",
  "JOIN component_marker cm ON cm.component_pk = ec.component_pk",
  "JOIN marker m ON m.marker_pk = cm.marker_pk",
  "WHERE g.gift_id =", DBI::dbQuoteString(connection, gift_id), "AND rr.required = 1",
  "ORDER BY r.reaction_id, ec.component_id, m.namespace, m.accession"
))
if (!setequal(unique(marker_rows$component_id), c("COMP_AMYLASE", "COMP_GLUCOSIDASE"))) {
  stop("Pinned database no longer has the expected starch components", call. = FALSE)
}
marker_metadata <- component_marker_summary(marker_rows)
audit_kos <- sort(unique(marker_rows$accession[marker_rows$namespace == "KO"]))
audit_cazy <- sort(unique(marker_rows$accession[marker_rows$namespace == "CAZY"]))
if (!length(audit_kos) || !length(audit_cazy)) stop("Pinned starch route lacks expected marker namespaces", call. = FALSE)

if (!file.exists(paste0(kofam_library, ".ssi"))) run_or_stop(hmmfetch, c("--index", kofam_library))
model_dir <- tempfile("starch-specificity-models-")
dir.create(model_dir)
on.exit(unlink(model_dir, recursive = TRUE), add = TRUE)
kofam_paths <- vapply(audit_kos, function(accession)
  extract_kofam_model(hmmfetch, kofam_library, accession, model_dir), character(1))
combined_kofam <- file.path(model_dir, "starch-specificity-kofam.hmm")
writeLines(unlist(lapply(kofam_paths, readLines, warn = FALSE)), combined_kofam, useBytes = TRUE)

ko_list <- utils::read.delim(gzfile(kofam_thresholds), quote = "", comment.char = "",
                             stringsAsFactors = FALSE)
names(ko_list)[[1L]] <- "accession"
ko_list <- ko_list[ko_list$accession %in% audit_kos, c("accession", "threshold", "score_type"), drop = FALSE]
ko_list$threshold <- suppressWarnings(as.numeric(ko_list$threshold))
if (!setequal(ko_list$accession, audit_kos) || anyNA(ko_list$threshold) ||
    any(!ko_list$score_type %in% c("full", "domain"))) {
  stop("KOfam threshold table does not provide valid rules for the starch markers", call. = FALSE)
}

dbcan_sizes <- utils::read.delim(dbcan_sizes_path, header = FALSE,
                                 col.names = c("source_file", "profiles_kept", "library_size"),
                                 stringsAsFactors = FALSE)
dbcan_libraries <- data.frame(
  source_file = c("dbCAN.hmm", "dbCAN_sub.hmm"),
  profile_library = c(dbcan_family, dbcan_sub),
  stringsAsFactors = FALSE
)
dbcan_libraries$library_size <- dbcan_sizes$library_size[
  match(dbcan_libraries$source_file, dbcan_sizes$source_file)
]
if (anyNA(dbcan_libraries$library_size)) stop("dbCAN library-size table lacks a required source library", call. = FALSE)

hmmsearch_help <- system2(hmmsearch, "-h", stdout = TRUE)
hmmsearch_version <- sub("^#[[:space:]]*", "", grep("^#[[:space:]]*HMMER[[:space:]]", hmmsearch_help,
                                                         value = TRUE)[[1L]])
run_at <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
resolving_keys <- paste(
  marker_rows$namespace[marker_rows$confidence %in% c("high-confidence", "curated")],
  marker_rows$accession[marker_rows$confidence %in% c("high-confidence", "curated")], sep = "::"
)

all_hits <- list()
audit_rows <- list()
trace_rows <- list()
for (i in seq_len(nrow(candidates))) {
  candidate <- candidates[i, , drop = FALSE]
  proteome <- proteome_paths[[i]]
  fasta <- read_fasta_gz(proteome)
  on.exit(unlink(fasta), add = TRUE)

  ko_tbl <- tempfile(fileext = ".tblout")
  run_or_stop(hmmsearch, c("--noali", "--cpu", "2", "-T", "0", "--tblout", ko_tbl,
                           combined_kofam, fasta))
  ko_hits <- read_tblout(ko_tbl)
  unlink(ko_tbl)
  ko_hits$namespace <- "KO"
  ko_hits$accession <- ko_hits$profile_name
  ko_hits$threshold <- ko_list$threshold[match(ko_hits$accession, ko_list$accession)]
  ko_hits$score_type <- ko_list$score_type[match(ko_hits$accession, ko_list$accession)]
  ko_hits$coverage <- NA_real_
  ko_hits$i_evalue <- NA_real_
  ko_hits$called <- ifelse(
    ko_hits$score_type == "domain", ko_hits$domain_score >= ko_hits$threshold,
    ko_hits$sequence_score >= ko_hits$threshold
  )

  cazy_hits <- do.call(rbind, lapply(seq_len(nrow(dbcan_libraries)), function(j) {
    dom <- tempfile(fileext = ".domtblout")
    run_or_stop(hmmsearch, c("--noali", "--cpu", "2", "-Z",
                             format(dbcan_libraries$library_size[[j]], scientific = FALSE),
                             "--domtblout", dom, dbcan_libraries$profile_library[[j]], fasta))
    hits <- read_domtblout(dom)
    unlink(dom)
    if (!nrow(hits)) return(NULL)
    hits <- hits[hits$profile_name %in% audit_cazy, , drop = FALSE]
    if (!nrow(hits)) return(NULL)
    hits$namespace <- "CAZY"
    hits$accession <- hits$profile_name
    hits$coverage <- (hits$hmm_to - hits$hmm_from) / hits$model_length
    hits$threshold <- paste0("i-E < 1e-15; coverage > 0.35; -Z ", dbcan_libraries$library_size[[j]])
    hits$score_type <- "dbCAN_i-E_and_profile_coverage"
    hits$called <- hits$i_evalue < 1e-15 & hits$coverage > 0.35
    hits
  }))
  if (is.null(cazy_hits)) {
    cazy_hits <- data.frame(
      gene_id = character(), profile_name = character(), profile_accession = character(),
      sequence_score = numeric(), domain_score = numeric(), i_evalue = numeric(),
      model_length = numeric(), hmm_from = numeric(), hmm_to = numeric(), namespace = character(),
      accession = character(), coverage = numeric(), threshold = character(), score_type = character(),
      called = logical(), stringsAsFactors = FALSE
    )
  }
  ko_hits$model_length <- NA_real_
  ko_hits$hmm_from <- NA_real_
  ko_hits$hmm_to <- NA_real_
  hits <- rbind(
    ko_hits[c("gene_id", "namespace", "accession", "profile_name", "profile_accession",
              "sequence_score", "domain_score", "i_evalue", "model_length", "hmm_from", "hmm_to",
              "coverage", "threshold", "score_type", "called")],
    cazy_hits[c("gene_id", "namespace", "accession", "profile_name", "profile_accession",
               "sequence_score", "domain_score", "i_evalue", "model_length", "hmm_from", "hmm_to",
               "coverage", "threshold", "score_type", "called")]
  )
  metadata_index <- match(paste(hits$namespace, hits$accession),
                          paste(marker_metadata$namespace, marker_metadata$accession))
  hits$component_ids <- marker_metadata$component_ids[metadata_index]
  hits$evidence_types <- marker_metadata$evidence_types[metadata_index]
  hits$confidences <- marker_metadata$confidences[metadata_index]
  hits$candidate_id <- candidate$candidate_id
  hits$assembly_accession <- candidate$assembly_accession
  all_hits[[i]] <- hits[c("candidate_id", "assembly_accession", "gene_id", "namespace", "accession",
                          "profile_name", "profile_accession", "sequence_score", "domain_score", "i_evalue",
                          "model_length", "hmm_from", "hmm_to", "coverage", "threshold", "score_type",
                          "called", "component_ids", "evidence_types", "confidences")]

  all_annotations <- hits[hits$called, c("gene_id", "namespace", "accession"), drop = FALSE]
  resolving_annotations <- all_annotations[
    paste(all_annotations$namespace, all_annotations$accession, sep = "::") %in% resolving_keys,
    , drop = FALSE
  ]
  raw_result <- evaluate_gifts(all_annotations, db = connection, max_genes = Inf)
  resolving_result <- evaluate_gifts(resolving_annotations, db = connection, max_genes = Inf)
  raw_call <- gift_call(raw_result, gift_id)
  resolving_call <- gift_call(resolving_result, gift_id)
  broad_family_only <- nrow(all_annotations) > 0L &&
    !any(all_annotations$namespace == "KO") &&
    any(all_annotations$namespace == "CAZY") &&
    !nrow(resolving_annotations)
  marker_class <- if (isTRUE(resolving_call$complete[[1L]])) {
    "specific_evidence"
  } else if (broad_family_only) {
    "broad_marker_only"
  } else {
    "no_complete_resolving_evidence"
  }
  if (candidate$role[[1L]] == "specific-positive" && !isTRUE(resolving_call$complete[[1L]])) {
    stop("Specific-positive candidate lacks a complete resolving starch route", call. = FALSE)
  }
  if (candidate$role[[1L]] == "broad-marker control" && !broad_family_only) {
    stop("Broad-marker control is not limited to broad CAZy evidence", call. = FALSE)
  }

  for (evidence_set in c("all_curated_marker_rows", "substrate_resolving_marker_rows")) {
    result <- if (evidence_set == "all_curated_marker_rows") raw_result else resolving_result
    trace <- trace_gift(result, gift_id)
    trace$candidate_id <- candidate$candidate_id
    trace$assembly_accession <- candidate$assembly_accession
    trace$annotation_evidence_set <- evidence_set
    trace_rows[[paste(candidate$candidate_id, evidence_set, sep = "::")]] <- trace
  }

  cazy_called <- hits$called & hits$namespace == "CAZY"
  resolving_called <- hits$called & paste(hits$namespace, hits$accession, sep = "::") %in% resolving_keys
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
    route_id = routes$route_id[[1L]],
    all_called_marker_genes = collapse_or_empty(all_annotations$gene_id),
    resolving_marker_genes = collapse_or_empty(hits$gene_id[resolving_called]),
    broad_cazy_marker_genes = collapse_or_empty(hits$gene_id[cazy_called & !resolving_called]),
    marker_evidence_class = marker_class,
    all_curated_marker_rows_complete = raw_call$complete[[1L]],
    all_curated_marker_rows_confidence = raw_call$evidence_confidence[[1L]],
    all_curated_marker_rows_minimum_missing_requirements = raw_call$minimum_missing_requirements[[1L]],
    substrate_resolving_marker_rows_complete = resolving_call$complete[[1L]],
    substrate_resolving_marker_rows_minimum_missing_requirements = resolving_call$minimum_missing_requirements[[1L]],
    broad_marker_only_completes_named_claim = broad_family_only && raw_call$complete[[1L]],
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
                 rep("KOfam_model", length(audit_kos)), "dbCAN_family_library", "dbCAN_subfamily_library",
                 "dbCAN_library_size_table", "database"),
  identifier = c(candidates$assembly_accession, "curated-ko.hmm", "ko_list.gz", audit_kos,
                 "dbCAN.hmm", "dbCAN_sub.hmm", "dbcan-library-sizes.tsv", database_version),
  source = c(candidates$protein_fasta_url,
             "https://www.genome.jp/ftp/db/kofam/profiles.tar.gz",
             "https://www.genome.jp/ftp/db/kofam/ko_list.gz",
             rep("extracted from curated-ko.hmm", length(audit_kos)),
             "https://dbcan.s3.us-west-2.amazonaws.com/db_v5-2-9_5-5-2026/dbCAN.hmm",
             "https://dbcan.s3.us-west-2.amazonaws.com/db_v5-2-9_5-5-2026/dbCAN_sub.hmm",
             "derived during manuscript/analysis/05-annotation-route.R",
             normalizePath(database_path)),
  sha256 = c(vapply(proteome_paths, sha256, character(1)), sha256(kofam_library),
             sha256(kofam_thresholds), vapply(kofam_paths, sha256, character(1)),
             sha256(dbcan_family), sha256(dbcan_sub), sha256(dbcan_sizes_path), sha256(database_path)),
  call_rule = c(rep("exact NCBI protein FASTA", nrow(candidates)),
                "content-addressed source library", "KOfam adaptive threshold table", model_rules,
                "dbCAN i-E < 1e-15; profile coverage > 0.35; -Z 875",
                "dbCAN i-E < 1e-15; profile coverage > 0.35; -Z 53411",
                "pins full dbCAN library sizes used with filtered HMM files",
                "gifter database used for final route calls"),
  stringsAsFactors = FALSE
)

write_tsv(do.call(rbind, audit_rows), file.path(output_dir, "candidate-annotation-audit.tsv"))
write_tsv(do.call(rbind, all_hits), file.path(output_dir, "candidate-marker-hits.tsv"))
write_tsv(do.call(rbind, trace_rows), file.path(output_dir, "starch-gift-traces.tsv"))
write_tsv(manifest, file.path(output_dir, "input-manifest.tsv"))

cat("Priority 1 starch-specificity candidate annotation audit\n")
cat("------------------------------------------------------\n")
cat("  database version: ", database_version, "\n", sep = "")
cat("  candidate assemblies: ", nrow(candidates), "\n", sep = "")
cat("  output: ", output_dir, "\n", sep = "")
cat("  status: candidate annotation audit only; no prospective assay observation was read.\n")
