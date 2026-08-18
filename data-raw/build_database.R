# Rebuild the packaged reference database from the reviewable TSV sources.
# Run from the package root after installing development dependencies.

devtools::load_all(quiet = TRUE)

validate_giftr_sources("inst/extdata/database-source")
build_giftr_database(
  source_dir = "inst/extdata/database-source",
  output = "inst/extdata/giftr.sqlite",
  overwrite = TRUE
)

# Keep the browsable database snapshot in sync with the compiled artifact.
write_giftr_database_html(
  output = "inst/extdata/giftr-database.html",
  database = "inst/extdata/giftr.sqlite"
)
