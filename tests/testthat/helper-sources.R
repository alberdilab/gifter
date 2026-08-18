# Copy the packaged source tables into a temporary directory so that a test can
# mutate biological content and re-validate it without touching the repository.
giftr_source_copy <- function(envir = parent.frame()) {
  source_dir <- tempfile("giftr-sources-")
  dir.create(source_dir, recursive = TRUE)
  withr::defer(unlink(source_dir, recursive = TRUE), envir = envir)
  packaged <- system.file("extdata", "database-source", package = "giftr")
  if (!nzchar(packaged)) packaged <- file.path("inst", "extdata", "database-source")
  file.copy(list.files(packaged, full.names = TRUE), source_dir)
  source_dir
}

read_source <- function(source_dir, table) {
  utils::read.delim(
    file.path(source_dir, paste0(table, ".tsv")),
    colClasses = "character", check.names = FALSE, na.strings = c("", "NA")
  )
}

write_source <- function(source_dir, table, data) {
  utils::write.table(
    data, file.path(source_dir, paste0(table, ".tsv")),
    sep = "\t", quote = FALSE, row.names = FALSE, na = ""
  )
}

append_source <- function(source_dir, table, ...) {
  existing <- read_source(source_dir, table)
  added <- data.frame(..., stringsAsFactors = FALSE)
  missing <- setdiff(names(existing), names(added))
  for (column in missing) added[[column]] <- NA_character_
  write_source(source_dir, table, rbind(existing, added[names(existing)]))
  invisible(source_dir)
}

# Add a GIFT that reuses existing curated chemistry. Only the boundary claim is
# under test, so the route borrows a reaction that already carries a complete
# enzyme system rather than inventing one.
add_test_gift <- function(source_dir, gift_id, mode, inputs, outputs,
                          reaction_id = "RHEA:14905") {
  append_source(
    source_dir, "gifts",
    gift_id = gift_id, name = gift_id, description = "Fixture GIFT.",
    category = "fixture", mode = mode, status = "curated", version = "1"
  )
  append_source(
    source_dir, "gift_anchors",
    gift_id = gift_id,
    anchor_id = c(inputs, outputs),
    role = rep(c("input", "output"), c(length(inputs), length(outputs))),
    ordinal = c(seq_along(inputs), seq_along(outputs))
  )
  route_id <- paste0("ROUTE_", toupper(gift_id))
  append_source(
    source_dir, "gift_routes",
    route_id = route_id, gift_id = gift_id, name = route_id,
    description = "Fixture route.", status = "curated",
    oxygen_requirement = "independent"
  )
  append_source(
    source_dir, "route_reactions",
    route_id = route_id, reaction_id = reaction_id,
    orientation = "forward", step_order = "1", required = "1"
  )
  # Facets are required of every GIFT, so a fixture must carry them too.
  append_source(
    source_dir, "gift_facets",
    gift_id = gift_id,
    facet = c("substrate_class", "physiological_role"),
    value = c("monosaccharide", "carbon_acquisition")
  )
  invisible(source_dir)
}

add_test_anchor <- function(source_dir, anchor_id, molecule, compartment) {
  append_source(
    source_dir, "anchors",
    anchor_id = anchor_id, molecule = molecule, compartment = compartment,
    name = anchor_id, description = "Fixture anchor."
  )
  append_source(
    source_dir, "anchor_facets",
    anchor_id = anchor_id,
    facet = c("molecular_tier", "biomass_essential"),
    value = c("monomer", "no")
  )
}

# Compile a mutated source tree and hand the caller an open connection.
build_test_database <- function(source_dir, envir = parent.frame()) {
  output <- tempfile("giftr-test-", fileext = ".sqlite")
  build_giftr_database(source_dir, output, overwrite = TRUE)
  connection <- giftr_db_connect(output)
  withr::defer(
    {
      if (DBI::dbIsValid(connection)) DBI::dbDisconnect(connection)
      unlink(output)
    },
    envir = envir
  )
  connection
}
