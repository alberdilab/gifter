# Potential resource-handoff topology, per sample.
#
# No compatibility semantics are added here. `gift_graph` decides when one
# GIFT's declared output anchor reaches another's declared input,
# `community_network()` projects that decision onto a pair of genomes, and the
# extracellular gate that keeps a cytoplasmic molecule inside one cell stays
# exactly where it is. All this layer does is ask the same question of each
# sample's membership.
#
# The catalogue's edge set is built once and filtered to each sample's detected
# genomes, because which genome could hand which molecule to which other genome
# is a property of the two genomes. What varies per sample is which of those
# pairs are both there -- so the degrees, the density, the chain coverage and
# the cycle closure are recounted, and the edges are restricted.
#
# Detection removes genomes from a sample. It never creates an edge, never
# relaxes the compartment rule, and never changes what an edge means. An edge
# is a potential compatibility relationship in a sample where both organisms
# were detected; it is not evidence that exchange occurs.

# One sample's topology, from the catalogue's edges restricted to its members.
.sample_topology <- function(community, catalogue_edges, graph, cycles,
                             universe_ids, transferable, label, version,
                             sample) {
  genomes <- community$genome_id
  edges <- catalogue_edges[
    catalogue_edges$from_genome %in% genomes &
      catalogue_edges$to_genome %in% genomes, ,
    drop = FALSE
  ]
  nodes <- tibble::tibble(
    sample_id = sample,
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
  # Recounted rather than restricted: a link is completed within a genome only
  # if a *detected* genome holds both ends, and a cycle is closed only if a
  # detected genome closes it.
  coverage <- .chain_coverage(community, graph, universe_ids, transferable)
  cycle_coverage <- .distributed_cycles(community, cycles, transferable)

  pairs <- unique(edges[c("from_genome", "to_genome")])
  ordered_pairs <- length(genomes) * (length(genomes) - 1L)
  distributed <- coverage$status == "community_distributed"
  metrics <- rbind(
    .sample_metric_row(
      sample, "community", "community", "interaction_density",
      if (ordered_pairs > 0L) nrow(pairs) / ordered_pairs else NA_real_,
      "proportion", nrow(pairs), ordered_pairs, length(universe_ids), label,
      version,
      paste(
        "ordered pairs of genomes detected in this sample joined by at least",
        "one potential resource handoff, over all ordered pairs of them; a",
        "pair connected in both directions counts twice"
      )
    ),
    .sample_metric_row(
      sample, "community", "community", "handoff_edges", nrow(edges), "count",
      nrow(edges), NA_integer_, length(universe_ids), label, version,
      "GIFT-resolved potential resource handoffs between distinct genomes detected in this sample"
    ),
    .sample_metric_row(
      sample, "community", "community", "distributed_chain_links",
      sum(distributed), "count", sum(distributed), nrow(coverage),
      length(universe_ids), label, version,
      "curated composition links completed only by combining genomes detected in this sample, over represented links"
    )
  )

  if (nrow(edges)) edges$sample_id <- sample
  if (nrow(coverage)) coverage$sample_id <- sample
  if (nrow(cycle_coverage)) cycle_coverage$sample_id <- sample
  list(
    nodes = nodes,
    edges = if (nrow(edges)) edges[c("sample_id", setdiff(names(edges), "sample_id"))] else NULL,
    chain_coverage = if (nrow(coverage)) {
      coverage[c("sample_id", setdiff(names(coverage), "sample_id"))]
    } else NULL,
    cycle_coverage = if (nrow(cycle_coverage)) {
      cycle_coverage[c("sample_id", setdiff(names(cycle_coverage), "sample_id"))]
    } else NULL,
    metrics = metrics
  )
}

#' Potential resource-handoff topology of every sample in a dataset
#'
#' Asks of each sample the question [community_network()] asks of one
#' community: which genomes detected there support a GIFT whose declared output
#' anchor another detected genome's supported GIFT declares as an input.
#'
#' No compatibility rule is invented, and none is relaxed. [gift_graph()]
#' decides when one GIFT's output can reach another's input, every edge inherits
#' the `edge_quality` of the GIFT edge beneath it, and a cross-genome edge still
#' requires the producing GIFT's output anchor to be declared `extracellular`.
#' Detection decides only which genomes are in a sample's community.
#'
#' The catalogue's edge set is built once and restricted to each sample's
#' detected genomes, because which genome could hand which molecule to which
#' other is a property of the two genomes. Degrees, density, chain coverage and
#' cycle closure are recounted per sample, since each depends on which genomes
#' are actually there --- a link is completed within a genome only when a
#' detected genome holds both ends.
#'
#' @section What an edge is and is not:
#'
#' An edge is a **potential** compatibility relationship between what one genome
#' encodes and what another encodes, in a sample where both were detected. It is
#' not evidence that exchange occurs, that either GIFT is expressed, that the
#' molecule is released at a useful concentration, or that the two organisms
#' ever meet. Cross-feeding is a hypothesis an edge can support, never a
#' conclusion it establishes, and a difference in edge count between two groups
#' of samples is not a difference in interaction.
#'
#' @section Cost:
#'
#' Unlike the metrics of [dataset_traits()], the edges cannot be vectorized away:
#' the returned `edges` table carries one row per sample per edge. A catalogue
#' whose genomes are densely connected produces a large table for a dataset of
#' many samples, and `universe` is the lever that narrows it.
#'
#' @param dataset A dataset from [gifter_dataset()].
#' @param interaction Interaction type. Only `"metabolic_handoff"` is defined.
#' @param universe Optional [gift_universe()] restricting which GIFTs may form
#'   edges.
#' @param quality Optional [gift_graph()] edge quality filter, `"exact"` or
#'   `"compartment_inexact"`. This is the quality of a curated GIFT edge, not a
#'   genome completeness estimate.
#' @param detection Abundance a genome must exceed to be a member of a sample's
#'   community. `0` by default.
#' @param limit Passed to [gift_cycles()] for distributed cycle closure, which
#'   is enumerated once and read per sample.
#' @param db Optional open gifter database connection.
#' @return A `gifter_dataset_network` list whose `nodes`, `edges`,
#'   `chain_coverage`, `cycle_coverage` and `metrics` each carry a `sample_id`
#'   column.
#' @export
dataset_network <- function(dataset, interaction = "metabolic_handoff",
                            universe = NULL, quality = NULL, detection = 0,
                            limit = 100L, db = NULL) {
  if (!inherits(dataset, "gifter_dataset")) {
    stop("dataset must come from gifter_dataset()", call. = FALSE)
  }
  interaction <- match.arg(interaction, .gifter_interaction_types)
  if (!is.null(quality)) {
    quality <- match.arg(quality, c("exact", "compartment_inexact"))
  }
  if (!is.null(universe) && !inherits(universe, "gifter_universe")) {
    stop("universe must come from gift_universe()", call. = FALSE)
  }
  .check_cycle_limit(limit)
  detection <- .normalize_detection(detection)
  detected <- .detection_matrix(dataset$abundance, detection)

  .with_gifter_db(db, function(connection) {
    version <- gifter_db_version(connection)$gifter_db_version
    dataset_version <- .gifter_database_version_value(dataset$database_version)
    if (!identical(version, dataset_version)) {
      stop(
        "The dataset was evaluated against database version ", dataset_version,
        " but the supplied connection serves ", version, ".",
        call. = FALSE
      )
    }
    if (is.null(universe)) {
      universe <- gift_universe(db = connection, label = "all curated GIFTs")
    } else if (!identical(universe$database_version, version)) {
      stop(
        "The universe was built against a different database version",
        call. = FALSE
      )
    }

    graph <- gift_graph(db = connection, quality = quality)
    transferable <- .transferable_anchors(connection)
    universe_ids <- universe$gift_id
    # Built once. Which genome could hand which molecule to which other genome
    # does not depend on the sample either of them was seen in.
    catalogue_edges <- .handoff_edges(
      dataset$catalogue, graph, universe_ids, transferable
    )
    cycles <- gift_cycles(db = connection, limit = limit)

    parts <- lapply(dataset$sample_id, function(sample) {
      community <- .restrict_community(
        dataset$catalogue, dataset$genome_id[detected[, sample]]
      )
      .sample_topology(
        community, catalogue_edges, graph, cycles, universe_ids, transferable,
        universe$label, version, sample
      )
    })
    collect <- function(field) {
      rows <- do.call(rbind, lapply(parts, function(part) part[[field]]))
      if (is.null(rows)) tibble::tibble(sample_id = character()) else rows
    }

    structure(
      list(
        interaction = interaction,
        nodes = collect("nodes"),
        edges = collect("edges"),
        chain_coverage = collect("chain_coverage"),
        cycle_coverage = collect("cycle_coverage"),
        metrics = collect("metrics"),
        universe = universe,
        sample_id = dataset$sample_id,
        detection = detection,
        database_version = dataset$database_version
      ),
      class = c("gifter_dataset_network", "list")
    )
  })
}

#' @export
sample_id.gifter_dataset_network <- function(x, ...) x$sample_id

#' @export
print.gifter_dataset_network <- function(x, ...) {
  cat("<gifter_dataset_network>", x$interaction, "\n")
  cat("  samples:", length(x$sample_id), "\n")
  cat("  potential handoffs:", nrow(x$edges), "across every sample")
  if (nrow(x$edges)) {
    inexact <- sum(x$edges$edge_quality == "compartment_inexact")
    cat(
      " (", nrow(x$edges) - inexact, " exact, ", inexact,
      " compartment-inexact)", sep = ""
    )
  }
  cat("\n")
  density <- x$metrics[x$metrics$metric_id == "interaction_density", , drop = FALSE]
  # A sample of one detected genome has no ordered pair to be a density over,
  # so the range is over the samples that have one rather than over Inf.
  values <- density$value[!is.na(density$value)]
  if (length(values)) {
    cat(sprintf(
      "  interaction density: %.3f-%.3f across samples\n",
      min(values), max(values)
    ))
  }
  distributed <- sum(x$chain_coverage$status == "community_distributed")
  cat(
    "  composition links completed only across a sample's community: ",
    distributed, "\n", sep = ""
  )
  cat("  detection:", format(x$detection), "\n")
  cat("  database version:", .gifter_database_version_value(x$database_version), "\n")
  invisible(x)
}
