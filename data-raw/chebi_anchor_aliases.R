#!/usr/bin/env Rscript
# Derive, and verify, the ChEBI identifiers an external record may use for a
# gifter anchor.
#
# gifter's anchors carry Rhea's participant identifiers, which are charge- and
# anomer-resolved: L-tryptophan is CHEBI:57912, the zwitterion, and D-galactose
# is CHEBI:27667, the beta anomer. Every external phenotype record consulted so
# far uses the parent instead -- BacDive records L-arabinose as CHEBI:30849
# against the anchor's CHEBI:17535, and MediaDive lists L-Tryptophan as
# CHEBI:16828. Joining an observation to an anchor on identifier equality
# therefore fails for almost every metabolite that matters, and the assessment
# in inst/doc/proposal-phenotype-validation.md refuses to close that gap by
# walking the ontology at analysis time: a traversal that goes one step too far
# turns a specific anchor into a compound class, which is invariant 16 breached
# through the back door.
#
# So the walk happens here, once, with its evidence recorded. For every anchor
# this asks ChEBI for the relations that preserve chemical identity --
#
#   is tautomer of            the zwitterion and its neutral parent
#   is protonated form of     a protonation state
#   is deprotonated form of   the same, the other way
#   is conjugate acid/base of the older spelling of the same thing
#
# -- and writes them as `derived`. `is enantiomer of` and `has parent hydride`
# are never accepted: they change the molecule.
#
# The other step an assay needs is the anomeric one, from beta-D-galactose to
# D-galactose, and **that step is not derived here**. It cannot be: the ChEBI
# parent of an anomer is sometimes the sugar (L-rhamnopyranose to L-rhamnose)
# and sometimes another anomeric class (beta-D-galactose to D-galactopyranose),
# and the parent of a specific compound is sometimes a genuine widening with an
# identical molecular formula (N-acetyl-D-glucosamine to N-acetyl-D-hexosamine).
# No label or formula rule separates those cases, which is the assessment's
# point restated: a traversal that goes one step too far turns a specific anchor
# into a compound class. So the subClassOf steps are written to a candidates
# file for review, and an accepted one is added to the alias table with
# `status = curated`. Reruns preserve curated rows.
#
# This is a curation reference input. It is not compiled into the database, and
# an alias here never changes a call: it only lets an external observation find
# the anchor it was always about.
#
# Usage:
#   Rscript data-raw/chebi_anchor_aliases.R [--cache=DIR] [--out=PATH] [--offline]

suppressWarnings(suppressMessages({
  library(DBI); library(RSQLite); library(jsonlite); library(curl)
}))

args <- commandArgs(trailingOnly = TRUE)
opt <- function(name, default) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit) == 0) default else sub(paste0("^--", name, "="), "", hit[[1]])
}
cache_dir <- opt("cache", "data-raw/reference/.cache/chebi-graph")
out_path  <- opt("out", "data-raw/reference/chebi-anchor-aliases.tsv")
cand_path <- opt("candidates", "data-raw/reference/chebi-anchor-alias-candidates.tsv")
offline   <- "--offline" %in% args
dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)

# Relations that keep the molecule the same molecule. Widening this vector is a
# deliberate edit, and it is the only place the walk can be widened.
IDENTITY_RELATIONS <- c("is tautomer of",
                        "is protonated form of", "is deprotonated form of",
                        "is conjugate acid of", "is conjugate base of")

con <- dbConnect(SQLite(), "inst/extdata/gifter.sqlite")
anchors <- dbGetQuery(con, "select anchor_id, name, chebi_id from anchor
                            where chebi_id is not null and chebi_id <> ''")
anchors$chebi <- sub("CHEBI:", "", anchors$chebi_id)
# Two anchors can share a ChEBI when a molecule is declared on both sides of a
# membrane. Query once, emit for both.
queries <- unique(anchors$chebi)
message("anchors with a ChEBI identifier: ", nrow(anchors),
        " over ", length(queries), " distinct identifiers")

ols_graph <- function(chebi) {
  path <- file.path(cache_dir, paste0(chebi, ".json"))
  if (!file.exists(path)) {
    if (offline) return(NULL)
    # OLS wants the IRI double-encoded. URLencode() leaves an existing '%'
    # alone, so a second call is a no-op and the percent must be escaped by
    # hand -- otherwise every request comes back 400.
    iri <- utils::URLencode(paste0("http://purl.obolibrary.org/obo/CHEBI_", chebi),
                            reserved = TRUE)
    iri <- gsub("%", "%25", iri, fixed = TRUE)
    url <- paste0("https://www.ebi.ac.uk/ols4/api/ontologies/chebi/terms/", iri, "/graph")
    ok <- tryCatch({ curl::curl_download(url, path, quiet = TRUE); TRUE },
                   error = function(e) FALSE)
    Sys.sleep(0.15)
    if (!ok) return(NULL)
  }
  tryCatch(fromJSON(path, simplifyVector = FALSE), error = function(e) NULL)
}

short <- function(iri) sub(".*CHEBI_", "", iri)
`%||%` <- function(a, b) if (is.null(a)) b else a
rows <- list()
candidates <- list()

for (i in seq_along(queries)) {
  chebi <- queries[[i]]
  a <- anchors[anchors$chebi == chebi, ][1, ]
  g <- ols_graph(chebi)
  if (is.null(g)) next
  labels <- setNames(
    vapply(g$nodes, function(n) as.character(n$label %||% NA), character(1)),
    vapply(g$nodes, function(n) as.character(n$iri), character(1)))

  for (e in g$edges) {
    relation <- as.character(e$label)
    from <- as.character(e$source); to <- as.character(e$target)
    # Only edges that leave the anchor itself, and only toward another ChEBI.
    if (!grepl("CHEBI_", to) || short(from) != a$chebi) next

    sharing <- anchors[anchors$chebi == chebi, ]
    row <- function(rel, status)
      data.frame(anchor_id = sharing$anchor_id,
                 anchor_chebi = paste0("CHEBI:", chebi),
                 anchor_label = sharing$name,
                 alias_chebi = paste0("CHEBI:", short(to)),
                 alias_label = labels[[to]] %||% NA_character_,
                 relation = rel, status = status, notes = "",
                 stringsAsFactors = FALSE)

    if (relation %in% IDENTITY_RELATIONS) {
      rows[[length(rows) + 1]] <- row(relation, "derived")
    } else if (relation == "subClassOf") {
      candidates[[length(candidates) + 1]] <- row(relation, "candidate")
    }
  }
  if (i %% 25 == 0) message("  ", i, "/", length(queries))
}

if (!length(rows)) stop("no aliases derived -- check the OLS requests and the cache")
out <- do.call(rbind, rows)
out$verified <- format(Sys.Date())

# A curator's accepted parent-form step is not something this script may
# overwrite. Existing curated rows are carried through and win on conflict.
if (file.exists(out_path)) {
  prior <- read.delim(out_path, stringsAsFactors = FALSE)
  kept <- prior[prior$status == "curated", , drop = FALSE]
  if (nrow(kept)) {
    message("carrying ", nrow(kept), " curated rows through")
    out <- rbind(kept, out)
  }
}
out <- out[!duplicated(out[, c("anchor_id", "alias_chebi")]), ]
out <- out[order(out$anchor_id, out$alias_chebi), ]

dir.create(dirname(out_path), showWarnings = FALSE, recursive = TRUE)
write.table(out, out_path, sep = "\t", quote = FALSE, row.names = FALSE, na = "")

cand <- if (length(candidates)) do.call(rbind, candidates) else data.frame()
if (nrow(cand)) {
  cand <- cand[!paste(cand$anchor_id, cand$alias_chebi) %in%
                 paste(out$anchor_id, out$alias_chebi), ]
  cand <- cand[order(cand$anchor_id), ]
  cand$verified <- format(Sys.Date())
  write.table(cand, cand_path, sep = "\t", quote = FALSE, row.names = FALSE, na = "")
}

message("\nwrote ", nrow(out), " aliases over ",
        length(unique(out$anchor_id)), " anchors to ", out_path)
print(table(out$relation, out$status))
message("\n", nrow(cand), " subClassOf steps await review in ", cand_path)
