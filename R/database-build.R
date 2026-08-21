.gifter_schema_version <- 7L

# The kinds of biologically meaningful capability gifter can state. This is not a
# facet: it selects the completeness model that produces a call, decides which
# source tables may attach to a GIFT, and bounds what a positive call may mean.
.gifter_gift_types <- c("metabolic", "structural", "regulatory", "defense")

# Direction of a metabolic capability. Anchor-derived composition may not cycle
# within a mode; it is expected to cycle between modes, because a catabolic
# route back to a metabolite an anabolic GIFT produces is real biology. The
# other GIFT types have no direction between molecules and must leave it empty.
.gifter_gift_modes <- c("anabolic", "catabolic", "transport", "interconversion")

# Derived resource strategies exposed by the gift_profile view. Named reference
# universes may select these values, but the view remains their single source of
# biological meaning.
.gifter_resource_strategies <- c("uptake", "public_good", "private", "unresolved")

# Metrics that the named-universe registry may recommend. Recommendations are
# discovery metadata only: they do not cause a metric to be computed and cannot
# change a GIFT call. Keeping the vocabulary closed catches misspelled or
# nonexistent output names during source validation.
.gifter_reference_metric_ids <- list(
  genome = c(
    "gift_richness", "supported_fraction", "assessable_fraction",
    "breadth_substrate_class", "breadth_physiological_role",
    "handoff_out_degree", "handoff_in_degree", "multi_implementation_gifts"
  ),
  community = c(
    "community_richness", "community_coverage", "mean_genome_richness",
    "provider_count", "provider_fraction", "abundance_coverage",
    "singleton_fraction", "unique_contribution", "repertoire_overlap"
  ),
  network = c(
    "interaction_density", "handoff_edges", "distributed_chain_links",
    "distributed_cycles"
  )
)

# The modes that declare a direction between molecules, and therefore the modes
# in which a composition cycle is evidence of a badly chosen boundary. See the
# cycle scan in `validate_gifter_sources()` for why `interconversion` is not one
# of them.
.gifter_directed_gift_modes <- setdiff(.gifter_gift_modes, "interconversion")

# The non-metabolic GIFT types share a Boolean shape but not their biology, so
# each keeps its own named tables. This map is the only place the shape is
# stated once: validation, compilation and evaluation are driven by it, which is
# how dispatch happens by GIFT type rather than by trait identity.
.gifter_machinery_models <- list(
  structural = list(
    gift_type = "structural",
    implementation = "architecture", implementation_plural = "architectures",
    unit = "structural function",
    implementation_source = "gift_architectures", implementation_table = "gift_architecture",
    implementation_id = "architecture_id", implementation_pk = "architecture_pk",
    membership_source = "architecture_functions", membership_table = "architecture_function",
    function_source = "structural_functions", function_table = "structural_function",
    system_source = "structural_systems", system_table = "structural_system",
    component_source = "structural_components", component_table = "structural_component",
    evidence_source = "structural_component_markers",
    evidence_table = "structural_component_marker"
  ),
  regulatory = list(
    gift_type = "regulatory",
    implementation = "circuit", implementation_plural = "circuits",
    unit = "regulatory function",
    implementation_source = "gift_circuits", implementation_table = "gift_circuit",
    implementation_id = "circuit_id", implementation_pk = "circuit_pk",
    membership_source = "circuit_functions", membership_table = "circuit_function",
    function_source = "regulatory_functions", function_table = "regulatory_function",
    system_source = "regulatory_systems", system_table = "regulatory_system",
    component_source = "regulatory_components", component_table = "regulatory_component",
    evidence_source = "regulatory_component_markers",
    evidence_table = "regulatory_component_marker"
  ),
  defense = list(
    gift_type = "defense",
    implementation = "mechanism", implementation_plural = "mechanisms",
    unit = "defense function",
    implementation_source = "gift_mechanisms", implementation_table = "gift_mechanism",
    implementation_id = "mechanism_id", implementation_pk = "mechanism_pk",
    membership_source = "mechanism_functions", membership_table = "mechanism_function",
    function_source = "defense_functions", function_table = "defense_function",
    system_source = "defense_systems", system_table = "defense_system",
    component_source = "defense_components", component_table = "defense_component",
    evidence_source = "defense_component_markers",
    evidence_table = "defense_component_marker"
  )
)

# Two-state location qualifier on declared anchors. Nothing else in gifter is
# compartmentalised; see inst/doc/architecture.md.
.gifter_compartments <- c("extracellular", "cytoplasmic", "unspecified")

# Whether a route needs oxygen. This is a route property and not a GIFT
# property: alternative routes to the same anchors genuinely differ, and
# recording it on the GIFT would flatten the distinction the OR-over-routes
# model exists to preserve.
.gifter_oxygen_requirements <- c("aerobic", "anaerobic", "independent")

# What a facet may classify.
.gifter_facet_targets <- c("gift", "anchor")

# Facets a GIFT must carry, scoped by GIFT type because the questions differ.
# `substrate_class` answers "what chemistry is this capability about" and is
# meaningless for a flagellum; `structural_class` answers "what kind of thing is
# built" and is meaningless for a biosynthetic route. Single-valued facets can
# partition their type; multi-valued ones return supersets.
#
# Each type's single-valued class facet partitions that type and answers the
# question the type is about: what chemistry, what structure, what kind of
# signalling machine, what kind of defense. Each vocabulary was registered when
# the first content of its type was curated, not before.
.gifter_required_gift_facets <- list(
  metabolic = list(single = "substrate_class", multi = "physiological_role"),
  structural = list(single = "structural_class", multi = character()),
  regulatory = list(single = "regulatory_class", multi = character()),
  defense = list(single = "defense_class", multi = character())
)

# Facets an anchor must carry, both single-valued: a molecule has one size tier
# and is either a building block or not. `resource_origin` is deliberately not
# required. It is meant to be total, but a missing origin is warned rather than
# rejected, so that a new anchor can be curated in two passes instead of
# blocking the chemistry on a provenance judgement.
.gifter_required_single_anchor_facets <- c("molecular_tier", "biomass_essential")
.gifter_expected_anchor_facets <- c("resource_origin")

# How a curated GIFT boundary compares with an external pathway record. A GIFT
# is never defined as a pathway, so the relation is part of the biological
# claim and not decoration.
.gifter_xref_relations <- c(
  "equivalent", "subset_of", "superset_of", "overlaps", "related"
)

# Hierarchy layers a curation decision can touch. The metabolic layers come
# first, then the layers of each typed machinery model.
.gifter_change_layers <- c(
  "gift", "anchor", "route", "reaction", "enzyme_system",
  "enzyme_component", "marker",
  "architecture", "structural_function", "structural_system", "structural_component",
  "circuit", "regulatory_function", "regulatory_system", "regulatory_component",
  "mechanism", "defense_function", "defense_system", "defense_component",
  "provenance", "schema"
)

# Layers that make a biological claim about specific traits. A change to one of
# them must name the GIFTs it affects; provenance and schema changes need not.
.gifter_gift_bearing_layers <- setdiff(.gifter_change_layers, c("provenance", "schema"))

.gifter_change_categories <- c("addition", "correction", "removal", "clarification")

.gifter_call_effects <- c("broadens", "narrows", "mixed", "none")

.gifter_source_spec <- list(
  gifts = c(
    "gift_id", "gift_type", "name", "description", "mode", "status", "version",
    "notes"
  ),
  facet_terms = c("facet", "value", "applies_to", "definition"),
  gift_facets = c("gift_id", "facet", "value", "notes"),
  anchor_facets = c("anchor_id", "facet", "value", "notes"),
  reference_universes = c(
    "universe_id", "label", "description", "bounded", "interpretation"
  ),
  reference_universe_filters = c("universe_id", "filter_key", "value"),
  reference_universe_metrics = c("universe_id", "scope", "metric_id", "rationale"),
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
  gift_architectures = c("architecture_id", "gift_id", "name", "description", "status"),
  architecture_functions = c("architecture_id", "function_id", "ordinal", "required"),
  structural_functions = c("function_id", "name", "description"),
  structural_systems = c("system_id", "function_id", "name", "description"),
  structural_components = c("component_id", "system_id", "name", "description"),
  structural_component_markers = c(
    "component_id", "namespace", "accession", "evidence_type",
    "confidence", "source", "notes"
  ),
  gift_circuits = c("circuit_id", "gift_id", "name", "description", "status"),
  circuit_functions = c("circuit_id", "function_id", "ordinal", "required"),
  regulatory_functions = c("function_id", "name", "description"),
  regulatory_systems = c("system_id", "function_id", "name", "description"),
  regulatory_components = c("component_id", "system_id", "name", "description"),
  regulatory_component_markers = c(
    "component_id", "namespace", "accession", "evidence_type",
    "confidence", "source", "notes"
  ),
  gift_mechanisms = c("mechanism_id", "gift_id", "name", "description", "status"),
  mechanism_functions = c("mechanism_id", "function_id", "ordinal", "required"),
  defense_functions = c("function_id", "name", "description"),
  defense_systems = c("system_id", "function_id", "name", "description"),
  defense_components = c("component_id", "system_id", "name", "description"),
  defense_component_markers = c(
    "component_id", "namespace", "accession", "evidence_type",
    "confidence", "source", "notes"
  ),
  database_changes = c(
    "change_id", "released", "changed_at", "layer", "category", "call_effect",
    "summary", "rationale", "evidence", "effect"
  ),
  change_gifts = c("change_id", "gift_id"),
  database_release = c(
    "gifter_db_version", "schema_version", "build_date", "rhea_release",
    "chebi_release", "kegg_release", "source_commit"
  )
)

.read_gifter_sources <- function(source_dir) {
  if (!dir.exists(source_dir)) {
    stop("Source directory does not exist: ", source_dir, call. = FALSE)
  }

  tables <- lapply(names(.gifter_source_spec), function(table) {
    path <- file.path(source_dir, paste0(table, ".tsv"))
    if (!file.exists(path)) {
      return(structure(list(path = path), class = "gifter_missing_source"))
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
  names(tables) <- names(.gifter_source_spec)
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

#' Validate human-readable gifter database sources
#'
#' Performs structural validation before a SQLite database is compiled. Any
#' duplicate identifiers, broken references, missing hierarchy levels, invalid
#' directions, malformed anchor boundaries, graph cycles, or inconsistent
#' release metadata are reported as build errors.
#'
#' @param source_dir Directory containing the gifter TSV source tables.
#' @param stop_on_error If `TRUE`, stop when structural errors are found.
#' @return A list with `valid`, `errors`, `warnings`, and table row counts.
#' @export
validate_gifter_sources <- function(source_dir, stop_on_error = TRUE) {
  tables <- .read_gifter_sources(source_dir)
  errors <- character()
  warnings <- character()

  for (table in names(.gifter_source_spec)) {
    value <- tables[[table]]
    if (inherits(value, "gifter_missing_source")) {
      errors <- c(errors, paste0("Missing source table: ", basename(value$path)))
      next
    }
    missing_columns <- setdiff(.gifter_source_spec[[table]], names(value))
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
      class = "gifter_validation"
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
    change_gifts = "change_id", database_release = "gifter_db_version",
    facet_terms = "facet", gift_facets = "gift_id", anchor_facets = "anchor_id",
    reference_universes = "universe_id",
    reference_universe_filters = "universe_id",
    reference_universe_metrics = "universe_id"
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
    enzyme_components = "component_id", database_changes = "change_id",
    gift_architectures = "architecture_id", structural_functions = "function_id",
    structural_systems = "system_id", structural_components = "component_id",
    gift_circuits = "circuit_id", regulatory_functions = "function_id",
    regulatory_systems = "system_id", regulatory_components = "component_id",
    gift_mechanisms = "mechanism_id", defense_functions = "function_id",
    defense_systems = "system_id", defense_components = "component_id",
    reference_universes = "universe_id"
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
    list("anchor_facets.anchor_id", tables$anchor_facets$anchor_id, tables$anchors$anchor_id),
    list(
      "reference_universe_filters.universe_id",
      tables$reference_universe_filters$universe_id,
      tables$reference_universes$universe_id
    ),
    list(
      "reference_universe_metrics.universe_id",
      tables$reference_universe_metrics$universe_id,
      tables$reference_universes$universe_id
    )
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
  invalid_targets <- setdiff(unique(tables$facet_terms$applies_to), .gifter_facet_targets)
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
  for (target in .gifter_facet_targets) {
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

  # Named reference universes are curated analytical metadata, not stored GIFT
  # memberships. Filters are ANDed across keys and ORed within a key, so every
  # preset remains a reproducible query over the ontology rather than a list of
  # stable IDs that would drift as the catalogue grows.
  universes <- tables$reference_universes
  universe_filters <- tables$reference_universe_filters
  universe_metrics <- tables$reference_universe_metrics
  if (length(.duplicate_values(universes$label))) {
    errors <- c(errors, "reference_universes.label must be unique")
  }
  invalid_universe_ids <- universes$universe_id[
    is.na(universes$universe_id) |
      !grepl("^[a-z][a-z0-9_]*$", universes$universe_id)
  ]
  if (length(invalid_universe_ids)) {
    errors <- c(
      errors,
      paste0(
        "Invalid reference_universes.universe_id: ",
        paste(unique(invalid_universe_ids), collapse = ", ")
      )
    )
  }
  for (column in c("label", "description", "interpretation")) {
    empty <- universes$universe_id[
      is.na(universes[[column]]) | !nzchar(trimws(universes[[column]]))
    ]
    if (length(empty)) {
      errors <- c(
        errors,
        paste0(
          "reference_universes.", column, " must be recorded for: ",
          paste(empty, collapse = ", ")
        )
      )
    }
  }
  bounded <- suppressWarnings(as.integer(universes$bounded))
  invalid_bounded <- universes$universe_id[is.na(bounded) | !bounded %in% c(0L, 1L)]
  if (length(invalid_bounded)) {
    errors <- c(
      errors,
      paste0(
        "reference_universes.bounded must be 0 or 1 for: ",
        paste(invalid_bounded, collapse = ", ")
      )
    )
  }
  if (length(.duplicate_keys(
    universe_filters, c("universe_id", "filter_key", "value")
  ))) {
    errors <- c(errors, "reference_universe_filters contains duplicate filters")
  }
  missing_filters <- setdiff(universes$universe_id, universe_filters$universe_id)
  if (length(missing_filters)) {
    errors <- c(
      errors,
      paste0(
        "Every named reference universe needs a metadata filter: ",
        paste(missing_filters, collapse = ", ")
      )
    )
  }
  empty_filter_values <- universe_filters$universe_id[
    is.na(universe_filters$value) | !nzchar(trimws(universe_filters$value))
  ]
  if (length(empty_filter_values)) {
    errors <- c(
      errors,
      paste0(
        "reference_universe_filters.value must be recorded for: ",
        paste(unique(empty_filter_values), collapse = ", ")
      )
    )
  }
  simple_filter_keys <- c(
    "type", "mode", "status", "resource_strategy", "auxotrophy_indicator"
  )
  is_facet_filter <- grepl("^facet:[a-z][a-z0-9_]*$", universe_filters$filter_key)
  invalid_filter_keys <- universe_filters$filter_key[
    is.na(universe_filters$filter_key) |
      !(universe_filters$filter_key %in% simple_filter_keys | is_facet_filter)
  ]
  if (length(invalid_filter_keys)) {
    errors <- c(
      errors,
      paste0(
        "Invalid reference_universe_filters.filter_key: ",
        paste(unique(invalid_filter_keys), collapse = ", ")
      )
    )
  }
  validate_filter_values <- function(key, allowed) {
    values <- universe_filters$value[universe_filters$filter_key == key]
    invalid <- setdiff(values, allowed)
    if (length(invalid)) {
      errors <<- c(
        errors,
        paste0(
          "Invalid ", key, " reference-universe filter value: ",
          paste(invalid, collapse = ", ")
        )
      )
    }
  }
  validate_filter_values("type", .gifter_gift_types)
  validate_filter_values("mode", .gifter_gift_modes)
  validate_filter_values("status", unique(tables$gifts$status))
  validate_filter_values("resource_strategy", .gifter_resource_strategies)
  validate_filter_values("auxotrophy_indicator", c("true", "false"))
  facet_filter_rows <- universe_filters[is_facet_filter, , drop = FALSE]
  if (nrow(facet_filter_rows)) {
    facet_filter_rows$facet <- sub("^facet:", "", facet_filter_rows$filter_key)
    gift_terms <- tables$facet_terms[
      tables$facet_terms$applies_to == "gift", c("facet", "value"), drop = FALSE
    ]
    registered_gift_terms <- paste(gift_terms$facet, gift_terms$value, sep = "\r")
    requested_gift_terms <- paste(
      facet_filter_rows$facet, facet_filter_rows$value, sep = "\r"
    )
    unknown <- setdiff(requested_gift_terms, registered_gift_terms)
    if (length(unknown)) {
      errors <- c(
        errors,
        paste0(
          "Unregistered reference-universe facet filters: ",
          paste(sub("\r", "=", unknown, fixed = TRUE), collapse = ", ")
        )
      )
    }
  }
  if (length(.duplicate_keys(
    universe_metrics, c("universe_id", "scope", "metric_id")
  ))) {
    errors <- c(errors, "reference_universe_metrics contains duplicate recommendations")
  }
  invalid_scopes <- setdiff(unique(universe_metrics$scope), names(.gifter_reference_metric_ids))
  if (length(invalid_scopes)) {
    errors <- c(
      errors,
      paste0(
        "Invalid reference_universe_metrics.scope: ",
        paste(invalid_scopes, collapse = ", ")
      )
    )
  }
  for (scope in intersect(unique(universe_metrics$scope), names(.gifter_reference_metric_ids))) {
    invalid <- setdiff(
      universe_metrics$metric_id[universe_metrics$scope == scope],
      .gifter_reference_metric_ids[[scope]]
    )
    if (length(invalid)) {
      errors <- c(
        errors,
        paste0(
          "Invalid ", scope, " reference-universe metric: ",
          paste(invalid, collapse = ", ")
        )
      )
    }
  }
  empty_metric_rationale <- universe_metrics$universe_id[
    is.na(universe_metrics$rationale) |
      !nzchar(trimws(universe_metrics$rationale))
  ]
  if (length(empty_metric_rationale)) {
    errors <- c(
      errors,
      paste0(
        "reference_universe_metrics.rationale must be recorded for: ",
        paste(unique(empty_metric_rationale), collapse = ", ")
      )
    )
  }
  open_ids <- universes$universe_id[bounded == 0L]
  invalid_fraction_recommendations <- universe_metrics$universe_id[
    universe_metrics$universe_id %in% open_ids &
      universe_metrics$metric_id %in% c("supported_fraction", "community_coverage")
  ]
  if (length(invalid_fraction_recommendations)) {
    errors <- c(
      errors,
      paste0(
        "Unbounded reference universes may not recommend coverage fractions: ",
        paste(unique(invalid_fraction_recommendations), collapse = ", ")
      )
    )
  }

  # Required facets are scoped by GIFT type: a substrate class is meaningless for
  # a flagellum, and a structural class is meaningless for a biosynthetic route.
  for (type in names(.gifter_required_gift_facets)) {
    of_type <- tables$gifts$gift_id[
      !is.na(tables$gifts$gift_type) & tables$gifts$gift_type == type
    ]
    if (!length(of_type)) next
    requirement <- .gifter_required_gift_facets[[type]]
    for (facet in requirement$single) {
      assigned <- tables$gift_facets$gift_id[
        tables$gift_facets$facet == facet & tables$gift_facets$gift_id %in% of_type
      ]
      counts <- table(assigned)
      missing_facet <- setdiff(of_type, names(counts))
      if (length(missing_facet)) {
        errors <- c(
          errors,
          paste0(
            "Every ", type, " GIFT needs one ", facet, ": ",
            paste(missing_facet, collapse = ", ")
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
    for (facet in requirement$multi) {
      missing_facet <- setdiff(
        of_type, tables$gift_facets$gift_id[tables$gift_facets$facet == facet]
      )
      if (length(missing_facet)) {
        errors <- c(
          errors,
          paste0(
            "Every ", type, " GIFT needs at least one ", facet, ": ",
            paste(missing_facet, collapse = ", ")
          )
        )
      }
    }
    # A facet required of one type must not silently classify another: a
    # structural GIFT with a substrate class would claim chemistry it has none of.
    foreign <- unlist(lapply(
      setdiff(names(.gifter_required_gift_facets), type),
      function(other) .gifter_required_gift_facets[[other]]$single
    ))
    foreign <- setdiff(foreign, c(requirement$single, requirement$multi))
    misapplied <- sort(unique(tables$gift_facets$gift_id[
      tables$gift_facets$facet %in% foreign & tables$gift_facets$gift_id %in% of_type
    ]))
    if (length(misapplied)) {
      errors <- c(
        errors,
        paste0(
          "A ", type, " GIFT carries a facet required of another GIFT type: ",
          paste(misapplied, collapse = ", ")
        )
      )
    }
  }

  for (facet in .gifter_required_single_anchor_facets) {
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
  for (facet in .gifter_expected_anchor_facets) {
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
    unique(tables$gift_routes$oxygen_requirement), .gifter_oxygen_requirements
  )
  if (length(invalid_oxygen)) {
    errors <- c(
      errors,
      paste0("Invalid gift_routes.oxygen_requirement: ", paste(invalid_oxygen, collapse = ", "))
    )
  }

  invalid_compartments <- setdiff(unique(tables$anchors$compartment), .gifter_compartments)
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
  # `gift_type` selects the completeness model, so an unknown value cannot be
  # evaluated at all and is rejected before anything else about the GIFT is read.
  declared_types <- unique(tables$gifts$gift_type)
  untyped <- tables$gifts$gift_id[is.na(tables$gifts$gift_type)]
  if (length(untyped)) {
    errors <- c(
      errors,
      paste0("gifts.gift_type must be recorded for: ", paste(untyped, collapse = ", "))
    )
  }
  invalid_types <- setdiff(declared_types[!is.na(declared_types)], .gifter_gift_types)
  if (length(invalid_types)) {
    errors <- c(
      errors,
      paste0("Invalid gifts.gift_type: ", paste(invalid_types, collapse = ", "))
    )
  }

  gift_type <- stats::setNames(tables$gifts$gift_type, tables$gifts$gift_id)
  gifts_of_type <- function(type) {
    tables$gifts$gift_id[!is.na(tables$gifts$gift_type) & tables$gifts$gift_type == type]
  }
  metabolic_gifts <- gifts_of_type("metabolic")

  invalid_modes <- setdiff(
    unique(tables$gifts$mode[!is.na(tables$gifts$mode)]), .gifter_gift_modes
  )
  if (length(invalid_modes)) {
    errors <- c(errors, paste0("Invalid gifts.mode: ", paste(invalid_modes, collapse = ", ")))
  }
  # `mode` is the direction of a metabolic capability. A flagellum has none, and
  # inventing one would let a structural GIFT into the anchor-derived cycle check.
  missing_mode <- setdiff(metabolic_gifts, tables$gifts$gift_id[!is.na(tables$gifts$mode)])
  if (length(missing_mode)) {
    errors <- c(
      errors,
      paste0("Every metabolic GIFT needs a mode: ", paste(missing_mode, collapse = ", "))
    )
  }
  moded_non_metabolic <- tables$gifts$gift_id[
    !is.na(tables$gifts$mode) & !tables$gifts$gift_id %in% metabolic_gifts
  ]
  if (length(moded_non_metabolic)) {
    errors <- c(
      errors,
      paste0(
        "mode applies to metabolic GIFTs only, but is recorded for: ",
        paste(moded_non_metabolic, collapse = ", ")
      )
    )
  }

  # The metabolic anchor/route model is metabolic-only. A structural GIFT that
  # declared anchors would be inventing molecular boundaries to satisfy a schema
  # rather than describing a structure.
  for (check in list(
    list("gift_anchors", tables$gift_anchors$gift_id),
    list("gift_routes", tables$gift_routes$gift_id)
  )) {
    misplaced <- sort(unique(check[[2]][
      check[[2]] %in% tables$gifts$gift_id & !check[[2]] %in% metabolic_gifts
    ]))
    if (length(misplaced)) {
      errors <- c(
        errors,
        paste0(
          check[[1]], " describes the metabolic model and may not name a ",
          "non-metabolic GIFT: ", paste(misplaced, collapse = ", ")
        )
      )
    }
  }

  anchor_molecule <- stats::setNames(tables$anchors$molecule, tables$anchors$anchor_id)
  gift_mode <- stats::setNames(tables$gifts$mode, tables$gifts$gift_id)

  for (gift_id in metabolic_gifts) {
    anchors <- tables$gift_anchors[tables$gift_anchors$gift_id == gift_id, , drop = FALSE]
    routes <- tables$gift_routes[tables$gift_routes$gift_id == gift_id, , drop = FALSE]
    if (!any(anchors$role == "input")) errors <- c(errors, paste0(gift_id, " has no input anchor"))
    if (!any(anchors$role == "output")) errors <- c(errors, paste0(gift_id, " has no output anchor"))
    if (!nrow(routes)) errors <- c(errors, paste0(gift_id, " has no route"))
    mode <- unname(gift_mode[gift_id])
    inputs <- anchors$anchor_id[anchors$role == "input"]
    outputs <- anchors$anchor_id[anchors$role == "output"]

    # Three ways a molecule can appear on both sides of a boundary, and the
    # mode is what says which one is meant.
    #
    #   the same anchor, so the same molecule in the same compartment
    #     -> a reversible node: the chemistry runs both ways and the evidence
    #        does not say which, so both directions are declared. Only an
    #        `interconversion` GIFT may say this.
    #   different anchors of one molecule, so two compartments
    #     -> translocation, which is what `transport` means.
    #   neither
    #     -> ordinary directed chemistry.
    #
    # Collapsing the first two would cost the compartment layer its meaning:
    # transport would stop being required to reach the cytoplasm.
    mirrored <- intersect(inputs, outputs)
    translocated <- setdiff(
      intersect(
        unname(anchor_molecule[inputs]), unname(anchor_molecule[outputs])
      ),
      unname(anchor_molecule[mirrored])
    )

    if (length(mirrored) && !identical(mode, "interconversion")) {
      errors <- c(
        errors,
        paste0(
          gift_id, " declares ", paste(sort(mirrored), collapse = ", "),
          " as both input and output; only mode = interconversion may do that"
        )
      )
    }
    # The contract runs both ways. A GIFT that declares itself reversible must
    # declare every boundary reversibly, or it is asserting a direction for
    # some of them while denying one for the rest.
    if (identical(mode, "interconversion")) {
      one_way <- setdiff(union(inputs, outputs), mirrored)
      if (length(one_way)) {
        errors <- c(
          errors,
          paste0(
            gift_id, " is an interconversion GIFT, so every anchor must be ",
            "declared as both input and output, but these are not: ",
            paste(sort(one_way), collapse = ", ")
          )
        )
      }
    }
    if (identical(mode, "transport") && !length(translocated)) {
      errors <- c(
        errors,
        paste0(gift_id, " is a transport GIFT but no molecule appears as both input and output")
      )
    }
    if (!identical(mode, "transport") && length(translocated)) {
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

  invalid_relations <- setdiff(unique(tables$gift_xrefs$relation), .gifter_xref_relations)
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

  # ---- typed machinery models ---------------------------------------------
  #
  # Structural, regulatory and defense GIFTs are evaluated over their own named
  # tables. The checks below are identical in shape because the Boolean contract
  # is identical; the tables they read are not, which is what keeps a regulatory
  # circuit from being curated as a flagellar architecture.
  for (model in .gifter_machinery_models) {
    implementations <- tables[[model$implementation_source]]
    membership <- tables[[model$membership_source]]
    functions <- tables[[model$function_source]]
    systems <- tables[[model$system_source]]
    components <- tables[[model$component_source]]
    evidence <- tables[[model$evidence_source]]
    id_column <- model$implementation_id
    typed_gifts <- gifts_of_type(model$gift_type)

    for (check in list(
      list(paste0(model$implementation_source, ".gift_id"),
           implementations$gift_id, tables$gifts$gift_id),
      list(paste0(model$membership_source, ".", id_column),
           membership[[id_column]], implementations[[id_column]]),
      list(paste0(model$membership_source, ".function_id"),
           membership$function_id, functions$function_id),
      list(paste0(model$system_source, ".function_id"),
           systems$function_id, functions$function_id),
      list(paste0(model$component_source, ".system_id"),
           components$system_id, systems$system_id),
      list(paste0(model$evidence_source, ".component_id"),
           evidence$component_id, components$component_id),
      list(paste0(model$evidence_source, " marker key"),
           paste(evidence$namespace, evidence$accession, sep = "\r"),
           paste(tables$markers$namespace, tables$markers$accession, sep = "\r"))
    )) {
      missing <- .missing_refs(check[[2]], check[[3]])
      if (length(missing)) {
        errors <- c(
          errors,
          paste0(
            "Invalid ", check[[1]], ": ",
            paste(sub("\r", ":", missing, fixed = TRUE), collapse = ", ")
          )
        )
      }
    }

    # A curated row belongs to exactly one completeness model. Attaching an
    # architecture to a metabolic GIFT, or a circuit to a structural one, would
    # make the GIFT's type stop predicting how it is evaluated.
    wrong_type <- sort(unique(implementations$gift_id[
      implementations$gift_id %in% tables$gifts$gift_id &
        !implementations$gift_id %in% typed_gifts
    ]))
    if (length(wrong_type)) {
      errors <- c(
        errors,
        paste0(
          model$implementation_source, " describes the ", model$gift_type,
          " model and may not name a GIFT of another type: ",
          paste(wrong_type, collapse = ", ")
        )
      )
    }

    without_implementation <- setdiff(typed_gifts, implementations$gift_id)
    if (length(without_implementation)) {
      errors <- c(
        errors,
        paste0(
          "Every ", model$gift_type, " GIFT needs at least one ",
          model$implementation, ": ", paste(without_implementation, collapse = ", ")
        )
      )
    }

    if (length(.duplicate_keys(membership, c(id_column, "function_id")))) {
      errors <- c(
        errors,
        paste0(model$membership_source, " contains duplicate ",
               model$implementation, "/function pairs")
      )
    }
    if (length(.duplicate_keys(membership, c(id_column, "ordinal")))) {
      errors <- c(
        errors, paste0(model$membership_source, " contains duplicate ordinal values")
      )
    }
    if (length(.duplicate_keys(evidence, c("component_id", "namespace", "accession")))) {
      errors <- c(
        errors, paste0(model$evidence_source, " contains duplicate component/marker pairs")
      )
    }
    ordinals <- suppressWarnings(as.integer(membership$ordinal))
    if (any(is.na(ordinals) | ordinals < 1L)) {
      errors <- c(errors, paste0(model$membership_source, " contains an invalid ordinal"))
    }
    if (any(!membership$required %in% c("0", "1"))) {
      errors <- c(errors, paste0(model$membership_source, ".required must be 0 or 1"))
    }

    # Completeness is discrete, so every level of the hierarchy must be able to
    # be satisfied. An implementation with only accessory functions, or a
    # component with no accepted evidence, can never produce a defensible call.
    for (implementation_id in implementations[[id_column]]) {
      required <- membership[
        membership[[id_column]] == implementation_id & membership$required == "1",
        , drop = FALSE
      ]
      if (!nrow(required)) {
        errors <- c(
          errors,
          paste0(implementation_id, " has no required ", model$unit)
        )
      }
    }
    for (function_id in functions$function_id) {
      if (!any(systems$function_id == function_id)) {
        errors <- c(errors, paste0(function_id, " has no system"))
      }
      if (!any(membership$function_id == function_id)) {
        warnings <- c(
          warnings,
          paste0(function_id, " is not used by any ", model$implementation)
        )
      }
    }
    for (system_id in systems$system_id) {
      if (!any(components$system_id == system_id)) {
        errors <- c(errors, paste0(system_id, " has no component"))
      }
    }
    for (component_id in components$component_id) {
      if (!any(evidence$component_id == component_id)) {
        errors <- c(errors, paste0(component_id, " has no marker"))
      }
    }
  }

  # Function, system and component identifiers are stable public keys that a
  # trace prints without saying which table they came from, so they must be
  # unique across the models, not only within one.
  for (level in list(
    list("function", c("structural_functions", "regulatory_functions", "defense_functions"), "function_id"),
    list("system", c("enzyme_systems", "structural_systems", "regulatory_systems", "defense_systems"), "system_id"),
    list("component", c("enzyme_components", "structural_components", "regulatory_components", "defense_components"), "component_id"),
    list("implementation", c("gift_routes", "gift_architectures", "gift_circuits", "gift_mechanisms"),
         c("route_id", "architecture_id", "circuit_id", "mechanism_id"))
  )) {
    columns <- level[[3]]
    if (length(columns) == 1L) columns <- rep(columns, length(level[[2]]))
    values <- unlist(Map(function(table, column) tables[[table]][[column]], level[[2]], columns))
    shared <- .duplicate_values(values)
    if (length(shared)) {
      errors <- c(
        errors,
        paste0(
          "The same ", level[[1]], " identifier is used by more than one GIFT model: ",
          paste(sort(shared), collapse = ", ")
        )
      )
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
    # Cycles are forbidden within a directed mode and expected between modes.
    #
    # `interconversion` is exempt, and the exemption is not a concession to any
    # particular biology. That mode's boundary contract requires every anchor to
    # be declared in both roles, so two interconversion GIFTs that share one
    # anchor produce an edge in each direction by construction. The loop is made
    # by the mode, not by the boundary, and reporting it would be the check
    # reading its own contract back as a curation error.
    for (mode in intersect(.gifter_directed_gift_modes, unique(tables$gifts$mode))) {
      # `%in%` rather than `==` so that a GIFT whose mode is missing -- which is
      # a separate, already reported error -- drops out of the scan instead of
      # producing an NA row the traversal cannot name.
      within_mode <- edges[
        unname(gift_mode[edges$from]) %in% mode & unname(gift_mode[edges$to]) %in% mode,
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
  invalid_layers <- setdiff(unique(changes$layer), .gifter_change_layers)
  if (length(invalid_layers)) {
    errors <- c(errors, paste0("Invalid database_changes.layer: ", paste(invalid_layers, collapse = ", ")))
  }
  invalid_categories <- setdiff(unique(changes$category), .gifter_change_categories)
  if (length(invalid_categories)) {
    errors <- c(
      errors,
      paste0("Invalid database_changes.category: ", paste(invalid_categories, collapse = ", "))
    )
  }
  invalid_effects <- setdiff(unique(changes$call_effect), .gifter_call_effects)
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
    changes$change_id[changes$layer %in% .gifter_gift_bearing_layers],
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
    required_release <- .gifter_source_spec$database_release
    if (any(is.na(release[1, required_release]))) {
      errors <- c(errors, "database_release contains missing version fields")
    }
    release_schema <- suppressWarnings(as.integer(release$schema_version[[1]]))
    if (is.na(release_schema) || release_schema != .gifter_schema_version) {
      errors <- c(errors, paste0("schema_version must be ", .gifter_schema_version))
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
    class = "gifter_validation"
  )
  if (length(errors) && isTRUE(stop_on_error)) {
    stop(paste(c("gifter source validation failed:", paste0("- ", errors)), collapse = "\n"), call. = FALSE)
  }
  report
}

.gifter_schema_path <- function() {
  path <- system.file("schema", "gifter.sql", package = "gifter")
  if (nzchar(path)) return(path)
  candidate <- file.path("inst", "schema", "gifter.sql")
  if (file.exists(candidate)) return(candidate)
  stop("Could not locate the gifter SQL schema", call. = FALSE)
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

#' Compile gifter source tables into SQLite
#'
#' Validates the human-readable TSV source tables and compiles a normalized,
#' indexed SQLite database. The output is written atomically after all foreign
#' key checks pass.
#'
#' @param source_dir Directory containing the gifter TSV source tables.
#' @param output Path for the compiled SQLite database.
#' @param overwrite Whether an existing output may be replaced.
#' @param source_commit Optional source commit to store in release metadata.
#' @return The normalized output path, invisibly.
#' @export
build_gifter_database <- function(source_dir, output, overwrite = FALSE, source_commit = NULL) {
  validate_gifter_sources(source_dir, stop_on_error = TRUE)
  tables <- .read_gifter_sources(source_dir)
  output <- normalizePath(output, winslash = "/", mustWork = FALSE)
  if (file.exists(output) && !isTRUE(overwrite)) {
    stop("Output already exists; set overwrite = TRUE to replace it: ", output, call. = FALSE)
  }
  dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile("gifter-build-", tmpdir = dirname(output), fileext = ".sqlite")
  on.exit(if (file.exists(temporary)) unlink(temporary), add = TRUE)

  connection <- DBI::dbConnect(RSQLite::SQLite(), temporary)
  on.exit(if (DBI::dbIsValid(connection)) DBI::dbDisconnect(connection), add = TRUE)
  DBI::dbExecute(connection, "PRAGMA foreign_keys = ON")
  .execute_schema(connection, .gifter_schema_path())
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

  reference_universes <- tables$reference_universes
  reference_universes$bounded <- as.integer(reference_universes$bounded)
  DBI::dbWriteTable(
    connection, "reference_universe", reference_universes,
    append = TRUE, row.names = FALSE
  )
  universe_pk <- .db_key_map(
    connection, "reference_universe", "universe_id", "universe_pk"
  )
  DBI::dbWriteTable(
    connection, "reference_universe_filter",
    data.frame(
      universe_pk = unname(universe_pk[tables$reference_universe_filters$universe_id]),
      filter_key = tables$reference_universe_filters$filter_key,
      value = tables$reference_universe_filters$value,
      stringsAsFactors = FALSE
    ),
    append = TRUE, row.names = FALSE
  )
  DBI::dbWriteTable(
    connection, "reference_universe_metric",
    data.frame(
      universe_pk = unname(universe_pk[tables$reference_universe_metrics$universe_id]),
      scope = tables$reference_universe_metrics$scope,
      metric_id = tables$reference_universe_metrics$metric_id,
      rationale = tables$reference_universe_metrics$rationale,
      stringsAsFactors = FALSE
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

  # Compile each typed machinery model from its own named source tables. The
  # loop is generic because the relational shape is; the tables it reads are
  # biologically specific because the content is.
  for (model in .gifter_machinery_models) {
    functions <- tables[[model$function_source]]
    DBI::dbWriteTable(
      connection, model$function_table,
      functions[c("function_id", "name", "description")],
      append = TRUE, row.names = FALSE
    )
    function_pk <- .db_key_map(connection, model$function_table, "function_id", "function_pk")

    systems <- tables[[model$system_source]]
    DBI::dbWriteTable(
      connection, model$system_table,
      data.frame(
        function_pk = unname(function_pk[systems$function_id]),
        system_id = systems$system_id,
        name = systems$name,
        description = systems$description,
        stringsAsFactors = FALSE
      ),
      append = TRUE, row.names = FALSE
    )
    system_pk <- .db_key_map(connection, model$system_table, "system_id", "system_pk")

    components <- tables[[model$component_source]]
    DBI::dbWriteTable(
      connection, model$component_table,
      data.frame(
        system_pk = unname(system_pk[components$system_id]),
        component_id = components$component_id,
        name = components$name,
        description = components$description,
        stringsAsFactors = FALSE
      ),
      append = TRUE, row.names = FALSE
    )
    component_pk <- .db_key_map(connection, model$component_table, "component_id", "component_pk")

    evidence <- tables[[model$evidence_source]]
    DBI::dbWriteTable(
      connection, model$evidence_table,
      data.frame(
        component_pk = unname(component_pk[evidence$component_id]),
        marker_pk = unname(marker_key[paste(evidence$namespace, evidence$accession, sep = "\r")]),
        evidence_type = evidence$evidence_type,
        confidence = evidence$confidence,
        source = evidence$source,
        notes = evidence$notes,
        stringsAsFactors = FALSE
      ),
      append = TRUE, row.names = FALSE
    )

    implementations <- tables[[model$implementation_source]]
    implementation_rows <- data.frame(
      gift_pk = unname(gift_pk[implementations$gift_id]),
      id = implementations[[model$implementation_id]],
      name = implementations$name,
      description = implementations$description,
      status = implementations$status,
      stringsAsFactors = FALSE
    )
    names(implementation_rows)[[2]] <- model$implementation_id
    DBI::dbWriteTable(
      connection, model$implementation_table, implementation_rows,
      append = TRUE, row.names = FALSE
    )
    implementation_pk <- .db_key_map(
      connection, model$implementation_table, model$implementation_id, model$implementation_pk
    )

    membership <- tables[[model$membership_source]]
    membership_rows <- data.frame(
      implementation = unname(implementation_pk[membership[[model$implementation_id]]]),
      function_pk = unname(function_pk[membership$function_id]),
      ordinal = as.integer(membership$ordinal),
      required = as.integer(membership$required),
      stringsAsFactors = FALSE
    )
    names(membership_rows)[[1]] <- model$implementation_pk
    DBI::dbWriteTable(
      connection, model$membership_table, membership_rows,
      append = TRUE, row.names = FALSE
    )
  }

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
    "release_pk", "gifter_db_version", "schema_version", "build_date",
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
