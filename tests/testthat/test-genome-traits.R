# Quantitative genome traits. The assessment is
# inst/doc/proposal-quantitative-traits.md.
#
# These tests protect the properties that make a derived number reportable: it
# is computed within a declared universe, it can be taken apart into the GIFTs
# that produced it, it never claims a denominator the catalogue does not
# support, and it never changes a call.

traits_of <- function(markers, ...) {
  genome_traits(evaluate_gifts(ko_annotations(markers)), ...)
}

metric <- function(traits, id, universe) {
  rows <- traits$metrics[
    traits$metrics$metric_id == id &
      traits$metrics$reference_universe == universe, ,
    drop = FALSE
  ]
  expect_equal(nrow(rows), 1L)
  rows
}

purine_universe <- function() {
  gift_universe(facet = "substrate_class", value = "nucleotide",
                label = "nucleotide GIFTs")
}

test_that("richness counts supported GIFTs and traces every one of them", {
  traits <- traits_of(direct_purine_markers(include_amp = TRUE),
                      universes = list(purine_universe()), genome_id = "MAG_001")
  row <- metric(traits, "gift_richness", "nucleotide GIFTs")
  expect_equal(row$value, 2)
  expect_equal(row$numerator, 2L)

  trace <- traits$trace[traits$trace$metric_id == "gift_richness", , drop = FALSE]
  expect_setequal(
    trace$gift_id,
    c("purine_core_biosynthesis", "adenylate_biosynthesis")
  )
  # The trace is the audit: its rows must reconstruct the numerator exactly.
  expect_equal(nrow(trace), row$numerator)
})

test_that("richness rises only for the capability the added marker completes", {
  without <- traits_of(direct_purine_markers(),
                       universes = list(purine_universe()))
  with_amp <- traits_of(direct_purine_markers(include_amp = TRUE),
                        universes = list(purine_universe()))
  expect_equal(metric(without, "gift_richness", "nucleotide GIFTs")$value, 1)
  expect_equal(metric(with_amp, "gift_richness", "nucleotide GIFTs")$value, 2)
  expect_false(
    "adenylate_biosynthesis" %in%
      without$trace$gift_id[without$trace$metric_id == "gift_richness"]
  )
})

test_that("a fraction of the catalogue is reported only for a bounded universe", {
  # The database is not the universe of microbial function. Reporting a
  # supported fraction of all metabolic GIFTs would say a genome lacks 120
  # capabilities when the catalogue merely stops there.
  open_universe <- gift_universe(type = "metabolic", label = "metabolic GIFTs")
  closed_universe <- gift_universe(
    mode = "anabolic", auxotrophy_indicator = TRUE, bounded = TRUE,
    label = "biomass-essential anabolic GIFTs"
  )
  traits <- traits_of(
    direct_purine_markers(include_amp = TRUE),
    universes = list(open_universe, closed_universe)
  )
  fractions <- traits$metrics[traits$metrics$metric_id == "supported_fraction", ]
  expect_identical(
    unique(fractions$reference_universe), "biomass-essential anabolic GIFTs"
  )
  expect_equal(
    fractions$value,
    fractions$numerator / fractions$denominator
  )
})

test_that("every proportion carries the numerator and denominator that produced it", {
  traits <- traits_of(direct_purine_markers(include_amp = TRUE))
  proportions <- traits$metrics[traits$metrics$unit == "proportion", , drop = FALSE]
  expect_gt(nrow(proportions), 0L)
  expect_false(any(is.na(proportions$numerator)))
  expect_false(any(is.na(proportions$denominator)))
  expect_true(all(proportions$denominator > 0L))
  expect_equal(proportions$value, proportions$numerator / proportions$denominator)
})

test_that("breadth counts distinct classifications, not GIFTs", {
  # Two supported GIFTs that share a substrate class contribute one class. This
  # is the whole point of breadth: raw richness overcounts a subdivided region
  # of the ontology.
  universe <- purine_universe()
  traits <- traits_of(direct_purine_markers(include_amp = TRUE),
                      universes = list(universe))
  richness <- metric(traits, "gift_richness", "nucleotide GIFTs")$value
  breadth <- metric(traits, "breadth_substrate_class", "nucleotide GIFTs")$value
  expect_equal(richness, 2)
  expect_equal(breadth, 1)
  expect_lte(breadth, richness)
})

test_that("a breadth denominator is the classifications available in the universe", {
  traits <- traits_of(direct_purine_markers(include_amp = TRUE))
  breadths <- traits$metrics[
    startsWith(traits$metrics$metric_id, "breadth_") &
      traits$metrics$reference_universe == "all curated GIFTs", ,
    drop = FALSE
  ]
  expect_gt(nrow(breadths), 0L)
  expect_true(all(breadths$numerator <= breadths$denominator))
  substrate <- breadths[breadths$metric_id == "breadth_substrate_class", ]
  expect_equal(
    substrate$denominator,
    length(unique(gift_profile()$substrate_class))
  )
})

test_that("handoff degrees count anchors and are withheld where anchors do not exist", {
  # A structural GIFT declares no anchors, so a universe of them has no handoff
  # interface to report. Reporting zero would imply a test the genome failed.
  metabolic <- gift_universe(type = "metabolic", label = "metabolic GIFTs")
  structural <- gift_universe(type = "structural", label = "structural GIFTs")
  traits <- traits_of(direct_purine_markers(include_amp = TRUE),
                      universes = list(metabolic, structural))
  reported <- traits$metrics$reference_universe[
    traits$metrics$metric_id == "handoff_out_degree"
  ]
  expect_identical(reported, "metabolic GIFTs")

  # PRPP > IMP releases IMP, which IMP > AMP consumes: one outgoing anchor.
  out_degree <- metric(traits, "handoff_out_degree", "metabolic GIFTs")
  expect_gte(out_degree$value, 1)
  trace <- traits$trace[traits$trace$metric_id == "handoff_out_degree", ]
  expect_true("purine_core_biosynthesis" %in% trace$gift_id)
  expect_true(all(trace$contribution %in% gift_graph()$shared_anchor))
})

test_that("cycle closure is reported without changing a call", {
  traits <- traits_of(direct_purine_markers(include_amp = TRUE))
  closed <- traits$metrics[traits$metrics$metric_id == "closed_cycles", ]
  expect_equal(nrow(closed), 1L)
  expect_equal(closed$denominator, length(unique(gift_cycles()$cycle_id)))
  # A purine genome closes no cycle of central metabolism, and saying so must
  # not have removed a capability it does encode.
  expect_equal(closed$value, 0)
  expect_equal(
    metric(traits, "gift_richness", "all curated GIFTs")$value, 2
  )
})

test_that("a genome supporting nothing reports zeros, not missing rows", {
  # An empty repertoire is an answer. Dropping the rows would make a genome
  # with no curated capability indistinguishable from an unevaluated one.
  traits <- genome_traits(evaluate_gifts(ko_annotations("K99999")))
  richness <- traits$metrics[traits$metrics$metric_id == "gift_richness", ]
  expect_gt(nrow(richness), 0L)
  expect_true(all(richness$value == 0))
  expect_true(all(richness$assessable > 0L))
})

test_that("every metric names its universe, its assessable count and its version", {
  traits <- traits_of(direct_purine_markers(include_amp = TRUE),
                      genome_id = "MAG_042")
  expect_true(all(nzchar(traits$metrics$reference_universe)))
  expect_true(all(nzchar(traits$metrics$derivation_method)))
  expect_true(all(traits$metrics$assessable > 0L))
  expect_true(all(traits$metrics$target_id == "MAG_042"))
  expect_true(all(traits$metrics$target_type == "genome"))
  expect_true(all(
    traits$metrics$database_version == gifter_db_version()$gifter_db_version
  ))
  # Assessability is not yet modelled, so every member of a universe was
  # assessed. Phase 4 changes what fills this column, not its presence.
  richness <- traits$metrics[traits$metrics$metric_id == "gift_richness", ]
  sizes <- vapply(traits$universes, function(u) length(u$gift_id), integer(1))
  expect_setequal(richness$assessable, sizes)
})

test_that("every trace row belongs to a metric that was reported", {
  traits <- traits_of(direct_purine_markers(include_amp = TRUE))
  key <- function(frame) paste(frame$metric_id, frame$reference_universe)
  expect_true(all(key(traits$trace) %in% key(traits$metrics)))
  expect_true(all(traits$trace$gift_id %in% list_gifts()$gift_id))
})

test_that("traits refuse inputs that are not calls, and identifiers that are not names", {
  expect_error(genome_traits(list()), "must come from evaluate_gifts")
  result <- evaluate_gifts(ko_annotations(direct_purine_markers()))
  expect_error(genome_traits(result, genome_id = c("a", "b")), "one non-empty identifier")
  expect_error(genome_traits(result, universes = list()), "non-empty list")
  expect_error(genome_traits(result, universes = list("metabolic")), "non-empty list")
})

test_that("universes built against another release are refused", {
  # Comparing calls across releases compares different universes. A silent
  # mismatch would make two incomparable numbers look comparable.
  result <- evaluate_gifts(ko_annotations(direct_purine_markers()))
  stale <- gift_universe(type = "metabolic")
  stale$database_version <- "0000.0.0"
  expect_error(
    genome_traits(result, universes = list(stale)),
    "built against a different database version"
  )
})

test_that("min_confidence excludes calls resting on ambiguous evidence", {
  # GH2, GH3, GH13, GH31 and GH43 are carried by nearly every gut Bacteroidetes
  # genome and are polyspecific enough to assert no particular activity. They
  # call the whole polysaccharide layer complete, and every metric counted that
  # until confidence was allowed to gate it.
  result <- evaluate_gifts(c("GH2", "GH3", "GH13", "GH31", "GH43"))
  universes <- list(gift_universe(preset = "carbohydrate_degradation"))
  richness <- function(...) {
    traits <- genome_traits(result, universes = universes, ...)
    traits$metrics$value[traits$metrics$metric_id == "gift_richness"]
  }
  expect_equal(richness(), 3)
  expect_equal(richness(min_confidence = "high-confidence"), 0)

  # Weak evidence is not evidence of absence, so the capability leaves the
  # denominator with the numerator rather than counting as a negative call.
  gated <- genome_traits(
    result, universes = universes, min_confidence = "high-confidence"
  )
  assessable <- gated$metrics$assessable[gated$metrics$metric_id == "gift_richness"]
  ungated <- genome_traits(result, universes = universes)
  expect_lt(
    assessable,
    ungated$metrics$assessable[ungated$metrics$metric_id == "gift_richness"]
  )
})

test_that("min_confidence leaves well-evidenced calls alone", {
  result <- evaluate_gifts(c("GH11_e15", "GH120"))
  universes <- list(gift_universe(preset = "carbohydrate_degradation"))
  for (floor in c("ambiguous", "high-confidence", "curated")) {
    traits <- genome_traits(result, universes = universes, min_confidence = floor)
    expect_equal(
      traits$metrics$value[traits$metrics$metric_id == "gift_richness"], 1
    )
  }
  expect_error(
    genome_traits(result, universes = universes, min_confidence = "excellent"),
    "min_confidence must be one of"
  )
})

# Where a resource comes from. `resource_origin` is curated on anchors, so
# until it was split by anchor role it classified no GIFT and reached no trait.
# These protect the split, the denominators, and the boundary between a
# declared origin and a claim about what an organism eats.

test_that("an anchor's resource origin classifies the GIFTs that declare it", {
  traits <- genome_traits(
    arabinoxylan_genome("backbone"),
    universes = list(gift_universe(
      facet = "substrate_class", value = "polysaccharide",
      label = "polysaccharide GIFTs"
    )),
    genome_id = "backbone"
  )
  row <- metric(traits, "breadth_input_resource_origin", "polysaccharide GIFTs")
  expect_equal(row$value, 1)

  supported <- metric(
    traits, "supported_gifts_input_resource_origin:plant_derived",
    "polysaccharide GIFTs"
  )
  expect_equal(supported$numerator, 1L)
  # Every row of a one-genome result names that genome. A facet value is a
  # breakdown of its traits, not another thing the traits are about.
  expect_equal(supported$target_type, "genome")
  expect_equal(supported$target_id, "backbone")

  trace <- traits$trace[
    traits$trace$metric_id ==
      "supported_gifts_input_resource_origin:plant_derived", ,
    drop = FALSE
  ]
  expect_equal(trace$gift_id, "xylan_degradation")
  expect_equal(nrow(trace), supported$numerator)
})

test_that("consuming an origin and releasing it are separate facets", {
  traits <- genome_traits(
    arabinoxylan_genome("consumer"), genome_id = "consumer"
  )
  facets <- unique(traits$metrics$metric_id)
  expect_true("breadth_input_resource_origin" %in% facets)
  expect_true("breadth_output_resource_origin" %in% facets)
  # xylose_degradation_isomerase enters on a plant-derived anchor and releases
  # a central-metabolism one. One resource_origin count would add the two
  # opposite positions together.
  expect_false("breadth_resource_origin" %in% facets)

  values <- function(facet) {
    rows <- traits$trace[
      traits$trace$metric_id == paste0("breadth_", facet) &
        traits$trace$reference_universe == "all curated GIFTs" &
        traits$trace$gift_id == "xylose_degradation_isomerase", ,
      drop = FALSE
    ]
    rows$contribution
  }
  expect_equal(values("input_resource_origin"), "plant_derived")
  expect_equal(values("output_resource_origin"), "central_metabolism")
})

test_that("a facet value count is over the GIFTs carrying it, not the universe", {
  traits <- genome_traits(
    arabinoxylan_genome("backbone"),
    universes = list(gift_universe(label = "all curated GIFTs")),
    genome_id = "backbone"
  )
  rows <- traits$metrics[
    startsWith(traits$metrics$metric_id, "supported_gifts_"), , drop = FALSE
  ]
  expect_true(nrow(rows) > 0L)
  expect_true(all(rows$unit == "count"))
  # The denominator is the assessable GIFTs carrying the value. It must never
  # be the universe, which would read as a fraction of the catalogue.
  expect_true(all(rows$denominator <= rows$assessable))
  expect_true(all(rows$numerator <= rows$denominator))
  # Only a value the genome reaches is reported; a value it reaches nothing of
  # is counted in the breadth denominator instead.
  expect_true(all(rows$numerator > 0L))
})

test_that("a facet value count reconstructs from its trace in every universe", {
  traits <- genome_traits(
    arabinoxylan_genome("consumer"), genome_id = "consumer"
  )
  rows <- traits$metrics[
    startsWith(traits$metrics$metric_id, "supported_gifts_"), , drop = FALSE
  ]
  expect_true(nrow(rows) > 0L)
  for (index in seq_len(nrow(rows))) {
    trace <- traits$trace[
      traits$trace$metric_id == rows$metric_id[[index]] &
        traits$trace$reference_universe == rows$reference_universe[[index]], ,
      drop = FALSE
    ]
    expect_equal(nrow(trace), rows$numerator[[index]])
  }
})

test_that("no resource origin promotes an unsupported GIFT to supported", {
  markers <- ko_annotations(direct_purine_markers())
  before <- evaluate_gifts(markers)$gifts
  traits <- genome_traits(evaluate_gifts(markers), genome_id = "MAG_001")
  after <- traits$trace[traits$trace$metric_id == "gift_richness", , drop = FALSE]
  expect_true(all(after$gift_id %in% before$gift_id[before$complete]))
})
