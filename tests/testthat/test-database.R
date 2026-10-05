test_that("canonical source tables validate", {
  source_dir <- system.file("extdata", "database-source", package = "gifter")
  report <- validate_gifter_sources(source_dir)

  expect_true(report$valid)
  expect_length(report$errors, 0L)
  expect_equal(
    unname(report$rows[c("gifts", "anchors", "reactions")]), c(163L, 156L, 440L)
  )
  # Every typed model now ships curated content.
  expect_equal(
    unname(report$rows[c("gift_architectures", "gift_circuits", "gift_mechanisms")]),
    c(11L, 5L, 7L)
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
    "component_marker", "gift_xref", "gift_evidence", "database_release",
    "reference_frame", "reference_frame_filter",
    "reference_frame_metric",
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
      "arabinoxylan_debranching", "archaellum", "arginine_biosynthesis",
      "arginine_deiminase_pathway", "asparagine_biosynthesis",
      "aspartate_biosynthesis", "aspartate_chemoreception",
      "aspartate_semialdehyde_biosynthesis", "assimilatory_sulfate_reduction",
      "benzoate_degradation_catechol",
      "beta_lactam_detoxification", "betaine_demethylation",
      "biotin_biosynthesis", "butyrate_formation",
      "carnitine_degradation_trimethylamine", "carnitine_to_betaine",
      "catechol_meta_cleavage", "catechol_ortho_cleavage",
      "chemotaxis_signal_transduction", "chitin_degradation",
      "chloramphenicol_detoxification", "choline_to_betaine",
      "chorismate_biosynthesis",
      "citrate_fermentation", "cobamide_nucleotide_loop_assembly",
      "cobinamide_biosynthesis", "collagen_cleavage",
      "corrin_ring_biosynthesis", "creatinine_degradation",
      "cysteine_biosynthesis_homocysteine", "cysteine_biosynthesis_sulfide",
      "cysteine_degradation_sulfide", "cytidylate_biosynthesis",
      "dap_biosynthesis", "diglucosyl_diacylglycerol_anchored_lipoteichoic_acid",
      "dihydroxybenzoate_biosynthesis",
      "dihydroxyphenylpropanoate_degradation", "dmb_biosynthesis_aerobic",
      "ectoine_biosynthesis", "ectoine_degradation",
      "enterobactin_biosynthesis", "ethanol_formation",
      "flagellar_apparatus",
      "folate_biosynthesis", "fucose_degradation_isomerase",
      "fumarate_oxaloacetate_interconversion", "galactose_degradation_leloir",
      "galacturonate_degradation", "glcnac_degradation",
      "glucuronate_degradation", "glutamate_decarboxylation_gaba",
      "glutamine_biosynthesis", "glycine_biosynthesis",
      "glycine_reduction_stickland", "glyoxylate_bypass", "guanylate_biosynthesis",
      "heme_b_biosynthesis", "histidine_biosynthesis", "histidine_degradation_glutamate",
      "hmp_phosphate_biosynthesis", "homoserine_biosynthesis",
      "hydroxyectoine_biosynthesis",
      "hydroxyphenylpropanoate_hydroxylation",
      "indole_3_acetate_biosynthesis", "isocitrate_to_oxoglutarate",
      "isoleucine_biosynthesis", "kdg_degradation",
      "lactate_formation", "lactate_formation_lactaldehyde",
      "lactate_racemisation", "leucine_biosynthesis",
      "lpt_lipopolysaccharide_export_apparatus",
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
      "rhamnose_degradation", "ribitol_phosphate_wall_teichoic_acid",
      "riboflavin_biosynthesis",
      "salicylate_biosynthesis", "sarcosine_demethylation",
      "serine_biosynthesis", "serine_chemoreception",
      "serine_deamination", "siroheme_biosynthesis",
      "siroheme_to_heme_b", "starch_degradation",
      "succinate_fumarate_interconversion", "superoxide_detoxification",
      "taurine_degradation_sulfoacetaldehyde",
      "taurine_desulfonation_aerobic", "taurine_uptake_abc",
      "thiamine_phosphate_biosynthesis", "thiamine_precursor_salvage",
      "thiazole_phosphate_biosynthesis", "threonine_biosynthesis",
      "threonine_deamination", "tryptophan_biosynthesis",
      "tryptophan_degradation_indole", "type_i_e_crispr_cas_machinery",
      "type_i_restriction_modification", "type_ii_secretion_system",
      "type_iii_secretion_injectisome", "type_iva_pilus",
      "type_vi_secretion_apparatus",
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
  expect_equal(version$package_version, "0.7.3")
  expect_equal(version$gifter_db_version, "2026.39.1")
  expect_equal(version$schema_version, 9L)
  expect_equal(version$source_repository, "https://github.com/alberdilab/gifter")
  expect_equal(version$rhea_release, "142")
})

test_that("release source commits are explicit, exact, and reproducible", {
  commit <- paste(rep("a", 40), collapse = "")
  clean_git <- function(args) {
    if ("rev-parse" %in% args) return(commit)
    character()
  }
  expect_null(.release_source_commit(value = "", git = clean_git))
  expect_identical(.release_source_commit(value = commit, git = clean_git), commit)
  expect_error(
    .release_source_commit(value = "not-a-commit", git = clean_git),
    "full Git commit hash"
  )
  expect_error(
    .release_source_commit(
      value = commit,
      git = function(args) if ("rev-parse" %in% args) sub("a$", "b", commit) else character()
    ),
    "existing full Git commit"
  )
  expect_error(
    .release_source_commit(
      value = commit,
      git = function(args) if ("rev-parse" %in% args) commit else " M inst/schema/gifter.sql"
    ),
    "uncommitted changes"
  )
  expect_error(
    .release_source_commit(
      value = commit,
      git = function(args) {
        if ("rev-parse" %in% args) return(commit)
        if ("diff" %in% args) return(structure(character(), status = 1L))
        character()
      }
    ),
    "differ from GIFTER_SOURCE_COMMIT"
  )

  source_dir <- gifter_source_copy()
  output <- tempfile(fileext = ".sqlite")
  on.exit(unlink(output), add = TRUE)
  expect_error(
    build_gifter_database(source_dir, output, source_commit = "invented"),
    "full Git commit hash"
  )
  build_gifter_database(source_dir, output, source_commit = commit)
  connection <- gifter_db_connect(output)
  on.exit(DBI::dbDisconnect(connection), add = TRUE)
  expect_identical(gifter_db_version(connection)$source_commit, commit)
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
    'href="https://alberdilab.github.io/gifter/articles/evaluating-a-genome.html">Get started</a>',
    fixed = TRUE
  )
  expect_match(
    html,
    '<details class="site-menu"><summary class="site-nav-link">Workflows</summary>',
    fixed = TRUE
  )
  workflow_positions <- vapply(
    c(
      "From calls to quantitative traits",
      "A genome-resolved community",
      "Many samples over one catalogue"
    ),
    function(title) regexpr(title, html, fixed = TRUE)[[1]],
    integer(1)
  )
  expect_true(all(workflow_positions > 0L))
  expect_true(all(diff(workflow_positions) > 0L))
  # The atlas sections live in an Atlas dropdown of the site navigation, not in
  # a bar of their own, and the atlas lands on its introduction.
  expect_match(
    html,
    '<details class="site-menu atlas-menu" data-view-menu><summary class="site-nav-link active" aria-current="page">Atlas</summary>',
    fixed = TRUE
  )
  expect_no_match(html, 'class="view-nav"', fixed = TRUE)
  atlas_positions <- vapply(
    c(
      'data-view-button="introduction">Introduction</button>',
      'data-view-button="frames">Frames</button>',
      'data-view-button="gifts">GIFTs</button>',
      'data-view-button="changelog">Changes</button>',
      '<div class="site-menu-label">Advanced</div>',
      'data-view-button="overview">Network overview</button>',
      'data-view-button="schema">Data model</button>',
      'data-view-button="tables">Tables</button>'
    ),
    function(item) regexpr(item, html, fixed = TRUE)[[1]],
    integer(1)
  )
  expect_true(all(atlas_positions > 0L))
  expect_true(all(diff(atlas_positions) > 0L))
  expect_match(html, '<section class="view active" id="introduction"', fixed = TRUE)
  expect_match(
    html,
    paste0(
      '<main><nav class="breadcrumbs" aria-label="Breadcrumb">',
      '<ol data-breadcrumbs data-home="https://alberdilab.github.io/gifter/">',
      '<li><a href="https://alberdilab.github.io/gifter/">gifter</a></li>',
      '<li><a href="#introduction">Atlas</a></li>',
      '<li aria-current="page">Introduction</li></ol></nav>'
    ),
    fixed = TRUE
  )
  expect_match(html, "<h1>Reference atlas</h1>", fixed = TRUE)
  expect_match(html, 'class="atlas-section" href="#frames"', fixed = TRUE)
  # The introduction's statistics are read from the compiled database, one row
  # per GIFT type over the layers of its own completeness model.
  db <- gifter_db_connect()
  type_counts <- DBI::dbGetQuery(
    db, "SELECT gift_type, COUNT(*) AS n FROM gift GROUP BY gift_type"
  )
  layer_counts <- DBI::dbGetQuery(db, paste(
    "SELECT (SELECT COUNT(*) FROM gift_route) AS routes,",
    "(SELECT COUNT(*) FROM structural_function) AS structural_functions"
  ))
  DBI::dbDisconnect(db)
  metric <- function(count, label) {
    paste0('<div class="metric-card"><strong>', format(count, big.mark = ","),
      "</strong><span>", label, "</span>")
  }
  expect_match(html, metric(sum(type_counts$n), "GIFTs"), fixed = TRUE)
  layer_cell <- function(count, unit) {
    paste0("<td><strong>", format(count, big.mark = ","), "</strong><small>", unit, "</small></td>")
  }
  metabolic_row <- paste0(
    '<tr><th scope="row">Metabolic</th><td><strong>',
    type_counts$n[type_counts$gift_type == "metabolic"], "</strong></td>",
    layer_cell(layer_counts$routes, "routes")
  )
  expect_match(html, metabolic_row, fixed = TRUE)
  expect_match(
    html,
    paste0(
      '<tr><th scope="row">Structural</th><td><strong>',
      type_counts$n[type_counts$gift_type == "structural"], "</strong></td>"
    ),
    fixed = TRUE
  )
  expect_match(html, layer_cell(layer_counts$structural_functions, "functions"), fixed = TRUE)
  expect_match(html, '>How a GIFT is built</a>', fixed = TRUE)
  expect_match(html, '>Glossary</a>', fixed = TRUE)
  expect_match(
    html,
    'href="https://alberdilab.github.io/gifter/reference/index.html">API</a>',
    fixed = TRUE
  )
  expect_match(html, 'aria-label="Atlas sections"', fixed = TRUE)
  expect_match(html, '<section class="view" id="frames"', fixed = TRUE)
  expect_match(html, "<h1>Frames</h1>", fixed = TRUE)
  expect_match(html, "4 of the 19 presets are bounded", fixed = TRUE)
  # Frames are indexed in one table and each one is detailed on its own page,
  # reached at #frames/<frame_id>. Row and page must pair up one to one.
  frame_row_ids <- regmatches(
    html, gregexpr('<tr class="frame-row" data-frame-row data-frame-id="[^"]+"', html)
  )[[1]]
  frame_page_ids <- regmatches(
    html, gregexpr('<article class="frame-page" data-frame-page data-frame-id="[^"]+" hidden>', html)
  )[[1]]
  expect_length(frame_row_ids, 19L)
  expect_identical(
    sub('.*data-frame-id="([^"]+)".*', "\\1", frame_row_ids),
    sub('.*data-frame-id="([^"]+)".*', "\\1", frame_page_ids)
  )
  expect_match(html, '<table class="changelog-table frame-table">', fixed = TRUE)
  expect_match(html, 'data-frame-back>&larr; All frames</button>', fixed = TRUE)
  expect_match(html, 'window.location.hash = "frames/"', fixed = TRUE)
  # A frame page lists the GIFTs the preset resolves to, linked to their detail.
  carbohydrate_page <- regmatches(
    html,
    regexpr('data-frame-id="carbohydrate_degradation" hidden>.*?</article>', html, perl = TRUE)
  )
  carbohydrate_members <- reference_frame(preset = "carbohydrate_degradation")$gift_id
  expect_length(
    regmatches(carbohydrate_page, gregexpr("data-gift-link=", carbohydrate_page))[[1]],
    length(carbohydrate_members)
  )
  expect_match(
    carbohydrate_page,
    paste0('data-gift-link="', carbohydrate_members[[1]], '"'),
    fixed = TRUE
  )
  # Members are listed in the GIFTs view's own table layout, cell for cell.
  expect_match(carbohydrate_page, '<table class="gift-summary-table frame-member-table">', fixed = TRUE)
  explorer_row <- regmatches(html, regexpr(
    paste0('data-gift-row data-search-item data-gift-id="', carbohydrate_members[[1]], '"[^>]*>.*?</tr>'),
    html, perl = TRUE
  ))
  expect_true(grepl(sub("^[^>]*>", "", explorer_row), carbohydrate_page, fixed = TRUE))
  # Every preset label is sentence case, as the table lists them side by side.
  frame_labels <- list_reference_frames()$label
  expect_true(all(grepl("^[A-Z]", frame_labels)), info = paste(frame_labels, collapse = "; "))
  expect_match(html, "<strong>Biomass-essential anabolic GIFTs</strong>", fixed = TRUE)
  expect_match(html, 'data-frame-filter="genome"', fixed = TRUE)
  expect_match(html, 'data-frame-filter="community"', fixed = TRUE)
  expect_match(html, 'data-frame-filter="network"', fixed = TRUE)
  expect_match(html, 'data-frame-filter="bounded"', fixed = TRUE)
  expect_match(
    html,
    'reference_frame(preset = &quot;carbohydrate_degradation&quot;)',
    fixed = TRUE
  )
  expect_match(html, "Count complete curated carbohydrate-degradation capabilities.", fixed = TRUE)
  expect_match(html, "bounded &middot; coverage valid", fixed = TRUE)
  expect_match(html, "function filterFrames", fixed = TRUE)
  expect_match(html, "<h1>GIFTs</h1>", fixed = TRUE)
  expect_match(html, "The catalogue currently contains [0-9]+ metabolic, [0-9]+ structural, [0-9]+ regulatory and [0-9]+ defense GIFTs.")
  expect_match(html, "purine_core_biosynthesis", fixed = TRUE)
  expect_match(html, "reference_frame", fixed = TRUE)
  expect_match(html, "carbohydrate_degradation", fixed = TRUE)
  expect_match(html, "guanylate_biosynthesis", fixed = TRUE)
  expect_match(html, "cytidylate_biosynthesis", fixed = TRUE)
  expect_match(html, "RHEA:14905", fixed = TRUE)
  expect_match(html, "K00764", fixed = TRUE)
  expect_match(html, "gift-summary-table", fixed = TRUE)
  expect_match(html, "data-gift-row", fixed = TRUE)
  expect_match(html, "data-gift-detail", fixed = TRUE)
  expect_match(html, "data-table-panel", fixed = TRUE)
  # Each GIFT has its own page at #gifts/<gift_id>, as each frame does, in
  # place of a dialog over the table: one page per catalogue row.
  expect_no_match(html, "data-gift-modal", fixed = TRUE)
  expect_match(html, '<div class="gift-list" data-gift-list>', fixed = TRUE)
  expect_match(html, '<div class="gift-pages" data-gift-pages hidden>', fixed = TRUE)
  expect_match(html, 'data-gift-back>&larr; All GIFTs</button>', fixed = TRUE)
  expect_match(html, 'window.location.hash = "gifts/" + giftId', fixed = TRUE)
  gift_pages <- regmatches(
    html, gregexpr('<article class="gift-detail gift-page" data-gift-detail data-gift-id="[^"]+"', html)
  )[[1]]
  gift_row_ids <- regmatches(
    html, gregexpr('data-gift-row data-search-item data-gift-id="[^"]+"', html)
  )[[1]]
  expect_length(gift_pages, nrow(list_gifts()))
  expect_identical(
    sub('.*data-gift-id="([^"]+)"', "\\1", gift_pages),
    sub('.*data-gift-id="([^"]+)"', "\\1", gift_row_ids)
  )
  # The same type-scoped class facet must label both the catalogue row and its
  # detail page, including the regulatory and defense types.
  classes <- c(
    purine_core_biosynthesis = "nucleotide",
    flagellar_apparatus = "cell_surface_appendage",
    chemotaxis_signal_transduction = "chemosensory_pathway",
    type_i_restriction_modification = "restriction_modification",
    type_i_e_crispr_cas_machinery = "crispr_cas",
    mercury_detoxification = "chemical_detoxification"
  )
  for (id in names(classes)) {
    row <- regmatches(html, regexpr(
      paste0('(?s)<tr class="gift-table-row"[^>]*data-gift-id="', id, '".*?</tr>'),
      html, perl = TRUE
    ))
    detail <- regmatches(html, regexpr(
      paste0('(?s)<article class="gift-detail gift-page"[^>]*data-gift-id="',
             id, '".*?</header>'),
      html, perl = TRUE
    ))
    expect_match(row, paste0('<span class="category-label">', classes[[id]], '</span>'),
                 fixed = TRUE)
    expect_match(detail, paste0('</span><span>', classes[[id]], '</span>'),
                 fixed = TRUE)
  }
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
  # A change record's own category column is unrelated to the facet rename: the
  # changelog Scope cell pairs the layer with it, never with a GIFT facet.
  expect_match(
    html, '<span class="scope-chip">gift</span><span class="category-chip">addition</span>',
    fixed = TRUE
  )
  expect_no_match(html, '<span class="category-chip">&mdash;</span>', fixed = TRUE)
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
  detail_tags <- regmatches(html, gregexpr('<article class="gift-detail[^"]*"[^>]*>', html))[[1]]
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
    "IMP", "ASA",
    # Siroheme became a shared anchor in database 2026.24.1, when the Ahb route
    # from siroheme to heme b gave the branch a consumer. Until then the edge
    # was absent because no marker separated AhbA from AhbB.
    "SIROHEME",
    # Ectoine became a shared anchor when its two fates were curated: the
    # biosynthesis GIFT outputs it, degradation and hydroxylation consume it.
    "ECTOINE", "HOMOSERINE", "SERINE", "CYSTEINE", "XYLOSE_IN", "ARABINOSE_IN",
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
  # Two entries since database 2026.27.1: the curation that created the GIFT,
  # and the clarification that refused RHEA:15481 a forward direction in a
  # second anabolic GIFT. A decision not to curate is still a decision the
  # changelog has to carry, which is why it names both GIFTs it constrains.
  expect_equal(nrow(database_changelog("glycine_biosynthesis")), 2L)
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
  expect_match(html, "Database changes", fixed = TRUE)
  expect_match(html, "history-section", fixed = TRUE)

  changes <- database_changelog()
  for (id in changes$change_id) expect_match(html, id, fixed = TRUE)
  for (summary in changes$summary) expect_match(html, gifter:::.html_escape(summary), fixed = TRUE)

  # Frame pages link their member GIFTs too, so count within the Changes view.
  changelog <- regmatches(
    html, regexpr('id="changelog" data-view="changelog".*?</table>', html, perl = TRUE)
  )
  links <- regmatches(changelog, gregexpr('data-gift-link="[^"]+"', changelog))[[1]]
  expect_equal(
    length(links),
    sum(lengths(changes$gifts))
  )
  expect_true(all(
    paste0('data-gift-link="', unique(unlist(changes$gifts)), '"') %in% links
  ))

  # One table row and one page per change; nothing expands in place.
  for (id in changes$change_id) {
    expect_match(html, paste0('data-change-row data-change-id="', id, '"'), fixed = TRUE)
    expect_match(html, paste0('data-change-page data-change-id="', id, '"'), fixed = TRUE)
  }
  expect_no_match(html, '<details class="change-detail">', fixed = TRUE)

  # The page carries what the change recorded and the GIFTs it affects.
  change <- changes[1, ]
  page <- regmatches(html, regexpr(
    paste0('data-change-page data-change-id="', change$change_id, '".*?</article>'),
    html, perl = TRUE
  ))
  for (field in c("rationale", "evidence", "effect")) {
    expect_match(page, gifter:::.html_escape(change[[field]]), fixed = TRUE)
  }
  for (gift_id in change$gifts[[1]]) {
    expect_match(page, paste0('data-gift-link="', gift_id, '"'), fixed = TRUE)
  }

  # A GIFT's change history links to the page of each change it lists.
  history <- regmatches(html, regexpr(
    '<div class="history-section">.*?</ol>', html, perl = TRUE
  ))
  expect_match(history, 'href="#changelog/DBC-[A-Z0-9-]+"', perl = TRUE)
})
