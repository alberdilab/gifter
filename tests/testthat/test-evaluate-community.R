# evaluate_gifts_community() exists to keep genomes apart. Everything tested
# here protects that: what a genome is, that the split decides it, and that
# nothing about how the work is distributed changes a call.

squished_condition <- function(expr, class) {
  condition <- tryCatch(expr, condition = function(condition) condition)
  expect_s3_class(condition, class)
  gsub("[[:space:]]+", " ", conditionMessage(condition))
}

test_that("each genome is evaluated on its own markers, never on the pool", {
  # The arabinoxylan chain is distributed across three genomes: debranching,
  # backbone cleavage, and uptake with catabolism. No member encodes the chain.
  community <- evaluate_gifts_community(arabinoxylan_table(), workers = 1)
  expect_s3_class(community, "gifter_community")
  expect_equal(community$genome_id, c("backbone", "consumer", "debrancher"))

  supported <- function(genome) {
    calls <- community$results[[genome]]$gifts
    sort(calls$gift_id[calls$complete])
  }
  expect_equal(supported("debrancher"), "arabinoxylan_debranching")
  expect_equal(supported("backbone"), "xylan_degradation")
  expect_equal(
    supported("consumer"),
    c("xylose_degradation_isomerase", "xylose_uptake_abc")
  )

  # Pooled, the same markers give one genome the whole chain. That call is a
  # statement about the collection and about no genome in it, which is the
  # mistake the split exists to prevent.
  pooled <- evaluate_gifts(arabinoxylan_table()[, -1], max_genes = Inf)
  pooled_ids <- sort(pooled$gifts$gift_id[pooled$gifts$complete])
  expect_length(pooled_ids, 4L)
  expect_false(any(vapply(
    community$genome_id, function(genome) identical(supported(genome), pooled_ids),
    logical(1)
  )))
})

test_that("a genome in a community is the genome evaluated alone", {
  community <- evaluate_gifts_community(arabinoxylan_table(), workers = 1)
  # The fixture names its genes after the genome, so the calls are compared
  # apart from the gene identifiers that necessarily differ.
  calls <- function(result) result$gifts[setdiff(names(result$gifts), "supporting_genes")]
  for (role in names(arabinoxylan_markers)) {
    solo <- arabinoxylan_genome(role)
    expect_equal(calls(community$results[[role]]), calls(solo))
    # Evidence, not only the call: a mixed genome would show a foreign gene.
    expect_equal(
      sort(community$results[[role]]$observed_markers$accession),
      sort(solo$observed_markers$accession)
    )
    expect_true(all(grepl(
      paste0("^", role, "_"), community$results[[role]]$observed_markers$gene_id
    )))
  }
})

test_that("workers change wall time and nothing else", {
  # Two workers over three genomes: one worker carries two of them, so this
  # also covers a block being evaluated on one connection.
  sequential <- evaluate_gifts_community(arabinoxylan_table(), workers = 1)
  parallel_run <- evaluate_gifts_community(arabinoxylan_table(), workers = 2)
  # Including the order: a community ordered by which worker finished first
  # would give the same calls a different genome axis.
  expect_identical(parallel_run$genome_id, sequential$genome_id)
  expect_identical(parallel_run$matrix, sequential$matrix)
  expect_equal(parallel_run$results, sequential$results)
})

test_that("the worker count is bounded by the work and by the platform", {
  # More workers than genomes would fork a process with nothing to evaluate.
  expect_identical(.resolve_workers(100, genomes = 3, forkable = TRUE), 3L)
  expect_identical(.resolve_workers(Inf, genomes = 3, forkable = TRUE), 3L)
  # Where forking is unavailable the request is met sequentially, and said.
  expect_warning(
    expect_identical(.resolve_workers(4, genomes = 3, forkable = FALSE), 1L),
    "cannot fork"
  )
  # The default is not a request, so it falls back silently.
  expect_silent(expect_identical(
    .resolve_workers(NULL, genomes = 3, forkable = FALSE), 1L
  ))
  expect_identical(
    withr::with_options(
      list(mc.cores = 2), .resolve_workers(NULL, genomes = 3, forkable = TRUE)
    ),
    2L
  )
  expect_error(.resolve_workers(0, genomes = 3, forkable = TRUE), "at least 1")
})

test_that("a worker that fails or dies is not passed off as a result", {
  # A child reports a failure as a value rather than by raising it, so a
  # community could otherwise come back quietly short of a genome.
  testthat::local_mocked_bindings(
    .evaluate_genome_block = function(tables, namespace, path, ticker = NULL) {
      stop("no database in this worker")
    }
  )
  expect_match(
    squished_condition(
      evaluate_gifts_community(arabinoxylan_table(), workers = 2), "error"
    ),
    "no database in this worker"
  )

  # A killed worker returns nothing at all, which is just as short a community.
  testthat::local_mocked_bindings(
    .evaluate_genome_block = function(tables, namespace, path, ticker = NULL) NULL
  )
  expect_match(
    squished_condition(
      evaluate_gifts_community(arabinoxylan_table(), workers = 2), "error"
    ),
    "Evaluation failed"
  )
})

test_that("progress counts genomes evaluated, however the work was spread", {
  # The display exists because a large community runs for a long time, so what
  # it counts has to be the work the caller asked for. Two workers over three
  # genomes means the blocks land in two pieces; the count must still move
  # genome by genome, and must end on every genome having been evaluated.
  seen <- list()
  recorder <- function(total, enabled) {
    list(
      enabled = TRUE,
      update = function(evaluated) seen[[length(seen) + 1L]] <<- evaluated,
      done = function() invisible(NULL),
      dismiss = function() invisible(NULL)
    )
  }
  testthat::local_mocked_bindings(.genome_progress = recorder)

  for (workers in c(1, 2)) {
    seen <- list()
    community <- evaluate_gifts_community(
      arabinoxylan_table(), workers = workers, progress = TRUE
    )
    counted <- unlist(seen)
    expect_length(community$genome_id, 3L)
    expect_equal(max(counted), 3L)
    # A count that went backwards would report genomes as unevaluated again.
    expect_false(is.unsorted(counted))
  }
})

test_that("a forked child reports its genomes to the parent it cannot speak to", {
  # The count crosses the process boundary through a file, one appended byte per
  # genome, because a child has no console and the parent is waiting on results.
  ticker <- .new_genome_ticker(TRUE)
  on.exit(unlink(ticker), add = TRUE)
  expect_equal(.ticked_genomes(ticker), 0L)

  jobs <- lapply(1:3, function(job) {
    parallel::mcparallel({
      .tick_genome(ticker)
      .tick_genome(ticker)
      TRUE
    })
  })
  parallel::mccollect(jobs)
  # Six concurrent appends from three processes, and none of them lost.
  expect_equal(.ticked_genomes(ticker), 6L)

  # With the display off there is no file to write to, and a tick costs nothing.
  expect_null(.new_genome_ticker(FALSE))
  expect_null(.tick_genome(NULL))
  expect_equal(.ticked_genomes(NULL), 0L)
})

test_that("progress is shown to a watching console and to nobody else", {
  # A bar written into a log, a knitted document or a package check is noise,
  # and one genome is never partway through.
  expect_identical(.resolve_progress(NULL, units = 3), interactive())
  expect_false(.resolve_progress(NULL, units = 1))
  expect_true(.resolve_progress(TRUE, units = 1))
  expect_false(.resolve_progress(FALSE, units = 3))
  expect_error(.resolve_progress("yes", units = 3), "TRUE")

  # The default is silent here, which is also what keeps the calls the only
  # thing this function puts on the console.
  expect_silent(evaluate_gifts_community(arabinoxylan_table(), workers = 2))
})

test_that("the genome column is required and never inferred", {
  markers <- arabinoxylan_table()
  names(markers)[names(markers) == "genome_id"] <- "bin"

  refusal <- squished_condition(evaluate_gifts_community(markers), "error")
  expect_match(refusal, "has no column named genome_id")
  expect_match(refusal, "evaluate_gifts")

  named <- evaluate_gifts_community(markers, genome_id = "bin", workers = 1)
  expect_equal(named$genome_id, c("backbone", "consumer", "debrancher"))

  # A marker naming no genome belongs to no genome, so it is not quietly given
  # to one.
  unnamed <- arabinoxylan_table()
  unnamed$genome_id[[1]] <- NA
  expect_match(
    squished_condition(evaluate_gifts_community(unnamed), "error"),
    "name no genome|names no genome"
  )

  expect_match(
    squished_condition(evaluate_gifts_community(arabinoxylan_markers$backbone), "error"),
    "must be a data frame"
  )
})

test_that("the gene column is resolved over the table, never from the genome column", {
  markers <- arabinoxylan_table()
  names(markers)[names(markers) == "gene_id"] <- "locus_tag"

  # The genome column is the first column, and is never the one proposed.
  refusal <- squished_condition(evaluate_gifts_community(markers), "error")
  expect_match(refusal, "has no gene_id column")
  expect_match(refusal, "locus_tag")
  expect_false(grepl("genome_id", refusal, fixed = TRUE))

  named <- evaluate_gifts_community(markers, gene_id = "locus_tag", workers = 1)
  expect_true(all(grepl(
    "^debrancher_", named$results$debrancher$observed_markers$gene_id
  )))

  # Declining the column numbers the markers within each genome and changes no
  # call: the evidence chain stops at the marker rather than at a wrong gene.
  numbered <- evaluate_gifts_community(markers, gene_id = FALSE, workers = 1)
  expect_equal(numbered$results$debrancher$observed_markers$gene_id, "marker_1")
  without_genes <- function(gifts) gifts[setdiff(names(gifts), "supporting_genes")]
  expect_equal(
    without_genes(numbered$results$debrancher$gifts),
    without_genes(named$results$debrancher$gifts)
  )
})

test_that("the single-genome guardrail is applied to each genome separately", {
  markers <- arabinoxylan_table()
  # Three genes is under the threshold for two of the genomes and over it for
  # the consumer, so the guardrail must name the genome it suspects.
  suspicion <- squished_condition(
    evaluate_gifts_community(markers, max_genes = 3, workers = 1), "warning"
  )
  expect_match(suspicion, "consumer")
  expect_match(suspicion, "5 distinct gene identifiers")
  expect_match(suspicion, "max_genes = Inf", fixed = TRUE)

  expect_silent(evaluate_gifts_community(markers, max_genes = 5, workers = 1))
})

test_that("the returned community is what the quantitative trait layer reads", {
  community <- evaluate_gifts_community(arabinoxylan_table(), workers = 1)
  traits <- community_traits(
    community, universes = list(arabinoxylan_universe()),
    abundance = c(debrancher = 0.5, backbone = 0.3, consumer = 0.2)
  )
  expect_true(nrow(traits$metrics) > 0L)
  expect_true(all(community$genome_id %in% c(traits$metrics$target_id, "community")))
  expect_true(any(traits$metrics$metric_id == "abundance_coverage"))
})

test_that("the evaluation commits to no reading of its calls", {
  # Abundance and completeness never reach this function: they say how a reader
  # weighs a carrier and how far a reader will read an absence, and an hour of
  # evaluation should not have to be repeated to revise either.
  community <- evaluate_gifts_community(arabinoxylan_table(), workers = 1)
  expect_null(community$abundance)
  expect_null(community$assessability)
  expect_false(any(is.na(community$matrix)))
  expect_error(
    evaluate_gifts_community(
      arabinoxylan_table(), workers = 1, abundance = c(backbone = 1)
    ),
    "unused argument"
  )
})

test_that("a nonsensical worker request is refused before any genome is evaluated", {
  # The whole cost of this function is between the split and the constructor,
  # and the guardrail below the check may stop to ask about a large genome, so
  # a request that cannot be met is refused before either happens.
  evaluated <- FALSE
  testthat::local_mocked_bindings(
    .evaluate_genomes = function(tables, namespace, db, workers, progress) {
      evaluated <<- TRUE
      stop("no genome should have been evaluated")
    }
  )
  expect_error(
    evaluate_gifts_community(arabinoxylan_table(), workers = 0), "at least 1"
  )
  expect_false(evaluated)

  # And a request that is fine is not refused: the check lets the run start.
  expect_error(
    evaluate_gifts_community(arabinoxylan_table(), workers = 2),
    "no genome should have been evaluated"
  )
  expect_true(evaluated)
})
