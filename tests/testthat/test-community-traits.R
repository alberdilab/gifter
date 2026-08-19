# Community distributional traits. The assessment is
# inst/doc/proposal-quantitative-traits.md.
#
# The container's job is to refuse comparisons that are not comparable, and the
# metrics' job is to describe how capability is distributed without implying
# that distribution is interaction. Both are tested here against a fixture whose
# expected values are hand-computed from a curated chain.

community_metric <- function(traits, id, target = NULL) {
  rows <- traits$metrics[
    traits$metrics$metric_id == id &
      traits$metrics$reference_universe == "all curated GIFTs", ,
    drop = FALSE
  ]
  if (!is.null(target)) rows <- rows[rows$target_id == target, , drop = FALSE]
  rows
}

test_that("the fixture completes exactly the intended capabilities", {
  # Every expected value below depends on this. Several CAZy families evidence
  # both debranching and backbone cleavage, so the separation is checked first
  # rather than assumed.
  supported <- function(role) {
    result <- arabinoxylan_genome(role)
    result$gifts$gift_id[result$gifts$complete]
  }
  expect_setequal(supported("debrancher"), "arabinoxylan_debranching")
  expect_setequal(supported("backbone"), "xylan_degradation")
  expect_setequal(
    supported("consumer"),
    c("xylose_uptake_abc", "xylose_degradation_isomerase")
  )
})

test_that("a community carries its genome identifiers and call matrix", {
  community <- arabinoxylan_community()
  expect_s3_class(community, "giftr_community")
  expect_identical(community$genome_id, c("A", "B", "C", "D"))
  expect_equal(dim(community$matrix), c(length(community$gift_id), 4L))
  expect_true(community$matrix["arabinoxylan_debranching", "A"])
  expect_false(community$matrix["arabinoxylan_debranching", "B"])
})

test_that("genomes must be named, and results must be calls", {
  genome <- arabinoxylan_genome("debrancher")
  expect_error(giftr_community(genome), "distinct name")
  expect_error(giftr_community(A = genome, A = genome), "distinct name")
  expect_error(giftr_community(A = list()), "result from evaluate_gifts")
  expect_error(giftr_community(), "at least one evaluated genome")
})

test_that("genomes evaluated against different releases are refused", {
  # A provider count over two releases counts capabilities that were not
  # offered to every genome.
  genome <- arabinoxylan_genome("debrancher")
  other <- genome
  other$database_version$giftr_db_version <- "0000.0.0"
  expect_error(
    giftr_community(A = genome, B = other),
    "different database versions"
  )
})

test_that("abundance is validated against the genomes it weights", {
  genome <- arabinoxylan_genome("debrancher")
  expect_error(
    giftr_community(A = genome, abundance = c(B = 1)),
    "exactly the supplied genomes"
  )
  expect_error(
    giftr_community(A = genome, abundance = c(A = -1)),
    "non-negative"
  )
  expect_error(giftr_community(A = genome, abundance = c(A = 0)), "all zero")
  expect_error(giftr_community(A = genome, abundance = 1), "named numeric")
  # Normalisation happens on read; the supplied values are kept.
  community <- giftr_community(A = genome, B = genome, abundance = c(A = 3, B = 1))
  expect_equal(unname(community$abundance), c(0.75, 0.25))
  expect_equal(unname(community$abundance_supplied), c(3, 1))
})

test_that("provider counts match the distributed chain", {
  traits <- community_traits(
    arabinoxylan_community(), universes = list(arabinoxylan_universe())
  )
  providers <- community_metric(traits, "provider_count")
  counts <- stats::setNames(providers$value, providers$target_id)
  expect_equal(counts[["arabinoxylan_debranching"]], 1)
  expect_equal(counts[["xylan_degradation"]], 1)
  expect_equal(counts[["xylose_uptake_abc"]], 2)
  expect_equal(counts[["xylose_degradation_isomerase"]], 2)
  expect_equal(community_metric(traits, "community_richness")$value, 4)
  # Community richness exceeds every member's, and both components are reported
  # rather than only their ratio.
  expect_equal(community_metric(traits, "mean_genome_richness")$value, 1.5)
})

test_that("the trace names the genomes behind every provider count", {
  traits <- community_traits(
    arabinoxylan_community(), universes = list(arabinoxylan_universe())
  )
  trace <- traits$trace[
    traits$trace$metric_id == "provider_count" &
      traits$trace$target_id == "xylose_uptake_abc", ,
    drop = FALSE
  ]
  expect_setequal(trace$contribution, c("C", "D"))
})

test_that("singleton fraction and unique contribution agree on who is alone", {
  traits <- community_traits(
    arabinoxylan_community(), universes = list(arabinoxylan_universe())
  )
  # Two of four represented GIFTs have one provider each.
  singleton <- community_metric(traits, "singleton_fraction")
  expect_equal(singleton$value, 0.5)
  expect_equal(singleton$numerator, 2L)
  expect_equal(singleton$denominator, 4L)

  unique_rows <- community_metric(traits, "unique_contribution")
  contributions <- stats::setNames(unique_rows$value, unique_rows$target_id)
  expect_equal(unname(contributions[c("A", "B")]), c(1, 1))
  # C and D duplicate each other, so neither is anyone's only provider. This is
  # a property of the sampling, not of the organisms.
  expect_equal(unname(contributions[c("C", "D")]), c(0, 0))
})

test_that("presence and abundance stay in separate rows", {
  traits <- community_traits(
    arabinoxylan_community(abundance = c(A = 0.1, B = 0.2, C = 0.3, D = 0.4)),
    universes = list(arabinoxylan_universe())
  )
  coverage <- community_metric(traits, "abundance_coverage")
  values <- stats::setNames(coverage$value, coverage$target_id)
  expect_equal(values[["arabinoxylan_debranching"]], 0.1)
  expect_equal(values[["xylose_uptake_abc"]], 0.7)
  # Same provider count, different abundance coverage: the two quantities are
  # not interchangeable, which is why neither is folded into the other.
  providers <- community_metric(traits, "provider_count")
  provider_values <- stats::setNames(providers$value, providers$target_id)
  expect_equal(provider_values[["xylose_uptake_abc"]], 2)
  expect_equal(provider_values[["xylose_degradation_isomerase"]], 2)
  expect_equal(values[["xylose_degradation_isomerase"]], 0.7)
})

test_that("abundance coverage is absent when abundance was not supplied", {
  traits <- community_traits(
    arabinoxylan_community(), universes = list(arabinoxylan_universe())
  )
  expect_equal(nrow(community_metric(traits, "abundance_coverage")), 0L)
})

test_that("repertoire overlap is a Jaccard index within the universe", {
  traits <- community_traits(
    arabinoxylan_community(), universes = list(arabinoxylan_universe())
  )
  overlaps <- community_metric(traits, "repertoire_overlap")
  values <- stats::setNames(overlaps$value, overlaps$target_id)
  # C and D are duplicates; nobody else shares a capability with anybody.
  expect_equal(values[["C | D"]], 1)
  expect_equal(values[["A | B"]], 0)
  expect_equal(values[["B | C"]], 0)
  expect_equal(overlaps$value, overlaps$numerator / overlaps$denominator)
  # Disjoint repertoires are different repertoires. Nothing here asserts that A
  # and B cooperate, and the metric is named for what it measures.
  expect_true(all(overlaps$metric_id == "repertoire_overlap"))
})

test_that("overlap is reported within a universe, not only across the catalogue", {
  transport <- gift_universe(mode = "transport", label = "transport GIFTs")
  catabolic <- gift_universe(mode = "catabolic", label = "catabolic GIFTs")
  traits <- community_traits(
    arabinoxylan_community(), universes = list(transport, catabolic)
  )
  within_transport <- traits$metrics[
    traits$metrics$metric_id == "repertoire_overlap" &
      traits$metrics$reference_universe == "transport GIFTs", ,
    drop = FALSE
  ]
  # B carries no transport GIFT, so B and C share nothing there, while C and D
  # remain identical. An unstratified overlap would blur the two.
  values <- stats::setNames(within_transport$value, within_transport$target_id)
  expect_equal(values[["C | D"]], 1)
  expect_equal(values[["B | C"]], 0)
  # A and B both hold nothing in this universe, so their overlap is undefined
  # rather than zero, and an undefined quantity is withheld. Reporting 0 would
  # say two genomes were compared and found to share nothing.
  expect_false("A | B" %in% names(values))
  expect_gt(nrow(traits$metrics[
    traits$metrics$reference_universe == "catabolic GIFTs", , drop = FALSE
  ]), 0L)
})

test_that("community coverage is reported only for a bounded universe", {
  bounded <- gift_universe(
    mode = "anabolic", auxotrophy_indicator = TRUE, bounded = TRUE,
    label = "biomass-essential anabolic GIFTs"
  )
  traits <- community_traits(
    arabinoxylan_community(),
    universes = list(arabinoxylan_universe(), bounded)
  )
  coverage <- traits$metrics[traits$metrics$metric_id == "community_coverage", ]
  expect_identical(
    unique(coverage$reference_universe), "biomass-essential anabolic GIFTs"
  )
})

test_that("community traits refuse a bad container or a stale universe", {
  expect_error(community_traits(list()), "must come from giftr_community")
  community <- arabinoxylan_community()
  stale <- gift_universe(type = "metabolic")
  stale$database_version <- "0000.0.0"
  expect_error(
    community_traits(community, universes = list(stale)),
    "different database version"
  )
})

test_that("every community metric names its universe and its target", {
  traits <- community_traits(
    arabinoxylan_community(abundance = c(A = 1, B = 1, C = 1, D = 1)),
    universes = list(arabinoxylan_universe())
  )
  expect_true(all(nzchar(traits$metrics$reference_universe)))
  expect_true(all(nzchar(traits$metrics$derivation_method)))
  expect_true(all(
    traits$metrics$target_type %in% c("community", "gift", "genome", "genome_pair")
  ))
  proportions <- traits$metrics[traits$metrics$unit == "proportion", , drop = FALSE]
  expect_true(all(proportions$denominator > 0L))
  expect_true(all(proportions$value >= 0 & proportions$value <= 1))
})
