# Cyclic metabolic topology, derived rather than curated.
#
# gifter composes GIFTs through declared anchors, and some real metabolism closes
# a ring: the oxidative citric acid cycle, the glyoxylate bypass, the reductive
# citric acid cycle, the Calvin cycle. None of those is a new kind of object.
# Each is a cycle in the graph `gift_graph()` already derives, so this file
# contains graph code and no biology. The only curated part of a cycle is its
# name, which lives in the `metabolic_cycle` GIFT facet.
#
# See inst/doc/proposal-central-metabolic-cycles.md for why this is derived and
# not stored, and for why closure never feeds back into a GIFT's Boolean call.

# The enumeration bound, checked wherever a cycle enumeration is asked for
# rather than only where it is finally run: a caller who states a nonsensical
# limit should hear about it before the work that leads up to the enumeration,
# not after it.
.check_cycle_limit <- function(limit) {
  if (!is.numeric(limit) || length(limit) != 1L || is.na(limit) || limit < 1L) {
    stop("limit must be one positive number", call. = FALSE)
  }
  invisible(NULL)
}

# Elementary cycles of a directed graph, by the standard depth-first
# enumeration: a cycle is reported once, from its lowest-ordered node, and a
# node already on the current path is never revisited. `limit` bounds the result
# because the enumeration is exponential in the worst case; the metabolic
# composition graph is small and sparse, but a caller should be told when it
# stopped early rather than left to guess.
.elementary_cycles <- function(edges, limit = 100L) {
  found <- list()
  truncated <- FALSE
  if (!nrow(edges)) {
    return(structure(found, truncated = truncated))
  }
  nodes <- sort(unique(c(edges$from, edges$to)))
  rank <- stats::setNames(seq_along(nodes), nodes)
  successors <- split(edges$to, factor(edges$from, levels = nodes))

  visit <- function(start, node, path) {
    if (truncated) return(invisible(NULL))
    for (next_node in successors[[node]]) {
      if (identical(next_node, start)) {
        found[[length(found) + 1L]] <<- path
        if (length(found) >= limit) {
          truncated <<- TRUE
          return(invisible(NULL))
        }
      } else if (!next_node %in% path && rank[[next_node]] > rank[[start]]) {
        visit(start, next_node, c(path, next_node))
      }
      if (truncated) return(invisible(NULL))
    }
    invisible(NULL)
  }

  for (start in nodes) {
    visit(start, start, start)
    if (truncated) break
  }
  structure(found, truncated = truncated)
}

# The curated name of a cycle, when its members agree on one. A cycle whose
# members carry different `metabolic_cycle` values, or none, is still a real
# cycle and is reported without a name -- which is what keeps the accessor
# general instead of a lookup for the cycles somebody remembered to label.
.cycle_name <- function(members, facets) {
  values <- lapply(members, function(gift) facets$value[facets$gift_id == gift])
  shared <- Reduce(intersect, values)
  if (!length(shared)) return(NA_character_)
  sort(shared)[[1]]
}

#' Derive the cyclic structure of the GIFT composition graph
#'
#' A cycle in the composition graph is a set of GIFTs whose declared anchors
#' close a ring: each member's output boundary is the next member's input
#' boundary, and the last returns to the first. The oxidative citric acid cycle
#' is one, and nothing about it is curated -- it follows from four boundary
#' declarations. Compare [gift_graph()], which returns the edges this is derived
#' from.
#'
#' A cycle is a statement about curated boundaries, not about any genome. Use
#' [evaluate_gift_cycles()] to ask whether a particular genome closes one.
#'
#' Two loops are excluded because the mode makes them rather than the chemistry:
#' a two-node loop between `interconversion` GIFTs, which that mode's boundary
#' contract produces by construction, and any ring containing both an
#' `anabolic` and a `catabolic` member, which says that a genome can both build
#' a metabolite and break it down. Composition is expected to cycle between
#' modes, which is why the source validator checks acyclicity per mode, so
#' neither loop is circular metabolism.
#'
#' `named_cycle` is the value of the `metabolic_cycle` facet shared by every
#' member, and `NA` when the members share none. Naming is the only curated part
#' of a cycle; membership and shape are derived, so the two cannot disagree.
#'
#' @param db Optional open gifter database connection.
#' @param limit Maximum number of cycles to enumerate. Elementary-cycle
#'   enumeration is exponential in the worst case, so the search stops at this
#'   many and warns rather than running unbounded.
#' @return A tibble with one row per member of each cycle: `cycle_id`,
#'   `cycle_length`, `position`, `gift_id`, `shared_anchor` -- the anchor through
#'   which this member reaches the next -- and `named_cycle`.
#' @examples
#' cycles <- gift_cycles()
#' unique(cycles[, c("cycle_id", "cycle_length", "named_cycle")])
#' @export
gift_cycles <- function(db = NULL, limit = 100L) {
  .check_cycle_limit(limit)
  .with_gifter_db(db, function(connection) {
    graph <- .as_tibble_query(
      connection,
      "SELECT from_gift, shared_anchor, to_gift FROM gift_graph"
    )
    facets <- .as_tibble_query(
      connection,
      paste(
        "SELECT g.gift_id, f.value FROM gift_facet f",
        "JOIN gift g ON g.gift_pk = f.gift_pk",
        "WHERE f.facet = 'metabolic_cycle'"
      )
    )
    modes <- .as_tibble_query(connection, "SELECT gift_id, mode FROM gift")
    gift_mode <- stats::setNames(modes$mode, modes$gift_id)
    empty <- tibble::tibble(
      cycle_id = integer(), cycle_length = integer(), position = integer(),
      gift_id = character(), shared_anchor = character(), named_cycle = character()
    )
    edges <- data.frame(
      from = graph$from_gift, to = graph$to_gift, stringsAsFactors = FALSE
    )
    edges <- unique(edges)
    cycles <- .elementary_cycles(edges, limit = as.integer(limit))
    # Two kinds of loop are made by the mode rather than by the chemistry, and
    # neither is circular metabolism.
    #
    # A two-node cycle between two interconversion GIFTs is the first: that mode
    # declares every anchor in both roles, so a shared anchor produces an edge
    # each way whatever the chemistry does. The source validator exempts exactly
    # this case from the acyclicity check, and reporting it would contradict it.
    #
    # A cycle that contains both an anabolic and a catabolic member is the
    # second, and the amino acid layer is what made it common: a genome that can
    # build L-arginine and also take it apart closes a ring in the graph, and so
    # does every biosynthesis/degradation pair. The composition rule already
    # calls those loops expected rather than erroneous -- they are why the
    # acyclicity check runs per mode -- so a ring that reverses direction is a
    # statement about two capabilities existing, not about metabolism running
    # round. Reporting them would also bury the cycles that do run one way: with
    # the amino acid layer curated, the mixed-mode rings outnumber the citric
    # acid cycle by more than thirty to one and exhaust the enumeration limit.
    directional <- function(members) {
      modes <- unname(gift_mode[members])
      !(("anabolic" %in% modes) && ("catabolic" %in% modes))
    }
    cycles <- Filter(function(members) {
      directional(members) &&
        !(length(members) == 2L &&
            all(unname(gift_mode[members]) %in% "interconversion"))
    }, cycles)
    if (isTRUE(attr(cycles, "truncated"))) {
      warning(
        "Cycle enumeration stopped at limit = ", limit,
        "; the reported cycles are a subset.", call. = FALSE
      )
    }
    if (!length(cycles)) return(empty)

    # Deterministic order: shorter cycles first, then alphabetically by member,
    # so that a cycle keeps its identifier across rebuilds.
    keys <- vapply(cycles, function(members) {
      paste0(
        formatC(length(members), width = 4, flag = "0"), "|",
        paste(sort(members), collapse = "|")
      )
    }, character(1))
    cycles <- cycles[order(keys)]

    rows <- lapply(seq_along(cycles), function(index) {
      members <- cycles[[index]]
      following <- c(members[-1L], members[[1L]])
      anchors <- vapply(seq_along(members), function(step) {
        candidates <- graph$shared_anchor[
          graph$from_gift == members[[step]] & graph$to_gift == following[[step]]
        ]
        if (!length(candidates)) NA_character_ else sort(candidates)[[1]]
      }, character(1))
      tibble::tibble(
        cycle_id = index,
        cycle_length = length(members),
        position = seq_along(members),
        gift_id = members,
        shared_anchor = anchors,
        named_cycle = .cycle_name(members, facets)
      )
    })
    do.call(rbind, rows)
  })
}

#' Report which derived cycles a genome closes
#'
#' Reads a completed [evaluate_gifts()] result against the cycles
#' [gift_cycles()] derives, and reports for each whether the genome supports
#' every member.
#'
#' This never changes a call. A GIFT is complete or not on its own routes and
#' markers, whether or not its neighbours are; inferring a capability's absence
#' from a neighbour's absence is the opposite of what the composition model is
#' for. `status` is therefore assembled from calls that were already made:
#'
#' \describe{
#'   \item{`closed`}{every member of the cycle is complete}
#'   \item{`open`}{some but not all members are complete; `broken_at` names the
#'     members that are not}
#'   \item{`absent`}{no member is complete}
#' }
#'
#' A `closed` cycle means the genome encodes at least one complete route for
#' every segment of a ring in the composition graph. It does not mean the cycle
#' carries flux, runs in the direction the name suggests, or is expressed. Two
#' of the citric acid cycle's segments are curated as `interconversion`
#' precisely because gifter cannot say which way they run.
#'
#' @param result A result returned by [evaluate_gifts()].
#' @param db Optional open gifter database connection.
#' @param limit Passed to [gift_cycles()].
#' @return A tibble with one row per cycle: `cycle_id`, `named_cycle`,
#'   `cycle_length`, `supported`, `status`, and `broken_at`, a comma-separated
#'   list of the members that are not complete.
#' @export
evaluate_gift_cycles <- function(result, db = NULL, limit = 100L) {
  if (!inherits(result, "gifter_genome")) {
    stop("result must come from evaluate_gifts()", call. = FALSE)
  }
  cycles <- gift_cycles(db = db, limit = limit)
  if (!nrow(cycles)) {
    return(tibble::tibble(
      cycle_id = integer(), named_cycle = character(), cycle_length = integer(),
      supported = integer(), status = character(), broken_at = character()
    ))
  }
  complete <- stats::setNames(
    as.logical(result$gifts$complete), result$gifts$gift_id
  )
  parts <- split(cycles, cycles$cycle_id)
  rows <- lapply(parts, function(cycle) {
    # A member missing from the result is not complete. Silently treating it as
    # supported would let a filtered evaluation close a cycle it never tested.
    supported <- unname(!is.na(complete[cycle$gift_id]) & complete[cycle$gift_id])
    status <- if (all(supported)) {
      "closed"
    } else if (any(supported)) {
      "open"
    } else {
      "absent"
    }
    broken_at <- paste(sort(cycle$gift_id[!supported]), collapse = ", ")
    # `status` and `broken_at` are computed before the tibble is built rather
    # than inside it: `tibble()` evaluates its arguments in order and exposes
    # earlier ones to later ones, so an expression reading `supported` would see
    # the summed column rather than this vector.
    tibble::tibble(
      cycle_id = cycle$cycle_id[[1L]],
      named_cycle = cycle$named_cycle[[1L]],
      cycle_length = cycle$cycle_length[[1L]],
      supported = sum(supported),
      status = status,
      broken_at = broken_at
    )
  })
  summary <- do.call(rbind, rows)
  summary[order(summary$cycle_id), , drop = FALSE]
}
