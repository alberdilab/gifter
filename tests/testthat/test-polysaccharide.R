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
  connection <- gifter_db_connect()
  withr::defer(gifter_db_disconnect(connection))
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

  connection <- gifter_db_connect()
  withr::defer(gifter_db_disconnect(connection))
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
  expect_equal(gifter:::.call_confidence(c(1, 1), c("ambiguous", "curated")), "curated")
  expect_equal(gifter:::.call_confidence(c(1, 2), c("curated", "ambiguous")), "ambiguous")
})

test_that("bare dbCAN output is evaluated without an explicit namespace", {
  result <- evaluate_gifts(c("GH11", "GH39", "K01181"))
  expect_true(result$gifts$complete[result$gifts$gift_id == "xylan_degradation"])
  expect_equal(
    unique(result$observed_markers$namespace[result$observed_markers$accession == "GH11"]),
    "CAZY"
  )
})

test_that("chitin saccharification needs both the endo and the exo activity", {
  ask <- function(markers) {
    result <- evaluate_gifts(markers)
    result$gifts[result$gifts$gift_id == "chitin_degradation", ]
  }

  both <- ask(c("K01183", "K01207"))
  expect_true(both$complete)
  expect_equal(both$evidence_confidence, "curated")

  # Chitinase alone liberates chito-oligosaccharides, not free GlcNAc, so the
  # genome is a primary degrader and the call names what is missing.
  endo <- ask("K01183")
  expect_false(endo$complete)
  expect_equal(endo$missing_reactions_best_route[[1]], "RXN_CHITOBIOSE_EXO")

  # NagZ is carried for peptidoglycan recycling by a great many genomes that
  # cannot touch chitin. Requiring the endo activity is what stops that from
  # reading as chitin degradation.
  exo <- ask("K01207")
  expect_false(exo$complete)
  expect_equal(exo$missing_reactions_best_route[[1]], "RXN_CHITIN_ENDO")
})

test_that("oxidative chain cleavage is accessory to chitin saccharification", {
  # AA10 lytic polysaccharide monooxygenase opens crystalline chitin for the
  # endo-enzyme, which changes the rate rather than the capability.
  without <- evaluate_gifts(c("K01183", "K01207"))
  gift <- "chitin_degradation"
  expect_true(without$gifts$complete[without$gifts$gift_id == gift])
  trace <- trace_gift(without, gift)
  accessory <- trace[trace$reaction_id == "RXN_CHITIN_LPMO", ]
  expect_false(accessory$required[[1]])
  expect_false(accessory$reaction_supported[[1]])

  chitin <- get_gift_reactions(gift)
  expect_equal(chitin$required[chitin$reaction_id == "RXN_CHITIN_LPMO"], 0L)
})

test_that("mucin O-glycan is curated as parallel release GIFTs, not a tier", {
  mucin <- c(
    "mucin_sialic_acid_release", "mucin_fucose_release", "mucin_galnac_release"
  )
  # There is no polymer-to-oligomer cut in mucin, so each exo-glycosidase is one
  # required reaction and the GIFTs vary independently of one another.
  for (gift_id in mucin) {
    reactions <- get_gift_reactions(gift_id)
    expect_equal(sum(reactions$required == 1L), 1L)
    anchors <- get_gift_anchors(gift_id)
    expect_equal(anchors$anchor_id[anchors$role == "input"], "MUCIN_O_GLYCAN")
  }

  one <- evaluate_gifts("K23550")$gifts
  expect_true(one$complete[one$gift_id == "mucin_sialic_acid_release"])
  expect_false(any(one$complete[one$gift_id %in% mucin[-1]]))
})

test_that("housekeeping glycosidases do not call mucin foraging", {
  # beta-galactosidase and NagZ were assessed as mucin candidates and rejected:
  # their families cannot separate mucin from lactose or peptidoglycan, so
  # admitting them would have called foraging from housekeeping chemistry.
  mucin <- c(
    "mucin_sialic_acid_release", "mucin_fucose_release", "mucin_galnac_release"
  )
  for (marker in c("K01190", "K12308", "K01207")) {
    calls <- evaluate_gifts(marker)$gifts
    expect_false(any(calls$complete[calls$gift_id %in% mucin]))
  }
})

test_that("released mucin and chitin sugars reach catabolism only inexactly", {
  # The sugar is freed outside the cell and consumed inside it. No transporter
  # evidence licensed splitting these anchors, so both GIFTs name the one
  # unsplit anchor and the edge must record that the transport step is assumed.
  graph <- gift_graph()
  edges <- graph[graph$from_gift %in% c(
    "chitin_degradation", "mucin_sialic_acid_release", "mucin_fucose_release"
  ), ]
  expect_true(nrow(edges) > 0L)
  expect_true(all(edges$edge_quality == "compartment_inexact"))
  expect_setequal(
    edges$to_gift,
    c("glcnac_degradation", "neuac_degradation", "fucose_degradation_isomerase")
  )

  # Uptake still produces exact edges, which is what keeps transport GIFTs
  # load-bearing rather than decorative.
  uptake <- graph[graph$from_gift == "xylose_uptake_abc", ]
  expect_true(all(uptake$edge_quality == "exact"))
})

test_that("pectin saccharification needs both the endo and the exo activity", {
  ask <- function(markers) {
    result <- evaluate_gifts(markers)
    result$gifts[result$gifts$gift_id == "pectin_degradation", ]
  }

  both <- ask(c("K01184", "K01213"))
  expect_true(both$complete)
  expect_equal(both$evidence_confidence, "curated")

  endo <- ask("K01184")
  expect_false(endo$complete)
  expect_equal(endo$missing_reactions_best_route[[1]], "RXN_OLIGOGALACTURONIDE_EXO")

  # De-esterification exposes the backbone but liberates no uronate of its own,
  # so it is accessory here for the same reason acetyl removal is for xylan.
  esterase <- ask("K01051")
  expect_false(esterase$complete)
  reactions <- get_gift_reactions("pectin_degradation")
  expect_equal(
    reactions$required[reactions$reaction_id == "RXN_PECTIN_DEMETHYL"], 0L
  )
})

test_that("GH28 is substrate-coherent but cannot separate endo from exo", {
  # All seven characterised GH28 activities are on pectin, so the family says
  # what the substrate is; it does not say which end of the chain is attacked.
  # One bare call therefore satisfies both components, and the ambiguous grade
  # is what keeps that from reading like real evidence.
  bare <- evaluate_gifts("GH28")$gifts
  call <- bare[bare$gift_id == "pectin_degradation", ]
  expect_true(call$complete)
  expect_equal(call$evidence_confidence, "ambiguous")

  universes <- list(gift_universe(preset = "carbohydrate_degradation"))
  gated <- genome_traits(
    evaluate_gifts("GH28"), universes = universes,
    min_confidence = "high-confidence"
  )
  expect_equal(
    gated$metrics$value[gated$metrics$metric_id == "gift_richness"], 0
  )
})

lyase_route_markers <- c("K01728", "K01731", "K01730", "K01815", "K00065")

test_that("the two pectin chemistries are separate capabilities that converge", {
  # beta-elimination and hydrolysis end at different metabolites, so they cannot
  # be two routes of one GIFT. What they share is where they arrive.
  hydrolytic <- get_gift_anchors("pectin_degradation")
  lyase <- get_gift_anchors("pectate_lyase_degradation")
  expect_equal(hydrolytic$anchor_id[hydrolytic$role == "input"], "PECTIN")
  expect_equal(lyase$anchor_id[lyase$role == "input"], "PECTIN")
  expect_equal(hydrolytic$anchor_id[hydrolytic$role == "output"], "GALACTURONATE")
  expect_equal(lyase$anchor_id[lyase$role == "output"], "KDG")

  # Both reach the branchpoint, one directly and one through galacturonate
  # catabolism. Neither call is evidence for the other.
  graph <- gift_graph()
  expect_true(any(
    graph$from_gift == "pectate_lyase_degradation" &
      graph$to_gift == "kdg_degradation" & graph$shared_anchor == "KDG"
  ))
  expect_true(any(
    graph$from_gift == "pectin_degradation" &
      graph$to_gift == "galacturonate_degradation"
  ))

  # Extracellular depolymerisation handing off through an anchor that leaves the
  # compartment unresolved is inexact, exactly as it is for the hydrolytic arm.
  edge <- graph[graph$from_gift == "pectate_lyase_degradation", ]
  expect_equal(edge$edge_quality, "compartment_inexact")
})

test_that("the lyase route runs to the branchpoint and needs every step of it", {
  ask <- function(markers) {
    result <- evaluate_gifts(markers)
    result$gifts[result$gifts$gift_id == "pectate_lyase_degradation", ]
  }

  full <- ask(lyase_route_markers)
  expect_true(full$complete)
  expect_equal(full$evidence_confidence, "curated")

  # Each of the five is required chemistry: the endo- and exo-acting lyases and
  # the three intracellular steps that carry the unsaturated disaccharide to the
  # branchpoint. Dropping any one of them is a negative call.
  for (missing in seq_along(lyase_route_markers)) {
    expect_false(ask(lyase_route_markers[-missing])$complete)
  }

  # Endo-lyase alone stops at the exo step, which is the conservatism this route
  # was curated with rather than around.
  expect_equal(ask("K01728")$missing_reactions_best_route[[1]][[1]], "RHEA:57104")

  # Pectin lyase is an alternative entry on esterified backbone and
  # de-esterification exposes the backbone; neither liberates anything on its
  # own, so both are accessory.
  reactions <- get_gift_reactions("pectate_lyase_degradation")
  accessory <- reactions$reaction_id[reactions$required == 0L]
  expect_setequal(accessory, c("RXN_PECTIN_LYASE", "RXN_PECTIN_DEMETHYL"))
  expect_false(ask(c("K01732", "K01051"))$complete)
})

component_markers_for <- function(component_id) {
  connection <- gifter_db_connect()
  withr::defer(gifter_db_disconnect(connection), envir = parent.frame())
  DBI::dbGetQuery(connection, paste(
    "SELECT m.namespace, m.accession, cm.confidence, cm.notes",
    "FROM component_marker cm",
    "JOIN marker m ON m.marker_pk = cm.marker_pk",
    "JOIN enzyme_component ec ON ec.component_pk = cm.component_pk",
    "WHERE ec.component_id =", DBI::dbQuoteString(connection, component_id)
  ))
}

test_that("PL family markers are graded on what they can and cannot separate", {
  markers <- component_markers_for("COMP_ENDO_PL")
  bare <- markers[markers$namespace == "CAZY" & !grepl("_e", markers$accession), ]
  grades <- stats::setNames(bare$confidence, bare$accession)

  # Monoactivity families stand alone; two pectin activities are
  # high-confidence; four or more are ambiguous.
  expect_equal(unname(grades[c("PL3", "PL10")]), c("curated", "curated"))
  expect_equal(unname(grades[["PL2"]]), "high-confidence")
  expect_equal(unname(grades[c("PL1", "PL9")]), c("ambiguous", "ambiguous"))

  # Both ambiguous grades must say *why*, and the reasons are different.
  # PL1 cannot separate the steps it marks; PL9 may not be on pectin at all.
  expect_match(bare$notes[bare$accession == "PL1"], "endo versus exo")
  expect_match(bare$notes[bare$accession == "PL9"], "thiopeptidoglycan")

  # No CBM family and nothing below the agreement floor was admitted. PL1_e2 is
  # the case the floor exists for: admitted for EC 4.2.2.2 at 15 of 20 annotated
  # members, refused for EC 4.2.2.9 at 5 of 20.
  clusters <- markers$accession[grepl("_e", markers$accession)]
  expect_false(any(grepl("^CBM", markers$accession)))
  expect_true("PL1_e2" %in% clusters)
  expect_false("PL1_e2" %in% component_markers_for("COMP_57104_CATALYTIC")$accession)
})

test_that("a bare PL1 call is possible but never reads as real evidence", {
  # PL1 marks the endo step, the exo step and the accessory pectin lyase, so one
  # bare hit satisfies both required lyase components. The intracellular trio
  # still has to be there, and the ambiguous grade is what keeps the result from
  # being counted as evidence under a confidence floor.
  bare <- evaluate_gifts(c("PL1", "K01730", "K01815", "K00065"))$gifts
  call <- bare[bare$gift_id == "pectate_lyase_degradation", ]
  expect_true(call$complete)
  expect_equal(call$evidence_confidence, "ambiguous")

  gated <- genome_traits(
    evaluate_gifts(c("PL1", "K01730", "K01815", "K00065")),
    universes = list(gift_universe(preset = "carbohydrate_degradation")),
    min_confidence = "high-confidence"
  )
  expect_equal(
    gated$metrics$value[gated$metrics$metric_id == "gift_richness"], 0
  )
})

test_that("housekeeping Entner-Doudoroff chemistry does not call pectin foraging", {
  # The negative case the branchpoint anchor makes possible to state. KdgK and
  # Eda are the lower Entner-Doudoroff pathway and are carried for gluconate,
  # alginate and 2-keto-3-deoxy sugar acid catabolism, by genomes that touch no
  # pectin at all. They complete kdg_degradation, and nothing upstream of it.
  housekeeping <- evaluate_gifts(c("K00874", "K01625"))$gifts
  complete <- housekeeping$gift_id[housekeeping$complete]
  expect_true("kdg_degradation" %in% complete)
  expect_false("pectate_lyase_degradation" %in% complete)
  expect_false("pectin_degradation" %in% complete)
  expect_false("galacturonate_degradation" %in% complete)
  expect_false("glucuronate_degradation" %in% complete)
})
