# Keep the live catalogue summary in the README aligned with the compiled DB.
# Run from the package root, or use --check to fail if the summary is stale.

update_database_docs <- function(
    database = "inst/extdata/gifter.sqlite", readme = "README.md", check = FALSE) {
  if (!file.exists(database)) stop("Compiled database is missing: ", database, call. = FALSE)
  connection <- DBI::dbConnect(RSQLite::SQLite(), database)
  on.exit(DBI::dbDisconnect(connection), add = TRUE)

  count <- function(table) {
    as.integer(DBI::dbGetQuery(connection, paste0("SELECT COUNT(*) FROM ", table))[[1]])
  }
  gift_types <- c("metabolic", "structural", "regulatory", "defense")
  type_rows <- DBI::dbGetQuery(
    connection, "SELECT gift_type, COUNT(*) AS n FROM gift GROUP BY gift_type"
  )
  if (!setequal(type_rows$gift_type, gift_types)) {
    stop("The compiled database does not contain all four GIFT types", call. = FALSE)
  }
  type_counts <- stats::setNames(type_rows$n, type_rows$gift_type)[gift_types]
  fmt <- function(value) format(value, big.mark = ",", scientific = FALSE, trim = TRUE)

  summary <- c(
    strwrap(paste0(
      "The packaged database currently contains ", fmt(count("gift")),
      " GIFTs: ", fmt(type_counts[["metabolic"]]), " metabolic, ",
      fmt(type_counts[["structural"]]), " structural, ",
      fmt(type_counts[["regulatory"]]), " regulatory and ",
      fmt(type_counts[["defense"]]), " defense capabilities."
    ), width = 80),
    "",
    strwrap(paste0(
      "The same release has ", fmt(count("anchor")), " declared anchors, ",
      fmt(count("gift_route")), " metabolic routes, ",
      fmt(count("reaction")), " distinct reactions, ",
      fmt(sum(vapply(
        c("enzyme_system", "structural_system", "regulatory_system", "defense_system"),
        count, integer(1)
      ))), " systems across the four types, and ",
      fmt(count("marker")), " distinct marker identifiers."
    ), width = 80)
  )

  lines <- readLines(readme, warn = FALSE, encoding = "UTF-8")
  start <- which(lines == "<!-- database-stats:start -->")
  end <- which(lines == "<!-- database-stats:end -->")
  if (length(start) != 1L || length(end) != 1L || end <= start) {
    stop("README database-stats markers are missing or duplicated", call. = FALSE)
  }
  updated <- c(lines[seq_len(start)], summary, lines[end:length(lines)])
  if (identical(lines, updated)) return(invisible(FALSE))
  if (check) stop("README database statistics are stale; run Rscript data-raw/update_database_docs.R", call. = FALSE)
  writeLines(updated, readme, useBytes = TRUE)
  invisible(TRUE)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(setdiff(args, "--check"))) stop("Only --check is supported", call. = FALSE)
  update_database_docs(check = "--check" %in% args)
}
