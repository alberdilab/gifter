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
  expect_true(
    all(file.exists(file.path(root, sources))),
    info = paste("Missing source paths:", paste(sources[!file.exists(file.path(root, sources))], collapse = ", "))
  )

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
  gifts <- utils::read.delim(
    file.path(root, "inst", "extdata", "database-source", "gifts.tsv"),
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
