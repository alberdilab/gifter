# Per-sample distributional traits over one genome catalogue. The assessment is
# inst/doc/proposal-multi-sample-datasets.md.
#
# The decisive test is self-verifying against the engine that already exists:
# whatever dataset_traits() reports for a sample must be what community_traits()
# reports for that sample's community. Everything else here protects the
# invariant that makes the vectorized derivation legitimate -- detection may
# move a denominator and may not touch a call.

dataset_universes <- function() {
  gifter:::.with_gifter_db(NULL, function(connection) {
    gifter:::.default_universes(connection)
  })
}

dataset_metric <- function(traits, id, sample = NULL, target = NULL,
                           universe = "all curated GIFTs") {
  rows <- traits$metrics[
    traits$metrics$metric_id == id &
      traits$metrics$reference_universe == universe, ,
    drop = FALSE
  ]
  if (!is.null(sample)) rows <- rows[rows$sample_id == sample, , drop = FALSE]
  if (!is.null(target)) rows <- rows[rows$target_id == target, , drop = FALSE]
  rows
}

test_that("every sample's traits are what community_traits() reports for it", {
  # The whole layer rests on this. If a matrix product and a per-sample walk
  # ever disagree, the product is wrong: the walk is the definition.
  dataset <- arabinoxylan_dataset()
  universes <- dataset_universes()
  traits <- dataset_traits(dataset, universes = universes, progress = FALSE)
  key <- c("target_type", "target_id", "metric_id", "reference_universe")
  compared <- c(key, "value", "numerator", "denominator", "assessable")
  sample_invariant <- c("gift_richness", "repertoire_overlap")
  sample_only <- c("detected_genomes", "mean_repertoire_overlap")

  for (sample in sample_id(dataset)) {
    community <- sample_community(dataset, sample)
    expected <- community_traits(
      community, universes = universes,
      abundance = dataset$abundance[community$genome_id, sample],
      progress = FALSE
    )
    rows <- expected$metrics[
      !expected$metrics$metric_id %in% sample_invariant, , drop = FALSE
    ]
    actual <- traits$metrics[
      traits$metrics$sample_id == sample &
        !traits$metrics$metric_id %in% sample_only, ,
      drop = FALSE
    ]
    expect_equal(
      as.data.frame(actual[do.call(order, actual[key]), compared]),
      as.data.frame(rows[do.call(order, rows[key]), compared]),
      ignore_attr = TRUE
    )
  }
})

test_that("the sample-invariant metrics are the same numbers, reported once", {
  dataset <- arabinoxylan_dataset()
  universes <- dataset_universes()
  traits <- dataset_traits(dataset, universes = universes, progress = FALSE)
  key <- c("target_type", "target_id", "metric_id", "reference_universe")
  # `assessable` is deliberately not compared: it counts what the whole
  # catalogue could assess, because a catalogue row belongs to no sample. The
  # metric itself is the same in every sample the genomes are detected in.
  compared <- c(key, "value", "numerator", "denominator")

  for (sample in sample_id(dataset)) {
    community <- sample_community(dataset, sample)
    expected <- community_traits(
      community, universes = universes, progress = FALSE
    )
    rows <- expected$metrics[
      expected$metrics$metric_id %in% c("gift_richness", "repertoire_overlap"), ,
      drop = FALSE
    ]
    catalogue <- traits$catalogue_metrics
    actual <- catalogue[
      (catalogue$target_type == "genome" &
         catalogue$target_id %in% community$genome_id) |
        (catalogue$target_type == "genome_pair" &
           catalogue$target_id %in% rows$target_id), ,
      drop = FALSE
    ]
    expect_equal(
      as.data.frame(actual[do.call(order, actual[key]), compared]),
      as.data.frame(rows[do.call(order, rows[key]), compared]),
      ignore_attr = TRUE
    )
  }
})

test_that("a sample's trace is what community_traits() records for it", {
  dataset <- arabinoxylan_dataset()
  universes <- dataset_universes()
  traits <- dataset_traits(dataset, universes = universes, progress = FALSE)
  for (sample in sample_id(dataset)) {
    expected <- community_traits(
      sample_community(dataset, sample), universes = universes,
      progress = FALSE
    )$trace
    actual <- trace_sample(traits, sample)
    expect_equal(
      as.data.frame(actual[do.call(order, actual), ]),
      as.data.frame(expected[do.call(order, expected), ]),
      ignore_attr = TRUE
    )
  }
})

test_that("no sample_id column appears on a row no sample can change", {
  traits <- dataset_traits(
    arabinoxylan_dataset(), universes = list(arabinoxylan_universe()),
    progress = FALSE
  )
  expect_false("sample_id" %in% names(traits$catalogue_metrics))
  expect_identical(names(traits$metrics)[[1L]], "sample_id")
  expect_setequal(
    unique(traits$catalogue_metrics$metric_id),
    c("gift_richness", "repertoire_overlap")
  )
  expect_false(any(
    traits$metrics$metric_id %in% c("gift_richness", "repertoire_overlap")
  ))
  expect_setequal(unique(traits$metrics$target_type), c("community", "gift", "genome"))
})

test_that("detection never changes a call", {
  # The invariant this layer exists to establish. Detection decides membership;
  # it may not decide what a genome encodes.
  dataset <- arabinoxylan_dataset()
  universes <- list(arabinoxylan_universe())
  loose <- dataset_traits(dataset, universes = universes, progress = FALSE)
  strict <- dataset_traits(
    dataset, universes = universes, detection = 0.15, progress = FALSE
  )
  expect_identical(loose$calls, strict$calls)
  expect_identical(loose$calls, dataset$catalogue$matrix)
  # And the per-genome repertoire is untouched, in both directions.
  expect_equal(loose$catalogue_metrics, strict$catalogue_metrics)
})

test_that("raising detection moves denominators and nothing else", {
  dataset <- arabinoxylan_dataset()
  universes <- list(arabinoxylan_universe())
  loose <- dataset_traits(dataset, universes = universes, progress = FALSE)
  strict <- dataset_traits(
    dataset, universes = universes, detection = 0.15, progress = FALSE
  )
  # s1 loses D, which shares its repertoire with C, so no capability leaves the
  # sample: only the counts that D was part of move.
  expect_equal(dataset_metric(loose, "detected_genomes", "s1")$value, 4)
  expect_equal(dataset_metric(strict, "detected_genomes", "s1")$value, 3)
  expect_equal(
    dataset_metric(loose, "community_richness", "s1")$value,
    dataset_metric(strict, "community_richness", "s1")$value
  )
  expect_equal(
    dataset_metric(loose, "provider_count", "s1", "xylose_uptake_abc")$value, 2
  )
  expect_equal(
    dataset_metric(strict, "provider_count", "s1", "xylose_uptake_abc")$value, 1
  )
  # No GIFT gains a provider by a genome being withdrawn from the sample.
  gained <- merge(
    dataset_metric(loose, "provider_count", "s1")[c("target_id", "value")],
    dataset_metric(strict, "provider_count", "s1")[c("target_id", "value")],
    by = "target_id"
  )
  expect_true(all(gained$value.y <= gained$value.x))
})

test_that("no policy or detection promotes an unsupported GIFT to supported", {
  dataset <- arabinoxylan_dataset()
  universes <- list(arabinoxylan_universe())
  quality <- c(A = 0.4, B = 0.4, C = 0.95, D = 0.95)
  read <- suppressWarnings(dataset_traits(
    dataset, universes = universes, quality = quality, policy = "completeness",
    threshold = 0.7, detection = 0.15, progress = FALSE
  ))
  supported <- read$calls %in% TRUE
  dim(supported) <- dim(read$calls)
  original <- dataset$catalogue$matrix
  expect_true(all(!supported | original))
  expect_false(any(supported & !original))
})

test_that("assessability is applied once to the catalogue, not per sample", {
  # A genome cannot be assessable in one sample and not in another: whether its
  # silence is informative is a property of how well it was observed.
  dataset <- arabinoxylan_dataset()
  universes <- list(arabinoxylan_universe())
  quality <- c(A = 0.4, B = 0.4, C = 0.95, D = 0.95)
  traits <- suppressWarnings(dataset_traits(
    dataset, universes = universes, quality = quality, policy = "completeness",
    threshold = 0.7, progress = FALSE
  ))
  # A and B are too fragmented for their silence to be read, so every negative
  # call of theirs is withheld -- once, on the catalogue, before any sample.
  for (genome in c("A", "B")) {
    negative <- !dataset$catalogue$matrix[, genome]
    expect_true(all(is.na(traits$calls[negative, genome])))
    expect_identical(
      traits$calls[!negative, genome], dataset$catalogue$matrix[!negative, genome]
    )
  }
  # s2 holds only those two, so only what they support can be assessed there.
  # s1 and s3 both hold a complete genome, and a complete genome can assess the
  # whole universe -- which is what makes the fraction a property of the
  # sample's membership and not of a per-sample re-reading of the calls.
  assessable <- dataset_metric(traits, "assessable_fraction")
  expect_equal(assessable$value[assessable$sample_id == "s1"], 1)
  expect_equal(assessable$value[assessable$sample_id == "s3"], 1)
  expect_lt(assessable$value[assessable$sample_id == "s2"], 1)
  expect_equal(assessable$numerator[assessable$sample_id == "s2"], 2L)
})

test_that("abundance is closed within each sample's detected set", {
  dataset <- arabinoxylan_dataset()
  universes <- list(arabinoxylan_universe())
  loose <- dataset_traits(dataset, universes = universes, progress = FALSE)
  # C and D alone support xylose catabolism: 0.2 + 0.1 of s1's total of 1.0.
  expect_equal(
    dataset_metric(loose, "abundance_coverage", "s1", "xylose_uptake_abc")$value,
    0.3
  )
  # In s3 the same two carry 0.4 + 0.1 of a total of 1.0, A being absent.
  expect_equal(
    dataset_metric(loose, "abundance_coverage", "s3", "xylose_uptake_abc")$value,
    0.5
  )
  # Above the threshold D is not a member, so it is not in the denominator
  # either: 0.2 of the 0.9 that A, B and C carry between them.
  strict <- dataset_traits(
    dataset, universes = universes, detection = 0.15, progress = FALSE
  )
  expect_equal(
    dataset_metric(strict, "abundance_coverage", "s1", "xylose_uptake_abc")$value,
    0.2 / 0.9
  )
})

test_that("a bounded universe reports coverage and an unbounded one refuses it", {
  dataset <- arabinoxylan_dataset()
  bounded <- gift_universe(preset = "biomass_essential_anabolism")
  unbounded <- arabinoxylan_universe()
  expect_true(isTRUE(bounded$bounded))
  expect_false(isTRUE(unbounded$bounded))
  traits <- dataset_traits(
    dataset, universes = list(bounded, unbounded), progress = FALSE
  )
  coverage <- traits$metrics[traits$metrics$metric_id == "community_coverage", ]
  expect_setequal(coverage$reference_universe, bounded$label)
  expect_setequal(coverage$sample_id, sample_id(dataset))
  expect_equal(nrow(dataset_metric(traits, "community_coverage")), 0L)
})

test_that("detected_genomes is reported beside every richness", {
  # Absence from a sample may be below detection rather than genuine, and
  # gifter models no sequencing depth. This row is what says so.
  dataset <- arabinoxylan_dataset()
  universes <- dataset_universes()
  traits <- dataset_traits(dataset, universes = universes, progress = FALSE)
  richness <- traits$metrics[traits$metrics$metric_id == "community_richness", ]
  detected <- traits$metrics[traits$metrics$metric_id == "detected_genomes", ]
  expect_equal(nrow(detected), nrow(richness))
  expect_setequal(
    paste(detected$sample_id, detected$reference_universe),
    paste(richness$sample_id, richness$reference_universe)
  )
  expect_equal(dataset_metric(traits, "detected_genomes", "s2")$value, 2)
  expect_equal(dataset_metric(traits, "detected_genomes", "s2")$denominator, 4L)
})

test_that("the one composite carries its denominator and no fabricated count", {
  dataset <- arabinoxylan_dataset()
  traits <- dataset_traits(
    dataset, universes = list(arabinoxylan_universe()), progress = FALSE
  )
  overlap <- dataset_metric(traits, "mean_repertoire_overlap", "s1")
  expect_equal(nrow(overlap), 1L)
  # A sum of Jaccard indices is not a count, so there is no numerator to give.
  expect_true(is.na(overlap$numerator))
  # Six pairs among four genomes, all comparable in this universe.
  expect_equal(overlap$denominator, 6L)
  pairs <- traits$catalogue_metrics[
    traits$catalogue_metrics$metric_id == "repertoire_overlap", ]
  expect_equal(overlap$value, mean(pairs$value))
})

test_that("pairwise = FALSE drops the pair rows and their summary together", {
  dataset <- arabinoxylan_dataset()
  universes <- list(arabinoxylan_universe())
  without <- dataset_traits(
    dataset, universes = universes, pairwise = FALSE, progress = FALSE
  )
  expect_false(any(without$catalogue_metrics$metric_id == "repertoire_overlap"))
  expect_false(any(without$metrics$metric_id == "mean_repertoire_overlap"))
  with_pairs <- dataset_traits(dataset, universes = universes, progress = FALSE)
  key <- c("sample_id", "target_type", "target_id", "metric_id")
  expect_equal(
    without$metrics,
    with_pairs$metrics[
      with_pairs$metrics$metric_id != "mean_repertoire_overlap", ,
      drop = FALSE
    ],
    ignore_attr = TRUE
  )
  expect_true(all(key %in% names(without$metrics)))
})

test_that("a sample with no detected genome is named rather than reported empty", {
  dataset <- arabinoxylan_dataset()
  expect_error(
    dataset_traits(
      dataset, universes = list(arabinoxylan_universe()), detection = 0.45,
      progress = FALSE
    ),
    "No genome is detected above detection = 0.45 in these samples: s1"
  )
})

test_that("the reading's arguments are checked before the walk", {
  dataset <- arabinoxylan_dataset()
  universes <- list(arabinoxylan_universe())
  expect_error(dataset_traits(dataset$catalogue), "must come from gifter_dataset")
  expect_error(
    dataset_traits(dataset, universes = universes, detection = -1),
    "non-negative"
  )
  expect_error(
    dataset_traits(dataset, universes = universes, pairwise = NA),
    "pairwise must be TRUE or FALSE"
  )
  expect_error(
    dataset_traits(dataset, universes = universes, progress = "yes"),
    "must be"
  )
  expect_error(
    dataset_traits(dataset, universes = list()),
    "non-empty list of gift_universe"
  )
  expect_error(
    dataset_traits(dataset, universes = universes, policy = "completeness"),
    "needs genome completeness"
  )
  expect_error(
    dataset_traits(
      dataset, universes = universes, policy = "completeness",
      quality = c(A = 0.9, B = 0.9, C = 0.9, D = 0.9)
    ),
    "explicit `threshold`"
  )
})

test_that("trace_sample() names the sample it cannot find", {
  traits <- dataset_traits(
    arabinoxylan_dataset(), universes = list(arabinoxylan_universe()),
    progress = FALSE
  )
  expect_error(trace_sample(traits, "s9"), "no sample called s9")
  expect_error(trace_sample(traits, 1), "one sample identifier")
  expect_error(trace_sample(list(), "s1"), "must come from dataset_traits")
})

test_that("the catalogue trace is the primitive every sample trace recounts", {
  traits <- dataset_traits(
    arabinoxylan_dataset(), universes = list(arabinoxylan_universe()),
    progress = FALSE
  )
  expect_setequal(traits$trace$metric_id, "provider_count")
  catalogue <- traits$trace[
    traits$trace$target_id == "xylose_uptake_abc", , drop = FALSE
  ]
  expect_setequal(catalogue$contribution, c("C", "D"))
  # A sample's providers are those, intersected with what it detected.
  sample <- trace_sample(traits, "s2")
  expect_false("xylose_uptake_abc" %in% sample$target_id)
  expect_setequal(
    trace_sample(traits, "s1")$contribution[
      trace_sample(traits, "s1")$target_id == "xylose_uptake_abc"
    ],
    c("C", "D")
  )
})

test_that("printing dataset traits says what was read and how much was detected", {
  traits <- dataset_traits(
    arabinoxylan_dataset(), universes = list(arabinoxylan_universe()),
    progress = FALSE
  )
  output <- paste(capture.output(print(traits)), collapse = "\n")
  expect_match(output, "<gifter_dataset_traits> 4 genomes x 3 samples")
  expect_match(output, "sample-invariant rows")
  expect_match(output, "detection: 0")
  expect_match(output, "s2\\s+2 / 149 supported,\\s+2 genomes detected")
})

test_that("a thin denominator is counted in sample-universe readings", {
  # A dataset reports one assessable_fraction per sample per universe, so
  # calling those universes would undercount them by the sample count. The
  # single-community wording is unchanged.
  dataset <- arabinoxylan_dataset()
  universes <- list(arabinoxylan_universe())
  quality <- c(A = 0.4, B = 0.4, C = 0.95, D = 0.95)
  expect_warning(
    dataset_traits(
      dataset, universes = universes, quality = quality,
      policy = "completeness", threshold = 0.7, progress = FALSE
    ),
    "1 of 3 sample-universe readings"
  )
  expect_warning(
    community_traits(
      sample_community(dataset, "s2"), universes = universes,
      quality = quality[c("A", "B")], policy = "completeness", threshold = 0.7,
      progress = FALSE
    ),
    "1 of 1 universes"
  )
})

test_that("a sample of one genome is read without a pair to compare", {
  catalogue <- gifter_community(
    A = arabinoxylan_genome("debrancher"),
    B = arabinoxylan_genome("backbone")
  )
  dataset <- gifter_dataset(catalogue, matrix(
    c(1, 0, 0.5, 0.5), nrow = 2,
    dimnames = list(c("A", "B"), c("lone", "both"))
  ))
  traits <- dataset_traits(
    dataset, universes = list(arabinoxylan_universe()), progress = FALSE
  )
  expect_equal(dataset_metric(traits, "detected_genomes", "lone")$value, 1)
  expect_equal(dataset_metric(traits, "community_richness", "lone")$value, 1)
  # One genome is no pair, so there is no mean of overlaps to report -- rather
  # than a mean of nothing reported as zero.
  expect_equal(nrow(dataset_metric(traits, "mean_repertoire_overlap", "lone")), 0L)
  expect_equal(nrow(dataset_metric(traits, "mean_repertoire_overlap", "both")), 1L)
  # It still agrees with community_traits() on its own community.
  expected <- community_traits(
    sample_community(dataset, "lone"),
    universes = list(arabinoxylan_universe()), progress = FALSE
  )
  expect_equal(
    dataset_metric(traits, "community_richness", "lone")$value,
    expected$metrics$value[expected$metrics$metric_id == "community_richness"]
  )
})

test_that("a universe with no member in the catalogue is read as empty", {
  dataset <- arabinoxylan_dataset()
  empty <- gift_universe(type = "structural")
  expect_equal(
    length(intersect(dataset$catalogue$gift_id, empty$gift_id)),
    length(empty$gift_id)
  )
  traits <- dataset_traits(
    dataset, universes = list(gift_universe(type = "defense")), progress = FALSE
  )
  richness <- traits$metrics[traits$metrics$metric_id == "community_richness", ]
  expect_equal(richness$value, c(0, 0, 0))
  expect_equal(nrow(traits$metrics[traits$metrics$target_type == "gift", ]), 0L)
})
