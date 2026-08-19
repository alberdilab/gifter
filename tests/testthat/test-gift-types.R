# The typed-GIFT contract. A GIFT is an umbrella concept: `gift_type` decides
# which completeness model produces a call, which source tables may attach to
# the GIFT, and what a positive call is allowed to mean.

test_that("every GIFT curated before the typed migration is metabolic", {
  gifts <- list_gifts()
  metabolic <- gifts$gift_id[gifts$gift_type == "metabolic"]

  # The 29 GIFTs that existed at schema version 5. None of them may silently
  # change type, because the type is what the evaluator dispatches on. Later
  # metabolic content is allowed to join them, so this is containment rather
  # than equality; what it protects is that none of the original 29 leaves.
  expect_true(all(
    c(
      "adenylate_biosynthesis", "arabinose_degradation", "arabinose_uptake_abc",
      "arabinoxylan_debranching", "aspartate_semialdehyde_biosynthesis",
      "collagen_cleavage", "cysteine_biosynthesis_homocysteine",
      "cysteine_biosynthesis_sulfide", "cytidylate_biosynthesis",
      "fucose_degradation_isomerase", "galactose_degradation_leloir",
      "galacturonate_degradation", "glcnac_degradation", "glucuronate_degradation",
      "glycine_biosynthesis", "guanylate_biosynthesis", "homoserine_biosynthesis",
      "methionine_biosynthesis_sulfhydrylation",
      "methionine_biosynthesis_transsulfuration", "neuac_degradation",
      "purine_core_biosynthesis", "pyrimidine_core_biosynthesis",
      "rhamnose_degradation", "serine_biosynthesis", "starch_degradation",
      "threonine_biosynthesis", "xylan_degradation", "xylose_degradation_isomerase",
      "xylose_uptake_abc"
    ) %in% metabolic
  ))
  expect_true(all(gifts$gift_type %in% c("metabolic", "structural", "regulatory", "defense")))
})

test_that("gift_type reaches the browsing API and the call summary", {
  expect_true("gift_type" %in% names(list_gifts()))
  expect_equal(get_gift("flagellar_apparatus")$gift_type, "structural")
  expect_equal(get_gift("purine_core_biosynthesis")$gift_type, "metabolic")

  expect_setequal(list_gifts(type = "structural")$gift_id,
                  c("flagellar_apparatus", "type_iva_pilus"))
  expect_setequal(
    list_gifts(type = "defense")$gift_id,
    c(
      "type_i_restriction_modification", "type_i_e_crispr_cas_machinery",
      "mercury_detoxification"
    )
  )
  expect_equal(nrow(list_gifts(type = "regulatory")), 3L)
  expect_equal(
    nrow(list_gifts(type = c("metabolic", "structural", "regulatory", "defense"))),
    nrow(list_gifts())
  )
  expect_error(list_gifts(type = "phenotypic"), "should be one of")

  result <- evaluate_gifts(character())
  expect_true("gift_type" %in% names(result$gifts))
  expect_setequal(
    unique(result$gifts$gift_type),
    c("metabolic", "structural", "regulatory", "defense")
  )
})

test_that("an unknown or missing gift_type is rejected", {
  source_dir <- giftr_source_copy()
  gifts <- read_source(source_dir, "gifts")
  gifts$gift_type[gifts$gift_id == "glycine_biosynthesis"] <- "phenotypic"
  write_source(source_dir, "gifts", gifts)
  expect_error(validate_giftr_sources(source_dir), "Invalid gifts.gift_type")

  source_dir <- giftr_source_copy()
  gifts <- read_source(source_dir, "gifts")
  gifts$gift_type[gifts$gift_id == "glycine_biosynthesis"] <- NA_character_
  write_source(source_dir, "gifts", gifts)
  expect_error(validate_giftr_sources(source_dir), "gift_type must be recorded")
})

test_that("mode belongs to the metabolic model only", {
  source_dir <- giftr_source_copy()
  gifts <- read_source(source_dir, "gifts")
  gifts$mode[gifts$gift_id == "flagellar_apparatus"] <- "anabolic"
  write_source(source_dir, "gifts", gifts)
  expect_error(validate_giftr_sources(source_dir), "mode applies to metabolic GIFTs only")

  source_dir <- giftr_source_copy()
  gifts <- read_source(source_dir, "gifts")
  gifts$mode[gifts$gift_id == "glycine_biosynthesis"] <- NA_character_
  write_source(source_dir, "gifts", gifts)
  expect_error(validate_giftr_sources(source_dir), "Every metabolic GIFT needs a mode")
})

test_that("a structural GIFT may not borrow the metabolic anchor and route model", {
  # The point of the type is that a flagellum has no molecular boundaries. A
  # structural GIFT that declared them would be inventing anchors to satisfy a
  # schema rather than describing a structure.
  source_dir <- giftr_source_copy()
  append_source(
    source_dir, "gift_anchors",
    gift_id = "flagellar_apparatus", anchor_id = "PRPP", role = "input", ordinal = "1"
  )
  expect_error(
    validate_giftr_sources(source_dir),
    "gift_anchors describes the metabolic model"
  )

  source_dir <- giftr_source_copy()
  append_source(
    source_dir, "gift_routes",
    route_id = "FAKE_ROUTE", gift_id = "flagellar_apparatus", name = "fake",
    description = "fake", status = "curated", oxygen_requirement = "independent"
  )
  append_source(
    source_dir, "route_reactions",
    route_id = "FAKE_ROUTE", reaction_id = "RHEA:14905", orientation = "forward",
    step_order = "1", required = "1"
  )
  expect_error(
    validate_giftr_sources(source_dir),
    "gift_routes describes the metabolic model"
  )
})

test_that("typed source rows cannot be attached to the wrong GIFT type", {
  source_dir <- giftr_source_copy()
  architectures <- read_source(source_dir, "gift_architectures")
  architectures$gift_id[architectures$architecture_id == "ARCH_T4AP_CORE"] <-
    "purine_core_biosynthesis"
  write_source(source_dir, "gift_architectures", architectures)
  expect_error(
    validate_giftr_sources(source_dir),
    "gift_architectures describes the structural model"
  )
})

test_that("a GIFT of a machinery type needs an implementation", {
  source_dir <- giftr_source_copy()
  append_source(
    source_dir, "gifts",
    gift_id = "empty_structure", gift_type = "structural", name = "empty",
    description = "No architecture.", mode = NA_character_, status = "draft",
    version = "1"
  )
  append_source(
    source_dir, "gift_facets",
    gift_id = "empty_structure", facet = "structural_class",
    value = "cell_surface_appendage"
  )
  expect_error(
    validate_giftr_sources(source_dir),
    "Every structural GIFT needs at least one architecture"
  )
})

test_that("required facets are scoped by GIFT type", {
  # A substrate class answers a question about chemistry, which a structural
  # GIFT does not have; a structural class answers one about what is built, and
  # each of the other types has its own single-valued class facet.
  expect_equal(get_facets("flagellar_apparatus")$facet, "structural_class")
  expect_false("substrate_class" %in% get_facets("type_iva_pilus")$facet)
  expect_equal(get_facets("chemotaxis_signal_transduction")$facet, "regulatory_class")
  expect_equal(get_facets("type_i_restriction_modification")$facet, "defense_class")

  # Each class facet partitions its own type.
  for (type in c("metabolic", "structural", "regulatory", "defense")) {
    facet <- giftr:::.giftr_required_gift_facets[[type]]$single
    of_type <- list_gifts(type = type)$gift_id
    values <- vapply(of_type, function(id) {
      assigned <- get_facets(id)
      assigned$value[assigned$facet == facet]
    }, character(1))
    expect_equal(length(values), length(of_type))
  }

  source_dir <- giftr_source_copy()
  facets <- read_source(source_dir, "gift_facets")
  facets <- facets[facets$gift_id != "flagellar_apparatus", , drop = FALSE]
  write_source(source_dir, "gift_facets", facets)
  expect_error(
    validate_giftr_sources(source_dir),
    "Every structural GIFT needs one structural_class"
  )

  source_dir <- giftr_source_copy()
  append_source(
    source_dir, "gift_facets",
    gift_id = "flagellar_apparatus", facet = "substrate_class", value = "protein"
  )
  expect_error(
    validate_giftr_sources(source_dir),
    "carries a facet required of another GIFT type"
  )
})

test_that("identifiers stay unique across the typed models", {
  # A trace prints a component identifier without saying which table it came
  # from, so the same identifier may not mean two different things.
  source_dir <- giftr_source_copy()
  components <- read_source(source_dir, "structural_components")
  components$component_id[[1]] <- "COMP_15753_CATALYTIC"
  write_source(source_dir, "structural_components", components)
  markers <- read_source(source_dir, "structural_component_markers")
  markers$component_id[markers$component_id == "COMP_SF_FLHA"] <- "COMP_15753_CATALYTIC"
  write_source(source_dir, "structural_component_markers", markers)
  expect_error(
    validate_giftr_sources(source_dir),
    "component identifier is used by more than one GIFT model"
  )
})

test_that("one evaluation call covers a mixed-type database", {
  markers <- c(
    direct_purine_markers(include_amp = TRUE),
    # Enough of the flagellar machinery for the monoderm architecture.
    "K02400", "K02401", "K02419", "K02420", "K02421", "K02412", "K02411",
    "K02409", "K02408", "K02387", "K02388", "K02391", "K02392", "K02410",
    "K02416", "K02417", "K02390", "K02396", "K02397", "K02406", "K02407",
    "K02556", "K02557",
    # Core chemotaxis, and a type I restriction-modification system.
    "K03406", "K03407", "K03408", "K03413", "K00575", "K03412",
    "K01153", "K03427", "K01154"
  )
  result <- evaluate_gifts(ko_annotations(markers))
  complete <- result$gifts[result$gifts$complete, , drop = FALSE]

  expect_true("purine_core_biosynthesis" %in% complete$gift_id)
  expect_true("flagellar_apparatus" %in% complete$gift_id)
  expect_true("chemotaxis_signal_transduction" %in% complete$gift_id)
  expect_true("type_i_restriction_modification" %in% complete$gift_id)
  expect_setequal(
    unique(complete$gift_type),
    c("metabolic", "structural", "regulatory", "defense")
  )

  # Both types answer the same type-neutral questions.
  purine <- result$gifts[result$gifts$gift_id == "purine_core_biosynthesis", ]
  flagellum <- result$gifts[result$gifts$gift_id == "flagellar_apparatus", ]
  expect_equal(purine$best_implementation, purine$best_route)
  expect_equal(flagellum$best_implementation, "ARCH_FLAGELLUM_MONODERM")
  expect_equal(flagellum$minimum_missing_requirements, 0L)
  expect_true(length(flagellum$supporting_genes[[1]]) > 0L)
  expect_equal(flagellum$evidence_confidence, "curated")
})

test_that("the metabolic model is unchanged by the presence of other types", {
  # Compile a database from which the structural content has been removed and
  # compare it with the shipped one. Any drift in a metabolic call or trace
  # caused by the migration shows up here rather than in a reviewer's memory.
  source_dir <- giftr_source_copy()
  non_metabolic <- list_gifts()$gift_id[list_gifts()$gift_type != "metabolic"]
  gifts <- read_source(source_dir, "gifts")
  write_source(source_dir, "gifts", gifts[!gifts$gift_id %in% non_metabolic, , drop = FALSE])
  for (table in c("gift_facets", "gift_xrefs", "change_gifts")) {
    rows <- read_source(source_dir, table)
    write_source(source_dir, table, rows[!rows$gift_id %in% non_metabolic, , drop = FALSE])
  }
  changes <- read_source(source_dir, "database_changes")
  links <- read_source(source_dir, "change_gifts")
  write_source(
    source_dir, "database_changes",
    changes[
      changes$layer %in% c("provenance", "schema") | changes$change_id %in% links$change_id,
      , drop = FALSE
    ]
  )
  for (model in giftr:::.giftr_machinery_models) {
    for (table in c(
      model$implementation_source, model$membership_source, model$function_source,
      model$system_source, model$component_source, model$evidence_source
    )) {
      rows <- read_source(source_dir, table)
      write_source(source_dir, table, rows[0, , drop = FALSE])
    }
  }

  metabolic_only <- build_test_database(source_dir)
  markers <- ko_annotations(c(
    direct_purine_markers(include_amp = TRUE), complex_pyrimidine_markers(),
    "K00088", "K01951", "K01937"
  ))
  reference <- evaluate_gifts(markers, db = metabolic_only)
  shipped <- evaluate_gifts(markers)

  columns <- c(
    "gift_id", "complete", "number_of_complete_routes", "best_route",
    "minimum_missing_reactions", "route_score"
  )
  shipped_metabolic <- shipped$gifts[shipped$gifts$gift_type == "metabolic", columns]
  expect_equal(as.data.frame(shipped_metabolic), as.data.frame(reference$gifts[columns]))
  expect_equal(
    shipped$gifts$missing_reactions_best_route[shipped$gifts$gift_type == "metabolic"],
    reference$gifts$missing_reactions_best_route
  )
  expect_equal(
    shipped$gifts$supporting_markers[shipped$gifts$gift_type == "metabolic"],
    reference$gifts$supporting_markers
  )

  for (gift_id in reference$gifts$gift_id) {
    expect_equal(
      as.data.frame(trace_gift(shipped, gift_id)),
      as.data.frame(trace_gift(reference, gift_id)),
      info = gift_id
    )
  }

  # Anchor-derived topology and the derived profile are unchanged too.
  expect_equal(
    as.data.frame(gift_graph()),
    as.data.frame(gift_graph(db = metabolic_only))
  )
  expect_equal(
    as.data.frame(gift_profile()),
    as.data.frame(gift_profile(db = metabolic_only))
  )
})
