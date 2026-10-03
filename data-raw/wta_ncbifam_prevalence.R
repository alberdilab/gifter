#!/usr/bin/env Rscript
# Exact candidate-specific NCBIfam prevalence screen for wall teichoic acid.
#
# The stored 11,949-genome frame is KO-only. Annotating a random subset with
# NCBIfam would estimate prevalence but would not answer the curation question:
# how many genomes in the full frame complete the marker-resolved architecture?
# The safe architecture supplies a cheaper exact screen. Every positive call
# must first carry every required KO proxy, so NCBIfam only has to be run on the
# exact KO-assigned polymerase sequences from the intersection of those KO
# sets. The NCBIfam-positive set is necessarily a subset of that full-frame
# intersection; taxonomy never substitutes for a marker.
#
# This script also re-reads the complete pinned NCBIfam metadata table for a
# 168-type TagF equivalog. It records why the broad domain profile and the
# Staphylococcus TarF equivalog cannot license the Bacillus 168 polymerase.
#
# Usage:
#   Rscript data-raw/wta_ncbifam_prevalence.R
#   Rscript data-raw/wta_ncbifam_prevalence.R --offline
#
# Downloaded KO links, HMMs and amino-acid sequences are cached and are not committed.
# Only aggregate results are written, because KEGG's per-genome assignments
# are not redistributable.

args <- commandArgs(trailingOnly = TRUE)
opt <- function(name, default) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit)) sub(paste0("^--", name, "="), "", hit[[1L]]) else default
}

cache_dir <- opt("cache", "data-raw/reference/.cache/wta-ncbifam")
out_dir <- opt("out", "data-raw/reference")
frame_path <- opt("frame", "manuscript/analysis/output/kegg-genome-set.tsv")
threads <- as.integer(opt("threads", "2"))
offline <- "--offline" %in% args

dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

say <- function(...) cat(..., "\n", sep = "")
read_tsv <- function(path, ...) {
  utils::read.delim(
    path, quote = "", comment.char = "", stringsAsFactors = FALSE,
    check.names = FALSE, ...
  )
}
write_tsv <- function(x, path) {
  utils::write.table(
    x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = ""
  )
  invisible(path)
}

fetch <- function(url, relative, attempts = 5L) {
  path <- file.path(cache_dir, relative)
  if (file.exists(path) && file.size(path) > 0) return(path)
  if (offline) stop("missing cached input and --offline was given: ", path)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  part <- paste0(path, ".part")
  for (attempt in seq_len(attempts)) {
    if (file.exists(part)) unlink(part)
    status <- tryCatch(
      utils::download.file(url, part, quiet = TRUE, mode = "wb"),
      error = function(e) 1L,
      warning = function(w) 1L
    )
    if (identical(status, 0L) && file.exists(part) && file.size(part) > 0) {
      if (!file.rename(part, path)) stop("could not install downloaded input: ", path)
      return(path)
    }
    if (attempt < attempts) Sys.sleep(2 * attempt)
  }
  if (file.exists(part)) unlink(part)
  stop("download failed after ", attempts, " attempts: ", url)
}

sha256 <- function(path) {
  value <- system2("shasum", c("-a", "256", path), stdout = TRUE, stderr = TRUE)
  status <- attr(value, "status")
  if (!is.null(status) && status != 0L) stop("could not hash ", path)
  sub("[[:space:]].*$", "", value[[1L]])
}

intersect_all <- function(x) {
  if (!length(x)) character() else Reduce(intersect, x)
}

kegg_genes_for_ko <- function(ko, frame_orgs) {
  path <- fetch(
    paste0("https://rest.kegg.jp/link/genes/ko:", ko),
    file.path("kegg", paste0(ko, ".tsv"))
  )
  lines <- readLines(path, warn = FALSE)
  lines <- lines[nzchar(lines)]
  if (!length(lines)) {
    return(data.frame(org = character(), gene_id = character(), stringsAsFactors = FALSE))
  }
  gene <- sub("^[^\t]+\t", "", lines)
  out <- data.frame(
    org = sub(":.*", "", gene), gene_id = gene, stringsAsFactors = FALSE
  )
  unique(out[out$org %in% frame_orgs, ])
}

read_tblout <- function(path) {
  lines <- grep("^#", readLines(path, warn = FALSE), value = TRUE, invert = TRUE)
  lines <- lines[nzchar(trimws(lines))]
  if (!length(lines)) {
    return(data.frame(target = character(), accession = character(), stringsAsFactors = FALSE))
  }
  fields <- strsplit(trimws(lines), "[[:space:]]+")
  unique(data.frame(
    target = vapply(fields, `[`, character(1), 1L),
    accession = vapply(fields, `[`, character(1), 4L),
    stringsAsFactors = FALSE
  ))
}

standing_band <- function(n) {
  if (is.na(n)) return("not_assessable")
  if (n < 20L) "below_20" else if (n < 50L) "defer_20_to_49" else "passes_50"
}

# ------------------------------------------------------------------------- frame

frame <- read_tsv(frame_path)
required_frame <- c("org", "assembly", "prokaryote")
if (!all(required_frame %in% names(frame))) {
  stop("stored genome frame lacks: ", paste(setdiff(required_frame, names(frame)), collapse = ", "))
}
frame <- frame[!duplicated(frame$org), ]
prokaryote <- as.logical(frame$prokaryote)
frame_orgs <- frame$org[!is.na(prokaryote) & prokaryote]
say("Stored frame: ", nrow(frame), " genomes; ", length(frame_orgs), " prokaryotic")

common <- c(
  "K02851", "K05946", "K01791", "K00980", "K21285", "K09692",
  "K09693", "K01005"
)
glycerol <- c(common, "K09809")
staph_ribitol <- c(common, "K21591", "K21030", "K05352", "K18704")
w23_ribitol <- c(common, "K21030", "K05352", "K21592", "K18704")
all_kos <- sort(unique(c(glycerol, staph_ribitol, w23_ribitol)))
ko_genes <- setNames(lapply(all_kos, kegg_genes_for_ko, frame_orgs = frame_orgs), all_kos)
ko_genomes <- lapply(ko_genes, function(x) unique(x$org))

proxy <- list(
  glycerol_168 = intersect_all(ko_genomes[glycerol]),
  ribitol_staphylococcus = intersect_all(ko_genomes[staph_ribitol]),
  ribitol_w23 = intersect_all(ko_genomes[w23_ribitol])
)
say(
  "KO proxy intersections: glycerol=", length(proxy$glycerol_168),
  "; Staphylococcus ribitol=", length(proxy$ribitol_staphylococcus),
  "; W23 ribitol=", length(proxy$ribitol_w23)
)

# ----------------------------------------------------------- NCBIfam metadata

ncbifam_root <- "https://ftp.ncbi.nlm.nih.gov/hmm/current"
metadata_path <- fetch(
  paste0(ncbifam_root, "/hmm_PGAP.tsv"), "ncbifam/hmm_PGAP.tsv"
)
notes_path <- fetch(
  paste0(ncbifam_root, "/RELEASE_NOTES.txt"), "ncbifam/RELEASE_NOTES.txt"
)
metadata <- read_tsv(metadata_path)
names(metadata)[[1L]] <- sub("^#", "", names(metadata)[[1L]])
notes <- readLines(notes_path, warn = FALSE)
release_line <- grep("Release number/name", notes, value = TRUE)
if (length(release_line) != 1L) stop("could not identify the NCBIfam release")
release <- trimws(sub(".*:", "", release_line))
if (!identical(release, "hmm_PGAP/20.0")) {
  stop("NCBIfam moved from the assessed release hmm_PGAP/20.0 to ", release)
}

profiles <- c("NF041712.1", "NF041713.1")
profile_meta <- metadata[match(profiles, metadata$ncbi_accession), ]
if (anyNA(profile_meta$ncbi_accession) || any(profile_meta$family_type != "equivalog")) {
  stop("the two Staphylococcus WTA discriminators are absent or no longer equivalogs")
}
profile_paths <- setNames(lapply(profiles, function(accession) {
  fetch(
    paste0(ncbifam_root, "/hmm_PGAP.HMM/", accession, ".HMM"),
    file.path("ncbifam", paste0(accession, ".HMM"))
  )
}), profiles)

# Search the exact polymerase proteins assigned to the two required KOs in the
# complete proxy subset. A broader KO or a Staphylococcus name is never used in
# place of either profile. Restricting the search to these already-required
# proteins cannot create a false positive; it only asks whether each KO protein
# also meets the equivalog's curated gathering threshold.
candidate_orgs <- proxy$ribitol_staphylococcus
role <- list(
  NF041712.1 = ko_genes[["K21591"]][ko_genes[["K21591"]]$org %in% candidate_orgs, ],
  NF041713.1 = ko_genes[["K18704"]][ko_genes[["K18704"]]$org %in% candidate_orgs, ]
)
if (any(vapply(role, nrow, integer(1)) == 0L)) stop("a polymerase role has no KEGG genes")

hmmsearch <- Sys.which("hmmsearch")
if (!nzchar(hmmsearch)) hmmsearch <- "/opt/miniconda3/bin/hmmsearch"
if (!file.exists(hmmsearch)) stop("HMMER hmmsearch is required")

scan_role <- function(accession, genes) {
  ids <- sort(unique(genes$gene_id))
  chunks <- split(ids, ceiling(seq_along(ids) / 10L))
  hit_ids <- character()
  for (i in seq_along(chunks)) {
    block <- chunks[[i]]
    label <- paste0(
      sprintf("%03d", i), "-", gsub("[^A-Za-z0-9_.-]", "_", block[[1L]]),
      "-", gsub("[^A-Za-z0-9_.-]", "_", block[[length(block)]]), ".faa"
    )
    faa <- fetch(
      paste0("https://rest.kegg.jp/get/", paste(block, collapse = "+"), "/aaseq"),
      file.path("kegg-aaseq", accession, label)
    )
    tblout <- tempfile(fileext = ".tblout")
    status <- system2(
      hmmsearch,
      c(
        "--noali", "--cpu", as.character(threads), "--cut_ga", "--tblout",
        tblout, profile_paths[[accession]], faa
      ),
      stdout = FALSE, stderr = FALSE
    )
    if (!identical(status, 0L)) stop("hmmsearch failed for ", accession, " batch ", i)
    table <- read_tblout(tblout)
    hit_ids <- union(hit_ids, table$target[table$accession == accession])
    unlink(tblout)
  }
  unique(genes$org[genes$gene_id %in% hit_ids])
}

role_hits <- Map(scan_role, names(role), role)
complete_orgs <- intersect_all(role_hits)
resolved_staph <- length(complete_orgs)
sequences_scanned <- sum(vapply(role, function(x) length(unique(x$gene_id)), integer(1)))
profile_hit_summary <- paste0(
  names(role_hits), "=", vapply(role_hits, length, integer(1)), collapse = ";"
)
say(
  "Marker-resolved Staphylococcus architecture: ", resolved_staph, " of ",
  length(candidate_orgs), " KO-proxy genomes (", sequences_scanned,
  " exact KO-assigned protein sequences)"
)
say("Profile-positive genomes: ", profile_hit_summary)
say("Marker-resolved failures: ", paste(setdiff(candidate_orgs, complete_orgs), collapse = ";"))

# --------------------------------------------------------------- aggregate outputs

prevalence <- data.frame(
  ncbifam_release = release,
  frame_genomes = nrow(frame),
  prokaryotic_frame_genomes = length(frame_orgs),
  candidate = c(
    "poly(glycerol-phosphate) WTA, 168-type",
    "poly(ribitol-phosphate) WTA, Staphylococcus-type",
    "poly(ribitol-phosphate) WTA, W23-type"
  ),
  ko_proxy_genomes = c(
    length(proxy$glycerol_168), length(proxy$ribitol_staphylococcus),
    length(proxy$ribitol_w23)
  ),
  ncbifam_profiles_required = c(
    "", paste(profiles, collapse = ";"), ""
  ),
  ncbifam_profile_positive_genomes = c("", profile_hit_summary, ""),
  candidate_gene_sequences_scanned = c(NA_integer_, sequences_scanned, NA_integer_),
  marker_resolved_complete_genomes = c(NA_integer_, resolved_staph, length(proxy$ribitol_w23)),
  standing_test = c(
    "not_assessable_marker_specificity",
    standing_band(resolved_staph), standing_band(length(proxy$ribitol_w23))
  ),
  result = c(
    "deferred: no equivalog separates the 168-type TagF polymerase from the W23 non-WTA homologue",
    if (resolved_staph >= 50L) "marker-resolved prevalence passes" else
      "standing prevalence band: below 50 genomes; curation disposition is recorded separately",
    if (length(proxy$ribitol_w23) >= 50L) "marker-resolved prevalence passes" else
      "standing prevalence band: complete TarK-plus-TarL architecture remains below 50 genomes; curation disposition is recorded separately"
  ),
  stringsAsFactors = FALSE
)

# Exhaustive metadata result for the 168-type TagF search. The broad domain is
# the only profile naming the activity; the other TagF equivalog is explicitly
# the S. aureus TarF primase from the separate ribitol architecture.
tagf_candidates <- metadata[
  metadata$ncbi_accession %in% c("NF016357.7", "NF041712.1"),
  c(
    "ncbi_accession", "family_type", "product_name", "gene_symbol",
    "taxonomic_range_name", "taxonomic_rank_name", "n_refseq_protein_hits",
    "source"
  )
]
tagf_candidates$licenses_168_type_tagf <- FALSE
tagf_candidates$decision <- ifelse(
  tagf_candidates$ncbi_accession == "NF016357.7",
  "refused: domain grade merges TagF-like primases and polymerases",
  "refused for this role: equivalog is the S. aureus TarF primase in ribitol-WTA synthesis"
)
tagf_candidates$ncbifam_release <- release
tagf_candidates$metadata_sha256 <- sha256(metadata_path)

prevalence_path <- file.path(out_dir, "wta-ncbifam-prevalence.tsv")
marker_path <- file.path(out_dir, "wta-tagf-marker-audit.tsv")
write_tsv(prevalence, prevalence_path)
write_tsv(tagf_candidates, marker_path)
say("Wrote ", prevalence_path)
say("Wrote ", marker_path)
