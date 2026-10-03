#!/usr/bin/env Rscript
# Prevalence and specificity screen for the type II secretion system.
#
# The T2SS was deferred by the 2026-10-03 machine screen pending the
# shared-component rule, because its prepilin peptidase is not a homologue of
# the type IVa pilus peptidase but literally the same enzyme, and KEGG files
# most of them under PilD rather than GspO. With that rule settled, the open
# curation questions are quantitative:
#
#   1. Does the Gsp inventory identify a machine distinct from the type IVa
#      pilus, or does it mostly mark genomes that carry the pilus? The two
#      proxies are intersected to answer it.
#   2. Does the shared peptidase do any of the discriminating work? The Gsp
#      proxy is counted with and without it. If the count barely moves, the
#      peptidase is a shared component carrying no specificity, which is what
#      the rule predicts.
#   3. Which function do near-complete genomes lack, and is it one weak
#      component or a spread?
#
# Usage:
#   Rscript data-raw/t2ss_prevalence.R
#   Rscript data-raw/t2ss_prevalence.R --offline
#
# Downloaded KO links and protein sets are cached and are not committed. Only
# aggregate results and named reference strains are written, because KEGG's
# per-genome assignments are not redistributable.

args <- commandArgs(trailingOnly = TRUE)
opt <- function(name, default) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit)) sub(paste0("^--", name, "="), "", hit[[1L]]) else default
}

cache_dir <- opt("cache", "data-raw/reference/.cache/t2ss")
out_dir <- opt("out", "data-raw/reference")
frame_path <- opt("frame", "manuscript/analysis/output/kegg-genome-set.tsv")
threads <- as.integer(opt("threads", "2"))
offline <- "--offline" %in% args

dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

say <- function(...) cat(..., "\n", sep = "")
read_tsv <- function(path, ...) {
  utils::read.delim(
    path, quote = "", comment.char = "", stringsAsFactors = FALSE,
    check.names = FALSE, ...
  )
}
write_tsv <- function(x, path) {
  utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = "")
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
      error = function(e) 1L, warning = function(w) 1L
    )
    if (identical(status, 0L) && file.exists(part) && file.size(part) > 0) {
      if (!file.rename(part, path)) stop("could not install downloaded input: ", path)
      Sys.sleep(0.35)
      return(path)
    }
    if (attempt < attempts) Sys.sleep(2 * attempt)
  }
  if (file.exists(part)) unlink(part)
  stop("download failed after ", attempts, " attempts: ", url)
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

hmmsearch <- Sys.which("hmmsearch")
if (!nzchar(hmmsearch)) hmmsearch <- "/opt/miniconda3/bin/hmmsearch"
if (!file.exists(hmmsearch)) stop("HMMER hmmsearch is required")

# --------------------------------------------------------------------- models

# The curated T2SS inventory. The peptidase is listed last and separately,
# because it is the shared component under test rather than a discriminator.
t2ss_core <- list(
  GspC = "K02452", GspD = "K02453", GspE = "K02454", GspF = "K02455",
  GspG = "K02456", GspH = "K02457", GspI = "K02458", GspJ = "K02459",
  GspK = "K02460", GspL = "K02461", GspM = "K02462"
)
t2ss_peptidase <- c("K02464", "K02654")

# The curated type IVa pilus required inventory, from the database. The pilus
# is the machine the T2SS must be distinguished from.
t4ap_core <- list(
  pilin = c("K02650", "K02655"), PilB_or_PilF = c("K02652", "K02656"),
  PilC = "K02653", PilM = "K02662", PilN = "K02663", PilO = "K02664",
  PilP = "K02665", PilQ = "K02666"
)
t4ap_peptidase <- "K02654"

equivalogs <- c(
  GspC = "TIGR01713.1", GspD = "TIGR02517.1", GspE = "TIGR02533.1",
  GspF = "TIGR02120.1", GspG = "TIGR01710.1", GspH = "TIGR01708.2",
  GspI = "TIGR01707.1", GspJ = "TIGR01711.1", GspK = "NF037980.1",
  GspL = "TIGR01709.2", GspM = "NF040576.1"
)

# ----------------------------------------------------------------------- frame

frame <- read_tsv(frame_path)
frame <- frame[!duplicated(frame$org), ]
prokaryote <- as.logical(frame$prokaryote)
frame_orgs <- frame$org[!is.na(prokaryote) & prokaryote]
say("Stored frame: ", nrow(frame), " genomes; ", length(frame_orgs), " prokaryotic")

kegg_genes_for_ko <- function(ko) {
  path <- fetch(
    paste0("https://rest.kegg.jp/link/genes/ko:", ko),
    file.path("kegg", paste0(ko, ".tsv"))
  )
  lines <- readLines(path, warn = FALSE)
  lines <- lines[nzchar(lines)]
  gene <- sub("^[^\t]+\t", "", lines)
  out <- data.frame(org = sub(":.*", "", gene), gene_id = gene, stringsAsFactors = FALSE)
  unique(out[out$org %in% frame_orgs, ])
}

all_kos <- sort(unique(c(
  unlist(t2ss_core), t2ss_peptidase, unlist(t4ap_core), t4ap_peptidase
)))
ko_genes <- setNames(lapply(all_kos, kegg_genes_for_ko), all_kos)
has_any <- function(kos) frame_orgs %in% unique(unlist(lapply(ko_genes[kos], `[[`, "org")))

present <- function(model) {
  out <- vapply(model, has_any, logical(length(frame_orgs)))
  dimnames(out) <- list(frame_orgs, names(model))
  out
}
t2ss_matrix <- present(t2ss_core)
t4ap_matrix <- present(t4ap_core)
named <- function(x) setNames(x, frame_orgs)
peptidase <- named(has_any(t2ss_peptidase))
gspo_only <- named(has_any("K02464"))
pild_only <- named(has_any("K02654"))

t2ss_core_complete <- rowSums(t2ss_matrix) == ncol(t2ss_matrix)
t2ss_complete <- t2ss_core_complete & peptidase
t4ap_complete <- rowSums(t4ap_matrix) == ncol(t4ap_matrix) & pild_only

say(
  "T2SS core complete: ", sum(t2ss_core_complete),
  "; with the shared peptidase: ", sum(t2ss_complete),
  "; type IVa pilus complete: ", sum(t4ap_complete)
)

# --------------------------------------------------- specificity against T4aP

found <- rowSums(t2ss_matrix)
n <- ncol(t2ss_matrix)
one_short <- t2ss_matrix[found == n - 1L, , drop = FALSE]
missing <- sort(colSums(!one_short), decreasing = TRUE)
missing <- missing[missing > 0L]

prevalence <- data.frame(
  prokaryotic_frame_genomes = length(frame_orgs),
  required_gsp_roles = n,
  genomes_with_no_gsp_role = sum(found == 0L),
  genomes_one_short = sum(found == n - 1L),
  genomes_two_short = sum(found == n - 2L),
  t2ss_core_complete = sum(t2ss_core_complete),
  t2ss_complete_with_peptidase = sum(t2ss_complete),
  peptidase_cost_in_genomes = sum(t2ss_core_complete) - sum(t2ss_complete),
  t4ap_complete = sum(t4ap_complete),
  complete_both = sum(t2ss_complete & t4ap_complete),
  t2ss_without_t4ap = sum(t2ss_complete & !t4ap_complete),
  t4ap_without_t2ss = sum(t4ap_complete & !t2ss_complete),
  peptidase_gspo_genomes = sum(gspo_only),
  peptidase_pild_genomes = sum(pild_only),
  peptidase_both_genomes = sum(gspo_only & pild_only),
  t2ss_complete_resting_on_pild_only = sum(t2ss_complete & pild_only & !gspo_only),
  one_short_missing_role = paste0(names(missing), "=", missing, collapse = ";"),
  stringsAsFactors = FALSE
)
say(
  "T2SS complete without the pilus: ", prevalence$t2ss_without_t4ap,
  "; pilus without the T2SS: ", prevalence$t4ap_without_t2ss,
  "; both: ", prevalence$complete_both
)
say("Weakest Gsp roles: ", prevalence$one_short_missing_role)

roles <- data.frame(
  role = names(t2ss_core),
  ko = unlist(t2ss_core, use.names = FALSE),
  ncbifam_equivalog = unname(equivalogs[names(t2ss_core)]),
  frame_genomes_with_ko = unname(colSums(t2ss_matrix)),
  stringsAsFactors = FALSE
)
roles <- rbind(roles, data.frame(
  role = "prepilin peptidase (shared component)",
  ko = paste(t2ss_peptidase, collapse = ";"),
  ncbifam_equivalog = "",
  frame_genomes_with_ko = sum(peptidase),
  stringsAsFactors = FALSE
))

# --------------------------------------------------------------- named strains

# `expect` is what the strain is established to encode. It is compared with the
# marker result and never used to produce it; `unverified` marks a strain whose
# expectation was not checked.
controls <- read.table(text = "
org	expect_t2ss	note
vch	yes	Eps system secreting cholera toxin
pae	yes	Xcp system
eco	yes	cryptic but complete gsp cluster in K-12
xcc	yes	Xps and Xcs systems
lpn	yes	Lsp system
aha	yes	Aeromonas Exe system
dze	yes	Dickeya Out system secreting plant cell wall enzymes
ecs	unverified	Enterobacterial gsp cluster
kox	unverified	Klebsiella michiganensis, a Klebsiella oxytoca relative
bsu	no	monoderm; no type II secretion system
cje	no	no type II secretion system
hpy	no	no type II secretion system
", header = TRUE, sep = "\t", quote = "", stringsAsFactors = FALSE)
controls <- controls[controls$org %in% frame_orgs, ]

control_rows <- do.call(rbind, lapply(seq_len(nrow(controls)), function(i) {
  org <- controls$org[[i]]
  by_ko <- t2ss_matrix[org, ]
  assembly <- frame$assembly[frame$org == org]
  zip <- fetch(
    paste0(
      "https://api.ncbi.nlm.nih.gov/datasets/v2/genome/accession/", assembly,
      "/download?include_annotation_type=PROT_FASTA"
    ),
    file.path("proteomes", paste0(org, ".zip"))
  )
  member <- grep("protein\\.faa$", utils::unzip(zip, list = TRUE)$Name, value = TRUE)
  dir <- tempfile()
  faa <- utils::unzip(zip, files = member[[1L]], exdir = dir, junkpaths = TRUE)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  profile_hits <- unique(do.call(rbind, lapply(equivalogs, function(accession) {
    hmm <- fetch(
      paste0("https://ftp.ncbi.nlm.nih.gov/hmm/current/hmm_PGAP.HMM/", accession, ".HMM"),
      file.path("ncbifam", paste0(accession, ".HMM"))
    )
    tblout <- tempfile(fileext = ".tblout")
    on.exit(unlink(tblout), add = TRUE)
    status <- system2(
      hmmsearch,
      c("--noali", "--cpu", as.character(threads), "--cut_ga", "--tblout", tblout, hmm, faa),
      stdout = FALSE, stderr = FALSE
    )
    if (!identical(status, 0L)) stop("hmmsearch failed for ", accession)
    read_tblout(tblout)
  }))$accession)
  by_either <- by_ko | equivalogs[names(t2ss_core)] %in% profile_hits
  data.frame(
    org = org, strain = frame$name[frame$org == org],
    expect_t2ss = controls$expect_t2ss[[i]],
    gsp_roles_by_ko = sum(by_ko),
    gsp_roles_by_ko_or_ncbifam = sum(by_either),
    peptidase_marker = peptidase[[org]],
    complete_by_ko = all(by_ko) && peptidase[[org]],
    complete_by_ko_or_ncbifam = all(by_either) && peptidase[[org]],
    missing_roles = paste(names(t2ss_core)[!by_either], collapse = ";"),
    note = controls$note[[i]],
    stringsAsFactors = FALSE
  )
}))
say(
  "Controls: ", sum(control_rows$complete_by_ko_or_ncbifam & control_rows$expect_t2ss == "yes"),
  " of ", sum(control_rows$expect_t2ss == "yes"), " expected systems complete; ",
  sum(control_rows$expect_t2ss == "no" & control_rows$complete_by_ko_or_ncbifam),
  " complete where none is expected"
)

write_tsv(prevalence, file.path(out_dir, "t2ss-prevalence.tsv"))
write_tsv(roles, file.path(out_dir, "t2ss-roles.tsv"))
write_tsv(control_rows, file.path(out_dir, "t2ss-controls.tsv"))
say("Wrote three T2SS tables to ", out_dir)
