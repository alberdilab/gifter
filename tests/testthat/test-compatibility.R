test_that("representative public signatures remain source compatible", {
  expect_identical(
    names(formals(evaluate_gifts)),
    c("annotation_table", "namespace", "db", "gene_id", "max_genes")
  )
  expect_identical(
    names(formals(evaluate_gifts_community)),
    c(
      "annotation_table", "namespace", "db", "genome_id", "gene_id",
      "max_genes", "workers", "progress"
    )
  )
  expect_identical(
    names(formals(community_traits)),
    c(
      "community", "frames", "abundance", "quality", "policy", "threshold",
      "min_confidence", "pairwise", "pair_trace", "db", "progress"
    )
  )
  expect_identical(
    names(formals(dataset_traits)),
    c(
      "dataset", "frames", "quality", "policy", "threshold",
      "min_confidence", "detection", "pairwise", "db", "progress"
    )
  )
})

test_that("public result classes retain their stable core fields", {
  expect_core <- function(value, class, fields) {
    expect_s3_class(value, class)
    expect_true(all(fields %in% names(value)))
  }

  genome <- evaluate_gifts(character())
  expect_core(genome, "gifter_genome", c(
    "gifts", "routes", "route_reactions", "reactions", "systems",
    "components", "evidence", "structural", "regulatory", "defense",
    "marker_map", "observed_markers", "database_version"
  ))
  reactions <- evaluate_reactions(character())
  expect_core(reactions, "gifter_reaction_result", c(
    "reactions", "systems", "components", "evidence", "marker_map",
    "observed_markers", "database_version"
  ))

  community <- gifter_community(A = genome)
  expect_core(community, "gifter_community", c(
    "genome_id", "gift_id", "matrix", "results", "database_version"
  ))
  frame <- reference_frame(label = "compatibility fixture")
  expect_core(frame, "gifter_frame", c(
    "gift_id", "label", "filters", "bounded", "database_version"
  ))
  traits <- genome_traits(genome, frames = list(frame), genome_id = "A")
  expect_core(traits, "gifter_traits", c(
    "metrics", "trace", "frames", "database_version"
  ))

  abundance <- matrix(1, nrow = 1L, dimnames = list("A", "S1"))
  dataset <- gifter_dataset(community, abundance)
  expect_core(dataset, "gifter_dataset", c(
    "catalogue", "genome_id", "sample_id", "abundance", "metadata",
    "database_version"
  ))
  many <- dataset_traits(dataset, frames = list(frame), pairwise = FALSE)
  expect_core(many, "gifter_dataset_traits", c(
    "metrics", "catalogue_metrics", "trace", "frames", "sample_id",
    "genome_id", "metadata", "database_version"
  ))

  network <- community_network(community, frame = frame)
  expect_core(network, "gifter_network", c(
    "nodes", "edges", "metrics", "frame", "database_version"
  ))
  networks <- dataset_network(dataset, frame = frame)
  expect_core(networks, "gifter_dataset_network", c(
    "nodes", "edges", "metrics", "frame", "sample_id", "detection",
    "database_version"
  ))

  expect_identical(names(traits$metrics), .metric_columns)
  expect_identical(names(traits$trace), .trace_columns)
})

test_that("custom database compatibility fails early and specifically", {
  # The compiler writes the newest schema; the reader also accepts the one
  # before it, which schema 8 extends without changing.
  expect_identical(max(.gifter_supported_schema_versions), .gifter_schema_version)
  expect_identical(.gifter_supported_schema_versions, c(7L, 8L))
  expect_silent({
    connection <- gifter_db_connect()
    DBI::dbDisconnect(connection)
  })

  empty <- tempfile(fileext = ".sqlite")
  raw <- DBI::dbConnect(RSQLite::SQLite(), empty)
  DBI::dbDisconnect(raw)
  on.exit(unlink(empty), add = TRUE)
  expect_error(gifter_db_connect(empty), "missing database_release metadata")

  incompatible <- tempfile(fileext = ".sqlite")
  on.exit(unlink(incompatible), add = TRUE)
  expect_true(file.copy(.gifter_database_path(), incompatible))
  raw <- DBI::dbConnect(RSQLite::SQLite(), incompatible)
  DBI::dbExecute(raw, "UPDATE database_release SET schema_version = 6 WHERE release_pk = 1")
  expect_error(
    list_gifts(db = raw),
    "Unsupported gifter database schema version 6; this package supports 7, 8"
  )
  DBI::dbDisconnect(raw)
  expect_error(gifter_db_connect(incompatible), "matching gifter package")
})
