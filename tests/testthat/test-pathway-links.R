test_that("external pathways are linked with an explicit set relation", {
  links <- get_gift_pathways("threonine_biosynthesis")

  expect_true(all(
    c("gift_id", "namespace", "accession", "name", "relation", "notes") %in%
      names(links)
  ))
  expect_true("M00018" %in% links$accession)
  # gifter curates only the tail of the module, and says so.
  expect_equal(links$relation[links$accession == "M00018"], "subset_of")
  expect_equal(
    links$name[links$accession == "M00018"],
    "Threonine biosynthesis, aspartate => homoserine => threonine"
  )
})

test_that("the relation records how curated boundaries differ from the source", {
  relation <- function(gift_id, accession) {
    links <- get_gift_pathways(gift_id)
    links$relation[links$accession == accession]
  }

  # Boundaries kept.
  expect_equal(relation("serine_biosynthesis", "M00020"), "equivalent")
  expect_equal(relation("cysteine_biosynthesis_sulfide", "M00021"), "equivalent")
  # Boundaries cut.
  expect_equal(relation("adenylate_biosynthesis", "M00049"), "subset_of")
  expect_equal(
    relation("methionine_biosynthesis_transsulfuration", "M00017"), "subset_of"
  )
  # Module extended, and module partly reused.
  expect_equal(
    relation("methionine_biosynthesis_sulfhydrylation", "M00017"), "overlaps"
  )
  expect_equal(
    relation("cysteine_biosynthesis_homocysteine", "M00338"), "superset_of"
  )
  expect_equal(
    relation("cysteine_biosynthesis_homocysteine", "M00609"), "overlaps"
  )
})

test_that("one module can resolve to the several GIFTs that split it", {
  gifts <- gifts_for_pathway("M00018", namespace = "KEGG_MODULE")

  expect_setequal(
    gifts$gift_id,
    c(
      "aspartate_semialdehyde_biosynthesis", "homoserine_biosynthesis",
      "threonine_biosynthesis"
    )
  )
  expect_true(all(gifts$relation == "subset_of"))
  # M00016 runs from L-aspartate to L-lysine and now overlaps three curated
  # boundaries: the semialdehyde trunk, the diaminopimelate branch, and the
  # decarboxylation that is its final step.
  expect_setequal(
    gifts_for_pathway("M00016")$gift_id,
    c(
      "aspartate_semialdehyde_biosynthesis", "dap_biosynthesis",
      "lysine_biosynthesis_dap"
    )
  )
  expect_equal(nrow(gifts_for_pathway("M99999")), 0L)
})

test_that("pathway links are filterable and KEGG context is complete or named", {
  modules <- get_gift_pathways("aspartate_semialdehyde_biosynthesis", "KEGG_MODULE")
  expect_setequal(modules$accession, c("M00016", "M00017", "M00018"))
  expect_true(all(modules$namespace == "KEGG_MODULE"))

  # Every GIFT carries external context except where no external record covers
  # the capability. Five are such cases. Four are unlinked for the same reason:
  # KEGG describes them in a BRITE hierarchy rather than a pathway map, and a
  # hierarchy is not a pathway record whose boundaries could be compared.
  # Microbial collagenolysis sits in the bacterial toxin hierarchy; the type IVa
  # pilus in the secretion-system hierarchy, the only pilus module M00852 being
  # the unrelated type IVb toxin-coregulated pilus; and both defense systems in
  # the prokaryotic defense hierarchy. Recording a link whose boundaries could
  # not be compared would assert an equivalence that does not exist, so the
  # honest answer is no link -- named here rather than left as a silent gap.
  #
  # The two carnitine GIFTs are a sixth kind of gap: KEGG assigns the carnitine
  # monooxygenase and dehydrogenase orthology groups to no metabolic map at
  # all, so there is no record whose boundaries could be compared. Mercury
  # detoxification is the same gap in the defense model: K00520, K00221, K08363
  # and K08365 belong to no KEGG pathway and no module, which is why the mer
  # operon was curated from the operon biology rather than from a module
  # boundary. taurine
  # uptake is a seventh: map00430 carries the taurine chemistry but not the
  # translocation, and linking a transport GIFT to a chemistry map would assert
  # a containment that is false.
  #
  # citrate_fermentation is the fifth and its gap is a different one: KEGG has
  # no metabolic map for fermentative citrate cleavage at all. R00362 carries no
  # pathway link, and the citrate lyase orthology groups appear only in the
  # two-component system map, which describes the CitAB regulator rather than
  # the chemistry.
  gift_ids <- list_gifts()$gift_id
  linked <- vapply(gift_ids, function(id) nrow(get_gift_pathways(id)), integer(1))
  expect_equal(
    unname(gift_ids[linked == 0L]),
    c(
      "carnitine_degradation_trimethylamine", "carnitine_to_betaine",
      "citrate_fermentation", "collagen_cleavage", "mercury_detoxification",
      "taurine_uptake_abc", "type_i_e_crispr_cas_machinery",
      "type_i_restriction_modification", "type_iva_pilus"
    )
  )

  # A GIFT with no module at all still carries pathway context.
  glycine <- get_gift_pathways("glycine_biosynthesis")
  expect_equal(nrow(get_gift_pathways("glycine_biosynthesis", "KEGG_MODULE")), 0L)
  expect_true(all(glycine$namespace == "KEGG_PATHWAY"))
})

test_that("source validation rejects an unknown pathway relation", {
  source_dir <- file.path(tempfile("gifter-sources-"))
  dir.create(source_dir, recursive = TRUE)
  on.exit(unlink(source_dir, recursive = TRUE), add = TRUE)
  packaged <- system.file("extdata", "database-source", package = "gifter")
  if (!nzchar(packaged)) packaged <- file.path("inst", "extdata", "database-source")
  file.copy(list.files(packaged, full.names = TRUE), source_dir)

  path <- file.path(source_dir, "gift_xrefs.tsv")
  xrefs <- utils::read.delim(path, colClasses = "character", quote = "")
  xrefs$relation[1] <- "same_as"
  utils::write.table(
    xrefs, path, sep = "\t", quote = FALSE, row.names = FALSE, na = ""
  )

  expect_error(
    validate_gifter_sources(source_dir),
    "Invalid gift_xrefs.relation"
  )
})

test_that("source validation rejects a pathway link to an unknown GIFT", {
  source_dir <- file.path(tempfile("gifter-sources-"))
  dir.create(source_dir, recursive = TRUE)
  on.exit(unlink(source_dir, recursive = TRUE), add = TRUE)
  packaged <- system.file("extdata", "database-source", package = "gifter")
  if (!nzchar(packaged)) packaged <- file.path("inst", "extdata", "database-source")
  file.copy(list.files(packaged, full.names = TRUE), source_dir)

  path <- file.path(source_dir, "gift_xrefs.tsv")
  xrefs <- utils::read.delim(path, colClasses = "character", quote = "")
  xrefs$gift_id[1] <- "not_a_gift"
  utils::write.table(
    xrefs, path, sep = "\t", quote = FALSE, row.names = FALSE, na = ""
  )

  expect_error(validate_gifter_sources(source_dir), "gift_xrefs.gift_id")
})

test_that("the atlas publishes related pathways on each GIFT", {
  output <- tempfile(fileext = ".html")
  on.exit(unlink(output), add = TRUE)
  html <- paste(readLines(write_gifter_database_html(output), warn = FALSE), collapse = "\n")

  expect_match(html, "Related pathways", fixed = TRUE)
  expect_match(html, "pathway-section", fixed = TRUE)
  expect_match(html, "M00018", fixed = TRUE)
  expect_match(html, "M00609", fixed = TRUE)
  expect_match(html, "partly overlaps", fixed = TRUE)
  expect_match(html, "is part of", fixed = TRUE)

  db <- gifter_db_connect()
  on.exit(gifter_db_disconnect(db), add = TRUE)
  data <- gifter:::.gifter_report_data(db)
  entries <- regmatches(html, gregexpr("data-pathway-accession=", html))[[1]]
  expect_equal(length(entries), nrow(data$gift_pathways))
})
