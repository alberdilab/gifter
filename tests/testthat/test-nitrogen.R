# Nitrogen, methylated amine and organosulfonate catabolism.
#
# These tests protect the two rules the layer cannot be curated without -- the
# nitrogen-anchor rule and the electron-acceptor scope -- and the marker
# specificity refusals that decided four of its candidate traits.

# giftr exposes anchors per GIFT rather than GIFTs per anchor, so the inverse
# lookup these tests need is assembled here rather than added to the API.
anchor_users <- function(anchor_id) {
  ids <- list_gifts()$gift_id
  rows <- lapply(ids, function(id) {
    anchors <- get_gift_anchors(id)
    if (!nrow(anchors)) return(NULL)
    hit <- anchors[anchors$anchor_id == anchor_id, , drop = FALSE]
    if (!nrow(hit)) return(NULL)
    data.frame(gift_id = id, role = hit$role, stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}

test_that("ammonium is a boundary only where a reaction liberates or assimilates it", {
  # The nitrogen-anchor rule. Ammonium participates in four curated reactions
  # and is a declared anchor for the three GIFTs whose chemistry is aimed at it,
  # never for the vitamin GIFTs that merely release or consume it in passing.
  ammonium_gifts <- sort(unique(anchor_users("AMMONIUM")$gift_id))
  expect_setequal(
    ammonium_gifts,
    c(
      "ammonium_assimilation", "glcnac_degradation", "methylamine_degradation",
      "neuac_degradation", "nitrate_assimilation", "urea_hydrolysis",
      # The amino acid layer applies the same rule in both directions: the
      # capabilities whose chemistry is aimed at liberating ammonium declare it,
      # and glutamine synthetase declares it because it assimilates it.
      "glutamine_biosynthesis",
      "arginine_deiminase_pathway", "histidine_degradation_glutamate",
      "threonine_deamination", "serine_deamination",
      "tryptophan_degradation_indole", "methionine_degradation_methanethiol",
      "cysteine_degradation_sulfide", "glycine_reduction_stickland"
    )
  )
  # Asparagine biosynthesis is the boundary case the rule decides: its AsnA
  # route does assimilate ammonium, but its AsnB route uses the glutamine amide
  # instead, and an anchor is a claim about every route. It declares only
  # aspartate, and the same reasoning keeps ammonium off alanine biosynthesis.
  expect_false(any(
    c("asparagine_biosynthesis", "alanine_biosynthesis") %in% ammonium_gifts
  ))
  # The three rejected reactions belong to GIFTs that must not gain the anchor:
  # riboflavin and menaquinone would become nitrogen sources, and NAD
  # biosynthesis would become a sink every catabolic GIFT composed into.
  expect_false(any(
    c("riboflavin_biosynthesis", "menaquinone_biosynthesis",
      "nad_biosynthesis_namn") %in% ammonium_gifts
  ))
})

test_that("the amino sugar GIFTs declare the ammonium their deaminase releases", {
  # RHEA:12172 terminates both routes and its whole purpose is deamination, so
  # both GIFTs qualify under the rule. The carbon boundary is unchanged.
  for (id in c("glcnac_degradation", "neuac_degradation")) {
    anchors <- get_gift_anchors(id)
    outputs <- anchors$anchor_id[anchors$role == "output"]
    expect_setequal(outputs, c("FRUCTOSE_6P", "AMMONIUM"))
  }
})

test_that("nitrogen catabolism composes through declared anchors without cycling", {
  # Urate to ammonium is a path of three capabilities that only 88 of 10151
  # bacteria complete together, which is why it is three GIFTs and not one.
  graph <- gift_graph()
  step <- function(from, to) {
    any(graph$from_gift == from & graph$to_gift == to)
  }
  expect_true(step("urate_degradation", "allantoin_degradation"))
  expect_true(step("allantoin_degradation", "urea_hydrolysis"))
  expect_true(step("urea_hydrolysis", "ammonium_assimilation"))
  # Carnitine reaches glycine only by composition, never by duplicated steps.
  expect_true(step("carnitine_to_betaine", "betaine_demethylation"))
  expect_true(step("betaine_demethylation", "sarcosine_demethylation"))
  expect_true(step("creatinine_degradation", "sarcosine_demethylation"))
  # No catabolic GIFT of the layer is reachable from itself.
  catabolic <- list_gifts()$gift_id[list_gifts()$mode %in% "catabolic"]
  edges <- graph[graph$from_gift %in% catabolic & graph$to_gift %in% catabolic, ]
  reach <- edges[, c("from_gift", "to_gift")]
  for (i in seq_len(6)) {
    grown <- merge(reach, edges[, c("from_gift", "to_gift")],
                   by.x = "to_gift", by.y = "from_gift")
    if (!nrow(grown)) break
    reach <- unique(rbind(
      reach,
      data.frame(from_gift = grown$from_gift, to_gift = grown$to_gift.y)
    ))
  }
  expect_false(any(reach$from_gift == reach$to_gift))
})

test_that("sarcosine is curated once and reached from both upstream capabilities", {
  # Invariant 8: composition, not duplication. The sarcosine reactions belong
  # to sarcosine_demethylation alone.
  sarcosine_reactions <- get_gift_routes("sarcosine_demethylation")$route_id
  for (id in c("betaine_demethylation", "creatinine_degradation")) {
    expect_false(any(get_gift_routes(id)$route_id %in% sarcosine_reactions))
  }
  anchors <- get_gift_anchors("creatinine_degradation")
  expect_setequal(
    anchors$anchor_id[anchors$role == "output"], c("SARCOSINE", "UREA")
  )
})

test_that("urease needs all three catalytic subunits and accepts the fused gene", {
  # AND across components, OR across markers within one.
  none <- evaluate_gifts(ko_annotations("K01428"))
  expect_false(none$gifts$complete[none$gifts$gift_id == "urea_hydrolysis"])
  separate <- evaluate_gifts(ko_annotations(c("K01428", "K01429", "K01430")))
  expect_true(separate$gifts$complete[separate$gifts$gift_id == "urea_hydrolysis"])
  # UreAB is one protein carrying two components, so it satisfies both.
  fused <- evaluate_gifts(ko_annotations(c("K01428", "K14048")))
  expect_true(fused$gifts$complete[fused$gifts$gift_id == "urea_hydrolysis"])
  # The nickel maturation proteins are deliberately not components.
  maturation <- evaluate_gifts(ko_annotations(c("K03187", "K03188", "K03189", "K03190")))
  expect_false(maturation$gifts$complete[maturation$gifts$gift_id == "urea_hydrolysis"])
})

test_that("nitrate assimilation is an OR over two reductases and three nitrite systems", {
  routes <- get_gift_routes("nitrate_assimilation")
  expect_equal(nrow(routes), 4L)
  # Either nitrate reductase with either nitrite reductase completes the trait.
  for (pair in list(c("K00372", "K00366"), c("K00367", "K00366"))) {
    result <- evaluate_gifts(ko_annotations(pair))
    expect_true(result$gifts$complete[result$gifts$gift_id == "nitrate_assimilation"])
  }
  # NirBD and NasDE are alternative systems of one reaction, not two reactions.
  for (pair in list(c("K00372", "K00362", "K00363"), c("K00372", "K26139", "K26138"))) {
    result <- evaluate_gifts(ko_annotations(pair))
    expect_true(result$gifts$complete[result$gifts$gift_id == "nitrate_assimilation"])
  }
  # A nitrate reductase alone is not the capability.
  alone <- evaluate_gifts(ko_annotations("K00372"))
  expect_false(alone$gifts$complete[alone$gifts$gift_id == "nitrate_assimilation"])
})

test_that("respiratory nitrogen and sulfur markers fire nothing", {
  # The electron-acceptor scope. These accessions are specific, abundant and
  # easy to curate, which is exactly why the refusal has to be tested: nothing
  # in the evidence layer would otherwise stop them being added.
  respiratory <- c(
    "K00370", "K00371", "K00374",  # NarGHI, nitrate respiration
    "K02567", "K02568",            # NapAB, periplasmic nitrate reductase
    "K03385", "K15876",            # NrfAH, dissimilatory reduction to ammonium
    "K00368", "K15864",            # NirK / NirS, denitrification
    "K11180", "K11181"             # DsrAB, taurine to hydrogen sulfide
  )
  result <- evaluate_gifts(ko_annotations(respiratory))
  expect_false(any(result$gifts$complete))
  # None of them is even an accepted marker anywhere in the database.
  mapped <- map_markers(ko_annotations(respiratory))
  expect_false(any(mapped$matched))
})

test_that("a broad amine oxidase does not fire an amine trait", {
  # Invariant 16. K00276 is a primary-amine oxidase and K00274 a monoamine
  # oxidase; both act on tyramine, histamine and putrescine, so neither can
  # name the amine and phenylethylamine degradation is refused. K01485 is a
  # cytosine/creatinine deaminase, so it cannot license creatinine degradation.
  broad <- evaluate_gifts(ko_annotations(c("K00276", "K00274", "K00146", "K01485")))
  expect_false(any(broad$gifts$complete))
  expect_false(any(list_gifts()$gift_id == "phenylethylamine_degradation"))
  expect_false(any(list_gifts()$gift_id == "hypotaurine_degradation"))
  # Creatinine degradation needs the specific pair and nothing less.
  first_only <- evaluate_gifts(ko_annotations("K01470"))
  expect_false(first_only$gifts$complete[
    first_only$gifts$gift_id == "creatinine_degradation"
  ])
  both <- evaluate_gifts(ko_annotations(c("K01470", "K08688")))
  expect_true(both$gifts$complete[both$gifts$gift_id == "creatinine_degradation"])
})

test_that("the two carnitine capabilities are separate and release different products", {
  # CdhC yields the betainyl thioester, not a free amine, so the dehydrogenase
  # route is not a second route to trimethylamine.
  cnt <- evaluate_gifts(ko_annotations(c("K22443", "K22444")))
  expect_true(cnt$gifts$complete[
    cnt$gifts$gift_id == "carnitine_degradation_trimethylamine"
  ])
  expect_false(cnt$gifts$complete[cnt$gifts$gift_id == "carnitine_to_betaine"])

  cdh <- evaluate_gifts(ko_annotations(c("K17735", "K27837")))
  expect_true(cdh$gifts$complete[cdh$gifts$gift_id == "carnitine_to_betaine"])
  expect_false(cdh$gifts$complete[
    cdh$gifts$gift_id == "carnitine_degradation_trimethylamine"
  ])
  # Only one GIFT declares trimethylamine, and only as an output.
  tma <- anchor_users("TRIMETHYLAMINE")
  expect_equal(tma$gift_id, "carnitine_degradation_trimethylamine")
  expect_equal(tma$role, "output")
})

test_that("taurine uptake gates the cytoplasmic capabilities", {
  # The compartment split is load-bearing: the desulfonation enzymes act on
  # cytoplasmic taurine, so the importer is what connects them to the outside.
  enzymes <- evaluate_gifts(ko_annotations("K03119"))
  expect_true(enzymes$gifts$complete[
    enzymes$gifts$gift_id == "taurine_desulfonation_aerobic"
  ])
  expect_false(enzymes$gifts$complete[
    enzymes$gifts$gift_id == "taurine_uptake_abc"
  ])
  graph <- gift_graph()
  gated <- graph[graph$to_gift == "taurine_desulfonation_aerobic", ]
  expect_equal(unique(gated$from_gift), "taurine_uptake_abc")
  expect_true(all(gated$edge_quality == "exact"))
})

test_that("neither taurine capability claims hydrogen sulfide or nitrogen", {
  # Both routes stop at sulfite, and the nitrogen fate differs by route --
  # L-alanine from the transaminase, ammonium from the dehydrogenase -- so the
  # GIFT declares neither.
  for (id in c("taurine_desulfonation_aerobic",
               "taurine_degradation_sulfoacetaldehyde")) {
    outputs <- get_gift_anchors(id)
    expect_setequal(outputs$anchor_id[outputs$role == "output"], "SULFITE")
  }
  # SULFITE is output-only: nothing consumes it, because that would be
  # respiration.
  expect_setequal(anchor_users("SULFITE")$role, "output")
})

test_that("the layer is discriminating rather than universal", {
  # A genome with none of the layer's markers calls none of its capabilities.
  empty <- evaluate_gifts(ko_annotations("K00764"))
  layer <- c(
    "urate_degradation", "allantoin_degradation", "urea_hydrolysis",
    "nitrate_assimilation", "betaine_demethylation", "sarcosine_demethylation",
    "creatinine_degradation", "carnitine_degradation_trimethylamine",
    "carnitine_to_betaine", "methylamine_degradation",
    "taurine_desulfonation_aerobic", "taurine_degradation_sulfoacetaldehyde",
    "taurine_uptake_abc", "ammonium_assimilation"
  )
  expect_false(any(empty$gifts$complete[empty$gifts$gift_id %in% layer]))
  # Every one of them is a curated metabolic GIFT with a mode and a substrate
  # class, which is the typed contract for this type.
  for (id in layer) {
    gift <- get_gift(id)
    expect_equal(gift$gift_type, "metabolic")
    expect_true(!is.na(gift$mode))
    facets <- get_facets(id)
    expect_equal(sum(facets$facet == "substrate_class"), 1L)
    expect_true(sum(facets$facet == "physiological_role") >= 1L)
  }
})
