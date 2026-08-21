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

.marker_hierarchy_columns <- c(
  "namespace", "accession", "marker_pk", "marker_name", "gift_type", "component_pk",
  "component_id", "system_pk", "system_id", "function_pk", "function_id",
  "reaction_pk", "reaction_id", "rhea_master", "evidence_type", "confidence",
  "source", "notes"
)

.empty_marker_hierarchy <- function() {
  columns <- .marker_hierarchy_columns
  empty <- stats::setNames(replicate(length(columns), character(), simplify = FALSE), columns)
  for (column in c("marker_pk", "component_pk", "system_pk", "function_pk", "reaction_pk")) {
    empty[[column]] <- integer()
  }
  tibble::as_tibble(empty)
}

# Look a set of observed markers up in one evidence hierarchy. `sql_for_chunk`
# receives the WHERE predicate and returns the query for that model, so the
# chunking, parameter binding and column contract are stated once for all types.
.marker_lookup <- function(connection, keys, sql_for_chunk) {
  if (!nrow(keys)) return(NULL)
  chunks <- split(seq_len(nrow(keys)), ceiling(seq_len(nrow(keys)) / 300))
  results <- lapply(chunks, function(index) {
    chunk <- keys[index, , drop = FALSE]
    predicates <- paste(rep("(m.namespace = ? AND m.accession = ?)", nrow(chunk)), collapse = " OR ")
    params <- as.list(as.vector(t(as.matrix(chunk[c("namespace", "accession")]))))
    DBI::dbGetQuery(connection, sql_for_chunk(predicates), params = params)
  })
  do.call(rbind, results)
}

.metabolic_marker_hierarchy <- function(connection, keys) {
  .marker_lookup(connection, keys, function(predicates) {
    paste(
      "SELECT m.namespace, m.accession, m.marker_pk, m.name AS marker_name,",
      "'metabolic' AS gift_type,",
      "ec.component_pk, ec.component_id, es.system_pk, es.system_id,",
      "NULL AS function_pk, NULL AS function_id,",
      "r.reaction_pk, r.reaction_id, r.rhea_master, cm.evidence_type, cm.confidence,",
      "cm.source, cm.notes",
      "FROM marker m",
      "JOIN component_marker cm ON cm.marker_pk = m.marker_pk",
      "JOIN enzyme_component ec ON ec.component_pk = cm.component_pk",
      "JOIN enzyme_system es ON es.system_pk = ec.system_pk",
      "JOIN reaction r ON r.reaction_pk = es.reaction_pk",
      "WHERE", predicates
    )
  })
}

.machinery_marker_hierarchy <- function(connection, model, keys) {
  .marker_lookup(connection, keys, function(predicates) {
    paste0(
      "SELECT m.namespace, m.accession, m.marker_pk, m.name AS marker_name, '",
      model$gift_type, "' AS gift_type, ",
      "c.component_pk, c.component_id, s.system_pk, s.system_id, ",
      "f.function_pk, f.function_id, ",
      "NULL AS reaction_pk, NULL AS reaction_id, NULL AS rhea_master, ",
      "e.evidence_type, e.confidence, e.source, e.notes ",
      "FROM marker m ",
      "JOIN ", model$evidence_table, " e ON e.marker_pk = m.marker_pk ",
      "JOIN ", model$component_table, " c ON c.component_pk = e.component_pk ",
      "JOIN ", model$system_table, " s ON s.system_pk = c.system_pk ",
      "JOIN ", model$function_table, " f ON f.function_pk = s.function_pk ",
      "WHERE ", predicates
    )
  })
}

# Every curated GIFT type contributes evidence for the same observed markers, so
# the hierarchies are looked up together and distinguished by `gift_type`.
# Component primary keys are only unique within a model, which is why nothing
# downstream may compare them without also comparing the type.
.marker_hierarchy_query <- function(connection, keys) {
  parts <- c(
    list(.metabolic_marker_hierarchy(connection, keys)),
    lapply(.gifter_machinery_models, function(model) {
      .machinery_marker_hierarchy(connection, model, keys)
    })
  )
  parts <- parts[!vapply(parts, is.null, logical(1))]
  parts <- parts[vapply(parts, nrow, integer(1)) > 0L]
  if (!length(parts)) return(.empty_marker_hierarchy())
  combined <- do.call(rbind, lapply(parts, function(part) part[.marker_hierarchy_columns]))
  tibble::as_tibble(combined)
}

#' Map observed genomic markers to curated components
#'
#' Marker namespaces and accessions are normalized before indexed lookups, and
#' every curated GIFT type is searched. The result retains unmatched
#' observations, making marker use auditable.
#'
#' @param annotation_table A data frame with `namespace` and `accession`
#'   columns and an optional `gene_id` column, or a character vector of marker
#'   accessions.
#' @param namespace Namespace for a character-vector input. If omitted, KO, EC,
#'   Pfam, and TIGRFAM accessions are inferred where possible.
#' @param db Optional open gifter database connection.
#' @return A long-form tibble linking each observation to zero or more curated
#'   components. `gift_type` names the completeness model a row belongs to:
#'   metabolic rows carry `reaction_id`, and the machinery types carry
#'   `function_id`. Component keys are unique only within a model, so compare
#'   them together with `gift_type`. `matched` is `FALSE` for unused markers.
#' @export
map_markers <- function(annotation_table, namespace = NULL, db = NULL) {
  observed <- .prepare_observed_markers(annotation_table, namespace)
  .with_gifter_db(db, function(connection) {
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
.gifter_confidence_order <- c(
  "insufficient evidence", "ambiguous", "putative", "high-confidence", "curated"
)

.confidence_rank <- function(confidence) {
  rank <- match(confidence, .gifter_confidence_order)
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

# The metabolic completeness model, unchanged in substance: markers OR into
# enzyme components, components AND into enzyme systems, systems OR into
# reactions, required reactions AND into routes, and routes OR into the GIFT.
.evaluate_metabolic_model <- function(connection, marker_map) {
  evidence <- marker_map[
    marker_map$matched & !is.na(marker_map$gift_type) & marker_map$gift_type == "metabolic",
    , drop = FALSE
  ]

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
  components <- .annotate_component_support(components, marker_vocabulary, evidence)

  systems <- .as_tibble_query(
    connection,
    paste(
      "SELECT es.system_pk, es.system_id, es.name, es.description,",
      "r.reaction_pk, r.reaction_id, r.rhea_master",
      "FROM enzyme_system es JOIN reaction r ON r.reaction_pk = es.reaction_pk",
      "ORDER BY es.system_id"
    )
  )
  systems <- .annotate_system_support(systems, components)

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
      "SELECT g.gift_pk, g.gift_id, g.gift_type, g.name, g.description, g.mode,",
      "g.status, g.version, g.notes,",
      "(SELECT value FROM gift_facet gf WHERE gf.gift_pk = g.gift_pk",
      " AND gf.facet = 'substrate_class') AS substrate_class"
      , "FROM gift g WHERE g.gift_type = 'metabolic' ORDER BY g.gift_id"
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

  list(
    gifts = gifts,
    routes = routes,
    route_reactions = route_reactions,
    reactions = reactions,
    systems = systems,
    components = components,
    marker_vocabulary = marker_vocabulary,
    evidence = evidence
  )
}

# Shared lower-level steps. These are the operations whose semantics really are
# identical across GIFT types -- a component is supported by any accepted marker,
# and a system needs all of its components -- so they are written once. Nothing
# above this level is shared, because above this level the biology differs.
.annotate_component_support <- function(components, marker_vocabulary, evidence) {
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
  components
}

.annotate_system_support <- function(systems, components) {
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
  systems
}

# A machinery completeness model. The GIFT is complete when at least one curated
# implementation -- an architecture, a circuit, a defense mechanism -- has every
# required function supported; a function is supported by any complete system;
# and a system needs all of its components. An incomplete call reports the
# closest implementation and the functions missing from it, never a fraction of
# expected genes.
.evaluate_machinery_model <- function(connection, model, marker_map) {
  evidence <- marker_map[
    marker_map$matched & !is.na(marker_map$gift_type) &
      marker_map$gift_type == model$gift_type,
    , drop = FALSE
  ]

  components <- .as_tibble_query(
    connection,
    paste0(
      "SELECT c.component_pk, c.component_id, c.name, c.description, ",
      "s.system_pk, s.system_id, f.function_pk, f.function_id ",
      "FROM ", model$component_table, " c ",
      "JOIN ", model$system_table, " s ON s.system_pk = c.system_pk ",
      "JOIN ", model$function_table, " f ON f.function_pk = s.function_pk ",
      "ORDER BY c.component_id"
    )
  )
  marker_vocabulary <- .as_tibble_query(
    connection,
    paste0(
      "SELECT c.component_pk, c.component_id, m.namespace, m.accession, ",
      "e.evidence_type, e.confidence, e.source ",
      "FROM ", model$component_table, " c ",
      "JOIN ", model$evidence_table, " e ON e.component_pk = c.component_pk ",
      "JOIN marker m ON m.marker_pk = e.marker_pk ",
      "ORDER BY c.component_id, m.namespace, m.accession"
    )
  )
  components <- .annotate_component_support(components, marker_vocabulary, evidence)

  systems <- .as_tibble_query(
    connection,
    paste0(
      "SELECT s.system_pk, s.system_id, s.name, s.description, ",
      "f.function_pk, f.function_id ",
      "FROM ", model$system_table, " s ",
      "JOIN ", model$function_table, " f ON f.function_pk = s.function_pk ",
      "ORDER BY s.system_id"
    )
  )
  systems <- .annotate_system_support(systems, components)

  functions <- .as_tibble_query(
    connection,
    paste0(
      "SELECT function_pk, function_id, name, description FROM ",
      model$function_table, " ORDER BY function_id"
    )
  )
  functions$number_of_complete_systems <- integer(nrow(functions))
  functions$best_system <- character(nrow(functions))
  functions$minimum_missing_components <- integer(nrow(functions))
  functions$supported <- logical(nrow(functions))
  for (i in seq_len(nrow(functions))) {
    rows <- systems[systems$function_pk == functions$function_pk[[i]], , drop = FALSE]
    missing_count <- lengths(rows$missing_components)
    best <- order(missing_count, rows$system_id)[[1]]
    functions$number_of_complete_systems[[i]] <- sum(rows$supported)
    functions$best_system[[i]] <- rows$system_id[[best]]
    functions$minimum_missing_components[[i]] <- missing_count[[best]]
    functions$supported[[i]] <- any(rows$supported)
  }

  membership <- .as_tibble_query(
    connection,
    paste0(
      "SELECT g.gift_pk, g.gift_id, i.", model$implementation_pk, " AS implementation_pk, ",
      "i.", model$implementation_id, " AS implementation_id, ",
      "mf.ordinal, mf.required, f.function_pk, f.function_id, f.name AS function_name ",
      "FROM gift g ",
      "JOIN ", model$implementation_table, " i ON i.gift_pk = g.gift_pk ",
      "JOIN ", model$membership_table, " mf ON mf.", model$implementation_pk,
      " = i.", model$implementation_pk, " ",
      "JOIN ", model$function_table, " f ON f.function_pk = mf.function_pk ",
      "ORDER BY g.gift_id, i.", model$implementation_id, ", mf.ordinal"
    )
  )
  membership$function_supported <- functions$supported[
    match(membership$function_pk, functions$function_pk)
  ]
  membership$best_system <- functions$best_system[
    match(membership$function_pk, functions$function_pk)
  ]

  implementations <- .as_tibble_query(
    connection,
    paste0(
      "SELECT i.", model$implementation_pk, " AS implementation_pk, ",
      "i.", model$implementation_id, " AS implementation_id, ",
      "i.name, i.description, i.status, g.gift_pk, g.gift_id ",
      "FROM ", model$implementation_table, " i ",
      "JOIN gift g ON g.gift_pk = i.gift_pk ",
      "ORDER BY g.gift_id, i.", model$implementation_id
    )
  )
  implementations$required_functions <- integer(nrow(implementations))
  implementations$supporting_functions <- vector("list", nrow(implementations))
  implementations$missing_functions <- vector("list", nrow(implementations))
  implementations$complete <- logical(nrow(implementations))
  for (i in seq_len(nrow(implementations))) {
    rows <- membership[
      membership$implementation_pk == implementations$implementation_pk[[i]] &
        membership$required == 1L,
      , drop = FALSE
    ]
    implementations$required_functions[[i]] <- nrow(rows)
    implementations$supporting_functions[[i]] <- rows$function_id[rows$function_supported]
    implementations$missing_functions[[i]] <- rows$function_id[!rows$function_supported]
    implementations$complete[[i]] <- nrow(rows) > 0L && all(rows$function_supported)
  }

  gifts <- .as_tibble_query(
    connection,
    paste0(
      "SELECT g.gift_pk, g.gift_id, g.gift_type, g.name, g.description, g.mode, ",
      "g.status, g.version, g.notes FROM gift g WHERE g.gift_type = '",
      model$gift_type, "' ORDER BY g.gift_id"
    )
  )
  gifts$complete <- logical(nrow(gifts))
  gifts$number_of_complete_implementations <- integer(nrow(gifts))
  gifts$best_implementation <- character(nrow(gifts))
  gifts$minimum_missing_requirements <- integer(nrow(gifts))
  gifts$missing_requirements <- vector("list", nrow(gifts))
  gifts$supporting_requirements <- vector("list", nrow(gifts))
  gifts$supporting_components <- vector("list", nrow(gifts))
  gifts$supporting_markers <- vector("list", nrow(gifts))
  gifts$supporting_genes <- vector("list", nrow(gifts))
  gifts$evidence_confidence <- character(nrow(gifts))
  gifts$completeness_score <- numeric(nrow(gifts))

  for (i in seq_len(nrow(gifts))) {
    candidates <- implementations[
      implementations$gift_pk == gifts$gift_pk[[i]], , drop = FALSE
    ]
    missing_count <- lengths(candidates$missing_functions)
    best_index <- order(missing_count, candidates$implementation_id)[[1]]
    best <- candidates[best_index, , drop = FALSE]
    gifts$complete[[i]] <- any(candidates$complete)
    gifts$number_of_complete_implementations[[i]] <- sum(candidates$complete)
    gifts$best_implementation[[i]] <- best$implementation_id[[1]]
    gifts$minimum_missing_requirements[[i]] <- missing_count[[best_index]]
    gifts$missing_requirements[[i]] <- best$missing_functions[[1]]
    gifts$supporting_requirements[[i]] <- best$supporting_functions[[1]]
    gifts$completeness_score[[i]] <- if (best$required_functions[[1]] > 0L) {
      1 - missing_count[[best_index]] / best$required_functions[[1]]
    } else {
      NA_real_
    }

    best_functions <- membership$function_pk[
      membership$implementation_pk == best$implementation_pk[[1]]
    ]
    best_system_ids <- functions$best_system[functions$function_pk %in% best_functions]
    best_system_pks <- systems$system_pk[systems$system_id %in% best_system_ids]
    best_components <- components[
      components$system_pk %in% best_system_pks & components$supported,
      , drop = FALSE
    ]
    gifts$supporting_components[[i]] <- sort(unique(best_components$component_id))
    best_evidence <- evidence[
      evidence$component_pk %in% best_components$component_pk, , drop = FALSE
    ]
    gifts$supporting_markers[[i]] <- sort(unique(paste(
      best_evidence$namespace, best_evidence$accession, sep = ":"
    )))
    gifts$supporting_genes[[i]] <- sort(unique(best_evidence$gene_id))
    gifts$evidence_confidence[[i]] <- .call_confidence(
      best_evidence$component_pk, best_evidence$confidence
    )
  }

  list(
    model = model,
    gifts = gifts,
    implementations = implementations,
    membership = membership,
    functions = functions,
    systems = systems,
    components = components,
    marker_vocabulary = marker_vocabulary,
    evidence = evidence
  )
}

# The call summary every GIFT shares, whatever produced it. Type-neutral columns
# name the implementation and the requirements missing from it; the metabolic
# route columns are kept beside them so that a route-aware caller does not have
# to translate, and are empty for the types that have no routes.
.gifter_call_columns <- c(
  "gift_pk", "gift_id", "gift_type", "name", "description", "mode", "status",
  "version", "notes", "substrate_class", "complete", "evidence_confidence",
  "best_implementation", "number_of_complete_implementations",
  "minimum_missing_requirements", "missing_requirements", "completeness_score",
  "supporting_components", "supporting_markers", "supporting_genes",
  "number_of_complete_routes", "best_route", "minimum_missing_reactions",
  "missing_reactions_best_route", "supporting_reactions", "route_score"
)

.blank_call_columns <- function(gifts) {
  n <- nrow(gifts)
  for (column in setdiff(.gifter_call_columns, names(gifts))) {
    gifts[[column]] <- switch(
      column,
      substrate_class = ,
      best_implementation = ,
      best_route = rep(NA_character_, n),
      number_of_complete_implementations = ,
      minimum_missing_requirements = ,
      number_of_complete_routes = ,
      minimum_missing_reactions = rep(NA_integer_, n),
      completeness_score = ,
      route_score = rep(NA_real_, n),
      rep(list(character()), n)
    )
  }
  gifts[.gifter_call_columns]
}

.assemble_gift_calls <- function(metabolic_gifts, machinery_results) {
  metabolic_gifts$best_implementation <- metabolic_gifts$best_route
  metabolic_gifts$number_of_complete_implementations <- metabolic_gifts$number_of_complete_routes
  metabolic_gifts$minimum_missing_requirements <- metabolic_gifts$minimum_missing_reactions
  metabolic_gifts$missing_requirements <- metabolic_gifts$missing_reactions_best_route
  metabolic_gifts$completeness_score <- metabolic_gifts$route_score

  parts <- c(
    list(.blank_call_columns(metabolic_gifts)),
    lapply(machinery_results, function(result) .blank_call_columns(result$gifts))
  )
  parts <- parts[vapply(parts, nrow, integer(1)) > 0L]
  if (!length(parts)) return(.blank_call_columns(metabolic_gifts))
  combined <- do.call(rbind, parts)
  combined[order(combined$gift_id), , drop = FALSE]
}

.evaluate_gifter_model <- function(annotation_table, namespace, connection) {
  marker_map <- map_markers(annotation_table, namespace = namespace, db = connection)
  metabolic <- .evaluate_metabolic_model(connection, marker_map)
  machinery <- lapply(.gifter_machinery_models, function(model) {
    .evaluate_machinery_model(connection, model, marker_map)
  })

  observed <- unique(marker_map[c("observed_marker_id", "gene_id", "namespace", "accession")])
  observed$matched <- vapply(observed$observed_marker_id, function(id) {
    any(marker_map$observed_marker_id == id & marker_map$matched)
  }, logical(1))

  structure(
    list(
      gifts = .assemble_gift_calls(metabolic$gifts, machinery),
      routes = metabolic$routes,
      route_reactions = metabolic$route_reactions,
      reactions = metabolic$reactions,
      systems = metabolic$systems,
      components = metabolic$components,
      marker_vocabulary = metabolic$marker_vocabulary,
      evidence = metabolic$evidence,
      structural = .machinery_result_view(machinery$structural),
      regulatory = .machinery_result_view(machinery$regulatory),
      defense = .machinery_result_view(machinery$defense),
      marker_map = marker_map,
      observed_markers = tibble::as_tibble(observed),
      database_version = gifter_db_version(connection)
    ),
    class = c("gifter_genome", "list")
  )
}

# Present a machinery result under the names its biology uses. The evaluator is
# generic; what a curator reads is not.
.machinery_result_view <- function(result) {
  model <- result$model
  gifts <- result$gifts
  implementations <- result$implementations
  membership <- result$membership

  names(gifts)[names(gifts) == "best_implementation"] <-
    paste0("best_", model$implementation)
  names(gifts)[names(gifts) == "number_of_complete_implementations"] <-
    paste0("number_of_complete_", model$implementation_plural)
  names(gifts)[names(gifts) == "minimum_missing_requirements"] <- "minimum_missing_functions"
  names(gifts)[names(gifts) == "missing_requirements"] <-
    paste0("missing_functions_best_", model$implementation)
  names(gifts)[names(gifts) == "supporting_requirements"] <- "supporting_functions"

  names(implementations)[names(implementations) == "implementation_pk"] <- model$implementation_pk
  names(implementations)[names(implementations) == "implementation_id"] <- model$implementation_id
  names(membership)[names(membership) == "implementation_pk"] <- model$implementation_pk
  names(membership)[names(membership) == "implementation_id"] <- model$implementation_id

  view <- list(
    gift_type = model$gift_type,
    implementation = model$implementation,
    implementation_id = model$implementation_id,
    implementation_plural = model$implementation_plural,
    membership_name = model$membership_source,
    gifts = gifts,
    functions = result$functions,
    systems = result$systems,
    components = result$components,
    marker_vocabulary = result$marker_vocabulary,
    evidence = result$evidence
  )
  view[[model$implementation_plural]] <- implementations
  view[[model$membership_source]] <- membership
  view
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
  .with_gifter_db(db, function(connection) {
    result <- .evaluate_gifter_model(annotation_table, namespace, connection)
    structure(
      result[c(
        "reactions", "systems", "components", "marker_vocabulary", "evidence",
        "marker_map", "observed_markers", "database_version"
      )],
      class = c("gifter_reaction_result", "list")
    )
  })
}

# Input guardrails for evaluate_gifts().
#
# Two input mistakes produce a well-formed result that answers a question the
# user never asked: an unlabelled first column taken for gene identifiers, and a
# whole collection of genomes evaluated as if it were a single genome. Neither
# shows up in the calls themselves — pooled markers simply report capabilities
# that no single member encodes — so both are settled with the user before the
# evaluation rather than reported after it.
#
# Every guardrail speaks through cli. A guardrail the user cannot read is a
# guardrail that does not work, and base warning() and stop() emit a paragraph
# as one unbroken line however narrow the console. cli wraps to the console
# width and keeps the concern, its reason, and the ways out on separate bullets.

# Ask a yes/no question, after stating the concern. Returns TRUE, FALSE, or NA
# when there is nobody to ask; each caller decides what an unanswerable question
# means for its own guardrail. Isolated in one function so tests can answer
# without a console.
.gifter_ask <- function(concern, question) {
  if (!interactive()) return(NA)
  cli::cli_bullets(concern, .envir = parent.frame())
  # A bounded number of attempts: an empty line is no answer, and at end of
  # input readline() returns one forever, so an unbounded loop would hang a
  # session that has nobody left to answer it.
  for (attempt in seq_len(3L)) {
    answer <- tolower(trimws(readline(paste0(question, " (y/n) "))))
    if (answer %in% c("y", "yes")) return(TRUE)
    if (answer %in% c("n", "no")) return(FALSE)
    if (!nzchar(answer)) break
    cli::cli_alert_info("Please answer {.kbd y} or {.kbd n}.")
  }
  NA
}

# The first column that is not part of the marker itself. Column order is the
# only signal available, so the candidate is proposed, never assumed.
.gene_id_candidate <- function(annotation_table) {
  candidates <- setdiff(names(annotation_table), c("namespace", "accession"))
  if (length(candidates)) candidates[[1]] else NA_character_
}

.adopt_gene_id_column <- function(annotation_table, column) {
  if (!identical(column, "gene_id")) {
    annotation_table$gene_id <- as.character(annotation_table[[column]])
  }
  annotation_table
}

# What the proposed column actually holds. Seeing the values is what lets a user
# recognise their locus tags, or recognise that the column is something else.
.gene_id_concern <- function(candidate, values) {
  values <- as.character(values)
  concern <- c(
    "{.arg annotation_table} has no {.field gene_id} column.",
    "i" = "Gene identifiers are what makes a call traceable to a locus, so the
           column is never chosen by position alone."
  )
  if (length(values)) {
    c(concern, "i" = "The first column that is not a marker is
                      {.field {candidate}}, holding {.val {values}}.")
  } else {
    c(concern, "i" = "The first column that is not a marker is {.field {candidate}}.")
  }
}

# Resolve which column names genes, asking for approval before adopting one that
# was never labelled as such. Gene identifiers carry the evidence chain down to
# the genome, so adopting the wrong column mislabels every supporting gene in
# the result while leaving the calls themselves looking correct.
.resolve_gene_id_column <- function(annotation_table, gene_id) {
  if (!is.data.frame(annotation_table)) {
    if (!is.null(gene_id) && !isTRUE(gene_id) && !isFALSE(gene_id)) {
      cli::cli_abort(c(
        "{.arg gene_id} names a column of a data frame.",
        "i" = "A marker vector carries its gene identifiers in its names."
      ), call = NULL)
    }
    return(annotation_table)
  }
  if (isFALSE(gene_id)) {
    annotation_table$gene_id <- NULL
    return(annotation_table)
  }
  if (is.character(gene_id)) {
    if (length(gene_id) != 1L || is.na(gene_id) || !nzchar(gene_id)) {
      cli::cli_abort("{.arg gene_id} must be a single column name.", call = NULL)
    }
    if (!gene_id %in% names(annotation_table)) {
      cli::cli_abort(c(
        "{.arg annotation_table} has no column named {.field {gene_id}}.",
        "i" = "Its columns are {.field {names(annotation_table)}}."
      ), call = NULL)
    }
    return(.adopt_gene_id_column(annotation_table, gene_id))
  }
  if (!is.null(gene_id) && !isTRUE(gene_id)) {
    cli::cli_abort(
      "{.arg gene_id} must be {.code NULL}, {.code TRUE}, {.code FALSE}, or a column name.",
      call = NULL
    )
  }
  if ("gene_id" %in% names(annotation_table)) return(annotation_table)

  candidate <- .gene_id_candidate(annotation_table)
  # A table of nothing but markers holds no column to mistake for a gene
  # identifier: the markers are numbered, and the evidence chain stops at the
  # marker rather than at a wrong gene.
  if (is.na(candidate)) return(annotation_table)
  if (isTRUE(gene_id)) return(.adopt_gene_id_column(annotation_table, candidate))

  values <- annotation_table[[candidate]]
  # cli truncates the preview itself, so a longer column shows that more values
  # follow rather than implying the three shown are all of them.
  values <- cli::cli_vec(
    as.character(values),
    list("vec-trunc" = 3L, "vec-trunc-style" = "head")
  )
  concern <- .gene_id_concern(candidate, values)
  approved <- .gifter_ask(
    concern,
    cli::format_inline("Treat {.field {candidate}} as the gene identifier?")
  )
  if (isTRUE(approved)) return(.adopt_gene_id_column(annotation_table, candidate))
  cli::cli_abort(c(
    concern,
    "*" = "Name the gene column with {.code gene_id = \"{candidate}\"}.",
    "*" = "Approve the first column with {.code gene_id = TRUE}.",
    "*" = "Number the markers instead with {.code gene_id = FALSE}."
  ), call = NULL)
}

# The number of distinct gene identifiers the evaluation will see, computed the
# way .prepare_observed_markers() will build them so that the guardrail counts
# what is actually evaluated.
.distinct_gene_count <- function(annotation_table) {
  if (is.data.frame(annotation_table)) {
    if ("gene_id" %in% names(annotation_table)) {
      return(length(unique(as.character(annotation_table$gene_id))))
    }
    return(nrow(annotation_table))
  }
  if (is.character(annotation_table) && is.null(dim(annotation_table))) {
    ids <- names(annotation_table)
    return(if (is.null(ids)) length(annotation_table) else length(unique(ids)))
  }
  0L
}

# What is suspicious about an oversized input depends on how the genome was
# delimited. A whole table taken for one genome may be a collection that was
# never split; a group of one `genome_id` value has been split already, so what
# is in doubt is the column, not the call.
.single_genome_concern <- function(genes, max_genes, genome) {
  if (is.null(genome)) {
    return(c(
      "{genes} distinct gene identifiers were supplied, more than the
       {max_genes} expected of a single genome.",
      "i" = "{.fn evaluate_gifts} evaluates one genome: markers pooled from
             several genomes complete routes that no single genome encodes.",
      "i" = "For a collection of genomes, use {.fn evaluate_gifts_community},
             which evaluates each genome separately."
    ))
  }
  c(
    "Genome {.val {genome}} carries {genes} distinct gene identifiers, more
     than the {max_genes} expected of a single genome.",
    "i" = "Markers pooled under one genome identifier complete routes that no
           single genome encodes.",
    "i" = "Check that the genome column names one genome per value."
  )
}

# Question an input too large to be one genome. The calls of a pooled table are
# individually valid and collectively meaningless: a route completed by
# reactions drawn from different genomes is a capability of the collection, not
# of any member. `genome` names the group being checked when the input was
# already split by genome, and is `NULL` for a whole table taken as one genome.
.check_single_genome <- function(annotation_table, max_genes, genome = NULL) {
  if (is.null(max_genes)) return(invisible(NULL))
  if (!is.numeric(max_genes) || length(max_genes) != 1L || is.na(max_genes)) {
    cli::cli_abort(c(
      "{.arg max_genes} must be a single number.",
      "i" = "Use {.code max_genes = Inf} to skip the single-genome check."
    ), call = NULL)
  }
  genes <- .distinct_gene_count(annotation_table)
  if (genes <= max_genes) return(invisible(NULL))

  concern <- .single_genome_concern(genes, max_genes, genome)
  escape <- if (is.null(genome)) {
    "evaluate this table as one genome"
  } else {
    "accept every genome as the column defines it"
  }
  approved <- .gifter_ask(concern, "Are these markers from a single genome?")
  if (isTRUE(approved)) return(invisible(NULL))
  if (isFALSE(approved)) {
    cli::cli_abort(c(
      concern,
      "*" = "Set {.code max_genes = Inf} to {escape} anyway."
    ), call = NULL)
  }
  # Nobody to ask: the input is still evaluated as one genome, because the count
  # is a suspicion and a large genome is a legitimate input, but the suspicion is
  # not swallowed.
  cli::cli_warn(c(
    concern,
    "*" = "Set {.code max_genes = Inf} to {escape} silently."
  ))
  invisible(NULL)
}

#' Evaluate genome-inferred functional traits
#'
#' Evaluation follows explicit Boolean layers: markers OR into components,
#' components AND into enzyme systems, systems OR into reactions, reactions AND
#' into routes, and routes OR into GIFTs. Incomplete calls report the route with
#' the fewest unsupported reactions rather than a raw percentage of genes.
#'
#' @section Input guardrails:
#'
#' Two input mistakes yield a well-formed result that answers a question the
#' user never asked, and neither is visible in the calls themselves.
#'
#' An unlabelled column taken for gene identifiers mislabels the whole evidence
#' chain while leaving every call intact, so a table without a `gene_id` column
#' is not guessed at: the first other column is proposed for approval, and
#' without an answer the call fails rather than choosing.
#'
#' Markers pooled from several genomes complete routes that no single genome
#' encodes, so an input carrying more than `max_genes` distinct gene identifiers
#' is questioned before it is evaluated as one genome. A collection of genomes
#' belongs in `evaluate_gifts_community()`, which evaluates each genome
#' separately.
#'
#' @inheritParams map_markers
#' @param gene_id Which column names genes when `annotation_table` has no
#'   `gene_id` column. `NULL`, the default, proposes the first column that is
#'   neither `namespace` nor `accession` and adopts it only with approval. A
#'   column name adopts that column, `TRUE` approves the proposal in advance,
#'   and `FALSE` numbers the markers rather than naming genes. Ignored when a
#'   `gene_id` column is already present, unless a column is named explicitly.
#' @param max_genes Number of distinct gene identifiers above which the input is
#'   questioned as a possible collection of genomes. `Inf` evaluates any table
#'   as a single genome without asking.
#' @return A `gifter_genome` list. Its `gifts` member is the call summary;
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
#'
#' # A table whose gene column is named something else: approve it explicitly
#' # rather than leaving the choice to column order.
#' locus_markers <- data.frame(
#'   locus_tag = paste0("b", 1:2),
#'   namespace = "KO",
#'   accession = c("K01198", "K01805")
#' )
#' evaluate_gifts(locus_markers, gene_id = "locus_tag")$observed_markers$gene_id
#' @export
evaluate_gifts <- function(annotation_table, namespace = NULL, db = NULL,
                           gene_id = NULL, max_genes = 5000) {
  annotation_table <- .resolve_gene_id_column(annotation_table, gene_id)
  .check_single_genome(annotation_table, max_genes)
  .with_gifter_db(db, function(connection) {
    .evaluate_gifter_model(annotation_table, namespace, connection)
  })
}

#' @export
print.gifter_genome <- function(x, ...) {
  cat("<gifter_genome>\n")
  print(x$gifts[c(
    "gift_id", "gift_type", "complete", "number_of_complete_implementations",
    "best_implementation", "minimum_missing_requirements"
  )], ...)
  invisible(x)
}

#' @export
print.gifter_reaction_result <- function(x, ...) {
  cat("<gifter_reaction_result>\n")
  print(x$reactions[c(
    "reaction_id", "supported", "number_of_complete_systems", "best_system",
    "minimum_missing_components"
  )], ...)
  invisible(x)
}

#' Trace the evidence chain for a GIFT call
#'
#' Traceability follows the completeness model that produced the call. For a
#' metabolic GIFT the chain runs route -> reaction -> enzyme system -> component
#' -> marker -> gene; for a structural, regulatory or defense GIFT it runs
#' architecture, circuit or mechanism -> function -> system -> component ->
#' marker -> gene. Both end at the supplied gene identifiers.
#'
#' @param result A result returned by [evaluate_gifts()].
#' @param gift_id Stable GIFT identifier.
#' @param route_id Optional route to trace, for a metabolic GIFT. The evaluated
#'   best route is used by default.
#' @param implementation Optional architecture, circuit or mechanism to trace,
#'   for a non-metabolic GIFT. The evaluated best one is used by default.
#' @return A long-form tibble from the chosen implementation down to observed
#'   markers and genes.
#' @export
trace_gift <- function(result, gift_id, route_id = NULL, implementation = NULL) {
  if (!inherits(result, "gifter_genome")) {
    stop("result must come from evaluate_gifts()", call. = FALSE)
  }
  gift_id <- .normalize_gift_id(gift_id)
  gift <- result$gifts[result$gifts$gift_id == gift_id, , drop = FALSE]
  if (!nrow(gift)) stop("Unknown gift_id in result: ", gift_id, call. = FALSE)
  gift_type <- gift$gift_type[[1]]
  if (!identical(gift_type, "metabolic")) {
    if (!is.null(route_id)) {
      stop(
        "route_id traces a metabolic GIFT; ", gift_id, " is ", gift_type,
        ". Use implementation instead.",
        call. = FALSE
      )
    }
    return(.trace_machinery_gift(result[[gift_type]], gift, implementation))
  }
  if (!is.null(implementation)) {
    stop(
      "implementation traces a non-metabolic GIFT; ", gift_id,
      " is metabolic. Use route_id instead.",
      call. = FALSE
    )
  }
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


# Trace one machinery GIFT. The shape mirrors the metabolic trace so that both
# can be read side by side, but the columns are named for the model that
# produced them.
.trace_machinery_gift <- function(view, gift, implementation) {
  gift_id <- gift$gift_id[[1]]
  id_column <- view$implementation_id
  implementations <- view[[view$implementation_plural]]
  membership <- view[[view$membership_name]]

  if (is.null(implementation)) {
    implementation <- view$gifts[[paste0("best_", view$implementation)]][
      view$gifts$gift_id == gift_id
    ][[1]]
  }
  chosen <- implementations[
    implementations$gift_id == gift_id & implementations[[id_column]] == implementation,
    , drop = FALSE
  ]
  if (!nrow(chosen)) {
    stop(view$implementation, " does not belong to gift: ", implementation, call. = FALSE)
  }

  rows <- membership[membership[[id_column]] == implementation, , drop = FALSE]
  rows <- rows[order(rows$ordinal), , drop = FALSE]
  output <- list()
  row_index <- 0L
  for (i in seq_len(nrow(rows))) {
    fn <- view$functions[view$functions$function_pk == rows$function_pk[[i]], , drop = FALSE]
    system <- view$systems[view$systems$system_id == fn$best_system[[1]], , drop = FALSE]
    component_rows <- view$components[
      view$components$system_pk == system$system_pk[[1]], , drop = FALSE
    ]
    for (j in seq_len(nrow(component_rows))) {
      component <- component_rows[j, , drop = FALSE]
      component_evidence <- view$evidence[
        view$evidence$component_pk == component$component_pk[[1]], , drop = FALSE
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
        entry <- data.frame(
          gift_id = gift_id,
          gift_type = view$gift_type,
          gift_complete = gift$complete[[1]],
          implementation = implementation,
          implementation_complete = chosen$complete[[1]],
          ordinal = rows$ordinal[[i]],
          required = as.logical(rows$required[[i]]),
          function_id = rows$function_id[[i]],
          function_name = rows$function_name[[i]],
          function_supported = fn$supported[[1]],
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
        names(entry)[names(entry) == "implementation"] <- id_column
        names(entry)[names(entry) == "implementation_complete"] <-
          paste0(view$implementation, "_complete")
        output[[row_index]] <- entry
      }
    }
  }
  tibble::as_tibble(do.call(rbind, output))
}
