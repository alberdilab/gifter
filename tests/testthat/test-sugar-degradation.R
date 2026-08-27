sugar_gifts <- c(
  "xylose_degradation_isomerase", "arabinose_degradation",
  "fucose_degradation_isomerase", "rhamnose_degradation",
  "galactose_degradation_leloir", "glcnac_degradation", "neuac_degradation",
  "galacturonate_degradation", "glucuronate_degradation", "kdg_degradation"
)

full_sugar_markers <- c(
  "K01805", "K00854", "K01804", "K00853", "K03077", "K01818", "K00879",
  "K01628", "K01813", "K00848", "K01629", "K00849", "K00965", "K01784",
  "K00884", "K01443", "K02564", "K01639", "K00885", "K01788", "K01812",
  "K00041", "K01685", "K00874", "K01625", "K00040", "K01686"
)

test_that("every sugar degradation GIFT is curated to the full evidence depth", {
  for (gift_id in sugar_gifts) {
    gift <- get_gift(gift_id)
    expect_equal(nrow(gift), 1L)
    expect_equal(gift$mode, "catabolic")

    anchors <- get_gift_anchors(gift_id)
    expect_true(any(anchors$role == "input"))
    expect_true(any(anchors$role == "output"))
    # A substrate anchor is split only where an uptake GIFT licensed it.
    licensed <- anchors$molecule %in% c("XYLOSE", "ARABINOSE")
    expect_true(all(anchors$compartment[!licensed] == "unspecified"))
    expect_true(all(anchors$compartment[licensed] == "cytoplasmic"))

    reactions <- get_gift_reactions(gift_id)
    expect_gt(nrow(reactions), 0L)
    for (reaction in unique(reactions$reaction_id)) {
      expect_gt(nrow(get_reaction_systems(reaction)), 0L)
    }
  }

  result <- evaluate_gifts(ko_annotations(full_sugar_markers))
  complete <- result$gifts$gift_id[result$gifts$complete]
  expect_true(all(sugar_gifts %in% complete))
})

test_that("catabolism does not connect to biosynthesis through internal metabolites", {
  graph <- gift_graph()

  # A degradation GIFT may be upstream only of the fermentation layer, and only
  # through a declared central-metabolite anchor. It is never upstream of a
  # biosynthesis GIFT, which is what this test exists to protect: shared
  # internal metabolites still create no edges. The set of downstream GIFTs
  # grows whenever a capability consuming pyruvate or lactaldehyde is curated;
  # the invariant that must not move is the anchor set and the mode.
  outgoing <- graph[graph$from_gift %in% sugar_gifts, ]
  downstream_modes <- vapply(
    unique(outgoing$to_gift), function(id) get_gift(id)$mode, character(1)
  )
  # The carbon anchors reach fermentation, central metabolism and -- since the
  # amino acid layer -- biosynthesis, because pyruvate is where sugar carbon
  # genuinely enters alanine and the branched-chain amino acids. That edge is
  # real biology rather than a boundary error, and the anabolic GIFTs it reaches
  # are exactly the ones whose curated input is pyruvate.
  carbon <- outgoing[outgoing$shared_anchor != "AMMONIUM", ]
  anabolic <- vapply(
    unique(carbon$to_gift), function(id) get_gift(id)$mode, character(1)
  )
  expect_setequal(
    names(anabolic)[anabolic == "anabolic"],
    c(
      "alanine_biosynthesis", "oxoisovalerate_biosynthesis",
      "oxobutanoate_biosynthesis_citramalate"
    )
  )
  expect_setequal(
    unique(carbon$shared_anchor[carbon$to_gift %in% names(anabolic)[anabolic == "anabolic"]]),
    "PYRUVATE"
  )
  # Ammonium reaches assimilation and, since glutamine synthetase was curated,
  # amidation as well. Both are the same rule: a deaminase liberates it and an
  # anabolic capability takes it up.
  nitrogen <- outgoing[outgoing$shared_anchor == "AMMONIUM", ]
  expect_setequal(
    unique(nitrogen$to_gift),
    c("ammonium_assimilation", "glutamine_biosynthesis")
  )
  expect_setequal(
    unique(nitrogen$from_gift), c("glcnac_degradation", "neuac_degradation")
  )
  expect_setequal(
    unique(outgoing$shared_anchor),
    c("PYRUVATE", "LACTALDEHYDE", "AMMONIUM", "KDG")
  )
  expect_setequal(
    unique(outgoing$to_gift),
    c(
      "pyruvate_to_acetyl_coa", "propanediol_formation",
      # Lactaldehyde now has a second fate beside its reduction to propanediol.
      "lactate_formation_lactaldehyde",
      "lactate_formation", "acetoin_formation", "ammonium_assimilation",
      "glutamine_biosynthesis", "alanine_biosynthesis",
      "oxoisovalerate_biosynthesis", "oxobutanoate_biosynthesis_citramalate",
      "kdg_degradation"
    )
  )

  # A degradation GIFT is reached on an exact edge only through its own uptake
  # step. Nothing reaches one through a shared cytoplasmic intermediate.
  # Two kinds of exact edge reach this layer, and the difference is the point.
  # An uptake GIFT reaches the catabolism of the sugar it imports, which is what
  # keeps transport GIFTs load-bearing. Since the 2026.21.3 re-cut, the two
  # hexuronate heads also reach the shared Entner-Doudoroff tail -- but through
  # 2-dehydro-3-deoxy-D-gluconate, a *declared* branchpoint anchor. That is the
  # licensed case; what this test still forbids is a connection made through an
  # undeclared internal metabolite.
  incoming <- graph[graph$to_gift %in% sugar_gifts, ]
  exact <- incoming[incoming$edge_quality == "exact", ]
  expect_setequal(
    paste(exact$from_gift, exact$to_gift),
    c(
      "xylose_uptake_abc xylose_degradation_isomerase",
      "arabinose_uptake_abc arabinose_degradation",
      "galacturonate_degradation kdg_degradation",
      "glucuronate_degradation kdg_degradation"
    )
  )
  uptake <- exact[exact$to_gift != "kdg_degradation", ]
  modes <- vapply(unique(uptake$from_gift), function(id) get_gift(id)$mode, character(1))
  expect_true(all(modes == "transport"))
  expect_true(all(exact$shared_anchor[exact$to_gift == "kdg_degradation"] == "KDG"))

  # Extracellular saccharification reaches the matching catabolic GIFT, but only
  # on a compartment-inexact edge. The released sugar is outside the cell and the
  # catabolism is inside it; where no transporter evidence licensed a compartment
  # split, both sides name the one unsplit anchor. Flagging the edge keeps the
  # chain traversable while recording that the transport step is assumed rather
  # than evidenced, which is what separates a forager from a public-goods donor.
  inexact <- incoming[incoming$edge_quality == "compartment_inexact", ]
  expect_setequal(
    paste(inexact$from_gift, inexact$to_gift),
    c(
      "chitin_degradation glcnac_degradation",
      "mucin_sialic_acid_release neuac_degradation",
      "mucin_fucose_release fucose_degradation_isomerase",
      "pectin_degradation galacturonate_degradation",
      "pectate_lyase_degradation kdg_degradation"
    )
  )
  expect_true(all(vapply(
    unique(inexact$from_gift),
    function(id) any(get_gift_anchors(id)$compartment == "extracellular"),
    logical(1)
  )))

  # Xylose and arabinose both end at D-xylulose 5-phosphate. Sharing an output
  # anchor is convergence, not composition.
  expect_equal(
    get_gift_anchors("arabinose_degradation")$anchor_id[2],
    get_gift_anchors("xylose_degradation_isomerase")$anchor_id[2]
  )
})

test_that("the Leloir pathway is called without a recognised mutarotase", {
  # Anomerisation also proceeds spontaneously, so aldose 1-epimerase is
  # required = 0: it belongs in the trace, not in the call.
  result <- evaluate_gifts(ko_annotations(c("K00849", "K00965", "K01784")))
  gift <- result$gifts[result$gifts$gift_id == "galactose_degradation_leloir", ]
  expect_true(gift$complete)
  expect_equal(gift$minimum_missing_reactions, 0L)

  reactions <- get_gift_reactions("galactose_degradation_leloir")
  expect_equal(reactions$required[reactions$reaction_id == "RHEA:28675"], 0L)
  # Catabolism runs the epimerase backwards relative to the Rhea master.
  expect_equal(reactions$orientation[reactions$reaction_id == "RHEA:22168"], "reverse")
})

test_that("sialic acid degradation needs the shared amino sugar chemistry", {
  # neuac_degradation reuses the nagA and nagB reactions but is not a composite
  # of glcnac_degradation: the shared intermediate is phosphorylated and is
  # deliberately internal to both, so no anchor and no graph edge exist.
  partial <- evaluate_gifts(ko_annotations(c("K01639", "K00885", "K01788")))
  gift <- partial$gifts[partial$gifts$gift_id == "neuac_degradation", ]
  expect_false(gift$complete)
  expect_equal(gift$minimum_missing_reactions, 2L)
  expect_setequal(gift$missing_reactions_best_route[[1]], c("RHEA:22936", "RHEA:12172"))

  expect_false("GLCNAC" %in% get_gift_anchors("neuac_degradation")$anchor_id)
})

test_that("a bifunctional marker supports both of the reactions it catalyses", {
  # nanEK carries the kinase and the epimerase activity in one protein.
  complete <- evaluate_gifts(ko_annotations(c("K01639", "K13967", "K01443", "K02564")))
  gift <- complete$gifts[complete$gifts$gift_id == "neuac_degradation", ]
  expect_true(gift$complete)

  trace <- trace_gift(complete, "neuac_degradation")
  supported_by_nanek <- unique(trace$reaction_id[trace$accession == "K13967"])
  expect_setequal(supported_by_nanek, c("RHEA:25253", "RHEA:25257"))
})

test_that("the biosynthetic GNE kinase is not evidence for sialic acid catabolism", {
  # K12409 catalyses the chemistry but does so in the direction of sialic acid
  # synthesis. Accepting it would call degradation in genomes that only build.
  result <- evaluate_gifts(ko_annotations(c("K01639", "K12409", "K01788", "K01443", "K02564")))
  gift <- result$gifts[result$gifts$gift_id == "neuac_degradation", ]
  expect_false(gift$complete)
  expect_equal(gift$missing_reactions_best_route[[1]], "RHEA:25253")

  accepted <- get_reaction_systems("RHEA:25253")$accession
  expect_false("K12409" %in% accepted)
  expect_true(all(c("K00885", "K13967") %in% accepted))
})

test_that("altronate dehydratase works as a monomer or as a complete heterodimer", {
  monomer <- evaluate_gifts(ko_annotations(
    c("K01812", "K00041", "K01685", "K00874", "K01625")
  ))
  expect_true(monomer$gifts$complete[
    monomer$gifts$gift_id == "galacturonate_degradation"
  ])

  heterodimer <- evaluate_gifts(ko_annotations(
    c("K01812", "K00041", "K16849", "K16850", "K00874", "K01625")
  ))
  expect_true(heterodimer$gifts$complete[
    heterodimer$gifts$gift_id == "galacturonate_degradation"
  ])

  # One subunit is not half a reaction.
  partial <- evaluate_gifts(ko_annotations(
    c("K01812", "K00041", "K16849", "K00874", "K01625")
  ))
  gift <- partial$gifts[partial$gifts$gift_id == "galacturonate_degradation", ]
  expect_false(gift$complete)
  expect_equal(gift$missing_reactions_best_route[[1]], "RHEA:15957")
})

test_that("uronate isomerase evidence is shared without merging the capabilities", {
  # One enzyme, two Rhea reactions, two capabilities. The marker supports both;
  # the routes stay distinct because the head chemistry differs.
  expect_true("K01812" %in% get_reaction_systems("RHEA:27702")$accession)
  expect_true("K01812" %in% get_reaction_systems("RHEA:13049")$accession)

  galacturonate <- get_gift_reactions("galacturonate_degradation")$reaction_id
  glucuronate <- get_gift_reactions("glucuronate_degradation")$reaction_id
  expect_true("RHEA:27702" %in% galacturonate)
  expect_false("RHEA:27702" %in% glucuronate)
  # Since the 2026.21.3 re-cut they share no reaction at all. The two reactions
  # they used to carry twice between them are kdg_degradation, and the
  # convergence is expressed as a shared anchor instead of duplicated chemistry.
  expect_length(intersect(galacturonate, glucuronate), 0L)
  expect_setequal(
    get_gift_reactions("kdg_degradation")$reaction_id,
    c("RHEA:14797", "RHEA:17089")
  )
  expect_true(all(vapply(
    c("galacturonate_degradation", "glucuronate_degradation"),
    function(id) {
      anchors <- get_gift_anchors(id)
      identical(anchors$anchor_id[anchors$role == "output"], "KDG")
    },
    logical(1)
  )))
})

test_that("xylose isomerase is curated on xylose, not on its promiscuous activity", {
  # EC 5.3.1.5 also carries alpha-D-glucose = alpha-D-fructose in Rhea. Curating
  # that reaction would make every xylA genome a glucose isomerase trait.
  reactions <- get_gift_reactions("xylose_degradation_isomerase")$reaction_id
  expect_true("RHEA:22816" %in% reactions)
  expect_false("RHEA:28546" %in% reactions)
})

test_that("sugar degradation curation is recorded in the biological changelog", {
  for (gift_id in sugar_gifts) {
    expect_gt(nrow(database_changelog(gift_id)), 0L)
  }
  changes <- database_changelog("neuac_degradation")$change_id
  expect_true("DBC-20260818-GNE-EXCLUDED" %in% changes)
})

test_that("glcnac_degradation offers two entries and neither requires the other", {
  # Database 2026.26.1. The single curated route required a cytoplasmic
  # N-acetylglucosamine kinase carried by 8.0% of the reference genomes, while
  # the two reactions below it reach 59.5% and 47.3%. Most bacteria import the
  # sugar through a PTS that phosphorylates it in transit, so they reach
  # GlcNAc-6-phosphate having never needed the kinase. The fix is a second route
  # between the same anchors, not a moved boundary.
  routes <- get_gift_routes("glcnac_degradation")
  expect_setequal(routes$route_id, c("GLCNAC_KINASE", "GLCNAC_PTS"))

  reactions <- get_gift_reactions("glcnac_degradation")
  entry <- list(GLCNAC_KINASE = "RHEA:17417", GLCNAC_PTS = "RHEA:49240")
  shared <- c("RHEA:22936", "RHEA:12172")
  for (route in names(entry)) {
    in_route <- reactions$reaction_id[reactions$route_id == route]
    expect_setequal(in_route, c(entry[[route]], shared))
    # The other route's entry reaction is absent, which is what makes them
    # alternatives rather than one longer route.
    expect_false(entry[[setdiff(names(entry), route)]] %in% in_route)
  }

  downstream <- c("K01443", "K02564")
  kinase <- evaluate_gifts(ko_annotations(c("K00884", downstream)))
  pts <- evaluate_gifts(ko_annotations(c("K02804", downstream)))
  neither <- evaluate_gifts(ko_annotations(downstream))

  complete_route <- function(result, route_id) {
    routes <- result$routes
    routes$complete[routes$gift_id == "glcnac_degradation" &
                      routes$route_id == route_id]
  }
  is_complete <- function(result) {
    result$gifts$complete[result$gifts$gift_id == "glcnac_degradation"]
  }

  expect_true(is_complete(kinase))
  expect_true(complete_route(kinase, "GLCNAC_KINASE"))
  expect_false(complete_route(kinase, "GLCNAC_PTS"))

  expect_true(is_complete(pts))
  expect_true(complete_route(pts, "GLCNAC_PTS"))
  expect_false(complete_route(pts, "GLCNAC_KINASE"))

  # Neither entry, and the downstream chemistry alone proves nothing.
  expect_false(is_complete(neither))
})

test_that("the GlcNAc PTS route claims no boundary the old one did not", {
  # The decision recorded in DBC-20260827-GLCNAC-PTS-ROUTE was to leave the
  # boundaries alone. Minting a GLCNAC_6P anchor for an internal intermediate
  # would have broken the composition edge from chitin_degradation and left a
  # one-reaction kinase GIFT, which invariant 9 refuses.
  anchors <- get_gift_anchors("glcnac_degradation")
  expect_setequal(
    anchors$anchor_id[anchors$role == "input"], "GLCNAC"
  )
  expect_setequal(
    anchors$anchor_id[anchors$role == "output"], c("FRUCTOSE_6P", "AMMONIUM")
  )
  expect_equal(get_gift("glcnac_degradation")$mode, "catabolic")
  all_anchors <- do.call(rbind, lapply(list_gifts()$gift_id, get_gift_anchors))
  expect_false("GLCNAC_6P" %in% all_anchors$anchor_id)

  # GLCNAC stays compartment-unspecified because the two entries start on
  # opposite sides of the membrane, so the chitin edge stays traversable and
  # compartment-inexact rather than becoming a cross-organism edge.
  expect_equal(anchors$compartment[anchors$role == "input"], "unspecified")
})

test_that("a promiscuous hexose PTS does not evidence GlcNAc translocation", {
  # Invariant 16. ManXYZ moves glucose, mannose, fructose, glucosamine and
  # N-acetylglucosamine through one enzyme II, so admitting it here would equate
  # glcnac_degradation with four sugars it does not claim. The refusal is in the
  # deferral register and this test is what makes it findable.
  mannose_pts <- c("K02793", "K02794", "K02795", "K02796", "K25814")
  expect_false(any(map_markers(ko_annotations(mannose_pts))$matched))

  result <- evaluate_gifts(ko_annotations(c(mannose_pts, "K01443", "K02564")))
  expect_false(result$gifts$complete[result$gifts$gift_id == "glcnac_degradation"])
})

test_that("the amino sugar NCBIfam equivalogs reach both capabilities", {
  # NF046059.1 nagB-II is a second deaminase family K02564 does not cover, on a
  # reaction glcnac_degradation and neuac_degradation share.
  profiles <- c("NF046059.1", "TIGR00502.1", "TIGR01998.1", "NF008371.0")
  annotation <- data.frame(
    gene_id = paste0("gene_", seq_along(profiles)),
    namespace = "NCBIFAM",
    accession = profiles,
    stringsAsFactors = FALSE
  )
  mapped <- map_markers(annotation)
  expect_true(all(mapped$matched))

  # An NCBIfam-only annotation completes the PTS route end to end: enzyme II,
  # deacetylase, deaminase, with no KO involved.
  result <- evaluate_gifts(annotation[annotation$accession != "NF046059.1", ])
  expect_true(result$gifts$complete[result$gifts$gift_id == "glcnac_degradation"])

  # And nagB-II alone stands in for the deaminase the KO layer misses.
  nagb2 <- annotation[annotation$accession != "TIGR00502.1", ]
  result <- evaluate_gifts(nagb2)
  expect_true(result$gifts$complete[result$gifts$gift_id == "glcnac_degradation"])
  # The deaminase is shared, so the gain lands on both amino sugar capabilities
  # and the changelog says so on both.
  expect_true("RHEA:12172" %in% get_gift_reactions("neuac_degradation")$reaction_id)
  for (gift_id in c("glcnac_degradation", "neuac_degradation")) {
    expect_true("DBC-20260827-AMINO-SUGAR-NCBIFAM-MARKERS" %in%
                  database_changelog(gift_id)$change_id)
  }
})
