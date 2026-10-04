# External verification of curated facts.
#
# `validate_gifter_sources()` proves that the source tables are coherent with
# each other. It cannot prove that an accession exists, that a Rhea identifier
# is a master, or that a declared anchor takes part in the chemistry of its
# route: those are statements about Rhea, ChEBI and KEGG, and a plausible but
# wrong value satisfies every relational check. The functions below compare the
# source tables with a pinned extract of those resources, so that such a value
# fails the build instead of being read as curated.
#
# The extract is written by `data-raw/reference_snapshot.R` and never by hand.
# It covers Rhea and ChEBI in the detail the checks need, and KEGG only as a
# list of accessions confirmed current: KEGG redistribution is under review (see
# inst/doc/licensing-review.md), so no KEGG definition or link is shipped.

# How a marker-to-component assignment is supported. The first three values are
# derived from external records and never typed; `reference` means nothing was
# derivable and the row cites a publication or a result table instead;
# `unsupported` means the row was assessed and rests on the curator's assertion
# alone; `not_assessed` means no derivation exists yet for that namespace or
# GIFT type, which is a statement about the check and not about the marker.
.gifter_evidence_bases <- c(
  "kegg_reaction_link", "ec_match", "kegg_module_member",
  "reference", "unsupported", "not_assessed"
)

.gifter_evidence_types <- c(
  "orthology", "sequence_family", "sequence_subfamily", "activity"
)

# The strongest confidence a row may claim when its basis is `unsupported`.
.gifter_unsupported_confidence_ceiling <- "putative"

# What a `reference` token may be: a PubMed identifier, a DOI, or a result table
# or analysis script inside the repository. A curation document is deliberately
# not accepted. It records the reasoning for an assignment, so citing it as the
# evidence for the same assignment would let a claim support itself.
.gifter_reference_token <- paste0(
  "^(PMID:[0-9]+|DOI:10\\.[0-9]{4,9}/[^[:space:];]+|",
  "data-raw/[A-Za-z0-9_./-]+\\.(tsv|csv|txt|R|py))$"
)

# Why a route's Rhea chemistry may differ from its declared boundary or fail to
# chain. Each is a claim the snapshot cannot check, which is why it is recorded
# instead of being left implicit in the choice of reactions.
.gifter_route_exception_kinds <- c(
  # The anchor's ChEBI entity is not the entity Rhea writes in this route: an
  # anomer, a tautomer, a stereo-unspecified parent, or the other member of a
  # redox couple.
  "anchor_form",
  # Two reactions name different ChEBI entities for one compound.
  "form_change",
  # The connecting conversion is non-enzymatic.
  "spontaneous_step",
  # A conversion is deliberately left out of the route.
  "omitted_step",
  # The route converts separate inputs that meet only at or beyond its boundary.
  "parallel_branch"
)

# Which kinds may excuse a boundary anchor and which a break between steps.
.gifter_anchor_exception_kinds <- c("anchor_form", "spontaneous_step", "omitted_step")
.gifter_break_exception_kinds <- c(
  "form_change", "spontaneous_step", "omitted_step", "parallel_branch"
)

# Compounds that take part in so many reactions that sharing one says nothing
# about whether two steps follow each other. They are ignored when a route is
# tested for being one connected chain, and nowhere else.
.gifter_hub_chebi <- c(
  "CHEBI:15377", # H2O
  "CHEBI:15378", # H(+)
  "CHEBI:15379", # O2
  "CHEBI:16526", # CO2
  "CHEBI:28938", # NH4(+)
  "CHEBI:43474", # phosphate
  "CHEBI:33019", # diphosphate
  "CHEBI:30616", # ATP
  "CHEBI:456216", # ADP
  "CHEBI:456215", # AMP
  "CHEBI:57540", # NAD(+)
  "CHEBI:57945", # NADH
  "CHEBI:58349", # NADP(+)
  "CHEBI:57783", # NADPH
  "CHEBI:57287"  # CoA
)

.gifter_reference_files <- list(
  manifest = c("resource", "release", "retrieved", "licence"),
  rhea_reactions = c("rhea_id", "status", "master_id", "equation"),
  rhea_participants = c("master_id", "side", "chebi_id"),
  rhea_xrefs = c("master_id", "namespace", "accession"),
  chebi_compounds = c("chebi_id", "status", "name", "rhea_form"),
  kegg_accessions = c("namespace", "accession", "status"),
  marker_accessions = c("namespace", "accession", "status", "family_type")
)

.read_reference_table <- function(path) {
  utils::read.delim(
    path, header = TRUE, sep = "\t", quote = "", comment.char = "",
    na.strings = "", colClasses = "character", check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

.read_reference_snapshot <- function(reference_dir) {
  if (!dir.exists(reference_dir)) {
    stop("Reference snapshot directory does not exist: ", reference_dir, call. = FALSE)
  }
  snapshot <- list()
  for (name in names(.gifter_reference_files)) {
    file <- if (identical(name, "manifest")) "MANIFEST.tsv" else {
      paste0(gsub("_", "-", name, fixed = TRUE), ".tsv")
    }
    path <- file.path(reference_dir, file)
    if (!file.exists(path)) {
      stop("Reference snapshot is missing ", file, call. = FALSE)
    }
    table <- .read_reference_table(path)
    missing <- setdiff(.gifter_reference_files[[name]], names(table))
    if (length(missing)) {
      stop(
        "Reference snapshot ", file, " is missing columns: ",
        paste(missing, collapse = ", "), call. = FALSE
      )
    }
    snapshot[[name]] <- table
  }
  snapshot
}

# What an external resource attaches to each marker gifter references: for a
# KO, the reactions, EC numbers and modules KEGG assigns it; for an NCBIfam
# profile, the EC numbers of its release metadata; for a CAZy family or dbCAN
# subfamily, the EC numbers of its characterised members. The KEGG extract is
# read from the ignored cache because KEGG content is not redistributed; the
# others are derived from tables committed under data-raw/reference.
.read_marker_links <- function(paths) {
  links <- lapply(paths, function(path) {
    table <- .read_reference_table(path)
    missing <- setdiff(c("namespace", "accession", "kind", "value"), names(table))
    if (length(missing)) {
      stop("Marker link extract ", basename(path), " is missing columns: ",
           paste(missing, collapse = ", "), call. = FALSE)
    }
    table[c("namespace", "accession", "kind", "value")]
  })
  if (!length(links)) {
    return(data.frame(
      namespace = character(), accession = character(), kind = character(),
      value = character(), stringsAsFactors = FALSE
    ))
  }
  do.call(rbind, links)
}

# The namespaces for which a marker on an enzyme component has a derivation.
.gifter_derivable_namespaces <- c("KO", "NCBIFAM", "CAZY")

.empty_text <- function(x) is.na(x) | !nzchar(trimws(x))

.split_reference <- function(x) {
  x[is.na(x)] <- ""
  lapply(strsplit(x, ";", fixed = TRUE), function(tokens) {
    tokens <- trimws(tokens)
    tokens[nzchar(tokens)]
  })
}

.evidence_sources <- function() {
  c("component_markers",
    vapply(.gifter_machinery_models, function(model) model$evidence_source, character(1)))
}

# Checks that need nothing but the source tables: closed vocabularies, the shape
# of a reference, and the rule that ties confidence to basis. They run on every
# validation, including the synthetic fixtures the tests build.
.validate_evidence_contract <- function(tables) {
  errors <- character()
  for (source in .evidence_sources()) {
    rows <- tables[[source]]
    if (!nrow(rows)) next
    key <- paste0(rows$component_id, " ", rows$namespace, ":", rows$accession)

    for (check in list(
      list("confidence", .gifter_confidence_order),
      list("evidence_type", .gifter_evidence_types)
    )) {
      invalid <- setdiff(unique(rows[[check[[1]]]]), check[[2]])
      if (length(invalid)) {
        errors <- c(errors, paste0(
          "Invalid ", source, ".", check[[1]], ": ",
          paste(sort(invalid, na.last = TRUE), collapse = ", ")
        ))
      }
    }
    invalid <- setdiff(unique(rows$basis[!is.na(rows$basis)]), .gifter_evidence_bases)
    if (length(invalid)) {
      errors <- c(errors, paste0(
        "Invalid ", source, ".basis: ", paste(sort(invalid), collapse = ", ")
      ))
    }

    tokens <- .split_reference(rows$reference)
    malformed <- vapply(
      tokens, function(x) any(!grepl(.gifter_reference_token, x)), logical(1)
    )
    if (any(malformed)) {
      errors <- c(errors, paste0(
        source, ".reference must list PMID:<id>, DOI:<doi> or a data-raw result ",
        "table or script, separated by semicolons: ",
        paste(key[malformed], collapse = ", ")
      ))
    }
    uncited <- !is.na(rows$basis) & rows$basis == "reference" & !lengths(tokens)
    if (any(uncited)) {
      errors <- c(errors, paste0(
        source, " rows with basis = reference must record one: ",
        paste(key[uncited], collapse = ", ")
      ))
    }
    ceiling <- match(.gifter_unsupported_confidence_ceiling, .gifter_confidence_order)
    overclaimed <- !is.na(rows$basis) & rows$basis == "unsupported" &
      match(rows$confidence, .gifter_confidence_order) > ceiling
    overclaimed[is.na(overclaimed)] <- FALSE
    if (any(overclaimed)) {
      errors <- c(errors, paste0(
        source, " rows with basis = unsupported may not claim more than ",
        .gifter_unsupported_confidence_ceiling, " confidence: ",
        paste(key[overclaimed], collapse = ", ")
      ))
    }
  }

  exceptions <- tables$route_chemistry_exceptions
  if (nrow(exceptions)) {
    missing <- .missing_refs(exceptions$route_id, tables$gift_routes$route_id)
    if (length(missing)) {
      errors <- c(errors, paste0(
        "Invalid route_chemistry_exceptions.route_id: ", paste(missing, collapse = ", ")
      ))
    }
    invalid <- setdiff(unique(exceptions$kind), .gifter_route_exception_kinds)
    if (length(invalid)) {
      errors <- c(errors, paste0(
        "Invalid route_chemistry_exceptions.kind: ", paste(invalid, collapse = ", ")
      ))
    }
    if (length(.duplicate_keys(exceptions, c("route_id", "subject")))) {
      errors <- c(errors, "route_chemistry_exceptions contains duplicate route/subject pairs")
    }
    unexplained <- .empty_text(exceptions$subject) | .empty_text(exceptions$rationale)
    if (any(unexplained)) {
      errors <- c(errors, paste0(
        "route_chemistry_exceptions needs a subject and a rationale for: ",
        paste(unique(exceptions$route_id[unexplained]), collapse = ", ")
      ))
    }
  }

  reviews <- tables$gift_reviews
  if (nrow(reviews)) {
    missing <- .missing_refs(reviews$gift_id, tables$gifts$gift_id)
    if (length(missing)) {
      errors <- c(errors, paste0(
        "Invalid gift_reviews.gift_id: ", paste(missing, collapse = ", ")
      ))
    }
    if (length(.duplicate_keys(reviews, c("gift_id", "version", "reviewer")))) {
      errors <- c(errors, "gift_reviews contains duplicate gift/version/reviewer rows")
    }
    current <- suppressWarnings(as.integer(
      tables$gifts$version[match(reviews$gift_id, tables$gifts$gift_id)]
    ))
    reviewed <- suppressWarnings(as.integer(reviews$version))
    invalid <- is.na(reviewed) | reviewed < 1L | (!is.na(current) & reviewed > current)
    if (any(invalid)) {
      errors <- c(errors, paste0(
        "gift_reviews.version must be a version the GIFT has reached: ",
        paste(unique(reviews$gift_id[invalid]), collapse = ", ")
      ))
    }
    unsigned <- .empty_text(reviews$reviewer) |
      !grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", ifelse(is.na(reviews$reviewed_at), "", reviews$reviewed_at))
    if (any(unsigned)) {
      errors <- c(errors, paste0(
        "gift_reviews needs a reviewer and a YYYY-MM-DD reviewed_at for: ",
        paste(unique(reviews$gift_id[unsigned]), collapse = ", ")
      ))
    }
  }
  errors
}

# The side of each step a route consumes and the side it produces, read from the
# Rhea master equation and the step's orientation. `covered` is FALSE when any
# step has no Rhea participants, in which case the route's chemistry is only
# partly checkable.
.route_chemistry <- function(steps, participants) {
  steps <- steps[order(as.integer(steps$step_order)), , drop = FALSE]
  consumed <- produced <- vector("list", nrow(steps))
  covered <- TRUE
  for (i in seq_len(nrow(steps))) {
    rows <- participants[participants$master_id == steps$reaction_id[[i]], , drop = FALSE]
    if (!nrow(rows)) {
      covered <- FALSE
      consumed[[i]] <- produced[[i]] <- character()
      next
    }
    left <- rows$chebi_id[rows$side == "L"]
    right <- rows$chebi_id[rows$side == "R"]
    if (identical(steps$orientation[[i]], "reverse")) {
      consumed[[i]] <- right
      produced[[i]] <- left
    } else {
      consumed[[i]] <- left
      produced[[i]] <- right
    }
  }
  list(steps = steps, consumed = consumed, produced = produced, covered = covered)
}

# The reactions that begin a part of the route not linked to its first step. Two
# steps are linked when one produces a compound the other consumes, hubs aside.
# Sharing a compound on the same side is not a link: two methyltransferases both
# consume S-adenosyl-L-methionine without either feeding the other. An empty
# result means the route is one chain.
.route_breaks <- function(chemistry) {
  n <- nrow(chemistry$steps)
  if (n < 2L || !chemistry$covered) return(character())
  consumed <- lapply(chemistry$consumed, setdiff, .gifter_hub_chebi)
  produced <- lapply(chemistry$produced, setdiff, .gifter_hub_chebi)
  linked <- function(i, j) {
    length(intersect(produced[[i]], consumed[[j]])) > 0L ||
      length(intersect(produced[[j]], consumed[[i]])) > 0L
  }
  component <- integer(n)
  breaks <- character()
  for (start in seq_len(n)) {
    if (component[[start]]) next
    component[[start]] <- start
    queue <- start
    while (length(queue)) {
      current <- queue[[1]]
      queue <- queue[-1]
      for (other in which(!component)) {
        if (linked(current, other)) {
          component[[other]] <- start
          queue <- c(queue, other)
        }
      }
    }
    if (start > 1L) breaks <- c(breaks, chemistry$steps$reaction_id[[start]])
  }
  breaks
}

# Derive how each marker assignment is supported. A marker on an enzyme
# component has a derivation when its namespace states, independently of gifter,
# what the marker does: KEGG says which reactions, EC numbers and modules an
# orthologue belongs to, NCBIfam and dbCAN say which EC numbers a profile or a
# subfamily carries, and Rhea says which EC numbers and KEGG reactions a master
# reaction corresponds to. Agreement between the two sides is evidence that does
# not depend on who curated the row.
#
# A derivable namespace for which `links` holds nothing returns NA: the
# derivation exists but its input was not supplied, which is different from a
# marker that was assessed and found unsupported.
.derive_marker_basis <- function(tables, reference, links) {
  cited <- function(rows) {
    ifelse(lengths(.split_reference(rows$reference)) > 0L, "reference", "not_assessed")
  }
  result <- list()
  for (source in setdiff(.evidence_sources(), "component_markers")) {
    result[[source]] <- cited(tables[[source]])
  }

  rows <- tables$component_markers
  basis <- cited(rows)
  system_id <- tables$enzyme_components$system_id[
    match(rows$component_id, tables$enzyme_components$component_id)
  ]
  reaction_id <- tables$enzyme_systems$reaction_id[
    match(system_id, tables$enzyme_systems$system_id)
  ]

  xrefs <- rbind(
    data.frame(
      reaction_id = reference$rhea_xrefs$master_id,
      namespace = reference$rhea_xrefs$namespace,
      accession = reference$rhea_xrefs$accession,
      stringsAsFactors = FALSE
    ),
    tables$reaction_xrefs[c("reaction_id", "namespace", "accession")]
  )
  routes_of_reaction <- split(tables$route_reactions$route_id, tables$route_reactions$reaction_id)
  gift_of_route <- stats::setNames(tables$gift_routes$gift_id, tables$gift_routes$route_id)
  modules <- tables$gift_xrefs[tables$gift_xrefs$namespace == "KEGG_MODULE", , drop = FALSE]
  covered <- intersect(.gifter_derivable_namespaces, unique(links$namespace))
  own_links <- split(
    links[c("kind", "value")], paste(links$namespace, links$accession, sep = "\r")
  )

  derivable <- rows$namespace %in% .gifter_derivable_namespaces
  basis[derivable & !rows$namespace %in% covered] <- NA_character_
  for (i in which(rows$namespace %in% covered)) {
    own <- own_links[[paste(rows$namespace[[i]], rows$accession[[i]], sep = "\r")]]
    reaction <- reaction_id[[i]]
    target <- xrefs[xrefs$reaction_id == reaction, , drop = FALSE]
    gifts <- unique(unname(gift_of_route[routes_of_reaction[[reaction]]]))
    supported <- if (is.null(own)) character() else c(
      if (any(own$value[own$kind == "reaction"] %in%
              target$accession[target$namespace == "KEGG_REACTION"])) "kegg_reaction_link",
      if (any(own$value[own$kind == "ec"] %in%
              target$accession[target$namespace == "EC"])) "ec_match",
      if (any(own$value[own$kind == "module"] %in%
              modules$accession[modules$gift_id %in% gifts])) "kegg_module_member"
    )
    basis[[i]] <- if (length(supported)) {
      supported[[1]]
    } else if (identical(basis[[i]], "reference")) {
      "reference"
    } else {
      "unsupported"
    }
  }
  result$component_markers <- basis
  result
}

# Compare the source tables with the pinned snapshot. Returns errors and
# warnings in the same form as the structural validator.
.verify_external_references <- function(tables, reference, links = .read_marker_links(character())) {
  errors <- character()
  warnings <- character()
  stale <- "; regenerate the snapshot with data-raw/reference_snapshot.R"

  # ---- Rhea identity and equations ----------------------------------------
  reactions <- tables$reactions
  rhea <- reference$rhea_reactions
  recorded <- reactions[!is.na(reactions$rhea_master), , drop = FALSE]
  mismatched <- recorded$reaction_id[recorded$reaction_id != recorded$rhea_master]
  if (length(mismatched)) {
    errors <- c(errors, paste0(
      "A reaction with a Rhea master must use it as its reaction_id: ",
      paste(mismatched, collapse = ", ")
    ))
  }
  unlabelled <- reactions$reaction_id[
    is.na(reactions$rhea_master) & grepl("^RHEA:", reactions$reaction_id)
  ]
  if (length(unlabelled)) {
    errors <- c(errors, paste0(
      "A RHEA reaction_id must be recorded as its rhea_master: ",
      paste(unlabelled, collapse = ", ")
    ))
  }
  status <- rhea$status[match(recorded$rhea_master, rhea$rhea_id)]
  unknown <- recorded$rhea_master[is.na(status)]
  if (length(unknown)) {
    errors <- c(errors, paste0(
      "Rhea identifiers absent from the pinned snapshot: ",
      paste(unknown, collapse = ", "), stale
    ))
  }
  not_master <- !is.na(status) & status != "master"
  if (any(not_master)) {
    master <- rhea$master_id[match(recorded$rhea_master[not_master], rhea$rhea_id)]
    errors <- c(errors, paste0(
      "Not a Rhea master identifier: ",
      paste0(recorded$rhea_master[not_master], " (", status[not_master],
             ifelse(is.na(master), "", paste0(", master ", master)), ")", collapse = ", ")
    ))
  }
  expected <- rhea$equation[match(reactions$rhea_master, rhea$rhea_id)]
  drifted <- !is.na(reactions$rhea_master) & !is.na(expected) &
    (is.na(reactions$equation) | reactions$equation != expected)
  if (any(drifted)) {
    errors <- c(errors, paste0(
      "reactions.equation must be the Rhea master equation, imported and not typed: ",
      paste(reactions$reaction_id[drifted], collapse = ", ")
    ))
  }
  invented <- is.na(reactions$rhea_master) & !is.na(reactions$equation)
  if (any(invented)) {
    errors <- c(errors, paste0(
      "reactions.equation is imported from Rhea and must be empty without a Rhea master: ",
      paste(reactions$reaction_id[invented], collapse = ", ")
    ))
  }

  # ---- reaction cross-references ------------------------------------------
  xrefs <- tables$reaction_xrefs
  checked <- xrefs$namespace %in% c("EC", "KEGG_REACTION") &
    xrefs$reaction_id %in% recorded$rhea_master
  in_rhea <- paste(xrefs$reaction_id, xrefs$namespace, xrefs$accession, sep = "\r") %in%
    paste(reference$rhea_xrefs$master_id, reference$rhea_xrefs$namespace,
          reference$rhea_xrefs$accession, sep = "\r")
  unexplained <- checked & !in_rhea & .empty_text(xrefs$notes)
  if (any(unexplained)) {
    errors <- c(errors, paste0(
      "Cross-references that Rhea does not record for the reaction need a note ",
      "stating why they are kept: ",
      paste0(xrefs$reaction_id[unexplained], " ", xrefs$namespace[unexplained], ":",
             xrefs$accession[unexplained], collapse = ", ")
    ))
  }

  # ---- KEGG accessions ----------------------------------------------------
  kegg <- reference$kegg_accessions
  current <- paste(kegg$namespace, kegg$accession, sep = "\r")[kegg$status == "current"]
  cited <- unique(rbind(
    data.frame(namespace = "KO",
               accession = tables$markers$accession[tables$markers$namespace == "KO"],
               stringsAsFactors = FALSE),
    xrefs[xrefs$namespace == "KEGG_REACTION", c("namespace", "accession")],
    tables$gift_xrefs[tables$gift_xrefs$namespace %in% c("KEGG_MODULE", "KEGG_PATHWAY"),
                      c("namespace", "accession")]
  ))
  absent <- !paste(cited$namespace, cited$accession, sep = "\r") %in% current
  if (any(absent)) {
    errors <- c(errors, paste0(
      "KEGG accessions not confirmed current by the pinned snapshot: ",
      paste0(cited$namespace[absent], ":", cited$accession[absent], collapse = ", "), stale
    ))
  }

  # ---- family and profile accessions ---------------------------------------
  #
  # An NCBIfam accession names one version of one profile, and its grade is a
  # property of that release, not a judgement of the curator. The grade a row
  # declares in its notes must therefore be the grade the pinned release gives.
  pinned <- reference$marker_accessions
  pinned_key <- paste(pinned$namespace, pinned$accession, sep = "\r")
  families <- tables$markers[
    tables$markers$namespace %in% unique(pinned$namespace), , drop = FALSE
  ]
  absent <- !paste(families$namespace, families$accession, sep = "\r") %in%
    pinned_key[pinned$status == "current"]
  if (any(absent)) {
    errors <- c(errors, paste0(
      "Family or profile accessions absent from the pinned release: ",
      paste0(families$namespace[absent], ":", families$accession[absent], collapse = ", "),
      stale
    ))
  }
  for (source in .evidence_sources()) {
    rows <- tables[[source]]
    rows <- rows[rows$namespace %in% "NCBIFAM", , drop = FALSE]
    if (!nrow(rows)) next
    released <- pinned$family_type[match(paste("NCBIFAM", rows$accession, sep = "\r"), pinned_key)]
    declared_grade <- .ncbifam_declared_grade(rows$notes)
    wrong <- !is.na(released) & !is.na(declared_grade) & released != declared_grade
    if (any(wrong)) {
      errors <- c(errors, paste0(
        source, " declares an NCBIfam grade the pinned release does not give: ",
        paste0(rows$accession[wrong], " is ", released[wrong], ", not ",
               declared_grade[wrong], collapse = ", ")
      ))
    }
  }

  # ---- anchor identity ----------------------------------------------------
  anchors <- tables$anchors[!is.na(tables$anchors$chebi_id), , drop = FALSE]
  compound <- reference$chebi_compounds[
    match(anchors$chebi_id, reference$chebi_compounds$chebi_id), , drop = FALSE
  ]
  unknown <- is.na(compound$status) | compound$status != "current"
  if (any(unknown)) {
    errors <- c(errors, paste0(
      "ChEBI identifiers not confirmed current by the pinned snapshot: ",
      paste0(anchors$anchor_id[unknown], " ", anchors$chebi_id[unknown], collapse = ", "),
      stale
    ))
  }
  other_form <- !unknown & !is.na(compound$rhea_form) & compound$rhea_form != anchors$chebi_id
  if (any(other_form)) {
    errors <- c(errors, paste0(
      "Anchors must use the ChEBI form Rhea writes at pH 7.3: ",
      paste0(anchors$anchor_id[other_form], " ", anchors$chebi_id[other_form],
             " -> ", compound$rhea_form[other_form], collapse = ", ")
    ))
  }
  renamed <- !unknown & (is.na(anchors$chebi_name) | anchors$chebi_name != compound$name)
  if (any(renamed)) {
    errors <- c(errors, paste0(
      "anchors.chebi_name must be the ChEBI name, imported and not typed: ",
      paste(anchors$anchor_id[renamed], collapse = ", ")
    ))
  }
  nameless <- is.na(tables$anchors$chebi_id) & !is.na(tables$anchors$chebi_name)
  if (any(nameless)) {
    errors <- c(errors, paste0(
      "anchors.chebi_name is imported from ChEBI and must be empty without a chebi_id: ",
      paste(tables$anchors$anchor_id[nameless], collapse = ", ")
    ))
  }

  # ---- route chemistry ----------------------------------------------------
  #
  # A declared anchor is a claim about where a route begins and ends. For a
  # route written entirely in Rhea reactions that claim is checkable: an input
  # must be consumed by one of the steps and an output produced by one, read on
  # the side of the equation the step's orientation selects. An interconversion
  # GIFT declares every anchor in both roles and is run in either direction, so
  # either side satisfies it.
  exceptions <- tables$route_chemistry_exceptions
  declared <- paste(exceptions$route_id, exceptions$subject, sep = "\r")
  required <- character()
  chebi_of <- stats::setNames(tables$anchors$chebi_id, tables$anchors$anchor_id)
  mode_of <- stats::setNames(tables$gifts$mode, tables$gifts$gift_id)
  steps_by_route <- split(tables$route_reactions, tables$route_reactions$route_id)
  for (i in seq_len(nrow(tables$gift_routes))) {
    route_id <- tables$gift_routes$route_id[[i]]
    gift_id <- tables$gift_routes$gift_id[[i]]
    steps <- steps_by_route[[route_id]]
    if (is.null(steps)) next
    chemistry <- .route_chemistry(steps, reference$rhea_participants)
    consumed <- unlist(chemistry$consumed)
    produced <- unlist(chemistry$produced)
    either <- identical(unname(mode_of[[gift_id]]), "interconversion")

    boundary <- tables$gift_anchors[tables$gift_anchors$gift_id == gift_id, , drop = FALSE]
    for (j in seq_len(nrow(boundary))) {
      chebi <- unname(chebi_of[[boundary$anchor_id[[j]]]])
      if (is.na(chebi)) next
      side <- if (either) c(consumed, produced) else if (boundary$role[[j]] == "input") consumed else produced
      if (chebi %in% side) next
      # Part of the route has no Rhea participants, so the anchor may belong to
      # chemistry the snapshot cannot see.
      if (!chemistry$covered && !chebi %in% c(consumed, produced)) next
      key <- paste(route_id, boundary$anchor_id[[j]], sep = "\r")
      required <- c(required, key)
      if (!key %in% declared[exceptions$kind %in% .gifter_anchor_exception_kinds]) {
        errors <- c(errors, paste0(
          route_id, ": ", boundary$role[[j]], " anchor ", boundary$anchor_id[[j]],
          " (", chebi, ") is not ",
          if (boundary$role[[j]] == "input") "consumed" else "produced",
          " by any step of the route as oriented"
        ))
      }
    }

    for (reaction_id in .route_breaks(chemistry)) {
      key <- paste(route_id, reaction_id, sep = "\r")
      required <- c(required, key)
      if (!key %in% declared[exceptions$kind %in% .gifter_break_exception_kinds]) {
        errors <- c(errors, paste0(
          route_id, ": ", reaction_id,
          " is not linked to the first step by any compound one step produces ",
          "and another consumes, so the route is not one chain"
        ))
      }
    }
  }
  unused <- !declared %in% required
  if (any(unused)) {
    errors <- c(errors, paste0(
      "route_chemistry_exceptions rows that excuse nothing: ",
      paste0(exceptions$route_id[unused], " ", exceptions$subject[unused], collapse = ", ")
    ))
  }

  # ---- evidence basis -----------------------------------------------------
  for (source in .evidence_sources()) {
    rows <- tables[[source]]
    undeclared <- is.na(rows$basis)
    if (any(undeclared)) {
      errors <- c(errors, paste0(
        source, ".basis must be recorded for every row; missing for ",
        sum(undeclared), " rows, first ",
        rows$component_id[undeclared][[1]], " ", rows$accession[undeclared][[1]]
      ))
    }
  }
  derived <- .derive_marker_basis(tables, reference, links)
  for (source in names(derived)) {
    rows <- tables[[source]]
    wrong <- !is.na(rows$basis) & !is.na(derived[[source]]) & rows$basis != derived[[source]]
    if (any(wrong)) {
      errors <- c(errors, paste0(
        source, ".basis is derived and must not be typed: ",
        paste0(rows$component_id[wrong], " ", rows$accession[wrong], " is ",
               derived[[source]][wrong], collapse = ", ")
      ))
    }
  }
  unchecked <- setdiff(.gifter_derivable_namespaces, unique(links$namespace))
  if (length(unchecked)) {
    warnings <- c(warnings, paste0(
      "Evidence basis was not recomputed for ", paste(unchecked, collapse = ", "),
      ": no link extract for that namespace was supplied"
    ))
  }

  # ---- pinned releases ----------------------------------------------------
  manifest <- reference$manifest
  release <- tables$database_release
  for (pin in list(c("Rhea", "rhea_release"), c("ChEBI", "chebi_release"))) {
    pinned <- unique(manifest$release[manifest$resource == pin[[1]]])
    if (nrow(release) == 1L && length(pinned) == 1L &&
        !identical(release[[pin[[2]]]][[1]], pinned)) {
      errors <- c(errors, paste0(
        "database_release.", pin[[2]], " is ", release[[pin[[2]]]][[1]],
        " but the snapshot pins ", pin[[1]], " release ", pinned
      ))
    }
  }

  list(errors = errors, warnings = warnings)
}
