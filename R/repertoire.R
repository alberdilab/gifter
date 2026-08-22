# Distance between genomes, by what they encode.
#
# `community_traits()` already answers every pair at once and reports the
# Jaccard index of two genomes' supported GIFTs as `repertoire_overlap`. This
# file returns the same numbers in the shape a clustering or ordination routine
# expects, and returns nothing else: gifter exports the distance and does not
# cut the tree.
#
# That is not squeamishness about clustering. A grouping is a linkage, a cut
# height and a number of groups, all three of which are the analyst's and none
# of which gifter can defend from the calls -- and the word for the result is
# the problem, because "guild" names a set of organisms exploiting a resource
# in the same way, which is a claim about resource use in situ. Two genomes
# that encode similar capabilities have similar repertoires. §8 refusal 4 of
# the quantitative traits proposal refuses lighter ecological claims than that
# one.
#
# The overlap is sample-invariant. Two genomes share what they share wherever
# both are detected, so a dataset delegates to its catalogue exactly as
# `gift_matrix()` does.

#' Distance between genomes by encoded repertoire
#'
#' Returns one minus the Jaccard index of every pair of genomes' supported
#' GIFTs, as a [stats::dist] object, so that a repertoire can be handed to
#' `hclust()`, `cmdscale()`, `vegan::adonis2()` or any other routine that takes
#' a distance.
#'
#' The values are the `repertoire_overlap` of [community_traits()], subtracted
#' from one. Computing them here does not require the traits to have been
#' computed, and the two agree exactly.
#'
#' @section What gifter does not do with it:
#'
#' gifter returns the distance and stops. It fits no clustering, chooses no
#' linkage, cuts no tree and names no groups, because the linkage, the cut and
#' the number of groups are the analyst's choices and gifter cannot defend any
#' of them from the calls.
#'
#' Nor are the groups that a clustering finds guilds. A guild is a set of
#' organisms exploiting a resource in the same way, which is a claim about
#' resource use where the organisms live. Two genomes near each other here
#' encode similar capabilities; they have not been shown to use the same
#' resource, to use it in the same way, or to co-occur.
#'
#' @section Why there is no assessability policy here:
#'
#' A Jaccard index reads supported sets. A GIFT a genome does not support is
#' outside its set whether the call was a confident negative or an
#' indeterminate one, so `policy`, `quality` and `threshold` cannot move this
#' distance and are not accepted: an argument that does nothing is worse than
#' one that is absent, because a reader assumes it worked.
#'
#' `min_confidence` is accepted, because it does move the distance. It removes
#' a positive call from the supported set when the evidence behind it is too
#' weak, and the set is what is being compared.
#'
#' @section Pairs with no distance:
#'
#' Two genomes that support nothing in the universe have no overlap to measure
#' rather than an overlap of zero, so their distance is `NA`. Reporting `1`
#' would say they were compared and found to share nothing.
#'
#' @param x A `gifter_community` or a `gifter_dataset`. A dataset delegates to
#'   its catalogue: a pair of genomes shares what it shares in every sample
#'   both are detected in, so the distance carries no `sample_id`.
#' @param universe Optional [gift_universe()] restricting which GIFTs the
#'   repertoires are compared over. Omitted, every GIFT the evaluation produced
#'   is compared. Stratifying matters here: the catalogue is overwhelmingly
#'   metabolic, so an unstratified distance is a metabolic distance under a
#'   general name.
#' @param min_confidence Optional weakest marker confidence a positive call may
#'   rest on and still enter a repertoire, as in [community_traits()]. `NULL`,
#'   the default, compares every positive call whatever it rests on.
#' @return A [stats::dist] over the genomes, carrying `reference_universe`,
#'   `database_version` and `min_confidence` attributes.
#' @seealso [gift_matrix()] for the calls the distance is computed from, and
#'   [community_traits()], which reports the same overlaps per pair beside the
#'   GIFTs behind them.
#' @examples
#' donor <- evaluate_gifts(data.frame(
#'   gene_id = "g1", namespace = "KO", accession = "K01198"
#' ))
#' recipient <- evaluate_gifts(data.frame(
#'   gene_id = "g1", namespace = "KO", accession = "K01805"
#' ))
#' community <- gifter_community(donor = donor, recipient = recipient)
#' repertoire_distance(community)
#' @export
repertoire_distance <- function(x, universe = NULL, min_confidence = NULL) {
  # Every argument is resolved by the exporter, so the distance and the matrix
  # it is computed from can never disagree about which calls they read.
  calls <- gift_matrix(x, universe = universe, min_confidence = min_confidence)
  genomes <- rownames(calls)
  if (length(genomes) < 2L) {
    stop(
      "A distance needs at least two genomes to compare; this one names ",
      length(genomes),
      call. = FALSE
    )
  }

  # Only supported calls are compared. A negative and an indeterminate call are
  # alike here -- both are outside the set -- which is why this function takes
  # no assessability policy.
  supports <- calls %in% TRUE
  dim(supports) <- dim(calls)
  dimnames(supports) <- dimnames(calls)
  counts <- supports
  storage.mode(counts) <- "double"

  # The whole triangle at once, as community_traits() computes it: one
  # cross-product holds every shared count, and the union sizes follow from the
  # row sums.
  shared <- tcrossprod(counts)
  sizes <- rowSums(supports)
  union <- outer(sizes, sizes, "+") - shared
  distance <- 1 - shared / union
  distance[union == 0] <- NA_real_

  result <- stats::as.dist(distance)
  attr(result, "reference_universe") <- attr(calls, "reference_universe")
  attr(result, "database_version") <- attr(calls, "database_version")
  # Not the assessability policy, which cannot have moved these numbers.
  attr(result, "min_confidence") <-
    if (is.null(min_confidence)) NA_character_ else as.character(min_confidence)
  result
}
