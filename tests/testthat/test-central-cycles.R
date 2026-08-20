# Circular central metabolism, curated as atomic composable segments plus
# derived closure. The assessment is inst/doc/proposal-central-metabolic-cycles.md.
#
# Most of these tests protect two things the layer exists to get right: that a
# segment is a capability with its own Boolean call, and that whether the cycle
# closes is derived from those calls and never feeds back into one.

cycle_gifts <- c(
  "acetyl_coa_to_isocitrate", "isocitrate_to_oxoglutarate",
  "oxoglutarate_to_succinate",
  "succinate_fumarate_interconversion", "fumarate_oxaloacetate_interconversion"
)

glyoxylate_cycle_gifts <- c(
  "acetyl_coa_to_isocitrate", "glyoxylate_bypass",
  "succinate_fumarate_interconversion", "fumarate_oxaloacetate_interconversion"
)

markers_of <- function(...) {
  accessions <- unlist(list(...), use.names = FALSE)
  data.frame(
    gene_id = paste0("gene_", seq_along(accessions)),
    namespace = "KO",
    accession = accessions,
    stringsAsFactors = FALSE
  )
}

complete_gifts <- function(...) {
  result <- evaluate_gifts(markers_of(...))
  result$gifts$gift_id[result$gifts$complete]
}

# Marker sets standing for real architectures. Each was checked against KEGG
# organism gene content on 2026-08-18; see section 7 of the proposal.
architecture <- list(
  complete = c(
    "K01647", "K01682", "K00031", "K00164", "K00658", "K00382",
    "K01902", "K01903", "K00239", "K00240", "K01679", "K00024"
  ),
  kgd_bypass = c(
    "K01647", "K27802", "K00031", "K01616", "K00139",
    "K00239", "K00240", "K01679", "K00024"
  ),
  branched = c("K01647", "K01682", "K00031", "K00174", "K00175", "K01679", "K00024"),
  none = "K00016"
)

test_that("every cycle segment is curated to the full evidence depth", {
  for (gift_id in cycle_gifts) {
    gift <- get_gift(gift_id)
    expect_equal(nrow(gift), 1L)
    expect_equal(gift$gift_type, "metabolic")

    anchors <- get_gift_anchors(gift_id)
    expect_true(any(anchors$role == "input"))
    expect_true(any(anchors$role == "output"))
    # No transporter marker licenses a compartment split for these acids, so no
    # boundary here may claim one.
    expect_true(all(anchors$compartment == "unspecified"))

    reactions <- get_gift_reactions(gift_id)
    expect_gt(nrow(reactions), 0L)
    for (reaction in unique(reactions$reaction_id)) {
      expect_gt(nrow(get_reaction_systems(reaction)), 0L)
    }
  }
})

test_that("a reversible segment declares every anchor in both roles", {
  # The interconversion contract. Declaring some anchors reversibly and others
  # not would claim a direction for half the boundary.
  for (gift_id in cycle_gifts) {
    anchors <- get_gift_anchors(gift_id)
    inputs <- anchors$anchor_id[anchors$role == "input"]
    outputs <- anchors$anchor_id[anchors$role == "output"]
    if (identical(get_gift(gift_id)$mode, "interconversion")) {
      expect_setequal(inputs, outputs)
    } else {
      expect_length(intersect(inputs, outputs), 0L)
    }
  }
  expect_equal(get_gift("acetyl_coa_to_isocitrate")$mode, "catabolic")
  expect_equal(get_gift("isocitrate_to_oxoglutarate")$mode, "catabolic")
  expect_equal(get_gift("oxoglutarate_to_succinate")$mode, "catabolic")
  expect_equal(get_gift("succinate_fumarate_interconversion")$mode, "interconversion")
  expect_equal(get_gift("fumarate_oxaloacetate_interconversion")$mode, "interconversion")
})

test_that("the succinate/fumarate couple claims no direction", {
  # The durable protection for section 6.4. K00239 is named by KEGG sdhA, frdA:
  # one orthology group for both enzymes. Two opposed directional GIFTs would be
  # complete on identical markers, so there is one reversible GIFT instead, and
  # it must stay reversible.
  anchors <- get_gift_anchors("succinate_fumarate_interconversion")
  expect_setequal(anchors$anchor_id[anchors$role == "input"], c("SUCCINATE", "FUMARATE"))
  expect_setequal(anchors$anchor_id[anchors$role == "output"], c("SUCCINATE", "FUMARATE"))
  # One traversal, not a mirrored pair: a flipped copy would complete on the
  # same markers and make closest-route selection non-deterministic.
  expect_equal(nrow(get_gift_routes("succinate_fumarate_interconversion")), 1L)

  # The shared group and each dedicated group satisfy it on their own.
  for (pair in list(c("K00239", "K00240"), c("K00234", "K00235"), c("K00244", "K00245"))) {
    expect_true("succinate_fumarate_interconversion" %in% complete_gifts(pair))
  }
  # One subunit of a two-subunit system is not enough.
  expect_false("succinate_fumarate_interconversion" %in% complete_gifts("K00239"))
})

test_that("the three routes to succinate are alternatives, not requirements", {
  scs <- c("K01902", "K01903")
  odh <- complete_gifts("K00164", "K00658", "K00382", scs)
  ofor <- complete_gifts("K00174", "K00175", scs)
  kgd <- complete_gifts("K01616", "K00139")
  for (calls in list(odh, ofor, kgd)) {
    expect_true("oxoglutarate_to_succinate" %in% calls)
  }
  # The decarboxylase bypass is what makes the actinobacteria positive without
  # the E1o component, so it must not require any part of the complex.
  expect_false("oxoglutarate_to_succinate" %in% complete_gifts("K00164", "K00658", scs))
  expect_false("oxoglutarate_to_succinate" %in% complete_gifts("K01616"))
})

test_that("the ambiguous citrate synthase group is accepted and reported as such", {
  # Section 6.2. K01659 is named by KEGG 2-methylcitrate synthase and carries the
  # genuine citrate synthases of Bacteroides thetaiotaomicron and Staphylococcus
  # aureus. Accepting it keeps those genomes positive; recording it as ambiguous
  # is what stops the call from looking better evidenced than it is.
  aconitase_icdh <- c("K27802", "K00031")
  canonical <- evaluate_gifts(markers_of("K01647", aconitase_icdh))
  ambiguous <- evaluate_gifts(markers_of("K01659", aconitase_icdh))
  row <- function(result) {
    result$gifts[result$gifts$gift_id == "acetyl_coa_to_isocitrate", ]
  }
  expect_true(row(canonical)$complete)
  expect_true(row(ambiguous)$complete)
  expect_equal(row(canonical)$evidence_confidence, "curated")
  expect_equal(row(ambiguous)$evidence_confidence, "ambiguous")
})

test_that("aconitase accepts all three orthology groups", {
  # K27802 was split out of K01681 by KEGG. Without it Bacillus subtilis and
  # Mycobacterium tuberculosis are wrongly called aconitase-negative.
  for (aconitase in c("K01681", "K01682", "K27802")) {
    expect_true(
      "acetyl_coa_to_isocitrate" %in% complete_gifts("K01647", aconitase)
    )
  }
})

test_that("the oxidative citric acid cycle is derived, not curated", {
  cycles <- gift_cycles()
  expect_gte(nrow(cycles), 9L)

  named <- unique(cycles[c("cycle_id", "named_cycle", "cycle_length")])
  tca <- named$cycle_id[named$named_cycle %in% "citric_acid_cycle_oxidative"]
  expect_length(tca, 1L)

  members <- cycles[cycles$cycle_id == tca, ]
  expect_equal(members$cycle_length[[1]], 5L)
  expect_setequal(members$gift_id, cycle_gifts)
  # The ring closes through the four declared boundaries and nothing else.
  expect_setequal(
    members$shared_anchor,
    c("ISOCITRATE", "OXOGLUTARATE", "SUCCINATE", "FUMARATE", "OXALOACETATE")
  )

  # Every edge of the derived cycle is a real edge of the composition graph.
  graph <- gift_graph()
  following <- c(members$gift_id[-1], members$gift_id[[1]])
  for (step in seq_len(nrow(members))) {
    expect_true(any(
      graph$from_gift == members$gift_id[[step]] &
        graph$to_gift == following[[step]] &
        graph$shared_anchor == members$shared_anchor[[step]]
    ))
  }
})

test_that("a two-node loop between reversible GIFTs is not reported as a cycle", {
  # An interconversion GIFT declares every anchor in both roles, so two adjacent
  # ones produce an edge each way by construction. That loop is made by the mode
  # and not by the chemistry; the source validator exempts it and gift_cycles()
  # must not report it as metabolism.
  cycles <- gift_cycles()
  pair <- cycles$cycle_id[cycles$cycle_length == 2L]
  expect_length(pair, 0L)
})

test_that("closure is derived from calls and never changes one", {
  closed <- evaluate_gifts(markers_of(architecture$complete))
  open <- evaluate_gifts(markers_of(architecture$branched))
  absent <- evaluate_gifts(markers_of(architecture$none))

  cycle_result <- function(result) {
    evaluated <- evaluate_gift_cycles(result)
    evaluated[evaluated$named_cycle == "citric_acid_cycle_oxidative", ]
  }
  status <- function(result) cycle_result(result)$status
  expect_equal(status(closed), "closed")
  expect_equal(status(open), "open")
  expect_equal(status(absent), "absent")

  # The branched genome supports two of four segments, and both calls are the
  # same as they would be in isolation. An open cycle must not downgrade a
  # member: inferring absence from a neighbour's absence is the opposite of what
  # the composition model is for.
  branched <- cycle_result(open)
  expect_equal(branched$supported, 3L)
  expect_true("acetyl_coa_to_isocitrate" %in% complete_gifts(architecture$branched))
  alone <- complete_gifts("K01647", "K01682", "K00031")
  expect_true("acetyl_coa_to_isocitrate" %in% alone)
  expect_true("isocitrate_to_oxoglutarate" %in% alone)
  expect_false("oxoglutarate_to_succinate" %in% alone)

  # And the broken members are named rather than summarised as a percentage.
  expect_equal(
    sort(strsplit(branched$broken_at, ", ", fixed = TRUE)[[1]]),
    sort(c("oxoglutarate_to_succinate", "succinate_fumarate_interconversion"))
  )
})

test_that("the actinobacterial bypass closes the cycle without the E1o complex", {
  result <- evaluate_gifts(markers_of(architecture$kgd_bypass))
  evaluated <- evaluate_gift_cycles(result)
  oxidative <- evaluated[evaluated$named_cycle == "citric_acid_cycle_oxidative", ]
  expect_equal(oxidative$status, "closed")
  route <- result$gifts$best_implementation[
    result$gifts$gift_id == "oxoglutarate_to_succinate"
  ]
  expect_equal(route, "TCA2_KGD_SSADH_NAD")
})

test_that("the segments connect to the curated catabolic content", {
  # The composition dividend: acetyl-CoA was a terminal boundary before this
  # layer and now carries the entry edge into the cycle.
  graph <- gift_graph()
  into_cycle <- graph[graph$to_gift == "acetyl_coa_to_isocitrate", ]
  expect_true(all(into_cycle$edge_quality == "exact"))
  expect_true(all(
    c("pyruvate_to_acetyl_coa", "acetate_interconversion") %in% into_cycle$from_gift
  ))
  expect_true("ACETYL_COA" %in% into_cycle$shared_anchor)
})

test_that("citrate stays input-only while bypass malate composes", {
  # Citrate remains internal to the upper segment and cannot create the
  # unrelated fermentation loop. Malate is now a justified bypass output and
  # therefore connects specifically to malolactic fermentation.
  connection <- giftr_db_connect()
  withr::defer(giftr_db_disconnect(connection))
  roles <- DBI::dbGetQuery(
    connection,
    "SELECT DISTINCT ga.role FROM gift_anchor ga
       JOIN anchor a ON a.anchor_pk = ga.anchor_pk
      WHERE a.molecule = 'CITRATE'"
  )$role
  expect_equal(roles, "input")
  graph <- gift_graph()
  expect_false(any(graph$shared_anchor == "CITRATE"))
  expect_true(any(
    graph$from_gift == "glyoxylate_bypass" &
      graph$to_gift == "malolactic_fermentation" &
      graph$shared_anchor == "MALATE"
  ))
})

test_that("declaring FUMARATE creates no edge between purine and pyrimidine", {
  # This assertion existed before FUMARATE was an anchor and protected a
  # hypothetical. It now protects a live risk: the chemistry is curated, the
  # co-product is real, and the edge must still not exist, because giftr derives
  # edges from declared boundaries and not from shared reaction participants.
  graph <- gift_graph()
  expect_false(any(
    graph$from_gift %in% c("purine_core_biosynthesis", "adenylate_biosynthesis") &
      graph$to_gift == "pyrimidine_core_biosynthesis"
  ))
  expect_false(any(
    graph$shared_anchor == "FUMARATE" &
      graph$from_gift %in% c("purine_core_biosynthesis", "adenylate_biosynthesis")
  ))
})

test_that("the cycle facet names a cycle and classifies nothing else", {
  members <- gifts_by_facet("metabolic_cycle", "citric_acid_cycle_oxidative")
  expect_setequal(members$gift_id, cycle_gifts)

  bypass <- gifts_by_facet("metabolic_cycle", "glyoxylate_cycle")
  expect_setequal(bypass$gift_id, glyoxylate_cycle_gifts)
})

test_that("the glyoxylate cycle is derived from the isocitrate cut", {
  cycles <- gift_cycles()
  ids <- unique(cycles$cycle_id[cycles$named_cycle == "glyoxylate_cycle"])
  expect_length(ids, 1L)
  members <- cycles[cycles$cycle_id == ids, ]
  expect_equal(unique(members$cycle_length), 4L)
  expect_setequal(members$gift_id, glyoxylate_cycle_gifts)
  expect_setequal(
    members$shared_anchor,
    c("ISOCITRATE", "SUCCINATE", "FUMARATE", "OXALOACETATE")
  )
})
