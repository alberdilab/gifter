# Rebuild the packaged reference database from the reviewable TSV sources.
# Run from the package root after installing development dependencies.

devtools::load_all(quiet = TRUE)

# The sources are checked against the pinned reference snapshot as well as
# against each other, and the basis of each marker assignment is recomputed
# from the link extracts written by data-raw/reference_snapshot.R. The NCBIfam
# and CAZy extract is committed. KEGG's own links are not redistributed, so KO
# assignments are recomputed only where the cached extract is present; without
# it validation says so.
reference_dir <- "inst/extdata/reference-snapshot"
marker_links <- c(
  "data-raw/reference/marker-links.tsv",
  "data-raw/reference/.cache/external/kegg-ko-links.tsv"
)
marker_links <- marker_links[file.exists(marker_links)]

report <- validate_gifter_sources(
  "inst/extdata/database-source", reference_dir = reference_dir, marker_links = marker_links
)
for (warning in report$warnings) message("Warning: ", warning)
source_commit <- .release_source_commit()
build_gifter_database(
  source_dir = "inst/extdata/database-source",
  output = "inst/extdata/gifter.sqlite",
  overwrite = TRUE,
  source_commit = source_commit,
  reference_dir = reference_dir,
  marker_links = marker_links
)
source("data-raw/update_database_docs.R", local = TRUE)
update_database_docs()
