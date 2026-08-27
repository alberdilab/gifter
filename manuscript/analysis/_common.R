# Shared helpers for the manuscript analyses.
#
# R7, R8 and R9 all need the same two things: a set of genomes whose markers are
# known, and a way to reach an external record about the organisms behind them.
# Building that once here keeps the three result sections comparable -- a
# disagreement between R8 and R9 should be a disagreement about phenotype, not
# about which genomes were annotated how.
#
# Everything downloaded is cached under manuscript/analysis/.cache and is not
# committed. KEGG's REST service is licensed for academic use and its derived
# tables must not be redistributed; BacDive and MediaDive are CC BY 4.0 and
# MediaDive needs no key. Commit derived summaries, never the caches.
#
# source("manuscript/analysis/_common.R") from the repository root.

suppressWarnings(suppressMessages({
  library(DBI)
  library(RSQLite)
  library(jsonlite)
  library(curl)
}))

ANALYSIS_CACHE <- Sys.getenv("GIFTER_ANALYSIS_CACHE", "manuscript/analysis/.cache")
dir.create(ANALYSIS_CACHE, showWarnings = FALSE, recursive = TRUE)

`%||%` <- function(a, b) if (is.null(a)) b else a

say  <- function(...) cat(..., "\n", sep = "")
kv   <- function(label, value) cat(sprintf("  %-56s %s\n", label, format(value)))
rule <- function(title) cat("\n", title, "\n", strrep("-", nchar(title)), "\n", sep = "")

# ---------------------------------------------------------------------- caching
# One file per request. Re-running an analysis must not re-hit a public service,
# both out of courtesy and because a benchmark whose inputs move underneath it
# is not reproducible.

cache_path <- function(...) {
  path <- file.path(ANALYSIS_CACHE, ...)
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  path
}

cached_get <- function(url, dest, pause = 0.34) {
  path <- cache_path(dest)
  if (!file.exists(path)) {
    ok <- tryCatch({
      utils::download.file(url, path, quiet = TRUE)
      TRUE
    }, error = function(e) FALSE, warning = function(w) FALSE)
    Sys.sleep(pause)
    if (!ok || !file.exists(path) || file.size(path) == 0) {
      if (file.exists(path)) unlink(path)
      return(NA_character_)
    }
  }
  path
}

# Concurrent variant. Forking is not an option here -- the analyses hold an open
# SQLite handle, and a forked child inheriting it aborts the session -- so this
# uses libcurl's own connection pool instead. Four connections against a public
# academic service, and every file is written once and reused.
cached_get_many <- function(urls, dests, host_con = 4L) {
  paths <- vapply(dests, cache_path, character(1), USE.NAMES = FALSE)
  todo <- which(!file.exists(paths))
  if (length(todo)) {
    message("  fetching ", length(todo), " of ", length(paths), " on ", host_con, " connections")
    # multi_download has no connection cap of its own, so the cap is the batch
    # size: `host_con` requests are in flight, then the next group starts.
    groups <- split(todo, ceiling(seq_along(todo) / host_con))
    for (i in seq_along(groups)) {
      g   <- groups[[i]]
      res <- curl::multi_download(urls[g], paths[g], resume = FALSE, progress = FALSE)
      unlink(paths[g][!res$success | res$status_code >= 400])
      if (i %% 50 == 0) message("    ", i * host_con, "/", length(todo))
    }
  }
  empty <- file.exists(paths) & file.size(paths) == 0
  unlink(paths[empty])
  ifelse(file.exists(paths), paths, NA_character_)
}

# ------------------------------------------------------------------- the database

gifter_db <- function(path = "inst/extdata/gifter.sqlite") {
  # No finalizer. An earlier version registered one on environment(), which is
  # the call frame: it becomes unreachable the moment the function returns, so
  # the next garbage collection closed the connection underneath the caller.
  # That failed silently until a long run called gc() explicitly and then tried
  # to query. R closes the handle at session end, which is all this needs.
  dbConnect(SQLite(), path)
}

# Every marker that is evidence for a GIFT, at whatever layer it attaches. A
# slice only needs to fetch the annotations that could possibly bear on the GIFT
# under test, which is what makes a one-GIFT pipeline cheap enough to iterate on.
gift_markers <- function(con, gift_id) {
  metabolic <- dbGetQuery(con, "
    select distinct m.namespace, m.accession, ec.component_id
    from gift g
    join gift_route gr on gr.gift_pk = g.gift_pk
    join route_reaction rr on rr.route_pk = gr.route_pk
    join enzyme_system es on es.reaction_pk = rr.reaction_pk
    join enzyme_component ec on ec.system_pk = es.system_pk
    join component_marker cm on cm.component_pk = ec.component_pk
    join marker m on m.marker_pk = cm.marker_pk
    where g.gift_id = :gift", params = list(gift = gift_id))
  metabolic
}

# ------------------------------------------------------------------------- KEGG
# 11 949 genome entries, each with an NCBI taxon and a GenBank assembly. The
# assembly accession is what joins a KEGG genome to a BacDive strain, and the
# taxon is what joins it to a species-level trait record.

kegg_genome_list <- function() {
  path <- cached_get("https://rest.kegg.jp/list/genome", "kegg/list-genome.tsv")
  lines <- readLines(path, warn = FALSE)
  tnum  <- sub("\t.*", "", lines)
  rest  <- sub("^[^\t]+\t", "", lines)
  org   <- sub(";.*", "", rest)
  name  <- sub(" [(].*", "", sub("^[a-z0-9]+; ", "", rest))
  binom <- vapply(strsplit(name, " "), function(x) paste(x[1:2], collapse = " "), character(1))
  data.frame(tnumber = tnum, org = org, name = name, binomial = binom,
             stringsAsFactors = FALSE)
}

# Ten entries per request is KEGG's documented batch limit, so the whole genome
# table costs about 1 200 requests rather than 11 949.
kegg_genome_metadata <- function(tnumbers, batch = 10, workers = 4L) {
  chunks <- split(tnumbers, ceiling(seq_along(tnumbers) / batch))

  # A ten-entry batch takes about 1.6 s, so the full genome table is 40 minutes
  # on one connection and about ten on four. The table is fetched once and then
  # serves R7, R8 and R9 alike.
  cached_get_many(
    vapply(chunks, function(ids)
      paste0("https://rest.kegg.jp/get/", paste0("gn:", ids, collapse = "+")),
      character(1), USE.NAMES = FALSE),
    vapply(chunks, function(ids)
      file.path("kegg", "genome", paste0(ids[[1]], ".txt")),
      character(1), USE.NAMES = FALSE),
    host_con = workers)

  out <- vector("list", length(chunks))
  for (i in seq_along(chunks)) {
    ids  <- chunks[[i]]
    path <- cache_path(file.path("kegg", "genome", paste0(ids[[1]], ".txt")))
    if (!file.exists(path)) next
    lines <- readLines(path, warn = FALSE)
    entry <- taxid <- assembly <- NA_character_
    rows  <- list()
    flush <- function() {
      if (!is.na(entry)) rows[[length(rows) + 1]] <<-
        data.frame(tnumber = entry, taxid = taxid, assembly = assembly,
                   stringsAsFactors = FALSE)
    }
    for (line in lines) {
      if (startsWith(line, "ENTRY")) {
        flush()
        entry <- sub("^ENTRY\\s+(\\S+).*", "\\1", line)
        taxid <- assembly <- NA_character_
      } else if (startsWith(line, "TAXONOMY")) {
        taxid <- sub("^TAXONOMY\\s+TAX:(\\S+).*", "\\1", line)
      } else if (startsWith(line, "DATA_SOURCE") && grepl("Assembly:", line)) {
        assembly <- sub(".*Assembly:\\s*(GC[AF]_[0-9.]+).*", "\\1", line)
      }
    }
    flush()
    out[[i]] <- if (length(rows)) do.call(rbind, rows) else NULL
  }
  res <- do.call(rbind, out)
  if (is.null(res)) return(data.frame())
  res$assembly_base <- sub("[.].*", "", res$assembly)
  res
}

# Which KEGG genomes carry a KO. This is the annotation-free marker matrix: one
# request per curated marker rather than one annotation run per genome. It is
# KEGG's own per-genome assignment and therefore an upper bound on what a user's
# annotator would produce -- see the assessment, section 7.2.
kegg_ko_genes <- function(ko) {
  path <- cached_get(paste0("https://rest.kegg.jp/link/genes/ko:", ko),
                     file.path("kegg", "ko", paste0(ko, ".tsv")))
  if (is.na(path)) return(data.frame())
  lines <- readLines(path, warn = FALSE)
  lines <- lines[nzchar(lines)]
  if (!length(lines)) return(data.frame())
  gene <- sub("^[^\t]+\t", "", lines)
  data.frame(accession = ko, org = sub(":.*", "", gene), gene_id = gene,
             stringsAsFactors = FALSE)
}

# A gifter annotation table for every KEGG genome carrying any of these KOs.
# Genomes with none of them are absent, which is correct: their call is
# unsupported either way, and materialising 11 949 empty genomes to say so costs
# memory for no information.
kegg_annotation_table <- function(kos) {
  hits <- do.call(rbind, lapply(kos, kegg_ko_genes))
  if (!nrow(hits)) return(data.frame())
  data.frame(genome_id = hits$org, namespace = "KO", accession = hits$accession,
             gene_id = hits$gene_id, stringsAsFactors = FALSE)
}

# ---------------------------------------------------------------------- BacDive
# /v2/fetch takes 100 semicolon-separated identifiers, so a complete sweep is
# roughly 1 100 requests. Sample only while iterating.

bacdive_fetch <- function(ids, batch = 100, workers = 4L) {
  chunks <- split(ids, ceiling(seq_along(ids) / batch))
  dest <- function(block) file.path("bacdive",
    paste0(block[[1]], "-", block[[length(block)]], ".json"))

  cached_get_many(
    vapply(chunks, function(block)
      paste0("https://api.bacdive.dsmz.de/v2/fetch/", paste(block, collapse = ";")),
      character(1), USE.NAMES = FALSE),
    vapply(chunks, dest, character(1), USE.NAMES = FALSE),
    host_con = workers)

  out <- list()
  for (i in seq_along(chunks)) {
    block <- chunks[[i]]
    path  <- cache_path(dest(block))
    if (!file.exists(path)) next
    parsed <- tryCatch(fromJSON(path, simplifyVector = FALSE), error = function(e) NULL)
    res <- parsed$results
    if (length(res)) out <- c(out, res)
    if (i %% 20 == 0) message("  bacdive ", i, "/", length(chunks), ", ", length(out), " records")
  }
  out
}

# Retaining every parsed record does not scale: a full sweep is over 100 000
# deeply nested lists and the session dies before it finishes. This applies the
# extractors one batch at a time and keeps only the rows, which is what every
# analysis actually wants.
bacdive_reduce <- function(ids, extractors, batch = 100, workers = 4L) {
  chunks <- split(ids, ceiling(seq_along(ids) / batch))
  dest <- function(block) file.path("bacdive",
    paste0(block[[1]], "-", block[[length(block)]], ".json"))

  cached_get_many(
    vapply(chunks, function(block)
      paste0("https://api.bacdive.dsmz.de/v2/fetch/", paste(block, collapse = ";")),
      character(1), USE.NAMES = FALSE),
    vapply(chunks, dest, character(1), USE.NAMES = FALSE),
    host_con = workers)

  parts <- setNames(vector("list", length(extractors)), names(extractors))
  seen <- 0L
  for (i in seq_along(chunks)) {
    path <- cache_path(dest(chunks[[i]]))
    if (!file.exists(path)) next
    parsed <- tryCatch(fromJSON(path, simplifyVector = FALSE), error = function(e) NULL)
    res <- parsed$results
    if (!length(res)) next
    seen <- seen + length(res)
    for (nm in names(extractors)) {
      rows <- do.call(rbind, lapply(res, extractors[[nm]]))
      if (!is.null(rows) && nrow(rows)) parts[[nm]] <- c(parts[[nm]], list(rows))
    }
    rm(parsed, res)
    if (i %% 40 == 0) { gc(FALSE); message("  bacdive ", i, "/", length(chunks), ", ", seen, " records") }
  }
  out <- lapply(parts, function(x) if (length(x)) do.call(rbind, x) else data.frame())
  attr(out, "records") <- seen
  out
}

# BacDive nests single records as bare lists and repeated ones as lists of
# lists. Everything downstream wants the second shape.
bd_rows <- function(record, section, field) {
  value <- record[[section]][[field]]
  if (is.null(value)) return(list())
  if (!is.null(names(value))) list(value) else value
}

bd_id       <- function(r) as.character(r[["General"]][["BacDive-ID"]] %||% NA)
bd_name     <- function(r) as.character(r[["Name and taxonomic classification"]][["species"]] %||% NA)

bd_assemblies <- function(r) {
  rows <- bd_rows(r, "Sequence information", "Genome sequences")
  if (!length(rows)) return(data.frame())
  data.frame(
    bacdive_id = bd_id(r),
    assembly   = vapply(rows, function(x) as.character(x[["INSDC accession"]] %||% NA), character(1)),
    level      = vapply(rows, function(x) as.character(x[["assembly level"]] %||% NA), character(1)),
    score      = vapply(rows, function(x) as.numeric(x[["score"]] %||% NA), numeric(1)),
    stringsAsFactors = FALSE)
}

bd_utilisation <- function(r) {
  rows <- bd_rows(r, "Physiology and metabolism", "metabolite utilization")
  if (!length(rows)) return(data.frame())
  data.frame(
    bacdive_id = bd_id(r),
    chebi      = vapply(rows, function(x) as.character(x[["Chebi-ID"]] %||% NA), character(1)),
    metabolite = vapply(rows, function(x) as.character(x[["metabolite"]] %||% NA), character(1)),
    activity   = vapply(rows, function(x) as.character(x[["utilization activity"]] %||% NA), character(1)),
    kind       = vapply(rows, function(x) as.character(x[["kind of utilization tested"]] %||% NA), character(1)),
    stringsAsFactors = FALSE)
}

bd_production <- function(r) {
  rows <- bd_rows(r, "Physiology and metabolism", "metabolite production")
  if (!length(rows)) return(data.frame())
  data.frame(
    bacdive_id = bd_id(r),
    chebi      = vapply(rows, function(x) as.character(x[["Chebi-ID"]] %||% NA), character(1)),
    metabolite = vapply(rows, function(x) as.character(x[["metabolite"]] %||% NA), character(1)),
    produced   = vapply(rows, function(x) as.character(x[["production"]] %||% NA), character(1)),
    stringsAsFactors = FALSE)
}

bd_enzymes <- function(r) {
  rows <- bd_rows(r, "Physiology and metabolism", "enzymes")
  if (!length(rows)) return(data.frame())
  data.frame(
    bacdive_id = bd_id(r),
    ec         = vapply(rows, function(x) as.character(x[["ec"]] %||% NA), character(1)),
    enzyme     = vapply(rows, function(x) as.character(x[["value"]] %||% NA), character(1)),
    activity   = vapply(rows, function(x) as.character(x[["activity"]] %||% NA), character(1)),
    stringsAsFactors = FALSE)
}

bd_motility <- function(r) {
  rows <- bd_rows(r, "Morphology", "cell morphology")
  if (!length(rows)) return(data.frame())
  value <- vapply(rows, function(x) as.character(x[["motility"]] %||% NA), character(1))
  value <- value[!is.na(value)]
  if (!length(value)) return(data.frame())
  data.frame(bacdive_id = bd_id(r), motility = value[[1]], stringsAsFactors = FALSE)
}

# --------------------------------------------------------------- the crosswalk
# The curated mapping from an external observation to something gifter claims,
# and the ChEBI aliases that let a metabolite record find its anchor. Both live
# in data-raw/reference/ with the other consulted evidence: a mapping to someone
# else's observation vocabulary is a benchmark artefact, not a claim gifter
# makes, and compiling it into the database would start making it look like one.

CROSSWALK_RELATIONS <- c("equivalent", "subset_of", "superset_of", "overlaps",
                         "related", "refused", "voids")

# Which relations let an observation imply the target. This is the rule the
# whole benchmark turns on, so it is one line and it is stated once.
#
#   equivalent   observation and target are the same claim
#   subset_of    observation is narrower, so it implies the target
#   superset_of  observation is broader, so it does NOT imply the target
#   overlaps     neither implies the other
#
# Only the first two may enter a recall table. `superset_of` rows are kept
# because they still bound the permitted cell -- the target implies them -- and
# discarding them would hide the fact that the mapping was considered.
RECALL_RELATIONS <- c("equivalent", "subset_of")

read_phenotype_crosswalk <- function(con,
                                     path = "data-raw/reference/phenotype-crosswalk.tsv") {
  x <- read.delim(path, stringsAsFactors = FALSE, na.strings = "")
  required <- c("source", "source_field", "source_id", "source_label", "kinds",
                "layer", "target_id", "relation", "polarity", "notes")
  missing <- setdiff(required, names(x))
  if (length(missing)) stop("crosswalk is missing columns: ", paste(missing, collapse = ", "))

  bad <- setdiff(x$relation, CROSSWALK_RELATIONS)
  if (length(bad)) stop("unknown relation(s): ", paste(unique(bad), collapse = ", "))
  bad <- setdiff(x$layer, c("reaction", "gift", "frame"))
  if (length(bad)) stop("unknown layer(s): ", paste(unique(bad), collapse = ", "))
  bad <- setdiff(x$polarity, c("necessary", "falsifying"))
  if (length(bad)) stop("unknown polarity: ", paste(unique(bad), collapse = ", "))

  # A target that does not exist is the failure mode this reader exists to
  # catch: a renamed GIFT leaves a crosswalk row pointing at nothing, and the
  # analysis would silently lose a test rather than fail.
  known <- list(
    gift     = dbGetQuery(con, "select gift_id id from gift")$id,
    reaction = dbGetQuery(con, "select reaction_id id from reaction")$id,
    frame    = dbGetQuery(con, "select frame_id id from reference_frame")$id)
  for (layer in names(known)) {
    rows <- x[x$layer == layer & !is.na(x$target_id), ]
    gone <- setdiff(rows$target_id, known[[layer]])
    if (length(gone)) stop("crosswalk names unknown ", layer, "(s): ",
                           paste(gone, collapse = ", "))
  }

  x$recall_usable <- x$relation %in% RECALL_RELATIONS
  x$kinds <- strsplit(ifelse(is.na(x$kinds), "", x$kinds), ";\\s*")
  x
}

# The ChEBI identifiers an external record may use for an anchor. Returns a
# lookup from any accepted alias to the anchor's own identifier, so a join can
# be a match rather than a traversal.
read_chebi_aliases <- function(path = "data-raw/reference/chebi-anchor-aliases.tsv") {
  x <- read.delim(path, stringsAsFactors = FALSE, na.strings = "")
  bad <- setdiff(x$status, c("derived", "curated"))
  if (length(bad)) stop("unknown alias status: ", paste(unique(bad), collapse = ", "))
  identity <- unique(data.frame(alias = x$anchor_chebi, anchor = x$anchor_chebi,
                                stringsAsFactors = FALSE))
  aliased <- unique(data.frame(alias = x$alias_chebi, anchor = x$anchor_chebi,
                               stringsAsFactors = FALSE))
  both <- rbind(identity, aliased)
  # One alias reaching two anchors would silently mis-assign an observation.
  clash <- both$alias[duplicated(both$alias) & !duplicated(both[, c("alias", "anchor")])]
  if (length(clash)) warning("alias reaches more than one anchor: ",
                             paste(unique(clash), collapse = ", "))
  lookup <- setNames(both$anchor, both$alias)
  # Returned through a resolver rather than raw: `lookup[["CHEBI:28087"]]` on an
  # identifier that has no alias -- glycogen, say, which is genuinely not a name
  # for starch -- errors rather than returning nothing, and that trap belongs
  # here once instead of in every caller.
  structure(lookup, class = c("gifter_chebi_alias", class(lookup)))
}

# The anchor identifier an external ChEBI term stands for, or NA. Vectorised.
resolve_chebi <- function(alias, chebi) unname(alias[match(chebi, names(alias))])

# ------------------------------------------------------------- the asymmetric 2x2
# The assessment's section 2, as code, so that no analysis can quietly compute an
# accuracy. A supported call in an organism that does not show the phenotype is
# permitted; an unsupported call in an organism that does is a failure. Recall is
# the statistic. `polarity = "falsifying"` is for anabolic capabilities, where an
# observation of growth without a nutrient makes a positive call refutable and
# both directions carry information.

agreement <- function(call, observed, polarity = c("necessary", "falsifying")) {
  polarity <- match.arg(polarity)
  stopifnot(is.logical(call), is.logical(observed), length(call) == length(observed))
  keep <- !is.na(call) & !is.na(observed)
  call <- call[keep]; observed <- observed[keep]
  out <- list(
    n                  = length(call),
    concordant_positive = sum(call & observed),
    concordant_negative = sum(!call & !observed),
    encoded_not_observed = sum(call & !observed),
    observed_not_encoded = sum(!call & observed),
    polarity           = polarity)
  out$recall <- if (sum(observed) > 0) out$concordant_positive / sum(observed) else NA_real_
  out$falsified <- if (polarity == "falsifying") out$encoded_not_observed else NA_integer_
  class(out) <- "gifter_agreement"
  out
}

print.gifter_agreement <- function(x, ...) {
  cat(sprintf("  n = %d\n", x$n))
  cat(sprintf("  %-38s %d\n", "concordant, both positive", x$concordant_positive))
  cat(sprintf("  %-38s %d\n", "concordant, both negative", x$concordant_negative))
  cat(sprintf("  %-38s %d%s\n", "encoded, not observed", x$encoded_not_observed,
              if (x$polarity == "falsifying") "   <- FALSIFIED positive calls" else "   (permitted)"))
  cat(sprintf("  %-38s %d   <- gifter failures\n", "observed, not encoded", x$observed_not_encoded))
  cat(sprintf("  %-38s %s\n", "recall against observed positives",
              if (is.na(x$recall)) "undefined" else sprintf("%.3f", x$recall)))
  invisible(x)
}
