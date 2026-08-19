# Reference universes. The assessment is inst/doc/proposal-quantitative-traits.md.
#
# A universe is the denominator of every quantitative trait, so these tests
# protect two things. First, that a universe is built from curated metadata and
# resolves to the GIFTs that metadata actually classifies -- not to a list
# written in R. Second, that `bounded` stays a deliberate biological claim,
# because it is what decides whether a fraction of the catalogue is reported at
# all.

test_that("an unfiltered universe is the whole curated catalogue", {
  universe <- gift_universe()
  expect_s3_class(universe, "giftr_universe")
  expect_setequal(universe$gift_id, list_gifts()$gift_id)
  expect_false(universe$bounded)
})

test_that("type and mode partition the catalogue and agree with the gift table", {
  gifts <- list_gifts()
  for (type in unique(gifts$gift_type)) {
    expect_setequal(
      gift_universe(type = type)$gift_id,
      gifts$gift_id[gifts$gift_type == type]
    )
  }
  modes <- unique(gifts$mode[!is.na(gifts$mode)])
  members <- unlist(lapply(modes, function(mode) gift_universe(mode = mode)$gift_id))
  # Every mode is metabolic and no GIFT carries two, so the modes partition the
  # metabolic type exactly. A machinery GIFT must never appear.
  expect_setequal(members, gifts$gift_id[!is.na(gifts$mode)])
  expect_equal(anyDuplicated(members), 0L)
  expect_true(all(gifts$gift_type[gifts$gift_id %in% members] == "metabolic"))
})

test_that("filters combine with AND", {
  anabolic <- gift_universe(mode = "anabolic")$gift_id
  essential <- gift_universe(auxotrophy_indicator = TRUE)$gift_id
  both <- gift_universe(mode = "anabolic", auxotrophy_indicator = TRUE)$gift_id
  expect_setequal(both, intersect(anabolic, essential))
})

test_that("a facet universe holds exactly the GIFTs that facet value classifies", {
  classified <- gifts_by_facet("substrate_class", "amino_acid")
  expect_setequal(
    gift_universe(facet = "substrate_class", value = "amino_acid")$gift_id,
    classified$gift_id
  )
  # Without a value, the universe is every GIFT the facet classifies at all.
  expect_true(all(
    gift_universe(facet = "substrate_class", value = "amino_acid")$gift_id %in%
      gift_universe(facet = "substrate_class")$gift_id
  ))
})

test_that("profile filters reach only the metabolic model", {
  # gift_profile covers metabolic GIFTs alone, so a resource strategy can never
  # select a structure. Inventing a resource strategy for a flagellum is the
  # error the view's WHERE clause exists to prevent.
  for (strategy in c("uptake", "public_good", "private")) {
    members <- gift_universe(resource_strategy = strategy)$gift_id
    expect_true(all(list_gifts()$gift_type[list_gifts()$gift_id %in% members] == "metabolic"))
  }
  profile <- gift_profile()
  expect_setequal(
    gift_universe(resource_strategy = "uptake")$gift_id,
    profile$gift_id[profile$resource_strategy == "uptake"]
  )
})

test_that("an unregistered facet is refused rather than returning nothing", {
  # Returning an empty universe would make a typo look like a genome with no
  # capabilities of that kind.
  expect_error(gift_universe(facet = "substrate_klass"), "Unregistered GIFT facet")
  expect_error(gift_universe(value = "amino_acid"), "value requires a facet")
})

test_that("bounded is a declared claim, defaulting to FALSE", {
  expect_false(gift_universe(type = "metabolic")$bounded)
  expect_true(gift_universe(type = "metabolic", bounded = TRUE)$bounded)
  expect_error(gift_universe(bounded = NA), "bounded must be TRUE or FALSE")
})

test_that("a universe records the database version it was resolved against", {
  expect_identical(
    gift_universe()$database_version,
    giftr_db_version()$giftr_db_version
  )
})

test_that("the default universe set partitions by type, mode and strategy and bounds only one", {
  db <- giftr_db_connect()
  on.exit(giftr_db_disconnect(db))
  universes <- giftr:::.default_universes(db)
  labels <- vapply(universes, function(u) u$label, character(1))
  expect_true("all curated GIFTs" %in% labels)
  expect_true("metabolic GIFTs" %in% labels)
  expect_true("anabolic GIFTs" %in% labels)
  expect_true("biomass-essential anabolic GIFTs" %in% labels)
  bounded <- vapply(universes, function(u) u$bounded, logical(1))
  expect_identical(labels[bounded], "biomass-essential anabolic GIFTs")
  # An empty universe would contribute rows whose denominator is zero.
  expect_true(all(vapply(universes, function(u) length(u$gift_id) > 0L, logical(1))))
})
