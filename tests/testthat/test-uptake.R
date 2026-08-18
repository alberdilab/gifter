test_that("uptake GIFTs translocate one molecule and nothing else", {
  for (gift_id in c("xylose_uptake_abc", "arabinose_uptake_abc")) {
    gift <- get_gift(gift_id)
    expect_equal(gift$mode, "transport")

    anchors <- get_gift_anchors(gift_id)
    expect_equal(nrow(anchors), 2L)
    # One substance, two sides of the membrane. This is what makes it transport
    # rather than chemistry, and the validator enforces it.
    expect_equal(length(unique(anchors$molecule)), 1L)
    expect_setequal(anchors$compartment, c("extracellular", "cytoplasmic"))
    expect_equal(anchors$compartment[anchors$role == "input"], "extracellular")
    expect_equal(anchors$compartment[anchors$role == "output"], "cytoplasmic")
    # Rhea uses one ChEBI for both sides, so the identity is the substance.
    expect_equal(length(unique(anchors$chebi_id)), 1L)
  }
})

test_that("uptake composes with catabolism through the cytoplasmic anchor", {
  graph <- gift_graph()
  xylose <- graph[graph$from_gift == "xylose_uptake_abc", ]
  expect_equal(xylose$to_gift, "xylose_degradation_isomerase")
  expect_equal(xylose$shared_anchor, "XYLOSE_IN")
  expect_equal(xylose$edge_quality, "exact")

  arabinose <- graph[graph$from_gift == "arabinose_uptake_abc", ]
  expect_equal(arabinose$to_gift, "arabinose_degradation")
  expect_equal(arabinose$edge_quality, "exact")

  # Extracellular xylose must not reach the catabolic GIFT except through
  # uptake. If it could, the transport GIFT would carry no information.
  expect_false(any(
    graph$shared_anchor == "XYLOSE_EX" & graph$to_gift == "xylose_degradation_isomerase"
  ))
})

test_that("an ABC importer needs all three of its subunits", {
  complete <- evaluate_gifts(ko_annotations(c("K10543", "K10544", "K10545")))
  gift <- complete$gifts[complete$gifts$gift_id == "xylose_uptake_abc", ]
  expect_true(gift$complete)
  expect_equal(gift$evidence_confidence, "curated")

  # A binding protein and a permease without the ATPase transport nothing.
  partial <- evaluate_gifts(ko_annotations(c("K10543", "K10544")))
  expect_false(partial$gifts$complete[partial$gifts$gift_id == "xylose_uptake_abc"])

  # Uptake is independent of catabolism: a cross-feeder carrying only the
  # importer is positive for uptake and negative for the pathway.
  expect_false(complete$gifts$complete[
    complete$gifts$gift_id == "xylose_degradation_isomerase"
  ])
})

test_that("a dual-specificity importer serves both pentoses", {
  # XacGHI is characterised on L-arabinose and D-xylose, so it is an
  # alternative system for both reactions rather than a marker of one.
  result <- evaluate_gifts(ko_annotations(c("K25045", "K25046", "K25047")))
  transport <- result$gifts[result$gifts$mode == "transport", ]
  expect_true(all(transport$complete))

  expect_setequal(
    unique(get_reaction_systems("RHEA:29899")$system_id),
    c("SYS_29899_XYLFGH", "SYS_29899_XACGHI")
  )
})

test_that("promiscuous carriers are not accepted as uptake evidence", {
  # K02429 is annotated as a fucose-galactose-glucose symporter. Accepting it
  # would attribute fucose uptake to any genome carrying that MFS family, so no
  # fucose uptake GIFT exists and the anchor stays unresolved.
  expect_equal(nrow(get_gift("fucose_uptake")), 0L)
  expect_true(all(
    get_gift_anchors("fucose_degradation_isomerase")$compartment == "unspecified"
  ))

  # Substrates whose uptake could not be evidenced keep an unspecified anchor,
  # so their catabolic chain is never broken by a missing transporter.
  unresolved <- c(
    "fucose_degradation_isomerase", "rhamnose_degradation",
    "galactose_degradation_leloir", "neuac_degradation", "glcnac_degradation",
    "glucuronate_degradation", "galacturonate_degradation"
  )
  for (gift_id in unresolved) {
    inputs <- get_gift_anchors(gift_id)
    expect_true(all(inputs$compartment[inputs$role == "input"] == "unspecified"))
  }
})

test_that("the uptake licence and its refusals are recorded", {
  changes <- database_changelog("fucose_degradation_isomerase")$change_id
  expect_true("DBC-20260818-UPTAKE-LICENCE" %in% changes)
  expect_true("DBC-20260818-PENTOSE-UPTAKE" %in% database_changelog("xylose_uptake_abc")$change_id)
})
