# Shared input contract for prospective biological validation.
#
# This is deliberately an analysis-side registry, not a package API or a
# database table.  It records a study's external observations and uses gifter
# only to evaluate the separately supplied annotation for the pinned database.

.prospective_relations <- c(
  "equivalent", "subset_of", "superset_of", "overlaps", "related", "refused", "voids"
)

.prospective_priorities <- c("specificity", "mag_robustness", "machinery", "auxotrophy")

.prospective_required <- function(x, columns, label) {
  missing <- setdiff(columns, names(x))
  if (length(missing)) {
    stop(label, " is missing columns: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  invisible(x)
}

.prospective_read_tsv <- function(path, columns, label) {
  if (!file.exists(path)) stop(label, " does not exist: ", path, call. = FALSE)
  x <- utils::read.delim(path, stringsAsFactors = FALSE, na.strings = "", check.names = FALSE)
  .prospective_required(x, columns, label)
  if (!nrow(x)) stop(label, " has no rows", call. = FALSE)
  x
}

.prospective_nonempty <- function(x, columns, label) {
  for (column in columns) {
    bad <- is.na(x[[column]]) | !nzchar(trimws(as.character(x[[column]])))
    if (any(bad)) {
      stop(label, " has blank ", column, " in row(s): ",
           paste(which(bad), collapse = ", "), call. = FALSE)
    }
  }
  invisible(x)
}

.prospective_unique <- function(x, columns, label) {
  key <- do.call(paste, c(x[columns], sep = "\r"))
  duplicate <- which(duplicated(key))
  if (length(duplicate)) {
    stop(label, " has duplicate ", paste(columns, collapse = "+"), " at row(s): ",
         paste(duplicate, collapse = ", "), call. = FALSE)
  }
  invisible(x)
}

.prospective_utc <- function(x, label) {
  x <- as.character(x)
  valid <- grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}(:[0-9]{2})?Z$", x)
  if (any(!valid)) {
    stop(label, " must use UTC ISO-8601 timestamps such as 2026-10-01T12:00Z", call. = FALSE)
  }
  format <- ifelse(nchar(x) == 17L, "%Y-%m-%dT%H:%MZ", "%Y-%m-%dT%H:%M:%SZ")
  out <- as.POSIXct(rep(NA_character_, length(x)), tz = "UTC")
  for (f in unique(format)) {
    hit <- format == f
    out[hit] <- as.POSIXct(x[hit], format = f, tz = "UTC")
  }
  if (any(is.na(out))) stop(label, " contains an invalid timestamp", call. = FALSE)
  out
}

.prospective_known_target <- function(layer, target_id, db) {
  if (layer == "gift") return(nrow(get_gift(target_id, db = db)) == 1L)
  nrow(get_reaction(target_id, db = db)) == 1L
}

#' Read and validate a locked prospective-validation study
#'
#' The reader enforces the protocol elements that prevent an external
#' observation from becoming an untraceable phenotype score: exact targets,
#' accessioned assemblies, pinned annotation and database versions, an explicit
#' observation/claim relation, biological replicates and assay conditions.  It
#' intentionally does not calculate accuracy, F1, AUC or a catalogue-wide
#' score.
#'
#' @param studies_path Path to `studies.tsv`.
#' @param samples_path Path to `samples.tsv`.
#' @param annotations_path Path to `annotations.tsv`.
#' @param observations_path Path to `observations.tsv`.
#' @param db Optional gifter database connection.
#' @return Validated registry inputs and the pinned database metadata.
prospective_read_inputs <- function(studies_path, samples_path, annotations_path,
                                    observations_path, db = NULL) {
  studies <- .prospective_read_tsv(
    studies_path,
    c("study_id", "status", "priority", "target_layer", "target_id", "claim",
      "assay_endpoint", "crosswalk_relation", "selection_rule", "exclusion_rule",
      "annotation_pipeline", "annotation_version", "database_version", "locked_at_utc"),
    "studies"
  )
  samples <- .prospective_read_tsv(
    samples_path,
    c("sample_id", "study_id", "strain_id", "assembly_accession", "lineage",
      "genome_role", "paired_sample_id", "marker_evidence_class",
      "marker_evidence_method", "marker_evidence_reference"),
    "samples"
  )
  annotations <- .prospective_read_tsv(
    annotations_path, c("sample_id", "gene_id", "namespace", "accession"), "annotations"
  )
  observations <- .prospective_read_tsv(
    observations_path,
    c("observation_id", "sample_id", "biological_replicate", "assayed_at_utc",
      "observed", "assay_conditions", "assay_reference", "baseline_medium",
      "omitted_nutrient", "rescue_observed"),
    "observations"
  )

  .prospective_nonempty(
    studies,
    c("study_id", "status", "priority", "target_layer", "target_id", "claim",
      "assay_endpoint", "crosswalk_relation", "selection_rule", "exclusion_rule",
      "annotation_pipeline", "annotation_version", "database_version", "locked_at_utc"),
    "studies"
  )
  .prospective_nonempty(
    samples,
    c("sample_id", "study_id", "strain_id", "assembly_accession", "lineage",
      "genome_role", "marker_evidence_class", "marker_evidence_method",
      "marker_evidence_reference"),
    "samples"
  )
  .prospective_nonempty(annotations, c("sample_id", "gene_id", "namespace", "accession"),
                         "annotations")
  .prospective_nonempty(
    observations,
    c("observation_id", "sample_id", "biological_replicate", "assayed_at_utc",
      "observed", "assay_conditions", "assay_reference", "baseline_medium",
      "omitted_nutrient", "rescue_observed"),
    "observations"
  )
  .prospective_unique(studies, "study_id", "studies")
  .prospective_unique(samples, "sample_id", "samples")
  .prospective_unique(annotations, c("sample_id", "gene_id", "namespace", "accession"),
                       "annotations")
  .prospective_unique(observations, "observation_id", "observations")

  bad <- setdiff(studies$status, c("locked", "complete", "planned"))
  if (length(bad)) stop("studies has unknown status: ", paste(unique(bad), collapse = ", "), call. = FALSE)
  if (any(studies$status == "planned")) {
    stop("Refusing to score planned study rows. Lock the protocol before adding observations.", call. = FALSE)
  }
  bad <- setdiff(studies$priority, .prospective_priorities)
  if (length(bad)) stop("studies has unknown priority: ", paste(unique(bad), collapse = ", "), call. = FALSE)
  bad <- setdiff(studies$target_layer, c("gift", "reaction"))
  if (length(bad)) stop("studies has unknown target_layer: ", paste(unique(bad), collapse = ", "), call. = FALSE)
  bad <- setdiff(studies$crosswalk_relation, .prospective_relations)
  if (length(bad)) stop("studies has unknown crosswalk_relation: ", paste(unique(bad), collapse = ", "), call. = FALSE)
  lock_time <- .prospective_utc(studies$locked_at_utc, "locked_at_utc")

  actual_version <- as.character(gifter_db_version(db = db)$gifter_db_version[[1L]])
  if (!all(studies$database_version == actual_version)) {
    wrong <- unique(studies$database_version[studies$database_version != actual_version])
    stop("studies pins database version ", paste(wrong, collapse = ", "),
         " but the open database is ", actual_version,
         ". Reopen the pinned database rather than mixing results across releases.", call. = FALSE)
  }
  unknown <- !mapply(.prospective_known_target, studies$target_layer, studies$target_id,
                     MoreArgs = list(db = db))
  if (any(unknown)) {
    stop("studies names unknown target(s): ", paste(studies$target_id[unknown], collapse = ", "),
         call. = FALSE)
  }

  unknown <- setdiff(samples$study_id, studies$study_id)
  if (length(unknown)) stop("samples names unknown study_id(s): ", paste(unique(unknown), collapse = ", "), call. = FALSE)
  unknown <- setdiff(annotations$sample_id, samples$sample_id)
  if (length(unknown)) stop("annotations names unknown sample_id(s): ", paste(unique(unknown), collapse = ", "), call. = FALSE)
  unknown <- setdiff(observations$sample_id, samples$sample_id)
  if (length(unknown)) stop("observations names unknown sample_id(s): ", paste(unique(unknown), collapse = ", "), call. = FALSE)
  missing_annotation <- setdiff(samples$sample_id, annotations$sample_id)
  if (length(missing_annotation)) {
    stop("samples have no deposited annotation rows: ", paste(missing_annotation, collapse = ", "), call. = FALSE)
  }
  missing_observation <- setdiff(samples$sample_id, observations$sample_id)
  if (length(missing_observation)) {
    stop("samples have no assay observations: ", paste(missing_observation, collapse = ", "), call. = FALSE)
  }

  bad <- setdiff(samples$genome_role, c("isolate", "mag_like_draft", "mag", "contaminated_bin"))
  if (length(bad)) stop("samples has unknown genome_role: ", paste(unique(bad), collapse = ", "), call. = FALSE)
  bad <- setdiff(samples$marker_evidence_class,
                 c("specific_evidence", "broad_marker_only", "no_relevant_marker", "not_applicable"))
  if (length(bad)) stop("samples has unknown marker_evidence_class: ",
                        paste(unique(bad), collapse = ", "), call. = FALSE)
  bad <- setdiff(observations$observed, c("positive", "negative", "indeterminate"))
  if (length(bad)) stop("observations has unknown observed value: ", paste(unique(bad), collapse = ", "), call. = FALSE)
  bad <- setdiff(observations$rescue_observed, c("positive", "negative", "not_applicable"))
  if (length(bad)) stop("observations has unknown rescue_observed value: ",
                        paste(unique(bad), collapse = ", "), call. = FALSE)
  if (any(!grepl("^[1-9][0-9]*$", observations$biological_replicate))) {
    stop("biological_replicate must be a positive integer", call. = FALSE)
  }

  assayed_at <- .prospective_utc(observations$assayed_at_utc, "assayed_at_utc")
  observation_study <- samples$study_id[match(observations$sample_id, samples$sample_id)]
  observation_lock <- lock_time[match(observation_study, studies$study_id)]
  if (any(assayed_at < observation_lock)) {
    stop("observations predate their locked protocol; preserve them as pilot data, not scored results", call. = FALSE)
  }

  specificity_rows <- samples$study_id %in% studies$study_id[studies$priority == "specificity"]
  if (any(samples$marker_evidence_class[specificity_rows] == "not_applicable")) {
    stop("specificity studies must classify marker evidence; use broad_marker_only or no_relevant_marker when appropriate", call. = FALSE)
  }
  auxotrophy_study <- studies$study_id[studies$priority == "auxotrophy"]
  auxotrophy_rows <- observation_study %in% auxotrophy_study
  if (any(observations$baseline_medium[auxotrophy_rows] == "not_applicable") ||
      any(observations$omitted_nutrient[auxotrophy_rows] == "not_applicable") ||
      any(observations$rescue_observed[auxotrophy_rows] == "not_applicable")) {
    stop("auxotrophy observations require a baseline medium, omitted nutrient and rescue result", call. = FALSE)
  }

  list(
    studies = studies,
    samples = samples,
    annotations = annotations,
    observations = observations,
    database_version = gifter_db_version(db = db)
  )
}

.prospective_collapse <- function(x) paste(as.character(x[[1L]]), collapse = ";")

.prospective_reaction_trace <- function(result, reaction_id) {
  components <- as.data.frame(result$components)
  components <- components[components$reaction_id == reaction_id, , drop = FALSE]
  if (!nrow(components)) return(components)
  components$accepted_markers <- vapply(components$accepted_markers, paste, collapse = ";", character(1))
  components$supporting_markers <- vapply(components$supporting_markers, paste, collapse = ";", character(1))
  components$supporting_genes <- vapply(components$supporting_genes, paste, collapse = ";", character(1))
  components
}

#' Evaluate every deposited annotation in a prospective-validation registry
#'
#' Calls are calculated once per sample from its own annotation table. Results
#' retain the raw observation, protocol and exact trace; observation rows are
#' never pooled into an accuracy metric.
#'
#' @param inputs A value returned by [prospective_read_inputs()].
#' @param db Optional gifter database connection.
#' @return Report, trace and count tables suitable for writing to the study
#'   output directory.
prospective_evaluate <- function(inputs, db = NULL) {
  required <- c("studies", "samples", "annotations", "observations", "database_version")
  if (!is.list(inputs) || !all(required %in% names(inputs))) {
    stop("inputs must come from prospective_read_inputs()", call. = FALSE)
  }

  calls <- list()
  gift_traces <- list()
  reaction_traces <- list()
  index <- 0L
  for (i in seq_len(nrow(inputs$samples))) {
    sample <- inputs$samples[i, , drop = FALSE]
    study <- inputs$studies[inputs$studies$study_id == sample$study_id, , drop = FALSE]
    annotation <- inputs$annotations[inputs$annotations$sample_id == sample$sample_id,
                                      c("gene_id", "namespace", "accession"), drop = FALSE]
    if (study$target_layer == "gift") {
      evaluated <- evaluate_gifts(annotation, max_genes = Inf, db = db)
      call <- as.data.frame(evaluated$gifts[evaluated$gifts$gift_id == study$target_id, , drop = FALSE])
      index <- index + 1L
      calls[[index]] <- data.frame(
        sample_id = sample$sample_id,
        study_id = study$study_id,
        target_layer = study$target_layer,
        target_id = study$target_id,
        call_supported = call$complete,
        best_implementation = call$best_implementation,
        minimum_missing_requirements = call$minimum_missing_requirements,
        missing_requirements = .prospective_collapse(call$missing_requirements),
        stringsAsFactors = FALSE
      )
      trace <- as.data.frame(trace_gift(evaluated, study$target_id))
      trace$sample_id <- sample$sample_id
      trace$study_id <- study$study_id
      gift_traces[[length(gift_traces) + 1L]] <- trace
    } else {
      evaluated <- evaluate_reactions(annotation, db = db)
      call <- as.data.frame(evaluated$reactions[evaluated$reactions$reaction_id == study$target_id, , drop = FALSE])
      index <- index + 1L
      calls[[index]] <- data.frame(
        sample_id = sample$sample_id,
        study_id = study$study_id,
        target_layer = study$target_layer,
        target_id = study$target_id,
        call_supported = call$supported,
        best_implementation = call$best_system,
        minimum_missing_requirements = call$minimum_missing_components,
        missing_requirements = .prospective_collapse(call$missing_components),
        stringsAsFactors = FALSE
      )
      trace <- .prospective_reaction_trace(evaluated, study$target_id)
      trace$sample_id <- sample$sample_id
      trace$study_id <- study$study_id
      reaction_traces[[length(reaction_traces) + 1L]] <- trace
    }
  }
  calls <- do.call(rbind, calls)

  observations <- merge(inputs$observations, inputs$samples, by = "sample_id", sort = FALSE)
  observations <- merge(observations, inputs$studies, by = "study_id", sort = FALSE)
  report <- merge(observations, calls,
                  by = c("sample_id", "study_id", "target_layer", "target_id"), sort = FALSE)
  report$database_version_evaluated <- as.character(inputs$database_version$gifter_db_version[[1L]])
  report$call_supported <- as.logical(report$call_supported)

  recall_usable <- report$crosswalk_relation %in% c("equivalent", "subset_of")
  reportable <- report[recall_usable, , drop = FALSE]
  groups <- split(reportable, reportable$study_id)
  summary <- do.call(rbind, lapply(groups, function(x) {
    data.frame(
      study_id = x$study_id[[1L]],
      target_id = x$target_id[[1L]],
      paired_observations = nrow(x),
      observed_positive_n = sum(x$observed == "positive"),
      observed_positive_unsupported = sum(x$observed == "positive" & !x$call_supported),
      supported_observed_negative = sum(x$observed == "negative" & x$call_supported),
      broad_marker_only_supported = sum(x$marker_evidence_class == "broad_marker_only" & x$call_supported),
      distinct_lineages = length(unique(x$lineage)),
      stringsAsFactors = FALSE
    )
  }))
  if (is.null(summary)) {
    summary <- data.frame(
      study_id = character(), target_id = character(), paired_observations = integer(),
      observed_positive_n = integer(), observed_positive_unsupported = integer(),
      supported_observed_negative = integer(), broad_marker_only_supported = integer(),
      distinct_lineages = integer(), stringsAsFactors = FALSE
    )
  }

  list(
    report = report,
    summary = summary,
    gift_trace = if (length(gift_traces)) do.call(rbind, gift_traces) else data.frame(),
    reaction_trace = if (length(reaction_traces)) do.call(rbind, reaction_traces) else data.frame(),
    database_version = inputs$database_version
  )
}

#' Write prospective-validation analysis outputs
#'
#' @param result A value returned by [prospective_evaluate()].
#' @param output_dir Directory to receive versioned TSV outputs.
#' @return Invisibly, the paths written.
prospective_write_outputs <- function(result, output_dir) {
  if (!is.list(result) || !all(c("report", "summary", "gift_trace", "reaction_trace") %in% names(result))) {
    stop("result must come from prospective_evaluate()", call. = FALSE)
  }
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  paths <- c(
    report = file.path(output_dir, "prospective-validation-results.tsv"),
    summary = file.path(output_dir, "prospective-validation-summary.tsv"),
    gift_trace = file.path(output_dir, "prospective-validation-gift-trace.tsv"),
    reaction_trace = file.path(output_dir, "prospective-validation-reaction-trace.tsv")
  )
  for (name in names(paths)) {
    utils::write.table(result[[name]], paths[[name]], sep = "\t", quote = FALSE,
                       row.names = FALSE, na = "")
  }
  invisible(paths)
}
