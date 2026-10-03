# R10: genome-resolved chicken caecal case study.
#
# Drakkar supplies gene-resolved marker evidence for the exact 822 published
# bacterial MAGs. gifter evaluates each genome separately, then reads those
# immutable calls across 388 samples. Detection and completeness only change
# denominators; neither may promote an unsupported GIFT. The archived public
# data do not retain the paper's per-sample 30% breadth filter, so every sample
# result is repeated across explicit abundance thresholds and the network is
# labelled as a sensitivity analysis rather than an observed interaction map.
#
# Run from the repository root after fetching the verified Drakkar transfer:
#   Rscript manuscript/analysis/21-r10-chicken.R

suppressWarnings(suppressPackageStartupMessages({
  library(ggplot2)
}))

devtools::load_all(".", quiet = TRUE)

root <- "manuscript/analysis"
case_dir <- file.path(root, "r10-chicken")
cache_dir <- Sys.getenv(
  "R10_CACHE_DIR", file.path(root, ".cache", "r10-chicken")
)
public_dir <- Sys.getenv(
  "R10_PUBLIC_DATA", file.path(root, ".cache", "r10-chicken", "public-data")
)
drakkar_dir <- Sys.getenv("R10_DRAKKAR_DIR", file.path(cache_dir, "drakkar"))
output_dir <- Sys.getenv("R10_OUTPUT_DIR", file.path(root, "output"))
figure_dir <- Sys.getenv("R10_FIGURE_DIR", "manuscript/figures")
dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

annotation_path <- Sys.getenv(
  "R10_GIFTER_INPUT",
  file.path(drakkar_dir, "gifter_input.tsv.xz")
)
annotation_manifest_path <- Sys.getenv(
  "R10_ANNOTATION_MANIFEST",
  file.path(drakkar_dir, "annotation_manifest.yaml")
)
annotation_qc_path <- Sys.getenv(
  "R10_ANNOTATION_QC",
  file.path(drakkar_dir, "annotation_qc.tsv")
)
transfer_manifest_path <- file.path(drakkar_dir, "transfer-manifest.tsv")
transfer_complete_path <- file.path(drakkar_dir, "transfer.complete")

required <- c(
  annotation_path,
  annotation_manifest_path,
  annotation_qc_path,
  transfer_manifest_path,
  transfer_complete_path,
  file.path(case_dir, "mag-manifest.tsv"),
  file.path(case_dir, "public-input-manifest.tsv"),
  file.path(public_dir, "metadata.tsv"),
  file.path(public_dir, "mag_counts.tsv"),
  file.path(public_dir, "stats.tsv"),
  file.path(public_dir, "taxonomy_v2.tsv"),
  file.path(public_dir, "ena_to_mag_id.tsv")
)
missing <- required[!file.exists(required)]
if (length(missing)) {
  stop(
    "R10 inputs are incomplete. Missing:\n  ",
    paste(missing, collapse = "\n  "),
    call. = FALSE
  )
}

write_tsv <- function(x, path) {
  utils::write.table(
    x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = ""
  )
}

write_xz_tsv <- function(x, path) {
  connection <- xzfile(path, open = "wt", compression = 9)
  on.exit(close(connection), add = TRUE)
  write_tsv(x, connection)
}

sha256 <- function(path) {
  command <- if (nzchar(Sys.which("shasum"))) "shasum" else "sha256sum"
  args <- if (identical(command, "shasum")) c("-a", "256", path) else path
  output <- system2(command, args, stdout = TRUE, stderr = TRUE)
  if (!length(output)) stop("Could not checksum ", path, call. = FALSE)
  sub("[[:space:]].*$", "", output[[1L]])
}

read_tsv <- function(path) {
  utils::read.delim(path, check.names = FALSE, stringsAsFactors = FALSE)
}

read_xz_tsv <- function(path) {
  connection <- xzfile(path, open = "rt")
  on.exit(close(connection), add = TRUE)
  utils::read.delim(connection, check.names = FALSE, stringsAsFactors = FALSE)
}

cat("Validating public and remote inputs...\n")
public_manifest <- read_tsv(file.path(case_dir, "public-input-manifest.tsv"))
public_observed <- vapply(
  file.path(public_dir, public_manifest$file), sha256, character(1)
)
if (!identical(unname(public_observed), public_manifest$sha256)) {
  bad <- public_manifest$file[public_observed != public_manifest$sha256]
  stop("Public input checksum mismatch: ", paste(bad, collapse = ", "), call. = FALSE)
}

transfer_manifest <- read_tsv(transfer_manifest_path)
transfer_paths <- file.path(drakkar_dir, transfer_manifest$file)
if (any(!file.exists(transfer_paths))) {
  stop(
    "Fetched transfer is incomplete: ",
    paste(transfer_manifest$file[!file.exists(transfer_paths)], collapse = ", "),
    call. = FALSE
  )
}
transfer_observed_sha <- vapply(transfer_paths, sha256, character(1))
transfer_observed_bytes <- unname(file.info(transfer_paths)$size)
if (!identical(unname(transfer_observed_sha), transfer_manifest$sha256) ||
    !identical(as.numeric(transfer_observed_bytes), as.numeric(transfer_manifest$bytes))) {
  stop("Fetched Drakkar files do not match transfer-manifest.tsv", call. = FALSE)
}

mag_manifest <- read_tsv(file.path(case_dir, "mag-manifest.tsv"))
taxonomy <- read_tsv(file.path(public_dir, "taxonomy_v2.tsv"))
stats <- read_tsv(file.path(public_dir, "stats.tsv"))
metadata <- read_tsv(file.path(public_dir, "metadata.tsv"))
counts_table <- read_tsv(file.path(public_dir, "mag_counts.tsv"))

stopifnot(
  nrow(mag_manifest) == 822L,
  nrow(taxonomy) == 822L,
  setequal(mag_manifest$genome_id, taxonomy$genome),
  nrow(metadata) == 388L,
  setequal(names(counts_table)[-1L], metadata$animal_code)
)

annotations <- read_xz_tsv(annotation_path)
expected_columns <- c("genome_id", "gene_id", "namespace", "accession")
if (!identical(names(annotations), expected_columns)) {
  stop(
    "Drakkar gifter input must have exactly: ",
    paste(expected_columns, collapse = ", "),
    call. = FALSE
  )
}
if (anyNA(annotations) || any(!nzchar(annotations$genome_id))) {
  stop("Drakkar gifter input contains missing identifiers", call. = FALSE)
}
if (!setequal(unique(annotations$genome_id), mag_manifest$genome_id)) {
  stop("Drakkar output does not cover exactly the 822 manifest MAGs", call. = FALSE)
}

transfer_complete <- utils::read.delim(
  transfer_complete_path,
  header = FALSE,
  check.names = FALSE,
  stringsAsFactors = FALSE
)
names(transfer_complete) <- c("item", "value")
completed_genomes <- suppressWarnings(as.integer(
  transfer_complete$value[transfer_complete$item == "genomes"]
))
completed_rows <- suppressWarnings(as.numeric(
  transfer_complete$value[transfer_complete$item == "marker_rows"]
))
if (!identical(completed_genomes, 822L) ||
    length(completed_rows) != 1L || completed_rows != nrow(annotations)) {
  stop("transfer.complete does not match the fetched marker table", call. = FALSE)
}

annotation_sha <- sha256(annotation_path)
database_sha <- sha256("inst/extdata/gifter.sqlite")
analysis_sha <- sha256("manuscript/analysis/21-r10-chicken.R")
analysis_cache_version <- "r10-2026-10-03-v1"
cache_key <- paste(annotation_sha, database_sha, sep = "-")
community_cache <- file.path(cache_dir, paste0("community-", cache_key, ".rds"))

if (file.exists(community_cache)) {
  cat("Reading cached genome calls...\n")
  community <- readRDS(community_cache)
} else {
  workers <- suppressWarnings(as.integer(Sys.getenv("R10_WORKERS", "8")))
  if (is.na(workers) || workers < 1L) workers <- 1L
  workers <- min(workers, 8L, length(unique(annotations$genome_id)))
  cat("Evaluating 822 genomes with ", workers, " workers...\n", sep = "")
  community <- evaluate_gifts_community(
    annotations,
    genome_id = "genome_id",
    gene_id = "gene_id",
    max_genes = Inf,
    workers = workers,
    progress = interactive()
  )
  saveRDS(community, community_cache, compress = "xz")
}
stopifnot(setequal(community$genome_id, mag_manifest$genome_id))

supported_calls <- do.call(rbind, lapply(community$genome_id, function(genome) {
  calls <- community$results[[genome]]$gifts
  calls <- calls[calls$complete, c(
    "gift_id", "gift_type", "best_implementation", "evidence_confidence",
    "supporting_genes"
  )]
  calls$supporting_genes <- vapply(
    calls$supporting_genes, paste, collapse = ";", FUN.VALUE = character(1)
  )
  calls$genome_id <- genome
  calls[c(
    "genome_id", "gift_id", "gift_type", "best_implementation",
    "evidence_confidence", "supporting_genes"
  )]
}))
rownames(supported_calls) <- NULL

# Attach the database-derived profile rather than re-deriving resource
# strategies in analysis code. Non-metabolic GIFTs correctly retain NA here.
profile <- as.data.frame(gift_profile())
profile_columns <- setdiff(names(profile), "gift_id")
profile_match <- match(supported_calls$gift_id, profile$gift_id)
for (column in profile_columns) {
  supported_calls[[column]] <- profile[[column]][profile_match]
}
write_xz_tsv(
  supported_calls,
  file.path(output_dir, "r10-supported-gift-calls.tsv.xz")
)

marker_counts <- as.data.frame(
  xtabs(~ genome_id + namespace, annotations), stringsAsFactors = FALSE
)
names(marker_counts)[3L] <- "retained_markers"
marker_counts <- marker_counts[marker_counts$retained_markers > 0, ]
write_tsv(marker_counts, file.path(output_dir, "r10-drakkar-marker-counts.tsv"))

# Reconstruct count/length relative abundance. The archived preparation divides
# by median_length / length, which multiplies by length; that object is retained
# only as a sensitivity source and is not the primary abundance here.
counts_table <- counts_table[match(community$genome_id, counts_table$mag_id), ]
stats <- stats[match(community$genome_id, stats$mag_id), ]
taxonomy <- taxonomy[match(community$genome_id, taxonomy$genome), ]
stopifnot(
  identical(counts_table$mag_id, community$genome_id),
  identical(stats$mag_id, community$genome_id),
  identical(taxonomy$genome, community$genome_id),
  all(stats$mag_length > 0)
)

counts <- as.matrix(counts_table[-1L])
storage.mode(counts) <- "double"
rownames(counts) <- counts_table$mag_id
length_corrected <- sweep(counts, 1L, stats$mag_length, "/")
abundance <- sweep(length_corrected, 2L, colSums(length_corrected), "/")
stopifnot(all(is.finite(abundance)), all(abundance >= 0))

metadata$sample_id <- metadata$animal_code
metadata <- metadata[match(colnames(abundance), metadata$sample_id), ]
dataset <- gifter_dataset(community, abundance, metadata)
quality <- stats::setNames(stats$completeness_score, stats$mag_id)

frames <- list(
  reference_frame(type = "metabolic", label = "All metabolic GIFTs"),
  reference_frame(preset = "carbohydrate_degradation"),
  reference_frame(preset = "plant_fibre_utilisation"),
  reference_frame(preset = "fermentation_products"),
  reference_frame(preset = "short_chain_fatty_acids"),
  reference_frame(preset = "biomass_essential_anabolism"),
  reference_frame(preset = "amino_acid_autonomy"),
  reference_frame(preset = "nucleotide_autonomy"),
  reference_frame(preset = "cofactor_autonomy"),
  reference_frame(preset = "extracellular_public_goods"),
  reference_frame(preset = "nutrient_uptake")
)

high_quality_genomes <- names(quality)[quality >= 90]
bounded_anabolism <- frames[[6L]]
bounded_state <- community$matrix[
  bounded_anabolism$gift_id, high_quality_genomes, drop = FALSE
]
gift_catalogue <- as.data.frame(list_gifts())
bounded_anabolism_gaps <- data.frame(
  gift_id = rownames(bounded_state),
  supported_genomes = rowSums(bounded_state),
  unsupported_genomes = ncol(bounded_state) - rowSums(bounded_state),
  assessable_genomes = ncol(bounded_state),
  support_fraction = rowSums(bounded_state) / ncol(bounded_state),
  stringsAsFactors = FALSE
)
bounded_anabolism_gaps$gift_name <- gift_catalogue$name[
  match(bounded_anabolism_gaps$gift_id, gift_catalogue$gift_id)
]
bounded_anabolism_gaps <- bounded_anabolism_gaps[c(
  "gift_id", "gift_name", "supported_genomes", "unsupported_genomes",
  "assessable_genomes", "support_fraction"
)]
bounded_anabolism_gaps <- bounded_anabolism_gaps[order(
  bounded_anabolism_gaps$supported_genomes, bounded_anabolism_gaps$gift_id
), ]
write_tsv(
  bounded_anabolism_gaps,
  file.path(output_dir, "r10-bounded-anabolism-gaps.tsv")
)

detection_thresholds <- c(0, 1e-5, 1e-4, 1e-3)
primary_detection <- 1e-3
detection_audit <- do.call(rbind, lapply(detection_thresholds, function(threshold) {
  detected <- colSums(abundance > threshold)
  data.frame(
    detection = threshold,
    minimum_detected_genomes = min(detected),
    median_detected_genomes = stats::median(detected),
    maximum_detected_genomes = max(detected),
    stringsAsFactors = FALSE
  )
}))
write_tsv(detection_audit, file.path(output_dir, "r10-detection-sensitivity.tsv"))

cat("Computing sample traits across detection thresholds...\n")
analysis_cache_key <- paste(cache_key, analysis_cache_version, sep = "-")
trait_cache <- file.path(
  cache_dir, paste0("dataset-traits-", analysis_cache_key, ".rds")
)
if (file.exists(trait_cache)) {
  trait_reads <- readRDS(trait_cache)
} else {
  trait_reads <- lapply(detection_thresholds, function(threshold) {
    suppressWarnings(dataset_traits(
      dataset,
      frames = frames,
      quality = quality,
      policy = "completeness",
      threshold = 90,
      detection = threshold,
      pairwise = FALSE,
      progress = FALSE
    ))
  })
  saveRDS(trait_reads, trait_cache, compress = "xz")
}
names(trait_reads) <- format(detection_thresholds, scientific = TRUE)

strict_trait_cache <- file.path(
  cache_dir, paste0("dataset-traits-high-confidence-", analysis_cache_key, ".rds")
)
if (file.exists(strict_trait_cache)) {
  strict_traits <- readRDS(strict_trait_cache)
} else {
  strict_traits <- suppressWarnings(dataset_traits(
    dataset,
    frames = frames,
    quality = quality,
    policy = "completeness",
    threshold = 90,
    min_confidence = "high-confidence",
    detection = primary_detection,
    pairwise = FALSE,
    progress = FALSE
  ))
  saveRDS(strict_traits, strict_trait_cache, compress = "xz")
}

confidence_metrics <- rbind(
  transform(
    as.data.frame(trait_reads[[which(detection_thresholds == primary_detection)]]$metrics),
    confidence_floor = "all accepted"
  ),
  transform(
    as.data.frame(strict_traits$metrics),
    confidence_floor = "high-confidence"
  )
)
confidence_metrics <- confidence_metrics[
  confidence_metrics$target_type == "community", , drop = FALSE
]
confidence_groups <- interaction(
  confidence_metrics[c("confidence_floor", "reference_frame", "metric_id")],
  drop = TRUE,
  lex.order = TRUE
)
confidence_sensitivity <- do.call(
  rbind,
  lapply(split(seq_len(nrow(confidence_metrics)), confidence_groups), function(index) {
    values <- confidence_metrics$value[index]
    data.frame(
      confidence_floor = confidence_metrics$confidence_floor[index[[1L]]],
      reference_frame = confidence_metrics$reference_frame[index[[1L]]],
      metric_id = confidence_metrics$metric_id[index[[1L]]],
      samples = sum(!is.na(values)),
      median = stats::median(values, na.rm = TRUE),
      q25 = as.numeric(stats::quantile(values, 0.25, na.rm = TRUE)),
      q75 = as.numeric(stats::quantile(values, 0.75, na.rm = TRUE)),
      stringsAsFactors = FALSE
    )
  })
)
rownames(confidence_sensitivity) <- NULL
write_tsv(
  confidence_sensitivity,
  file.path(output_dir, "r10-confidence-sensitivity.tsv")
)

sample_metrics <- do.call(rbind, Map(function(reading, threshold) {
  rows <- as.data.frame(reading$metrics)
  rows <- rows[rows$target_type == "community", ]
  rows$detection <- threshold
  rows
}, trait_reads, detection_thresholds))
rownames(sample_metrics) <- NULL
sample_metrics <- merge(sample_metrics, metadata, by = "sample_id", sort = FALSE)
sample_metrics <- sample_metrics[order(
  sample_metrics$detection, sample_metrics$reference_frame,
  sample_metrics$metric_id, sample_metrics$sample_id
), ]
sample_metric_export <- sample_metrics[c(
  "sample_id", "detection", "trial", "pen", "sampling_time", "metric_id",
  "value", "unit", "numerator", "denominator", "assessable",
  "reference_frame", "database_version"
)]
write_xz_tsv(
  sample_metric_export,
  file.path(output_dir, "r10-sample-traits.tsv.xz")
)

catalogue_metrics <- as.data.frame(trait_reads[[1L]]$catalogue_metrics)
catalogue_metrics <- catalogue_metrics[
  catalogue_metrics$target_type == "genome" &
    catalogue_metrics$metric_id == "gift_richness",
]
catalogue_metrics$genome_id <- catalogue_metrics$target_id
catalogue_metrics <- merge(
  catalogue_metrics,
  stats[c("mag_id", "completeness_score", "contamination_score", "mag_length")],
  by.x = "genome_id", by.y = "mag_id", sort = FALSE
)
catalogue_metrics <- merge(
  catalogue_metrics,
  taxonomy[c("genome", "phylum", "class", "order", "family", "genus", "species")],
  by.x = "genome_id", by.y = "genome", sort = FALSE
)
catalogue_metric_export <- catalogue_metrics[c(
  "genome_id", "reference_frame", "value", "unit", "numerator",
  "denominator", "assessable", "database_version", "completeness_score",
  "contamination_score", "mag_length", "phylum", "class", "order",
  "family", "genus", "species"
)]
write_xz_tsv(
  catalogue_metric_export,
  file.path(output_dir, "r10-genome-traits.tsv.xz")
)

# The bounded autonomy frames need per-genome denominators, which are not part
# of dataset_traits()' sample-invariant catalogue table. Read those frames, plus
# the two resource-strategy frames, through the public genome API and retain
# both metrics and their GIFT-level trace.
profile_frames <- frames[vapply(frames, function(frame) {
  isTRUE(frame$bounded) ||
    (!is.null(frame$preset) &&
       frame$preset %in% c("extracellular_public_goods", "nutrient_uptake"))
}, logical(1))]
genome_profile_cache <- file.path(
  cache_dir, paste0("genome-profiles-", analysis_cache_key, ".rds")
)
if (file.exists(genome_profile_cache)) {
  genome_profiles <- readRDS(genome_profile_cache)
} else {
  profile_db <- gifter_db_connect()
  genome_profiles <- tryCatch(
    lapply(community$genome_id, function(genome) {
      suppressWarnings(genome_traits(
        community$results[[genome]],
        frames = profile_frames,
        genome_id = genome,
        quality = stats::setNames(quality[[genome]], genome),
        policy = "completeness",
        threshold = 90,
        db = profile_db
      ))
    }),
    finally = gifter_db_disconnect(profile_db)
  )
  names(genome_profiles) <- community$genome_id
  saveRDS(genome_profiles, genome_profile_cache, compress = "xz")
}
genome_profile_metrics <- do.call(
  rbind,
  lapply(genome_profiles, function(reading) as.data.frame(reading$metrics))
)
genome_profile_metrics <- genome_profile_metrics[
  genome_profile_metrics$metric_id %in%
    c("gift_richness", "supported_fraction", "assessable_fraction"),
]
genome_profile_metrics <- merge(
  genome_profile_metrics,
  stats[c("mag_id", "completeness_score", "contamination_score")],
  by.x = "target_id", by.y = "mag_id", sort = FALSE
)
genome_profile_metrics <- merge(
  genome_profile_metrics,
  taxonomy[c("genome", "phylum", "class", "order", "family", "genus", "species")],
  by.x = "target_id", by.y = "genome", sort = FALSE
)
write_xz_tsv(
  genome_profile_metrics,
  file.path(output_dir, "r10-genome-resource-autonomy-profiles.tsv.xz")
)
genome_profile_trace <- do.call(
  rbind,
  lapply(genome_profiles, function(reading) as.data.frame(reading$trace))
)
write_xz_tsv(
  genome_profile_trace,
  file.path(output_dir, "r10-genome-resource-autonomy-trace.tsv.xz")
)

summarise_groups <- function(table, keys) {
  groups <- interaction(table[keys], drop = TRUE, lex.order = TRUE)
  parts <- lapply(split(seq_len(nrow(table)), groups), function(index) {
    row <- table[index[[1L]], keys, drop = FALSE]
    values <- table$value[index]
    row$n <- sum(!is.na(values))
    row$mean <- mean(values, na.rm = TRUE)
    row$sd <- stats::sd(values, na.rm = TRUE)
    row$median <- stats::median(values, na.rm = TRUE)
    row$q25 <- as.numeric(stats::quantile(values, 0.25, na.rm = TRUE))
    row$q75 <- as.numeric(stats::quantile(values, 0.75, na.rm = TRUE))
    row
  })
  result <- do.call(rbind, parts)
  rownames(result) <- NULL
  result
}

age_summary <- summarise_groups(
  sample_metrics,
  c("detection", "sampling_time", "trial", "reference_frame", "metric_id")
)
write_tsv(age_summary, file.path(output_dir, "r10-age-summary.tsv"))

# Planned age contrasts. Trial, treatment, breed and sex are fixed design terms
# and pen is a random intercept; all contrasts remain on the metric's original,
# interpretable scale. These tests describe this dataset and are not part of
# gifter itself.
model_metrics <- sample_metrics[
  sample_metrics$metric_id %in% c(
    "community_richness", "mean_genome_richness", "community_coverage",
    "singleton_fraction"
  ),
]
fit_contrasts <- function(table) {
  observed <- table$value[is.finite(table$value)]
  tolerance <- sqrt(.Machine$double.eps) * max(1, abs(observed))
  if (length(observed) < 2L || diff(range(observed)) <= max(tolerance)) {
    return(data.frame(
      contrast = c("day_21_minus_day_7", "day_35_minus_day_7"),
      estimate = NA_real_, standard_error = NA_real_, degrees_freedom = NA_real_,
      p_value = NA_real_, model_status = "constant_metric",
      stringsAsFactors = FALSE
    ))
  }
  table$sampling_time <- factor(table$sampling_time, levels = c(7, 21, 35))
  table$trial <- factor(table$trial)
  table$treatment <- factor(table$treatment)
  table$breed <- factor(table$breed)
  table$sex <- factor(table$sex)
  table$pen <- factor(table$pen)
  fit <- tryCatch(
    suppressWarnings(nlme::lme(
      value ~ sampling_time + trial + treatment + breed + sex,
      random = ~ 1 | pen,
      data = table,
      na.action = stats::na.omit,
      method = "REML",
      control = nlme::lmeControl(returnObject = TRUE)
    )),
    error = function(error) error
  )
  if (inherits(fit, "error")) {
    return(data.frame(
      contrast = c("day_21_minus_day_7", "day_35_minus_day_7"),
      estimate = NA_real_, standard_error = NA_real_, degrees_freedom = NA_real_,
      p_value = NA_real_, model_status = conditionMessage(fit),
      stringsAsFactors = FALSE
    ))
  }
  coefficients <- summary(fit)$tTable
  terms <- c("sampling_time21", "sampling_time35")
  data.frame(
    contrast = c("day_21_minus_day_7", "day_35_minus_day_7"),
    estimate = unname(coefficients[terms, "Value"]),
    standard_error = unname(coefficients[terms, "Std.Error"]),
    degrees_freedom = unname(coefficients[terms, "DF"]),
    p_value = unname(coefficients[terms, "p-value"]),
    model_status = "ok",
    stringsAsFactors = FALSE
  )
}

model_keys <- c("detection", "reference_frame", "metric_id")
model_groups <- interaction(model_metrics[model_keys], drop = TRUE, lex.order = TRUE)
model_parts <- lapply(split(seq_len(nrow(model_metrics)), model_groups), function(index) {
  key <- model_metrics[index[[1L]], model_keys, drop = FALSE]
  rownames(key) <- NULL
  cbind(key, fit_contrasts(model_metrics[index, ]))
})
age_contrasts <- do.call(rbind, model_parts)
rownames(age_contrasts) <- NULL
age_contrasts$q_value <- stats::p.adjust(age_contrasts$p_value, method = "BH")
write_tsv(age_contrasts, file.path(output_dir, "r10-age-contrasts.tsv"))

# Exact extracellular-anchor-compatible topology at the conservative threshold.
# No result here asserts exchange or ecological interaction.
cat("Computing exact plant-fibre handoff sensitivity network...\n")
plant_frame <- frames[[3L]]
network_cache <- file.path(
  cache_dir, paste0("network-plant-fibre-exact-", analysis_cache_key, ".rds")
)
if (file.exists(network_cache)) {
  network <- readRDS(network_cache)
} else {
  network <- dataset_network(
    dataset,
    frame = plant_frame,
    quality = "exact",
    detection = primary_detection
  )
  saveRDS(network, network_cache, compress = "xz")
}
network_metrics <- merge(as.data.frame(network$metrics), metadata, by = "sample_id", sort = FALSE)
network_metrics$detection <- primary_detection
network_metric_export <- network_metrics[c(
  "sample_id", "detection", "trial", "pen", "sampling_time", "metric_id",
  "value", "unit", "numerator", "denominator", "assessable",
  "reference_frame", "database_version"
)]
write_tsv(network_metric_export, file.path(output_dir, "r10-network-metrics.tsv"))

if (nrow(network$chain_coverage) && "status" %in% names(network$chain_coverage)) {
  chain_status <- as.data.frame(xtabs(
    ~ sample_id + status,
    data = as.data.frame(network$chain_coverage)
  ))
  chain_status <- chain_status[chain_status$Freq > 0, ]
  names(chain_status)[3L] <- "links"
  chain_status$detection <- primary_detection
  chain_status <- merge(chain_status, metadata, by = "sample_id", sort = FALSE)
} else {
  chain_status <- data.frame(
    sample_id = character(), status = character(), links = integer(),
    detection = numeric(), stringsAsFactors = FALSE
  )
}
write_tsv(chain_status, file.path(output_dir, "r10-chain-status.tsv"))

input_audit <- data.frame(
  item = c(
    "published_bacterial_mags", "samples", "drakkar_marker_rows",
    "drakkar_marker_genomes", "supported_genome_gift_calls",
    "supported_call_genomes", "represented_gifts", "catalogue_gifts",
    "high_quality_genomes_at_90_percent",
    "annotation_sha256", "annotation_manifest_sha256",
    "annotation_qc_sha256", "gifter_sqlite_sha256",
    "analysis_script_sha256", "analysis_cache_version", "primary_detection",
    "confidence_sensitivity_floor",
    "completeness_assessability_threshold_percent"
  ),
  value = c(
    nrow(mag_manifest), nrow(metadata), nrow(annotations),
    length(unique(annotations$genome_id)), nrow(supported_calls),
    length(unique(supported_calls$genome_id)),
    length(unique(supported_calls$gift_id)), nrow(gift_catalogue),
    length(high_quality_genomes),
    annotation_sha, sha256(annotation_manifest_path), sha256(annotation_qc_path),
    database_sha, analysis_sha, analysis_cache_version, primary_detection,
    "high-confidence", 90
  ),
  stringsAsFactors = FALSE
)
write_tsv(input_audit, file.path(output_dir, "r10-input-audit.tsv"))

# Figure 7: encoded capability summaries only. The subtitle carries the
# operational detection threshold because the original breadth matrix is absent.
plot_metrics <- rbind(
  transform(
    sample_metrics[
      sample_metrics$detection == primary_detection &
        sample_metrics$reference_frame == "All metabolic GIFTs" &
        sample_metrics$metric_id == "community_richness",
    ], panel = "Community metabolic GIFT richness"
  ),
  transform(
    sample_metrics[
      sample_metrics$detection == primary_detection &
        sample_metrics$reference_frame == "All metabolic GIFTs" &
        sample_metrics$metric_id == "mean_genome_richness",
    ], panel = "Mean encoded repertoire per detected MAG"
  ),
  transform(
    sample_metrics[
      sample_metrics$detection == primary_detection &
        sample_metrics$reference_frame == "Plant fibre utilisation" &
        sample_metrics$metric_id == "community_richness",
    ], panel = "Community plant-fibre GIFT richness"
  ),
  transform(
    network_metrics[network_metrics$metric_id == "interaction_density", ],
    panel = "Exact potential handoff density"
  )
)
plot_metrics$sampling_time <- factor(
  plot_metrics$sampling_time, levels = c(7, 21, 35),
  labels = c("day 7", "day 21", "day 35")
)
plot_metrics$panel <- factor(plot_metrics$panel, levels = c(
  "Community metabolic GIFT richness",
  "Mean encoded repertoire per detected MAG",
  "Community plant-fibre GIFT richness",
  "Exact potential handoff density"
))

figure <- ggplot(plot_metrics, aes(sampling_time, value, colour = trial)) +
  geom_boxplot(aes(group = interaction(sampling_time, trial)), outlier.shape = NA,
               width = 0.62, alpha = 0.18) +
  geom_jitter(width = 0.16, height = 0, alpha = 0.34, size = 0.8) +
  facet_wrap(~ panel, scales = "free_y", ncol = 2) +
  scale_colour_manual(values = c(CA = "#356E75", CB = "#C17A35")) +
  labs(
    x = NULL, y = NULL, colour = "trial",
    title = "Encoded capability structure across chicken caecal maturation",
    subtitle = paste0(
      "822 reannotated MAGs; completeness changes absence denominators only; ",
      "operational detection > ", format(primary_detection),
      " relative abundance"
    )
  ) +
  theme_bw(base_size = 10) +
  theme(
    legend.position = "top",
    strip.text = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

ggsave(file.path(figure_dir, "figure-7-r10-chicken.pdf"), figure,
       width = 8.2, height = 6.3, device = cairo_pdf)
ggsave(file.path(figure_dir, "figure-7-r10-chicken.png"), figure,
       width = 8.2, height = 6.3, dpi = 320)

cat("R10 analysis complete.\n")
