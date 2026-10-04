# The structural validator proves the source tables agree with each other. These
# tests protect the other half: that a plausible but wrong external fact -- an
# accession that does not exist, a Rhea identifier that is not a master, an
# anchor on the wrong side of its route -- fails the build against the pinned
# reference snapshot instead of compiling as curated content.

snapshot_dir <- function() {
  system.file("extdata", "reference-snapshot", package = "gifter")
}

# A copy of the packaged snapshot, so a test can make it disagree with a source
# table without editing either the sources or the packaged extract.
snapshot_copy <- function(envir = parent.frame()) {
  copy <- tempfile("gifter-snapshot-")
  dir.create(copy)
  withr::defer(unlink(copy, recursive = TRUE), envir = envir)
  file.copy(list.files(snapshot_dir(), full.names = TRUE), copy)
  copy
}

edit_snapshot <- function(dir, file, mutate) {
  path <- file.path(dir, file)
  table <- gifter:::.read_reference_table(path)
  utils::write.table(
    mutate(table), path, sep = "\t", quote = FALSE, row.names = FALSE, na = ""
  )
}

edit_source <- function(source_dir, table, mutate) {
  write_source(source_dir, table, mutate(read_source(source_dir, table)))
}

external_errors <- function(source_dir, reference = snapshot_dir()) {
  validate_gifter_sources(
    source_dir, stop_on_error = FALSE, reference_dir = reference
  )$errors
}

test_that("the packaged sources agree with the pinned reference snapshot", {
  report <- validate_gifter_sources(
    system.file("extdata", "database-source", package = "gifter"),
    stop_on_error = FALSE, reference_dir = snapshot_dir()
  )
  expect_identical(report$errors, character())
  # KEGG's links are not redistributed, so without the cached extract the basis
  # cannot be recomputed, and validation must say so rather than stay silent.
  expect_match(report$warnings, "Evidence basis was not recomputed", all = FALSE)
})

test_that("a KEGG accession the snapshot has not confirmed is refused", {
  source_dir <- gifter_source_copy()
  add_test_marker(source_dir, "KO", "K99999")
  expect_match(
    external_errors(source_dir), "KEGG accessions not confirmed current.*KO:K99999",
    all = FALSE
  )
})

test_that("a Rhea identifier that is not a master is refused", {
  reference <- snapshot_copy()
  edit_snapshot(reference, "rhea-reactions.tsv", function(rhea) {
    rhea$status[rhea$rhea_id == "RHEA:14905"] <- "directional"
    rhea$master_id[rhea$rhea_id == "RHEA:14905"] <- "RHEA:14902"
    rhea
  })
  expect_match(
    external_errors(gifter_source_copy(), reference),
    "Not a Rhea master identifier: RHEA:14905 \\(directional, master RHEA:14902\\)",
    all = FALSE
  )
})

test_that("a Rhea identifier absent from the snapshot is refused", {
  source_dir <- gifter_source_copy()
  for (table in c("reactions", "enzyme_systems", "route_reactions", "reaction_xrefs")) {
    edit_source(source_dir, table, function(data) {
      for (column in intersect(c("reaction_id", "rhea_master"), names(data))) {
        data[[column]][data[[column]] %in% "RHEA:14905"] <- "RHEA:99999999"
      }
      data
    })
  }
  expect_match(
    external_errors(source_dir),
    "Rhea identifiers absent from the pinned snapshot: RHEA:99999999", all = FALSE
  )
})

test_that("an equation or a ChEBI name is imported and cannot be typed", {
  source_dir <- gifter_source_copy()
  edit_source(source_dir, "reactions", function(reactions) {
    reactions$equation[reactions$reaction_id == "RHEA:14905"] <- "PRPP = IMP"
    reactions
  })
  edit_source(source_dir, "anchors", function(anchors) {
    anchors$chebi_name[anchors$anchor_id == "IMP"] <- "inosinate"
    anchors
  })
  errors <- external_errors(source_dir)
  expect_match(errors, "reactions.equation must be the Rhea master equation.*RHEA:14905", all = FALSE)
  expect_match(errors, "anchors.chebi_name must be the ChEBI name.*IMP", all = FALSE)
})

test_that("an anchor must use the ChEBI form Rhea writes", {
  reference <- snapshot_copy()
  edit_snapshot(reference, "chebi-compounds.tsv", function(compounds) {
    compounds$rhea_form[compounds$chebi_id == "CHEBI:58053"] <- "CHEBI:1"
    compounds
  })
  expect_match(
    external_errors(gifter_source_copy(), reference),
    "Anchors must use the ChEBI form Rhea writes at pH 7.3: IMP CHEBI:58053 -> CHEBI:1",
    all = FALSE
  )
})

test_that("a cross-reference Rhea does not record needs a stated reason", {
  source_dir <- gifter_source_copy()
  append_source(
    source_dir, "reaction_xrefs",
    reaction_id = "RHEA:14905", namespace = "KEGG_REACTION", accession = "R01072X"
  )
  errors <- external_errors(source_dir)
  expect_match(
    errors, "Cross-references that Rhea does not record.*RHEA:14905 KEGG_REACTION:R01072X",
    all = FALSE
  )

  edit_source(source_dir, "reaction_xrefs", function(xrefs) {
    xrefs$notes[xrefs$accession == "R01072X"] <- "Fixture reason."
    xrefs
  })
  expect_false(any(grepl("Cross-references that Rhea does not record", external_errors(source_dir))))
})

test_that("a declared anchor must be on the side of the route its role claims", {
  # PRPP is the input of purine core biosynthesis and stands on the right of the
  # Rhea master, so the step is curated in reverse. Flipping it makes the route
  # produce its own input.
  source_dir <- gifter_source_copy()
  edit_source(source_dir, "route_reactions", function(steps) {
    flipped <- steps$route_id == "PCR_FOLATE_DIRECT_FOLATE" & steps$reaction_id == "RHEA:14905"
    steps$orientation[flipped] <- "forward"
    steps
  })
  expect_match(
    external_errors(source_dir),
    "PCR_FOLATE_DIRECT_FOLATE: input anchor PRPP \\(CHEBI:58017\\) is not consumed",
    all = FALSE
  )
})

test_that("an interconversion route satisfies its anchors in either direction", {
  sources <- system.file("extdata", "database-source", package = "gifter")
  gifts <- read_source(sources, "gifts")
  routes <- read_source(sources, "gift_routes")
  reversible <- routes$route_id[
    routes$gift_id %in% gifts$gift_id[gifts$mode %in% "interconversion"]
  ]
  expect_gt(length(reversible), 0L)
  expect_false(any(grepl(
    paste0("^(", paste(reversible, collapse = "|"), "): (input|output) anchor"),
    external_errors(sources)
  )))
})

test_that("a route that is not one chain needs a recorded exception", {
  source_dir <- gifter_source_copy()
  edit_source(source_dir, "route_chemistry_exceptions", function(exceptions) {
    exceptions[exceptions$route_id != "PRO_CANONICAL", , drop = FALSE]
  })
  expect_match(
    external_errors(source_dir),
    "PRO_CANONICAL: RHEA:14109 is not linked to the first step",
    all = FALSE
  )
})

test_that("an exception of the wrong kind does not excuse a break", {
  source_dir <- gifter_source_copy()
  edit_source(source_dir, "route_chemistry_exceptions", function(exceptions) {
    exceptions$kind[exceptions$route_id == "PRO_CANONICAL"] <- "anchor_form"
    exceptions
  })
  expect_match(external_errors(source_dir), "PRO_CANONICAL: RHEA:14109 is not linked", all = FALSE)
})

test_that("an exception that excuses nothing is refused", {
  source_dir <- gifter_source_copy()
  append_source(
    source_dir, "route_chemistry_exceptions",
    route_id = "PCR_FOLATE_DIRECT_FOLATE", kind = "spontaneous_step",
    subject = "RHEA:17453", rationale = "Fixture exception with nothing to excuse."
  )
  expect_match(
    external_errors(source_dir),
    "route_chemistry_exceptions rows that excuse nothing: PCR_FOLATE_DIRECT_FOLATE RHEA:17453",
    all = FALSE
  )
})

test_that("two steps sharing a cofactor on the same side are not linked by it", {
  participants <- data.frame(
    master_id = rep(c("RHEA:1", "RHEA:2"), each = 4),
    side = rep(c("L", "L", "R", "R"), 2),
    chebi_id = c("CHEBI:A", "CHEBI:SAM", "CHEBI:B", "CHEBI:SAH",
                 "CHEBI:C", "CHEBI:SAM", "CHEBI:D", "CHEBI:SAH"),
    stringsAsFactors = FALSE
  )
  steps <- data.frame(
    reaction_id = c("RHEA:1", "RHEA:2"), orientation = "forward",
    step_order = c("1", "2"), stringsAsFactors = FALSE
  )
  chemistry <- gifter:::.route_chemistry(steps, participants)
  expect_identical(gifter:::.route_breaks(chemistry), "RHEA:2")

  participants$chebi_id[participants$chebi_id == "CHEBI:C"] <- "CHEBI:B"
  chemistry <- gifter:::.route_chemistry(steps, participants)
  expect_identical(gifter:::.route_breaks(chemistry), character())
})

test_that("the snapshot pins the upstream releases the database records", {
  source_dir <- gifter_source_copy()
  edit_source(source_dir, "database_release", function(release) {
    release$rhea_release <- "1"
    release
  })
  expect_match(
    external_errors(source_dir), "database_release.rhea_release is 1 but the snapshot pins",
    all = FALSE
  )
})

# ---- evidence contract: enforced without a snapshot ---------------------------

contract_errors <- function(mutate, table = "component_markers") {
  source_dir <- gifter_source_copy()
  edit_source(source_dir, table, mutate)
  validate_gifter_sources(source_dir, stop_on_error = FALSE)$errors
}

test_that("confidence, evidence type and basis are closed vocabularies", {
  expect_match(contract_errors(function(rows) {
    rows$confidence[[1]] <- "excellent"
    rows
  }), "Invalid component_markers.confidence: excellent", all = FALSE)
  expect_match(contract_errors(function(rows) {
    rows$evidence_type[[1]] <- "hunch"
    rows
  }), "Invalid component_markers.evidence_type: hunch", all = FALSE)
  expect_match(contract_errors(function(rows) {
    rows$basis[[1]] <- "verified"
    rows
  }, "structural_component_markers"), "Invalid structural_component_markers.basis: verified", all = FALSE)
})

test_that("an unsupported assignment cannot be reported as curated", {
  errors <- contract_errors(function(rows) {
    row <- which(rows$basis %in% "unsupported")[[1]]
    rows$confidence[[row]] <- "curated"
    rows
  })
  expect_match(
    errors, "basis = unsupported may not claim more than putative confidence", all = FALSE
  )
  sources <- read_source(
    system.file("extdata", "database-source", package = "gifter"), "component_markers"
  )
  expect_true(all(sources$confidence[sources$basis %in% "unsupported"] %in%
                    c("putative", "ambiguous", "insufficient evidence")))
})

test_that("a reference is a publication or a result, never a curation document", {
  expect_match(contract_errors(function(rows) {
    rows$reference[[1]] <- "inst/doc/proposal-vitamin-biosynthesis.md"
    rows
  }), "component_markers.reference must list PMID", all = FALSE)
  expect_match(contract_errors(function(rows) {
    rows$reference[[1]] <- "see Smith 2019"
    rows
  }), "component_markers.reference must list PMID", all = FALSE)
  expect_identical(contract_errors(function(rows) {
    rows$reference[[1]] <- "PMID:12345678; DOI:10.1000/example.1;data-raw/reference/t2ss-roles.tsv"
    rows
  }), character())
  expect_match(contract_errors(function(rows) {
    row <- which(rows$basis %in% "reference")[[1]]
    rows$reference[[row]] <- NA
    rows
  }, "defense_component_markers"), "basis = reference must record one", all = FALSE)
})

test_that("marker basis is derived from KEGG and Rhea records, in a fixed order", {
  tables <- gifter:::.read_gifter_sources(
    system.file("extdata", "database-source", package = "gifter")
  )
  reference <- gifter:::.read_reference_snapshot(snapshot_dir())
  row <- which(tables$component_markers$component_id == "COMP_14905_CATALYTIC" &
                 tables$component_markers$accession == "K00764")
  basis <- function(kind, value, cite = NA_character_) {
    tables$component_markers$reference[[row]] <- cite
    links <- data.frame(
      namespace = "KO", accession = "K00764", kind = kind, value = value,
      stringsAsFactors = FALSE
    )
    gifter:::.derive_marker_basis(tables, reference, links)$component_markers[[row]]
  }
  expect_identical(basis(c("reaction", "ec"), c("R01072", "2.4.2.14")), "kegg_reaction_link")
  expect_identical(basis("ec", "2.4.2.14"), "ec_match")
  # A link to some other reaction supports nothing about this one.
  expect_identical(basis("reaction", "R00001"), "unsupported")
  expect_identical(basis("reaction", "R00001", "PMID:1"), "reference")
  # A derivable basis wins over a citation: the citation is then additional.
  expect_identical(basis("ec", "2.4.2.14", "PMID:1"), "ec_match")
})

test_that("a family marker is supported only by an EC number its release carries", {
  tables <- gifter:::.read_gifter_sources(
    system.file("extdata", "database-source", package = "gifter")
  )
  reference <- gifter:::.read_reference_snapshot(snapshot_dir())
  rows <- tables$component_markers
  row <- which(rows$namespace == "NCBIFAM" & rows$basis %in% "ec_match")[[1]]
  system <- tables$enzyme_components$system_id[
    tables$enzyme_components$component_id == rows$component_id[[row]]
  ]
  reaction <- tables$enzyme_systems$reaction_id[tables$enzyme_systems$system_id == system]
  ec <- reference$rhea_xrefs$accession[
    reference$rhea_xrefs$master_id == reaction & reference$rhea_xrefs$namespace == "EC"
  ][[1]]
  basis <- function(value) {
    links <- data.frame(
      namespace = "NCBIFAM", accession = rows$accession[[row]], kind = "ec",
      value = value, stringsAsFactors = FALSE
    )
    gifter:::.derive_marker_basis(tables, reference, links)$component_markers
  }
  expect_identical(basis(ec)[[row]], "ec_match")
  # A profile whose release metadata names another activity does not support
  # this one, however plausible its product name.
  expect_identical(basis("9.9.9.9")[[row]], "unsupported")
  # No KEGG extract was supplied, so KO rows are left undecided, not condemned.
  expect_true(all(is.na(basis(ec)[rows$namespace == "KO"])))
})

test_that("a declared NCBIfam grade must be the grade the pinned release gives", {
  reference <- snapshot_copy()
  edit_snapshot(reference, "marker-accessions.tsv", function(accessions) {
    accessions$family_type[accessions$accession == "NF040708.3"] <- "subfamily"
    accessions
  })
  expect_match(
    external_errors(gifter_source_copy(), reference),
    "declares an NCBIfam grade the pinned release does not give: NF040708.3 is subfamily, not equivalog",
    all = FALSE
  )
})

test_that("a family or profile accession absent from the pinned release is refused", {
  source_dir <- gifter_source_copy()
  add_test_marker(source_dir, "CAZY", "GH9999")
  add_test_marker(source_dir, "NCBIFAM", "NF999999.1")
  expect_match(
    external_errors(source_dir),
    "Family or profile accessions absent from the pinned release: CAZY:GH9999, NCBIFAM:NF999999.1",
    all = FALSE
  )
})

test_that("a typed basis that disagrees with the derivation is refused", {
  links <- tempfile(fileext = ".tsv")
  withr::defer(unlink(links))
  utils::write.table(
    data.frame(namespace = "KO", accession = "K00764", kind = "ec", value = "2.4.2.14"),
    links, sep = "\t", quote = FALSE, row.names = FALSE
  )
  errors <- validate_gifter_sources(
    gifter_source_copy(), stop_on_error = FALSE,
    reference_dir = snapshot_dir(), marker_links = links
  )$errors
  expect_match(
    errors, "component_markers.basis is derived and must not be typed.*K00764 is ec_match",
    all = FALSE
  )
})

test_that("a review names a version the GIFT has reached and who signed it", {
  review <- function(...) {
    source_dir <- gifter_source_copy()
    append_source(source_dir, "gift_reviews", gift_id = "purine_core_biosynthesis", ...)
    validate_gifter_sources(source_dir, stop_on_error = FALSE)$errors
  }
  expect_identical(
    review(version = "1", reviewer = "A. Curator", reviewed_at = "2026-10-04"), character()
  )
  expect_match(
    review(version = "7", reviewer = "A. Curator", reviewed_at = "2026-10-04"),
    "gift_reviews.version must be a version the GIFT has reached", all = FALSE
  )
  expect_match(
    review(version = "1", reviewer = NA_character_, reviewed_at = "2026-10-04"),
    "gift_reviews needs a reviewer", all = FALSE
  )
})

test_that("no GIFT is recorded as reviewed until a person signs it", {
  # The table is written by a human reviewer. An agent that curates a GIFT must
  # not also attest to it, so the shipped table starts empty.
  connection <- gifter_db_connect()
  withr::defer(DBI::dbDisconnect(connection))
  expect_identical(
    DBI::dbGetQuery(connection, "SELECT COUNT(*) AS n FROM gift_review")$n, 0L
  )
})
