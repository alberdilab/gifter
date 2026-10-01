#!/usr/bin/env Rscript
# R9, database-only validation coverage.
#
# This audit turns the already committed BacDive, MediaDive and Madin outputs
# into a per-GIFT account of what existing phenotype/genome information can and
# cannot test. It does not fetch a source, annotate a new genome, treat a
# related phenotype as an equivalent claim, or emit an accuracy-like score.
#
# Products, written to manuscript/analysis/output/:
#
#   phenotype-validation-evidence.tsv  every source row mapped to each GIFT it
#                                      can inform, retaining relation and n
#   phenotype-validation-coverage.tsv  one auditable validation status per GIFT
#   phenotype-validation-summary.tsv   counts by GIFT type and status
#   phenotype-validation-input-manifest.tsv  SHA-256 pins for all inputs
#
# Usage:
#   Rscript manuscript/analysis/19-phenotype-validation-coverage.R

source("manuscript/analysis/_common.R")
suppressMessages(devtools::load_all(".", quiet = TRUE))

out_dir <- "manuscript/analysis/output"
input_paths <- c(
  phenotype_agreement = file.path(out_dir, "phenotype-agreement.tsv"),
  madin_agreement = file.path(out_dir, "madin-agreement.tsv"),
  auxotrophy_agreement = file.path(out_dir, "auxotrophy-agreement.tsv"),
  database = "inst/extdata/gifter.sqlite"
)

must_path <- function(path, label) {
  if (!file.exists(path)) stop(label, " does not exist: ", path, call. = FALSE)
  normalizePath(path, mustWork = TRUE)
}
sha256 <- function(path) {
  out <- system2("shasum", c("-a", "256", path), stdout = TRUE, stderr = TRUE)
  if (!is.null(attr(out, "status")) && attr(out, "status") != 0L)
    stop("Cannot hash ", path, call. = FALSE)
  value <- sub("[[:space:]].*$", "", out[[1L]])
  if (!grepl("^[0-9a-f]{64}$", value)) stop("Invalid SHA-256 for ", path, call. = FALSE)
  value
}
read_agreement <- function(path, label) {
  x <- read.delim(path, stringsAsFactors = FALSE, check.names = FALSE)
  required <- c("source", "field", "term", "layer", "target", "relation",
                "recall_usable", "n")
  missing <- setdiff(required, names(x))
  if (length(missing))
    stop(label, " is missing columns: ", paste(missing, collapse = ", "), call. = FALSE)
  if (!all(x$layer %in% c("gift", "reaction")))
    stop(label, " has an unsupported target layer", call. = FALSE)
  x
}
collapse <- function(x) {
  x <- sort(unique(as.character(x[!is.na(x) & nzchar(x)])))
  if (length(x)) paste(x, collapse = ";") else ""
}

paths <- vapply(names(input_paths), function(name)
  must_path(input_paths[[name]], name), character(1))
phenotype <- read_agreement(paths[["phenotype_agreement"]], "phenotype agreement")
madin <- read_agreement(paths[["madin_agreement"]], "Madin agreement")
auxotrophy <- read.delim(paths[["auxotrophy_agreement"]], stringsAsFactors = FALSE,
                         check.names = FALSE)
if (!nrow(auxotrophy) || !all(c("gift_id", "n") %in% names(auxotrophy)))
  stop("auxotrophy agreement no longer records gift_id and n", call. = FALSE)

rule("1. Inputs")
kv("BacDive/MediaDive agreement rows", nrow(phenotype))
kv("Madin agreement rows", nrow(madin))
kv("auxotrophy nutrient rows", nrow(auxotrophy))

con <- gifter_db(paths[["database"]])
on.exit(dbDisconnect(con), add = TRUE)
database_version <- gifter_db_version(con)$gifter_db_version[[1L]]
gifts <- dbGetQuery(con, "select gift_id, gift_type from gift order by gift_id")
reaction_gifts <- dbGetQuery(con, "
  select distinct r.reaction_id, g.gift_id
  from reaction r
  join route_reaction rr on rr.reaction_pk = r.reaction_pk
  join gift_route gr on gr.route_pk = rr.route_pk
  join gift g on g.gift_pk = gr.gift_pk")
frame_gifts <- dbGetQuery(con, "
  select gift_id
  from gift_profile
  where auxotrophy_indicator = 1 and mode = 'anabolic'")$gift_id

agreement_columns <- c("source", "field", "term", "layer", "target", "relation",
                       "recall_usable", "n")
agreement <- rbind(
  transform(phenotype[, agreement_columns, drop = FALSE],
            analysis_input = "phenotype-agreement.tsv"),
  transform(madin[, agreement_columns, drop = FALSE],
            analysis_input = "madin-agreement.tsv")
)

# One reaction can occur in more than one GIFT. Expand it explicitly rather
# than selecting one convenient boundary for the coverage count.
reaction_rows <- agreement[agreement$layer == "reaction", , drop = FALSE]
if (nrow(reaction_rows)) {
  reaction_rows <- merge(reaction_rows, reaction_gifts,
                         by.x = "target", by.y = "reaction_id",
                         all.x = TRUE, sort = FALSE)
}
gift_rows <- agreement[agreement$layer == "gift", , drop = FALSE]
gift_rows$gift_id <- gift_rows$target
evidence <- rbind(gift_rows, reaction_rows)
if (any(is.na(evidence$gift_id)) || any(!evidence$gift_id %in% gifts$gift_id))
  stop("A phenotype target cannot be mapped to a current GIFT", call. = FALSE)
evidence$recall_usable <- as.logical(evidence$recall_usable)
evidence$n <- as.integer(evidence$n)
evidence$evidence_class <- ifelse(
  evidence$relation == "refused", "refused_proxy",
  ifelse(evidence$recall_usable & evidence$n >= 20L, "individual_recall_usable",
  ifelse(evidence$recall_usable, "individual_below_threshold", "related_context"))
)
evidence <- evidence[, c("gift_id", "analysis_input", "source", "field", "term", "layer",
                         "target", "relation", "recall_usable", "n", "evidence_class")]
evidence <- evidence[order(evidence$gift_id, evidence$evidence_class, evidence$source,
                           evidence$field, evidence$term), ]
row.names(evidence) <- NULL

rule("2. Validation evidence mapped to GIFTs")
kv("mapped source-to-GIFT rows", nrow(evidence))
kv("individual recall-usable rows", sum(evidence$evidence_class == "individual_recall_usable"))
kv("related-context rows", sum(evidence$evidence_class == "related_context"))

coverage <- gifts
coverage$individual_recall_usable <- coverage$gift_id %in%
  evidence$gift_id[evidence$evidence_class == "individual_recall_usable"]
coverage$individual_below_threshold <- coverage$gift_id %in%
  evidence$gift_id[evidence$evidence_class == "individual_below_threshold"]
coverage$related_context <- coverage$gift_id %in%
  evidence$gift_id[evidence$evidence_class == "related_context"]
coverage$refused_proxy <- coverage$gift_id %in%
  evidence$gift_id[evidence$evidence_class == "refused_proxy"]
coverage$bounded_frame_aggregate <- coverage$gift_id %in% frame_gifts
coverage$bounded_frame_aggregate <- coverage$bounded_frame_aggregate &
  !coverage$individual_recall_usable
coverage$validation_status <- ifelse(
  coverage$individual_recall_usable, "individual_recall_usable",
  ifelse(coverage$bounded_frame_aggregate, "bounded_frame_aggregate",
  ifelse(coverage$individual_below_threshold, "individual_below_threshold",
  ifelse(coverage$related_context, "related_context_only",
  ifelse(coverage$refused_proxy, "refused_proxy_only", "no_public_observation")))))
coverage$source_records <- vapply(coverage$gift_id, function(id) {
  rows <- evidence[evidence$gift_id == id, , drop = FALSE]
  if (!nrow(rows)) return("")
  collapse(paste(rows$source, rows$field, rows$term, rows$relation,
                 paste0("n=", rows$n), sep = ":"))
}, character(1))
coverage <- coverage[, c(
  "gift_id", "gift_type", "individual_recall_usable", "individual_below_threshold",
  "related_context", "refused_proxy", "bounded_frame_aggregate", "source_records",
  "validation_status"
)]

if (sum(coverage$individual_recall_usable) != 17L ||
    sum(coverage$bounded_frame_aggregate) != 44L ||
    sum(!coverage$individual_recall_usable & !coverage$bounded_frame_aggregate) != 92L) {
  stop("The current R9 coverage contract (17 individual / 44 frame / 92 remainder) changed; ",
       "inspect the pinned inputs and update the manuscript deliberately.", call. = FALSE)
}
if (any(coverage$gift_type %in% c("regulatory", "defense") &
        coverage$validation_status != "no_public_observation")) {
  stop("A regulatory or defense GIFT unexpectedly acquired public phenotype evidence; ",
       "review the crosswalk rather than silently classifying it.", call. = FALSE)
}

summary <- as.data.frame(table(gift_type = coverage$gift_type,
                               validation_status = coverage$validation_status),
                         stringsAsFactors = FALSE)
summary <- summary[summary$Freq > 0, ]
names(summary)[[3L]] <- "gift_n"
summary <- summary[order(summary$gift_type, summary$validation_status), ]

rule("3. Database-only validation coverage")
print(summary, row.names = FALSE)
cat("\n  `no_public_observation` is not an absence call. It says that the pinned\n",
    "  phenotype/genome references contain no admissible observation for the GIFT.\n",
    "  `related_context_only` remains visible but cannot be promoted into recall.\n",
    "  `refused_proxy_only` is retained to document why a tempting record is not evidence.\n", sep = "")

manifest <- data.frame(
  input_kind = c("phenotype_agreement", "madin_agreement", "auxotrophy_agreement", "gifter_database"),
  path = unname(paths),
  sha256 = vapply(paths, sha256, character(1)),
  database_version = c("", "", "", database_version),
  role = c("strain-matched BacDive phenotype and MediaDive frame results",
           "species-level Madin phenotype results with representative-genome sensitivity",
           "defined-medium bounded-frame result",
           "current GIFT catalogue and reaction-to-GIFT mapping"),
  stringsAsFactors = FALSE
)

write.table(evidence, file.path(out_dir, "phenotype-validation-evidence.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
write.table(coverage, file.path(out_dir, "phenotype-validation-coverage.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
write.table(summary, file.path(out_dir, "phenotype-validation-summary.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
write.table(manifest, file.path(out_dir, "phenotype-validation-input-manifest.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
