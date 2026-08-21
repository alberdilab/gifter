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

# Whether the run should say how far along it is. A progress display is for a
# person waiting at a console: written into a log or a knitted document it is
# noise, and for a single genome there is nothing to be partway through.
.resolve_progress <- function(progress, genomes) {
  if (is.null(progress)) return(interactive() && genomes > 1L)
  if (!is.logical(progress) || length(progress) != 1L || is.na(progress)) {
    cli::cli_abort("{.arg progress} must be {.code TRUE} or {.code FALSE}.", call = NULL)
  }
  progress
}

# The display, as a set of closures over a cli progress bar, so that the
# sequential and the forked paths report the same thing through the same object
# and neither has to know whether a bar exists. cli holds the bar back for a
# couple of seconds, so a community small enough to finish immediately never
# draws one.
.genome_progress <- function(total, enabled) {
  if (!enabled) {
    return(list(
      enabled = FALSE,
      update = function(evaluated) invisible(NULL),
      done = function() invisible(NULL),
      dismiss = function() invisible(NULL)
    ))
  }
  id <- cli::cli_progress_bar(
    format = paste0(
      "{cli::pb_spin} Evaluating genomes ",
      "{cli::pb_bar} {cli::pb_current}/{cli::pb_total} ",
      "({cli::pb_percent}) | ETA {cli::pb_eta}"
    ),
    format_done = paste0(
      "{cli::col_green(cli::symbol$tick)} Evaluated {cli::pb_total} ",
      "genome{?s} in {cli::pb_elapsed}."
    ),
    total = total,
    clear = FALSE,
    .auto_close = FALSE
  )
  closed <- FALSE
  close <- function(result) {
    if (closed) return(invisible(NULL))
    closed <<- TRUE
    cli::cli_progress_done(id = id, result = result)
  }
  list(
    enabled = TRUE,
    # cli terminates a bar the moment its count reaches its total, so the count
    # stops one short of it and the run is declared finished from one place: the
    # last genome is evaluated a moment before the community it belongs to
    # exists, and a run that fails between the two never claims to have
    # finished.
    update = function(evaluated) {
      if (closed) return(invisible(NULL))
      cli::cli_progress_update(set = min(evaluated, total - 1L), id = id)
    },
    done = function() close("done"),
    dismiss = function() close("clear")
  )
}

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
                                     progress = NULL,
                                     abundance = NULL, quality = NULL,
                                     policy = "none", threshold = NULL) {
  genomes <- .resolve_genome_id_column(annotation_table, genome_id)
  column <- if (is.null(genome_id)) "genome_id" else genome_id
  progress <- .resolve_progress(progress, length(unique(genomes)))

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

  results <- .evaluate_genomes(tables, namespace, db, workers, progress)
  .gifter_community(
    results, abundance = abundance, quality = quality,
    policy = policy, threshold = threshold
  )
}
