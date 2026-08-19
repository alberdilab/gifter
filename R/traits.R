# Quantitative genome traits derived from GIFT calls.
#
# Nothing here is curated and nothing here changes a call. This layer reads the
# calls `evaluate_gifts()` produced, the curated facets that classify them, and
# the two derived views -- `gift_profile` and `gift_graph` -- and summarises
# them within declared reference universes. It is the derived layer the
# architecture guide anticipated, not a fifth GIFT type.
#
# Every row carries its numerator, its denominator, how many members of the
# universe were assessable, the universe itself and the database version, so
# that a number can be taken apart again. A metric whose ingredients cannot be
# recovered is not reportable, however correct it is.

.metric_columns <- c(
  "target_type", "target_id", "metric_id", "value", "unit", "numerator",
  "denominator", "assessable", "reference_universe", "database_version",
  "derivation_method"
)

.trace_columns <- c(
  "target_type", "target_id", "metric_id", "reference_universe", "gift_id",
  "contribution"
)

.empty_metrics <- function() {
  tibble::tibble(
    target_type = character(), target_id = character(), metric_id = character(),
    value = numeric(), unit = character(), numerator = integer(),
    denominator = integer(), assessable = integer(),
    reference_universe = character(), database_version = character(),
    derivation_method = character()
  )
}

.empty_trace <- function() {
  tibble::tibble(
    target_type = character(), target_id = character(), metric_id = character(),
    reference_universe = character(), gift_id = character(),
    contribution = character()
  )
}

.metric_row <- function(target_type, target_id, metric_id, value, unit,
                        numerator, denominator, assessable, universe,
                        version, derivation_method) {
  tibble::tibble(
    target_type = target_type, target_id = target_id, metric_id = metric_id,
    value = as.numeric(value), unit = unit,
    numerator = as.integer(numerator),
    denominator = if (is.null(denominator)) NA_integer_ else as.integer(denominator),
    assessable = as.integer(assessable),
    reference_universe = universe, database_version = version,
    derivation_method = derivation_method
  )
}

.trace_rows <- function(target_type, target_id, metric_id, universe, gift_id,
                        contribution = NA_character_) {
  if (!length(gift_id)) return(.empty_trace())
  tibble::tibble(
    target_type = target_type, target_id = target_id, metric_id = metric_id,
    reference_universe = universe, gift_id = as.character(gift_id),
    contribution = as.character(contribution)
  )
}

# Facet and profile classifications of the GIFTs in one universe, in the shape
# breadth needs: one row per GIFT per classification. `gift_profile` columns are
# included alongside registered facets because a substrate tier and a resource
# strategy classify a call exactly as a facet does; they are simply derived
# rather than curated, and the metric identifiers say which is which.
.gift_classifications <- function(connection, gift_id) {
  if (!length(gift_id)) {
    return(tibble::tibble(
      gift_id = character(), facet = character(), value = character(),
      source = character()
    ))
  }
  placeholders <- paste(rep("?", length(gift_id)), collapse = ", ")
  curated <- .as_tibble_query(
    connection,
    paste0(
      "SELECT g.gift_id, f.facet, f.value FROM gift_facet f ",
      "JOIN gift g ON g.gift_pk = f.gift_pk ",
      "WHERE g.gift_id IN (", placeholders, ")"
    ),
    as.list(gift_id)
  )
  curated$source <- "gift_facet"
  derived <- .as_tibble_query(
    connection,
    paste0(
      "SELECT gift_id, substrate_tier, resource_strategy, network_position ",
      "FROM gift_profile WHERE gift_id IN (", placeholders, ")"
    ),
    as.list(gift_id)
  )
  derived_long <- lapply(c("substrate_tier", "resource_strategy", "network_position"), function(column) {
    keep <- !is.na(derived[[column]])
    tibble::tibble(
      gift_id = derived$gift_id[keep], facet = column,
      value = as.character(derived[[column]][keep]), source = "gift_profile"
    )
  })
  combined <- do.call(rbind, c(list(curated[c("gift_id", "facet", "value", "source")]), derived_long))
  combined[!is.na(combined$value) & nzchar(combined$value), , drop = FALSE]
}

.universe_metrics <- function(connection, universe, calls, graph, target_id, version) {
  members <- universe$gift_id
  label <- universe$label
  in_universe <- calls[calls$gift_id %in% members, , drop = FALSE]
  supported <- in_universe$gift_id[in_universe$complete %in% TRUE]
  # Phase 4 replaces this with the assessability policy. Until one exists, every
  # member of the universe was assessed, and saying so in the output is what
  # keeps the assumption visible rather than implied.
  assessable <- length(members)

  metrics <- list(.metric_row(
    "genome", target_id, "gift_richness", length(supported), "count",
    length(supported), NA_integer_, assessable, label, version,
    "supported GIFTs in the reference universe"
  ))
  trace <- list(.trace_rows(
    "genome", target_id, "gift_richness", label, supported
  ))

  # A supported fraction over an open catalogue would read as the share of
  # microbial function a genome carries, which is not what it measures.
  if (isTRUE(universe$bounded) && assessable > 0L) {
    metrics <- c(metrics, list(.metric_row(
      "genome", target_id, "supported_fraction", length(supported) / assessable,
      "proportion", length(supported), assessable, assessable, label, version,
      "supported GIFTs divided by assessable GIFTs in a bounded universe"
    )))
    trace <- c(trace, list(.trace_rows(
      "genome", target_id, "supported_fraction", label, supported
    )))
  }

  classifications <- .gift_classifications(connection, members)
  for (facet in sort(unique(classifications$facet))) {
    rows <- classifications[classifications$facet == facet, , drop = FALSE]
    available <- unique(rows$value)
    hit <- unique(rows$value[rows$gift_id %in% supported])
    metric_id <- paste0("breadth_", facet)
    source <- rows$source[[1L]]
    metrics <- c(metrics, list(.metric_row(
      "genome", target_id, metric_id, length(hit), "count", length(hit),
      length(available), assessable, label, version,
      paste0(
        "distinct ", facet, " values (", source,
        ") with at least one supported GIFT"
      )
    )))
    contributing <- rows[rows$gift_id %in% supported, , drop = FALSE]
    trace <- c(trace, list(.trace_rows(
      "genome", target_id, metric_id, label, contributing$gift_id,
      contributing$value
    )))
  }

  # Handoff interfaces are anchor-derived, so they exist only where the universe
  # reaches the metabolic model. Reporting an out-degree of zero for a universe
  # of structural GIFTs would imply a genome failed a test it was never given.
  if (any(members %in% c(graph$from_gift, graph$to_gift))) {
    outgoing <- graph[graph$from_gift %in% supported, , drop = FALSE]
    incoming <- graph[graph$to_gift %in% supported, , drop = FALSE]
    metrics <- c(metrics, list(
      .metric_row(
        "genome", target_id, "handoff_out_degree",
        length(unique(outgoing$shared_anchor)), "count",
        length(unique(outgoing$shared_anchor)), NA_integer_, assessable, label,
        version,
        "distinct output anchors of supported GIFTs that a curated GIFT consumes"
      ),
      .metric_row(
        "genome", target_id, "handoff_in_degree",
        length(unique(incoming$shared_anchor)), "count",
        length(unique(incoming$shared_anchor)), NA_integer_, assessable, label,
        version,
        "distinct input anchors of supported GIFTs that a curated GIFT produces"
      )
    ))
    trace <- c(trace, list(
      .trace_rows("genome", target_id, "handoff_out_degree", label,
                  outgoing$from_gift, outgoing$shared_anchor),
      .trace_rows("genome", target_id, "handoff_in_degree", label,
                  incoming$to_gift, incoming$shared_anchor)
    ))
  }

  redundant <- in_universe[
    in_universe$complete %in% TRUE &
      !is.na(in_universe$number_of_complete_implementations) &
      in_universe$number_of_complete_implementations > 1L, ,
    drop = FALSE
  ]
  metrics <- c(metrics, list(.metric_row(
    "genome", target_id, "multi_implementation_gifts", nrow(redundant), "count",
    nrow(redundant), length(supported), assessable, label, version,
    "supported GIFTs completed by more than one curated route, architecture, circuit or mechanism"
  )))
  trace <- c(trace, list(.trace_rows(
    "genome", target_id, "multi_implementation_gifts", label, redundant$gift_id,
    redundant$number_of_complete_implementations
  )))

  list(
    metrics = do.call(rbind, metrics),
    trace = do.call(rbind, trace)
  )
}

.cycle_metrics <- function(result, connection, target_id, version) {
  cycles <- evaluate_gift_cycles(result, db = connection)
  label <- "elementary cycles of the anchor composition graph"
  if (!nrow(cycles)) {
    return(list(metrics = .empty_metrics(), trace = .empty_trace()))
  }
  closed <- cycles[cycles$status == "closed", , drop = FALSE]
  members <- gift_cycles(db = connection)
  members <- members[members$cycle_id %in% closed$cycle_id, , drop = FALSE]
  list(
    metrics = .metric_row(
      "genome", target_id, "closed_cycles", nrow(closed), "count", nrow(closed),
      nrow(cycles), nrow(cycles), label, version,
      "cycles of the anchor graph whose every member GIFT is supported"
    ),
    trace = .trace_rows(
      "genome", target_id, "closed_cycles", label, members$gift_id,
      members$named_cycle
    )
  )
}

#' Quantitative traits of one genome
#'
#' Summarises the GIFT calls of a single genome into quantitative traits within
#' declared reference universes. Nothing here is curated and nothing here
#' changes a call: this reads the calls [evaluate_gifts()] already made, the
#' facets that classify them, and the derived [gift_profile()] and
#' [gift_graph()] views.
#'
#' Metrics reported per universe:
#'
#' \describe{
#'   \item{`gift_richness`}{supported GIFTs in the universe}
#'   \item{`supported_fraction`}{richness over assessable members, reported for
#'     bounded universes only. Over the biomass-essential anabolic universe this
#'     is biosynthetic capability coverage}
#'   \item{`breadth_*`}{distinct values of one curated facet or one
#'     [gift_profile()] classification represented by a supported GIFT}
#'   \item{`handoff_out_degree`, `handoff_in_degree`}{distinct anchors through
#'     which the genome's supported GIFTs could hand off to, or receive from, a
#'     curated GIFT. Reported only where the universe reaches the metabolic
#'     model, since anchors belong to it}
#'   \item{`multi_implementation_gifts`}{supported GIFTs completed by more than
#'     one curated implementation}
#'   \item{`closed_cycles`}{elementary cycles of the composition graph whose
#'     every member is supported, from [evaluate_gift_cycles()]}
#' }
#'
#' @section Interpretation:
#'
#' These traits count encoded capabilities in the current giftr ontology within
#' a stated universe. They are not measures of biological complexity, metabolic
#' versatility in an environment, growth independence, activity, flux or
#' phenotype. `supported_fraction = 0.8` over the biomass-essential anabolic
#' universe means four fifths of the curated biomass-essential anabolic
#' capabilities that were assessable are genomically supported; it does not mean
#' the organism grows without supplementation. The database is not the universe
#' of microbial function, which is why an unbounded universe reports no
#' fraction at all.
#'
#' `assessable` currently equals the size of the universe, because giftr accepts
#' no genome-quality information and therefore treats every member as assessed.
#' A fragmented genome will report absences that a complete one would not.
#'
#' @param result A result returned by [evaluate_gifts()].
#' @param universes Optional list of [gift_universe()] objects. A default set
#'   partitioning the catalogue by type, mode and resource strategy, plus the
#'   bounded biomass-essential anabolic universe, is used if omitted.
#' @param genome_id Identifier reported in the `target_id` column.
#' @param db Optional open giftr database connection.
#' @return A `giftr_traits` list with `metrics` (one row per trait),
#'   `trace` (the GIFTs behind each trait), `universes`, and
#'   `database_version`.
#' @examples
#' markers <- data.frame(
#'   gene_id = paste0("gene_", 1:9),
#'   namespace = "KO",
#'   accession = c(
#'     "K00764", "K01945", "K00601", "K01952", "K01933",
#'     "K01587", "K01756", "K00602", "K01939"
#'   )
#' )
#' traits <- genome_traits(evaluate_gifts(markers), genome_id = "MAG_001")
#' subset(traits$metrics, metric_id == "gift_richness",
#'        c("reference_universe", "value", "assessable"))
#' @export
genome_traits <- function(result, universes = NULL, genome_id = "genome",
                          db = NULL) {
  if (!inherits(result, "giftr_result")) {
    stop("result must come from evaluate_gifts()", call. = FALSE)
  }
  if (length(genome_id) != 1L || is.na(genome_id) || !nzchar(as.character(genome_id))) {
    stop("genome_id must be one non-empty identifier", call. = FALSE)
  }
  genome_id <- as.character(genome_id)

  .with_giftr_db(db, function(connection) {
    version <- giftr_db_version(connection)$giftr_db_version
    if (!identical(version, result$database_version$giftr_db_version)) {
      stop(
        "The result was evaluated against database version ",
        result$database_version$giftr_db_version,
        " but the supplied connection serves ", version,
        ". Traits computed across releases would compare different universes.",
        call. = FALSE
      )
    }
    if (is.null(universes)) universes <- .default_universes(connection)
    if (!is.list(universes) || !length(universes) ||
        !all(vapply(universes, inherits, logical(1), "giftr_universe"))) {
      stop("universes must be a non-empty list of gift_universe() objects", call. = FALSE)
    }
    stale <- vapply(universes, function(u) !identical(u$database_version, version), logical(1))
    if (any(stale)) {
      stop(
        "Universes were built against a different database version: ",
        paste(unique(vapply(universes[stale], function(u) u$label, character(1))), collapse = ", "),
        call. = FALSE
      )
    }

    calls <- result$gifts
    graph <- gift_graph(db = connection)
    parts <- lapply(universes, function(universe) {
      .universe_metrics(connection, universe, calls, graph, genome_id, version)
    })
    parts <- c(parts, list(.cycle_metrics(result, connection, genome_id, version)))

    metrics <- do.call(rbind, lapply(parts, function(part) part$metrics))
    trace <- do.call(rbind, lapply(parts, function(part) part$trace))
    if (is.null(metrics)) metrics <- .empty_metrics()
    if (is.null(trace)) trace <- .empty_trace()

    structure(
      list(
        metrics = metrics[.metric_columns],
        trace = trace[.trace_columns],
        universes = universes,
        genome_id = genome_id,
        database_version = result$database_version
      ),
      class = c("giftr_traits", "list")
    )
  })
}

#' @export
print.giftr_traits <- function(x, ...) {
  cat("<giftr_traits>", x$genome_id, "\n")
  cat("  metrics: ", nrow(x$metrics), "rows across", length(x$universes), "reference universes\n")
  cat("  database version:", x$database_version$giftr_db_version, "\n")
  richness <- x$metrics[x$metrics$metric_id == "gift_richness", , drop = FALSE]
  if (nrow(richness)) {
    cat("\n")
    for (index in seq_len(nrow(richness))) {
      cat(sprintf(
        "  %-46s %3d / %3d supported\n", richness$reference_universe[[index]],
        as.integer(richness$value[[index]]), richness$assessable[[index]]
      ))
    }
  }
  invisible(x)
}
