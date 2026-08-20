.gifter_database_path <- function() {
  path <- system.file("extdata", "gifter.sqlite", package = "gifter")
  if (nzchar(path) && file.exists(path)) return(path)
  candidate <- file.path("inst", "extdata", "gifter.sqlite")
  if (file.exists(candidate)) return(normalizePath(candidate, winslash = "/"))
  stop(
    "The packaged gifter reference database is unavailable. Reinstall the package or supply a database connection.",
    call. = FALSE
  )
}

.as_tibble_query <- function(connection, sql, params = NULL) {
  value <- if (is.null(params)) {
    DBI::dbGetQuery(connection, sql)
  } else {
    DBI::dbGetQuery(connection, sql, params = params)
  }
  tibble::as_tibble(value)
}

.with_gifter_db <- function(db, code) {
  owned <- is.null(db)
  if (owned) db <- gifter_db_connect()
  if (!inherits(db, "DBIConnection") || !DBI::dbIsValid(db)) {
    stop("db must be a valid DBI connection", call. = FALSE)
  }
  if (owned) on.exit(DBI::dbDisconnect(db), add = TRUE)
  code(db)
}

.gifter_database_version_value <- function(version) {
  value <- version$gifter_db_version
  if (is.null(value)) value <- version$giftr_db_version
  value
}

.normalize_gift_id <- function(gift_id) {
  if (length(gift_id) != 1L || is.na(gift_id) || !nzchar(trimws(gift_id))) {
    stop("gift_id must be one non-empty value", call. = FALSE)
  }
  trimws(as.character(gift_id))
}

# A reaction is addressed by its stable curator-facing identifier, which equals
# the Rhea master wherever one exists. Bare digits are read as a Rhea master so
# that get_reaction(15753) keeps working.
.normalize_reaction_key <- function(reaction) {
  if (length(reaction) != 1L || is.na(reaction) || !nzchar(trimws(as.character(reaction)))) {
    stop("reaction must be one non-empty value", call. = FALSE)
  }
  value <- trimws(as.character(reaction))
  if (grepl("^[0-9]+$", value)) return(paste0("RHEA:", value))
  if (grepl("^rhea:[0-9]+$", value, ignore.case = TRUE)) return(toupper(value))
  value
}

#' Connect to a gifter SQLite database
#'
#' @param path SQLite database path. By default, the packaged reference
#'   database is opened.
#' @param read_only Open the database read-only. This is recommended for
#'   annotation workflows.
#' @return A DBI connection. Close it with [gifter_db_disconnect()].
#' @section Compatibility:
#' `giftr_db_connect()` is retained as an alias for code written before the
#' package was renamed to gifter.
#' @export
gifter_db_connect <- function(path = NULL, read_only = TRUE) {
  if (is.null(path)) path <- .gifter_database_path()
  if (length(path) != 1L || !file.exists(path)) {
    stop("SQLite database does not exist: ", path, call. = FALSE)
  }
  flags <- if (isTRUE(read_only)) RSQLite::SQLITE_RO else RSQLite::SQLITE_RWC
  connection <- DBI::dbConnect(RSQLite::SQLite(), dbname = path, flags = flags)
  DBI::dbExecute(connection, "PRAGMA foreign_keys = ON")
  connection
}

#' Disconnect from a gifter database
#'
#' @param db A connection returned by [gifter_db_connect()].
#' @return `TRUE`, invisibly, when the connection is closed.
#' @section Compatibility:
#' `giftr_db_disconnect()` is retained as an alias for code written before the
#' package was renamed to gifter.
#' @export
gifter_db_disconnect <- function(db) {
  if (!inherits(db, "DBIConnection")) stop("db must be a DBI connection", call. = FALSE)
  DBI::dbDisconnect(db)
}

#' Report gifter package and database versions
#'
#' The biological database version is deliberately independent of the R
#' package version.
#'
#' @param db Optional open gifter database connection.
#' @return A one-row tibble containing package, database, schema, and upstream
#'   source versions. The deprecated `giftr_db_version` column duplicates
#'   `gifter_db_version` for compatibility with existing result consumers.
#' @section Compatibility:
#' `giftr_db_version()` is retained as an alias for code written before the
#' package was renamed to gifter.
#' @export
gifter_db_version <- function(db = NULL) {
  .with_gifter_db(db, function(connection) {
    result <- .as_tibble_query(
      connection,
      paste(
        "SELECT gifter_db_version, schema_version, build_date,",
        "rhea_release, chebi_release, kegg_release, source_commit",
        "FROM database_release WHERE release_pk = 1"
      )
    )
    result$package_version <- as.character(utils::packageVersion("gifter"))
    result$giftr_db_version <- result$gifter_db_version
    result[c(
      "package_version", "gifter_db_version", "giftr_db_version",
      "schema_version", "build_date",
      "rhea_release", "chebi_release", "kegg_release", "source_commit"
    )]
  })
}

#' @rdname gifter_db_connect
#' @export
giftr_db_connect <- function(path = NULL, read_only = TRUE) {
  gifter_db_connect(path = path, read_only = read_only)
}

#' @rdname gifter_db_disconnect
#' @export
giftr_db_disconnect <- function(db) {
  gifter_db_disconnect(db)
}

#' @rdname gifter_db_version
#' @export
giftr_db_version <- function(db = NULL) {
  gifter_db_version(db)
}

#' List curated genome-inferred functional traits
#'
#' `gift_type` names the completeness model behind each capability:
#' `metabolic` GIFTs are complete when a curated enzymatic route is complete,
#' and `structural`, `regulatory` and `defense` GIFTs when a curated
#' architecture, circuit or defense mechanism is complete. `mode` is a property
#' of the metabolic model and is `NA` for the other types.
#'
#' @param status Optional status filter such as `"curated"`.
#' @param type Optional GIFT type filter: `"metabolic"`, `"structural"`,
#'   `"regulatory"` or `"defense"`.
#' @param db Optional open gifter database connection.
#' @return A tibble with one row per GIFT.
#' @export
list_gifts <- function(status = NULL, type = NULL, db = NULL) {
  if (!is.null(type)) type <- match.arg(type, .gifter_gift_types, several.ok = TRUE)
  .with_gifter_db(db, function(connection) {
    sql <- paste(
      "SELECT gift_id, gift_type, name, description, mode, status, version, notes",
      "FROM gift"
    )
    conditions <- character()
    params <- list()
    if (!is.null(status)) {
      conditions <- c(conditions, "status = ?")
      params <- c(params, list(as.character(status)))
    }
    if (!is.null(type)) {
      conditions <- c(
        conditions,
        paste0("gift_type IN (", paste(rep("?", length(type)), collapse = ", "), ")")
      )
      params <- c(params, as.list(type))
    }
    if (length(conditions)) sql <- paste(sql, "WHERE", paste(conditions, collapse = " AND "))
    sql <- paste(sql, "ORDER BY gift_id")
    .as_tibble_query(connection, sql, if (length(params)) params else NULL)
  })
}

#' Get a GIFT definition
#'
#' @param gift_id Stable GIFT identifier.
#' @param db Optional open gifter database connection.
#' @return A zero- or one-row tibble.
#' @export
get_gift <- function(gift_id, db = NULL) {
  gift_id <- .normalize_gift_id(gift_id)
  .with_gifter_db(db, function(connection) {
    .as_tibble_query(
      connection,
      paste(
        "SELECT gift_id, gift_type, name, description, mode, status, version, notes",
        "FROM gift WHERE gift_id = ?"
      ),
      list(gift_id)
    )
  })
}

#' Get the declared molecular anchors of a GIFT
#'
#' @inheritParams get_gift
#' @return A tibble ordered by boundary role and ordinal.
#' @export
get_gift_anchors <- function(gift_id, db = NULL) {
  gift_id <- .normalize_gift_id(gift_id)
  .with_gifter_db(db, function(connection) {
    .as_tibble_query(
      connection,
      paste(
        "SELECT g.gift_id, ga.role, ga.ordinal, a.anchor_id, a.molecule,",
        "a.compartment, a.name, a.chebi_id, a.description",
        "FROM gift g",
        "JOIN gift_anchor ga ON ga.gift_pk = g.gift_pk",
        "JOIN anchor a ON a.anchor_pk = ga.anchor_pk",
        "WHERE g.gift_id = ?",
        "ORDER BY CASE ga.role WHEN 'input' THEN 1 ELSE 2 END, ga.ordinal"
      ),
      list(gift_id)
    )
  })
}

#' Get related external pathways for a GIFT
#'
#' A GIFT is a curated capability between declared anchors, never a pathway
#' record. These references say how the curated boundaries compare with an
#' external pathway, so that a GIFT can be found from the resource a user
#' already knows without implying that the two definitions are the same.
#'
#' `relation` is one of `equivalent`, `subset_of`, `superset_of`, `overlaps`,
#' or `related`, read as "this GIFT is ... the external pathway". The namespace
#' is open; `KEGG_MODULE` and `KEGG_PATHWAY` are curated today.
#'
#' @inheritParams get_gift
#' @param namespace Optional namespace filter such as `"KEGG_MODULE"`.
#' @return A tibble with one row per related pathway.
#' @export
get_gift_pathways <- function(gift_id, namespace = NULL, db = NULL) {
  gift_id <- .normalize_gift_id(gift_id)
  .with_gifter_db(db, function(connection) {
    sql <- paste(
      "SELECT g.gift_id, gx.namespace, gx.accession, gx.name, gx.relation, gx.notes",
      "FROM gift g",
      "JOIN gift_xref gx ON gx.gift_pk = g.gift_pk",
      "WHERE g.gift_id = ?"
    )
    params <- list(gift_id)
    if (!is.null(namespace)) {
      sql <- paste(sql, "AND gx.namespace = ?")
      params <- c(params, list(as.character(namespace)))
    }
    sql <- paste(sql, "ORDER BY gx.namespace, gx.accession")
    .as_tibble_query(connection, sql, params)
  })
}

#' Find GIFTs related to an external pathway
#'
#' The reverse of [get_gift_pathways()]: given a pathway identifier from another
#' resource, report which curated GIFTs relate to it and how.
#'
#' @param accession External pathway accession such as `"M00018"`.
#' @param namespace Optional namespace filter such as `"KEGG_MODULE"`.
#' @param db Optional open gifter database connection.
#' @return A tibble with one row per related GIFT.
#' @export
gifts_for_pathway <- function(accession, namespace = NULL, db = NULL) {
  if (length(accession) != 1L || is.na(accession) || !nzchar(trimws(accession))) {
    stop("accession must be one non-empty value", call. = FALSE)
  }
  accession <- trimws(as.character(accession))
  .with_gifter_db(db, function(connection) {
    sql <- paste(
      "SELECT gx.namespace, gx.accession, gx.name, gx.relation, g.gift_id,",
      "g.name AS gift_name, gx.notes",
      "FROM gift_xref gx",
      "JOIN gift g ON g.gift_pk = gx.gift_pk",
      "WHERE gx.accession = ?"
    )
    params <- list(accession)
    if (!is.null(namespace)) {
      sql <- paste(sql, "AND gx.namespace = ?")
      params <- c(params, list(as.character(namespace)))
    }
    sql <- paste(sql, "ORDER BY gx.namespace, g.gift_id")
    .as_tibble_query(connection, sql, params)
  })
}

#' Get alternative routes for a GIFT
#'
#' @inheritParams get_gift
#' @return A tibble with one row per route.
#' @export
get_gift_routes <- function(gift_id, db = NULL) {
  gift_id <- .normalize_gift_id(gift_id)
  .with_gifter_db(db, function(connection) {
    .as_tibble_query(
      connection,
      paste(
        "SELECT g.gift_id, gr.route_id, gr.name, gr.description, gr.status,",
        "SUM(CASE WHEN rr.required = 1 THEN 1 ELSE 0 END) AS required_reactions",
        "FROM gift g",
        "JOIN gift_route gr ON gr.gift_pk = g.gift_pk",
        "LEFT JOIN route_reaction rr ON rr.route_pk = gr.route_pk",
        "WHERE g.gift_id = ?",
        "GROUP BY gr.route_pk ORDER BY gr.route_id"
      ),
      list(gift_id)
    )
  })
}

#' Get route reactions for a GIFT
#'
#' @inheritParams get_gift
#' @return A long-form tibble with route, reaction, direction, and step order.
#' @export
get_gift_reactions <- function(gift_id, db = NULL) {
  gift_id <- .normalize_gift_id(gift_id)
  .with_gifter_db(db, function(connection) {
    .as_tibble_query(
      connection,
      paste(
        "SELECT g.gift_id, gr.route_id, rr.step_order, rr.required,",
        "r.reaction_id, r.rhea_master, r.name AS reaction_name,",
        "rr.orientation, r.description",
        "FROM gift g",
        "JOIN gift_route gr ON gr.gift_pk = g.gift_pk",
        "JOIN route_reaction rr ON rr.route_pk = gr.route_pk",
        "JOIN reaction r ON r.reaction_pk = rr.reaction_pk",
        "WHERE g.gift_id = ?",
        "ORDER BY gr.route_id, rr.step_order"
      ),
      list(gift_id)
    )
  })
}

#' Get a reaction used by gifter
#'
#' Reactions are identified by a stable `reaction_id`, which is the Rhea master
#' identifier wherever Rhea covers the chemistry. Polymer-acting reactions
#' frequently have no Rhea master, because a polysaccharide is a substrate class
#' rather than a compound with a balanced equation; those carry a curated
#' identifier and at least one cross-reference instead.
#'
#' @param reaction A `reaction_id` or a Rhea master ID, with or without the
#'   `RHEA:` prefix.
#' @param db Optional open gifter database connection.
#' @return A zero- or one-row tibble.
#' @export
get_reaction <- function(reaction, db = NULL) {
  key <- .normalize_reaction_key(reaction)
  .with_gifter_db(db, function(connection) {
    .as_tibble_query(
      connection,
      paste(
        "SELECT reaction_id, rhea_master, name, description FROM reaction",
        "WHERE reaction_id = ? OR rhea_master = ?"
      ),
      list(key, key)
    )
  })
}

#' Get enzyme systems, components, and accepted markers for a reaction
#'
#' @inheritParams get_reaction
#' @return A long-form tibble. Multiple components within a system are AND;
#'   multiple markers for a component are OR.
#' @export
get_reaction_systems <- function(reaction, db = NULL) {
  key <- .normalize_reaction_key(reaction)
  .with_gifter_db(db, function(connection) {
    .as_tibble_query(
      connection,
      paste(
        "SELECT r.reaction_id, r.rhea_master, es.system_id, es.name AS system_name,",
        "ec.component_id, ec.name AS component_name,",
        "m.namespace, m.accession, m.name AS marker_name,",
        "cm.evidence_type, cm.confidence, cm.source, cm.notes",
        "FROM reaction r",
        "JOIN enzyme_system es ON es.reaction_pk = r.reaction_pk",
        "JOIN enzyme_component ec ON ec.system_pk = es.system_pk",
        "JOIN component_marker cm ON cm.component_pk = ec.component_pk",
        "JOIN marker m ON m.marker_pk = cm.marker_pk",
        "WHERE r.reaction_id = ? OR r.rhea_master = ?",
        "ORDER BY es.system_id, ec.component_id, m.namespace, m.accession"
      ),
      list(key, key)
    )
  })
}

#' Read the curation history of the biological database
#'
#' Returns the changes made to the reference database, newest first, with the
#' GIFTs each change affects. This is the biological changelog only; code and
#' public API changes are recorded in the package changelog.
#'
#' @param gift_id Optional GIFT identifier. When supplied, only changes
#'   affecting that GIFT are returned.
#' @param db Optional open gifter database connection.
#' @return A tibble with one row per change. The `gifts` list column holds the
#'   affected GIFT identifiers.
#' @export
database_changelog <- function(gift_id = NULL, db = NULL) {
  if (!is.null(gift_id)) gift_id <- .normalize_gift_id(gift_id)
  .with_gifter_db(db, function(connection) {
    sql <- paste(
      "SELECT c.change_pk, c.change_id, c.released, c.changed_at, c.layer,",
      "c.category, c.call_effect, c.summary, c.rationale, c.evidence, c.effect",
      "FROM database_change c"
    )
    params <- NULL
    if (!is.null(gift_id)) {
      sql <- paste(
        sql,
        "WHERE EXISTS (SELECT 1 FROM change_gift cg JOIN gift g ON g.gift_pk = cg.gift_pk",
        "WHERE cg.change_pk = c.change_pk AND g.gift_id = ?)"
      )
      params <- list(gift_id)
    }
    sql <- paste(sql, "ORDER BY c.changed_at DESC, c.change_id")
    changes <- .as_tibble_query(connection, sql, params)

    links <- .as_tibble_query(
      connection,
      paste(
        "SELECT c.change_id, g.gift_id FROM change_gift cg",
        "JOIN database_change c ON c.change_pk = cg.change_pk",
        "JOIN gift g ON g.gift_pk = cg.gift_pk",
        "ORDER BY c.change_id, g.gift_id"
      )
    )
    changes$gifts <- lapply(changes$change_id, function(id) links$gift_id[links$change_id == id])
    changes[setdiff(names(changes), "change_pk")]
  })
}

#' Get the curated facets of a GIFT or an anchor
#'
#' Facets classify a capability; they never enter the completeness logic that
#' produces a call. `substrate_class` is single-valued so that it can partition
#' the database; `physiological_role` and the anchor facets are multi-valued,
#' so filtering on them returns supersets rather than partitions.
#'
#' @param id A `gift_id`, or an `anchor_id` when `target = "anchor"`.
#' @param target Whether `id` names a GIFT or an anchor.
#' @param db Optional open gifter database connection.
#' @return A tibble with one row per assigned facet value.
#' @export
get_facets <- function(id, target = c("gift", "anchor"), db = NULL) {
  target <- match.arg(target)
  id <- .normalize_gift_id(id)
  .with_gifter_db(db, function(connection) {
    sql <- if (identical(target, "gift")) {
      paste(
        "SELECT g.gift_id AS id, f.facet, f.value, t.definition, f.notes",
        "FROM gift g JOIN gift_facet f ON f.gift_pk = g.gift_pk",
        "JOIN facet_term t ON t.facet = f.facet AND t.value = f.value",
        "WHERE g.gift_id = ? ORDER BY f.facet, f.value"
      )
    } else {
      paste(
        "SELECT a.anchor_id AS id, f.facet, f.value, t.definition, f.notes",
        "FROM anchor a JOIN anchor_facet f ON f.anchor_pk = a.anchor_pk",
        "JOIN facet_term t ON t.facet = f.facet AND t.value = f.value",
        "WHERE a.anchor_id = ? ORDER BY f.facet, f.value"
      )
    }
    .as_tibble_query(connection, sql, list(id))
  })
}

#' List the registered facet vocabulary
#'
#' The vocabulary is open to new facets and closed within a facet: the build
#' rejects any assignment whose `facet`/`value` pair is not registered here.
#'
#' @param facet Optional facet name to filter by.
#' @param db Optional open gifter database connection.
#' @return A tibble of registered terms with their definitions.
#' @export
list_facets <- function(facet = NULL, db = NULL) {
  .with_gifter_db(db, function(connection) {
    sql <- "SELECT facet, value, applies_to, definition FROM facet_term"
    params <- NULL
    if (!is.null(facet)) {
      sql <- paste(sql, "WHERE facet = ?")
      params <- list(as.character(facet))
    }
    .as_tibble_query(connection, paste(sql, "ORDER BY facet, value"), params)
  })
}

#' Find GIFTs by a curated facet value
#'
#' @param facet Facet name, such as `"physiological_role"`.
#' @param value Facet value, such as `"fibre_degradation"`.
#' @param db Optional open gifter database connection.
#' @return A tibble of matching GIFTs.
#' @export
gifts_by_facet <- function(facet, value, db = NULL) {
  .with_gifter_db(db, function(connection) {
    .as_tibble_query(
      connection,
      paste(
        "SELECT g.gift_id, g.gift_type, g.name, g.mode, f.facet, f.value",
        "FROM gift g JOIN gift_facet f ON f.gift_pk = g.gift_pk",
        "WHERE f.facet = ? AND f.value = ? ORDER BY g.gift_id"
      ),
      list(as.character(facet), as.character(value))
    )
  })
}

#' Derived ecological and physiological profile of each metabolic GIFT
#'
#' Nothing in the profile is curated. Every field is computed from declared
#' anchors, anchor facets, and the composition graph, all of which belong to the
#' metabolic model, so non-metabolic GIFTs are absent rather than carrying an
#' empty row. Reporting a resource strategy for a flagellum would invent one.
#'
#' `resource_strategy` is the degrader-versus-forager distinction the anchor
#' compartment field exists to support: `uptake` consumes outside and delivers
#' inside, `public_good` consumes and releases outside, `private` stays
#' internal, and `unresolved` means a compartment was never licensed, which is a
#' real answer rather than a gap.
#'
#' @param db Optional open gifter database connection.
#' @return A tibble with one row per metabolic GIFT.
#' @export
gift_profile <- function(db = NULL) {
  .with_gifter_db(db, function(connection) {
    .as_tibble_query(
      connection,
      paste(
        "SELECT gift_id, mode, substrate_class, substrate_tier, resource_strategy,",
        "network_position, cross_feeding_output, auxotrophy_indicator",
        "FROM gift_profile ORDER BY gift_id"
      )
    )
  })
}

#' Derive the directed GIFT graph from shared anchors
#'
#' Only declared output and input anchors create graph edges. Internal reaction
#' metabolites are not stored in the anchor table and therefore cannot create
#' implicit connections.
#'
#' `edge_quality` is `exact` when both GIFTs declare the same anchor, and
#' `compartment_inexact` when they declare the same molecule but one side leaves
#' the compartment unresolved. An inexact edge is a real composition step whose
#' location was not evidenced well enough to split; a chain assembled only from
#' exact edges is the stronger claim. Two anchors whose compartments are both
#' specified and different are never connected, so a transport GIFT is required
#' to cross that boundary.
#'
#' @param db Optional open gifter database connection.
#' @param quality Optional filter, `"exact"` or `"compartment_inexact"`.
#' @return A tibble with `from_gift`, `shared_anchor`, `to_anchor`,
#'   `shared_molecule`, `edge_quality`, and `to_gift`.
#' @export
gift_graph <- function(db = NULL, quality = NULL) {
  if (!is.null(quality)) {
    quality <- match.arg(quality, c("exact", "compartment_inexact"))
  }
  .with_gifter_db(db, function(connection) {
    sql <- paste(
      "SELECT from_gift, shared_anchor, to_anchor, shared_molecule,",
      "edge_quality, to_gift FROM gift_graph"
    )
    params <- NULL
    if (!is.null(quality)) {
      sql <- paste(sql, "WHERE edge_quality = ?")
      params <- list(quality)
    }
    sql <- paste(sql, "ORDER BY from_gift, shared_anchor, to_gift")
    .as_tibble_query(connection, sql, params)
  })
}

#' Get the curated machinery of a non-metabolic GIFT
#'
#' The machinery analogue of [get_gift_reactions()] and
#' [get_reaction_systems()]. A structural, regulatory or defense GIFT is
#' complete when at least one of its curated implementations -- an
#' architecture, a circuit, a defense mechanism -- has every required function
#' supported, so this returns that hierarchy in one long-form table:
#' implementation, function, system, component and accepted marker.
#'
#' Reading it: implementations are alternatives (OR), the required functions of
#' one implementation are jointly needed (AND), the systems of one function are
#' alternatives (OR), the components of one system are jointly needed (AND),
#' and the markers of one component are alternatives (OR).
#'
#' @inheritParams get_gift
#' @return A long-form tibble. The implementation column is named for the GIFT
#'   type: `architecture_id`, `circuit_id` or `mechanism_id`. Calling this on a
#'   metabolic GIFT is an error, because a metabolic GIFT has routes instead.
#' @export
get_gift_machinery <- function(gift_id, db = NULL) {
  gift_id <- .normalize_gift_id(gift_id)
  .with_gifter_db(db, function(connection) {
    type <- .as_tibble_query(
      connection, "SELECT gift_type FROM gift WHERE gift_id = ?", list(gift_id)
    )
    if (!nrow(type)) stop("Unknown gift_id: ", gift_id, call. = FALSE)
    type <- type$gift_type[[1]]
    if (identical(type, "metabolic")) {
      stop(
        gift_id, " is a metabolic GIFT; use get_gift_routes() and ",
        "get_gift_reactions() instead.",
        call. = FALSE
      )
    }
    model <- .gifter_machinery_models[[type]]
    result <- .as_tibble_query(
      connection,
      paste0(
        "SELECT g.gift_id, g.gift_type, i.", model$implementation_id, ", i.name AS ",
        model$implementation, "_name, mf.ordinal, mf.required, ",
        "f.function_id, f.name AS function_name, s.system_id, s.name AS system_name, ",
        "c.component_id, c.name AS component_name, m.namespace, m.accession, ",
        "e.evidence_type, e.confidence, e.source, e.notes ",
        "FROM gift g ",
        "JOIN ", model$implementation_table, " i ON i.gift_pk = g.gift_pk ",
        "JOIN ", model$membership_table, " mf ON mf.", model$implementation_pk,
        " = i.", model$implementation_pk, " ",
        "JOIN ", model$function_table, " f ON f.function_pk = mf.function_pk ",
        "JOIN ", model$system_table, " s ON s.function_pk = f.function_pk ",
        "JOIN ", model$component_table, " c ON c.system_pk = s.system_pk ",
        "JOIN ", model$evidence_table, " e ON e.component_pk = c.component_pk ",
        "JOIN marker m ON m.marker_pk = e.marker_pk ",
        "WHERE g.gift_id = ? ",
        "ORDER BY i.", model$implementation_id,
        ", mf.ordinal, s.system_id, c.component_id, m.namespace, m.accession"
      ),
      list(gift_id)
    )
    result$required <- as.logical(result$required)
    result
  })
}
