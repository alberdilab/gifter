# R10 follow-up: temporal change and stability across curated reference frames.
#
# The unit of analysis here is a reference frame, never a new composite GIFT.
# Each frame is resolved from database metadata, every Boolean call remains the
# genome-level call made by 21-r10-chicken.R, and sample detection only selects
# which genomes are read. The analysis separates the community union from the
# mean repertoire per detected genome. Neither quantity is activity or flux.
#
# Run from the repository root after 21-r10-chicken.R:
#   Rscript manuscript/analysis/24-r10-reference-frame-time.R
# If the working database has advanced since R10 was audited, point R10_DB_PATH
# at the archived, hash-matching SQLite artifact instead.

suppressWarnings(suppressPackageStartupMessages({
  library(ggplot2)
  library(patchwork)
}))

devtools::load_all(".", quiet = TRUE)

root <- "manuscript/analysis"
cache_dir <- Sys.getenv(
  "R10_CACHE_DIR", file.path(root, ".cache", "r10-chicken")
)
output_dir <- Sys.getenv("R10_OUTPUT_DIR", file.path(root, "output"))
figure_dir <- Sys.getenv("R10_FIGURE_DIR", "manuscript/figures")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

read_tsv <- function(path) {
  utils::read.delim(path, check.names = FALSE, stringsAsFactors = FALSE)
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

audit_path <- file.path(output_dir, "r10-input-audit.tsv")
if (!file.exists(audit_path)) {
  stop("Run 21-r10-chicken.R before this follow-up analysis", call. = FALSE)
}
audit <- read_tsv(audit_path)
audit_value <- stats::setNames(audit$value, audit$item)
database_path <- Sys.getenv("R10_DB_PATH", "inst/extdata/gifter.sqlite")
database_sha <- sha256(database_path)
if (!identical(database_sha, unname(audit_value[["gifter_sqlite_sha256"]]))) {
  stop("The gifter database no longer matches the R10 input audit", call. = FALSE)
}
database <- gifter_db_connect(database_path)
on.exit(gifter_db_disconnect(database), add = TRUE)

analysis_key <- paste(
  audit_value[["annotation_sha256"]], audit_value[["gifter_sqlite_sha256"]],
  audit_value[["analysis_cache_version"]], sep = "-"
)
trait_cache <- file.path(
  cache_dir, paste0("dataset-traits-", analysis_key, ".rds")
)
strict_cache <- file.path(
  cache_dir, paste0("dataset-traits-high-confidence-", analysis_key, ".rds")
)
required <- c(trait_cache, strict_cache)
missing <- required[!file.exists(required)]
if (length(missing)) {
  stop("Missing R10 cache inputs:\n  ", paste(missing, collapse = "\n  "), call. = FALSE)
}

trait_reads <- readRDS(trait_cache)
strict_traits <- readRDS(strict_cache)
thresholds <- vapply(trait_reads, function(x) x$detection, numeric(1))
expected_thresholds <- c(0, 1e-5, 1e-4, 1e-3)
if (!identical(thresholds, expected_thresholds)) {
  stop("The cached detection thresholds do not match the R10 contract", call. = FALSE)
}
primary_detection <- as.numeric(audit_value[["primary_detection"]])
if (!identical(primary_detection, 1e-3)) {
  stop("The audited primary detection threshold is no longer 0.001", call. = FALSE)
}

# Use every named frame in the compiled database. A frame's membership is
# metadata, not a GIFT list written into this script.
frame_catalogue <- as.data.frame(list_reference_frames(db = database))
frames <- lapply(
  frame_catalogue$frame_id,
  function(id) reference_frame(preset = id, db = database)
)
names(frames) <- frame_catalogue$frame_id
stopifnot(
  length(frames) == nrow(frame_catalogue),
  all(vapply(frames, inherits, logical(1), "gifter_frame")),
  identical(
    unname(vapply(frames, function(frame) length(frame$gift_id), integer(1))),
    as.integer(frame_catalogue$member_count)
  )
)

reshape_like <- function(values, template) {
  dim(values) <- dim(template)
  dimnames(values) <- dimnames(template)
  values
}

metric_rows <- function(reading, frame_id, frame_row, frame) {
  members <- intersect(rownames(reading$calls), frame$gift_id)
  state <- reading$calls[members, , drop = FALSE]
  supports <- reshape_like(state %in% TRUE, state)
  assessed <- reshape_like(!is.na(state), state)
  detected <- reading$detected
  support_values <- reshape_like(as.double(supports), supports)
  assessed_values <- reshape_like(as.double(assessed), assessed)
  detection_values <- reshape_like(as.double(detected), detected)

  providers <- support_values %*% detection_values
  assessors <- assessed_values %*% detection_values
  detected_count <- colSums(detected)
  assessable <- colSums(assessors > 0)
  richness <- colSums(providers > 0)
  gift_richness <- colSums(supports)
  detected_richness <- as.vector(gift_richness %*% detection_values)

  metadata <- as.data.frame(reading$metadata)
  metadata <- metadata[match(colnames(detected), metadata$sample_id), , drop = FALSE]
  stopifnot(identical(metadata$sample_id, colnames(detected)))

  make_rows <- function(metric_id, value, unit, equivalence_margin) {
    data.frame(
      sample_id = metadata$sample_id,
      detection = reading$detection,
      trial = metadata$trial,
      pen = metadata$pen,
      treatment = metadata$treatment,
      breed = metadata$breed,
      sex = metadata$sex,
      sampling_time = metadata$sampling_time,
      frame_id = frame_id,
      reference_frame = frame_row$label,
      bounded = frame_row$bounded,
      member_count = frame_row$member_count,
      metric_id = metric_id,
      value = value,
      unit = unit,
      equivalence_margin = equivalence_margin,
      stringsAsFactors = FALSE
    )
  }

  rows <- list(
    make_rows("community_richness", richness, "count", 1),
    make_rows(
      "mean_genome_richness", detected_richness / detected_count, "count", 1
    )
  )
  if (isTRUE(frame$bounded)) {
    coverage <- rep(NA_real_, length(assessable))
    readable <- assessable > 0L
    coverage[readable] <- richness[readable] / assessable[readable]
    rows[[length(rows) + 1L]] <- make_rows(
      "community_coverage", coverage, "proportion", 0.05
    )
  }
  do.call(rbind, rows)
}

read_frames <- function(reading) {
  parts <- lapply(seq_along(frames), function(index) {
    metric_rows(
      reading,
      frame_catalogue$frame_id[[index]],
      frame_catalogue[index, , drop = FALSE],
      frames[[index]]
    )
  })
  result <- do.call(rbind, parts)
  rownames(result) <- NULL
  result
}

weighted_metric_rows <- function(reading, frame_id, frame_row, frame) {
  members <- intersect(rownames(reading$calls), frame$gift_id)
  state <- reading$calls[members, , drop = FALSE]
  supports <- reshape_like(state %in% TRUE, state)
  gift_richness <- colSums(supports)

  # Close abundance within the detected community exactly as dataset_traits()
  # does before reporting per-GIFT abundance_coverage. The frame value is the
  # sum of those per-GIFT shares, equivalently the abundance-weighted expected
  # GIFT richness of a detected carrier genome.
  weights <- reading$abundance
  weights[!reading$detected] <- 0
  weights <- sweep(weights, 2L, colSums(weights), "/")
  weighted_richness <- as.vector(gift_richness %*% weights)

  metadata <- as.data.frame(reading$metadata)
  metadata <- metadata[
    match(colnames(reading$detected), metadata$sample_id), , drop = FALSE
  ]
  stopifnot(identical(metadata$sample_id, colnames(reading$detected)))
  data.frame(
    sample_id = metadata$sample_id,
    detection = reading$detection,
    trial = metadata$trial,
    pen = metadata$pen,
    treatment = metadata$treatment,
    breed = metadata$breed,
    sex = metadata$sex,
    sampling_time = metadata$sampling_time,
    frame_id = frame_id,
    reference_frame = frame_row$label,
    bounded = frame_row$bounded,
    member_count = frame_row$member_count,
    metric_id = "abundance_weighted_genome_richness",
    value = weighted_richness,
    unit = "count",
    equivalence_margin = 1,
    stringsAsFactors = FALSE
  )
}

read_weighted_frames <- function(reading) {
  parts <- lapply(seq_along(frames), function(index) {
    weighted_metric_rows(
      reading,
      frame_catalogue$frame_id[[index]],
      frame_catalogue[index, , drop = FALSE],
      frames[[index]]
    )
  })
  result <- do.call(rbind, parts)
  rownames(result) <- NULL
  result
}

# The cached objects contain the exact calls, assessability states, detection
# matrices and sample metadata used by dataset_traits(). Reconstructing only
# the three required frame metrics avoids materialising millions of unrelated
# per-genome rows. For every frame already read by 21-r10-chicken.R, assert that
# the reconstruction equals the public API result exactly.
validate_cached_frames <- function(reading, derived) {
  cached_labels <- vapply(
    reading$frames, function(frame) frame$label, character(1)
  )
  comparable_labels <- intersect(cached_labels, unique(derived$reference_frame))
  existing <- as.data.frame(reading$metrics)
  existing <- existing[
    existing$target_type == "community" &
      existing$reference_frame %in% comparable_labels &
      existing$metric_id %in% c(
        "community_richness", "mean_genome_richness", "community_coverage"
      ),
    c("sample_id", "reference_frame", "metric_id", "value"),
    drop = FALSE
  ]
  expected <- derived[
    derived$reference_frame %in% comparable_labels & !is.na(derived$value),
    c("sample_id", "reference_frame", "metric_id", "value"),
    drop = FALSE
  ]
  existing$key <- paste(existing$sample_id, existing$reference_frame, existing$metric_id)
  expected$key <- paste(expected$sample_id, expected$reference_frame, expected$metric_id)
  if (!setequal(existing$key, expected$key)) {
    stop(
      "Frame reconstruction no longer matches cached dataset_traits() rows; ",
      "cached only: ",
      paste(head(setdiff(existing$key, expected$key), 3L), collapse = " | "),
      "; reconstructed only: ",
      paste(head(setdiff(expected$key, existing$key), 3L), collapse = " | "),
      call. = FALSE
    )
  }
  existing <- existing[match(expected$key, existing$key), ]
  if (!isTRUE(all.equal(existing$value, expected$value, tolerance = 1e-12))) {
    stop("Frame reconstruction no longer matches cached dataset_traits() values", call. = FALSE)
  }
  invisible(TRUE)
}

validate_cached_weighted_frames <- function(reading, derived) {
  cached_labels <- vapply(
    reading$frames, function(frame) frame$label, character(1)
  )
  comparable_labels <- intersect(cached_labels, unique(derived$reference_frame))
  existing <- as.data.frame(reading$metrics)
  existing <- existing[
    existing$target_type == "gift" &
      existing$metric_id == "abundance_coverage" &
      existing$reference_frame %in% comparable_labels,
    c("sample_id", "reference_frame", "value"), drop = FALSE
  ]
  existing <- stats::aggregate(
    value ~ sample_id + reference_frame, existing, sum
  )
  expected <- derived[
    derived$reference_frame %in% comparable_labels,
    c("sample_id", "reference_frame", "value"), drop = FALSE
  ]
  existing$key <- paste(existing$sample_id, existing$reference_frame)
  expected$key <- paste(expected$sample_id, expected$reference_frame)
  observed <- existing$value[match(expected$key, existing$key)]
  observed[is.na(observed)] <- 0
  if (!isTRUE(all.equal(observed, expected$value, tolerance = 1e-12))) {
    stop(
      "Abundance-weighted frame reconstruction no longer equals summed ",
      "dataset_traits() abundance_coverage",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

cat("Reading all curated frames across detection thresholds...\n")
sample_metrics <- do.call(rbind, lapply(trait_reads, read_frames))
rownames(sample_metrics) <- NULL
strict_metrics <- read_frames(strict_traits)
weighted_metrics <- do.call(rbind, lapply(trait_reads, read_weighted_frames))
rownames(weighted_metrics) <- NULL
strict_weighted_metrics <- read_weighted_frames(strict_traits)
for (index in seq_along(trait_reads)) {
  validate_cached_frames(
    trait_reads[[index]],
    sample_metrics[sample_metrics$detection == thresholds[[index]], , drop = FALSE]
  )
  validate_cached_weighted_frames(
    trait_reads[[index]],
    weighted_metrics[
      weighted_metrics$detection == thresholds[[index]], , drop = FALSE
    ]
  )
}
validate_cached_frames(strict_traits, strict_metrics)
validate_cached_weighted_frames(strict_traits, strict_weighted_metrics)

sample_metrics <- sample_metrics[order(
  sample_metrics$detection, sample_metrics$frame_id,
  sample_metrics$metric_id, sample_metrics$sample_id
), ]
write_xz_tsv(
  sample_metrics,
  file.path(output_dir, "r10-frame-time-sample-metrics.tsv.xz")
)
weighted_metrics <- weighted_metrics[order(
  weighted_metrics$detection, weighted_metrics$frame_id,
  weighted_metrics$sample_id
), ]
write_xz_tsv(
  weighted_metrics,
  file.path(
    output_dir, "r10-frame-time-abundance-weighted-sample-metrics.tsv.xz"
  )
)

membership <- do.call(rbind, lapply(seq_along(frames), function(index) {
  data.frame(
    frame_id = frame_catalogue$frame_id[[index]],
    reference_frame = frame_catalogue$label[[index]],
    bounded = frame_catalogue$bounded[[index]],
    member_count = frame_catalogue$member_count[[index]],
    gift_id = frames[[index]]$gift_id,
    stringsAsFactors = FALSE
  )
}))
gifts <- as.data.frame(list_gifts(db = database))
membership$gift_name <- gifts$name[match(membership$gift_id, gifts$gift_id)]
membership$gift_type <- gifts$gift_type[match(membership$gift_id, gifts$gift_id)]
membership$mode <- gifts$mode[match(membership$gift_id, gifts$gift_id)]
membership <- membership[order(membership$frame_id, membership$gift_id), ]
rownames(membership) <- NULL
write_tsv(membership, file.path(output_dir, "r10-frame-membership.tsv"))

summarise_values <- function(table, keys) {
  groups <- interaction(table[keys], drop = TRUE, lex.order = TRUE)
  parts <- lapply(split(seq_len(nrow(table)), groups), function(index) {
    row <- table[index[[1L]], keys, drop = FALSE]
    values <- table$value[index]
    values <- values[is.finite(values)]
    row$n <- length(values)
    row$mean <- if (length(values)) mean(values) else NA_real_
    row$sd <- if (length(values) > 1L) stats::sd(values) else NA_real_
    row$median <- if (length(values)) stats::median(values) else NA_real_
    row$q25 <- if (length(values)) {
      as.numeric(stats::quantile(values, 0.25))
    } else {
      NA_real_
    }
    row$q75 <- if (length(values)) {
      as.numeric(stats::quantile(values, 0.75))
    } else {
      NA_real_
    }
    row
  })
  result <- do.call(rbind, parts)
  rownames(result) <- NULL
  result
}

age_summary <- summarise_values(
  sample_metrics,
  c(
    "detection", "sampling_time", "trial", "frame_id", "reference_frame",
    "bounded", "member_count", "metric_id", "unit", "equivalence_margin"
  )
)
write_tsv(age_summary, file.path(output_dir, "r10-frame-time-age-summary.tsv"))

fit_contrasts <- function(table) {
  margin <- unique(table$equivalence_margin)
  stopifnot(length(margin) == 1L, is.finite(margin), margin > 0)
  observed <- table$value[is.finite(table$value)]
  tolerance <- sqrt(.Machine$double.eps) * max(1, abs(observed))
  if (length(observed) < 2L || diff(range(observed)) <= max(tolerance)) {
    return(data.frame(
      contrast = c("day_21_minus_day_7", "day_35_minus_day_7"),
      estimate = 0, standard_error = 0, degrees_freedom = NA_real_,
      confidence_low = 0, confidence_high = 0,
      p_value = NA_real_, equivalence_p_value = NA_real_,
      minimum_effect_p_value = NA_real_,
      model_status = "constant_metric", stringsAsFactors = FALSE
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
      confidence_low = NA_real_, confidence_high = NA_real_,
      p_value = NA_real_, equivalence_p_value = NA_real_,
      minimum_effect_p_value = NA_real_,
      model_status = conditionMessage(fit), stringsAsFactors = FALSE
    ))
  }
  coefficients <- summary(fit)$tTable
  terms <- c("sampling_time21", "sampling_time35")
  estimate <- unname(coefficients[terms, "Value"])
  standard_error <- unname(coefficients[terms, "Std.Error"])
  degrees_freedom <- unname(coefficients[terms, "DF"])
  critical <- stats::qt(0.975, degrees_freedom)
  lower_test <- (estimate + margin) / standard_error
  upper_test <- (estimate - margin) / standard_error
  equivalence_p <- pmax(
    stats::pt(lower_test, degrees_freedom, lower.tail = FALSE),
    stats::pt(upper_test, degrees_freedom, lower.tail = TRUE)
  )
  minimum_effect_p <- ifelse(
    estimate < 0,
    stats::pt(lower_test, degrees_freedom, lower.tail = TRUE),
    stats::pt(upper_test, degrees_freedom, lower.tail = FALSE)
  )
  data.frame(
    contrast = c("day_21_minus_day_7", "day_35_minus_day_7"),
    estimate = estimate,
    standard_error = standard_error,
    degrees_freedom = degrees_freedom,
    confidence_low = estimate - critical * standard_error,
    confidence_high = estimate + critical * standard_error,
    p_value = unname(coefficients[terms, "p-value"]),
    equivalence_p_value = equivalence_p,
    minimum_effect_p_value = minimum_effect_p,
    model_status = "ok",
    stringsAsFactors = FALSE
  )
}

fit_grouped <- function(table, confidence_floor) {
  keys <- c(
    "detection", "frame_id", "reference_frame", "bounded", "member_count",
    "metric_id", "unit", "equivalence_margin"
  )
  groups <- interaction(table[keys], drop = TRUE, lex.order = TRUE)
  parts <- lapply(split(seq_len(nrow(table)), groups), function(index) {
    key <- table[index[[1L]], keys, drop = FALSE]
    rownames(key) <- NULL
    cbind(key, fit_contrasts(table[index, , drop = FALSE]))
  })
  result <- do.call(rbind, parts)
  rownames(result) <- NULL
  result$confidence_floor <- confidence_floor
  result$q_value <- stats::p.adjust(result$p_value, method = "BH")
  result$equivalence_q_value <- stats::p.adjust(
    result$equivalence_p_value, method = "BH"
  )
  result$minimum_effect_q_value <- stats::p.adjust(
    result$minimum_effect_p_value, method = "BH"
  )
  result
}

fit_age_means <- function(table) {
  observed <- table$value[is.finite(table$value)]
  tolerance <- sqrt(.Machine$double.eps) * max(1, abs(observed))
  days <- c(7, 21, 35)
  if (length(observed) < 2L || diff(range(observed)) <= max(tolerance)) {
    value <- if (length(observed)) observed[[1L]] else NA_real_
    return(data.frame(
      sampling_time = days, adjusted_mean = value, standard_error = 0,
      confidence_low = value, confidence_high = value,
      model_status = "constant_metric", stringsAsFactors = FALSE
    ))
  }
  table$sampling_time <- factor(table$sampling_time, levels = days)
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
      sampling_time = days, adjusted_mean = NA_real_, standard_error = NA_real_,
      confidence_low = NA_real_, confidence_high = NA_real_,
      model_status = conditionMessage(fit), stringsAsFactors = FALSE
    ))
  }

  # Standardise each age over the observed covariate distribution. Because the
  # model is additive, differences between these means equal the fitted age
  # contrasts exactly while the intercept remains an interpretable population
  # average rather than the value for an arbitrary reference bird.
  coefficients <- nlme::fixed.effects(fit)
  variance <- fit$varFix
  design <- do.call(rbind, lapply(days, function(day) {
    newdata <- table
    newdata$sampling_time <- factor(day, levels = days)
    matrix <- stats::model.matrix(
      ~ sampling_time + trial + treatment + breed + sex, data = newdata
    )
    colMeans(matrix[, names(coefficients), drop = FALSE])
  }))
  estimate <- as.vector(design %*% coefficients)
  standard_error <- sqrt(diag(design %*% variance %*% t(design)))
  degrees_freedom <- min(summary(fit)$tTable[, "DF"], na.rm = TRUE)
  critical <- stats::qt(0.975, degrees_freedom)
  data.frame(
    sampling_time = days,
    adjusted_mean = estimate,
    standard_error = standard_error,
    confidence_low = estimate - critical * standard_error,
    confidence_high = estimate + critical * standard_error,
    model_status = "ok",
    stringsAsFactors = FALSE
  )
}

fit_age_means_grouped <- function(table) {
  keys <- c(
    "detection", "frame_id", "reference_frame", "bounded", "member_count",
    "metric_id", "unit", "equivalence_margin"
  )
  groups <- interaction(table[keys], drop = TRUE, lex.order = TRUE)
  parts <- lapply(split(seq_len(nrow(table)), groups), function(index) {
    key <- table[index[[1L]], keys, drop = FALSE]
    rownames(key) <- NULL
    cbind(key, fit_age_means(table[index, , drop = FALSE]))
  })
  result <- do.call(rbind, parts)
  rownames(result) <- NULL
  result
}

cat("Fitting frame-level age contrasts...\n")
contrasts <- fit_grouped(sample_metrics, "all accepted")
strict_contrasts <- fit_grouped(strict_metrics, "ambiguous withheld")
contrasts <- contrasts[order(
  contrasts$detection, contrasts$frame_id, contrasts$metric_id,
  contrasts$contrast
), ]
strict_contrasts <- strict_contrasts[order(
  strict_contrasts$frame_id, strict_contrasts$metric_id,
  strict_contrasts$contrast
), ]
write_tsv(contrasts, file.path(output_dir, "r10-frame-time-contrasts.tsv"))
write_tsv(
  strict_contrasts,
  file.path(output_dir, "r10-frame-time-confidence-sensitivity.tsv")
)

cat("Fitting abundance-weighted frame-level age contrasts...\n")
weighted_contrasts <- fit_grouped(weighted_metrics, "all accepted")
strict_weighted_contrasts <- fit_grouped(
  strict_weighted_metrics, "ambiguous withheld"
)
weighted_contrasts <- weighted_contrasts[order(
  weighted_contrasts$detection, weighted_contrasts$frame_id,
  weighted_contrasts$contrast
), ]
strict_weighted_contrasts <- strict_weighted_contrasts[order(
  strict_weighted_contrasts$frame_id, strict_weighted_contrasts$contrast
), ]
write_tsv(
  weighted_contrasts,
  file.path(output_dir, "r10-frame-time-abundance-weighted-contrasts.tsv")
)
write_tsv(
  strict_weighted_contrasts,
  file.path(
    output_dir,
    "r10-frame-time-abundance-weighted-confidence-sensitivity.tsv"
  )
)

weighted_adjusted_means <- fit_age_means_grouped(
  weighted_metrics[
    weighted_metrics$detection == primary_detection, , drop = FALSE
  ]
)
weighted_adjusted_means <- weighted_adjusted_means[order(
  weighted_adjusted_means$frame_id, weighted_adjusted_means$sampling_time
), ]
write_tsv(
  weighted_adjusted_means,
  file.path(output_dir, "r10-frame-time-abundance-weighted-adjusted-means.tsv")
)

cat("Estimating adjusted three-day trajectories...\n")
adjusted_means <- fit_age_means_grouped(
  sample_metrics[sample_metrics$detection == primary_detection, , drop = FALSE]
)
adjusted_means <- adjusted_means[order(
  adjusted_means$frame_id, adjusted_means$metric_id,
  adjusted_means$sampling_time
), ]

# The plotted trajectories and contrast heatmap are two views of the same
# model. Assert that every plotted day-21/day-35 difference reproduces the
# corresponding fitted contrast before writing either figure.
trajectory_groups <- split(
  seq_len(nrow(adjusted_means)),
  interaction(
    adjusted_means$frame_id, adjusted_means$metric_id,
    drop = TRUE, lex.order = TRUE
  )
)
trajectory_differences <- do.call(rbind, lapply(trajectory_groups, function(index) {
  rows <- adjusted_means[index, , drop = FALSE]
  rows <- rows[match(c(7, 21, 35), rows$sampling_time), ]
  data.frame(
    frame_id = rows$frame_id[[1L]], metric_id = rows$metric_id[[1L]],
    contrast = c("day_21_minus_day_7", "day_35_minus_day_7"),
    estimate = rows$adjusted_mean[c(2L, 3L)] - rows$adjusted_mean[[1L]],
    stringsAsFactors = FALSE
  )
}))
primary_for_validation <- contrasts[
  contrasts$detection == primary_detection,
  c("frame_id", "metric_id", "contrast", "estimate"), drop = FALSE
]
trajectory_differences$key <- paste(
  trajectory_differences$frame_id, trajectory_differences$metric_id,
  trajectory_differences$contrast
)
primary_for_validation$key <- paste(
  primary_for_validation$frame_id, primary_for_validation$metric_id,
  primary_for_validation$contrast
)
primary_for_validation <- primary_for_validation[
  match(trajectory_differences$key, primary_for_validation$key),
]
if (!isTRUE(all.equal(
  trajectory_differences$estimate, primary_for_validation$estimate,
  tolerance = 1e-10
))) {
  stop("Adjusted trajectories no longer reproduce the fitted age contrasts", call. = FALSE)
}
write_tsv(
  adjusted_means,
  file.path(output_dir, "r10-frame-time-adjusted-means.tsv")
)

classify_contrast <- function(primary_row, sensitivity_table = contrasts,
                              strict_table = strict_contrasts) {
  sensitivity <- sensitivity_table[
    sensitivity_table$frame_id == primary_row$frame_id &
      sensitivity_table$metric_id == primary_row$metric_id &
      sensitivity_table$contrast == primary_row$contrast,
    , drop = FALSE
  ]
  strict_row <- strict_table[
    strict_table$frame_id == primary_row$frame_id &
      strict_table$metric_id == primary_row$metric_id &
      strict_table$contrast == primary_row$contrast,
    , drop = FALSE
  ]
  all_constant <- all(sensitivity$model_status == "constant_metric")
  finite <- is.finite(sensitivity$estimate)
  direction_robust <- if (primary_row$estimate > 0) {
    all(finite & sensitivity$estimate > 0)
  } else if (primary_row$estimate < 0) {
    all(finite & sensitivity$estimate < 0)
  } else {
    FALSE
  }
  significant <- !is.na(sensitivity$q_value) & sensitivity$q_value < 0.05
  minimum_effect <- !is.na(sensitivity$minimum_effect_q_value) &
    sensitivity$minimum_effect_q_value < 0.05
  equivalent <- sensitivity$model_status == "constant_metric" |
    (!is.na(sensitivity$equivalence_q_value) &
       sensitivity$equivalence_q_value < 0.05)
  primary_significant <- !is.na(primary_row$q_value) & primary_row$q_value < 0.05
  primary_minimum_effect <- !is.na(primary_row$minimum_effect_q_value) &
    primary_row$minimum_effect_q_value < 0.05
  primary_equivalent <- primary_row$model_status == "constant_metric" |
    (!is.na(primary_row$equivalence_q_value) &
       primary_row$equivalence_q_value < 0.05)

  classification <- if (all_constant) {
    "observed_invariant"
  } else if (primary_equivalent && all(equivalent)) {
    "stable_within_margin"
  } else if (primary_minimum_effect && direction_robust) {
    if (primary_row$estimate > 0) "increase" else "decrease"
  } else if (any(minimum_effect)) {
    "detection_sensitive"
  } else if (primary_significant && direction_robust) {
    "magnitude_uncertain"
  } else if (any(significant)) {
    "detection_sensitive"
  } else if (primary_equivalent) {
    "stability_detection_sensitive"
  } else {
    "no_detected_association"
  }

  strict_significant <- nrow(strict_row) == 1L &&
    !is.na(strict_row$q_value) && strict_row$q_value < 0.05
  strict_minimum_effect <- nrow(strict_row) == 1L &&
    !is.na(strict_row$minimum_effect_q_value) &&
    strict_row$minimum_effect_q_value < 0.05
  strict_direction_agreement <- nrow(strict_row) == 1L &&
    is.finite(strict_row$estimate) && is.finite(primary_row$estimate) &&
    sign(strict_row$estimate) == sign(primary_row$estimate)
  strict_equivalent <- nrow(strict_row) == 1L && (
    strict_row$model_status == "constant_metric" ||
      (!is.na(strict_row$equivalence_q_value) &
         strict_row$equivalence_q_value < 0.05)
  )
  data.frame(
    classification = classification,
    direction_robust_across_detection = direction_robust,
    significant_all_detection = all(significant),
    minimum_effect_all_detection = all(minimum_effect),
    equivalent_all_detection = all(equivalent),
    ambiguous_withheld_significant = strict_significant,
    ambiguous_withheld_minimum_effect = strict_minimum_effect,
    ambiguous_withheld_direction_agreement = strict_direction_agreement,
    ambiguous_withheld_equivalent = strict_equivalent,
    stringsAsFactors = FALSE
  )
}

primary_rows <- contrasts[contrasts$detection == primary_detection, , drop = FALSE]
classification <- do.call(rbind, lapply(seq_len(nrow(primary_rows)), function(index) {
  cbind(primary_rows[index, , drop = FALSE], classify_contrast(primary_rows[index, ]))
}))
rownames(classification) <- NULL
classification <- classification[order(
  classification$frame_id, classification$metric_id, classification$contrast
), ]
write_tsv(
  classification,
  file.path(output_dir, "r10-frame-time-classification.tsv")
)

weighted_primary_rows <- weighted_contrasts[
  weighted_contrasts$detection == primary_detection, , drop = FALSE
]
weighted_classification <- do.call(rbind, lapply(
  seq_len(nrow(weighted_primary_rows)),
  function(index) {
    cbind(
      weighted_primary_rows[index, , drop = FALSE],
      classify_contrast(
        weighted_primary_rows[index, ],
        sensitivity_table = weighted_contrasts,
        strict_table = strict_weighted_contrasts
      )
    )
  }
))
rownames(weighted_classification) <- NULL
weighted_classification <- weighted_classification[order(
  weighted_classification$frame_id, weighted_classification$contrast
), ]
write_tsv(
  weighted_classification,
  file.path(output_dir, "r10-frame-time-abundance-weighted-classification.tsv")
)

# Resolve the clearly varying mean-per-MAG frames into the individual GIFT
# carrier fractions that compose them. Frame selection comes from the analysis
# classification above, and member selection still comes from database-derived
# frame metadata. The detailed view is descriptive: it ranks contributions for
# visual explanation and performs no per-GIFT hypothesis tests.
decrease_rows <- classification[
  classification$metric_id == "mean_genome_richness" &
    classification$classification == "decrease",
  , drop = FALSE
]
decrease_count <- table(decrease_rows$frame_id)
variation_frame_ids <- names(decrease_count)[decrease_count == 2L]
variation_frame_ids <- frame_catalogue$frame_id[
  frame_catalogue$frame_id %in% variation_frame_ids
]
if (!length(variation_frame_ids)) {
  stop("No reference frame decreased at both later ages", call. = FALSE)
}

variation_membership <- membership[
  membership$frame_id %in% variation_frame_ids, , drop = FALSE
]
variation_gifts <- unique(variation_membership$gift_id)
primary_reading <- trait_reads[[which(thresholds == primary_detection)]]
gift_state <- primary_reading$calls[variation_gifts, , drop = FALSE]
gift_support <- reshape_like(gift_state %in% TRUE, gift_state)
detected_values <- reshape_like(
  as.double(primary_reading$detected), primary_reading$detected
)
gift_carriers <- reshape_like(as.double(gift_support), gift_support) %*%
  detected_values
detected_genomes <- colSums(primary_reading$detected)
gift_carrier_fraction <- sweep(gift_carriers, 2L, detected_genomes, "/")

gift_metadata <- as.data.frame(primary_reading$metadata)
gift_metadata <- gift_metadata[
  match(colnames(gift_carrier_fraction), gift_metadata$sample_id), , drop = FALSE
]
stopifnot(identical(gift_metadata$sample_id, colnames(gift_carrier_fraction)))

# Mean per-MAG frame richness is exactly the sum of its member-GIFT carrier
# fractions in every sample. This guards the biological decomposition before
# fitting the descriptive GIFT-level trajectories.
for (frame_id in variation_frame_ids) {
  members <- variation_membership$gift_id[
    variation_membership$frame_id == frame_id
  ]
  observed <- colSums(gift_carrier_fraction[members, , drop = FALSE])
  expected <- sample_metrics[
    sample_metrics$detection == primary_detection &
      sample_metrics$frame_id == frame_id &
      sample_metrics$metric_id == "mean_genome_richness",
    c("sample_id", "value"), drop = FALSE
  ]
  expected <- expected[match(colnames(gift_carrier_fraction), expected$sample_id), ]
  if (!isTRUE(all.equal(
    unname(observed), unname(expected$value), tolerance = 1e-12
  ))) {
    stop("GIFT carrier fractions no longer sum to frame richness", call. = FALSE)
  }
}

gift_adjusted_means <- do.call(rbind, lapply(variation_gifts, function(gift_id) {
  model_table <- gift_metadata
  model_table$value <- as.numeric(gift_carrier_fraction[gift_id, ])
  result <- fit_age_means(model_table)
  member_rows <- variation_membership[
    variation_membership$gift_id == gift_id, , drop = FALSE
  ]
  data.frame(
    gift_id = gift_id,
    gift_name = member_rows$gift_name[[1L]],
    member_frame_ids = paste(member_rows$frame_id, collapse = ";"),
    member_frames = paste(member_rows$reference_frame, collapse = ";"),
    result,
    stringsAsFactors = FALSE
  )
}))
rownames(gift_adjusted_means) <- NULL
gift_adjusted_means <- gift_adjusted_means[order(
  gift_adjusted_means$gift_id, gift_adjusted_means$sampling_time
), ]
write_tsv(
  gift_adjusted_means,
  file.path(output_dir, "r10-frame-time-gift-adjusted-means.tsv")
)

primary_weights <- primary_reading$abundance
primary_weights[!primary_reading$detected] <- 0
primary_weights <- sweep(primary_weights, 2L, colSums(primary_weights), "/")
gift_abundance_coverage <- reshape_like(
  as.double(gift_support), gift_support
) %*% primary_weights
gift_weighted_adjusted_means <- do.call(rbind, lapply(
  variation_gifts,
  function(gift_id) {
    model_table <- gift_metadata
    model_table$value <- as.numeric(gift_abundance_coverage[gift_id, ])
    result <- fit_age_means(model_table)
    member_rows <- variation_membership[
      variation_membership$gift_id == gift_id, , drop = FALSE
    ]
    data.frame(
      gift_id = gift_id,
      gift_name = member_rows$gift_name[[1L]],
      member_frame_ids = paste(member_rows$frame_id, collapse = ";"),
      member_frames = paste(member_rows$reference_frame, collapse = ";"),
      result,
      stringsAsFactors = FALSE
    )
  }
))
rownames(gift_weighted_adjusted_means) <- NULL
gift_weighted_adjusted_means <- gift_weighted_adjusted_means[order(
  gift_weighted_adjusted_means$gift_id,
  gift_weighted_adjusted_means$sampling_time
), ]
write_tsv(
  gift_weighted_adjusted_means,
  file.path(
    output_dir, "r10-frame-time-gift-abundance-weighted-adjusted-means.tsv"
  )
)

gift_changes <- do.call(rbind, lapply(
  split(seq_len(nrow(gift_adjusted_means)), gift_adjusted_means$gift_id),
  function(index) {
    rows <- gift_adjusted_means[index, , drop = FALSE]
    rows <- rows[match(c(7, 21, 35), rows$sampling_time), ]
    data.frame(
      gift_id = rows$gift_id[[1L]], gift_name = rows$gift_name[[1L]],
      day_21_minus_day_7 = rows$adjusted_mean[[2L]] - rows$adjusted_mean[[1L]],
      day_35_minus_day_7 = rows$adjusted_mean[[3L]] - rows$adjusted_mean[[1L]],
      stringsAsFactors = FALSE
    )
  }
))
rownames(gift_changes) <- NULL

gift_weighted_changes <- do.call(rbind, lapply(
  split(
    seq_len(nrow(gift_weighted_adjusted_means)),
    gift_weighted_adjusted_means$gift_id
  ),
  function(index) {
    rows <- gift_weighted_adjusted_means[index, , drop = FALSE]
    rows <- rows[match(c(7, 21, 35), rows$sampling_time), ]
    data.frame(
      gift_id = rows$gift_id[[1L]], gift_name = rows$gift_name[[1L]],
      day_21_minus_day_7 = rows$adjusted_mean[[2L]] - rows$adjusted_mean[[1L]],
      day_35_minus_day_7 = rows$adjusted_mean[[3L]] - rows$adjusted_mean[[1L]],
      stringsAsFactors = FALSE
    )
  }
))
rownames(gift_weighted_changes) <- NULL

detail_selection <- do.call(rbind, lapply(variation_frame_ids, function(frame_id) {
  members <- variation_membership$gift_id[
    variation_membership$frame_id == frame_id
  ]
  rows <- gift_changes[gift_changes$gift_id %in% members, , drop = FALSE]
  rows <- rows[order(rows$day_35_minus_day_7, rows$gift_id), ]
  rows <- head(rows, 6L)
  rows$detail_rank <- seq_len(nrow(rows))
  rows$frame_id <- frame_id
  rows$reference_frame <- frame_catalogue$label[
    match(frame_id, frame_catalogue$frame_id)
  ]
  rows
}))
rownames(detail_selection) <- NULL

gift_detail <- merge(
  detail_selection,
  gift_adjusted_means[c(
    "gift_id", "sampling_time", "adjusted_mean", "standard_error",
    "confidence_low", "confidence_high", "model_status"
  )],
  by = "gift_id", all.x = TRUE, sort = FALSE
)
gift_detail <- gift_detail[order(
  match(gift_detail$frame_id, variation_frame_ids),
  gift_detail$detail_rank, gift_detail$sampling_time
), ]
write_tsv(
  gift_detail,
  file.path(output_dir, "r10-frame-time-gift-detail.tsv")
)

gift_weighting_detail <- merge(
  detail_selection,
  gift_weighted_changes[c(
    "gift_id", "day_21_minus_day_7", "day_35_minus_day_7"
  )],
  by = "gift_id", all.x = TRUE, sort = FALSE,
  suffixes = c("_unweighted", "_abundance_weighted")
)
gift_weighting_detail <- gift_weighting_detail[order(
  match(gift_weighting_detail$frame_id, variation_frame_ids),
  gift_weighting_detail$detail_rank
), ]
write_tsv(
  gift_weighting_detail,
  file.path(output_dir, "r10-frame-time-gift-weighting-sensitivity.tsv")
)

plot_data <- classification
plot_data$metric_label <- factor(
  plot_data$metric_id,
  levels = c(
    "community_richness", "mean_genome_richness", "community_coverage"
  ),
  labels = c(
    "Community richness", "Mean per-MAG richness", "Bounded coverage"
  )
)
plot_data$contrast_label <- factor(
  plot_data$contrast,
  levels = c("day_21_minus_day_7", "day_35_minus_day_7"),
  labels = c("Day 21 – day 7", "Day 35 – day 7")
)
plot_data$plot_class <- ifelse(
  plot_data$classification == "increase",
  "Increase beyond margin\n(at >0.001)",
  ifelse(
    plot_data$classification == "decrease",
    "Decrease beyond margin\n(at >0.001)",
    ifelse(
      plot_data$classification %in% c(
        "stable_within_margin", "observed_invariant"
      ),
      "Stable or invariant\n(all thresholds)",
      ifelse(
        plot_data$classification %in% c(
          "detection_sensitive", "stability_detection_sensitive"
        ),
        "Detection-sensitive",
        ifelse(
          plot_data$classification == "magnitude_uncertain",
          "Magnitude uncertain", "No detected association"
        )
      )
    )
  )
)
plot_data$plot_class <- factor(
  plot_data$plot_class,
  levels = c(
    "Increase beyond margin\n(at >0.001)",
    "Decrease beyond margin\n(at >0.001)",
    "Stable or invariant\n(all thresholds)",
    "Detection-sensitive", "Magnitude uncertain",
    "No detected association"
  )
)
plot_data$effect_label <- ifelse(
  plot_data$metric_id == "community_coverage",
  sprintf("%+.1f pp", 100 * plot_data$estimate),
  sprintf("%+.2f", plot_data$estimate)
)
plot_data$reference_frame <- factor(
  plot_data$reference_frame,
  levels = rev(frame_catalogue$label)
)

figure <- ggplot(
  plot_data,
  aes(contrast_label, reference_frame, fill = plot_class)
) +
  geom_tile(colour = "white", linewidth = 0.5) +
  geom_text(aes(label = effect_label), size = 2.55, colour = "black") +
  facet_grid(. ~ metric_label, scales = "free_x", space = "free_x") +
  scale_fill_manual(
    values = c(
      `Increase beyond margin\n(at >0.001)` = "#0072B2",
      `Decrease beyond margin\n(at >0.001)` = "#D55E00",
      `Stable or invariant\n(all thresholds)` = "#009E73",
      `Detection-sensitive` = "#E69F00",
      `Magnitude uncertain` = "#CC79A7",
      `No detected association` = "#BDBDBD"
    )
  ) +
  labs(
    x = NULL, y = NULL, fill = "Classification",
    title = "Curated capability frames separate temporal change from stability",
    subtitle = paste(
      "Adjusted effects at operational detection > 0.001;",
      "counts use a ±1-GIFT stability margin and bounded coverage uses ±5 percentage points"
    ),
    caption = paste(
      "Colors classify the evidence; printed values are adjusted differences.",
      "Reference frames aggregate unchanged genome-level calls.",
      "Tiles describe encoded capability distribution, not expression, activity or flux."
    )
  ) +
  theme_bw(base_size = 9) +
  theme(
    legend.position = "bottom",
    legend.title = element_text(face = "bold"),
    legend.key.width = grid::unit(1.6, "lines"),
    axis.text.x = element_text(angle = 35, hjust = 1),
    strip.text = element_text(face = "bold"),
    panel.grid = element_blank(),
    plot.caption = element_text(hjust = 0)
  )

ggsave(
  file.path(figure_dir, "figure-s5-r10-reference-frames.pdf"),
  figure, width = 12.2, height = 8.8, device = cairo_pdf
)
ggsave(
  file.path(figure_dir, "figure-s5-r10-reference-frames.png"),
  figure, width = 12.2, height = 8.8, dpi = 320
)

# A companion figure shows the fitted values behind the two contrasts. Each
# metric gets its own fixed scale, and colour carries no classification here:
# the lines are a direct view of the adjusted three-day trajectory.
adjusted_means$reference_frame <- factor(
  adjusted_means$reference_frame, levels = frame_catalogue$label
)

trajectory_plot <- function(data, title, y_label, digits, ncol = 5L,
                            proportion = FALSE) {
  if (isTRUE(proportion)) {
    data$confidence_low <- pmax(0, data$confidence_low)
    data$confidence_high <- pmin(1, data$confidence_high)
    data$value_label <- sprintf("%.*f%%", digits, 100 * data$adjusted_mean)
  } else {
    data$confidence_low <- pmax(0, data$confidence_low)
    data$value_label <- sprintf(paste0("%.", digits, "f"), data$adjusted_mean)
  }
  plot <- ggplot(
    data,
    aes(sampling_time, adjusted_mean, group = frame_id)
  ) +
    geom_errorbar(
      aes(ymin = confidence_low, ymax = confidence_high),
      width = 1.1, linewidth = 0.35, colour = "#777777"
    ) +
    geom_line(linewidth = 0.65, colour = "#3B5B92") +
    geom_point(size = 1.8, colour = "#3B5B92") +
    geom_text(
      aes(label = value_label), vjust = -0.75, size = 2.25,
      colour = "#222222", check_overlap = TRUE
    ) +
    facet_wrap(~ reference_frame, ncol = ncol) +
    scale_x_continuous(breaks = c(7, 21, 35)) +
    labs(title = title, x = "Sampling day", y = y_label) +
    theme_bw(base_size = 8) +
    theme(
      strip.text = element_text(size = 7.1),
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = 10),
      axis.title = element_text(size = 8)
    )
  if (isTRUE(proportion)) {
    plot <- plot + scale_y_continuous(
      limits = c(0, 1),
      labels = function(value) paste0(round(100 * value), "%"),
      expand = expansion(mult = c(0.02, 0.12))
    )
  } else {
    plot <- plot + expand_limits(y = 0) +
      scale_y_continuous(expand = expansion(mult = c(0.02, 0.16)))
  }
  plot
}

community_trajectory <- trajectory_plot(
  adjusted_means[adjusted_means$metric_id == "community_richness", ],
  "A. Community richness", "GIFTs in community union", digits = 1
)
genome_trajectory <- trajectory_plot(
  adjusted_means[adjusted_means$metric_id == "mean_genome_richness", ],
  "B. Mean per-MAG richness", "GIFTs per detected MAG", digits = 2
)
coverage_trajectory <- trajectory_plot(
  adjusted_means[adjusted_means$metric_id == "community_coverage", ],
  "C. Bounded community coverage", "Assessable frame covered",
  digits = 1, ncol = 4, proportion = TRUE
)

trajectory_figure <- community_trajectory / genome_trajectory /
  coverage_trajectory +
  plot_layout(heights = c(4, 4, 1.35)) +
  plot_annotation(
    title = "Adjusted capability-frame values across three sampling days",
    subtitle = paste(
      "Population-standardised means at operational detection > 0.001;",
      "error bars are 95% confidence intervals"
    ),
    caption = paste(
      "Lines connect model-adjusted values, not repeated measurements of one bird.",
      "Values describe encoded capability distribution, not expression, activity or flux."
    ),
    theme = theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 10),
      plot.caption = element_text(size = 8, hjust = 0)
    )
  )

ggsave(
  file.path(figure_dir, "figure-s6-r10-reference-frame-trajectories.pdf"),
  trajectory_figure, width = 13.5, height = 18.5, device = cairo_pdf
)
ggsave(
  file.path(figure_dir, "figure-s6-r10-reference-frame-trajectories.png"),
  trajectory_figure, width = 13.5, height = 18.5, dpi = 320
)

# Couple the three clearly changing frame-level trajectories to a readable
# GIFT-level view. Six GIFTs per frame are shown to keep the figure legible;
# the complete, overlapping memberships and all fitted GIFT trajectories are
# retained in the output tables above.
frame_colours <- stats::setNames(
  c("#0072B2", "#D55E00", "#009E73", "#CC79A7", "#E69F00")[
    seq_along(variation_frame_ids)
  ],
  variation_frame_ids
)
frame_trend_data <- adjusted_means[
  adjusted_means$frame_id %in% variation_frame_ids &
    adjusted_means$metric_id == "mean_genome_richness",
  , drop = FALSE
]
frame_trend_data$reference_frame <- factor(
  frame_trend_data$reference_frame,
  levels = frame_catalogue$label[
    match(variation_frame_ids, frame_catalogue$frame_id)
  ]
)
frame_trend_data$value_label <- sprintf("%.2f", frame_trend_data$adjusted_mean)

frame_trend_plot <- ggplot(
  frame_trend_data,
  aes(sampling_time, adjusted_mean, colour = frame_id, group = frame_id)
) +
  geom_errorbar(
    aes(ymin = confidence_low, ymax = confidence_high),
    width = 1.1, linewidth = 0.45
  ) +
  geom_line(linewidth = 0.85) +
  geom_point(size = 2.4) +
  geom_text(
    aes(label = value_label), vjust = -0.8, size = 2.8,
    colour = "#222222"
  ) +
  facet_wrap(~ reference_frame, nrow = 1) +
  scale_colour_manual(values = frame_colours, guide = "none") +
  scale_x_continuous(breaks = c(7, 21, 35)) +
  expand_limits(y = 0) +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.16))) +
  labs(
    title = "A. Overall frame-level trend",
    x = "Sampling day", y = "Mean GIFTs per detected MAG"
  ) +
  theme_bw(base_size = 9) +
  theme(
    strip.text = element_text(face = "bold", size = 8.5),
    plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

wrap_gift_label <- function(value, width = 31L) {
  vapply(value, function(label) {
    paste(strwrap(label, width = width), collapse = "\n")
  }, character(1))
}

gift_detail_plot <- function(frame_id, show_y_title = FALSE) {
  data <- gift_detail[gift_detail$frame_id == frame_id, , drop = FALSE]
  order_rows <- data[!duplicated(data$gift_id), ]
  order_rows <- order_rows[order(order_rows$detail_rank), ]
  label_by_id <- stats::setNames(
    wrap_gift_label(order_rows$gift_name), order_rows$gift_id
  )
  data$gift_label <- factor(
    label_by_id[data$gift_id], levels = unname(label_by_id)
  )
  data$value_label <- sprintf("%.1f%%", 100 * data$adjusted_mean)
  data$plot_low <- pmax(0, data$confidence_low)
  data$plot_high <- pmin(1, data$confidence_high)
  frame_label <- frame_catalogue$label[
    match(frame_id, frame_catalogue$frame_id)
  ]
  ggplot(data, aes(sampling_time, adjusted_mean, group = gift_id)) +
    geom_errorbar(
      aes(ymin = plot_low, ymax = plot_high),
      width = 1.1, linewidth = 0.35, colour = "#777777"
    ) +
    geom_line(linewidth = 0.7, colour = frame_colours[[frame_id]]) +
    geom_point(size = 1.9, colour = frame_colours[[frame_id]]) +
    geom_text(
      aes(label = value_label), vjust = -0.7, size = 2.15,
      colour = "#222222", check_overlap = TRUE
    ) +
    facet_wrap(~ gift_label, ncol = 1) +
    scale_x_continuous(breaks = c(7, 21, 35)) +
    scale_y_continuous(
      limits = c(0, 1.05), breaks = c(0, 0.5, 1),
      labels = function(value) paste0(round(100 * value), "%"),
      expand = expansion(mult = c(0.01, 0.02))
    ) +
    labs(
      title = paste0(if (show_y_title) "B. " else "", frame_label),
      x = "Sampling day",
      y = if (show_y_title) "Carrier prevalence among detected MAGs" else NULL
    ) +
    theme_bw(base_size = 8) +
    theme(
      strip.text = element_text(size = 7),
      plot.title = element_text(
        face = "bold", size = 9, colour = frame_colours[[frame_id]]
      ),
      panel.grid.minor = element_blank(),
      axis.title.y = element_text(size = 8)
    )
}

gift_detail_plots <- lapply(seq_along(variation_frame_ids), function(index) {
  gift_detail_plot(
    variation_frame_ids[[index]], show_y_title = identical(index, 1L)
  )
})
gift_detail_row <- wrap_plots(gift_detail_plots, nrow = 1)

composite_figure <- frame_trend_plot / gift_detail_row +
  plot_layout(heights = c(1.05, 4.2)) +
  plot_annotation(
    title = "Frame-level change resolves to named genome-inferred capabilities",
    subtitle = paste(
      "Six largest descriptive day-35 minus day-7 declines in adjusted",
      "GIFT carrier prevalence within each clearly changing frame"
    ),
    caption = paste(
      "GIFT detail is descriptive and was not tested individually.",
      "Overlapping frames may contain the same GIFT; complete memberships and trajectories are retained in the source tables."
    ),
    theme = theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 10),
      plot.caption = element_text(size = 8, hjust = 0)
    )
  )

ggsave(
  file.path(figure_dir, "figure-s7-r10-frame-gift-decomposition.pdf"),
  composite_figure, width = 13.5, height = 14.5, device = cairo_pdf
)
ggsave(
  file.path(figure_dir, "figure-s7-r10-frame-gift-decomposition.png"),
  composite_figure, width = 13.5, height = 14.5, dpi = 320
)

# Compare equal weighting of detected MAGs with weighting by their closed
# relative abundance. Both are distributions of encoded capability; neither is
# an activity, expression or flux measurement.
weighting_levels <- c(
  "Equal weight per detected MAG", "Carrier-genome abundance weighted"
)
weighting_colours <- c(
  `Equal weight per detected MAG` = "#4D4D4D",
  `Carrier-genome abundance weighted` = "#0072B2"
)
weighting_linetypes <- c(
  `Equal weight per detected MAG` = "solid",
  `Carrier-genome abundance weighted` = "22"
)

unweighted_comparison <- frame_trend_data[c(
  "frame_id", "reference_frame", "sampling_time", "adjusted_mean",
  "confidence_low", "confidence_high"
)]
unweighted_comparison$weighting <- weighting_levels[[1L]]
weighted_comparison <- weighted_adjusted_means[
  weighted_adjusted_means$frame_id %in% variation_frame_ids,
  c(
    "frame_id", "reference_frame", "sampling_time", "adjusted_mean",
    "confidence_low", "confidence_high"
  ), drop = FALSE
]
weighted_comparison$weighting <- weighting_levels[[2L]]
frame_weighting_comparison <- rbind(
  unweighted_comparison, weighted_comparison
)
frame_weighting_comparison$weighting <- factor(
  frame_weighting_comparison$weighting, levels = weighting_levels
)
frame_weighting_comparison$reference_frame <- factor(
  frame_weighting_comparison$reference_frame,
  levels = frame_catalogue$label[
    match(variation_frame_ids, frame_catalogue$frame_id)
  ]
)
frame_weighting_comparison$value_label <- sprintf(
  "%.2f", frame_weighting_comparison$adjusted_mean
)
frame_weighting_comparison$label_vjust <- ifelse(
  frame_weighting_comparison$weighting == weighting_levels[[2L]], -0.8, 1.45
)

frame_weighting_plot <- ggplot(
  frame_weighting_comparison,
  aes(
    sampling_time, adjusted_mean, colour = weighting,
    linetype = weighting, shape = weighting, group = weighting
  )
) +
  geom_errorbar(
    aes(ymin = confidence_low, ymax = confidence_high),
    width = 1.1, linewidth = 0.35, alpha = 0.8
  ) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2.2) +
  geom_text(
    aes(label = value_label, vjust = label_vjust),
    size = 2.55, colour = "#222222", show.legend = FALSE
  ) +
  facet_wrap(~ reference_frame, nrow = 1) +
  scale_colour_manual(values = weighting_colours) +
  scale_linetype_manual(values = weighting_linetypes) +
  scale_shape_manual(values = c(16, 17)) +
  scale_x_continuous(breaks = c(7, 21, 35)) +
  expand_limits(y = 0) +
  scale_y_continuous(expand = expansion(mult = c(0.02, 0.17))) +
  labs(
    title = "A. Frame trajectories under equal and abundance weighting",
    x = "Sampling day", y = "Mean GIFT richness", colour = NULL,
    linetype = NULL, shape = NULL
  ) +
  theme_bw(base_size = 9) +
  theme(
    strip.text = element_text(face = "bold"),
    plot.title = element_text(face = "bold"),
    panel.grid.minor = element_blank(),
    legend.position = "bottom"
  )

gift_change_limit <- range(
  100 * c(
    gift_weighting_detail$day_35_minus_day_7_unweighted,
    gift_weighting_detail$day_35_minus_day_7_abundance_weighted, 0
  ),
  finite = TRUE
)
gift_change_limit <- gift_change_limit + c(-1.5, 1.5)

gift_weighting_plot <- function(frame_id, show_y_title = FALSE) {
  data <- gift_weighting_detail[
    gift_weighting_detail$frame_id == frame_id, , drop = FALSE
  ]
  data <- data[order(data$detail_rank), ]
  labels <- wrap_gift_label(data$gift_name, width = 28L)
  data$gift_label <- factor(labels, levels = rev(labels))
  segments <- data.frame(
    gift_label = data$gift_label,
    unweighted = 100 * data$day_35_minus_day_7_unweighted,
    abundance_weighted = 100 *
      data$day_35_minus_day_7_abundance_weighted
  )
  long <- rbind(
    data.frame(
      gift_label = data$gift_label,
      weighting = weighting_levels[[1L]],
      change = segments$unweighted
    ),
    data.frame(
      gift_label = data$gift_label,
      weighting = weighting_levels[[2L]],
      change = segments$abundance_weighted
    )
  )
  long$weighting <- factor(long$weighting, levels = weighting_levels)
  frame_label <- frame_catalogue$label[
    match(frame_id, frame_catalogue$frame_id)
  ]
  ggplot() +
    geom_vline(xintercept = 0, colour = "#888888", linewidth = 0.35) +
    geom_segment(
      data = segments,
      aes(
        x = unweighted, xend = abundance_weighted,
        y = gift_label, yend = gift_label
      ),
      colour = "#BDBDBD", linewidth = 0.65
    ) +
    geom_point(
      data = long,
      aes(change, gift_label, colour = weighting, shape = weighting),
      size = 2.4
    ) +
    scale_colour_manual(values = weighting_colours, guide = "none") +
    scale_shape_manual(values = c(16, 17), guide = "none") +
    scale_x_continuous(
      limits = gift_change_limit,
      labels = function(value) paste0(sprintf("%+.0f", value), " pp")
    ) +
    labs(
      title = paste0(if (show_y_title) "B. " else "", frame_label),
      x = "Adjusted day 35 − day 7 change",
      y = if (show_y_title) "Displayed GIFT" else NULL
    ) +
    theme_bw(base_size = 8) +
    theme(
      plot.title = element_text(face = "bold", size = 9),
      axis.text.y = element_text(size = 7),
      panel.grid.minor = element_blank()
    )
}

gift_weighting_plots <- lapply(seq_along(variation_frame_ids), function(index) {
  gift_weighting_plot(
    variation_frame_ids[[index]], show_y_title = identical(index, 1L)
  )
})
gift_weighting_row <- wrap_plots(gift_weighting_plots, nrow = 1)

weighting_figure <- frame_weighting_plot / gift_weighting_row +
  plot_layout(heights = c(1.05, 1.55)) +
  plot_annotation(
    title = "Abundance weighting preserves the principal frame-level declines",
    subtitle = paste(
      "Five of six focal contrasts remain beyond the ±1-GIFT margin;",
      "vitamin biosynthesis at day 21 remains negative but its magnitude is uncertain"
    ),
    caption = paste(
      "Abundance is closed within each sample's detected MAGs.",
      "Carrier abundance is encoded capability distribution, not activity, expression or flux."
    ),
    theme = theme(
      plot.title = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(size = 10),
      plot.caption = element_text(size = 8, hjust = 0)
    )
  )

ggsave(
  file.path(figure_dir, "figure-s8-r10-abundance-weighting.pdf"),
  weighting_figure, width = 13.5, height = 9.5, device = cairo_pdf
)
ggsave(
  file.path(figure_dir, "figure-s8-r10-abundance-weighting.png"),
  weighting_figure, width = 13.5, height = 9.5, dpi = 320
)

analysis_audit <- data.frame(
  item = c(
    "analysis_script_sha256", "gifter_sqlite_sha256", "trait_cache_sha256",
    "strict_trait_cache_sha256", "curated_reference_frames",
    "detection_thresholds", "primary_detection",
    "count_equivalence_margin_gifts",
    "bounded_coverage_equivalence_margin", "multiple_testing_correction",
    "decreasing_frames_detailed", "unique_member_gifts_detailed",
    "gift_detail_gifts_per_frame", "abundance_weighted_metric",
    "focal_abundance_weighted_decreases",
    "focal_abundance_weighted_magnitude_uncertain"
  ),
  value = c(
    sha256("manuscript/analysis/24-r10-reference-frame-time.R"), database_sha,
    sha256(trait_cache), sha256(strict_cache), nrow(frame_catalogue),
    paste(format(thresholds, scientific = TRUE), collapse = ";"),
    primary_detection, 1, 0.05, "Benjamini-Hochberg",
    length(variation_frame_ids), length(variation_gifts), 6,
    "sum of member-GIFT abundance_coverage",
    sum(
      weighted_classification$frame_id %in% variation_frame_ids &
        weighted_classification$classification == "decrease"
    ),
    sum(
      weighted_classification$frame_id %in% variation_frame_ids &
        weighted_classification$classification == "magnitude_uncertain"
    )
  ),
  stringsAsFactors = FALSE
)
write_tsv(
  analysis_audit,
  file.path(output_dir, "r10-frame-time-audit.tsv")
)

cat("R10 curated-reference-frame temporal analysis complete.\n")
