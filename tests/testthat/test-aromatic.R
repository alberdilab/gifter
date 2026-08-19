# Aerobic aromatic ring catabolism. The layer is a funnel: three peripheral
# entries reach catechol, two cleavage strategies leave it, and the lower routes
# are curated once and shared. Most of these tests are about what the markers may
# not claim, because that is where the layer was nearly wrong.

aromatic_gifts <- c(
  "benzoate_degradation_catechol", "anthranilate_degradation_catechol",
  "phenol_hydroxylation", "catechol_ortho_cleavage", "oxoadipate_activation",
  "oxoadipyl_coa_thiolysis", "catechol_meta_cleavage",
  "oxopentenoate_degradation", "phenylacetate_degradation",
  "phenylpropanoate_dihydroxylation", "hydroxyphenylpropanoate_hydroxylation",
  "dihydroxyphenylpropanoate_degradation"
)

benzoate_markers <- c("K05549", "K05550", "K05783")
ortho_markers <- c("K03381", "K01856", "K03464", "K01055")
paa_markers <- c(
  "K01912", "K02609", "K02610", "K02611", "K02612", "K02613",
  "K15866", "K02618", "K02615", "K01692", "K00074"
)
phenol_markers <- c("K16249", "K16243", "K16244", "K16242", "K16245", "K16246")

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

test_that("every aromatic GIFT is curated to the full evidence depth", {
  for (gift_id in aromatic_gifts) {
    gift <- get_gift(gift_id)
    expect_equal(nrow(gift), 1L)
    expect_equal(gift$gift_type, "metabolic")
    expect_equal(gift$mode, "catabolic")

    anchors <- get_gift_anchors(gift_id)
    expect_true(any(anchors$role == "input"))
    expect_true(any(anchors$role == "output"))
    # No transport GIFT is evidenceable for an aromatic compound, so no boundary
    # here may claim a compartment and none may claim a cross-feeding edge.
    expect_true(all(anchors$compartment == "unspecified"))

    reactions <- get_gift_reactions(gift_id)
    expect_gt(nrow(reactions), 0L)
    for (reaction in unique(reactions$reaction_id)) {
      expect_gt(nrow(get_reaction_systems(reaction)), 0L)
    }
  }
})

test_that("the funnel composes through declared anchors and nothing else", {
  graph <- gift_graph()
  edge <- function(from, to) any(graph$from_gift == from & graph$to_gift == to)

  # Three entries converge on catechol, and both cleavage strategies leave it.
  for (entry in c(
    "benzoate_degradation_catechol", "anthranilate_degradation_catechol",
    "phenol_hydroxylation"
  )) {
    expect_true(edge(entry, "catechol_ortho_cleavage"))
    expect_true(edge(entry, "catechol_meta_cleavage"))
  }
  expect_true(edge("catechol_ortho_cleavage", "oxoadipate_activation"))
  expect_true(edge("catechol_meta_cleavage", "oxopentenoate_degradation"))

  # Two unrelated routes meet at the thioester, which is why the thiolysis is
  # one GIFT rather than a step duplicated inside each of them.
  expect_true(edge("oxoadipate_activation", "oxoadipyl_coa_thiolysis"))
  expect_true(edge("phenylacetate_degradation", "oxoadipyl_coa_thiolysis"))

  # Internal intermediates create no edges. cis,cis-Muconate is shared by the
  # ortho route's own reactions and is not an anchor, so ortho cleavage must not
  # reach the thiolysis without passing through the activation GIFT.
  expect_false(edge("catechol_ortho_cleavage", "oxoadipyl_coa_thiolysis"))
  expect_false(edge("catechol_ortho_cleavage", "oxopentenoate_degradation"))

  # The phenylpropanoid entries share their product anchor and nothing else.
  expect_true(edge("phenylpropanoate_dihydroxylation", "dihydroxyphenylpropanoate_degradation"))
  expect_true(edge("hydroxyphenylpropanoate_hydroxylation", "dihydroxyphenylpropanoate_degradation"))
  expect_false(edge("phenylpropanoate_dihydroxylation", "hydroxyphenylpropanoate_hydroxylation"))
})

test_that("K07104 does not fire catechol meta cleavage", {
  # It is assigned in 2081 KEGG genomes, led by Bacillus, Streptococcus,
  # Staphylococcus and Listeria, of which only 276 carry any lower meta pathway
  # gene. Accepting it would make the trait a Firmicutes trait.
  expect_false("catechol_meta_cleavage" %in% complete_gifts("K07104", "K10216"))
  expect_false(
    "catechol_meta_cleavage" %in%
      complete_gifts("K07104", "K10217", "K01821", "K01617")
  )

  # The specific orthologue and the corroborating family each complete it.
  expect_true("catechol_meta_cleavage" %in% complete_gifts("K00446", "K10216"))
  expect_true("catechol_meta_cleavage" %in% complete_gifts("TIGR03211", "K10216"))
})

test_that("meta cleavage completes by either branch, and ortho by either lactonase", {
  expect_true("catechol_meta_cleavage" %in% complete_gifts("K00446", "K10216"))
  expect_true(
    "catechol_meta_cleavage" %in%
      complete_gifts("K00446", "K10217", "K01821", "K01617")
  )
  # One dioxygenase alone is not a route.
  expect_false("catechol_meta_cleavage" %in% complete_gifts("K00446"))

  expect_true("catechol_ortho_cleavage" %in% complete_gifts(ortho_markers))
  # pcaL is the fused alternative to pcaD, so it is a system, not a component.
  expect_true(
    "catechol_ortho_cleavage" %in%
      complete_gifts("K03381", "K01856", "K03464", "K14727")
  )
})

test_that("the shared lower route completes on either enzyme set", {
  expect_true("oxopentenoate_degradation" %in% complete_gifts("K02554", "K01666", "K04073"))
  expect_true("oxopentenoate_degradation" %in% complete_gifts("K18364", "K18365", "K18366"))
  expect_false("oxopentenoate_degradation" %in% complete_gifts("K02554", "K01666"))
})

test_that("multi-subunit oxygenases are AND, and their shared carriers are not required", {
  expect_true("benzoate_degradation_catechol" %in% complete_gifts(benzoate_markers))
  # The beta subunit is jointly required.
  expect_false("benzoate_degradation_catechol" %in% complete_gifts("K05549", "K05783"))

  # The ferredoxin reductase is deliberately not curated: it is interchangeable
  # between Rieske systems and annotated far less often than the subunits it
  # serves. Adding it must change nothing, in either direction.
  expect_setequal(
    complete_gifts(benzoate_markers),
    complete_gifts(benzoate_markers, "K05784")
  )

  # Where the components really are the enzyme, all of them are required.
  expect_true("phenol_hydroxylation" %in% complete_gifts(phenol_markers))
  for (dropped in phenol_markers) {
    expect_false(
      "phenol_hydroxylation" %in% complete_gifts(setdiff(phenol_markers, dropped))
    )
  }
})

test_that("anthranilate cleavage accepts either non-homologous oxygenase", {
  expect_true("anthranilate_degradation_catechol" %in% complete_gifts("K05599", "K05600"))
  expect_true("anthranilate_degradation_catechol" %in% complete_gifts("K16319", "K16320"))
  expect_false("anthranilate_degradation_catechol" %in% complete_gifts("K05599", "K16320"))
})

test_that("the phenylacetate route reports the thiolase as a missing reaction", {
  expect_true("phenylacetate_degradation" %in% complete_gifts(paa_markers))

  result <- evaluate_gifts(markers_of(setdiff(paa_markers, "K02615")))
  gift <- result$gifts[result$gifts$gift_id == "phenylacetate_degradation", ]
  expect_false(gift$complete)
  expect_equal(unlist(gift$missing_reactions_best_route), "RHEA:34799")

  # The trait's specificity comes from the ligase and the epoxidase, so removing
  # the ligase must break it even with the whole tail present.
  expect_false(
    "phenylacetate_degradation" %in% complete_gifts(setdiff(paa_markers, "K01912"))
  )
})

test_that("one bifunctional protein evidences two consecutive reactions", {
  # PaaZ hydrolyses the oxepin and oxidises the semialdehyde. Both reactions are
  # curated, and both rest on the same accession, which is what the marker layer
  # is for.
  for (reaction in c("RHEA:31755", "RHEA:31747")) {
    systems <- get_reaction_systems(reaction)
    expect_true(any(grepl("PAAZ", systems$system_id)))
  }
  result <- evaluate_gifts(markers_of(paa_markers))
  trace <- trace_gift(result, "phenylacetate_degradation")
  paaz <- trace[trace$reaction_id %in% c("RHEA:31755", "RHEA:31747"), ]
  expect_setequal(paaz$reaction_id, c("RHEA:31755", "RHEA:31747"))
  # Both steps trace back to one accession, carried by one gene.
  expect_equal(unique(paaz$accession), "K02618")
  expect_equal(length(unique(paaz$gene_id)), 1L)
})

test_that("route direction is curated where Rhea writes the other way", {
  ortho <- get_gift_reactions("catechol_ortho_cleavage")
  expect_equal(
    ortho$orientation[ortho$reaction_id == "RHEA:30031"], "reverse"
  )
  thiolysis <- get_gift_reactions("oxoadipyl_coa_thiolysis")
  expect_equal(
    thiolysis$orientation[thiolysis$reaction_id == "RHEA:19481"], "reverse"
  )
  lower <- get_gift_reactions("oxopentenoate_degradation")
  expect_equal(lower$orientation[lower$reaction_id == "RHEA:22580"], "reverse")
})

test_that("adding the aromatic acetaldehyde dehydrogenases leaves ethanol formation alone", {
  # MhpF and XylQ are alternative systems of a reaction ethanol formation already
  # uses, so the addition was checked rather than assumed: the route's second
  # reaction rests on adhE alone, and a genome carrying adhE already satisfied
  # the first. No ethanol call changes.
  expect_true("ethanol_formation" %in% complete_gifts("K04072"))
  expect_false("ethanol_formation" %in% complete_gifts("K04073"))
  expect_false("ethanol_formation" %in% complete_gifts("K18366"))
  expect_setequal(complete_gifts("K04072"), complete_gifts("K04072", "K04073"))
})

test_that("the layer is classified as aromatic chemistry and nothing broader", {
  for (gift_id in aromatic_gifts) {
    facets <- get_facets(gift_id)
    expect_equal(facets$value[facets$facet == "substrate_class"], "aromatic_compound")
    expect_true("aromatic_ring_catabolism" %in% facets$value[facets$facet == "physiological_role"])
  }
  # The layer is named for the chemistry, not for the compounds' origin: no
  # xenobiotic role exists, and provenance lives on the anchor instead.
  expect_false("xenobiotic_degradation" %in% list_facets()$value)
  expect_true("anthropogenic" %in% list_facets()$value)
})

test_that("every aromatic route records an oxygen requirement that matches its chemistry", {
  # Oxygen requirement is a route property. Here it separates the ring
  # chemistry, which uses O2 as a substrate, from everything after cleavage,
  # which does not -- and it is why this layer will be silent in strict
  # anaerobes without any of its calls being wrong.
  connection <- giftr_db_connect()
  withr::defer(giftr_db_disconnect(connection))
  oxygen <- DBI::dbGetQuery(
    connection,
    "SELECT g.gift_id, r.oxygen_requirement FROM gift_route r
       JOIN gift g ON g.gift_pk = r.gift_pk"
  )
  requirement <- function(gift_id) oxygen$oxygen_requirement[oxygen$gift_id == gift_id]

  for (gift_id in c(
    "benzoate_degradation_catechol", "anthranilate_degradation_catechol",
    "phenol_hydroxylation", "catechol_ortho_cleavage", "catechol_meta_cleavage",
    "phenylacetate_degradation", "phenylpropanoate_dihydroxylation",
    "hydroxyphenylpropanoate_hydroxylation", "dihydroxyphenylpropanoate_degradation"
  )) {
    expect_true(all(requirement(gift_id) == "aerobic"))
  }
  for (gift_id in c(
    "oxoadipate_activation", "oxoadipyl_coa_thiolysis", "oxopentenoate_degradation"
  )) {
    expect_true(all(requirement(gift_id) == "independent"))
  }
})
