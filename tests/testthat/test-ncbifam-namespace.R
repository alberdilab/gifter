# The NCBIfam marker namespace.
#
# Admitting a marker namespace is an evidence-model decision, and the three
# rules it was admitted under are what these tests protect:
#
#   1. Equivalog grades only. Every other `family_type` groups sequences more
#      loosely than a function, which is the over-broad evidence invariant 16
#      refuses.
#   2. Versioned accessions. `NF040708` and `NF040708.3` are not guaranteed to
#      be the same profile, so an unversioned accession is pinned to nothing.
#   3. The original namespace release was additive. Later architecture
#      corrections can replace ambiguous KO evidence and are tested separately.
#
# The third is proved rather than asserted: the release before this one is
# reconstructed by deleting every NCBIFAM evidence row from the source tables
# and recompiling, and both databases are evaluated over the same marker sets.

ncbifam_source_rows <- function() {
  source_dir <- system.file("extdata", "database-source", package = "gifter")
  if (!nzchar(source_dir)) {
    source_dir <- file.path("..", "..", "inst", "extdata", "database-source")
  }
  rows <- utils::read.delim(
    file.path(source_dir, "component_markers.tsv"),
    colClasses = "character", check.names = FALSE, quote = "", comment.char = ""
  )
  rows[rows$namespace == "NCBIFAM", , drop = FALSE]
}

test_that("every NCBIfam marker is a versioned accession of an admitted grade", {
  rows <- ncbifam_source_rows()
  expect_gt(nrow(rows), 0L)

  # Rule 2. The suffix is the whole reason a marker in this namespace can be
  # re-checked when NCBIfam moves.
  expect_true(all(grepl("^(NF|TIGR)[0-9]+\\.[0-9]+$", rows$accession)))

  # Rule 1, as the database states it. Each row declares the grade it was
  # admitted under, in the same sentence as the curator's reasoning.
  grade <- sub("^family_type=", "",
               regmatches(rows$notes, regexpr("family_type=[A-Za-z_]+", rows$notes)))
  expect_equal(length(grade), nrow(rows))
  expect_setequal(unique(grade), c("equivalog", "equivalog_domain"))

  # Rule 1, as NCBIfam states it. The grade column of this table comes from the
  # pinned release rather than from gifter, which is what keeps the check from
  # asking the database to vouch for itself. The table is a curation input and
  # is absent from the built package, so the check runs where it can.
  audit <- file.path("..", "..", "data-raw", "reference",
                     "ncbifam-curated-grades.tsv")
  skip_if_not(file.exists(audit), "curation reference tables not available")
  pinned <- utils::read.delim(audit, colClasses = "character", quote = "",
                              comment.char = "", check.names = FALSE)
  expect_setequal(pinned$accession, unique(rows$accession))
  expect_true(all(pinned$in_release == "1"))
  expect_true(all(pinned$family_type %in% c("equivalog", "equivalog_domain")))
})

test_that("no profile refused on grade is admitted as a marker", {
  # The negative case, over the whole set of profiles that were close enough to
  # matter: every non-equivalog profile whose EC numbers reach a reaction gifter
  # curates. These are the accessions a curator would plausibly have reached
  # for, and the grade is the only thing standing between them and the database.
  refusals <- file.path("..", "..", "data-raw", "reference",
                        "ncbifam-grade-refusals.tsv")
  skip_if_not(file.exists(refusals), "curation reference tables not available")
  refused <- utils::read.delim(refusals, colClasses = "character", quote = "",
                               comment.char = "", check.names = FALSE)
  expect_gt(nrow(refused), 0L)
  expect_false(any(refused$family_type %in% c("equivalog", "equivalog_domain")))

  connection <- gifter_db_connect()
  on.exit(gifter_db_disconnect(connection), add = TRUE)
  present <- DBI::dbGetQuery(connection, "SELECT accession FROM marker")$accession
  expect_length(intersect(refused$accession, present), 0L)
})

test_that("the compiler refuses an NCBIfam profile of a non-equivalog grade", {
  # The rule has to hold for content nobody has written yet, so it is enforced
  # where new content arrives rather than only asserted about current content.
  source_dir <- gifter_source_copy()
  add_test_marker(source_dir, "NCBIFAM", "NF999001.1")
  append_rows(source_dir, "component_markers", data.frame(
    component_id = "COMP_15753_CATALYTIC", namespace = "NCBIFAM",
    accession = "NF999001.1", evidence_type = "sequence_family",
    confidence = "high-confidence", source = "Synthetic fixture",
    notes = "family_type=subfamily. A subfamily groups sequences, not a function.",
    stringsAsFactors = FALSE
  ))

  expect_error(
    validate_gifter_sources(source_dir),
    "admits only equivalog and equivalog_domain NCBIfam profiles"
  )
})

test_that("an NCBIfam marker must declare its grade and carry a version", {
  source_dir <- gifter_source_copy()
  add_test_marker(source_dir, "NCBIFAM", "NF999002")
  append_rows(source_dir, "component_markers", data.frame(
    component_id = "COMP_15753_CATALYTIC", namespace = "NCBIFAM",
    accession = "NF999002", evidence_type = "sequence_family",
    confidence = "high-confidence", source = "Synthetic fixture",
    notes = "Copied from an annotator without a grade or a release.",
    stringsAsFactors = FALSE
  ))

  expect_error(validate_gifter_sources(source_dir), "release version suffix")
  expect_error(validate_gifter_sources(source_dir), "must declare family_type")
})

test_that("an NCBIfam marker respects its curated component logic", {
  # The original namespace release added OR evidence to existing components.
  #
  # Structurally: on every component that existed before the namespace, the
  # NCBIfam profile sits beside a marker that was already there. Nothing became
  # newly satisfiable. The later serine-deamination correction deliberately
  # replaces an ambiguous KO with NCBIfam-only components; its AND logic is
  # exercised in test-amino-acids.R.
  #
  # Behaviourally: where a component has both, either marker alone completes the
  # reaction. A layer that required both would be modelling a heterodimer, which
  # is a claim about the enzyme rather than about the annotation that finds it.
  connection <- gifter_db_connect()
  on.exit(gifter_db_disconnect(connection), add = TRUE)

  evidence <- DBI::dbGetQuery(connection, paste(
    "SELECT c.component_id, r.reaction_id, m.namespace FROM component_marker cm",
    "JOIN enzyme_component c ON c.component_pk = cm.component_pk",
    "JOIN enzyme_system s ON s.system_pk = c.system_pk",
    "JOIN reaction r ON r.reaction_pk = s.reaction_pk",
    "JOIN marker m ON m.marker_pk = cm.marker_pk"
  ))
  by_component <- split(evidence$namespace, evidence$component_id)
  ncbifam_only <- names(by_component)[
    vapply(by_component, function(x) all(x == "NCBIFAM"), logical(1))
  ]
  ahb <- get_gift_reactions("siroheme_to_heme_b")$reaction_id
  expect_setequal(
    unique(evidence$reaction_id[evidence$component_id %in% ncbifam_only]),
    c("RHEA:19093", "RHEA:19169")
  )
  expect_true("RHEA:19093" %in% ahb)

  # SerA is the worked OR case: one component, one KO, one NCBIfam profile.
  ko_only <- evaluate_reactions("K00058")$reactions
  ncbifam_only_call <- evaluate_reactions(data.frame(
    gene_id = "gene_1", namespace = "NCBIFAM", accession = "NF008759.0",
    stringsAsFactors = FALSE
  ))$reactions
  expect_true(ko_only$supported[ko_only$reaction_id == "RHEA:12641"])
  expect_true(ncbifam_only_call$supported[ncbifam_only_call$reaction_id == "RHEA:12641"])

  # AhbC is the same shape inside the new capability: KEGG orthology and an
  # NCBIfam equivalog for one protein, either of which satisfies the component.
  for (marker in list(c("KO", "K22226"), c("NCBIFAM", "TIGR04546.1"))) {
    ahbc <- evaluate_reactions(data.frame(
      gene_id = "gene_1", namespace = marker[[1]], accession = marker[[2]],
      stringsAsFactors = FALSE
    ))$reactions
    expect_true(ahbc$supported[ahbc$reaction_id == "RHEA:37431"], info = marker[[2]])
  }

  # And the multisubunit case, where attaching a subunit profile to the wrong
  # component would have been the easy mistake. CitD alone does not build a
  # citrate lyase: the alpha, beta and ligase components are still required.
  citd <- evaluate_reactions(data.frame(
    gene_id = "gene_1", namespace = "NCBIFAM", accession = "TIGR01608.1",
    stringsAsFactors = FALSE
  ))$reactions
  expect_false(citd$supported[citd$reaction_id == "RHEA:10760"])
  expect_equal(citd$minimum_missing_components[citd$reaction_id == "RHEA:10760"], 3L)
})

# Reconstruct the pre-namespace comparison frame: remove every NCBIFAM row and
# the capabilities whose current definitions depend on NCBIfam-only evidence.
# Serine deamination was revised later and has its own regression tests.
pre_namespace_sources <- function(envir = parent.frame()) {
  source_dir <- gifter_source_copy(envir)
  drop <- function(table, column, values) {
    rows <- read_source(source_dir, table)
    write_source(source_dir, table, rows[!rows[[column]] %in% values, , drop = FALSE])
  }
  gift <- "siroheme_to_heme_b"
  routes <- c("AHB_AHBD", "AHB_CHDC")
  # RHEA:56516 stays: heme_b_biosynthesis curated it first and still uses it.
  reactions <- c("RHEA:19093", "RHEA:37431", "RHEA:56520")
  systems <- c("SYS_19093_AHBAB", "SYS_37431_AHBC", "SYS_56520_AHBD")
  components <- c("COMP_19093_AHBA", "COMP_19093_AHBB", "COMP_37431_AHBC",
                  "COMP_56520_AHBD")

  for (table in c("gifts", "gift_anchors", "gift_facets", "gift_xrefs", "gift_evidence",
                  "gift_routes", "change_gifts")) {
    drop(table, "gift_id", gift)
  }
  drop("route_reactions", "route_id", routes)
  drop("reactions", "reaction_id", reactions)
  drop("reaction_xrefs", "reaction_id", reactions)
  drop("enzyme_systems", "system_id", systems)
  drop("enzyme_components", "component_id", components)
  drop("component_markers", "component_id", components)
  drop("change_gifts", "change_id", "DBC-20260823-SIROHEME-TO-HEME-B")
  drop("database_changes", "change_id", "DBC-20260823-SIROHEME-TO-HEME-B")

  # The 2026.37.1 serine correction is intentionally outside the additive
  # namespace comparison: its old K01752 semantics were unsound, and deleting
  # its NCBIfam markers would leave required components without evidence.
  serine <- "serine_deamination"
  for (table in c("gifts", "gift_anchors", "gift_facets", "gift_xrefs",
                  "gift_evidence", "gift_routes", "change_gifts")) {
    drop(table, "gift_id", serine)
  }
  drop("route_reactions", "route_id", "SER_DEAMINATION")
  drop("reaction_xrefs", "reaction_id", "RHEA:19169")
  drop("reactions", "reaction_id", "RHEA:19169")
  serine_systems <- c("SYS_19169_SDAA", "SYS_19169_SDA_SPLIT", "SYS_19169_SDS")
  serine_components <- c("COMP_19169_CATALYTIC", "COMP_19169_SDA_ALPHA",
                         "COMP_19169_SDA_BETA", "COMP_19169_SDS")
  drop("enzyme_systems", "system_id", serine_systems)
  drop("enzyme_components", "component_id", serine_components)
  drop("component_markers", "component_id", serine_components)
  drop("database_changes", "change_id", "DBC-20261004-SERINE-DEAMINATION-SYSTEMS")

  evidence <- read_source(source_dir, "component_markers")
  write_source(source_dir, "component_markers",
               evidence[evidence$namespace != "NCBIFAM", , drop = FALSE])

  # A marker is registered once and used by any of the four evidence tables, so
  # the orphan check has to read all of them. K22226 and K22227 arrived with the
  # Ahb route and support nothing without it.
  used <- unlist(lapply(
    c("component_markers", "structural_component_markers",
      "regulatory_component_markers", "defense_component_markers"),
    function(table) {
      rows <- read_source(source_dir, table)
      paste(rows$namespace, rows$accession)
    }
  ))
  markers <- read_source(source_dir, "markers")
  keep <- paste(markers$namespace, markers$accession) %in% used
  write_source(source_dir, "markers", markers[keep, , drop = FALSE])
  source_dir
}

test_that("admitting the namespace changed no call over the vocabulary that preceded it", {
  before <- build_test_database(pre_namespace_sources())
  after <- gifter_db_connect()
  on.exit(gifter_db_disconnect(after), add = TRUE)

  vocabulary <- DBI::dbGetQuery(before, paste(
    "SELECT DISTINCT m.namespace, m.accession FROM component_marker cm",
    "JOIN marker m ON m.marker_pk = cm.marker_pk"
  ))
  expect_gt(nrow(vocabulary), 1000L)
  expect_false("NCBIFAM" %in% vocabulary$namespace)

  annotation_of <- function(rows) {
    data.frame(
      gene_id = paste0("gene_", seq_len(nrow(rows))),
      namespace = rows$namespace, accession = rows$accession,
      stringsAsFactors = FALSE
    )
  }

  # The whole pre-NCBIfam vocabulary, then deterministic subsets of it. The
  # subsets matter more than the union: a difference in Boolean logic shows up
  # where a route is partially satisfied, not where everything is.
  set.seed(20260823)
  sets <- c(
    list(vocabulary),
    lapply(seq_len(24), function(i) {
      vocabulary[sample.int(nrow(vocabulary), size = as.integer(nrow(vocabulary) / 3)), ,
                 drop = FALSE]
    })
  )
  # Plus the vocabulary of each component the additive release touched, which is
  # where a regression would be concentrated if there were one.
  touched <- unique(ncbifam_source_rows()$component_id)
  per_component <- DBI::dbGetQuery(before, paste(
    "SELECT c.component_id, m.namespace, m.accession FROM component_marker cm",
    "JOIN enzyme_component c ON c.component_pk = cm.component_pk",
    "JOIN marker m ON m.marker_pk = cm.marker_pk"
  ))
  sets <- c(sets, lapply(touched, function(id)
    per_component[per_component$component_id == id, c("namespace", "accession"),
                  drop = FALSE]))

  compared <- c("gift_id", "complete", "evidence_confidence",
                "number_of_complete_implementations", "best_implementation",
                "minimum_missing_requirements", "minimum_missing_reactions")
  for (rows in sets) {
    if (!nrow(rows)) next
    annotation <- annotation_of(rows)
    old <- evaluate_gifts(annotation, db = before)$gifts
    new <- evaluate_gifts(annotation, db = after)$gifts
    # `siroheme_to_heme_b` did not exist before; every other call must match.
    new <- new[new$gift_id %in% old$gift_id, ]
    expect_setequal(old$gift_id, new$gift_id)
    expect_equal(new[compared], old[compared])
  }
})

test_that("the version suffix decides which namespace an accession belongs to", {
  # A user pasting accessions out of a bakta or InterProScan table gets the
  # namespace inferred, and the suffix is what separates the two identities: a
  # bare `TIGR03948` is the unversioned TIGRFAM row gifter recorded from
  # InterPro, while `TIGR04545.1` is the JCVI profile as the pinned NCBIfam
  # release publishes it. Reading one as the other would silently substitute a
  # different marker.
  mapped <- map_markers(c("NF040708.3", "TIGR04545.1", "TIGR03948",
                          "nf040707.3"))
  expect_equal(
    mapped$namespace, c("NCBIFAM", "NCBIFAM", "TIGRFAM", "NCBIFAM")
  )
  # Lower case survives normalisation as the accession the database holds.
  expect_equal(mapped$accession[[4]], "NF040707.3")
  expect_true(all(mapped$matched))

  # An unversioned NCBIfam accession is refused rather than promoted to the
  # versioned marker. The failure is loud, which is the point: the alternative
  # is a genome that quietly looks as though it lacks the capability.
  expect_error(map_markers("NF040708"), "Could not infer namespaces")
  unversioned <- map_markers(data.frame(
    namespace = "NCBIFAM", accession = "NF040708", stringsAsFactors = FALSE
  ))
  expect_false(unversioned$matched)
})
