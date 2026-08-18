test_that("GIFT graph is derived only from declared anchors", {
  graph <- gift_graph()

  purine <- graph[graph$from_gift == "purine_core_biosynthesis", ]
  expect_equal(nrow(purine), 2L)
  expect_equal(purine$shared_anchor, rep("IMP", 2L))
  expect_equal(
    purine$to_gift,
    c("adenylate_biosynthesis", "guanylate_biosynthesis")
  )

  # Internal intermediates of any GIFT must never appear as a shared anchor.
  expect_false(any(
    c(
      "PRA", "GAR", "AIR", "AICAR", "FAICAR", "OAS", "CYSTATHIONINE",
      "PSER", "PHOMOSERINE", "ASPARTYL_PHOSPHATE"
    ) %in% graph$shared_anchor
  ))
})

test_that("PRPP to IMP to AMP composition is executable", {
  result <- evaluate_gifts(ko_annotations(direct_purine_markers(include_amp = TRUE)))
  complete <- result$gifts$gift_id[result$gifts$complete]
  graph <- gift_graph()

  expect_true(all(c("purine_core_biosynthesis", "adenylate_biosynthesis") %in% complete))
  expect_true(
    any(graph$from_gift %in% complete & graph$to_gift %in% complete & graph$shared_anchor == "IMP")
  )
})

test_that("PRPP to IMP composes independently with both purine branches", {
  markers <- c(direct_purine_markers(include_amp = TRUE), "K00088", "K01951")
  result <- evaluate_gifts(ko_annotations(markers))
  complete <- result$gifts$gift_id[result$gifts$complete]
  graph <- gift_graph()

  expect_true(all(c(
    "purine_core_biosynthesis", "adenylate_biosynthesis",
    "guanylate_biosynthesis"
  ) %in% complete))
  expect_equal(
    graph$to_gift[graph$from_gift == "purine_core_biosynthesis"],
    c("adenylate_biosynthesis", "guanylate_biosynthesis")
  )
})
