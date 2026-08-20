# The structural completeness model.
#
# A structural GIFT claims that a genome encodes the machinery required to build
# a defined cellular structure. It is complete when at least one curated
# architecture has every required structural function supported. The Boolean
# layers are tested first on synthetic fixtures, so that the contract does not
# depend on any particular curated biology, and then on the curated flagellar
# and type IVa pilus content.

structural_fixture_db <- function(envir = parent.frame()) {
  source_dir <- gifter_source_copy(envir)
  add_structural_fixture(source_dir)
  build_test_database(source_dir, envir)
}

fixture_markers <- function(...) {
  markers <- c(...)
  data.frame(
    gene_id = paste0("gene_", seq_along(markers)), namespace = "KO",
    accession = markers, stringsAsFactors = FALSE
  )
}

test_that("a structural GIFT is complete when every required function is supported", {
  db <- structural_fixture_db()
  result <- evaluate_gifts(fixture_markers("K90001", "K90002"), db = db)
  gift <- result$gifts[result$gifts$gift_id == "fixture_structure", ]

  expect_equal(gift$gift_type, "structural")
  expect_true(gift$complete)
  expect_equal(gift$best_implementation, "ARCH_FIXTURE")
  expect_equal(gift$minimum_missing_requirements, 0L)
  expect_equal(gift$completeness_score, 1)

  # The structural view reports the same call in structural vocabulary.
  structural <- result$structural$gifts[result$structural$gifts$gift_id == "fixture_structure", ]
  expect_equal(structural$best_architecture, "ARCH_FIXTURE")
  expect_equal(structural$minimum_missing_functions, 0L)
  expect_equal(structural$missing_functions_best_architecture[[1]], character())
  expect_setequal(
    structural$supporting_functions[[1]],
    c("SF_FIXTURE_STRUCTURE_CORE", "SF_FIXTURE_STRUCTURE_ANCHORPOINT")
  )
})

test_that("every required structural function is jointly needed", {
  db <- structural_fixture_db()
  result <- evaluate_gifts(fixture_markers("K90001"), db = db)
  gift <- result$gifts[result$gifts$gift_id == "fixture_structure", ]
  structural <- result$structural$gifts[result$structural$gifts$gift_id == "fixture_structure", ]

  expect_false(gift$complete)
  # An incomplete structural call names the missing function, exactly as an
  # incomplete metabolic call names the missing reaction. It is never a
  # percentage of expected genes.
  expect_equal(structural$minimum_missing_functions, 1L)
  expect_equal(
    structural$missing_functions_best_architecture[[1]],
    "SF_FIXTURE_STRUCTURE_ANCHORPOINT"
  )
  expect_equal(structural$best_architecture, "ARCH_FIXTURE")
})

test_that("alternative systems satisfy the same structural function", {
  db <- structural_fixture_db()
  simple <- evaluate_gifts(fixture_markers("K90001", "K90002"), db = db)
  complex <- evaluate_gifts(fixture_markers("K90001", "K90003", "K90004"), db = db)

  expect_true(simple$gifts$complete[simple$gifts$gift_id == "fixture_structure"])
  expect_true(complex$gifts$complete[complex$gifts$gift_id == "fixture_structure"])

  functions <- complex$structural$functions
  anchorpoint <- functions[functions$function_id == "SF_FIXTURE_STRUCTURE_ANCHORPOINT", ]
  expect_true(anchorpoint$supported)
  expect_equal(anchorpoint$number_of_complete_systems, 1L)
  expect_equal(anchorpoint$best_system, "SYS_FIXTURE_STRUCTURE_COMPLEX")
})

test_that("a multisubunit structural system fails when a component is missing", {
  db <- structural_fixture_db()
  result <- evaluate_gifts(fixture_markers("K90001", "K90003"), db = db)
  systems <- result$structural$systems
  complex <- systems[systems$system_id == "SYS_FIXTURE_STRUCTURE_COMPLEX", ]

  expect_false(complex$supported)
  expect_equal(complex$required_components, 2L)
  expect_equal(complex$missing_components[[1]], "COMP_FIXTURE_STRUCTURE_BETA")
  expect_false(result$gifts$complete[result$gifts$gift_id == "fixture_structure"])
})

test_that("alternative architectures complete independently and deterministically", {
  source_dir <- gifter_source_copy()
  # Two architectures of one structure that share a function and differ in a
  # second: the structural analogue of alternative routes.
  add_test_machinery_gift(
    source_dir, "two_way_structure", "structural", "ARCH_TWO_WAY_ALPHA",
    list(
      list(id = "SF_TWO_WAY_SHARED", systems = list(
        list(id = "SYS_TWO_WAY_SHARED", components = list(
          list(id = "COMP_TWO_WAY_SHARED", markers = "KO:K91001")
        ))
      )),
      list(id = "SF_TWO_WAY_ALPHA", systems = list(
        list(id = "SYS_TWO_WAY_ALPHA", components = list(
          list(id = "COMP_TWO_WAY_ALPHA", markers = "KO:K91002")
        ))
      ))
    )
  )
  # The second architecture reuses the shared function rather than copying it.
  implementations <- read_source(source_dir, "gift_architectures")
  write_source(source_dir, "gift_architectures", rbind(
    implementations,
    data.frame(
      architecture_id = "ARCH_TWO_WAY_BETA", gift_id = "two_way_structure",
      name = "beta", description = "Second architecture.", status = "curated",
      stringsAsFactors = FALSE
    )[names(implementations)]
  ))
  append_source(
    source_dir, "structural_functions",
    function_id = "SF_TWO_WAY_BETA", name = "beta function",
    description = "Fixture function."
  )
  append_source(
    source_dir, "structural_systems",
    system_id = "SYS_TWO_WAY_BETA", function_id = "SF_TWO_WAY_BETA",
    name = "beta", description = "Fixture system."
  )
  append_source(
    source_dir, "structural_components",
    component_id = "COMP_TWO_WAY_BETA", system_id = "SYS_TWO_WAY_BETA",
    name = "beta", description = "Fixture component."
  )
  add_test_marker(source_dir, "KO", "K91003")
  append_rows(source_dir, "structural_component_markers", data.frame(
    component_id = "COMP_TWO_WAY_BETA", namespace = "KO", accession = "K91003",
    evidence_type = "orthology", confidence = "curated",
    source = "Synthetic fixture", stringsAsFactors = FALSE
  ))
  append_source(
    source_dir, "architecture_functions",
    architecture_id = "ARCH_TWO_WAY_BETA",
    function_id = c("SF_TWO_WAY_SHARED", "SF_TWO_WAY_BETA"),
    ordinal = c("1", "2"), required = c("1", "1")
  )
  db <- build_test_database(source_dir)

  alpha <- evaluate_gifts(fixture_markers("K91001", "K91002"), db = db)
  beta <- evaluate_gifts(fixture_markers("K91001", "K91003"), db = db)
  both <- evaluate_gifts(fixture_markers("K91001", "K91002", "K91003"), db = db)
  call <- function(result) result$structural$gifts[
    result$structural$gifts$gift_id == "two_way_structure",
  ]

  expect_true(call(alpha)$complete)
  expect_equal(call(alpha)$best_architecture, "ARCH_TWO_WAY_ALPHA")
  expect_true(call(beta)$complete)
  expect_equal(call(beta)$best_architecture, "ARCH_TWO_WAY_BETA")
  expect_equal(call(both)$number_of_complete_architectures, 2L)
  # Ties are broken by identifier, so the reported architecture never depends
  # on row order in the source tables.
  expect_equal(call(both)$best_architecture, "ARCH_TWO_WAY_ALPHA")

  # The shared function is curated once and serves both architectures.
  membership <- both$structural$architecture_functions
  expect_equal(
    sort(membership$architecture_id[membership$function_id == "SF_TWO_WAY_SHARED"]),
    c("ARCH_TWO_WAY_ALPHA", "ARCH_TWO_WAY_BETA")
  )
})

test_that("an accessory function does not determine completeness", {
  source_dir <- gifter_source_copy()
  add_test_machinery_gift(
    source_dir, "accessory_structure", "structural", "ARCH_ACCESSORY",
    list(
      list(id = "SF_ACCESSORY_CORE", required = TRUE, systems = list(
        list(id = "SYS_ACCESSORY_CORE", components = list(
          list(id = "COMP_ACCESSORY_CORE", markers = "KO:K92001")
        ))
      )),
      list(id = "SF_ACCESSORY_EXTRA", required = FALSE, systems = list(
        list(id = "SYS_ACCESSORY_EXTRA", components = list(
          list(id = "COMP_ACCESSORY_EXTRA", markers = "KO:K92002")
        ))
      ))
    )
  )
  db <- build_test_database(source_dir)

  without <- evaluate_gifts(fixture_markers("K92001"), db = db)
  gift <- without$structural$gifts[
    without$structural$gifts$gift_id == "accessory_structure",
  ]
  expect_true(gift$complete)
  expect_equal(gift$minimum_missing_functions, 0L)
  # The accessory function is still visible as unsupported; it simply does not
  # enter the call.
  functions <- without$structural$functions
  expect_false(functions$supported[functions$function_id == "SF_ACCESSORY_EXTRA"])

  # An implementation whose functions are all accessory could never be
  # defensibly complete, so the build refuses it.
  source_dir <- gifter_source_copy()
  add_test_machinery_gift(
    source_dir, "all_accessory", "structural", "ARCH_ALL_ACCESSORY",
    list(
      list(id = "SF_ALL_ACCESSORY", required = FALSE, systems = list(
        list(id = "SYS_ALL_ACCESSORY", components = list(
          list(id = "COMP_ALL_ACCESSORY", markers = "KO:K92003")
        ))
      ))
    )
  )
  expect_error(
    validate_gifter_sources(source_dir),
    "ARCH_ALL_ACCESSORY has no required structural function"
  )
})

test_that("a structural call traces back to markers and genes", {
  db <- structural_fixture_db()
  result <- evaluate_gifts(fixture_markers("K90001", "K90002"), db = db)
  trace <- trace_gift(result, "fixture_structure")

  expect_equal(unique(trace$architecture_id), "ARCH_FIXTURE")
  expect_true(all(trace$architecture_complete))
  expect_equal(trace$ordinal, c(1L, 2L))
  expect_true(all(trace$required))
  expect_true(all(trace$function_supported))
  expect_true(all(trace$component_supported))
  expect_equal(trace$accession, c("K90001", "K90002"))
  expect_true(all(!is.na(trace$gene_id)))
  expect_equal(trace$gift_type, rep("structural", 2L))

  # A named architecture that does not belong to the GIFT is an error, and the
  # metabolic argument is refused rather than silently ignored.
  expect_error(trace_gift(result, "fixture_structure", implementation = "ARCH_T4AP_CORE"),
               "architecture does not belong to gift")
  expect_error(trace_gift(result, "fixture_structure", route_id = "AMP_ADENYLOSUCCINATE"),
               "route_id traces a metabolic GIFT")
  expect_error(trace_gift(result, "purine_core_biosynthesis", implementation = "ARCH_FIXTURE"),
               "implementation traces a non-metabolic GIFT")
})

# ---------------------------------------------------------------------------
# Curated structural content
# ---------------------------------------------------------------------------

flagellar_core_markers <- function() {
  c(
    "K02400", "K02401", "K02419", "K02420", "K02421",  # export gate
    "K02412", "K02411",                                 # export ATPase
    "K02409",                                           # MS ring
    "K02408", "K02387", "K02388", "K02391", "K02392",   # rod
    "K02410", "K02416", "K02417",                       # C ring
    "K02390",                                           # hook
    "K02396", "K02397",                                 # hook-filament junction
    "K02406", "K02407",                                 # filament
    "K02556", "K02557"                                  # stator
  )
}

type_iva_pilus_markers <- function() {
  c("K02654", "K02650", "K02652", "K02653", "K02662", "K02663", "K02664",
    "K02665", "K02666")
}

test_that("the diderm and monoderm flagellar architectures share their machinery", {
  machinery <- get_gift_machinery("flagellar_apparatus")
  by_architecture <- split(unique(machinery[c("architecture_id", "function_id")]),
                           unique(machinery[c("architecture_id", "function_id")])$architecture_id)
  diderm <- by_architecture$ARCH_FLAGELLUM_DIDERM$function_id
  monoderm <- by_architecture$ARCH_FLAGELLUM_MONODERM$function_id

  # The monoderm flagellum is the diderm one without the envelope bushings.
  expect_setequal(setdiff(diderm, monoderm), "SF_FLAGELLAR_OUTER_RING")
  expect_equal(length(setdiff(monoderm, diderm)), 0L)
  # Shared functions are curated once, not duplicated per architecture.
  expect_equal(length(unique(machinery$function_id)), length(diderm))
})

test_that("a diderm flagellar genome completes both architectures", {
  result <- evaluate_gifts(ko_annotations(c(flagellar_core_markers(), "K02393", "K02394")))
  gift <- result$structural$gifts[result$structural$gifts$gift_id == "flagellar_apparatus", ]

  expect_true(gift$complete)
  expect_equal(gift$number_of_complete_architectures, 2L)
  expect_equal(gift$best_architecture, "ARCH_FLAGELLUM_DIDERM")
  expect_equal(gift$minimum_missing_functions, 0L)
})

test_that("a monoderm flagellar genome completes without L and P rings", {
  result <- evaluate_gifts(ko_annotations(flagellar_core_markers()))
  gift <- result$structural$gifts[result$structural$gifts$gift_id == "flagellar_apparatus", ]

  expect_true(gift$complete)
  expect_equal(gift$number_of_complete_architectures, 1L)
  expect_equal(gift$best_architecture, "ARCH_FLAGELLUM_MONODERM")
  # The diderm architecture is reported as one function short, not as a
  # fraction of missing genes.
  implementations <- result$structural$architectures
  diderm <- implementations[implementations$architecture_id == "ARCH_FLAGELLUM_DIDERM", ]
  expect_false(diderm$complete)
  expect_equal(diderm$missing_functions[[1]], "SF_FLAGELLAR_OUTER_RING")
})

test_that("a missing flagellar function is reported, not scored away", {
  # Remove the stator: the genome encodes an axial structure it cannot turn.
  markers <- setdiff(flagellar_core_markers(), c("K02556", "K02557"))
  result <- evaluate_gifts(ko_annotations(markers))
  gift <- result$structural$gifts[result$structural$gifts$gift_id == "flagellar_apparatus", ]

  expect_false(gift$complete)
  expect_equal(gift$minimum_missing_functions, 1L)
  expect_equal(gift$missing_functions_best_architecture[[1]], "SF_FLAGELLAR_STATOR")
  expect_equal(gift$best_architecture, "ARCH_FLAGELLUM_MONODERM")
})

test_that("a fused FliR-FlhB protein supports both export gate components", {
  # K13820 is a single protein carrying two export gate roles. Each justified
  # component/marker relationship is recorded explicitly rather than collapsing
  # the two components into one.
  markers <- setdiff(flagellar_core_markers(), c("K02401", "K02421"))
  result <- evaluate_gifts(ko_annotations(c(markers, "K13820")))
  gift <- result$structural$gifts[result$structural$gifts$gift_id == "flagellar_apparatus", ]
  components <- result$structural$components

  expect_true(gift$complete)
  expect_true(components$supported[components$component_id == "COMP_SF_FLHB"])
  expect_true(components$supported[components$component_id == "COMP_SF_FLIR"])
})

test_that("flagellar evidence does not license a coupling-ion claim", {
  # KEGG assigns Vibrio PomA/PomB, a sodium-driven stator, to the same
  # orthologues as Escherichia coli MotA/MotB. The specificity of a GIFT claim
  # may not exceed the specificity of its evidence, so no proton- or
  # sodium-specific flagellar GIFT exists.
  gift_ids <- list_gifts()$gift_id
  expect_false(any(grepl("proton_driven|sodium_driven", gift_ids)))

  machinery <- get_gift_machinery("flagellar_apparatus")
  stator <- machinery[machinery$function_id == "SF_FLAGELLAR_STATOR", ]
  expect_setequal(stator$accession, c("K02556", "K02557"))
  expect_true(all(grepl("PomA|PomB", stator$notes)))

  # The refusal is recorded as a curation decision, not left implicit.
  changes <- database_changelog("flagellar_apparatus")
  expect_true("DBC-20260818-FLAGELLAR-ION-COUPLING" %in% changes$change_id)
  expect_match(
    changes$evidence[changes$change_id == "DBC-20260818-FLAGELLAR-ION-COUPLING"],
    "K02556", fixed = TRUE
  )
})

test_that("the type IVa pilus completes without its retraction ATPase", {
  # Retraction is accessory to assembling a pilus. A genome without PilT is
  # expected to build a pilus it cannot retract.
  result <- evaluate_gifts(ko_annotations(type_iva_pilus_markers()))
  gift <- result$structural$gifts[result$structural$gifts$gift_id == "type_iva_pilus", ]

  expect_true(gift$complete)
  expect_equal(gift$minimum_missing_functions, 0L)
  expect_false("SF_T4AP_RETRACTION_ATPASE" %in% gift$supporting_functions[[1]])

  with_retraction <- evaluate_gifts(ko_annotations(c(type_iva_pilus_markers(), "K02669")))
  functions <- with_retraction$structural$functions
  expect_true(functions$supported[functions$function_id == "SF_T4AP_RETRACTION_ATPASE"])
})

test_that("the type IVa alignment subcomplex is jointly required", {
  markers <- setdiff(type_iva_pilus_markers(), "K02664")
  result <- evaluate_gifts(ko_annotations(markers))
  gift <- result$structural$gifts[result$structural$gifts$gift_id == "type_iva_pilus", ]
  systems <- result$structural$systems

  expect_false(gift$complete)
  expect_equal(gift$missing_functions_best_architecture[[1]], "SF_T4AP_ALIGNMENT_COMPLEX")
  expect_equal(
    systems$missing_components[systems$system_id == "SYS_T4AP_ALIGNMENT_COMPLEX"][[1]],
    "COMP_T4AP_PILO"
  )
})

test_that("alternative assembly ATPases satisfy the same pilus function", {
  pilb <- evaluate_gifts(ko_annotations(type_iva_pilus_markers()))
  pilf <- evaluate_gifts(ko_annotations(c(
    setdiff(type_iva_pilus_markers(), "K02652"), "K02656"
  )))

  expect_true(pilb$gifts$complete[pilb$gifts$gift_id == "type_iva_pilus"])
  expect_true(pilf$gifts$complete[pilf$gifts$gift_id == "type_iva_pilus"])
  functions <- pilf$structural$functions
  expect_equal(
    functions$best_system[functions$function_id == "SF_T4AP_ASSEMBLY_ATPASE"],
    "SYS_T4AP_ASSEMBLY_ATPASE_PILF"
  )
})

test_that("a pilin marker of uncertain role weakens the call it supports", {
  # K02655 is the major pilin in Neisseria and a minor pilin in Pseudomonas, so
  # it is accepted as an alternative marker at reduced confidence rather than
  # being treated as equivalent evidence.
  curated <- evaluate_gifts(ko_annotations(type_iva_pilus_markers()))
  ambiguous <- evaluate_gifts(ko_annotations(c(
    setdiff(type_iva_pilus_markers(), "K02650"), "K02655"
  )))

  expect_equal(
    curated$gifts$evidence_confidence[curated$gifts$gift_id == "type_iva_pilus"],
    "curated"
  )
  expect_true(ambiguous$gifts$complete[ambiguous$gifts$gift_id == "type_iva_pilus"])
  expect_equal(
    ambiguous$gifts$evidence_confidence[ambiguous$gifts$gift_id == "type_iva_pilus"],
    "ambiguous"
  )
})

test_that("the structural claim stops at the encoded machinery", {
  # A structural GIFT says what a genome encodes. It does not say that the
  # structure is expressed, that the cell moves, that it takes up DNA, or that
  # it adheres to anything.
  gift_ids <- list_gifts()$gift_id
  expect_false(any(grepl(
    "motility|twitching|competence|adhesion|virulence", gift_ids
  )))
  for (gift_id in list_gifts(type = "structural")$gift_id) {
    expect_match(get_gift(gift_id)$description, "does not|it does not")
  }
})
