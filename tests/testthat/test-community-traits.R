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
  expect_s3_class(community, "gifter_community")
  expect_identical(community$genome_id, c("A", "B", "C", "D"))
  expect_equal(dim(community$matrix), c(length(community$gift_id), 4L))
  expect_true(community$matrix["arabinoxylan_debranching", "A"])
  expect_false(community$matrix["arabinoxylan_debranching", "B"])
})

test_that("genomes must be named, and results must be calls", {
  genome <- arabinoxylan_genome("debrancher")
  expect_error(gifter_community(genome), "distinct name")
  expect_error(gifter_community(A = genome, A = genome), "distinct name")
  expect_error(gifter_community(A = list()), "result from evaluate_gifts")
  expect_error(gifter_community(), "at least one evaluated genome")
})

test_that("genomes evaluated against different releases are refused", {
  # A provider count over two releases counts capabilities that were not
  # offered to every genome.
  genome <- arabinoxylan_genome("debrancher")
  other <- genome
  other$database_version$gifter_db_version <- "0000.0.0"
  expect_error(
    gifter_community(A = genome, B = other),
    "different database versions"
  )
})

test_that("a community holds calls, not abundance or completeness", {
  # Abundance and completeness are ways of reading calls, not properties of
  # them, so the container commits to neither and the same calls can be read
  # under two thresholds without being evaluated twice.
  community <- arabinoxylan_community()
  expect_null(community$abundance)
  expect_null(community$assessability)
  expect_false(any(is.na(community$matrix)))
  expect_error(
    gifter_community(A = arabinoxylan_genome("debrancher"), abundance = c(A = 1)),
    "pass them to community_traits"
  )
})

test_that("abundance is validated against the genomes it weights", {
  community <- gifter_community(
    A = arabinoxylan_genome("debrancher"), B = arabinoxylan_genome("backbone")
  )
  weighted <- function(abundance) {
    community_traits(
      community, universes = list(arabinoxylan_universe()), abundance = abundance
    )
  }
  expect_error(weighted(c(B = 1)), "exactly the supplied genomes")
  expect_error(weighted(c(A = -1, B = 1)), "non-negative")
  expect_error(weighted(c(A = 0, B = 0)), "all zero")
  expect_error(weighted(1), "named numeric")
  # Normalisation happens on read; the supplied values are kept beside it.
  traits <- weighted(c(A = 3, B = 1))
  expect_equal(unname(traits$abundance), c(0.75, 0.25))
  expect_equal(unname(traits$abundance_supplied), c(3, 1))
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
    arabinoxylan_community(), universes = list(arabinoxylan_universe()),
    abundance = c(A = 0.1, B = 0.2, C = 0.3, D = 0.4)
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

test_that("every pair is answered at once, and answered as the loop did", {
  # The pairwise walk is quadratic in the community, so the overlaps are
  # computed from one cross-product rather than one intersect() per pair. That
  # is an implementation of the same definition, checked here against the
  # definition itself over a community large enough for the two to disagree.
  set.seed(4)
  genomes <- paste0("g", seq_len(24))
  gifts <- utils::head(sort(arabinoxylan_universe()$gift_id), 30L)
  supports <- matrix(
    stats::runif(length(gifts) * length(genomes)) < 0.3,
    nrow = length(gifts), dimnames = list(gifts, genomes)
  )
  # Two genomes holding nothing: their overlap is undefined, not zero.
  supports[, "g7"] <- FALSE
  supports[, "g8"] <- FALSE

  expected <- do.call(rbind, lapply(
    utils::combn(genomes, 2L, simplify = FALSE),
    function(pair) {
      left <- gifts[supports[, pair[[1L]]]]
      right <- gifts[supports[, pair[[2L]]]]
      union_size <- length(union(left, right))
      if (union_size == 0L) return(NULL)
      data.frame(
        target_id = paste(pair, collapse = " | "),
        value = length(intersect(left, right)) / union_size,
        stringsAsFactors = FALSE
      )
    }
  ))

  community <- arabinoxylan_community()
  community$genome_id <- genomes
  community$gift_id <- gifts
  community$matrix <- supports
  traits <- community_traits(
    community, universes = list(arabinoxylan_universe())
  )
  overlaps <- community_metric(traits, "repertoire_overlap")
  expect_identical(overlaps$target_id, expected$target_id)
  expect_equal(overlaps$value, expected$value)
  # A named value column would travel through every downstream summary.
  expect_null(names(overlaps$value))
})

test_that("the pair trace is recorded only when it is asked for", {
  # One row per pair per shared GIFT is quadratic in the community and reaches
  # gigabytes at a few hundred genomes, while the overlaps it justifies are the
  # same either way. So it is off unless the caller wants it.
  community <- arabinoxylan_community()
  quiet <- community_traits(community, universes = list(arabinoxylan_universe()))
  traced <- community_traits(
    community, universes = list(arabinoxylan_universe()), pair_trace = TRUE
  )
  expect_equal(sum(quiet$trace$target_type == "genome_pair"), 0L)
  expect_equal(quiet$metrics, traced$metrics)

  pairs <- traced$trace[traced$trace$target_type == "genome_pair", , drop = FALSE]
  expect_true(all(pairs$metric_id == "repertoire_overlap"))
  # C and D are duplicates, so their shared GIFTs are exactly C's repertoire.
  shared <- pairs$gift_id[pairs$target_id == "C | D"]
  expect_setequal(
    shared, c("xylose_uptake_abc", "xylose_degradation_isomerase")
  )
  # A and B share nothing, so there is nothing to trace for them.
  expect_false("A | B" %in% pairs$target_id)
  expect_error(
    community_traits(community, pair_trace = "yes"), "TRUE or FALSE"
  )
})

test_that("a community is read within the full default set of universes", {
  # A catalogue that is 94% metabolic makes an unstratified reading a metabolic
  # reading wearing a general name, and the bounded anabolic universe is the
  # only one community_coverage is defined for. Everything except the pair
  # metric is cheap enough to report in all of them.
  traits <- community_traits(arabinoxylan_community(), progress = FALSE)
  expect_gt(length(traits$universes), 1L)
  labels <- vapply(traits$universes, function(u) u$label, character(1))
  expect_true("all curated GIFTs" %in% labels)
  expect_true("biomass-essential anabolic GIFTs" %in% labels)
  expect_true("community_coverage" %in% traits$metrics$metric_id)
})

test_that("the pair metric can be dropped without touching the others", {
  # repertoire_overlap is the one quantity that is quadratic in the community.
  # A community of thousands of genomes can afford every other metric within
  # every universe, and this is how it asks for them.
  community <- arabinoxylan_community()
  full <- community_traits(
    community, universes = list(arabinoxylan_universe())
  )
  without <- community_traits(
    community, universes = list(arabinoxylan_universe()), pairwise = FALSE
  )
  expect_gt(sum(full$metrics$metric_id == "repertoire_overlap"), 0L)
  expect_equal(sum(without$metrics$metric_id == "repertoire_overlap"), 0L)
  # Every other row is the row it was.
  expect_equal(
    full$metrics[full$metrics$metric_id != "repertoire_overlap", ],
    without$metrics
  )
  expect_equal(full$trace, without$trace)

  expect_error(
    community_traits(community, pairwise = "yes"), "TRUE or FALSE"
  )
  # Asking to trace an overlap that is not computed is a contradiction, not a
  # request to be quietly ignored.
  expect_error(
    community_traits(community, pairwise = FALSE, pair_trace = TRUE),
    "does not compute"
  )
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
  expect_error(community_traits(list()), "must come from gifter_community")
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
    arabinoxylan_community(), universes = list(arabinoxylan_universe()),
    abundance = c(A = 1, B = 1, C = 1, D = 1)
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

test_that("progress counts reference universes summarised, and nothing finer", {
  # The display exists because reading a large community takes minutes, so what
  # it counts has to be the work the caller asked for: the reference universes
  # the metrics are reported within, one tick each, never the GIFTs or genome
  # pairs a universe happens to contain.
  universes <- list(
    arabinoxylan_universe(),
    gift_universe(type = "metabolic", label = "metabolic GIFTs")
  )
  seen <- NULL
  counted <- integer()
  recorder <- function(total, enabled) {
    seen <<- list(total = total, enabled = enabled)
    list(
      enabled = enabled,
      update = function(done) counted <<- c(counted, done),
      done = function() invisible(NULL),
      dismiss = function() invisible(NULL)
    )
  }
  testthat::local_mocked_bindings(.universe_progress = recorder)

  community <- arabinoxylan_community()
  traits <- community_traits(community, universes = universes, progress = TRUE)
  expect_equal(seen$total, 2L)
  expect_true(seen$enabled)
  # A count that went backwards would report a universe as unread again.
  expect_false(is.unsorted(counted))
  expect_equal(max(counted), 2L)

  # The display is a display: the metrics are the same with it and without it.
  quiet <- community_traits(community, universes = universes, progress = FALSE)
  expect_false(seen$enabled)
  expect_equal(traits$metrics, quiet$metrics)
})

test_that("progress is shown to a watching console and to nobody else", {
  # A bar written into a log, a knitted document or a package check is noise,
  # and a single universe is never partway through.
  expect_identical(.resolve_progress(NULL, units = 3), interactive())
  expect_false(.resolve_progress(NULL, units = 1))

  # A malformed request is answered before any universe is built, not after the
  # walk it would have decorated.
  expect_error(
    community_traits(arabinoxylan_community(), progress = "yes"), "TRUE"
  )

  # The default is silent here, which is what keeps the metrics the only thing
  # this function puts on the console.
  expect_silent(community_traits(
    arabinoxylan_community(), universes = list(arabinoxylan_universe())
  ))
})
