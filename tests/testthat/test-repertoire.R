# Distance between genomes by encoded repertoire.
#
# The property that matters most is agreement: these are the numbers
# community_traits() already reports as `repertoire_overlap`, in another shape.
# A second implementation that quietly disagreed with the first would be worse
# than no second implementation.

test_that("the distance is the overlap community_traits() reports, subtracted from one", {
  community <- do.call(gifter_community, list(
    debrancher = arabinoxylan_genome("debrancher"),
    backbone = arabinoxylan_genome("backbone"),
    consumer = arabinoxylan_genome("consumer")
  ))
  universe <- gift_universe(label = "all curated GIFTs")
  traits <- community_traits(
    community, universes = list(universe), progress = FALSE
  )
  overlaps <- traits$metrics[
    traits$metrics$metric_id == "repertoire_overlap", , drop = FALSE
  ]
  expect_true(nrow(overlaps) > 0L)

  distance <- as.matrix(repertoire_distance(community, universe = universe))
  for (index in seq_len(nrow(overlaps))) {
    pair <- strsplit(overlaps$target_id[[index]], " | ", fixed = TRUE)[[1L]]
    expect_equal(
      distance[pair[[1L]], pair[[2L]]], 1 - overlaps$value[[index]]
    )
  }
})

test_that("the result is a dist over the genomes, labelled with them", {
  community <- do.call(gifter_community, list(
    debrancher = arabinoxylan_genome("debrancher"),
    backbone = arabinoxylan_genome("backbone"),
    consumer = arabinoxylan_genome("consumer")
  ))
  distance <- repertoire_distance(community)
  expect_s3_class(distance, "dist")
  expect_setequal(labels(distance), c("debrancher", "backbone", "consumer"))
  expect_equal(length(distance), 3L)
  expect_true(all(stats::na.omit(as.vector(distance)) >= 0))
  expect_true(all(stats::na.omit(as.vector(distance)) <= 1))
})

test_that("a genome is at no distance from a genome with the same repertoire", {
  community <- do.call(gifter_community, list(
    backbone = arabinoxylan_genome("backbone"),
    twin = arabinoxylan_genome("backbone"),
    consumer = arabinoxylan_genome("consumer")
  ))
  distance <- as.matrix(repertoire_distance(community))
  expect_equal(distance["backbone", "twin"], 0)
  expect_gt(distance["backbone", "consumer"], 0)
})

test_that("two genomes supporting nothing have no distance rather than one", {
  empty <- evaluate_gifts(data.frame(
    gene_id = "g1", namespace = "KO", accession = "K01198"
  ))
  community <- gifter_community(
    one = empty, two = empty, consumer = arabinoxylan_genome("consumer")
  )
  distance <- as.matrix(repertoire_distance(community))
  # Reporting 1 would say they were compared and found to share nothing.
  expect_true(is.na(distance["one", "two"]))
  # An empty repertoire against a non-empty one is a different case: the union
  # is not empty, they genuinely share none of it, and 1 is the right answer.
  expect_equal(distance["one", "consumer"], 1)
})

test_that("a dataset delegates to its catalogue", {
  catalogue <- evaluate_gifts_community(arabinoxylan_table(), workers = 1)
  abundance <- matrix(
    c(4, 1, 2, 0, 3, 5), nrow = length(catalogue$genome_id),
    dimnames = list(catalogue$genome_id, c("s1", "s2"))
  )
  dataset <- gifter_dataset(catalogue, abundance)
  # A pair shares what it shares in every sample both are detected in, so the
  # distance cannot carry a sample.
  expect_equal(
    as.matrix(repertoire_distance(dataset)),
    as.matrix(repertoire_distance(catalogue))
  )
})

test_that("the universe restricts what is compared and is carried on the result", {
  community <- do.call(gifter_community, list(
    debrancher = arabinoxylan_genome("debrancher"),
    consumer = arabinoxylan_genome("consumer")
  ))
  universe <- gift_universe(
    facet = "substrate_class", value = "polysaccharide",
    label = "polysaccharide GIFTs"
  )
  distance <- repertoire_distance(community, universe = universe)
  expect_equal(attr(distance, "reference_universe"), "polysaccharide GIFTs")
  expect_equal(
    attr(distance, "database_version"), gifter_db_version()$gifter_db_version
  )
  expect_true(is.na(attr(distance, "min_confidence")))

  # The catalogue is overwhelmingly metabolic, so a stratified distance and an
  # unstratified one are different readings and must be able to differ.
  everything <- repertoire_distance(community)
  expect_equal(attr(everything, "reference_universe"), "every GIFT evaluated")
})

test_that("a universe from another release is refused", {
  community <- do.call(gifter_community, list(
    debrancher = arabinoxylan_genome("debrancher"),
    consumer = arabinoxylan_genome("consumer")
  ))
  universe <- gift_universe(label = "all curated GIFTs")
  universe$database_version <- "0000.0.0"
  expect_error(
    repertoire_distance(community, universe = universe),
    "different database version"
  )
})

test_that("a distance needs two genomes to compare", {
  community <- gifter_community(only = arabinoxylan_genome("consumer"))
  expect_error(repertoire_distance(community), "at least two genomes")
  expect_error(repertoire_distance(list()), "gifter_community")
})

test_that("min_confidence moves the distance and is recorded on it", {
  community <- do.call(gifter_community, list(
    debrancher = arabinoxylan_genome("debrancher"),
    backbone = arabinoxylan_genome("backbone"),
    consumer = arabinoxylan_genome("consumer")
  ))
  strict <- repertoire_distance(community, min_confidence = "curated")
  expect_equal(attr(strict, "min_confidence"), "curated")
  # Removing positives from a repertoire can only remove what a pair shares.
  loose <- as.matrix(repertoire_distance(community))
  strict_matrix <- as.matrix(strict)
  comparable <- !is.na(loose) & !is.na(strict_matrix)
  expect_true(all(strict_matrix[comparable] >= loose[comparable] - 1e-9))
})
