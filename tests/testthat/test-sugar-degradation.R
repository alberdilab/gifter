sugar_gifts <- c(
  "xylose_degradation_isomerase", "arabinose_degradation",
  "fucose_degradation_isomerase", "rhamnose_degradation",
  "galactose_degradation_leloir", "glcnac_degradation", "neuac_degradation",
  "galacturonate_degradation", "glucuronate_degradation"
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
    unique(outgoing$shared_anchor), c("PYRUVATE", "LACTALDEHYDE", "AMMONIUM")
  )
  expect_setequal(
    unique(outgoing$to_gift),
    c(
      "pyruvate_to_acetyl_coa", "propanediol_formation",
      "lactate_formation", "acetoin_formation", "ammonium_assimilation",
      "glutamine_biosynthesis", "alanine_biosynthesis",
      "oxoisovalerate_biosynthesis", "oxobutanoate_biosynthesis_citramalate"
    )
  )

  # A degradation GIFT is reached on an exact edge only through its own uptake
  # step. Nothing reaches one through a shared cytoplasmic intermediate.
  incoming <- graph[graph$to_gift %in% sugar_gifts, ]
  exact <- incoming[incoming$edge_quality == "exact", ]
  modes <- vapply(unique(exact$from_gift), function(id) get_gift(id)$mode, character(1))
  expect_true(all(modes == "transport"))
  expect_setequal(exact$from_gift, c("xylose_uptake_abc", "arabinose_uptake_abc"))

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
      "pectin_degradation galacturonate_degradation"
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
  # They converge only on the final two shared reactions.
  expect_setequal(intersect(galacturonate, glucuronate), c("RHEA:14797", "RHEA:17089"))
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
