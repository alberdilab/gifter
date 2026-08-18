test_that("the facet vocabulary is open across facets and closed within one", {
  terms <- list_facets()
  expect_true(all(terms$applies_to %in% c("gift", "anchor")))
  expect_true(all(nzchar(terms$definition)))
  expect_false(any(duplicated(paste(terms$facet, terms$value))))

  # Closed within a facet: an unregistered value must not compile.
  source_dir <- giftr_source_copy()
  append_source(source_dir, "gift_facets",
    gift_id = "xylan_degradation", facet = "physiological_role", value = "invented_role")
  expect_error(validate_giftr_sources(source_dir), "Unregistered gift_facets terms")
})

test_that("a facet registered for anchors cannot classify a GIFT", {
  source_dir <- giftr_source_copy()
  append_source(source_dir, "gift_facets",
    gift_id = "xylan_degradation", facet = "molecular_tier", value = "polymer")
  expect_error(
    validate_giftr_sources(source_dir),
    "registered for another target"
  )
})

test_that("substrate_class partitions and physiological_role does not", {
  gifts <- list_gifts()$gift_id
  for (gift_id in gifts) {
    facets <- get_facets(gift_id)
    expect_equal(sum(facets$facet == "substrate_class"), 1L)
    expect_gte(sum(facets$facet == "physiological_role"), 1L)
  }

  # Single-valued means it can partition: every GIFT appears exactly once
  # across the substrate_class values.
  classes <- list_facets("substrate_class")$value
  covered <- unlist(lapply(classes, function(v) gifts_by_facet("substrate_class", v)$gift_id))
  expect_setequal(covered, gifts)
  expect_false(any(duplicated(covered)))

  # Multi-valued means filters return supersets, not partitions.
  fibre <- gifts_by_facet("physiological_role", "fibre_degradation")$gift_id
  carbon <- gifts_by_facet("physiological_role", "carbon_acquisition")$gift_id
  expect_gt(length(intersect(fibre, carbon)), 0L)
})

test_that("a repeated substrate_class is rejected", {
  source_dir <- giftr_source_copy()
  append_source(source_dir, "gift_facets",
    gift_id = "xylan_degradation", facet = "substrate_class", value = "monosaccharide")
  expect_error(validate_giftr_sources(source_dir), "must be single-valued")
})

test_that("the derived profile reads the compartment layer, not curation", {
  profile <- gift_profile()
  expect_equal(nrow(profile), nrow(list_gifts()))

  strategy <- function(id) profile$resource_strategy[profile$gift_id == id]
  # Consumes outside, delivers inside.
  expect_equal(strategy("xylose_uptake_abc"), "uptake")
  # Consumes an extracellular polymer and releases the product outside.
  expect_equal(strategy("xylan_degradation"), "public_good")
  # Wholly internal chemistry.
  expect_equal(strategy("purine_core_biosynthesis"), "private")
  # Starch releases glucose, whose compartment was never licensed. That is a
  # real answer: the database does not know whether the product is shared.
  expect_equal(strategy("starch_degradation"), "unresolved")
})

test_that("network position and cross-feeding follow the composition graph", {
  profile <- gift_profile()
  position <- function(id) profile$network_position[profile$gift_id == id]

  expect_equal(position("arabinoxylan_debranching"), "entry")
  expect_equal(position("xylose_uptake_abc"), "intermediate")
  expect_equal(position("xylose_degradation_isomerase"), "terminal")

  # Xylan degradation releases extracellular xylose that another GIFT consumes.
  expect_equal(
    profile$cross_feeding_output[profile$gift_id == "xylan_degradation"], 1L
  )
  expect_equal(
    profile$cross_feeding_output[profile$gift_id == "purine_core_biosynthesis"], 0L
  )
})

test_that("auxotrophy is flagged from biomass-essential anabolic outputs", {
  profile <- gift_profile()
  flagged <- profile$gift_id[profile$auxotrophy_indicator == 1L]
  expect_true("methionine_biosynthesis_transsulfuration" %in% flagged)
  expect_true("adenylate_biosynthesis" %in% flagged)
  # A catabolic capability is never an auxotrophy indicator.
  expect_false(any(profile$mode[profile$auxotrophy_indicator == 1L] != "anabolic"))
  # An intermediate is not a building block.
  expect_false("homoserine_biosynthesis" %in% flagged)
})

test_that("every route declares an oxygen requirement", {
  connection <- giftr_db_connect()
  withr::defer(giftr_db_disconnect(connection))
  routes <- DBI::dbGetQuery(connection, "SELECT oxygen_requirement FROM gift_route")
  expect_true(all(routes$oxygen_requirement %in% c("aerobic", "anaerobic", "independent")))

  source_dir <- giftr_source_copy()
  gift_routes <- read_source(source_dir, "gift_routes")
  gift_routes$oxygen_requirement[[1]] <- "microaerophilic"
  write_source(source_dir, "gift_routes", gift_routes)
  expect_error(validate_giftr_sources(source_dir), "Invalid gift_routes.oxygen_requirement")
})
