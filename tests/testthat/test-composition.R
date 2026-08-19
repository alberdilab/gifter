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

test_that("two adjacent reversible GIFTs are not a boundary error", {
  # The acyclicity check is scoped to the directed modes. An interconversion
  # GIFT declares every anchor in both roles, so two of them sharing one anchor
  # produce an edge in each direction whatever the chemistry does: the loop is
  # made by the mode's own boundary contract, and reporting it would be the
  # check reading that contract back as a curation error. No citric acid
  # chemistry is involved, which is the point -- this is arithmetic, not biology.
  source_dir <- giftr_source_copy()
  for (anchor in c("FIXTURE_X", "FIXTURE_Y", "FIXTURE_Z")) {
    add_test_anchor(source_dir, anchor, anchor, "unspecified")
  }
  add_test_gift(
    source_dir, "fixture_xy", "interconversion",
    c("FIXTURE_X", "FIXTURE_Y"), c("FIXTURE_X", "FIXTURE_Y")
  )
  add_test_gift(
    source_dir, "fixture_yz", "interconversion",
    c("FIXTURE_Y", "FIXTURE_Z"), c("FIXTURE_Y", "FIXTURE_Z")
  )
  expect_true(validate_giftr_sources(source_dir)$valid)

  # The exemption is scoped to that mode and to nothing else: the same loop
  # between two catabolic GIFTs is still an error.
  directed <- giftr_source_copy()
  add_test_anchor(directed, "FIXTURE_X", "FIXTURE_X", "unspecified")
  add_test_anchor(directed, "FIXTURE_Y", "FIXTURE_Y", "unspecified")
  add_test_gift(directed, "fixture_out", "catabolic", "FIXTURE_X", "FIXTURE_Y")
  add_test_gift(directed, "fixture_back", "catabolic", "FIXTURE_Y", "FIXTURE_X")
  expect_error(
    validate_giftr_sources(directed),
    "Circular catabolic GIFT composition"
  )
})

test_that("the curated database has no cycle in any directed mode", {
  # The exemption must not become a licence for undeclared loops in the modes
  # that do declare a direction. Curating the citric acid cycle added a ring to
  # the graph and left every directed partition acyclic.
  connection <- giftr_db_connect()
  withr::defer(giftr_db_disconnect(connection))
  modes <- DBI::dbGetQuery(connection, "SELECT gift_id, mode FROM gift")
  gift_mode <- stats::setNames(modes$mode, modes$gift_id)
  graph <- gift_graph()
  edges <- data.frame(
    from = graph$from_gift, to = graph$to_gift, stringsAsFactors = FALSE
  )
  for (mode in c("anabolic", "catabolic", "transport")) {
    within_mode <- edges[
      unname(gift_mode[edges$from]) %in% mode & unname(gift_mode[edges$to]) %in% mode,
      , drop = FALSE
    ]
    expect_length(giftr:::.find_graph_cycle(within_mode), 0L)
  }
})
