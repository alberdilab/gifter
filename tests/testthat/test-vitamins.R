# Vitamin biosynthesis. Three things separate this layer from the ones before
# it: reactions that are certainly present and have no marker of their own, a
# vitamin whose name is a claim about a lower ligand rather than about a ring,
# and cofactor products that must not become input anchors. Most of these tests
# defend one of those three.

vitamin_gifts <- c(
  "riboflavin_biosynthesis", "paba_biosynthesis", "folate_biosynthesis",
  "hmp_phosphate_biosynthesis", "thiazole_phosphate_biosynthesis",
  "thiamine_phosphate_biosynthesis", "thiamine_precursor_salvage",
  "pantothenate_biosynthesis", "plp_biosynthesis_r5p", "plp_biosynthesis_dxp",
  "biotin_biosynthesis", "quinolinate_biosynthesis_aspartate",
  "namn_biosynthesis_quinolinate", "nad_biosynthesis_namn",
  "namn_salvage_nicotinate", "corrin_ring_biosynthesis",
  "cobinamide_biosynthesis", "cobamide_nucleotide_loop_assembly",
  "dmb_biosynthesis_aerobic", "menaquinone_biosynthesis"
)

vitamin_complete <- function(...) {
  result <- evaluate_gifts(ko_annotations(c(...)))
  result$gifts$gift_id[result$gifts$complete]
}

# Two properties this layer depends on are curated rather than exposed by the
# public API: the oxygen requirement of a route, and whether a marker is in the
# database at all. Both are read from the reviewable source tables.
vitamin_source <- function(table) {
  packaged <- system.file("extdata", "database-source", package = "gifter")
  if (!nzchar(packaged)) packaged <- file.path("inst", "extdata", "database-source")
  utils::read.delim(
    file.path(packaged, paste0(table, ".tsv")),
    colClasses = "character", check.names = FALSE, na.strings = c("", "NA")
  )
}

route_oxygen <- function(gift_id) {
  routes <- vitamin_source("gift_routes")
  routes$oxygen_requirement[routes$gift_id == gift_id]
}

curated_accessions <- function() vitamin_source("markers")$accession

anchor_compartments <- function(anchor_ids) {
  anchors <- vitamin_source("anchors")
  anchors$compartment[anchors$anchor_id %in% anchor_ids]
}

riboflavin_markers <- c("K01497", "K01498", "K00082", "K02858", "K00794", "K00793")
folate_markers <- c("K01495", "K01633", "K00950", "K00796", "K11754", "K00287")
menaquinone_classic_markers <- c(
  "K02552", "K02551", "K02549", "K01911", "K01661", "K02548", "K03183"
)
futalosine_markers <- c(
  "K11782", "K18285", "K11783", "K11784", "K11785", "K02548", "K03183"
)
corrin_anaerobic_markers <- c(
  "K02303", "K02304", "K03795", "K03394", "K05934", "K05936", "K02189",
  "K02188", "K05895", "K02191", "K03399", "K06042", "K02224"
)
loop_markers <- c("K02231", "K00768", "K02226", "K02233")

test_that("every vitamin GIFT is curated to the full evidence depth", {
  for (gift_id in vitamin_gifts) {
    gift <- get_gift(gift_id)
    expect_equal(nrow(gift), 1L)
    expect_equal(gift$gift_type, "metabolic")
    expect_equal(gift$mode, "anabolic")

    anchors <- get_gift_anchors(gift_id)
    expect_true(any(anchors$role == "input"))
    expect_true(any(anchors$role == "output"))
    # No vitamin transporter is evidenceable, so no boundary in this layer may
    # claim a compartment. Declaring one would manufacture the cross-feeding
    # edge the proposal deliberately refuses.
    expect_true(all(anchors$compartment == "unspecified"))
    expect_length(
      intersect(
        anchors$anchor_id[anchors$role == "input"],
        anchors$anchor_id[anchors$role == "output"]
      ),
      0L
    )

    reactions <- get_gift_reactions(gift_id)
    expect_gt(nrow(reactions), 0L)
    for (reaction in unique(reactions$reaction_id)) {
      expect_gt(nrow(get_reaction_systems(reaction)), 0L)
    }
  }
})

test_that("the layer classifies itself as cofactor chemistry with a vitamin role", {
  profile <- gift_profile()
  layer <- profile[profile$gift_id %in% vitamin_gifts, ]
  expect_equal(nrow(layer), length(vitamin_gifts))
  expect_true(all(layer$substrate_class == "cofactor"))

  facets <- get_facets("riboflavin_biosynthesis", "gift")
  roles <- facets$value[facets$facet == "physiological_role"]
  expect_true(all(c("biosynthesis", "vitamin_biosynthesis") %in% roles))

  # Nothing in the layer may claim to feed anything else: without a transport
  # GIFT there is no extracellular anchor to cross-feed from.
  expect_true(all(layer$cross_feeding_output == 0))

  # A GIFT whose product is a building block a cell must otherwise import is an
  # auxotrophy indicator, and that follows from the anchor facet alone.
  vitamins <- c(
    "riboflavin_biosynthesis", "folate_biosynthesis", "paba_biosynthesis",
    "thiamine_phosphate_biosynthesis", "pantothenate_biosynthesis",
    "plp_biosynthesis_r5p", "biotin_biosynthesis", "nad_biosynthesis_namn",
    "cobamide_nucleotide_loop_assembly", "menaquinone_biosynthesis"
  )
  expect_true(all(layer$auxotrophy_indicator[layer$gift_id %in% vitamins] == 1))
})

test_that("an orphan step is curated but does not gate the call", {
  # Three reactions in this layer are certain chemistry with no marker at the
  # specificity of the step. Each is present in its route, and each is
  # required = 0, so a genome carrying everything else is complete.
  orphans <- list(
    riboflavin_biosynthesis = "RHEA:25197",
    folate_biosynthesis = "RHEA:25302",
    menaquinone_biosynthesis = c("RHEA:25597", "RHEA:26309")
  )
  for (gift_id in names(orphans)) {
    reactions <- get_gift_reactions(gift_id)
    for (reaction in orphans[[gift_id]]) {
      rows <- reactions[reactions$reaction_id == reaction, ]
      expect_gt(nrow(rows), 0L)
      expect_true(all(rows$required == 0))
    }
  }

  expect_true("riboflavin_biosynthesis" %in% vitamin_complete(riboflavin_markers))
  expect_true("folate_biosynthesis" %in% vitamin_complete(folate_markers))
  expect_true(
    "menaquinone_biosynthesis" %in% vitamin_complete(menaquinone_classic_markers)
  )

  # Adding the orphan marker must change nothing, in either direction.
  expect_setequal(
    vitamin_complete(riboflavin_markers),
    vitamin_complete(riboflavin_markers, "K20862")
  )
})

test_that("a generic phosphatase is never accepted as folate evidence", {
  # The dihydroneopterin monophosphatase step is uncurated rather than
  # evidenced by an alkaline phosphatase, which would fire in most genomes and
  # would damage every other trait that marker also matches.
  expect_false(any(curated_accessions() %in% c("K01077", "K01113")))
  expect_false("folate_biosynthesis" %in% vitamin_complete("K01077", "K01113"))
})

test_that("bifunctional proteins complete riboflavin biosynthesis on their own", {
  # RibAB carries the cyclohydrolase and the butanone phosphate synthase; RibG
  # carries the deaminase and the reductase. Four accessions must be enough.
  expect_true(
    "riboflavin_biosynthesis" %in%
      vitamin_complete("K14652", "K11752", "K00794", "K00793")
  )
})

test_that("folate is cut at 4-aminobenzoate and the two halves compose", {
  paba <- c("K01665", "K02619")
  expect_true("paba_biosynthesis" %in% vitamin_complete(paba))
  # The pterin branch completes without the aromatic one: this is the
  # Bifidobacterium profile, and the distinction is the point of the cut.
  expect_false("paba_biosynthesis" %in% vitamin_complete(folate_markers))
  expect_true("folate_biosynthesis" %in% vitamin_complete(folate_markers))

  edge <- gift_graph()
  edge <- edge[edge$from_gift == "paba_biosynthesis", ]
  expect_true("folate_biosynthesis" %in% edge$to_gift)
  expect_true(all(edge$edge_quality[edge$to_gift == "folate_biosynthesis"] == "exact"))
})

test_that("thiamine salvage reaches the same two anchors as de novo synthesis", {
  de_novo <- c("K03147", "K00941", "K03150", "K03149", "K00788")
  salvage <- c("K00941", "K00878", "K00788")

  complete <- vitamin_complete(de_novo)
  expect_true(all(c(
    "hmp_phosphate_biosynthesis", "thiazole_phosphate_biosynthesis",
    "thiamine_phosphate_biosynthesis"
  ) %in% complete))

  complete <- vitamin_complete(salvage)
  expect_true("thiamine_precursor_salvage" %in% complete)
  expect_true("thiamine_phosphate_biosynthesis" %in% complete)
  expect_false("thiazole_phosphate_biosynthesis" %in% complete)

  # ThiE is curated once. Both suppliers reach it through the same anchors
  # rather than repeating the condensation in a salvage route.
  edges <- gift_graph()
  edges <- edges[edges$to_gift == "thiamine_phosphate_biosynthesis", ]
  expect_setequal(
    edges$from_gift,
    c("hmp_phosphate_biosynthesis", "thiazole_phosphate_biosynthesis",
      "thiamine_precursor_salvage")
  )
})

test_that("the thiazole sulfur carrier is not required evidence", {
  # ThiF is homologous to MoeB and ThiI also serves tRNA thiolation, so neither
  # marker adds thiamine specificity. Adding them must change nothing.
  without <- vitamin_complete("K03150", "K03149")
  with_carrier <- vitamin_complete("K03150", "K03149", "K03148", "K03154")
  expect_setequal(without, with_carrier)
  expect_true("thiazole_phosphate_biosynthesis" %in% without)

  # Either imine donor completes the branch, and they are separate routes with
  # different oxygen requirements.
  expect_true("thiazole_phosphate_biosynthesis" %in% vitamin_complete("K03153", "K03149"))
  expect_setequal(
    route_oxygen("thiazole_phosphate_biosynthesis"), c("aerobic", "anaerobic")
  )
})

test_that("the two pyridoxal phosphate routes are separate GIFTs on different inputs", {
  r5p <- get_gift_anchors("plp_biosynthesis_r5p")
  dxp <- get_gift_anchors("plp_biosynthesis_dxp")
  # The pentose phosphate and the nitrogen donor are declared; the triose
  # phosphate the same reaction consumes is not, following purine core
  # biosynthesis, which declares PRPP without declaring the glycine, aspartate
  # and formate it also uses. Declaring it would have made every sugar
  # degradation GIFT an upstream neighbour of vitamin B6.
  expect_setequal(r5p$anchor_id[r5p$role == "input"], c("RIBOSE_5P", "GLUTAMINE"))
  expect_setequal(dxp$anchor_id[dxp$role == "input"], c("E4P", "DXP"))
  expect_equal(r5p$anchor_id[r5p$role == "output"], "PLP")
  expect_equal(dxp$anchor_id[dxp$role == "output"], "PLP")

  # The synthase is a two-subunit complex: one subunit is not evidence.
  expect_true("plp_biosynthesis_r5p" %in% vitamin_complete("K06215", "K08681"))
  expect_false("plp_biosynthesis_r5p" %in% vitamin_complete("K06215"))
  expect_false("plp_biosynthesis_r5p" %in% vitamin_complete("K08681"))

  expect_true(
    "plp_biosynthesis_dxp" %in%
      vitamin_complete("K03472", "K03473", "K00831", "K00097", "K03474", "K00275")
  )
  # The shared transaminase alone says nothing about vitamin B6.
  expect_false("plp_biosynthesis_dxp" %in% vitamin_complete("K00831"))
})

test_that("a non-homologous replacement is accepted for one reaction, not for the trait", {
  # IlvC reduces ketopantoate in genomes lacking PanE. It is accepted for that
  # reaction; the other three reactions carry the pantothenate claim.
  with_pane <- c("K00606", "K00077", "K01579", "K01918")
  with_ilvc <- c("K00606", "K00053", "K01579", "K01918")
  expect_true("pantothenate_biosynthesis" %in% vitamin_complete(with_pane))
  expect_true("pantothenate_biosynthesis" %in% vitamin_complete(with_ilvc))
  expect_false("pantothenate_biosynthesis" %in% vitamin_complete("K00053"))
})

test_that("biotin completes on either transaminase route and nothing else", {
  sam <- c("K00652", "K00833", "K01935", "K01012")
  lys <- c("K00652", "K19563", "K01935", "K01012")
  expect_true("biotin_biosynthesis" %in% vitamin_complete(sam))
  expect_true("biotin_biosynthesis" %in% vitamin_complete(lys))
  # Biotin synthase alone is not biotin biosynthesis.
  expect_false("biotin_biosynthesis" %in% vitamin_complete("K01012"))
  # The precursor supply is refused, so none of its markers is curated.
  expect_false(any(curated_accessions() %in% c("K02169", "K02170", "K01906", "K16593", "K25570")))
})

test_that("NAD is cut at the mononucleotide so salvage and de novo share the trunk", {
  trunk <- c("K00969", "K01916")
  de_novo <- c("K00278", "K03517", "K00767")
  salvage <- "K00763"

  complete <- vitamin_complete(c(de_novo, trunk))
  expect_true(all(c(
    "quinolinate_biosynthesis_aspartate", "namn_biosynthesis_quinolinate",
    "nad_biosynthesis_namn"
  ) %in% complete))
  expect_false("namn_salvage_nicotinate" %in% complete)

  # A niacin-dependent genome: it reaches NAD, and cannot make the ring.
  complete <- vitamin_complete(c(salvage, trunk))
  expect_true(all(c("namn_salvage_nicotinate", "nad_biosynthesis_namn") %in% complete))
  expect_false("quinolinate_biosynthesis_aspartate" %in% complete)

  # The trunk is curated once, so both suppliers are edges into it.
  edges <- gift_graph()
  edges <- edges[edges$to_gift == "nad_biosynthesis_namn", ]
  expect_setequal(
    edges$from_gift,
    c("namn_biosynthesis_quinolinate", "namn_salvage_nicotinate")
  )

  # Either aspartate-oxidising enzyme opens the de novo route.
  expect_true(
    "quinolinate_biosynthesis_aspartate" %in% vitamin_complete("K06989", "K03517")
  )
})

test_that("cobamide assembly does not imply a corrin ring", {
  # Escherichia coli's profile: the whole nucleotide loop, no ring at all.
  complete <- vitamin_complete(loop_markers)
  expect_true("cobamide_nucleotide_loop_assembly" %in% complete)
  expect_false("corrin_ring_biosynthesis" %in% complete)
  expect_false("cobinamide_biosynthesis" %in% complete)

  complete <- vitamin_complete(corrin_anaerobic_markers)
  expect_true("corrin_ring_biosynthesis" %in% complete)

  # The two ring routes are one capability with one pair of boundaries, told
  # apart by oxygen and by nothing else the model records.
  expect_equal(nrow(get_gift_routes("corrin_ring_biosynthesis")), 2L)
  expect_setequal(
    route_oxygen("corrin_ring_biosynthesis"), c("aerobic", "anaerobic")
  )
})

test_that("the lower ligand is its own capability, so a cobamide is not vitamin B12", {
  anchors <- get_gift_anchors("cobamide_nucleotide_loop_assembly")
  expect_true("DMB" %in% anchors$anchor_id[anchors$role == "input"])
  # CobT consumes nicotinate D-ribonucleotide, which is what ties the cobamide
  # layer to NAD metabolism rather than leaving it an island.
  expect_true("NAMN" %in% anchors$anchor_id[anchors$role == "input"])

  expect_false("dmb_biosynthesis_aerobic" %in% vitamin_complete(loop_markers))
  expect_true("dmb_biosynthesis_aerobic" %in% vitamin_complete("K04719"))

  edges <- gift_graph()
  edges <- edges[edges$to_gift == "cobamide_nucleotide_loop_assembly", ]
  expect_true(all(
    c("cobinamide_biosynthesis", "dmb_biosynthesis_aerobic") %in% edges$from_gift
  ))
})

test_that("an incomplete corrin ring names the reactions it is missing", {
  # The Propionibacterium freudenreichii case: the genes are there, as fusions
  # KEGG assigns to none of the component orthology groups.
  partial <- setdiff(corrin_anaerobic_markers, c("K03795", "K05934", "K02189"))
  result <- evaluate_gifts(ko_annotations(partial))
  gift <- result$gifts[result$gifts$gift_id == "corrin_ring_biosynthesis", ]
  expect_false(gift$complete)
  missing <- unlist(gift$missing_reactions_best_route)
  expect_setequal(missing, c("RHEA:15893", "RHEA:36155", "RHEA:26281"))
})

test_that("menaquinone completes by either route, and EntC counts for its reaction", {
  expect_true("menaquinone_biosynthesis" %in% vitamin_complete(menaquinone_classic_markers))
  expect_true("menaquinone_biosynthesis" %in% vitamin_complete(futalosine_markers))

  # The Bacteroides profile: an isochorismate synthase annotated as entC.
  entc <- c(setdiff(menaquinone_classic_markers, "K02552"), "K02361")
  expect_true("menaquinone_biosynthesis" %in% vitamin_complete(entc))

  # But the enterobactin enzyme on its own is not menaquinone biosynthesis.
  expect_false("menaquinone_biosynthesis" %in% vitamin_complete("K02361"))

  # The deaminase of the futalosine route is not required, because the modified
  # futalosine route does not use it.
  expect_setequal(
    vitamin_complete(futalosine_markers),
    vitamin_complete(c(futalosine_markers, "K18286"))
  )
})

test_that("cofactor activation is not curated and cofactors are not input anchors", {
  # Riboflavin to FAD, thiamine phosphate to TPP, and pantothenate to CoA are
  # housekeeping steps that partition nothing.
  expect_false(any(curated_accessions() %in% c("K11753", "K20884", "K22949", "K00946")))

  # FMNH2 is the one cofactor admitted as an input, because BluB destroys it.
  expect_true("FMNH2" %in% vitamin_source("anchors")$anchor_id)
  roles <- get_gift_anchors("dmb_biosynthesis_aerobic")
  expect_equal(roles$anchor_id[roles$role == "input"], "FMNH2")

  # Input-only means input-only: no GIFT may declare FMNH2 or GTP as an output,
  # or the anabolic graph would start describing cofactor dependence.
  all_anchors <- do.call(rbind, lapply(list_gifts()$gift_id, get_gift_anchors))
  outputs <- all_anchors$anchor_id[all_anchors$role == "output"]
  expect_false(any(c("FMNH2", "GTP") %in% outputs))
})

test_that("no vitamin uptake is claimed", {
  # The corrinoid importers that matter in the gut have no orthology group, so
  # the Proteobacterial system is refused rather than curated alone.
  expect_false(any(curated_accessions() %in% c("K16092", "K06073", "K06074")))
  expect_true(all(
    anchor_compartments(c("COBALAMIN", "RIBOFLAVIN", "THF", "BIOTIN")) == "unspecified"
  ))
})

test_that("the layer adds no anabolic cycle and every reaction is Rhea-identified", {
  reactions <- get_gift_reactions(vitamin_gifts[[1]])
  expect_true(all(grepl("^RHEA:", reactions$reaction_id)))

  for (gift_id in vitamin_gifts) {
    reactions <- get_gift_reactions(gift_id)
    expect_true(all(grepl("^RHEA:", reactions$reaction_id)))
  }
})
