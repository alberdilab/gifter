# The export surface: the objects an external statistics package needs.
#
# gifter computes per-sample traits and stops there. It runs no hypothesis
# test, no differential-abundance analysis, no ordination and no effect size
# between groups of samples, and it interprets no metadata column. The design,
# the contrasts and the multiple-testing correction are the analyst's, and a
# group label multiplied through a call matrix and presented as a gifter
# inference would be the user's assumption wearing gifter's name -- which is
# already refused, as §8 refusal 3 of the quantitative traits proposal.
#
# What gifter uniquely has to give those packages is the thing this file
# exports: an assessability-aware matrix with a declared reference universe, in
# which a genome's silence about a capability it was never well enough observed
# to assess is NA rather than a fabricated zero. Every model fitted on a
# fabricated zero inherits the fabrication, and nothing downstream can see it.

#' The three-state call matrix, for export
#'
#' Returns which genomes support which GIFTs, in the three states the
#' assessability layer distinguishes: `TRUE` supported, `FALSE` confidently
#' unsupported, and `NA` indeterminate --- the markers do not support a complete
#' implementation, and the policy declines to read that as absence.
#'
#' This is the object to hand to an external statistics package. The `NA` is the
#' point of it: a genome that was never fully observed has not been shown to
#' lack anything, and a `0` in its place is a fabricated absence that every
#' model fitted on the matrix will inherit.
#'
#' @section Orientation:
#'
#' Rows are genomes and columns are GIFTs, because rows are observations in the
#' packages that receive it. This is the transpose of the matrix a
#' `gifter_community` holds internally.
#'
#' @section What the matrix is not:
#'
#' A supported call means the observed markers support at least one complete
#' curated implementation. It does not mean expression, activity, flux,
#' physiological state or phenotype, and no arrangement of the matrix makes it
#' mean any of those. The reference universe and database version are carried as
#' attributes so that a matrix exported from one release is not silently
#' compared with one from another.
#'
#' @param x A `gifter_community` or a `gifter_dataset`. A dataset delegates to
#'   its catalogue: calls are a property of a genome, so a dataset has exactly
#'   one call matrix and no sample can change it.
#' @param universe Optional [gift_universe()] restricting the columns. Omitted,
#'   every GIFT the evaluation produced is a column.
#' @param quality,policy,threshold,min_confidence Assessability, on the terms of
#'   [community_traits()]. With the default policy nothing is indeterminate and
#'   the matrix is Boolean, which is stated in the `assessability_policy`
#'   attribute rather than implied.
#' @return A logical genomes by GIFTs matrix with `reference_universe`,
#'   `database_version` and `assessability_policy` attributes.
#' @examples
#' donor <- evaluate_gifts(data.frame(
#'   gene_id = "g1", namespace = "KO", accession = "K01198"
#' ))
#' recipient <- evaluate_gifts(data.frame(
#'   gene_id = "g1", namespace = "KO", accession = "K01805"
#' ))
#' community <- gifter_community(donor = donor, recipient = recipient)
#' matrix <- gift_matrix(community)
#' dim(matrix)
#' @export
gift_matrix <- function(x, universe = NULL, quality = NULL, policy = "none",
                        threshold = NULL, min_confidence = NULL) {
  community <- if (inherits(x, "gifter_dataset")) {
    x$catalogue
  } else if (inherits(x, "gifter_community")) {
    x
  } else {
    stop(
      "gift_matrix() needs a gifter_community or a gifter_dataset",
      call. = FALSE
    )
  }
  version <- .gifter_database_version_value(community$database_version)
  label <- "every GIFT evaluated"
  members <- community$gift_id
  if (!is.null(universe)) {
    if (!inherits(universe, "gifter_universe")) {
      stop("universe must come from gift_universe()", call. = FALSE)
    }
    # A universe carries its release as a plain version string, as
    # gift_universe() built it; a community carries the whole release row.
    if (!identical(universe$database_version, version)) {
      stop(
        "The universe was built against a different database version",
        call. = FALSE
      )
    }
    label <- universe$label
    members <- intersect(members, universe$gift_id)
  }
  min_confidence <- .normalize_min_confidence(min_confidence)
  threshold <- .normalize_threshold(threshold)
  policy <- .resolve_policy(policy, quality, threshold)
  completeness <- .normalize_quality(quality, community$genome_id)
  calls <- .assessable_matrix(community$matrix, policy, completeness, threshold)
  if (!is.null(min_confidence)) {
    confidence <- .community_confidence(community$results, community$gift_id)
    calls <- .confidence_state(
      calls, confidence[rownames(calls), colnames(calls)], min_confidence
    )
  }
  matrix <- t(calls[members, , drop = FALSE])
  attr(matrix, "reference_universe") <- label
  attr(matrix, "database_version") <- version
  attr(matrix, "assessability_policy") <- policy
  matrix
}

#' One metric of a dataset as a samples by target matrix
#'
#' Reshapes one metric of [dataset_traits()] into the shape an ordination or a
#' distance function expects: one row per sample, one column per GIFT or genome
#' the metric was reported for.
#'
#' @section Absent cells are not zeros:
#'
#' A metric is reported only where it exists. `provider_count` has no row for a
#' GIFT no genome in a sample supports, and whether that is a true zero or a
#' GIFT nothing in that sample could assess is exactly the distinction the
#' assessability layer exists to keep. The cell is therefore `NA` by default and
#' gifter does not guess. `fill = 0` is available for the caller who knows what
#' the absence means for their metric --- and it is then the caller's claim.
#'
#' @param traits A `gifter_dataset_traits` from [dataset_traits()].
#' @param metric_id One metric identifier.
#' @param universe Reference universe label. Required whenever the metric was
#'   reported for more than one, because stacking a metric across universes
#'   puts columns with different denominators side by side.
#' @param fill Value for a cell the metric was not reported for. `NA` by
#'   default.
#' @return A numeric matrix with samples as rows, carrying `metric_id`,
#'   `reference_universe` and `database_version` attributes.
#' @export
dataset_matrix <- function(traits, metric_id, universe = NULL, fill = NA) {
  if (!inherits(traits, "gifter_dataset_traits")) {
    stop("traits must come from dataset_traits()", call. = FALSE)
  }
  if (!is.character(metric_id) || length(metric_id) != 1L || is.na(metric_id)) {
    stop("metric_id must be one metric identifier", call. = FALSE)
  }
  rows <- traits$metrics[traits$metrics$metric_id == metric_id, , drop = FALSE]
  if (!nrow(rows)) {
    stop(
      "No metric called ", metric_id, " was reported. The metrics hold: ",
      .abbreviate_ids(sort(unique(traits$metrics$metric_id)), 10L),
      call. = FALSE
    )
  }
  universes <- unique(rows$reference_universe)
  if (is.null(universe)) {
    if (length(universes) > 1L) {
      stop(
        metric_id, " was reported for ", length(universes),
        " reference universes, and their denominators are not the same set. ",
        "Name one: ", .abbreviate_ids(sort(universes), 10L),
        call. = FALSE
      )
    }
    universe <- universes
  } else {
    if (!universe %in% universes) {
      stop(
        metric_id, " was not reported for the reference universe ", universe,
        ". It was reported for: ", .abbreviate_ids(sort(universes), 10L),
        call. = FALSE
      )
    }
    rows <- rows[rows$reference_universe == universe, , drop = FALSE]
  }
  samples <- traits$sample_id
  targets <- unique(rows$target_id)
  matrix <- matrix(
    fill, nrow = length(samples), ncol = length(targets),
    dimnames = list(samples, targets)
  )
  matrix[cbind(
    match(rows$sample_id, samples), match(rows$target_id, targets)
  )] <- rows$value
  attr(matrix, "metric_id") <- metric_id
  attr(matrix, "reference_universe") <- universe
  attr(matrix, "database_version") <-
    .gifter_database_version_value(traits$database_version)
  matrix
}

#' Per-sample metrics joined to sample metadata
#'
#' Returns the per-sample metric table with the dataset's metadata columns
#' beside it, ready to be handed to an external statistics package. gifter
#' interprets none of those columns: a group, a timepoint or a treatment is the
#' analyst's, and so is every test run on it.
#'
#' The join neither drops nor duplicates a sample, which [gifter_dataset()]
#' makes provable rather than hoped for by requiring the metadata to cover
#' exactly the samples the abundance names.
#'
#' Sample-invariant rows --- `gift_richness` and `repertoire_overlap` --- are
#' not included, because they belong to no sample. They are in
#' `traits$catalogue_metrics`.
#'
#' @param x A `gifter_dataset_traits` from [dataset_traits()].
#' @param row.names,optional Ignored; present for the generic.
#' @param ... Unused.
#' @return A data frame of the per-sample metrics with the metadata columns
#'   appended.
#' @export
as.data.frame.gifter_dataset_traits <- function(x, row.names = NULL,
                                                optional = FALSE, ...) {
  frame <- as.data.frame(x$metrics, stringsAsFactors = FALSE)
  if (!is.null(x$metadata)) {
    columns <- setdiff(names(x$metadata), "sample_id")
    if (length(columns)) {
      extra <- as.data.frame(
        x$metadata[, columns, drop = FALSE], stringsAsFactors = FALSE
      )
      frame <- cbind(
        frame,
        extra[match(frame$sample_id, x$metadata$sample_id), , drop = FALSE]
      )
    }
  }
  rownames(frame) <- NULL
  frame
}
