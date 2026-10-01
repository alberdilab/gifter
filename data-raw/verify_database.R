# Verify that the reviewable TSV source compiles to the packaged database.
#
# This intentionally builds into a temporary file. CI must never rebuild or
# modify the tracked SQLite artifact merely in order to test reproducibility.

devtools::load_all(quiet = TRUE)

source_dir <- file.path("inst", "extdata", "database-source")
packaged_path <- file.path("inst", "extdata", "gifter.sqlite")

validation <- validate_gifter_sources(source_dir)
stopifnot(validation$valid, !length(validation$errors))

packaged <- gifter_db_connect(packaged_path)
on.exit(DBI::dbDisconnect(packaged), add = TRUE)

# Development artifacts record `unreleased`. For a release artifact, reproduce
# the commit already recorded in the packaged database unless the caller has
# explicitly supplied GIFTER_SOURCE_COMMIT. This keeps the same script useful
# in CI after release without teaching the workflow a version-specific hash.
requested_commit <- Sys.getenv("GIFTER_SOURCE_COMMIT", unset = "")
recorded_commit <- gifter_db_version(packaged)$source_commit[[1L]]
source_commit <- if (nzchar(trimws(requested_commit))) {
  .release_source_commit(requested_commit)
} else if (identical(recorded_commit, "unreleased")) {
  NULL
} else {
  .release_source_commit(recorded_commit)
}

compiled_path <- tempfile("gifter-ci-", fileext = ".sqlite")
on.exit(unlink(compiled_path), add = TRUE)
build_gifter_database(
  source_dir, compiled_path, source_commit = source_commit
)

compiled <- gifter_db_connect(compiled_path)
on.exit(DBI::dbDisconnect(compiled), add = TRUE)

check_sqlite <- function(connection, label) {
  foreign_keys <- DBI::dbGetQuery(connection, "PRAGMA foreign_key_check")
  if (nrow(foreign_keys)) {
    stop(label, " database failed foreign-key validation", call. = FALSE)
  }
  integrity <- DBI::dbGetQuery(connection, "PRAGMA integrity_check")[[1]]
  if (!identical(integrity, "ok")) {
    stop(label, " database failed integrity validation: ", integrity, call. = FALSE)
  }
}

canonical_table <- function(connection, table) {
  value <- DBI::dbReadTable(connection, table)
  if (!nrow(value)) return(value)
  keys <- lapply(value, function(column) {
    ifelse(is.na(column), "<NA>", enc2utf8(as.character(column)))
  })
  value[do.call(order, c(keys, list(na.last = TRUE))), , drop = FALSE]
}

check_sqlite(packaged, "Packaged")
check_sqlite(compiled, "Compiled")

packaged_tables <- sort(DBI::dbListTables(packaged))
compiled_tables <- sort(DBI::dbListTables(compiled))
if (!identical(compiled_tables, packaged_tables)) {
  stop("Compiled and packaged databases expose different table sets", call. = FALSE)
}

for (table in packaged_tables) {
  expected <- canonical_table(packaged, table)
  observed <- canonical_table(compiled, table)
  if (!identical(observed, expected)) {
    stop("Compiled table differs from packaged SQLite: ", table, call. = FALSE)
  }
}

message(
  "Validated sources and reproduced ", length(packaged_tables),
  " SQLite tables with integrity and foreign keys intact."
)
