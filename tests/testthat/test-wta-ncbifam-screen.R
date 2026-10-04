test_that("the WTA NCBIfam screen separates proxies from resolved calls", {
  root <- testthat::test_path("..", "..")
  path <- file.path(root, "data-raw", "reference", "wta-ncbifam-prevalence.tsv")
  skip_if_not(file.exists(path), "source reference table is unavailable")
  screen <- utils::read.delim(
    path,
    sep = "\t", quote = "", comment.char = "", check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expect_setequal(
    screen$candidate,
    c(
      "poly(glycerol-phosphate) WTA, 168-type",
      "poly(ribitol-phosphate) WTA, Staphylococcus-type",
      "poly(ribitol-phosphate) WTA, W23-type"
    )
  )
  expect_true(all(screen$marker_resolved_complete_genomes <= screen$ko_proxy_genomes,
                  na.rm = TRUE))

  glycerol <- screen[grepl("glycerol", screen$candidate, fixed = TRUE), ]
  staph <- screen[grepl("Staphylococcus", screen$candidate, fixed = TRUE), ]
  w23 <- screen[grepl("W23", screen$candidate, fixed = TRUE), ]
  expect_true(is.na(glycerol$marker_resolved_complete_genomes))
  expect_identical(staph$ko_proxy_genomes, 49L)
  expect_identical(staph$marker_resolved_complete_genomes, 48L)
  expect_identical(staph$standing_test, "defer_20_to_49")
  expect_identical(w23$marker_resolved_complete_genomes, 22L)
})

test_that("the 168-type TagF audit admits no profile", {
  root <- testthat::test_path("..", "..")
  path <- file.path(root, "data-raw", "reference", "wta-tagf-marker-audit.tsv")
  skip_if_not(file.exists(path), "source reference table is unavailable")
  audit <- utils::read.delim(
    path,
    sep = "\t", quote = "", comment.char = "", check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expect_setequal(audit$ncbi_accession, c("NF016357.7", "NF041712.1"))
  expect_false(any(audit$licenses_168_type_tagf))
  expect_setequal(audit$family_type, c("domain", "equivalog"))
  expect_true(all(audit$ncbifam_release == "hmm_PGAP/20.0"))
})
