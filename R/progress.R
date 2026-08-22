# Progress displays for the long-running readers of a community.
#
# Two functions in this package run for minutes or hours over a large
# community: evaluate_gifts_community(), which evaluates every genome, and
# community_traits(), which walks every reference universe over the calls. A
# run of that length with a silent console is indistinguishable from a hung
# one, so both say how far along they are, through the same object and on the
# same terms.
#
# Progress is always reported in the unit the caller asked for -- genomes
# evaluated, reference universes summarised -- and never in workers started,
# blocks finished or genome pairs compared, which are implementation details of
# how the same work was arranged. A display never changes a result.

# The shape of a `progress` request, which is answerable before any work
# starts. What it resolves to is not: that depends on how many units of work
# there turn out to be, which a caller who supplied no reference universes has
# not yet decided.
.check_progress <- function(progress) {
  if (is.null(progress)) return(invisible(NULL))
  if (!is.logical(progress) || length(progress) != 1L || is.na(progress)) {
    cli::cli_abort("{.arg progress} must be {.code TRUE} or {.code FALSE}.", call = NULL)
  }
  invisible(NULL)
}

# Whether the run should say how far along it is. A progress display is for a
# person waiting at a console: written into a log or a knitted document it is
# noise, and for a single unit of work there is nothing to be partway through.
.resolve_progress <- function(progress, units) {
  .check_progress(progress)
  if (is.null(progress)) return(interactive() && units > 1L)
  progress
}

# The display, as a set of closures over a cli progress bar, so that a caller
# reports through one object without having to know whether a bar exists -- and
# so that the sequential and the forked paths of an evaluation report the same
# thing. cli holds the bar back for a couple of seconds, so work small enough
# to finish immediately never draws one.
.progress_display <- function(total, enabled, format, format_done) {
  if (!enabled) {
    return(list(
      enabled = FALSE,
      update = function(done) invisible(NULL),
      done = function() invisible(NULL),
      dismiss = function() invisible(NULL)
    ))
  }
  id <- cli::cli_progress_bar(
    format = format,
    format_done = format_done,
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
    # stops one short of it and the run is declared finished from one place:
    # the last unit is finished a moment before the result it belongs to
    # exists, and a run that fails between the two never claims to have
    # finished.
    update = function(done) {
      if (closed) return(invisible(NULL))
      cli::cli_progress_update(set = min(done, total - 1L), id = id)
    },
    done = function() close("done"),
    dismiss = function() close("clear")
  )
}

.genome_progress <- function(total, enabled) {
  .progress_display(
    total, enabled,
    format = paste0(
      "{cli::pb_spin} Evaluating genomes ",
      "{cli::pb_bar} {cli::pb_current}/{cli::pb_total} ",
      "({cli::pb_percent}) | ETA {cli::pb_eta}"
    ),
    format_done = paste0(
      "{cli::col_green(cli::symbol$tick)} Evaluated {cli::pb_total} ",
      "genome{?s} in {cli::pb_elapsed}."
    )
  )
}

# Reference universes are the unit here because they are what the caller
# supplied and what the returned metrics are reported within. A universe is not
# a fixed quantity of work -- one spanning the whole catalogue takes longer
# than a narrow one -- so the estimate is coarser than the genome count of an
# evaluation, and it still measures the reading of a community rather than the
# GIFTs and genome pairs each universe happens to contain.
.universe_progress <- function(total, enabled) {
  .progress_display(
    total, enabled,
    format = paste0(
      "{cli::pb_spin} Summarising universes ",
      "{cli::pb_bar} {cli::pb_current}/{cli::pb_total} ",
      "({cli::pb_percent}) | ETA {cli::pb_eta}"
    ),
    format_done = paste0(
      "{cli::col_green(cli::symbol$tick)} Summarised {cli::pb_total} ",
      "reference universe{?s} in {cli::pb_elapsed}."
    )
  )
}
