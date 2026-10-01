# Rebuild the packaged reference database from the reviewable TSV sources.
# Run from the package root after installing development dependencies.

devtools::load_all(quiet = TRUE)

validate_gifter_sources("inst/extdata/database-source")
source_commit <- .release_source_commit()
build_gifter_database(
  source_dir = "inst/extdata/database-source",
  output = "inst/extdata/gifter.sqlite",
  overwrite = TRUE,
  source_commit = source_commit
)
