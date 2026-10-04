attempt_register_path <- function() {
  path <- testthat::test_path(
    "..", "..", "inst", "doc", "catalogue-expansion-attempts.tsv"
  )
  if (file.exists(path)) return(path)
  system.file("doc", "catalogue-expansion-attempts.tsv", package = "gifter")
}

read_attempt_register <- function() {
  utils::read.delim(
    attempt_register_path(),
    sep = "\t",
    colClasses = "character",
    quote = "",
    comment.char = "",
    check.names = FALSE,
    na.strings = character()
  )
}

split_attempt_values <- function(x) {
  values <- trimws(unlist(strsplit(x[nzchar(x)], ";", fixed = TRUE)))
  values[nzchar(values)]
}

test_that("catalogue expansion attempts have a stable searchable contract", {
  attempts <- read_attempt_register()

  expect_named(
    attempts,
    c(
      "attempt_id", "started_at", "closed_at", "state", "scope",
      "gift_types", "candidate_terms", "implemented_gifts",
      "deferred_or_open", "refused_or_superseded", "revisits", "source",
      "result"
    )
  )
  expect_gt(nrow(attempts), 0L)
  expect_true(all(grepl("^GEA-[0-9]{8}-[A-Z0-9-]+$", attempts$attempt_id)))
  expect_identical(anyDuplicated(attempts$attempt_id), 0L)
  expect_true(all(attempts$state %in% c("in_progress", "closed")))
  expect_true(all(nzchar(attempts$scope)))
  expect_true(all(nzchar(attempts$candidate_terms)))
  expect_true(all(nzchar(attempts$source)))

  iso_date <- "^[0-9]{4}-[0-9]{2}-[0-9]{2}(T[0-9]{2}:[0-9]{2}(:[0-9]{2})?Z)?$"
  expect_true(all(grepl(iso_date, attempts$started_at)))
  expect_true(all(!nzchar(attempts$closed_at) | grepl(iso_date, attempts$closed_at)))
  expect_true(all(nzchar(attempts$closed_at[attempts$state == "closed"])))
  expect_true(all(!nzchar(attempts$closed_at[attempts$state == "in_progress"])))

  for (i in seq_len(nrow(attempts))) {
    for (field in c(
      "candidate_terms", "implemented_gifts", "deferred_or_open",
      "refused_or_superseded", "revisits", "source"
    )) {
      values <- split_attempt_values(attempts[[field]][i])
      expect_identical(
        anyDuplicated(values), 0L,
        info = paste(attempts$attempt_id[i], "duplicates a value in", field)
      )
    }
  }
})

test_that("attempt sources and revisit links resolve", {
  attempts <- read_attempt_register()
  root <- testthat::test_path("..", "..")

  sources <- split_attempt_values(attempts$source)
  # The full source repository is not included in an installed package. The
  # source-path audit applies when that repository is available; revisit links
  # are part of the packaged register and are checked in either setting.
  if (dir.exists(file.path(root, "data-raw"))) {
    expect_true(
      all(file.exists(file.path(root, sources))),
      info = paste("Missing source paths:", paste(sources[!file.exists(file.path(root, sources))], collapse = ", "))
    )
  }

  revisits <- split_attempt_values(attempts$revisits)
  expect_true(all(revisits %in% attempts$attempt_id))
  for (i in seq_len(nrow(attempts))) {
    expect_false(
      attempts$attempt_id[i] %in% split_attempt_values(attempts$revisits[i]),
      info = paste(attempts$attempt_id[i], "cannot revisit itself")
    )
  }
})

test_that("completed expansion attempts account for the curated catalogue", {
  attempts <- read_attempt_register()
  root <- testthat::test_path("..", "..")
  gifts_path <- file.path(root, "inst", "extdata", "database-source", "gifts.tsv")
  if (!file.exists(gifts_path)) {
    gifts_path <- system.file("extdata", "database-source", "gifts.tsv", package = "gifter")
  }
  gifts <- utils::read.delim(
    gifts_path,
    sep = "\t",
    colClasses = "character",
    quote = "",
    comment.char = "",
    check.names = FALSE
  )

  implemented <- split_attempt_values(
    attempts$implemented_gifts[attempts$state == "closed"]
  )
  expect_true(all(implemented %in% gifts$gift_id))
  expect_setequal(implemented, gifts$gift_id)
})

test_that("the atlas lists every expansion attempt with its outcomes", {
  attempts <- read_attempt_register()
  output <- tempfile(fileext = ".html")
  on.exit(unlink(output), add = TRUE)
  html <- paste(readLines(write_gifter_database_html(output), warn = FALSE), collapse = "\n")

  # The view is reached from the Curation menu, not the Atlas menu.
  expect_match(html, '<section class="view" id="attempts" data-view="attempts">', fixed = TRUE)
  curation_menu <- regmatches(
    html, regexpr("<details class=\"site-menu\" data-view-menu [^§]*?</details>", html, perl = TRUE)
  )
  expect_match(curation_menu, "<summary class=\"site-nav-link\">Curation</summary>", fixed = TRUE)
  expect_match(
    curation_menu,
    '<div class="site-menu-label">History</div><button class="view-menu-link" type="button" data-view-button="attempts">',
    fixed = TRUE
  )

  # One table row and one page per registered attempt.
  for (attempt_id in attempts$attempt_id) {
    expect_match(html, paste0('data-attempt-row data-attempt-id="', attempt_id, '"'), fixed = TRUE)
    expect_match(html, paste0('data-attempt-page data-attempt-id="', attempt_id, '"'), fixed = TRUE)
  }

  # An attempt that added nothing is listed and filterable by what it did record.
  empty <- attempts[!nzchar(attempts$implemented_gifts) & nzchar(attempts$refused_or_superseded), ][1, ]
  row <- regmatches(html, regexpr(
    paste0('data-attempt-row data-attempt-id="', empty$attempt_id, '"[^>]*>'), html
  ))
  expect_match(row, "data-attempt-outcomes=\" [a-z ]*refused ", perl = TRUE)
  expect_no_match(row, "implemented", fixed = TRUE)

  # Implemented GIFTs open their atlas pages, and sources point to the repository.
  page <- regmatches(html, regexpr(
    paste0('data-attempt-page data-attempt-id="GEA-20260818-PROTEIN-DEGRADATION"[^§]*?</article>'),
    html, perl = TRUE
  ))
  expect_match(page, 'data-gift-link="collagen_cleavage"', fixed = TRUE)
  expect_match(page, "elastin cleavage", fixed = TRUE)
  expect_match(page, "/inst/doc/proposal-protein-degradation.md", fixed = TRUE)
  # The page renders the log's row, so it does not send readers back to the log.
  expect_no_match(html, "/inst/doc/catalogue-expansion-attempts.tsv", fixed = TRUE)

  # A revisit links both ways between the attempts.
  later <- attempts[nzchar(attempts$revisits), ][1, ]
  earlier <- strsplit(later$revisits, ";", fixed = TRUE)[[1]][[1]]
  earlier_page <- regmatches(html, regexpr(
    paste0('data-attempt-page data-attempt-id="', earlier, '"[^§]*?</article>'), html, perl = TRUE
  ))
  expect_match(earlier_page, "Revisited by", fixed = TRUE)
  expect_match(earlier_page, paste0('href="#attempts/', later$attempt_id, '"'), fixed = TRUE)
})
