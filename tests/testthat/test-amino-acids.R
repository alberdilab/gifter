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

gifter_source_dir <- function() {
  packaged <- system.file("extdata", "database-source", package = "gifter")
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
  # Cysteine degradation and sulfate assimilation now supply the boundary two
  # biosynthesis GIFTs consume; the promiscuous PLP marker remains refused.
  graph <- gift_graph()
  sulfide <- graph[graph$shared_anchor == "SULFIDE", ]
  expect_setequal(
    unique(sulfide$from_gift),
    c("cysteine_degradation_sulfide", "assimilatory_sulfate_reduction")
  )
  expect_setequal(
    unique(sulfide$to_gift),
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
  expect_setequal(
    unique(cycles$named_cycle),
    c("citric_acid_cycle_oxidative", "glyoxylate_cycle")
  )
  # The edges themselves are untouched: the exclusion is about what counts as a
  # cycle, not about what counts as composition.
  graph <- gift_graph()
  expect_gt(nrow(graph[graph$from_gift == "arginine_deiminase_pathway", ]), 0L)
})

test_that("branchpoints that were deliberately left internal create no edges", {
  anchors <- read_source(gifter_source_dir(), "anchors")$anchor_id
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
  facets <- read_source(gifter_source_dir(), "anchor_facets")
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

test_that("the histidine phosphatase step accepts every family that solves it", {
  # Database 2026.25.1. RHEA:14465 is solved by at least three unrelated protein
  # families and RHEA:22828 occurs standalone and fused, which is why orthology
  # splits both across several accessions and still under-called: the phenotype
  # benchmark scored histidine_biosynthesis at recall 0.520 against strains
  # observed to grow without histidine. The point of the test is that the
  # alternatives are *alternatives* -- each family alone completes the step --
  # rather than a longer list of jointly required components.
  systems <- get_reaction_systems("RHEA:14465")
  standalone <- systems[systems$component_id == "COMP_14465_HISN_CATALYTIC", ]
  expect_true(all(c("TIGR02067.1", "NF005996.1", "NF052359.1", "NF052360.1") %in%
                    standalone$accession))

  # TIGR01261.1 is the phosphatase domain of the bifunctional HisB protein, so
  # it belongs on the bifunctional component and nowhere else. Putting it on the
  # standalone component would claim a protein the profile cannot see.
  bifunctional <- systems[systems$component_id ==
                            "COMP_14465_HISB_BIFUNCTIONAL_CATALYTIC", ]
  expect_true("TIGR01261.1" %in% bifunctional$accession)
  expect_false("TIGR01261.1" %in% standalone$accession)

  # One marker from one family is enough for the step, which is the OR the
  # component layer exists to express.
  for (marker in c("TIGR02067.1", "NF005996.1", "NF052359.1", "NF052360.1")) {
    reactions <- evaluate_reactions(
      data.frame(namespace = "NCBIFAM", accession = marker))$reactions
    expect_true(reactions$supported[reactions$reaction_id == "RHEA:14465"],
                info = marker)
  }

  # The same for the diphosphatase, including the domain-grade profile whose
  # source identifier reads hisI while its EC is the diphosphatase's.
  for (marker in c("NF001610.0", "NF001611.0", "NF001613.0", "TIGR03188.1")) {
    reactions <- evaluate_reactions(
      data.frame(namespace = "NCBIFAM", accession = marker))$reactions
    expect_true(reactions$supported[reactions$reaction_id == "RHEA:22828"],
                info = marker)
  }

  # None of them fires the cyclohydrolase, which is a different reaction that
  # the hisI naming would invite a curator to conflate with the diphosphatase.
  cyclohydrolase <- evaluate_reactions(
    data.frame(namespace = "NCBIFAM", accession = "TIGR03188.1"))$reactions
  expect_false(cyclohydrolase$supported[cyclohydrolase$reaction_id == "RHEA:20049"])
})

test_that("the serine/glycine reaction stays on one side of one directed GIFT", {
  # Database 2026.27.1. Serine hydroxymethyltransferase is reversible and its
  # Rhea master runs glycine to serine, so its forward direction was proposed as
  # a second entry into SERINE. It is refused: both GIFTs are anabolic and each
  # asserts a direction, so the loop is a claim rather than the syntactic
  # artefact the interconversion exemption covers, and the claim is false --
  # gifter's only anabolic producer of GLYCINE is the reverse of this very
  # reaction. See inst/doc/proposal-phenotype-curation-leads.md section 2.
  routes <- read_source(gifter_source_dir(), "route_reactions")
  shmt <- routes[routes$reaction_id == "RHEA:15481", ]
  expect_equal(nrow(shmt), 1L)
  expect_equal(shmt$route_id, "GLY_SHMT")
  expect_equal(shmt$orientation, "reverse")

  # The boundary that carries the refusal: GLYCINE is not an input of serine
  # biosynthesis, and serine biosynthesis enters at 3-phosphoglycerate only.
  anchors <- read_source(gifter_source_dir(), "gift_anchors")
  serine_inputs <- anchors$anchor_id[anchors$gift_id == "serine_biosynthesis" &
                                       anchors$role == "input"]
  expect_equal(serine_inputs, "PG3")
  expect_false("GLYCINE" %in% serine_inputs)

  # And the mode that carries it: the pair stays two directed GIFTs. Converting
  # glycine_biosynthesis to interconversion validates, which is why the decision
  # is recorded rather than left to the build to enforce.
  expect_equal(get_gift("glycine_biosynthesis")$mode, "anabolic")
  expect_equal(get_gift("serine_biosynthesis")$mode, "anabolic")
  graph <- gift_graph()
  pair <- function(a, b) nrow(graph[graph$from_gift == a & graph$to_gift == b, ])
  expect_gt(pair("serine_biosynthesis", "glycine_biosynthesis"), 0L)
  expect_equal(pair("glycine_biosynthesis", "serine_biosynthesis"), 0L)

  # Nothing else makes glycine anabolically, which is the reason the edge is
  # refused rather than merely inconvenient.
  glycine_sources <- sort(unique(
    graph$from_gift[graph$shared_anchor == "GLYCINE"]
  ))
  expect_setequal(glycine_sources,
                  c("glycine_biosynthesis", "sarcosine_demethylation"))
  expect_equal(get_gift("sarcosine_demethylation")$mode, "catabolic")
})

test_that("the archaeal phosphoserine transaminase is admitted, and stays ambiguous", {
  # Database 2026.27.1. K28205 is the only other orthology group KEGG assigns to
  # RHEA:14329, the step gifter's trace names in 62 of the 86 organisms observed
  # to grow without serine and called unsupported. It is narrower than the
  # curated K00831, which also carries the pyridoxal phosphate transamination,
  # so it must evidence the serine reaction and not the vitamin B6 one.
  reactions <- evaluate_reactions(
    data.frame(namespace = "KO", accession = "K28205"))$reactions
  expect_true(reactions$supported[reactions$reaction_id == "RHEA:14329"])
  expect_false(reactions$supported[reactions$reaction_id == "RHEA:16573"])

  # It completes the route on its own in place of serC, and the call it produces
  # is ambiguous, because UniProt names the characterised member a probable
  # serine--glyoxylate aminotransferase. The weakest-confidence rule is what
  # reports that honestly rather than a footnote nobody reads.
  archaeal <- evaluate_gifts(ko_annotations(c("K00058", "K28205", "K01079")))$gifts
  archaeal <- archaeal[archaeal$gift_id == "serine_biosynthesis", ]
  expect_true(archaeal$complete)
  expect_equal(archaeal$evidence_confidence, "ambiguous")

  canonical <- evaluate_gifts(ko_annotations(c("K00058", "K00831", "K01079")))$gifts
  canonical <- canonical[canonical$gift_id == "serine_biosynthesis", ]
  expect_true(canonical$complete)
  expect_equal(canonical$evidence_confidence, "curated")

  # The refusals taken in the same pass: the sigma-factor phosphatases carry
  # EC 3.1.3.3 for a phosphoserine residue, not the free metabolite, and are
  # admitted nowhere in the database.
  for (accession in c("K05518", "K07315", "K15781", "K00830", "K00049")) {
    result <- evaluate_gifts(ko_annotations(accession))
    expect_equal(nrow(result$evidence[result$evidence$accession == accession, ]),
                 0L, info = accession)
  }
})
