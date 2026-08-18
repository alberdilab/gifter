.giftr_schema_version <- 5L

# Direction of a capability. Anchor-derived composition may not cycle within a
# mode; it is expected to cycle between modes, because a catabolic route back to
# a metabolite an anabolic GIFT produces is real biology.
.giftr_gift_modes <- c("anabolic", "catabolic", "transport", "interconversion")

# Two-state location qualifier on declared anchors. Nothing else in giftr is
# compartmentalised; see inst/doc/architecture.md.
.giftr_compartments <- c("extracellular", "cytoplasmic", "unspecified")

# Whether a route needs oxygen. This is a route property and not a GIFT
# property: alternative routes to the same anchors genuinely differ, and
# recording it on the GIFT would flatten the distinction the OR-over-routes
# model exists to preserve.
.giftr_oxygen_requirements <- c("aerobic", "anaerobic", "independent")

# What a facet may classify.
.giftr_facet_targets <- c("gift", "anchor")

# Facets a GIFT must carry. `substrate_class` answers "what is this capability
# about" and must be single-valued, or it cannot partition anything;
# `physiological_role` is multi-valued because one capability legitimately
# serves several roles.
.giftr_required_single_gift_facets <- c("substrate_class")
.giftr_required_multi_gift_facets <- c("physiological_role")

# Facets an anchor must carry, both single-valued: a molecule has one size tier
# and is either a building block or not. `resource_origin` is deliberately not
# required. It is meant to be total, but a missing origin is warned rather than
# rejected, so that a new anchor can be curated in two passes instead of
# blocking the chemistry on a provenance judgement.
.giftr_required_single_anchor_facets <- c("molecular_tier", "biomass_essential")
.giftr_expected_anchor_facets <- c("resource_origin")

# How a curated GIFT boundary compares with an external pathway record. A GIFT
# is never defined as a pathway, so the relation is part of the biological
# claim and not decoration.
.giftr_xref_relations <- c(
  "equivalent", "subset_of", "superset_of", "overlaps", "related"
)

.giftr_change_layers <- c(
  "gift", "anchor", "route", "reaction", "enzyme_system",
  "enzyme_component", "marker", "provenance", "schema"
)

# Layers that make a biological claim about specific traits. A change to one of
# them must name the GIFTs it affects; provenance and schema changes need not.
.giftr_gift_bearing_layers <- c(
  "gift", "anchor", "route", "reaction", "enzyme_system",
  "enzyme_component", "marker"
)

.giftr_change_categories <- c("addition", "correction", "removal", "clarification")

.giftr_call_effects <- c("broadens", "narrows", "mixed", "none")

.giftr_source_spec <- list(
  gifts = c(
    "gift_id", "name", "description", "mode", "status", "version", "notes"
  ),
  facet_terms = c("facet", "value", "applies_to", "definition"),
  gift_facets = c("gift_id", "facet", "value", "notes"),
  anchor_facets = c("anchor_id", "facet", "value", "notes"),
  anchors = c("anchor_id", "molecule", "compartment", "name", "chebi_id", "description"),
  gift_anchors = c("gift_id", "anchor_id", "role", "ordinal"),
  gift_xrefs = c("gift_id", "namespace", "accession", "name", "relation", "notes"),
  reactions = c("reaction_id", "rhea_master", "name", "description"),
  reaction_xrefs = c("reaction_id", "namespace", "accession"),
  gift_routes = c(
    "route_id", "gift_id", "name", "description", "status", "oxygen_requirement"
  ),
  route_reactions = c("route_id", "reaction_id", "orientation", "step_order", "required"),
  enzyme_systems = c("system_id", "reaction_id", "name", "description"),
  enzyme_components = c("component_id", "system_id", "name", "description"),
  markers = c("namespace", "accession", "name", "description"),
  component_markers = c(
    "component_id", "namespace", "accession", "evidence_type",
    "confidence", "source", "notes"
  ),
  database_changes = c(
    "change_id", "released", "changed_at", "layer", "category", "call_effect",
    "summary", "rationale", "evidence", "effect"
  ),
  change_gifts = c("change_id", "gift_id"),
  database_release = c(
    "giftr_db_version", "schema_version", "build_date", "rhea_release",
    "chebi_release", "kegg_release", "source_commit"
  )
)

.read_giftr_sources <- function(source_dir) {
  if (!dir.exists(source_dir)) {
    stop("Source directory does not exist: ", source_dir, call. = FALSE)
  }

  tables <- lapply(names(.giftr_source_spec), function(table) {
    path <- file.path(source_dir, paste0(table, ".tsv"))
    if (!file.exists(path)) {
      return(structure(list(path = path), class = "giftr_missing_source"))
    }
    utils::read.delim(
      path,
      header = TRUE,
      sep = "\t",
      quote = "\"",
      comment.char = "",
      na.strings = c("", "NA"),
      colClasses = "character",
      check.names = FALSE,
      stringsAsFactors = FALSE
    )
  })
  names(tables) <- names(.giftr_source_spec)
  tables
}

.duplicate_values <- function(x) {
  unique(x[!is.na(x) & duplicated(x)])
}

.duplicate_keys <- function(data, columns) {
  if (!nrow(data)) {
    return(character())
  }
  values <- do.call(paste, c(data[columns], sep = " | "))
  .duplicate_values(values)
}

.missing_refs <- function(values, parents) {
  sort(unique(values[!is.na(values) & !values %in% parents]))
}

.find_graph_cycle <- function(edges) {
  if (!nrow(edges)) {
    return(character())
  }
  nodes <- sort(unique(c(edges$from, edges$to)))
  state <- stats::setNames(integer(length(nodes)), nodes)
  stack <- character()
  found <- character()

  visit <- function(node) {
    if (length(found)) {
      return(invisible(NULL))
    }
    state[[node]] <<- 1L
    stack <<- c(stack, node)
    children <- edges$to[edges$from == node]
    for (child in children) {
      if (state[[child]] == 0L) {
        visit(child)
      } else if (state[[child]] == 1L) {
        start <- match(child, stack)
        found <<- c(stack[start:length(stack)], child)
        return(invisible(NULL))
      }
    }
    stack <<- utils::head(stack, -1L)
    state[[node]] <<- 2L
    invisible(NULL)
  }

  for (node in nodes[state == 0L]) {
    visit(node)
    if (length(found)) break
  }
  found
}

#' Validate human-readable giftr database sources
#'
#' Performs structural validation before a SQLite database is compiled. Any
#' duplicate identifiers, broken references, missing hierarchy levels, invalid
#' directions, malformed anchor boundaries, graph cycles, or inconsistent
#' release metadata are reported as build errors.
#'
#' @param source_dir Directory containing the giftr TSV source tables.
#' @param stop_on_error If `TRUE`, stop when structural errors are found.
#' @return A list with `valid`, `errors`, `warnings`, and table row counts.
#' @export
validate_giftr_sources <- function(source_dir, stop_on_error = TRUE) {
  tables <- .read_giftr_sources(source_dir)
  errors <- character()
  warnings <- character()

  for (table in names(.giftr_source_spec)) {
    value <- tables[[table]]
    if (inherits(value, "giftr_missing_source")) {
      errors <- c(errors, paste0("Missing source table: ", basename(value$path)))
      next
    }
    missing_columns <- setdiff(.giftr_source_spec[[table]], names(value))
    if (length(missing_columns)) {
      errors <- c(
        errors,
        paste0(table, " is missing columns: ", paste(missing_columns, collapse = ", "))
      )
    }
  }

  if (length(errors)) {
    report <- structure(
      list(valid = FALSE, errors = errors, warnings = warnings, rows = integer()),
      class = "giftr_validation"
    )
    if (isTRUE(stop_on_error)) stop(paste(errors, collapse = "\n"), call. = FALSE)
    return(report)
  }

  required_nonempty <- c(
    gifts = "gift_id", anchors = "anchor_id", gift_anchors = "gift_id",
    reactions = "reaction_id", gift_routes = "route_id",
    route_reactions = "route_id", enzyme_systems = "system_id",
    enzyme_components = "component_id", markers = "namespace",
    component_markers = "component_id", database_changes = "change_id",
    change_gifts = "change_id", database_release = "giftr_db_version",
    facet_terms = "facet", gift_facets = "gift_id", anchor_facets = "anchor_id"
  )
  for (table in names(required_nonempty)) {
    column <- required_nonempty[[table]]
    if (!nrow(tables[[table]]) || any(is.na(tables[[table]][[column]]))) {
      errors <- c(errors, paste0(table, " must contain non-empty ", column, " values"))
    }
  }

  unique_ids <- c(
    gifts = "gift_id", anchors = "anchor_id", reactions = "reaction_id",
    gift_routes = "route_id", enzyme_systems = "system_id",
    enzyme_components = "component_id", database_changes = "change_id"
  )
  for (table in names(unique_ids)) {
    column <- unique_ids[[table]]
    duplicates <- .duplicate_values(tables[[table]][[column]])
    if (length(duplicates)) {
      errors <- c(
        errors,
        paste0("Duplicated ", table, ".", column, ": ", paste(duplicates, collapse = ", "))
      )
    }
  }

  duplicate_markers <- .duplicate_keys(tables$markers, c("namespace", "accession"))
  if (length(duplicate_markers)) {
    errors <- c(errors, paste0("Duplicated marker keys: ", paste(duplicate_markers, collapse = ", ")))
  }
  duplicate_anchor_molecules <- .duplicate_keys(
    tables$anchors, c("molecule", "compartment")
  )
  if (length(duplicate_anchor_molecules)) {
    errors <- c(
      errors,
      paste0(
        "Duplicated anchor molecule/compartment pairs: ",
        paste(duplicate_anchor_molecules, collapse = ", ")
      )
    )
  }
  duplicate_route_reactions <- .duplicate_keys(
    tables$route_reactions, c("route_id", "reaction_id")
  )
  if (length(duplicate_route_reactions)) {
    errors <- c(
      errors,
      paste0("Duplicated route/reaction combinations: ", paste(duplicate_route_reactions, collapse = ", "))
    )
  }
  duplicate_component_markers <- .duplicate_keys(
    tables$component_markers, c("component_id", "namespace", "accession")
  )
  if (length(duplicate_component_markers)) {
    errors <- c(
      errors,
      paste0("Duplicated component/marker combinations: ", paste(duplicate_component_markers, collapse = ", "))
    )
  }
  duplicate_gift_xrefs <- .duplicate_keys(
    tables$gift_xrefs, c("gift_id", "namespace", "accession")
  )
  if (length(duplicate_gift_xrefs)) {
    errors <- c(
      errors,
      paste0("Duplicated GIFT pathway references: ", paste(duplicate_gift_xrefs, collapse = ", "))
    )
  }

  reference_checks <- list(
    list("gift_anchors.gift_id", tables$gift_anchors$gift_id, tables$gifts$gift_id),
    list("gift_anchors.anchor_id", tables$gift_anchors$anchor_id, tables$anchors$anchor_id),
    list("gift_xrefs.gift_id", tables$gift_xrefs$gift_id, tables$gifts$gift_id),
    list("gift_routes.gift_id", tables$gift_routes$gift_id, tables$gifts$gift_id),
    list("route_reactions.route_id", tables$route_reactions$route_id, tables$gift_routes$route_id),
    list("route_reactions.reaction_id", tables$route_reactions$reaction_id, tables$reactions$reaction_id),
    list("reaction_xrefs.reaction_id", tables$reaction_xrefs$reaction_id, tables$reactions$reaction_id),
    list("enzyme_systems.reaction_id", tables$enzyme_systems$reaction_id, tables$reactions$reaction_id),
    list("enzyme_components.system_id", tables$enzyme_components$system_id, tables$enzyme_systems$system_id),
    list("component_markers.component_id", tables$component_markers$component_id, tables$enzyme_components$component_id),
    list("change_gifts.change_id", tables$change_gifts$change_id, tables$database_changes$change_id),
    list("change_gifts.gift_id", tables$change_gifts$gift_id, tables$gifts$gift_id),
    list("gift_facets.gift_id", tables$gift_facets$gift_id, tables$gifts$gift_id),
    list("anchor_facets.anchor_id", tables$anchor_facets$anchor_id, tables$anchors$anchor_id)
  )
  marker_keys <- paste(tables$markers$namespace, tables$markers$accession, sep = "\r")
  component_marker_keys <- paste(
    tables$component_markers$namespace, tables$component_markers$accession, sep = "\r"
  )
  reference_checks <- c(
    reference_checks,
    list(list("component_markers marker key", component_marker_keys, marker_keys))
  )
  for (check in reference_checks) {
    missing <- .missing_refs(check[[2]], check[[3]])
    if (length(missing)) {
      errors <- c(errors, paste0("Invalid ", check[[1]], ": ", paste(missing, collapse = ", ")))
    }
  }

  # A facet vocabulary is open to new facets and closed within a facet. Both
  # halves matter: without registration a multi-valued classification degenerates
  # into free text, and nothing downstream can rely on the values it sees.
  if (length(.duplicate_keys(tables$facet_terms, c("facet", "value")))) {
    errors <- c(errors, "facet_terms contains duplicate facet/value pairs")
  }
  invalid_targets <- setdiff(unique(tables$facet_terms$applies_to), .giftr_facet_targets)
  if (length(invalid_targets)) {
    errors <- c(
      errors,
      paste0("Invalid facet_terms.applies_to: ", paste(invalid_targets, collapse = ", "))
    )
  }
  undefined_definition <- tables$facet_terms$facet[
    is.na(tables$facet_terms$definition) | !nzchar(trimws(tables$facet_terms$definition))
  ]
  if (length(undefined_definition)) {
    errors <- c(
      errors,
      paste0(
        "facet_terms.definition must be recorded for: ",
        paste(unique(undefined_definition), collapse = ", ")
      )
    )
  }

  registered <- paste(tables$facet_terms$facet, tables$facet_terms$value, sep = "\r")
  for (target in .giftr_facet_targets) {
    table_name <- paste0(target, "_facets")
    assignments <- tables[[table_name]]
    if (length(.duplicate_keys(assignments, c(paste0(target, "_id"), "facet", "value")))) {
      errors <- c(errors, paste0(table_name, " contains duplicate assignments"))
    }
    unknown <- setdiff(
      paste(assignments$facet, assignments$value, sep = "\r"), registered
    )
    if (length(unknown)) {
      errors <- c(
        errors,
        paste0(
          "Unregistered ", table_name, " terms: ",
          paste(sub("\r", "=", unknown, fixed = TRUE), collapse = ", ")
        )
      )
    }
    # A facet registered for anchors must not be attached to a GIFT, or the
    # vocabulary stops meaning anything.
    wrong_target <- assignments$facet[
      assignments$facet %in% tables$facet_terms$facet[tables$facet_terms$applies_to != target]
    ]
    if (length(wrong_target)) {
      errors <- c(
        errors,
        paste0(
          table_name, " uses facets registered for another target: ",
          paste(sort(unique(wrong_target)), collapse = ", ")
        )
      )
    }
  }

  for (facet in .giftr_required_single_gift_facets) {
    counts <- table(tables$gift_facets$gift_id[tables$gift_facets$facet == facet])
    missing_facet <- setdiff(tables$gifts$gift_id, names(counts))
    if (length(missing_facet)) {
      errors <- c(
        errors,
        paste0(
          "Every GIFT needs one ", facet, ": ", paste(missing_facet, collapse = ", ")
        )
      )
    }
    if (any(counts > 1L)) {
      errors <- c(
        errors,
        paste0(
          facet, " must be single-valued, but is repeated for: ",
          paste(names(counts)[counts > 1L], collapse = ", ")
        )
      )
    }
  }
  for (facet in .giftr_required_multi_gift_facets) {
    missing_facet <- setdiff(
      tables$gifts$gift_id, tables$gift_facets$gift_id[tables$gift_facets$facet == facet]
    )
    if (length(missing_facet)) {
      errors <- c(
        errors,
        paste0(
          "Every GIFT needs at least one ", facet, ": ",
          paste(missing_facet, collapse = ", ")
        )
      )
    }
  }

  for (facet in .giftr_required_single_anchor_facets) {
    counts <- table(tables$anchor_facets$anchor_id[tables$anchor_facets$facet == facet])
    missing_facet <- setdiff(tables$anchors$anchor_id, names(counts))
    if (length(missing_facet)) {
      errors <- c(
        errors,
        paste0(
          "Every anchor needs one ", facet, ": ", paste(missing_facet, collapse = ", ")
        )
      )
    }
    if (any(counts > 1L)) {
      errors <- c(
        errors,
        paste0(
          facet, " must be single-valued, but is repeated for: ",
          paste(names(counts)[counts > 1L], collapse = ", ")
        )
      )
    }
  }

  # Provenance is meant to cover every boundary molecule, but an unstated origin
  # is a curation gap rather than a broken claim, so it does not fail the build.
  for (facet in .giftr_expected_anchor_facets) {
    missing_facet <- setdiff(
      tables$anchors$anchor_id, tables$anchor_facets$anchor_id[tables$anchor_facets$facet == facet]
    )
    if (length(missing_facet)) {
      warnings <- c(
        warnings,
        paste0(
          "Anchors without a ", facet, ": ", paste(missing_facet, collapse = ", ")
        )
      )
    }
  }

  invalid_oxygen <- setdiff(
    unique(tables$gift_routes$oxygen_requirement), .giftr_oxygen_requirements
  )
  if (length(invalid_oxygen)) {
    errors <- c(
      errors,
      paste0("Invalid gift_routes.oxygen_requirement: ", paste(invalid_oxygen, collapse = ", "))
    )
  }

  invalid_compartments <- setdiff(unique(tables$anchors$compartment), .giftr_compartments)
  if (length(invalid_compartments)) {
    errors <- c(
      errors,
      paste0("Invalid anchor compartment: ", paste(invalid_compartments, collapse = ", "))
    )
  }
  empty_molecules <- tables$anchors$anchor_id[
    is.na(tables$anchors$molecule) | !nzchar(trimws(tables$anchors$molecule))
  ]
  if (length(empty_molecules)) {
    errors <- c(
      errors,
      paste0("anchors.molecule must be recorded for: ", paste(empty_molecules, collapse = ", "))
    )
  }
  invalid_modes <- setdiff(unique(tables$gifts$mode), .giftr_gift_modes)
  if (length(invalid_modes)) {
    errors <- c(errors, paste0("Invalid gifts.mode: ", paste(invalid_modes, collapse = ", ")))
  }

  anchor_molecule <- stats::setNames(tables$anchors$molecule, tables$anchors$anchor_id)
  gift_mode <- stats::setNames(tables$gifts$mode, tables$gifts$gift_id)

  for (gift_id in tables$gifts$gift_id) {
    anchors <- tables$gift_anchors[tables$gift_anchors$gift_id == gift_id, , drop = FALSE]
    routes <- tables$gift_routes[tables$gift_routes$gift_id == gift_id, , drop = FALSE]
    if (!any(anchors$role == "input")) errors <- c(errors, paste0(gift_id, " has no input anchor"))
    if (!any(anchors$role == "output")) errors <- c(errors, paste0(gift_id, " has no output anchor"))
    if (!nrow(routes)) errors <- c(errors, paste0(gift_id, " has no route"))
    if (any(anchors$anchor_id[anchors$role == "input"] %in% anchors$anchor_id[anchors$role == "output"])) {
      errors <- c(errors, paste0(gift_id, " uses the same anchor as input and output"))
    }

    # A transport GIFT moves one molecule across a boundary; a chemistry GIFT
    # changes the molecule. The declared anchors must say which this is, or the
    # compartment layer carries no meaning and transport stops being required
    # to reach the cytoplasm.
    translocated <- intersect(
      unname(anchor_molecule[anchors$anchor_id[anchors$role == "input"]]),
      unname(anchor_molecule[anchors$anchor_id[anchors$role == "output"]])
    )
    if (identical(unname(gift_mode[gift_id]), "transport") && !length(translocated)) {
      errors <- c(
        errors,
        paste0(gift_id, " is a transport GIFT but no molecule appears as both input and output")
      )
    }
    if (!identical(unname(gift_mode[gift_id]), "transport") && length(translocated)) {
      warnings <- c(
        warnings,
        paste0(
          gift_id, " declares ", paste(translocated, collapse = ", "),
          " as both input and output in different compartments but is not mode = transport"
        )
      )
    }
  }
  if (any(!tables$gift_anchors$role %in% c("input", "output"))) {
    errors <- c(errors, "gift_anchors contains an invalid role")
  }
  anchor_ordinals <- suppressWarnings(as.integer(tables$gift_anchors$ordinal))
  if (any(is.na(anchor_ordinals) | anchor_ordinals < 1L)) {
    errors <- c(errors, "gift_anchors contains an invalid ordinal")
  }
  if (length(.duplicate_keys(tables$gift_anchors, c("gift_id", "role", "ordinal")))) {
    errors <- c(errors, "gift_anchors contains duplicate gift/role/ordinal values")
  }

  invalid_relations <- setdiff(unique(tables$gift_xrefs$relation), .giftr_xref_relations)
  if (length(invalid_relations)) {
    errors <- c(
      errors,
      paste0("Invalid gift_xrefs.relation: ", paste(invalid_relations, collapse = ", "))
    )
  }
  for (column in c("namespace", "accession", "name")) {
    empty <- tables$gift_xrefs$gift_id[
      is.na(tables$gift_xrefs[[column]]) | !nzchar(trimws(tables$gift_xrefs[[column]]))
    ]
    if (length(empty)) {
      errors <- c(
        errors,
        paste0(
          "gift_xrefs.", column, " must be recorded for: ",
          paste(sort(unique(empty)), collapse = ", ")
        )
      )
    }
  }

  for (route_id in tables$gift_routes$route_id) {
    reactions <- tables$route_reactions[
      tables$route_reactions$route_id == route_id & tables$route_reactions$required == "1",
      , drop = FALSE
    ]
    if (!nrow(reactions)) errors <- c(errors, paste0(route_id, " has no required reactions"))
  }
  if (any(!tables$route_reactions$orientation %in% c("forward", "reverse"))) {
    errors <- c(errors, "route_reactions contains an invalid orientation")
  }
  step_order <- suppressWarnings(as.integer(tables$route_reactions$step_order))
  if (any(is.na(step_order) | step_order < 1L)) {
    errors <- c(errors, "route_reactions contains an invalid step_order")
  }
  if (length(.duplicate_keys(tables$route_reactions, c("route_id", "step_order")))) {
    errors <- c(errors, "route_reactions contains duplicate step order values")
  }
  if (any(!tables$route_reactions$required %in% c("0", "1"))) {
    errors <- c(errors, "route_reactions.required must be 0 or 1")
  }
  # A Rhea master is optional, because polymer-acting chemistry often has none,
  # but when recorded it must be well formed.
  recorded_rhea <- tables$reactions$rhea_master[!is.na(tables$reactions$rhea_master)]
  invalid_rhea <- recorded_rhea[!grepl("^RHEA:[0-9]+$", recorded_rhea)]
  if (length(invalid_rhea)) {
    errors <- c(errors, paste0("Invalid Rhea master IDs: ", paste(invalid_rhea, collapse = ", ")))
  }
  duplicate_rhea <- .duplicate_values(recorded_rhea)
  if (length(duplicate_rhea)) {
    errors <- c(errors, paste0("Duplicated Rhea master IDs: ", paste(duplicate_rhea, collapse = ", ")))
  }

  # A reaction without a Rhea master must still be externally identifiable, or
  # its chemistry rests on nothing a reader can check.
  unidentified <- tables$reactions$reaction_id[
    is.na(tables$reactions$rhea_master) &
      !tables$reactions$reaction_id %in% tables$reaction_xrefs$reaction_id
  ]
  if (length(unidentified)) {
    errors <- c(
      errors,
      paste0(
        "Reactions without a Rhea master need at least one cross-reference: ",
        paste(unidentified, collapse = ", ")
      )
    )
  }

  for (reaction_id in tables$reactions$reaction_id) {
    if (!any(tables$enzyme_systems$reaction_id == reaction_id)) {
      errors <- c(errors, paste0(reaction_id, " has no enzyme system"))
    }
  }
  for (system_id in tables$enzyme_systems$system_id) {
    if (!any(tables$enzyme_components$system_id == system_id)) {
      errors <- c(errors, paste0(system_id, " has no component"))
    }
  }
  for (component_id in tables$enzyme_components$component_id) {
    if (!any(tables$component_markers$component_id == component_id)) {
      errors <- c(errors, paste0(component_id, " has no marker"))
    }
  }

  # Composition edges must be derived exactly as the gift_graph view derives
  # them, including the rule that two specified and different compartments do
  # not connect.
  anchor_compartment <- stats::setNames(tables$anchors$compartment, tables$anchors$anchor_id)
  outputs <- tables$gift_anchors[tables$gift_anchors$role == "output", c("gift_id", "anchor_id")]
  inputs <- tables$gift_anchors[tables$gift_anchors$role == "input", c("gift_id", "anchor_id")]
  outputs$molecule <- unname(anchor_molecule[outputs$anchor_id])
  inputs$molecule <- unname(anchor_molecule[inputs$anchor_id])
  edges <- merge(outputs, inputs, by = "molecule", suffixes = c("_from", "_to"))
  if (nrow(edges)) {
    connected <- edges$anchor_id_from == edges$anchor_id_to |
      unname(anchor_compartment[edges$anchor_id_from]) == "unspecified" |
      unname(anchor_compartment[edges$anchor_id_to]) == "unspecified"
    edges <- edges[connected, , drop = FALSE]
  }
  if (nrow(edges)) {
    edges <- data.frame(from = edges$gift_id_from, to = edges$gift_id_to, stringsAsFactors = FALSE)
    edges <- edges[edges$from != edges$to, , drop = FALSE]
    # Cycles are forbidden within a mode and expected between modes.
    for (mode in intersect(.giftr_gift_modes, unique(tables$gifts$mode))) {
      within_mode <- edges[
        unname(gift_mode[edges$from]) == mode & unname(gift_mode[edges$to]) == mode,
        , drop = FALSE
      ]
      cycle <- .find_graph_cycle(within_mode)
      if (length(cycle)) {
        errors <- c(
          errors,
          paste0("Circular ", mode, " GIFT composition: ", paste(cycle, collapse = " -> "))
        )
      }
    }
  }

  changes <- tables$database_changes
  if (length(.duplicate_keys(tables$change_gifts, c("change_id", "gift_id")))) {
    errors <- c(errors, "change_gifts contains duplicate change/gift pairs")
  }
  invalid_layers <- setdiff(unique(changes$layer), .giftr_change_layers)
  if (length(invalid_layers)) {
    errors <- c(errors, paste0("Invalid database_changes.layer: ", paste(invalid_layers, collapse = ", ")))
  }
  invalid_categories <- setdiff(unique(changes$category), .giftr_change_categories)
  if (length(invalid_categories)) {
    errors <- c(
      errors,
      paste0("Invalid database_changes.category: ", paste(invalid_categories, collapse = ", "))
    )
  }
  invalid_effects <- setdiff(unique(changes$call_effect), .giftr_call_effects)
  if (length(invalid_effects)) {
    errors <- c(
      errors,
      paste0("Invalid database_changes.call_effect: ", paste(invalid_effects, collapse = ", "))
    )
  }
  invalid_timestamps <- changes$change_id[
    is.na(changes$changed_at) |
      !grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}(T[0-9]{2}:[0-9]{2}Z)?$", changes$changed_at)
  ]
  if (length(invalid_timestamps)) {
    errors <- c(
      errors,
      paste0(
        "database_changes.changed_at must use YYYY-MM-DD or YYYY-MM-DDThh:mmZ: ",
        paste(invalid_timestamps, collapse = ", ")
      )
    )
  }
  for (column in c("released", "summary", "rationale")) {
    empty <- changes$change_id[is.na(changes[[column]]) | !nzchar(trimws(changes[[column]]))]
    if (length(empty)) {
      errors <- c(
        errors,
        paste0("database_changes.", column, " must be recorded for: ", paste(empty, collapse = ", "))
      )
    }
  }
  unlinked <- setdiff(
    changes$change_id[changes$layer %in% .giftr_gift_bearing_layers],
    tables$change_gifts$change_id
  )
  if (length(unlinked)) {
    errors <- c(
      errors,
      paste0(
        "database_changes entries must name the GIFTs they affect: ",
        paste(unlinked, collapse = ", ")
      )
    )
  }

  release <- tables$database_release
  if (nrow(release) != 1L) {
    errors <- c(errors, "database_release must contain exactly one row")
  } else {
    required_release <- .giftr_source_spec$database_release
    if (any(is.na(release[1, required_release]))) {
      errors <- c(errors, "database_release contains missing version fields")
    }
    release_schema <- suppressWarnings(as.integer(release$schema_version[[1]]))
    if (is.na(release_schema) || release_schema != .giftr_schema_version) {
      errors <- c(errors, paste0("schema_version must be ", .giftr_schema_version))
    }
    if (is.na(suppressWarnings(as.Date(release$build_date[[1]])))) {
      errors <- c(errors, "database_release.build_date must use YYYY-MM-DD")
    }
  }

  errors <- unique(errors)
  warnings <- unique(warnings)
  report <- structure(
    list(
      valid = !length(errors),
      errors = errors,
      warnings = warnings,
      rows = vapply(tables, nrow, integer(1))
    ),
    class = "giftr_validation"
  )
  if (length(errors) && isTRUE(stop_on_error)) {
    stop(paste(c("giftr source validation failed:", paste0("- ", errors)), collapse = "\n"), call. = FALSE)
  }
  report
}

.giftr_schema_path <- function() {
  path <- system.file("schema", "giftr.sql", package = "giftr")
  if (nzchar(path)) return(path)
  candidate <- file.path("inst", "schema", "giftr.sql")
  if (file.exists(candidate)) return(candidate)
  stop("Could not locate the giftr SQL schema", call. = FALSE)
}

.db_key_map <- function(connection, table, id_column, pk_column) {
  data <- DBI::dbGetQuery(
    connection,
    paste0("SELECT ", pk_column, ", ", id_column, " FROM ", table)
  )
  stats::setNames(data[[pk_column]], data[[id_column]])
}

.execute_schema <- function(connection, schema_path) {
  sql <- paste(readLines(schema_path, warn = FALSE), collapse = "\n")
  statements <- strsplit(sql, ";[[:space:]]*(?:\n|$)", perl = TRUE)[[1]]
  for (statement in statements[nzchar(trimws(statements))]) {
    DBI::dbExecute(connection, statement)
  }
  invisible(NULL)
}

#' Compile giftr source tables into SQLite
#'
#' Validates the human-readable TSV source tables and compiles a normalized,
#' indexed SQLite database. The output is written atomically after all foreign
#' key checks pass.
#'
#' @param source_dir Directory containing the giftr TSV source tables.
#' @param output Path for the compiled SQLite database.
#' @param overwrite Whether an existing output may be replaced.
#' @param source_commit Optional source commit to store in release metadata.
#' @return The normalized output path, invisibly.
#' @export
build_giftr_database <- function(source_dir, output, overwrite = FALSE, source_commit = NULL) {
  validate_giftr_sources(source_dir, stop_on_error = TRUE)
  tables <- .read_giftr_sources(source_dir)
  output <- normalizePath(output, winslash = "/", mustWork = FALSE)
  if (file.exists(output) && !isTRUE(overwrite)) {
    stop("Output already exists; set overwrite = TRUE to replace it: ", output, call. = FALSE)
  }
  dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile("giftr-build-", tmpdir = dirname(output), fileext = ".sqlite")
  on.exit(if (file.exists(temporary)) unlink(temporary), add = TRUE)

  connection <- DBI::dbConnect(RSQLite::SQLite(), temporary)
  on.exit(if (DBI::dbIsValid(connection)) DBI::dbDisconnect(connection), add = TRUE)
  DBI::dbExecute(connection, "PRAGMA foreign_keys = ON")
  .execute_schema(connection, .giftr_schema_path())
  DBI::dbBegin(connection)
  committed <- FALSE
  on.exit(if (!committed && DBI::dbIsValid(connection)) DBI::dbRollback(connection), add = TRUE)

  gifts <- tables$gifts
  anchors <- tables$anchors
  reactions <- tables$reactions
  DBI::dbWriteTable(connection, "gift", gifts, append = TRUE, row.names = FALSE)
  DBI::dbWriteTable(connection, "anchor", anchors, append = TRUE, row.names = FALSE)
  DBI::dbWriteTable(connection, "reaction", reactions, append = TRUE, row.names = FALSE)

  gift_pk <- .db_key_map(connection, "gift", "gift_id", "gift_pk")
  anchor_pk <- .db_key_map(connection, "anchor", "anchor_id", "anchor_pk")
  reaction_pk <- .db_key_map(connection, "reaction", "reaction_id", "reaction_pk")

  gift_anchors <- data.frame(
    gift_pk = unname(gift_pk[tables$gift_anchors$gift_id]),
    anchor_pk = unname(anchor_pk[tables$gift_anchors$anchor_id]),
    role = tables$gift_anchors$role,
    ordinal = as.integer(tables$gift_anchors$ordinal)
  )
  DBI::dbWriteTable(connection, "gift_anchor", gift_anchors, append = TRUE, row.names = FALSE)

  DBI::dbWriteTable(connection, "facet_term", tables$facet_terms, append = TRUE, row.names = FALSE)
  DBI::dbWriteTable(
    connection, "gift_facet",
    data.frame(
      gift_pk = unname(gift_pk[tables$gift_facets$gift_id]),
      facet = tables$gift_facets$facet,
      value = tables$gift_facets$value,
      notes = tables$gift_facets$notes
    ),
    append = TRUE, row.names = FALSE
  )
  DBI::dbWriteTable(
    connection, "anchor_facet",
    data.frame(
      anchor_pk = unname(anchor_pk[tables$anchor_facets$anchor_id]),
      facet = tables$anchor_facets$facet,
      value = tables$anchor_facets$value,
      notes = tables$anchor_facets$notes
    ),
    append = TRUE, row.names = FALSE
  )

  gift_xrefs <- data.frame(
    gift_pk = unname(gift_pk[tables$gift_xrefs$gift_id]),
    namespace = tables$gift_xrefs$namespace,
    accession = tables$gift_xrefs$accession,
    name = tables$gift_xrefs$name,
    relation = tables$gift_xrefs$relation,
    notes = tables$gift_xrefs$notes
  )
  DBI::dbWriteTable(connection, "gift_xref", gift_xrefs, append = TRUE, row.names = FALSE)

  reaction_xrefs <- data.frame(
    reaction_pk = unname(reaction_pk[tables$reaction_xrefs$reaction_id]),
    namespace = tables$reaction_xrefs$namespace,
    accession = tables$reaction_xrefs$accession
  )
  DBI::dbWriteTable(connection, "reaction_xref", reaction_xrefs, append = TRUE, row.names = FALSE)

  routes <- tables$gift_routes[c(
    "route_id", "name", "description", "status", "oxygen_requirement"
  )]
  routes$gift_pk <- unname(gift_pk[tables$gift_routes$gift_id])
  routes <- routes[c(
    "gift_pk", "route_id", "name", "description", "status", "oxygen_requirement"
  )]
  DBI::dbWriteTable(connection, "gift_route", routes, append = TRUE, row.names = FALSE)
  route_pk <- .db_key_map(connection, "gift_route", "route_id", "route_pk")

  route_reactions <- data.frame(
    route_pk = unname(route_pk[tables$route_reactions$route_id]),
    reaction_pk = unname(reaction_pk[tables$route_reactions$reaction_id]),
    orientation = tables$route_reactions$orientation,
    step_order = as.integer(tables$route_reactions$step_order),
    required = as.integer(tables$route_reactions$required)
  )
  DBI::dbWriteTable(connection, "route_reaction", route_reactions, append = TRUE, row.names = FALSE)

  systems <- tables$enzyme_systems[c("system_id", "name", "description")]
  systems$reaction_pk <- unname(reaction_pk[tables$enzyme_systems$reaction_id])
  systems <- systems[c("reaction_pk", "system_id", "name", "description")]
  DBI::dbWriteTable(connection, "enzyme_system", systems, append = TRUE, row.names = FALSE)
  system_pk <- .db_key_map(connection, "enzyme_system", "system_id", "system_pk")

  components <- tables$enzyme_components[c("component_id", "name", "description")]
  components$system_pk <- unname(system_pk[tables$enzyme_components$system_id])
  components <- components[c("system_pk", "component_id", "name", "description")]
  DBI::dbWriteTable(connection, "enzyme_component", components, append = TRUE, row.names = FALSE)
  component_pk <- .db_key_map(connection, "enzyme_component", "component_id", "component_pk")

  DBI::dbWriteTable(connection, "marker", tables$markers, append = TRUE, row.names = FALSE)
  marker_rows <- DBI::dbGetQuery(connection, "SELECT marker_pk, namespace, accession FROM marker")
  marker_key <- stats::setNames(
    marker_rows$marker_pk,
    paste(marker_rows$namespace, marker_rows$accession, sep = "\r")
  )
  component_marker_key <- paste(
    tables$component_markers$namespace,
    tables$component_markers$accession,
    sep = "\r"
  )
  component_markers <- data.frame(
    component_pk = unname(component_pk[tables$component_markers$component_id]),
    marker_pk = unname(marker_key[component_marker_key]),
    evidence_type = tables$component_markers$evidence_type,
    confidence = tables$component_markers$confidence,
    source = tables$component_markers$source,
    notes = tables$component_markers$notes
  )
  DBI::dbWriteTable(connection, "component_marker", component_markers, append = TRUE, row.names = FALSE)

  database_changes <- tables$database_changes[c(
    "change_id", "released", "changed_at", "layer", "category", "call_effect",
    "summary", "rationale", "evidence", "effect"
  )]
  DBI::dbWriteTable(connection, "database_change", database_changes, append = TRUE, row.names = FALSE)
  change_pk <- .db_key_map(connection, "database_change", "change_id", "change_pk")

  change_gifts <- data.frame(
    change_pk = unname(change_pk[tables$change_gifts$change_id]),
    gift_pk = unname(gift_pk[tables$change_gifts$gift_id])
  )
  DBI::dbWriteTable(connection, "change_gift", change_gifts, append = TRUE, row.names = FALSE)

  release <- tables$database_release
  if (!is.null(source_commit)) release$source_commit <- as.character(source_commit)
  release$release_pk <- 1L
  release$schema_version <- as.integer(release$schema_version)
  release <- release[c(
    "release_pk", "giftr_db_version", "schema_version", "build_date",
    "rhea_release", "chebi_release", "kegg_release", "source_commit"
  )]
  DBI::dbWriteTable(connection, "database_release", release, append = TRUE, row.names = FALSE)

  foreign_keys <- DBI::dbGetQuery(connection, "PRAGMA foreign_key_check")
  if (nrow(foreign_keys)) stop("Compiled database failed foreign-key validation", call. = FALSE)
  integrity <- DBI::dbGetQuery(connection, "PRAGMA integrity_check")[[1]]
  if (!identical(integrity, "ok")) stop("Compiled database failed integrity validation", call. = FALSE)
  DBI::dbCommit(connection)
  committed <- TRUE
  DBI::dbDisconnect(connection)

  if (file.exists(output)) unlink(output)
  if (!file.rename(temporary, output)) {
    if (!file.copy(temporary, output, overwrite = FALSE)) {
      stop("Could not move compiled database to: ", output, call. = FALSE)
    }
    unlink(temporary)
  }
  invisible(output)
}
