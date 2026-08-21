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

test_that("no giftr name survives in the public surface", {
  # gifter was never published as giftr, so the pre-rename aliases carried a
  # compatibility promise to nobody. Their absence is the contract.
  exports <- getNamespaceExports("gifter")
  expect_false(any(grepl("^giftr_|_giftr_", exports)))
  expect_false("giftr_db_version" %in% names(gifter_db_version()))

  result <- evaluate_gifts(character())
  expect_s3_class(result, "gifter_genome")
  expect_false(any(grepl("^giftr_", class(result))))

  community <- gifter_community(genome = result)
  expect_s3_class(community, "gifter_community")
  expect_false(any(grepl("^giftr_", class(community))))
})
