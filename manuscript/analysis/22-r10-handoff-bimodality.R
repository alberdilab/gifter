# R10 follow-up: encoded handoff potential and richness bimodality.
#
# This script reads the checksum-pinned calls and sample readings produced by
# 21-r10-chicken.R. It never treats an edge as exchange or cooperation. An edge
# is only an exact, extracellular-anchor-compatible relationship between two
# detected MAGs. Detection changes sample membership only, and a confidence
# floor may withhold a weak positive but never create one.
#
# Run from the repository root after 21-r10-chicken.R:
#   Rscript manuscript/analysis/22-r10-handoff-bimodality.R

suppressWarnings(suppressPackageStartupMessages({
  library(ggplot2)
}))

devtools::load_all(".", quiet = TRUE)

root <- "manuscript/analysis"
cache_dir <- Sys.getenv(
  "R10_CACHE_DIR", file.path(root, ".cache", "r10-chicken")
)
public_dir <- Sys.getenv(
  "R10_PUBLIC_DATA", file.path(cache_dir, "public-data")
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
database_sha <- sha256("inst/extdata/gifter.sqlite")
if (!identical(database_sha, unname(audit_value[["gifter_sqlite_sha256"]]))) {
  stop("The gifter database no longer matches the R10 input audit", call. = FALSE)
}

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
required <- c(
  trait_cache, strict_cache,
  file.path(public_dir, "stats.tsv"),
  file.path(public_dir, "taxonomy_v2.tsv")
)
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
primary <- which(thresholds == 1e-3)
primary_traits <- trait_reads[[primary]]
metadata <- as.data.frame(primary_traits$metadata)
stats <- read_tsv(file.path(public_dir, "stats.tsv"))
taxonomy <- read_tsv(file.path(public_dir, "taxonomy_v2.tsv"))

frame_by_label <- function(reading, label) {
  index <- which(vapply(
    reading$frames, function(frame) identical(frame$label, label), logical(1)
  ))
  if (length(index) != 1L) stop("Could not resolve frame: ", label, call. = FALSE)
  reading$frames[[index]]
}
metabolic_frame <- frame_by_label(primary_traits, "All metabolic GIFTs")
plant_frame <- frame_by_label(primary_traits, "Plant fibre utilisation")

# The public graph defines compatibility. Keep only exact links whose shared
# anchor is explicitly extracellular and whose endpoints are metabolic.
graph <- as.data.frame(gift_graph(quality = "exact"))
graph_gifts <- unique(c(graph$from_gift, graph$to_gift))
anchor_rows <- do.call(rbind, lapply(graph_gifts, function(gift) {
  as.data.frame(get_gift_anchors(gift))
}))
external_anchors <- unique(
  anchor_rows$anchor_id[anchor_rows$compartment == "extracellular"]
)
handoff_graph <- graph[
  graph$shared_anchor %in% external_anchors &
    graph$from_gift %in% metabolic_frame$gift_id &
    graph$to_gift %in% metabolic_frame$gift_id,
  , drop = FALSE
]
handoff_graph <- unique(handoff_graph[c(
  "from_gift", "shared_anchor", "shared_molecule", "to_gift", "edge_quality"
)])
handoff_graph <- handoff_graph[order(
  handoff_graph$shared_anchor, handoff_graph$from_gift, handoff_graph$to_gift
), ]
rownames(handoff_graph) <- NULL
if (!nrow(handoff_graph)) stop("No exact extracellular handoff links", call. = FALSE)
if (nrow(handoff_graph) > 30L) {
  stop("The bit-mask topology summary supports at most 30 graph links", call. = FALSE)
}

support_flags <- function(calls) {
  genomes <- colnames(calls)
  providers <- t(vapply(
    handoff_graph$from_gift,
    function(gift) calls[gift, ] %in% TRUE,
    logical(length(genomes))
  ))
  recipients <- t(vapply(
    handoff_graph$to_gift,
    function(gift) calls[gift, ] %in% TRUE,
    logical(length(genomes))
  ))
  dimnames(providers) <- list(seq_len(nrow(handoff_graph)), genomes)
  dimnames(recipients) <- list(seq_len(nrow(handoff_graph)), genomes)
  list(providers = providers, recipients = recipients)
}

# Count unique directed genome pairs without materialising the edge table.
# Each genome is represented by the graph links it can provide and receive;
# only the small set of observed bit-mask classes needs to be crossed.
pair_count <- function(providers, recipients, index) {
  powers <- 2^((seq_len(nrow(providers))) - 1L)
  provider_mask <- as.integer(colSums(providers[, index, drop = FALSE] * powers))
  recipient_mask <- as.integer(colSums(recipients[, index, drop = FALSE] * powers))
  classes <- aggregate(
    rep.int(1L, length(index)),
    list(provider_mask = provider_mask, recipient_mask = recipient_mask),
    sum
  )
  names(classes)[3L] <- "n"
  compatible <- outer(
    classes$provider_mask, classes$recipient_mask,
    Vectorize(function(from, to) bitwAnd(from, to) != 0L)
  )
  pairs <- sum(outer(classes$n, classes$n) * compatible)
  self_compatible <- bitwAnd(classes$provider_mask, classes$recipient_mask) != 0L
  pairs - sum(classes$n[self_compatible])
}

topology_reading <- function(reading, confidence_floor) {
  calls <- reading$calls
  detected <- reading$detected
  weights <- reading$abundance
  flags <- support_flags(calls)
  providers <- flags$providers
  recipients <- flags$recipients
  genomes <- rownames(detected)
  samples <- colnames(detected)
  anchors <- unique(handoff_graph$shared_anchor)

  metric_rows <- vector("list", length(samples))
  anchor_output <- vector("list", length(samples))
  chain_output <- vector("list", length(samples))
  for (sample_index in seq_along(samples)) {
    sample <- samples[[sample_index]]
    index <- which(detected[, sample_index])
    n <- length(index)
    provider_count <- rowSums(providers[, index, drop = FALSE])
    recipient_count <- rowSums(recipients[, index, drop = FALSE])
    within_count <- rowSums(
      providers[, index, drop = FALSE] & recipients[, index, drop = FALSE]
    )
    cross_pairs <- provider_count * recipient_count - within_count
    status <- ifelse(
      within_count > 0L, "within_genome",
      ifelse(cross_pairs > 0L, "community_distributed", "not_represented")
    )
    unique_pairs <- pair_count(providers, recipients, index)
    possible_pairs <- n * (n - 1L)
    provider_any <- colSums(providers[, index, drop = FALSE]) > 0L
    recipient_any <- colSums(recipients[, index, drop = FALSE]) > 0L

    anchor_parts <- lapply(anchors, function(anchor) {
      link_index <- which(handoff_graph$shared_anchor == anchor)
      provider <- colSums(providers[link_index, index, drop = FALSE]) > 0L
      recipient <- colSums(recipients[link_index, index, drop = FALSE]) > 0L
      overlap <- provider & recipient
      pairs <- sum(provider) * sum(recipient) - sum(overlap)
      data.frame(
        sample_id = sample,
        confidence_floor = confidence_floor,
        detection = reading$detection,
        anchor_id = anchor,
        provider_genomes = sum(provider),
        recipient_genomes = sum(recipient),
        provider_fraction = sum(provider) / n,
        recipient_fraction = sum(recipient) / n,
        provider_abundance_coverage = sum(weights[index, sample_index][provider]),
        recipient_abundance_coverage = sum(weights[index, sample_index][recipient]),
        cross_genome_pairs = pairs,
        compatible = pairs > 0L,
        stringsAsFactors = FALSE
      )
    })
    anchor_table <- do.call(rbind, anchor_parts)

    metric_rows[[sample_index]] <- data.frame(
      sample_id = sample,
      confidence_floor = confidence_floor,
      detection = reading$detection,
      detected_genomes = n,
      metric_id = c(
        "interaction_density", "unique_handoff_pairs", "gift_resolved_handoff_edges",
        "handoff_anchor_richness", "represented_chain_links",
        "within_genome_chain_links", "distributed_chain_links",
        "distributed_link_fraction", "provider_genome_fraction",
        "recipient_genome_fraction"
      ),
      value = c(
        if (possible_pairs > 0L) unique_pairs / possible_pairs else NA_real_,
        unique_pairs, sum(cross_pairs), sum(anchor_table$compatible),
        sum(status != "not_represented"), sum(status == "within_genome"),
        sum(status == "community_distributed"),
        if (sum(status != "not_represented")) {
          sum(status == "community_distributed") / sum(status != "not_represented")
        } else NA_real_,
        sum(provider_any) / n, sum(recipient_any) / n
      ),
      numerator = c(
        unique_pairs, unique_pairs, sum(cross_pairs), sum(anchor_table$compatible),
        sum(status != "not_represented"), sum(status == "within_genome"),
        sum(status == "community_distributed"),
        sum(status == "community_distributed"), sum(provider_any), sum(recipient_any)
      ),
      denominator = c(
        possible_pairs, NA, NA, length(anchors), nrow(handoff_graph),
        nrow(handoff_graph), nrow(handoff_graph),
        sum(status != "not_represented"), n, n
      ),
      stringsAsFactors = FALSE
    )
    anchor_output[[sample_index]] <- anchor_table
    chain_output[[sample_index]] <- data.frame(
      sample_id = sample,
      confidence_floor = confidence_floor,
      detection = reading$detection,
      handoff_graph,
      provider_genomes = provider_count,
      recipient_genomes = recipient_count,
      within_genomes = within_count,
      cross_genome_pairs = cross_pairs,
      status = status,
      stringsAsFactors = FALSE
    )
  }
  list(
    metrics = do.call(rbind, metric_rows),
    anchors = do.call(rbind, anchor_output),
    chains = do.call(rbind, chain_output),
    flags = flags
  )
}

cat("Summarising exact extracellular handoffs...\n")
readings <- lapply(trait_reads, topology_reading, confidence_floor = "all accepted")
readings[[length(readings) + 1L]] <- topology_reading(
  strict_traits, confidence_floor = "high-confidence"
)
handoff_metrics <- do.call(rbind, lapply(readings, `[[`, "metrics"))
handoff_anchors <- do.call(rbind, lapply(readings, `[[`, "anchors"))
handoff_chains <- do.call(rbind, lapply(readings, `[[`, "chains"))
handoff_metrics <- merge(handoff_metrics, metadata, by = "sample_id", sort = FALSE)
handoff_anchors <- merge(handoff_anchors, metadata, by = "sample_id", sort = FALSE)
handoff_chains <- merge(handoff_chains, metadata, by = "sample_id", sort = FALSE)
write_xz_tsv(
  handoff_metrics, file.path(output_dir, "r10-handoff-sensitivity.tsv.xz")
)
write_xz_tsv(
  handoff_anchors, file.path(output_dir, "r10-handoff-anchors.tsv.xz")
)
write_xz_tsv(
  handoff_chains, file.path(output_dir, "r10-handoff-chain-status.tsv.xz")
)
write_tsv(handoff_graph, file.path(output_dir, "r10-handoff-graph.tsv"))

summarise_values <- function(table, keys) {
  groups <- interaction(table[keys], drop = TRUE, lex.order = TRUE)
  rows <- lapply(split(seq_len(nrow(table)), groups), function(index) {
    key <- table[index[[1L]], keys, drop = FALSE]
    values <- table$value[index]
    key$samples <- sum(!is.na(values))
    key$median <- stats::median(values, na.rm = TRUE)
    key$q25 <- as.numeric(stats::quantile(values, 0.25, na.rm = TRUE))
    key$q75 <- as.numeric(stats::quantile(values, 0.75, na.rm = TRUE))
    key
  })
  result <- do.call(rbind, rows)
  rownames(result) <- NULL
  result
}

handoff_age_summary <- summarise_values(
  handoff_metrics,
  c("confidence_floor", "detection", "sampling_time", "metric_id")
)
write_tsv(
  handoff_age_summary, file.path(output_dir, "r10-handoff-age-summary.tsv")
)

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
      random = ~ 1 | pen, data = table, na.action = stats::na.omit,
      method = "REML", control = nlme::lmeControl(returnObject = TRUE)
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
    model_status = "ok", stringsAsFactors = FALSE
  )
}

fit_grouped <- function(table, keys) {
  groups <- interaction(table[keys], drop = TRUE, lex.order = TRUE)
  rows <- lapply(split(seq_len(nrow(table)), groups), function(index) {
    key <- table[index[[1L]], keys, drop = FALSE]
    rownames(key) <- NULL
    cbind(key, fit_contrasts(table[index, , drop = FALSE]))
  })
  result <- do.call(rbind, rows)
  rownames(result) <- NULL
  result$q_value <- stats::p.adjust(result$p_value, method = "BH")
  result
}

metric_contrasts <- fit_grouped(
  handoff_metrics,
  c("confidence_floor", "detection", "metric_id")
)
anchor_keys <- c(
  "sample_id", "confidence_floor", "detection", "anchor_id", "sampling_time",
  "trial", "pen", "treatment", "breed", "sex"
)
anchor_metric_long <- function(column) {
  result <- handoff_anchors[anchor_keys]
  result$metric_id <- column
  result$value <- handoff_anchors[[column]]
  result
}
anchor_long <- do.call(rbind, lapply(c(
  "provider_fraction", "recipient_fraction",
  "provider_abundance_coverage", "recipient_abundance_coverage"
), anchor_metric_long))
rownames(anchor_long) <- NULL
anchor_age_summary <- summarise_values(
  anchor_long,
  c("confidence_floor", "detection", "sampling_time", "anchor_id", "metric_id")
)
write_tsv(
  anchor_age_summary,
  file.path(output_dir, "r10-handoff-anchor-age-summary.tsv")
)
anchor_contrasts <- fit_grouped(
  anchor_long,
  c("confidence_floor", "detection", "anchor_id", "metric_id")
)
write_tsv(metric_contrasts, file.path(output_dir, "r10-handoff-age-contrasts.tsv"))
write_tsv(anchor_contrasts, file.path(output_dir, "r10-handoff-anchor-age-contrasts.tsv"))

# A detected-count-matched null for topology presence metrics. The null samples
# genomes uniformly from the same 822-MAG catalogue. It does not randomise or
# combine abundance with encoded compatibility.
cat("Computing detected-count-matched topology null...\n")
primary_network <- readings[[primary]]
primary_metrics <- primary_network$metrics
null_metric_ids <- c(
  "interaction_density", "handoff_anchor_richness", "distributed_chain_links"
)
observed <- primary_metrics[
  primary_metrics$metric_id %in% null_metric_ids,
  c("sample_id", "detected_genomes", "metric_id", "value")
]
flags <- primary_network$flags
genome_count <- ncol(flags$providers)
null_replicates <- 499L
set.seed(20261003)

scalar_topology <- function(index) {
  provider_count <- rowSums(flags$providers[, index, drop = FALSE])
  recipient_count <- rowSums(flags$recipients[, index, drop = FALSE])
  within_count <- rowSums(
    flags$providers[, index, drop = FALSE] &
      flags$recipients[, index, drop = FALSE]
  )
  cross_pairs <- provider_count * recipient_count - within_count
  n <- length(index)
  c(
    interaction_density = pair_count(flags$providers, flags$recipients, index) /
      (n * (n - 1L)),
    handoff_anchor_richness = length(unique(
      handoff_graph$shared_anchor[cross_pairs > 0L]
    )),
    distributed_chain_links = sum(
      within_count == 0L & cross_pairs > 0L
    )
  )
}

null_by_size <- lapply(sort(unique(observed$detected_genomes)), function(n) {
  values <- replicate(
    null_replicates,
    scalar_topology(sample.int(genome_count, n, replace = FALSE))
  )
  lapply(seq_along(null_metric_ids), function(metric_index) {
    value <- values[null_metric_ids[[metric_index]], ]
    data.frame(
      detected_genomes = n,
      metric_id = null_metric_ids[[metric_index]],
      null_mean = mean(value),
      null_sd = stats::sd(value),
      null_q025 = as.numeric(stats::quantile(value, 0.025)),
      null_median = stats::median(value),
      null_q975 = as.numeric(stats::quantile(value, 0.975)),
      stringsAsFactors = FALSE
    )
  })
})
null_summary <- do.call(rbind, unlist(null_by_size, recursive = FALSE))
null_results <- merge(
  observed, null_summary, by = c("detected_genomes", "metric_id"), sort = FALSE
)
null_results$difference_from_null <- null_results$value - null_results$null_mean
null_results$standardized_difference <- ifelse(
  null_results$null_sd > 0,
  null_results$difference_from_null / null_results$null_sd,
  NA_real_
)
null_results <- merge(null_results, metadata, by = "sample_id", sort = FALSE)
write_xz_tsv(null_results, file.path(output_dir, "r10-handoff-null.tsv.xz"))
null_for_models <- null_results
null_for_models$value <- null_for_models$difference_from_null
null_contrasts <- fit_grouped(null_for_models, "metric_id")
write_tsv(
  null_contrasts,
  file.path(output_dir, "r10-handoff-null-age-contrasts.tsv")
)

# Explain the two richness modes without assuming their driver. Define the two
# modes by the largest empty gap in primary metabolic community richness, then
# screen every MAG for agreement between its detection and the upper mode.
primary_metric_table <- as.data.frame(primary_traits$metrics)
richness <- primary_metric_table[
  primary_metric_table$metric_id == "community_richness" &
    primary_metric_table$reference_frame %in%
      c("All metabolic GIFTs", "Plant fibre utilisation"),
  c("sample_id", "reference_frame", "value")
]
richness <- reshape(
  richness, idvar = "sample_id", timevar = "reference_frame", direction = "wide"
)
names(richness) <- sub("^value[.]", "", names(richness))
names(richness)[names(richness) == "All metabolic GIFTs"] <- "metabolic_richness"
names(richness)[names(richness) == "Plant fibre utilisation"] <- "plant_fibre_richness"
levels <- sort(unique(richness$metabolic_richness))
gap_index <- which.max(diff(levels))
lower_max <- levels[[gap_index]]
upper_min <- levels[[gap_index + 1L]]
richness$richness_mode <- ifelse(
  richness$metabolic_richness <= lower_max, "lower", "upper"
)
upper <- richness$richness_mode == "upper"
detected <- primary_traits$detected[, match(richness$sample_id, colnames(primary_traits$detected))]
agreement <- rowMeans(detected == rep(upper, each = nrow(detected)))
association <- abs(vapply(seq_len(nrow(detected)), function(index) {
  genome_state <- as.numeric(detected[index, ])
  if (length(unique(genome_state)) < 2L) return(0)
  stats::cor(genome_state, as.numeric(upper))
}, numeric(1)))
association[!is.finite(association)] <- 0
candidate_order <- order(-agreement, -association, rownames(detected))
driver <- rownames(detected)[candidate_order[[1L]]]
driver_detected <- detected[driver, ]

driver_stats <- merge(
  stats[stats$mag_id == driver, ],
  taxonomy[taxonomy$genome == driver, ],
  by.x = "mag_id", by.y = "genome", sort = FALSE
)

frame_diagnostics <- function(frame) {
  ids <- intersect(frame$gift_id, rownames(primary_traits$calls))
  supports <- primary_traits$calls[ids, , drop = FALSE] %in% TRUE
  dim(supports) <- c(length(ids), ncol(primary_traits$calls))
  dimnames(supports) <- list(ids, colnames(primary_traits$calls))
  rows <- lapply(seq_len(ncol(detected)), function(sample_index) {
    present <- rownames(detected)[detected[, sample_index]]
    other <- setdiff(present, driver)
    represented <- rowSums(supports[, present, drop = FALSE]) > 0L
    represented_without <- if (length(other)) {
      rowSums(supports[, other, drop = FALSE]) > 0L
    } else {
      rep(FALSE, length(ids))
    }
    data.frame(
      sample_id = colnames(detected)[[sample_index]],
      richness_without_driver = sum(represented_without),
      driver_unique_gifts = sum(represented & !represented_without),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}
metabolic_diagnostic <- frame_diagnostics(metabolic_frame)
plant_diagnostic <- frame_diagnostics(plant_frame)
names(metabolic_diagnostic)[-1L] <- paste0(
  names(metabolic_diagnostic)[-1L], "_metabolic"
)
names(plant_diagnostic)[-1L] <- paste0(
  names(plant_diagnostic)[-1L], "_plant_fibre"
)

raw_abundance <- trait_reads[[1L]]$abundance[driver, ]
detected_count <- primary_metric_table[
  primary_metric_table$metric_id == "detected_genomes" &
    primary_metric_table$reference_frame == "All metabolic GIFTs",
  c("sample_id", "value")
]
names(detected_count)[2L] <- "detected_genomes"
mode_samples <- Reduce(
  function(x, y) merge(x, y, by = "sample_id", sort = FALSE),
  list(
    richness,
    metabolic_diagnostic,
    plant_diagnostic,
    detected_count,
    metadata,
    data.frame(
      sample_id = names(raw_abundance),
      driver_abundance = as.numeric(raw_abundance),
      driver_detected = as.logical(driver_detected),
      stringsAsFactors = FALSE
    )
  )
)
mode_samples <- mode_samples[match(richness$sample_id, mode_samples$sample_id), ]
write_tsv(mode_samples, file.path(output_dir, "r10-richness-mode-samples.tsv"))

driver_age_groups <- split(mode_samples, mode_samples$sampling_time)
driver_age_summary <- do.call(rbind, lapply(driver_age_groups, function(rows) {
  data.frame(
    sampling_time = rows$sampling_time[[1L]],
    samples = nrow(rows),
    median_abundance = stats::median(rows$driver_abundance),
    q25_abundance = as.numeric(stats::quantile(rows$driver_abundance, 0.25)),
    q75_abundance = as.numeric(stats::quantile(rows$driver_abundance, 0.75)),
    below_primary_threshold = sum(!rows$driver_detected),
    fraction_below_primary_threshold = mean(!rows$driver_detected),
    stringsAsFactors = FALSE
  )
}))
rownames(driver_age_summary) <- NULL
write_tsv(
  driver_age_summary,
  file.path(output_dir, "r10-richness-mode-driver-age-summary.tsv")
)
driver_model <- mode_samples
driver_model$value <- log10(driver_model$driver_abundance)
driver_age_contrasts <- fit_contrasts(driver_model)
driver_age_contrasts$q_value <- stats::p.adjust(
  driver_age_contrasts$p_value, method = "BH"
)
driver_age_contrasts$abundance_ratio <- 10^driver_age_contrasts$estimate
write_tsv(
  driver_age_contrasts,
  file.path(output_dir, "r10-richness-mode-driver-age-contrasts.tsv")
)

driver_calls <- primary_traits$calls[, driver] %in% TRUE
names(driver_calls) <- rownames(primary_traits$calls)
driver_summary <- data.frame(
  driver_genome = driver,
  mode_lower_maximum = lower_max,
  mode_upper_minimum = upper_min,
  samples = nrow(mode_samples),
  lower_mode_samples = sum(mode_samples$richness_mode == "lower"),
  upper_mode_samples = sum(mode_samples$richness_mode == "upper"),
  detection_mode_agreement = mean(mode_samples$driver_detected ==
    (mode_samples$richness_mode == "upper")),
  genomes_with_equal_or_better_agreement = sum(agreement >= agreement[[driver]]),
  next_best_genome_agreement = max(agreement[names(agreement) != driver]),
  phi = stats::cor(
    as.numeric(mode_samples$driver_detected),
    as.numeric(mode_samples$richness_mode == "upper")
  ),
  metabolic_gifts_in_driver = sum(
    driver_calls[names(driver_calls) %in% metabolic_frame$gift_id]
  ),
  plant_fibre_gifts_in_driver = sum(
    driver_calls[names(driver_calls) %in% plant_frame$gift_id]
  ),
  completeness_score = driver_stats$completeness_score,
  contamination_score = driver_stats$contamination_score,
  mag_length = driver_stats$mag_length,
  phylum = driver_stats$phylum,
  family = driver_stats$family,
  genus = driver_stats$genus,
  species = driver_stats$species,
  stringsAsFactors = FALSE
)
write_tsv(driver_summary, file.path(output_dir, "r10-richness-mode-driver.tsv"))

driver_unique_gifts <- function(frame, label) {
  ids <- intersect(frame$gift_id, rownames(primary_traits$calls))
  supports <- primary_traits$calls[ids, , drop = FALSE] %in% TRUE
  dim(supports) <- c(length(ids), ncol(primary_traits$calls))
  dimnames(supports) <- list(ids, colnames(primary_traits$calls))
  sample_index <- which(driver_detected)
  unique_matrix <- sapply(sample_index, function(index) {
    present <- rownames(detected)[detected[, index]]
    other <- setdiff(present, driver)
    supports[, driver] & !(rowSums(supports[, other, drop = FALSE]) > 0L)
  })
  data.frame(
    reference_frame = label,
    gift_id = ids,
    driver_support = supports[, driver],
    unique_samples = rowSums(unique_matrix),
    detected_driver_samples = length(sample_index),
    unique_fraction = rowMeans(unique_matrix),
    stringsAsFactors = FALSE
  )
}
mode_gifts <- rbind(
  driver_unique_gifts(metabolic_frame, metabolic_frame$label),
  driver_unique_gifts(plant_frame, plant_frame$label)
)
mode_gifts <- mode_gifts[mode_gifts$driver_support, ]
mode_gifts <- mode_gifts[order(
  mode_gifts$reference_frame, -mode_gifts$unique_fraction, mode_gifts$gift_id
), ]
write_tsv(mode_gifts, file.path(output_dir, "r10-richness-mode-gifts.tsv"))

threshold_mode_rows <- lapply(trait_reads, function(reading) {
  metrics <- as.data.frame(reading$metrics)
  values <- metrics[
    metrics$metric_id == "community_richness" &
      metrics$reference_frame %in%
        c("All metabolic GIFTs", "Plant fibre utilisation"),
    c("sample_id", "reference_frame", "value")
  ]
  values$driver_detected <- reading$detected[
    driver, match(values$sample_id, colnames(reading$detected))
  ]
  groups <- interaction(
    values[c("reference_frame", "driver_detected")],
    drop = TRUE, lex.order = TRUE
  )
  do.call(rbind, lapply(split(seq_len(nrow(values)), groups), function(index) {
    x <- values$value[index]
    data.frame(
      detection = reading$detection,
      reference_frame = values$reference_frame[index[[1L]]],
      driver_detected = values$driver_detected[index[[1L]]],
      samples = length(x), minimum = min(x), median = stats::median(x),
      maximum = max(x), stringsAsFactors = FALSE
    )
  }))
})
threshold_modes <- do.call(rbind, threshold_mode_rows)
rownames(threshold_modes) <- NULL
write_tsv(threshold_modes, file.path(output_dir, "r10-richness-mode-thresholds.tsv"))

mode_plot <- rbind(
  data.frame(
    sample_id = mode_samples$sample_id,
    driver_abundance = mode_samples$driver_abundance,
    sampling_time = mode_samples$sampling_time,
    richness = mode_samples$metabolic_richness,
    panel = "Community metabolic GIFT richness"
  ),
  data.frame(
    sample_id = mode_samples$sample_id,
    driver_abundance = mode_samples$driver_abundance,
    sampling_time = mode_samples$sampling_time,
    richness = mode_samples$plant_fibre_richness,
    panel = "Community plant-fibre GIFT richness"
  )
)
mode_plot$sampling_time <- factor(
  mode_plot$sampling_time, levels = c(7, 21, 35),
  labels = c("day 7", "day 21", "day 35")
)
mode_plot$panel <- factor(mode_plot$panel, levels = c(
  "Community metabolic GIFT richness", "Community plant-fibre GIFT richness"
))
figure <- ggplot(mode_plot, aes(driver_abundance, richness, colour = sampling_time)) +
  geom_vline(xintercept = 1e-3, colour = "#555555", linetype = 2) +
  geom_point(alpha = 0.62, size = 1.35) +
  scale_x_log10() +
  facet_wrap(~ panel, scales = "free_y", ncol = 1) +
  scale_colour_manual(values = c(
    "day 7" = "#356E75", "day 21" = "#C17A35", "day 35" = "#754668"
  )) +
  labs(
    x = paste0(driver, " relative abundance"), y = NULL, colour = NULL,
    title = "One high-repertoire MAG explains the R10 richness modes",
    subtitle = paste0(
      "Dashed line: operational detection > 0.001; ",
      driver_stats$species, " (", driver, ")"
    )
  ) +
  theme_bw(base_size = 10) +
  theme(
    legend.position = "top", strip.text = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )
ggsave(
  file.path(figure_dir, "figure-s3-r10-richness-mode.pdf"), figure,
  width = 7.2, height = 6.2, device = cairo_pdf
)
ggsave(
  file.path(figure_dir, "figure-s3-r10-richness-mode.png"), figure,
  width = 7.2, height = 6.2, dpi = 320
)

followup_audit <- data.frame(
  item = c(
    "analysis_script_sha256", "gifter_sqlite_sha256", "trait_cache_sha256",
    "strict_trait_cache_sha256", "exact_extracellular_graph_links",
    "exact_extracellular_anchors", "null_replicates_per_detected_genome_count",
    "richness_mode_driver"
  ),
  value = c(
    sha256("manuscript/analysis/22-r10-handoff-bimodality.R"), database_sha,
    sha256(trait_cache), sha256(strict_cache), nrow(handoff_graph),
    length(unique(handoff_graph$shared_anchor)), null_replicates, driver
  ),
  stringsAsFactors = FALSE
)
write_tsv(followup_audit, file.path(output_dir, "r10-followup-audit.tsv"))

cat("R10 handoff and richness-mode follow-up complete.\n")
