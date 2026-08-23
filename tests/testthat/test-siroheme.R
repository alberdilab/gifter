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

test_that("SIROHEME is a boundary, and the Ahb edge appeared only when evidence did", {
  anchors <- get_gift_anchors("siroheme_biosynthesis")
  expect_equal(anchors$anchor_id, c("UROGEN_III", "SIROHEME"))
  expect_equal(anchors$role, c("input", "output"))
  expect_true(all(anchors$compartment == "unspecified"))

  links <- get_gift_pathways("siroheme_biosynthesis")
  expect_setequal(links$accession, c("PWY-5194", "M00846"))
  expect_equal(links$relation[links$accession == "PWY-5194"], "equivalent")
  expect_equal(links$relation[links$accession == "M00846"], "subset_of")

  # Until database 2026.24.1 SIROHEME was an output nothing consumed, and the
  # absent edge was the visible consequence of evidence specificity rather than
  # a data gap. It exists now, through the declared anchor and nothing else.
  graph <- gift_graph()
  edge <- graph[graph$from_gift == "siroheme_biosynthesis", ]
  expect_equal(edge$to_gift, "siroheme_to_heme_b")
  expect_equal(edge$shared_anchor, "SIROHEME")
  expect_equal(edge$edge_quality, "exact")
  expect_false(any(graph$to_gift == "siroheme_biosynthesis"))
})

test_that("K22225 is admitted nowhere, and the Ahb heterodimer needs two profiles", {
  # The refusal that made this GIFT wait was never about the pathway. It was
  # that one accession matches both subunits of a jointly required heterodimer,
  # so a genome carrying a single ahbB gene would have satisfied AhbA as well.
  # Curating the route did not relax that: K22225 is still evidence for nothing.
  connection <- gifter_db_connect()
  withr::defer(gifter_db_disconnect(connection))
  admitted <- DBI::dbGetQuery(
    connection, "SELECT accession FROM marker WHERE accession = 'K22225'"
  )
  expect_equal(nrow(admitted), 0L)

  kegg_complete <- evaluate_gifts(ko_annotations(c("K22225", "K22226", "K22227")))
  call <- kegg_complete$gifts[kegg_complete$gifts$gift_id == "siroheme_to_heme_b", ]
  expect_false(call$complete)
  expect_equal(call$minimum_missing_reactions, 1L)
  expect_false("K22225" %in% kegg_complete$marker_vocabulary$accession)

  decisions <- database_changelog("siroheme_biosynthesis")
  expect_true(all(c(
    "DBC-20260820-SIROHEME-BIOSYNTHESIS",
    "DBC-20260820-AHB-DECARBOXYLASE-REFUSAL",
    "DBC-20260823-SIROHEME-TO-HEME-B"
  ) %in% decisions$change_id))
  refusal <- decisions[
    decisions$change_id == "DBC-20260820-AHB-DECARBOXYLASE-REFUSAL",
  ]
  expect_match(refusal$effect, "distinct observed genes", fixed = TRUE)
})

test_that("AhbA alone does not complete the route, and neither does any two of the three steps", {
  ncbifam <- function(accessions) {
    data.frame(
      gene_id = paste0("gene_", seq_along(accessions)),
      namespace = "NCBIFAM", accession = accessions, stringsAsFactors = FALSE
    )
  }
  call_of <- function(annotation) {
    result <- evaluate_gifts(annotation)
    result$gifts[result$gifts$gift_id == "siroheme_to_heme_b", ]
  }

  complete <- call_of(ncbifam(c("NF040708.3", "NF040707.3", "TIGR04546.1",
                                "TIGR04545.1")))
  expect_true(complete$complete)
  expect_equal(complete$best_implementation, "AHB_AHBD")

  # The heterodimer. AhbA without AhbB leaves the decarboxylase unsatisfied, and
  # so does AhbB without AhbA; the system needs two distinct proteins and the
  # two profiles are the only way to say so.
  for (alone in c("NF040708.3", "NF040707.3")) {
    partial <- call_of(ncbifam(c(alone, "TIGR04546.1", "TIGR04545.1")))
    expect_false(partial$complete, info = alone)
    expect_equal(partial$minimum_missing_reactions, 1L, info = alone)
  }

  # And the rest of the route is required too: a heterodimer that completes one
  # reaction is not a capability.
  expect_false(call_of(ncbifam(c("NF040708.3", "NF040707.3")))$complete)
  expect_false(
    call_of(ncbifam(c("NF040708.3", "NF040707.3", "TIGR04546.1")))$complete
  )
  expect_false(
    call_of(ncbifam(c("NF040708.3", "NF040707.3", "TIGR04545.1")))$complete
  )
})

test_that("the Ahb route composes through SIROHEME and admits both terminal steps", {
  reactions <- get_gift_reactions("siroheme_to_heme_b")
  expect_setequal(
    unique(reactions$rhea_master),
    c("RHEA:19093", "RHEA:37431", "RHEA:56520", "RHEA:56516")
  )
  expect_true(all(reactions$orientation == "forward"))

  # The alternative terminal step is the reaction heme_b_biosynthesis already
  # curates on its coproporphyrin route. Sharing a reaction between two GIFTs is
  # how alternative implementations are represented; it creates no edge, because
  # only declared anchors do that.
  chdc <- evaluate_gifts(rbind(
    data.frame(gene_id = paste0("gene_", 1:3), namespace = "NCBIFAM",
               accession = c("NF040708.3", "NF040707.3", "TIGR04546.1"),
               stringsAsFactors = FALSE),
    data.frame(gene_id = "gene_4", namespace = "KO", accession = "K00435",
               stringsAsFactors = FALSE)
  ))
  call <- chdc$gifts[chdc$gifts$gift_id == "siroheme_to_heme_b", ]
  expect_true(call$complete)
  expect_equal(call$best_implementation, "AHB_CHDC")

  # heme_b_biosynthesis is untouched by the new GIFT: its own boundaries, links
  # and calls are what they were.
  expect_false("PWY-7552" %in% get_gift_pathways("heme_b_biosynthesis")$accession)
  heme <- chdc$gifts[chdc$gifts$gift_id == "heme_b_biosynthesis", ]
  expect_false(heme$complete)

  links <- get_gift_pathways("siroheme_to_heme_b")
  expect_setequal(links$accession, c("M00847", "PWY-7552"))
  expect_true(all(links$relation == "equivalent"))
})
