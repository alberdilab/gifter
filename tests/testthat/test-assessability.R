# Whether a negative call may enter a denominator. The assessment is
# inst/doc/proposal-quantitative-traits.md section 4.
#
# The whole layer rests on one asymmetry: genome quality changes how absence is
# read and never changes what the markers support. These tests protect that
# asymmetry, the refusal to guess a threshold, and the visibility of a
# denominator that has quietly collapsed.

purine_result <- function() {
  evaluate_gifts(ko_annotations(direct_purine_markers(include_amp = TRUE)))
}

bounded_universe <- function() {
  gift_universe(
    mode = "anabolic", auxotrophy_indicator = TRUE, bounded = TRUE,
    label = "biomass-essential anabolic GIFTs"
  )
}

test_that("the default policy declares nothing indeterminate", {
  traits <- genome_traits(purine_result(), universes = list(bounded_universe()))
  fraction <- traits$metrics[traits$metrics$metric_id == "assessable_fraction", ]
  expect_equal(fraction$value, 1)
  expect_identical(traits$assessability$policy, "none")
})

test_that("a fragmented genome's absences leave every denominator", {
  universe <- bounded_universe()
  full <- genome_traits(
    purine_result(), universes = list(universe), genome_id = "MAG",
    quality = c(MAG = 0.98), policy = "completeness", threshold = 0.9
  )
  fragmented <- suppressWarnings(genome_traits(
    purine_result(), universes = list(universe), genome_id = "MAG",
    quality = c(MAG = 0.55), policy = "completeness", threshold = 0.9
  ))
  richness <- function(traits) {
    traits$metrics$value[traits$metrics$metric_id == "gift_richness"]
  }
  assessable <- function(traits) {
    traits$metrics$assessable[traits$metrics$metric_id == "gift_richness"]
  }
  # What the markers support is identical. Only the denominator moved.
  expect_equal(richness(fragmented), richness(full))
  expect_lt(assessable(fragmented), assessable(full))
  expect_equal(assessable(fragmented), richness(fragmented))
})

test_that("no policy can promote an unsupported GIFT to supported", {
  # The one constraint every future policy must also satisfy.
  universe <- gift_universe(label = "all curated GIFTs")
  supported <- function(quality) {
    traits <- suppressWarnings(genome_traits(
      purine_result(), universes = list(universe), genome_id = "MAG",
      quality = c(MAG = quality), policy = "completeness", threshold = 0.9
    ))
    sort(traits$trace$gift_id[traits$trace$metric_id == "gift_richness"])
  }
  baseline <- sort(
    genome_traits(purine_result(), universes = list(universe))$trace$gift_id[
      genome_traits(purine_result(), universes = list(universe))$trace$metric_id ==
        "gift_richness"
    ]
  )
  expect_identical(supported(0.99), baseline)
  expect_identical(supported(0.20), baseline)
})

test_that("a collapsed denominator is visible and warned about", {
  # A supported fraction of 1.0 over one assessable GIFT is arithmetically fine
  # and biologically empty. The reader must be told before they quote it.
  expect_warning(
    traits <- genome_traits(
      purine_result(), universes = list(bounded_universe()), genome_id = "MAG",
      quality = c(MAG = 0.30), policy = "completeness", threshold = 0.9
    ),
    "assessable_fraction"
  )
  fraction <- traits$metrics[traits$metrics$metric_id == "assessable_fraction", ]
  expect_lt(fraction$value, 0.5)
  supported <- traits$metrics[traits$metrics$metric_id == "supported_fraction", ]
  expect_equal(supported$denominator, fraction$numerator)
})

test_that("the completeness policy refuses to invent its own parameters", {
  result <- purine_result()
  expect_error(
    genome_traits(result, policy = "completeness"),
    "needs genome completeness"
  )
  expect_error(
    genome_traits(result, quality = c(genome = 0.5), policy = "completeness"),
    "needs an explicit `threshold`"
  )
  expect_error(
    genome_traits(result, quality = c(other = 0.5), policy = "completeness",
                  threshold = 0.9),
    "missing completeness for"
  )
  expect_error(
    genome_traits(result, quality = c(genome = 1.4), policy = "completeness",
                  threshold = 0.9),
    "between 0 and 1"
  )
  expect_error(
    genome_traits(result, quality = c(genome = 0.5), policy = "completeness",
                  threshold = 2),
    "one proportion between 0 and 1"
  )
  expect_error(genome_traits(result, policy = "guesswork"), "should be one of")
})

test_that("quality may be supplied as a data frame", {
  traits <- genome_traits(
    purine_result(), universes = list(bounded_universe()), genome_id = "MAG",
    quality = data.frame(genome_id = "MAG", completeness = 0.98),
    policy = "completeness", threshold = 0.9
  )
  expect_equal(traits$assessability$completeness[["MAG"]], 0.98)
  expect_error(
    genome_traits(purine_result(), quality = data.frame(genome_id = "genome"),
                  policy = "completeness", threshold = 0.9),
    "`genome_id` and `completeness`"
  )
})

test_that("indeterminacy is resolved per genome, not per community", {
  # A fragmented member's silence is uninformative while a complete member's is
  # not, and a provider denominator that mixed them would be meaningless.
  community <- gifter_community(
    complete_genome = arabinoxylan_genome("debrancher"),
    fragmented = arabinoxylan_genome("backbone"),
    quality = c(complete_genome = 0.99, fragmented = 0.40),
    policy = "completeness", threshold = 0.9
  )
  expect_equal(sum(is.na(community$matrix[, "complete_genome"])), 0L)
  expect_gt(sum(is.na(community$matrix[, "fragmented"])), 0L)
  # The fragmented genome's positive call survives untouched.
  expect_true(community$matrix["xylan_degradation", "fragmented"])
  expect_false(is.na(community$matrix["xylan_degradation", "fragmented"]))
})

test_that("a provider fraction counts only the genomes that could assess", {
  community <- gifter_community(
    A = arabinoxylan_genome("debrancher"),
    B = arabinoxylan_genome("backbone"),
    C = arabinoxylan_genome("consumer"),
    quality = c(A = 0.99, B = 0.99, C = 0.40),
    policy = "completeness", threshold = 0.9
  )
  traits <- community_traits(community, universes = list(arabinoxylan_universe()))
  rows <- traits$metrics[
    traits$metrics$metric_id == "provider_fraction" &
      traits$metrics$target_id == "arabinoxylan_debranching", ,
    drop = FALSE
  ]
  # C is too fragmented to say it lacks debranching, so it is not in the
  # denominator: one provider out of two genomes that could assess it.
  expect_equal(rows$denominator, 2L)
  expect_equal(rows$value, 0.5)
  expect_equal(
    traits$metrics$denominator[
      traits$metrics$metric_id == "provider_fraction" &
        traits$metrics$target_id == "xylose_uptake_abc"
    ],
    3L
  )
})

test_that("the community carries the policy it was built under", {
  community <- gifter_community(
    A = arabinoxylan_genome("debrancher"),
    quality = c(A = 0.95), policy = "completeness", threshold = 0.9
  )
  expect_identical(community$assessability$policy, "completeness")
  expect_equal(community$assessability$threshold, 0.9)
  traits <- community_traits(community, universes = list(arabinoxylan_universe()))
  expect_identical(traits$assessability$policy, "completeness")
})
