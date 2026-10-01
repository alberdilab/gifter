test_that("citation metadata is parseable and does not fabricate a DOI", {
  meta <- as.list(utils::packageDescription("gifter"))
  citation <- utils::readCitationFile(
    system.file("CITATION", package = "gifter"), meta = meta
  )
  expect_true(length(citation) >= 1L)
  text <- paste(capture.output(print(citation)), collapse = "\n")
  expect_match(text, "gifter: Genome-Inferred Functional Traits")
  expect_false(grepl("doi.org/10\\.", text, ignore.case = TRUE))
})

test_that("every shipped upstream resource has a reviewable licensing row", {
  manifest <- utils::read.delim(
    system.file("extdata", "UPSTREAM-SOURCES.tsv", package = "gifter"),
    sep = "\t", quote = "", check.names = FALSE, stringsAsFactors = FALSE
  )
  expect_named(manifest, c(
    "resource", "use_in_shipped_content", "pinned_release_or_access_date",
    "source_url", "terms_url", "known_terms", "redistribution_status",
    "review_status", "notes"
  ))
  expect_true(all(vapply(manifest, function(column) all(nzchar(column)), logical(1))))
  expect_setequal(
    manifest$resource,
    c(
      "Rhea", "ChEBI", "KEGG", "dbCAN and dbCAN-sub", "CAZy", "InterPro",
      "Pfam", "NCBIfam", "TIGRFAM legacy records", "MetaCyc / BioCyc",
      "Primary scientific literature"
    )
  )
  expect_true(all(manifest$review_status %in% c("cleared", "human_review_required")))
  expect_setequal(
    manifest$resource[manifest$review_status == "human_review_required"],
    c(
      "KEGG", "dbCAN and dbCAN-sub", "CAZy", "InterPro", "NCBIfam",
      "TIGRFAM legacy records", "MetaCyc / BioCyc"
    )
  )
})
