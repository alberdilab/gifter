test_that("canonical source tables validate", {
  source_dir <- system.file("extdata", "database-source", package = "giftr")
  report <- validate_giftr_sources(source_dir)

  expect_true(report$valid)
  expect_length(report$errors, 0L)
  expect_equal(unname(report$rows[c("gifts", "anchors", "reactions")]), c(29L, 43L, 91L))
})

test_that("database compilation creates constrained SQLite schema", {
  source_dir <- system.file("extdata", "database-source", package = "giftr")
  output <- tempfile(fileext = ".sqlite")
  on.exit(unlink(output), add = TRUE)

  expect_silent(build_giftr_database(source_dir, output))
  db <- giftr_db_connect(output)
  on.exit(giftr_db_disconnect(db), add = TRUE)

  tables <- DBI::dbListTables(db)
  expect_true(all(c(
    "gift", "anchor", "gift_anchor", "reaction", "gift_route",
    "route_reaction", "enzyme_system", "enzyme_component", "marker",
    "component_marker", "gift_xref", "database_release"
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
})

test_that("source validation rejects duplicate stable IDs", {
  source_dir <- system.file("extdata", "database-source", package = "giftr")
  fixture <- tempfile("giftr-source-")
  dir.create(fixture)
  on.exit(unlink(fixture, recursive = TRUE), add = TRUE)
  expect_true(all(file.copy(list.files(source_dir, full.names = TRUE), fixture)))

  gifts_path <- file.path(fixture, "gifts.tsv")
  gifts <- utils::read.delim(gifts_path, sep = "\t", check.names = FALSE)
  gifts <- rbind(gifts, gifts[1, ])
  utils::write.table(gifts, gifts_path, sep = "\t", quote = FALSE, row.names = FALSE, na = "")

  report <- validate_giftr_sources(fixture, stop_on_error = FALSE)
  expect_false(report$valid)
  expect_true(any(grepl("Duplicated gifts.gift_id", report$errors, fixed = TRUE)))
  expect_error(validate_giftr_sources(fixture), "source validation failed")
})

test_that("foreign key enforcement is enabled on runtime connections", {
  db <- giftr_db_connect()
  on.exit(giftr_db_disconnect(db), add = TRUE)
  expect_equal(DBI::dbGetQuery(db, "PRAGMA foreign_keys")[[1]], 1L)
})

test_that("database accessors return stable definitions", {
  gifts <- list_gifts()
  expect_equal(
    gifts$gift_id,
    c(
      "adenylate_biosynthesis", "arabinose_degradation",
      "arabinose_uptake_abc", "arabinoxylan_debranching",
      "aspartate_semialdehyde_biosynthesis", "collagen_cleavage",
      "cysteine_biosynthesis_homocysteine", "cysteine_biosynthesis_sulfide",
      "cytidylate_biosynthesis",
      "fucose_degradation_isomerase", "galactose_degradation_leloir",
      "galacturonate_degradation", "glcnac_degradation",
      "glucuronate_degradation", "glycine_biosynthesis",
      "guanylate_biosynthesis", "homoserine_biosynthesis",
      "methionine_biosynthesis_sulfhydrylation", "methionine_biosynthesis_transsulfuration",
      "neuac_degradation", "purine_core_biosynthesis",
      "pyrimidine_core_biosynthesis", "rhamnose_degradation",
      "serine_biosynthesis", "starch_degradation",
      "threonine_biosynthesis", "xylan_degradation",
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
  version <- giftr_db_version()
  expect_equal(version$package_version, "0.1.0")
  expect_equal(version$giftr_db_version, "2026.12.1")
  expect_equal(version$schema_version, 5L)
  expect_equal(version$rhea_release, "141")
})

test_that("database HTML atlas is self-contained and reflects compiled rows", {
  output <- tempfile(fileext = ".html")
  on.exit(unlink(output), add = TRUE)

  path <- write_giftr_database_html(output)
  html <- paste(readLines(path, warn = FALSE), collapse = "\n")

  expect_true(file.exists(path))
  expect_match(html, "giftr reference atlas", fixed = TRUE)
  expect_match(html, "GIFT explorer", fixed = TRUE)
  expect_match(html, "purine_core_biosynthesis", fixed = TRUE)
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

test_that("every GIFT gets a route network bounded by its declared anchors", {
  db <- giftr_db_connect()
  on.exit(giftr_db_disconnect(db), add = TRUE)
  data <- giftr:::.giftr_report_data(db)

  for (gift_id in data$gifts$gift_id) {
    anchors <- data$anchors[data$anchors$gift_id == gift_id, , drop = FALSE]
    svg <- giftr:::.report_gift_network_svg(
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
  db <- giftr_db_connect()
  on.exit(giftr_db_disconnect(db), add = TRUE)
  data <- giftr:::.giftr_report_data(db)
  anchors <- data$anchors[data$anchors$gift_id == "purine_core_biosynthesis", , drop = FALSE]

  svg <- giftr:::.report_gift_network_svg(
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
  db <- giftr_db_connect()
  on.exit(giftr_db_disconnect(db), add = TRUE)
  data <- giftr:::.giftr_report_data(db)

  svg <- giftr:::.report_anchor_network_svg(data)
  nodes <- regmatches(svg, gregexpr('class="graph-node[^"]*"', svg))[[1]]

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
    "XYLAN", "XYLOSE_EX", "ARABINOSE_EX"
  ))
  expect_match(svg, "IMP is an output boundary of purine_core_biosynthesis", fixed = TRUE)
  expect_match(svg, "IMP is an input boundary of adenylate_biosynthesis", fixed = TRUE)
  expect_false(grepl("GAR", svg, fixed = TRUE))
})

test_that("network markers stay unique across the report", {
  output <- tempfile(fileext = ".html")
  on.exit(unlink(output), add = TRUE)
  html <- paste(readLines(write_giftr_database_html(output), warn = FALSE), collapse = "\n")

  markers <- regmatches(html, gregexpr('<marker id="[^"]+"', html))[[1]]
  expect_equal(length(markers), nrow(list_gifts()) + 2L)
  expect_equal(anyDuplicated(markers), 0L)
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
  source_dir <- file.path(tempfile("giftr-sources-"))
  dir.create(source_dir, recursive = TRUE)
  on.exit(unlink(source_dir, recursive = TRUE), add = TRUE)
  packaged <- system.file("extdata", "database-source", package = "giftr")
  if (!nzchar(packaged)) packaged <- file.path("inst", "extdata", "database-source")
  file.copy(list.files(packaged, full.names = TRUE), source_dir)

  links <- utils::read.delim(file.path(source_dir, "change_gifts.tsv"), colClasses = "character")
  links <- links[links$change_id != "DBC-20260817-ATCASE-PYRI", , drop = FALSE]
  utils::write.table(
    links, file.path(source_dir, "change_gifts.tsv"),
    sep = "\t", quote = FALSE, row.names = FALSE, na = ""
  )

  expect_error(
    validate_giftr_sources(source_dir),
    "must name the GIFTs they affect"
  )
})

test_that("the atlas publishes the changelog linked to GIFT traits", {
  output <- tempfile(fileext = ".html")
  on.exit(unlink(output), add = TRUE)
  html <- paste(readLines(write_giftr_database_html(output), warn = FALSE), collapse = "\n")

  expect_match(html, 'data-view="changelog"', fixed = TRUE)
  expect_match(html, "changelog-table", fixed = TRUE)
  expect_match(html, "Database changelog", fixed = TRUE)
  expect_match(html, "history-section", fixed = TRUE)

  changes <- database_changelog()
  for (id in changes$change_id) expect_match(html, id, fixed = TRUE)
  for (summary in changes$summary) expect_match(html, giftr:::.html_escape(summary), fixed = TRUE)

  links <- regmatches(html, gregexpr('data-gift-link="[^"]+"', html))[[1]]
  expect_equal(
    length(links),
    sum(lengths(changes$gifts))
  )
  expect_true(all(
    paste0('data-gift-link="', unique(unlist(changes$gifts)), '"') %in% links
  ))
})
