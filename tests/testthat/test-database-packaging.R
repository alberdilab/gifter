test_that("the rendered database atlas is not installed beside SQLite", {
  # The atlas is generated on demand and published with the package website.
  # Shipping it beside SQLite would install the same database content twice.
  expect_identical(
    system.file("extdata", "gifter-database.html", package = "gifter"),
    ""
  )
})
