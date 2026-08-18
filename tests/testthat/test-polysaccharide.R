polysaccharide_gifts <- c(
  "xylan_degradation", "arabinoxylan_debranching", "starch_degradation"
)

test_that("a polysaccharide GIFT is a capability, not a single reaction", {
  # The question a user asks is whether a genome can degrade the substrate, so
  # the trait spans the chemistry that liberates a usable monosaccharide.
  # Requiring both activities is a curation decision about sufficient evidence:
  # the exo-acting enzyme can act on polymer termini by itself, but the endo
  # enzyme is what generates the chain ends that make it productive.
  for (gift_id in c("xylan_degradation", "starch_degradation")) {
    reactions <- get_gift_reactions(gift_id)
    expect_equal(sum(reactions$required == 1L), 2L)
    expect_equal(sum(reactions$required == 0L), 1L)
  }

  # Oligosaccharides are internal intermediates and must not be boundaries.
  connection <- giftr_db_connect()
  withr::defer(giftr_db_disconnect(connection))
  anchors <- DBI::dbGetQuery(connection, "SELECT anchor_id FROM anchor")$anchor_id
  expect_false(any(grepl("OLIGOSACCHARIDE", anchors)))
})

test_that("xylan degradation answers the substrate-level question", {
  ask <- function(markers) {
    result <- evaluate_gifts(ko_annotations(markers))
    result$gifts[result$gifts$gift_id == "xylan_degradation", ]
  }

  both <- ask(c("K01181", "K01198"))
  expect_true(both$complete)

  # Endo-acting cleavage yields xylo-oligosaccharides rather than free xylose,
  # so this genome is a primary degrader. That state is expressed as an
  # incomplete capability naming what is missing, which says more than a
  # positive call for a fragment would.
  endo <- ask("K01181")
  expect_false(endo$complete)
  expect_equal(endo$minimum_missing_reactions, 1L)
  expect_equal(endo$missing_reactions_best_route[[1]], "RXN_XYLOOLIGO_EXO")

  # The exo-acting enzyme can release xylose from polymer termini on its own,
  # so this is a deliberate evidence threshold rather than a chemical claim:
  # exo activity alone is not accepted as complete polymer saccharification.
  exo <- ask("K01198")
  expect_false(exo$complete)
  expect_equal(exo$missing_reactions_best_route[[1]], "RXN_XYLAN_ENDO_1_4")
})

test_that("accessory chemistry appears in the trace without gating the call", {
  # Acetyl decorations block backbone xylanases, and debranching limits how far
  # amylases reach, but neither is required to liberate the monosaccharide.
  without <- evaluate_gifts(ko_annotations(c("K01181", "K01198")))
  with <- evaluate_gifts(ko_annotations(c("K01181", "K01198", "K05972")))
  gift <- "xylan_degradation"
  expect_true(without$gifts$complete[without$gifts$gift_id == gift])
  expect_true(with$gifts$complete[with$gifts$gift_id == gift])

  trace <- trace_gift(without, gift)
  accessory <- trace[trace$reaction_id == "RXN_XYLAN_DEACETYL", ]
  expect_false(accessory$required[[1]])
  expect_false(accessory$reaction_supported[[1]])

  starch <- get_gift_reactions("starch_degradation")
  expect_equal(starch$required[starch$reaction_id == "RXN_STARCH_DEBRANCH_1_6"], 0L)
})

test_that("polymer chemistry is curated without a Rhea master", {
  # A polysaccharide is a substrate class, not a compound with a balanced
  # equation, so none of these reactions has a Rhea entry. They must still be
  # externally identifiable.
  for (gift_id in polysaccharide_gifts) {
    reactions <- get_gift_reactions(gift_id)
    expect_true(all(is.na(reactions$rhea_master)))
    expect_true(all(grepl("^RXN_", reactions$reaction_id)))
  }

  connection <- giftr_db_connect()
  withr::defer(giftr_db_disconnect(connection))
  # Scoped to this layer's own chemistry. That a reaction without a Rhea master
  # carries a cross-reference instead is a general invariant, tested in
  # test-reaction-identity.R; here the claim is that all seven polymer-acting
  # hydrolases of the polysaccharide GIFTs are identified that way.
  xrefs <- DBI::dbGetQuery(connection, paste(
    "SELECT DISTINCT r.reaction_id, x.namespace FROM gift g",
    "JOIN gift_route gr ON gr.gift_pk = g.gift_pk",
    "JOIN route_reaction rr ON rr.route_pk = gr.route_pk",
    "JOIN reaction r ON r.reaction_pk = rr.reaction_pk",
    "JOIN reaction_xref x ON x.reaction_pk = r.reaction_pk",
    "WHERE r.rhea_master IS NULL AND g.gift_id IN",
    "('xylan_degradation', 'arabinoxylan_debranching', 'starch_degradation')"
  ))
  expect_equal(nrow(xrefs), 7L)
  expect_true(all(xrefs$namespace == "EC"))
})

test_that("dietary fibre composes to central metabolism through declared anchors", {
  graph <- gift_graph()
  step <- function(from) graph$to_gift[graph$from_gift == from]

  # Arabinoxylan is decorated xylan: stripping the side chains yields both a
  # fermentable sugar and the backbone the xylan GIFT consumes.
  expect_true("xylan_degradation" %in% step("arabinoxylan_debranching"))
  expect_true("arabinose_uptake_abc" %in% step("arabinoxylan_debranching"))
  expect_equal(step("xylan_degradation"), "xylose_uptake_abc")
  expect_equal(step("xylose_uptake_abc"), "xylose_degradation_isomerase")

  chain <- graph[graph$from_gift %in% c(
    "arabinoxylan_debranching", "xylan_degradation", "xylose_uptake_abc"
  ), ]
  expect_true(all(chain$edge_quality == "exact"))

  # Starch stops at glucose because glycolysis is not curated.
  expect_length(step("starch_degradation"), 0L)
})

test_that("polymers are extracellular and unlicensed products stay unresolved", {
  for (gift_id in c("xylan_degradation", "starch_degradation")) {
    inputs <- get_gift_anchors(gift_id)
    expect_equal(inputs$compartment[inputs$role == "input"], "extracellular")
  }
  glucose <- get_gift_anchors("starch_degradation")
  expect_equal(glucose$compartment[glucose$anchor_id == "GLUCOSE"], "unspecified")
})

test_that("CAZy confidence tracks measured family polyspecificity", {
  # GH11 carries two characterised activities in dbCAN; GH5 carries 28. Both
  # support the same call, and the call says how well.
  cazy <- function(families) {
    evaluate_gifts(data.frame(
      gene_id = paste0("g", seq_along(families)), namespace = "CAZY",
      accession = families, stringsAsFactors = FALSE
    ))
  }
  gift <- "xylan_degradation"
  specific <- cazy(c("GH11", "GH39"))
  promiscuous <- cazy(c("GH5", "GH3"))
  expect_true(specific$gifts$complete[specific$gifts$gift_id == gift])
  expect_true(promiscuous$gifts$complete[promiscuous$gifts$gift_id == gift])
  expect_equal(specific$gifts$evidence_confidence[specific$gifts$gift_id == gift],
               "high-confidence")
  expect_equal(promiscuous$gifts$evidence_confidence[promiscuous$gifts$gift_id == gift],
               "ambiguous")
})

test_that("a weak marker alongside a strong one does not weaken the call", {
  # Alternative markers for one component are OR, so the component is as good as
  # its best evidence. Only across required components does the weakest win.
  both <- evaluate_gifts(data.frame(
    gene_id = c("g1", "g2", "g3"), namespace = c("CAZY", "KO", "KO"),
    accession = c("GH5", "K01181", "K01198"), stringsAsFactors = FALSE
  ))
  expect_equal(
    both$gifts$evidence_confidence[both$gifts$gift_id == "xylan_degradation"],
    "curated"
  )
  expect_equal(giftr:::.call_confidence(c(1, 1), c("ambiguous", "curated")), "curated")
  expect_equal(giftr:::.call_confidence(c(1, 2), c("curated", "ambiguous")), "ambiguous")
})

test_that("bare dbCAN output is evaluated without an explicit namespace", {
  result <- evaluate_gifts(c("GH11", "GH39", "K01181"))
  expect_true(result$gifts$complete[result$gifts$gift_id == "xylan_degradation"])
  expect_equal(
    unique(result$observed_markers$namespace[result$observed_markers$accession == "GH11"]),
    "CAZY"
  )
})
