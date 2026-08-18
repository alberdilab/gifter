amino_acid_gifts <- c(
  "serine_biosynthesis", "glycine_biosynthesis",
  "aspartate_semialdehyde_biosynthesis", "homoserine_biosynthesis",
  "threonine_biosynthesis", "methionine_biosynthesis_transsulfuration",
  "methionine_biosynthesis_sulfhydrylation", "cysteine_biosynthesis_sulfide",
  "cysteine_biosynthesis_homocysteine"
)

# Transsulfuration organism: sulfur reaches methionine through cysteine.
transsulfuration_markers <- function() {
  c(
    "K00058", "K00831", "K01079", "K00600", "K00928", "K12524", "K00133",
    "K00872", "K01733", "K00651", "K01739", "K01760", "K00549", "K00640",
    "K01738"
  )
}

# Direct sulfhydrylation organism: sulfide enters homoserine directly, and
# cysteine is recovered from homocysteine by the O-acetylserine route.
sulfhydrylation_markers <- function() {
  c(
    "K00058", "K00831", "K01079", "K00600", "K00928", "K00133", "K00003",
    "K00872", "K01733", "K00641", "K01740", "K24042", "K00640", "K01738",
    "K17216", "K17217"
  )
}

complete_gifts <- function(markers) {
  result <- evaluate_gifts(ko_annotations(markers))
  result$gifts$gift_id[result$gifts$complete]
}

test_that("the aspartate trunk is curated once and composed, not duplicated", {
  trunk <- get_gift_reactions("aspartate_semialdehyde_biosynthesis")$rhea_master
  homoserine <- get_gift_reactions("homoserine_biosynthesis")$rhea_master
  downstream <- unlist(lapply(
    c(
      "threonine_biosynthesis", "methionine_biosynthesis_transsulfuration",
      "methionine_biosynthesis_sulfhydrylation"
    ),
    function(gift) get_gift_reactions(gift)$rhea_master
  ))

  expect_setequal(trunk, c("RHEA:23776", "RHEA:24284"))
  expect_setequal(homoserine, c("RHEA:15757", "RHEA:15761"))
  expect_false(any(c(trunk, homoserine) %in% downstream))

  graph <- gift_graph()
  expect_true(all(
    c("threonine_biosynthesis", "methionine_biosynthesis_transsulfuration") %in%
      graph$to_gift[graph$shared_anchor == "HOMOSERINE"]
  ))
})

test_that("reaction direction is curated per route, not assumed forward", {
  serine <- get_gift_reactions("serine_biosynthesis")
  glycine <- get_gift_reactions("glycine_biosynthesis")

  expect_equal(
    serine$orientation[serine$rhea_master == "RHEA:14329"], "reverse"
  )
  expect_equal(
    serine$orientation[serine$rhea_master == "RHEA:12641"], "forward"
  )
  # The Rhea master runs glycine to serine, so glycine formation is reverse.
  expect_equal(glycine$orientation, "reverse")
  expect_equal(
    get_gift_reactions("homoserine_biosynthesis")$orientation,
    c("reverse", "reverse")
  )
})

test_that("methionine sulfur source separates two capabilities", {
  transsulfuration <- complete_gifts(transsulfuration_markers())
  sulfhydrylation <- complete_gifts(sulfhydrylation_markers())

  expect_true("methionine_biosynthesis_transsulfuration" %in% transsulfuration)
  expect_false("methionine_biosynthesis_sulfhydrylation" %in% transsulfuration)

  expect_true("methionine_biosynthesis_sulfhydrylation" %in% sulfhydrylation)
  expect_false(
    "methionine_biosynthesis_transsulfuration" %in% sulfhydrylation
  )

  # The declared inputs are what makes the two claims different.
  expect_true("CYSTEINE" %in% get_gift_anchors(
    "methionine_biosynthesis_transsulfuration"
  )$anchor_id)
  expect_true("SULFIDE" %in% get_gift_anchors(
    "methionine_biosynthesis_sulfhydrylation"
  )$anchor_id)
})

test_that("a cystathionine gamma-synthase alone does not claim sulfhydrylation", {
  # KEGG annotates K01739 to the sulfide-dependent reaction R01288. Accepting it
  # would make every transsulfuration genome positive for direct sulfide
  # assimilation, which is the distinction the two GIFTs exist to draw.
  markers <- get_reaction_systems("RHEA:27826")$accession
  expect_false("K01739" %in% markers)
  expect_true("K10764" %in% markers)
})

test_that("reverse transsulfuration ORs two taxonomically disjoint routes", {
  routes <- get_gift_routes("cysteine_biosynthesis_homocysteine")$route_id
  expect_setequal(routes, c("CYS_RT_SERINE", "CYS_RT_OAS"))

  serine_route <- complete_gifts(c("K01697", "K01758"))
  oas_route <- complete_gifts(c("K00640", "K17216", "K17217"))

  expect_true("cysteine_biosynthesis_homocysteine" %in% serine_route)
  expect_true("cysteine_biosynthesis_homocysteine" %in% oas_route)

  # The excluded SAM-cycle steps of M00609 must not be required evidence.
  markers <- unlist(lapply(
    get_gift_reactions("cysteine_biosynthesis_homocysteine")$rhea_master,
    function(rhea) get_reaction_systems(rhea)$accession
  ))
  expect_false(any(c("K00789", "K17462", "K01243", "K07173") %in% markers))
})

test_that("the required phosphoserine phosphatase names itself when missing", {
  result <- evaluate_gifts(ko_annotations(c("K00058", "K00831")))
  serine <- result$gifts[result$gifts$gift_id == "serine_biosynthesis", ]

  expect_false(serine$complete)
  expect_equal(serine$best_route, "SER_PHOSPHORYLATED")
  expect_equal(serine$minimum_missing_reactions, 1L)
  expect_equal(unlist(serine$missing_reactions_best_route), "RHEA:21208")
})

test_that("serine composes forward into glycine, cysteine and methionine", {
  graph <- gift_graph()
  from_serine <- graph$to_gift[graph$from_gift == "serine_biosynthesis"]

  expect_setequal(
    from_serine,
    c(
      "glycine_biosynthesis", "cysteine_biosynthesis_sulfide",
      "cysteine_biosynthesis_homocysteine"
    )
  )
  expect_true("methionine_biosynthesis_transsulfuration" %in%
    graph$to_gift[graph$shared_anchor == "CYSTEINE"])

  chain <- complete_gifts(transsulfuration_markers())
  expect_true(all(c(
    "serine_biosynthesis", "cysteine_biosynthesis_sulfide",
    "methionine_biosynthesis_transsulfuration"
  ) %in% chain))
})

test_that("homocysteine is an input boundary and never an output", {
  # Declaring it as an output closes the sulfur cycle and the database stops
  # building, so the asymmetry is a load-bearing curation decision.
  db <- giftr_db_connect()
  on.exit(giftr_db_disconnect(db), add = TRUE)

  roles <- DBI::dbGetQuery(
    db,
    paste(
      "SELECT DISTINCT ga.role FROM gift_anchor ga",
      "JOIN anchor a ON a.anchor_pk = ga.anchor_pk",
      "WHERE a.anchor_id = 'HOMOCYSTEINE'"
    )
  )$role

  expect_equal(roles, "input")
})

test_that("the sulfur cycle is rejected as a circular composition", {
  source_dir <- file.path(tempfile("giftr-sources-"))
  dir.create(source_dir, recursive = TRUE)
  on.exit(unlink(source_dir, recursive = TRUE), add = TRUE)
  packaged <- system.file("extdata", "database-source", package = "giftr")
  if (!nzchar(packaged)) packaged <- file.path("inst", "extdata", "database-source")
  file.copy(list.files(packaged, full.names = TRUE), source_dir)

  path <- file.path(source_dir, "gift_anchors.tsv")
  anchors <- utils::read.delim(path, colClasses = "character")
  anchors <- rbind(anchors, data.frame(
    gift_id = "methionine_biosynthesis_transsulfuration",
    anchor_id = "HOMOCYSTEINE",
    role = "output",
    ordinal = "2",
    stringsAsFactors = FALSE
  ))
  utils::write.table(
    anchors, path, sep = "\t", quote = FALSE, row.names = FALSE, na = ""
  )

  expect_error(
    validate_giftr_sources(source_dir),
    "Circular anabolic GIFT composition"
  )
})

test_that("every amino acid GIFT is curated to the full evidence depth", {
  for (gift_id in amino_acid_gifts) {
    expect_equal(nrow(get_gift(gift_id)), 1L)
    anchors <- get_gift_anchors(gift_id)
    expect_true(any(anchors$role == "input"))
    expect_true(any(anchors$role == "output"))

    reactions <- get_gift_reactions(gift_id)
    expect_gt(nrow(reactions), 0L)
    for (rhea in unique(reactions$rhea_master)) {
      systems <- get_reaction_systems(rhea)
      expect_gt(nrow(systems), 0L)
      expect_true(all(nzchar(systems$accession)))
    }
  }
})
