# The container for one genome catalogue observed across many samples.
#
# What these tests protect is that membership and weight are the only two
# things a sample may vary, and that every way of getting them wrong -- a
# failed join, a lost identifier, an absent row read as a zero -- is refused
# rather than absorbed into a number that looks normal.

test_that("a dataset is composed of a community and inherits its checks", {
  dataset <- arabinoxylan_dataset()
  expect_s3_class(dataset, "gifter_dataset")
  expect_identical(dataset$genome_id, c("A", "B", "C", "D"))
  expect_identical(sample_id(dataset), c("s1", "s2", "s3"))
  # The calls are the catalogue's, referenced rather than copied.
  expect_identical(dataset$catalogue, arabinoxylan_community())
  expect_identical(
    .gifter_database_version_value(dataset$database_version),
    .gifter_database_version_value(dataset$catalogue$database_version)
  )
})

test_that("only a community may be a catalogue", {
  expect_error(
    gifter_dataset(
      arabinoxylan_genome("debrancher"), arabinoxylan_abundance()
    ),
    "must come from gifter_community"
  )
})

test_that("abundance must name exactly the catalogue's genomes", {
  catalogue <- arabinoxylan_community()
  abundance <- arabinoxylan_abundance()
  expect_error(
    gifter_dataset(catalogue, abundance[c("A", "B", "C"), , drop = FALSE]),
    "missing: D"
  )
  extra <- rbind(abundance, E = c(0.1, 0.1, 0.1))
  expect_error(
    gifter_dataset(catalogue, extra), "not in the catalogue: E"
  )
})

test_that("abundance without identifiers is refused rather than aligned by position", {
  catalogue <- arabinoxylan_community()
  bare <- matrix(runif(12), nrow = 4)
  expect_error(gifter_dataset(catalogue, bare), "both genome identifiers")
  rows_only <- bare
  rownames(rows_only) <- c("A", "B", "C", "D")
  expect_error(gifter_dataset(catalogue, rows_only), "both genome identifiers")
  columns_only <- bare
  colnames(columns_only) <- c("s1", "s2", "s3")
  expect_error(gifter_dataset(catalogue, columns_only), "both genome identifiers")
  expect_error(
    gifter_dataset(catalogue, as.vector(bare)),
    "genome x sample numeric matrix"
  )
})

test_that("negative, NA and non-finite abundance are refused", {
  catalogue <- arabinoxylan_community()
  negative <- arabinoxylan_abundance()
  negative["A", "s1"] <- -0.1
  expect_error(gifter_dataset(catalogue, negative), "non-negative")

  missing <- arabinoxylan_abundance()
  missing["A", "s1"] <- NA_real_
  expect_error(gifter_dataset(catalogue, missing), "finite and complete")

  infinite <- arabinoxylan_abundance()
  infinite["A", "s1"] <- Inf
  expect_error(gifter_dataset(catalogue, infinite), "finite and complete")
})

test_that("a sample no threshold could ever read is refused at construction", {
  catalogue <- arabinoxylan_community()
  abundance <- arabinoxylan_abundance()
  abundance[, "s2"] <- 0
  expect_error(gifter_dataset(catalogue, abundance), "no abundance at all.*s2")
})

test_that("a duplicated sample or genome identifier is refused", {
  catalogue <- arabinoxylan_community()
  abundance <- arabinoxylan_abundance()
  colnames(abundance) <- c("s1", "s1", "s3")
  expect_error(gifter_dataset(catalogue, abundance), "same sample twice: s1")
})

test_that("the long form pivots to the same dataset as the matrix", {
  catalogue <- arabinoxylan_community()
  from_matrix <- gifter_dataset(catalogue, arabinoxylan_abundance())
  from_long <- gifter_dataset(catalogue, arabinoxylan_long_abundance())
  expect_identical(from_long$abundance, from_matrix$abundance)
  expect_identical(from_long, from_matrix)
})

test_that("a long form missing a row is refused rather than read as zero", {
  catalogue <- arabinoxylan_community()
  long <- arabinoxylan_long_abundance()
  gap <- long[!(long$sample_id == "s2" & long$genome_id == "C"), ]
  expect_error(
    gifter_dataset(catalogue, gap),
    "row for every genome in every sample.*genome C in sample s2"
  )
})

test_that("a long form repeating a genome in a sample is refused rather than summed", {
  catalogue <- arabinoxylan_community()
  long <- arabinoxylan_long_abundance()
  long$genome_id[long$sample_id == "s1" & long$genome_id == "D"] <- "C"
  expect_error(
    gifter_dataset(catalogue, long), "same genome twice in one sample: C in s1"
  )
})

test_that("metadata must cover exactly the samples and is otherwise untouched", {
  catalogue <- arabinoxylan_community()
  abundance <- arabinoxylan_abundance()
  dataset <- gifter_dataset(catalogue, abundance, arabinoxylan_metadata())
  expect_identical(dataset$metadata$sample_id, c("s1", "s2", "s3"))
  expect_identical(dataset$metadata$group, c("treated", "control", "treated"))

  short <- arabinoxylan_metadata()[1:2, ]
  expect_error(gifter_dataset(catalogue, abundance, short), "missing: s3")

  extra <- rbind(arabinoxylan_metadata(), data.frame(
    sample_id = "s4", group = "control", stringsAsFactors = FALSE
  ))
  expect_error(
    gifter_dataset(catalogue, abundance, extra), "not in abundance: s4"
  )

  duplicated_rows <- rbind(arabinoxylan_metadata(), arabinoxylan_metadata()[1, ])
  expect_error(
    gifter_dataset(catalogue, abundance, duplicated_rows),
    "same sample twice: s1"
  )

  expect_error(
    gifter_dataset(catalogue, abundance, data.frame(group = "treated")),
    "`sample_id` column"
  )
})

test_that("metadata is reordered to the samples rather than assumed aligned", {
  catalogue <- arabinoxylan_community()
  shuffled <- arabinoxylan_metadata()[c(3, 1, 2), ]
  dataset <- gifter_dataset(catalogue, arabinoxylan_abundance(), shuffled)
  expect_identical(dataset$metadata$sample_id, c("s1", "s2", "s3"))
  expect_identical(dataset$metadata$group, c("treated", "control", "treated"))
})

test_that("a dataset holds no detection threshold, policy or design", {
  dataset <- arabinoxylan_dataset()
  expect_null(dataset$detection)
  expect_null(dataset$policy)
  expect_null(dataset$threshold)
})

test_that("sample_community() round-trips to the subset community", {
  dataset <- arabinoxylan_dataset()
  detected <- sample_community(dataset, "s2")
  expect_s3_class(detected, "gifter_community")
  expect_identical(detected$genome_id, c("A", "B"))

  expected <- do.call(gifter_community, dataset$catalogue$results[c("A", "B")])
  expect_identical(detected, expected)
})

test_that("a sample's calls are the catalogue's, restricted", {
  dataset <- arabinoxylan_dataset()
  for (sample in sample_id(dataset)) {
    community <- sample_community(dataset, sample)
    expect_identical(
      community$matrix,
      dataset$catalogue$matrix[, community$genome_id, drop = FALSE]
    )
    expect_identical(community$gift_id, dataset$catalogue$gift_id)
  }
})

test_that("the reference universe does not shrink with the sample", {
  # Genomes evaluated over different GIFT subsets are the one case where the
  # union over a sample differs from the catalogue's. Letting it shrink would
  # give every sample a different assessable denominator.
  catalogue <- arabinoxylan_community()
  narrow <- catalogue$results[["A"]]
  narrow$gifts <- narrow$gifts[seq_len(3L), , drop = FALSE]
  wide <- .gifter_community(list(A = narrow, B = catalogue$results[["B"]]))
  dataset <- gifter_dataset(wide, matrix(
    c(1, 1, 1, 0), nrow = 2, dimnames = list(c("A", "B"), c("both", "a_only"))
  ))
  expect_identical(sample_community(dataset, "a_only")$genome_id, "A")
  expect_identical(sample_community(dataset, "a_only")$gift_id, wide$gift_id)
  # The union over the sample's own genomes would have been three GIFTs, and
  # every proportion taken over it would have had a different denominator from
  # the same proportion in the sample next to it.
  expect_identical(length(.gifter_community(list(A = narrow))$gift_id), 3L)
  expect_gt(length(sample_community(dataset, "a_only")$gift_id), 3L)
})

test_that("detection moves membership and refuses an emptied sample", {
  dataset <- arabinoxylan_dataset()
  expect_identical(
    sample_community(dataset, "s1")$genome_id, c("A", "B", "C", "D")
  )
  expect_identical(
    sample_community(dataset, "s1", detection = 0.15)$genome_id,
    c("A", "B", "C")
  )
  expect_identical(
    sample_community(dataset, "s1", detection = 0.35)$genome_id, "A"
  )
  expect_error(
    sample_community(dataset, "s1", detection = 0.5),
    "No genome is detected above detection = 0.5 in these samples: s1"
  )
})

test_that("detection is checked before it is used", {
  dataset <- arabinoxylan_dataset()
  expect_error(sample_community(dataset, "s1", detection = -1), "non-negative")
  expect_error(sample_community(dataset, "s1", detection = NA), "one finite number")
  expect_error(
    sample_community(dataset, "s1", detection = c(0, 1)), "one finite number"
  )
})

test_that("an unknown sample is named rather than returned empty", {
  dataset <- arabinoxylan_dataset()
  expect_error(sample_community(dataset, "s9"), "holds no sample called s9")
  expect_error(sample_community(dataset, 1), "one sample identifier")
  expect_error(sample_id(dataset$catalogue), "needs a gifter_dataset")
})

test_that("printing a dataset says what it holds", {
  dataset <- arabinoxylan_dataset(arabinoxylan_metadata())
  output <- paste(capture.output(print(dataset)), collapse = "\n")
  expect_match(output, "<gifter_dataset> 4 genomes x 3 samples")
  expect_match(output, "detected per sample at detection = 0: 2-4")
  expect_match(output, "metadata: 1 column")
  expect_match(output, "group")
})
