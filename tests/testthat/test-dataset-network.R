# Per-sample handoff topology. The assessment is
# inst/doc/proposal-multi-sample-datasets.md §9.
#
# Invariant 22 is what these tests protect. Detection decides which genomes are
# in a sample's community and nothing else: it adds no compatibility rule, does
# not relax the extracellular gate, and cannot make an edge exist that
# community_network() would not have found in that sample's community.

sample_rows <- function(table, sample) {
  table[table$sample_id == sample, , drop = FALSE]
}

test_that("every sample's topology is what community_network() reports for it", {
  dataset <- arabinoxylan_dataset()
  network <- dataset_network(dataset)
  for (sample in sample_id(dataset)) {
    expected <- community_network(sample_community(dataset, sample))
    columns <- setdiff(names(expected$edges), "sample_id")
    expect_equal(
      as.data.frame(sample_rows(network$edges, sample)[columns]),
      as.data.frame(expected$edges), ignore_attr = TRUE
    )
    expect_equal(
      as.data.frame(sample_rows(network$nodes, sample)[names(expected$nodes)]),
      as.data.frame(expected$nodes), ignore_attr = TRUE
    )
    expect_equal(
      as.data.frame(
        sample_rows(network$chain_coverage, sample)[names(expected$chain_coverage)]
      ),
      as.data.frame(expected$chain_coverage), ignore_attr = TRUE
    )
    expect_equal(
      as.data.frame(
        sample_rows(network$cycle_coverage, sample)[names(expected$cycle_coverage)]
      ),
      as.data.frame(expected$cycle_coverage), ignore_attr = TRUE
    )
    # Every number and every denominator, but not the prose: a dataset's
    # derivation says "detected in this sample", which is what its denominator
    # actually is.
    quantities <- setdiff(.metric_columns, "derivation_method")
    expect_equal(
      as.data.frame(sample_rows(network$metrics, sample)[quantities]),
      as.data.frame(expected$metrics[quantities]), ignore_attr = TRUE
    )
  }
})

test_that("a dataset metric says its denominator is the sample's membership", {
  network <- dataset_network(arabinoxylan_dataset())
  derivations <- unique(network$metrics$derivation_method)
  expect_true(all(grepl("this sample", derivations)))
})

test_that("a genome undetected in a sample contributes no edge there", {
  dataset <- arabinoxylan_dataset()
  network <- dataset_network(dataset)
  # The curated chain is A --XYLAN--> B --XYLOSE_EX--> C and D.
  expect_equal(nrow(sample_rows(network$edges, "s1")), 3L)
  # s2 holds only A and B, so the two handoffs into the consumers are gone.
  s2 <- sample_rows(network$edges, "s2")
  expect_equal(nrow(s2), 1L)
  expect_identical(s2$from_genome, "A")
  expect_identical(s2$to_genome, "B")
  # s3 holds no A, so nothing hands xylan to B.
  s3 <- sample_rows(network$edges, "s3")
  expect_false("A" %in% c(s3$from_genome, s3$to_genome))
  expect_setequal(s3$to_genome, c("C", "D"))
  expect_true(all(network$edges$from_genome %in% dataset$genome_id))
})

test_that("density is over the ordered pairs of the sample's detected genomes", {
  dataset <- arabinoxylan_dataset()
  network <- dataset_network(dataset)
  density <- network$metrics[
    network$metrics$metric_id == "interaction_density", , drop = FALSE
  ]
  # Four genomes are twelve ordered pairs, two are two, three are six.
  expect_equal(density$denominator, c(12L, 2L, 6L))
  expect_equal(density$numerator, c(3L, 1L, 2L))
})

test_that("raising detection removes genomes and never adds an edge", {
  dataset <- arabinoxylan_dataset()
  loose <- dataset_network(dataset)
  strict <- dataset_network(dataset, detection = 0.15)
  for (sample in sample_id(dataset)) {
    kept <- sample_rows(strict$edges, sample)
    all_edges <- sample_rows(loose$edges, sample)
    expect_lte(nrow(kept), nrow(all_edges))
    if (nrow(kept)) {
      expect_true(all(paste(kept$from_genome, kept$to_genome, kept$shared_anchor)
                      %in% paste(all_edges$from_genome, all_edges$to_genome,
                                 all_edges$shared_anchor)))
    }
  }
  # D falls below the threshold in s1, so the handoff into it goes with it.
  expect_false("D" %in% sample_rows(strict$edges, "s1")$to_genome)
  expect_true("D" %in% sample_rows(loose$edges, "s1")$to_genome)
})

test_that("the extracellular gate is where it was", {
  # XYLOSE_IN is cytoplasmic. C and D each encode both uptake and catabolism,
  # so a rule that projected every composition link across a genome pair would
  # hand one organism a molecule that never leaves a cell -- in every sample.
  dataset <- arabinoxylan_dataset()
  network <- dataset_network(dataset)
  expect_false("XYLOSE_IN" %in% network$edges$shared_anchor)
  internal <- network$chain_coverage[
    network$chain_coverage$shared_anchor == "XYLOSE_IN", , drop = FALSE
  ]
  expect_true(all(internal$status %in% c("within_genome", "not_transferable",
                                         "not_represented")))
  expect_true(all(!internal$transferable))
  # And every edge still carries the quality of the GIFT edge beneath it.
  expect_true(all(
    network$edges$edge_quality %in% c("exact", "compartment_inexact")
  ))
})

test_that("no cycle is closed across a sample's community", {
  # Central metabolism runs on intermediates that never leave a cell, so the
  # honest answer is negative and stays negative per sample.
  network <- dataset_network(arabinoxylan_dataset())
  expect_false(any(network$cycle_coverage$status == "community_distributed"))
})

test_that("the universe restricts which GIFTs may form an edge", {
  dataset <- arabinoxylan_dataset()
  narrow <- gift_universe(mode = "anabolic")
  network <- dataset_network(dataset, universe = narrow)
  expect_equal(nrow(network$edges), 0L)
  expect_identical(network$universe$label, narrow$label)
  wide <- dataset_network(dataset)
  expect_gt(nrow(wide$edges), 0L)
})

test_that("the reading's arguments are checked", {
  dataset <- arabinoxylan_dataset()
  expect_error(dataset_network(dataset$catalogue), "must come from gifter_dataset")
  expect_error(dataset_network(dataset, interaction = "co_occurrence"), "arg")
  expect_error(dataset_network(dataset, quality = "approximate"), "arg")
  expect_error(dataset_network(dataset, universe = "all"), "gift_universe")
  expect_error(dataset_network(dataset, detection = -1), "non-negative")
  expect_error(
    dataset_network(dataset, detection = 0.45),
    "No genome is detected above detection = 0.45"
  )
})

test_that("printing a dataset network says what it found and where it stops", {
  network <- dataset_network(arabinoxylan_dataset())
  output <- paste(capture.output(print(network)), collapse = "\n")
  expect_match(output, "<gifter_dataset_network> metabolic_handoff")
  expect_match(output, "samples: 3")
  expect_match(output, "potential handoffs: 6")
  expect_match(output, "interaction density: 0.250-0.500")
  expect_match(output, "detection: 0")
})

test_that("a sample of one genome has no ordered pair to be a density over", {
  catalogue <- gifter_community(
    A = arabinoxylan_genome("debrancher"),
    B = arabinoxylan_genome("backbone")
  )
  dataset <- gifter_dataset(catalogue, matrix(
    c(1, 0, 0.5, 0.5), nrow = 2,
    dimnames = list(c("A", "B"), c("lone", "both"))
  ))
  network <- dataset_network(dataset)
  lone <- sample_rows(network$metrics, "lone")
  density <- lone[lone$metric_id == "interaction_density", ]
  expect_true(is.na(density$value))
  expect_equal(density$denominator, 0L)
  expect_equal(nrow(sample_rows(network$edges, "lone")), 0L)
  expect_equal(nrow(sample_rows(network$edges, "both")), 1L)
  # And the range printed is over the samples that have one.
  expect_match(
    paste(capture.output(print(network)), collapse = "\n"),
    "interaction density: 0.500-0.500"
  )
})
