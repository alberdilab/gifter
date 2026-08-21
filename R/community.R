# Genome-resolved community traits derived from GIFT calls.
#
# A community is a set of named genome results evaluated against one database
# release. Everything here reads those calls; nothing re-evaluates and nothing
# changes a call.
#
# Presence and abundance are kept apart throughout. How many genomes encode a
# capability and how much of the community's abundance those genomes represent
# are different quantities that answer different questions, and a single number
# combining them would answer neither. Neither is a statement about activity.

.community_matrix <- function(results, universe_ids, policy, completeness, threshold) {
  genomes <- names(results)
  matrix <- vapply(genomes, function(genome) {
    result <- results[[genome]]
    calls <- stats::setNames(as.logical(result$gifts$complete), result$gifts$gift_id)
    # A GIFT the evaluation never produced is not supported. Treating it as
    # supported would let a filtered evaluation claim a capability it never
    # tested.
    present <- calls[universe_ids]
    state <- !is.na(present) & present
    # Indeterminacy is per genome: a fragmented member's silence is uninformative
    # while a complete member's is not, and a provider count must not mix them.
    .assessability_state(
      state, policy,
      if (is.null(completeness)) NA_real_ else completeness[[genome]],
      threshold
    )
  }, logical(length(universe_ids)))
  if (is.null(dim(matrix))) {
    matrix <- matrix(matrix, nrow = length(universe_ids), ncol = length(genomes))
  }
  dimnames(matrix) <- list(universe_ids, genomes)
  matrix
}

#' Bind genome results into a genome-resolved community
#'
#' Collects the calls of several genomes so that community-level quantitative
#' traits can be computed over them. Nothing is re-evaluated: this is the
#' container the community layer reads.
#'
#' @section Abundance:
#'
#' `abundance` is optional and, when supplied, is normalised to sum to one while
#' the values as supplied are retained. It weights how much of the observed
#' community a capability's carriers represent. It is not a weight on the
#' capability: a GIFT encoded by an abundant genome is not thereby more active,
#' more expressed or more important, and [community_traits()] keeps
#' presence-based and abundance-weighted quantities in separate rows for that
#' reason.
#'
#' @param ... Named `gifter_genome` results from [evaluate_gifts()], one per
#'   genome. The argument names become the genome identifiers. A whole
#'   annotation table carrying a `genome_id` column is bound in one call by
#'   [evaluate_gifts_community()] instead.
#' @param abundance Optional named numeric vector of relative abundances over
#'   the same genomes. Must be non-negative and not all zero.
#' @param quality Optional genome completeness, as a named numeric vector or a
#'   data frame with `genome_id` and `completeness` columns, on a 0-1 scale.
#' @param policy Assessability policy: `"none"` or `"completeness"`. See
#'   [genome_traits()]. Indeterminacy is resolved per genome, so a fragmented
#'   member's silence is withheld from a provider count while a complete
#'   member's is not.
#' @param threshold Completeness below which a negative call is treated as
#'   indeterminate. Required by the `"completeness"` policy.
#' @return A `gifter_community` list holding the genome identifiers, the call
#'   matrix, the abundance vector if supplied, and the `database_version`.
#' @examples
#' donor <- evaluate_gifts(data.frame(
#'   gene_id = "g1", namespace = "KO", accession = "K01198"
#' ))
#' recipient <- evaluate_gifts(data.frame(
#'   gene_id = "g1", namespace = "KO", accession = "K01805"
#' ))
#' community <- gifter_community(donor = donor, recipient = recipient)
#' community$genome_id
#' @export
gifter_community <- function(..., abundance = NULL, quality = NULL,
                            policy = "none", threshold = NULL) {
  .gifter_community(
    list(...), abundance = abundance, quality = quality,
    policy = policy, threshold = threshold
  )
}

# The community constructor, over an already-collected list of genome results.
# `gifter_community()` collects them from named arguments and
# `evaluate_gifts_community()` from the genomes of one annotation table; a
# genome named `policy` or `abundance` must not change which is which, so the
# list is passed as a list rather than spliced back through `...`.
.gifter_community <- function(results, abundance = NULL, quality = NULL,
                              policy = "none", threshold = NULL) {
  if (!length(results)) {
    stop("Supply at least one evaluated genome", call. = FALSE)
  }
  if (!all(vapply(results, inherits, logical(1), "gifter_genome"))) {
    stop("Every genome must be a result from evaluate_gifts()", call. = FALSE)
  }
  genomes <- names(results)
  if (is.null(genomes) || any(!nzchar(genomes)) || anyDuplicated(genomes)) {
    stop(
      "Every genome must be supplied under a distinct name, which becomes its identifier",
      call. = FALSE
    )
  }

  versions <- vapply(results, function(result) {
    .gifter_database_version_value(result$database_version)
  }, character(1))
  if (length(unique(versions)) > 1L) {
    # Calls made against different releases were made against different
    # universes. A provider count mixing them would count capabilities that
    # were not offered to every genome.
    stop(
      "Genomes were evaluated against different database versions: ",
      paste(sort(unique(versions)), collapse = ", "),
      call. = FALSE
    )
  }

  if (!is.null(abundance)) {
    if (!is.numeric(abundance) || is.null(names(abundance))) {
      stop("abundance must be a named numeric vector", call. = FALSE)
    }
    if (!setequal(names(abundance), genomes)) {
      stop(
        "abundance must name exactly the supplied genomes; missing: ",
        paste(setdiff(genomes, names(abundance)), collapse = ", "),
        call. = FALSE
      )
    }
    abundance <- abundance[genomes]
    if (any(is.na(abundance)) || any(abundance < 0)) {
      stop("abundance must be non-negative and complete", call. = FALSE)
    }
    if (sum(abundance) <= 0) {
      stop("abundance must not be all zero", call. = FALSE)
    }
  }

  policy <- .resolve_policy(policy, quality, threshold)
  completeness <- .normalize_quality(quality, genomes)

  universe_ids <- sort(unique(unlist(lapply(results, function(result) {
    result$gifts$gift_id
  }), use.names = FALSE)))

  structure(
    list(
      genome_id = genomes,
      gift_id = universe_ids,
      matrix = .community_matrix(results, universe_ids, policy, completeness, threshold),
      assessability = list(
        policy = policy, threshold = threshold, completeness = completeness
      ),
      abundance = if (is.null(abundance)) NULL else abundance / sum(abundance),
      abundance_supplied = abundance,
      results = results,
      database_version = results[[1L]]$database_version
    ),
    class = c("gifter_community", "list")
  )
}

#' @export
print.gifter_community <- function(x, ...) {
  cat("<gifter_community>", length(x$genome_id), "genomes\n")
  cat("  genomes:", paste(x$genome_id, collapse = ", "), "\n")
  cat("  GIFTs evaluated:", length(x$gift_id), "\n")
  cat("  abundance:", if (is.null(x$abundance)) "not supplied" else "supplied", "\n")
  cat("  database version:", .gifter_database_version_value(x$database_version), "\n")
  invisible(x)
}

.community_universe_metrics <- function(community, universe, version) {
  label <- universe$label
  members <- intersect(community$gift_id, universe$gift_id)
  matrix <- community$matrix[members, , drop = FALSE]
  genomes <- community$genome_id
  supports <- matrix %in% TRUE
  dim(supports) <- dim(matrix)
  dimnames(supports) <- dimnames(matrix)
  # A GIFT nobody could assess is not part of the denominator, and the genomes
  # that could not assess one are not part of its provider denominator either.
  assessed_by <- if (length(members)) rowSums(!is.na(matrix)) else integer()
  assessable <- sum(assessed_by > 0L)
  provider_count <- if (length(members)) rowSums(supports) else integer()
  represented <- members[provider_count > 0L]

  metrics <- list(
    .metric_row(
      "community", "community", "community_richness", length(represented),
      "count", length(represented), NA_integer_, assessable, label, version,
      "GIFTs supported by at least one genome"
    ),
    .metric_row(
      "community", "community", "mean_genome_richness",
      if (length(genomes)) mean(colSums(supports)) else 0, "count",
      sum(supports), length(genomes), assessable, label, version,
      "supported GIFTs summed over genomes, divided by the number of genomes"
    )
  )
  trace <- list(.trace_rows(
    "community", "community", "community_richness", label, represented
  ))

  if (isTRUE(universe$bounded) && assessable > 0L) {
    metrics <- c(metrics, list(.metric_row(
      "community", "community", "community_coverage",
      length(represented) / assessable, "proportion", length(represented),
      assessable, assessable, label, version,
      "GIFTs supported by at least one genome, over assessable GIFTs in a bounded universe"
    )))
  }

  singletons <- members[provider_count == 1L]
  if (length(members)) {
    metrics <- c(metrics, list(.metric_row(
      "community", "community", "assessable_fraction",
      assessable / length(members), "proportion", assessable, length(members),
      assessable, label, version,
      "members of the reference universe at least one genome could assess"
    )))
  }
  if (length(represented)) {
    metrics <- c(metrics, list(.metric_row(
      "community", "community", "singleton_fraction",
      length(singletons) / length(represented), "proportion",
      length(singletons), length(represented), assessable, label, version,
      "represented GIFTs with exactly one provider, over represented GIFTs"
    )))
    trace <- c(trace, list(.trace_rows(
      "community", "community", "singleton_fraction", label, singletons
    )))
  }

  # Per-GIFT distribution. provider_count is a presence quantity and
  # abundance_coverage is an abundance quantity; they are separate rows because
  # they answer separate questions and are not interchangeable.
  for (gift in represented) {
    providers <- genomes[supports[gift, ]]
    assessors <- as.integer(assessed_by[[gift]])
    metrics <- c(metrics, list(
      .metric_row(
        "gift", gift, "provider_count", length(providers), "count",
        length(providers), assessors, assessable, label, version,
        "genomes supporting this GIFT, over genomes that could assess it"
      ),
      .metric_row(
        "gift", gift, "provider_fraction", length(providers) / assessors,
        "proportion", length(providers), assessors, assessable, label, version,
        "genomes supporting this GIFT, over genomes that could assess it"
      )
    ))
    trace <- c(trace, list(tibble::tibble(
      target_type = "gift", target_id = gift, metric_id = "provider_count",
      reference_universe = label, gift_id = gift, contribution = providers
    )))
    if (!is.null(community$abundance)) {
      coverage <- sum(community$abundance[providers])
      metrics <- c(metrics, list(.metric_row(
        "gift", gift, "abundance_coverage", coverage, "proportion",
        length(providers), length(genomes), assessable, label, version,
        "share of supplied community abundance carried by genomes supporting this GIFT"
      )))
    }
  }

  # Per-genome contribution.
  for (genome in genomes) {
    supported <- members[supports[, genome]]
    unique_to <- supported[provider_count[supported] == 1L]
    metrics <- c(metrics, list(
      .metric_row(
        "genome", genome, "gift_richness", length(supported), "count",
        length(supported), NA_integer_, assessable, label, version,
        "supported GIFTs in the reference universe"
      ),
      .metric_row(
        "genome", genome, "unique_contribution", length(unique_to), "count",
        length(unique_to), length(supported), assessable, label, version,
        "GIFTs for which this genome is the community's only provider"
      )
    ))
    trace <- c(trace, list(.trace_rows(
      "genome", genome, "unique_contribution", label, unique_to
    )))
  }

  # Pairwise repertoire overlap. Stratification is the default rather than an
  # option: 94% of the catalogue is metabolic, so an unstratified overlap is a
  # metabolic overlap wearing a general name.
  if (length(genomes) > 1L) {
    pairs <- utils::combn(genomes, 2L, simplify = FALSE)
    for (pair in pairs) {
      left <- members[supports[, pair[[1L]]]]
      right <- members[supports[, pair[[2L]]]]
      union_size <- length(union(left, right))
      shared <- intersect(left, right)
      value <- if (union_size == 0L) NA_real_ else length(shared) / union_size
      if (is.na(value)) next
      metrics <- c(metrics, list(.metric_row(
        "genome_pair", paste(pair, collapse = " | "), "repertoire_overlap",
        value, "proportion", length(shared), union_size, assessable, label,
        version,
        "Jaccard index of the two genomes' supported GIFTs, within this universe"
      )))
      trace <- c(trace, list(.trace_rows(
        "genome_pair", paste(pair, collapse = " | "), "repertoire_overlap",
        label, shared
      )))
    }
  }

  list(
    metrics = do.call(rbind, metrics),
    trace = do.call(rbind, trace)
  )
}

#' Quantitative traits of a genome-resolved community
#'
#' Summarises how curated capabilities are distributed across the genomes of a
#' community, within declared reference universes. Nothing here is curated and
#' nothing changes a call.
#'
#' Metrics reported per universe:
#'
#' \describe{
#'   \item{`community_richness`}{GIFTs supported by at least one genome}
#'   \item{`community_coverage`}{richness over assessable members, for bounded
#'     universes only}
#'   \item{`mean_genome_richness`}{reported beside community richness rather
#'     than divided into it, so both components stay visible}
#'   \item{`provider_count`, `provider_fraction`}{per GIFT, the genomes
#'     supporting it, and that count over the genomes that could assess it}
#'   \item{`abundance_coverage`}{per GIFT, the share of supplied abundance those
#'     genomes carry. Only when `abundance` was supplied}
#'   \item{`singleton_fraction`}{represented GIFTs with exactly one provider}
#'   \item{`unique_contribution`}{per genome, the GIFTs it alone provides}
#'   \item{`repertoire_overlap`}{per genome pair, the Jaccard index of their
#'     supported GIFTs}
#' }
#'
#' @section Interpretation:
#'
#' These traits describe how genomic capability is distributed among the
#' genomes supplied. They are not measures of ecological interaction, division
#' of labour, cooperation or stability. Two genomes with disjoint repertoires
#' have different repertoires; they have not been shown to be complementary.
#' `unique_contribution` counts GIFTs no other sampled genome provides; it does
#' not make a genome ecologically indispensable, and it moves when the sampling
#' does.
#'
#' `abundance_coverage` is the fraction of observed genome abundance carrying a
#' capability. It is not a fraction of activity, flux, transcript production or
#' ecological effect, which is why it never merges with `provider_count`.
#'
#' @param community A community from [gifter_community()].
#' @param universes Optional list of [gift_universe()] objects. The default set
#'   is used if omitted.
#' @param db Optional open gifter database connection.
#' @return A `gifter_traits` list with `metrics` and `trace`, whose
#'   `target_type` distinguishes community, GIFT, genome and genome-pair rows.
#' @export
community_traits <- function(community, universes = NULL, db = NULL) {
  if (!inherits(community, "gifter_community")) {
    stop("community must come from gifter_community()", call. = FALSE)
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
    if (is.null(universes)) universes <- .default_universes(connection)
    if (!is.list(universes) || !length(universes) ||
        !all(vapply(
          universes, inherits, logical(1), "gifter_universe"
        ))) {
      stop("universes must be a non-empty list of gift_universe() objects", call. = FALSE)
    }
    stale <- vapply(universes, function(u) !identical(u$database_version, version), logical(1))
    if (any(stale)) {
      stop("Universes were built against a different database version", call. = FALSE)
    }

    parts <- lapply(universes, function(universe) {
      .community_universe_metrics(community, universe, version)
    })
    metrics <- do.call(rbind, lapply(parts, function(part) part$metrics))
    trace <- do.call(rbind, lapply(parts, function(part) part$trace))
    if (is.null(metrics)) metrics <- .empty_metrics()
    if (is.null(trace)) trace <- .empty_trace()
    .warn_thin_denominators(metrics)

    structure(
      list(
        metrics = metrics[.metric_columns],
        trace = trace[.trace_columns],
        universes = universes,
        genome_id = community$genome_id,
        assessability = community$assessability,
        database_version = community$database_version
      ),
      class = c("gifter_traits", "list")
    )
  })
}
