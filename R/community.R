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
#
# The container holds calls and nothing else. Abundance and genome completeness
# are not properties of a call: they are how much of the sampled community a
# reader chooses to weigh a carrier by, and how far a reader is willing to read
# an absence. Both belong to community_traits(), where genome_traits() already
# takes them for one genome. Binding a community is therefore cheap and carries
# no interpretation the caller did not ask for, and the same calls can be read
# under two completeness thresholds without being evaluated twice.
#
# Reading is cheap per genome and quadratic per community: every universe is
# walked over every GIFT, every genome and every pair of genomes. The pair
# count is the only term that grows that way -- four hundred genomes are
# eighty-seven thousand pairs, two thousand are two million -- so pairs are
# answered in one cross-product rather than one at a time, the pair trace is
# built only when asked for, and `pairwise = FALSE` drops the pair metric
# without touching anything else. Everything per GIFT and per genome stays
# cheap enough to report within every default universe. community_traits()
# reports its progress on the same terms as evaluate_gifts_community(),
# through the display in R/progress.R, counting the unit the caller asked for
# -- reference universes -- and never the GIFTs or genome pairs each of them
# happens to contain.

# The calls as they were made, one column per genome, over every GIFT any
# genome was evaluated for. Nothing here reads an absence: what a negative call
# may be taken to mean is a question for the reader, and .assessable_matrix()
# answers it at that point.
.community_matrix <- function(results, universe_ids) {
  genomes <- names(results)
  matrix <- vapply(genomes, function(genome) {
    result <- results[[genome]]
    calls <- stats::setNames(as.logical(result$gifts$complete), result$gifts$gift_id)
    # A GIFT the evaluation never produced is not supported. Treating it as
    # supported would let a filtered evaluation claim a capability it never
    # tested.
    present <- calls[universe_ids]
    !is.na(present) & present
  }, logical(length(universe_ids)))
  if (is.null(dim(matrix))) {
    matrix <- matrix(matrix, nrow = length(universe_ids), ncol = length(genomes))
  }
  dimnames(matrix) <- list(universe_ids, genomes)
  matrix
}

# The confidence behind each call, shaped like the call matrix so the two can be
# read together. A GIFT the evaluation never produced has no confidence to
# report, which is distinct from one called on weak evidence.
.community_confidence <- function(results, universe_ids) {
  genomes <- names(results)
  matrix <- vapply(genomes, function(genome) {
    result <- results[[genome]]
    confidence <- stats::setNames(
      as.character(result$gifts$evidence_confidence), result$gifts$gift_id
    )
    unname(confidence[universe_ids])
  }, character(length(universe_ids)))
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
#' @section What a community does not hold:
#'
#' Genome abundances and completeness estimates are not part of a community.
#' They say how a reader wishes to weigh a carrier and how far a reader is
#' willing to read an absence, neither of which is a property of a call, and
#' both are supplied to [community_traits()] when the calls are read -- as
#' [genome_traits()] already takes them for a single genome. Binding a
#' community therefore commits to nothing, and the same community can be read
#' under two completeness thresholds without being evaluated twice.
#'
#' @param ... Named `gifter_genome` results from [evaluate_gifts()], one per
#'   genome. The argument names become the genome identifiers. A whole
#'   annotation table carrying a `genome_id` column is bound in one call by
#'   [evaluate_gifts_community()] instead.
#' @return A `gifter_community` list holding the genome identifiers, the call
#'   matrix and the `database_version`.
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
gifter_community <- function(...) {
  results <- list(...)
  # These were arguments here until 0.4.0. Left to `...` they would be read as
  # genomes and refused for not being calls, which says nothing about where
  # they went, so they are named and answered. A genome legitimately called
  # `abundance` is a call, and is let through.
  moved <- intersect(names(results), c("abundance", "quality", "policy", "threshold"))
  moved <- moved[!vapply(results[moved], inherits, logical(1), "gifter_genome")]
  if (length(moved)) {
    stop(
      "`", moved[[1L]], "` is not supplied here. Genome abundance and ",
      "completeness say how calls are to be read, not what they are: pass ",
      "them to community_traits(), which can then read one community under ",
      "more than one threshold",
      call. = FALSE
    )
  }
  .gifter_community(results)
}

# The abundance vector, checked against the genomes it weights and returned in
# their order, as supplied. Normalisation is left to the caller, because a
# reader may want the values as they were given.
.normalize_abundance <- function(abundance, genomes) {
  if (is.null(abundance)) return(NULL)
  if (!is.numeric(abundance) || is.null(names(abundance))) {
    # The commonest way to arrive here is an abundance column pulled out of a
    # count table, which loses the genome identifiers on the way. Position is
    # not a substitute: the genomes it would be aligned against come from the
    # community, and a silent off-by-one credits one genome's abundance to
    # another.
    stop(
      "abundance must be a named numeric vector over the genomes it weights. ",
      "Name it with the genome identifiers, as setNames(abundance, genome_id)",
      call. = FALSE
    )
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
  abundance
}

# The same matrix read under an assessability policy. Indeterminacy is per
# genome: a fragmented member's silence is uninformative while a complete
# member's is not, and a provider count must not mix them. A positive call is
# never touched, so no policy can promote or demote a capability -- only the
# denominators move.
.assessable_matrix <- function(matrix, policy, completeness, threshold) {
  if (identical(policy, "none")) return(matrix)
  read <- vapply(colnames(matrix), function(genome) {
    .assessability_state(
      matrix[, genome], policy,
      if (is.null(completeness)) NA_real_ else completeness[[genome]],
      threshold
    )
  }, logical(nrow(matrix)))
  if (is.null(dim(read))) {
    read <- matrix(read, nrow = nrow(matrix), ncol = ncol(matrix))
  }
  dimnames(read) <- dimnames(matrix)
  read
}

# The community constructor, over an already-collected list of genome results.
# `gifter_community()` collects them from named arguments and
# `evaluate_gifts_community()` from the genomes of one annotation table; the
# list is passed as a list rather than spliced back through `...` so that a
# genome's name can never be read as an argument name.
.gifter_community <- function(results) {
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

  universe_ids <- sort(unique(unlist(lapply(results, function(result) {
    result$gifts$gift_id
  }), use.names = FALSE)))

  structure(
    list(
      genome_id = genomes,
      gift_id = universe_ids,
      matrix = .community_matrix(results, universe_ids),
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
  cat("  database version:", .gifter_database_version_value(x$database_version), "\n")
  invisible(x)
}

# Which GIFTs each pair of genomes shares, in long form. The rows are the same
# rows a per-pair intersect() would produce, built per GIFT because the GIFTs of
# a universe are hundreds while the pairs of a community are hundreds of
# thousands: every pair that shares a GIFT is exactly every pair of its
# providers. They arrive grouped by GIFT rather than by pair, which is a
# different order of the same evidence.
#
# This block is what makes a pair trace expensive to hold rather than to
# compute. It carries one row per pair per shared GIFT -- tens of millions of
# rows and gigabytes for a few hundred genomes -- which is why
# community_traits() only builds it when asked.
.pair_overlap_trace <- function(genomes, members, supports, label) {
  blocks <- lapply(members, function(gift) {
    providers <- genomes[supports[gift, ]]
    total <- length(providers)
    if (total < 2L) return(NULL)
    first <- rep.int(seq_len(total - 1L), (total - 1L):1L)
    second <- sequence((total - 1L):1L, from = 2L:total)
    tibble::tibble(
      target_type = "genome_pair",
      target_id = paste(providers[first], providers[second], sep = " | "),
      metric_id = "repertoire_overlap",
      reference_universe = label,
      gift_id = gift,
      contribution = NA_character_
    )
  })
  do.call(rbind, blocks)
}

.community_universe_metrics <- function(community, universe, version, calls,
                                       abundance, pairwise = TRUE,
                                       pair_trace = FALSE) {
  label <- universe$label
  members <- intersect(community$gift_id, universe$gift_id)
  matrix <- calls[members, , drop = FALSE]
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
    if (!is.null(abundance)) {
      coverage <- sum(abundance[providers])
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

  # Pairwise repertoire overlap, always within the universe being read and
  # never across universes in one number: 94% of the catalogue is metabolic, so
  # an overlap taken over the whole catalogue is a metabolic overlap wearing a
  # general name.
  #
  # The pair count is quadratic in the community -- four hundred genomes are
  # eighty-seven thousand pairs and a thousand are half a million -- so every
  # pair is answered at once rather than one at a time. One cross-product of
  # the call matrix holds every shared count there is, the union sizes follow
  # from the row sums, and the rows are assembled as columns. A per-pair
  # intersect() and a per-pair one-row tibble spend the walk in allocation:
  # the arithmetic here was never the cost.
  if (pairwise && length(genomes) > 1L && length(members)) {
    counts <- supports
    storage.mode(counts) <- "double"
    shared_counts <- crossprod(counts)
    sizes <- colSums(supports)
    total <- length(genomes)
    first <- rep.int(seq_len(total - 1L), (total - 1L):1L)
    second <- sequence((total - 1L):1L, from = 2L:total)
    shared_size <- shared_counts[cbind(first, second)]
    union_size <- sizes[first] + sizes[second] - shared_size
    # Two genomes holding nothing in this universe have an undefined overlap
    # rather than an overlap of zero. Reporting zero would say they were
    # compared and found to share nothing.
    comparable <- union_size > 0
    first <- first[comparable]
    second <- second[comparable]
    shared_size <- shared_size[comparable]
    union_size <- union_size[comparable]
    if (length(first)) {
      metrics <- c(metrics, list(.metric_row(
        "genome_pair", paste(genomes[first], genomes[second], sep = " | "),
        "repertoire_overlap", shared_size / union_size, "proportion",
        shared_size, union_size, assessable, label, version,
        "Jaccard index of the two genomes' supported GIFTs, within this universe"
      )))
      if (pair_trace) {
        trace <- c(trace, list(.pair_overlap_trace(
          genomes, members, supports, label
        )))
      }
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
#' @section Abundance:
#'
#' `abundance` is optional and, when supplied, is normalised to sum to one. It
#' weights how much of the observed community a capability's carriers
#' represent. It is not a weight on the capability: a GIFT encoded by an
#' abundant genome is not thereby more active, more expressed or more
#' important, which is why presence-based and abundance-weighted quantities are
#' reported in separate rows and never combined.
#'
#' @section Assessability:
#'
#' `quality`, `policy` and `threshold` decide which negative calls may enter a
#' denominator, on the same terms as [genome_traits()], and are supplied here
#' rather than to [gifter_community()] because they are a way of reading calls
#' and not a property of them. Indeterminacy is resolved per genome: a
#' fragmented member's silence is withheld from a provider count while a
#' complete member's is not. No policy can make an unsupported GIFT supported.
#'
#' @section Cost:
#'
#' Everything reported per GIFT and per genome is cheap: reading four hundred
#' genomes within all fourteen default universes is thirteen thousand rows and
#' a few seconds. The pair metric is the expensive one, because the pair count
#' is quadratic in the community -- four hundred genomes are eighty-seven
#' thousand pairs, two thousand are two million -- and every universe pays it
#' again. Measured on four hundred and eighteen genomes over the default
#' universes: 13 s and 100 MB, of which 99% of the rows are pairs. At two
#' thousand genomes the same reading is 93 s and 2.2 GB.
#'
#' The two are separate arguments because they are separate costs.
#' `pairwise = FALSE` drops `repertoire_overlap` and keeps every richness,
#' provider and unique-contribution row, which is what makes a community of
#' thousands of genomes readable within every universe. `pair_trace = TRUE`
#' adds the GIFTs behind each overlap, one row per pair per shared GIFT: tens
#' of millions of rows and gigabytes at a few hundred genomes, which is why it
#' is off unless it is asked for. The overlap values themselves are the same
#' with it or without it.
#'
#' @section Progress:
#'
#' A run over several universes reports itself at an interactive console, in
#' reference universes summarised out of universes to summarise, with an
#' estimate of the time remaining. A universe is not a fixed quantity of work
#' -- one spanning the whole catalogue takes longer than a narrow one -- so the
#' estimate is coarser than the genome count of [evaluate_gifts_community()].
#' Nothing is reported when there is nobody watching, which is why a script, a
#' knitted document and a package check stay silent unless they ask for the
#' display with `progress = TRUE`.
#'
#' @param community A community from [gifter_community()].
#' @param universes Optional list of [gift_universe()] objects. The default set
#'   is used if omitted: the whole catalogue, each `gift_type`, each `mode`,
#'   each resource strategy, and the bounded biomass-essential anabolic set
#'   that `community_coverage` is reported for.
#' @param abundance Optional named numeric vector of relative abundances over
#'   the community's genomes, named with their identifiers. Must be
#'   non-negative and not all zero.
#' @param quality Optional genome completeness, as a named numeric vector or a
#'   data frame with `genome_id` and `completeness` columns. Read as
#'   proportions, or as percentages when any value exceeds 1.
#' @param policy Assessability policy: `"none"` or `"completeness"`. See
#'   [genome_traits()].
#' @param threshold Completeness below which a negative call is treated as
#'   indeterminate, on the same scale as `quality`. Required by the
#'   `"completeness"` policy and has no default.
#' @param min_confidence Optional weakest marker confidence a positive call may
#'   rest on and still count, as in [genome_traits()]. Applied per genome, so a
#'   capability stays in the community count while any one genome evidences it
#'   above the floor. `NULL`, the default, counts every positive call.
#' @param pairwise Whether to report `repertoire_overlap`. `TRUE`, the default.
#'   It is the one metric that is quadratic in the community, and the only one
#'   a community of thousands of genomes cannot afford in every universe:
#'   `FALSE` drops it and leaves every other metric untouched.
#' @param pair_trace Whether to record, for every genome pair, the GIFTs behind
#'   its `repertoire_overlap`. `FALSE`, the default: the trace carries one row
#'   per pair per shared GIFT, which is quadratic in the community and reaches
#'   gigabytes at a few hundred genomes, and the overlap values are unchanged
#'   either way. The community, GIFT and genome traces are always recorded.
#' @param db Optional open gifter database connection.
#' @param progress Whether to display a progress bar over the reference
#'   universes. Defaults to `TRUE` at an interactive console reading more than
#'   one universe, and to `FALSE` otherwise. The display never changes a
#'   metric.
#' @return A `gifter_traits` list with `metrics` and `trace`, whose
#'   `target_type` distinguishes community, GIFT, genome and genome-pair rows.
#' @export
community_traits <- function(community, universes = NULL, abundance = NULL,
                             quality = NULL, policy = "none", threshold = NULL,
                             min_confidence = NULL, pairwise = TRUE,
                             pair_trace = FALSE, db = NULL, progress = NULL) {
  if (!inherits(community, "gifter_community")) {
    stop("community must come from gifter_community()", call. = FALSE)
  }
  # A malformed `progress` request is exactly as wrong now as it will be after
  # the universes have been built, and answering it here costs a message rather
  # than the walk. What it resolves to waits for the universes themselves,
  # since they are the unit it counts.
  .check_progress(progress)
  if (!isTRUE(pairwise) && !isFALSE(pairwise)) {
    stop("pairwise must be TRUE or FALSE", call. = FALSE)
  }
  if (!isTRUE(pair_trace) && !isFALSE(pair_trace)) {
    stop("pair_trace must be TRUE or FALSE", call. = FALSE)
  }
  if (pair_trace && !pairwise) {
    stop(
      "pair_trace = TRUE asks for the GIFTs behind an overlap that ",
      "pairwise = FALSE does not compute",
      call. = FALSE
    )
  }
  min_confidence <- .normalize_min_confidence(min_confidence)
  # How the calls are to be read, settled against the genomes the community
  # names before any universe is walked.
  abundance <- .normalize_abundance(abundance, community$genome_id)
  threshold <- .normalize_threshold(threshold)
  policy <- .resolve_policy(policy, quality, threshold)
  completeness <- .normalize_quality(quality, community$genome_id)
  calls <- .assessable_matrix(community$matrix, policy, completeness, threshold)
  if (!is.null(min_confidence)) {
    confidence <- .community_confidence(community$results, community$gift_id)
    calls <- .confidence_state(calls, confidence[rownames(calls), colnames(calls)],
                               min_confidence)
  }
  weights <- if (is.null(abundance)) NULL else abundance / sum(abundance)
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

    # Every universe is walked over every GIFT, every genome and every pair of
    # genomes, so a community of thousands of genomes spends minutes to hours
    # here and has to be able to say how far along it is.
    display <- .universe_progress(
      length(universes), .resolve_progress(progress, length(universes))
    )
    # A walk that aborts must not leave a bar behind reporting a run that
    # finished, so the bar is taken down either way and completed only on the
    # one path that produced the traits.
    on.exit(display$dismiss(), add = TRUE)
    parts <- vector("list", length(universes))
    for (index in seq_along(universes)) {
      parts[[index]] <- .community_universe_metrics(
        community, universes[[index]], version, calls, weights, pairwise,
        pair_trace
      )
      display$update(index)
    }
    display$done()
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
        assessability = list(
          policy = policy, threshold = threshold, completeness = completeness
        ),
        abundance = weights,
        abundance_supplied = abundance,
        database_version = community$database_version
      ),
      class = c("gifter_traits", "list")
    )
  })
}
