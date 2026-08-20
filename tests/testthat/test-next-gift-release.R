# Release 2026.20.1: nitrogen fixation, assimilatory sulfate reduction and the
# isocitrate-anchored glyoxylate bypass. These tests protect evidence
# specificity and the Boolean layer at which each alternative belongs.

release_annotations <- function(...) {
  accessions <- unlist(list(...), use.names = FALSE)
  data.frame(
    gene_id = paste0("gene_", seq_along(accessions)),
    namespace = ifelse(grepl("^[0-9]+\\.[0-9]+", accessions), "EC", "KO"),
    accession = accessions,
    stringsAsFactors = FALSE
  )
}

release_call <- function(gift_id, ...) {
  result <- evaluate_gifts(release_annotations(...))
  result$gifts$complete[result$gifts$gift_id == gift_id]
}

test_that("nitrogen fixation requires a complete Mo or V architecture", {
  mo <- c("K02588", "K02586", "K02591", "K02585", "K02587", "K02592")
  vanadium <- c(
    "K22899", "K22896", "K22897", "K22898", "K02585", "K22903", "K02592"
  )

  expect_true(release_call("nitrogen_fixation", mo))
  expect_true(release_call("nitrogen_fixation", vanadium))
  for (missing in seq_along(mo)) {
    expect_false(release_call("nitrogen_fixation", mo[-missing]))
  }
  for (missing in seq_along(vanadium)) {
    expect_false(release_call("nitrogen_fixation", vanadium[-missing]))
  }

  # The common screen is deliberately refused: NifH is an electron-delivery
  # component, not a complete nitrogenase or its cofactor assembly pathway.
  expect_false(release_call("nitrogen_fixation", "K02588"))
  expect_false(release_call("nitrogen_fixation", "K00531"))
  expect_equal(nrow(get_gift_routes("nitrogen_fixation")), 2L)
})

test_that("nitrogenase evidence traces through every required component", {
  mo <- c("K02588", "K02586", "K02591", "K02585", "K02587", "K02592")
  result <- evaluate_gifts(release_annotations(mo))
  trace <- trace_gift(result, "nitrogen_fixation")

  expect_equal(unique(trace$route_id), "N_FIX_MO")
  expect_equal(unique(trace$rhea_master), "RHEA:21448")
  expect_true(all(trace$reaction_supported))
  expect_true(all(trace$system_supported))
  expect_true(all(trace$component_supported))
  expect_setequal(trace$accession, mo)
  expect_true(all(!is.na(trace$gene_id)))
})

test_that("assimilatory sulfate routes are explicit alternatives", {
  paps_nadph <- c("K00958", "K00860", "1.8.4.8", "K00380", "K00381")
  paps_fd <- c("K00958", "K00860", "1.8.4.8", "K00392")
  aps_nadph <- c("K00958", "1.8.4.10", "K00380", "K00381")
  aps_fd <- c("K00958", "1.8.4.10", "K00392")

  for (route in list(paps_nadph, paps_fd, aps_nadph, aps_fd)) {
    expect_true(release_call("assimilatory_sulfate_reduction", route))
  }
  expect_equal(nrow(get_gift_routes("assimilatory_sulfate_reduction")), 4L)

  # The heterodimer and fusion implementations operate at the enzyme-system
  # layer and therefore satisfy the same activation reactions.
  expect_true(release_call(
    "assimilatory_sulfate_reduction",
    "K00956", "K00957", "K00860", "1.8.4.8", "K00392"
  ))
  expect_true(release_call(
    "assimilatory_sulfate_reduction",
    "K00955", "K00957", "1.8.4.8", "K00392"
  ))

  # K00390 spans both CysH activities and cannot choose the APS or PAPS route.
  expect_false(release_call(
    "assimilatory_sulfate_reduction",
    "K00958", "K00860", "K00390", "K00380", "K00381"
  ))
  # A partial NADPH sulfite reductase and dissimilatory sulfur markers are not
  # accepted evidence for the assimilatory capability.
  expect_false(release_call(
    "assimilatory_sulfate_reduction", "K00958", "1.8.4.10", "K00380"
  ))
  expect_false(release_call(
    "assimilatory_sulfate_reduction", "K00394", "K00395", "K11180", "K11181"
  ))
})

test_that("the glyoxylate bypass is atomic and marker-specific", {
  expect_true(release_call("glyoxylate_bypass", "K01637", "K01638"))
  expect_false(release_call("glyoxylate_bypass", "K01637"))
  expect_false(release_call("glyoxylate_bypass", "K01638"))
  expect_false(release_call("glyoxylate_bypass", "K01637", "K01639"))

  anchors <- get_gift_anchors("glyoxylate_bypass")
  expect_setequal(anchors$anchor_id[anchors$role == "input"], c("ISOCITRATE", "ACETYL_COA"))
  expect_setequal(anchors$anchor_id[anchors$role == "output"], c("SUCCINATE", "MALATE"))
  expect_false("GLYOXYLATE" %in% anchors$anchor_id)

  # The recut upper segment and either oxidative or bypass branch are separate
  # calls. No route repeats citrate synthase or aconitase in the bypass.
  expect_true(release_call("acetyl_coa_to_isocitrate", "K01647", "K01681"))
  expect_true(release_call("isocitrate_to_oxoglutarate", "K00031"))
  reactions <- get_gift_reactions("glyoxylate_bypass")
  expect_setequal(reactions$rhea_master, c("RHEA:13245", "RHEA:18181"))
})

test_that("new anchors compose without inventing internal-metabolite edges", {
  graph <- gift_graph()
  expect_true(any(
    graph$from_gift == "nitrogen_fixation" &
      graph$to_gift == "ammonium_assimilation" & graph$shared_anchor == "AMMONIUM"
  ))
  expect_true(all(c(
    "cysteine_biosynthesis_sulfide", "methionine_biosynthesis_sulfhydrylation"
  ) %in% graph$to_gift[
    graph$from_gift == "assimilatory_sulfate_reduction" &
      graph$shared_anchor == "SULFIDE"
  ]))
  expect_false(any(
    graph$shared_anchor == "SULFITE" &
      graph$to_gift == "assimilatory_sulfate_reduction"
  ))
  expect_true(any(
    graph$from_gift == "glyoxylate_bypass" &
      graph$to_gift == "malolactic_fermentation" & graph$shared_anchor == "MALATE"
  ))
})
