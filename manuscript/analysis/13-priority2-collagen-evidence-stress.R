#!/usr/bin/env Rscript
# Priority 2 stress test: loss and mixing of the exact collagen-candidate evidence.
#
# This uses the content-addressed M9 marker audit from Priority 1 as its input.
# It deliberately separates a genuine evidence-loss exercise from a provenance-
# violating mixed-bin exercise. The latter shows why a contaminated bin cannot
# be interpreted as a PAO1 genome, even when the evaluator correctly completes
# a route from the markers it was given.
#
# Usage:
#   Rscript manuscript/analysis/13-priority2-collagen-evidence-stress.R \
#     [--audit=manuscript/analysis/prospective/collagen-annotation-audit] \
#     [--database=inst/extdata/gifter.sqlite] \
#     [--output=manuscript/analysis/prospective/collagen-evidence-stress]

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
  invisible(path)
}

collapse_or_empty <- function(x) {
  x <- sort(unique(as.character(x[!is.na(x) & nzchar(x)])))
  if (length(x)) paste(x, collapse = ";") else ""
}

root <- getwd()
audit_dir <- path_or_stop(option(
  "audit", "manuscript/analysis/prospective/collagen-annotation-audit"
), "Priority 1 audit directory")
database_path <- path_or_stop(option("database", "inst/extdata/gifter.sqlite"), "database")
output_dir <- normalizePath(option(
  "output", "manuscript/analysis/prospective/collagen-evidence-stress"
), mustWork = FALSE)
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

audit <- utils::read.delim(file.path(audit_dir, "candidate-annotation-audit.tsv"),
                           stringsAsFactors = FALSE, check.names = FALSE)
hits <- utils::read.delim(file.path(audit_dir, "candidate-marker-hits.tsv"),
                          stringsAsFactors = FALSE, check.names = FALSE)
required_audit <- c("candidate_id", "role", "assembly_accession", "database_version")
required_hits <- c("candidate_id", "gene_id", "namespace", "accession", "called")
if (!all(required_audit %in% names(audit))) stop("Priority 1 audit summary has changed columns", call. = FALSE)
if (!all(required_hits %in% names(hits))) stop("Priority 1 marker table has changed columns", call. = FALSE)

positive <- audit$candidate_id[audit$role == "specific-positive"]
control <- audit$candidate_id[audit$role == "broad-marker control"]
if (length(positive) != 1L || length(control) != 1L) {
  stop("Priority 1 audit must have one specific-positive and one broad-marker control", call. = FALSE)
}
positive <- positive[[1L]]
control <- control[[1L]]
positive_assembly <- audit$assembly_accession[match(positive, audit$candidate_id)]
control_assembly <- audit$assembly_accession[match(control, audit$candidate_id)]

# Only markers that the independent Priority 1 audit accepted may be passed to
# gifter. The untreated PAO1 candidate has no such M9 marker; its low-scoring
# K01387 comparison is intentionally absent from these inputs.
supported <- hits[
  hits$candidate_id == positive & hits$called & hits$accession %in% c("K01387", "PF01752"),
  c("gene_id", "namespace", "accession"), drop = FALSE
]
if (!nrow(supported) || length(unique(supported$gene_id)) < 2L) {
  stop("Priority 1 audit does not contain the expected independent M9 evidence", call. = FALSE)
}
control_markers <- hits[
  hits$candidate_id == control & hits$called & hits$accession %in% c("K01387", "PF01752"),
  c("gene_id", "namespace", "accession"), drop = FALSE
]
if (nrow(control_markers)) stop("Broad-marker control unexpectedly has accepted M9 evidence", call. = FALSE)

empty_markers <- supported[FALSE, , drop = FALSE]
one_gene <- sort(unique(supported$gene_id))[[1L]]
one_marker <- supported[supported$gene_id == one_gene & supported$accession == "K01387", , drop = FALSE]
if (nrow(one_marker) != 1L) stop("Priority 1 evidence lacks a single accepted K01387 row", call. = FALSE)

# Every scenario retains the provenance of the marker rows it receives. The
# mixed-bin scenario is created only to test the interpretation boundary; its
# source marker is renamed so an output cannot be mistaken for a PAO1 gene.
scenarios <- list(
  list(
    id = "HHIST_exact_full", kind = "exact_isolate_annotation", target = positive,
    target_assembly = positive_assembly, markers = supported,
    interpretation = "Exact M9-positive isolate annotation; genomic evidence only."
  ),
  list(
    id = "HHIST_drop_VTQ90952_1", kind = "synthetic_evidence_loss", target = positive,
    target_assembly = positive_assembly,
    markers = supported[supported$gene_id != "VTQ90952.1", , drop = FALSE],
    interpretation = "Remove one independent M9-supported gene from the fixed annotation table; not a MAG."
  ),
  list(
    id = "HHIST_drop_VTQ92554_1", kind = "synthetic_evidence_loss", target = positive,
    target_assembly = positive_assembly,
    markers = supported[supported$gene_id != "VTQ92554.1", , drop = FALSE],
    interpretation = "Remove one independent M9-supported gene from the fixed annotation table; not a MAG."
  ),
  list(
    id = "HHIST_drop_all_M9", kind = "synthetic_evidence_loss", target = positive,
    target_assembly = positive_assembly, markers = empty_markers,
    interpretation = "Remove all accepted M9 evidence from the fixed annotation table; not a MAG."
  ),
  list(
    id = "HHIST_single_K01387", kind = "synthetic_evidence_loss", target = positive,
    target_assembly = positive_assembly, markers = one_marker,
    interpretation = "Retain one accepted M9 marker only; validates component-level OR logic, not genome completeness."
  ),
  list(
    id = "PAO1_exact_no_M9", kind = "exact_isolate_annotation", target = control,
    target_assembly = control_assembly, markers = empty_markers,
    interpretation = "Exact PAO1 M9 input has no accepted M9 marker; this is not a phenotype-negative claim."
  ),
  list(
    id = "PAO1_plus_HHIST_K01387", kind = "synthetic_mixed_bin", target = control,
    target_assembly = control_assembly,
    markers = transform(one_marker, gene_id = paste0(positive, ":", gene_id)),
    interpretation = "Deliberately mixed evidence: complete only because an M9 marker from Hathewaya was inserted. Never interpret as PAO1."
  )
)

connection <- gifter_db_connect(database_path)
on.exit(gifter_db_disconnect(connection), add = TRUE)
database_version <- gifter_db_version(connection)$gifter_db_version[[1L]]
if (!identical(database_version, audit$database_version[[1L]])) {
  stop("Priority 1 audit database version does not match supplied database", call. = FALSE)
}

summary_rows <- vector("list", length(scenarios))
trace_rows <- list()
for (i in seq_along(scenarios)) {
  scenario <- scenarios[[i]]
  result <- evaluate_gifts(scenario$markers, db = connection, max_genes = Inf)
  collagen <- result$gifts[result$gifts$gift_id == "collagen_cleavage", , drop = FALSE]
  if (nrow(collagen) != 1L) stop("Pinned database does not contain collagen_cleavage", call. = FALSE)
  trace <- trace_gift(result, "collagen_cleavage")
  trace$scenario_id <- scenario$id
  trace$scenario_kind <- scenario$kind
  trace$target_candidate_id <- scenario$target
  trace$target_assembly_accession <- scenario$target_assembly
  trace_rows[[i]] <- trace
  summary_rows[[i]] <- data.frame(
    scenario_id = scenario$id,
    scenario_kind = scenario$kind,
    target_candidate_id = scenario$target,
    target_assembly_accession = scenario$target_assembly,
    marker_source_candidate_ids = if (nrow(scenario$markers)) positive else "none",
    input_marker_rows = nrow(scenario$markers),
    input_gene_ids = collapse_or_empty(scenario$markers$gene_id),
    collagen_cleavage_complete = collagen$complete[[1L]],
    best_route = collagen$best_implementation[[1L]],
    minimum_missing_requirements = collagen$minimum_missing_requirements[[1L]],
    interpretation = scenario$interpretation,
    record_status = "synthetic_evidence_stress_not_MAG_or_prospective_observation",
    stringsAsFactors = FALSE
  )
}

summary <- do.call(rbind, summary_rows)
write_tsv(summary, file.path(output_dir, "collagen-evidence-stress.tsv"))
write_tsv(do.call(rbind, trace_rows), file.path(output_dir, "collagen-evidence-stress-trace.tsv"))

cat("Priority 2 collagen evidence stress test\n")
cat("-----------------------------------------\n")
cat("  database version: ", database_version, "\n", sep = "")
cat("  scenarios: ", nrow(summary), "\n", sep = "")
cat("  output: ", output_dir, "\n", sep = "")
cat("  status: synthetic evidence test only; no MAG or assay observation was read.\n")
