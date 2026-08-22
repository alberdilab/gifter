# One genome catalogue observed across many samples.
#
# A call is a property of a genome. `evaluate_gifts()` reads markers; it has
# never seen a sample and cannot. So across a dataset exactly two things vary:
# which genomes are members of a sample's community, and how much of that
# sample each one represents. Both are per genome, neither can change a call,
# and neither may promote an unsupported GIFT to supported.
#
# That is why a dataset is composed of a community rather than replacing one.
# The catalogue is evaluated once and holds one call matrix; the dataset adds
# an abundance matrix over the same genomes and nothing else. The mixed-release
# refusal, the distinct-name requirement and the `gifter_genome` membership
# check are inherited rather than reimplemented, and `sample_community()` hands
# any existing function an ordinary community, so nothing in the package needs
# a dataset-aware variant to keep working on one sample.
#
# Detection is to samples what assessability is to genomes. Both may only move
# denominators: assessability decides whether a genome's silence about a GIFT
# is informative, detection decides whether a genome is part of a sample's
# community at all, and both are resolved per genome. A detection threshold is
# therefore a reading of an abundance rather than a property of one, which is
# why it belongs to the readers -- dataset_traits(), dataset_network(),
# sample_community() -- and not to the container, on exactly the terms that put
# `threshold` on community_traits() rather than on gifter_community().
#
# Nothing is normalised here. The abundances are kept as they were supplied,
# because a reader may want them back, and closure happens at read time after
# detection has been applied.
#
# The design record is inst/doc/proposal-multi-sample-datasets.md.

# The abundance matrix, in the two shapes users actually hold, reduced to one.
#
# The canonical shape is a genome x sample numeric matrix carrying both sets of
# identifiers. A long data frame is accepted too, because that is what coverM
# and its relatives emit, and is pivoted to the same matrix -- so that no metric
# anywhere depends on which shape was supplied.
.as_abundance_matrix <- function(abundance) {
  if (is.data.frame(abundance)) {
    long <- c("sample_id", "genome_id", "abundance")
    if (all(long %in% names(abundance))) return(.pivot_abundance(abundance))
    if (!is.character(attr(abundance, "row.names"))) {
      stop(
        "abundance is a data frame with neither genome identifiers in its row ",
        "names nor `sample_id`, `genome_id` and `abundance` columns, so there ",
        "is nothing to say which genome each value belongs to. Supply a ",
        "genome x sample matrix with both dimnames, or the long form with ",
        "those three columns",
        call. = FALSE
      )
    }
    numeric_column <- vapply(abundance, is.numeric, logical(1))
    if (!all(numeric_column)) {
      stop(
        "abundance must be numeric; these columns are not: ",
        paste(names(abundance)[!numeric_column], collapse = ", "),
        call. = FALSE
      )
    }
    return(as.matrix(abundance))
  }
  abundance
}

# The long form pivoted. Rectangularity is required rather than assumed: an
# absent row and a true zero are indistinguishable once the pivot has happened,
# and a row dropped by a failed join takes an abundant genome out of a sample's
# community where nothing downstream can notice. Completing the table is one
# call the caller can make and gifter cannot make for them.
.pivot_abundance <- function(long) {
  if (!is.numeric(long$abundance)) {
    stop("abundance must be a numeric column", call. = FALSE)
  }
  samples <- as.character(long$sample_id)
  genomes <- as.character(long$genome_id)
  if (anyNA(samples) || anyNA(genomes) || !all(nzchar(samples)) ||
      !all(nzchar(genomes))) {
    stop(
      "`sample_id` and `genome_id` must name every row of the long form",
      call. = FALSE
    )
  }
  duplicated_pairs <- duplicated(paste(samples, genomes, sep = "\r"))
  if (any(duplicated_pairs)) {
    first <- which(duplicated_pairs)[[1L]]
    stop(
      "abundance names the same genome twice in one sample: ",
      genomes[[first]], " in ", samples[[first]],
      ". Two abundances for one genome in one sample are not summed, because ",
      "a repeated row is more often a failed join than a measurement",
      call. = FALSE
    )
  }
  sample_levels <- unique(samples)
  genome_levels <- unique(genomes)
  expected <- length(sample_levels) * length(genome_levels)
  if (nrow(long) != expected) {
    missing <- .first_missing_pair(samples, genomes, sample_levels, genome_levels)
    stop(
      "The long form of abundance must carry a row for every genome in every ",
      "sample, and ", expected - nrow(long), " of ", expected,
      " are absent, beginning with genome ", missing[["genome_id"]],
      " in sample ", missing[["sample_id"]],
      ". An absent row and an abundance of zero are indistinguishable after ",
      "the pivot, so gifter will not read one as the other; complete the ",
      "table, as tidyr::complete(abundance, sample_id, genome_id, ",
      "fill = list(abundance = 0))",
      call. = FALSE
    )
  }
  matrix <- matrix(
    NA_real_, nrow = length(genome_levels), ncol = length(sample_levels),
    dimnames = list(genome_levels, sample_levels)
  )
  matrix[cbind(
    match(genomes, genome_levels), match(samples, sample_levels)
  )] <- as.numeric(long$abundance)
  matrix
}

# Which genome is missing from which sample, so that the error names a row the
# caller can go and look for rather than a count they have to hunt through.
.first_missing_pair <- function(samples, genomes, sample_levels, genome_levels) {
  present <- matrix(
    FALSE, nrow = length(genome_levels), ncol = length(sample_levels),
    dimnames = list(genome_levels, sample_levels)
  )
  present[cbind(match(genomes, genome_levels), match(samples, sample_levels))] <- TRUE
  absent <- which(!present, arr.ind = TRUE)
  c(
    genome_id = genome_levels[[absent[1L, "row"]]],
    sample_id = sample_levels[[absent[1L, "col"]]]
  )
}

# The matrix checked against the genomes it weights and returned in their order.
# Position is not a substitute for an identifier here any more than it is in
# .normalize_abundance(): the genomes a positional matrix would be aligned
# against come from the catalogue, and a silent off-by-one credits one genome's
# abundance to another.
.check_abundance_matrix <- function(abundance, genomes) {
  if (!is.matrix(abundance) || !is.numeric(abundance)) {
    stop(
      "abundance must be a genome x sample numeric matrix, or a long data ",
      "frame with `sample_id`, `genome_id` and `abundance` columns",
      call. = FALSE
    )
  }
  if (is.null(rownames(abundance)) || is.null(colnames(abundance))) {
    stop(
      "abundance must carry both genome identifiers in its row names and ",
      "sample identifiers in its column names. Position is not a substitute: ",
      "the genomes it would be aligned against come from the catalogue, and a ",
      "silent off-by-one credits one genome's abundance to another",
      call. = FALSE
    )
  }
  if (!ncol(abundance)) {
    stop("abundance must name at least one sample", call. = FALSE)
  }
  samples <- colnames(abundance)
  if (anyNA(samples) || !all(nzchar(samples))) {
    stop("Every sample must carry a non-empty identifier", call. = FALSE)
  }
  if (anyDuplicated(samples)) {
    stop(
      "abundance names the same sample twice: ",
      paste(unique(samples[duplicated(samples)]), collapse = ", "),
      call. = FALSE
    )
  }
  if (anyDuplicated(rownames(abundance))) {
    stop(
      "abundance names the same genome twice: ",
      paste(unique(rownames(abundance)[duplicated(rownames(abundance))]),
            collapse = ", "),
      call. = FALSE
    )
  }
  # A catalogue genome missing from the matrix is an error, not a silent zero.
  # Both directions are almost always a failed join between a quality table and
  # a mapping table, and a silent zero turns that mistake into a genome that is
  # simply never detected anywhere -- which is indistinguishable from a real
  # biological result.
  missing <- setdiff(genomes, rownames(abundance))
  unexpected <- setdiff(rownames(abundance), genomes)
  if (length(missing) || length(unexpected)) {
    stop(
      "abundance must name exactly the catalogue's genomes",
      if (length(missing)) {
        paste0("; missing: ", paste(missing, collapse = ", "))
      } else "",
      if (length(unexpected)) {
        paste0("; not in the catalogue: ", paste(unexpected, collapse = ", "))
      } else "",
      call. = FALSE
    )
  }
  abundance <- abundance[genomes, , drop = FALSE]
  if (anyNA(abundance) || any(!is.finite(abundance))) {
    stop(
      "abundance must be finite and complete: an unobserved genome in a ",
      "sample is an abundance of zero, and NA says instead that nothing is ",
      "known, which gifter will not guess at",
      call. = FALSE
    )
  }
  if (any(abundance < 0)) {
    stop("abundance must be non-negative", call. = FALSE)
  }
  # No threshold can ever detect a genome in an all-zero sample, so it is
  # refused once here rather than at every reading.
  empty <- samples[colSums(abundance) <= 0]
  if (length(empty)) {
    stop(
      "These samples carry no abundance at all, so no genome is detected in ",
      "them at any threshold: ", paste(empty, collapse = ", "),
      call. = FALSE
    )
  }
  abundance
}

# Sample metadata, covering exactly the samples and interpreted by nothing.
# Group labels, timepoints, treatments and covariates are carried through
# untouched: gifter emits traits joined to them and takes no position on what
# they mean, which is what keeps a group contrast the analyst's inference
# rather than gifter's.
.check_sample_metadata <- function(metadata, samples) {
  if (is.null(metadata)) return(NULL)
  if (!is.data.frame(metadata)) {
    stop("metadata must be a data frame with a `sample_id` column", call. = FALSE)
  }
  if (!"sample_id" %in% names(metadata)) {
    stop("metadata must have a `sample_id` column", call. = FALSE)
  }
  ids <- as.character(metadata$sample_id)
  if (anyNA(ids) || !all(nzchar(ids))) {
    stop("Every metadata row must carry a non-empty `sample_id`", call. = FALSE)
  }
  if (anyDuplicated(ids)) {
    stop(
      "metadata names the same sample twice: ",
      paste(unique(ids[duplicated(ids)]), collapse = ", "),
      call. = FALSE
    )
  }
  missing <- setdiff(samples, ids)
  unexpected <- setdiff(ids, samples)
  if (length(missing) || length(unexpected)) {
    stop(
      "metadata must cover exactly the samples abundance names",
      if (length(missing)) {
        paste0("; missing: ", paste(missing, collapse = ", "))
      } else "",
      if (length(unexpected)) {
        paste0("; not in abundance: ", paste(unexpected, collapse = ", "))
      } else "",
      call. = FALSE
    )
  }
  metadata <- metadata[match(samples, ids), , drop = FALSE]
  metadata$sample_id <- samples
  rownames(metadata) <- NULL
  tibble::as_tibble(metadata)
}

# A detection threshold is one non-negative number. A negative one would detect
# a genome whose abundance is zero, which is a claim that an unobserved genome
# is a community member.
.normalize_detection <- function(detection) {
  if (!is.numeric(detection) || length(detection) != 1L || is.na(detection) ||
      !is.finite(detection)) {
    stop("detection must be one finite number", call. = FALSE)
  }
  if (detection < 0) {
    stop(
      "detection must be non-negative: a negative threshold would make a ",
      "genome of zero abundance a member of the community",
      call. = FALSE
    )
  }
  as.numeric(detection)
}

# Which genomes are members of which sample's community. Strictly greater, so
# that the default of zero means "observed at all" rather than "not absent".
.detection_matrix <- function(abundance, detection) {
  detected <- abundance > detection
  dimnames(detected) <- dimnames(abundance)
  empty <- colnames(detected)[colSums(detected) == 0L]
  if (length(empty)) {
    stop(
      "No genome is detected above detection = ", format(detection),
      " in these samples: ", paste(empty, collapse = ", "),
      ". A community of no genomes has no richness and no denominator, so ",
      "gifter reports nothing for it rather than reporting NA",
      call. = FALSE
    )
  }
  detected
}

# Abundance closed within each sample's detected set, after detection.
#
# This differs from closing over the whole catalogue as soon as detection is
# above zero, and the difference is the point: once a reader has declared that a
# genome below the threshold is not part of the community, leaving its abundance
# in the denominator would report a share of a community that same reader just
# said does not include it.
.closed_abundance <- function(abundance, detected) {
  weights <- abundance
  weights[!detected] <- 0
  totals <- colSums(weights)
  weights <- sweep(weights, 2L, totals, "/")
  dimnames(weights) <- dimnames(abundance)
  weights
}

#' One genome catalogue observed across many samples
#'
#' Binds an evaluated genome catalogue to a genome by sample abundance matrix,
#' so that quantitative traits can be reported per sample without evaluating
#' any genome more than once. Nothing is re-evaluated and nothing changes a
#' call: a call is a property of a genome, and across a dataset only which
#' genomes are members of a sample and how much of it they represent can vary.
#'
#' @section Detection is to samples what assessability is to genomes:
#'
#' Both may only move denominators. Assessability decides whether a genome's
#' silence about a GIFT is informative; detection decides whether a genome is
#' part of a sample's community at all. Neither may promote an unsupported GIFT
#' to supported, neither may change a call, and both are resolved per genome.
#'
#' A detection threshold is therefore a way of reading an abundance rather than
#' a property of one, and is supplied to the readers --- [dataset_traits()],
#' [sample_community()] --- rather than here, on exactly the terms that put
#' `threshold` on [community_traits()] rather than on [gifter_community()]. One
#' dataset can then be read at two thresholds without being rebuilt.
#'
#' @section What a dataset does not hold:
#'
#' A dataset holds membership evidence and weights. It holds no detection
#' threshold, no assessability policy, no completeness table, no confidence
#' floor, and no group label, design or hypothesis. The first four are readings
#' and belong to [dataset_traits()]. The last three are the analyst's: gifter
#' carries metadata columns through untouched and interprets none of them, and
#' runs no test, ordination or effect size between groups of samples.
#'
#' @section Absence below detection:
#'
#' A genome absent from a sample may be below detection rather than genuinely
#' absent, and gifter models no sequencing depth, library size or detection
#' limit. Nothing here imputes one. [dataset_traits()] reports
#' `detected_genomes` beside every sample-level richness instead, so that a
#' richness of 40 over 31 detected genomes is not read as the same result as a
#' richness of 40 over 207.
#'
#' @param catalogue A `gifter_community` from [gifter_community()] or
#'   [evaluate_gifts_community()], holding every genome the samples were mapped
#'   against.
#' @param abundance A genome by sample numeric matrix carrying genome
#'   identifiers in its row names and sample identifiers in its column names,
#'   or a long data frame with `sample_id`, `genome_id` and `abundance`
#'   columns. The long form must carry a row for every genome in every sample:
#'   an absent row and an abundance of zero are indistinguishable after the
#'   pivot, so gifter refuses to read one as the other. Values must be finite
#'   and non-negative, the genomes must be exactly the catalogue's, and no
#'   sample may be entirely zero.
#' @param metadata Optional data frame with a `sample_id` column covering
#'   exactly the samples `abundance` names. Every other column is carried
#'   through untouched and interpreted by nothing in gifter.
#' @return A `gifter_dataset` list holding the catalogue, the genome and sample
#'   identifiers, the abundance matrix as supplied, the metadata and the
#'   `database_version`.
#' @examples
#' donor <- evaluate_gifts(data.frame(
#'   gene_id = "g1", namespace = "KO", accession = "K01198"
#' ))
#' recipient <- evaluate_gifts(data.frame(
#'   gene_id = "g1", namespace = "KO", accession = "K01805"
#' ))
#' catalogue <- gifter_community(donor = donor, recipient = recipient)
#' abundance <- matrix(
#'   c(0.7, 0.3, 0.2, 0.8), nrow = 2,
#'   dimnames = list(c("donor", "recipient"), c("gut", "soil"))
#' )
#' dataset <- gifter_dataset(catalogue, abundance)
#' sample_id(dataset)
#' @export
gifter_dataset <- function(catalogue, abundance, metadata = NULL) {
  if (!inherits(catalogue, "gifter_community")) {
    stop(
      "catalogue must come from gifter_community() or ",
      "evaluate_gifts_community(): a dataset is a community observed across ",
      "samples, so the calls it reads are bound once, there",
      call. = FALSE
    )
  }
  abundance <- .check_abundance_matrix(
    .as_abundance_matrix(abundance), catalogue$genome_id
  )
  metadata <- .check_sample_metadata(metadata, colnames(abundance))

  structure(
    list(
      catalogue = catalogue,
      genome_id = catalogue$genome_id,
      sample_id = colnames(abundance),
      abundance = abundance,
      metadata = metadata,
      database_version = catalogue$database_version
    ),
    class = c("gifter_dataset", "list")
  )
}

# A short list, and how much of it was elided, so that printing a catalogue of
# four hundred genomes says what it holds without filling a console.
.abbreviate_ids <- function(ids, limit = 6L) {
  if (length(ids) <= limit) return(paste(ids, collapse = ", "))
  paste0(
    paste(ids[seq_len(limit)], collapse = ", "),
    ", ... (", length(ids) - limit, " more)"
  )
}

#' @export
print.gifter_dataset <- function(x, ...) {
  cat(
    "<gifter_dataset>", length(x$genome_id), "genomes x",
    length(x$sample_id), "samples\n"
  )
  cat("  genomes:", .abbreviate_ids(x$genome_id), "\n")
  cat("  samples:", .abbreviate_ids(x$sample_id), "\n")
  detected <- colSums(x$abundance > 0)
  cat(sprintf(
    "  detected per sample at detection = 0: %d-%d (median %g)\n",
    min(detected), max(detected), stats::median(detected)
  ))
  if (is.null(x$metadata)) {
    cat("  metadata: none\n")
  } else {
    columns <- setdiff(names(x$metadata), "sample_id")
    cat(
      "  metadata:", length(columns), "column(s):",
      .abbreviate_ids(columns), "\n"
    )
  }
  cat("  GIFTs evaluated:", length(x$catalogue$gift_id), "\n")
  cat("  database version:", .gifter_database_version_value(x$database_version), "\n")
  invisible(x)
}

#' Sample identifiers of a dataset
#'
#' @param x A `gifter_dataset`.
#' @param ... Unused.
#' @return A character vector of sample identifiers, in the order the abundance
#'   matrix names them.
#' @examples
#' donor <- evaluate_gifts(data.frame(
#'   gene_id = "g1", namespace = "KO", accession = "K01198"
#' ))
#' catalogue <- gifter_community(donor = donor)
#' dataset <- gifter_dataset(catalogue, matrix(
#'   1, nrow = 1, dimnames = list("donor", "gut")
#' ))
#' sample_id(dataset)
#' @export
sample_id <- function(x, ...) UseMethod("sample_id")

#' @export
sample_id.gifter_dataset <- function(x, ...) x$sample_id

#' @export
sample_id.default <- function(x, ...) {
  stop("sample_id() needs a gifter_dataset", call. = FALSE)
}

#' One sample of a dataset, as an ordinary community
#'
#' Returns the genomes detected in one sample as a `gifter_community`, so that
#' [community_traits()], [community_network()] and everything else keep working
#' on a single sample unchanged. Nothing is re-evaluated: the calls are the
#' catalogue's, restricted to the detected genomes.
#'
#' @section The reference universe does not shrink:
#'
#' The returned community keeps the catalogue's evaluated GIFTs rather than
#' recomputing the union over the detected genomes. For a catalogue whose
#' genomes were evaluated together --- the ordinary case --- the two are
#' identical. They differ only when genomes were evaluated over different GIFT
#' subsets, and there the recomputed union would give every sample a different
#' `assessable` denominator, which is the sample-level form of the failure the
#' mixed-release refusal in [gifter_community()] exists to prevent. A dataset's
#' reference universe is the catalogue's, and it does not shrink because a
#' sample is small.
#'
#' @param dataset A `gifter_dataset`.
#' @param sample One sample identifier.
#' @param detection Abundance a genome must exceed to be a member of the
#'   sample's community. `0` by default, meaning observed at all. A sample in
#'   which no genome exceeds it is refused rather than returned empty.
#' @return A `gifter_community` of the genomes detected in that sample.
#' @examples
#' donor <- evaluate_gifts(data.frame(
#'   gene_id = "g1", namespace = "KO", accession = "K01198"
#' ))
#' recipient <- evaluate_gifts(data.frame(
#'   gene_id = "g1", namespace = "KO", accession = "K01805"
#' ))
#' catalogue <- gifter_community(donor = donor, recipient = recipient)
#' abundance <- matrix(
#'   c(0.7, 0.3, 0, 1), nrow = 2,
#'   dimnames = list(c("donor", "recipient"), c("gut", "soil"))
#' )
#' dataset <- gifter_dataset(catalogue, abundance)
#' sample_community(dataset, "soil")$genome_id
#' @export
sample_community <- function(dataset, sample, detection = 0) {
  if (!inherits(dataset, "gifter_dataset")) {
    stop("dataset must come from gifter_dataset()", call. = FALSE)
  }
  if (!is.character(sample) || length(sample) != 1L || is.na(sample)) {
    stop("sample must be one sample identifier", call. = FALSE)
  }
  if (!sample %in% dataset$sample_id) {
    stop(
      "The dataset holds no sample called ", sample, ". It names: ",
      .abbreviate_ids(dataset$sample_id),
      call. = FALSE
    )
  }
  detection <- .normalize_detection(detection)
  detected <- .detection_matrix(
    dataset$abundance[, sample, drop = FALSE], detection
  )[, 1L]
  .restrict_community(dataset$catalogue, dataset$genome_id[detected])
}

# The catalogue restricted to a set of genomes, keeping its evaluated GIFTs.
# This is what .gifter_community() would build for a catalogue whose genomes
# were evaluated together, without walking the calls again.
.restrict_community <- function(catalogue, genomes) {
  structure(
    list(
      genome_id = genomes,
      gift_id = catalogue$gift_id,
      matrix = catalogue$matrix[, genomes, drop = FALSE],
      results = catalogue$results[genomes],
      database_version = catalogue$database_version
    ),
    class = c("gifter_community", "list")
  )
}
