# Organic acid and neutral fermentation product formation. The layer exists to
# separate two things the request that produced it treated as one: fermentation
# end products, which a genome can be said to release, and citric acid cycle
# intermediates, which it cannot. Most of these tests protect the second half.

organic_acid_gifts <- c(
  "lactate_formation", "lactate_racemisation", "malolactic_fermentation",
  "citrate_fermentation", "ethanol_formation", "acetoin_formation"
)

# Every acid of the citric acid cycle, by the molecule name an anchor would use.
tca_metabolites <- c(
  "CITRATE", "CIS_ACONITATE", "ISOCITRATE", "OXOGLUTARATE", "SUCCINYL_COA",
  "SUCCINATE", "FUMARATE", "MALATE", "OXALOACETATE"
)

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

test_that("every organic acid GIFT is curated to the full evidence depth", {
  for (gift_id in organic_acid_gifts) {
    gift <- get_gift(gift_id)
    expect_equal(nrow(gift), 1L)
    expect_equal(gift$gift_type, "metabolic")

    anchors <- get_gift_anchors(gift_id)
    expect_true(any(anchors$role == "input"))
    expect_true(any(anchors$role == "output"))
    # No organic acid transporter marker is specific enough to license a
    # compartment split, so no boundary here may claim one. The lactate
    # cross-feeding edge is as well documented as the acetate one and the model
    # still may not draw it.
    expect_true(all(anchors$compartment == "unspecified"))

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
      expect_gt(nrow(get_reaction_systems(reaction)), 0L)
    }
  }
})

test_that("no citric acid cycle acid is claimed as a released product", {
  # This test protected inst/doc/proposal-organic-acid-formation.md section 7,
  # which concluded that the citric acid cycle cannot be anchored at all. That
  # conclusion was right about the question it asked -- whether a genome can be
  # said to form and release citrate, fumarate or succinate -- and
  # inst/doc/proposal-central-metabolic-cycles.md asks a different one: what
  # chemistry a genome encodes between two boundaries. The cycle is now curated
  # as four segments and its acids are boundaries.
  #
  # What survives is the part the refusals were actually about, and it is what
  # this test now asserts: no GIFT claims that a genome forms and releases one
  # of these acids as a product.
  connection <- giftr_db_connect()
  withr::defer(giftr_db_disconnect(connection))
  anchors <- DBI::dbGetQuery(connection, "SELECT anchor_id, molecule FROM anchor")

  # Malate and citrate are consumed and never produced. Nothing in the database
  # outputs them, so a substrate anchor still makes no claim about how the
  # genome obtained the substrate.
  expect_true(all(c("MALATE", "CITRATE") %in% anchors$molecule))
  for (molecule in c("MALATE", "CITRATE")) {
    roles <- DBI::dbGetQuery(
      connection,
      "SELECT DISTINCT ga.role FROM gift_anchor ga
         JOIN anchor a ON a.anchor_pk = ga.anchor_pk
        WHERE a.molecule = ?",
      params = list(molecule)
    )$role
    expect_equal(roles, "input")
  }

  # The refused formation traits stay refused. Succinate, fumarate and
  # oxaloacetate are boundaries of segments of a cycle, and every GIFT that
  # declares one is either a segment of that cycle, a curated ring-cleavage
  # route that genuinely releases succinate as a co-product, or a consumer --
  # none is a formation trait, and the two segments that touch the
  # succinate/fumarate couple are reversible precisely because their markers
  # cannot say which way it runs.
  ring_cleavage_producers <- "dihydroxyphenylpropanoate_degradation"
  for (molecule in c("SUCCINATE", "FUMARATE", "OXALOACETATE")) {
    producers <- DBI::dbGetQuery(
      connection,
      "SELECT DISTINCT g.gift_id, g.mode FROM gift_anchor ga
         JOIN anchor a ON a.anchor_pk = ga.anchor_pk
         JOIN gift g ON g.gift_pk = ga.gift_pk
        WHERE a.molecule = ? AND ga.role = 'output'",
      params = list(molecule)
    )
    expect_true(all(producers$gift_id %in% c(
      gifts_by_facet("metabolic_cycle", "citric_acid_cycle_oxidative")$gift_id,
      ring_cleavage_producers
    )))
    expect_false(any(grepl("_formation$", producers$gift_id)))
  }
})

test_that("fumarate stays out of the graph although curated reactions make it", {
  # Adenylosuccinate lyase releases fumarate and is curated twice, in
  # purine_core_biosynthesis and adenylate_biosynthesis; the fumarate-dependent
  # dihydroorotate dehydrogenase consumes it in one of three pyrimidine routes.
  # Edges are derived from declared anchors only, so none of that connects.
  #
  # The assertion mattered more once FUMARATE became a declared anchor for the
  # citric acid cycle segments: the chemistry is curated, the co-product is
  # real, the anchor now exists, and the edge must still not be there.
  graph <- gift_graph()
  nucleotide <- c(
    "purine_core_biosynthesis", "adenylate_biosynthesis",
    "pyrimidine_core_biosynthesis"
  )
  expect_false(any(
    graph$shared_anchor == "FUMARATE" &
      (graph$from_gift %in% nucleotide | graph$to_gift %in% nucleotide)
  ))
  expect_false(any(
    graph$from_gift %in% c("purine_core_biosynthesis", "adenylate_biosynthesis") &
      graph$to_gift == "pyrimidine_core_biosynthesis"
  ))
})

test_that("lactate formation is evidenced in the direction it claims", {
  # The layer's reason for existing. Acetate had to be declared reversible
  # because one pair of genes serves both directions; lactate does not, because
  # the NAD-dependent enzyme that forms it and the quinone- or
  # cytochrome-dependent enzymes that consume it are different orthology groups.
  expect_equal(get_gift("lactate_formation")$mode, "catabolic")
  expect_true("lactate_formation" %in% complete_gifts("K00016"))

  # The consuming groups are refused, not accepted as alternatives. K29125 is
  # lldD, K00101 the cytochrome enzyme, K03777 and K00102 their D-specific
  # counterparts.
  for (consuming in c("K29125", "K00101", "K03777", "K00102")) {
    expect_false("lactate_formation" %in% complete_gifts(consuming))
  }
  # And adding them to a genome that already completes changes nothing.
  expect_setequal(
    complete_gifts("K00016"),
    complete_gifts("K00016", "K29125", "K00101", "K03777", "K00102")
  )

  # D-lactate dehydrogenase is deferred, so it evidences nothing here.
  expect_false("lactate_formation" %in% complete_gifts("K03778"))
})

test_that("the racemase closes the acrylate route's open input", {
  expect_equal(get_gift("lactate_racemisation")$mode, "interconversion")

  anchors <- get_gift_anchors("lactate_racemisation")
  expect_setequal(anchors$anchor_id[anchors$role == "input"], c("LACTATE_L", "LACTATE"))
  expect_setequal(anchors$anchor_id[anchors$role == "output"], c("LACTATE_L", "LACTATE"))
  # One traversal, not a mirrored pair: a flipped copy would complete on the
  # same marker and make closest-route selection non-deterministic.
  expect_equal(nrow(get_gift_routes("lactate_racemisation")), 1L)

  graph <- gift_graph()
  into_acrylate <- graph[graph$to_gift == "propionate_formation_acrylate", ]
  expect_equal(into_acrylate$from_gift, "lactate_racemisation")
  expect_equal(into_acrylate$shared_anchor, "LACTATE")
  expect_equal(into_acrylate$edge_quality, "exact")

  # Both lactate-forming GIFTs feed it, which is how the eight racemase-carrying
  # genomes behind the acrylate route actually reach (R)-lactate.
  into_racemase <- graph[graph$to_gift == "lactate_racemisation", ]
  expect_setequal(
    into_racemase$from_gift, c("lactate_formation", "malolactic_fermentation")
  )
  expect_true(all(into_racemase$shared_anchor == "LACTATE_L"))

  expect_true("lactate_racemisation" %in% complete_gifts("K22373"))
})

test_that("the two lactate anchors stay distinct", {
  # Enantiomers, not compartment variants of one molecule. Collapsing them would
  # let the L-specific dehydrogenase evidence the acrylate route's substrate.
  connection <- giftr_db_connect()
  withr::defer(giftr_db_disconnect(connection))
  lactate <- DBI::dbGetQuery(
    connection,
    "SELECT anchor_id, molecule, chebi_id FROM anchor WHERE anchor_id LIKE 'LACTATE%'"
  )
  expect_setequal(lactate$anchor_id, c("LACTATE", "LACTATE_L"))
  expect_equal(length(unique(lactate$molecule)), 2L)
  expect_setequal(lactate$chebi_id, c("CHEBI:16004", "CHEBI:16651"))

  # The L-specific enzyme alone must not complete the acrylate route.
  expect_false("propionate_formation_acrylate" %in% complete_gifts("K00016", "K22373"))
})

test_that("malolactic fermentation is the one place a cycle acid is a boundary", {
  expect_true("malolactic_fermentation" %in% complete_gifts("K22212"))
  anchors <- get_gift_anchors("malolactic_fermentation")
  expect_equal(anchors$anchor_id[anchors$role == "input"], "MALATE")
  expect_equal(anchors$anchor_id[anchors$role == "output"], "LACTATE_L")

  # Nothing produces malate, and the acyclicity argument is the HOMOCYSTEINE one.
  graph <- gift_graph()
  expect_false(any(graph$shared_anchor == "MALATE"))
})

test_that("citrate fermentation needs the whole holoenzyme and a decarboxylase", {
  lyase <- c("K01643", "K01644", "K01646", "K01910")
  expect_true("citrate_fermentation" %in% complete_gifts(lyase, "K01571"))
  # Either decarboxylase system satisfies the second step.
  expect_true("citrate_fermentation" %in% complete_gifts(lyase, "K01003"))
  # Three subunits of four is not a complex, and apo-citrate lyase is inactive
  # without its acyl-carrier ligase.
  expect_false(
    "citrate_fermentation" %in% complete_gifts(setdiff(lyase, "K01646"), "K01571")
  )
  expect_false(
    "citrate_fermentation" %in% complete_gifts(setdiff(lyase, "K01910"), "K01571")
  )
  # The lyase without a decarboxylase reports the missing step rather than
  # stopping the route at oxaloacetate, which would need an anchor section 7
  # refuses.
  result <- evaluate_gifts(markers_of(lyase))
  gift <- result$gifts[result$gifts$gift_id == "citrate_fermentation", ]
  expect_false(gift$complete)
  expect_equal(unlist(gift$missing_reactions_best_route), "RHEA:15641")

  # The transporter is not required evidence: the classic aerobic Cit-negative
  # phenotype of Escherichia coli K-12 is regulation, which giftr does not model,
  # so requiring CitT would look like a phenotype claim without being one.
  expect_setequal(
    complete_gifts(lyase, "K01571"),
    complete_gifts(lyase, "K01571", "K09477")
  )
})

test_that("acetoin rests on the decarboxylase, not on the shared synthase", {
  # The butyrate decision applied again. K01652 is ilvB/ilvG/ilvI, the anabolic
  # branched-chain amino acid synthase in 9341 organisms; it carries no
  # acetoin-specific information and must not be able to complete anything.
  expect_false("acetoin_formation" %in% complete_gifts("K01652"))
  expect_true("acetoin_formation" %in% complete_gifts("K01575"))
  expect_setequal(
    complete_gifts("K01575"), complete_gifts("K01575", "K01652")
  )

  # The synthase step stays curated so the PYRUVATE boundary is truthful; it is
  # the route membership that is optional, not the chemistry.
  reactions <- get_gift_reactions("acetoin_formation")
  expect_true("RHEA:25249" %in% reactions$reaction_id)
  expect_equal(as.integer(reactions$required[reactions$reaction_id == "RHEA:25249"]), 0L)
  expect_equal(as.integer(reactions$required[reactions$reaction_id == "RHEA:21580"]), 1L)
})

test_that("one bifunctional protein evidences both ethanol steps", {
  expect_true("ethanol_formation" %in% complete_gifts("K04072"))
  reactions <- get_gift_reactions("ethanol_formation")
  expect_setequal(reactions$reaction_id, c("RHEA:23288", "RHEA:25290"))
  # Both are run against the direction Rhea writes them in.
  expect_true(all(reactions$orientation == "reverse"))

  # The pyruvate decarboxylase route of Zymomonas and Saccharomyces is not
  # curated, so its markers complete nothing.
  expect_false("ethanol_formation" %in% complete_gifts("K01568", "K13953"))
})

test_that("the layer composes with existing catabolism and claims no cross-feeding", {
  graph <- gift_graph()
  # Pyruvate is already an output of the uronic acid GIFTs, so curating anything
  # that consumes it extends that layer without re-cutting it.
  into_lactate <- graph[graph$to_gift == "lactate_formation", ]
  expect_true(all(
    c("galacturonate_degradation", "glucuronate_degradation") %in% into_lactate$from_gift
  ))

  # Citrate fermentation lands on two anchors the database already had.
  from_citrate <- graph[graph$from_gift == "citrate_fermentation", ]
  expect_setequal(unique(from_citrate$shared_anchor), c("PYRUVATE", "ACETATE"))

  expect_false(any(graph$from_gift == graph$to_gift))

  profile <- gift_profile()
  layer <- profile[profile$gift_id %in% organic_acid_gifts, ]
  expect_equal(nrow(layer), length(organic_acid_gifts))
  expect_true(all(layer$cross_feeding_output == 0L))
  expect_true(all(layer$resource_strategy == "private"))
})
