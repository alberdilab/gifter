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

lpt_ko_markers <- function() {
  c(
    LptA = "K09774", LptB = "K06861", LptC = "K11719", LptD = "K04744",
    LptE = "K03643", LptF = "K07091", LptG = "K11720"
  )
}

lpt_annotations <- function(markers = lpt_ko_markers()) {
  data.frame(
    gene_id = paste0("gene_", names(markers)), namespace = "KO",
    accession = unname(markers), stringsAsFactors = FALSE
  )
}

ribitol_wta_common_markers <- function() {
  c(
    MnaA = "K01791", TagO = "K02851", TagA = "K05946", TagB = "K21285",
    TagD = "K00980", TarI = "K21030", TarJ = "K05352", TagG = "K09692",
    TagH = "K09693", LCP = "K01005"
  )
}

staphylococcus_ribitol_wta_annotations <- function() {
  common <- ribitol_wta_common_markers()
  rbind(
    data.frame(
      gene_id = paste0("gene_", names(common)), namespace = "KO",
      accession = unname(common), stringsAsFactors = FALSE
    ),
    data.frame(
      gene_id = c("gene_TarF", "gene_TarL"), namespace = "NCBIFAM",
      accession = c("NF041712.1", "NF041713.1"), stringsAsFactors = FALSE
    )
  )
}

w23_ribitol_wta_annotations <- function() {
  markers <- c(ribitol_wta_common_markers(), TarK = "K21592", TarL = "K18704")
  data.frame(
    gene_id = paste0("gene_", names(markers)), namespace = "KO",
    accession = unname(markers), stringsAsFactors = FALSE
  )
}

lta_glc2dag_annotations <- function() {
  markers <- c(
    YpfP = "NF010134.0", LtaA = "NF047396.1", LtaS = "NF053595.1"
  )
  data.frame(
    gene_id = paste0("gene_", names(markers)), namespace = "NCBIFAM",
    accession = unname(markers), stringsAsFactors = FALSE
  )
}

t6ss_required_markers <- function() {
  c(
    TssL = "K11892", TssM = "K11891", TssE = "K11897", TssF = "K11896",
    TssG = "K11895", TssK = "K11893", VgrG = "K11904", Hcp = "K11903",
    TssB = "K11901", TssC = "K11900", TssA = "K11902", ClpV = "K11907"
  )
}

t6ss_annotations <- function(markers = t6ss_required_markers()) {
  data.frame(
    gene_id = paste0("gene_", names(markers)), namespace = "KO",
    accession = unname(markers), stringsAsFactors = FALSE
  )
}

injectisome_required_markers <- function() {
  c(
    SctR = "K03226", SctS = "K03227", SctT = "K03228", SctU = "K03229",
    SctV = "K03230", SctN = "K03224", SctD = "K03220", SctJ = "K03222",
    SctC = "K03219", SctQ = "K03225", SctI = "K04053", SctF = "K03221"
  )
}

injectisome_annotations <- function(markers = injectisome_required_markers()) {
  data.frame(
    gene_id = paste0("gene_", names(markers)), namespace = "KO",
    accession = unname(markers), stringsAsFactors = FALSE
  )
}

flagellar_export_markers <- function() {
  c(
    FlhA = "K02400", FlhB = "K02401", FliF = "K02409", FliI = "K02412",
    FliP = "K02419", FliQ = "K02420", FliR = "K02421"
  )
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

test_that("the canonical LptA--G apparatus requires all three machine functions", {
  result <- evaluate_gifts(lpt_annotations())
  gift <- result$structural$gifts[
    result$structural$gifts$gift_id == "lpt_lipopolysaccharide_export_apparatus",
  ]

  expect_true(gift$complete)
  expect_equal(gift$best_architecture, "ARCH_LPT_CANONICAL")
  expect_equal(gift$minimum_missing_functions, 0L)
  expect_setequal(
    gift$supporting_functions[[1]],
    c(
      "SF_LPT_INNER_MEMBRANE_EXTRACTION", "SF_LPT_PERIPLASMIC_BRIDGE",
      "SF_LPT_OUTER_MEMBRANE_TRANSLOCON"
    )
  )

  machinery <- get_gift_machinery("lpt_lipopolysaccharide_export_apparatus")
  expect_equal(length(unique(machinery$architecture_id)), 1L)
  expect_equal(length(unique(machinery$function_id)), 3L)
  expect_equal(length(unique(machinery$component_id)), 7L)
  expect_true(all(machinery$required))
})

test_that("removing any LptA--G role makes the apparatus incomplete", {
  missing_function <- c(
    LptA = "SF_LPT_PERIPLASMIC_BRIDGE",
    LptB = "SF_LPT_INNER_MEMBRANE_EXTRACTION",
    LptC = "SF_LPT_INNER_MEMBRANE_EXTRACTION",
    LptD = "SF_LPT_OUTER_MEMBRANE_TRANSLOCON",
    LptE = "SF_LPT_OUTER_MEMBRANE_TRANSLOCON",
    LptF = "SF_LPT_INNER_MEMBRANE_EXTRACTION",
    LptG = "SF_LPT_INNER_MEMBRANE_EXTRACTION"
  )

  for (component in names(lpt_ko_markers())) {
    markers <- lpt_ko_markers()[names(lpt_ko_markers()) != component]
    result <- evaluate_gifts(lpt_annotations(markers))
    gift <- result$structural$gifts[
      result$structural$gifts$gift_id == "lpt_lipopolysaccharide_export_apparatus",
    ]
    expect_false(gift$complete, info = component)
    expect_equal(
      gift$missing_functions_best_architecture[[1]],
      unname(missing_function[[component]]), info = component
    )
  }
})

test_that("both Lpt permeases and both outer-membrane partners are jointly required", {
  cases <- list(
    LptF = c(system = "SYS_LPTBCFG", component = "COMP_LPTF"),
    LptG = c(system = "SYS_LPTBCFG", component = "COMP_LPTG"),
    LptD = c(system = "SYS_LPTDE", component = "COMP_LPTD"),
    LptE = c(system = "SYS_LPTDE", component = "COMP_LPTE")
  )

  for (missing in names(cases)) {
    markers <- lpt_ko_markers()[names(lpt_ko_markers()) != missing]
    systems <- evaluate_gifts(lpt_annotations(markers))$structural$systems
    system <- systems[systems$system_id == cases[[missing]][["system"]], ]
    expect_false(system$supported, info = missing)
    expect_equal(system$missing_components[[1]], cases[[missing]][["component"]],
                 info = missing)
  }
})

test_that("generic envelope evidence and broad Lpt profiles do not support Lpt", {
  unrelated <- data.frame(
    gene_id = paste0("unrelated_", 1:9),
    namespace = c(rep("KO", 4), rep("NCBIFAM", 5)),
    accession = c(
      "K02003", # generic ABC ATP-binding protein
      "K06048", # MsbA lipid A exporter
      "K07277", # BamA outer-membrane protein assembly factor
      "K02535", # LpxC lipid A precursor synthesis
      "NF015684.7", # combined LptF/LptG subfamily
      "NF015901.7", # LptA/LptD_N domain
      "NF018537.7", # LptC domain
      "NF016290.7", # LptE Pfam-equivalent profile
      "NF053613.1"  # unrelated Pseudomonas lipotoxin F
    ),
    stringsAsFactors = FALSE
  )
  result <- evaluate_gifts(unrelated)
  gift <- result$gifts[
    result$gifts$gift_id == "lpt_lipopolysaccharide_export_apparatus",
  ]

  expect_false(gift$complete)
  expect_false(any(result$structural$components$supported[
    grepl("^COMP_LPT", result$structural$components$component_id)
  ]))
  machinery <- get_gift_machinery("lpt_lipopolysaccharide_export_apparatus")
  expect_false(any(unrelated$accession %in% machinery$accession))
})

test_that("LptM and YedD are not requirements or shortcut markers", {
  result <- evaluate_gifts(lpt_annotations())
  gift <- result$gifts[
    result$gifts$gift_id == "lpt_lipopolysaccharide_export_apparatus",
  ]
  machinery <- get_gift_machinery("lpt_lipopolysaccharide_export_apparatus")

  expect_true(gift$complete)
  expect_false(any(grepl("LPTM|YEDD", toupper(paste(
    machinery$component_id, machinery$component_name
  )))))
  expect_false(any(machinery$accession %in% c("NF047847.2", "NF025353.8")))
})

test_that("Lpt evaluates beside a metabolic GIFT without changing either model", {
  annotations <- rbind(
    ko_annotations(direct_purine_markers()),
    lpt_annotations()
  )
  result <- evaluate_gifts(annotations)
  complete <- result$gifts[result$gifts$complete, ]

  expect_true("purine_core_biosynthesis" %in% complete$gift_id)
  expect_true("lpt_lipopolysaccharide_export_apparatus" %in% complete$gift_id)
  expect_equal(
    complete$gift_type[complete$gift_id == "lpt_lipopolysaccharide_export_apparatus"],
    "structural"
  )
})

test_that("the Lpt trace retains every role and observed gene", {
  annotations <- lpt_annotations()
  result <- evaluate_gifts(annotations)
  trace <- trace_gift(result, "lpt_lipopolysaccharide_export_apparatus")

  expect_equal(unique(trace$architecture_id), "ARCH_LPT_CANONICAL")
  expect_true(all(trace$architecture_complete))
  expect_setequal(trace$component_id, paste0("COMP_", toupper(names(lpt_ko_markers()))))
  expect_setequal(trace$accession, unname(lpt_ko_markers()))
  expect_setequal(trace$gene_id, annotations$gene_id)
  expect_true(all(trace$component_supported))
})

test_that("component-specific NCBIfam evidence can complete the Lpt apparatus", {
  markers <- c(
    LptA = "TIGR03002.1", LptB = "TIGR04406.1", LptC = "TIGR04409.1",
    LptD = "NF002997.0", LptE = "NF008062.1", LptF = "TIGR04407.1",
    LptG = "TIGR04408.1"
  )
  annotations <- data.frame(
    gene_id = paste0("ncbifam_", names(markers)), namespace = "NCBIFAM",
    accession = unname(markers), stringsAsFactors = FALSE
  )
  result <- evaluate_gifts(annotations)
  gift <- result$gifts[
    result$gifts$gift_id == "lpt_lipopolysaccharide_export_apparatus",
  ]

  expect_true(gift$complete)
  expect_equal(gift$evidence_confidence, "high-confidence")
  expect_setequal(
    trace_gift(result, "lpt_lipopolysaccharide_export_apparatus")$gene_id,
    annotations$gene_id
  )
})

test_that("a fused LptF/G annotation satisfies both retained permease roles", {
  annotations <- lpt_annotations(lpt_ko_markers()[1:5])
  annotations <- rbind(
    annotations,
    data.frame(
      gene_id = c("gene_LptFG", "gene_LptFG"), namespace = "KO",
      accession = c("K07091", "K11720"), stringsAsFactors = FALSE
    )
  )
  result <- evaluate_gifts(annotations)
  gift <- result$gifts[
    result$gifts$gift_id == "lpt_lipopolysaccharide_export_apparatus",
  ]
  trace <- trace_gift(result, "lpt_lipopolysaccharide_export_apparatus")

  expect_true(gift$complete)
  expect_equal(
    unique(trace$gene_id[trace$component_id %in% c("COMP_LPTF", "COMP_LPTG")]),
    "gene_LptFG"
  )
})

test_that("Lpt evaluation is deterministic under annotation order", {
  forward <- evaluate_gifts(lpt_annotations())
  reverse <- evaluate_gifts(lpt_annotations(rev(lpt_ko_markers())))
  gift_columns <- c(
    "complete", "best_architecture", "minimum_missing_functions",
    "evidence_confidence"
  )
  forward_gift <- forward$structural$gifts[
    forward$structural$gifts$gift_id == "lpt_lipopolysaccharide_export_apparatus",
    gift_columns, drop = FALSE
  ]
  reverse_gift <- reverse$structural$gifts[
    reverse$structural$gifts$gift_id == "lpt_lipopolysaccharide_export_apparatus",
    gift_columns, drop = FALSE
  ]

  expect_equal(forward_gift, reverse_gift)
  expect_equal(
    trace_gift(forward, "lpt_lipopolysaccharide_export_apparatus"),
    trace_gift(reverse, "lpt_lipopolysaccharide_export_apparatus")
  )
})

test_that("ribitol-phosphate WTA exposes two complete alternative architectures", {
  machinery <- get_gift_machinery("ribitol_phosphate_wall_teichoic_acid")
  expect_setequal(
    unique(machinery$architecture_id),
    c("ARCH_RIBITOL_WTA_STAPHYLOCOCCUS", "ARCH_RIBITOL_WTA_W23")
  )
  expect_equal(length(unique(machinery$function_id)), 8L)
  expect_equal(length(unique(machinery$system_id)), 8L)
  expect_equal(length(unique(machinery$component_id)), 14L)
  expect_true(all(machinery$required))

  by_architecture <- split(
    unique(machinery[c("architecture_id", "function_id")]),
    unique(machinery[c("architecture_id", "function_id")])$architecture_id
  )
  staph <- by_architecture$ARCH_RIBITOL_WTA_STAPHYLOCOCCUS$function_id
  w23 <- by_architecture$ARCH_RIBITOL_WTA_W23$function_id
  expect_equal(setdiff(staph, w23), "SF_RIBITOL_WTA_STAPH_POLYMERIZATION")
  expect_equal(setdiff(w23, staph), "SF_RIBITOL_WTA_W23_POLYMERIZATION")
  expect_equal(length(intersect(staph, w23)), 6L)
})

test_that("each ribitol-WTA architecture completes independently", {
  staph <- evaluate_gifts(staphylococcus_ribitol_wta_annotations())
  w23 <- evaluate_gifts(w23_ribitol_wta_annotations())
  call <- function(result) result$structural$gifts[
    result$structural$gifts$gift_id == "ribitol_phosphate_wall_teichoic_acid",
  ]

  expect_true(call(staph)$complete)
  expect_equal(call(staph)$best_architecture, "ARCH_RIBITOL_WTA_STAPHYLOCOCCUS")
  expect_equal(call(staph)$number_of_complete_architectures, 1L)
  expect_true(call(w23)$complete)
  expect_equal(call(w23)$best_architecture, "ARCH_RIBITOL_WTA_W23")
  expect_equal(call(w23)$number_of_complete_architectures, 1L)

  staph_architectures <- staph$structural$architectures
  w23_architectures <- w23$structural$architectures
  expect_false(staph_architectures$complete[
    staph_architectures$architecture_id == "ARCH_RIBITOL_WTA_W23"
  ])
  expect_false(w23_architectures$complete[
    w23_architectures$architecture_id == "ARCH_RIBITOL_WTA_STAPHYLOCOCCUS"
  ])
})

test_that("every shared ribitol-WTA role remains jointly required", {
  annotations <- staphylococcus_ribitol_wta_annotations()
  for (marker in ribitol_wta_common_markers()) {
    result <- evaluate_gifts(annotations[annotations$accession != marker, ])
    gift <- result$gifts[
      result$gifts$gift_id == "ribitol_phosphate_wall_teichoic_acid",
    ]
    expect_false(gift$complete, info = marker)
    expect_equal(gift$minimum_missing_requirements, 1L, info = marker)
  }
})

test_that("ribitol-WTA priming and polymerization evidence cannot be weakened", {
  common <- ribitol_wta_common_markers()
  common_annotations <- data.frame(
    gene_id = paste0("gene_", names(common)), namespace = "KO",
    accession = unname(common), stringsAsFactors = FALSE
  )
  broad <- rbind(
    common_annotations,
    data.frame(
      gene_id = c("gene_KO_TarF", "gene_KO_TarL", "gene_broad_TagF"),
      namespace = c("KO", "KO", "NCBIFAM"),
      accession = c("K21591", "K18704", "NF016357.7"),
      stringsAsFactors = FALSE
    )
  )
  broad_result <- evaluate_gifts(broad)
  expect_false(broad_result$gifts$complete[
    broad_result$gifts$gift_id == "ribitol_phosphate_wall_teichoic_acid"
  ])
  expect_false(any(c("K21591", "NF016357.7") %in%
                   get_gift_machinery("ribitol_phosphate_wall_teichoic_acid")$accession))

  for (marker in c("NF041712.1", "NF041713.1")) {
    annotations <- staphylococcus_ribitol_wta_annotations()
    result <- evaluate_gifts(annotations[annotations$accession != marker, ])
    expect_false(result$gifts$complete[
      result$gifts$gift_id == "ribitol_phosphate_wall_teichoic_acid"
    ], info = marker)
  }
  for (marker in c("K21592", "K18704")) {
    annotations <- w23_ribitol_wta_annotations()
    result <- evaluate_gifts(annotations[annotations$accession != marker, ])
    expect_false(result$gifts$complete[
      result$gifts$gift_id == "ribitol_phosphate_wall_teichoic_acid"
    ], info = marker)
  }
})

test_that("ribitol-WTA traces and calls are deterministic", {
  annotations <- staphylococcus_ribitol_wta_annotations()
  forward <- evaluate_gifts(annotations)
  reverse <- evaluate_gifts(annotations[nrow(annotations):1L, ])
  columns <- c(
    "complete", "best_architecture", "minimum_missing_functions",
    "evidence_confidence"
  )
  call <- function(result) result$structural$gifts[
    result$structural$gifts$gift_id == "ribitol_phosphate_wall_teichoic_acid",
    columns, drop = FALSE
  ]
  expect_equal(call(forward), call(reverse))
  expect_equal(
    trace_gift(forward, "ribitol_phosphate_wall_teichoic_acid"),
    trace_gift(reverse, "ribitol_phosphate_wall_teichoic_acid")
  )
  trace <- trace_gift(forward, "ribitol_phosphate_wall_teichoic_acid")
  expect_setequal(trace$gene_id, annotations$gene_id)
  expect_true(all(trace$architecture_complete))
})

test_that("diglucosyldiacylglycerol-anchored LTA requires all three functions", {
  annotations <- lta_glc2dag_annotations()
  result <- evaluate_gifts(annotations)
  gift_id <- "diglucosyl_diacylglycerol_anchored_lipoteichoic_acid"
  gift <- result$structural$gifts[result$structural$gifts$gift_id == gift_id, ]
  machinery <- get_gift_machinery(gift_id)

  expect_true(gift$complete)
  expect_equal(gift$best_architecture, "ARCH_LTA_GLC2DAG")
  expect_equal(length(unique(machinery$function_id)), 3L)
  expect_equal(length(unique(machinery$system_id)), 3L)
  expect_equal(length(unique(machinery$component_id)), 3L)
  expect_setequal(
    machinery$accession,
    c("NF010134.0", "NF047396.1", "NF053595.1")
  )
  expect_true(all(machinery$namespace == "NCBIFAM"))

  for (marker in annotations$accession) {
    incomplete <- evaluate_gifts(annotations[annotations$accession != marker, ])
    call <- incomplete$structural$gifts[
      incomplete$structural$gifts$gift_id == gift_id,
    ]
    expect_false(call$complete, info = marker)
    expect_equal(call$minimum_missing_functions, 1L, info = marker)
  }
})

test_that("broad LTA proxies cannot complete the narrow LTA architecture", {
  annotations <- data.frame(
    gene_id = c("gene_UgtP", "gene_LtaS"), namespace = "KO",
    accession = c("K03429", "K19005"), stringsAsFactors = FALSE
  )
  result <- evaluate_gifts(annotations)
  gift_id <- "diglucosyl_diacylglycerol_anchored_lipoteichoic_acid"

  expect_false(result$gifts$complete[result$gifts$gift_id == gift_id])
  expect_false(any(c("K03429", "K19005") %in%
                   get_gift_machinery(gift_id)$accession))
})

test_that("the narrow LTA trace retains each observed marker and is deterministic", {
  annotations <- lta_glc2dag_annotations()
  reverse <- annotations[nrow(annotations):1L, ]
  gift_id <- "diglucosyl_diacylglycerol_anchored_lipoteichoic_acid"
  forward_result <- evaluate_gifts(annotations)
  reverse_result <- evaluate_gifts(reverse)
  trace <- trace_gift(forward_result, gift_id)

  expect_equal(unique(trace$architecture_id), "ARCH_LTA_GLC2DAG")
  expect_true(all(trace$architecture_complete))
  expect_setequal(trace$gene_id, annotations$gene_id)
  expect_setequal(trace$accession, annotations$accession)
  expect_equal(trace, trace_gift(reverse_result, gift_id))
})

test_that("the type VI apparatus completes without its accessory lipoprotein", {
  annotations <- t6ss_annotations()
  result <- evaluate_gifts(annotations)
  gift <- result$structural$gifts[
    result$structural$gifts$gift_id == "type_vi_secretion_apparatus",
  ]
  machinery <- get_gift_machinery("type_vi_secretion_apparatus")

  expect_true(gift$complete)
  expect_equal(gift$best_architecture, "ARCH_T6SS_I")
  expect_equal(gift$minimum_missing_functions, 0L)
  expect_equal(length(unique(machinery$architecture_id)), 1L)
  expect_equal(length(unique(machinery$function_id)), 8L)
  expect_equal(length(unique(machinery$component_id)), 13L)
  expect_equal(
    unique(machinery$function_id[!machinery$required]),
    "SF_T6SS_MEMBRANE_LIPOPROTEIN"
  )
  expect_false("SF_T6SS_MEMBRANE_LIPOPROTEIN" %in% gift$supporting_functions[[1]])
})

test_that("every required type VI function is jointly needed", {
  annotations <- t6ss_annotations()
  for (marker in names(t6ss_required_markers())) {
    markers <- t6ss_required_markers()[names(t6ss_required_markers()) != marker]
    result <- evaluate_gifts(t6ss_annotations(markers))
    gift <- result$structural$gifts[
      result$structural$gifts$gift_id == "type_vi_secretion_apparatus",
    ]
    expect_false(gift$complete, info = marker)
    expect_equal(gift$minimum_missing_functions, 1L, info = marker)
  }
})

test_that("alternative TssA and TssE orthologies satisfy the same functions", {
  # Vibrio cholerae TssA and TssE are assigned to KEGG orthologies named only
  # for the system, not the role. They are accepted because the proteins they
  # hold pass the role equivalog, so the apparatus must complete through them.
  markers <- t6ss_required_markers()
  markers[["TssA"]] <- "K11910"
  markers[["TssE"]] <- "K11905"
  result <- evaluate_gifts(t6ss_annotations(markers))

  expect_true(result$gifts$complete[
    result$gifts$gift_id == "type_vi_secretion_apparatus"
  ])
  trace <- trace_gift(result, "type_vi_secretion_apparatus")
  expect_setequal(
    trace$component_id[trace$accession %in% c("K11910", "K11905")],
    c("COMP_T6SS_TSSA", "COMP_T6SS_TSSE")
  )
})

test_that("a type VI marker refused by its role equivalog supports nothing", {
  # K11918 is a type VI accession, but none of its sampled proteins passes the
  # TssJ equivalog, so it is not evidence of the lipoprotein role.
  result <- evaluate_gifts(data.frame(
    gene_id = "gene_lip3", namespace = "KO", accession = "K11918",
    stringsAsFactors = FALSE
  ))
  components <- result$structural$components

  expect_false(any(components$supported[
    components$component_id == "COMP_T6SS_TSSJ"
  ]))
  expect_false("K11918" %in% get_gift_machinery("type_vi_secretion_apparatus")$accession)
})

test_that("the injectisome requires every role of its single architecture", {
  annotations <- injectisome_annotations()
  result <- evaluate_gifts(annotations)
  gift <- result$structural$gifts[
    result$structural$gifts$gift_id == "type_iii_secretion_injectisome",
  ]
  machinery <- get_gift_machinery("type_iii_secretion_injectisome")

  expect_true(gift$complete)
  expect_equal(gift$best_architecture, "ARCH_T3SS_INJECTISOME")
  expect_equal(length(unique(machinery$function_id)), 7L)
  expect_equal(length(unique(machinery$system_id)), 8L)
  expect_true(all(machinery$required))

  for (marker in names(injectisome_required_markers())) {
    markers <- injectisome_required_markers()[
      names(injectisome_required_markers()) != marker
    ]
    incomplete <- evaluate_gifts(injectisome_annotations(markers))
    call <- incomplete$structural$gifts[
      incomplete$structural$gifts$gift_id == "type_iii_secretion_injectisome",
    ]
    expect_false(call$complete, info = marker)
    expect_equal(call$minimum_missing_functions, 1L, info = marker)
  }
})

test_that("a needle and an Hrp pilus are alternative injectisome filaments", {
  markers <- injectisome_required_markers()
  markers[["SctF"]] <- "K18375"
  hrp <- evaluate_gifts(injectisome_annotations(markers))
  systems <- hrp$structural$systems

  expect_true(hrp$gifts$complete[
    hrp$gifts$gift_id == "type_iii_secretion_injectisome"
  ])
  expect_true(systems$supported[systems$system_id == "SYS_T3SS_HRP_PILUS"])
  expect_false(systems$supported[systems$system_id == "SYS_T3SS_NEEDLE"])
})

test_that("flagellar export evidence does not support the injectisome", {
  # The two machines are homologous, so the whole claim rests on the accepted
  # accessions being specific. A flagellated genome encoding neither secretion
  # system must support no injectisome component, and the injectisome must not
  # borrow a flagellar accession.
  flagellar <- flagellar_export_markers()
  result <- evaluate_gifts(data.frame(
    gene_id = paste0("gene_", names(flagellar)), namespace = "KO",
    accession = unname(flagellar), stringsAsFactors = FALSE
  ))
  components <- result$structural$components
  machinery <- get_gift_machinery("type_iii_secretion_injectisome")

  expect_false(result$gifts$complete[
    result$gifts$gift_id == "type_iii_secretion_injectisome"
  ])
  expect_false(any(components$supported[
    grepl("^COMP_T3SS", components$component_id)
  ]))
  expect_false(any(flagellar %in% machinery$accession))

  # And the converse: injectisome evidence does not build a flagellum.
  injectisome <- evaluate_gifts(injectisome_annotations())
  expect_false(injectisome$gifts$complete[
    injectisome$gifts$gift_id == "flagellar_apparatus"
  ])
  expect_false(any(
    injectisome_required_markers() %in%
      get_gift_machinery("flagellar_apparatus")$accession
  ))
})

test_that("both secretion machines trace to their markers and are deterministic", {
  for (gift_id in c("type_vi_secretion_apparatus", "type_iii_secretion_injectisome")) {
    annotations <- if (gift_id == "type_vi_secretion_apparatus") {
      t6ss_annotations()
    } else {
      injectisome_annotations()
    }
    forward <- evaluate_gifts(annotations)
    reverse <- evaluate_gifts(annotations[nrow(annotations):1L, ])
    trace <- trace_gift(forward, gift_id)

    supported <- trace[trace$component_supported, ]

    # Every observed gene is retained. An unsupported accessory role stays
    # visible in the trace of a complete call instead of disappearing from it.
    expect_setequal(supported$gene_id, annotations$gene_id)
    expect_setequal(supported$accession, annotations$accession)
    expect_true(all(is.na(trace$gene_id[!trace$component_supported])))
    expect_true(all(trace$architecture_complete), info = gift_id)
    expect_equal(trace, trace_gift(reverse, gift_id), info = gift_id)
  }
})

t2ss_gsp_markers <- function() {
  c(
    GspC = "K02452", GspD = "K02453", GspE = "K02454", GspF = "K02455",
    GspG = "K02456", GspH = "K02457", GspI = "K02458", GspJ = "K02459",
    GspK = "K02460", GspL = "K02461", GspM = "K02462"
  )
}

t2ss_annotations <- function(markers = c(t2ss_gsp_markers(), GspO = "K02464")) {
  data.frame(
    gene_id = paste0("gene_", names(markers)), namespace = "KO",
    accession = unname(markers), stringsAsFactors = FALSE
  )
}

test_that("the type II apparatus requires all five of its subassemblies", {
  result <- evaluate_gifts(t2ss_annotations())
  gift <- result$structural$gifts[
    result$structural$gifts$gift_id == "type_ii_secretion_system",
  ]
  machinery <- get_gift_machinery("type_ii_secretion_system")

  expect_true(gift$complete)
  expect_equal(gift$best_architecture, "ARCH_T2SS_CANONICAL")
  expect_equal(length(unique(machinery$function_id)), 5L)
  expect_equal(length(unique(machinery$system_id)), 5L)
  expect_equal(length(unique(machinery$component_id)), 12L)
  expect_true(all(machinery$required))

  # Every Gsp role is jointly required, including the weakly marked GspC.
  for (marker in names(t2ss_gsp_markers())) {
    markers <- c(t2ss_gsp_markers()[names(t2ss_gsp_markers()) != marker], GspO = "K02464")
    incomplete <- evaluate_gifts(t2ss_annotations(markers))
    call <- incomplete$structural$gifts[
      incomplete$structural$gifts$gift_id == "type_ii_secretion_system",
    ]
    expect_false(call$complete, info = marker)
  }

  # And the whole Gsp inventory without a peptidase is still one function short.
  no_peptidase <- evaluate_gifts(t2ss_annotations(t2ss_gsp_markers()))
  call <- no_peptidase$structural$gifts[
    no_peptidase$structural$gifts$gift_id == "type_ii_secretion_system",
  ]
  expect_false(call$complete)
  expect_equal(
    call$missing_functions_best_architecture[[1]], "SF_T2SS_PREPILIN_PEPTIDASE"
  )
})

test_that("GspO and PilD are one shared peptidase, not two implementations", {
  # The same enzyme processes type IVa pilins and type II pseudopilins, and
  # KEGG files most of them under PilD. Both accessions must complete the
  # apparatus, and reaching the role through PilD must not call the pilus.
  gspo <- evaluate_gifts(t2ss_annotations())
  pild <- evaluate_gifts(t2ss_annotations(c(t2ss_gsp_markers(), PilD = "K02654")))

  expect_true(gspo$gifts$complete[gspo$gifts$gift_id == "type_ii_secretion_system"])
  expect_true(pild$gifts$complete[pild$gifts$gift_id == "type_ii_secretion_system"])
  expect_false(pild$gifts$complete[pild$gifts$gift_id == "type_iva_pilus"])

  # One component, two accepted accessions: not two alternative systems.
  machinery <- get_gift_machinery("type_ii_secretion_system")
  peptidase <- machinery[machinery$function_id == "SF_T2SS_PREPILIN_PEPTIDASE", ]
  expect_equal(length(unique(peptidase$system_id)), 1L)
  expect_equal(length(unique(peptidase$component_id)), 1L)
  expect_setequal(peptidase$accession, c("K02464", "K02654"))
})

test_that("a complete type IVa pilus does not imply a type II secretion system", {
  # The two machines share the peptidase and nothing else that is required.
  pilus <- evaluate_gifts(ko_annotations(type_iva_pilus_markers()))
  expect_true(pilus$gifts$complete[pilus$gifts$gift_id == "type_iva_pilus"])
  expect_false(pilus$gifts$complete[pilus$gifts$gift_id == "type_ii_secretion_system"])

  t2ss <- evaluate_gifts(t2ss_annotations(c(t2ss_gsp_markers(), PilD = "K02654")))
  expect_false(t2ss$gifts$complete[t2ss$gifts$gift_id == "type_iva_pilus"])

  # Neither apparatus accepts the other's discriminating accessions.
  gsp <- get_gift_machinery("type_ii_secretion_system")$accession
  pil <- get_gift_machinery("type_iva_pilus")$accession
  expect_equal(intersect(gsp, pil), "K02654")
})

test_that("a shared component carries no specificity between two GIFTs", {
  # One accession on two components is three situations and only one is a
  # defect: a fused protein serving two roles of one machine, a shared protein
  # serving two machines, or an accession that cannot say which protein it
  # matched. The first two are accepted; the third is invariant 16 and refused.
  # Where a component really is shared, the function it supports distinguishes
  # neither GIFT, so each must require a function the other does not.
  db <- gifter_db_connect()
  on.exit(gifter_db_disconnect(db), add = TRUE)
  shared <- DBI::dbGetQuery(db, "
    select mk.accession, g.gift_id, f.function_id
    from structural_component_marker scm
    join structural_component c on c.component_pk = scm.component_pk
    join marker mk on mk.marker_pk = scm.marker_pk
    join structural_system s on s.system_pk = c.system_pk
    join structural_function f on f.function_pk = s.function_pk
    join architecture_function af on af.function_pk = f.function_pk
    join gift_architecture ga on ga.architecture_pk = af.architecture_pk
    join gift g on g.gift_pk = ga.gift_pk
    where af.required = 1
  ")

  by_accession <- split(shared, shared$accession)
  crossing <- Filter(
    function(rows) length(unique(rows$gift_id)) > 1L, by_accession
  )
  # A new cross-GIFT accession must not appear silently: it is either a shared
  # component, which this rule governs, or an over-broad marker to refuse.
  expect_setequal(names(crossing), "K02654")

  required_functions <- function(gift_id) {
    unique(shared$function_id[shared$gift_id == gift_id])
  }
  for (rows in crossing) {
    gifts <- unique(rows$gift_id)
    for (pair in utils::combn(gifts, 2L, simplify = FALSE)) {
      own <- setdiff(required_functions(pair[[1]]), required_functions(pair[[2]]))
      other <- setdiff(required_functions(pair[[2]]), required_functions(pair[[1]]))
      expect_gt(length(own), 0L)
      expect_gt(length(other), 0L)
    }
  }
})

test_that("a shared peptidase does not make one machine evidence of another", {
  # K02654 is accepted by both the type IVa pilus and the archaellum. A genome
  # carrying it and nothing else must complete neither, and a genome completing
  # one must not thereby complete the other.
  peptidase_only <- evaluate_gifts(data.frame(
    gene_id = "gene_PilD", namespace = "KO", accession = "K02654",
    stringsAsFactors = FALSE
  ))
  calls <- peptidase_only$gifts
  expect_false(any(calls$complete[
    calls$gift_id %in% c("type_iva_pilus", "archaellum")
  ]))

  pilus <- evaluate_gifts(ko_annotations(type_iva_pilus_markers()))
  expect_true(pilus$gifts$complete[pilus$gifts$gift_id == "type_iva_pilus"])
  expect_false(pilus$gifts$complete[pilus$gifts$gift_id == "archaellum"])

  # The one gene is traceable under each GIFT that accepts it.
  shared <- evaluate_gifts(ko_annotations(type_iva_pilus_markers()))
  trace <- trace_gift(shared, "type_iva_pilus")
  expect_true("K02654" %in% trace$accession)
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

# ---------------------------------------------------------------------------
# Archaellum
# ---------------------------------------------------------------------------

archaellum_ko_markers <- function() {
  c(
    ArlB = "K07325", ArlK = "K07991", ArlF = "K07329", ArlG = "K07330",
    ArlH = "K07331", ArlI = "K07332", ArlJ = "K07333"
  )
}

archaellum_annotations <- function(markers = archaellum_ko_markers(), namespace = "KO") {
  data.frame(
    gene_id = paste0("gene_", names(markers)), namespace = namespace,
    accession = unname(markers), stringsAsFactors = FALSE
  )
}

archaellum_call <- function(result) {
  result$structural$gifts[result$structural$gifts$gift_id == "archaellum", ]
}

# KO accession sets of named reference genomes, restricted to the accessions
# that the archaellum, flagellar_apparatus or type_iva_pilus accept. Verified
# against KEGG REST `link/ko/<org>` on 2026-10-03; gene identifiers are
# synthetic because per-genome KEGG assignments are not redistributed.
archaellum_control_kos <- list(
  mmp = c("K07325", "K07327", "K07328", "K07329", "K07330", "K07331", "K07332",
          "K07333", "K07822", "K07991"),
  sai = c("K07325", "K07329", "K07330", "K07331", "K07332", "K07333", "K07991"),
  hvo = c("K07325", "K07329", "K07330", "K07331", "K07332", "K07333", "K07991",
          "K23986"),
  eco = c("K02387", "K02388", "K02390", "K02391", "K02392", "K02393", "K02394",
          "K02396", "K02397", "K02400", "K02401", "K02406", "K02407", "K02408",
          "K02409", "K02410", "K02411", "K02412", "K02416", "K02417", "K02419",
          "K02420", "K02421", "K02556", "K02557", "K02654", "K02669"),
  bsu = c("K02387", "K02388", "K02390", "K02391", "K02392", "K02396", "K02397",
          "K02400", "K02401", "K02406", "K02407", "K02408", "K02409", "K02410",
          "K02411", "K02412", "K02416", "K02417", "K02419", "K02420", "K02421",
          "K02556", "K02557")
)

control_annotations <- function(org) {
  kos <- archaellum_control_kos[[org]]
  data.frame(
    gene_id = paste0(org, "_", kos), namespace = "KO", accession = kos,
    stringsAsFactors = FALSE
  )
}

test_that("the archaellum core completes and every required function is jointly needed", {
  result <- evaluate_gifts(archaellum_annotations())
  gift <- archaellum_call(result)
  expect_true(gift$complete)
  expect_equal(gift$best_architecture, "ARCH_ARCHAELLUM_CORE")
  expect_setequal(gift$supporting_functions[[1]], c(
    "SF_ARCHAELLUM_FILAMENT", "SF_ARCHAELLUM_SIGNAL_PEPTIDASE",
    "SF_ARCHAELLUM_STATOR", "SF_ARCHAELLUM_MOTOR", "SF_ARCHAELLUM_PLATFORM"
  ))

  expected_missing <- c(
    ArlB = "SF_ARCHAELLUM_FILAMENT", ArlK = "SF_ARCHAELLUM_SIGNAL_PEPTIDASE",
    ArlF = "SF_ARCHAELLUM_STATOR", ArlG = "SF_ARCHAELLUM_STATOR",
    ArlH = "SF_ARCHAELLUM_MOTOR", ArlI = "SF_ARCHAELLUM_MOTOR",
    ArlJ = "SF_ARCHAELLUM_PLATFORM"
  )
  for (role in names(expected_missing)) {
    markers <- archaellum_ko_markers()[names(archaellum_ko_markers()) != role]
    gift <- archaellum_call(evaluate_gifts(archaellum_annotations(markers)))
    expect_false(gift$complete, info = role)
    expect_equal(gift$missing_functions_best_architecture[[1]], expected_missing[[role]], info = role)
  }
})

test_that("a missing stator or motor subunit is reported at the component", {
  markers <- archaellum_ko_markers()[names(archaellum_ko_markers()) != "ArlF"]
  systems <- evaluate_gifts(archaellum_annotations(markers))$structural$systems
  expect_equal(
    systems$missing_components[systems$system_id == "SYS_ARCHAELLUM_STATOR_FLAFG"][[1]],
    "COMP_ARCHAELLUM_FLAF"
  )
  markers <- archaellum_ko_markers()[names(archaellum_ko_markers()) != "ArlH"]
  systems <- evaluate_gifts(archaellum_annotations(markers))$structural$systems
  expect_equal(
    systems$missing_components[systems$system_id == "SYS_ARCHAELLUM_MOTOR_FLAHI"][[1]],
    "COMP_ARCHAELLUM_FLAH"
  )
})

test_that("FlaI and FlaJ with pilus machinery never fire the archaellum", {
  # K07332 and K07333 also collect the ATPases and platforms of archaeal type IV
  # pili and the bindosome, and PibD processes pilins too. A pilus locus
  # therefore supports at most the motor-less, specificity-free part of the
  # machine. The UpsF and bindosome profiles are not archaellum evidence at all.
  pilus <- rbind(
    archaellum_annotations(c(ArlI = "K07332", ArlJ = "K07333", ArlK = "K07991")),
    data.frame(
      gene_id = c("gene_UpsF", "gene_BasE", "gene_BasF", "gene_pilin"),
      namespace = "NCBIFAM",
      accession = c("NF046075.1", "NF053672.1", "NF053673.1", "TIGR02537.2"),
      stringsAsFactors = FALSE
    )
  )
  result <- evaluate_gifts(pilus)
  gift <- archaellum_call(result)
  expect_false(gift$complete)
  expect_setequal(gift$missing_functions_best_architecture[[1]], c(
    "SF_ARCHAELLUM_FILAMENT", "SF_ARCHAELLUM_STATOR", "SF_ARCHAELLUM_MOTOR"
  ))
  mapped <- map_markers(pilus)
  expect_false(any(mapped$matched[mapped$namespace == "NCBIFAM"]))

  # Even the archaellum-specific equivalogs for the ATPase and platform do not
  # fire the GIFT without archaellin, FlaF, FlaG and FlaH.
  motor_only <- archaellum_annotations(
    c(ArlI = "NF058587.1", ArlJ = "NF004704.2", ArlK = "NF040695.1"), namespace = "NCBIFAM"
  )
  expect_false(archaellum_call(evaluate_gifts(motor_only))$complete)
})

test_that("the FlaI and FlaJ orthologies carry their doubt to the call", {
  ko_only <- archaellum_call(evaluate_gifts(archaellum_annotations()))
  expect_equal(ko_only$evidence_confidence, "putative")

  # NCBIfam equivalogs separate FlaI and FlaJ from their pilus homologues, so a
  # genome whose ATPase and platform pass them reads as high-confidence.
  resolved <- rbind(
    archaellum_annotations(archaellum_ko_markers()[c("ArlB", "ArlK", "ArlF", "ArlG", "ArlH")]),
    archaellum_annotations(c(ArlI = "NF058587.1", ArlJ = "NF004705.1"), namespace = "NCBIFAM")
  )
  gift <- archaellum_call(evaluate_gifts(resolved))
  expect_true(gift$complete)
  expect_equal(gift$evidence_confidence, "high-confidence")
})

test_that("the archaellin orthologies do not include bacterial FlgA", {
  # K07325 is defined as flaB, flgA, but the flgA there is the haloarchaeal
  # archaellin name. Bacterial FlgA is K02386 and is not archaellin evidence.
  flga <- archaellum_annotations(c(archaellum_ko_markers()[-1], FlgA = "K02386"))
  gift <- archaellum_call(evaluate_gifts(flga))
  expect_false(gift$complete)
  expect_equal(gift$missing_functions_best_architecture[[1]], "SF_ARCHAELLUM_FILAMENT")
  expect_true(archaellum_call(evaluate_gifts(archaellum_annotations(
    c(archaellum_ko_markers()[-1], ArlA = "K07324")
  )))$complete)
})

test_that("lineage-restricted accessory functions do not change the archaellum call", {
  core <- evaluate_gifts(archaellum_annotations())
  with_accessories <- evaluate_gifts(rbind(
    archaellum_annotations(c(
      archaellum_ko_markers(), FlaC = "K07822", FlaD = "K07327", FlaE = "K07328"
    )),
    archaellum_annotations(c(FlaX = "NF058591.1"), namespace = "NCBIFAM")
  ))
  a <- archaellum_call(core)
  b <- archaellum_call(with_accessories)
  expect_true(a$complete)
  expect_true(b$complete)
  expect_equal(a$evidence_confidence, b$evidence_confidence)
  expect_equal(a$supporting_functions[[1]], b$supporting_functions[[1]])

  functions <- with_accessories$structural$functions
  expect_true(all(functions$supported[functions$function_id %in% c(
    "SF_ARCHAELLUM_SWITCH_COMPLEX", "SF_ARCHAELLUM_FLAX_RING"
  )]))

  # The haloarchaeal FlaCE fusion supports FlaC and FlaE but not FlaD, so the
  # switch complex stays visibly incomplete without changing the call.
  halo <- evaluate_gifts(archaellum_annotations(c(archaellum_ko_markers(), FlaCE = "K23986")))
  systems <- halo$structural$systems
  expect_equal(
    systems$missing_components[systems$system_id == "SYS_ARCHAELLUM_SWITCH_FLACDE"][[1]],
    "COMP_ARCHAELLUM_FLAD"
  )
  expect_true(archaellum_call(halo)$complete)
})

test_that("the archaellum and the bacterial flagellum and type IVa pilus do not cross", {
  archaeal <- evaluate_gifts(archaellum_annotations(c(
    archaellum_ko_markers(), FlaC = "K07822", FlaD = "K07327", FlaE = "K07328"
  )))
  functions <- archaeal$structural$functions
  expect_false(any(functions$supported[grepl("^SF_(FLAGELLAR|T4AP)_", functions$function_id)]))
  expect_false(any(archaeal$gifts$complete[
    archaeal$gifts$gift_id %in% c("flagellar_apparatus", "type_iva_pilus")
  ]))

  bacterial <- evaluate_gifts(ko_annotations(c(
    flagellar_core_markers(), "K02393", "K02394", type_iva_pilus_markers(), "K02669"
  )))
  expect_true(all(bacterial$gifts$complete[
    bacterial$gifts$gift_id %in% c("flagellar_apparatus", "type_iva_pilus")
  ]))
  gift <- archaellum_call(bacterial)
  expect_false(gift$complete)
  # The only overlap is the shared class III signal peptidase: K02654 is the
  # PilD of the type IVa pilus and the bacterial-type archaellin peptidase of
  # archaellum-encoding Chloroflexota. It carries no machine specificity.
  functions <- bacterial$structural$functions
  archaellum_functions <- functions[grepl("^SF_ARCHAELLUM_", functions$function_id), ]
  expect_equal(
    archaellum_functions$function_id[archaellum_functions$supported],
    "SF_ARCHAELLUM_SIGNAL_PEPTIDASE"
  )
})

test_that("a bacterial PilD peptidase supports the archaellum only at putative confidence", {
  markers <- c(archaellum_ko_markers()[names(archaellum_ko_markers()) != "ArlK"], PilD = "K02654")
  result <- evaluate_gifts(archaellum_annotations(markers))
  gift <- archaellum_call(result)
  functions <- result$structural$functions
  expect_true(gift$complete)
  expect_equal(gift$evidence_confidence, "putative")
  expect_equal(
    functions$best_system[functions$function_id == "SF_ARCHAELLUM_SIGNAL_PEPTIDASE"],
    "SYS_ARCHAELLUM_PILD"
  )
})

test_that("the archaellum evaluates beside a metabolic GIFT without changing either", {
  annotations <- rbind(
    ko_annotations(direct_purine_markers()),
    archaellum_annotations()
  )
  result <- evaluate_gifts(annotations)
  complete <- result$gifts[result$gifts$complete, ]
  expect_true(all(c("purine_core_biosynthesis", "archaellum") %in% complete$gift_id))
  expect_equal(complete$gift_type[complete$gift_id == "archaellum"], "structural")
  alone <- evaluate_gifts(ko_annotations(direct_purine_markers()))
  expect_equal(
    result$gifts$complete[result$gifts$gift_type == "metabolic"],
    alone$gifts$complete[alone$gifts$gift_type == "metabolic"]
  )
})

test_that("the archaellum trace reaches every observed marker and gene", {
  annotations <- archaellum_annotations()
  trace <- trace_gift(evaluate_gifts(annotations), "archaellum")
  supported <- trace[trace$component_supported, ]
  expect_equal(unique(trace$architecture_id), "ARCH_ARCHAELLUM_CORE")
  expect_setequal(supported$gene_id, annotations$gene_id)
  expect_setequal(supported$accession, annotations$accession)
  expect_setequal(supported$component_id, c(
    "COMP_ARCHAELLUM_ARCHAELLIN", "COMP_ARCHAELLUM_FLAK_PIBD", "COMP_ARCHAELLUM_FLAF",
    "COMP_ARCHAELLUM_FLAG", "COMP_ARCHAELLUM_FLAH", "COMP_ARCHAELLUM_FLAI",
    "COMP_ARCHAELLUM_FLAJ"
  ))
})

test_that("archaellated reference archaea complete and flagellated bacteria do not", {
  # Methanococcus maripaludis S2 (PMID 17887963), Sulfolobus acidocaldarius
  # DSM 639 (PMID 22081969) and Haloferax volcanii DS2 assemble archaella;
  # Escherichia coli K-12 and Bacillus subtilis 168 build bacterial flagella.
  for (org in c("mmp", "sai", "hvo")) {
    gift <- archaellum_call(evaluate_gifts(control_annotations(org)))
    expect_true(gift$complete, info = org)
    expect_equal(gift$evidence_confidence, "putative", info = org)
  }
  mmp <- evaluate_gifts(control_annotations("mmp"))$structural$functions
  expect_true(mmp$supported[mmp$function_id == "SF_ARCHAELLUM_SWITCH_COMPLEX"])

  for (org in c("eco", "bsu")) {
    result <- evaluate_gifts(control_annotations(org))
    expect_false(archaellum_call(result)$complete, info = org)
    expect_true(result$gifts$complete[result$gifts$gift_id == "flagellar_apparatus"], info = org)
  }
})

test_that("the archaellum decision is recorded with its evidence", {
  changes <- database_changelog("archaellum")
  expect_true("DBC-20261003-ARCHAELLUM" %in% changes$change_id)
  expect_match(changes$evidence[changes$change_id == "DBC-20261003-ARCHAELLUM"], "PMID 17887963", fixed = TRUE)
  expect_equal(get_gift("archaellum")$gift_type, "structural")
  expect_true(is.na(get_gift("archaellum")$mode) || !nzchar(get_gift("archaellum")$mode))
})
