# Named reference frames are curated analytical metadata. These tests protect
# the distinction between a metadata query and a stored GIFT list, the bounded
# denominator claim, and the ability to use the same preset for genome and
# community metrics without changing any underlying call.

test_that("named reference frames are discoverable and non-empty", {
  presets <- list_reference_frames()
  expect_s3_class(presets, "tbl_df")
  expect_equal(nrow(presets), 19L)
  expect_true(all(presets$member_count > 0L))
  expect_true(all(nzchar(presets$filter_expression)))
  expect_true(all(nzchar(presets$recommended_metrics)))
  expect_true(all(nzchar(presets$interpretation)))
  expect_setequal(
    presets$frame_id[presets$bounded],
    c(
      "biomass_essential_anabolism", "amino_acid_autonomy",
      "nucleotide_autonomy", "cofactor_autonomy"
    )
  )
})

test_that("the carbohydrate preset is resolved from current curated metadata", {
  frame <- reference_frame(preset = "carbohydrate_degradation")
  expect_s3_class(frame, "gifter_frame")
  expect_identical(frame$preset, "carbohydrate_degradation")
  expect_false(frame$bounded)
  expect_setequal(
    frame$gift_id,
    c(
      "arabinose_degradation", "arabinoxylan_debranching",
      "chitin_degradation",
      "fucose_degradation_isomerase", "galactose_degradation_leloir",
      "galacturonate_degradation", "glcnac_degradation",
      "glucuronate_degradation",
      "mucin_fucose_release", "mucin_galnac_release",
      "mucin_sialic_acid_release", "neuac_degradation",
      "pectate_lyase_degradation", "pectin_degradation",
      "rhamnose_degradation", "starch_degradation",
      "xylan_degradation", "xylose_degradation_isomerase"
    )
  )
  gifts <- list_gifts()
  facets <- do.call(rbind, lapply(frame$gift_id, get_facets))
  expect_true(all(
    gifts$mode[match(frame$gift_id, gifts$gift_id)] == "catabolic"
  ))
  classes <- facets$value[facets$facet == "substrate_class"]
  expect_true(all(classes %in% c(
    "polysaccharide", "monosaccharide", "amino_sugar", "uronate"
  )))
})

test_that("preset boundedness cannot be widened at runtime", {
  bounded <- reference_frame(preset = "biomass_essential_anabolism")
  expect_true(bounded$bounded)
  expect_equal(length(bounded$gift_id), 44L)

  expect_error(
    reference_frame(preset = "carbohydrate_degradation", bounded = TRUE),
    "cannot be promoted"
  )
  expect_error(
    reference_frame(preset = "carbohydrate_degradation", mode = "catabolic"),
    "cannot be combined"
  )
  expect_error(reference_frame(preset = "not_a_preset"), "Unknown reference-frame")
})

test_that("preset metadata recommends only real outputs at the proper scope", {
  carbohydrate <- reference_frame(preset = "carbohydrate_degradation")
  expect_setequal(
    carbohydrate$recommended_metrics$metric_id,
    c(
      "gift_richness", "breadth_substrate_class", "community_richness",
      "provider_count", "abundance_coverage"
    )
  )
  open <- list_reference_frames()
  expect_false(any(grepl(
    "supported_fraction|community_coverage",
    open$recommended_metrics[!open$bounded]
  )))
})

test_that("one preset drives both genome and community metrics", {
  frame <- reference_frame(preset = "plant_fibre_utilisation")
  genome <- arabinoxylan_genome("consumer")
  genome_result <- genome_traits(
    genome, frames = list(frame), genome_id = "consumer"
  )
  richness <- genome_result$metrics[
    genome_result$metrics$metric_id == "gift_richness", , drop = FALSE
  ]
  expect_equal(richness$value, 2)
  expect_identical(richness$reference_frame, "Plant fibre utilisation")

  community_result <- community_traits(
    arabinoxylan_community(), frames = list(frame)
  )
  community_richness <- community_result$metrics[
    community_result$metrics$metric_id == "community_richness", , drop = FALSE
  ]
  expect_equal(community_richness$value, 4)
  expect_identical(
    community_richness$reference_frame, "Plant fibre utilisation"
  )
})

test_that("source validation rejects invalid named-frame metadata", {
  source_dir <- system.file("extdata", "database-source", package = "gifter")
  fixture <- tempfile("gifter-frame-source-")
  dir.create(fixture)
  on.exit(unlink(fixture, recursive = TRUE), add = TRUE)
  expect_true(all(file.copy(list.files(source_dir, full.names = TRUE), fixture)))

  path <- file.path(fixture, "reference_frame_filters.tsv")
  filters <- utils::read.delim(path, sep = "\t", check.names = FALSE)
  filters$value[filters$frame_id == "carbohydrate_degradation" &
                  filters$filter_key == "mode"] <- "photosynthetic"
  utils::write.table(
    filters, path, sep = "\t", quote = FALSE, row.names = FALSE, na = ""
  )

  report <- validate_gifter_sources(fixture, stop_on_error = FALSE)
  expect_false(report$valid)
  expect_true(any(grepl(
    "Invalid mode reference-frame filter value", report$errors, fixed = TRUE
  )))
})
