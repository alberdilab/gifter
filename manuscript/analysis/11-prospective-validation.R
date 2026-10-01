#!/usr/bin/env Rscript
# Prospective biological-validation registry runner.
#
# Runs only a locked protocol. It evaluates each deposited strain annotation
# against the database version named in that protocol, joins the result to the
# raw assay observations, and writes evidence traces. It never converts the
# asymmetric cells into accuracy, F1, AUC or a catalogue-wide score.
#
# Usage:
#   Rscript manuscript/analysis/11-prospective-validation.R \
#     --studies=path/studies.tsv --samples=path/samples.tsv \
#     --annotations=path/annotations.tsv --observations=path/observations.tsv \
#     [--database=inst/extdata/gifter.sqlite] [--output=path/output]

suppressMessages(devtools::load_all(".", quiet = TRUE))
source("manuscript/analysis/_prospective.R")

args <- commandArgs(trailingOnly = TRUE)
option <- function(name, default = NULL) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (!length(hit)) return(default)
  sub(paste0("^--", name, "="), "", hit[[1L]])
}
required <- c("studies", "samples", "annotations", "observations")
missing <- required[vapply(required, function(x) is.null(option(x)), logical(1))]
if (length(missing)) {
  stop("Missing required option(s): ", paste(paste0("--", missing, "="), collapse = ", "), call. = FALSE)
}

database_path <- option("database")
output_dir <- option("output", "manuscript/analysis/output/prospective")
connection <- if (is.null(database_path)) NULL else gifter_db_connect(database_path)
if (!is.null(connection)) on.exit(gifter_db_disconnect(connection), add = TRUE)

inputs <- prospective_read_inputs(
  studies_path = option("studies"),
  samples_path = option("samples"),
  annotations_path = option("annotations"),
  observations_path = option("observations"),
  db = connection
)
result <- prospective_evaluate(inputs, db = connection)
paths <- prospective_write_outputs(result, output_dir)

cat("Prospective validation outputs\n")
cat("------------------------------\n")
cat("  database version: ", result$database_version$gifter_db_version[[1L]], "\n", sep = "")
cat("  paired observations: ", nrow(result$report), "\n", sep = "")
cat("  reportable summary rows: ", nrow(result$summary), "\n", sep = "")
for (path in paths) cat("  wrote: ", path, "\n", sep = "")
