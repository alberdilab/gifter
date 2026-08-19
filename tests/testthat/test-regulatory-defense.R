# The regulatory and defense completeness models.
#
# The Boolean contract is fixed first on synthetic fixtures, so that it does not
# depend on any particular curated biology, and then exercised on the curated
# chemotaxis, phosphate-response, restriction-modification and CRISPR-Cas
# content. What remains deferred, and why, is recorded in
# inst/doc/proposal-regulatory-gifts.md and inst/doc/proposal-defense-gifts.md.

fixture_annotations <- function(markers) {
  data.frame(
    gene_id = paste0("gene_", seq_along(markers)), namespace = "KO",
    accession = markers, stringsAsFactors = FALSE
  )
}

test_that("an empty marker set still produces an auditable answer for every type", {
  result <- evaluate_gifts(character())

  for (view in list(result$regulatory, result$defense)) {
    expect_gt(nrow(view$gifts), 0L)
    expect_false(any(view$gifts$complete))
    expect_true(all(view$gifts$minimum_missing_functions > 0L))
  }
})

test_that("a regulatory circuit needs every required regulatory function", {
  # A compact sensor/regulator circuit: a signal has to be detected and a
  # response executed. Encoding one without the other is not the capability.
  source_dir <- giftr_source_copy()
  add_test_machinery_gift(
    source_dir, "fixture_signal_response", "regulatory", "CIRCUIT_FIXTURE",
    list(
      list(id = "RF_FIXTURE_SENSING", systems = list(
        list(id = "SYS_RF_FIXTURE_SENSOR", components = list(
          list(id = "COMP_RF_FIXTURE_SENSOR", markers = "KO:K93001")
        ))
      )),
      list(id = "RF_FIXTURE_RESPONSE", systems = list(
        list(id = "SYS_RF_FIXTURE_REGULATOR", components = list(
          list(id = "COMP_RF_FIXTURE_REGULATOR", markers = "KO:K93002")
        ))
      ))
    )
  )
  db <- build_test_database(source_dir)

  sensor_only <- evaluate_gifts(fixture_annotations("K93001"), db = db)
  gift <- sensor_only$regulatory$gifts[
    sensor_only$regulatory$gifts$gift_id == "fixture_signal_response",
  ]
  expect_false(gift$complete)
  expect_equal(gift$minimum_missing_functions, 1L)
  expect_equal(gift$missing_functions_best_circuit[[1]], "RF_FIXTURE_RESPONSE")
  expect_equal(gift$best_circuit, "CIRCUIT_FIXTURE")

  both <- evaluate_gifts(fixture_annotations(c("K93001", "K93002")), db = db)
  expect_true(both$regulatory$gifts$complete[
    both$regulatory$gifts$gift_id == "fixture_signal_response"
  ])
  expect_equal(both$gifts$gift_type[both$gifts$gift_id == "fixture_signal_response"],
               "regulatory")

  trace <- trace_gift(both, "fixture_signal_response")
  expect_equal(unique(trace$circuit_id), "CIRCUIT_FIXTURE")
  expect_equal(trace$function_id, c("RF_FIXTURE_SENSING", "RF_FIXTURE_RESPONSE"))
  expect_true(all(!is.na(trace$gene_id)))
})

test_that("regulatory specificity cannot exceed evidence specificity", {
  # The chemotaxis case, as a fixture. A generic receptor marker supports the
  # core signal-transduction claim. It cannot support a ligand-specific claim,
  # which needs its own evidence -- so the ligand-specific GIFT stays incomplete
  # on a genome carrying only the generic receptor, instead of the broad marker
  # being widened to fire it.
  source_dir <- giftr_source_copy()
  add_test_machinery_gift(
    source_dir, "fixture_chemotaxis_core", "regulatory", "CIRCUIT_FIXTURE_CHEMOTAXIS_CORE",
    list(
      list(id = "RF_FIXTURE_RECEPTOR", systems = list(
        list(id = "SYS_RF_FIXTURE_GENERIC_RECEPTOR", components = list(
          list(id = "COMP_RF_FIXTURE_GENERIC_RECEPTOR", markers = "KO:K93010")
        ))
      )),
      list(id = "RF_FIXTURE_KINASE", systems = list(
        list(id = "SYS_RF_FIXTURE_KINASE", components = list(
          list(id = "COMP_RF_FIXTURE_KINASE", markers = "KO:K93011")
        ))
      ))
    )
  )
  add_test_machinery_gift(
    source_dir, "fixture_chemotaxis_ligand", "regulatory", "CIRCUIT_FIXTURE_CHEMOTAXIS_LIGAND",
    list(
      list(id = "RF_FIXTURE_LIGAND_RECEPTOR", systems = list(
        list(id = "SYS_RF_FIXTURE_LIGAND_RECEPTOR", components = list(
          # A binding-protein marker specific to one chemoeffector. The generic
          # receptor accession is deliberately not accepted here.
          list(id = "COMP_RF_FIXTURE_LIGAND_RECEPTOR", markers = "KO:K93012")
        ))
      )),
      list(id = "RF_FIXTURE_KINASE", systems = list())
    )[1]
  )
  membership <- read_source(source_dir, "circuit_functions")
  membership <- rbind(membership, data.frame(
    circuit_id = "CIRCUIT_FIXTURE_CHEMOTAXIS_LIGAND", function_id = "RF_FIXTURE_KINASE",
    ordinal = "2", required = "1", stringsAsFactors = FALSE
  )[names(membership)])
  write_source(source_dir, "circuit_functions", membership)
  db <- build_test_database(source_dir)

  generic <- evaluate_gifts(fixture_annotations(c("K93010", "K93011")), db = db)
  calls <- generic$regulatory$gifts
  expect_true(calls$complete[calls$gift_id == "fixture_chemotaxis_core"])
  expect_false(calls$complete[calls$gift_id == "fixture_chemotaxis_ligand"])
  expect_equal(
    calls$missing_functions_best_circuit[calls$gift_id == "fixture_chemotaxis_ligand"][[1]],
    "RF_FIXTURE_LIGAND_RECEPTOR"
  )

  specific <- evaluate_gifts(
    fixture_annotations(c("K93010", "K93011", "K93012")), db = db
  )
  calls <- specific$regulatory$gifts
  expect_true(all(calls$complete[
    calls$gift_id %in% c("fixture_chemotaxis_core", "fixture_chemotaxis_ligand")
  ]))
})

test_that("a defense mechanism needs every required defense function", {
  # A multisubunit restriction-modification fixture: recognition, restriction
  # and methylation are separate functions, and the restriction machine is a
  # complex whose subunits are jointly required.
  source_dir <- giftr_source_copy()
  add_test_machinery_gift(
    source_dir, "fixture_restriction_modification", "defense", "MECH_FIXTURE_RM",
    list(
      list(id = "DF_FIXTURE_RECOGNITION", systems = list(
        list(id = "SYS_DF_FIXTURE_SPECIFICITY", components = list(
          list(id = "COMP_DF_FIXTURE_SPECIFICITY", markers = "KO:K94001")
        ))
      )),
      list(id = "DF_FIXTURE_RESTRICTION", systems = list(
        list(id = "SYS_DF_FIXTURE_RESTRICTION", components = list(
          list(id = "COMP_DF_FIXTURE_ENDONUCLEASE", markers = "KO:K94002"),
          list(id = "COMP_DF_FIXTURE_TRANSLOCASE", markers = "KO:K94003")
        ))
      )),
      list(id = "DF_FIXTURE_MODIFICATION", systems = list(
        list(id = "SYS_DF_FIXTURE_METHYLTRANSFERASE", components = list(
          list(id = "COMP_DF_FIXTURE_METHYLTRANSFERASE", markers = "KO:K94004")
        ))
      ))
    )
  )
  db <- build_test_database(source_dir)

  complete <- evaluate_gifts(
    fixture_annotations(c("K94001", "K94002", "K94003", "K94004")), db = db
  )
  fixture <- complete$defense$gifts[
    complete$defense$gifts$gift_id == "fixture_restriction_modification",
  ]
  expect_true(fixture$complete)
  expect_equal(fixture$best_mechanism, "MECH_FIXTURE_RM")

  # Losing one subunit of the restriction complex removes the whole function,
  # and the report says which function rather than counting genes.
  partial <- evaluate_gifts(
    fixture_annotations(c("K94001", "K94002", "K94004")), db = db
  )
  gift <- partial$defense$gifts[
    partial$defense$gifts$gift_id == "fixture_restriction_modification",
  ]
  expect_false(gift$complete)
  expect_equal(gift$minimum_missing_functions, 1L)
  expect_equal(gift$missing_functions_best_mechanism[[1]], "DF_FIXTURE_RESTRICTION")
  systems <- partial$defense$systems
  expect_equal(
    systems$missing_components[systems$system_id == "SYS_DF_FIXTURE_RESTRICTION"][[1]],
    "COMP_DF_FIXTURE_TRANSLOCASE"
  )

  # Methylation alone protects nothing; the mechanism is not the sum of its
  # convenient parts.
  methylation_only <- evaluate_gifts(fixture_annotations("K94004"), db = db)
  gift <- methylation_only$defense$gifts[
    methylation_only$defense$gifts$gift_id == "fixture_restriction_modification",
  ]
  expect_false(gift$complete)
  expect_equal(gift$minimum_missing_functions, 2L)
})

test_that("a machinery model of one type cannot borrow another type's tables", {
  source_dir <- giftr_source_copy()
  add_test_machinery_gift(
    source_dir, "fixture_defense", "defense", "MECH_FIXTURE_ONLY",
    list(list(id = "DF_FIXTURE_ONLY", systems = list(
      list(id = "SYS_DF_FIXTURE_ONLY", components = list(
        list(id = "COMP_DF_FIXTURE_ONLY", markers = "KO:K94010")
      ))
    )))
  )
  circuits <- read_source(source_dir, "gift_circuits")
  write_source(source_dir, "gift_circuits", rbind(circuits, data.frame(
    circuit_id = "CIRCUIT_WRONG_TYPE", gift_id = "fixture_defense",
    name = "wrong", description = "Attached to a defense GIFT.", status = "draft",
    stringsAsFactors = FALSE
  )[names(circuits)]))
  expect_error(
    validate_giftr_sources(source_dir),
    "gift_circuits describes the regulatory model"
  )
})


# ---------------------------------------------------------------------------
# Curated regulatory content
# ---------------------------------------------------------------------------

chemotaxis_downstream_markers <- function() {
  # CheA, CheW, CheY, CheR, CheB: everything but the receptor.
  c("K03407", "K03408", "K03413", "K00575", "K03412")
}

test_that("core chemotaxis needs receptor, kinase, response regulator and adaptation", {
  complete <- evaluate_gifts(ko_annotations(c("K03406", chemotaxis_downstream_markers())))
  gift <- complete$regulatory$gifts[
    complete$regulatory$gifts$gift_id == "chemotaxis_signal_transduction",
  ]
  expect_true(gift$complete)
  expect_equal(gift$best_circuit, "CIRCUIT_CHEMOTAXIS_CORE")
  expect_equal(gift$minimum_missing_functions, 0L)

  # CheA without CheW is not a kinase core: the receptor-CheW-CheA array is what
  # makes the kinase receptor-controlled.
  no_chew <- evaluate_gifts(ko_annotations(c(
    "K03406", setdiff(chemotaxis_downstream_markers(), "K03408")
  )))
  gift <- no_chew$regulatory$gifts[
    no_chew$regulatory$gifts$gift_id == "chemotaxis_signal_transduction",
  ]
  expect_false(gift$complete)
  expect_equal(gift$missing_functions_best_circuit[[1]], "RF_CHEMOTAXIS_KINASE_CORE")
  systems <- no_chew$regulatory$systems
  expect_equal(
    systems$missing_components[systems$system_id == "SYS_RF_CHEMOTAXIS_KINASE"][[1]],
    "COMP_RF_CHEW"
  )

  # Adaptation is a two-enzyme cycle; one half does not run it.
  half_adaptation <- evaluate_gifts(ko_annotations(c(
    "K03406", setdiff(chemotaxis_downstream_markers(), "K03412")
  )))
  gift <- half_adaptation$regulatory$gifts[
    half_adaptation$regulatory$gifts$gift_id == "chemotaxis_signal_transduction",
  ]
  expect_false(gift$complete)
  expect_equal(gift$missing_functions_best_circuit[[1]], "RF_CHEMOTAXIS_ADAPTATION")
})

test_that("an Escherichia coli annotation is not called receptor-less", {
  # E. coli K-12 carries no generic-MCP orthologue: its receptors are assigned
  # to the characterised groups. A reception function that accepted only K03406
  # would call the canonical chemotaxis organism incomplete.
  eco <- evaluate_gifts(ko_annotations(c(
    "K05874", "K05875", "K05876", "K03776", chemotaxis_downstream_markers()
  )))
  gift <- eco$regulatory$gifts[
    eco$regulatory$gifts$gift_id == "chemotaxis_signal_transduction",
  ]
  expect_true(gift$complete)

  functions <- eco$regulatory$functions
  expect_equal(
    functions$best_system[functions$function_id == "RF_CHEMOTAXIS_RECEPTION"],
    "SYS_RF_CHEMOTAXIS_RECEPTOR_CHARACTERISED"
  )
})

test_that("signal termination is accessory and has non-homologous alternatives", {
  base <- c("K03406", chemotaxis_downstream_markers())
  without <- evaluate_gifts(ko_annotations(base))
  expect_true(without$regulatory$gifts$complete[
    without$regulatory$gifts$gift_id == "chemotaxis_signal_transduction"
  ])

  # CheZ, CheC and CheX are unrelated in sequence and each satisfies the
  # function on its own.
  for (phosphatase in c("K03414", "K03410", "K03409")) {
    with_termination <- evaluate_gifts(ko_annotations(c(base, phosphatase)))
    functions <- with_termination$regulatory$functions
    expect_true(
      functions$supported[functions$function_id == "RF_CHEMOTAXIS_SIGNAL_TERMINATION"],
      info = phosphatase
    )
  }
})

test_that("a generic chemoreceptor does not license a ligand-specific claim", {
  # The invariant, on curated content: the specificity of a claim may not exceed
  # the specificity of its evidence. K03406 identifies the signalling domain
  # every chemoreceptor shares; it is not evidence of an aspartate sensor.
  generic <- evaluate_gifts(ko_annotations(c("K03406", chemotaxis_downstream_markers())))
  calls <- generic$regulatory$gifts
  expect_true(calls$complete[calls$gift_id == "chemotaxis_signal_transduction"])
  expect_false(calls$complete[calls$gift_id == "aspartate_chemoreception"])
  expect_equal(
    calls$missing_functions_best_circuit[calls$gift_id == "aspartate_chemoreception"][[1]],
    "RF_ASPARTATE_RECEPTION"
  )

  # Tar is evidence for both, because it is a chemoreceptor and it is that one.
  specific <- evaluate_gifts(ko_annotations(c("K05875", chemotaxis_downstream_markers())))
  calls <- specific$regulatory$gifts
  expect_true(calls$complete[calls$gift_id == "chemotaxis_signal_transduction"])
  expect_true(calls$complete[calls$gift_id == "aspartate_chemoreception"])

  # A serine receptor is a chemoreceptor and is not an aspartate receptor.
  serine <- evaluate_gifts(ko_annotations(c("K05874", chemotaxis_downstream_markers())))
  calls <- serine$regulatory$gifts
  expect_true(calls$complete[calls$gift_id == "chemotaxis_signal_transduction"])
  expect_false(calls$complete[calls$gift_id == "aspartate_chemoreception"])

  # The accepted markers of the aspartate receptor component are exactly Tar.
  machinery <- get_gift_machinery("aspartate_chemoreception")
  expect_equal(
    unique(machinery$accession[machinery$function_id == "RF_ASPARTATE_RECEPTION"]),
    "K05875"
  )
})

test_that("the two chemotaxis circuits share their downstream functions", {
  core <- get_gift_machinery("chemotaxis_signal_transduction")
  aspartate <- get_gift_machinery("aspartate_chemoreception")
  shared <- intersect(unique(core$function_id), unique(aspartate$function_id))

  # Reception differs; everything downstream is the same curated rows.
  expect_setequal(
    shared,
    c("RF_CHEMOTAXIS_KINASE_CORE", "RF_CHEMOTAXIS_RESPONSE_REGULATOR",
      "RF_CHEMOTAXIS_ADAPTATION")
  )
  expect_false("RF_CHEMOTAXIS_RECEPTION" %in% aspartate$function_id)
  expect_false("RF_ASPARTATE_RECEPTION" %in% core$function_id)
})

test_that("the phosphate response completes through either cognate circuit", {
  # A Gram-negative-style annotation: PhoR with PhoB.
  phob <- evaluate_gifts(ko_annotations(c("K07636", "K07657")))
  gift <- phob$regulatory$gifts[
    phob$regulatory$gifts$gift_id == "phosphate_starvation_response",
  ]
  expect_true(gift$complete)
  expect_equal(gift$best_circuit, "CIRCUIT_PHO_PHOR_PHOB")
  expect_equal(gift$number_of_complete_circuits, 1L)

  # A Bacillus-style annotation: the same sensor with the other regulator.
  phop <- evaluate_gifts(ko_annotations(c("K07636", "K07658")))
  gift <- phop$regulatory$gifts[
    phop$regulatory$gifts$gift_id == "phosphate_starvation_response",
  ]
  expect_true(gift$complete)
  expect_equal(gift$best_circuit, "CIRCUIT_PHO_PHOR_PHOP")

  # The sensor alone is half a circuit, and the report says which half is absent.
  sensor_only <- evaluate_gifts(ko_annotations("K07636"))
  gift <- sensor_only$regulatory$gifts[
    sensor_only$regulatory$gifts$gift_id == "phosphate_starvation_response",
  ]
  expect_false(gift$complete)
  expect_equal(gift$minimum_missing_functions, 1L)
  expect_equal(gift$best_circuit, "CIRCUIT_PHO_PHOR_PHOB")
  expect_equal(gift$missing_functions_best_circuit[[1]], "RF_PHO_RESPONSE_PHOB")
})

test_that("the magnesium-sensing PhoP is not accepted as a phosphate regulator", {
  # K07660 shares the gene name PhoP with K07658 and is a different protein,
  # the response regulator of the magnesium-sensing PhoP/PhoQ system. Accepting
  # it would call a phosphate response from a genome that has none.
  collision <- evaluate_gifts(ko_annotations(c("K07636", "K07660")))
  gift <- collision$regulatory$gifts[
    collision$regulatory$gifts$gift_id == "phosphate_starvation_response",
  ]
  expect_false(gift$complete)

  machinery <- get_gift_machinery("phosphate_starvation_response")
  expect_false("K07660" %in% machinery$accession)
  expect_setequal(
    unique(machinery$accession[grepl("^RF_PHO_RESPONSE", machinery$function_id)]),
    c("K07657", "K07658")
  )
})

test_that("the Pst transporter is accessory to the phosphate circuit", {
  # It is how PhoR learns the phosphate status, but it is independently a
  # transport capability, and requiring it here would curate the same biology
  # twice.
  minimal <- evaluate_gifts(ko_annotations(c("K07636", "K07657")))
  expect_true(minimal$regulatory$gifts$complete[
    minimal$regulatory$gifts$gift_id == "phosphate_starvation_response"
  ])

  full <- evaluate_gifts(ko_annotations(c(
    "K07636", "K07657", "K02040", "K02037", "K02038", "K02036", "K02039"
  )))
  functions <- full$regulatory$functions
  expect_true(functions$supported[functions$function_id == "RF_PHO_PHOSPHATE_STATUS"])

  partial <- evaluate_gifts(ko_annotations(c(
    "K07636", "K07657", "K02040", "K02037", "K02038", "K02036"
  )))
  systems <- partial$regulatory$systems
  expect_equal(
    systems$missing_components[systems$system_id == "SYS_RF_PST_PHOU"][[1]],
    "COMP_RF_PHOU"
  )
  # Still complete: the accessory function does not enter the call.
  expect_true(partial$regulatory$gifts$complete[
    partial$regulatory$gifts$gift_id == "phosphate_starvation_response"
  ])
})

# ---------------------------------------------------------------------------
# Curated defense content
# ---------------------------------------------------------------------------

test_that("type I restriction-modification needs all three subunits", {
  complete <- evaluate_gifts(ko_annotations(c("K01153", "K03427", "K01154")))
  gift <- complete$defense$gifts[
    complete$defense$gifts$gift_id == "type_i_restriction_modification",
  ]
  expect_true(gift$complete)
  expect_equal(gift$best_mechanism, "MECH_TYPE_I_RM")
  expect_equal(gift$evidence_confidence, "curated")

  # An orphan methyltransferase is real biology and defends against nothing.
  orphan <- evaluate_gifts(ko_annotations(c("K03427", "K01154")))
  gift <- orphan$defense$gifts[
    orphan$defense$gifts$gift_id == "type_i_restriction_modification",
  ]
  expect_false(gift$complete)
  expect_equal(gift$minimum_missing_functions, 1L)
  expect_equal(gift$missing_functions_best_mechanism[[1]], "DF_TYPE_I_RM_RESTRICTION")

  # Restriction without host protection is not a curated mechanism either.
  unprotected <- evaluate_gifts(ko_annotations(c("K01153", "K01154")))
  gift <- unprotected$defense$gifts[
    unprotected$defense$gifts$gift_id == "type_i_restriction_modification",
  ]
  expect_false(gift$complete)
  expect_equal(gift$missing_functions_best_mechanism[[1]], "DF_TYPE_I_RM_MODIFICATION")
})

test_that("the restriction-modification claim stops short of a target sequence", {
  # HsdS specificity comes from variable target recognition domains that the
  # orthology group does not resolve, so no sequence is claimed.
  expect_false(any(grepl("eco_?ki|target_sequence", list_gifts()$gift_id)))
  notes <- get_gift_machinery("type_i_restriction_modification")
  specificity <- notes[notes$function_id == "DF_TYPE_I_RM_SPECIFICITY", ]
  expect_equal(unique(specificity$accession), "K01154")
  expect_match(unique(specificity$notes), "target recognition domains")
})

test_that("the type I-E Cascade complex is jointly required", {
  cascade <- c("K19123", "K19046", "K19124", "K19125", "K19126")
  complete <- evaluate_gifts(ko_annotations(c(cascade, "K07012")))
  gift <- complete$defense$gifts[
    complete$defense$gifts$gift_id == "type_i_e_crispr_cas_machinery",
  ]
  expect_true(gift$complete)
  expect_equal(gift$minimum_missing_functions, 0L)

  # Losing one subunit removes the whole surveillance function. Completeness is
  # discrete: "four of the five Cascade subunits" is not a defense call.
  partial <- evaluate_gifts(ko_annotations(c(setdiff(cascade, "K19125"), "K07012")))
  gift <- partial$defense$gifts[
    partial$defense$gifts$gift_id == "type_i_e_crispr_cas_machinery",
  ]
  expect_false(gift$complete)
  expect_equal(gift$missing_functions_best_mechanism[[1]], "DF_CRISPR_I_E_SURVEILLANCE")
  systems <- partial$defense$systems
  expect_equal(
    systems$missing_components[systems$system_id == "SYS_DF_CASCADE_I_E"][[1]],
    "COMP_DF_CASD"
  )
})

test_that("CRISPR spacer acquisition is accessory to the encoded machinery", {
  cascade <- c("K19123", "K19046", "K19124", "K19125", "K19126")
  without <- evaluate_gifts(ko_annotations(c(cascade, "K07012")))
  expect_true(without$defense$gifts$complete[
    without$defense$gifts$gift_id == "type_i_e_crispr_cas_machinery"
  ])

  with_adaptation <- evaluate_gifts(ko_annotations(c(cascade, "K07012", "K15342", "K09951")))
  functions <- with_adaptation$defense$functions
  expect_true(functions$supported[functions$function_id == "DF_CRISPR_ADAPTATION"])
})

test_that("the CRISPR claim is about encoded machinery, not interference", {
  # An array supplies the guide RNAs and is a repeat-spacer locus detected by
  # structure, not a protein annotation. The claim is narrowed rather than
  # pretending a Cas accession evidences an array.
  description <- get_gift("type_i_e_crispr_cas_machinery")$description
  expect_match(description, "CRISPR array", fixed = TRUE)
  expect_match(description, "does not mean the system can interfere", fixed = TRUE)

  # The split Cas3 HD module is not accepted as evidence of the whole nuclease.
  machinery <- get_gift_machinery("type_i_e_crispr_cas_machinery")
  expect_false("K07475" %in% machinery$accession)
  expect_equal(
    unique(machinery$accession[
      machinery$function_id == "DF_CRISPR_I_E_INTERFERENCE_NUCLEASE"
    ]),
    "K07012"
  )

  # The limitation is recorded as a curation decision, not left implicit.
  changes <- database_changelog("type_i_e_crispr_cas_machinery")
  expect_true("DBC-20260818-CRISPR-ARRAY-LIMIT" %in% changes$change_id)
})

test_that("mercury detoxification is complete on merA alone", {
  complete <- evaluate_gifts(ko_annotations("K00520"))
  gift <- complete$defense$gifts[
    complete$defense$gifts$gift_id == "mercury_detoxification",
  ]
  expect_true(gift$complete)
  expect_equal(gift$best_mechanism, "MECH_MER_HG")
  expect_equal(gift$evidence_confidence, "curated")

  # Reduction is what the claim rests on. The transporters without it are a
  # delivery capability that detoxifies nothing.
  transport <- evaluate_gifts(ko_annotations(c("K08363", "K08364")))
  gift <- transport$defense$gifts[
    transport$defense$gifts$gift_id == "mercury_detoxification",
  ]
  expect_false(gift$complete)
  expect_equal(gift$minimum_missing_functions, 1L)
  expect_equal(gift$missing_functions_best_mechanism[[1]], "DF_MER_HG_REDUCTION")
})

test_that("delivery, induction and organomercurial lysis are accessory", {
  accessory <- c(
    "DF_MER_HG_DELIVERY", "DF_MER_HG_INDUCTION", "DF_MER_ORGANOMERCURIAL_LYSIS"
  )
  bare <- evaluate_gifts(ko_annotations("K00520"))
  functions <- bare$defense$functions
  expect_false(any(functions$supported[functions$function_id %in% accessory]))
  expect_true(bare$defense$gifts$complete[
    bare$defense$gifts$gift_id == "mercury_detoxification"
  ])

  # merC substitutes for the merT-merP pair, which is why requiring the pair
  # would refuse genomes whose operon is built the other way.
  merc <- evaluate_gifts(ko_annotations(c("K00520", "K19058")))
  systems <- merc$defense$systems
  expect_true(systems$supported[systems$system_id == "SYS_DF_MERC"])
  expect_false(systems$supported[systems$system_id == "SYS_DF_MERTP"])
  functions <- merc$defense$functions
  expect_true(functions$supported[functions$function_id == "DF_MER_HG_DELIVERY"])

  # MerT without MerP is not the pair: the two are jointly required.
  half <- evaluate_gifts(ko_annotations(c("K00520", "K08363")))
  functions <- half$defense$functions
  expect_false(functions$supported[functions$function_id == "DF_MER_HG_DELIVERY"])
})

test_that("the MerA sequence family is an alternative, not a second requirement", {
  family <- evaluate_gifts(data.frame(
    gene_id = "gene_1", namespace = "TIGRFAM", accession = "TIGR02053",
    stringsAsFactors = FALSE
  ))
  gift <- family$defense$gifts[
    family$defense$gifts$gift_id == "mercury_detoxification",
  ]
  expect_true(gift$complete)
  # Evidence rows are alternatives within a component, and the family carries
  # its own confidence rather than inheriting the orthology group's.
  expect_equal(gift$evidence_confidence, "high-confidence")
})

test_that("the mercury claim is detoxification machinery, not resistance", {
  description <- get_gift("mercury_detoxification")$description
  expect_match(description, "does not mean the organism survives", fixed = TRUE)

  facets <- get_facets("mercury_detoxification")
  expect_equal(
    facets$value[facets$facet == "defense_class"], "chemical_detoxification"
  )

  # The class is named for the mechanism, and its definition excludes the
  # mechanisms that would turn it into a resistance drawer.
  terms <- list_facets("defense_class")
  definition <- terms$definition[terms$value == "chemical_detoxification"]
  expect_match(definition, "Efflux, sequestration and repair of the damage are excluded")

  changes <- database_changelog("mercury_detoxification")
  expect_true(all(
    c("DBC-20260819-MERCURY-DEFENSE", "DBC-20260819-CHEMICAL-DETOXIFICATION-CLASS")
    %in% changes$change_id
  ))
})

test_that("merD and the unmatchable namespaces are not mer evidence", {
  machinery <- get_gift_machinery("mercury_detoxification")

  # MerD modulates MerR-driven transcription rather than activating the
  # promoter, so as an alternative it would let a genome with no activator
  # claim induction.
  expect_false("K19057" %in% machinery$accession)
  expect_equal(
    unique(machinery$accession[machinery$function_id == "DF_MER_HG_INDUCTION"]),
    "K08365"
  )

  # NF033555 and the InterPro entries name the enzymes more precisely than the
  # curated accessions do, and giftr's evidence layer can never match them.
  expect_false(any(grepl("^(NF|IPR)[0-9]", machinery$accession)))
  expect_equal(
    unique(machinery$accession[
      machinery$function_id == "DF_MER_ORGANOMERCURIAL_LYSIS"
    ]),
    "K00221"
  )

  changes <- database_changelog("mercury_detoxification")
  expect_true("DBC-20260819-MER-EVIDENCE-REFUSALS" %in% changes$change_id)
})

test_that("no curated GIFT claims a behaviour or an outcome", {
  # Machinery is what the evidence supports, so machinery is what is claimed.
  ids <- list_gifts()$gift_id
  expect_false(any(grepl(
    "motility|twitching|competence|adhesion|virulence|resistance|phage_resistance",
    ids
  )))
  for (gift_id in list_gifts(type = c("structural", "regulatory", "defense"))$gift_id) {
    expect_match(
      get_gift(gift_id)$description, "does not mean|does not establish",
      info = gift_id
    )
  }
})
