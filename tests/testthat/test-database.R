test_that("canonical source tables validate", {
  source_dir <- system.file("extdata", "database-source", package = "gifter")
  report <- validate_gifter_sources(source_dir)

  expect_true(report$valid)
  expect_length(report$errors, 0L)
  expect_equal(
    unname(report$rows[c("gifts", "anchors", "reactions")]), c(149L, 154L, 432L)
  )
  # Every typed model now ships curated content.
  expect_equal(
    unname(report$rows[c("gift_architectures", "gift_circuits", "gift_mechanisms")]),
    c(3L, 4L, 5L)
  )
})

test_that("database compilation creates constrained SQLite schema", {
  source_dir <- system.file("extdata", "database-source", package = "gifter")
  output <- tempfile(fileext = ".sqlite")
  on.exit(unlink(output), add = TRUE)

  expect_silent(build_gifter_database(source_dir, output))
  db <- gifter_db_connect(output)
  on.exit(gifter_db_disconnect(db), add = TRUE)

  tables <- DBI::dbListTables(db)
  expect_true(all(c(
    "gift", "anchor", "gift_anchor", "reaction", "gift_route",
    "route_reaction", "enzyme_system", "enzyme_component", "marker",
    "component_marker", "gift_xref", "database_release",
    "reference_universe", "reference_universe_filter",
    "reference_universe_metric",
    "gift_architecture", "architecture_function", "structural_function",
    "structural_system", "structural_component", "structural_component_marker",
    "gift_circuit", "circuit_function", "gift_mechanism", "mechanism_function"
  ) %in% tables))
  expect_equal(nrow(DBI::dbGetQuery(db, "PRAGMA foreign_key_check")), 0L)
  expect_identical(DBI::dbGetQuery(db, "PRAGMA integrity_check")[[1]], "ok")

  indexes <- DBI::dbGetQuery(
    db,
    "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_%'"
  )$name
  expect_true("idx_marker_namespace_accession" %in% indexes)
  expect_true("idx_route_reaction_route_pk" %in% indexes)
  expect_true("idx_gift_xref_gift_pk" %in% indexes)
  expect_true("idx_gift_gift_type" %in% indexes)
  expect_true("idx_structural_component_system_pk" %in% indexes)
})

test_that("source validation rejects duplicate stable IDs", {
  source_dir <- system.file("extdata", "database-source", package = "gifter")
  fixture <- tempfile("gifter-source-")
  dir.create(fixture)
  on.exit(unlink(fixture, recursive = TRUE), add = TRUE)
  expect_true(all(file.copy(list.files(source_dir, full.names = TRUE), fixture)))

  gifts_path <- file.path(fixture, "gifts.tsv")
  gifts <- utils::read.delim(gifts_path, sep = "\t", check.names = FALSE)
  gifts <- rbind(gifts, gifts[1, ])
  utils::write.table(gifts, gifts_path, sep = "\t", quote = FALSE, row.names = FALSE, na = "")

  report <- validate_gifter_sources(fixture, stop_on_error = FALSE)
  expect_false(report$valid)
  expect_true(any(grepl("Duplicated gifts.gift_id", report$errors, fixed = TRUE)))
  expect_error(validate_gifter_sources(fixture), "source validation failed")
})

test_that("foreign key enforcement is enabled on runtime connections", {
  db <- gifter_db_connect()
  on.exit(gifter_db_disconnect(db), add = TRUE)
  expect_equal(DBI::dbGetQuery(db, "PRAGMA foreign_keys")[[1]], 1L)
})

test_that("database accessors return stable definitions", {
  gifts <- list_gifts()
  expect_equal(
    gifts$gift_id,
    c(
     "acetate_interconversion", "acetoin_formation",
      "acetyl_coa_to_isocitrate", "adenylate_biosynthesis",
      "alanine_biosynthesis", "allantoin_degradation",
      "ammonium_assimilation", "anthranilate_degradation_catechol",
      "arabinose_degradation", "arabinose_uptake_abc",
      "arabinoxylan_debranching", "arginine_biosynthesis",
      "arginine_deiminase_pathway", "asparagine_biosynthesis",
      "aspartate_biosynthesis", "aspartate_chemoreception",
      "aspartate_semialdehyde_biosynthesis", "assimilatory_sulfate_reduction",
      "benzoate_degradation_catechol",
      "betaine_demethylation", "biotin_biosynthesis", "butyrate_formation",
      "carnitine_degradation_trimethylamine", "carnitine_to_betaine",
      "catechol_meta_cleavage", "catechol_ortho_cleavage",
      "chemotaxis_signal_transduction", "chitin_degradation",
      "choline_to_betaine",
      "chorismate_biosynthesis",
      "citrate_fermentation", "cobamide_nucleotide_loop_assembly",
      "cobinamide_biosynthesis", "collagen_cleavage",
      "corrin_ring_biosynthesis", "creatinine_degradation",
      "cysteine_biosynthesis_homocysteine", "cysteine_biosynthesis_sulfide",
      "cysteine_degradation_sulfide", "cytidylate_biosynthesis",
      "dap_biosynthesis", "dihydroxybenzoate_biosynthesis",
      "dihydroxyphenylpropanoate_degradation", "dmb_biosynthesis_aerobic",
      "ectoine_biosynthesis", "enterobactin_biosynthesis", "ethanol_formation",
      "flagellar_apparatus",
      "folate_biosynthesis", "fucose_degradation_isomerase",
      "fumarate_oxaloacetate_interconversion", "galactose_degradation_leloir",
      "galacturonate_degradation", "glcnac_degradation",
      "glucuronate_degradation", "glutamate_decarboxylation_gaba",
      "glutamine_biosynthesis", "glycine_biosynthesis",
      "glycine_reduction_stickland", "glyoxylate_bypass", "guanylate_biosynthesis",
      "heme_b_biosynthesis", "histidine_biosynthesis", "histidine_degradation_glutamate",
      "hmp_phosphate_biosynthesis", "homoserine_biosynthesis",
      "hydroxyphenylpropanoate_hydroxylation",
      "indole_3_acetate_biosynthesis", "isocitrate_to_oxoglutarate",
      "isoleucine_biosynthesis", "kdg_degradation",
      "lactate_formation", "lactate_racemisation", "leucine_biosynthesis",
      "lysine_biosynthesis_dap", "malolactic_fermentation",
      "menaquinone_biosynthesis", "mercury_detoxification", "methionine_biosynthesis_sulfhydrylation",
      "methionine_biosynthesis_transsulfuration",
      "methionine_degradation_methanethiol", "methylamine_degradation",
      "methylglyoxal_detoxification",
      "mucin_fucose_release", "mucin_galnac_release",
      "mucin_sialic_acid_release",
      "nad_biosynthesis_namn", "namn_biosynthesis_quinolinate",
      "namn_salvage_nicotinate", "neuac_degradation", "nitrate_assimilation",
      "nitrogen_fixation",
      "ornithine_biosynthesis", "oxoadipate_activation",
      "oxoadipyl_coa_thiolysis", "oxobutanoate_biosynthesis_citramalate",
      "oxoglutarate_to_succinate", "oxoisovalerate_biosynthesis",
      "oxopentenoate_degradation", "paba_biosynthesis",
      "pantothenate_biosynthesis",
      "pectate_lyase_degradation", "pectin_degradation",
      "phenol_hydroxylation",
      "phenylacetate_degradation", "phenylalanine_biosynthesis",
      "phenylpropanoate_dihydroxylation", "phosphate_starvation_response",
      "plp_biosynthesis_dxp", "plp_biosynthesis_r5p", "proline_biosynthesis",
      "proline_reduction_stickland", "propanediol_formation",
      "propionate_formation_acrylate", "propionate_formation_propanediol",
      "purine_core_biosynthesis", "pyrimidine_core_biosynthesis",
      "pyruvate_to_acetyl_coa", "quinolinate_biosynthesis_aspartate",
      "rhamnose_degradation", "riboflavin_biosynthesis",
      "salicylate_biosynthesis", "sarcosine_demethylation",
      "serine_biosynthesis", "serine_deamination", "siroheme_biosynthesis",
      "starch_degradation",
      "succinate_fumarate_interconversion", "superoxide_detoxification",
      "taurine_degradation_sulfoacetaldehyde",
      "taurine_desulfonation_aerobic", "taurine_uptake_abc",
      "thiamine_phosphate_biosynthesis", "thiamine_precursor_salvage",
      "thiazole_phosphate_biosynthesis", "threonine_biosynthesis",
      "threonine_deamination", "tryptophan_biosynthesis",
      "tryptophan_degradation_indole", "type_i_e_crispr_cas_machinery",
      "type_i_restriction_modification", "type_iva_pilus",
      "tyrosine_biosynthesis", "urate_degradation", "urea_hydrolysis",
      "valine_biosynthesis", "xylan_degradation",
      "xylose_degradation_isomerase", "xylose_uptake_abc"
    )
  )
  expect_equal(nrow(get_gift("purine_core_biosynthesis")), 1L)

  anchors <- get_gift_anchors("purine_core_biosynthesis")
  expect_equal(anchors$anchor_id, c("PRPP", "IMP"))
  expect_equal(anchors$role, c("input", "output"))

  routes <- get_gift_routes("purine_core_biosynthesis")
  expect_equal(nrow(routes), 8L)
  expect_equal(nrow(get_gift_reactions("adenylate_biosynthesis")), 2L)
  pyrimidine_anchors <- get_gift_anchors("pyrimidine_core_biosynthesis")
  expect_equal(pyrimidine_anchors$anchor_id, c("GLUTAMINE", "PRPP", "UMP"))
  expect_equal(pyrimidine_anchors$role, c("input", "input", "output"))
  expect_equal(nrow(get_gift_routes("pyrimidine_core_biosynthesis")), 3L)
  expect_equal(nrow(get_gift_reactions("pyrimidine_core_biosynthesis")), 18L)
  expect_equal(
    get_gift_anchors("guanylate_biosynthesis")$anchor_id,
    c("IMP", "GMP")
  )
  expect_equal(
    get_gift_reactions("guanylate_biosynthesis")$rhea_master,
    c("RHEA:11708", "RHEA:11680")
  )
  expect_equal(
    get_gift_anchors("cytidylate_biosynthesis")$anchor_id,
    c("UTP", "CTP")
  )
  expect_equal(
    get_gift_reactions("cytidylate_biosynthesis")$rhea_master,
    "RHEA:26426"
  )
  descriptions <- stats::setNames(gifts$description, gifts$gift_id)
  expect_match(descriptions[["purine_core_biosynthesis"]], "purine salvage", fixed = TRUE)
  expect_match(descriptions[["adenylate_biosynthesis"]], "energy transfer", fixed = TRUE)
  expect_match(
    descriptions[["guanylate_biosynthesis"]],
    "GTP-dependent cellular processes",
    fixed = TRUE
  )
  expect_match(
    descriptions[["pyrimidine_core_biosynthesis"]],
    "activated-sugar metabolism",
    fixed = TRUE
  )
  expect_match(descriptions[["cytidylate_biosynthesis"]], "phospholipid", fixed = TRUE)
  expect_equal(get_reaction(15753)$rhea_master, "RHEA:15753")
  expect_equal(
    sort(unique(get_reaction_systems("RHEA:17129")$system_id)),
    c("SYS_17129_DIMER", "SYS_17129_LARGE", "SYS_17129_TRIMER")
  )
  expect_equal(
    sort(unique(get_reaction_systems("RHEA:18633")$system_id)),
    c("SYS_18633_HETERODIMER", "SYS_18633_MONOMER")
  )
})

test_that("database and schema versions are independent", {
  version <- gifter_db_version()
  expect_equal(version$package_version, "0.4.1")
  expect_equal(version$gifter_db_version, "2026.21.3")
  expect_equal(version$schema_version, 7L)
  expect_equal(version$rhea_release, "141")
})

test_that("database HTML atlas is self-contained and reflects compiled rows", {
  output <- tempfile(fileext = ".html")
  on.exit(unlink(output), add = TRUE)

  path <- write_gifter_database_html(output)
  html <- paste(readLines(path, warn = FALSE), collapse = "\n")

  expect_true(file.exists(path))
  expect_match(html, "gifter reference atlas", fixed = TRUE)
  expect_match(html, '<span class="brand-mark" aria-hidden="true"><svg', fixed = TRUE)
  expect_match(html, '<b>gift<span>er</span></b>', fixed = TRUE)
  expect_match(html, 'aria-label="Site sections"', fixed = TRUE)
  expect_match(
    html,
    'href="https://alberdilab.github.io/gifter/reference/index.html">Reference</a>',
    fixed = TRUE
  )
  expect_match(
    html,
    '<details class="site-menu"><summary class="site-nav-link">Articles</summary>',
    fixed = TRUE
  )
  tutorial_positions <- vapply(
    c(
      "1. Evaluating a genome",
      "2. From calls to quantitative traits",
      "3. A genome-resolved community"
    ),
    function(title) regexpr(title, html, fixed = TRUE)[[1]],
    integer(1)
  )
  expect_true(all(tutorial_positions > 0L))
  expect_true(all(diff(tutorial_positions) > 0L))
  expect_match(html, 'aria-current="page">GIFT atlas</a>', fixed = TRUE)
  expect_match(html, 'aria-label="Atlas sections"', fixed = TRUE)
  expect_match(
    html,
    '<button class="nav-button" data-view-button="universes">Reference universes</button>',
    fixed = TRUE
  )
  expect_match(html, "Choose a reference universe", fixed = TRUE)
  universe_cards <- regmatches(
    html,
    gregexpr('<article class="universe-card[^>]* data-universe-card', html)
  )[[1]]
  expect_length(universe_cards, 19L)
  expect_match(html, 'data-universe-filter="genome"', fixed = TRUE)
  expect_match(html, 'data-universe-filter="community"', fixed = TRUE)
  expect_match(html, 'data-universe-filter="network"', fixed = TRUE)
  expect_match(html, 'data-universe-filter="bounded"', fixed = TRUE)
  expect_match(
    html,
    'gift_universe(preset = &quot;carbohydrate_degradation&quot;)',
    fixed = TRUE
  )
  expect_match(html, "Count complete curated carbohydrate-degradation capabilities.", fixed = TRUE)
  expect_match(html, "bounded &middot; coverage valid", fixed = TRUE)
  expect_match(html, "function filterUniverses", fixed = TRUE)
  expect_match(html, "GIFT explorer", fixed = TRUE)
  expect_match(html, "purine_core_biosynthesis", fixed = TRUE)
  expect_match(html, "reference_universe", fixed = TRUE)
  expect_match(html, "carbohydrate_degradation", fixed = TRUE)
  expect_match(html, "guanylate_biosynthesis", fixed = TRUE)
  expect_match(html, "cytidylate_biosynthesis", fixed = TRUE)
  expect_match(html, "RHEA:14905", fixed = TRUE)
  expect_match(html, "K00764", fixed = TRUE)
  expect_match(html, "gift-summary-table", fixed = TRUE)
  expect_match(html, "data-gift-row", fixed = TRUE)
  expect_match(html, "data-gift-detail", fixed = TRUE)
  expect_match(html, "data-table-panel", fixed = TRUE)
  expect_match(html, "data-gift-modal", fixed = TRUE)
  expect_match(html, "data-gift-group-select", fixed = TRUE)
  expect_match(html, 'data-gift-anchor-filter="input"', fixed = TRUE)
  expect_match(html, 'data-gift-anchor-filter="output"', fixed = TRUE)
  expect_match(html, 'data-gift-combo="input"', fixed = TRUE)
  expect_match(html, 'role="combobox"', fixed = TRUE)
  expect_match(html, 'data-value="STARCH"', fixed = TRUE)
  expect_match(html, 'data-search="starch starch"', fixed = TRUE)
  # The atlas groups by the substrate_class facet, which replaced the former
  # free-text category column.
  expect_match(html, 'data-substrate-class="monosaccharide"', fixed = TRUE)
  # Process grouping is the biosynthesis/degradation axis; it must stay
  # reachable in the report, not only in the API.
  expect_match(html, 'data-mode="transport"', fixed = TRUE)
  expect_match(html, '<option value="mode">Process</option>', fixed = TRUE)
  # Substrate class and process are independent axes, so the report must offer
  # both grouping selects: their combination is what the fused `category`
  # label used to provide.
  expect_match(html, "data-gift-group-select>", fixed = TRUE)
  expect_match(html, "data-gift-group-select-2>", fixed = TRUE)
  expect_equal(
    lengths(regmatches(html, gregexpr('value="substrate-class"', html, fixed = TRUE))),
    2L
  )
  # A second axis nests inside the first rather than producing a combined
  # label, so the report ships the level styling the subgroup headers need.
  expect_match(html, '[data-gift-group-level="2"]', fixed = TRUE)
  expect_match(html, "function ancestorCollapsed", fixed = TRUE)
  expect_match(html, 'data-inputs=" STARCH "', fixed = TRUE)
  expect_match(html, 'data-outputs=" GLUCOSE "', fixed = TRUE)
  detail_tags <- regmatches(html, gregexpr('<article class="gift-detail"[^>]*>', html))[[1]]
  expect_gt(length(detail_tags), 0L)
  expect_true(all(grepl(" hidden>$", detail_tags)))
  expect_false(grepl('<link[^>]+rel=["\']stylesheet', html))
  expect_false(grepl('<script[^>]+src=', html))
})

test_that("every metabolic GIFT gets a route network bounded by its declared anchors", {
  db <- gifter_db_connect()
  on.exit(gifter_db_disconnect(db), add = TRUE)
  data <- gifter:::.gifter_report_data(db)

  for (gift_id in data$gifts$gift_id[data$gifts$gift_type == "metabolic"]) {
    anchors <- data$anchors[data$anchors$gift_id == gift_id, , drop = FALSE]
    svg <- gifter:::.report_gift_network_svg(
      gift_id,
      anchors[anchors$role == "input", , drop = FALSE],
      anchors[anchors$role == "output", , drop = FALSE],
      data,
      paste0("arrow-", gift_id)
    )

    # Reactions are drawn by their stable identifier, which polymer chemistry
    # carries in place of a Rhea master.
    reactions <- unique(data$route_reactions$reaction_id[
      data$route_reactions$route_id %in% data$routes$route_id[data$routes$gift_id == gift_id]
    ])
    for (reaction_id in reactions) expect_match(svg, reaction_id, fixed = TRUE)
    for (anchor_id in anchors$anchor_id) expect_match(svg, paste0(">", anchor_id, "<"), fixed = TRUE)

    # Every drawn node is either a declared anchor or a route reaction, so the
    # network can never imply a boundary that curation did not declare.
    nodes <- regmatches(svg, gregexpr('class="graph-node[^"]*"', svg))[[1]]
    expect_equal(
      length(nodes),
      length(reactions) + nrow(anchors)
    )
  }
})

test_that("the merged route network overlays alternative routes on shared reactions", {
  db <- gifter_db_connect()
  on.exit(gifter_db_disconnect(db), add = TRUE)
  data <- gifter:::.gifter_report_data(db)
  anchors <- data$anchors[data$anchors$gift_id == "purine_core_biosynthesis", , drop = FALSE]

  svg <- gifter:::.report_gift_network_svg(
    "purine_core_biosynthesis",
    anchors[anchors$role == "input", , drop = FALSE],
    anchors[anchors$role == "output", , drop = FALSE],
    data,
    "arrow-purine"
  )

  # Reactions shared by all eight routes are drawn once, and the branchpoints
  # that separate route alternatives report partial usage.
  expect_match(svg, "used by 8 of 8 routes", fixed = TRUE)
  expect_match(svg, "used by 4 of 8 routes", fixed = TRUE)
  expect_match(svg, "\u2190 reverse", fixed = TRUE)
  expect_false(grepl("PRA<", svg, fixed = TRUE))
  expect_false(grepl("AICAR<", svg, fixed = TRUE))
})

test_that("the anchor network links GIFTs only through declared anchors", {
  db <- gifter_db_connect()
  on.exit(gifter_db_disconnect(db), add = TRUE)
  data <- gifter:::.gifter_report_data(db)

  svg <- gifter:::.report_anchor_network_svg(data)
  # The trailing space keeps the `dot-nodes` group that holds them out of the
  # count.
  nodes <- regmatches(svg, gregexpr('class="dot-node [^"]*"', svg))[[1]]

  expect_equal(
    length(nodes),
    length(unique(data$anchors$anchor_id)) + nrow(data$gifts)
  )
  # An anchor is drawn as shared exactly when it is both an output of one GIFT
  # and an input of another, which is the only way GIFTs may connect.
  shared <- unique(data$graph$shared_anchor)
  expect_equal(sum(grepl("anchor shared", nodes, fixed = TRUE)), length(shared))
  expect_setequal(shared, c(
    "IMP", "ASA", "HOMOSERINE", "SERINE", "CYSTEINE", "XYLOSE_IN", "ARABINOSE_IN",
    "XYLAN", "XYLOSE_EX", "ARABINOSE_EX",
    # The Entner-Doudoroff branchpoint, where both hexuronate heads and the
    # pectate lyase route hand off to the shared lower segment.
    "KDG",
    # Chitin, mucin and pectin saccharification hand their released sugars to
    # the matching catabolic GIFT. These four are shared on compartment-inexact
    # edges only: the sugar is freed outside the cell and consumed inside it,
    # and no transporter evidence licensed splitting the anchor.
    "GLCNAC", "FUCOSE", "NEUAC", "GALACTURONATE",
    # The SCFA layer connects catabolism to fermentation, so central metabolites
    # become shared boundaries for the first time.
    "PYRUVATE", "ACETYL_COA", "ACETATE", "LACTALDEHYDE", "PROPANEDIOL",
    # Both lactate enantiomers are shared, through the racemase: it is what
    # gives propionate_formation_acrylate a producer for its input at last.
    "LACTATE_L", "LACTATE",
    # The vitamin layer shares boundaries only inside itself: the two thiamine
    # moieties, the folate aromatic half, the pyridine mononucleotide that NAD
    # and the cobamide lower loop both consume, and the corrinoid chain.
    "HMP_PP", "THZ_P", "PABA", "QUINOLINATE", "NAMN",
    "COBYRINATE_DIAMIDE", "ADENOSYLCOBINAMIDE_P", "DMB",
    # The isocitrate re-cut gives the oxidative and glyoxylate branches a
    # shared boundary. Malate becomes shared only from the bypass to the
    # existing malolactic capability.
    "ISOCITRATE", "MALATE", "OXOGLUTARATE", "SUCCINATE", "FUMARATE",
    "OXALOACETATE",
    # The shikimate layer supplies a producer for a boundary two GIFTs already
    # consumed, so chorismate becomes shared without a new consumer being added.
    "CHORISMATE",
    # The nitrogen layer shares the ureide chain, the two methylamine
    # intermediates, the taurine it takes up, and the ammonium every
    # deaminating route releases into assimilation.
    "UREA", "ALLANTOIN", "BETAINE", "SARCOSINE", "TAURINE_IN", "AMMONIUM",
    # The aromatic degradation layer shares its funnel intermediates.
    "CATECHOL", "DHPP", "OXOPENTENOATE", "OXOADIPATE", "OXOADIPYL_COA",
    # The amino acid layer is the first content whose members mostly connect to
    # each other: the family entry points that were declared inputs with no
    # producer -- aspartate, glutamine, 2-oxoisovalerate -- now have one, the
    # two branchpoint intermediates the layer cut at are shared by construction,
    # and five amino acids are shared because a catabolic capability consumes
    # what a biosynthetic one makes. Sulfide is shared in the other direction:
    # cysteine desulfidation supplies two GIFTs that had no producer.
    "ASPARTATE", "GLUTAMINE", "GLUTAMATE", "OXOISOVALERATE", "OXOBUTANOATE",
    "MESO_DAP", "ORNITHINE", "THREONINE", "TRYPTOPHAN", "METHIONINE",
    "HISTIDINE", "PROLINE", "ARGININE", "GLYCINE", "SULFIDE",
    # The enterobactin split exposes its reusable catecholate branchpoint.
    "DIHYDROXYBENZOATE_2_3"
  ))
  # The drawn edges are the boundary declarations themselves: one from the GIFT
  # that outputs the anchor, one to the GIFT that takes it as an input.
  expect_match(
    svg,
    'data-edge-from="gift:purine_core_biosynthesis" data-edge-to="anchor:IMP"',
    fixed = TRUE
  )
  expect_match(
    svg,
    'data-edge-from="anchor:IMP" data-edge-to="gift:adenylate_biosynthesis"',
    fixed = TRUE
  )
  expect_false(grepl("GAR", svg, fixed = TRUE))
})

test_that("the overview network is unlabelled dots that carry their own detail", {
  db <- gifter_db_connect()
  on.exit(gifter_db_disconnect(db), add = TRUE)
  data <- gifter:::.gifter_report_data(db)

  network <- gifter:::.report_anchor_network_svg(data)
  # The drawing carries no text at all: every identifier, boundary, and count a
  # reader needs is an attribute the hover card is built from.
  expect_false(grepl("<text", network, fixed = TRUE))
  expect_match(network, 'data-node-gift="purine_core_biosynthesis"', fixed = TRUE)
  expect_match(network, "Out|IMP", fixed = TRUE)

  # Only GIFT dots open a detail. An anchor is a boundary between traits, not a
  # trait, and has nothing of its own to open.
  expect_equal(
    length(regmatches(network, gregexpr("data-node-gift=", network))[[1]]),
    nrow(data$gifts)
  )
})

test_that("the overview network can be coloured by curated metadata", {
  db <- gifter_db_connect()
  on.exit(gifter_db_disconnect(db), add = TRUE)
  data <- gifter:::.gifter_report_data(db)
  network <- gifter:::.report_anchor_network_svg(data)

  # Every dot carries the colour each scheme would paint it, so switching a menu
  # is a repaint rather than a redraw.
  for (family in names(gifter:::.report_dot_schemes)) {
    for (scheme in gifter:::.report_dot_schemes[[family]]) {
      attribute <- paste0("data-fill-", scheme[["key"]], '="')
      expect_true(grepl(attribute, network, fixed = TRUE), info = scheme[["key"]])
      expect_match(
        network, paste0('data-legend="', family, ":", scheme[["key"]], '"'),
        fixed = TRUE
      )
    }
  }

  # The palette is assigned in a fixed order and never cycled: a scheme with
  # more values than slots folds the rest into the unassigned ring instead of
  # inventing an eighth hue.
  fills <- regmatches(network, gregexpr('data-fill-substrate="[^"]*"', network))[[1]]
  used <- setdiff(unique(sub('.*="([^"]*)"$', "\\1", fills)), "")
  expect_lte(length(used), length(gifter:::.report_dot_palette))
  expect_true(all(used %in% gifter:::.report_dot_palette))

  # Uniform is the default, so the drawing opens exactly as it did before any
  # metadata was applied.
  menu <- gifter:::.report_scheme_menu("gift", "Colour GIFTs by")
  expect_match(menu, '<option value="">Uniform</option>', fixed = TRUE)
})

test_that("network markers stay unique across the report", {
  output <- tempfile(fileext = ".html")
  on.exit(unlink(output), add = TRUE)
  html <- paste(readLines(write_gifter_database_html(output), warn = FALSE), collapse = "\n")

  # Each graph defines a matched pair of arrowheads: the forward head every edge
  # uses, and the mirrored head drawn at the start of a bidirectional edge.
  markers <- regmatches(html, gregexpr('<marker id="[^"]+"', html))[[1]]
  expect_equal(length(markers), 2L * (nrow(list_gifts()) + 1L))
  expect_equal(anyDuplicated(markers), 0L)
  expect_equal(sum(grepl('-start"$', markers)), (nrow(list_gifts()) + 1L))
  expect_match(html, 'data-graph-panel="anchors"', fixed = TRUE)
  expect_match(html, "route-network-svg", fixed = TRUE)
})

test_that("the database changelog is curated content linked to GIFTs", {
  changes <- database_changelog()

  expect_gt(nrow(changes), 0L)
  expect_true(all(c(
    "change_id", "released", "changed_at", "layer", "category", "call_effect",
    "summary", "rationale", "evidence", "effect", "gifts"
  ) %in% names(changes)))
  expect_equal(anyDuplicated(changes$change_id), 0L)
  expect_true(all(nzchar(changes$rationale)))
  expect_true(all(changes$call_effect %in% c("broadens", "narrows", "mixed", "none")))
  expect_match(changes$changed_at, "^[0-9]{4}-[0-9]{2}-[0-9]{2}(T[0-9]{2}:[0-9]{2}Z)?$")

  # Newest first, and every biological change names the traits it affects.
  expect_equal(changes$changed_at, sort(changes$changed_at, decreasing = TRUE))
  biological <- changes[!changes$layer %in% c("provenance", "schema"), ]
  expect_true(all(lengths(biological$gifts) > 0L))
  expect_true(all(unlist(biological$gifts) %in% list_gifts()$gift_id))
})

test_that("the changelog can be read from the perspective of one GIFT", {
  pyrimidine <- database_changelog("pyrimidine_core_biosynthesis")
  purine <- database_changelog("purine_core_biosynthesis")

  expect_true(all(vapply(
    pyrimidine$gifts, function(x) "pyrimidine_core_biosynthesis" %in% x, logical(1)
  )))
  expect_true("DBC-20260817-ATCASE-PYRI" %in% pyrimidine$change_id)
  expect_false("DBC-20260817-ATCASE-PYRI" %in% purine$change_id)
  expect_equal(nrow(database_changelog("cytidylate_biosynthesis")), 2L)
  expect_equal(nrow(database_changelog("glycine_biosynthesis")), 1L)
})

test_that("the two curation corrections of release 2026.08.2 are recorded", {
  changes <- database_changelog()
  atcase <- changes[changes$change_id == "DBC-20260817-ATCASE-PYRI", ]
  pyrk <- changes[changes$change_id == "DBC-20260817-DHOD-PYRK", ]

  expect_equal(atcase$released, "2026.08.2")
  expect_equal(atcase$call_effect, "broadens")
  expect_match(atcase$evidence, "7863", fixed = TRUE)
  expect_equal(pyrk$call_effect, "narrows")
  expect_match(pyrk$evidence, "K02823", fixed = TRUE)
})

test_that("changelog sources reject entries without a linked GIFT", {
  source_dir <- file.path(tempfile("gifter-sources-"))
  dir.create(source_dir, recursive = TRUE)
  on.exit(unlink(source_dir, recursive = TRUE), add = TRUE)
  packaged <- system.file("extdata", "database-source", package = "gifter")
  if (!nzchar(packaged)) packaged <- file.path("inst", "extdata", "database-source")
  file.copy(list.files(packaged, full.names = TRUE), source_dir)

  links <- utils::read.delim(file.path(source_dir, "change_gifts.tsv"), colClasses = "character")
  links <- links[links$change_id != "DBC-20260817-ATCASE-PYRI", , drop = FALSE]
  utils::write.table(
    links, file.path(source_dir, "change_gifts.tsv"),
    sep = "\t", quote = FALSE, row.names = FALSE, na = ""
  )

  expect_error(
    validate_gifter_sources(source_dir),
    "must name the GIFTs they affect"
  )
})

test_that("the atlas publishes the changelog linked to GIFT traits", {
  output <- tempfile(fileext = ".html")
  on.exit(unlink(output), add = TRUE)
  html <- paste(readLines(write_gifter_database_html(output), warn = FALSE), collapse = "\n")

  expect_match(html, 'data-view="changelog"', fixed = TRUE)
  expect_match(html, "changelog-table", fixed = TRUE)
  expect_match(html, "Database changelog", fixed = TRUE)
  expect_match(html, "history-section", fixed = TRUE)

  changes <- database_changelog()
  for (id in changes$change_id) expect_match(html, id, fixed = TRUE)
  for (summary in changes$summary) expect_match(html, gifter:::.html_escape(summary), fixed = TRUE)

  links <- regmatches(html, gregexpr('data-gift-link="[^"]+"', html))[[1]]
  expect_equal(
    length(links),
    sum(lengths(changes$gifts))
  )
  expect_true(all(
    paste0('data-gift-link="', unique(unlist(changes$gifts)), '"') %in% links
  ))
})
