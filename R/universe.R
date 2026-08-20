# Reference universes for quantitative traits.
#
# A count of supported GIFTs means nothing without the set it was counted over,
# and that set changes between database releases. Every quantitative trait
# therefore names the universe it was computed in, and a universe is built only
# from curated metadata -- gift_type, mode, the registered facet vocabulary, and
# the derived gift_profile view. A universe may never be a literal list of
# gift_ids written in R source: that would move biological content out of the
# database and into code, where it cannot be validated or versioned.

.gifter_resource_strategies <- c("uptake", "public_good", "private", "unresolved")

.universe_label <- function(filters) {
  if (!length(filters)) return("all curated GIFTs")
  parts <- vapply(names(filters), function(name) {
    paste0(name, " = ", paste(filters[[name]], collapse = " | "))
  }, character(1))
  paste("GIFTs where", paste(parts, collapse = ", "))
}

#' Define a reference universe of GIFTs
#'
#' A quantitative trait is only interpretable relative to the set of GIFTs that
#' could have been called, so every metric [genome_traits()] reports names the
#' universe it was computed in. This function builds one from curated metadata.
#'
#' Filters combine with AND. `facet` and `value` read the registered facet
#' vocabulary; `resource_strategy` and `auxotrophy_indicator` read the derived
#' [gift_profile()] view, which covers metabolic GIFTs only, so either of them
#' bounds the universe to that type by construction.
#'
#' @section Bounded universes:
#'
#' `bounded` declares that the universe enumerates a biologically closed set
#' that curation intends to cover completely, so the fraction of it a genome
#' supports is a meaningful quantity. The curated biomass-essential anabolic
#' capabilities are such a set. "All metabolic GIFTs" is not: the catalogue is
#' open and growing, and a genome supporting 12 of 122 has not been shown to
#' lack 110 capabilities. [genome_traits()] reports `supported_fraction` for
#' bounded universes and withholds it otherwise, which is why the flag is a
#' biological claim rather than a formatting option. It defaults to `FALSE`.
#'
#' @param type Optional GIFT type: `"metabolic"`, `"structural"`,
#'   `"regulatory"` or `"defense"`.
#' @param mode Optional metabolic mode: `"anabolic"`, `"catabolic"`,
#'   `"transport"` or `"interconversion"`.
#' @param facet Optional registered facet name, such as `"substrate_class"`.
#' @param value Optional facet values. Requires `facet`.
#' @param resource_strategy Optional [gift_profile()] resource strategy.
#' @param auxotrophy_indicator Optional logical. `TRUE` selects the anabolic
#'   GIFTs whose declared output is a biomass-essential anchor.
#' @param status Optional curation status filter.
#' @param bounded Whether the denominator is biologically meaningful. See
#'   details.
#' @param label Optional human-readable name. Derived from the filters if
#'   omitted.
#' @param db Optional open gifter database connection.
#' @return A `gifter_universe`: the member `gift_id`s, the `label`, the filters
#'   that produced it, whether it is `bounded`, and the `database_version` it
#'   was resolved against.
#' @examples
#' universe <- gift_universe(mode = "anabolic", auxotrophy_indicator = TRUE,
#'                           bounded = TRUE, label = "biomass-essential anabolic")
#' length(universe$gift_id)
#' @export
gift_universe <- function(type = NULL, mode = NULL, facet = NULL, value = NULL,
                          resource_strategy = NULL, auxotrophy_indicator = NULL,
                          status = NULL, bounded = FALSE, label = NULL,
                          db = NULL) {
  if (!is.null(type)) type <- match.arg(type, .gifter_gift_types, several.ok = TRUE)
  if (!is.null(mode)) mode <- match.arg(mode, .gifter_gift_modes, several.ok = TRUE)
  if (!is.null(resource_strategy)) {
    resource_strategy <- match.arg(
      resource_strategy, .gifter_resource_strategies, several.ok = TRUE
    )
  }
  if (!is.null(value) && is.null(facet)) {
    stop("value requires a facet", call. = FALSE)
  }
  if (length(bounded) != 1L || is.na(bounded) || !is.logical(bounded)) {
    stop("bounded must be TRUE or FALSE", call. = FALSE)
  }

  .with_gifter_db(db, function(connection) {
    if (!is.null(facet)) {
      known <- .as_tibble_query(
        connection,
        "SELECT DISTINCT facet FROM facet_term WHERE applies_to = 'gift'"
      )$facet
      if (!all(facet %in% known)) {
        stop(
          "Unregistered GIFT facet: ",
          paste(setdiff(facet, known), collapse = ", "),
          ". Registered facets are: ", paste(sort(known), collapse = ", "),
          call. = FALSE
        )
      }
    }

    sql <- "SELECT g.gift_id FROM gift g"
    conditions <- character()
    params <- list()
    filters <- list()

    if (!is.null(type)) {
      conditions <- c(conditions, .in_predicate("g.gift_type", type))
      params <- c(params, as.list(type))
      filters$type <- type
    }
    if (!is.null(mode)) {
      conditions <- c(conditions, .in_predicate("g.mode", mode))
      params <- c(params, as.list(mode))
      filters$mode <- mode
    }
    if (!is.null(status)) {
      conditions <- c(conditions, "g.status = ?")
      params <- c(params, list(as.character(status)))
      filters$status <- as.character(status)
    }
    if (!is.null(facet)) {
      clause <- paste(
        "EXISTS (SELECT 1 FROM gift_facet f WHERE f.gift_pk = g.gift_pk AND",
        .in_predicate("f.facet", facet)
      )
      params <- c(params, as.list(facet))
      if (!is.null(value)) {
        clause <- paste(clause, "AND", .in_predicate("f.value", value))
        params <- c(params, as.list(as.character(value)))
      }
      conditions <- c(conditions, paste0(clause, ")"))
      filters$facet <- facet
      if (!is.null(value)) filters$value <- as.character(value)
    }
    if (!is.null(resource_strategy) || !is.null(auxotrophy_indicator)) {
      clause <- "EXISTS (SELECT 1 FROM gift_profile p WHERE p.gift_id = g.gift_id"
      if (!is.null(resource_strategy)) {
        clause <- paste(clause, "AND", .in_predicate("p.resource_strategy", resource_strategy))
        params <- c(params, as.list(resource_strategy))
        filters$resource_strategy <- resource_strategy
      }
      if (!is.null(auxotrophy_indicator)) {
        clause <- paste(clause, "AND p.auxotrophy_indicator = ?")
        params <- c(params, list(as.integer(isTRUE(auxotrophy_indicator))))
        filters$auxotrophy_indicator <- isTRUE(auxotrophy_indicator)
      }
      conditions <- c(conditions, paste0(clause, ")"))
    }

    if (length(conditions)) sql <- paste(sql, "WHERE", paste(conditions, collapse = " AND "))
    sql <- paste(sql, "ORDER BY g.gift_id")
    members <- .as_tibble_query(connection, sql, if (length(params)) params else NULL)

    structure(
      list(
        gift_id = members$gift_id,
        label = if (is.null(label)) .universe_label(filters) else as.character(label),
        filters = filters,
        bounded = isTRUE(bounded),
        database_version = gifter_db_version(connection)$gifter_db_version
      ),
      class = c("gifter_universe", "giftr_universe", "list")
    )
  })
}

.in_predicate <- function(column, values) {
  paste0(column, " IN (", paste(rep("?", length(values)), collapse = ", "), ")")
}

#' @export
print.gifter_universe <- function(x, ...) {
  cat("<gifter_universe>", x$label, "\n")
  cat("  GIFTs:  ", length(x$gift_id), "\n")
  cat("  bounded:", x$bounded, "\n")
  cat("  database version:", x$database_version, "\n")
  invisible(x)
}

#' @export
print.giftr_universe <- print.gifter_universe

# The universes reported when the caller supplies none. Types and modes
# partition the catalogue two ways, because gift_type barely partitions a
# database that is overwhelmingly metabolic while mode splits it usefully. Only
# the biomass-essential anabolic set is bounded, and it is the universe that
# makes supported_fraction mean biosynthetic autonomy.
.default_universes <- function(connection) {
  universes <- list(gift_universe(db = connection, label = "all curated GIFTs"))
  present_types <- .as_tibble_query(
    connection, "SELECT DISTINCT gift_type FROM gift ORDER BY gift_type"
  )$gift_type
  universes <- c(universes, lapply(present_types, function(type) {
    gift_universe(type = type, db = connection, label = paste(type, "GIFTs"))
  }))
  present_modes <- .as_tibble_query(
    connection, "SELECT DISTINCT mode FROM gift WHERE mode IS NOT NULL ORDER BY mode"
  )$mode
  universes <- c(universes, lapply(present_modes, function(mode) {
    gift_universe(mode = mode, db = connection, label = paste(mode, "GIFTs"))
  }))
  present_strategies <- .as_tibble_query(
    connection,
    "SELECT DISTINCT resource_strategy FROM gift_profile ORDER BY resource_strategy"
  )$resource_strategy
  universes <- c(universes, lapply(present_strategies, function(strategy) {
    gift_universe(
      resource_strategy = strategy, db = connection,
      label = paste0("GIFTs with resource strategy ", strategy)
    )
  }))
  universes <- c(universes, list(gift_universe(
    mode = "anabolic", auxotrophy_indicator = TRUE, bounded = TRUE,
    db = connection, label = "biomass-essential anabolic GIFTs"
  )))
  universes[vapply(universes, function(u) length(u$gift_id) > 0L, logical(1))]
}
