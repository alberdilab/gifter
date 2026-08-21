# Whether a negative call is informative.
#
# `evaluate_gifts()` answers one question: do the observed markers support a
# complete curated implementation? It answers it the same way for a closed
# isolate genome and for a 60%-complete MAG, because the markers are all it
# sees. That is correct for a call and wrong for a denominator: a genome that
# was never fully observed has not been shown to lack anything.
#
# This layer therefore adds a third state on top of the Boolean call, under an
# explicitly named policy. Two constraints hold for every policy that will ever
# be added here:
#
#   1. No policy may promote an unsupported GIFT to supported. Genome quality
#      informs the reading of absence and nothing else.
#   2. The default policy declares nothing indeterminate, so a user who supplies
#      no quality information gets exactly the Boolean behaviour they had, with
#      `assessable` in the output saying so rather than the assumption being
#      implied.

.gifter_assessability_policies <- c("none", "completeness")

# The scale a set of completeness values is stated on. CheckM, BUSCO and most
# MAG quality tables report percentages; every comparison inside this layer is a
# proportion. The two are distinguishable without asking the caller, because a
# proportion cannot exceed 1: a set whose largest value is above 1 can only be
# percentages. A set that stays at or below 1 is read as proportions, so 1 means
# a complete genome rather than a 1% one. The scale is decided once over every
# value supplied, so that a 0.95 sitting in a percentage table is read on its
# table's scale rather than on its own.
.completeness_scale <- function(values) {
  observed <- values[is.finite(values)]
  if (length(observed) && max(observed) > 1) 100 else 1
}

# Convert to the proportion scale under that rule. A value below 1 inside a
# table read as percentages is either an almost empty genome or a proportion
# that was mixed in, and the two mean opposite things; the reading is stated
# rather than chosen silently.
.as_completeness <- function(values, what) {
  scale <- .completeness_scale(values)
  if (scale > 1) {
    mixed <- which(is.finite(values) & values > 0 & values < 1)
    if (length(mixed)) {
      labels <- if (is.null(names(values))) mixed else names(values)[mixed]
      warning(
        what, " is read as percentages, because it holds values above 1. ",
        "Completeness below 1 therefore means a near-empty genome rather than ",
        "a proportion: ", paste(labels, collapse = ", "),
        call. = FALSE
      )
    }
  }
  values / scale
}

.normalize_quality <- function(quality, genomes) {
  if (is.null(quality)) return(NULL)
  if (is.data.frame(quality)) {
    if (!all(c("genome_id", "completeness") %in% names(quality))) {
      stop(
        "quality must have `genome_id` and `completeness` columns",
        call. = FALSE
      )
    }
    values <- stats::setNames(as.numeric(quality$completeness), quality$genome_id)
  } else if (is.numeric(quality) && !is.null(names(quality))) {
    values <- quality
  } else if (is.numeric(quality)) {
    # The commonest way to arrive here is a completeness column pulled out of a
    # MAG quality table, which loses the genome identifiers on the way. gifter
    # will not align it by position: the genomes it would be aligned against
    # come from the annotation table, in that table's order, and a silent
    # off-by-one assigns one genome's fragmentation to another.
    stop(
      "quality is a numeric vector without names, so there is nothing to say which genome each completeness value belongs to. ",
      "Name it with the genome identifiers, as setNames(completeness, genome_id), or pass the quality table itself with `genome_id` and `completeness` columns",
      call. = FALSE
    )
  } else {
    stop(
      "quality must be a named numeric vector of completeness values, or a data frame with `genome_id` and `completeness`",
      call. = FALSE
    )
  }
  values <- .as_completeness(values, "quality")
  missing <- setdiff(genomes, names(values))
  if (length(missing)) {
    stop(
      "quality is missing completeness for: ", paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  values <- values[genomes]
  if (any(is.na(values)) || any(values < 0) || any(values > 1)) {
    stop(
      "completeness must be a proportion between 0 and 1, or a percentage between 0 and 100",
      call. = FALSE
    )
  }
  values
}

# The state of one genome's calls under a policy. `complete` is the Boolean the
# evaluator produced; the result is `TRUE` for supported, `FALSE` for a negative
# call that may be read as absence, and `NA` for one that may not.
.assessability_state <- function(complete, policy, completeness, threshold) {
  state <- as.logical(complete)
  state[is.na(state)] <- FALSE
  if (identical(policy, "none")) return(state)
  # Below the declared completeness, a genome has not been observed well enough
  # for any absence to be informative. This is deliberately blunt: it makes no
  # claim about which capability was lost, because gifter has no validated model
  # of how gene content is lost from a fragmented assembly.
  if (identical(policy, "completeness") && completeness < threshold) {
    state[!state] <- NA
  }
  state
}

# The threshold is a completeness value and is read on the same terms, so a
# caller working in percentages may state both in percentages. A malformed
# threshold is returned untouched for `.resolve_policy()` to report.
.normalize_threshold <- function(threshold) {
  if (is.null(threshold)) return(NULL)
  if (!is.numeric(threshold) || length(threshold) != 1L || is.na(threshold)) {
    return(threshold)
  }
  .as_completeness(threshold, "threshold")
}

.resolve_policy <- function(policy, quality, threshold) {
  policy <- match.arg(policy, .gifter_assessability_policies)
  if (identical(policy, "completeness")) {
    if (is.null(quality)) {
      stop(
        "The completeness policy needs genome completeness values in `quality`",
        call. = FALSE
      )
    }
    if (is.null(threshold)) {
      stop(
        "The completeness policy needs an explicit `threshold`. There is no defensible default: how complete a genome must be before its absences are informative is the analyst's declared choice.",
        call. = FALSE
      )
    }
    if (length(threshold) != 1L || is.na(threshold) || threshold < 0 || threshold > 1) {
      stop(
        "threshold must be one completeness value: a proportion between 0 and 1, or a percentage between 0 and 100",
        call. = FALSE
      )
    }
  }
  policy
}
