# The export surface. The assessment is
# inst/doc/proposal-multi-sample-datasets.md, decision 4.8.
#
# gifter stops at the matrix. What these tests protect is that the matrix
# arrives with the one thing that makes it worth exporting -- the third state --
# intact, and with the universe and release that make its columns comparable
# still attached to it.

test_that("the three states survive the export", {
  dataset <- arabinoxylan_dataset()
  quality <- c(A = 0.4, B = 0.4, C = 0.95, D = 0.95)
  matrix <- gift_matrix(
    dataset, quality = quality, policy = "completeness", threshold = 0.7
  )
  expect_true(is.logical(matrix))
  # A fragmented genome's negative calls are withheld, not zeroed. A zero in
  # their place is a fabricated absence and every model fitted on it inherits
  # the fabrication.
  expect_true(all(is.na(matrix["A", !dataset$catalogue$matrix[, "A"]])))
  expect_true(all(matrix["A", dataset$catalogue$matrix[, "A"]]))
  # A complete genome's silence is read as absence, and is FALSE rather than NA.
  expect_false(anyNA(matrix["C", ]))
  expect_true(any(matrix["C", ]))
  expect_true(any(!matrix["C", ]))
  expect_setequal(unique(as.vector(matrix)), c(TRUE, FALSE, NA))
})

test_that("the default policy exports a Boolean matrix and says so", {
  matrix <- gift_matrix(arabinoxylan_community())
  expect_false(anyNA(matrix))
  expect_identical(attr(matrix, "assessability_policy"), "none")
})

test_that("rows are genomes and columns are GIFTs", {
  community <- arabinoxylan_community()
  matrix <- gift_matrix(community)
  expect_identical(rownames(matrix), community$genome_id)
  expect_identical(colnames(matrix), community$gift_id)
  # The transpose of what a community holds internally, because rows are
  # observations in every package this is handed to.
  expect_equal(matrix, t(community$matrix), ignore_attr = TRUE)
})

test_that("a dataset delegates to its catalogue", {
  dataset <- arabinoxylan_dataset()
  expect_identical(gift_matrix(dataset), gift_matrix(dataset$catalogue))
})

test_that("the universe restriction is honoured and carried", {
  dataset <- arabinoxylan_dataset()
  universe <- gift_universe(preset = "carbohydrate_degradation")
  matrix <- gift_matrix(dataset, universe = universe)
  expect_setequal(
    colnames(matrix), intersect(dataset$catalogue$gift_id, universe$gift_id)
  )
  expect_lt(ncol(matrix), length(dataset$catalogue$gift_id))
  expect_identical(attr(matrix, "reference_universe"), universe$label)
  expect_identical(
    attr(matrix, "database_version"),
    .gifter_database_version_value(dataset$database_version)
  )
  # Without one, the columns are the GIFTs the evaluation produced, and the
  # attribute says that rather than naming a universe nobody declared.
  expect_identical(
    attr(gift_matrix(dataset), "reference_universe"), "every GIFT evaluated"
  )
})

test_that("a matrix from one release is not silently exported against another", {
  community <- arabinoxylan_community()
  universe <- arabinoxylan_universe()
  universe$database_version <- "0000.0.0"
  expect_error(
    gift_matrix(community, universe = universe), "different database version"
  )
  expect_error(gift_matrix(list()), "gifter_community or a gifter_dataset")
  expect_error(gift_matrix(community, universe = "all"), "gift_universe")
})

test_that("dataset_matrix() reshapes one metric to samples by target", {
  dataset <- arabinoxylan_dataset()
  traits <- dataset_traits(
    dataset, universes = list(arabinoxylan_universe()), progress = FALSE
  )
  matrix <- dataset_matrix(traits, "provider_count")
  expect_identical(rownames(matrix), sample_id(dataset))
  expect_true("xylose_uptake_abc" %in% colnames(matrix))
  expect_equal(matrix["s1", "xylose_uptake_abc"], 2)
  expect_identical(attr(matrix, "metric_id"), "provider_count")
  expect_identical(attr(matrix, "reference_universe"), "all curated GIFTs")
})

test_that("an absent cell is not a zero unless the caller says so", {
  dataset <- arabinoxylan_dataset()
  traits <- dataset_traits(
    dataset, universes = list(arabinoxylan_universe()), progress = FALSE
  )
  # No genome detected in s2 supports xylose uptake, so nothing was reported.
  # Whether that is a true zero or a GIFT nothing there could assess is the
  # distinction the assessability layer exists to keep, so gifter does not guess.
  expect_true(is.na(dataset_matrix(traits, "provider_count")["s2", "xylose_uptake_abc"]))
  filled <- dataset_matrix(traits, "provider_count", fill = 0)
  expect_equal(filled["s2", "xylose_uptake_abc"], 0)
  expect_equal(filled["s1", "xylose_uptake_abc"], 2)
})

test_that("a metric spanning several universes must name one", {
  dataset <- arabinoxylan_dataset()
  universes <- list(arabinoxylan_universe(), gift_universe(mode = "catabolic"))
  traits <- dataset_traits(dataset, universes = universes, progress = FALSE)
  expect_error(
    dataset_matrix(traits, "community_richness"),
    "reported for 2 reference universes"
  )
  matrix <- dataset_matrix(
    traits, "community_richness", universe = "all curated GIFTs"
  )
  expect_equal(dim(matrix), c(3L, 1L))
  expect_equal(matrix[, "community"], c(s1 = 4, s2 = 2, s3 = 3))
  expect_error(
    dataset_matrix(traits, "community_richness", universe = "nowhere"),
    "was not reported for the reference universe nowhere"
  )
  expect_error(dataset_matrix(traits, "not_a_metric"), "No metric called")
  expect_error(dataset_matrix(list(), "x"), "must come from dataset_traits")
})

test_that("the metadata join neither drops nor duplicates a sample", {
  dataset <- arabinoxylan_dataset(arabinoxylan_metadata())
  traits <- dataset_traits(
    dataset, universes = list(arabinoxylan_universe()), progress = FALSE
  )
  frame <- as.data.frame(traits)
  expect_s3_class(frame, "data.frame")
  expect_identical(nrow(frame), nrow(traits$metrics))
  expect_true("group" %in% names(frame))
  expect_identical(
    frame$group, c("treated", "control", "treated")[match(frame$sample_id, c("s1", "s2", "s3"))]
  )
  expect_setequal(unique(frame$sample_id), sample_id(dataset))
  # Sample-invariant rows belong to no sample, so they are not in the join.
  expect_false(any(frame$metric_id %in% c("gift_richness", "repertoire_overlap")))
})

test_that("a dataset without metadata joins to nothing and loses nothing", {
  traits <- dataset_traits(
    arabinoxylan_dataset(), universes = list(arabinoxylan_universe()),
    progress = FALSE
  )
  frame <- as.data.frame(traits)
  expect_identical(names(frame), names(traits$metrics))
  expect_identical(nrow(frame), nrow(traits$metrics))
})
