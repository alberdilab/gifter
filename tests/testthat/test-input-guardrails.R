# The guardrails protect the meaning of an evaluation, not its mechanics: a
# mislabelled gene column and a pooled collection of genomes both produce calls
# that look correct and answer a question the user never asked.

locus_annotations <- function() {
  data.frame(
    locus_tag = c("b0001", "b0002"),
    namespace = "KO",
    accession = c("K01198", "K01805"),
    stringsAsFactors = FALSE
  )
}

test_that("an unlabelled gene column is never adopted without approval", {
  # Non-interactive: nobody to approve, so the call refuses rather than guessing.
  expect_error(
    evaluate_gifts(locus_annotations()),
    "no gene_id column"
  )
  expect_error(evaluate_gifts(locus_annotations()), "locus_tag")

  # Approved, by name or in advance, the column carries the evidence chain.
  named <- evaluate_gifts(locus_annotations(), gene_id = "locus_tag")
  expect_equal(sort(named$observed_markers$gene_id), c("b0001", "b0002"))
  approved <- evaluate_gifts(locus_annotations(), gene_id = TRUE)
  expect_equal(sort(approved$observed_markers$gene_id), c("b0001", "b0002"))

  # Declined, the markers are numbered and no gene is claimed.
  declined <- evaluate_gifts(locus_annotations(), gene_id = FALSE)
  expect_equal(sort(declined$observed_markers$gene_id), c("marker_1", "marker_2"))

  expect_error(
    evaluate_gifts(locus_annotations(), gene_id = "gene"),
    "no column named gene"
  )
})

test_that("the interactive answer decides which column names genes", {
  testthat::local_mocked_bindings(.gifter_ask = function(question) {
    expect_match(question, "locus_tag")
    TRUE
  })
  result <- evaluate_gifts(locus_annotations())
  expect_equal(sort(result$observed_markers$gene_id), c("b0001", "b0002"))

  testthat::local_mocked_bindings(.gifter_ask = function(question) FALSE)
  expect_error(evaluate_gifts(locus_annotations()), "gene_id = TRUE")
})

test_that("inputs that hold no gene column are evaluated unquestioned", {
  # A labelled table is taken as given.
  labelled <- evaluate_gifts(ko_annotations(c("K01198", "K01805")))
  expect_equal(sort(labelled$observed_markers$gene_id), c("gene_1", "gene_2"))

  # A table of markers alone holds nothing to mistake for a gene identifier.
  markers_only <- data.frame(
    namespace = "KO", accession = c("K01198", "K01805"), stringsAsFactors = FALSE
  )
  numbered <- evaluate_gifts(markers_only)
  expect_equal(sort(numbered$observed_markers$gene_id), c("marker_1", "marker_2"))

  # Neither does a marker vector, whose gene identifiers are its names.
  expect_equal(evaluate_gifts(c(gene_a = "K01198"))$observed_markers$gene_id, "gene_a")
  expect_silent(evaluate_gifts(character()))
})

test_that("an input too large for one genome is questioned before evaluation", {
  many <- ko_annotations(rep(c("K01198", "K01805"), 6))

  # Non-interactive: a large genome is a legitimate input, so the evaluation
  # proceeds, but the suspicion is not swallowed.
  expect_warning(
    result <- evaluate_gifts(many, max_genes = 5),
    "evaluate_gifts_community"
  )
  expect_true(nrow(result$gifts) > 0L)
  expect_warning(evaluate_gifts(many, max_genes = 5), "12 distinct gene identifiers")

  # The threshold counts genes, not annotation rows: one gene carrying many
  # markers is still one gene.
  repeated <- data.frame(
    gene_id = "b0001", namespace = "KO",
    accession = rep("K01198", 20), stringsAsFactors = FALSE
  )
  expect_silent(evaluate_gifts(repeated, max_genes = 5))
  expect_silent(evaluate_gifts(many, max_genes = Inf))
})

test_that("the answer to the single-genome question decides the evaluation", {
  many <- ko_annotations(rep(c("K01198", "K01805"), 6))

  testthat::local_mocked_bindings(.gifter_ask = function(question) {
    expect_match(question, "single genome")
    TRUE
  })
  expect_silent(evaluate_gifts(many, max_genes = 5))

  testthat::local_mocked_bindings(.gifter_ask = function(question) FALSE)
  expect_error(evaluate_gifts(many, max_genes = 5), "evaluate_gifts_community")
})

test_that("guardrails change no call", {
  markers <- ko_annotations(direct_purine_markers(include_amp = TRUE))
  guarded <- evaluate_gifts(markers)
  relabelled <- markers
  names(relabelled)[names(relabelled) == "gene_id"] <- "locus_tag"
  approved <- evaluate_gifts(relabelled, gene_id = "locus_tag")
  expect_equal(approved$gifts, guarded$gifts)
  expect_equal(approved$observed_markers, guarded$observed_markers)

  expect_error(
    evaluate_gifts(markers, max_genes = "many"),
    "max_genes must be a single number"
  )
  expect_error(
    evaluate_gifts(markers, gene_id = 1),
    "gene_id must be NULL"
  )
})
