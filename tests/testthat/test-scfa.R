# Short-chain fatty acid formation. The layer's whole point is that its
# specificity comes from one marker in one namespace, so most of these tests are
# about what does *not* fire.

scfa_gifts <- c(
  "pyruvate_to_acetyl_coa", "acetate_interconversion", "butyrate_formation",
  "propanediol_formation", "propionate_formation_propanediol",
  "propionate_formation_acrylate"
)

butyrate_core_markers <- c("K00626", "K00074", "K01715", "K00248")

markers_of <- function(...) {
  accessions <- c(...)
  data.frame(
    gene_id = paste0("gene_", seq_along(accessions)),
    namespace = ifelse(grepl("^TIGR", accessions), "TIGRFAM", "KO"),
    accession = accessions,
    stringsAsFactors = FALSE
  )
}

complete_gifts <- function(...) {
  result <- evaluate_gifts(markers_of(...))
  result$gifts$gift_id[result$gifts$complete]
}

test_that("every SCFA GIFT is curated to the full evidence depth", {
  for (gift_id in scfa_gifts) {
    gift <- get_gift(gift_id)
    expect_equal(nrow(gift), 1L)
    expect_equal(gift$gift_type, "metabolic")

    anchors <- get_gift_anchors(gift_id)
    expect_true(any(anchors$role == "input"))
    expect_true(any(anchors$role == "output"))
    # No SCFA transport GIFT is evidenceable, so no boundary here may claim a
    # compartment. Declaring one would manufacture the cross-feeding edge that
    # inst/doc/proposal-scfa-biosynthesis.md deliberately refuses.
    expect_true(all(anchors$compartment == "unspecified"))
    # Every anchor of an interconversion GIFT carries both roles; every anchor
    # of a directed one carries exactly one.
    mirrored <- intersect(
      anchors$anchor_id[anchors$role == "input"],
      anchors$anchor_id[anchors$role == "output"]
    )
    if (identical(gift$mode, "interconversion")) {
      expect_setequal(mirrored, unique(anchors$anchor_id))
    } else {
      expect_length(mirrored, 0L)
    }

    reactions <- get_gift_reactions(gift_id)
    expect_gt(nrow(reactions), 0L)
    for (reaction in unique(reactions$reaction_id)) {
      systems <- get_reaction_systems(reaction)
      expect_gt(nrow(systems), 0L)
    }
  }
})

test_that("butyrate formation rests on a sequence family, not an orthology group", {
  # The four core enzymes are chain-length-generic. On their own they are the
  # Bacillus subtilis profile, and B. subtilis is not a butyrate fermenter.
  expect_false("butyrate_formation" %in% complete_gifts(butyrate_core_markers))

  # KEGG fuses EC 2.8.3.8 and EC 2.8.3.9 into one pair of accessions, so the
  # acetoacetate degradation transferase of Escherichia coli must not stand in
  # for the butyrate-releasing one.
  expect_false(
    "butyrate_formation" %in%
      complete_gifts(butyrate_core_markers, "K01034", "K01035")
  )

  # Nor may the butyrate kinase route, which is refused outright.
  expect_false(
    "butyrate_formation" %in%
      complete_gifts(butyrate_core_markers, "K00634", "K00929")
  )

  # Only the substrate-specific family completes it.
  expect_true(
    "butyrate_formation" %in% complete_gifts(butyrate_core_markers, "TIGR03948")
  )
})

test_that("the missing reaction reported for a core-only genome is the transferase", {
  result <- evaluate_gifts(markers_of(butyrate_core_markers))
  gift <- result$gifts[result$gifts$gift_id == "butyrate_formation", ]
  expect_false(gift$complete)
  expect_equal(unlist(gift$missing_reactions_best_route), "RHEA:30071")
})

test_that("the electron-transfer flavoprotein is not required evidence", {
  # K03521 and K03522 are the generic fixA/fixB orthologues. Adding them must
  # change nothing, in either direction.
  without <- complete_gifts(butyrate_core_markers, "TIGR03948")
  with_etf <- complete_gifts(butyrate_core_markers, "TIGR03948", "K03521", "K03522")
  expect_setequal(without, with_etf)
})

test_that("the acetate node declares both directions, as its mode requires", {
  expect_equal(get_gift("acetate_interconversion")$mode, "interconversion")

  # The markers cannot say which way the node runs, so the boundary does not
  # either. Declaring only acetyl-CoA to acetate would assert a direction the
  # evidence does not support; splitting it into a formation GIFT and an
  # assimilation GIFT would assert a distinction the same two genes cannot make.
  anchors <- get_gift_anchors("acetate_interconversion")
  expect_setequal(
    anchors$anchor_id[anchors$role == "input"], c("ACETYL_COA", "ACETATE")
  )
  expect_setequal(
    anchors$anchor_id[anchors$role == "output"], c("ACETYL_COA", "ACETATE")
  )

  # One route, not a mirrored pair. A flipped copy would complete on the same
  # markers and make closest-route selection non-deterministic, so direction
  # lives in the anchors for composition and in the reaction orientations for
  # chemistry, and the two are not kept in step.
  expect_equal(nrow(get_gift_routes("acetate_interconversion")), 1L)
})

test_that("the acetate node completes on either phosphotransacetylase group", {
  expect_true("acetate_interconversion" %in% complete_gifts("K00625", "K00925"))
  # Its only alternative markers are OR across one component.
  expect_true("acetate_interconversion" %in% complete_gifts("K13788", "K00925"))
  expect_false("acetate_interconversion" %in% complete_gifts("K00625"))

  # Butyrate formation consumes both of this node's boundaries, so declaring
  # both directions gives it two edges rather than one. Both cross a mode
  # boundary, which is why they are exempt from the within-mode acyclicity rule.
  graph <- gift_graph()
  edge <- graph[
    graph$from_gift == "acetate_interconversion" & graph$to_gift == "butyrate_formation",
  ]
  expect_setequal(edge$shared_anchor, c("ACETATE", "ACETYL_COA"))
  expect_true(all(edge$edge_quality == "exact"))

  # A reversible node must not become a self-loop in the graph, and must not
  # trip the acyclicity check for its own mode.
  expect_false(any(graph$from_gift == graph$to_gift))
})

test_that("the pyruvate node carries three non-interchangeable routes", {
  routes <- get_gift_routes("pyruvate_to_acetyl_coa")
  expect_setequal(routes$route_id, c("PYR_ACOA_PDH", "PYR_ACOA_PFOR", "PYR_ACOA_PFL"))

  # Oxygen requirement is a route property, and here the routes genuinely
  # differ: recording it on the GIFT would flatten exactly this distinction.
  connection <- gifter_db_connect()
  withr::defer(gifter_db_disconnect(connection))
  oxygen <- DBI::dbGetQuery(
    connection,
    "SELECT route_id, oxygen_requirement FROM gift_route WHERE route_id LIKE 'PYR_ACOA_%'"
  )
  expect_equal(
    oxygen$oxygen_requirement[oxygen$route_id == "PYR_ACOA_PDH"], "independent"
  )
  expect_true(all(
    oxygen$oxygen_requirement[oxygen$route_id != "PYR_ACOA_PDH"] == "anaerobic"
  ))

  # Two dehydrogenase architectures, alternatives at the system layer rather
  # than the route layer: the E1 subunit count is not a different pathway.
  expect_setequal(
    get_reaction_systems("RHEA:28042")$system_id,
    c("SYS_28042_PDH_E1AB", "SYS_28042_PDH_E1")
  )
  expect_true(
    "pyruvate_to_acetyl_coa" %in%
      complete_gifts("K00161", "K00162", "K00627", "K00382")
  )
  expect_true(
    "pyruvate_to_acetyl_coa" %in% complete_gifts("K00163", "K00627", "K00382")
  )
  # A fused oxidoreductase replaces four subunits; a partial complex does not.
  expect_true("pyruvate_to_acetyl_coa" %in% complete_gifts("K03737"))
  expect_false(
    "pyruvate_to_acetyl_coa" %in% complete_gifts("K00169", "K00170", "K00171")
  )
  # The lyase is inactive without its activating enzyme.
  expect_false("pyruvate_to_acetyl_coa" %in% complete_gifts("K00656"))
  expect_true("pyruvate_to_acetyl_coa" %in% complete_gifts("K00656", "K04069"))
})

test_that("the propanediol route composes with deoxyhexose catabolism", {
  graph <- gift_graph()
  into_diol <- graph[graph$to_gift == "propanediol_formation", ]
  expect_setequal(
    into_diol$from_gift,
    c("fucose_degradation_isomerase", "rhamnose_degradation")
  )
  expect_true(all(into_diol$shared_anchor == "LACTALDEHYDE"))
  expect_true(all(into_diol$edge_quality == "exact"))

  onward <- graph[graph$from_gift == "propanediol_formation", ]
  expect_equal(onward$to_gift, "propionate_formation_propanediol")
  expect_equal(onward$shared_anchor, "PROPANEDIOL")

  # The dehydratase is a three-subunit holoenzyme: two of three is not a machine.
  pdu <- c("K01699", "K13919", "K13920", "K13922", "K13923", "K19697")
  expect_true("propionate_formation_propanediol" %in% complete_gifts(pdu))
  expect_false(
    "propionate_formation_propanediol" %in% complete_gifts(setdiff(pdu, "K13920"))
  )
  # TdcD is accepted as an alternative kinase to PduW.
  expect_true(
    "propionate_formation_propanediol" %in%
      complete_gifts(c(setdiff(pdu, "K19697"), "K00932"))
  )
})

test_that("the acrylate route reports its unannotated reductase rather than scoring it away", {
  core <- c("K01026", "K20626", "K20627")
  result <- evaluate_gifts(markers_of(core))
  gift <- result$gifts[result$gifts$gift_id == "propionate_formation_acrylate", ]
  expect_false(gift$complete)
  expect_equal(unlist(gift$missing_reactions_best_route), "RHEA:34471")
  expect_true("propionate_formation_acrylate" %in% complete_gifts(core, "K20143"))
})

test_that("routes record the direction the chemistry is used in", {
  # Several reactions are curated against the Rhea master's direction, because
  # the master is written towards the substrate rather than the product.
  acetate <- get_gift_reactions("acetate_interconversion")
  expect_equal(
    acetate$orientation[acetate$reaction_id == "RHEA:19521"], "forward"
  )
  expect_equal(
    acetate$orientation[acetate$reaction_id == "RHEA:11352"], "reverse"
  )
  butyrate <- get_gift_reactions("butyrate_formation")
  expect_equal(
    butyrate$orientation[butyrate$reaction_id == "RHEA:30071"], "reverse"
  )
  expect_equal(
    butyrate$orientation[butyrate$reaction_id == "RHEA:21036"], "forward"
  )
})

test_that("the layer claims no cross-feeding it cannot evidence", {
  profile <- gift_profile()
  layer <- profile[profile$gift_id %in% scfa_gifts, ]
  expect_equal(nrow(layer), length(scfa_gifts))
  # cross_feeding_output requires an extracellular output anchor, and no SCFA
  # transporter marker licenses one. The zero is the honest answer, not a gap.
  expect_true(all(layer$cross_feeding_output == 0L))
  expect_true(all(layer$resource_strategy == "private"))
})

test_that("the new anchors create no edge through internal metabolites", {
  graph <- gift_graph()
  # Acetyl-CoA is consumed internally by serine and homoserine acetylation.
  # Declaring it an anchor must not connect those biosynthesis GIFTs to anything.
  acetyl_coa <- graph[graph$shared_anchor == "ACETYL_COA", ]
  expect_setequal(
    acetyl_coa$from_gift,
    c(
      "pyruvate_to_acetyl_coa", "acetate_interconversion",
      # The aromatic funnel delivers ring carbon as acetyl-CoA, which is what
      # makes it carbon acquisition rather than a dead end.
      "oxoadipyl_coa_thiolysis", "oxopentenoate_degradation"
    )
  )
  expect_setequal(
    acetyl_coa$to_gift,
    c(
      "acetate_interconversion", "butyrate_formation", "ethanol_formation",
      # The citric acid cycle layer attaches here, which is the whole point of
      # declaring the anchor: acetyl-CoA is where fermentation and the cycle
      # compete for the same carbon.
      "acetyl_coa_to_isocitrate", "glyoxylate_bypass"
    )
  )
  # Serine and homoserine acetylation consume acetyl-CoA inside their reactions
  # and gain nothing from the anchor existing.
  expect_false(any(
    c("serine_biosynthesis", "methionine_biosynthesis_transsulfuration") %in%
      c(acetyl_coa$from_gift, acetyl_coa$to_gift)
  ))
})

test_that("the atlas draws a reversible boundary as reversible", {
  output <- tempfile(fileext = ".html")
  withr::defer(unlink(output))
  html <- paste(readLines(write_gifter_database_html(output), warn = FALSE), collapse = "\n")

  # Each anchor is drawn once per side rather than listed under both roles, so
  # the boundary reads ACETYL_COA <-> ACETATE and not
  # `ACETYL_COA ACETATE -> ACETATE ACETYL_COA`.
  cell <- regmatches(
    html,
    regexpr(
      '<td class="gift-boundary-cell">(?:(?!</td>).)*ACETYL_COA(?:(?!</td>).)*</td>',
      html, perl = TRUE
    )
  )
  expect_length(cell, 1L)
  expect_match(cell, "&harr;", fixed = TRUE)
  expect_equal(lengths(regmatches(cell, gregexpr("ACETYL_COA", cell))), 1L)
  expect_equal(lengths(regmatches(cell, gregexpr("ACETATE", cell))), 1L)
  # Neither side is coloured as an input or an output, because it is both.
  expect_false(grepl('anchor-chip input', cell, fixed = TRUE))
  expect_false(grepl('anchor-chip output', cell, fixed = TRUE))

  expect_match(html, "Inputs / outputs", fixed = TRUE)
  expect_match(html, "Outputs / inputs", fixed = TRUE)

  # A directed GIFT keeps the one-way arrow and the role colours.
  butyrate <- regmatches(
    html,
    regexpr(
      '<td class="gift-boundary-cell">(?:(?!</td>).)*BUTYRATE(?:(?!</td>).)*</td>',
      html, perl = TRUE
    )
  )
  expect_match(butyrate, "&rarr;", fixed = TRUE)
  expect_match(butyrate, "anchor-chip output", fixed = TRUE)
})

test_that("the route network of a reversible GIFT is drawn both ways", {
  output <- tempfile(fileext = ".html")
  withr::defer(unlink(output))
  html <- paste(readLines(write_gifter_database_html(output), warn = FALSE), collapse = "\n")

  network <- function(gift_id) {
    regmatches(
      html,
      regexpr(
        paste0(
          '<svg class="network-svg route-network-svg[^>]*aria-label="Route network of ',
          gift_id, '".*?</svg>'
        ),
        html, perl = TRUE
      )
    )
  }

  reversible <- network("acetate_interconversion")
  expect_length(reversible, 1L)
  heads <- lengths(regmatches(reversible, gregexpr("marker-end=", reversible)))
  tails <- lengths(regmatches(reversible, gregexpr("marker-start=", reversible)))
  # Every edge of the chain carries a head at each end, boundary to boundary.
  expect_gt(heads, 0L)
  expect_equal(tails, heads)
  expect_match(reversible, "in either direction", fixed = TRUE)

  # The per-reaction orientation badges survive, because they answer a different
  # question: how each step is used relative to its own Rhea master equation.
  expect_match(reversible, "forward", fixed = TRUE)
  expect_match(reversible, "reverse", fixed = TRUE)

  directed <- network("butyrate_formation")
  expect_length(directed, 1L)
  expect_gt(lengths(regmatches(directed, gregexpr("marker-end=", directed))), 0L)
  expect_equal(lengths(regmatches(directed, gregexpr("marker-start=", directed))), 0L)
})
