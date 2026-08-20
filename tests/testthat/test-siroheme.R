siroheme_call <- function(markers) {
  result <- evaluate_gifts(ko_annotations(markers))
  result$gifts[result$gifts$gift_id == "siroheme_biosynthesis", ]
}

test_that("siroheme biosynthesis accepts multifunctional and split systems", {
  cysg <- siroheme_call("K02302")
  expect_true(cysg$complete)
  expect_equal(cysg$best_route, "SIROHEME_UROGEN")

  # Every maintained methyltransferase alternative can feed the complete
  # split SirC-SirB terminal pair.
  methyltransferases <- c("K00589", "K02303", "K02496", "K13542", "K13543")
  for (marker in methyltransferases) {
    expect_true(
      siroheme_call(c(marker, "K24866", "K03794"))$complete,
      info = marker
    )
  }

  # Met8 is bifunctional and supplies both dehydrogenation and ferrochelation.
  expect_true(siroheme_call(c("K02303", "K02304"))$complete)

  reactions <- get_gift_reactions("siroheme_biosynthesis")
  expect_equal(
    reactions$rhea_master,
    c("RHEA:32459", "RHEA:15613", "RHEA:24360")
  )
  expect_equal(reactions$orientation, c("forward", "forward", "reverse"))
  connection <- gifter_db_connect()
  withr::defer(gifter_db_disconnect(connection))
  oxygen <- DBI::dbGetQuery(
    connection,
    "SELECT oxygen_requirement FROM gift_route WHERE route_id = 'SIROHEME_UROGEN'"
  )
  expect_equal(oxygen$oxygen_requirement, "independent")
})

test_that("each siroheme reaction remains independently required", {
  missing <- list(
    `RHEA:32459` = c("K24866", "K03794"),
    `RHEA:15613` = c("K02303", "K03794"),
    `RHEA:24360` = c("K02303", "K24866")
  )
  for (reaction in names(missing)) {
    result <- siroheme_call(missing[[reaction]])
    expect_false(result$complete, info = reaction)
    expect_equal(result$missing_reactions_best_route[[1]], reaction,
                 info = reaction)
  }

  # K03795 is a cobaltochelatase marker already used by corrin synthesis. Its
  # CbiX-family membership cannot establish iron insertion into siroheme.
  broad_chelatase <- siroheme_call(c("K02303", "K24866", "K03795"))
  expect_false(broad_chelatase$complete)
  expect_equal(broad_chelatase$missing_reactions_best_route[[1]], "RHEA:24360")
})

test_that("one CysG observation traces through three reaction components", {
  result <- evaluate_gifts(ko_annotations("K02302"))
  trace <- trace_gift(result, "siroheme_biosynthesis")
  expect_setequal(unique(trace$component_id), c(
    "COMP_32459_CYSG", "COMP_15613_CYSG2", "COMP_24360_CYSG"
  ))
  expect_equal(unique(trace$accession), "K02302")
})

test_that("SIROHEME is a boundary without manufacturing an Ahb edge", {
  anchors <- get_gift_anchors("siroheme_biosynthesis")
  expect_equal(anchors$anchor_id, c("UROGEN_III", "SIROHEME"))
  expect_equal(anchors$role, c("input", "output"))
  expect_true(all(anchors$compartment == "unspecified"))

  links <- get_gift_pathways("siroheme_biosynthesis")
  expect_setequal(links$accession, c("PWY-5194", "M00846"))
  expect_equal(links$relation[links$accession == "PWY-5194"], "equivalent")
  expect_equal(links$relation[links$accession == "M00846"], "subset_of")

  graph <- gift_graph()
  expect_false(any(graph$from_gift == "siroheme_biosynthesis"))
  expect_false(any(graph$to_gift == "siroheme_biosynthesis"))
})

test_that("the Ahb tail stays refused at K22225 specificity", {
  expect_false("siroheme_to_heme_b" %in% list_gifts()$gift_id)
  ahb <- evaluate_gifts(ko_annotations(c("K22225", "K22226", "K22227")))
  expect_false(any(ahb$gifts$gift_id == "siroheme_to_heme_b"))
  expect_false("K22225" %in% ahb$marker_vocabulary$accession)
  expect_false("PWY-7552" %in%
    get_gift_pathways("heme_b_biosynthesis")$accession)

  decisions <- database_changelog("siroheme_biosynthesis")
  expect_true(all(c(
    "DBC-20260820-SIROHEME-BIOSYNTHESIS",
    "DBC-20260820-AHB-DECARBOXYLASE-REFUSAL"
  ) %in% decisions$change_id))
  refusal <- decisions[
    decisions$change_id == "DBC-20260820-AHB-DECARBOXYLASE-REFUSAL",
  ]
  expect_match(refusal$effect, "distinct observed genes", fixed = TRUE)
})
