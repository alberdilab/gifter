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

.giftr_assessability_policies <- c("none", "completeness")

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
  } else {
    stop(
      "quality must be a named numeric vector of completeness values, or a data frame with `genome_id` and `completeness`",
      call. = FALSE
    )
  }
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
      "completeness must be a proportion between 0 and 1",
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
  # claim about which capability was lost, because giftr has no validated model
  # of how gene content is lost from a fragmented assembly.
  if (identical(policy, "completeness") && completeness < threshold) {
    state[!state] <- NA
  }
  state
}

.resolve_policy <- function(policy, quality, threshold) {
  policy <- match.arg(policy, .giftr_assessability_policies)
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
      stop("threshold must be one proportion between 0 and 1", call. = FALSE)
    }
  }
  policy
}
