test_that("markers normalize and map to components", {
  mapped <- map_markers(c(gene_a = "ko:K01939", gene_b = "K99999"))

  expect_equal(mapped$accession, c("K01939", "K99999"))
  expect_equal(mapped$namespace, c("KO", "KO"))
  expect_equal(mapped$matched, c(TRUE, FALSE))
  expect_equal(mapped$component_id[[1]], "COMP_15753_CATALYTIC")
})

test_that("empty marker sets produce auditable incomplete calls", {
  result <- evaluate_gifts(character())
  expect_false(any(result$gifts$complete))
  # Every type reports what is missing, in the vocabulary of its own model.
  expect_true(all(result$gifts$minimum_missing_requirements > 0L))
  metabolic <- result$gifts[result$gifts$gift_type == "metabolic", ]
  expect_true(all(metabolic$minimum_missing_reactions > 0L))
  # Reactions belong to the metabolic model, so the route columns of a
  # non-metabolic call are empty rather than zero.
  structural <- result$gifts[result$gifts$gift_type == "structural", ]
  expect_true(all(is.na(structural$minimum_missing_reactions)))
  expect_equal(nrow(result$observed_markers), 0L)
})

test_that("single-component enzymes require one supported component", {
  result <- evaluate_reactions("K01939")
  reaction <- result$reactions[result$reactions$reaction_id == "RHEA:15753", ]

  expect_true(reaction$supported)
  expect_equal(reaction$number_of_complete_systems, 1L)
  expect_equal(reaction$minimum_missing_components, 0L)
})

test_that("multi-component systems use component AND logic", {
  incomplete <- evaluate_reactions(c("K23269", "K23264"))
  incomplete_reaction <- incomplete$reactions[
    incomplete$reactions$reaction_id == "RHEA:17129", ]
  expect_false(incomplete_reaction$supported)

  complete <- evaluate_reactions(c("K23269", "K23264", "K23265"))
  complete_reaction <- complete$reactions[complete$reactions$reaction_id == "RHEA:17129", ]
  trimer <- complete$systems[complete$systems$system_id == "SYS_17129_TRIMER", ]
  expect_true(complete_reaction$supported)
  expect_true(trimer$supported)
  expect_equal(trimer$required_components, 3L)
})

test_that("alternative enzyme systems use system OR logic", {
  result <- evaluate_reactions(c("K01952", "K23269", "K23264", "K23265"))
  reaction <- result$reactions[result$reactions$reaction_id == "RHEA:17129", ]

  expect_true(reaction$supported)
  expect_equal(reaction$number_of_complete_systems, 2L)
})

test_that("alternative markers use component OR logic", {
  result <- evaluate_reactions("K11787")
  supported <- result$reactions$rhea_master[result$reactions$supported]

  expect_true(all(c("RHEA:17453", "RHEA:15053", "RHEA:23032") %in% supported))
})

test_that("M00051 multifunctional markers support each encoded reaction", {
  result <- evaluate_reactions(c("K11540", "K13421"))
  supported <- result$reactions$rhea_master[result$reactions$supported]

  expect_true(all(c(
    "RHEA:18633", "RHEA:20013", "RHEA:24296", "RHEA:10380", "RHEA:11596"
  ) %in% supported))
})

test_that("M00051 multi-subunit systems use component AND logic", {
  incomplete <- evaluate_reactions(c("K01955", "K17828"))
  expect_false(incomplete$reactions$supported[
    incomplete$reactions$reaction_id == "RHEA:18633"
  ])
  expect_false(incomplete$reactions$supported[
    incomplete$reactions$reaction_id == "RHEA:13513"
  ])

  complete <- evaluate_reactions(c("K01955", "K01956", "K17828", "K02823"))
  expect_true(complete$reactions$supported[
    complete$reactions$reaction_id == "RHEA:18633"
  ])
  expect_true(complete$reactions$supported[
    complete$reactions$reaction_id == "RHEA:13513"
  ])
})

test_that("the aspartate carbamoyltransferase catalytic subunit is sufficient", {
  # Class C enzymes are catalytic trimers, so requiring the allosteric PyrI
  # subunit would call the reaction absent in most bacteria that encode it.
  catalytic <- evaluate_reactions("K00609")
  expect_true(catalytic$reactions$supported[
    catalytic$reactions$reaction_id == "RHEA:20013"
  ])

  regulatory <- evaluate_reactions("K00610")
  expect_false(any(regulatory$reactions$supported))
  expect_false("K00610" %in% regulatory$marker_vocabulary$accession)
})

test_that("NAD-dependent dihydroorotate oxidation requires both class 1B subunits", {
  catalytic_only <- evaluate_reactions("K17828")
  expect_false(catalytic_only$reactions$supported[
    catalytic_only$reactions$reaction_id == "RHEA:13513"
  ])
  expect_equal(
    catalytic_only$reactions$minimum_missing_components[
      catalytic_only$reactions$reaction_id == "RHEA:13513"
    ],
    1L
  )

  holoenzyme <- evaluate_reactions(c("K17828", "K02823"))
  expect_true(holoenzyme$reactions$supported[
    holoenzyme$reactions$reaction_id == "RHEA:13513"
  ])

  # The other two dihydroorotate chemistries stay single-subunit systems.
  for (marker in c("K00226", "K00254")) {
    single <- evaluate_reactions(marker)
    expect_true(any(single$reactions$supported))
  }
})

test_that("a catalytic-trimer pyrimidine genome completes without pyrI", {
  markers <- complex_pyrimidine_markers()
  expect_false("K00610" %in% markers)

  result <- evaluate_gifts(ko_annotations(markers))
  gift <- result$gifts[result$gifts$gift_id == "pyrimidine_core_biosynthesis", ]
  reactions <- result$reactions

  expect_true(gift$complete)
  expect_true("KO:K00609" %in% gift$supporting_markers[[1]])
  expect_equal(
    reactions$best_system[reactions$reaction_id == "RHEA:20013"],
    "SYS_20013_CATALYTIC"
  )
})

test_that("the direct PRPP to IMP route completes", {
  result <- evaluate_gifts(ko_annotations(direct_purine_markers()))
  gift <- result$gifts[result$gifts$gift_id == "purine_core_biosynthesis", ]

  expect_true(gift$complete)
  expect_equal(gift$best_route, "PCR_FOLATE_DIRECT_FOLATE")
  expect_equal(gift$minimum_missing_reactions, 0L)
  expect_equal(gift$route_score, 1)
})

test_that("the formate and two-step PRPP to IMP route completes", {
  result <- evaluate_gifts(ko_annotations(alternative_purine_markers()))
  gift <- result$gifts[result$gifts$gift_id == "purine_core_biosynthesis", ]

  expect_true(gift$complete)
  expect_equal(gift$best_route, "PCR_FORMATE_TWOSTEP_FORMATE")
  expect_equal(gift$number_of_complete_routes, 1L)
})

test_that("incomplete GIFTs report the closest route by missing reactions", {
  markers <- setdiff(direct_purine_markers(), "K01933")
  result <- evaluate_gifts(ko_annotations(markers))
  gift <- result$gifts[result$gifts$gift_id == "purine_core_biosynthesis", ]

  expect_false(gift$complete)
  expect_equal(gift$minimum_missing_reactions, 1L)
  expect_equal(gift$missing_reactions_best_route[[1]], "RHEA:23032")
})

test_that("IMP to AMP stops at AMP and calls both required reactions", {
  result <- evaluate_gifts(ko_annotations(c("K01939", "K01756")))
  gift <- result$gifts[result$gifts$gift_id == "adenylate_biosynthesis", ]

  expect_true(gift$complete)
  expect_equal(gift$number_of_complete_routes, 1L)
  expect_equal(
    get_gift_reactions("adenylate_biosynthesis")$rhea_master,
    c("RHEA:15753", "RHEA:16853")
  )
})

test_that("missing IMP to AMP evidence is reaction-interpretable", {
  result <- evaluate_gifts("K01756")
  gift <- result$gifts[result$gifts$gift_id == "adenylate_biosynthesis", ]

  expect_false(gift$complete)
  expect_equal(gift$minimum_missing_reactions, 1L)
  expect_equal(gift$missing_reactions_best_route[[1]], "RHEA:15753")
})

test_that("the M00050-derived guanylate branch stops at GMP and completes", {
  result <- evaluate_gifts(ko_annotations(c("K00088", "K01951")))
  gift <- result$gifts[result$gifts$gift_id == "guanylate_biosynthesis", ]

  expect_true(gift$complete)
  expect_equal(gift$best_route, "GMP_XMP")
  expect_equal(gift$minimum_missing_reactions, 0L)
  expect_equal(
    get_gift_reactions("guanylate_biosynthesis")$rhea_master,
    c("RHEA:11708", "RHEA:11680")
  )
})

test_that("the M00052-derived cytidylate-forming capability completes", {
  result <- evaluate_gifts(ko_annotations("K01937"))
  gift <- result$gifts[result$gifts$gift_id == "cytidylate_biosynthesis", ]

  expect_true(gift$complete)
  expect_equal(gift$best_route, "CTP_GLUTAMINE")
  expect_equal(gift$minimum_missing_reactions, 0L)
  expect_equal(
    get_gift_reactions("cytidylate_biosynthesis")$rhea_master,
    "RHEA:26426"
  )
})

test_that("new nucleotide branches report missing reactions deterministically", {
  result <- evaluate_gifts("K00088")

  guanylate <- result$gifts[result$gifts$gift_id == "guanylate_biosynthesis", ]
  cytidylate <- result$gifts[result$gifts$gift_id == "cytidylate_biosynthesis", ]
  expect_false(guanylate$complete)
  expect_equal(guanylate$missing_reactions_best_route[[1]], "RHEA:11680")
  expect_false(cytidylate$complete)
  expect_equal(cytidylate$missing_reactions_best_route[[1]], "RHEA:26426")
})

test_that("new nucleotide GIFTs retain route-to-gene evidence", {
  result <- evaluate_gifts(ko_annotations(c("K00088", "K01951", "K01937")))
  guanylate <- trace_gift(result, "guanylate_biosynthesis")
  cytidylate <- trace_gift(result, "cytidylate_biosynthesis")

  expect_equal(guanylate$rhea_master, c("RHEA:11708", "RHEA:11680"))
  expect_true(all(guanylate$reaction_supported))
  expect_true(all(!is.na(guanylate$gene_id)))
  expect_equal(cytidylate$rhea_master, "RHEA:26426")
  expect_true(cytidylate$reaction_supported)
  expect_false(is.na(cytidylate$gene_id))
})

test_that("the M00051 multifunctional quinone route completes", {
  result <- evaluate_gifts(ko_annotations(multifunctional_pyrimidine_markers()))
  gift <- result$gifts[result$gifts$gift_id == "pyrimidine_core_biosynthesis", ]

  expect_true(gift$complete)
  expect_equal(gift$best_route, "PYR_DHODH_QUINONE")
  expect_equal(gift$number_of_complete_routes, 1L)
  expect_equal(gift$minimum_missing_reactions, 0L)
})

test_that("the M00051 multi-subunit fumarate route completes", {
  result <- evaluate_gifts(ko_annotations(complex_pyrimidine_markers()))
  gift <- result$gifts[result$gifts$gift_id == "pyrimidine_core_biosynthesis", ]

  expect_true(gift$complete)
  expect_equal(gift$best_route, "PYR_DHODH_FUMARATE")
  expect_equal(gift$number_of_complete_routes, 1L)
})

test_that("M00051 routes retain curated chemistry and direction", {
  reactions <- get_gift_reactions("pyrimidine_core_biosynthesis")
  expect_equal(
    sort(unique(reactions$rhea_master)),
    sort(c(
      "RHEA:18633", "RHEA:20013", "RHEA:24296", "RHEA:30059",
      "RHEA:30187", "RHEA:13513", "RHEA:10380", "RHEA:11596"
    ))
  )
  expect_true(all(reactions$orientation[
    reactions$rhea_master %in% c("RHEA:24296", "RHEA:10380")
  ] == "reverse"))
  expect_true(all(reactions$orientation[
    !reactions$rhea_master %in% c("RHEA:24296", "RHEA:10380")
  ] == "forward"))
})

test_that("trace_gift retains route-to-gene evidence", {
  result <- evaluate_gifts(ko_annotations(direct_purine_markers(include_amp = TRUE)))
  trace <- trace_gift(result, "adenylate_biosynthesis")

  expect_equal(unique(trace$route_id), "AMP_ADENYLOSUCCINATE")
  expect_equal(trace$rhea_master, c("RHEA:15753", "RHEA:16853"))
  expect_true(all(trace$reaction_supported))
  expect_true(all(trace$component_supported))
  expect_true(all(!is.na(trace$gene_id)))
})

test_that("CAZy families and subfamilies are recognised without an explicit namespace", {
  expect_equal(
    giftr:::.infer_marker_namespace(c("GH5", "GH5_4", "PL1", "CE8", "AA9", "CBM6")),
    rep("CAZY", 6L)
  )
  # A subfamily is its own accession. Recognising it must not silently promote
  # it to the parent family, whose other activities it is not evidence for.
  expect_equal(
    giftr:::.normalize_marker_accession("CAZY", "gh5_4"), "GH5_4"
  )
  expect_equal(giftr:::.infer_marker_namespace("K01945"), "KO")
  expect_true(is.na(giftr:::.infer_marker_namespace("GHX")))

  mapped <- map_markers(c("GH5_4", "K00764"))
  expect_equal(mapped$namespace[mapped$accession == "GH5_4"], "CAZY")
  expect_false(any(mapped$matched[mapped$accession == "GH5_4"]))
})

test_that("a call reports the weakest confidence behind it", {
  expect_equal(
    giftr:::.weakest_confidence(c("curated", "ambiguous", "high-confidence")),
    "ambiguous"
  )
  expect_equal(giftr:::.weakest_confidence(c("curated", "curated")), "curated")
  expect_true(is.na(giftr:::.weakest_confidence(character())))
  # An unrecognised term is never promoted above a known one.
  expect_equal(giftr:::.weakest_confidence(c("curated", "invented")), "invented")

  result <- evaluate_gifts(ko_annotations(direct_purine_markers()))
  purine <- result$gifts[result$gifts$gift_id == "purine_core_biosynthesis", ]
  expect_true(purine$complete)
  expect_equal(purine$evidence_confidence, "curated")

  # Nothing observed means nothing to be confident about.
  empty <- evaluate_gifts(ko_annotations("K00000"))
  expect_true(all(is.na(empty$gifts$evidence_confidence)))
})
