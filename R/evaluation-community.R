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
#
# Wall time is the whole reason this file exists, and a run measured in minutes
# or hours has to be able to say how far along it is. Progress is reported in
# genomes evaluated -- the unit the caller asked for -- never in workers
# started or blocks finished, which are an implementation detail of how the
# same work was spread out.
#
# It is also why the arguments that shape the run are checked before the first
# genome is evaluated rather than where they are finally used. A `workers`
# request that makes no sense is exactly as wrong now as it will be after an
# hour of evaluation, and the guardrail of a large genome may stop to ask a
# question before it is ever reached.

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

# The shape of a `workers` request, which is answerable before any genome is
# evaluated. What it resolves to is not: that depends on how many genomes there
# are and on whether this platform can fork, neither of which changes whether
# the request itself makes sense.
.check_workers <- function(workers) {
  if (is.null(workers)) return(invisible(NULL))
  if (!is.numeric(workers) || length(workers) != 1L || is.na(workers) || workers < 1) {
    cli::cli_abort("{.arg workers} must be a single number of at least 1.", call = NULL)
  }
  invisible(NULL)
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
  # A default taken from mc.cores is as capable of being nonsense as a request.
  .check_workers(workers)
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

# The progress display of this run, and the rule for whether there is one, are
# in R/progress.R, where community_traits() reports through the same object.

# How a forked child tells the parent that it has finished a genome. The child
# has no console of its own and the parent is occupied waiting for results, so
# the count travels through a file: one byte appended per genome, an append the
# operating system serialises between processes, whose size is therefore the
# number of genomes evaluated so far. Nothing but the count crosses back; the
# results still travel the way they always did.
.new_genome_ticker <- function(enabled) {
  if (!enabled) return(NULL)
  path <- tempfile("gifter-progress-")
  if (!file.create(path, showWarnings = FALSE)) return(NULL)
  path
}

# A tick is progress reporting and nothing more, so a filesystem that refuses
# the write costs the caller a moving bar, never a genome.
.tick_genome <- function(ticker) {
  if (is.null(ticker)) return(invisible(NULL))
  try(cat(".", file = ticker, append = TRUE), silent = TRUE)
  invisible(NULL)
}

.ticked_genomes <- function(ticker) {
  if (is.null(ticker)) return(0L)
  size <- file.size(ticker)
  if (is.na(size)) 0L else as.integer(size)
}

# Evaluate a contiguous block of genomes on one connection. Opening the database
# once per worker rather than once per genome is why a large community does not
# spend its time connecting. A genome is ticked once its result exists, so the
# count the caller reads is genomes evaluated and not genomes started.
.evaluate_genome_block <- function(tables, namespace, path, ticker = NULL) {
  connection <- gifter_db_connect(path)
  on.exit(DBI::dbDisconnect(connection), add = TRUE)
  lapply(tables, function(table) {
    result <- .evaluate_gifter_model(table, namespace, connection)
    .tick_genome(ticker)
    result
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

.evaluate_genomes <- function(tables, namespace, db, workers, progress) {
  path <- .gifter_database_source(db)
  forkable <- !identical(.Platform$OS.type, "windows") && !is.null(path)
  workers <- .resolve_workers(workers, length(tables), forkable)
  display <- .genome_progress(length(tables), progress)
  # An evaluation that aborts must not leave a bar behind reporting a run that
  # finished, so the bar is taken down either way and completed only on the one
  # path that produced a result.
  on.exit(display$dismiss(), add = TRUE)

  results <- if (workers <= 1L) {
    .with_gifter_db(db, function(connection) {
      evaluated <- vector("list", length(tables))
      names(evaluated) <- names(tables)
      for (index in seq_along(tables)) {
        evaluated[[index]] <- .evaluate_gifter_model(
          tables[[index]], namespace, connection
        )
        display$update(index)
      }
      evaluated
    })
  } else {
    .evaluate_genomes_forked(tables, namespace, path, workers, display)
  }
  display$done()
  results
}

# One child per block, and exactly as many blocks as workers. The children are
# started by hand rather than through mclapply() because mclapply() blocks the
# parent until the last of them returns, and a parent that cannot run between
# results cannot report progress; collecting them as they finish also keeps a
# failure attached to the block that raised it.
.evaluate_genomes_forked <- function(tables, namespace, path, workers, display) {
  blocks <- split(
    seq_along(tables),
    cut(seq_along(tables), breaks = workers, labels = FALSE)
  )
  ticker <- .new_genome_ticker(display$enabled)
  jobs <- list()
  pids <- integer()
  outstanding <- integer()
  # An interrupted or failed wait must not leave children evaluating genomes
  # that nobody is going to collect, and the children go before the file they
  # report through.
  on.exit({
    if (length(outstanding)) {
      for (pid in pids[outstanding]) {
        try(tools::pskill(pid, tools::SIGKILL), silent = TRUE)
      }
      # A child already reaped by the kill above is one this reports on, and
      # the community is being abandoned in any case.
      suppressWarnings(try(
        parallel::mccollect(jobs[outstanding], wait = FALSE), silent = TRUE
      ))
    }
    unlink(ticker)
  }, add = TRUE)

  jobs <- lapply(blocks, function(index) {
    parallel::mcparallel(
      .evaluate_genome_block(tables[index], namespace, path, ticker)
    )
  })
  pids <- vapply(jobs, function(job) job$pid, integer(1))
  outstanding <- seq_along(jobs)

  evaluated <- vector("list", length(jobs))
  while (length(outstanding)) {
    # The wait is bounded so that the display keeps moving while the children
    # work: the count comes from the ticker, which advances genome by genome,
    # rather than from the blocks, which only ever land whole.
    ready <- withCallingHandlers(
      parallel::mccollect(jobs[outstanding], wait = FALSE, timeout = 0.2),
      # A warning here is mccollect() counting a child that died without
      # delivering a result. That is reported below, against the block it left
      # empty. A warning raised inside a child never reaches this process.
      warning = function(condition) invokeRestart("muffleWarning")
    )
    display$update(.ticked_genomes(ticker))
    if (is.null(ready)) next
    delivered <- match(as.integer(names(ready)), pids)
    evaluated[delivered] <- ready
    outstanding <- setdiff(outstanding, delivered)
  }

  # A child reports a failure as a value rather than by raising it, and a child
  # that died reports nothing at all. Either way the community would be short of
  # a genome, so neither is allowed to pass as a result.
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
#' @section Arguments are checked before anything is evaluated:
#'
#' Evaluating a large community takes minutes or hours, so everything that can
#' be decided from the annotation table is decided before the first genome is
#' evaluated: the genome column, the gene column, the shape of the `workers`
#' request, and the single-genome guardrail of every genome. A malformed
#' argument therefore costs a message rather than the run.
#'
#' Nothing about how the calls will later be read is settled here. Genome
#' abundances and completeness estimates belong to [community_traits()], so a
#' community can be evaluated once and read under several thresholds.
#'
#' @section Parallel evaluation:
#'
#' Genomes are evaluated in forked worker processes, each holding its own
#' read-only database connection. Parallelism changes wall time only: the calls,
#' their order, and the assembled community are the same at any number of
#' workers. Forking is unavailable on Windows and for a connection with no file
#' behind it, where the genomes are evaluated one after another.
#'
#' A community of any size reports its progress at an interactive console, in
#' genomes evaluated out of genomes to evaluate, with an estimate of the time
#' remaining. The count advances genome by genome whether one worker or many
#' produced them, so it measures the run rather than the way the work was
#' spread out. Nothing is reported when there is nobody watching, which is why
#' a script, a knitted document and a package check stay silent unless they ask
#' for the display with `progress = TRUE`.
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
#' @param progress Whether to display a progress bar. Defaults to `TRUE` at an
#'   interactive console evaluating more than one genome, and to `FALSE`
#'   otherwise. The display never changes a call.
#' @return A `gifter_community` list. Its `results` member holds the
#'   `gifter_genome` result of every genome, under its genome identifier.
#' @seealso [evaluate_gifts()] for one genome, [community_traits()] for the
#'   quantitative traits of the returned community, which is where genome
#'   abundance and completeness are supplied.
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
                                     progress = NULL) {
  genomes <- .resolve_genome_id_column(annotation_table, genome_id)
  column <- if (is.null(genome_id)) "genome_id" else genome_id
  identifiers <- sort(unique(genomes))
  progress <- .resolve_progress(progress, length(identifiers))

  # A nonsensical `workers` request is answerable now, and the guardrail below
  # may stop to ask about a large genome before the evaluation would ever reach
  # the point where the request is resolved.
  .check_workers(workers)

  # The genome column is dropped before the gene column is resolved, so that it
  # is never the column proposed as a gene identifier.
  markers <- annotation_table
  markers[[column]] <- NULL
  markers <- .resolve_gene_id_column(markers, gene_id)

  tables <- lapply(identifiers, function(id) markers[genomes == id, , drop = FALSE])
  names(tables) <- identifiers

  # Every guardrail is answered in this session, before any worker starts: a
  # question asked in a forked child has nobody to answer it.
  for (id in identifiers) .check_single_genome(tables[[id]], max_genes, genome = id)

  results <- .evaluate_genomes(tables, namespace, db, workers, progress)
  .gifter_community(results)
}
