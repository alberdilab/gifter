if (!exists("gifter_db_version", mode = "function")) {
  devtools::load_all(testthat::test_path("..", ".."), quiet = TRUE)
}
source(testthat::test_path("..", "..", "manuscript", "analysis", "_prospective.R"))

prospective_fixture <- function(path, database_version = gifter_db_version()$gifter_db_version[[1L]],
                                locked_at = "2026-10-01T12:00Z", target_layer = "gift",
                                target_id = "purine_core_biosynthesis") {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  studies <- data.frame(
    study_id = "specificity_fixture",
    status = "locked",
    priority = "specificity",
    target_layer = target_layer,
    target_id = target_id,
    claim = "fixture only: a curated metabolic capability",
    assay_endpoint = "fixture endpoint",
    crosswalk_relation = "equivalent",
    selection_rule = "fixture selected before evaluation",
    exclusion_rule = "fixture has no exclusions",
    annotation_pipeline = "fixture annotator",
    annotation_version = "1.0",
    database_version = database_version,
    locked_at_utc = locked_at,
    stringsAsFactors = FALSE
  )
  samples <- data.frame(
    sample_id = "fixture_sample",
    study_id = "specificity_fixture",
    strain_id = "fixture strain",
    assembly_accession = "GCF_000000000.1",
    lineage = "Fixturelineage example",
    genome_role = "isolate",
    paired_sample_id = "",
    marker_evidence_class = "specific_evidence",
    marker_evidence_method = "fixture sequence review",
    marker_evidence_reference = "fixture record",
    stringsAsFactors = FALSE
  )
  annotations <- data.frame(
    sample_id = "fixture_sample", gene_id = "fixture_gene", namespace = "KO", accession = "K01939",
    stringsAsFactors = FALSE
  )
  observations <- data.frame(
    observation_id = "fixture_observation",
    sample_id = "fixture_sample",
    biological_replicate = "1",
    assayed_at_utc = "2026-10-02T12:00Z",
    observed = "positive",
    assay_conditions = "fixture assay conditions",
    assay_reference = "fixture raw record",
    baseline_medium = "not_applicable",
    omitted_nutrient = "not_applicable",
    rescue_observed = "not_applicable",
    stringsAsFactors = FALSE
  )
  paths <- file.path(path, c("studies.tsv", "samples.tsv", "annotations.tsv", "observations.tsv"))
  for (i in seq_along(paths)) {
    utils::write.table(list(studies, samples, annotations, observations)[[i]], paths[[i]],
                       sep = "\t", quote = FALSE, row.names = FALSE, na = "")
  }
  stats::setNames(paths, c("studies", "samples", "annotations", "observations"))
}

test_that("prospective validation keeps a locked assay, annotation and trace together", {
  paths <- prospective_fixture(tempfile("prospective-validation-"))
  inputs <- prospective_read_inputs(
    paths[["studies"]], paths[["samples"]], paths[["annotations"]], paths[["observations"]]
  )
  result <- prospective_evaluate(inputs)

  expect_equal(nrow(result$report), 1L)
  expect_equal(result$report$study_id, "specificity_fixture")
  expect_equal(result$report$database_version_evaluated, gifter_db_version()$gifter_db_version)
  expect_equal(result$summary$observed_positive_n, 1L)
  expect_equal(result$summary$observed_positive_unsupported, 1L)
  expect_gt(nrow(result$gift_trace), 0L)
  expect_false(any(tolower(names(result$summary)) %in% c("accuracy", "precision", "f1", "auc")))

  output <- tempfile("prospective-output-")
  paths_written <- prospective_write_outputs(result, output)
  expect_true(all(file.exists(paths_written)))
})

test_that("prospective validation refuses an unpinned database or pilot observation", {
  paths <- prospective_fixture(tempfile("prospective-validation-version-"),
                               database_version = "not-the-open-database")
  expect_error(
    prospective_read_inputs(paths[["studies"]], paths[["samples"]],
                            paths[["annotations"]], paths[["observations"]]),
    "pins database version"
  )

  paths <- prospective_fixture(tempfile("prospective-validation-pilot-"),
                               locked_at = "2026-10-03T12:00Z")
  expect_error(
    prospective_read_inputs(paths[["studies"]], paths[["samples"]],
                            paths[["annotations"]], paths[["observations"]]),
    "predate their locked protocol"
  )
})

test_that("prospective validation keeps reaction observations separate from GIFT traces", {
  paths <- prospective_fixture(
    tempfile("prospective-validation-reaction-"),
    target_layer = "reaction", target_id = "RHEA:15753"
  )
  result <- prospective_evaluate(prospective_read_inputs(
    paths[["studies"]], paths[["samples"]], paths[["annotations"]], paths[["observations"]]
  ))

  expect_true(result$report$call_supported)
  expect_gt(nrow(result$reaction_trace), 0L)
  expect_equal(nrow(result$gift_trace), 0L)
})
