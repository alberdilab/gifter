.gifter_report_tables <- c(
  "gift", "anchor", "gift_anchor", "gift_xref", "gift_route", "route_reaction",
  "reaction", "reaction_xref", "enzyme_system", "enzyme_component",
  "gift_architecture", "architecture_function", "structural_function",
  "structural_system", "structural_component", "structural_component_marker",
  "gift_circuit", "circuit_function", "regulatory_function",
  "regulatory_system", "regulatory_component", "regulatory_component_marker",
  "gift_mechanism", "mechanism_function", "defense_function",
  "defense_system", "defense_component", "defense_component_marker",
  "marker", "component_marker", "reference_universe",
  "reference_universe_filter", "reference_universe_metric",
  "database_change", "change_gift",
  "database_release"
)

.html_escape <- function(value) {
  value <- as.character(value)
  value[is.na(value)] <- ""
  value <- gsub("&", "&amp;", value, fixed = TRUE)
  value <- gsub("<", "&lt;", value, fixed = TRUE)
  value <- gsub(">", "&gt;", value, fixed = TRUE)
  value <- gsub('"', "&quot;", value, fixed = TRUE)
  gsub("'", "&#39;", value, fixed = TRUE)
}

.html_text <- function(value, empty = "&mdash;") {
  if (!length(value) || is.na(value[[1]]) || !nzchar(as.character(value[[1]]))) {
    return(empty)
  }
  .html_escape(value[[1]])
}

.html_search_text <- function(...) {
  value <- unlist(list(...), recursive = TRUE, use.names = FALSE)
  value <- value[!is.na(value)]
  tolower(paste(value, collapse = " "))
}

.gifter_report_asset <- function(name) {
  path <- system.file("templates", name, package = "gifter")
  if (!nzchar(path)) path <- file.path("inst", "templates", name)
  if (!file.exists(path)) stop("Could not locate report asset: ", name, call. = FALSE)
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

.gifter_report_data <- function(connection) {
  available <- DBI::dbListTables(connection)
  missing <- setdiff(.gifter_report_tables, available)
  if (length(missing)) {
    stop(
      "Database is missing report tables: ", paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  tables <- lapply(.gifter_report_tables, function(table) {
    DBI::dbReadTable(connection, table)
  })
  names(tables) <- .gifter_report_tables

  # Each typed machinery model is read through the same six shapes, named
  # generically here because the report renders them identically; the biological
  # names stay on the tables and on the identifiers the report prints.
  machinery <- lapply(.gifter_machinery_models, function(model) {
    query <- function(sql) DBI::dbGetQuery(connection, sql)
    list(
      model = model,
      implementations = query(paste0(
        "SELECT g.gift_id, i.", model$implementation_id, " AS implementation_id, ",
        "i.name, i.description, i.status FROM ", model$implementation_table, " i ",
        "JOIN gift g ON g.gift_pk = i.gift_pk ORDER BY g.gift_id, i.",
        model$implementation_id
      )),
      membership = query(paste0(
        "SELECT i.", model$implementation_id, " AS implementation_id, mf.ordinal, ",
        "mf.required, f.function_id, f.name AS function_name, ",
        "f.description AS function_description FROM ", model$membership_table, " mf ",
        "JOIN ", model$implementation_table, " i ON i.", model$implementation_pk,
        " = mf.", model$implementation_pk, " ",
        "JOIN ", model$function_table, " f ON f.function_pk = mf.function_pk ",
        "ORDER BY i.", model$implementation_id, ", mf.ordinal"
      )),
      functions = query(paste0(
        "SELECT function_id, name, description FROM ", model$function_table,
        " ORDER BY function_id"
      )),
      systems = query(paste0(
        "SELECT f.function_id, s.system_id, s.name, s.description FROM ",
        model$system_table, " s JOIN ", model$function_table,
        " f ON f.function_pk = s.function_pk ORDER BY f.function_id, s.system_id"
      )),
      components = query(paste0(
        "SELECT s.system_id, c.component_id, c.name, c.description FROM ",
        model$component_table, " c JOIN ", model$system_table,
        " s ON s.system_pk = c.system_pk ORDER BY s.system_id, c.component_id"
      )),
      markers = query(paste0(
        "SELECT c.component_id, m.namespace, m.accession, m.name, ",
        "e.evidence_type, e.confidence, e.source, e.notes FROM ",
        model$evidence_table, " e JOIN ", model$component_table,
        " c ON c.component_pk = e.component_pk ",
        "JOIN marker m ON m.marker_pk = e.marker_pk ",
        "ORDER BY c.component_id, m.namespace, m.accession"
      ))
    )
  })

  queries <- list(
    gifts = paste(
      "SELECT g.* ,",
      "(SELECT value FROM gift_facet gf WHERE gf.gift_pk = g.gift_pk",
      " AND gf.facet = 'substrate_class') AS substrate_class,",
      "(SELECT GROUP_CONCAT(value, ', ') FROM gift_facet gf WHERE gf.gift_pk = g.gift_pk",
      " AND gf.facet = 'physiological_role') AS physiological_role,",
      "(SELECT COUNT(*) FROM gift_route gr WHERE gr.gift_pk = g.gift_pk) AS route_count,",
      "(SELECT COUNT(DISTINCT rr.reaction_pk) FROM gift_route gr",
      " JOIN route_reaction rr ON rr.route_pk = gr.route_pk",
      " WHERE gr.gift_pk = g.gift_pk) AS reaction_count",
      "FROM gift g ORDER BY g.gift_id"
    ),
    anchors = paste(
      "SELECT g.gift_id, ga.role, ga.ordinal, a.anchor_id, a.molecule, a.compartment,",
      "a.name, a.chebi_id, a.description",
      "FROM gift g JOIN gift_anchor ga ON ga.gift_pk = g.gift_pk",
      "JOIN anchor a ON a.anchor_pk = ga.anchor_pk",
      "ORDER BY g.gift_id, CASE ga.role WHEN 'input' THEN 1 ELSE 2 END, ga.ordinal"
    ),
    gift_pathways = paste(
      "SELECT g.gift_id, gx.namespace, gx.accession, gx.name, gx.relation, gx.notes",
      "FROM gift g JOIN gift_xref gx ON gx.gift_pk = g.gift_pk",
      "ORDER BY g.gift_id, gx.namespace, gx.accession"
    ),
    # Every curated facet, not just the two the summary table groups by, so the
    # detail page shows the whole annotation a GIFT carries.
    gift_facets = paste(
      "SELECT g.gift_id, gf.facet, gf.value, gf.notes, ft.definition",
      "FROM gift g JOIN gift_facet gf ON gf.gift_pk = g.gift_pk",
      "LEFT JOIN facet_term ft ON ft.facet = gf.facet AND ft.value = gf.value",
      "ORDER BY g.gift_id, gf.facet, gf.value"
    ),
    # Anchor facets are what the overview network can colour a boundary by.
    anchor_facets = paste(
      "SELECT a.anchor_id, af.facet, af.value",
      "FROM anchor a JOIN anchor_facet af ON af.anchor_pk = a.anchor_pk",
      "ORDER BY a.anchor_id, af.facet, af.value"
    ),
    routes = paste(
      "SELECT g.gift_id, gr.route_pk, gr.route_id, gr.name, gr.description, gr.status,",
      "COUNT(rr.reaction_pk) AS reaction_count,",
      "SUM(CASE WHEN rr.required = 1 THEN 1 ELSE 0 END) AS required_count",
      "FROM gift g JOIN gift_route gr ON gr.gift_pk = g.gift_pk",
      "LEFT JOIN route_reaction rr ON rr.route_pk = gr.route_pk",
      "GROUP BY gr.route_pk ORDER BY g.gift_id, gr.route_id"
    ),
    route_reactions = paste(
      "SELECT gr.route_id, rr.step_order, rr.required, rr.orientation,",
      "r.reaction_pk, r.reaction_id, r.rhea_master, r.name, r.description",
      "FROM gift_route gr JOIN route_reaction rr ON rr.route_pk = gr.route_pk",
      "JOIN reaction r ON r.reaction_pk = rr.reaction_pk",
      "ORDER BY gr.route_id, rr.step_order"
    ),
    systems = paste(
      "SELECT r.reaction_id, r.rhea_master, es.system_pk, es.system_id, es.name, es.description,",
      "COUNT(DISTINCT ec.component_pk) AS component_count,",
      "COUNT(DISTINCT cm.marker_pk) AS marker_count",
      "FROM reaction r JOIN enzyme_system es ON es.reaction_pk = r.reaction_pk",
      "LEFT JOIN enzyme_component ec ON ec.system_pk = es.system_pk",
      "LEFT JOIN component_marker cm ON cm.component_pk = ec.component_pk",
      "GROUP BY es.system_pk ORDER BY r.reaction_id, es.system_id"
    ),
    components = paste(
      "SELECT es.system_id, ec.component_pk, ec.component_id, ec.name, ec.description",
      "FROM enzyme_system es JOIN enzyme_component ec ON ec.system_pk = es.system_pk",
      "ORDER BY es.system_id, ec.component_id"
    ),
    component_markers = paste(
      "SELECT ec.component_id, m.namespace, m.accession, m.name, m.description,",
      "cm.evidence_type, cm.confidence, cm.source, cm.notes",
      "FROM enzyme_component ec",
      "JOIN component_marker cm ON cm.component_pk = ec.component_pk",
      "JOIN marker m ON m.marker_pk = cm.marker_pk",
      "ORDER BY ec.component_id, m.namespace, m.accession"
    ),
    changes = paste(
      "SELECT change_id, released, changed_at, layer, category, call_effect,",
      "summary, rationale, evidence, effect FROM database_change",
      "ORDER BY changed_at DESC, change_id"
    ),
    change_gifts = paste(
      "SELECT c.change_id, g.gift_id, g.name FROM change_gift cg",
      "JOIN database_change c ON c.change_pk = cg.change_pk",
      "JOIN gift g ON g.gift_pk = cg.gift_pk",
      "ORDER BY c.change_id, g.gift_id"
    ),
    graph = paste(
      "SELECT from_gift, shared_anchor, to_anchor, shared_molecule, edge_quality, to_gift",
      "FROM gift_graph ORDER BY from_gift, to_gift"
    ),
    xrefs = paste(
      "SELECT r.reaction_id, rx.namespace, rx.accession",
      "FROM reaction r LEFT JOIN reaction_xref rx ON rx.reaction_pk = r.reaction_pk",
      "ORDER BY r.reaction_id, rx.namespace, rx.accession"
    )
  )
  values <- lapply(queries, function(sql) DBI::dbGetQuery(connection, sql))

  schema <- lapply(.gifter_report_tables, function(table) {
    columns <- DBI::dbGetQuery(
      connection,
      paste0("PRAGMA table_info('", gsub("'", "''", table, fixed = TRUE), "')")
    )
    foreign_keys <- DBI::dbGetQuery(
      connection,
      paste0("PRAGMA foreign_key_list('", gsub("'", "''", table, fixed = TRUE), "')")
    )
    list(table = table, columns = columns, foreign_keys = foreign_keys)
  })
  names(schema) <- .gifter_report_tables

  c(
    values,
    list(
      machinery = machinery,
      universes = list_gift_universes(db = connection),
      tables = tables,
      schema = schema,
      release = tables$database_release[1, , drop = FALSE],
      counts = vapply(tables, nrow, integer(1))
    )
  )
}

# `role` overrides the declared role for display only. An interconversion GIFT
# declares both, so colouring one boundary as an input and the other as an
# output would re-assert the direction the bidirectional arrow just removed.
.report_anchor_badges <- function(rows, role = NULL) {
  if (!nrow(rows)) return('<span class="empty-state">None declared</span>')
  paste(vapply(seq_len(nrow(rows)), function(index) {
    row <- rows[index, , drop = FALSE]
    if (!is.null(role)) row$role <- role
    chebi <- if (!is.na(row$chebi_id) && nzchar(row$chebi_id)) {
      paste0(" &middot; ", .html_escape(row$chebi_id))
    } else {
      ""
    }
    paste0(
      '<span class="anchor-chip ', .html_escape(row$role), '" title="',
      .html_escape(row$name), chebi, '">', .html_escape(row$anchor_id), "</span>"
    )
  }, character(1)), collapse = "")
}

.report_marker_rows <- function(rows) {
  if (!nrow(rows)) return('<div class="empty-state compact">No accepted markers</div>')
  paste(vapply(seq_len(nrow(rows)), function(index) {
    row <- rows[index, , drop = FALSE]
    paste0(
      '<div class="marker-row">',
      '<span class="marker-accession"><span class="namespace">',
      .html_text(row$namespace), '</span>', .html_text(row$accession), "</span>",
      '<span class="marker-name">', .html_text(row$name), "</span>",
      '<span class="confidence">', .html_text(row$confidence), "</span>",
      "</div>"
    )
  }, character(1)), collapse = "")
}

.report_component_rows <- function(system_id, data) {
  rows <- data$components[data$components$system_id == system_id, , drop = FALSE]
  if (!nrow(rows)) return('<div class="empty-state compact">No components</div>')
  paste(vapply(seq_len(nrow(rows)), function(index) {
    row <- rows[index, , drop = FALSE]
    markers <- data$component_markers[
      data$component_markers$component_id == row$component_id, , drop = FALSE
    ]
    paste0(
      '<div class="component-block">',
      '<div class="component-head"><span class="logic-token and">AND</span><div>',
      '<div class="entity-id">', .html_text(row$component_id), "</div>",
      '<div class="entity-name">', .html_text(row$name), "</div></div></div>",
      '<div class="component-description">', .html_text(row$description), "</div>",
      '<div class="or-label">Accepted markers <span>OR</span></div>',
      .report_marker_rows(markers),
      "</div>"
    )
  }, character(1)), collapse = "")
}

# Chemistry without a Rhea master, such as polymer hydrolysis, is identified by
# its curated reaction_id and has nothing to link to.
.reaction_id_html <- function(row) {
  if (!is.na(row$rhea_master) && nzchar(row$rhea_master)) {
    paste0(
      '<a class="rhea-id" href="https://www.rhea-db.org/rhea/',
      sub("^RHEA:", "", row$rhea_master), '" target="_blank" rel="noreferrer">',
      .html_text(row$rhea_master), "</a>"
    )
  } else {
    paste0('<span class="rhea-id">', .html_text(row$reaction_id), "</span>")
  }
}

.report_system_rows <- function(reaction_id, data) {
  rows <- data$systems[data$systems$reaction_id == reaction_id, , drop = FALSE]
  if (!nrow(rows)) return('<div class="empty-state compact">No enzyme systems</div>')
  paste(vapply(seq_len(nrow(rows)), function(index) {
    row <- rows[index, , drop = FALSE]
    paste0(
      '<details class="system-block">',
      '<summary><span class="logic-token or">OR</span><span class="summary-main">',
      '<span class="entity-id">', .html_text(row$system_id), "</span>",
      '<span class="entity-name">', .html_text(row$name), "</span></span>",
      '<span class="mini-count">', row$component_count, " component",
      if (row$component_count == 1L) "" else "s", " &middot; ", row$marker_count, " marker",
      if (row$marker_count == 1L) "" else "s", "</span></summary>",
      '<div class="system-body"><p>', .html_text(row$description), "</p>",
      .report_component_rows(row$system_id, data), "</div></details>"
    )
  }, character(1)), collapse = "")
}

.report_reaction_rows <- function(route_id, data) {
  rows <- data$route_reactions[data$route_reactions$route_id == route_id, , drop = FALSE]
  if (!nrow(rows)) return('<div class="empty-state compact">No reactions</div>')
  paste(vapply(seq_len(nrow(rows)), function(index) {
    row <- rows[index, , drop = FALSE]
    xrefs <- data$xrefs[
      data$xrefs$reaction_id == row$reaction_id & !is.na(data$xrefs$namespace), , drop = FALSE
    ]
    xref_html <- if (nrow(xrefs)) paste(vapply(seq_len(nrow(xrefs)), function(x) {
      paste0(
        '<span class="xref">', .html_text(xrefs$namespace[x]), ":",
        .html_text(xrefs$accession[x]), "</span>"
      )
    }, character(1)), collapse = "") else ""
    required <- if (identical(as.integer(row$required), 1L)) "required" else "optional"
    paste0(
      '<li class="reaction-block">',
      '<div class="reaction-rail"><span class="step-number">', row$step_order,
      '</span><span class="rail-line"></span></div>',
      '<div class="reaction-content"><div class="reaction-head">',
      "<div>", .reaction_id_html(row), "<h5>", .html_text(row$name), "</h5></div>",
      '<div class="reaction-flags"><span class="direction">',
      if (identical(row$orientation, "reverse")) "&larr; reverse" else "forward &rarr;",
      '</span><span class="requirement ', required, '">', required, "</span></div></div>",
      '<p class="reaction-description">', .html_text(row$description), "</p>",
      if (nzchar(xref_html)) paste0('<div class="xref-list">', xref_html, "</div>") else "",
      '<details class="evidence-block"><summary>Enzyme evidence <span>',
      sum(data$systems$reaction_id == row$reaction_id), " system",
      if (sum(data$systems$reaction_id == row$reaction_id) == 1L) "" else "s",
      "</span></summary><div class=\"evidence-body\">",
      .report_system_rows(row$reaction_id, data), "</div></details>",
      "</div></li>"
    )
  }, character(1)), collapse = "")
}

.report_route_cards <- function(gift_id, data) {
  rows <- data$routes[data$routes$gift_id == gift_id, , drop = FALSE]
  if (!nrow(rows)) return('<div class="empty-state">No routes</div>')
  paste(vapply(seq_len(nrow(rows)), function(index) {
    row <- rows[index, , drop = FALSE]
    paste0(
      '<details class="route-card">',
      '<summary><span class="route-number">', sprintf("%02d", index), "</span>",
      '<span class="summary-main"><span class="entity-name">', .html_text(row$name), "</span>",
      '<span class="entity-id">', .html_text(row$route_id), "</span></span>",
      '<span class="route-meta"><span class="status-dot"></span>', .html_text(row$status),
      " &middot; ", row$required_count, " reaction", if (row$required_count == 1L) "" else "s",
      "</span></summary>",
      '<div class="route-body"><p class="route-description">', .html_text(row$description), "</p>",
      '<ol class="reaction-list">', .report_reaction_rows(row$route_id, data), "</ol></div>",
      "</details>"
    )
  }, character(1)), collapse = "")
}

.report_facet_label <- function(facet) {
  label <- gsub("_", " ", facet, fixed = TRUE)
  paste0(toupper(substr(label, 1L, 1L)), substr(label, 2L, nchar(label)))
}

.report_mode_blurb <- c(
  anabolic = "Builds the output molecules from the input molecules.",
  catabolic = "Breaks the input molecules down towards the output molecules.",
  transport = "Moves a molecule across a compartment boundary.",
  interconversion = "Converts between metabolites without a net build or breakdown."
)

# The curated annotation of a GIFT lives in two places: fixed columns on the
# gift row and free facets in `gift_facet`. Both are shown here, and the facet
# groups are read from the data rather than named, so a facet added to the
# vocabulary appears without touching the report.
.report_gift_metadata <- function(gift, data) {
  entries <- character(0)
  if (!is.na(gift$mode) && nzchar(gift$mode)) {
    blurb <- unname(.report_mode_blurb[gift$mode])
    if (is.na(blurb)) blurb <- ""
    entries <- paste0(
      '<div class="metadata-entry"><dt>Process</dt><dd>',
      '<span class="metadata-chip" title="', .html_escape(blurb), '">',
      .html_escape(gift$mode), "</span></dd></div>"
    )
  }

  facets <- data$gift_facets[data$gift_facets$gift_id == gift$gift_id, , drop = FALSE]
  for (facet in unique(facets$facet)) {
    rows <- facets[facets$facet == facet, , drop = FALSE]
    chips <- paste(vapply(seq_len(nrow(rows)), function(index) {
      row <- rows[index, , drop = FALSE]
      tip <- c(
        if (!is.na(row$definition) && nzchar(row$definition)) row$definition,
        if (!is.na(row$notes) && nzchar(row$notes)) row$notes
      )
      paste0(
        '<span class="metadata-chip" title="',
        .html_escape(paste(tip, collapse = " \u2014 ")), '">',
        .html_escape(row$value), "</span>"
      )
    }, character(1)), collapse = "")
    entries <- c(
      entries,
      paste0(
        '<div class="metadata-entry"><dt>', .html_escape(.report_facet_label(facet)),
        "</dt><dd>", chips, "</dd></div>"
      )
    )
  }

  entries <- c(
    entries,
    paste0(
      '<div class="metadata-entry"><dt>Status</dt><dd><span class="metadata-chip">',
      .html_text(gift$status), "</span></dd></div>",
      '<div class="metadata-entry"><dt>Version</dt><dd><span class="metadata-chip">',
      .html_text(gift$version), "</span></dd></div>"
    )
  )

  paste0(
    '<div class="metadata-section"><h4>Metadata</h4>',
    '<p class="network-caption">Curated annotation of this GIFT. Hover a value for ',
    'its vocabulary definition.</p>',
    '<dl class="metadata-grid">', paste(entries, collapse = ""), "</dl></div>"
  )
}

.report_relation_phrase <- c(
  equivalent = "is equivalent to",
  subset_of = "is part of",
  superset_of = "covers all of",
  overlaps = "partly overlaps",
  related = "is related to"
)

# External pathways are shown with the relation spelled out, because a GIFT is
# curated between declared anchors and is almost never the same thing as the
# pathway record a reader arrives from.
.report_gift_pathways <- function(gift_id, data) {
  rows <- data$gift_pathways[data$gift_pathways$gift_id == gift_id, , drop = FALSE]
  if (!nrow(rows)) return("")
  entries <- paste(vapply(seq_len(nrow(rows)), function(index) {
    row <- rows[index, , drop = FALSE]
    phrase <- .report_relation_phrase[[row$relation]]
    notes <- if (!is.na(row$notes) && nzchar(row$notes)) {
      paste0('<p class="pathway-note">', .html_escape(row$notes), "</p>")
    } else {
      ""
    }
    paste0(
      '<li class="pathway-entry" data-pathway-accession="', .html_escape(row$accession), '">',
      '<div class="pathway-head">',
      '<span class="marker-accession"><span class="namespace">',
      .html_text(row$namespace), "</span>", .html_text(row$accession), "</span>",
      '<span class="pathway-relation ', .html_escape(row$relation), '">',
      .html_escape(phrase), "</span></div>",
      '<div class="pathway-name">', .html_text(row$name), "</div>", notes, "</li>"
    )
  }, character(1)), collapse = "")
  paste0(
    '<div class="pathway-section"><h4>Related pathways <span>',
    nrow(rows), " reference", if (nrow(rows) == 1L) "" else "s",
    '</span></h4><p class="network-caption">A GIFT is a curated capability between ',
    'declared anchors, not a pathway record. Each reference states how the curated ',
    'boundaries compare with the external definition.</p>',
    '<ul class="pathway-list">', entries, "</ul></div>"
  )
}

# Every declared anchor of one role, so the reader can ask which GIFTs start
# from a molecule or end at one without knowing which GIFT holds it. Anchor
# names repeat across compartments, so each option carries its anchor id too.
.report_anchor_combo <- function(data, role, label, placeholder) {
  rows <- data$anchors[data$anchors$role == role, c("anchor_id", "name"), drop = FALSE]
  rows <- rows[!duplicated(rows$anchor_id), , drop = FALSE]
  rows <- rows[order(rows$anchor_id), , drop = FALSE]
  field_id <- paste0("gift-anchor-", role)

  options <- paste(vapply(seq_len(nrow(rows)), function(index) {
    anchor_id <- rows$anchor_id[index]
    name <- rows$name[index]
    if (is.na(name) || !nzchar(name)) name <- anchor_id
    option_label <- if (identical(name, anchor_id)) anchor_id else paste0(name, " \u00b7 ", anchor_id)
    paste0(
      '<li class="combo-option" role="option" id="', field_id, "-option-", index,
      '" data-value="', .html_escape(anchor_id),
      '" data-label="', .html_escape(option_label),
      '" data-search="', .html_escape(tolower(paste(name, anchor_id))),
      '" aria-selected="false"><strong>', .html_escape(name),
      "</strong><small>", .html_escape(anchor_id), "</small></li>"
    )
  }, character(1)), collapse = "")

  paste0(
    '<div class="gift-control gift-combo" data-gift-combo="', role, '">',
    '<label class="gift-control-label" for="', field_id, '">', label, "</label>",
    '<div class="combo-field"><input type="text" id="', field_id, '" class="combo-input" ',
    'role="combobox" aria-expanded="false" aria-autocomplete="list" aria-controls="',
    field_id, '-list" autocomplete="off" placeholder="', placeholder,
    '" data-gift-combo-input>',
    '<button type="button" class="combo-clear" data-gift-combo-clear aria-label="Clear ',
    tolower(label), '" hidden>&times;</button></div>',
    '<ul class="combo-list" id="', field_id, '-list" role="listbox" aria-label="', label,
    '" hidden>', options,
    '<li class="combo-empty" data-combo-empty hidden>No matching anchor</li></ul>',
    '<input type="hidden" data-gift-anchor-filter="', role, '" value="">',
    "</div>"
  )
}

# Both grouping selects offer the same axes, so an axis is added in one place.
# The option value is the row's data-attribute suffix.
.report_group_select <- function(attribute, selected) {
  axes <- c(
    none = "No grouping", `gift-type` = "GIFT type", mode = "Process",
    `substrate-class` = "Substrate class"
  )
  paste0(
    "<select ", attribute, ">",
    paste0(
      '<option value="', names(axes), '"',
      ifelse(names(axes) == selected, " selected", ""), ">",
      unname(axes), "</option>",
      collapse = ""
    ),
    "</select>"
  )
}

.report_gift_controls <- function(data) {
  paste0(
    '<div class="gift-controls">',
    # Two axes rather than one, because substrate class and process are
    # independent and the combination is the view the old fused `category`
    # label used to give: "amino_acid . anabolic".
    '<label class="gift-control"><span>Group by</span>',
    .report_group_select("data-gift-group-select", "none"),
    "</label>",
    '<label class="gift-control"><span>and</span>',
    .report_group_select("data-gift-group-select-2", "none"),
    "</label>",
    .report_anchor_combo(data, "input", "Start anchor", "Type a molecule or anchor"),
    .report_anchor_combo(data, "output", "End anchor", "Type a molecule or anchor"),
    '<button type="button" class="gift-control-reset" data-gift-reset hidden>Clear anchors</button>',
    "</div>"
  )
}

# Every column but the open-detail one sorts. The header carries what the
# script needs to read a row: which element in the cell holds the key, and
# whether to compare it as a number or as text.
.report_gift_table_head <- function() {
  columns <- list(
    list(label = "GIFT", key = "name", type = "text", select = "strong"),
    list(label = "Boundaries or structure", key = "boundary", type = "text"),
    list(label = "Class", key = "class", type = "text"),
    list(label = "Alternatives", key = "alternatives", type = "number"),
    list(label = "Requirements", key = "requirements", type = "number"),
    list(label = "Systems", key = "systems", type = "number"),
    list(label = "Status", key = "status", type = "text")
  )
  cells <- vapply(columns, function(column) {
    paste0(
      '<th class="sortable" aria-sort="none" data-gift-sort-column="', column$key, '">',
      '<button type="button" class="th-sort" data-gift-sort="', column$key,
      '" data-sort-type="', column$type, '"',
      if (!is.null(column$select)) paste0(' data-sort-select="', column$select, '"') else "",
      '><span>', column$label, "</span>",
      '<span class="sort-arrow" aria-hidden="true"></span></button></th>'
    )
  }, character(1))
  paste0("<thead><tr>", paste(cells, collapse = ""), "<th></th></tr></thead>")
}

# The table is long, so it is paged. The page size options are read straight
# from the select, and the rest of the bar is filled in by the script.
.report_gift_pager <- function(sizes = c(20L, 50L, 100L)) {
  options <- paste0(
    '<option value="', sizes, '"',
    ifelse(seq_along(sizes) == 1L, " selected", ""), ">", sizes, "</option>",
    collapse = ""
  )
  paste0(
    '<div class="gift-pager" data-gift-pager>',
    '<label class="gift-pager-size"><span>Rows per page</span>',
    '<select data-gift-page-size aria-label="Rows per page">', options, "</select></label>",
    '<span class="gift-pager-status" data-gift-pager-status></span>',
    '<div class="gift-pager-nav">',
    '<button type="button" class="gift-pager-step" data-gift-page-step="-1" ',
    'aria-label="Previous page">&larr;</button>',
    '<span class="gift-pager-pages" data-gift-pager-pages></span>',
    '<button type="button" class="gift-pager-step" data-gift-page-step="1" ',
    'aria-label="Next page">&rarr;</button></div></div>'
  )
}

.report_gift_explorer <- function(data) {
  rendered <- lapply(seq_len(nrow(data$gifts)), function(index) {
    gift <- data$gifts[index, , drop = FALSE]
    metabolic <- identical(gift$gift_type, "metabolic")
    pathways <- data$gift_pathways[data$gift_pathways$gift_id == gift$gift_id, , drop = FALSE]
    facets <- data$gift_facets[data$gift_facets$gift_id == gift$gift_id, , drop = FALSE]
    detail_id <- paste0("gift-detail-", sprintf("%02d", index))
    marker_id <- paste0("arrow-gift-", sprintf("%02d", index))
    class_label <- if (nrow(facets)) {
      single <- facets$value[facets$facet %in% c("substrate_class", "structural_class")]
      if (length(single)) single[[1]] else NA_character_
    } else {
      NA_character_
    }

    if (metabolic) {
      anchors <- data$anchors[data$anchors$gift_id == gift$gift_id, , drop = FALSE]
      sides <- .report_boundary_sides(anchors, gift$mode)
      inputs <- sides$left
      outputs <- sides$right
      gift_routes <- data$routes[data$routes$gift_id == gift$gift_id, , drop = FALSE]
      gift_reactions <- data$route_reactions[
        data$route_reactions$route_id %in% gift_routes$route_id, , drop = FALSE
      ]
      evidence <- data$systems[
        data$systems$reaction_id %in% gift_reactions$reaction_id, , drop = FALSE
      ]
      components <- data$components[
        data$components$system_id %in% evidence$system_id, , drop = FALSE
      ]
      markers <- data$component_markers[
        data$component_markers$component_id %in% components$component_id, , drop = FALSE
      ]
      searchable <- .html_search_text(
        gift, anchors, gift_routes, gift_reactions, evidence, components, markers,
        pathways, facets
      )
      # The filter chips stay keyed on the declared roles, so an interconversion
      # GIFT is found by searching either of its boundaries in either direction.
      input_ids <- anchors$anchor_id[anchors$role == "input"]
      output_ids <- anchors$anchor_id[anchors$role == "output"]
      alternatives <- gift$route_count
      requirements <- gift$reaction_count
      system_count <- length(unique(evidence$system_id))
      boundary_cell <- paste0(
        '<td class="gift-boundary-cell"><span class="compact-boundary">',
        .report_anchor_badges(inputs, sides$left_role),
        '</span><span class="compact-arrow">', sides$arrow, '</span>',
        '<span class="compact-boundary">',
        .report_anchor_badges(outputs, sides$right_role), "</span></td>"
      )
      scope_block <- paste0(
        '<div class="boundary-flow"><div class="boundary">',
        '<span class="boundary-label">', sides$left_label, "</span>",
        .report_anchor_badges(inputs, sides$left_role),
        '</div><div class="boundary-arrow" aria-hidden="true">', sides$arrow, "</div>",
        '<div class="boundary"><span class="boundary-label">', sides$right_label, "</span>",
        .report_anchor_badges(outputs, sides$right_role), "</div></div>",
        if (sides$reversible) {
          paste0(
            '<p class="boundary-note">Both boundaries are declared as input and ',
            'output. The chemistry is near-equilibrium and the markers do not say ',
            'which way it runs, so neither direction is claimed.</p>'
          )
        } else ""
      )
      statline <- paste0(
        '<div class="gift-statline"><span><strong>', alternatives, "</strong> routes</span>",
        '<span><strong>', requirements, "</strong> unique reactions</span>",
        '<span><strong>', system_count, "</strong> enzyme systems</span></div>"
      )
      network_block <- paste0(
        '<div class="network-section"><div class="network-heading"><h4>Route network</h4>',
        '<div class="graph-legend"><span class="legend-chip ',
        if (sides$reversible) "shared\">Boundary anchor" else "input\">Input anchor",
        "</span>",
        '<span class="legend-chip reaction">Reaction</span>',
        '<span class="legend-chip ',
        if (sides$reversible) "shared\">Boundary anchor" else "output\">Output anchor",
        "</span></div></div>",
        '<p class="network-caption">Alternative routes are overlaid on the reactions they ',
        'share, so parallel branches are route alternatives. Thicker edges are used by ',
        'more routes.',
        if (sides$reversible) {
          paste0(
            ' The chain is drawn both ways because this GIFT declares no ',
            'direction. Each step still carries its own orientation badge, which ',
            'says how that reaction is used relative to its Rhea master equation ',
            '&mdash; a separate question from which way the capability runs.'
          )
        } else "",
        "</p>",
        '<div class="graph-scroll compact">',
        .report_gift_network_svg(
          gift$gift_id, inputs, outputs, data, marker_id, sides$reversible
        ),
        "</div></div>"
      )
      alternatives_block <- paste0(
        '<div class="route-section"><h4>Alternative routes <span>OR</span></h4>',
        .report_route_cards(gift$gift_id, data), "</div>"
      )
    } else {
      view <- .report_machinery_view(data, gift$gift_type)
      slice <- .report_machinery_gift_slice(view, gift$gift_id)
      searchable <- .html_search_text(
        gift, slice$implementations, slice$membership, slice$systems,
        slice$components, slice$markers, pathways, facets
      )
      input_ids <- character()
      output_ids <- character()
      alternatives <- nrow(slice$implementations)
      requirements <- length(unique(slice$membership$function_id))
      system_count <- length(unique(slice$systems$system_id))
      # A structural, regulatory or defense GIFT has no molecular boundaries, so
      # the column names what is built rather than inventing an anchor pair.
      boundary_cell <- paste0(
        '<td class="gift-boundary-cell"><span class="compact-boundary">',
        '<span class="anchor-chip structure" title="',
        .html_escape(paste0(
          "Completeness follows the ", view$model$implementation,
          " model, not molecular boundaries"
        )), '">', .html_escape(gift$gift_type), " ", .html_escape(view$model$implementation),
        "</span></span></td>"
      )
      scope_block <- paste0(
        '<div class="boundary-flow"><div class="boundary">',
        '<span class="boundary-label">Completeness model</span>',
        '<span class="anchor-chip structure">', .html_escape(gift$gift_type),
        "</span></div>",
        '<div class="boundary-arrow" aria-hidden="true">&rarr;</div>',
        '<div class="boundary"><span class="boundary-label">Complete when</span>',
        '<span class="anchor-chip structure">any ', .html_escape(view$model$implementation),
        " is complete</span></div></div>"
      )
      statline <- paste0(
        '<div class="gift-statline"><span><strong>', alternatives, "</strong> ",
        .html_escape(view$model$implementation_plural), "</span>",
        '<span><strong>', requirements, "</strong> functions</span>",
        '<span><strong>', system_count, "</strong> systems</span></div>"
      )
      network_block <- paste0(
        '<div class="network-section"><div class="network-heading"><h4>Machinery</h4>',
        '<div class="graph-legend"><span class="legend-chip input">',
        .html_escape(view$model$implementation), "</span>",
        '<span class="legend-chip reaction">Function</span></div></div>',
        '<p class="network-caption">Alternative ', .html_escape(view$model$implementation_plural),
        ' are drawn over the functions they share, so a function curated once serves ',
        'every implementation that needs it. Thin edges mark accessory functions, whose ',
        'absence does not make an implementation incomplete.</p>',
        '<div class="graph-scroll compact">',
        .report_machinery_network_svg(gift, view, slice, marker_id),
        "</div></div>"
      )
      alternatives_block <- paste0(
        '<div class="route-section"><h4>Alternative ',
        .html_escape(view$model$implementation_plural), " <span>OR</span></h4>",
        .report_implementation_cards(gift, view, slice), "</div>"
      )
    }

    row <- paste0(
      '<tr class="gift-table-row" data-gift-row data-search-item data-gift-id="',
      .html_escape(gift$gift_id),
      '" data-gift-type="', .html_escape(gift$gift_type),
      '" data-substrate-class="', .html_escape(gift$substrate_class),
      '" data-mode="', .html_escape(gift$mode),
      '" data-inputs="', .html_escape(paste0(" ", paste(input_ids, collapse = " "), " ")),
      '" data-outputs="', .html_escape(paste0(" ", paste(output_ids, collapse = " "), " ")),
      '" data-search="', .html_escape(searchable), '" tabindex="0" role="button"',
      ' aria-selected="false" aria-haspopup="dialog" aria-controls="', detail_id, '">',
      '<td class="gift-name-cell"><span class="gift-table-index">', sprintf("%02d", index),
      '</span><span><strong>', .html_text(gift$name), '</strong><code>',
      .html_text(gift$gift_id), "</code></span></td>",
      boundary_cell,
      '<td><span class="category-label">', .html_text(class_label), "</span></td>",
      '<td class="numeric-cell"><strong>', alternatives, "</strong></td>",
      '<td class="numeric-cell"><strong>', requirements, "</strong></td>",
      '<td class="numeric-cell"><strong>', system_count, "</strong></td>",
      '<td><span class="table-status"><i></i>', .html_text(gift$status), "</span></td>",
      '<td class="open-cell"><span>View detail</span>&rarr;</td></tr>'
    )
    detail <- paste0(
      '<article class="gift-detail" data-gift-detail data-gift-id="',
      .html_escape(gift$gift_id), '" data-gift-name="', .html_escape(gift$name),
      '" id="', detail_id, '" hidden>',
      '<header class="gift-header"><div><div class="gift-index">GIFT ',
      sprintf("%02d", index), "</div>",
      '<h3>', .html_text(gift$name), '</h3><div class="gift-id">',
      .html_text(gift$gift_id), "</div></div>",
      '<div class="gift-tags"><span>', .html_text(gift$gift_type), "</span><span>",
      .html_text(class_label), "</span><span>",
      .html_text(gift$status), "</span><span>v", .html_text(gift$version), "</span></div></header>",
      '<p class="gift-description">', .html_text(gift$description), "</p>",
      .report_gift_metadata(gift, data),
      scope_block,
      statline,
      network_block,
      alternatives_block,
      .report_gift_pathways(gift$gift_id, data),
      .report_gift_change_history(gift$gift_id, data),
      if (!is.na(gift$notes) && nzchar(gift$notes)) {
        paste0('<div class="curation-note"><span>Curator note</span>', .html_text(gift$notes), "</div>")
      } else "",
      "</article>"
    )
    list(row = row, detail = detail)
  })

  rows <- paste(vapply(rendered, `[[`, character(1), "row"), collapse = "")
  details <- paste(vapply(rendered, `[[`, character(1), "detail"), collapse = "")
  paste0(
    # The filters sit above the table rather than inside it, so the box holds
    # the result and nothing else.
    .report_gift_controls(data),
    '<div class="gift-table-shell"><div class="gift-table-caption"><span>',
    nrow(data$gifts), ' curated GIFTs</span><small>Select a row to open its routes and reactions</small></div>',
    '<div class="gift-table-scroll"><table class="gift-summary-table">',
    .report_gift_table_head(),
    '<tbody>', rows, '</tbody></table></div>',
    .report_gift_pager(),
    "</div>",
    # The detail of one GIFT is long, so it opens over the table instead of
    # below it: the list stays where the reader left it.
    '<div class="gift-modal" data-gift-modal hidden>',
    '<div class="gift-modal-backdrop" data-gift-modal-close></div>',
    '<div class="gift-modal-window" role="dialog" aria-modal="true" tabindex="-1" ',
    'aria-labelledby="gift-modal-title">',
    '<div class="gift-modal-bar"><div class="gift-modal-title" id="gift-modal-title" ',
    'data-gift-modal-title>GIFT detail</div>',
    '<div class="gift-modal-actions"><button type="button" class="gift-modal-step" ',
    'data-gift-step="-1" aria-label="Previous GIFT">&larr;</button>',
    '<span class="gift-modal-position" data-gift-modal-position></span>',
    '<button type="button" class="gift-modal-step" data-gift-step="1" ',
    'aria-label="Next GIFT">&rarr;</button>',
    '<button type="button" class="gift-modal-close" data-gift-modal-close ',
    'aria-label="Close GIFT detail">&times;</button></div></div>',
    '<div class="gift-modal-body">', details, "</div></div></div>"
  )
}

.graph_truncate <- function(label, max_chars) {
  label <- as.character(label)
  if (is.na(label) || nchar(label) <= max_chars) return(label)
  paste0(substr(label, 1L, max_chars - 1L), "\u2026")
}

# One node of a layered diagram. `shape` selects the drawn geometry: `box` for
# GIFTs, `step` for reactions, and `pill` for declared molecular anchors.
.graph_node <- function(id, shape, kind, label, sublabel = "", badge = "", title = "") {
  width <- switch(
    shape,
    pill = max(70, nchar(label) * 7.6 + 32),
    step = 202,
    246
  )
  height <- switch(shape, pill = 34, step = 58, 70)
  data.frame(
    id = id, shape = shape, kind = kind, label = label, sublabel = sublabel,
    badge = badge, title = title, width = width, height = height,
    stringsAsFactors = FALSE
  )
}

.graph_edges <- function(from, to, label = "", weight = 0.35, title = "",
                         bidirectional = FALSE) {
  count <- length(from)
  edges <- data.frame(
    from = as.character(from), to = as.character(to),
    label = rep_len(label, count), weight = rep_len(weight, count),
    title = rep_len(title, count),
    bidirectional = rep_len(as.logical(bidirectional), count),
    stringsAsFactors = FALSE
  )
  edges[edges$from != edges$to, , drop = FALSE]
}

# Longest-path layering. Every edge pushes its target one column to the right of
# its source, so alternative branches of equal biological depth stay aligned.
# The sweep is bounded by the node count, which keeps cyclic input finite.
.report_graph_levels <- function(node_ids, edges) {
  levels <- stats::setNames(integer(length(node_ids)), node_ids)
  if (!nrow(edges)) return(levels)
  for (iteration in seq_along(node_ids)) {
    changed <- FALSE
    for (index in seq_len(nrow(edges))) {
      candidate <- levels[[edges$from[index]]] + 1L
      if (candidate > levels[[edges$to[index]]]) {
        levels[[edges$to[index]]] <- candidate
        changed <- TRUE
      }
    }
    if (!changed) break
  }
  levels
}

.report_graph_layout <- function(nodes, edges, column_gap = 62, row_gap = 26, margin = 30) {
  nodes$level <- unname(.report_graph_levels(nodes$id, edges)[nodes$id])
  columns <- sort(unique(nodes$level))
  column_width <- vapply(columns, function(level) {
    max(nodes$width[nodes$level == level])
  }, numeric(1))
  column_x <- margin + cumsum(c(0, column_width + column_gap))[seq_along(columns)]
  column_height <- vapply(columns, function(level) {
    heights <- nodes$height[nodes$level == level]
    sum(heights) + row_gap * (length(heights) - 1L)
  }, numeric(1))
  canvas_height <- max(column_height)

  nodes$x <- 0
  nodes$y <- 0
  for (index in seq_along(columns)) {
    at_level <- which(nodes$level == columns[index])
    offset <- margin + (canvas_height - column_height[index]) / 2
    for (position in at_level) {
      nodes$x[position] <- column_x[index] + (column_width[index] - nodes$width[position]) / 2
      nodes$y[position] <- offset
      offset <- offset + nodes$height[position] + row_gap
    }
  }
  attr(nodes, "canvas") <- c(
    width = margin * 2 + sum(column_width) + column_gap * max(0, length(columns) - 1L),
    height = margin * 2 + canvas_height
  )
  nodes
}

.report_graph_edge_svg <- function(nodes, edges, marker) {
  if (!nrow(edges)) return("")
  paste(vapply(seq_len(nrow(edges)), function(index) {
    from <- nodes[match(edges$from[index], nodes$id), , drop = FALSE]
    to <- nodes[match(edges$to[index], nodes$id), , drop = FALSE]
    x1 <- from$x + from$width
    y1 <- from$y + from$height / 2
    x2 <- to$x
    y2 <- to$y + to$height / 2
    mid <- (x1 + x2) / 2
    stroke <- round(1.2 + 1.4 * min(1, max(0, edges$weight[index])), 2)
    label <- edges$label[index]
    label_svg <- if (nzchar(label)) {
      half <- max(30, nchar(label) * 3.6 + 14)
      paste0(
        '<g class="edge-label"><rect x="', round(mid - half, 1), '" y="',
        round((y1 + y2) / 2 - 13, 1), '" width="', round(half * 2, 1),
        '" height="24" rx="12"/><text x="', round(mid, 1), '" y="',
        round((y1 + y2) / 2 + 4, 1), '" text-anchor="middle">',
        .html_escape(label), "</text></g>"
      )
    } else {
      ""
    }
    paste0(
      '<path class="graph-edge" style="stroke-width:', stroke, '" d="M ',
      round(x1, 1), " ", round(y1, 1), " C ", round(mid, 1), " ", round(y1, 1), ", ",
      round(mid, 1), " ", round(y2, 1), ", ", round(x2, 1), " ", round(y2, 1),
      '" marker-end="url(#', marker, ')"',
      if (isTRUE(edges$bidirectional[index])) {
        paste0(' marker-start="url(#', marker, '-start)"')
      } else "",
      ">",
      if (nzchar(edges$title[index])) {
        paste0("<title>", .html_escape(edges$title[index]), "</title>")
      } else "",
      "</path>", label_svg
    )
  }, character(1)), collapse = "")
}

.report_graph_node_svg <- function(nodes) {
  paste(vapply(seq_len(nrow(nodes)), function(index) {
    node <- nodes[index, , drop = FALSE]
    title <- if (nzchar(node$title)) {
      paste0("<title>", .html_escape(node$title), "</title>")
    } else {
      ""
    }
    body <- if (identical(node$shape, "pill")) {
      paste0(
        '<rect width="', node$width, '" height="', node$height, '" rx="',
        node$height / 2, '"/><text class="graph-anchor-label" x="',
        round(node$width / 2, 1), '" y="', round(node$height / 2 + 4, 1),
        '" text-anchor="middle">', .html_escape(node$label), "</text>"
      )
    } else if (identical(node$shape, "step")) {
      paste0(
        '<rect width="', node$width, '" height="', node$height, '" rx="11"/>',
        '<text class="graph-id" x="16" y="20">', .html_escape(node$sublabel), "</text>",
        '<text class="graph-step-name" x="16" y="37">',
        .html_escape(.graph_truncate(node$label, 25L)), "</text>",
        '<text class="graph-badge" x="16" y="50">', .html_escape(node$badge), "</text>"
      )
    } else {
      paste0(
        '<rect width="', node$width, '" height="', node$height, '" rx="13"/>',
        '<circle cx="20" cy="20" r="5"/>',
        '<text class="graph-name" x="20" y="39">',
        .html_escape(.graph_truncate(node$label, 31L)), "</text>",
        '<text class="graph-id" x="20" y="57">', .html_escape(node$sublabel), "</text>"
      )
    }
    paste0(
      '<g class="graph-node ', .html_escape(node$kind), '" transform="translate(',
      round(node$x, 1), " ", round(node$y, 1), ')">', title, body, "</g>"
    )
  }, character(1)), collapse = "")
}

.report_graph_svg <- function(nodes, edges, marker, label, class = "network-svg",
                              min_width = 620, column_gap = 62) {
  nodes <- .report_graph_layout(nodes, edges, column_gap = column_gap)
  canvas <- attr(nodes, "canvas")
  width <- max(min_width, canvas[["width"]])
  height <- max(180, canvas[["height"]])
  nodes$y <- nodes$y + (height - canvas[["height"]]) / 2
  paste0(
    '<svg class="', class, '" width="', round(width), '" height="', round(height),
    '" viewBox="0 0 ', round(width), " ", round(height),
    '" role="img" aria-label="', .html_escape(label), '"><defs><marker id="', marker,
    '" class="graph-arrow" markerWidth="10" markerHeight="10" refX="8" refY="3" ',
    'orient="auto" markerUnits="strokeWidth"><path d="M0,0 L0,6 L9,3 z"/></marker>',
    # The mirrored head, drawn at the start of an edge that runs both ways. Its
    # own path is reversed rather than relying on orient="auto-start-reverse",
    # which is SVG 2 and not worth depending on for one arrowhead.
    '<marker id="', marker, '-start" class="graph-arrow" markerWidth="10" ',
    'markerHeight="10" refX="1" refY="3" orient="auto" markerUnits="strokeWidth">',
    '<path d="M9,0 L9,6 L0,3 z"/></marker></defs>',
    .report_graph_edge_svg(nodes, edges, marker),
    .report_graph_node_svg(nodes), "</svg>"
  )
}

.report_change_timestamp <- function(value) {
  value <- as.character(value)
  if (is.na(value) || !nzchar(value)) return("&mdash;")
  if (grepl("T", value, fixed = TRUE)) {
    parts <- strsplit(value, "T", fixed = TRUE)[[1]]
    return(paste0(
      .html_escape(parts[[1]]), '<span class="change-time">',
      .html_escape(sub("Z$", "", parts[[2]])), " UTC</span>"
    ))
  }
  .html_escape(value)
}

.report_change_gift_chips <- function(change_id, data, linkable = TRUE) {
  rows <- data$change_gifts[data$change_gifts$change_id == change_id, , drop = FALSE]
  if (!nrow(rows)) {
    return('<span class="empty-state compact">No GIFT affected</span>')
  }
  paste(vapply(seq_len(nrow(rows)), function(index) {
    row <- rows[index, , drop = FALSE]
    if (isTRUE(linkable)) {
      paste0(
        '<button class="gift-link" type="button" data-gift-link="',
        .html_escape(row$gift_id), '" title="', .html_escape(row$name),
        '">', .html_escape(row$gift_id), "</button>"
      )
    } else {
      paste0('<span class="gift-link static">', .html_escape(row$gift_id), "</span>")
    }
  }, character(1)), collapse = "")
}

.report_change_detail <- function(row) {
  fields <- list(
    Rationale = row$rationale, Evidence = row$evidence, Effect = row$effect
  )
  fields <- fields[vapply(fields, function(value) {
    length(value) && !is.na(value[[1]]) && nzchar(as.character(value[[1]]))
  }, logical(1))]
  if (!length(fields)) return("")
  body <- paste(vapply(names(fields), function(name) {
    paste0("<dt>", name, "</dt><dd>", .html_text(fields[[name]]), "</dd>")
  }, character(1)), collapse = "")
  paste0(
    '<details class="change-detail"><summary>Why, evidence and effect</summary>',
    "<dl>", body, "</dl></details>"
  )
}

.report_changelog <- function(data) {
  changes <- data$changes
  if (!nrow(changes)) {
    return('<div class="empty-state">No recorded database changes</div>')
  }
  rows <- paste(vapply(seq_len(nrow(changes)), function(index) {
    row <- changes[index, , drop = FALSE]
    gifts <- data$change_gifts[data$change_gifts$change_id == row$change_id, , drop = FALSE]
    searchable <- .html_search_text(row, gifts$gift_id, gifts$name)
    paste0(
      '<tr class="changelog-row" data-search-item data-search="',
      .html_escape(searchable), '">',
      '<td><span class="release-badge">', .html_text(row$released), "</span></td>",
      '<td class="changelog-date">', .report_change_timestamp(row$changed_at), "</td>",
      '<td><span class="scope-chip">', .html_text(row$layer), "</span>",
      '<span class="category-chip">', .html_text(row$substrate_class), "</span></td>",
      '<td class="changelog-change"><strong>', .html_text(row$summary), "</strong>",
      "<code>", .html_text(row$change_id), "</code>",
      .report_change_detail(row), "</td>",
      '<td><span class="effect-chip ', .html_escape(row$call_effect), '">',
      .html_text(row$call_effect), "</span></td>",
      '<td class="changelog-gifts">', .report_change_gift_chips(row$change_id, data), "</td>",
      "</tr>"
    )
  }, character(1)), collapse = "")

  releases <- unique(changes$released)
  paste0(
    '<div class="changelog-shell"><div class="changelog-caption"><span>',
    nrow(changes), " recorded change", if (nrow(changes) == 1L) "" else "s",
    " across ", length(releases), " release", if (length(releases) == 1L) "" else "s",
    '</span><small>Select a GIFT identifier to open the trait a change refers to</small></div>',
    '<div class="changelog-scroll"><table class="changelog-table">',
    "<thead><tr><th>Release</th><th>Recorded</th><th>Scope</th><th>Change</th>",
    "<th>Calls</th><th>GIFTs affected</th></tr></thead><tbody>",
    rows, "</tbody></table></div></div>"
  )
}

.report_gift_change_history <- function(gift_id, data) {
  linked <- data$change_gifts$change_id[data$change_gifts$gift_id == gift_id]
  rows <- data$changes[data$changes$change_id %in% linked, , drop = FALSE]
  if (!nrow(rows)) return("")
  entries <- paste(vapply(seq_len(nrow(rows)), function(index) {
    row <- rows[index, , drop = FALSE]
    paste0(
      '<li class="history-entry"><div class="history-head">',
      '<span class="release-badge">', .html_text(row$released), "</span>",
      '<span class="history-date">', .report_change_timestamp(row$changed_at), "</span>",
      '<span class="effect-chip ', .html_escape(row$call_effect), '">',
      .html_text(row$call_effect), "</span></div>",
      '<div class="history-summary">', .html_text(row$summary), "</div>",
      .report_change_detail(row), "</li>"
    )
  }, character(1)), collapse = "")
  paste0(
    '<div class="history-section"><h4>Change history <span>',
    nrow(rows), " entr", if (nrow(rows) == 1L) "y" else "ies", "</span></h4>",
    '<ol class="history-list">', entries, "</ol></div>"
  )
}

# Deterministic force-directed placement (Fruchterman-Reingold). The overview
# networks hold a few hundred nodes, which R lays out in a fraction of a second,
# and the golden-angle seed keeps the drawn atlas byte-identical between builds
# without carrying a random seed around.
.report_force_layout <- function(node_ids, edges, width = 960, height = 600,
                                 iterations = 420L, gravity = 1) {
  count <- length(node_ids)
  if (!count) return(data.frame(id = character(), x = numeric(), y = numeric()))
  if (count == 1L) {
    return(data.frame(
      id = node_ids, x = width / 2, y = height / 2, stringsAsFactors = FALSE
    ))
  }

  index <- seq_len(count)
  angle <- index * 2.399963229728653
  radius <- sqrt(index / count) * min(width, height) * 0.45
  x <- width / 2 + radius * cos(angle)
  y <- height / 2 + radius * sin(angle)

  from <- match(edges$from, node_ids)
  to <- match(edges$to, node_ids)
  linked <- !is.na(from) & !is.na(to) & from != to
  from <- from[linked]
  to <- to[linked]

  accumulate <- function(index, value) {
    total <- numeric(count)
    if (!length(index)) return(total)
    summed <- tapply(value, index, sum)
    total[as.integer(names(summed))] <- summed
    total
  }

  ideal <- sqrt(width * height / count)
  temperature <- min(width, height) / 6
  cooling <- temperature / (iterations + 1)
  for (step in seq_len(iterations)) {
    gap_x <- outer(x, x, "-")
    gap_y <- outer(y, y, "-")
    distance <- sqrt(gap_x * gap_x + gap_y * gap_y)
    distance[distance < 0.05] <- 0.05
    push <- ideal * ideal / (distance * distance)
    diag(push) <- 0
    force_x <- rowSums(gap_x * push)
    force_y <- rowSums(gap_y * push)
    if (length(from)) {
      edge_x <- x[from] - x[to]
      edge_y <- y[from] - y[to]
      span <- pmax(sqrt(edge_x * edge_x + edge_y * edge_y), 0.05)
      pull_x <- edge_x * span / ideal
      pull_y <- edge_y * span / ideal
      force_x <- force_x - accumulate(from, pull_x) + accumulate(to, pull_x)
      force_y <- force_y - accumulate(from, pull_y) + accumulate(to, pull_y)
    }
    # Without a pull to the middle, disconnected GIFTs -- the structural,
    # regulatory, and defense traits that declare no anchors -- are pushed off
    # the canvas by repulsion alone. The pull is stronger along the short axis,
    # which settles the drawing into an ellipse shaped like the frame instead
    # of a disc that has to be squashed into it afterwards.
    force_x <- force_x + (width / 2 - x) * gravity
    force_y <- force_y + (height / 2 - y) * gravity * width / height

    reach <- pmax(sqrt(force_x * force_x + force_y * force_y), 0.05)
    limit <- pmin(reach, temperature) / reach
    x <- x + force_x * limit
    y <- y + force_y * limit
    temperature <- temperature - cooling
  }

  data.frame(id = node_ids, x = x, y = y, stringsAsFactors = FALSE)
}

# Categorical palette for the overview network, assigned in this fixed order and
# never cycled. Every prefix of it clears the all-pairs colour-vision gates on
# the report surface (#fffdf8): worst pair dE 8.1 under simulated protanopia,
# 18.5 unsimulated, every slot at or above 3:1 contrast against the surface.
# A value past the seventh is therefore not given a generated hue -- it is drawn
# as an unfilled ring, which is a shape difference rather than a colour a reader
# would have to tell apart from the seven.
.report_dot_palette <- c(
  "#1295db", "#a53603", "#076941", "#cc7e04", "#50409d", "#2ba567", "#b658a0"
)

# What the two overview colour menus offer. `key` is the attribute suffix each
# dot carries its colour under, and the order here is the order of the menu.
.report_dot_schemes <- list(
  gift = list(
    c(key = "type", label = "GIFT type"),
    c(key = "mode", label = "Metabolic mode"),
    c(key = "substrate", label = "Substrate class"),
    c(key = "role", label = "Physiological role")
  ),
  anchor = list(
    c(key = "boundary", label = "Boundary use"),
    c(key = "compartment", label = "Compartment"),
    c(key = "tier", label = "Molecular tier"),
    c(key = "origin", label = "Resource origin"),
    c(key = "biomass", label = "Biomass essential")
  )
)

# A curated snake_case value is not a caption. Underscores become spaces and the
# first letter is capitalized, which is enough for every value in the database
# and keeps the legend readable without a second curated column.
.report_scheme_caption <- function(value) {
  value <- gsub("_", " ", value, fixed = TRUE)
  paste0(toupper(substr(value, 1, 1)), substr(value, 2, nchar(value)))
}

# Which colour each value of one scheme gets. Frequency first so the biggest
# groups get the leading hues, ties broken alphabetically so a rebuild of the
# database never silently repaints the drawing.
.report_scheme_colours <- function(values) {
  values <- values[!is.na(values) & nzchar(values)]
  if (!length(values)) return(stats::setNames(character(), character()))
  counts <- table(values)
  ranked <- names(counts)[order(-as.integer(counts), names(counts))]
  ranked <- utils::head(ranked, length(.report_dot_palette))
  stats::setNames(.report_dot_palette[seq_along(ranked)], ranked)
}

# The scheme values one node carries, as a `key=value` string per scheme. Values
# are curated snake_case identifiers, so nothing here needs quoting.
.report_dot_facets <- function(...) {
  pairs <- c(...)
  pairs <- pairs[!is.na(pairs) & nzchar(pairs)]
  if (!length(pairs)) return("")
  paste(names(pairs), pairs, sep = "=", collapse = ";")
}

.report_facet_value <- function(facets, key) {
  vapply(strsplit(facets, ";", fixed = TRUE), function(parts) {
    hit <- parts[startsWith(parts, paste0(key, "="))]
    if (!length(hit)) "" else substring(hit[[1]], nchar(key) + 2L)
  }, character(1))
}

# One dot of an overview network. `detail` is the hover card body, one
# `label|value` pair per line, `target` names the GIFT the dot opens, and
# `facets` are the metadata values the colour menus can paint it by.
.report_dot_node <- function(id, kind, label, sublabel, detail, radius,
                             target = "", facets = "") {
  data.frame(
    id = id, kind = kind, label = label, sublabel = sublabel, detail = detail,
    radius = radius, target = target, facets = facets, stringsAsFactors = FALSE
  )
}

# The overview networks carry no drawn labels: every identifier, name, and role
# lives in the hover card instead, so the shape of the interconnection is what
# the reader sees first.
.report_dot_network_svg <- function(nodes, edges, marker, label, width = 960,
                                    height = 600) {
  if (!nrow(nodes)) return('<div class="empty-state">Nothing to draw</div>')
  margin <- max(nodes$radius) + 16
  layout <- .report_force_layout(
    nodes$id, edges,
    width = width - 2 * margin, height = height - 2 * margin
  )
  nodes$x <- layout$x[match(nodes$id, layout$id)] + margin
  nodes$y <- layout$y[match(nodes$id, layout$id)] + margin
  # The sweep settles at whatever scale the forces balance at, so the result is
  # zoomed to the frame. One scale is used for both axes: the drawing is a
  # picture of which traits sit near each other, and stretching the axes apart
  # would move nodes without moving anything they are connected to.
  span_x <- max(nodes$x) - min(nodes$x)
  span_y <- max(nodes$y) - min(nodes$y)
  scale <- min(
    if (span_x > 0) (width - 2 * margin) / span_x else Inf,
    if (span_y > 0) (height - 2 * margin) / span_y else Inf
  )
  if (!is.finite(scale)) scale <- 1
  nodes$x <- (nodes$x - min(nodes$x)) * scale + (width - span_x * scale) / 2
  nodes$y <- (nodes$y - min(nodes$y)) * scale + (height - span_y * scale) / 2

  edge_svg <- if (nrow(edges)) {
    from <- match(edges$from, nodes$id)
    to <- match(edges$to, nodes$id)
    drawable <- !is.na(from) & !is.na(to) & from != to
    from <- from[drawable]
    to <- to[drawable]
    edges <- edges[drawable, , drop = FALSE]
    paste(vapply(seq_along(from), function(index) {
      x1 <- nodes$x[from[index]]
      y1 <- nodes$y[from[index]]
      x2 <- nodes$x[to[index]]
      y2 <- nodes$y[to[index]]
      span <- max(sqrt((x2 - x1)^2 + (y2 - y1)^2), 0.01)
      # Trimming each end to the rim of its dot keeps the arrowhead visible
      # instead of buried under the node it points at.
      head_x <- (x2 - x1) / span
      head_y <- (y2 - y1) / span
      paste0(
        '<line class="dot-edge" data-edge-from="', .html_escape(edges$from[index]),
        '" data-edge-to="', .html_escape(edges$to[index]), '" x1="',
        round(x1 + head_x * (nodes$radius[from[index]] + 1), 1), '" y1="',
        round(y1 + head_y * (nodes$radius[from[index]] + 1), 1), '" x2="',
        round(x2 - head_x * (nodes$radius[to[index]] + 5), 1), '" y2="',
        round(y2 - head_y * (nodes$radius[to[index]] + 5), 1), '" marker-end="url(#',
        marker, ')"', if (isTRUE(edges$bidirectional[index])) {
          paste0(' marker-start="url(#', marker, '-start)"')
        } else "", "></line>"
      )
    }, character(1)), collapse = "")
  } else {
    ""
  }

  # One colour attribute per scheme per dot, so switching a menu is a repaint the
  # page can do without knowing anything about the biology.
  base_kind <- sub(" .*$", "", nodes$kind)
  colour_attrs <- rep("", nrow(nodes))
  legends <- list(
    "gift:" = .report_scheme_legend("gift", "", NULL, stats::setNames(character(), character())),
    "anchor:" = .report_scheme_legend("anchor", "", NULL, stats::setNames(character(), character()))
  )
  for (family in names(.report_dot_schemes)) {
    member <- base_kind == family
    if (!any(member)) next
    for (scheme in .report_dot_schemes[[family]]) {
      key <- scheme[["key"]]
      values <- .report_facet_value(nodes$facets[member], key)
      colours <- .report_scheme_colours(values)
      colour_attrs[member] <- paste0(
        colour_attrs[member], ' data-fill-', key, '="',
        .html_escape(ifelse(values %in% names(colours), colours[values], "")), '"'
      )
      legends[[paste0(family, ":", key)]] <- .report_scheme_legend(
        family, key, scheme[["label"]], colours,
        folded = any(nzchar(values) & !values %in% names(colours)),
        unset = any(!nzchar(values))
      )
    }
  }

  node_svg <- paste(vapply(seq_len(nrow(nodes)), function(index) {
    node <- nodes[index, , drop = FALSE]
    clickable <- nzchar(node$target)
    paste0(
      '<g class="dot-node ', .html_escape(node$kind), if (clickable) " linked" else "",
      '" data-node-id="', .html_escape(node$id),
      '" data-node-label="', .html_escape(node$label),
      '" data-node-sublabel="', .html_escape(node$sublabel),
      '" data-node-detail="', .html_escape(node$detail), '"', colour_attrs[index],
      if (clickable) {
        paste0(
          ' data-node-gift="', .html_escape(node$target),
          '" tabindex="0" role="link" aria-label="', .html_escape(node$label), '"'
        )
      } else "",
      ' transform="translate(', round(node$x, 1), " ", round(node$y, 1), ')">',
      '<circle class="dot-halo" r="', round(node$radius + 7, 1), '"/>',
      '<circle class="dot-core" r="', node$radius, '"/>',
      "<title>", .html_escape(paste0(node$label, " \u00b7 ", node$sublabel)),
      "</title></g>"
    )
  }, character(1)), collapse = "")

  paste0(
    '<div class="dot-network-frame" data-dot-network>',
    '<svg class="dot-network" viewBox="0 0 ', width, " ", height,
    '" preserveAspectRatio="xMidYMid meet" role="img" aria-label="',
    .html_escape(label), '"><defs><marker id="', marker,
    '" class="dot-arrow" markerWidth="7" markerHeight="7" refX="6" refY="2.5" ',
    'orient="auto" markerUnits="userSpaceOnUse"><path d="M0,0 L0,5 L6,2.5 z"/></marker>',
    '<marker id="', marker, '-start" class="dot-arrow" markerWidth="7" ',
    'markerHeight="7" refX="1" refY="2.5" orient="auto" markerUnits="userSpaceOnUse">',
    '<path d="M6,0 L6,5 L0,2.5 z"/></marker></defs>',
    '<g class="dot-edges">', edge_svg, "</g>",
    '<g class="dot-nodes">', node_svg, "</g></svg>",
    '<div class="dot-legend" data-dot-legend>',
    # Grouped by family so the GIFT key always sits above the anchor key,
    # whichever scheme each menu is showing.
    paste(unlist(legends[order(!startsWith(names(legends), "gift"))],
                 use.names = FALSE), collapse = ""), "</div>",
    '<div class="dot-tooltip" data-dot-tooltip hidden aria-hidden="true"></div></div>'
  )
}

# One legend panel: the key for a colour scheme, or -- with no scheme -- the
# plain GIFT/anchor key the drawing carries when nothing is coloured. Only one
# panel per family is visible at a time; the page unhides the one its menu names.
.report_scheme_legend <- function(family, key, label, colours, folded = FALSE,
                                  unset = FALSE) {
  rows <- if (length(colours)) {
    paste(vapply(names(colours), function(value) {
      paste0(
        '<span class="dot-key ', family, '" style="--swatch:', colours[[value]],
        '">', .html_escape(.report_scheme_caption(value)), "</span>"
      )
    }, character(1)), collapse = "")
  } else {
    paste0(
      '<span class="dot-key ', family, '">',
      if (identical(family, "gift")) "GIFT" else "Anchor", "</span>"
    )
  }
  # The palette is never cycled, so anything past its last slot -- and anything
  # the curators have not annotated -- is drawn as a ring rather than as a colour
  # a reader would have to tell apart from the seven real ones.
  rest <- if (folded || unset) {
    paste0(
      '<span class="dot-key ', family, ' unassigned">',
      if (folded && unset) "Other or unannotated" else if (folded) "Other" else "Unannotated",
      "</span>"
    )
  } else {
    ""
  }
  paste0(
    '<div class="dot-legend-block" data-legend="', family, ":", key, '"',
    if (is.null(label)) "" else " hidden", ">",
    if (is.null(label)) "" else {
      paste0('<span class="dot-legend-title">', .html_escape(label), "</span>")
    },
    rows, rest, "</div>"
  )
}

# Everything the hover card says about one GIFT. Kept to one line per fact so
# the card stays small enough to sit next to the dot it describes.
.report_gift_dot_detail <- function(gift, anchors) {
  own <- anchors[anchors$gift_id == gift$gift_id, , drop = FALSE]
  inputs <- unique(own$anchor_id[own$role == "input"])
  outputs <- unique(own$anchor_id[own$role == "output"])
  paste(c(
    paste0("Type|", gift$gift_type),
    if (!is.na(gift$mode) && nzchar(gift$mode)) paste0("Mode|", gift$mode),
    if (length(inputs)) paste0("In|", paste(inputs, collapse = ", ")),
    if (length(outputs)) paste0("Out|", paste(outputs, collapse = ", ")),
    paste0(
      "Content|", gift$route_count, " route", if (gift$route_count == 1L) "" else "s",
      " \u00b7 ", gift$reaction_count, " reaction",
      if (gift$reaction_count == 1L) "" else "s"
    )
  ), collapse = "\n")
}

# Which anchors to draw on each side of a GIFT's boundary, and which arrow to
# draw between them.
#
# A directed GIFT is simply its inputs and its outputs. An interconversion GIFT
# declares every anchor in both roles, so listing the roles verbatim prints each
# anchor twice and puts a one-way arrow between two identical sets --
# `ACETYL_COA ACETATE -> ACETATE ACETYL_COA`, which reads as nonsense and
# implies a direction the mode exists to deny. Each anchor is instead drawn once,
# on the side where it was declared first, which is what the ordinals record, and
# the arrow is drawn both ways.
.report_boundary_sides <- function(anchors, mode) {
  inputs <- anchors[anchors$role == "input", , drop = FALSE]
  outputs <- anchors[anchors$role == "output", , drop = FALSE]
  directed <- list(
    left = inputs, right = outputs, arrow = "&rarr;",
    left_label = "Inputs", right_label = "Outputs",
    left_role = "input", right_role = "output", reversible = FALSE
  )
  if (!identical(mode, "interconversion") || !nrow(inputs) || !nrow(outputs)) {
    return(directed)
  }

  inputs <- inputs[order(as.integer(inputs$ordinal)), , drop = FALSE]
  outputs <- outputs[order(as.integer(outputs$ordinal)), , drop = FALSE]
  counterpart <- as.integer(outputs$ordinal)[match(inputs$anchor_id, outputs$anchor_id)]
  first_declared_as_input <- is.na(counterpart) | as.integer(inputs$ordinal) <= counterpart
  left <- inputs[first_declared_as_input, , drop = FALSE]
  right <- outputs[!outputs$anchor_id %in% left$anchor_id, , drop = FALSE]
  # A shape where every anchor lands on one side would draw an empty box. No
  # curated GIFT does this, and falling back to the literal roles is better than
  # rendering nothing.
  if (!nrow(left) || !nrow(right)) return(directed)

  list(
    left = left, right = right, arrow = "&harr;",
    left_label = "Inputs / outputs", right_label = "Outputs / inputs",
    left_role = "shared", right_role = "shared", reversible = TRUE
  )
}

# Bipartite anchor network. Anchors are drawn once, so an anchor that is the
# output of one GIFT and the input of another is the single node where those
# GIFTs meet. This is the only mechanism by which GIFTs connect.
.report_anchor_network_svg <- function(data) {
  anchors <- data$anchors
  if (!nrow(anchors)) return('<div class="empty-state">No declared anchors</div>')
  # A facet a GIFT or an anchor declares more than once cannot paint one dot two
  # colours, so the first curated value stands for the whole annotation and the
  # hover card keeps the complete list.
  first_facet <- function(table, id_column, id, facet) {
    if (is.null(table) || !nrow(table)) return("")
    hit <- table$value[table[[id_column]] == id & table$facet == facet]
    if (!length(hit)) "" else hit[[1]]
  }
  anchor_ids <- unique(anchors$anchor_id)
  roles <- vapply(anchor_ids, function(anchor) {
    used <- anchors$role[anchors$anchor_id == anchor]
    if (all(used == "input")) "input" else if (all(used == "output")) "output" else "shared"
  }, character(1))

  anchor_nodes <- do.call(rbind, lapply(seq_along(anchor_ids), function(index) {
    anchor <- anchors[match(anchor_ids[index], anchors$anchor_id), , drop = FALSE]
    role <- roles[[index]]
    users <- anchors[anchors$anchor_id == anchor$anchor_id, , drop = FALSE]
    .report_dot_node(
      id = paste0("anchor:", anchor$anchor_id), kind = paste("anchor", role),
      label = anchor$name, sublabel = anchor$anchor_id,
      facets = .report_dot_facets(
        boundary = role,
        compartment = anchor$compartment,
        tier = first_facet(data$anchor_facets, "anchor_id", anchor$anchor_id, "molecular_tier"),
        origin = first_facet(data$anchor_facets, "anchor_id", anchor$anchor_id, "resource_origin"),
        biomass = first_facet(
          data$anchor_facets, "anchor_id", anchor$anchor_id, "biomass_essential"
        )
      ),
      detail = paste(c(
        paste0("Boundary|", switch(
          role,
          input = "input only",
          output = "output only",
          "shared, where GIFTs compose"
        )),
        if (!is.na(anchor$chebi_id) && nzchar(anchor$chebi_id)) {
          paste0("ChEBI|", anchor$chebi_id)
        },
        paste0("Compartment|", anchor$compartment),
        paste0(
          "Used by|", length(unique(users$gift_id)), " GIFT",
          if (length(unique(users$gift_id)) == 1L) "" else "s"
        )
      ), collapse = "\n"),
      radius = 5
    )
  }))
  gift_nodes <- do.call(rbind, lapply(seq_len(nrow(data$gifts)), function(index) {
    gift <- data$gifts[index, , drop = FALSE]
    .report_dot_node(
      id = paste0("gift:", gift$gift_id), kind = "gift", label = gift$name,
      sublabel = gift$gift_id,
      detail = .report_gift_dot_detail(gift, anchors), radius = 9,
      target = gift$gift_id,
      facets = .report_dot_facets(
        type = gift$gift_type,
        mode = if (is.na(gift$mode)) "" else gift$mode,
        substrate = first_facet(data$gift_facets, "gift_id", gift$gift_id, "substrate_class"),
        role = first_facet(data$gift_facets, "gift_id", gift$gift_id, "physiological_role")
      )
    )
  }))

  inputs <- anchors[anchors$role == "input", , drop = FALSE]
  outputs <- anchors[anchors$role == "output", , drop = FALSE]
  # An interconversion GIFT declares every anchor in both roles. Drawing both
  # would put two arrowheads face to face between the same pair of nodes, which
  # reads as a contradiction rather than as reversibility, so one edge is drawn
  # with a head at each end instead.
  reversible_gifts <- data$gifts$gift_id[
    !is.na(data$gifts$mode) & data$gifts$mode == "interconversion"
  ]
  reversible <- inputs[inputs$gift_id %in% reversible_gifts, , drop = FALSE]
  inputs <- inputs[!inputs$gift_id %in% reversible_gifts, , drop = FALSE]
  outputs <- outputs[!outputs$gift_id %in% reversible_gifts, , drop = FALSE]
  edges <- rbind(
    .graph_edges(
      from = paste0("anchor:", inputs$anchor_id), to = paste0("gift:", inputs$gift_id)
    ),
    .graph_edges(
      from = paste0("gift:", outputs$gift_id), to = paste0("anchor:", outputs$anchor_id)
    ),
    if (nrow(reversible)) {
      .graph_edges(
        from = paste0("anchor:", reversible$anchor_id),
        to = paste0("gift:", reversible$gift_id),
        bidirectional = TRUE
      )
    }
  )
  .report_dot_network_svg(
    rbind(gift_nodes, anchor_nodes), edges, "arrow-anchors",
    "GIFT and anchor network", height = 660
  )
}

# Merged route network of one GIFT. Alternative routes are overlaid on shared
# reaction nodes, so parallel branches are genuine route alternatives and the
# only entry and exit points are the declared anchors.
.report_gift_network_svg <- function(gift_id, inputs, outputs, data, marker,
                                     reversible = FALSE) {
  route_ids <- data$routes$route_id[data$routes$gift_id == gift_id]
  reactions <- data$route_reactions[
    data$route_reactions$route_id %in% route_ids, , drop = FALSE
  ]
  if (!length(route_ids) || !nrow(reactions)) {
    return('<div class="empty-state compact">No routes to draw</div>')
  }

  input_ids <- if (nrow(inputs)) paste0("in:", inputs$anchor_id) else character()
  output_ids <- if (nrow(outputs)) paste0("out:", outputs$anchor_id) else character()
  step_rows <- list()
  step_routes <- list()
  edge_routes <- list()
  edge_pairs <- list()

  for (route_id in route_ids) {
    chain <- reactions[reactions$route_id == route_id, , drop = FALSE]
    if (!nrow(chain)) next
    chain <- chain[order(chain$step_order), , drop = FALSE]
    step_ids <- paste0("rx:", chain$reaction_id, ":", chain$orientation)
    for (index in seq_along(step_ids)) {
      id <- step_ids[index]
      if (is.null(step_rows[[id]])) step_rows[[id]] <- chain[index, , drop = FALSE]
      step_routes[[id]] <- unique(c(step_routes[[id]], route_id))
    }
    pairs <- rbind(
      if (length(input_ids)) {
        data.frame(from = input_ids, to = step_ids[1], stringsAsFactors = FALSE)
      },
      if (length(step_ids) > 1L) {
        data.frame(
          from = step_ids[-length(step_ids)], to = step_ids[-1], stringsAsFactors = FALSE
        )
      },
      if (length(output_ids)) {
        data.frame(
          from = step_ids[length(step_ids)], to = output_ids, stringsAsFactors = FALSE
        )
      }
    )
    for (index in seq_len(nrow(pairs))) {
      key <- paste0(pairs$from[index], " -> ", pairs$to[index])
      if (is.null(edge_pairs[[key]])) edge_pairs[[key]] <- pairs[index, , drop = FALSE]
      edge_routes[[key]] <- unique(c(edge_routes[[key]], route_id))
    }
  }

  total_routes <- length(route_ids)
  anchor_node <- function(rows, role) {
    if (!nrow(rows)) return(NULL)
    do.call(rbind, lapply(seq_len(nrow(rows)), function(index) {
      row <- rows[index, , drop = FALSE]
      .graph_node(
        id = paste0(if (identical(role, "input")) "in:" else "out:", row$anchor_id),
        shape = "pill",
        kind = paste("anchor", if (reversible) "shared" else role),
        label = row$anchor_id,
        title = paste0(
          row$anchor_id, " \u00b7 ", row$name,
          if (!is.na(row$chebi_id) && nzchar(row$chebi_id)) paste0(" (", row$chebi_id, ")") else "",
          " \u00b7 declared ",
          if (reversible) "input and output boundary" else paste(role, "boundary")
        )
      )
    }))
  }
  step_nodes <- do.call(rbind, lapply(names(step_rows), function(id) {
    row <- step_rows[[id]]
    used <- length(step_routes[[id]])
    orientation <- if (identical(row$orientation, "reverse")) "\u2190 reverse" else "forward \u2192"
    .graph_node(
      id = id, shape = "step",
      kind = paste0("reaction", if (identical(row$orientation, "reverse")) " reverse" else ""),
      label = row$name, sublabel = row$reaction_id,
      badge = if (total_routes > 1L) {
        paste0(orientation, " \u00b7 ", used, "/", total_routes, " routes")
      } else {
        orientation
      },
      title = paste0(
        row$reaction_id, " \u00b7 ", row$name, " \u00b7 ", orientation,
        " \u00b7 used by ", used, " of ", total_routes,
        if (total_routes == 1L) " route" else " routes"
      )
    )
  }))
  nodes <- rbind(anchor_node(inputs, "input"), step_nodes, anchor_node(outputs, "output"))

  pairs <- do.call(rbind, edge_pairs)
  weights <- vapply(names(edge_pairs), function(key) {
    length(edge_routes[[key]]) / total_routes
  }, numeric(1))
  counts <- vapply(names(edge_pairs), function(key) length(edge_routes[[key]]), integer(1))
  # A reversible GIFT declares no direction, so the chain it draws has none
  # either. The per-reaction badges keep saying how each step is used relative
  # to its own Rhea master equation, which is a separate question from which way
  # the capability runs.
  edges <- .graph_edges(
    from = pairs$from, to = pairs$to, weight = unname(weights),
    title = paste0(
      "Traversed by ", counts, " of ", total_routes,
      if (total_routes == 1L) " route" else " routes",
      if (reversible) ", in either direction" else ""
    ),
    bidirectional = reversible
  )

  .report_graph_svg(
    nodes, edges, marker, paste0("Route network of ", gift_id),
    class = "network-svg route-network-svg", min_width = 480, column_gap = 54
  )
}


# ---------------------------------------------------------------------------
# Non-metabolic GIFT rendering
#
# A metabolic GIFT is drawn as a directed route between declared anchors. A
# structural, regulatory or defense GIFT has no anchors to draw between, so it
# is drawn as its alternative implementations and the functions each of them
# requires. Functions shared by two implementations appear once, which is what
# makes reuse visible instead of duplicated.
# ---------------------------------------------------------------------------

.report_machinery_view <- function(data, gift_type) {
  view <- data$machinery[[gift_type]]
  if (is.null(view)) stop("No report model for GIFT type: ", gift_type, call. = FALSE)
  view
}

.report_machinery_gift_slice <- function(view, gift_id) {
  implementations <- view$implementations[view$implementations$gift_id == gift_id, , drop = FALSE]
  membership <- view$membership[
    view$membership$implementation_id %in% implementations$implementation_id, , drop = FALSE
  ]
  systems <- view$systems[view$systems$function_id %in% membership$function_id, , drop = FALSE]
  components <- view$components[view$components$system_id %in% systems$system_id, , drop = FALSE]
  markers <- view$markers[view$markers$component_id %in% components$component_id, , drop = FALSE]
  list(
    implementations = implementations, membership = membership,
    systems = systems, components = components, markers = markers
  )
}

.report_machinery_marker_rows <- function(rows) {
  if (!nrow(rows)) return('<div class="empty-state compact">No accepted markers</div>')
  paste(vapply(seq_len(nrow(rows)), function(index) {
    row <- rows[index, , drop = FALSE]
    notes <- if (!is.na(row$notes) && nzchar(row$notes)) {
      paste0('<span class="marker-note">', .html_escape(row$notes), "</span>")
    } else ""
    paste0(
      '<div class="marker-row"><code>', .html_escape(row$namespace), ":",
      .html_escape(row$accession), "</code><span>", .html_text(row$name),
      '</span><span class="marker-confidence">', .html_text(row$confidence),
      "</span>", notes, "</div>"
    )
  }, character(1)), collapse = "")
}

.report_machinery_system_rows <- function(function_id, slice) {
  systems <- slice$systems[slice$systems$function_id == function_id, , drop = FALSE]
  if (!nrow(systems)) return('<div class="empty-state compact">No systems</div>')
  paste(vapply(seq_len(nrow(systems)), function(index) {
    system <- systems[index, , drop = FALSE]
    components <- slice$components[
      slice$components$system_id == system$system_id, , drop = FALSE
    ]
    component_rows <- paste(vapply(seq_len(nrow(components)), function(j) {
      component <- components[j, , drop = FALSE]
      markers <- slice$markers[
        slice$markers$component_id == component$component_id, , drop = FALSE
      ]
      paste0(
        '<div class="component-card"><div class="component-head">',
        '<span class="entity-name">', .html_text(component$name), "</span>",
        '<span class="entity-id">', .html_text(component$component_id), "</span></div>",
        '<p class="entity-description">', .html_text(component$description), "</p>",
        .report_machinery_marker_rows(markers), "</div>"
      )
    }, character(1)), collapse = "")
    paste0(
      '<div class="system-card"><div class="system-head">',
      '<span class="entity-name">', .html_text(system$name), "</span>",
      '<span class="entity-id">', .html_text(system$system_id), "</span>",
      '<span class="system-meta">', nrow(components), " component",
      if (nrow(components) == 1L) "" else "s", " &middot; AND</span></div>",
      '<p class="entity-description">', .html_text(system$description), "</p>",
      component_rows, "</div>"
    )
  }, character(1)), collapse = "")
}

.report_implementation_cards <- function(gift, view, slice) {
  rows <- slice$implementations
  if (!nrow(rows)) {
    return(paste0('<div class="empty-state">No ', view$model$implementation_plural, "</div>"))
  }
  paste(vapply(seq_len(nrow(rows)), function(index) {
    row <- rows[index, , drop = FALSE]
    functions <- slice$membership[
      slice$membership$implementation_id == row$implementation_id, , drop = FALSE
    ]
    functions <- functions[order(functions$ordinal), , drop = FALSE]
    required_count <- sum(functions$required == 1L)
    function_items <- paste(vapply(seq_len(nrow(functions)), function(j) {
      fn <- functions[j, , drop = FALSE]
      accessory <- fn$required != 1L
      paste0(
        '<li class="reaction-row', if (accessory) " optional" else "", '">',
        '<details><summary><span class="step-number">',
        sprintf("%02d", fn$ordinal), "</span>",
        '<span class="summary-main"><span class="entity-name">',
        .html_text(fn$function_name), "</span>",
        '<span class="entity-id">', .html_text(fn$function_id), "</span></span>",
        '<span class="reaction-meta">',
        if (accessory) "accessory" else "required", "</span></summary>",
        '<div class="reaction-body"><p class="entity-description">',
        .html_text(fn$function_description), "</p>",
        '<div class="system-block"><h5>Alternative systems <span>OR</span></h5>',
        .report_machinery_system_rows(fn$function_id, slice), "</div></div></details></li>"
      )
    }, character(1)), collapse = "")
    paste0(
      '<details class="route-card">',
      '<summary><span class="route-number">', sprintf("%02d", index), "</span>",
      '<span class="summary-main"><span class="entity-name">', .html_text(row$name), "</span>",
      '<span class="entity-id">', .html_text(row$implementation_id), "</span></span>",
      '<span class="route-meta"><span class="status-dot"></span>', .html_text(row$status),
      " &middot; ", required_count, " required function",
      if (required_count == 1L) "" else "s", "</span></summary>",
      '<div class="route-body"><p class="route-description">',
      .html_text(row$description), "</p>",
      '<ol class="reaction-list">', function_items, "</ol></div></details>"
    )
  }, character(1)), collapse = "")
}

.report_machinery_network_svg <- function(gift, view, slice, marker) {
  if (!nrow(slice$implementations) || !nrow(slice$membership)) {
    return(paste0(
      '<div class="empty-state compact">No ', view$model$implementation_plural, " to draw</div>"
    ))
  }
  total <- nrow(slice$implementations)
  implementation_nodes <- do.call(rbind, lapply(seq_len(total), function(index) {
    row <- slice$implementations[index, , drop = FALSE]
    .graph_node(
      id = paste0("impl:", row$implementation_id), shape = "box", kind = "gift",
      label = .graph_truncate(row$name, 34), sublabel = row$implementation_id,
      title = paste0(
        row$implementation_id, " \u00b7 ", row$name,
        " \u00b7 one complete curated ", view$model$implementation
      )
    )
  }))

  function_ids <- unique(slice$membership$function_id)
  function_nodes <- do.call(rbind, lapply(function_ids, function(function_id) {
    rows <- slice$membership[slice$membership$function_id == function_id, , drop = FALSE]
    used <- nrow(rows)
    accessory <- all(rows$required != 1L)
    .graph_node(
      id = paste0("fn:", function_id), shape = "step",
      kind = paste0("function", if (accessory) " accessory" else ""),
      label = .graph_truncate(rows$function_name[[1]], 30), sublabel = function_id,
      badge = paste0(
        if (accessory) "accessory" else "required", " \u00b7 ", used, "/", total, " ",
        if (total == 1L) view$model$implementation else view$model$implementation_plural
      ),
      title = paste0(
        function_id, " \u00b7 ", rows$function_name[[1]], " \u00b7 ",
        if (accessory) "accessory to " else "required by ", used, " of ", total, " ",
        if (total == 1L) view$model$implementation else view$model$implementation_plural
      )
    )
  }))

  edges <- .graph_edges(
    from = paste0("impl:", slice$membership$implementation_id),
    to = paste0("fn:", slice$membership$function_id),
    weight = ifelse(slice$membership$required == 1L, 0.75, 0.3),
    title = ifelse(
      slice$membership$required == 1L,
      "Required for this implementation",
      "Accessory: its absence does not make the implementation incomplete"
    )
  )

  .report_graph_svg(
    rbind(implementation_nodes, function_nodes), edges, marker,
    paste0("Machinery of ", gift$gift_id),
    class = "network-svg machinery-network-svg", min_width = 480, column_gap = 54
  )
}

.report_schema <- function(data) {
  table_cards <- paste(vapply(.gifter_report_tables, function(table) {
    info <- data$schema[[table]]
    foreign_columns <- if (nrow(info$foreign_keys)) info$foreign_keys$from else character()
    column_rows <- paste(vapply(seq_len(nrow(info$columns)), function(index) {
      column <- info$columns[index, , drop = FALSE]
      keys <- character()
      if (column$pk > 0L) keys <- c(keys, '<span class="key pk">PK</span>')
      if (column$name %in% foreign_columns) keys <- c(keys, '<span class="key fk">FK</span>')
      paste0(
        '<li><span class="column-name">', .html_text(column$name), "</span>",
        paste(keys, collapse = ""), '<span class="column-type">',
        .html_text(column$type), "</span></li>"
      )
    }, character(1)), collapse = "")
    paste0(
      '<article class="schema-card" data-search-item data-search="',
      .html_escape(.html_search_text(table, info$columns$name, info$columns$type)), '">',
      '<header><span class="table-icon">&#9638;</span><h3>', .html_escape(table), "</h3><span>",
      data$counts[[table]], " rows</span></header><ul>", column_rows, "</ul></article>"
    )
  }, character(1)), collapse = "")

  relationships <- do.call(rbind, lapply(data$schema, function(info) {
    if (!nrow(info$foreign_keys)) return(NULL)
    data.frame(
      from_table = info$table,
      from_column = info$foreign_keys$from,
      to_table = info$foreign_keys$table,
      to_column = info$foreign_keys$to,
      stringsAsFactors = FALSE
    )
  }))
  relationship_rows <- if (!is.null(relationships) && nrow(relationships)) {
    paste(vapply(seq_len(nrow(relationships)), function(index) {
      row <- relationships[index, , drop = FALSE]
      paste0(
        '<div class="relationship-row"><code>', .html_text(row$from_table), ".",
        .html_text(row$from_column), '</code><span class="relation-arrow">&rarr;</span><code>',
        .html_text(row$to_table), ".", .html_text(row$to_column), "</code></div>"
      )
    }, character(1)), collapse = "")
  } else {
    '<div class="empty-state compact">No foreign keys</div>'
  }

  paste0(
    '<div class="logic-strip" aria-label="Metabolic evaluation hierarchy">',
    '<span>metabolic gift</span><b>OR</b><span>gift_route</span><b>AND</b>',
    '<span>reaction</span><b>OR</b><span>enzyme_system</span><b>AND</b>',
    '<span>enzyme_component</span><b>OR</b><span>marker</span></div>',
    '<div class="logic-strip" aria-label="Machinery evaluation hierarchy">',
    '<span>structural gift</span><b>OR</b><span>gift_architecture</span><b>AND</b>',
    '<span>structural_function</span><b>OR</b><span>structural_system</span><b>AND</b>',
    '<span>structural_component</span><b>OR</b><span>marker</span></div>',
    '<div class="schema-layout"><div class="schema-grid">', table_cards, "</div>",
    '<aside class="relationships"><div class="eyebrow">Foreign keys</div><h3>Relationship inventory</h3>',
    '<p>Every arrow points from a child column to the parent key it references.</p>',
    relationship_rows, "</aside></div>"
  )
}

.report_table_cell <- function(value) {
  if (is.na(value) || !nzchar(as.character(value))) return('<td class="null">NULL</td>')
  paste0("<td>", .html_escape(value), "</td>")
}

.report_table_browser <- function(data) {
  paste(vapply(.gifter_report_tables, function(table) {
    values <- data$tables[[table]]
    header <- paste0("<tr>", paste0("<th>", .html_escape(names(values)), "</th>", collapse = ""), "</tr>")
    rows <- if (nrow(values)) paste(vapply(seq_len(nrow(values)), function(index) {
      row <- values[index, , drop = FALSE]
      paste0(
        '<tr data-table-row data-search="', .html_escape(.html_search_text(row)), '">',
        paste(vapply(row, .report_table_cell, character(1)), collapse = ""), "</tr>"
      )
    }, character(1)), collapse = "") else ""
    paste0(
      '<details class="table-panel" data-table-panel data-search-item data-table-name="',
      .html_escape(tolower(table)), '" data-search="',
      .html_escape(.html_search_text(table, values)), '"><summary><span class="table-name">',
      .html_escape(table), '</span><span class="row-count">', nrow(values), " rows &middot; ",
      ncol(values), ' columns</span></summary><div class="table-wrap"><table><thead>',
      header, "</thead><tbody>", rows, "</tbody></table></div></details>"
    )
  }, character(1)), collapse = "")
}

# The colour menu for one family of dots. "Uniform" is the drawing as it was
# before any metadata was applied, and stays the default.
.report_scheme_menu <- function(family, label) {
  options <- paste(vapply(.report_dot_schemes[[family]], function(scheme) {
    paste0(
      '<option value="', scheme[["key"]], '">',
      .html_escape(scheme[["label"]]), "</option>"
    )
  }, character(1)), collapse = "")
  paste0(
    '<label class="dot-control"><span>', .html_escape(label), "</span>",
    '<select data-colour-by="', family, '"><option value="">Uniform</option>',
    options, "</select></label>"
  )
}

.report_count_card <- function(count, label, note) {
  paste0(
    '<div class="metric-card"><strong>', format(count, big.mark = ","), "</strong>",
    '<span>', .html_escape(label), '</span><small>', .html_escape(note), "</small></div>"
  )
}

.report_reference_universes <- function(data) {
  definitions <- data$tables$reference_universe
  metric_table <- data$tables$reference_universe_metric
  scope_order <- c("genome", "community", "network")

  cards <- paste(vapply(seq_len(nrow(data$universes)), function(index) {
    universe <- data$universes[index, , drop = FALSE]
    universe_pk <- definitions$universe_pk[
      match(universe$universe_id, definitions$universe_id)
    ]
    metrics <- metric_table[metric_table$universe_pk == universe_pk, , drop = FALSE]
    scopes <- scope_order[scope_order %in% unique(metrics$scope)]
    bounded <- isTRUE(universe$bounded[[1L]])
    scope_sections <- paste(vapply(scopes, function(scope) {
      rows <- metrics[metrics$scope == scope, , drop = FALSE]
      items <- paste(vapply(seq_len(nrow(rows)), function(metric_index) {
        metric <- rows[metric_index, , drop = FALSE]
        paste0(
          '<li><code>', .html_text(metric$metric_id), '</code><span>',
          .html_text(metric$rationale), "</span></li>"
        )
      }, character(1)), collapse = "")
      paste0(
        '<section class="universe-scope"><h3>', .html_escape(.report_facet_label(scope)),
        '</h3><ul>', items, "</ul></section>"
      )
    }, character(1)), collapse = "")
    searchable <- .html_search_text(
      universe, metrics$scope, metrics$metric_id, metrics$rationale
    )

    paste0(
      '<article class="universe-card', if (bounded) " bounded" else "", '" ',
      'data-universe-card data-universe-scopes=" ', paste(scopes, collapse = " "), ' " ',
      'data-universe-bounded="', if (bounded) "true" else "false", '" data-search="',
      .html_escape(searchable), '">',
      '<header><div><div class="universe-id">', .html_text(universe$universe_id),
      '</div><h2>', .html_text(universe$label), '</h2></div>',
      '<span class="universe-bound ', if (bounded) "bounded" else "open", '">',
      if (bounded) "bounded &middot; coverage valid" else "open &middot; counts and breadth",
      '</span></header>',
      '<p class="universe-description">', .html_text(universe$description), "</p>",
      '<div class="universe-facts"><span><strong>', universe$member_count,
      '</strong> current GIFT', if (universe$member_count == 1L) "" else "s", '</span>',
      '<span><strong>', length(scopes), '</strong> analysis scale',
      if (length(scopes) == 1L) "" else "s", "</span></div>",
      '<div class="universe-call"><span>Use this preset</span><code>',
      'gift_universe(preset = &quot;', .html_text(universe$universe_id), '&quot;)',
      "</code></div>",
      '<div class="universe-metrics"><h3>Recommended analyses</h3>',
      scope_sections, "</div>",
      '<aside class="universe-interpretation"><strong>Interpret carefully</strong><span>',
      .html_text(universe$interpretation), "</span></aside>",
      '<details class="universe-definition"><summary>How membership is defined</summary>',
      '<code>', .html_text(universe$filter_expression), "</code></details></article>"
    )
  }, character(1)), collapse = "")

  paste0(
    '<section class="universe-intro" aria-label="How to choose a reference universe">',
    '<div><span>1</span><strong>Start with the biological question</strong>',
    '<p>Choose the card whose scope matches what you want to compare, not the metric ',
    'whose name sounds most familiar.</p></div>',
    '<div><span>2</span><strong>Match the unit of analysis</strong>',
    '<p>Genome metrics describe one encoded repertoire; community metrics describe ',
    'its distribution; network metrics require compatible extracellular boundaries.</p></div>',
    '<div><span>3</span><strong>Read the denominator</strong>',
    '<p>Open universes support counts and breadth. Coverage fractions are meaningful ',
    'only for universes curated as bounded.</p></div></section>',
    '<div class="universe-toolbar" aria-label="Filter reference universes by analysis scale">',
    '<span>Show questions for</span>',
    '<button type="button" class="active" data-universe-filter="all" aria-pressed="true">All data</button>',
    '<button type="button" data-universe-filter="genome" aria-pressed="false">Genomes</button>',
    '<button type="button" data-universe-filter="community" aria-pressed="false">Communities</button>',
    '<button type="button" data-universe-filter="network" aria-pressed="false">Networks</button>',
    '<button type="button" data-universe-filter="bounded" aria-pressed="false">Coverage fractions</button>',
    "</div>",
    '<div class="universe-grid">', cards, "</div>"
  )
}

.render_gifter_report <- function(data) {
  release <- data$release
  metric_cards <- paste0(
    .report_count_card(data$counts[["gift"]], "GIFTs", "curated capabilities"),
    .report_count_card(data$counts[["gift_route"]], "Routes", "alternative paths"),
    .report_count_card(data$counts[["reaction"]], "Reactions", "Rhea masters"),
    .report_count_card(data$counts[["enzyme_system"]], "Systems", "enzyme configurations"),
    .report_count_card(data$counts[["enzyme_component"]], "Components", "required proteins"),
    .report_count_card(data$counts[["marker"]], "Markers", "accepted identifiers")
  )
  css <- .gifter_report_asset("database-report.css")
  javascript <- .gifter_report_asset("database-report.js")
  logo <- sub(
    "^<\\?xml[^>]+>\\s*",
    "",
    .gifter_report_asset("gifter-logo.svg"),
    perl = TRUE
  )

  paste0(
    '<!doctype html><html lang="en"><head><meta charset="utf-8">',
    '<meta name="viewport" content="width=device-width, initial-scale=1">',
    '<meta name="color-scheme" content="light">',
    '<title>gifter reference atlas &middot; ', .html_text(release$gifter_db_version), "</title>",
    "<style>", css, "</style></head><body>",
    '<header class="site-header"><a class="brand" href="https://alberdilab.github.io/gifter/" ',
    'aria-label="gifter documentation home">',
    '<span class="brand-mark" aria-hidden="true">', logo, '</span><span><b>gift<span>er</span></b>',
    '<small>reference atlas</small></span></a>',
    '<nav class="site-nav" aria-label="Site sections">',
    '<a class="site-nav-link" href="https://alberdilab.github.io/gifter/reference/index.html">Reference</a>',
    '<details class="site-menu"><summary class="site-nav-link">Articles</summary>',
    '<div class="site-menu-list">',
    '<a href="https://alberdilab.github.io/gifter/articles/evaluating-a-genome.html">',
    '1. Evaluating a genome</a>',
    '<a href="https://alberdilab.github.io/gifter/articles/quantitative-traits.html">',
    '2. From calls to quantitative traits</a>',
    '<a href="https://alberdilab.github.io/gifter/articles/community-analysis.html">',
    '3. A genome-resolved community</a>',
    '</div></details>',
    '<a class="site-nav-link active" href="#overview" aria-current="page">GIFT atlas</a></nav>',
    '<label class="global-search"><span class="search-icon">&#8981;</span>',
    '<span class="sr-only">Search the database</span><input id="global-search" type="search" ',
    'placeholder="Search IDs, questions, markers&hellip;" autocomplete="off">',
    '<kbd>&#8984; K</kbd></label></header>',
    '<nav class="view-nav" aria-label="Atlas sections">',
    '<button class="nav-button active" data-view-button="overview">Overview</button>',
    '<button class="nav-button" data-view-button="universes">Reference universes</button>',
    '<button class="nav-button" data-view-button="gifts">GIFT explorer</button>',
    '<button class="nav-button" data-view-button="changelog">Changelog</button>',
    '<button class="nav-button" data-view-button="schema">SQL schema</button>',
    '<button class="nav-button" data-view-button="tables">Tables</button></nav>',
    '<main><section class="view active" id="overview" data-view="overview">',
    '<div class="metric-grid">', metric_cards, "</div>",
    '<section class="content-section network-overview">',
    '<div class="dot-controls">',
    .report_scheme_menu("gift", "Colour GIFTs by"),
    .report_scheme_menu("anchor", "Colour anchors by"),
    '<span class="dot-hint">Hover a dot for its detail &middot; click a GIFT to open it</span></div>',
    '<div data-graph-panel="anchors">', .report_anchor_network_svg(data),
    "</div></section></section>",
    '<section class="view" id="universes" data-view="universes"><div class="page-heading">',
    '<div><div class="eyebrow">Quantitative analysis</div><h1>Choose a reference universe</h1></div>',
    '<p>Find the curated comparison set that matches your biological question and ',
    'data scale. Every recommendation below comes from this database release.</p></div>',
    .report_reference_universes(data),
    '<div class="no-results" data-no-results>No matching reference universes.</div></section>',
    '<section class="view" id="gifts" data-view="gifts"><div class="page-heading">',
    '<div><div class="eyebrow">Biological hierarchy</div><h1>GIFT explorer</h1></div>',
    '<p>Select a GIFT to inspect its boundaries, routes, reactions, and accepted genomic evidence.</p></div>',
    .report_gift_explorer(data), '<div class="no-results" data-no-results>No matching GIFTs.</div></section>',
    '<section class="view" id="changelog" data-view="changelog"><div class="page-heading">',
    '<div><div class="eyebrow">Curation history &middot; database ',
    .html_text(release$gifter_db_version), '</div><h1>Database changelog</h1></div>',
    '<p>Every change to the biological content, why it was made, the evidence behind it, ',
    'and the traits it affects. Package and API changes are tracked separately.</p></div>',
    .report_changelog(data),
    '<div class="no-results" data-no-results>No matching changes.</div></section>',
    '<section class="view" id="schema" data-view="schema"><div class="page-heading">',
    '<div><div class="eyebrow">SQLite &middot; schema ', .html_text(release$schema_version),
    '</div><h1>Entity map</h1></div><p>Primary keys, foreign keys, and normalized tables behind the evaluation model.</p></div>',
    .report_schema(data), '<div class="no-results" data-no-results>No matching schema entities.</div></section>',
    '<section class="view" id="tables" data-view="tables"><div class="page-heading">',
    '<div><div class="eyebrow">Complete snapshot</div><h1>Table browser</h1></div>',
    '<p>All compiled rows are shown here. Search globally, then expand a table to inspect exact values.</p></div>',
    '<div class="table-list">', .report_table_browser(data),
    '</div><div class="no-results" data-no-results>No matching table rows.</div></section></main>',
    '<footer><span>gifter reference atlas</span><span>Generated from database release ',
    .html_text(release$gifter_db_version), " &middot; ", .html_text(release$build_date), "</span></footer>",
    '<div class="search-status" id="search-status" role="status" aria-live="polite"></div>',
    "<script>", javascript, "</script></body></html>"
  )
}

#' Write an interactive HTML atlas of the gifter database
#'
#' Creates a dependency-free HTML report containing release metadata, table
#' counts, a searchable guide to curated reference universes, a complete
#' biological hierarchy, the SQL schema, and a searchable browser for every
#' table. Two network views are drawn as inline SVG. The
#' overview network draws every GIFT together with its declared anchors as an
#' unlabelled force directed map in which a GIFT is a large dot and an anchor a
#' small one: hovering a dot dims everything it is not connected to and prints
#' its identifier, boundaries, and content, and clicking a GIFT opens it in the
#' explorer. Two menus recolour that drawing by curated metadata -- GIFTs by
#' type, mode, substrate class, or physiological role, anchors by boundary use,
#' compartment, molecular tier, resource origin, or biomass essentiality -- and
#' the key for whichever scheme is showing sits in the corner of the figure.
#' The second network is drawn for each GIFT: a merged route network in which
#' alternative routes are overlaid on the reactions they share. The GIFT table
#' can be grouped by category and filtered by start and end anchor, and a
#' selected GIFT opens in a dialog over the table. All styles, scripts, and data
#' are embedded so the output can be opened or shared as one file.
#'
#' @param output Path of the HTML file to create.
#' @param database Optional SQLite path or open DBI connection. By default, the
#'   packaged gifter reference database is used.
#' @param open Open the report in the default browser after writing it.
#' @return The normalized output path, invisibly.
#' @section Compatibility:
#' `write_giftr_database_html()` is retained as an alias for code written
#' before the package was renamed to gifter.
#' @export
write_gifter_database_html <- function(
  output = "gifter-database.html",
  database = NULL,
  open = FALSE
) {
  if (length(output) != 1L || is.na(output) || !nzchar(trimws(output))) {
    stop("output must be one non-empty path", call. = FALSE)
  }
  if (!grepl("[.]html?$", output, ignore.case = TRUE)) {
    stop("output must have an .html or .htm extension", call. = FALSE)
  }

  owned <- FALSE
  connection <- database
  if (is.null(database) || is.character(database)) {
    if (is.character(database) && (length(database) != 1L || !file.exists(database))) {
      stop("SQLite database does not exist: ", paste(database, collapse = ""), call. = FALSE)
    }
    connection <- gifter_db_connect(if (is.character(database)) database else NULL)
    owned <- TRUE
  }
  if (!inherits(connection, "DBIConnection") || !DBI::dbIsValid(connection)) {
    stop("database must be a SQLite path or valid DBI connection", call. = FALSE)
  }
  if (owned) on.exit(DBI::dbDisconnect(connection), add = TRUE)

  data <- .gifter_report_data(connection)
  html <- .render_gifter_report(data)
  output <- normalizePath(output, winslash = "/", mustWork = FALSE)
  dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
  writeLines(html, output, useBytes = TRUE)
  if (isTRUE(open)) utils::browseURL(output)
  invisible(output)
}

#' @rdname write_gifter_database_html
#' @export
write_giftr_database_html <- function(
  output = "gifter-database.html",
  database = NULL,
  open = FALSE
) {
  write_gifter_database_html(output = output, database = database, open = open)
}
