#!/usr/bin/env Rscript
# Priority 2: matched isolate and MAG-like-draft annotation robustness.
#
# This is an annotation/assembly audit, not a MAG benchmark or biological
# validation experiment.  It starts with the exact PacBio isolate assembly and
# its linked single-isolate WGS read run, makes one deterministic read subset,
# and reassembles that subset de novo.  The result is a MAG-like draft only: no
# metagenome, bin, contamination estimate, assay, or phenotype is supplied.
#
# Usage:
#   Rscript manuscript/analysis/17-priority2-matched-mag-robustness.R \
#     [--cache=manuscript/analysis/.cache/prospective/matched-mag-robustness] \
#     [--profiles=manuscript/analysis/.cache/annotation/profiles] \
#     [--database=inst/extdata/gifter.sqlite] \
#     [--output=manuscript/analysis/prospective/matched-mag-robustness-audit] \
#     [--threads=4]

suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
option <- function(name, default) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (!length(hit)) return(default)
  sub(paste0("^--", name, "="), "", hit[[1L]])
}

path_or_stop <- function(path, label) {
  if (!file.exists(path)) stop(label, " does not exist: ", path, call. = FALSE)
  normalizePath(path, mustWork = TRUE)
}

write_tsv <- function(x, path) {
  utils::write.table(x, path, sep = "\t", row.names = FALSE, quote = FALSE, na = "")
  # Keep a valid, rectangular-header TSV while omitting terminal absent values;
  # otherwise R leaves trailing tab whitespace in type-specific trace rows.
  lines <- readLines(path, warn = FALSE)
  writeLines(sub("\\t+$", "", lines), path, useBytes = TRUE)
  invisible(path)
}

# `trace_gift()` deliberately exposes type-specific columns.  This audit spans
# every GIFT type, so retain their union rather than dropping a type's evidence
# merely to make base `rbind()` accept the rows.
rbind_fill <- function(rows) {
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) return(NULL)
  columns <- unique(unlist(lapply(rows, names), use.names = FALSE))
  rows <- lapply(rows, function(row) {
    missing <- setdiff(columns, names(row))
    for (column in missing) row[[column]] <- NA
    row[, columns, drop = FALSE]
  })
  do.call(rbind, rows)
}

sha256 <- function(path) {
  result <- system2("shasum", c("-a", "256", path), stdout = TRUE, stderr = TRUE)
  if (!is.null(attr(result, "status")) && attr(result, "status") != 0L)
    stop("Could not calculate SHA-256 for ", path, call. = FALSE)
  value <- sub("[[:space:]].*$", "", result[[1L]])
  if (!grepl("^[0-9a-f]{64}$", value)) stop("Invalid SHA-256 for ", path, call. = FALSE)
  value
}

md5 <- function(path) unname(tools::md5sum(path)[[1L]])

collapse_or_empty <- function(x) {
  x <- sort(unique(as.character(x[!is.na(x) & nzchar(x)])))
  if (length(x)) paste(x, collapse = ";") else ""
}

run_or_stop <- function(command, arguments, stdout = NULL, stderr = NULL) {
  status <- system2(command, arguments, stdout = stdout, stderr = stderr)
  if (!identical(status, 0L)) {
    stop("Command failed: ", command, " ", paste(arguments, collapse = " "), call. = FALSE)
  }
  invisible(NULL)
}

command_version <- function(command, arguments = "--version", pattern = NULL) {
  output <- system2(command, arguments, stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status")
  if (!is.null(status) && status != 0L) stop("Could not obtain version for ", command, call. = FALSE)
  output <- trimws(output[nzchar(trimws(output))])
  if (!is.null(pattern)) {
    matched <- output[grepl(pattern, output)]
    if (length(matched)) output <- matched
  }
  output[[1L]]
}

fetch_verified <- function(url, destination, expected_md5 = NULL) {
  dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
  valid <- function(path) {
    file.exists(path) && file.size(path) > 0 &&
      (is.null(expected_md5) || identical(tolower(md5(path)), tolower(expected_md5)))
  }
  if (valid(destination)) return(normalizePath(destination, mustWork = TRUE))
  partial <- paste0(destination, ".partial")
  if (file.exists(destination) && !file.rename(destination, partial)) {
    stop("Could not retain invalid partial download for resumable retrieval: ", destination, call. = FALSE)
  }
  curl <- Sys.which("curl")
  if (!nzchar(curl)) stop("curl is required to retrieve the pinned public input", call. = FALSE)
  for (attempt in seq_len(5L)) {
    status <- system2(curl, c("--fail", "--location", "--retry", "3", "--retry-all-errors",
                              "--connect-timeout", "30", "--speed-limit", "10240", "--speed-time", "60",
                              "--max-time", "600",
                              "--continue-at", "-", "--output", partial, url))
    if (identical(status, 0L) && valid(partial)) {
      if (file.exists(destination)) unlink(destination)
      if (!file.rename(partial, destination)) stop("Could not finalize verified download", call. = FALSE)
      return(normalizePath(destination, mustWork = TRUE))
    }
    # A server can close a byte-range response at the advertised length while
    # still yielding corrupt bytes.  A checksum mismatch after a successful
    # transfer is therefore not resumable: preserve it for diagnosis and begin
    # the next attempt at byte zero rather than appending to bad gzip data.
    if (identical(status, 0L) && file.exists(partial) && !valid(partial)) {
      invalid <- paste0(partial, ".invalid-checksum-attempt", attempt)
      if (!file.rename(partial, invalid)) stop("Could not preserve invalid download for diagnosis", call. = FALSE)
    }
    message("  pinned download is incomplete or has the wrong checksum; resuming attempt ", attempt + 1L, "/5")
  }
  stop("Could not retrieve a checksum-matching input after five resumable attempts: ", url, call. = FALSE)
}

read_tblout <- function(path) {
  empty <- data.frame(
    target = character(), profile_name = character(), profile_accession = character(),
    sequence_score = numeric(), domain_score = numeric(), stringsAsFactors = FALSE
  )
  lines <- grep("^#", readLines(path, warn = FALSE), value = TRUE, invert = TRUE)
  lines <- lines[nzchar(trimws(lines))]
  if (!length(lines)) return(empty)
  fields <- strsplit(trimws(lines), "[[:space:]]+")
  data.frame(
    target = vapply(fields, `[`, character(1), 1L),
    profile_name = vapply(fields, `[`, character(1), 3L),
    profile_accession = vapply(fields, `[`, character(1), 4L),
    sequence_score = as.numeric(vapply(fields, `[`, character(1), 6L)),
    domain_score = as.numeric(vapply(fields, `[`, character(1), 9L)),
    stringsAsFactors = FALSE
  )
}

read_domtblout <- function(path) {
  empty <- data.frame(
    sequence = character(), model = character(), model_length = numeric(),
    i_evalue = numeric(), hmm_from = numeric(), hmm_to = numeric(), stringsAsFactors = FALSE
  )
  lines <- grep("^#", readLines(path, warn = FALSE), value = TRUE, invert = TRUE)
  lines <- lines[nzchar(trimws(lines))]
  if (!length(lines)) return(empty)
  fields <- strsplit(trimws(lines), "[[:space:]]+")
  data.frame(
    sequence = vapply(fields, `[`, character(1), 1L),
    model = vapply(fields, `[`, character(1), 4L),
    model_length = as.numeric(vapply(fields, `[`, character(1), 6L)),
    i_evalue = as.numeric(vapply(fields, `[`, character(1), 13L)),
    hmm_from = as.numeric(vapply(fields, `[`, character(1), 16L)),
    hmm_to = as.numeric(vapply(fields, `[`, character(1), 17L)),
    stringsAsFactors = FALSE
  )
}

fasta_statistics <- function(path) {
  reader <- if (grepl("[.]gz$", path)) gzfile(path, "rt") else file(path, "rt")
  on.exit(close(reader), add = TRUE)
  sequences <- 0L
  bases <- 0
  repeat {
    lines <- readLines(reader, n = 10000L, warn = FALSE)
    if (!length(lines)) break
    sequences <- sequences + sum(startsWith(lines, ">"))
    bases <- bases + sum(nchar(lines[!startsWith(lines, ">")]))
  }
  data.frame(sequence_count = sequences, bases = bases, stringsAsFactors = FALSE)
}

# Sampling physical reads, rather than editing genes, makes these real draft
# assemblies.  The fixed seed and one-draw-per-four-line FASTQ record make the
# exact retained molecule set reproducible.  These fractions are inputs, not
# estimates of MAG completeness or quality.
subsample_fastq <- function(input, output, fraction, seed, label) {
  if (file.exists(output)) return(invisible(NULL))
  dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
  in_handle <- gzfile(input, "rt")
  out_handle <- gzfile(output, "wt")
  on.exit(close(in_handle), add = TRUE)
  on.exit(close(out_handle), add = TRUE)
  set.seed(seed)
  record_number <- 0L
  repeat {
    record <- readLines(in_handle, n = 4L, warn = FALSE)
    if (!length(record)) break
    if (length(record) != 4L || !startsWith(record[[1L]], "@")) {
      stop("Raw read input is not a complete four-line FASTQ record", call. = FALSE)
    }
    record_number <- record_number + 1L
    if (stats::runif(1) < fraction) {
      # SRR1284073 has repeated public subread labels.  Flye requires a unique
      # first FASTQ header token, so prefix a deterministic record number while
      # retaining the untouched source header after whitespace for provenance.
      record[[1L]] <- paste0("@", label, "_", record_number, " ", substring(record[[1L]], 2L))
      writeLines(record, out_handle, useBytes = TRUE)
    }
  }
  invisible(NULL)
}

fastq_statistics <- function(path) {
  handle <- gzfile(path, "rt")
  on.exit(close(handle), add = TRUE)
  records <- 0L
  bases <- 0
  repeat {
    record <- readLines(handle, n = 4L, warn = FALSE)
    if (!length(record)) break
    if (length(record) != 4L || !startsWith(record[[1L]], "@")) {
      stop("FASTQ statistics found an incomplete record", call. = FALSE)
    }
    records <- records + 1L
    bases <- bases + nchar(record[[2L]])
  }
  data.frame(reads = records, bases = bases, stringsAsFactors = FALSE)
}

root <- getwd()
inputs_path <- path_or_stop(
  file.path(root, "manuscript/analysis/prospective/matched-mag-robustness-inputs.tsv"),
  "matched MAG robustness input specification"
)
database_path <- path_or_stop(option("database", "inst/extdata/gifter.sqlite"), "database")
cache_dir <- normalizePath(option(
  "cache", "manuscript/analysis/.cache/prospective/matched-mag-robustness"
), mustWork = FALSE)
profiles_dir <- path_or_stop(option(
  "profiles", "manuscript/analysis/.cache/annotation/profiles"
), "annotation-profile directory")
output_dir <- normalizePath(option(
  "output", "manuscript/analysis/prospective/matched-mag-robustness-audit"
), mustWork = FALSE)
threads <- as.integer(option("threads", "4"))
if (is.na(threads) || threads < 1L) stop("threads must be a positive integer", call. = FALSE)
dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

inputs <- utils::read.delim(inputs_path, stringsAsFactors = FALSE, check.names = FALSE)
required_inputs <- c("input_kind", "identifier", "source", "expected_md5", "eligibility_rule")
if (!all(required_inputs %in% names(inputs))) stop("Input specification has changed columns", call. = FALSE)
lookup_input <- function(kind) {
  row <- inputs[inputs$input_kind == kind, , drop = FALSE]
  if (nrow(row) != 1L) stop("Input specification needs exactly one ", kind, " row", call. = FALSE)
  row
}
raw_spec <- lookup_input("pacbio_subreads")
genome_spec <- lookup_input("exact_isolate_genome")

# Candidate ascertainment established that this exact complete assembly and the
# raw WGS run share BioSample SAMN02743420 and BioProject PRJNA237120.  Check
# those fields locally before creating any draft.
if (!identical(raw_spec$biosample[[1L]], genome_spec$biosample[[1L]]) ||
    !identical(raw_spec$bioproject[[1L]], genome_spec$bioproject[[1L]]) ||
    !identical(raw_spec$strain[[1L]], genome_spec$strain[[1L]])) {
  stop("Exact assembly and raw-read provenance are not a matched strain/sample/project", call. = FALSE)
}

raw_fastq <- fetch_verified(
  raw_spec$source[[1L]], file.path(cache_dir, "raw", "SRR1284073_subreads.fastq.gz"),
  raw_spec$expected_md5[[1L]]
)
exact_genome <- fetch_verified(
  genome_spec$source[[1L]], file.path(cache_dir, "raw", "GCA_000801205.1_genomic.fna.gz"),
  genome_spec$expected_md5[[1L]]
)
exact_genome_fna <- file.path(cache_dir, "raw", "GCA_000801205.1_genomic.fna")
if (!file.exists(exact_genome_fna)) run_or_stop("gunzip", c("-c", exact_genome), stdout = exact_genome_fna)

flye <- Sys.which("flye")
prodigal <- Sys.which("prodigal")
if (!nzchar(prodigal)) prodigal <- "/Users/anttonalberdi/panmapper/prodigal"
hmmsearch <- Sys.which("hmmsearch")
if (!nzchar(hmmsearch)) hmmsearch <- "/opt/miniconda3/bin/hmmsearch"
if (any(!file.exists(c(flye, prodigal, hmmsearch)))) {
  stop("Flye, Prodigal 2.6.3 and HMMER hmmsearch must be available", call. = FALSE)
}

ko_library <- path_or_stop(file.path(profiles_dir, "curated-ko.hmm"), "curated KOfam library")
ko_thresholds_path <- path_or_stop(file.path(profiles_dir, "ko_list.gz"), "KOfam threshold table")
ncbi_library <- path_or_stop(file.path(profiles_dir, "curated-ncbifam.hmm"), "curated NCBIfam library")
dbcan_family <- path_or_stop(file.path(profiles_dir, "dbcan-family.hmm"), "filtered dbCAN family library")
dbcan_sub <- path_or_stop(file.path(profiles_dir, "dbcan-sub.hmm"), "filtered dbCAN subfamily library")
dbcan_sizes_path <- path_or_stop(file.path(profiles_dir, "dbcan-library-sizes.tsv"), "dbCAN library sizes")

connection <- gifter_db_connect(database_path)
on.exit(gifter_db_disconnect(connection), add = TRUE)
database_version <- gifter_db_version(connection)$gifter_db_version[[1L]]
markers <- DBI::dbGetQuery(connection, "select distinct namespace, accession from marker")
ko_wanted <- sort(markers$accession[markers$namespace == "KO"])
if (length(ko_wanted) != 753L) stop("Pinned database no longer has 753 KO markers", call. = FALSE)
ko_list <- utils::read.delim(gzfile(ko_thresholds_path), stringsAsFactors = FALSE,
                             quote = "", comment.char = "")
names(ko_list)[[1L]] <- "accession"
ko_list <- ko_list[ko_list$accession %in% ko_wanted, c("accession", "threshold", "score_type"), drop = FALSE]
ko_list$threshold <- suppressWarnings(as.numeric(ko_list$threshold))
if (!setequal(ko_wanted, ko_list$accession) || anyNA(ko_list$threshold) ||
    any(!ko_list$score_type %in% c("full", "domain"))) {
  stop("KOfam threshold table does not cover every pinned gifter KO marker", call. = FALSE)
}

dbcan_sizes <- utils::read.delim(dbcan_sizes_path, header = FALSE,
                                 col.names = c("library", "matched", "profiles"),
                                 stringsAsFactors = FALSE)
dbcan_libraries <- data.frame(
  library = c("dbCAN.hmm", "dbCAN_sub.hmm"),
  path = c(dbcan_family, dbcan_sub), stringsAsFactors = FALSE
)
dbcan_libraries$Z <- dbcan_sizes$profiles[match(dbcan_libraries$library, dbcan_sizes$library)]
if (anyNA(dbcan_libraries$Z)) stop("Pinned dbCAN library sizes are incomplete", call. = FALSE)

reference_stats <- fasta_statistics(exact_genome)
if (reference_stats$sequence_count != 1L || reference_stats$bases != 4636831) {
  stop("Exact assembly is not the expected one-contig 4,636,831-base MG1655 genome", call. = FALSE)
}
# A whole isolate assembly plus one genuine de-novo assembly of a deterministic
# raw-read subset.  No read from another organism is introduced anywhere.
draft_specs <- data.frame(
  source_id = c("MG1655_exact_isolate", "MG1655_draft_reads_20pct"),
  genome_role = c("isolate", "MAG-like draft"),
  read_fraction = c(NA_real_, 0.20),
  subsample_seed = c(NA_integer_, 2026100201L),
  stringsAsFactors = FALSE
)
draft_specs$input_fastq <- c(
  NA_character_,
  file.path(cache_dir, "subsamples", "SRR1284073_20pct_seed2026100201.fastq.gz")
)
draft_specs$input_fastq <- sub("[.]fastq[.]gz$", "_unique_fastq_ids_v1.fastq.gz", draft_specs$input_fastq)
for (i in which(!is.na(draft_specs$read_fraction))) {
  subsample_fastq(raw_fastq, draft_specs$input_fastq[[i]], draft_specs$read_fraction[[i]],
                  draft_specs$subsample_seed[[i]], draft_specs$source_id[[i]])
}

draft_stats <- vector("list", nrow(draft_specs))
draft_stats[[1L]] <- data.frame(
  reads = NA_integer_, bases = NA_real_, input_fastq_sha256 = NA_character_,
  stringsAsFactors = FALSE
)
for (i in which(!is.na(draft_specs$read_fraction))) {
  draft_stats[[i]] <- fastq_statistics(draft_specs$input_fastq[[i]])
  draft_stats[[i]]$input_fastq_sha256 <- sha256(draft_specs$input_fastq[[i]])
}
draft_stats <- do.call(rbind, draft_stats)

assembly_paths <- character(nrow(draft_specs))
assembly_paths[[1L]] <- exact_genome_fna
for (i in which(draft_specs$genome_role == "MAG-like draft")) {
  assembly_dir <- file.path(cache_dir, "assemblies", paste0(draft_specs$source_id[[i]], "_unique_fastq_ids_v1"))
  assembly <- file.path(assembly_dir, "assembly.fasta")
  if (!file.exists(assembly)) {
    dir.create(assembly_dir, recursive = TRUE, showWarnings = FALSE)
    # A long Flye run may be interrupted after an expensive stage.  Resume the
    # same recorded command state when Flye's parameter file is present; do not
    # delete intermediates, alter reads, or silently substitute an assembler.
    flye_args <- if (file.exists(file.path(assembly_dir, "params.json"))) {
      c("--pacbio-raw", draft_specs$input_fastq[[i]],
        "--genome-size", as.character(reference_stats$bases),
        "--threads", as.character(threads), "--resume", "--out-dir", assembly_dir)
    } else {
      c("--pacbio-raw", draft_specs$input_fastq[[i]],
        "--genome-size", as.character(reference_stats$bases),
        "--threads", as.character(threads), "--out-dir", assembly_dir)
    }
    run_or_stop(flye, flye_args)
  }
  assembly_paths[[i]] <- path_or_stop(assembly, "Flye draft assembly")
}

assembly_stats <- do.call(rbind, lapply(assembly_paths, fasta_statistics))
assembly_stats$source_id <- draft_specs$source_id
assembly_stats$genome_role <- draft_specs$genome_role
assembly_stats$assembly_path <- assembly_paths
assembly_stats$assembly_sha256 <- vapply(assembly_paths, sha256, character(1))
assembly_stats$read_fraction <- draft_specs$read_fraction
assembly_stats$input_reads <- draft_stats$reads
assembly_stats$input_bases <- draft_stats$bases
assembly_stats$input_bases_per_exact_assembly_base <- draft_stats$bases / reference_stats$bases
assembly_stats$input_fastq_sha256 <- draft_stats$input_fastq_sha256
assembly_stats$assembly_method <- ifelse(
  assembly_stats$genome_role == "isolate", "deposited exact GCA_000801205.1 assembly",
  "Flye de-novo assembly from deterministic subset of one linked isolate WGS run"
)
assembly_stats$binning_status <- "not run: single-isolate read run; no MAG/bin was created"
assembly_stats$record_status <- ifelse(
  assembly_stats$genome_role == "isolate",
  "exact_isolate_reannotation_annotation_evidence_only",
  "matched_MAG_like_draft_reannotation_annotation_evidence_only"
)
assembly_stats <- assembly_stats[, c("source_id", "genome_role", "read_fraction", "input_reads",
  "input_bases", "input_bases_per_exact_assembly_base", "sequence_count", "bases", "assembly_method",
  "input_fastq_sha256", "binning_status", "assembly_sha256", "record_status")]

annotate_one <- function(source_id, genome_role, assembly) {
  work_dir <- file.path(cache_dir, "annotation", source_id)
  proteins <- file.path(work_dir, "proteins.faa")
  dir.create(work_dir, recursive = TRUE, showWarnings = FALSE)
  if (!file.exists(proteins)) {
    run_or_stop(prodigal, c("-i", assembly, "-a", proteins, "-p", "meta", "-q"))
  }
  ko_tbl <- file.path(work_dir, "kofam.tblout")
  if (!file.exists(ko_tbl)) {
    ko_floor <- floor(min(ko_list$threshold)) - 1L
    run_or_stop(hmmsearch, c("--noali", "--cpu", as.character(threads), "-T", as.character(ko_floor),
                             "--tblout", ko_tbl, ko_library, proteins))
  }
  ko <- read_tblout(ko_tbl)
  if (nrow(ko)) {
    ko$namespace <- "KO"
    ko$accession <- ko$profile_name
    ko$threshold <- ko_list$threshold[match(ko$accession, ko_list$accession)]
    ko$score_type <- ko_list$score_type[match(ko$accession, ko_list$accession)]
    ko$called <- !is.na(ko$threshold) & ifelse(
      ko$score_type == "domain", ko$domain_score >= ko$threshold, ko$sequence_score >= ko$threshold
    )
    ko <- ko[, c("target", "namespace", "accession", "profile_name", "profile_accession",
                 "sequence_score", "domain_score", "threshold", "score_type", "called"), drop = FALSE]
  }

  nf_tbl <- file.path(work_dir, "ncbifam.tblout")
  if (!file.exists(nf_tbl)) {
    run_or_stop(hmmsearch, c("--noali", "--cpu", as.character(threads), "--cut_ga",
                             "--tblout", nf_tbl, ncbi_library, proteins))
  }
  nf <- read_tblout(nf_tbl)
  if (nrow(nf)) {
    # Profile accessions are identities here; recover gifter's namespace and
    # versioned accession rather than inferring it from a human-readable name.
    profiles <- markers[markers$namespace %in% c("NCBIFAM", "TIGRFAM", "PFAM"), , drop = FALSE]
    profiles$base <- sub("[.][0-9]+$", "", profiles$accession)
    if (anyDuplicated(profiles$base)) stop("Profile namespace mapping is ambiguous", call. = FALSE)
    base <- sub("[.][0-9]+$", "", nf$profile_accession)
    hit <- match(base, profiles$base)
    nf <- nf[!is.na(hit), , drop = FALSE]
    hit <- hit[!is.na(hit)]
    if (nrow(nf)) {
      nf$namespace <- profiles$namespace[hit]
      nf$accession <- profiles$accession[hit]
      nf$threshold <- NA_real_
      nf$score_type <- "HMMER --cut_ga"
      nf$called <- TRUE
      nf <- nf[, c("target", "namespace", "accession", "profile_name", "profile_accession",
                   "sequence_score", "domain_score", "threshold", "score_type", "called"), drop = FALSE]
    }
  }

  cazy_parts <- vector("list", nrow(dbcan_libraries))
  for (i in seq_len(nrow(dbcan_libraries))) {
    dom_tbl <- file.path(work_dir, paste0("dbcan_", i, ".domtblout"))
    if (!file.exists(dom_tbl)) {
      run_or_stop(hmmsearch, c("--noali", "--cpu", as.character(threads), "-Z",
                               format(dbcan_libraries$Z[[i]], scientific = FALSE), "--domtblout", dom_tbl,
                               dbcan_libraries$path[[i]], proteins))
    }
    dom <- read_domtblout(dom_tbl)
    if (!nrow(dom)) next
    dom$coverage <- (dom$hmm_to - dom$hmm_from) / dom$model_length
    dom$accession <- sub("[.]hmm$", "", sub("[|].*$", "", dom$model))
    dom$called <- dom$i_evalue < 1e-15 & dom$coverage > 0.35
    dom <- dom[dom$called, , drop = FALSE]
    if (!nrow(dom)) next
    cazy_parts[[i]] <- data.frame(
      target = dom$sequence, namespace = "CAZY", accession = dom$accession,
      profile_name = dom$model, profile_accession = "", sequence_score = NA_real_, domain_score = NA_real_,
      threshold = NA_real_, score_type = "independent E-value < 1e-15; profile coverage > 0.35",
      called = TRUE, stringsAsFactors = FALSE
    )
  }
  cazy <- Filter(Negate(is.null), cazy_parts)
  cazy <- if (length(cazy)) rbind_fill(cazy) else ko[FALSE, , drop = FALSE]
  rows <- rbind_fill(Filter(function(x) nrow(x), list(ko, nf, cazy)))
  if (is.null(rows)) rows <- data.frame(
    target = character(), namespace = character(), accession = character(), profile_name = character(),
    profile_accession = character(), sequence_score = numeric(), domain_score = numeric(), threshold = numeric(),
    score_type = character(), called = logical(), stringsAsFactors = FALSE
  )
  rows$source_id <- source_id
  rows$genome_role <- genome_role
  names(rows)[names(rows) == "target"] <- "gene_id"
  rows[, c("source_id", "genome_role", "gene_id", "namespace", "accession", "profile_name",
           "profile_accession", "sequence_score", "domain_score", "threshold", "score_type", "called")]
}

all_hits <- vector("list", nrow(draft_specs))
annotations <- vector("list", nrow(draft_specs))
names(annotations) <- draft_specs$source_id
for (i in seq_len(nrow(draft_specs))) {
  all_hits[[i]] <- annotate_one(draft_specs$source_id[[i]], draft_specs$genome_role[[i]], assembly_paths[[i]])
  annotations[[i]] <- all_hits[[i]][all_hits[[i]]$called,
    c("gene_id", "namespace", "accession"), drop = FALSE]
}
all_hits <- rbind_fill(all_hits)

call_rows <- list()
trace_rows <- list()
results <- vector("list", nrow(draft_specs))
names(results) <- draft_specs$source_id
for (i in seq_len(nrow(draft_specs))) {
  source_id <- draft_specs$source_id[[i]]
  result <- evaluate_gifts(annotations[[source_id]], db = connection, max_genes = Inf)
  results[[source_id]] <- result
  calls <- result$gifts
  calls$source_id <- source_id
  calls$genome_role <- draft_specs$genome_role[[i]]
  call_rows[[i]] <- calls[, c("source_id", "genome_role", "gift_id", "gift_type", "complete",
                              "best_implementation", "minimum_missing_requirements", "evidence_confidence")]
  for (gift_id in calls$gift_id) {
    trace <- trace_gift(result, gift_id)
    trace$source_id <- source_id
    trace$genome_role <- draft_specs$genome_role[[i]]
    trace_rows[[length(trace_rows) + 1L]] <- trace
  }
}
calls <- do.call(rbind, call_rows)
traces <- rbind_fill(trace_rows)

# Every draft/full call pair receives an explicit transition label.  A supported
# result in a draft can be newly recoverable annotation evidence only; it never
# names a gain in the strain's biology.
full_calls <- calls[calls$source_id == "MG1655_exact_isolate", , drop = FALSE]
transition_rows <- list()
for (source_id in draft_specs$source_id[draft_specs$genome_role == "MAG-like draft"]) {
  draft_calls <- calls[calls$source_id == source_id, , drop = FALSE]
  paired <- merge(full_calls, draft_calls, by = c("gift_id", "gift_type"), suffixes = c("_isolate", "_draft"))
  paired$transition <- ifelse(
    paired$complete_isolate & !paired$complete_draft, "supported_to_unsupported_annotation_assembly_change",
    ifelse(!paired$complete_isolate & paired$complete_draft,
           "unsupported_to_supported_annotation_assembly_change", "no_call_change")
  )
  paired$interpretation <- ifelse(
    paired$transition == "supported_to_unsupported_annotation_assembly_change",
    "Missing draft evidence; not biological loss.",
    ifelse(paired$transition == "unsupported_to_supported_annotation_assembly_change",
           "Newly recovered draft annotation evidence; not biological gain.",
           "No annotation/call transition."))
  transition_rows[[length(transition_rows) + 1L]] <- paired[, c(
    "gift_id", "gift_type", "source_id_isolate", "source_id_draft", "complete_isolate", "complete_draft",
    "best_implementation_isolate", "best_implementation_draft", "minimum_missing_requirements_isolate",
    "minimum_missing_requirements_draft", "transition", "interpretation"
  )]
}
transitions <- do.call(rbind, transition_rows)

# Fixed annotation-table gene removal is a separate evaluator invariant check,
# not a MAG simulation.  For each isolate-supported GIFT, remove every traced
# accepted gene at once, then check every GIFT again.  This exercises removal
# over paths spanning alternatives and complexes without pretending the edited
# table is a genome or an assembly.
supported_ids <- full_calls$gift_id[full_calls$complete]
loss_call_rows <- list()
loss_trace_rows <- list()
loss_summaries <- list()
for (gift_id in supported_ids) {
  full_trace <- traces[traces$source_id == "MG1655_exact_isolate" & traces$gift_id == gift_id, , drop = FALSE]
  removed <- sort(unique(full_trace$gene_id[!is.na(full_trace$gene_id) & nzchar(full_trace$gene_id)]))
  if (!length(removed)) stop("A supported isolate GIFT has no traceable accepted gene: ", gift_id, call. = FALSE)
  scenario_id <- paste0("fixed_annotation_remove_trace_genes_", gift_id)
  edited <- annotations[["MG1655_exact_isolate"]][
    !annotations[["MG1655_exact_isolate"]]$gene_id %in% removed, , drop = FALSE
  ]
  edited_result <- evaluate_gifts(edited, db = connection, max_genes = Inf)
  edited_calls <- edited_result$gifts
  compared <- merge(full_calls[, c("gift_id", "complete", "minimum_missing_requirements")],
                    edited_calls[, c("gift_id", "complete", "minimum_missing_requirements")], by = "gift_id",
                    suffixes = c("_full", "_removed"))
  if (any(!compared$complete_full & compared$complete_removed)) {
    stop("Priority 2 invariant violated: removing genes promoted an unsupported call", call. = FALSE)
  }
  lost <- compared[compared$complete_full & !compared$complete_removed, , drop = FALSE]
  if (nrow(lost) && any(is.na(lost$minimum_missing_requirements_removed) |
                        lost$minimum_missing_requirements_removed < 1L)) {
    stop("Priority 2 invariant violated: a lost call did not identify missing requirements", call. = FALSE)
  }
  compared$scenario_id <- scenario_id
  compared$targeted_supported_gift <- gift_id
  compared$removed_gene_ids <- paste(removed, collapse = ";")
  compared$transition <- ifelse(
    compared$complete_full & !compared$complete_removed, "supported_to_unsupported_fixed_annotation_change",
    ifelse(!compared$complete_full & compared$complete_removed,
           "unsupported_to_supported_FIXED_ANNOTATION_ERROR", "no_call_change")
  )
  loss_call_rows[[length(loss_call_rows) + 1L]] <- compared
  if (nrow(lost)) {
    for (lost_gift in lost$gift_id) {
      trace <- trace_gift(edited_result, lost_gift)
      trace$scenario_id <- scenario_id
      trace$targeted_supported_gift <- gift_id
      trace$removed_gene_ids <- paste(removed, collapse = ";")
      loss_trace_rows[[length(loss_trace_rows) + 1L]] <- trace
    }
  }
  loss_summaries[[length(loss_summaries) + 1L]] <- data.frame(
    scenario_id = scenario_id,
    targeted_supported_gift = gift_id,
    removed_gene_count = length(removed),
    removed_gene_ids = paste(removed, collapse = ";"),
    unsupported_to_supported_changes = sum(!compared$complete_full & compared$complete_removed),
    supported_to_unsupported_changes = nrow(lost),
    record_status = "synthetic_fixed_annotation_gene_removal_not_MAG_or_biological_observation",
    stringsAsFactors = FALSE
  )
}
loss_calls <- do.call(rbind, loss_call_rows)
loss_summary <- do.call(rbind, loss_summaries)
loss_traces <- if (length(loss_trace_rows)) rbind_fill(loss_trace_rows) else traces[FALSE, , drop = FALSE]

# The assessability policy receives a deliberately synthetic policy input, not
# an inferred property of either draft.  Its sole purpose is to make the
# denominator-only contract executable in this audit without inventing a MAG
# completeness estimate.
policy_input <- 0.50
policy_threshold <- 0.90
none_traits <- genome_traits(results[["MG1655_exact_isolate"]], genome_id = "MG1655_exact_isolate",
                             policy = "none")
gated_traits <- genome_traits(
  results[["MG1655_exact_isolate"]], genome_id = "MG1655_exact_isolate",
  policy = "completeness", quality = setNames(policy_input, "MG1655_exact_isolate"),
  threshold = policy_threshold
)
metric_pair <- merge(
  none_traits$metrics[none_traits$metrics$metric_id == "supported_fraction",
                      c("reference_frame", "numerator", "assessable", "denominator")],
  gated_traits$metrics[gated_traits$metrics$metric_id == "supported_fraction",
                       c("reference_frame", "numerator", "assessable", "denominator")],
  by = "reference_frame", suffixes = c("_none", "_completeness"), all = TRUE
)
if (!nrow(metric_pair)) {
  stop("Priority 2 assessability exercise needs a bounded supported-fraction frame", call. = FALSE)
}
if (any(metric_pair$numerator_none != metric_pair$numerator_completeness, na.rm = TRUE)) {
  stop("Priority 2 invariant violated: assessability changed a supported numerator", call. = FALSE)
}
if (!any(metric_pair$denominator_none > metric_pair$denominator_completeness, na.rm = TRUE)) {
  stop("Synthetic assessability policy did not move any denominator", call. = FALSE)
}
metric_pair$policy_input <- policy_input
metric_pair$policy_threshold <- policy_threshold
metric_pair$interpretation <- "Synthetic assessability-policy exercise on bounded supported-fraction rows only; policy input is not MAG quality. Calls and supported numerators are identical; only absence denominators are withheld."

profile_thresholds <- rbind(
  data.frame(namespace = "KO", accession = ko_list$accession, score_type = ko_list$score_type,
             threshold = ko_list$threshold, rule = "KOfam adaptive threshold", stringsAsFactors = FALSE),
  data.frame(namespace = c("NCBIFAM", "TIGRFAM", "PFAM"), accession = "all curated profiles",
             score_type = "HMMER --cut_ga", threshold = NA_real_,
             rule = "profile-specific curated gathering cutoff", stringsAsFactors = FALSE),
  data.frame(namespace = "CAZY", accession = "all curated profiles",
             score_type = "dbCAN independent E-value and coverage", threshold = NA_real_,
             rule = "independent E-value < 1e-15; profile coverage > 0.35; -Z is full-library profile count", stringsAsFactors = FALSE),
  data.frame(namespace = "EC", accession = "1.8.4.10;1.8.4.8", score_type = "not profiled", threshold = NA_real_,
             rule = "No profile source is defined in the pinned multi-namespace pipeline; EC markers are not supplied to gifter.", stringsAsFactors = FALSE)
)

tool_manifest <- data.frame(
  role = c("assembler", "binning", "gene_caller", "profile_search", "R", "gifter_package"),
  tool = c("Flye", "not run", "Prodigal", "HMMER hmmsearch", "R", "gifter"),
  path_or_source = c(flye, "single-isolate read run; no bin exists", prodigal, hmmsearch,
                     R.home("bin"), normalizePath(".", mustWork = TRUE)),
  version = c(command_version(flye), "not applicable", command_version(prodigal, "-v"),
              command_version(hmmsearch, "-h", "HMMER [0-9]"), R.version.string, as.character(utils::packageVersion("gifter"))),
  sha256 = c(sha256(flye), "", sha256(prodigal), sha256(hmmsearch), "", ""),
  rule_or_scope = c(
    "--pacbio-raw; --genome-size 4636831; one deterministic read subset with unique Flye header tokens and retained raw IDs; no reference-guided assembly",
    "No binning: source reads are one linked isolate, and no output may be called a MAG or contaminated bin.",
    "-p meta for isolate and every draft, so gene calling does not vary by source role",
    "KOfam adaptive thresholds; NCBIfam/TIGRFAM/Pfam --cut_ga; dbCAN independent E-value/coverage filter",
    "runner", "pinned evaluator and SQLite database"
  ),
  stringsAsFactors = FALSE
)

input_manifest <- data.frame(
  input_kind = c("pacbio_subreads", "exact_isolate_genome", "KOfam_library", "KOfam_threshold_table",
                 "NCBIfam_TIGRFAM_Pfam_library", "dbCAN_family_library", "dbCAN_subfamily_library",
                 "gifter_database", "audit_script"),
  identifier = c(raw_spec$identifier, genome_spec$identifier, basename(ko_library), basename(ko_thresholds_path),
                 basename(ncbi_library), basename(dbcan_family), basename(dbcan_sub), database_version,
                 "17-priority2-matched-mag-robustness.R"),
  source = c(raw_spec$source, genome_spec$source,
             "https://www.genome.jp/ftp/db/kofam/profiles.tar.gz", "https://www.genome.jp/ftp/db/kofam/ko_list.gz",
             "https://ftp.ncbi.nlm.nih.gov/hmm/current/ and Pfam source pinned by curated library",
             "https://dbcan.s3.us-west-2.amazonaws.com/db_v5-2-9_5-5-2026/dbCAN.hmm",
             "https://dbcan.s3.us-west-2.amazonaws.com/db_v5-2-9_5-5-2026/dbCAN_sub.hmm",
             normalizePath(database_path), "manuscript/analysis/17-priority2-matched-mag-robustness.R"),
  published_md5 = c(raw_spec$expected_md5, genome_spec$expected_md5, rep("", 7L)),
  observed_sha256 = c(sha256(raw_fastq), sha256(exact_genome), sha256(ko_library), sha256(ko_thresholds_path),
                      sha256(ncbi_library), sha256(dbcan_family), sha256(dbcan_sub), sha256(database_path),
                      sha256("manuscript/analysis/17-priority2-matched-mag-robustness.R")),
  pin_or_rule = c(
    "ENA-published MD5 verified before use; SHA-256 recorded after verified download",
    "NCBI published genomic-FASTA MD5 verified before use; exact complete GCA_000801205.1 one-contig isolate assembly; SHA-256 recorded after download",
    "curated profiles actually searched", "adaptive threshold table used by each KO call",
    "curated NCBIfam/TIGRFAM/Pfam profiles actually searched with --cut_ga",
    "curated dbCAN family profiles actually searched; original library size retained for -Z",
    "curated dbCAN subfamily profiles actually searched; original library size retained for -Z",
    "exact gifter database used for every evaluator call", "version-controlled runner that generated this audit"
  ),
  stringsAsFactors = FALSE
)

write_tsv(assembly_stats, file.path(output_dir, "assembly-audit.tsv"))
write_tsv(all_hits, file.path(output_dir, "annotation-marker-hits.tsv"))
write_tsv(calls, file.path(output_dir, "gifter-calls.tsv"))
write_tsv(traces, file.path(output_dir, "gifter-gift-traces.tsv"))
write_tsv(transitions, file.path(output_dir, "gifter-call-transitions.tsv"))
write_tsv(loss_summary, file.path(output_dir, "fixed-annotation-gene-loss.tsv"))
write_tsv(loss_calls, file.path(output_dir, "fixed-annotation-gene-loss-calls.tsv"))
write_tsv(loss_traces, file.path(output_dir, "fixed-annotation-gene-loss-traces.tsv"))
write_tsv(metric_pair, file.path(output_dir, "assessability-invariant.tsv"))
write_tsv(profile_thresholds, file.path(output_dir, "profile-thresholds.tsv"))
write_tsv(tool_manifest, file.path(output_dir, "tool-manifest.tsv"))
write_tsv(input_manifest, file.path(output_dir, "input-manifest.tsv"))

cat("Priority 2 matched isolate / MAG-like draft annotation audit\n")
cat("-------------------------------------------------------------\n")
cat("  database version: ", database_version, "\n", sep = "")
cat("  exact isolate plus drafts: ", nrow(draft_specs), "\n", sep = "")
cat("  draft transitions (supported -> unsupported): ",
    sum(transitions$transition == "supported_to_unsupported_annotation_assembly_change"), "\n", sep = "")
cat("  draft transitions (unsupported -> supported): ",
    sum(transitions$transition == "unsupported_to_supported_annotation_assembly_change"), "\n", sep = "")
cat("  status: annotation/assembly evidence only; no MAG, bin, contamination estimate, assay, or biological observation was read.\n")
