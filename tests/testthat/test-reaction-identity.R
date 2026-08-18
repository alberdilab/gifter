test_that("curated chemistry keeps Rhea as its identity", {
  reactions <- get_gift_reactions("purine_core_biosynthesis")
  expect_true(all(reactions$reaction_id == reactions$rhea_master))

  # Both identifiers address the same reaction, and a bare number is still read
  # as a Rhea master.
  expect_equal(get_reaction("RHEA:15753")$reaction_id, "RHEA:15753")
  expect_equal(get_reaction(15753)$rhea_master, "RHEA:15753")
  expect_equal(nrow(get_reaction("RHEA:00000")), 0L)
})

test_that("a reaction without a Rhea master needs an external cross-reference", {
  # Polymer-acting chemistry frequently has no Rhea master, because a
  # polysaccharide is a substrate class rather than a compound with a balanced
  # equation. Such a reaction must still be identifiable by a reader.
  identified <- giftr_source_copy()
  reactions <- read_source(identified, "reactions")
  target <- reactions$reaction_id[[1]]
  xrefs <- read_source(identified, "reaction_xrefs")
  expect_true(target %in% xrefs$reaction_id)
  reactions$rhea_master[reactions$reaction_id == target] <- NA_character_
  write_source(identified, "reactions", reactions)
  expect_true(validate_giftr_sources(identified)$valid)

  unidentified <- giftr_source_copy()
  reactions <- read_source(unidentified, "reactions")
  reactions$rhea_master[reactions$reaction_id == target] <- NA_character_
  write_source(unidentified, "reactions", reactions)
  xrefs <- read_source(unidentified, "reaction_xrefs")
  write_source(unidentified, "reaction_xrefs", xrefs[xrefs$reaction_id != target, ])
  expect_error(
    validate_giftr_sources(unidentified),
    "without a Rhea master need at least one cross-reference"
  )
})

test_that("a recorded Rhea master must be well formed and unique", {
  malformed <- giftr_source_copy()
  reactions <- read_source(malformed, "reactions")
  reactions$rhea_master[[1]] <- "RHEA-15753"
  write_source(malformed, "reactions", reactions)
  expect_error(validate_giftr_sources(malformed), "Invalid Rhea master IDs")

  duplicated <- giftr_source_copy()
  reactions <- read_source(duplicated, "reactions")
  reactions$rhea_master[[2]] <- reactions$rhea_master[[1]]
  write_source(duplicated, "reactions", reactions)
  expect_error(validate_giftr_sources(duplicated), "Duplicated Rhea master IDs")
})

test_that("reaction identity survives evaluation and tracing", {
  result <- evaluate_gifts(ko_annotations(direct_purine_markers()))
  expect_true(all(
    result$gifts$supporting_reactions[[
      match("purine_core_biosynthesis", result$gifts$gift_id)
    ]] %in% result$reactions$reaction_id
  ))

  trace <- trace_gift(result, "purine_core_biosynthesis")
  expect_true(all(c("reaction_id", "rhea_master") %in% names(trace)))
  expect_false(any(is.na(trace$reaction_id)))
})
