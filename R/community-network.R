# Potential resource-handoff topology of a genome-resolved community.
#
# This layer creates no compatibility semantics of its own. `gift_graph`
# already decides when one GIFT's declared output anchor can reach another's
# declared input, including when a compartment was never licensed; all that
# happens here is the projection of an existing GIFT edge onto the pair of
# genomes that support its ends.
#
# Every edge therefore inherits the `edge_quality` of the GIFT edge beneath it.
# An edge built on a `compartment_inexact` GIFT edge is an inexact handoff, and
# collapsing that distinction would erase the reason the anchor compartment
# qualifier exists.
#
# One rule this layer does add, because `gift_graph` is not asking the same
# question: a molecule can only pass between two organisms if it leaves a cell,
# so a cross-genome edge requires the producing GIFT's output anchor to be
# declared `extracellular`. A cytoplasmic anchor is inside one cell and an
# `unspecified` one was never licensed to leave it. Within a single genome the
# same link is an ordinary composition step and stays one.
#
# An edge is a potential compatibility relationship. It is not evidence that
# exchange occurs, that either GIFT is expressed, or that the two organisms
# ever meet.

.gifter_interaction_types <- c("metabolic_handoff")

# The anchors a molecule can actually cross a cell boundary through. Only a
# declared `extracellular` anchor licenses that claim: `cytoplasmic` is inside
# one cell by construction, and `unspecified` means curation never evidenced a
# location, which is not the same as evidencing an external one.
.transferable_anchors <- function(connection) {
  .as_tibble_query(
    connection,
    "SELECT anchor_id FROM anchor WHERE compartment = 'extracellular'"
  )$anchor_id
}

.handoff_edges <- function(community, graph, universe_ids, transferable) {
  genomes <- community$genome_id
  matrix <- community$matrix
  graph <- graph[graph$shared_anchor %in% transferable, , drop = FALSE]
  supported_by <- lapply(stats::setNames(genomes, genomes), function(genome) {
    intersect(rownames(matrix)[matrix[, genome] %in% TRUE], universe_ids)
  })

  rows <- list()
  for (index in seq_len(nrow(graph))) {
    edge <- graph[index, , drop = FALSE]
    providers <- genomes[vapply(supported_by, function(ids) {
      edge$from_gift %in% ids
    }, logical(1))]
    recipients <- genomes[vapply(supported_by, function(ids) {
      edge$to_gift %in% ids
    }, logical(1))]
    if (!length(providers) || !length(recipients)) next
    pairs <- expand.grid(
      from_genome = providers, to_genome = recipients,
      stringsAsFactors = FALSE
    )
    # A genome that supports both ends composes the chain internally. That is a
    # property of the genome, not a handoff between organisms, and reporting it
    # as an edge would let a self-sufficient genome inflate the community's
    # interaction density.
    pairs <- pairs[pairs$from_genome != pairs$to_genome, , drop = FALSE]
    if (!nrow(pairs)) next
    rows[[length(rows) + 1L]] <- tibble::tibble(
      from_genome = pairs$from_genome,
      to_genome = pairs$to_genome,
      from_gift = edge$from_gift,
      to_gift = edge$to_gift,
      shared_anchor = edge$shared_anchor,
      edge_quality = edge$edge_quality
    )
  }
  if (!length(rows)) {
    return(tibble::tibble(
      from_genome = character(), to_genome = character(),
      from_gift = character(), to_gift = character(),
      shared_anchor = character(), edge_quality = character()
    ))
  }
  edges <- do.call(rbind, rows)
  edges[order(edges$from_genome, edges$to_genome, edges$shared_anchor), , drop = FALSE]
}

.chain_coverage <- function(community, graph, universe_ids, transferable) {
  genomes <- community$genome_id
  matrix <- community$matrix
  supported_by <- lapply(stats::setNames(genomes, genomes), function(genome) {
    intersect(rownames(matrix)[matrix[, genome] %in% TRUE], universe_ids)
  })
  represented <- Reduce(union, supported_by, character())

  in_universe <- graph[
    graph$from_gift %in% universe_ids & graph$to_gift %in% universe_ids, ,
    drop = FALSE
  ]
  if (!nrow(in_universe)) {
    return(tibble::tibble(
      from_gift = character(), shared_anchor = character(),
      to_gift = character(), edge_quality = character(),
      transferable = logical(), status = character(),
      within_genome = character(), providers = character(),
      recipients = character()
    ))
  }

  rows <- lapply(seq_len(nrow(in_universe)), function(index) {
    edge <- in_universe[index, , drop = FALSE]
    providers <- genomes[vapply(supported_by, function(ids) edge$from_gift %in% ids, logical(1))]
    recipients <- genomes[vapply(supported_by, function(ids) edge$to_gift %in% ids, logical(1))]
    within <- intersect(providers, recipients)
    crosses_boundary <- edge$shared_anchor %in% transferable
    status <- if (length(within)) {
      "within_genome"
    } else if (length(providers) && length(recipients) && crosses_boundary) {
      # Both halves exist in the community, no member holds both, and the shared
      # molecule is declared extracellular. This is the link the community
      # completes and no genome does.
      "community_distributed"
    } else if (length(providers) && length(recipients)) {
      # Both halves exist in different genomes but the molecule never leaves a
      # cell, so nothing completes this link. Calling it distributed would hand
      # a cytoplasmic intermediate between organisms.
      "not_transferable"
    } else {
      "not_represented"
    }
    tibble::tibble(
      from_gift = edge$from_gift, shared_anchor = edge$shared_anchor,
      to_gift = edge$to_gift, edge_quality = edge$edge_quality,
      transferable = crosses_boundary, status = status,
      within_genome = paste(sort(within), collapse = ", "),
      providers = paste(sort(providers), collapse = ", "),
      recipients = paste(sort(recipients), collapse = ", ")
    )
  })
  coverage <- do.call(rbind, rows)
  coverage <- coverage[coverage$from_gift %in% represented | coverage$to_gift %in% represented, , drop = FALSE]
  coverage[order(coverage$from_gift, coverage$shared_anchor, coverage$to_gift), , drop = FALSE]
}

.distributed_cycles <- function(community, connection, limit, transferable) {
  cycles <- gift_cycles(db = connection, limit = limit)
  if (!nrow(cycles)) {
    return(tibble::tibble(
      cycle_id = integer(), named_cycle = character(), cycle_length = integer(),
      status = character(), closed_by = character(),
      members_supported = integer(), transferable = logical()
    ))
  }
  genomes <- community$genome_id
  matrix <- community$matrix
  parts <- split(cycles, cycles$cycle_id)
  rows <- lapply(parts, function(cycle) {
    members <- cycle$gift_id
    present <- members[members %in% rownames(matrix)]
    per_genome <- vapply(genomes, function(genome) {
      length(present) == length(members) && all(matrix[members, genome] %in% TRUE)
    }, logical(1))
    supported_anywhere <- vapply(members, function(gift) {
      gift %in% rownames(matrix) && any(matrix[gift, ] %in% TRUE)
    }, logical(1))
    # A cycle can only be closed across organisms if every molecule handed from
    # one segment to the next actually leaves a cell. Central metabolism runs on
    # intermediates that never do, so this is `FALSE` for the cycles gifter
    # currently derives -- and reporting a distributed citric acid cycle would
    # pass oxaloacetate between organisms.
    crosses_boundary <- all(cycle$shared_anchor %in% transferable)
    status <- if (any(per_genome)) {
      "within_genome"
    } else if (all(supported_anywhere) && crosses_boundary) {
      "community_distributed"
    } else {
      "not_closed"
    }
    tibble::tibble(
      cycle_id = cycle$cycle_id[[1L]],
      named_cycle = cycle$named_cycle[[1L]],
      cycle_length = cycle$cycle_length[[1L]],
      status = status,
      closed_by = paste(genomes[per_genome], collapse = ", "),
      members_supported = sum(supported_anywhere),
      transferable = crosses_boundary
    )
  })
  summary <- do.call(rbind, rows)
  summary[order(summary$cycle_id), , drop = FALSE]
}

#' Potential resource-handoff topology of a community
#'
#' Projects the curated GIFT composition graph onto a genome-resolved
#' community: a directed edge means one genome supports a GIFT whose declared
#' output anchor another genome's supported GIFT declares as an input.
#'
#' No compatibility rule is invented here. [gift_graph()] already decides when
#' one GIFT's output can reach another's input, and this reads that decision.
#' `metabolic_handoff` is therefore the only interaction type: the other GIFT
#' types declare no anchors, and an edge between them would have to be inferred
#' from co-occurrence, which is not evidence of anything.
#'
#' @section What an edge is and is not:
#'
#' An edge is a **potential** compatibility relationship between what one genome
#' encodes and what another encodes. It is not evidence that exchange occurs,
#' that either GIFT is expressed, that the molecule is ever released at a useful
#' concentration, or that the two organisms co-occur. Cross-feeding is a
#' hypothesis an edge can support, never a conclusion it establishes.
#'
#' Every edge carries the `edge_quality` of the GIFT edge beneath it. An
#' `exact` edge means both GIFTs declared the same anchor; a
#' `compartment_inexact` edge means one side left the compartment unresolved,
#' so the handoff assumes a location that curation did not license. A network
#' filtered to exact edges is the stronger claim.
#'
#' A genome supporting both ends composes the chain internally and produces no
#' edge, because that is a property of one genome rather than a relationship
#' between two.
#'
#' A cross-genome edge additionally requires the producing GIFT's output anchor
#' to be declared `extracellular`. A cytoplasmic anchor is inside one cell, and
#' an `unspecified` one was never evidenced as leaving it, so neither can carry
#' a molecule between organisms. `chain_coverage` records such a link as
#' `not_transferable` when its two halves fall in different genomes: nothing
#' completes it, and calling it distributed would hand a cytoplasmic
#' intermediate from one organism to another.
#'
#' @param community A community from [gifter_community()].
#' @param interaction Interaction type. Only `"metabolic_handoff"` is defined.
#' @param universe Optional [gift_universe()] restricting which GIFTs may form
#'   edges.
#' @param quality Optional `gift_graph()` edge quality filter, `"exact"` or
#'   `"compartment_inexact"`.
#' @param limit Passed to [gift_cycles()] for distributed cycle closure.
#' @param db Optional open gifter database connection.
#' @return A `gifter_network` list with `nodes` (one row per genome, with
#'   provider and recipient degrees), `edges`, `chain_coverage` (each curated
#'   composition link classified as `within_genome`, `community_distributed`,
#'   `not_transferable` or `not_represented`), `cycle_coverage`, and `metrics`.
#' @export
community_network <- function(community, interaction = "metabolic_handoff",
                              universe = NULL, quality = NULL, limit = 100L,
                              db = NULL) {
  if (!inherits(community, "gifter_community")) {
    stop("community must come from gifter_community()", call. = FALSE)
  }
  interaction <- match.arg(interaction, .gifter_interaction_types)
  if (!is.null(quality)) {
    quality <- match.arg(quality, c("exact", "compartment_inexact"))
  }
  if (!is.null(universe) &&
      !inherits(universe, "gifter_universe")) {
    stop("universe must come from gift_universe()", call. = FALSE)
  }

  .with_gifter_db(db, function(connection) {
    version <- gifter_db_version(connection)$gifter_db_version
    community_version <- .gifter_database_version_value(community$database_version)
    if (!identical(version, community_version)) {
      stop(
        "The community was evaluated against database version ",
        community_version,
        " but the supplied connection serves ", version, ".",
        call. = FALSE
      )
    }
    if (is.null(universe)) {
      universe <- gift_universe(db = connection, label = "all curated GIFTs")
    } else if (!identical(universe$database_version, version)) {
      stop("The universe was built against a different database version", call. = FALSE)
    }

    graph <- gift_graph(db = connection, quality = quality)
    transferable <- .transferable_anchors(connection)
    universe_ids <- universe$gift_id
    edges <- .handoff_edges(community, graph, universe_ids, transferable)
    coverage <- .chain_coverage(community, graph, universe_ids, transferable)
    cycles <- .distributed_cycles(community, connection, limit, transferable)

    genomes <- community$genome_id
    nodes <- tibble::tibble(
      genome_id = genomes,
      provider_degree = unname(vapply(genomes, function(genome) {
        length(unique(edges$to_genome[edges$from_genome == genome]))
      }, integer(1))),
      recipient_degree = unname(vapply(genomes, function(genome) {
        length(unique(edges$from_genome[edges$to_genome == genome]))
      }, integer(1))),
      handoff_richness = unname(vapply(genomes, function(genome) {
        involved <- edges$from_genome == genome | edges$to_genome == genome
        length(unique(edges$shared_anchor[involved]))
      }, integer(1)))
    )

    pairs <- unique(edges[c("from_genome", "to_genome")])
    ordered_pairs <- length(genomes) * (length(genomes) - 1L)
    label <- universe$label
    metrics <- .metric_row(
      "community", "community", "interaction_density",
      if (ordered_pairs > 0L) nrow(pairs) / ordered_pairs else NA_real_,
      "proportion", nrow(pairs), ordered_pairs, length(universe_ids), label,
      version,
      paste(
        "ordered genome pairs joined by at least one potential resource handoff,",
        "over all ordered pairs; a pair connected in both directions counts twice"
      )
    )
    metrics <- rbind(metrics, .metric_row(
      "community", "community", "handoff_edges", nrow(edges), "count",
      nrow(edges), NA_integer_, length(universe_ids), label, version,
      "GIFT-resolved potential resource handoffs between distinct genomes"
    ))
    distributed <- coverage$status == "community_distributed"
    metrics <- rbind(metrics, .metric_row(
      "community", "community", "distributed_chain_links", sum(distributed),
      "count", sum(distributed), nrow(coverage), length(universe_ids), label,
      version,
      "curated composition links completed only by combining genomes, over represented links"
    ))

    structure(
      list(
        interaction = interaction,
        nodes = nodes,
        edges = edges,
        chain_coverage = coverage,
        cycle_coverage = cycles,
        metrics = metrics,
        universe = universe,
        database_version = community$database_version
      ),
      class = c("gifter_network", "list")
    )
  })
}

#' @export
print.gifter_network <- function(x, ...) {
  cat("<gifter_network>", x$interaction, "\n")
  cat("  genomes:", nrow(x$nodes), "\n")
  cat("  potential handoffs:", nrow(x$edges))
  if (nrow(x$edges)) {
    inexact <- sum(x$edges$edge_quality == "compartment_inexact")
    cat(" (", nrow(x$edges) - inexact, " exact, ", inexact, " compartment-inexact)", sep = "")
  }
  cat("\n")
  distributed <- sum(x$chain_coverage$status == "community_distributed")
  within <- sum(x$chain_coverage$status == "within_genome")
  cat("  composition links: ", within, " within a genome, ", distributed,
      " completed only across the community\n", sep = "")
  cat("  database version:", .gifter_database_version_value(x$database_version), "\n")
  invisible(x)
}
