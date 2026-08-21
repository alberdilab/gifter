# Genome-resolved evaluation of an annotation table spanning several genomes.
#
# A collection of genomes is not the sum of its markers. Pooling them completes
# routes that no member encodes, which is exactly what the single-genome
# guardrail of evaluate_gifts() refuses; this is the supported way in. The
# table is split on its genome column, every genome is evaluated on its own
# markers against one database release, and the calls are bound into the
# community container. Nothing is ever pooled, and nothing here changes a call:
# a genome evaluated here and the same genome evaluated alone are identical.
#
# Genomes are independent of one another, so they are evaluated in parallel.
# Parallelism is a matter of wall time only: the split, the per-genome
# evaluation and the assembled community are the same however many workers run
# them, and the result is ordered by genome identifier rather than by which
# worker finished first.

# The genome column is never guessed. Column order is enough to propose a gene
# identifier for approval, because a wrong one mislabels evidence within a
# genome; a wrong genome column silently redraws the genomes themselves, and
# there is no call in the result that would look wrong afterwards.
.resolve_genome_id_column <- function(annotation_table, genome_id) {
  if (!is.data.frame(annotation_table)) {
    cli::cli_abort(c(
      "{.arg annotation_table} must be a data frame naming the genome of every marker.",
      "i" = "{.fn evaluate_gifts} evaluates a marker vector, which is one genome."
    ), call = NULL)
  }
  column <- if (is.null(genome_id)) "genome_id" else genome_id
  if (!is.character(column) || length(column) != 1L || is.na(column) || !nzchar(column)) {
    cli::cli_abort("{.arg genome_id} must be a single column name.", call = NULL)
  }
  if (!column %in% names(annotation_table)) {
    cli::cli_abort(c(
      "{.arg annotation_table} has no column named {.field {column}}.",
      "i" = "Its columns are {.field {names(annotation_table)}}.",
      "*" = "Name the genome column with {.arg genome_id}.",
      "*" = "For a single genome, use {.fn evaluate_gifts}."
    ), call = NULL)
  }
  if (!nrow(annotation_table)) {
    cli::cli_abort("{.arg annotation_table} holds no markers.", call = NULL)
  }
  values <- trimws(as.character(annotation_table[[column]]))
  unnamed <- is.na(values) | !nzchar(values)
  if (any(unnamed)) {
    cli::cli_abort(c(
      "{sum(unnamed)} marker{?s} in {.field {column}} name{?s/} no genome.",
      "i" = "A marker of unknown provenance belongs to no genome, and assigning
             it to one would credit that genome with evidence it does not carry."
    ), call = NULL)
  }
  values
}

# How many genomes may be evaluated at once. Forking is what makes a worker
# cheap here -- the database connection is not shared, but the loaded package
# and the split table are -- and it is unavailable on Windows, where the
# request is met sequentially rather than silently.
.resolve_workers <- function(workers, genomes, forkable) {
  requested <- !is.null(workers)
  if (!requested) {
    # mc.cores is the conventional place to cap parallelism for a whole
    # session, and is what a checked example or vignette sets.
    workers <- getOption("mc.cores")
    if (is.null(workers)) {
      cores <- parallel::detectCores(logical = FALSE)
      if (is.na(cores)) cores <- 1L
      workers <- max(1L, cores - 1L)
    }
  }
  if (!is.numeric(workers) || length(workers) != 1L || is.na(workers) || workers < 1) {
    cli::cli_abort("{.arg workers} must be a single number of at least 1.", call = NULL)
  }
  workers <- as.integer(min(workers, genomes))
  if (workers > 1L && !forkable) {
    if (requested) {
      cli::cli_warn(c(
        "{.arg workers} is {workers}, but this platform cannot fork.",
        "i" = "The genomes are evaluated one after another. The calls are the same."
      ))
    }
    workers <- 1L
  }
  workers
}

# The file a worker should open for itself. A forked child must never touch the
# parent's SQLite connection, so the path is resolved once in the parent and
# every worker connects on its own. A connection with no readable file behind it
# cannot be reopened, which is what makes the evaluation sequential.
.gifter_database_source <- function(db) {
  if (is.null(db)) {
    return(tryCatch(.gifter_database_path(), error = function(condition) NULL))
  }
  path <- tryCatch(DBI::dbGetInfo(db)$dbname, error = function(condition) NULL)
  if (is.character(path) && length(path) == 1L && nzchar(path) && file.exists(path)) {
    return(path)
  }
  NULL
}

# Evaluate a contiguous block of genomes on one connection. Opening the database
# once per worker rather than once per genome is why a large community does not
# spend its time connecting.
.evaluate_genome_block <- function(tables, namespace, path) {
  connection <- gifter_db_connect(path)
  on.exit(DBI::dbDisconnect(connection), add = TRUE)
  lapply(tables, function(table) {
    .evaluate_gifter_model(table, namespace, connection)
  })
}

.is_genome_block <- function(value, size) {
  !inherits(value, "try-error") && is.list(value) && length(value) == size &&
    all(vapply(value, inherits, logical(1), "gifter_genome"))
}

.genome_block_failure <- function(value) {
  condition <- attr(value, "condition")
  if (!is.null(condition)) return(conditionMessage(condition))
  if (inherits(value, "try-error")) return(trimws(as.character(value)))
  "The worker returned no result, which usually means the process was killed."
}

.evaluate_genomes <- function(tables, namespace, db, workers) {
  path <- .gifter_database_source(db)
  forkable <- !identical(.Platform$OS.type, "windows") && !is.null(path)
  workers <- .resolve_workers(workers, length(tables), forkable)

  if (workers <= 1L) {
    return(.with_gifter_db(db, function(connection) {
      lapply(tables, function(table) {
        .evaluate_gifter_model(table, namespace, connection)
      })
    }))
  }

  blocks <- split(
    seq_along(tables),
    cut(seq_along(tables), breaks = workers, labels = FALSE)
  )
  # One child per block, and exactly as many blocks as workers. Prescheduling
  # would group the blocks again and report a failure as one generic message
  # for all of them, losing the error the failing genome actually raised.
  evaluated <- withCallingHandlers(
    parallel::mclapply(blocks, function(index) {
      .evaluate_genome_block(tables[index], namespace, path)
    }, mc.cores = workers, mc.preschedule = FALSE),
    # A warning raised here is mclapply counting its failed children; a warning
    # raised inside a child never reaches this process at all. The failures are
    # reported below, with the error the genome actually raised.
    warning = function(condition) invokeRestart("muffleWarning")
  )

  # mclapply reports a failure as a value rather than by raising it, and a
  # worker that died reports nothing at all. Either way the community would be
  # short of a genome, so neither is allowed to pass as a result.
  failed <- !vapply(seq_along(evaluated), function(index) {
    .is_genome_block(evaluated[[index]], length(blocks[[index]]))
  }, logical(1))
  if (any(failed)) {
    reason <- .genome_block_failure(evaluated[[which(failed)[[1]]]])
    cli::cli_abort(c(
      "Evaluation failed in {sum(failed)} of {length(blocks)} worker{?s}.",
      "x" = "{reason}",
      "i" = "Set {.code workers = 1} to evaluate the genomes in this session,
             where the failing genome reports its own error."
    ), call = NULL)
  }
  # Every genome is returned to the position it was split from, so the community
  # is ordered by genome identifier rather than by which worker finished first.
  results <- vector("list", length(tables))
  for (block in seq_along(blocks)) results[blocks[[block]]] <- evaluated[[block]]
  names(results) <- names(tables)
  results
}

#' Evaluate a community of genomes from one annotation table
#'
#' Evaluates every genome of a multi-genome annotation table separately and
#' binds the calls into a [gifter_community()]. Each genome is evaluated by
#' [evaluate_gifts()] on its own markers, against one database release; genomes
#' are evaluated in parallel because they are independent of one another.
#'
#' @section Why a community is not one evaluation:
#'
#' Markers pooled across genomes complete routes that no member encodes, so the
#' pooled call is a statement about the collection and not about any genome in
#' it. That is what the single-genome guardrail of [evaluate_gifts()] refuses,
#' and this function is the way past it: the genome column is what separates
#' the markers, and the evaluation never sees two genomes at once. A genome
#' evaluated here is identical to the same genome evaluated alone.
#'
#' The genome column is required and is never inferred from column order. A
#' misread gene column mislabels evidence inside a genome, which is why one may
#' be proposed for approval; a misread genome column redraws the genomes
#' themselves, and no call in the result would look wrong afterwards.
#'
#' @section Parallel evaluation:
#'
#' Genomes are evaluated in forked worker processes, each holding its own
#' read-only database connection. Parallelism changes wall time only: the calls,
#' their order, and the assembled community are the same at any number of
#' workers. Forking is unavailable on Windows and for a connection with no file
#' behind it, where the genomes are evaluated one after another.
#'
#' @inheritParams evaluate_gifts
#' @param annotation_table A data frame of markers for several genomes, with
#'   `genome_id`, `namespace` and `accession` columns and, normally, `gene_id`.
#' @param genome_id Name of the column separating genomes. Defaults to
#'   `genome_id`. Every row must name a genome.
#' @param gene_id Which column names genes, resolved as in [evaluate_gifts()]
#'   over the table as a whole. The genome column is never proposed for it.
#' @param max_genes Number of distinct gene identifiers above which a single
#'   genome is questioned, applied to each genome separately. `Inf` evaluates
#'   every genome without asking.
#' @param workers Number of genomes to evaluate at once. Defaults to the
#'   `mc.cores` option, or to one fewer than the number of physical cores, and
#'   is capped at the number of genomes.
#' @param abundance,quality,policy,threshold Passed to [gifter_community()].
#' @return A `gifter_community` list. Its `results` member holds the
#'   `gifter_genome` result of every genome, under its genome identifier.
#' @seealso [evaluate_gifts()] for one genome, [community_traits()] for the
#'   quantitative traits of the returned community.
#' @examples
#' markers <- data.frame(
#'   genome_id = c("A", "A", "B"),
#'   gene_id = c("g1", "g2", "g1"),
#'   namespace = "KO",
#'   accession = c("K01198", "K01805", "K01805")
#' )
#' community <- evaluate_gifts_community(markers, workers = 1)
#' community$genome_id
#' @export
evaluate_gifts_community <- function(annotation_table, namespace = NULL, db = NULL,
                                     genome_id = NULL, gene_id = NULL,
                                     max_genes = 5000, workers = NULL,
                                     abundance = NULL, quality = NULL,
                                     policy = "none", threshold = NULL) {
  genomes <- .resolve_genome_id_column(annotation_table, genome_id)
  column <- if (is.null(genome_id)) "genome_id" else genome_id

  # The genome column is dropped before the gene column is resolved, so that it
  # is never the column proposed as a gene identifier.
  markers <- annotation_table
  markers[[column]] <- NULL
  markers <- .resolve_gene_id_column(markers, gene_id)

  identifiers <- sort(unique(genomes))
  tables <- lapply(identifiers, function(id) markers[genomes == id, , drop = FALSE])
  names(tables) <- identifiers

  # Every guardrail is answered in this session, before any worker starts: a
  # question asked in a forked child has nobody to answer it.
  for (id in identifiers) .check_single_genome(tables[[id]], max_genes, genome = id)

  results <- .evaluate_genomes(tables, namespace, db, workers)
  .gifter_community(
    results, abundance = abundance, quality = quality,
    policy = policy, threshold = threshold
  )
}
