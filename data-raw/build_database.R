# Rebuild the packaged reference database from the reviewable TSV sources.
# Run from the package root after installing development dependencies.

devtools::load_all(quiet = TRUE)

validate_gifter_sources("inst/extdata/database-source")
build_gifter_database(
  source_dir = "inst/extdata/database-source",
  output = "inst/extdata/gifter.sqlite",
  overwrite = TRUE
)

# Keep the browsable database snapshot in sync with the compiled artifact.
write_gifter_database_html(
  output = "inst/extdata/gifter-database.html",
  database = "inst/extdata/gifter.sqlite"
)
