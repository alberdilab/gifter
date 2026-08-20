# Shikimate-derived aromatic biosynthesis. What separates this layer from the
# ones before it is a step whose marker has a taxonomic hole rather than a
# specificity problem, a bifunctional enzyme that must stay at the system layer
# instead of becoming a second route, an auxin whose alternative routes were all
# refused for want of discriminating markers, and a grouping facet that must not
# collapse into substrate_class. Most of these tests defend one of those four.

shikimate_gifts <- c(
  "chorismate_biosynthesis", "salicylate_biosynthesis",
  "indole_3_acetate_biosynthesis"
)

aromatic_complete <- function(...) {
  result <- evaluate_gifts(ko_annotations(c(...)))
  result$gifts$gift_id[result$gifts$complete]
}

aromatic_source <- function(table) {
  packaged <- system.file("extdata", "database-source", package = "gifter")
  if (!nzchar(packaged)) packaged <- file.path("inst", "extdata", "database-source")
  utils::read.delim(
    file.path(packaged, paste0(table, ".tsv")),
    colClasses = "character", check.names = FALSE, na.strings = c("", "NA")
  )
}

# The six steps of the shikimate pathway that are curated as required, each
# satisfied by its commonest orthology group.
shikimate_required_markers <- c(
  "K01626", "K01735", "K03786", "K00891", "K00800", "K01736"
)

test_that("the three shikimate aromatic GIFTs are metabolic and anabolic", {
  gifts <- list_gifts()
  layer <- gifts[gifts$gift_id %in% shikimate_gifts, ]
  expect_equal(nrow(layer), length(shikimate_gifts))
  expect_true(all(layer$gift_type == "metabolic"))
  expect_true(all(layer$mode == "anabolic"))
})

test_that("the shikimate pathway completes without a shikimate dehydrogenase marker", {
  # The step is curated as not required because K00014 misses most cyanobacteria
  # and two thirds of Actinomycetota, which do make aromatic amino acids.
  expect_true("chorismate_biosynthesis" %in% aromatic_complete(shikimate_required_markers))
  expect_false("chorismate_biosynthesis" %in% aromatic_complete(shikimate_required_markers[-6]))
})

test_that("the shikimate dehydrogenase step is curated as not required, deliberately", {
  route_reactions <- aromatic_source("route_reactions")
  step <- route_reactions[
    route_reactions$route_id == "CHOR_SHIKIMATE" &
      route_reactions$reaction_id == "RHEA:17737",
  ]
  expect_equal(nrow(step), 1L)
  expect_equal(step$required, "0")
  # The biosynthetic direction reduces 3-dehydroshikimate; Rhea writes the
  # oxidation, so the route runs the master in reverse.
  expect_equal(step$orientation, "reverse")
  # Every other step of the route is required.
  others <- route_reactions[
    route_reactions$route_id == "CHOR_SHIKIMATE" &
      route_reactions$reaction_id != "RHEA:17737",
  ]
  expect_true(all(others$required == "1"))
  expect_true(all(others$orientation == "forward"))
})

test_that("a non-KO marker can satisfy the shikimate dehydrogenase step", {
  # TIGR00507 is added for coverage, not specificity: it finds the AroE that
  # KEGG assigns to no KO in Mycobacterium and Synechocystis.
  markers <- aromatic_source("markers")
  expect_true(any(markers$namespace == "TIGRFAM" & markers$accession == "TIGR00507"))
  annotations <- rbind(
    ko_annotations(shikimate_required_markers),
    data.frame(
      gene_id = "gene_aroE", namespace = "TIGRFAM", accession = "TIGR00507",
      stringsAsFactors = FALSE
    )
  )
  result <- evaluate_gifts(annotations)
  expect_true(result$gifts$complete[result$gifts$gift_id == "chorismate_biosynthesis"])
  trace <- trace_gift(result, "chorismate_biosynthesis")
  expect_true(any(trace$accession == "TIGR00507"))
})

test_that("multifunctional shikimate proteins satisfy both of their steps", {
  # AroKB carries dehydroquinate synthase and shikimate kinase; AroDE carries
  # dehydroquinate dehydratase and shikimate dehydrogenase. Each is one marker
  # standing for two reactions, which is the system layer doing its job.
  expect_true("chorismate_biosynthesis" %in% aromatic_complete(
    "K01626", "K13829", "K03786", "K00800", "K01736"
  ))
  expect_true("chorismate_biosynthesis" %in% aromatic_complete(
    "K01626", "K01735", "K13832", "K00891", "K00800", "K01736"
  ))
})

test_that("non-homologous replacements are alternative systems of one reaction", {
  # Type I and type II dehydroquinate dehydratase are unrelated enzymes for the
  # same chemistry, so they must be systems, not routes.
  systems <- aromatic_source("enzyme_systems")
  dehydratase <- systems[systems$reaction_id == "RHEA:21096", ]
  expect_true(all(c("SYS_21096_TYPEI", "SYS_21096_TYPEII") %in% dehydratase$system_id))
  expect_true("chorismate_biosynthesis" %in% aromatic_complete(
    "K01626", "K01735", "K03785", "K00891", "K00800", "K01736"
  ))
  expect_true("chorismate_biosynthesis" %in% aromatic_complete(
    "K01626", "K01735", "K03786", "K00891", "K00800", "K01736"
  ))
  # The GIFT still owns exactly one route: alternatives live below it.
  expect_equal(nrow(get_gift_routes("chorismate_biosynthesis")), 1L)
})

test_that("chorismate biosynthesis composes into its curated consumers", {
  edges <- gift_graph()
  downstream <- edges$to_gift[edges$from_gift == "chorismate_biosynthesis"]
  expect_true(all(
    c("paba_biosynthesis", "menaquinone_biosynthesis", "salicylate_biosynthesis")
      %in% downstream
  ))
  expect_true(all(edges$shared_anchor[edges$from_gift == "chorismate_biosynthesis"] == "CHORISMATE"))
})

test_that("salicylate needs both reactions, and the bifunctional synthase supplies both", {
  # PchA and PchB together, or MbtI alone. Either half of the two-protein
  # implementation on its own is not enough.
  expect_true("salicylate_biosynthesis" %in% aromatic_complete("K01851", "K04782"))
  expect_true("salicylate_biosynthesis" %in% aromatic_complete("K04781"))
  expect_false("salicylate_biosynthesis" %in% aromatic_complete("K01851"))
  expect_false("salicylate_biosynthesis" %in% aromatic_complete("K04782"))
})

test_that("the salicylate synthase is curated as a system of both reactions, not a second route", {
  routes <- get_gift_routes("salicylate_biosynthesis")
  expect_equal(nrow(routes), 1L)
  markers <- aromatic_source("component_markers")
  components <- aromatic_source("enzyme_components")
  systems <- aromatic_source("enzyme_systems")
  mbti_components <- markers$component_id[markers$accession == "K04781"]
  mbti_systems <- components$system_id[components$component_id %in% mbti_components]
  reactions <- systems$reaction_id[systems$system_id %in% mbti_systems]
  expect_setequal(reactions, c("RHEA:18985", "RHEA:27874"))
})

test_that("the salicylate route reuses the curated isochorismate synthase reaction", {
  # Sharing the reaction rather than duplicating it is what lets one enzyme
  # system serve two GIFTs, and it is also why menaquinone gains PchA.
  route_reactions <- aromatic_source("route_reactions")
  shared <- route_reactions$route_id[route_reactions$reaction_id == "RHEA:18985"]
  expect_true(all(c("SAL_ISOCHORISMATE", "MK_CLASSIC") %in% shared))
  reactions <- aromatic_source("reactions")
  expect_equal(sum(reactions$reaction_id == "RHEA:18985"), 1L)
})

test_that("indole-3-acetate is called from the IAM route only", {
  expect_true("indole_3_acetate_biosynthesis" %in% aromatic_complete("K00466", "K21801"))
  expect_false("indole_3_acetate_biosynthesis" %in% aromatic_complete("K00466"))
  # The refused routes must not fire, however completely they are annotated.
  expect_false("indole_3_acetate_biosynthesis" %in% aromatic_complete(
    "K04103", "K00832", "K00128"
  ))
  expect_false("indole_3_acetate_biosynthesis" %in% aromatic_complete(
    "K01593", "K00128"
  ))
  expect_false("indole_3_acetate_biosynthesis" %in% aromatic_complete("K01501"))
})

test_that("the refused auxin markers are absent from the database entirely", {
  # Refusing a route means not curating its markers, so that no future edit can
  # attach them to this trait by accident.
  accessions <- aromatic_source("markers")$accession
  expect_false(any(c("K04103", "K01593", "K01501", "K23384") %in% accessions))
})

test_that("a broad amidase does not call the auxin without the diagnostic monooxygenase", {
  # K01426 matches 4948 bacteria. It is admitted only inside a route already
  # bounded by IaaM, which is the invariant-16 line: the broad marker never
  # licenses the specific trait on its own.
  expect_false("indole_3_acetate_biosynthesis" %in% aromatic_complete("K01426"))
  expect_true("indole_3_acetate_biosynthesis" %in% aromatic_complete("K00466", "K01426"))
})

test_that("the IAM route is curated as aerobic", {
  routes <- aromatic_source("gift_routes")
  expect_equal(routes$oxygen_requirement[routes$route_id == "IAA_IAM"], "aerobic")
})

test_that("gallate biosynthesis is refused and leaves no trace in the database", {
  expect_false("gallate_biosynthesis" %in% list_gifts()$gift_id)
  anchors <- aromatic_source("anchors")
  expect_false(any(grepl("GALLATE", anchors$anchor_id)))
  # The refusal is recorded rather than silent.
  changes <- aromatic_source("database_changes")
  expect_true("DBC-20260818-GALLATE-REFUSED" %in% changes$change_id)
})

test_that("biosynthetic_family groups the layer without duplicating substrate_class", {
  facets <- aromatic_source("gift_facets")
  family <- facets$gift_id[
    facets$facet == "biosynthetic_family" & facets$value == "shikimate_derived_aromatic"
  ]
  expect_setequal(
    family,
    c(
      shikimate_gifts, "paba_biosynthesis", "menaquinone_biosynthesis",
      # The amino acid layer joins the family from the other side: their rings
      # are built by the shikimate pathway, and the facet says so although
      # their substrate_class is amino_acid rather than aromatic_compound.
      "phenylalanine_biosynthesis", "tyrosine_biosynthesis",
      "tryptophan_biosynthesis"
    )
  )
  # If the two facets always agreed, one of them would be redundant. They do not.
  classes <- facets[facets$facet == "substrate_class" & facets$gift_id %in% family, ]
  expect_true(length(unique(classes$value)) > 1L)
  expect_true(all(
    classes$value[classes$gift_id %in% c("paba_biosynthesis", "menaquinone_biosynthesis")]
      == "cofactor"
  ))
})

test_that("the new facet vocabulary is registered for GIFTs and nothing else", {
  terms <- aromatic_source("facet_terms")
  added <- terms[terms$facet == "biosynthetic_family", ]
  expect_equal(nrow(added), 1L)
  expect_equal(added$applies_to, "gift")
  expect_true(nzchar(added$definition))
  expect_false("biosynthetic_family" %in% aromatic_source("anchor_facets")$facet)
})

test_that("the layer's reactions all carry a Rhea master", {
  reactions <- aromatic_source("reactions")
  added <- c(
    "RHEA:14717", "RHEA:21968", "RHEA:21096", "RHEA:17737", "RHEA:13121",
    "RHEA:21256", "RHEA:21020", "RHEA:27874", "RHEA:16165", "RHEA:34371"
  )
  layer <- reactions[reactions$reaction_id %in% added, ]
  expect_equal(nrow(layer), length(added))
  expect_false(any(is.na(layer$rhea_master)))
  expect_true(all(layer$rhea_master == layer$reaction_id))
})

test_that("the new anchors are boundaries, not every metabolite of the pathway", {
  anchors <- aromatic_source("anchors")$anchor_id
  expect_true(all(c("PEP", "SALICYLATE", "TRYPTOPHAN", "INDOLE_3_ACETATE") %in% anchors))
  # Internal intermediates stay internal, including the two the brief and the
  # archaeal argument both pointed at.
  expect_false(any(c("DHQ", "DEHYDROQUINATE", "DEHYDROSHIKIMATE", "SHIKIMATE",
                     "ISOCHORISMATE", "INDOLE_3_ACETAMIDE") %in% anchors))
})
