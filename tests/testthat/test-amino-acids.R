# The amino acid layer. What separates it from earlier layers is that most of
# its capabilities are reached from other capabilities rather than from the
# environment, so the tests here are mostly about boundaries: which molecule is
# an anchor, which is deliberately internal, and which marker is allowed to
# license which claim. See inst/doc/proposal-amino-acid-metabolism.md.

amino_acid_gifts <- c(
  "glutamine_biosynthesis", "alanine_biosynthesis", "aspartate_biosynthesis",
  "asparagine_biosynthesis", "dap_biosynthesis", "lysine_biosynthesis_dap",
  "oxoisovalerate_biosynthesis", "valine_biosynthesis", "leucine_biosynthesis",
  "oxobutanoate_biosynthesis_citramalate", "isoleucine_biosynthesis",
  "phenylalanine_biosynthesis", "tyrosine_biosynthesis",
  "tryptophan_biosynthesis", "histidine_biosynthesis", "proline_biosynthesis",
  "ornithine_biosynthesis", "arginine_biosynthesis"
)

amino_acid_catabolism <- c(
  "arginine_deiminase_pathway", "histidine_degradation_glutamate",
  "threonine_deamination", "serine_deamination",
  "glutamate_decarboxylation_gaba", "tryptophan_degradation_indole",
  "methionine_degradation_methanethiol", "cysteine_degradation_sulfide",
  "glycine_reduction_stickland", "proline_reduction_stickland"
)

giftr_source_dir <- function() {
  packaged <- system.file("extdata", "database-source", package = "giftr")
  if (nzchar(packaged)) packaged else file.path("inst", "extdata", "database-source")
}

complete_gifts <- function(...) {
  result <- evaluate_gifts(ko_annotations(c(...)))
  result$gifts$gift_id[result$gifts$complete]
}

dap_head <- c("K01714", "K00215")

test_that("the layer is curated as directed metabolic capabilities", {
  gifts <- list_gifts()
  layer <- gifts[gifts$gift_id %in% c(amino_acid_gifts, amino_acid_catabolism), ]
  expect_equal(nrow(layer), 28L)
  expect_true(all(layer$gift_type == "metabolic"))
  expect_setequal(
    layer$mode[layer$gift_id %in% amino_acid_gifts], "anabolic"
  )
  expect_setequal(
    layer$mode[layer$gift_id %in% amino_acid_catabolism], "catabolic"
  )
})

test_that("the four diaminopimelate routes are alternatives, not requirements", {
  routes <- get_gift_routes("dap_biosynthesis")
  expect_equal(nrow(routes), 4L)

  succinyl <- c(dap_head, "K00674", "K00821", "K01439", "K01778")
  acetyl <- c(dap_head, "K05822", "K00841", "K05823", "K01778")
  dehydrogenase <- c(dap_head, "K03340")
  aminotransferase <- c(dap_head, "K10206", "K01778")
  for (markers in list(succinyl, acetyl, dehydrogenase, aminotransferase)) {
    expect_true("dap_biosynthesis" %in% complete_gifts(markers))
  }
  # The shared head is not a route. Two steps of six is the closest any single
  # route gets, and none of them is complete.
  expect_false("dap_biosynthesis" %in% complete_gifts(dap_head))
  # The dehydrogenase route needs no epimerase, which is the whole point of it.
  expect_false("K01778" %in% dehydrogenase)
})

test_that("lysine is separable from the peptidoglycan precursor that supplies it", {
  expect_false("lysine_biosynthesis_dap" %in% complete_gifts(dap_head, "K03340"))
  expect_true("lysine_biosynthesis_dap" %in% complete_gifts("K01586"))
  # And the two compose only through the declared anchor.
  graph <- gift_graph()
  edge <- graph[graph$from_gift == "dap_biosynthesis" &
                  graph$to_gift == "lysine_biosynthesis_dap", ]
  expect_equal(nrow(edge), 1L)
  expect_equal(edge$shared_anchor, "MESO_DAP")
})

test_that("one branched-chain marker set licenses three amino acids, and the oxo acid separates them", {
  shared <- c("K01652", "K00053", "K01687", "K00826")
  complete <- complete_gifts(shared)
  # Valine and isoleucine share every enzyme; their reactions differ because
  # their substrates do, so both calls are correct and neither is evidence for
  # the other's precursor supply.
  expect_true(all(
    c("oxoisovalerate_biosynthesis", "valine_biosynthesis",
      "isoleucine_biosynthesis") %in% complete
  ))
  # Leucine needs its own chain-extension enzymes on top of the shared set.
  expect_false("leucine_biosynthesis" %in% complete)
  expect_true("leucine_biosynthesis" %in% complete_gifts(
    shared, "K01649", "K01703", "K01704", "K00052"
  ))
  # What the shared set does not supply is 2-oxobutanoate. Without a supplier,
  # the isoleucine capability has no upstream neighbour in the graph.
  graph <- gift_graph()
  suppliers <- graph$from_gift[graph$to_gift == "isoleucine_biosynthesis"]
  expect_setequal(
    suppliers,
    c("threonine_deamination", "oxobutanoate_biosynthesis_citramalate",
      "methionine_degradation_methanethiol")
  )
  expect_false("threonine_deamination" %in% complete)
})

test_that("threonine reaches isoleucine across modes, through one curated deamination", {
  graph <- gift_graph()
  expect_equal(
    nrow(graph[graph$from_gift == "threonine_biosynthesis" &
                 graph$to_gift == "threonine_deamination", ]), 1L
  )
  # The reaction is curated once. If it were duplicated into isoleucine
  # biosynthesis the chain would disappear and the two GIFTs would share nothing.
  ile <- get_gift_reactions("isoleucine_biosynthesis")
  expect_false("RHEA:22108" %in% ile$reaction_id)
  expect_equal(
    get_gift_reactions("threonine_deamination")$reaction_id, "RHEA:22108"
  )
  # No direct edge: threonine and isoleucine share no declared anchor.
  expect_equal(
    nrow(graph[graph$from_gift == "threonine_biosynthesis" &
                 graph$to_gift == "isoleucine_biosynthesis", ]), 0L
  )
})

test_that("the aromatic transamination is widened but the aryl skeleton still decides", {
  # The widened marker set is what makes the trait callable at the prevalence
  # the chemistry has; it is also shared with aspartate biosynthesis, which is
  # true of the enzyme and does not equate the traits.
  expect_true("aspartate_biosynthesis" %in% complete_gifts("K00812"))
  expect_false("phenylalanine_biosynthesis" %in% complete_gifts("K00812"))
  expect_true(
    "phenylalanine_biosynthesis" %in% complete_gifts("K04092", "K01713", "K00812")
  )
  # And the transaminase KEGG requires is not the only one accepted.
  expect_true(
    "tyrosine_biosynthesis" %in% complete_gifts("K04092", "K04517", "K00826")
  )
  expect_true(
    "tyrosine_biosynthesis" %in% complete_gifts("K04092", "K04517", "K00832")
  )
})

test_that("sulfide from cysteine is evidenced by dedicated desulfidases only", {
  # K01760 is curated as evidence for cysteine biosynthesis through
  # transsulfuration. Accepting it here would make every transsulfuration
  # genome a sulfide producer, which is the failure invariant 16 describes.
  expect_false("cysteine_degradation_sulfide" %in% complete_gifts("K01760"))
  expect_true("cysteine_degradation_sulfide" %in% complete_gifts("K20021"))
  # The product closes a boundary two biosynthesis GIFTs already consumed.
  graph <- gift_graph()
  sulfide <- graph[graph$shared_anchor == "SULFIDE", ]
  expect_setequal(sulfide$from_gift, "cysteine_degradation_sulfide")
  expect_setequal(
    sulfide$to_gift,
    c("cysteine_biosynthesis_sulfide", "methionine_biosynthesis_sulfhydrylation")
  )
})

test_that("the Stickland reductases require their whole complex", {
  glycine <- c("K10670", "K10671", "K10672", "K21576", "K21577")
  expect_true("glycine_reduction_stickland" %in% complete_gifts(glycine))
  for (dropped in glycine) {
    expect_false(
      "glycine_reduction_stickland" %in% complete_gifts(setdiff(glycine, dropped))
    )
  }
  # Proline reduction needs the racemase as well as the reductase, because the
  # reductase is specific for the D isomer.
  expect_false("proline_reduction_stickland" %in% complete_gifts("K10793", "K10794"))
  expect_true(
    "proline_reduction_stickland" %in% complete_gifts("K10793", "K10794", "K01777")
  )
})

test_that("cross-mode cycles are the expected shape and stay out of one mode", {
  graph <- gift_graph()
  pair <- function(a, b) nrow(graph[graph$from_gift == a & graph$to_gift == b, ])
  # Arginine: biosynthesis makes it, the deiminase pathway takes it apart and
  # returns the ornithine. Both directions exist and the modes differ.
  expect_gt(pair("arginine_biosynthesis", "arginine_deiminase_pathway"), 0L)
  expect_gt(pair("arginine_deiminase_pathway", "arginine_biosynthesis"), 0L)
  expect_equal(get_gift("arginine_biosynthesis")$mode, "anabolic")
  expect_equal(get_gift("arginine_deiminase_pathway")$mode, "catabolic")
  # Proline is the same shape through the Stickland reductase.
  expect_gt(pair("proline_biosynthesis", "proline_reduction_stickland"), 0L)
  # Glutamine synthetase appears in two GIFTs, and the pair does not cycle:
  # the glutamine of the GS-GOGAT route is internal to ammonium assimilation.
  expect_true(
    "RHEA:16169" %in% get_gift_reactions("glutamine_biosynthesis")$reaction_id
  )
  expect_true(
    "RHEA:16169" %in% get_gift_reactions("ammonium_assimilation")$reaction_id
  )
  expect_equal(pair("glutamine_biosynthesis", "ammonium_assimilation"), 0L)
})

test_that("a biosynthesis/degradation pair is an edge pair, not a metabolic cycle", {
  # The layer curates both directions for arginine, proline, cysteine and
  # threonine, so the graph closes rings that alternate anabolic and catabolic
  # members. Those rings say that two capabilities exist, not that metabolism
  # runs round, and gift_cycles() excludes them for the same reason the
  # acyclicity check runs per mode. Without the exclusion they outnumber the
  # citric acid cycle by more than thirty to one.
  cycles <- gift_cycles()
  members <- split(cycles$gift_id, cycles$cycle_id)
  expect_false(any(vapply(
    members,
    function(ids) any(c("arginine_deiminase_pathway", "threonine_deamination",
                        "cysteine_degradation_sulfide") %in% ids),
    logical(1)
  )))
  expect_setequal(unique(cycles$named_cycle), "citric_acid_cycle_oxidative")
  # The edges themselves are untouched: the exclusion is about what counts as a
  # cycle, not about what counts as composition.
  graph <- gift_graph()
  expect_gt(nrow(graph[graph$from_gift == "arginine_deiminase_pathway", ]), 0L)
})

test_that("branchpoints that were deliberately left internal create no edges", {
  anchors <- read_source(giftr_source_dir(), "anchors")$anchor_id
  # Citrulline and carbamoyl phosphate are shared by arginine biosynthesis and
  # the deiminase pathway; prephenate, AICAR and the indole-3-glycerol phosphate
  # of tryptophan synthase are internal to one route each. None is a boundary.
  for (internal in c("CITRULLINE", "CARBAMOYL_PHOSPHATE", "PREPHENATE",
                     "AICAR", "INDOLE_3_GLYCEROL_PHOSPHATE")) {
    expect_false(internal %in% anchors)
  }
  # Anthranilate is the sharper case: the aromatic degradation layer declares it
  # as a boundary of its own, and tryptophan biosynthesis passes through the
  # same molecule internally. Composition is derived from declarations, so the
  # existing anchor must not connect the biosynthetic route to anything.
  expect_true("ANTHRANILATE" %in% anchors)
  graph <- gift_graph()
  expect_equal(
    nrow(graph[graph$shared_anchor == "ANTHRANILATE" &
                 (graph$from_gift == "tryptophan_biosynthesis" |
                    graph$to_gift == "tryptophan_biosynthesis"), ]), 0L
  )
  # The two GIFTs that pass through citrulline share only the amino acids.
  graph <- gift_graph()
  shared <- graph$shared_anchor[
    (graph$from_gift == "arginine_biosynthesis" &
       graph$to_gift == "arginine_deiminase_pathway") |
      (graph$from_gift == "arginine_deiminase_pathway" &
         graph$to_gift == "arginine_biosynthesis")
  ]
  expect_setequal(shared, c("ARGININE", "ORNITHINE"))
})

test_that("the layer supplies the boundaries other GIFTs already consumed", {
  graph <- gift_graph()
  supplier <- function(anchor) sort(unique(graph$from_gift[graph$shared_anchor == anchor]))
  expect_equal(supplier("OXOISOVALERATE"), "oxoisovalerate_biosynthesis")
  expect_true("pantothenate_biosynthesis" %in%
                graph$to_gift[graph$shared_anchor == "OXOISOVALERATE"])
  expect_equal(supplier("ASPARTATE"), "aspartate_biosynthesis")
  expect_true(all(
    c("aspartate_semialdehyde_biosynthesis", "pantothenate_biosynthesis",
      "quinolinate_biosynthesis_aspartate") %in%
      graph$to_gift[graph$shared_anchor == "ASPARTATE"]
  ))
  expect_equal(supplier("GLUTAMINE"), "glutamine_biosynthesis")
  expect_true(all(
    c("pyrimidine_core_biosynthesis", "plp_biosynthesis_r5p",
      "tryptophan_biosynthesis", "histidine_biosynthesis") %in%
      graph$to_gift[graph$shared_anchor == "GLUTAMINE"]
  ))
})

test_that("amino acid anchors are biomass building blocks and 2-oxo acids are not", {
  facets <- read_source(giftr_source_dir(), "anchor_facets")
  essential <- facets$anchor_id[
    facets$facet == "biomass_essential" & facets$value == "yes"
  ]
  expect_true(all(
    c("ALANINE", "ASPARAGINE", "LYSINE", "VALINE", "LEUCINE", "ISOLEUCINE",
      "PHENYLALANINE", "TYROSINE", "HISTIDINE", "PROLINE", "ARGININE",
      "MESO_DAP") %in% essential
  ))
  expect_false(any(
    c("OXOISOVALERATE", "OXOBUTANOATE", "GABA", "INDOLE", "METHANETHIOL",
      "ACETYL_PHOSPHATE", "AMINOPENTANOATE", "ORNITHINE") %in% essential
  ))
})

test_that("evidence traces from a call back to the markers that made it", {
  markers <- c("K01714", "K00215", "K03340")
  result <- evaluate_gifts(ko_annotations(markers))
  trace <- trace_gift(result, "dap_biosynthesis")
  supported <- trace[trace$route_complete, ]
  expect_setequal(
    unique(supported$reaction_id),
    c("RHEA:34171", "RHEA:35331", "RHEA:13561")
  )
  expect_setequal(unique(supported$accession), markers)
  expect_true(all(grepl("^gene_", supported$gene_id)))
})
