#!/usr/bin/env Rscript
# Marker and prevalence screen for type III and type VI secretion as structural
# GIFTs.
#
# Both candidates were deferred because an unordered marker set was thought
# unable to tell one secretion machine from its homologues: the injectisome from
# the flagellar export apparatus, and the type VI apparatus from phage-like
# contractile systems. This screen tests that objection directly instead of
# assuming it. It asks three questions of the stored KEGG frame:
#
#   1. Do the system-specific KO roles fire in genomes that carry only the
#      homologous machine? The flagellated, injectisome-free controls answer it.
#   2. Is completeness bimodal, or does the required set mostly measure
#      annotation depth? The distribution of roles per genome answers it.
#   3. Where a model organism fails one role, is the role absent or has KEGG
#      split it over differently named KOs? Searching the KO-assigned proteins
#      with the matching NCBIfam equivalog answers it.
#
# Usage:
#   Rscript data-raw/secretion_system_prevalence.R
#   Rscript data-raw/secretion_system_prevalence.R --offline
#
# Downloaded KO links, HMMs and amino-acid sequences are cached and are not
# committed. Only aggregate results and named reference-strain controls are
# written, because KEGG's per-genome assignments are not redistributable.

args <- commandArgs(trailingOnly = TRUE)
opt <- function(name, default) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit)) sub(paste0("^--", name, "="), "", hit[[1L]]) else default
}

cache_dir <- opt("cache", "data-raw/reference/.cache/secretion-systems")
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

search_profiles <- function(profile_paths, faa) {
  hits <- lapply(profile_paths, function(profile) {
    tblout <- tempfile(fileext = ".tblout")
    on.exit(unlink(tblout))
    status <- system2(
      hmmsearch,
      c("--noali", "--cpu", as.character(threads), "--cut_ga", "--tblout", tblout, profile, faa),
      stdout = FALSE, stderr = FALSE
    )
    if (!identical(status, 0L)) stop("hmmsearch failed for ", profile)
    read_tblout(tblout)
  })
  do.call(rbind, hits)
}

# ------------------------------------------------------------------------ models

# One row per component role. `required` follows the curated architecture;
# `ko` holds alternative accessions for the same role and `ncbifam` the
# equivalog-grade profiles accepted for it. `rejected_ko` records accessions
# examined for the role and refused.
role <- function(candidate, role, required, ko, ncbifam = character(), rejected_ko = character()) {
  list(
    candidate = candidate, role = role, required = required, ko = ko,
    ncbifam = ncbifam, rejected_ko = rejected_ko
  )
}

models <- list(
  role("type VI secretion apparatus (T6SS-i)", "TssA", TRUE, c("K11902", "K11910"), c("TIGR03362.1", "TIGR03363.1")),
  role("type VI secretion apparatus (T6SS-i)", "TssB", TRUE, "K11901", "TIGR03358.1"),
  role("type VI secretion apparatus (T6SS-i)", "TssC", TRUE, "K11900", "TIGR03355.1"),
  role("type VI secretion apparatus (T6SS-i)", "Hcp", TRUE, "K11903"),
  role("type VI secretion apparatus (T6SS-i)", "TssE", TRUE, c("K11897", "K11905", "K11919"), "TIGR03357.1"),
  role("type VI secretion apparatus (T6SS-i)", "TssF", TRUE, "K11896", "TIGR03359.1"),
  role("type VI secretion apparatus (T6SS-i)", "TssG", TRUE, "K11895", "TIGR03347.1"),
  role("type VI secretion apparatus (T6SS-i)", "VgrG", TRUE, "K11904"),
  role("type VI secretion apparatus (T6SS-i)", "TssK", TRUE, "K11893", "TIGR03353.2"),
  role("type VI secretion apparatus (T6SS-i)", "TssL", TRUE, "K11892", "NF005444.0"),
  role("type VI secretion apparatus (T6SS-i)", "TssM", TRUE, "K11891", "TIGR03348.1"),
  role("type VI secretion apparatus (T6SS-i)", "ClpV", TRUE, "K11907", "TIGR03345.1"),
  role("type VI secretion apparatus (T6SS-i)", "TssJ", FALSE, "K11906", "TIGR03352.1", rejected_ko = "K11918"),
  role("type III secretion injectisome", "SctC", TRUE, c("K03219", "K22504"), "TIGR02516.1"),
  role("type III secretion injectisome", "SctD", TRUE, c("K03220", "K22488"), c("TIGR02500.1", "TIGR02554.1")),
  role("type III secretion injectisome", "SctJ", TRUE, c("K03222", "K22505"), "TIGR02544.1"),
  role("type III secretion injectisome", "SctN", TRUE, c("K03224", "K22506"), "TIGR02546.1"),
  role("type III secretion injectisome", "SctQ", TRUE, "K03225", "TIGR02551.1"),
  role("type III secretion injectisome", "SctR", TRUE, c("K03226", "K22507"), "TIGR01102.1"),
  role("type III secretion injectisome", "SctS", TRUE, c("K03227", "K22508"), "TIGR01403.1"),
  role("type III secretion injectisome", "SctT", TRUE, c("K03228", "K22509"), "TIGR01401.1"),
  role("type III secretion injectisome", "SctU", TRUE, c("K03229", "K22510"), "TIGR01404.2"),
  role("type III secretion injectisome", "SctV", TRUE, "K03230", "TIGR01399.1"),
  role("type III secretion injectisome", "SctI", TRUE, c("K04053", "K22487", "K23661", "K18374"), "NF038054.1"),
  role("type III secretion injectisome", "SctF or Hrp pilin", TRUE, c("K03221", "K18375"), c("TIGR02105.1", "NF011854.0", "NF053530.1")),
  # Biologically required, and deliberately outside the curated required set:
  # no accepted marker reaches the Inv-Mxi-Spa and Esc families.
  role("type III secretion injectisome", "SctL", FALSE, "K03223", c("TIGR02499.1", "NF011850.0", "NF005392.0"))
)
candidate_of <- vapply(models, `[[`, character(1), "candidate")
role_of <- vapply(models, `[[`, character(1), "role")
required_of <- vapply(models, `[[`, logical(1), "required")

# The flagellar export apparatus: the homologue the injectisome must not be
# confused with.
flagellar_export <- c(
  FlhA = "K02400", FlhB = "K02401", FliF = "K02409", FliI = "K02412",
  FliP = "K02419", FliQ = "K02420", FliR = "K02421"
)

# ------------------------------------------------------------------------- frame

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
  unlist(lapply(models, `[[`, "ko")), unlist(lapply(models, `[[`, "rejected_ko")),
  flagellar_export
)))
ko_genes <- setNames(lapply(all_kos, kegg_genes_for_ko), all_kos)
has_any <- function(kos) frame_orgs %in% unique(unlist(lapply(ko_genes[kos], `[[`, "org")))

presence <- vapply(models, function(m) has_any(m$ko), logical(length(frame_orgs)))
dimnames(presence) <- list(frame_orgs, paste(candidate_of, role_of, sep = "|"))
flagellar_complete <- rowSums(vapply(
  flagellar_export, function(ko) has_any(ko), logical(length(frame_orgs))
)) == length(flagellar_export)

# ------------------------------------------------------------- frame prevalence

candidates <- unique(candidate_of)
prevalence <- do.call(rbind, lapply(candidates, function(candidate) {
  required <- presence[, candidate_of == candidate & required_of, drop = FALSE]
  n <- ncol(required)
  found <- rowSums(required)
  complete <- found == n
  one_short <- required[found == n - 1L, , drop = FALSE]
  missing <- sort(colSums(!one_short), decreasing = TRUE)
  missing <- missing[missing > 0L]
  data.frame(
    candidate = candidate,
    prokaryotic_frame_genomes = length(frame_orgs),
    required_roles = n,
    genomes_with_no_role = sum(found == 0L),
    genomes_with_1_to_half_roles = sum(found >= 1L & found <= n %/% 2L),
    genomes_two_short = sum(found == n - 2L),
    genomes_one_short = sum(found == n - 1L),
    complete_ko_genomes = sum(complete),
    one_short_missing_role = paste0(
      sub(".*\\|", "", names(missing)), "=", missing, collapse = ";"
    ),
    complete_with_flagellar_export = sum(complete & flagellar_complete),
    flagellar_export_without_any_role = sum(flagellar_complete & found == 0L),
    flagellar_export_genomes = sum(flagellar_complete),
    stringsAsFactors = FALSE
  )
}))
say("Complete KO architectures: ", paste0(
  prevalence$candidate, "=", prevalence$complete_ko_genomes, collapse = "; "
))

roles <- data.frame(
  candidate = candidate_of,
  role = role_of,
  required = required_of,
  ko = vapply(models, function(m) paste(m$ko, collapse = ";"), character(1)),
  ncbifam_equivalogs = vapply(models, function(m) paste(m$ncbifam, collapse = ";"), character(1)),
  frame_genomes_with_ko = unname(colSums(presence)),
  stringsAsFactors = FALSE
)

# ----------------------------------------------------------- NCBIfam metadata

ncbifam_root <- "https://ftp.ncbi.nlm.nih.gov/hmm/current"
metadata <- read_tsv(fetch(paste0(ncbifam_root, "/hmm_PGAP.tsv"), "ncbifam/hmm_PGAP.tsv"))
names(metadata)[[1L]] <- sub("^#", "", names(metadata)[[1L]])
notes <- readLines(fetch(paste0(ncbifam_root, "/RELEASE_NOTES.txt"), "ncbifam/RELEASE_NOTES.txt"), warn = FALSE)
release <- trimws(sub(".*:", "", grep("Release number/name", notes, value = TRUE)))
if (!identical(release, "hmm_PGAP/20.0")) {
  stop("NCBIfam moved from the assessed release hmm_PGAP/20.0 to ", release)
}
profiles <- sort(unique(unlist(lapply(models, `[[`, "ncbifam"))))
grade <- setNames(metadata$family_type[match(profiles, metadata$ncbi_accession)], profiles)
if (anyNA(grade) || !all(grade %in% c("equivalog", "equivalog_domain"))) {
  stop("a listed profile is absent or below equivalog grade: ", paste(profiles[is.na(grade) | !grade %in% c("equivalog", "equivalog_domain")], collapse = ", "))
}
profile_paths <- setNames(vapply(profiles, function(accession) {
  fetch(
    paste0(ncbifam_root, "/hmm_PGAP.HMM/", accession, ".HMM"),
    file.path("ncbifam", paste0(accession, ".HMM"))
  )
}, character(1)), profiles)

# ------------------------------------------- KO roles tested against equivalogs

# KEGG splits TssA, TssE and TssJ over several accessions, some named only
# "type VI secretion system protein". An accession is accepted for a role only
# if the proteins KEGG assigns to it pass that role's equivalog. A systematic
# sample of at most 100 frame proteins per accession keeps the request small
# and the result reproducible.
ko_tests <- list(
  K11902 = "TssA", K11910 = "TssA", K11897 = "TssE", K11905 = "TssE",
  K11919 = "TssE", K11906 = "TssJ", K11918 = "TssJ"
)
ko_audit <- do.call(rbind, lapply(names(ko_tests), function(ko) {
  model <- models[[which(role_of == ko_tests[[ko]] & grepl("type VI", candidate_of))]]
  ids <- sort(unique(ko_genes[[ko]]$gene_id))
  ids <- ids[unique(round(seq(1, length(ids), length.out = min(100L, length(ids)))))]
  chunks <- split(ids, ceiling(seq_along(ids) / 10L))
  passed <- character()
  for (i in seq_along(chunks)) {
    faa <- fetch(
      paste0("https://rest.kegg.jp/get/", paste(chunks[[i]], collapse = "+"), "/aaseq"),
      file.path("kegg-aaseq", ko, sprintf("%03d.faa", i))
    )
    passed <- union(passed, search_profiles(profile_paths[model$ncbifam], faa)$target)
  }
  rate <- length(passed) / length(ids)
  data.frame(
    accession = ko, role = ko_tests[[ko]],
    frame_proteins = length(unique(ko_genes[[ko]]$gene_id)),
    proteins_tested = length(ids),
    equivalogs = paste(model$ncbifam, collapse = ";"),
    proteins_passing = length(passed),
    decision = if (ko %in% model$ko) "accepted" else "refused",
    reason = if (ko %in% model$ko) {
      sprintf("%.0f%% of tested KO-assigned proteins pass the role equivalog", 100 * rate)
    } else {
      sprintf("%.0f%% of tested KO-assigned proteins pass the role equivalog; the role identity is not supported", 100 * rate)
    },
    stringsAsFactors = FALSE
  )
}))
say("KO-versus-equivalog audit: ", paste0(
  ko_audit$accession, "=", ko_audit$proteins_passing, "/", ko_audit$proteins_tested, collapse = "; "
))

# ---------------------------------------------------------------- named controls

# Reference strains. `expect` states what the strain is established to carry
# and is `unverified` where no expectation was checked; it is compared with,
# and never used to produce, the marker result.
controls <- read.table(text = "
org	expect_t6ss	expect_t3ss	note
pae	yes	yes	three T6SS loci and the Psc injectisome
ype	yes	yes	Ysc injectisome
stm	yes	yes	SPI-1 and SPI-2 injectisomes; SPI-6 T6SS
vch	yes	no	model T6SS; TssA and TssE sit under K11910 and K11905
atu	yes	no	functional T6SS with no TssJ marker in either namespace
aby	yes	no	Acinetobacter T6SS with no TssJ marker in either namespace
sfl	unverified	yes	Mxi-Spa injectisome; no accepted SctL marker reaches MxiN
ecg	unverified	yes	LEE injectisome; no accepted SctL marker reaches EscL
ecs	unverified	yes	LEE injectisome
pst	yes	yes	Hrp pilus injectisome; HrpA pilin has no KO
xcc	unverified	yes	Hrp pilus injectisome
bpe	unverified	yes	Bsc injectisome
rso	yes	yes	Hrp pilus injectisome; HrpY pilin has no accepted marker
ctr	no	yes	divergent chlamydial injectisome
eco	no	no	flagellated; neither machine
bsu	no	no	flagellated monoderm; neither machine
cje	no	no	flagellated; neither machine
", header = TRUE, sep = "\t", quote = "", stringsAsFactors = FALSE)
controls <- controls[controls$org %in% frame_orgs, ]

control_rows <- do.call(rbind, lapply(seq_len(nrow(controls)), function(i) {
  org <- controls$org[[i]]
  assembly <- frame$assembly[frame$org == org]
  zip <- fetch(
    paste0(
      "https://api.ncbi.nlm.nih.gov/datasets/v2/genome/accession/", assembly,
      "/download?include_annotation_type=PROT_FASTA"
    ),
    file.path("proteomes", paste0(org, ".zip"))
  )
  member <- grep("protein\\.faa$", utils::unzip(zip, list = TRUE)$Name, value = TRUE)
  if (length(member) != 1L) stop("no protein set in the NCBI package for ", org)
  dir <- tempfile()
  faa <- utils::unzip(zip, files = member, exdir = dir, junkpaths = TRUE)
  on.exit(unlink(dir, recursive = TRUE))
  profile_hits <- unique(search_profiles(profile_paths, faa)$accession)
  do.call(rbind, lapply(candidates, function(candidate) {
    use <- which(candidate_of == candidate & required_of)
    by_ko <- presence[org, use]
    by_either <- by_ko | vapply(models[use], function(m) any(m$ncbifam %in% profile_hits), logical(1))
    expectation <- if (grepl("type VI", candidate)) controls$expect_t6ss[[i]] else controls$expect_t3ss[[i]]
    data.frame(
      org = org, strain = frame$name[frame$org == org], candidate = candidate,
      literature_expectation = expectation,
      required_roles = length(use),
      roles_by_ko = sum(by_ko),
      roles_by_ko_or_ncbifam = sum(by_either),
      complete_by_ko = all(by_ko),
      complete_by_ko_or_ncbifam = all(by_either),
      missing_roles = paste(role_of[use][!by_either], collapse = ";"),
      note = controls$note[[i]],
      stringsAsFactors = FALSE
    )
  }))
}))
false_positive <- control_rows$literature_expectation == "no" & control_rows$complete_by_ko_or_ncbifam
say(
  "Controls: ", sum(control_rows$complete_by_ko_or_ncbifam & control_rows$literature_expectation == "yes"),
  " of ", sum(control_rows$literature_expectation == "yes"), " expected machines complete; ",
  sum(false_positive), " complete where none is expected"
)

# --------------------------------------------------------------- aggregate outputs

prevalence <- cbind(ncbifam_release = release, frame_genomes = nrow(frame), prevalence)
write_tsv(prevalence, file.path(out_dir, "secretion-system-prevalence.tsv"))
write_tsv(roles, file.path(out_dir, "secretion-system-roles.tsv"))
write_tsv(ko_audit, file.path(out_dir, "secretion-system-marker-audit.tsv"))
write_tsv(control_rows, file.path(out_dir, "secretion-system-controls.tsv"))
say("Wrote four secretion-system tables to ", out_dir)
