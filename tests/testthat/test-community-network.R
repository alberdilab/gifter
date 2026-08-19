# Potential resource-handoff topology. The assessment is
# inst/doc/proposal-quantitative-traits.md.
#
# The invariant this layer exists to protect is that an edge is a claim, and the
# claim is bounded by curation. It may only come from a composition edge the
# database already derives, it may only cross organisms through a molecule
# curation declared extracellular, and it never becomes evidence that exchange
# happens.

test_that("edges follow the curated chain and nothing else", {
  network <- community_network(arabinoxylan_community())
  edges <- unique(network$edges[c("from_genome", "to_genome")])
  expect_setequal(
    paste(edges$from_genome, edges$to_genome),
    c("A B", "B C", "B D")
  )
  # Every edge names the GIFTs and the anchor that produced it, and that anchor
  # is one gift_graph actually derives.
  expect_true(all(network$edges$shared_anchor %in% gift_graph()$shared_anchor))
  expect_true(all(
    paste(network$edges$from_gift, network$edges$to_gift) %in%
      paste(gift_graph()$from_gift, gift_graph()$to_gift)
  ))
})

test_that("a cytoplasmic anchor never hands a molecule between organisms", {
  # C and D both encode uptake and downstream catabolism, so the XYLOSE_IN link
  # exists twice over. It is cytoplasmic: neither genome can pass it to the
  # other, and an edge would invent a transfer the compartment model forbids.
  network <- community_network(arabinoxylan_community())
  expect_false("XYLOSE_IN" %in% network$edges$shared_anchor)
  expect_equal(nrow(network$edges[network$edges$from_genome == "C", ]), 0L)

  compartments <- get_gift_anchors("xylose_uptake_abc")
  expect_true("cytoplasmic" %in% compartments$compartment)

  # The same link inside one genome is an ordinary composition step and is
  # still reported as complete there.
  link <- network$chain_coverage[
    network$chain_coverage$shared_anchor == "XYLOSE_IN", ,
    drop = FALSE
  ]
  expect_equal(link$status, "within_genome")
  expect_false(link$transferable)
  expect_equal(link$within_genome, "C, D")
})

test_that("a link split across genomes through an internal anchor completes nowhere", {
  # Uptake in one genome and downstream catabolism in another. Both halves are
  # encoded, no genome holds both, and the shared molecule never leaves a cell,
  # so nothing completes the link. Calling that "distributed" would be the
  # error the status exists to prevent.
  uptake <- evaluate_gifts(namespaced_annotations(
    c("KO:K10543", "KO:K10544", "KO:K10545")
  ))
  catabolism <- evaluate_gifts(namespaced_annotations(c("KO:K01805", "KO:K00854")))
  network <- community_network(giftr_community(U = uptake, V = catabolism))
  link <- network$chain_coverage[
    network$chain_coverage$shared_anchor == "XYLOSE_IN", ,
    drop = FALSE
  ]
  expect_equal(link$status, "not_transferable")
  expect_equal(link$providers, "U")
  expect_equal(link$recipients, "V")
  expect_false("XYLOSE_IN" %in% network$edges$shared_anchor)
})

test_that("a genome holding both ends composes internally rather than trading", {
  whole <- evaluate_gifts(namespaced_annotations(c(
    "CAZY:GH11", "CAZY:GH39", "KO:K10543", "KO:K10544", "KO:K10545"
  )))
  network <- community_network(giftr_community(solo = whole, other = whole))
  # Both genomes hold both ends of the XYLOSE_EX link, so it is completed within
  # a genome. Edges between the two duplicates are still potential handoffs --
  # the molecule is extracellular -- but the link is not one the community
  # completes and no member does.
  link <- network$chain_coverage[
    network$chain_coverage$shared_anchor == "XYLOSE_EX", ,
    drop = FALSE
  ]
  expect_equal(link$status, "within_genome")
  expect_equal(link$within_genome, "other, solo")

  # A single genome trades with nobody.
  alone <- community_network(giftr_community(solo = whole))
  expect_equal(nrow(alone$edges), 0L)
  expect_equal(alone$nodes$provider_degree, 0L)
})

test_that("chain coverage separates what a genome completes from what the community does", {
  coverage <- community_network(arabinoxylan_community())$chain_coverage
  status <- stats::setNames(coverage$status, coverage$shared_anchor)
  expect_equal(status[["XYLAN"]], "community_distributed")
  expect_equal(status[["XYLOSE_EX"]], "community_distributed")
  expect_equal(status[["XYLOSE_IN"]], "within_genome")
  # Arabinose is released by A but nobody takes it up, so that link is not
  # represented. A community metric must not quietly complete it.
  expect_equal(status[["ARABINOSE_EX"]], "not_represented")
})

test_that("provider and recipient degrees describe position, not importance", {
  nodes <- community_network(arabinoxylan_community())$nodes
  degrees <- stats::setNames(nodes$provider_degree, nodes$genome_id)
  recipients <- stats::setNames(nodes$recipient_degree, nodes$genome_id)
  # B releases xylose that both consumers can take, and takes xylan from A.
  expect_equal(degrees[["B"]], 2L)
  expect_equal(recipients[["B"]], 1L)
  expect_equal(degrees[["A"]], 1L)
  expect_equal(recipients[["A"]], 0L)
  expect_equal(degrees[["C"]], 0L)
  expect_equal(recipients[["C"]], 1L)
})

test_that("edges inherit the edge quality of the GIFT edge beneath them", {
  network <- community_network(arabinoxylan_community())
  expect_true(all(network$edges$edge_quality %in% c("exact", "compartment_inexact")))
  # The arabinoxylan chain is curated with both compartments declared, so every
  # handoff in it is exact.
  expect_true(all(network$edges$edge_quality == "exact"))
  # Filtering to exact edges is the stronger claim and must be possible.
  filtered <- community_network(arabinoxylan_community(), quality = "exact")
  expect_equal(nrow(filtered$edges), nrow(network$edges))
  inexact <- community_network(
    arabinoxylan_community(), quality = "compartment_inexact"
  )
  expect_equal(nrow(inexact$edges), 0L)
})

test_that("a universe restricts which GIFTs may form edges", {
  transport_only <- gift_universe(mode = "transport", label = "transport GIFTs")
  network <- community_network(arabinoxylan_community(), universe = transport_only)
  # No transport GIFT hands off to another transport GIFT.
  expect_equal(nrow(network$edges), 0L)
  expect_identical(network$universe$label, "transport GIFTs")
})

test_that("interaction density counts ordered pairs and says so", {
  network <- community_network(arabinoxylan_community())
  density <- network$metrics[network$metrics$metric_id == "interaction_density", ]
  # Four genomes give twelve ordered pairs; three are connected.
  expect_equal(density$denominator, 12L)
  expect_equal(density$numerator, 3L)
  expect_equal(density$value, 3 / 12)
  expect_match(density$derivation_method, "counts twice")
})

test_that("a cycle is not closed across organisms through internal intermediates", {
  # Every genome that could close the citric acid cycle is absent here, but the
  # point is the rule rather than the fixture: the cycle's shared anchors are
  # not extracellular, so no combination of genomes may be said to close it.
  cycles <- community_network(arabinoxylan_community())$cycle_coverage
  expect_gt(nrow(cycles), 0L)
  expect_false(any(cycles$transferable))
  expect_false(any(cycles$status == "community_distributed"))
  expect_true(all(cycles$status %in% c("within_genome", "not_closed")))
})

test_that("only defined interaction types and matching versions are accepted", {
  community <- arabinoxylan_community()
  expect_error(community_network(list()), "must come from giftr_community")
  expect_error(
    community_network(community, interaction = "signal_response"),
    'should be "metabolic_handoff"'
  )
  expect_error(community_network(community, universe = "metabolic"), "gift_universe")
  stale <- gift_universe(type = "metabolic")
  stale$database_version <- "0000.0.0"
  expect_error(
    community_network(community, universe = stale),
    "different database version"
  )
})

test_that("every edge is traceable to the GIFTs and anchor that produced it", {
  network <- community_network(arabinoxylan_community())
  expect_setequal(
    names(network$edges),
    c("from_genome", "to_genome", "from_gift", "to_gift", "shared_anchor",
      "edge_quality")
  )
  expect_true(all(network$edges$from_genome %in% network$nodes$genome_id))
  expect_true(all(network$edges$to_genome %in% network$nodes$genome_id))
  expect_false(any(network$edges$from_genome == network$edges$to_genome))
})
