curation_gift_call <- function(gift_id, markers) {
  result <- evaluate_gifts(ko_annotations(markers))
  result$gifts[result$gifts$gift_id == gift_id, ]
}

test_that("ectoine biosynthesis is the complete EctABC tail from ASA", {
  gift <- curation_gift_call(
    "ectoine_biosynthesis", c("K00836", "K06718", "K06720")
  )
  expect_true(gift$complete)
  expect_equal(gift$best_route, "ECT_ABC")
  expect_equal(
    get_gift_reactions("ectoine_biosynthesis")$rhea_master,
    c("RHEA:11160", "RHEA:16901", "RHEA:17281")
  )
  expect_equal(
    get_gift_reactions("ectoine_biosynthesis")$orientation,
    c("reverse", "forward", "forward")
  )

  for (missing in c("K00836", "K06718", "K06720")) {
    expect_false(curation_gift_call(
      "ectoine_biosynthesis",
      setdiff(c("K00836", "K06718", "K06720"), missing)
    )$complete)
  }
  partial <- curation_gift_call(
    "ectoine_biosynthesis", c("K00836", "K06718")
  )
  expect_equal(partial$missing_reactions_best_route[[1]], "RHEA:17281")
  expect_equal(
    get_gift_pathways("ectoine_biosynthesis")$relation,
    c("subset_of", "subset_of")
  )
})

test_that("heme b alternatives are separate complete minimal routes", {
  alternatives <- list(
    HEME_PROTO_HEMF_HEMY = c("K01599", "K00228", "K00231", "K01772"),
    HEME_PROTO_HEMF_HEMG = c("K01599", "K00228", "K00230", "K01772"),
    HEME_PROTO_HEMF_HEMJ = c("K01599", "K00228", "K08973", "K01772"),
    HEME_PROTO_HEMN_HEMY = c("K01599", "K02495", "K00231", "K01772"),
    HEME_PROTO_HEMN_HEMG = c("K01599", "K02495", "K00230", "K01772"),
    HEME_PROTO_HEMN_HEMJ = c("K01599", "K02495", "K08973", "K01772"),
    HEME_COPRO = c("K01599", "K00231", "K01772", "K00435")
  )

  expect_equal(nrow(get_gift_routes("heme_b_biosynthesis")), 7L)
  for (route_id in names(alternatives)) {
    gift <- curation_gift_call("heme_b_biosynthesis", alternatives[[route_id]])
    expect_true(gift$complete, info = route_id)
    expect_equal(gift$best_route, route_id, info = route_id)
  }

  missing_common_step <- curation_gift_call(
    "heme_b_biosynthesis", c("K00228", "K00231", "K01772")
  )
  expect_false(missing_common_step$complete)
  expect_equal(
    missing_common_step$missing_reactions_best_route[[1]], "RHEA:19865"
  )
})

test_that("enterobactin is split at a reusable 2,3-DHB branchpoint", {
  head <- evaluate_gifts(ko_annotations(c("K02361", "K01252", "K00216")))
  expect_true(head$gifts$complete[
    head$gifts$gift_id == "dihydroxybenzoate_biosynthesis"
  ])
  expect_false(head$gifts$complete[
    head$gifts$gift_id == "enterobactin_biosynthesis"
  ])

  assembly_markers <- c("K01252", "K02362", "K02363", "K02364")
  assembled <- evaluate_gifts(ko_annotations(assembly_markers))
  expect_true(assembled$gifts$complete[
    assembled$gifts$gift_id == "enterobactin_biosynthesis"
  ])
  for (missing in assembly_markers) {
    expect_false(curation_gift_call(
      "enterobactin_biosynthesis", setdiff(assembly_markers, missing)
    )$complete, info = missing)
  }

  trace <- trace_gift(assembled, "enterobactin_biosynthesis")
  expect_setequal(trace$component_id, c(
    "COMP_30571_ENTB", "COMP_30571_ENTD", "COMP_30571_ENTE", "COMP_30571_ENTF"
  ))
  expect_setequal(trace$accession, assembly_markers)

  edges <- gift_graph()
  expect_true(any(
    edges$from_gift == "dihydroxybenzoate_biosynthesis" &
      edges$to_gift == "enterobactin_biosynthesis" &
      edges$shared_anchor == "DIHYDROXYBENZOATE_2_3"
  ))
  expect_true(any(
    edges$from_gift == "chorismate_biosynthesis" &
      edges$to_gift == "dihydroxybenzoate_biosynthesis" &
      edges$shared_anchor == "CHORISMATE"
  ))
})

test_that("choline oxidation admits four routes and composes at betaine", {
  alternatives <- list(
    BETAINE_BETA = c("K00108", "K00130"),
    BETAINE_GBS = c("K11440", "K00130"),
    BETAINE_CMO = c("K00499", "K00130"),
    BETAINE_CODA = "K17755"
  )
  for (route_id in names(alternatives)) {
    gift <- curation_gift_call("choline_to_betaine", alternatives[[route_id]])
    expect_true(gift$complete, info = route_id)
    expect_equal(gift$best_route, route_id, info = route_id)
  }

  # Upstream choline specificity cannot rehabilitate broad ALDH7A1 evidence.
  expect_false(curation_gift_call(
    "choline_to_betaine", c("K00108", "K14085")
  )$complete)
  expect_false(map_markers(ko_annotations("K14085"))$matched)

  edges <- gift_graph()
  expect_true(any(
    edges$from_gift == "choline_to_betaine" &
      edges$to_gift == "betaine_demethylation" &
      edges$shared_anchor == "BETAINE"
  ))
})

test_that("methylglyoxal detoxification requires both glyoxalases", {
  complete <- evaluate_gifts(ko_annotations(c("K01759", "K01069")))
  gift <- complete$defense$gifts[
    complete$defense$gifts$gift_id == "methylglyoxal_detoxification",
  ]
  expect_true(gift$complete)
  expect_equal(gift$best_mechanism, "MECH_MG_GLYOXALASE")

  for (marker in c("K01759", "K01069")) {
    gift <- evaluate_gifts(ko_annotations(marker))$defense$gifts
    gift <- gift[gift$gift_id == "methylglyoxal_detoxification", ]
    expect_false(gift$complete)
    expect_equal(gift$minimum_missing_functions, 1L)
  }
  expect_false("K14085" %in%
    get_gift_machinery("methylglyoxal_detoxification")$accession)
})

test_that("complete superoxide detoxification requires peroxide removal", {
  for (peroxide in list("K03781", "K03782", "K07217", c("K03386", "K03387"))) {
    result <- evaluate_gifts(ko_annotations(c("K04564", peroxide)))
    expect_true(result$defense$gifts$complete[
      result$defense$gifts$gift_id == "superoxide_detoxification"
    ])
  }
  expect_true(curation_gift_call(
    "superoxide_detoxification", c("K04565", "K03781")
  )$complete)

  sod_only <- evaluate_gifts(ko_annotations("K04564"))
  gift <- sod_only$defense$gifts[
    sod_only$defense$gifts$gift_id == "superoxide_detoxification",
  ]
  expect_false(gift$complete)
  expect_equal(gift$missing_functions_best_mechanism[[1]], "DF_PEROXIDE_REMOVAL")

  half_ahpcf <- evaluate_gifts(ko_annotations(c("K04564", "K03386")))
  system <- half_ahpcf$defense$systems[
    half_ahpcf$defense$systems$system_id == "SYS_DF_AHPCF",
  ]
  expect_false(system$supported)
  expect_equal(system$missing_components[[1]], "COMP_DF_AHPF")

  for (refused in c("K00518", "K05919")) {
    expect_false(curation_gift_call(
      "superoxide_detoxification", c(refused, "K03781")
    )$complete, info = refused)
  }
})

test_that("PHB stays refused because the polymerase marker is too broad", {
  expect_false("polyhydroxybutyrate_biosynthesis" %in% list_gifts()$gift_id)
  result <- evaluate_gifts(ko_annotations(c("K00626", "K00023", "K03821")))
  expect_false(any(
    result$gifts$complete & grepl("polyhydroxy", result$gifts$gift_id)
  ))
  expect_false("K03821" %in% result$marker_vocabulary$accession)

  decisions <- database_changelog()
  expect_true("DBC-20260820-PHB-REFUSED" %in% decisions$change_id)
  refusal <- decisions[decisions$change_id == "DBC-20260820-PHB-REFUSED", ]
  expect_match(refusal$effect, "validated class-specific custom HMM", fixed = TRUE)
})

test_that("the candidate release records every accepted boundary decision", {
  expected <- c(
    ectoine_biosynthesis = "DBC-20260820-COMPATIBLE-SOLUTES",
    choline_to_betaine = "DBC-20260820-COMPATIBLE-SOLUTES",
    heme_b_biosynthesis = "DBC-20260820-HEME-B",
    dihydroxybenzoate_biosynthesis = "DBC-20260820-ENTEROBACTIN-SPLIT",
    enterobactin_biosynthesis = "DBC-20260820-ENTEROBACTIN-SPLIT",
    methylglyoxal_detoxification = "DBC-20260820-CHEMICAL-DETOX-EXPANSION",
    superoxide_detoxification = "DBC-20260820-CHEMICAL-DETOX-EXPANSION"
  )
  for (gift_id in names(expected)) {
    expect_true(expected[[gift_id]] %in% database_changelog(gift_id)$change_id)
  }
})
