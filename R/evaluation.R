.normalize_marker_namespace <- function(namespace) {
  value <- toupper(trimws(as.character(namespace)))
  aliases <- c(
    KEGG = "KO", KEGG_ORTHOLOGY = "KO", KEGGORTHOLOGY = "KO",
    ENZYME_COMMISSION = "EC", PFAM = "PFAM", TIGRFAM = "TIGRFAM"
  )
  replace <- value %in% names(aliases)
  value[replace] <- unname(aliases[value[replace]])
  value[!nzchar(value)] <- NA_character_
  value
}

.infer_marker_namespace <- function(accession) {
  value <- toupper(trimws(as.character(accession)))
  result <- rep(NA_character_, length(value))
  result[grepl("^(KO:)?K[0-9]{5}$", value)] <- "KO"
  result[grepl("^(EC:)?[0-9]+(\\.[0-9-]+){1,3}$", value)] <- "EC"
  result[grepl("^PF[0-9]{5}(\\.[0-9]+)?$", value)] <- "PFAM"
  result[grepl("^TIGR[0-9]{5}$", value)] <- "TIGRFAM"
  # CAZy accessions as reported by dbCAN, in three forms: the bare family
  # (GH5), the official CAZy subfamily (GH5_4), and the dbCAN-sub eCAMI cluster
  # (GH5_e12), which is what dbCAN-sub names in its own output. Each is a
  # distinct accession and none implies another: GH5 is evidence for any of the
  # activities the family carries, a subfamily for the narrower set its members
  # carry.
  result[grepl("^(GH|GT|PL|CE|AA|CBM)[0-9]+(_(E[0-9]+|[0-9]+))?$", value)] <- "CAZY"
  result
}

.normalize_marker_accession <- function(namespace, accession) {
  value <- trimws(as.character(accession))
  value[!nzchar(value)] <- NA_character_
  ko <- namespace == "KO" & !is.na(namespace) & !is.na(value)
  value[ko] <- toupper(sub("^KO:", "", value[ko], ignore.case = TRUE))
  ec <- namespace == "EC" & !is.na(namespace) & !is.na(value)
  value[ec] <- sub("^EC:", "", value[ec], ignore.case = TRUE)
  value[ec] <- gsub("^\\[|\\]$", "", value[ec])
  upper <- namespace %in% c("PFAM", "TIGRFAM", "CAZY", "CUSTOM_HMM") & !is.na(namespace)
  value[upper] <- toupper(value[upper])
  # An eCAMI cluster suffix is lower-case by construction (GH5_e12); uppercasing
  # the accession would silently mint an identifier that matches nothing.
  cazy <- namespace == "CAZY" & !is.na(namespace) & !is.na(value)
  value[cazy] <- sub("_E([0-9]+)$", "_e\\1", value[cazy])
  value
}

.prepare_observed_markers <- function(annotation_table, namespace = NULL) {
  if (is.character(annotation_table) && is.null(dim(annotation_table))) {
    accession <- annotation_table
    if (is.null(namespace)) namespace <- .infer_marker_namespace(accession)
    if (length(namespace) == 1L) namespace <- rep(namespace, length(accession))
    if (length(namespace) != length(accession)) {
      stop("namespace must have length one or match the marker vector", call. = FALSE)
    }
    gene_id <- names(annotation_table)
    if (is.null(gene_id)) {
      gene_id <- if (length(accession)) paste0("marker_", seq_along(accession)) else character()
    }
    data <- data.frame(
      gene_id = gene_id,
      namespace = namespace,
      accession = unname(accession),
      stringsAsFactors = FALSE
    )
  } else if (is.data.frame(annotation_table)) {
    required <- c("namespace", "accession")
    missing <- setdiff(required, names(annotation_table))
    if (length(missing)) {
      stop(
        "annotation_table is missing columns: ", paste(missing, collapse = ", "),
        call. = FALSE
      )
    }
    data <- annotation_table[c("namespace", "accession")]
    data$gene_id <- if ("gene_id" %in% names(annotation_table)) {
      as.character(annotation_table$gene_id)
    } else {
      if (nrow(annotation_table)) paste0("marker_", seq_len(nrow(annotation_table))) else character()
    }
    data <- data[c("gene_id", "namespace", "accession")]
  } else {
    stop("annotation_table must be a character vector or data frame", call. = FALSE)
  }

  data$namespace <- .normalize_marker_namespace(data$namespace)
  inferred <- is.na(data$namespace) & !is.na(data$accession)
  data$namespace[inferred] <- .infer_marker_namespace(data$accession[inferred])
  data$accession <- .normalize_marker_accession(data$namespace, data$accession)
  if (any(is.na(data$namespace) & !is.na(data$accession))) {
    unknown <- unique(data$accession[is.na(data$namespace) & !is.na(data$accession)])
    stop(
      "Could not infer namespaces for markers: ", paste(unknown, collapse = ", "),
      ". Supply an explicit namespace column.",
      call. = FALSE
    )
  }
  data$observed_marker_id <- seq_len(nrow(data))
  tibble::as_tibble(data[c("observed_marker_id", "gene_id", "namespace", "accession")])
}

.marker_hierarchy_query <- function(connection, keys) {
  columns <- c(
    "namespace", "accession", "marker_pk", "marker_name", "component_pk", "component_id", "system_pk",
    "system_id", "reaction_pk", "reaction_id", "rhea_master", "evidence_type", "confidence",
    "source", "notes"
  )
  if (!nrow(keys)) {
    empty <- stats::setNames(replicate(length(columns), character(), simplify = FALSE), columns)
    empty$marker_pk <- integer()
    empty$component_pk <- integer()
    empty$system_pk <- integer()
    empty$reaction_pk <- integer()
    return(tibble::as_tibble(empty))
  }

  chunks <- split(seq_len(nrow(keys)), ceiling(seq_len(nrow(keys)) / 300))
  results <- lapply(chunks, function(index) {
    chunk <- keys[index, , drop = FALSE]
    predicates <- paste(rep("(m.namespace = ? AND m.accession = ?)", nrow(chunk)), collapse = " OR ")
    params <- as.list(as.vector(t(as.matrix(chunk[c("namespace", "accession")]))))
    DBI::dbGetQuery(
      connection,
      paste(
        "SELECT m.namespace, m.accession, m.marker_pk, m.name AS marker_name,",
        "ec.component_pk, ec.component_id, es.system_pk, es.system_id,",
        "r.reaction_pk, r.reaction_id, r.rhea_master, cm.evidence_type, cm.confidence,",
        "cm.source, cm.notes",
        "FROM marker m",
        "JOIN component_marker cm ON cm.marker_pk = m.marker_pk",
        "JOIN enzyme_component ec ON ec.component_pk = cm.component_pk",
        "JOIN enzyme_system es ON es.system_pk = ec.system_pk",
        "JOIN reaction r ON r.reaction_pk = es.reaction_pk",
        "WHERE", predicates
      ),
      params = params
    )
  })
  tibble::as_tibble(do.call(rbind, results))
}

#' Map observed genomic markers to enzyme components
#'
#' Marker namespaces and accessions are normalized before indexed lookups. The
#' result retains unmatched observations, making marker use auditable.
#'
#' @param annotation_table A data frame with `namespace` and `accession`
#'   columns and an optional `gene_id` column, or a character vector of marker
#'   accessions.
#' @param namespace Namespace for a character-vector input. If omitted, KO, EC,
#'   Pfam, and TIGRFAM accessions are inferred where possible.
#' @param db Optional open giftr database connection.
#' @return A long-form tibble linking each observation to zero or more enzyme
#'   components and reactions. `matched` is `FALSE` for unused markers.
#' @export
map_markers <- function(annotation_table, namespace = NULL, db = NULL) {
  observed <- .prepare_observed_markers(annotation_table, namespace)
  .with_giftr_db(db, function(connection) {
    keys <- unique(observed[!is.na(observed$namespace) & !is.na(observed$accession), c("namespace", "accession")])
    hierarchy <- .marker_hierarchy_query(connection, keys)
    mapped <- merge(
      as.data.frame(observed),
      as.data.frame(hierarchy),
      by = c("namespace", "accession"),
      all.x = TRUE,
      sort = FALSE
    )
    mapped <- mapped[order(mapped$observed_marker_id, mapped$component_id, na.last = TRUE), , drop = FALSE]
    mapped$matched <- !is.na(mapped$marker_pk)
    leading <- c("observed_marker_id", "gene_id", "namespace", "accession", "matched")
    tibble::as_tibble(mapped[c(leading, setdiff(names(mapped), leading))])
  })
}

# Qualitative marker confidence, weakest first. A call is only as good as its
# weakest accepted marker, so the terms are ordered rather than scored: a GIFT
# resting on an ambiguous polyspecific family must not read like one resting on
# curated orthology.
.giftr_confidence_order <- c(
  "insufficient evidence", "ambiguous", "putative", "high-confidence", "curated"
)

.confidence_rank <- function(confidence) {
  rank <- match(confidence, .giftr_confidence_order)
  # An unrecognised term is never promoted above a known one.
  rank[is.na(rank)] <- 0L
  rank
}

.weakest_confidence <- function(confidence) {
  values <- unique(confidence[!is.na(confidence)])
  if (!length(values)) return(NA_character_)
  values[order(.confidence_rank(values))][[1]]
}

# Confidence follows the Boolean structure it describes. Alternative markers for
# one component are OR, so the component is only as uncertain as its *best*
# accepted marker; adding a weak marker alongside a strong one must not make the
# call look worse. Components are AND, so the route is as uncertain as its
# *weakest* component.
.call_confidence <- function(component_pk, confidence) {
  keep <- !is.na(confidence)
  if (!any(keep)) return(NA_character_)
  component_pk <- component_pk[keep]
  confidence <- confidence[keep]
  best <- vapply(
    split(confidence, component_pk),
    function(values) values[order(-.confidence_rank(values))][[1]],
    character(1)
  )
  .weakest_confidence(unname(best))
}

.list_for_ids <- function(ids, values, names = NULL) {
  if (!length(ids)) return(list())
  result <- lapply(ids, function(id) {
    selected <- values[[1]] == id
    output <- values[[2]][selected]
    if (!is.null(names)) output <- names(output)
    sort(unique(output[!is.na(output)]))
  })
  result
}

.evaluate_giftr_model <- function(annotation_table, namespace, connection) {
  marker_map <- map_markers(annotation_table, namespace = namespace, db = connection)
  evidence <- marker_map[marker_map$matched, , drop = FALSE]

  components <- .as_tibble_query(
    connection,
    paste(
      "SELECT ec.component_pk, ec.component_id, ec.name, ec.description,",
      "es.system_pk, es.system_id, r.reaction_pk, r.reaction_id, r.rhea_master",
      "FROM enzyme_component ec",
      "JOIN enzyme_system es ON es.system_pk = ec.system_pk",
      "JOIN reaction r ON r.reaction_pk = es.reaction_pk",
      "ORDER BY ec.component_id"
    )
  )
  marker_vocabulary <- .as_tibble_query(
    connection,
    paste(
      "SELECT ec.component_pk, ec.component_id, m.namespace, m.accession,",
      "cm.evidence_type, cm.confidence, cm.source",
      "FROM enzyme_component ec",
      "JOIN component_marker cm ON cm.component_pk = ec.component_pk",
      "JOIN marker m ON m.marker_pk = cm.marker_pk",
      "ORDER BY ec.component_id, m.namespace, m.accession"
    )
  )
  components$supported <- components$component_pk %in% evidence$component_pk
  components$accepted_markers <- lapply(components$component_pk, function(component_pk) {
    rows <- marker_vocabulary[marker_vocabulary$component_pk == component_pk, , drop = FALSE]
    sort(unique(paste(rows$namespace, rows$accession, sep = ":")))
  })
  components$supporting_markers <- lapply(components$component_pk, function(component_pk) {
    rows <- evidence[evidence$component_pk == component_pk, , drop = FALSE]
    sort(unique(paste(rows$namespace, rows$accession, sep = ":")))
  })
  components$supporting_genes <- lapply(components$component_pk, function(component_pk) {
    sort(unique(evidence$gene_id[evidence$component_pk == component_pk]))
  })

  systems <- .as_tibble_query(
    connection,
    paste(
      "SELECT es.system_pk, es.system_id, es.name, es.description,",
      "r.reaction_pk, r.reaction_id, r.rhea_master",
      "FROM enzyme_system es JOIN reaction r ON r.reaction_pk = es.reaction_pk",
      "ORDER BY es.system_id"
    )
  )
  systems$required_components <- integer(nrow(systems))
  systems$supported_components <- vector("list", nrow(systems))
  systems$missing_components <- vector("list", nrow(systems))
  systems$supported <- logical(nrow(systems))
  for (i in seq_len(nrow(systems))) {
    rows <- components[components$system_pk == systems$system_pk[[i]], , drop = FALSE]
    systems$required_components[[i]] <- nrow(rows)
    systems$supported_components[[i]] <- sort(rows$component_id[rows$supported])
    systems$missing_components[[i]] <- sort(rows$component_id[!rows$supported])
    systems$supported[[i]] <- nrow(rows) > 0L && all(rows$supported)
  }

  reactions <- .as_tibble_query(
    connection,
    paste(
      "SELECT reaction_pk, reaction_id, rhea_master, name, description",
      "FROM reaction ORDER BY reaction_id"
    )
  )
  reactions$number_of_complete_systems <- integer(nrow(reactions))
  reactions$best_system <- character(nrow(reactions))
  reactions$minimum_missing_components <- integer(nrow(reactions))
  reactions$supported <- logical(nrow(reactions))
  for (i in seq_len(nrow(reactions))) {
    rows <- systems[systems$reaction_pk == reactions$reaction_pk[[i]], , drop = FALSE]
    missing_count <- lengths(rows$missing_components)
    order_rows <- order(missing_count, rows$system_id)
    best <- order_rows[[1]]
    reactions$number_of_complete_systems[[i]] <- sum(rows$supported)
    reactions$best_system[[i]] <- rows$system_id[[best]]
    reactions$minimum_missing_components[[i]] <- missing_count[[best]]
    reactions$supported[[i]] <- any(rows$supported)
  }

  route_reactions <- .as_tibble_query(
    connection,
    paste(
      "SELECT g.gift_pk, g.gift_id, gr.route_pk, gr.route_id,",
      "rr.step_order, rr.required, rr.orientation, r.reaction_pk,",
      "r.reaction_id, r.rhea_master, r.name AS reaction_name",
      "FROM gift g",
      "JOIN gift_route gr ON gr.gift_pk = g.gift_pk",
      "JOIN route_reaction rr ON rr.route_pk = gr.route_pk",
      "JOIN reaction r ON r.reaction_pk = rr.reaction_pk",
      "ORDER BY g.gift_id, gr.route_id, rr.step_order"
    )
  )
  route_reactions$reaction_supported <- reactions$supported[
    match(route_reactions$reaction_pk, reactions$reaction_pk)
  ]
  route_reactions$best_system <- reactions$best_system[
    match(route_reactions$reaction_pk, reactions$reaction_pk)
  ]

  routes <- .as_tibble_query(
    connection,
    paste(
      "SELECT gr.route_pk, gr.route_id, gr.name, gr.description, gr.status,",
      "g.gift_pk, g.gift_id",
      "FROM gift_route gr JOIN gift g ON g.gift_pk = gr.gift_pk",
      "ORDER BY g.gift_id, gr.route_id"
    )
  )
  routes$required_reactions <- integer(nrow(routes))
  routes$supporting_reactions <- vector("list", nrow(routes))
  routes$missing_reactions <- vector("list", nrow(routes))
  routes$complete <- logical(nrow(routes))
  for (i in seq_len(nrow(routes))) {
    rows <- route_reactions[
      route_reactions$route_pk == routes$route_pk[[i]] & route_reactions$required == 1L,
      , drop = FALSE
    ]
    routes$required_reactions[[i]] <- nrow(rows)
    routes$supporting_reactions[[i]] <- rows$reaction_id[rows$reaction_supported]
    routes$missing_reactions[[i]] <- rows$reaction_id[!rows$reaction_supported]
    routes$complete[[i]] <- nrow(rows) > 0L && all(rows$reaction_supported)
  }

  gifts <- .as_tibble_query(
    connection,
    paste(
      "SELECT g.gift_pk, g.gift_id, g.name, g.description, g.mode, g.status,",
      "g.version, g.notes,",
      "(SELECT value FROM gift_facet gf WHERE gf.gift_pk = g.gift_pk",
      " AND gf.facet = 'substrate_class') AS substrate_class"
      , "FROM gift g ORDER BY g.gift_id"
    )
  )
  gifts$complete <- logical(nrow(gifts))
  gifts$number_of_complete_routes <- integer(nrow(gifts))
  gifts$best_route <- character(nrow(gifts))
  gifts$minimum_missing_reactions <- integer(nrow(gifts))
  gifts$missing_reactions_best_route <- vector("list", nrow(gifts))
  gifts$supporting_reactions <- vector("list", nrow(gifts))
  gifts$supporting_components <- vector("list", nrow(gifts))
  gifts$supporting_markers <- vector("list", nrow(gifts))
  gifts$supporting_genes <- vector("list", nrow(gifts))
  gifts$evidence_confidence <- character(nrow(gifts))
  gifts$route_score <- numeric(nrow(gifts))

  for (i in seq_len(nrow(gifts))) {
    gift_routes <- routes[routes$gift_pk == gifts$gift_pk[[i]], , drop = FALSE]
    missing_count <- lengths(gift_routes$missing_reactions)
    best_index <- order(missing_count, gift_routes$route_id)[[1]]
    best <- gift_routes[best_index, , drop = FALSE]
    gifts$complete[[i]] <- any(gift_routes$complete)
    gifts$number_of_complete_routes[[i]] <- sum(gift_routes$complete)
    gifts$best_route[[i]] <- best$route_id[[1]]
    gifts$minimum_missing_reactions[[i]] <- missing_count[[best_index]]
    gifts$missing_reactions_best_route[[i]] <- best$missing_reactions[[1]]
    gifts$supporting_reactions[[i]] <- best$supporting_reactions[[1]]
    gifts$route_score[[i]] <- if (best$required_reactions[[1]] > 0L) {
      1 - missing_count[[best_index]] / best$required_reactions[[1]]
    } else {
      NA_real_
    }

    best_reactions <- route_reactions$reaction_pk[route_reactions$route_pk == best$route_pk[[1]]]
    best_system_ids <- reactions$best_system[reactions$reaction_pk %in% best_reactions]
    best_system_pks <- systems$system_pk[systems$system_id %in% best_system_ids]
    best_components <- components[
      components$system_pk %in% best_system_pks & components$supported,
      , drop = FALSE
    ]
    gifts$supporting_components[[i]] <- sort(unique(best_components$component_id))
    best_evidence <- evidence[evidence$component_pk %in% best_components$component_pk, , drop = FALSE]
    gifts$supporting_markers[[i]] <- sort(unique(paste(
      best_evidence$namespace, best_evidence$accession, sep = ":"
    )))
    gifts$supporting_genes[[i]] <- sort(unique(best_evidence$gene_id))
    gifts$evidence_confidence[[i]] <- .call_confidence(
      best_evidence$component_pk, best_evidence$confidence
    )
  }

  observed <- unique(marker_map[c("observed_marker_id", "gene_id", "namespace", "accession")])
  observed$matched <- vapply(observed$observed_marker_id, function(id) {
    any(marker_map$observed_marker_id == id & marker_map$matched)
  }, logical(1))

  structure(
    list(
      gifts = gifts,
      routes = routes,
      route_reactions = route_reactions,
      reactions = reactions,
      systems = systems,
      components = components,
      marker_vocabulary = marker_vocabulary,
      evidence = evidence,
      marker_map = marker_map,
      observed_markers = tibble::as_tibble(observed),
      database_version = giftr_db_version(connection)
    ),
    class = c("giftr_result", "list")
  )
}

#' Evaluate reactions from observed genomic markers
#'
#' A component is supported by any accepted marker; an enzyme system requires
#' every component; and a reaction requires any one complete enzyme system.
#'
#' @inheritParams map_markers
#' @return A detailed result containing reaction, system, component, and marker
#'   evidence tibbles.
#' @export
evaluate_reactions <- function(annotation_table, namespace = NULL, db = NULL) {
  .with_giftr_db(db, function(connection) {
    result <- .evaluate_giftr_model(annotation_table, namespace, connection)
    structure(
      result[c(
        "reactions", "systems", "components", "marker_vocabulary", "evidence",
        "marker_map", "observed_markers", "database_version"
      )],
      class = c("giftr_reaction_result", "list")
    )
  })
}

#' Evaluate genome-inferred functional traits
#'
#' Evaluation follows explicit Boolean layers: markers OR into components,
#' components AND into enzyme systems, systems OR into reactions, reactions AND
#' into routes, and routes OR into GIFTs. Incomplete calls report the route with
#' the fewest unsupported reactions rather than a raw percentage of genes.
#'
#' @inheritParams map_markers
#' @return A `giftr_result` list. Its `gifts` member is the call summary;
#'   the remaining tibbles retain the full evidence chain.
#' @examples
#' markers <- data.frame(
#'   gene_id = paste0("gene_", 1:9),
#'   namespace = "KO",
#'   accession = c(
#'     "K00764", "K01945", "K00601", "K01952", "K01933",
#'     "K01587", "K01756", "K00602", "K01939"
#'   )
#' )
#' result <- evaluate_gifts(markers)
#' result$gifts[, c("gift_id", "complete", "best_route")]
#' @export
evaluate_gifts <- function(annotation_table, namespace = NULL, db = NULL) {
  .with_giftr_db(db, function(connection) {
    .evaluate_giftr_model(annotation_table, namespace, connection)
  })
}

#' @export
print.giftr_result <- function(x, ...) {
  cat("<giftr_result>\n")
  print(x$gifts[c(
    "gift_id", "complete", "number_of_complete_routes", "best_route",
    "minimum_missing_reactions"
  )], ...)
  invisible(x)
}

#' @export
print.giftr_reaction_result <- function(x, ...) {
  cat("<giftr_reaction_result>\n")
  print(x$reactions[c(
    "reaction_id", "supported", "number_of_complete_systems", "best_system",
    "minimum_missing_components"
  )], ...)
  invisible(x)
}

#' Trace the evidence chain for a GIFT call
#'
#' @param result A result returned by [evaluate_gifts()].
#' @param gift_id Stable GIFT identifier.
#' @param route_id Optional route to trace. The evaluated best route is used by
#'   default.
#' @return A long-form tibble from route reactions through selected enzyme
#'   systems and required components to observed markers and genes.
#' @export
trace_gift <- function(result, gift_id, route_id = NULL) {
  if (!inherits(result, "giftr_result")) {
    stop("result must come from evaluate_gifts()", call. = FALSE)
  }
  gift_id <- .normalize_gift_id(gift_id)
  gift <- result$gifts[result$gifts$gift_id == gift_id, , drop = FALSE]
  if (!nrow(gift)) stop("Unknown gift_id in result: ", gift_id, call. = FALSE)
  if (is.null(route_id)) route_id <- gift$best_route[[1]]
  route <- result$routes[
    result$routes$gift_id == gift_id & result$routes$route_id == route_id,
    , drop = FALSE
  ]
  if (!nrow(route)) stop("route_id does not belong to gift: ", route_id, call. = FALSE)

  route_rows <- result$route_reactions[
    result$route_reactions$route_pk == route$route_pk[[1]],
    , drop = FALSE
  ]
  route_rows <- route_rows[order(route_rows$step_order), , drop = FALSE]
  output <- list()
  row_index <- 0L
  for (i in seq_len(nrow(route_rows))) {
    reaction <- result$reactions[
      result$reactions$reaction_pk == route_rows$reaction_pk[[i]],
      , drop = FALSE
    ]
    system <- result$systems[
      result$systems$system_id == reaction$best_system[[1]],
      , drop = FALSE
    ]
    component_rows <- result$components[
      result$components$system_pk == system$system_pk[[1]],
      , drop = FALSE
    ]
    for (j in seq_len(nrow(component_rows))) {
      component <- component_rows[j, , drop = FALSE]
      component_evidence <- result$evidence[
        result$evidence$component_pk == component$component_pk[[1]],
        , drop = FALSE
      ]
      if (!nrow(component_evidence)) {
        component_evidence <- data.frame(
          gene_id = NA_character_, namespace = NA_character_, accession = NA_character_,
          evidence_type = NA_character_, confidence = NA_character_, source = NA_character_,
          stringsAsFactors = FALSE
        )
      }
      for (k in seq_len(nrow(component_evidence))) {
        row_index <- row_index + 1L
        output[[row_index]] <- data.frame(
          gift_id = gift_id,
          gift_complete = gift$complete[[1]],
          route_id = route_id,
          route_complete = route$complete[[1]],
          step_order = route_rows$step_order[[i]],
          required = as.logical(route_rows$required[[i]]),
          reaction_id = route_rows$reaction_id[[i]],
          rhea_master = route_rows$rhea_master[[i]],
          orientation = route_rows$orientation[[i]],
          reaction_supported = reaction$supported[[1]],
          system_id = system$system_id[[1]],
          system_supported = system$supported[[1]],
          component_id = component$component_id[[1]],
          component_supported = component$supported[[1]],
          accepted_markers = paste(component$accepted_markers[[1]], collapse = ";"),
          gene_id = component_evidence$gene_id[[k]],
          namespace = component_evidence$namespace[[k]],
          accession = component_evidence$accession[[k]],
          evidence_type = component_evidence$evidence_type[[k]],
          confidence = component_evidence$confidence[[k]],
          source = component_evidence$source[[k]],
          stringsAsFactors = FALSE
        )
      }
    }
  }
  tibble::as_tibble(do.call(rbind, output))
}
