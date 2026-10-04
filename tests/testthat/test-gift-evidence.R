source_dir <- function() system.file("extdata", "database-source", package = "gifter")

copy_sources <- function() {
  fixture <- tempfile("gifter-source-")
  dir.create(fixture)
  file.copy(list.files(source_dir(), full.names = TRUE), fixture)
  fixture
}

read_source <- function(dir, table) {
  utils::read.delim(
    file.path(dir, paste0(table, ".tsv")), sep = "\t", check.names = FALSE,
    colClasses = "character", na.strings = character()
  )
}

write_source <- function(dir, table, value) {
  utils::write.table(
    value, file.path(dir, paste0(table, ".tsv")), sep = "\t", quote = FALSE,
    row.names = FALSE, na = ""
  )
}

evidence_errors <- function(mutate) {
  fixture <- copy_sources()
  on.exit(unlink(fixture, recursive = TRUE))
  evidence <- read_source(fixture, "gift_evidence")
  write_source(fixture, "gift_evidence", mutate(evidence))
  validate_gifter_sources(fixture, stop_on_error = FALSE)$errors
}

test_that("every GIFT names at least one curation document", {
  evidence <- read_source(source_dir(), "gift_evidence")
  gifts <- read_source(source_dir(), "gifts")$gift_id
  documented <- unique(evidence$gift_id[evidence$evidence_kind == "curation_document"])
  expect_setequal(documented, gifts)
})

test_that("every evidence location exists in the source repository", {
  root <- testthat::test_path("..", "..")
  skip_if_not(dir.exists(file.path(root, "data-raw")), "source repository not available")
  evidence <- read_source(source_dir(), "gift_evidence")
  missing <- unique(evidence$location[!file.exists(file.path(root, evidence$location))])
  expect_identical(missing, character())
})

test_that("a cited result table brings the script recorded as regenerating it", {
  # data-raw/reference/README.md names the script behind each table family.
  # A GIFT that cites the table without its script would hide the code that
  # produced the numbers it relies on.
  evidence <- read_source(source_dir(), "gift_evidence")
  producers <- c(
    "^data-raw/reference/archaellum-" = "data-raw/archaellum_ncbifam_prevalence.R",
    "^data-raw/reference/t2ss-" = "data-raw/t2ss_prevalence.R",
    "^data-raw/reference/wta-" = "data-raw/wta_ncbifam_prevalence.R",
    "^data-raw/reference/secretion-system-" = "data-raw/secretion_system_prevalence.R",
    "^data-raw/reference/serine-deamination-" = "data-raw/serine_deamination_marker_audit.py"
  )
  tables <- evidence[evidence$evidence_kind == "result_table", , drop = FALSE]
  for (pattern in names(producers)) {
    citing <- unique(tables$gift_id[grepl(pattern, tables$location)])
    for (gift_id in citing) {
      expect_true(
        any(evidence$gift_id == gift_id & evidence$location == producers[[pattern]]),
        info = paste(gift_id, "cites", pattern, "without", producers[[pattern]])
      )
    }
  }
})

test_that("source validation refuses malformed curation evidence", {
  expect_true(any(grepl("Invalid gift_evidence.evidence_kind", evidence_errors(function(x) {
    x$evidence_kind[1] <- "publication"
    x
  }))))
  expect_true(any(grepl("relative path inside the source repository", evidence_errors(function(x) {
    x$location[1] <- "https://example.org/proposal.md"
    x
  }))))
  expect_true(any(grepl("relative path inside the source repository", evidence_errors(function(x) {
    x$location[1] <- "inst/doc/../../outside.md"
    x
  }))))
  expect_true(any(grepl("does not match its evidence_kind", evidence_errors(function(x) {
    row <- which(x$evidence_kind == "curation_document")[1]
    x$evidence_kind[row] <- "analysis_script"
    x
  }))))
  expect_false(any(grepl("does not match its evidence_kind", evidence_errors(function(x) {
    row <- which(x$location == "data-raw/serine_deamination_marker_audit.py")
    x$evidence_kind[row] <- "analysis_script"
    x
  }))))
  expect_true(any(grepl("gift_evidence.gift_id", evidence_errors(function(x) {
    x$gift_id[1] <- "no_such_gift"
    x
  }))))
  expect_true(any(grepl("Duplicated gift_evidence", evidence_errors(function(x) {
    rbind(x, x[1, ])
  }))))
  expect_true(any(grepl("gift_evidence.description must be recorded", evidence_errors(function(x) {
    x$description[1] <- ""
    x
  }))))
})

test_that("source validation refuses a malformed source repository", {
  fixture <- copy_sources()
  on.exit(unlink(fixture, recursive = TRUE))
  release <- read_source(fixture, "database_release")
  release$source_repository <- "https://github.com/alberdilab/gifter/"
  write_source(fixture, "database_release", release)
  errors <- validate_gifter_sources(fixture, stop_on_error = FALSE)$errors
  expect_true(any(grepl("source_repository must be an https URL", errors)))
})

test_that("evidence links follow the release commit, or the default branch before release", {
  evidence <- get_gift_evidence("type_ii_secretion_system")
  expect_setequal(
    unique(evidence$evidence_kind),
    c("curation_document", "analysis_script", "result_table")
  )
  expect_true("data-raw/t2ss_prevalence.R" %in% evidence$location)
  # Documents first, then the code, then what the code wrote.
  expect_identical(
    unique(evidence$evidence_kind),
    c("curation_document", "analysis_script", "result_table")
  )
  repository <- gifter_db_version()$source_repository
  expect_identical(repository, "https://github.com/alberdilab/gifter")
  expect_identical(
    evidence$url[evidence$location == "data-raw/t2ss_prevalence.R"],
    paste0(repository, "/blob/HEAD/data-raw/t2ss_prevalence.R")
  )

  commit <- strrep("ab12", 10)
  output <- tempfile(fileext = ".sqlite")
  on.exit(unlink(output), add = TRUE)
  build_gifter_database(source_dir(), output, source_commit = commit)
  db <- gifter_db_connect(output)
  on.exit(gifter_db_disconnect(db), add = TRUE)
  released <- get_gift_evidence("type_ii_secretion_system", db = db)
  expect_true(all(startsWith(released$url, paste0(repository, "/blob/", commit, "/"))))
})

test_that("evidence never changes a call", {
  # Provenance sits beside the hierarchy: removing every row must leave the
  # evaluation of every GIFT exactly as it was.
  markers <- ko_annotations(c("K01939", "K01756"))
  with_evidence <- evaluate_gifts(markers)
  output <- tempfile(fileext = ".sqlite")
  on.exit(unlink(output), add = TRUE)
  file.copy(gifter:::.gifter_database_path(), output)
  writable <- DBI::dbConnect(RSQLite::SQLite(), output)
  DBI::dbExecute(writable, "DELETE FROM gift_evidence")
  DBI::dbDisconnect(writable)
  db <- gifter_db_connect(output)
  on.exit(gifter_db_disconnect(db), add = TRUE)
  without_evidence <- evaluate_gifts(markers, db = db)
  expect_identical(
    as.data.frame(with_evidence$gifts[c("gift_id", "complete")]),
    as.data.frame(without_evidence$gifts[c("gift_id", "complete")])
  )
})

test_that("a schema 7 database still opens and reports no evidence", {
  output <- tempfile(fileext = ".sqlite")
  on.exit(unlink(output), add = TRUE)
  file.copy(gifter:::.gifter_database_path(), output)
  writable <- DBI::dbConnect(RSQLite::SQLite(), output)
  DBI::dbExecute(writable, "DROP TABLE gift_evidence")
  DBI::dbExecute(writable, "ALTER TABLE database_release DROP COLUMN source_repository")
  DBI::dbExecute(writable, "UPDATE database_release SET schema_version = 7")
  DBI::dbDisconnect(writable)

  db <- gifter_db_connect(output)
  on.exit(gifter_db_disconnect(db), add = TRUE)
  expect_identical(nrow(get_gift_evidence("archaellum", db = db)), 0L)
  expect_true(is.na(gifter_db_version(db)$source_repository))

  html_path <- tempfile(fileext = ".html")
  on.exit(unlink(html_path), add = TRUE)
  write_gifter_database_html(html_path, database = db)
  html <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
  expect_match(html, "records no curation evidence", fixed = TRUE)
})

test_that("the atlas links each GIFT's evidence and each identifier's public record", {
  output <- tempfile(fileext = ".html")
  on.exit(unlink(output), add = TRUE)
  html <- paste(readLines(write_gifter_database_html(output), warn = FALSE), collapse = "\n")

  page <- regmatches(html, regexpr(
    'data-gift-id="archaellum" data-gift-name="[^"]*"[^>]*hidden>.*?</article>', html, perl = TRUE
  ))
  expect_match(page, "Curation evidence", fixed = TRUE)
  expect_match(
    page,
    'href="https://github.com/alberdilab/gifter/blob/HEAD/data-raw/archaellum_ncbifam_prevalence.R"',
    fixed = TRUE
  )
  expect_match(page, "Analysis scripts (R)", fixed = TRUE)
  expect_no_match(page, "No analysis script is recorded", fixed = TRUE)

  # A GIFT curated without a script says so instead of implying one.
  adenylate <- regmatches(html, regexpr(
    'data-gift-id="adenylate_biosynthesis" data-gift-name="[^"]*"[^>]*hidden>.*?</article>',
    html, perl = TRUE
  ))
  expect_match(adenylate, "No analysis script is recorded for this GIFT", fixed = TRUE)
  expect_match(adenylate, 'href="https://www.kegg.jp/entry/K01939"', fixed = TRUE)
  expect_match(adenylate, "Source: KEGG M00049", fixed = TRUE)
  expect_match(adenylate, 'href="https://www.kegg.jp/module/M00049"', fixed = TRUE)

  # A dbCAN-sub cluster has no CAZy page; it links to its parent family.
  expect_identical(
    gifter:::.report_external_url("CAZY", c("GH13_e123", "GH43")),
    c("http://www.cazy.org/GH13.html", "http://www.cazy.org/GH43.html")
  )
  expect_true(is.na(gifter:::.report_external_url("UNKNOWN", "X1")))
})
