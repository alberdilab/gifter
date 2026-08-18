test_that("curated content declares a mode and leaves compartment unspecified", {
  gifts <- list_gifts()
  expect_true(all(gifts$mode %in% c("anabolic", "catabolic", "transport", "interconversion")))
  expect_true(all(gifts$mode[grepl("_biosynthesis", gifts$gift_id)] == "anabolic"))
  expect_true(all(gifts$mode[grepl("_degradation", gifts$gift_id)] == "catabolic"))

  # An anchor is split only where the uptake layer licensed it. Everything
  # else stays unresolved rather than being assigned a compartment by default.
  connection <- giftr_db_connect()
  withr::defer(giftr_db_disconnect(connection))
  anchors <- DBI::dbGetQuery(connection, "SELECT anchor_id, molecule, compartment FROM anchor")
  # Two ways an anchor acquires a compartment: an uptake GIFT licensed the
  # split, or the substance is extracellular by its own nature.
  licensed <- sort(unique(anchors$molecule[anchors$compartment == "cytoplasmic"]))
  expect_equal(licensed, c("ARABINOSE", "XYLOSE"))
  intrinsic <- sort(anchors$molecule[anchors$compartment == "extracellular"])
  expect_true(all(c("ARABINOXYLAN", "XYLAN", "STARCH") %in% intrinsic))
  expect_true(all(anchors$compartment[grepl("_biosynthesis", anchors$anchor_id)] == "unspecified"))

  anchors <- get_gift_anchors("purine_core_biosynthesis")
  expect_equal(anchors$molecule, anchors$anchor_id)
  expect_true(all(anchors$compartment == "unspecified"))
})

test_that("a cycle within one mode is rejected but a catabolic return is not", {
  within_mode <- giftr_source_copy()
  add_test_anchor(within_mode, "FIXTURE_X", "FIXTURE_X", "unspecified")
  add_test_anchor(within_mode, "FIXTURE_Y", "FIXTURE_Y", "unspecified")
  add_test_gift(within_mode, "fixture_forward", "catabolic", "FIXTURE_X", "FIXTURE_Y")
  add_test_gift(within_mode, "fixture_back", "catabolic", "FIXTURE_Y", "FIXTURE_X")
  expect_error(
    validate_giftr_sources(within_mode),
    "Circular catabolic GIFT composition"
  )

  # The same loop across modes is real biology: a catabolic route back to a
  # metabolite that biosynthesis produces is not a boundary error.
  across_modes <- giftr_source_copy()
  add_test_anchor(across_modes, "FIXTURE_X", "FIXTURE_X", "unspecified")
  add_test_anchor(across_modes, "FIXTURE_Y", "FIXTURE_Y", "unspecified")
  add_test_gift(across_modes, "fixture_forward", "anabolic", "FIXTURE_X", "FIXTURE_Y")
  add_test_gift(across_modes, "fixture_back", "catabolic", "FIXTURE_Y", "FIXTURE_X")
  expect_true(validate_giftr_sources(across_modes)$valid)
})

test_that("a transport GIFT must move one molecule across a boundary", {
  source_dir <- giftr_source_copy()
  add_test_anchor(source_dir, "FIXTURE_X", "FIXTURE_X", "extracellular")
  add_test_anchor(source_dir, "FIXTURE_Y", "FIXTURE_Y", "cytoplasmic")
  add_test_gift(source_dir, "fixture_transport", "transport", "FIXTURE_X", "FIXTURE_Y")
  expect_error(
    validate_giftr_sources(source_dir),
    "no molecule appears as both input and output"
  )
})

test_that("translocation outside a transport GIFT is flagged for review", {
  source_dir <- giftr_source_copy()
  add_test_anchor(source_dir, "FIXTURE_SUGAR_EX", "FIXTURE_SUGAR", "extracellular")
  add_test_anchor(source_dir, "FIXTURE_SUGAR_IN", "FIXTURE_SUGAR", "cytoplasmic")
  add_test_gift(
    source_dir, "fixture_mislabelled", "catabolic",
    "FIXTURE_SUGAR_EX", "FIXTURE_SUGAR_IN"
  )
  report <- validate_giftr_sources(source_dir)
  expect_true(report$valid)
  expect_match(report$warnings, "is not mode = transport", all = FALSE)
})

test_that("compartment decides which anchors compose", {
  source_dir <- giftr_source_copy()
  add_test_anchor(source_dir, "FIXTURE_POLYMER", "FIXTURE_POLYMER", "extracellular")
  add_test_anchor(source_dir, "FIXTURE_SUGAR_EX", "FIXTURE_SUGAR", "extracellular")
  add_test_anchor(source_dir, "FIXTURE_SUGAR_IN", "FIXTURE_SUGAR", "cytoplasmic")
  add_test_anchor(source_dir, "FIXTURE_SUGAR_ANY", "FIXTURE_SUGAR", "unspecified")
  add_test_anchor(source_dir, "FIXTURE_PRODUCT", "FIXTURE_PRODUCT", "cytoplasmic")

  add_test_gift(
    source_dir, "fixture_depolymerisation", "catabolic",
    "FIXTURE_POLYMER", "FIXTURE_SUGAR_EX"
  )
  add_test_gift(
    source_dir, "fixture_uptake", "transport",
    "FIXTURE_SUGAR_EX", "FIXTURE_SUGAR_IN"
  )
  add_test_gift(
    source_dir, "fixture_catabolism", "catabolic",
    "FIXTURE_SUGAR_IN", "FIXTURE_PRODUCT"
  )
  add_test_gift(
    source_dir, "fixture_unresolved", "catabolic",
    "FIXTURE_SUGAR_ANY", "FIXTURE_PRODUCT"
  )

  connection <- build_test_database(source_dir)
  graph <- gift_graph(db = connection)
  edge <- function(from, to) {
    graph$edge_quality[graph$from_gift == from & graph$to_gift == to]
  }

  # Same anchor on both sides: an exact composition edge.
  expect_equal(edge("fixture_depolymerisation", "fixture_uptake"), "exact")
  expect_equal(edge("fixture_uptake", "fixture_catabolism"), "exact")

  # The rule the compartment layer exists for: extracellular sugar does not
  # reach cytoplasmic sugar except through the uptake GIFT. Without this, the
  # transport GIFT would be decorative.
  expect_length(edge("fixture_depolymerisation", "fixture_catabolism"), 0L)

  # One side unresolved: traversed, and labelled so the weaker claim is visible.
  expect_equal(edge("fixture_depolymerisation", "fixture_unresolved"), "compartment_inexact")

  exact_only <- gift_graph(db = connection, quality = "exact")
  expect_false(any(exact_only$edge_quality == "compartment_inexact"))
  expect_true(all(
    c("fixture_depolymerisation", "fixture_uptake") %in% exact_only$from_gift
  ))
})

test_that("an anchor molecule may not repeat within one compartment", {
  source_dir <- giftr_source_copy()
  add_test_anchor(source_dir, "FIXTURE_ONE", "FIXTURE_MOLECULE", "cytoplasmic")
  add_test_anchor(source_dir, "FIXTURE_TWO", "FIXTURE_MOLECULE", "cytoplasmic")
  expect_error(
    validate_giftr_sources(source_dir),
    "Duplicated anchor molecule/compartment pairs"
  )
})

test_that("an unknown compartment or mode is rejected", {
  compartment_dir <- giftr_source_copy()
  add_test_anchor(compartment_dir, "FIXTURE_X", "FIXTURE_X", "periplasmic")
  expect_error(validate_giftr_sources(compartment_dir), "Invalid anchor compartment")

  mode_dir <- giftr_source_copy()
  add_test_anchor(mode_dir, "FIXTURE_X", "FIXTURE_X", "unspecified")
  add_test_anchor(mode_dir, "FIXTURE_Y", "FIXTURE_Y", "unspecified")
  add_test_gift(mode_dir, "fixture_unknown_mode", "digestive", "FIXTURE_X", "FIXTURE_Y")
  expect_error(validate_giftr_sources(mode_dir), "Invalid gifts.mode")
})
