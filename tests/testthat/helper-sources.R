# Copy the packaged source tables into a temporary directory so that a test can
# mutate biological content and re-validate it without touching the repository.
gifter_source_copy <- function(envir = parent.frame()) {
  source_dir <- tempfile("gifter-sources-")
  dir.create(source_dir, recursive = TRUE)
  withr::defer(unlink(source_dir, recursive = TRUE), envir = envir)
  packaged <- system.file("extdata", "database-source", package = "gifter")
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
  append_rows(source_dir, table, data.frame(..., stringsAsFactors = FALSE))
}

# Appending a prebuilt frame, because a column called `source` cannot be passed
# through `...`: R would partially match it to `source_dir`.
append_rows <- function(source_dir, table, added) {
  existing <- read_source(source_dir, table)
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
    gift_id = gift_id, gift_type = "metabolic", name = gift_id,
    description = "Fixture GIFT.", mode = mode, status = "curated", version = "1"
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
  output <- tempfile("gifter-test-", fileext = ".sqlite")
  build_gifter_database(source_dir, output, overwrite = TRUE)
  connection <- gifter_db_connect(output)
  withr::defer(
    {
      if (DBI::dbIsValid(connection)) DBI::dbDisconnect(connection)
      unlink(output)
    },
    envir = envir
  )
  connection
}

# Add a machinery GIFT of one of the non-metabolic types together with a
# complete implementation hierarchy. The fixture is synthetic on purpose: the
# Boolean contract of a typed model must be testable without depending on any
# particular curated biology.
#
# `functions` is a list of function specifications:
#   list(id = , required = TRUE, systems = list(list(id = , components = list(
#     list(id = , markers = c("KO:K90001")))))).
add_test_machinery_gift <- function(source_dir, gift_id, gift_type, implementation_id,
                                    functions, facets = NULL) {
  model <- gifter:::.gifter_machinery_models[[gift_type]]
  if (is.null(model)) stop("Unknown machinery gift_type: ", gift_type)

  append_source(
    source_dir, "gifts",
    gift_id = gift_id, gift_type = gift_type, name = gift_id,
    description = "Fixture GIFT.", mode = NA_character_, status = "curated",
    version = "1"
  )
  # Every type requires a single-valued class facet; a fixture must carry the
  # one its type requires, read from the same map the validator uses.
  required <- gifter:::.gifter_required_gift_facets[[gift_type]]$single
  if (length(required)) {
    terms <- read_source(source_dir, "facet_terms")
    value <- terms$value[terms$facet == required][[1]]
    append_source(
      source_dir, "gift_facets", gift_id = gift_id, facet = required, value = value
    )
  }
  if (!is.null(facets)) {
    append_source(
      source_dir, "gift_facets",
      gift_id = gift_id, facet = names(facets), value = unname(facets)
    )
  }

  implementation <- data.frame(
    id = implementation_id, gift_id = gift_id, name = implementation_id,
    description = "Fixture implementation.", status = "curated",
    stringsAsFactors = FALSE
  )
  names(implementation)[[1]] <- model$implementation_id
  existing <- read_source(source_dir, model$implementation_source)
  write_source(source_dir, model$implementation_source,
               rbind(existing, implementation[names(existing)]))

  for (index in seq_along(functions)) {
    spec <- functions[[index]]
    required <- if (is.null(spec$required)) TRUE else isTRUE(spec$required)
    append_source(
      source_dir, model$function_source,
      function_id = spec$id, name = spec$id, description = "Fixture function."
    )
    membership <- data.frame(
      id = implementation_id, function_id = spec$id, ordinal = as.character(index),
      required = if (required) "1" else "0", stringsAsFactors = FALSE
    )
    names(membership)[[1]] <- model$implementation_id
    existing <- read_source(source_dir, model$membership_source)
    write_source(source_dir, model$membership_source,
                 rbind(existing, membership[names(existing)]))

    for (system in spec$systems) {
      append_source(
        source_dir, model$system_source,
        system_id = system$id, function_id = spec$id, name = system$id,
        description = "Fixture system."
      )
      for (component in system$components) {
        append_source(
          source_dir, model$component_source,
          component_id = component$id, system_id = system$id, name = component$id,
          description = "Fixture component."
        )
        for (marker in component$markers) {
          parts <- strsplit(marker, ":", fixed = TRUE)[[1]]
          add_test_marker(source_dir, parts[[1]], parts[[2]])
          append_rows(source_dir, model$evidence_source, data.frame(
            component_id = component$id, namespace = parts[[1]],
            accession = parts[[2]], evidence_type = "orthology",
            confidence = if (is.null(component$confidence)) "curated" else component$confidence,
            source = "Synthetic fixture", notes = NA_character_,
            stringsAsFactors = FALSE
          ))
        }
      }
    }
  }
  invisible(source_dir)
}

add_test_marker <- function(source_dir, namespace, accession) {
  markers <- read_source(source_dir, "markers")
  if (any(markers$namespace == namespace & markers$accession == accession)) {
    return(invisible(source_dir))
  }
  append_source(
    source_dir, "markers",
    namespace = namespace, accession = accession, name = accession,
    description = "Synthetic fixture marker."
  )
}

# A minimal structural fixture: one architecture, two required functions, the
# second with two alternative systems, one of which needs two components.
add_structural_fixture <- function(source_dir, gift_id = "fixture_structure",
                                   implementation_id = "ARCH_FIXTURE") {
  add_test_machinery_gift(
    source_dir, gift_id, "structural", implementation_id,
    list(
      list(id = paste0("SF_", toupper(gift_id), "_CORE"), required = TRUE, systems = list(
        list(id = paste0("SYS_", toupper(gift_id), "_CORE"), components = list(
          list(id = paste0("COMP_", toupper(gift_id), "_CORE"), markers = "KO:K90001")
        ))
      )),
      list(id = paste0("SF_", toupper(gift_id), "_ANCHORPOINT"), required = TRUE, systems = list(
        list(id = paste0("SYS_", toupper(gift_id), "_SIMPLE"), components = list(
          list(id = paste0("COMP_", toupper(gift_id), "_SIMPLE"), markers = "KO:K90002")
        )),
        list(id = paste0("SYS_", toupper(gift_id), "_COMPLEX"), components = list(
          list(id = paste0("COMP_", toupper(gift_id), "_ALPHA"), markers = "KO:K90003"),
          list(id = paste0("COMP_", toupper(gift_id), "_BETA"), markers = "KO:K90004")
        ))
      ))
    )
  )
}
