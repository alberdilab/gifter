# Protein degradation is the layer where trait specificity and marker
# specificity come apart most easily, because proteases are named for the
# substrates they were assayed on rather than for the substrates their sequence
# family predicts. These tests protect the boundary between the two.
# Reasoning and per-substrate outcomes: inst/doc/proposal-protein-degradation.md.

refused_substrates <- c(
  "elastin", "keratin", "albumin", "actin",
  "glutelin", "tropomyosin", "troponin"
)

# Enzymes that hydrolyse peptide bonds broadly, including host proteins. None
# of them is evidence for a substrate-specific cleavage trait.
generic_protease_markers <- c(
  "K01399",  # lasB, pseudolysin: elastin, collagen III and IV, fibronectin, IgA
  "K01400",  # nprE, bacillolysin
  "K01401",  # aur, aureolysin
  "K01361",  # lactocepin
  "K14647"   # vpr, minor extracellular serine protease
)

test_that("a generic protease does not call a substrate-specific cleavage GIFT", {
  # The failure this guards against is not merely a false positive. Pseudolysin
  # hydrolyses collagen among several host proteins, so admitting it would
  # license a collagen call without a family M9 collagenase, and would equate
  # collagen cleavage with generic proteolysis -- damaging the trait it was not
  # admitted for.
  result <- evaluate_gifts(ko_annotations(generic_protease_markers))
  protein_gifts <- gifts_by_facet("substrate_class", "protein")$gift_id
  expect_true(length(protein_gifts) > 0)

  called <- result$gifts[result$gifts$gift_id %in% protein_gifts, ]
  expect_false(any(called$complete))

  # None of these markers is accepted anywhere in the database.
  expect_false(any(map_markers(ko_annotations(generic_protease_markers))$matched))
})

test_that("collagen cleavage is called only by mechanistically specific markers", {
  ask <- function(annotations) {
    result <- evaluate_gifts(annotations)
    result$gifts[result$gifts$gift_id == "collagen_cleavage", ]
  }

  # OR at the marker layer: the orthologue and the Pfam domain are alternative
  # evidence for one protein, not alternative enzymes.
  expect_true(ask(ko_annotations("K01387"))$complete)

  pfam <- data.frame(
    gene_id = "gene_1", namespace = "PFAM", accession = "PF01752",
    stringsAsFactors = FALSE
  )
  expect_true(ask(pfam)$complete)

  # A genome with broad proteolytic capability and no M9 collagenase is
  # negative, and the trace names the chemistry it lacks.
  without <- ask(ko_annotations(generic_protease_markers))
  expect_false(without$complete)
  expect_equal(without$missing_reactions_best_route[[1]], "RXN_COLLAGEN_HELIX_CLEAVAGE")
})

test_that("EC alone cannot carry a single-reaction protein cleavage call", {
  # Marker policy: an EC number asserts an activity with no sequence claim and
  # is never sufficient evidence for a required reaction. This GIFT has exactly
  # one required reaction, so admitting the EC as a marker would let it carry
  # the whole call. It is the reaction cross-reference instead.
  connection <- giftr_db_connect()
  withr::defer(giftr_db_disconnect(connection))

  markers <- DBI::dbGetQuery(connection, paste(
    "SELECT m.namespace FROM component_marker cm",
    "JOIN marker m ON m.marker_pk = cm.marker_pk",
    "JOIN enzyme_component ec ON ec.component_pk = cm.component_pk",
    "JOIN enzyme_system es ON es.system_pk = ec.system_pk",
    "JOIN reaction r ON r.reaction_pk = es.reaction_pk",
    "WHERE r.reaction_id = 'RXN_COLLAGEN_HELIX_CLEAVAGE'"
  ))$namespace
  expect_false("EC" %in% markers)

  xrefs <- DBI::dbGetQuery(connection, paste(
    "SELECT x.namespace, x.accession FROM reaction_xref x",
    "JOIN reaction r ON r.reaction_pk = x.reaction_pk",
    "WHERE r.reaction_id = 'RXN_COLLAGEN_HELIX_CLEAVAGE'"
  ))
  expect_equal(xrefs$namespace, "EC")
  expect_equal(xrefs$accession, "3.4.24.3")
})

test_that("refused substrates have no GIFT and no marker evidence", {
  # A regression guard rather than a tautology: it fails the day a
  # substrate-specific trait is added on family-level protease evidence.
  connection <- giftr_db_connect()
  withr::defer(giftr_db_disconnect(connection))

  gift_text <- DBI::dbGetQuery(
    connection, "SELECT gift_id, name, description FROM gift"
  )
  claimed <- tolower(paste(gift_text$gift_id, gift_text$name))
  for (substrate in refused_substrates) {
    expect_false(any(grepl(substrate, claimed, fixed = TRUE)))
  }

  accepted <- DBI::dbGetQuery(
    connection, "SELECT accession FROM marker WHERE namespace = 'KO'"
  )$accession
  expect_false(any(generic_protease_markers %in% accepted))
})

test_that("protein anchors work without a ChEBI identity or a Rhea master", {
  # Anchors were never restricted to small molecules and reactions were never
  # restricted to Rhea-covered chemistry. Collagenolysis needed neither.
  connection <- giftr_db_connect()
  withr::defer(giftr_db_disconnect(connection))

  anchors <- DBI::dbGetQuery(connection, paste(
    "SELECT anchor_id, compartment, chebi_id FROM anchor",
    "WHERE anchor_id IN ('COLLAGEN', 'COLLAGEN_PEPTIDES')"
  ))
  expect_equal(nrow(anchors), 2L)
  expect_true(all(anchors$compartment == "extracellular"))
  expect_true(all(is.na(anchors$chebi_id)))

  reaction <- get_reaction("RXN_COLLAGEN_HELIX_CLEAVAGE")
  expect_true(is.na(reaction$rhea_master))
})

test_that("the cleavage product is a substrate-specific boundary, not a pool", {
  # A shared peptide pool would connect every protein-degradation GIFT to every
  # other one's downstream through an entity with no membership criterion. The
  # product anchor is substrate-specific and terminal instead, so the trait is
  # isolated in the composition graph until a peptide tier is licensed by
  # transporter evidence.
  connection <- giftr_db_connect()
  withr::defer(giftr_db_disconnect(connection))

  anchors <- DBI::dbGetQuery(connection, "SELECT anchor_id FROM anchor")$anchor_id
  expect_false(any(anchors %in% c("PEPTIDES", "AMINO_ACIDS")))

  edges <- gift_graph()
  expect_equal(
    nrow(edges[edges$from_gift == "collagen_cleavage" |
                 edges$to_gift == "collagen_cleavage", ]),
    0L
  )

  profile <- gift_profile()
  collagen <- profile[profile$gift_id == "collagen_cleavage", ]
  expect_equal(collagen$substrate_tier, "polymer")
  expect_equal(collagen$network_position, "isolated")
  # Cleaved outside, released outside: the peptides are available to others.
  expect_equal(collagen$resource_strategy, "public_good")
})
