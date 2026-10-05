# Measure the uncached, preannotated-marker-to-sample gifter workflow in R10.
# Run from the repository root after fetching the checksum-verified R10 inputs:
#   Rscript manuscript/analysis/36-r10-gifter-resources.R
# Optional smoke test: GIFTER_BENCH_GENOMES=2 GIFTER_BENCH_SAMPLES=2 Rscript ...
# The default uses one evaluation worker so sampled RSS is the process RSS.

if (!requireNamespace("processx", quietly = TRUE) ||
    !requireNamespace("ps", quietly = TRUE)) {
  stop("This analysis needs the processx and ps R packages", call. = FALSE)
}
workers <- as.integer(Sys.getenv("GIFTER_BENCH_WORKERS", "1"))
genomes <- as.integer(Sys.getenv("GIFTER_BENCH_GENOMES", "822"))
samples <- as.integer(Sys.getenv("GIFTER_BENCH_SAMPLES", "388"))
stopifnot(!anyNA(c(workers, genomes, samples)), all(c(workers, genomes, samples) > 0L))

root <- "manuscript/analysis"
sha256 <- function(path) {
  command <- if (nzchar(Sys.which("shasum"))) "shasum" else "sha256sum"
  args <- if (identical(command, "shasum")) c("-a", "256", path) else path
  result <- system2(command, args, stdout = TRUE)
  sub("[[:space:]].*$", "", result[[1L]])
}
cache_dir <- file.path(root, ".cache/r10-chicken/gifter-benchmark")
output_dir <- file.path(root, "r10-chicken/benchmark")
dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
tag <- paste0("g", genomes, "-s", samples, "-w", workers)
event_path <- file.path(cache_dir, paste0(tag, "-events.tsv"))
sample_path <- file.path(cache_dir, paste0(tag, "-rss-samples.tsv"))
log_path <- file.path(cache_dir, paste0(tag, "-worker.log"))
error_path <- file.path(cache_dir, paste0(tag, "-worker.err"))
unlink(c(event_path, sample_path, log_path, error_path))

worker <- processx::process$new(
  Sys.which("Rscript"),
  c(file.path(root, "_r10-gifter-benchmark-worker.R"), event_path,
    workers, genomes, samples),
  stdout = log_path, stderr = error_path, cleanup = TRUE
)
handle <- ps::ps_handle(worker$get_pid())
observations <- vector("list", 0L)
repeat {
  children <- tryCatch(ps::ps_children(handle, recursive = TRUE),
                       error = function(e) list())
  processes <- c(list(handle), children)
  rss <- vapply(processes, function(p) {
    tryCatch(unname(ps::ps_memory_info(p)[["rss"]]),
             error = function(e) NA_real_)
  }, numeric(1))
  observations[[length(observations) + 1L]] <- c(
    epoch_seconds = as.numeric(Sys.time()),
    parent_rss_bytes = if (length(rss)) rss[[1L]] else NA_real_,
    summed_rss_bytes = if (any(!is.na(rss))) sum(rss, na.rm = TRUE) else NA_real_,
    processes = sum(!is.na(rss))
  )
  if (!worker$is_alive()) break
  Sys.sleep(0.05)
}
status <- worker$get_exit_status()
if (!identical(status, 0L)) {
  stop("Benchmark worker failed (exit ", status, "). See ", error_path,
       " and ", log_path, call. = FALSE)
}
identity <- grep("^genomes=", readLines(log_path, warn = FALSE), value = TRUE)
stopifnot(length(identity) == 1L)
tokens <- strsplit(strsplit(identity, " ", fixed = TRUE)[[1L]], "=", fixed = TRUE)
identity_fields <- stats::setNames(vapply(tokens, `[[`, character(1), 2L),
                                   vapply(tokens, `[[`, character(1), 1L))
stopifnot(all(c("genomes", "samples", "gift_db_version", "supported_calls") %in%
                names(identity_fields)))
field <- function(name) identity_fields[[name]]
stopifnot(as.integer(field("genomes")) == min(genomes, 822L),
          as.integer(field("samples")) == min(samples, 388L))

events <- utils::read.delim(event_path, stringsAsFactors = FALSE)
rss <- as.data.frame(do.call(rbind, observations))
utils::write.table(rss, sample_path, sep = "\t", quote = FALSE, row.names = FALSE)
stages <- unique(events$stage)
stopifnot(length(stages) == 5L, all(table(events$stage) == 2L))
rows <- lapply(stages, function(name) {
  begin <- events[events$stage == name & events$event == "start", ]
  end <- events[events$stage == name & events$event == "end", ]
  within <- rss[rss$epoch_seconds >= begin$epoch_seconds &
                  rss$epoch_seconds <= end$epoch_seconds, , drop = FALSE]
  data.frame(stage = name,
             wall_seconds = end$epoch_seconds - begin$epoch_seconds,
             cpu_seconds = end$cpu_seconds,
             peak_parent_rss_gb = if (nrow(within)) max(within$parent_rss_bytes, na.rm = TRUE) / 1e9 else NA_real_,
             peak_summed_rss_gb = if (nrow(within)) max(within$summed_rss_bytes, na.rm = TRUE) / 1e9 else NA_real_)
})
summary <- do.call(rbind, rows)
summary <- rbind(summary, data.frame(
  stage = "full_gifter_workflow",
  wall_seconds = max(events$epoch_seconds) - min(events$epoch_seconds),
  cpu_seconds = sum(summary$cpu_seconds),
  peak_parent_rss_gb = max(rss$parent_rss_bytes, na.rm = TRUE) / 1e9,
  peak_summed_rss_gb = max(rss$summed_rss_bytes, na.rm = TRUE) / 1e9
))
summary$max_observed_processes <- max(rss$processes)
if (workers > 1L && summary$max_observed_processes < 2L) {
  # On some sandboxed macOS hosts ps_children() cannot see forked workers.
  # The parent RSS remains valid, but it is not a whole-job memory reading.
  summary$peak_summed_rss_gb[
    summary$stage %in% c("genome_evaluation", "full_gifter_workflow")
  ] <- NA_real_
  warning("Forked workers were not visible; aggregate evaluation RSS is unavailable")
}
summary$genomes <- min(genomes, 822L)
summary$samples <- min(samples, 388L)
summary$workers <- workers
summary$sample_interval_seconds <- 0.05
summary$r_version <- as.character(getRversion())
summary$platform <- R.version$platform
summary$measured_utc <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
summary$annotation_sha256 <- "1bc6f6a882223d1f86c417f5d0f9c8937fc70b370affc0c5399bc3e81fcfbd86"
summary$database_sha256 <- sha256("inst/extdata/gifter.sqlite")
summary$database_version <- field("gift_db_version")
summary$supported_calls <- as.integer(field("supported_calls"))
summary_path <- file.path(output_dir, paste0("gifter-resource-", tag, ".tsv"))
utils::write.table(summary, summary_path, sep = "\t", quote = FALSE, row.names = FALSE)
stopifnot(file.copy(event_path,
                    file.path(output_dir, paste0("gifter-events-", tag, ".tsv")),
                    overwrite = TRUE))
rss_bytes <- readBin(sample_path, "raw", n = file.info(sample_path)$size)
writeBin(memCompress(rss_bytes, type = "xz"),
         file.path(output_dir, paste0("gifter-rss-", tag, ".tsv.xz")))
print(summary[c("stage", "wall_seconds", "cpu_seconds", "peak_parent_rss_gb", "peak_summed_rss_gb")], row.names = FALSE)
cat("Summary: ", summary_path, "\nRaw samples: ", sample_path,
    "\nWorker log: ", log_path, "\n", sep = "")
