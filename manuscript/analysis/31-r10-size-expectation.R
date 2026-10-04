# R10 follow-up: is the narrowing per-MAG repertoire a genome-size effect?
#
# 24-r10-reference-frame-time.R shows that the mean repertoire per detected MAG
# falls with age while the community union does not. 26-gtdb-repertoire-genome-
# size.R shows that, across the GTDB panel, repertoire size follows genome size.
# This script asks how much of the chicken trend that size relation predicts.
#
# Each MAG gets a size expectation from the GTDB panel, per reference frame, and
# every sample's mean per-MAG richness is split exactly into the mean expected
# from the sizes of its detected MAGs and the mean deviation from it. The same
# age model as R10 is then fitted to each part. A second, independent partition
# replaces each MAG by the mean of its taxon, to say at which taxonomic rank the
# turnover that carries the trend occurs.
#
# The GTDB panel was evaluated against a later database than the audited R10
# calls, so the MAGs are evaluated again here against the database the panel
# used. The audited R10 outputs are neither read as calls nor rewritten. No call
# is changed by size, completeness, detection or abundance: they only select and
# weight genomes. A deviation is a difference in encoded, curated capabilities;
# it is not activity, flux, phenotype or genome streamlining as a process.
#
# Run from the repository root after 21-r10-chicken.R and 23-gtdb-phylogeny.R:
#   Rscript manuscript/analysis/31-r10-size-expectation.R
# If the working database has advanced since the GTDB panel was audited, point
# R10_DB_PATH at the archived, hash-matching SQLite artifact instead.

suppressWarnings(suppressPackageStartupMessages({
  library(ggplot2)
  library(patchwork)
}))

devtools::load_all(".", quiet = TRUE)

root <- "manuscript/analysis"
cache_dir <- Sys.getenv(
  "R10_CACHE_DIR", file.path(root, ".cache", "r10-chicken")
)
public_dir <- Sys.getenv(
  "R10_PUBLIC_DATA", file.path(cache_dir, "public-data")
)
drakkar_dir <- Sys.getenv("R10_DRAKKAR_DIR", file.path(cache_dir, "drakkar"))
output_dir <- Sys.getenv("R10_OUTPUT_DIR", file.path(root, "output"))
figure_dir <- Sys.getenv("R10_FIGURE_DIR", "manuscript/figures")

HIGH_COMPLETENESS <- 90
TAXON_RANKS <- c("phylum", "class", "order", "family", "genus")
LABELLED_FRAME_CONTRAST <- 0.4
FOCAL_FRAMES <- c(
  "amino_acid_autonomy", "biomass_essential_anabolism", "vitamin_biosynthesis"
)

read_tsv <- function(path) {
  utils::read.delim(path, check.names = FALSE, stringsAsFactors = FALSE)
}
read_xz_tsv <- function(path) {
  connection <- xzfile(path, open = "rt")
  on.exit(close(connection), add = TRUE)
  utils::read.delim(connection, check.names = FALSE, stringsAsFactors = FALSE)
}
write_tsv <- function(x, path) {
  utils::write.table(
    x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = ""
  )
}
sha256 <- function(path) {
  command <- if (nzchar(Sys.which("shasum"))) "shasum" else "sha256sum"
  args <- if (identical(command, "shasum")) c("-a", "256", path) else path
  output <- system2(command, args, stdout = TRUE, stderr = TRUE)
  if (!length(output)) stop("Could not checksum ", path, call. = FALSE)
  sub("[[:space:]].*$", "", output[[1L]])
}

# ----------------------------------------------------------------------- inputs

r10_audit_path <- file.path(output_dir, "r10-input-audit.tsv")
gtdb_audit_path <- file.path(output_dir, "gtdb-phylogeny-input-audit.tsv")
gtdb_genomes_path <- file.path(output_dir, "gtdb-phylogeny-genome-summary.tsv")
gtdb_calls_path <- file.path(output_dir, "gtdb-phylogeny-calls.tsv.xz")
annotation_path <- file.path(drakkar_dir, "gifter_input.tsv.xz")
required <- c(
  r10_audit_path, gtdb_audit_path, gtdb_genomes_path, gtdb_calls_path,
  annotation_path, file.path(public_dir, "stats.tsv"),
  file.path(public_dir, "taxonomy_v2.tsv")
)
missing <- required[!file.exists(required)]
if (length(missing)) {
  stop("Run 21-r10-chicken.R and 23-gtdb-phylogeny.R first. Missing:\n  ",
       paste(missing, collapse = "\n  "), call. = FALSE)
}

r10_audit <- read_tsv(r10_audit_path)
r10_audit <- stats::setNames(r10_audit$value, r10_audit$item)
gtdb_audit <- read_tsv(gtdb_audit_path)
gtdb_audit <- stats::setNames(gtdb_audit$value, gtdb_audit$item)

# The expectation and the MAG calls must come from one database.
database_path <- Sys.getenv("R10_DB_PATH", "inst/extdata/gifter.sqlite")
database_sha <- sha256(database_path)
if (!identical(database_sha, unname(gtdb_audit[["gifter SQLite sha256"]]))) {
  stop("The gifter database no longer matches the GTDB panel audit; rerun ",
       "23-gtdb-phylogeny.R or set R10_DB_PATH to the audited artifact",
       call. = FALSE)
}
database <- gifter_db_connect(database_path)
on.exit(gifter_db_disconnect(database), add = TRUE)
annotation_sha <- sha256(annotation_path)
if (!identical(annotation_sha, unname(r10_audit[["annotation_sha256"]]))) {
  stop("The Drakkar marker table no longer matches the R10 audit", call. = FALSE)
}

# Sample membership is independent of the database: reuse the detection and
# abundance matrices of the audited R10 readings.
trait_cache <- file.path(cache_dir, paste0(
  "dataset-traits-", r10_audit[["annotation_sha256"]], "-",
  r10_audit[["gifter_sqlite_sha256"]], "-",
  r10_audit[["analysis_cache_version"]], ".rds"
))
if (!file.exists(trait_cache)) {
  stop("Missing R10 cache input: ", trait_cache, call. = FALSE)
}
trait_reads <- readRDS(trait_cache)
thresholds <- vapply(trait_reads, function(x) x$detection, numeric(1))
primary_detection <- as.numeric(r10_audit[["primary_detection"]])
stopifnot(
  identical(thresholds, c(0, 1e-5, 1e-4, 1e-3)),
  identical(primary_detection, 1e-3)
)
primary_read <- trait_reads[[which(thresholds == primary_detection)]]
genome_ids <- rownames(primary_read$detected)
metadata <- as.data.frame(primary_read$metadata)
metadata <- metadata[match(colnames(primary_read$detected), metadata$sample_id), ]
stopifnot(identical(metadata$sample_id, colnames(primary_read$detected)))

community_cache <- file.path(
  cache_dir, paste0("community-", annotation_sha, "-", database_sha, ".rds")
)
if (file.exists(community_cache)) {
  cat("Reading cached genome calls...\n")
  community <- readRDS(community_cache)
} else {
  annotations <- read_xz_tsv(annotation_path)
  workers <- suppressWarnings(as.integer(Sys.getenv("R10_WORKERS", "8")))
  if (is.na(workers) || workers < 1L) workers <- 1L
  workers <- min(workers, 8L)
  cat("Evaluating 822 genomes with ", workers, " workers...\n", sep = "")
  community <- evaluate_gifts_community(
    annotations, genome_id = "genome_id", gene_id = "gene_id",
    max_genes = Inf, workers = workers, db = database,
    progress = interactive()
  )
  saveRDS(community, community_cache, compress = "xz")
  rm(annotations)
}
stopifnot(setequal(community$genome_id, genome_ids))
mag_calls <- community$matrix[, genome_ids, drop = FALSE]
storage.mode(mag_calls) <- "double"

stats <- read_tsv(file.path(public_dir, "stats.tsv"))
taxonomy <- read_tsv(file.path(public_dir, "taxonomy_v2.tsv"))
stats <- stats[match(genome_ids, stats$mag_id), ]
taxonomy <- taxonomy[match(genome_ids, taxonomy$genome), ]
stopifnot(
  identical(stats$mag_id, genome_ids), identical(taxonomy$genome, genome_ids),
  all(stats$mag_length > 0), all(stats$completeness_score > 0)
)

gtdb_genomes <- read_tsv(gtdb_genomes_path)
gtdb_long <- read_xz_tsv(gtdb_calls_path)
gtdb_calls <- unclass(xtabs(
  as.integer(as.logical(complete)) ~ gift_id + genome_id, gtdb_long
))
gtdb_calls <- gtdb_calls[, gtdb_genomes$genome_id, drop = FALSE]
rm(gtdb_long)
stopifnot(
  setequal(rownames(gtdb_calls), rownames(mag_calls)),
  identical(
    as.integer(colSums(gtdb_calls)),
    as.integer(gtdb_genomes[["all supported GIFTs"]])
  )
)
gtdb_calls <- gtdb_calls[rownames(mag_calls), , drop = FALSE]

# Frames are database metadata, never a GIFT list written here.
gift_catalogue <- as.data.frame(list_gifts(db = database))
frame_catalogue <- as.data.frame(list_reference_frames(db = database))
frames <- c(
  list(
    all_gifts = list(label = "All GIFTs", gift_id = gift_catalogue$gift_id),
    all_metabolic = list(
      label = "All metabolic GIFTs",
      gift_id = reference_frame(type = "metabolic", db = database)$gift_id
    )
  ),
  stats::setNames(lapply(seq_len(nrow(frame_catalogue)), function(i) {
    list(
      label = frame_catalogue$label[[i]],
      gift_id = reference_frame(
        preset = frame_catalogue$frame_id[[i]], db = database
      )$gift_id
    )
  }), frame_catalogue$frame_id)
)
stopifnot(all(unlist(lapply(frames, `[[`, "gift_id")) %in% rownames(mag_calls)))

# ------------------------------------------------------------------ expectation

# A MAG's length understates its genome by the missing fraction. The primary
# size is length over reported completeness; raw length is a sensitivity
# variant. Sizes outside the GTDB range are read at the range boundary rather
# than extrapolated.
gtdb <- data.frame(
  log10_genome_size = log10(gtdb_genomes$genome_size),
  checkm2_completeness = gtdb_genomes$checkm2_completeness,
  metagenome_derived = gtdb_genomes$ncbi_genome_category == "derived from metagenome"
)
size_range <- range(gtdb$log10_genome_size)
clamp <- function(x) pmin(pmax(x, size_range[[1L]]), size_range[[2L]])
mags <- data.frame(
  genome_id = genome_ids,
  taxonomy[c("phylum", "class", "order", "family", "genus", "species")],
  mag_length = stats$mag_length,
  completeness = stats$completeness_score,
  contamination = stats$contamination_score,
  estimated_genome_size = stats$mag_length / (stats$completeness_score / 100),
  stringsAsFactors = FALSE
)
mags$outside_gtdb_size_range <-
  log10(mags$estimated_genome_size) != clamp(log10(mags$estimated_genome_size))

size_variants <- list(
  estimated = data.frame(
    log10_genome_size = clamp(log10(mags$estimated_genome_size))
  ),
  raw_length = data.frame(log10_genome_size = clamp(log10(mags$mag_length))),
  quality_adjusted = data.frame(
    log10_genome_size = clamp(log10(mags$estimated_genome_size)),
    checkm2_completeness = pmin(mags$completeness, 100),
    metagenome_derived = TRUE
  )
)

expect_frame <- function(frame, quality_adjusted) {
  members <- frame$gift_id
  n <- length(members)
  data <- gtdb
  data$supported <- colSums(gtdb_calls[members, , drop = FALSE])
  formula <- if (quality_adjusted) {
    cbind(supported, n - supported) ~ s(log10_genome_size, k = 6) +
      checkm2_completeness + metagenome_derived
  } else {
    cbind(supported, n - supported) ~ s(log10_genome_size, k = 6)
  }
  fit <- mgcv::gam(
    formula, family = stats::quasibinomial(), data = data, method = "REML"
  )
  list(fit = fit, n = n)
}
models <- lapply(frames, expect_frame, quality_adjusted = FALSE)
adjusted_models <- lapply(frames, expect_frame, quality_adjusted = TRUE)

# One row per frame, one column per MAG.
observed <- t(vapply(
  frames, function(frame) colSums(mag_calls[frame$gift_id, , drop = FALSE]),
  numeric(length(genome_ids))
))
predict_frames <- function(model_set, newdata) {
  t(vapply(model_set, function(model) {
    model$n * as.numeric(stats::predict(model$fit, newdata, type = "response"))
  }, numeric(length(genome_ids))))
}
expected <- list(
  estimated = predict_frames(models, size_variants$estimated),
  raw_length = predict_frames(models, size_variants$raw_length),
  quality_adjusted = predict_frames(adjusted_models, size_variants$quality_adjusted)
)
for (name in names(expected)) dimnames(expected[[name]]) <- dimnames(observed)
colnames(observed) <- genome_ids

# The all-GIFT expectation must be the model of 26-gtdb-repertoire-genome-size.R.
published_model <- read_tsv(file.path(output_dir, "gtdb-size-expectation-model.tsv"))
published_model <- stats::setNames(published_model$value, published_model$item)
stopifnot(
  identical(as.integer(published_model[["current GIFTs"]]), models$all_gifts$n),
  isTRUE(all.equal(
    round(summary(models$all_gifts$fit)$dev.expl, 4),
    as.numeric(published_model[["deviance explained"]])
  ))
)

mags$supported <- observed["all_gifts", ]
mags$expected <- expected$estimated["all_gifts", ]
mags$deviation <- mags$supported - mags$expected
mags$expected_quality_adjusted <- expected$quality_adjusted["all_gifts", ]

# ------------------------------------------------------------ sample-level parts

# mean per-MAG richness = mean size expectation + mean deviation, exactly.
sample_parts <- function(weights, frame_values, expectation, variant, detection) {
  weights <- sweep(weights, 2L, colSums(weights), "/")
  observed_mean <- frame_values %*% weights
  expected_mean <- expectation %*% weights
  parts <- list(
    observed = observed_mean, size_expected = expected_mean,
    deviation = observed_mean - expected_mean
  )
  do.call(rbind, lapply(names(parts), function(part) {
    data.frame(
      variant = variant, detection = detection,
      frame_id = rep(rownames(frame_values), times = ncol(weights)),
      part = part,
      sample_id = rep(colnames(weights), each = nrow(frame_values)),
      value = as.vector(parts[[part]]),
      stringsAsFactors = FALSE
    )
  }))
}
membership <- function(reading, keep = TRUE) {
  weights <- reading$detected[genome_ids, metadata$sample_id, drop = FALSE] * 1
  weights * keep
}
high_quality <- mags$completeness >= HIGH_COMPLETENESS
closed_abundance <- primary_read$abundance[genome_ids, metadata$sample_id] *
  membership(primary_read)

parts <- rbind(
  do.call(rbind, lapply(trait_reads, function(reading) {
    sample_parts(membership(reading), observed, expected$estimated,
                 "primary", reading$detection)
  })),
  sample_parts(membership(primary_read), observed, expected$raw_length,
               "raw MAG length", primary_detection),
  sample_parts(membership(primary_read, high_quality), observed,
               expected$estimated, "MAGs at least 90% complete",
               primary_detection),
  sample_parts(membership(primary_read), observed, expected$quality_adjusted,
               "quality-adjusted expectation", primary_detection),
  sample_parts(closed_abundance, observed, expected$estimated,
               "abundance-weighted", primary_detection)
)

# The mean estimated genome size of the detected MAGs, as its own reading.
size_rows <- do.call(rbind, lapply(trait_reads, function(reading) {
  weights <- membership(reading)
  data.frame(
    variant = "primary", detection = reading$detection,
    frame_id = "genome_size", part = "mean_estimated_genome_size_mb",
    sample_id = colnames(weights),
    value = as.vector((mags$estimated_genome_size / 1e6) %*% weights) /
      colSums(weights),
    stringsAsFactors = FALSE
  )
}))

# --------------------------------------------------------------- taxon partition

# Replace each MAG by the mean of its taxon over the whole catalogue. The
# between-taxon part is what a sample would show if every detected MAG were
# typical of its taxon; the remainder is turnover among MAGs within taxa.
taxon_key <- function(rank) {
  ranks <- c("phylum", "class", "order", "family", "genus")
  do.call(paste, c(mags[ranks[seq_len(match(rank, ranks))]], sep = ";"))
}
taxon_parts <- do.call(rbind, lapply(TAXON_RANKS, function(rank) {
  key <- taxon_key(rank)
  typical <- function(values) {
    t(apply(values, 1L, function(row) stats::ave(row, key)))
  }
  weights <- sweep(membership(primary_read), 2L,
                   colSums(membership(primary_read)), "/")
  sources <- list(
    observed = observed, size_expected = expected$estimated,
    deviation = observed - expected$estimated
  )
  do.call(rbind, lapply(names(sources), function(part) {
    total <- sources[[part]] %*% weights
    between <- typical(sources[[part]]) %*% weights
    components <- list(between_taxa = between, within_taxa = total - between)
    do.call(rbind, lapply(names(components), function(component) {
      data.frame(
        variant = paste(rank, component, sep = ":"),
        detection = primary_detection,
        frame_id = rep(rownames(observed), times = ncol(weights)),
        part = part,
        sample_id = rep(colnames(weights), each = nrow(observed)),
        value = as.vector(components[[component]]),
        stringsAsFactors = FALSE
      )
    }))
  }))
}))

# ------------------------------------------------------------------- age models

fit_contrasts <- function(table) {
  empty <- data.frame(
    contrast = c("day_21_minus_day_7", "day_35_minus_day_7"),
    estimate = NA_real_, standard_error = NA_real_, degrees_freedom = NA_real_,
    confidence_low = NA_real_, confidence_high = NA_real_, p_value = NA_real_,
    stringsAsFactors = FALSE
  )
  values <- table$value[is.finite(table$value)]
  if (length(values) < 2L ||
      diff(range(values)) <= sqrt(.Machine$double.eps) * max(1, abs(values))) {
    empty[c("estimate", "standard_error", "confidence_low", "confidence_high")] <- 0
    empty$model_status <- "constant_metric"
    return(empty)
  }
  table$sampling_time <- factor(table$sampling_time, levels = c(7, 21, 35))
  for (column in c("trial", "treatment", "breed", "sex", "pen")) {
    table[[column]] <- factor(table[[column]])
  }
  fit <- tryCatch(
    suppressWarnings(nlme::lme(
      value ~ sampling_time + trial + treatment + breed + sex,
      random = ~ 1 | pen, data = table, na.action = stats::na.omit,
      method = "REML", control = nlme::lmeControl(returnObject = TRUE)
    )),
    error = function(error) error
  )
  if (inherits(fit, "error")) {
    empty$model_status <- conditionMessage(fit)
    return(empty)
  }
  coefficients <- summary(fit)$tTable
  terms <- c("sampling_time21", "sampling_time35")
  estimate <- unname(coefficients[terms, "Value"])
  standard_error <- unname(coefficients[terms, "Std.Error"])
  degrees_freedom <- unname(coefficients[terms, "DF"])
  critical <- stats::qt(0.975, degrees_freedom)
  empty$estimate <- estimate
  empty$standard_error <- standard_error
  empty$degrees_freedom <- degrees_freedom
  empty$confidence_low <- estimate - critical * standard_error
  empty$confidence_high <- estimate + critical * standard_error
  empty$p_value <- unname(coefficients[terms, "p-value"])
  empty$model_status <- "ok"
  empty
}

fit_grouped <- function(table) {
  keys <- c("variant", "detection", "frame_id", "part")
  covariates <- metadata[match(table$sample_id, metadata$sample_id), c(
    "trial", "pen", "treatment", "breed", "sex", "sampling_time"
  )]
  table <- cbind(table, covariates)
  groups <- interaction(table[keys], drop = TRUE, lex.order = TRUE)
  result <- do.call(rbind, lapply(split(seq_len(nrow(table)), groups), function(index) {
    key <- table[index[[1L]], keys, drop = FALSE]
    rownames(key) <- NULL
    cbind(key, fit_contrasts(table[index, , drop = FALSE]))
  }))
  rownames(result) <- NULL
  result$q_value <- stats::p.adjust(result$p_value, method = "BH")
  result
}

cat("Fitting age models...\n")
contrasts <- fit_grouped(rbind(parts, size_rows))
taxon_contrasts <- fit_grouped(taxon_parts)

frame_labels <- vapply(frames, `[[`, character(1), "label")
frame_sizes <- vapply(frames, function(frame) length(frame$gift_id), integer(1))
label_frames <- function(table) {
  table$reference_frame <- unname(frame_labels[table$frame_id])
  table$member_count <- unname(frame_sizes[table$frame_id])
  table
}

# Share of each observed contrast that the size expectation reproduces.
wide_parts <- function(table) {
  keys <- c("variant", "detection", "frame_id", "contrast")
  observed_rows <- table[table$part == "observed", ]
  pick <- function(part, column) {
    rows <- table[table$part == part, ]
    rows[[column]][match(
      do.call(paste, observed_rows[keys]), do.call(paste, rows[keys])
    )]
  }
  data.frame(
    observed_rows[keys],
    observed = observed_rows$estimate,
    observed_low = observed_rows$confidence_low,
    observed_high = observed_rows$confidence_high,
    observed_q_value = observed_rows$q_value,
    size_expected = pick("size_expected", "estimate"),
    size_expected_low = pick("size_expected", "confidence_low"),
    size_expected_high = pick("size_expected", "confidence_high"),
    size_expected_q_value = pick("size_expected", "q_value"),
    deviation = pick("deviation", "estimate"),
    deviation_low = pick("deviation", "confidence_low"),
    deviation_high = pick("deviation", "confidence_high"),
    deviation_q_value = pick("deviation", "q_value"),
    stringsAsFactors = FALSE
  )
}
decomposition <- wide_parts(contrasts[contrasts$frame_id != "genome_size", ])
decomposition$share_reproduced_by_size <- ifelse(
  abs(decomposition$observed) > 0,
  decomposition$size_expected / decomposition$observed, NA_real_
)
decomposition <- label_frames(decomposition)

taxon_table <- taxon_contrasts
taxon_table$rank <- sub(":.*$", "", taxon_table$variant)
taxon_table$component <- sub("^.*:", "", taxon_table$variant)
total <- contrasts[contrasts$variant == "primary" &
                     contrasts$detection == primary_detection, ]
taxon_table$total_estimate <- total$estimate[match(
  paste(taxon_table$frame_id, taxon_table$part, taxon_table$contrast),
  paste(total$frame_id, total$part, total$contrast)
)]
taxon_table$share_of_total <- ifelse(
  abs(taxon_table$total_estimate) > 0,
  taxon_table$estimate / taxon_table$total_estimate, NA_real_
)
taxon_table$taxa <- vapply(
  taxon_table$rank, function(rank) length(unique(taxon_key(rank))), integer(1)
)
taxon_table <- label_frames(taxon_table)

# ------------------------------------------------------------------ MAG reading

# Which MAGs become more or less often detected with age, and how that relates
# to size and to the deviation. Family is a random intercept because related
# MAGs share both.
detected <- membership(primary_read) > 0
for (day in c(7, 21, 35)) {
  mags[[paste0("prevalence_day_", day)]] <- rowMeans(
    detected[, metadata$sampling_time == day, drop = FALSE]
  )
}
mags$prevalence_change <- mags$prevalence_day_35 - mags$prevalence_day_7
mags$family_key <- taxon_key("family")
mags$log10_estimated_genome_size <- log10(mags$estimated_genome_size)
mag_association <- function(response, subset, label) {
  data <- mags[subset, ]
  data$response <- data[[response]]
  correlation <- suppressWarnings(stats::cor.test(
    data$response, data$prevalence_change, method = "spearman"
  ))
  fit <- nlme::lme(
    response ~ prevalence_change, random = ~ 1 | family_key, data = data,
    method = "REML"
  )
  row <- summary(fit)$tTable["prevalence_change", ]
  data.frame(
    response = response, mags = label, genomes = nrow(data),
    families = length(unique(data$family_key)),
    spearman_rho = unname(correlation$estimate),
    spearman_p_value = correlation$p.value,
    slope_per_unit_prevalence_change = unname(row[["Value"]]),
    standard_error = unname(row[["Std.Error"]]),
    p_value = unname(row[["p-value"]]),
    stringsAsFactors = FALSE
  )
}
ever_detected <- rowSums(detected) > 0
mag_associations <- do.call(rbind, lapply(
  c("log10_estimated_genome_size", "supported", "expected", "deviation"),
  function(response) rbind(
    mag_association(response, ever_detected, "detected in at least one sample"),
    mag_association(response, ever_detected & high_quality,
                    "detected and at least 90% complete")
  )
))

completeness_check <- function(subset, label) {
  test <- suppressWarnings(stats::cor.test(
    mags$deviation[subset], mags$completeness[subset], method = "spearman"
  ))
  data.frame(
    mags = label, genomes = sum(subset),
    median_deviation = stats::median(mags$deviation[subset]),
    spearman_rho_deviation_completeness = unname(test$estimate),
    p_value = test$p.value, stringsAsFactors = FALSE
  )
}
completeness_table <- rbind(
  completeness_check(rep(TRUE, nrow(mags)), "all MAGs"),
  completeness_check(high_quality, "at least 90% complete"),
  completeness_check(!high_quality, "below 90% complete")
)

# How far the re-evaluation moved the audited calls on the GIFTs both share.
audited <- primary_read$calls[, genome_ids, drop = FALSE] %in% TRUE
dim(audited) <- dim(primary_read$calls)
rownames(audited) <- rownames(primary_read$calls)
shared_gifts <- intersect(rownames(audited), rownames(mag_calls))
changed_calls <- sum(audited[shared_gifts, ] != (mag_calls[shared_gifts, ] > 0))

# ----------------------------------------------------------------------- tables

round_columns <- function(table, digits = 4) {
  numeric <- vapply(table, is.double, logical(1))
  p_like <- grepl("p_value|q_value", names(table))
  table[numeric & !p_like] <- lapply(table[numeric & !p_like], round, digits)
  table[numeric & p_like] <- lapply(table[numeric & p_like], signif, 4)
  table
}

mag_table <- mags[order(mags$deviation), setdiff(
  names(mags), c("family_key", "log10_estimated_genome_size")
)]
write_tsv(round_columns(mag_table, 3),
          file.path(output_dir, "r10-size-expectation-mags.tsv"))
write_tsv(
  round_columns(decomposition[order(
    decomposition$variant, decomposition$detection, decomposition$frame_id,
    decomposition$contrast
  ), ]),
  file.path(output_dir, "r10-size-expectation-age-contrasts.tsv")
)
write_tsv(
  round_columns(contrasts[contrasts$frame_id == "genome_size", ]),
  file.path(output_dir, "r10-size-expectation-genome-size-contrasts.tsv")
)
write_tsv(
  round_columns(taxon_table[order(
    taxon_table$frame_id, taxon_table$part, match(taxon_table$rank, TAXON_RANKS),
    taxon_table$component, taxon_table$contrast
  ), c(
    "frame_id", "reference_frame", "member_count", "part", "rank", "taxa",
    "component", "contrast", "estimate", "standard_error", "confidence_low",
    "confidence_high", "p_value", "q_value", "total_estimate", "share_of_total",
    "model_status"
  )]),
  file.path(output_dir, "r10-size-expectation-taxon-partition.tsv")
)
write_tsv(round_columns(mag_associations),
          file.path(output_dir, "r10-size-expectation-mag-associations.tsv"))
write_tsv(round_columns(completeness_table),
          file.path(output_dir, "r10-size-expectation-completeness.tsv"))

frame_models <- do.call(rbind, lapply(names(frames), function(id) {
  data.frame(
    frame_id = id, reference_frame = frame_labels[[id]],
    member_count = frame_sizes[[id]],
    gtdb_deviance_explained = summary(models[[id]]$fit)$dev.expl,
    gtdb_mean_supported = mean(colSums(gtdb_calls[frames[[id]]$gift_id, , drop = FALSE])),
    mag_mean_supported = mean(observed[id, ]),
    mag_mean_expected = mean(expected$estimated[id, ]),
    stringsAsFactors = FALSE
  )
}))
write_tsv(round_columns(frame_models),
          file.path(output_dir, "r10-size-expectation-frame-models.tsv"))

audit <- data.frame(
  item = c(
    "MAGs", "samples", "database version", "gifter SQLite sha256",
    "annotation sha256", "GTDB genomes behind the expectation",
    "catalogue GIFTs", "supported genome-GIFT pairs",
    "GIFTs shared with the audited R10 catalogue",
    "calls on shared GIFTs that differ from the audited R10 calls",
    "expectation", "primary genome size", "MAGs at least 90% complete",
    "MAGs read at the GTDB size boundary", "GTDB size range (Mb)",
    "estimated MAG size range (Mb)", "primary detection", "age model",
    "taxon partition", "multiple testing", "analysis script sha256"
  ),
  value = c(
    nrow(mags), nrow(metadata), gtdb_audit[["database version"]], database_sha,
    annotation_sha, nrow(gtdb_genomes), nrow(mag_calls), sum(mag_calls),
    length(shared_gifts), changed_calls,
    "per reference frame, mgcv quasi-binomial GAM, logit link, s(log10 genome size, k = 6), REML, fitted to the GTDB panel",
    "MAG length divided by reported completeness",
    sum(high_quality), sum(mags$outside_gtdb_size_range),
    paste(round(10^size_range / 1e6, 3), collapse = " to "),
    paste(round(range(mags$estimated_genome_size) / 1e6, 3), collapse = " to "),
    primary_detection,
    "nlme::lme, value ~ sampling_time + trial + treatment + breed + sex, random intercept for pen, REML",
    "each MAG replaced by the unweighted mean of its taxon over the 822-MAG catalogue",
    "Benjamini-Hochberg within each contrast table",
    sha256(file.path(root, "31-r10-size-expectation.R"))
  ),
  stringsAsFactors = FALSE
)
write_tsv(audit, file.path(output_dir, "r10-size-expectation-audit.tsv"))

# ------------------------------------------------------------------- Figure S19

base_theme <- theme_minimal(base_size = 7) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(size = 8, face = "bold", hjust = 0),
    legend.position = "bottom", legend.text = element_text(size = 6),
    legend.title = element_text(size = 6.5),
    legend.key.height = grid::unit(2.5, "mm")
  )
part_colours <- c(
  "observed" = "#252522", "expected from genome size" = "#c8553d",
  "deviation from the expectation" = "#2f6f9f"
)
part_names <- c(
  observed = "observed", size_expected = "expected from genome size",
  deviation = "deviation from the expectation"
)

curve <- data.frame(log10_genome_size = seq(
  size_range[[1L]], size_range[[2L]], length.out = 200L
))
curve$expected <- models$all_gifts$n * as.numeric(
  stats::predict(models$all_gifts$fit, curve, type = "response")
)
curve$genome_size_mb <- 10^curve$log10_genome_size / 1e6
mag_plot <- mags[ever_detected, ]
change_limit <- max(abs(mag_plot$prevalence_change))
panel_mags <- ggplot(mag_plot, aes(
  x = estimated_genome_size / 1e6, y = supported, colour = prevalence_change
)) +
  geom_point(size = 0.6) +
  geom_line(
    data = curve, aes(x = genome_size_mb, y = expected), inherit.aes = FALSE,
    colour = "#252522", linewidth = 0.45
  ) +
  scale_x_log10(breaks = c(0.5, 1, 2, 4, 8)) +
  coord_cartesian(xlim = range(mag_plot$estimated_genome_size / 1e6)) +
  scale_colour_gradient2(
    low = "#2f6f9f", mid = "#cfcec8", high = "#c8553d", midpoint = 0,
    limits = c(-change_limit, change_limit),
    name = "change in prevalence, day 7 to day 35"
  ) +
  labs(
    title = "a  MAGs against the GTDB size expectation",
    x = "estimated genome size (Mb, log scale)", y = "supported GIFTs"
  ) +
  base_theme

all_gifts <- contrasts[
  contrasts$variant == "primary" & contrasts$frame_id == "all_gifts",
]
all_gifts$part <- factor(part_names[all_gifts$part], levels = part_names)
all_gifts$day <- ifelse(all_gifts$contrast == "day_21_minus_day_7", "day 21", "day 35")
all_gifts$detection_label <- factor(
  format(all_gifts$detection, scientific = FALSE, drop0trailing = TRUE),
  levels = format(thresholds, scientific = FALSE, drop0trailing = TRUE)
)
panel_parts <- ggplot(all_gifts, aes(
  x = detection_label, y = estimate, colour = part, group = part
)) +
  geom_hline(yintercept = 0, colour = "#252522", linewidth = 0.3) +
  geom_linerange(
    aes(ymin = confidence_low, ymax = confidence_high),
    position = position_dodge(width = 0.5), linewidth = 0.35
  ) +
  geom_point(position = position_dodge(width = 0.5), size = 0.9) +
  facet_wrap(~day) +
  scale_colour_manual(values = part_colours, name = NULL) +
  labs(
    title = "b  Age contrast in mean per-MAG richness, all GIFTs",
    x = "detection threshold (relative abundance)",
    y = "adjusted difference from day 7 (GIFTs)"
  ) +
  base_theme +
  theme(legend.position = "none")

frame_plot <- decomposition[
  decomposition$variant == "primary" &
    decomposition$detection == primary_detection &
    decomposition$contrast == "day_35_minus_day_7" &
    !decomposition$frame_id %in% c("all_gifts", "all_metabolic"),
]
frame_plot$focal <- frame_plot$frame_id %in% FOCAL_FRAMES
# Frames whose contrast is a small fraction of one GIFT crowd the origin; they
# are drawn unnamed and listed in r10-size-expectation-age-contrasts.tsv.
frame_plot$name <- ifelse(
  abs(frame_plot$observed) >= LABELLED_FRAME_CONTRAST,
  frame_plot$reference_frame, ""
)
frame_limit <- range(c(frame_plot$observed, frame_plot$size_expected, 0))
panel_frames <- ggplot(frame_plot, aes(x = size_expected, y = observed)) +
  geom_abline(slope = 1, intercept = 0, colour = "#8a8983", linewidth = 0.3,
              linetype = "dashed") +
  geom_hline(yintercept = 0, colour = "#252522", linewidth = 0.2) +
  geom_vline(xintercept = 0, colour = "#252522", linewidth = 0.2) +
  geom_point(aes(colour = focal), size = 1) +
  ggrepel::geom_text_repel(
    aes(label = name), size = 1.7, colour = "#252522",
    min.segment.length = 0, segment.size = 0.15, box.padding = 0.2,
    max.overlaps = Inf, seed = 1L
  ) +
  scale_colour_manual(
    values = c("TRUE" = "#c8553d", "FALSE" = "#8a8983"), guide = "none"
  ) +
  coord_equal(xlim = frame_limit, ylim = frame_limit) +
  labs(
    title = "c  Day 35 contrast per reference frame",
    x = "expected from genome size (GIFTs)", y = "observed (GIFTs)"
  ) +
  base_theme

taxon_plot <- taxon_table[
  taxon_table$frame_id == "all_gifts" &
    taxon_table$contrast == "day_35_minus_day_7" &
    taxon_table$component == "between_taxa",
]
taxon_plot$part <- factor(part_names[taxon_plot$part], levels = part_names)
taxon_plot$rank_label <- factor(
  paste0(taxon_plot$rank, " (", taxon_plot$taxa, ")"),
  levels = unique(paste0(taxon_plot$rank, " (", taxon_plot$taxa, ")")[
    order(match(taxon_plot$rank, TAXON_RANKS))
  ])
)
panel_taxa <- ggplot(taxon_plot, aes(
  x = rank_label, y = share_of_total, colour = part, group = part
)) +
  geom_hline(yintercept = c(0, 1), colour = "#252522", linewidth = 0.2) +
  geom_line(linewidth = 0.35) +
  geom_point(size = 0.9) +
  scale_colour_manual(values = part_colours, name = NULL) +
  scale_y_continuous(labels = function(x) paste0(round(100 * x), "%")) +
  labs(
    title = "d  Day 35 contrast carried by turnover between taxa",
    x = "taxonomic rank (taxa in the catalogue)",
    y = "share of the contrast"
  ) +
  base_theme

figure <- (panel_mags + panel_parts) / (panel_frames + panel_taxa) +
  plot_annotation(
    caption = paste0(
      "822 chicken caecal MAGs evaluated against database ",
      gtdb_audit[["database version"]], "; expectation fitted to the ",
      nrow(gtdb_genomes), "-genome GTDB panel. Encoded capability only."
    ),
    theme = theme(plot.caption = element_text(size = 5.5, hjust = 0))
  )
for (extension in c("pdf", "png")) {
  ggsave(
    file.path(figure_dir, paste0("figure-s19-r10-size-expectation.", extension)),
    figure, width = 180, height = 170, units = "mm", dpi = 300
  )
}

cat("Wrote r10-size-expectation-* tables and Figure S19.\n")
