# Quantitative traits of one genome catalogue read across many samples.
#
# Nothing here is curated, nothing re-evaluates a genome, and nothing changes a
# call. A call is a property of a genome, so the catalogue is read once and
# every sample is a restriction and a reweighting of that one reading.
#
# That makes every per-sample distributional metric a matrix product over all
# samples at once. With C the three-state call matrix (GIFT x genome, after
# assessability and the confidence floor), S detection (genome x sample) and W
# abundance closed within each sample's detected set:
#
#   providers          (C %in% TRUE) %*% S            GIFT x sample
#   assessors          (!is.na(C))   %*% S            GIFT x sample
#   abundance coverage (C %in% TRUE) %*% W            GIFT x sample
#
# Three products per reference universe answer every sample and every GIFT.
# Everything else is a row or column reduction of them. A loop calling
# community_traits() once per sample would repeat the whole quadratic walk of a
# community for every sample, which is the cost the 0.5.0 release removed.
#
# Reference universes therefore stay the progress unit, unchanged from
# community_traits(): the sample loop is vectorized away and there is no
# sample-shaped work to count.
#
# Two metrics are sample-invariant and are not re-emitted per sample.
# `gift_richness` is a property of a genome and `repertoire_overlap` of a pair
# of genomes; both hold in every sample the genomes are detected in. They go to
# `catalogue_metrics`, and the absence of a `sample_id` column there is the
# claim: a row without a sample is a row no sample can change.
#
# The design record is inst/doc/proposal-multi-sample-datasets.md.

# A function rather than a constant, because `.metric_columns` lives in
# R/traits.R and the package sources its files in alphabetical order.
.dataset_metric_columns <- function() c("sample_id", .metric_columns)

.empty_dataset_metrics <- function() {
  metrics <- .empty_metrics()
  metrics$sample_id <- character()
  metrics[.dataset_metric_columns()]
}

# A metric row that names the sample it belongs to. The sample is its own
# column rather than part of `target_id`, so that `target_type` keeps the
# vocabulary community / gift / genome it already has and a reader filtering to
# one GIFT does not have to parse an identifier apart.
.sample_metric_row <- function(sample_id, ...) {
  row <- .metric_row(...)
  row$sample_id <- sample_id
  row[.dataset_metric_columns()]
}

# A logical matrix reshaped for arithmetic. `%in%` drops dimensions and matrix
# multiplication needs them back.
.numeric_state <- function(state, template) {
  values <- as.double(state)
  dim(values) <- dim(template)
  dimnames(values) <- dimnames(template)
  values
}

.logical_state <- function(state, template) {
  dim(state) <- dim(template)
  dimnames(state) <- dimnames(template)
  state
}

# Which pairs of genomes to compare, in the catalogue's order, so that a pair
# taken within one sample carries the same orientation as the same pair taken
# across the whole catalogue.
.genome_pairs <- function(total) {
  if (total < 2L) return(NULL)
  list(
    first = rep.int(seq_len(total - 1L), (total - 1L):1L),
    second = sequence((total - 1L):1L, from = 2L:total)
  )
}

# One reference universe, read over every sample at once.
.dataset_universe_metrics <- function(dataset, universe, version, calls,
                                      detected, weights, pairwise) {
  label <- universe$label
  genomes <- dataset$genome_id
  samples <- dataset$sample_id
  members <- intersect(dataset$catalogue$gift_id, universe$gift_id)
  state <- calls[members, , drop = FALSE]
  supports <- .logical_state(state %in% TRUE, state)
  assessed <- .logical_state(!is.na(state), state)

  support_values <- .numeric_state(supports, state)
  assessed_values <- .numeric_state(assessed, state)
  detection_values <- .numeric_state(detected, detected)

  # The three products. Everything reported per sample is a reduction of them.
  providers <- support_values %*% detection_values
  assessors <- assessed_values %*% detection_values
  coverage <- support_values %*% weights

  detected_count <- colSums(detected)
  assessable <- colSums(assessors > 0)
  richness <- colSums(providers > 0)
  singletons <- colSums(providers == 1)
  gift_richness <- colSums(supports)
  detected_richness <- as.vector(gift_richness %*% detection_values)

  metrics <- list(
    .sample_metric_row(
      samples, "community", "community", "community_richness", richness,
      "count", richness, NA_integer_, assessable, label, version,
      "GIFTs supported by at least one genome detected in this sample"
    ),
    .sample_metric_row(
      samples, "community", "community", "mean_genome_richness",
      detected_richness / detected_count, "count", detected_richness,
      detected_count, assessable, label, version,
      "supported GIFTs summed over the sample's detected genomes, divided by the number of them"
    ),
    # Reported beside every richness in every universe, and not only once,
    # because a metrics table filtered to one universe must still carry the
    # denominator its richness has to be read against. A genome absent from a
    # sample may be below detection rather than genuinely absent, and gifter
    # models no sequencing depth: this row is what says so, and nothing here
    # imputes it.
    .sample_metric_row(
      samples, "community", "community", "detected_genomes", detected_count,
      "count", detected_count, length(genomes), assessable, label, version,
      "catalogue genomes detected in this sample, over all catalogue genomes"
    )
  )
  trace <- list()

  if (length(members)) {
    metrics <- c(metrics, list(.sample_metric_row(
      samples, "community", "community", "assessable_fraction",
      assessable / length(members), "proportion", assessable, length(members),
      assessable, label, version,
      "members of the reference universe at least one detected genome could assess"
    )))
  }

  if (isTRUE(universe$bounded)) {
    readable <- assessable > 0L
    if (any(readable)) {
      metrics <- c(metrics, list(.sample_metric_row(
        samples[readable], "community", "community", "community_coverage",
        richness[readable] / assessable[readable], "proportion",
        richness[readable], assessable[readable], assessable[readable], label,
        version,
        "GIFTs supported by at least one detected genome, over assessable GIFTs in a bounded universe"
      )))
    }
  }

  represented <- richness > 0L
  if (any(represented)) {
    metrics <- c(metrics, list(.sample_metric_row(
      samples[represented], "community", "community", "singleton_fraction",
      singletons[represented] / richness[represented], "proportion",
      singletons[represented], richness[represented], assessable[represented],
      label, version,
      "represented GIFTs with exactly one provider, over represented GIFTs"
    )))
  }

  # Per GIFT per sample, for every GIFT some detected genome supports.
  # provider_count is a presence quantity and abundance_coverage an abundance
  # quantity; they stay separate rows because they answer separate questions
  # and a genome that encodes a capability is not thereby more active for being
  # abundant.
  present <- which(providers > 0, arr.ind = TRUE)
  if (nrow(present)) {
    gift <- members[present[, "row"]]
    sample <- samples[present[, "col"]]
    provider_counts <- providers[present]
    assessor_counts <- assessors[present]
    sample_assessable <- assessable[present[, "col"]]
    metrics <- c(metrics, list(
      .sample_metric_row(
        sample, "gift", gift, "provider_count", provider_counts, "count",
        provider_counts, assessor_counts, sample_assessable, label, version,
        "genomes detected in this sample supporting this GIFT, over those that could assess it"
      ),
      .sample_metric_row(
        sample, "gift", gift, "provider_fraction",
        provider_counts / assessor_counts, "proportion", provider_counts,
        assessor_counts, sample_assessable, label, version,
        "genomes detected in this sample supporting this GIFT, over those that could assess it"
      ),
      .sample_metric_row(
        sample, "gift", gift, "abundance_coverage", coverage[present],
        "proportion", provider_counts, detected_count[present[, "col"]],
        sample_assessable, label, version,
        "share of this sample's detected abundance carried by genomes supporting this GIFT"
      )
    ))
  }

  # Per genome per sample. A genome is the sample's only provider of a GIFT
  # when it supports it and exactly one detected genome does; the mask by
  # detection is what removes the genomes that support it and are not there,
  # for which the single provider is somebody else.
  singleton_gifts <- .numeric_state(providers == 1, providers)
  unique_counts <- crossprod(support_values, singleton_gifts) * detected
  members_present <- which(detected, arr.ind = TRUE)
  if (nrow(members_present)) {
    genome <- genomes[members_present[, "row"]]
    sample <- samples[members_present[, "col"]]
    supported <- gift_richness[members_present[, "row"]]
    unique_to <- unique_counts[members_present]
    metrics <- c(metrics, list(.sample_metric_row(
      sample, "genome", genome, "unique_contribution", unique_to, "count",
      unique_to, supported, assessable[members_present[, "col"]], label,
      version,
      "GIFTs for which this genome is the only provider detected in this sample"
    )))
  }

  # Sample-invariant rows. A genome supports the same GIFTs in every sample it
  # is detected in, and two genomes share the same repertoire wherever both
  # are. Re-emitting either per sample would report the same number once per
  # sample and, for the pair metric, make the quadratic term quadratic again.
  catalogue_metrics <- list(.metric_row(
    "genome", genomes, "gift_richness", gift_richness, "count", gift_richness,
    NA_integer_, sum(rowSums(assessed) > 0L), label, version,
    "supported GIFTs in the reference universe; a property of the genome, so the same in every sample it is detected in"
  ))

  overlap <- NULL
  if (pairwise && length(genomes) > 1L && length(members)) {
    overlap <- .catalogue_overlap(genomes, supports, sum(rowSums(assessed) > 0L),
                                  label, version)
    catalogue_metrics <- c(catalogue_metrics, list(overlap$metrics))
    summary <- .sample_overlap_summary(
      overlap, detected, samples, assessable, label, version
    )
    if (!is.null(summary)) metrics <- c(metrics, list(summary))
  }

  # The catalogue's providers, from which every per-sample trace is recounted.
  # A sample's providers are these intersected with its detected genomes, so
  # the per-sample rows are derivable rather than stored -- the same reasoning,
  # and the same saving, as the `pair_trace = FALSE` default of
  # community_traits().
  catalogue_providers <- which(supports, arr.ind = TRUE)
  if (nrow(catalogue_providers)) {
    trace <- list(tibble::tibble(
      target_type = "gift",
      target_id = members[catalogue_providers[, "row"]],
      metric_id = "provider_count",
      reference_universe = label,
      gift_id = members[catalogue_providers[, "row"]],
      contribution = genomes[catalogue_providers[, "col"]]
    ))
  }

  list(
    metrics = do.call(rbind, metrics),
    catalogue_metrics = do.call(rbind, catalogue_metrics),
    trace = do.call(rbind, trace)
  )
}

# Pairwise repertoire overlap of the catalogue, computed once. The Jaccard
# index of two genomes' repertoires is a property of the two genomes: it does
# not depend on which sample they were seen in, and nothing about a sample can
# change it.
.catalogue_overlap <- function(genomes, supports, assessable, label, version) {
  pairs <- .genome_pairs(length(genomes))
  counts <- .numeric_state(supports, supports)
  shared_counts <- crossprod(counts)
  sizes <- colSums(supports)
  shared <- shared_counts[cbind(pairs$first, pairs$second)]
  union <- sizes[pairs$first] + sizes[pairs$second] - shared
  # Two genomes holding nothing in this universe have an undefined overlap
  # rather than an overlap of zero, exactly as in community_traits(): reporting
  # zero would say they were compared and found to share nothing.
  comparable <- union > 0
  first <- pairs$first[comparable]
  second <- pairs$second[comparable]
  shared <- shared[comparable]
  union <- union[comparable]
  metrics <- if (length(first)) {
    .metric_row(
      "genome_pair", paste(genomes[first], genomes[second], sep = " | "),
      "repertoire_overlap", shared / union, "proportion", shared, union,
      assessable, label, version,
      "Jaccard index of the two genomes' supported GIFTs within this universe; a property of the pair, so the same in every sample both are detected in"
    )
  } else {
    NULL
  }
  list(first = first, second = second, value = shared / union, metrics = metrics)
}

# The one composite in this layer. Its ingredients stay exactly recoverable --
# the pair rows are in `catalogue_metrics` and the detection matrix says which
# of them each sample averaged over -- which is why it is reported at all, and
# the sample-size sensitivity is stated in the derivation rather than hidden.
.sample_overlap_summary <- function(overlap, detected, samples, assessable,
                                    label, version) {
  if (!length(overlap$first)) return(NULL)
  both <- detected[overlap$first, , drop = FALSE] &
    detected[overlap$second, , drop = FALSE]
  pair_count <- colSums(both)
  totals <- colSums(overlap$value * both)
  reportable <- pair_count > 0L
  if (!any(reportable)) return(NULL)
  .sample_metric_row(
    samples[reportable], "community", "community", "mean_repertoire_overlap",
    totals[reportable] / pair_count[reportable], "proportion", NA_integer_,
    pair_count[reportable], assessable[reportable], label, version,
    paste(
      "mean Jaccard index over the pairs of genomes both detected in this",
      "sample whose repertoires within this universe are not both empty;",
      "the terms are the repertoire_overlap rows of catalogue_metrics. A mean",
      "of ratios has no count for a numerator, and it is taken over a larger",
      "pair set in a sample that detected more genomes, so two samples' means",
      "are not comparisons of the same number of things"
    )
  )
}

#' Quantitative traits of one genome catalogue across many samples
#'
#' Reports, per sample, how curated capabilities are distributed across the
#' genomes detected in it, within declared reference universes. Nothing is
#' re-evaluated and nothing changes a call: the catalogue is read once, and a
#' sample is a restriction of that reading to its detected genomes and a
#' reweighting by their abundance.
#'
#' Metrics reported per sample per universe, in `metrics`:
#'
#' \describe{
#'   \item{`community_richness`}{GIFTs supported by at least one detected
#'     genome}
#'   \item{`community_coverage`}{richness over assessable members, for bounded
#'     universes only}
#'   \item{`mean_genome_richness`}{reported beside community richness rather
#'     than divided into it, so both components stay visible}
#'   \item{`detected_genomes`}{catalogue genomes detected in this sample, over
#'     all catalogue genomes}
#'   \item{`assessable_fraction`}{members of the universe at least one detected
#'     genome could assess}
#'   \item{`singleton_fraction`}{represented GIFTs with exactly one provider}
#'   \item{`provider_count`, `provider_fraction`}{per GIFT, the detected
#'     genomes supporting it, and that count over the detected genomes that
#'     could assess it}
#'   \item{`abundance_coverage`}{per GIFT, the share of the sample's detected
#'     abundance those genomes carry}
#'   \item{`unique_contribution`}{per genome, the GIFTs it alone provides in
#'     this sample}
#'   \item{`mean_repertoire_overlap`}{the one composite; see below}
#' }
#'
#' Metrics reported once, in `catalogue_metrics`:
#'
#' \describe{
#'   \item{`gift_richness`}{per genome, its supported GIFTs in the universe}
#'   \item{`repertoire_overlap`}{per genome pair, the Jaccard index of their
#'     supported GIFTs}
#' }
#'
#' @section Two tables, not one nullable column:
#'
#' A genome supports the same GIFTs in every sample it is detected in, and two
#' genomes share the same repertoire wherever both are detected. Those rows
#' cannot vary between samples, so they are not given a `sample_id` column that
#' would always be empty: the absence of the column is the claim. Read either
#' for one sample by restricting it to that sample's detected genomes, which
#' `as.data.frame()` and [trace_sample()] both do for you.
#'
#' The `assessable` column of a `catalogue_metrics` row counts what the whole
#' catalogue could assess, since that row belongs to no sample. The metric
#' itself --- `value`, `numerator`, `denominator` --- is what [community_traits()]
#' reports for the same genome or pair in any sample.
#'
#' @section Detection:
#'
#' Detection is to samples what assessability is to genomes: both may only move
#' denominators. Assessability decides whether a genome's silence about a GIFT
#' is informative; detection decides whether a genome is part of a sample's
#' community at all. Neither may promote an unsupported GIFT to supported,
#' neither may change a call, and both are resolved per genome.
#'
#' A genome absent from a sample may be below detection rather than genuinely
#' absent, and gifter models no sequencing depth, library size or detection
#' limit. Nothing here imputes one, corrects for one, or rarefies. Every
#' sample-level richness is reported beside `detected_genomes` instead, so a
#' richness of 40 over 31 detected genomes is not read as the same result as a
#' richness of 40 over 207.
#'
#' @section Abundance closure:
#'
#' Abundance is closed within each sample's **detected** set, after detection
#' has been applied, so `abundance_coverage` is a share of the community
#' actually being described. At `detection = 0` this is the same as closing over
#' the whole catalogue; above it, it is not, and deliberately so. Once a reader
#' has declared that a genome below the threshold is not part of the community,
#' leaving its abundance in the denominator would report a share of a community
#' that same reader just said does not include it.
#'
#' @section What these numbers may not say:
#'
#' `abundance_coverage` is the share of observed genome abundance carrying a
#' capability. It is not a share of activity, transcript production, flux or
#' effect, which is why it never merges with `provider_count`. A GIFT whose
#' carriers are more abundant in one group of samples has not been shown to be
#' more active, more expressed or more important there.
#'
#' gifter runs no hypothesis test, differential-abundance analysis, ordination
#' or effect size between groups of samples, and interprets no metadata column.
#' The design, the contrasts and the multiple-testing correction are the
#' analyst's. What gifter contributes instead is an assessability-aware matrix
#' with a declared reference universe --- see [gift_matrix()] and
#' [dataset_matrix()] --- in which a genome's silence about a capability it was
#' never well enough observed to assess is `NA` rather than a fabricated zero.
#'
#' @section The one composite:
#'
#' `mean_repertoire_overlap` is a mean of ratios, so it has no count for a
#' numerator and reports `NA` there; its denominator is the comparable pairs
#' both of whose genomes the sample detected. It is reported because its terms
#' stay exactly recoverable from `catalogue_metrics` and the detection set,
#' which is a stronger guarantee than a trace table gives. It is taken over a
#' larger pair set in a sample that detected more genomes, so two samples' means
#' are not comparisons over the same number of pairs. `pairwise = FALSE` drops
#' it and the pair rows together.
#'
#' @section The trace:
#'
#' `trace` records the catalogue's providers: which genomes support each GIFT,
#' per universe. Every per-sample trace is a recount over those rows restricted
#' to the sample's detected genomes, which is what [trace_sample()] does, so
#' per-sample rows are derivable rather than stored. This is the same reasoning
#' as the `pair_trace = FALSE` default of [community_traits()]: the rows are
#' identical either way, and what is at stake is only whether a multiple of them
#' is carried around by default.
#'
#' @param dataset A dataset from [gifter_dataset()].
#' @param universes Optional list of [gift_universe()] objects. The default set
#'   is used if omitted.
#' @param quality,policy,threshold,min_confidence Assessability, on exactly the
#'   terms of [community_traits()]. These are properties of a genome, so they
#'   are applied once to the catalogue before any sample is read.
#' @param detection Abundance a genome must exceed to be a member of a sample's
#'   community. `0` by default, meaning observed at all. A sample in which no
#'   genome exceeds it is refused, naming it.
#' @param pairwise Whether to report `repertoire_overlap` and its per-sample
#'   summary. `TRUE` by default. It is the one quadratic metric, and unlike in
#'   [community_traits()] it is paid once rather than once per sample.
#' @param db Optional open gifter database connection.
#' @param progress Whether to display a progress bar over the reference
#'   universes. Reference universes remain the unit, because the sample loop is
#'   vectorized away.
#' @return A `gifter_dataset_traits` list with `metrics`, `catalogue_metrics`,
#'   `trace`, and the metadata, detection and assessability the reading used.
#' @export
dataset_traits <- function(dataset, universes = NULL, quality = NULL,
                           policy = "none", threshold = NULL,
                           min_confidence = NULL, detection = 0,
                           pairwise = TRUE, db = NULL, progress = NULL) {
  if (!inherits(dataset, "gifter_dataset")) {
    stop("dataset must come from gifter_dataset()", call. = FALSE)
  }
  .check_progress(progress)
  if (!isTRUE(pairwise) && !isFALSE(pairwise)) {
    stop("pairwise must be TRUE or FALSE", call. = FALSE)
  }
  detection <- .normalize_detection(detection)
  min_confidence <- .normalize_min_confidence(min_confidence)
  # Assessability is a property of a genome, so it is settled against the
  # catalogue once, before any sample is read. Reading it per sample would let
  # the same genome be assessable in one sample and not in another, which is
  # not a thing a genome can be.
  catalogue <- dataset$catalogue
  threshold <- .normalize_threshold(threshold)
  policy <- .resolve_policy(policy, quality, threshold)
  completeness <- .normalize_quality(quality, catalogue$genome_id)
  calls <- .assessable_matrix(catalogue$matrix, policy, completeness, threshold)
  if (!is.null(min_confidence)) {
    confidence <- .community_confidence(catalogue$results, catalogue$gift_id)
    calls <- .confidence_state(
      calls, confidence[rownames(calls), colnames(calls)], min_confidence
    )
  }
  detected <- .detection_matrix(dataset$abundance, detection)
  weights <- .closed_abundance(dataset$abundance, detected)

  .with_gifter_db(db, function(connection) {
    version <- gifter_db_version(connection)$gifter_db_version
    dataset_version <- .gifter_database_version_value(dataset$database_version)
    if (!identical(version, dataset_version)) {
      stop(
        "The dataset was evaluated against database version ", dataset_version,
        " but the supplied connection serves ", version, ".",
        call. = FALSE
      )
    }
    if (is.null(universes)) universes <- .default_universes(connection)
    if (!is.list(universes) || !length(universes) ||
        !all(vapply(universes, inherits, logical(1), "gifter_universe"))) {
      stop(
        "universes must be a non-empty list of gift_universe() objects",
        call. = FALSE
      )
    }
    stale <- vapply(
      universes, function(u) !identical(u$database_version, version), logical(1)
    )
    if (any(stale)) {
      stop("Universes were built against a different database version", call. = FALSE)
    }

    display <- .universe_progress(
      length(universes), .resolve_progress(progress, length(universes))
    )
    on.exit(display$dismiss(), add = TRUE)
    parts <- vector("list", length(universes))
    for (index in seq_along(universes)) {
      parts[[index]] <- .dataset_universe_metrics(
        dataset, universes[[index]], version, calls, detected, weights, pairwise
      )
      display$update(index)
    }
    display$done()

    metrics <- do.call(rbind, lapply(parts, function(part) part$metrics))
    catalogue_metrics <- do.call(
      rbind, lapply(parts, function(part) part$catalogue_metrics)
    )
    trace <- do.call(rbind, lapply(parts, function(part) part$trace))
    if (is.null(metrics)) metrics <- .empty_dataset_metrics()
    if (is.null(catalogue_metrics)) catalogue_metrics <- .empty_metrics()
    if (is.null(trace)) trace <- .empty_trace()
    # One assessable_fraction per sample per universe, so the thin readings are
    # counted in those rather than in universes.
    .warn_thin_denominators(metrics, "sample-universe readings")

    structure(
      list(
        metrics = metrics[.dataset_metric_columns()],
        catalogue_metrics = catalogue_metrics[.metric_columns],
        trace = trace[.trace_columns],
        universes = universes,
        sample_id = dataset$sample_id,
        genome_id = dataset$genome_id,
        metadata = dataset$metadata,
        detection = detection,
        detected = detected,
        calls = calls,
        abundance = weights,
        assessability = list(
          policy = policy, threshold = threshold, completeness = completeness
        ),
        database_version = dataset$database_version
      ),
      class = c("gifter_dataset_traits", "list")
    )
  })
}

#' @export
sample_id.gifter_dataset_traits <- function(x, ...) x$sample_id

#' @export
print.gifter_dataset_traits <- function(x, ...) {
  cat(
    "<gifter_dataset_traits>", length(x$genome_id), "genomes x",
    length(x$sample_id), "samples\n"
  )
  cat(
    "  metrics: ", nrow(x$metrics), " sample rows and ",
    nrow(x$catalogue_metrics), " sample-invariant rows across ",
    length(x$universes), " reference universes\n", sep = ""
  )
  cat("  detection:", format(x$detection), "\n")
  cat("  database version:", .gifter_database_version_value(x$database_version), "\n")
  headline <- x$metrics[
    x$metrics$metric_id == "community_richness" &
      x$metrics$reference_universe == x$universes[[1L]]$label, ,
    drop = FALSE
  ]
  detected <- x$metrics[
    x$metrics$metric_id == "detected_genomes" &
      x$metrics$reference_universe == x$universes[[1L]]$label, ,
    drop = FALSE
  ]
  if (nrow(headline)) {
    cat("\n  ", headline$reference_universe[[1L]], "\n", sep = "")
    shown <- seq_len(min(nrow(headline), 6L))
    for (index in shown) {
      cat(sprintf(
        "  %-24s %3d / %3d supported, %3d genomes detected\n",
        headline$sample_id[[index]], as.integer(headline$value[[index]]),
        headline$assessable[[index]],
        as.integer(detected$value[[index]])
      ))
    }
    if (nrow(headline) > length(shown)) {
      cat("  ... (", nrow(headline) - length(shown), " more samples)\n", sep = "")
    }
  }
  invisible(x)
}

#' The GIFTs and genomes behind one sample's traits
#'
#' Derives the trace rows for one sample. A sample's providers are the
#' catalogue's providers intersected with its detected genomes, so the rows are
#' recounted on demand rather than stored once per sample --- the same reasoning
#' as the `pair_trace = FALSE` default of [community_traits()], and with the
#' same result: the rows are identical either way.
#'
#' The rows returned are what [community_traits()] records for
#' [sample_community()] of the same sample.
#'
#' @param traits A `gifter_dataset_traits` from [dataset_traits()].
#' @param sample One sample identifier.
#' @return A tibble of trace rows naming the GIFTs and genomes behind that
#'   sample's `community_richness`, `singleton_fraction`, `provider_count` and
#'   `unique_contribution`.
#' @export
trace_sample <- function(traits, sample) {
  if (!inherits(traits, "gifter_dataset_traits")) {
    stop("traits must come from dataset_traits()", call. = FALSE)
  }
  if (!is.character(sample) || length(sample) != 1L || is.na(sample)) {
    stop("sample must be one sample identifier", call. = FALSE)
  }
  if (!sample %in% traits$sample_id) {
    stop(
      "The traits hold no sample called ", sample, ". They name: ",
      .abbreviate_ids(traits$sample_id),
      call. = FALSE
    )
  }
  genomes <- traits$genome_id[traits$detected[, sample]]
  parts <- lapply(traits$universes, function(universe) {
    members <- intersect(rownames(traits$calls), universe$gift_id)
    state <- traits$calls[members, genomes, drop = FALSE]
    supports <- .logical_state(state %in% TRUE, state)
    provider_count <- if (length(members)) rowSums(supports) else integer()
    label <- universe$label
    represented <- members[provider_count > 0L]
    rows <- list(
      .trace_rows("community", "community", "community_richness", label, represented)
    )
    if (length(represented)) {
      rows <- c(rows, list(.trace_rows(
        "community", "community", "singleton_fraction", label,
        members[provider_count == 1L]
      )))
      providers <- which(supports, arr.ind = TRUE)
      rows <- c(rows, list(tibble::tibble(
        target_type = "gift", target_id = members[providers[, "row"]],
        metric_id = "provider_count", reference_universe = label,
        gift_id = members[providers[, "row"]],
        contribution = genomes[providers[, "col"]]
      )))
    }
    for (genome in genomes) {
      supported <- members[supports[, genome]]
      rows <- c(rows, list(.trace_rows(
        "genome", genome, "unique_contribution", label,
        supported[provider_count[supported] == 1L]
      )))
    }
    do.call(rbind, rows)
  })
  trace <- do.call(rbind, parts)
  if (is.null(trace)) trace <- .empty_trace()
  trace[.trace_columns]
}
