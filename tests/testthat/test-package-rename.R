test_that("the installed package and packaged artifacts use the gifter name", {
  expect_identical(environmentName(environment(evaluate_gifts)), "gifter")
  expect_match(
    system.file("extdata", "gifter.sqlite", package = "gifter"),
    "gifter[.]sqlite$"
  )
  expect_match(
    system.file("schema", "gifter.sql", package = "gifter"),
    "gifter[.]sql$"
  )
})

test_that("pre-rename public names and classes remain compatible", {
  exports <- getNamespaceExports("gifter")
  expect_true(all(c(
    "giftr_community", "giftr_db_connect", "giftr_db_disconnect",
    "giftr_db_version", "validate_giftr_sources", "build_giftr_database",
    "write_giftr_database_html"
  ) %in% exports))

  version <- gifter_db_version()
  expect_identical(version$giftr_db_version, version$gifter_db_version)
  expect_identical(giftr_db_version(), version)

  result <- evaluate_gifts(character())
  expect_s3_class(result, "gifter_result")
  expect_true(inherits(result, "giftr_result"))

  community <- giftr_community(genome = result)
  expect_s3_class(community, "gifter_community")
  expect_true(inherits(community, "giftr_community"))
})
