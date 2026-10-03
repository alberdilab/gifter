#!/usr/bin/env Rscript
# Exact KO/NCBIfam screen for the archaellum structural GIFT.
#
# Curation evidence for attempt GEA-20261003-ARCHAELLUM. The stored KEGG frame
# is KO-only, and two of the archaellum KOs are known to be shared with
# homologous machines: FlaI (K07332) and FlaJ (K07333) are the ATPase and
# platform of the archaellum, but archaeal type IV pili (Ups, Aap, bindosome,
# Haloferax PilB/PilC) use homologous ATPases and platforms. Rather than assume
# what those KOs collect, this script fetches every protein KEGG assigns to an
# archaellum KO in the frame and searches it with:
#
#   * the admitted NCBIfam equivalogs for the archaellum roles, and
#   * contrast profiles for the homologous pilus machines, which are used only
#     to name what a KO-assigned protein is when it is not an archaellum
#     protein. A contrast profile is never accepted as gifter evidence.
#
# Every search uses the profile's curated gathering threshold (--cut_ga), so a
# hit is the profile's own definition of family membership.
#
# The second half evaluates the curated `archaellum` architecture exactly as the
# source TSVs define it, with the frame's KO assignments as the observed
# markers, and reports prevalence over the archaeal and bacterial denominators
# of the KEGG organism hierarchy (br08601). The frame's `prokaryote` flag is a
# genus-name filter and admits eukaryotes, so it is never used as a denominator.
#
# Usage:
#   Rscript data-raw/archaellum_ncbifam_prevalence.R
#   Rscript data-raw/archaellum_ncbifam_prevalence.R --offline
#
# Downloaded KO links, HMMs and amino-acid sequences are cached and are not
# committed. Only aggregate results are written, because KEGG's per-genome
# assignments are not redistributable.

args <- commandArgs(trailingOnly = TRUE)
opt <- function(name, default) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit)) sub(paste0("^--", name, "="), "", hit[[1L]]) else default
}

cache_dir <- opt("cache", "data-raw/reference/.cache/archaellum")
out_dir <- opt("out", "data-raw/reference")
frame_path <- opt("frame", "manuscript/analysis/output/kegg-genome-set.tsv")
source_dir <- opt("source", "inst/extdata/database-source")
threads <- as.integer(opt("threads", "4"))
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
      Sys.sleep(0.35)
      return(path)
    }
    if (attempt < attempts) Sys.sleep(2 * attempt)
  }
  if (file.exists(part)) unlink(part)
  stop("download failed after ", attempts, " attempts: ", url)
}

kegg_genes_for_ko <- function(ko, frame_orgs) {
  path <- fetch(
    paste0("https://rest.kegg.jp/link/genes/ko:", ko),
    file.path("kegg", paste0(ko, ".tsv"))
  )
  lines <- readLines(path, warn = FALSE)
  lines <- lines[nzchar(lines)]
  gene <- sub("^[^\t]+\t", "", lines)
  out <- data.frame(
    ko = ko, org = sub(":.*", "", gene), gene_id = gene, stringsAsFactors = FALSE
  )
  unique(out[out$org %in% frame_orgs, ])
}

read_tblout <- function(path) {
  lines <- grep("^#", readLines(path, warn = FALSE), value = TRUE, invert = TRUE)
  lines <- lines[nzchar(trimws(lines))]
  if (!length(lines)) {
    return(data.frame(target = character(), profile = character(), score = numeric()))
  }
  fields <- strsplit(trimws(lines), "[[:space:]]+")
  data.frame(
    target = vapply(fields, `[`, character(1), 1L),
    profile = vapply(fields, `[`, character(1), 4L),
    score = as.numeric(vapply(fields, `[`, character(1), 6L)),
    stringsAsFactors = FALSE
  )
}

# ------------------------------------------------------------------------- frame

frame <- read_tsv(frame_path)
frame <- frame[!duplicated(frame$org), ]
prokaryote <- as.logical(frame$prokaryote)
frame_orgs <- frame$org[!is.na(prokaryote) & prokaryote]

htext <- readLines(fetch("https://rest.kegg.jp/get/br:br08601", "kegg/br08601.keg"), warn = FALSE)
level <- substr(htext, 1L, 1L)
label <- trimws(sub(" \\([0-9]+\\)$", "", substring(htext, 2L)))
carry <- function(which) {
  idx <- cumsum(level == which)
  c(NA_character_, label[level == which])[idx + 1L]
}
is_org <- level == "E"
org_code <- sub(" .*", "", label[is_org])
domain <- setNames(carry("B")[is_org], org_code)[frame_orgs]
phylum <- setNames(carry("C")[is_org], org_code)[frame_orgs]
order_ <- setNames(carry("D")[is_org], org_code)[frame_orgs]
names(domain) <- names(phylum) <- names(order_) <- frame_orgs
archaea <- frame_orgs[domain %in% "Archaea"]
bacteria <- frame_orgs[domain %in% "Bacteria"]
say(
  "Stored frame: ", length(frame_orgs), " flagged prokaryotic; KEGG hierarchy: ",
  length(archaea), " archaea, ", length(bacteria), " bacteria"
)

# ---------------------------------------------------------------- KO evidence

roles <- c(
  K07324 = "archaellin", K07325 = "archaellin", K07329 = "FlaF",
  K07330 = "FlaG", K07331 = "FlaH", K07332 = "FlaI", K07333 = "FlaJ",
  K07991 = "FlaK/PibD", K07822 = "FlaC", K07327 = "FlaD", K07328 = "FlaE",
  K23986 = "FlaCE"
)
ko_genes <- do.call(rbind, lapply(names(roles), kegg_genes_for_ko, frame_orgs = frame_orgs))
ko_genes$role <- unname(roles[ko_genes$ko])
ko_orgs <- lapply(split(ko_genes$org, ko_genes$ko), unique)

# The screen's six-function KO core, used only to partition genomes for the
# homology question. The curated architecture is evaluated separately below.
screen_core <- Reduce(intersect, list(
  union(ko_orgs$K07324, ko_orgs$K07325), ko_orgs$K07329, ko_orgs$K07330,
  ko_orgs$K07331, ko_orgs$K07332, ko_orgs$K07333
))
genome_class <- function(org) {
  ifelse(
    org %in% screen_core,
    ifelse(org %in% archaea, "archaea_with_ko_core", "bacteria_with_ko_core"),
    ifelse(org %in% archaea, "archaea_without_ko_core",
      ifelse(org %in% bacteria, "bacteria_without_ko_core", "not_prokaryote"))
  )
}
ko_genes$genome_class <- genome_class(ko_genes$org)
say("KO-assigned proteins in the frame: ", nrow(ko_genes))

# ------------------------------------------------------------ NCBIfam profiles

ncbifam_root <- "https://ftp.ncbi.nlm.nih.gov/hmm/current"
metadata_path <- fetch(paste0(ncbifam_root, "/hmm_PGAP.tsv"), "ncbifam/hmm_PGAP.tsv")
notes_path <- fetch(paste0(ncbifam_root, "/RELEASE_NOTES.txt"), "ncbifam/RELEASE_NOTES.txt")
metadata <- read_tsv(metadata_path)
names(metadata)[[1L]] <- sub("^#", "", names(metadata)[[1L]])
notes <- readLines(notes_path, warn = FALSE)
release <- trimws(sub(".*:", "", grep("Release number/name", notes, value = TRUE)))
if (!identical(release, "hmm_PGAP/20.0")) {
  stop("NCBIfam moved from the assessed release hmm_PGAP/20.0 to ", release)
}

# `use = "candidate"` profiles are archaellum equivalogs considered for
# admission; `use = "contrast"` profiles name homologous pilus machinery or are
# broad families, and are searched only to identify what a KO protein is. The
# Pfam-derived NCBIfam entries are not distributed as NCBIfam HMMs, so the two
# Pfam contrasts needed for the archaellin question are taken from InterPro.
profiles <- data.frame(
  accession = c(
    "NF058587.1", "NF004703.2", "NF004704.2", "NF004705.1", "NF052589.1",
    "NF052590.1", "NF052591.1", "NF040695.1", "NF058591.1",
    "NF053826.1", "NF046075.1", "NF053672.1", "NF053673.1", "TIGR02537.2"
  ),
  role = c(
    "FlaI", "FlaJ", "FlaJ", "FlaJ", "FlaH", "FlaF", "FlaG", "FlaK/PibD", "FlaX",
    "pilin peptidase EppA", "pilus platform UpsF", "bindosome ATPase BasE",
    "bindosome platform BasF", "archaellin/type IV pilin N-terminus"
  ),
  use = c(rep("candidate", 9L), rep("contrast", 5L)),
  stringsAsFactors = FALSE
)
meta <- metadata[match(profiles$accession, metadata$ncbi_accession), ]
if (anyNA(meta$ncbi_accession)) {
  stop("profiles absent from ", release, ": ",
       paste(profiles$accession[is.na(meta$ncbi_accession)], collapse = ", "))
}
profiles <- cbind(profiles, meta[c(
  "family_type", "product_name", "gene_symbol", "taxonomic_range_name",
  "taxonomic_rank_name", "n_refseq_protein_hits", "pmids"
)])
profiles$source <- release

profile_paths <- vapply(profiles$accession, function(accession) {
  fetch(
    paste0(ncbifam_root, "/hmm_PGAP.HMM/", accession, ".HMM"),
    file.path("ncbifam", paste0(accession, ".HMM"))
  )
}, character(1))

pfam <- data.frame(
  accession = c("PF01917", "PF13144"),
  role = c("archaellin (Pfam)", "bacterial FlgA P-ring chaperone (Pfam)"),
  use = "contrast", family_type = "Pfam family",
  product_name = c("Archaeal-type flagellin", "Chaperone for flagella basal body P-ring formation"),
  gene_symbol = c("", "flgA"), taxonomic_range_name = "", taxonomic_rank_name = "",
  n_refseq_protein_hits = NA_integer_, pmids = "", source = "InterPro Pfam",
  stringsAsFactors = FALSE
)
pfam_paths <- vapply(pfam$accession, function(accession) {
  gz <- fetch(
    paste0("https://www.ebi.ac.uk/interpro/api/entry/pfam/", accession, "/?annotation=hmm"),
    file.path("pfam", paste0(accession, ".hmm.gz"))
  )
  lines <- readLines(gzfile(gz), warn = FALSE)
  pfam$accession[pfam$accession == accession] <<- sub("^ACC +", "", grep("^ACC", lines, value = TRUE))
  path <- sub("\\.gz$", "", gz)
  writeLines(lines, path)
  path
}, character(1))
profiles <- rbind(profiles, pfam)
profile_paths <- c(profile_paths, pfam_paths)
profile_db <- file.path(cache_dir, "ncbifam", "archaellum-profiles.hmm")
writeLines(unlist(lapply(profile_paths, readLines, warn = FALSE)), profile_db)

# ---------------------------------------------------------------- sequences

ids <- sort(unique(ko_genes$gene_id))
chunks <- split(ids, ceiling(seq_along(ids) / 10L))
faa_paths <- vapply(seq_along(chunks), function(i) {
  block <- chunks[[i]]
  label <- paste0(
    sprintf("%04d", i), "-", gsub("[^A-Za-z0-9_.-]", "_", block[[1L]]), ".faa"
  )
  fetch(
    paste0("https://rest.kegg.jp/get/", paste(block, collapse = "+"), "/aaseq"),
    file.path("kegg-aaseq", label)
  )
}, character(1))
all_faa <- file.path(cache_dir, "kegg-aaseq", "all.faa")
writeLines(unlist(lapply(faa_paths, readLines, warn = FALSE)), all_faa)
fetched <- sub("^>([^ ]+).*", "\\1", grep("^>", readLines(all_faa, warn = FALSE), value = TRUE))
say("Protein sequences fetched: ", length(unique(fetched)), " of ", length(ids))

hmmsearch <- Sys.which("hmmsearch")
if (!nzchar(hmmsearch)) hmmsearch <- "/opt/miniconda3/bin/hmmsearch"
if (!file.exists(hmmsearch)) stop("HMMER hmmsearch is required")
tblout <- file.path(cache_dir, "hmmsearch.tblout")
status <- system2(
  hmmsearch,
  c("--noali", "--cpu", as.character(threads), "--cut_ga", "--tblout", tblout,
    profile_db, all_faa),
  stdout = FALSE, stderr = FALSE
)
if (!identical(status, 0L)) stop("hmmsearch failed")
hits <- read_tblout(tblout)
hits <- hits[order(hits$target, -hits$score, hits$profile), ]

# Best-scoring profile per protein, separately over candidate and contrast
# profiles, so a protein's archaellum assignment and its best non-archaellum
# explanation are both visible.
best_of <- function(which) {
  h <- hits[hits$profile %in% profiles$accession[profiles$use == which], ]
  h <- h[!duplicated(h$target), ]
  setNames(h$profile, h$target)
}
best_candidate <- best_of("candidate")
best_contrast <- best_of("contrast")
ko_genes$fetched <- ko_genes$gene_id %in% fetched
ko_genes$candidate_hit <- unname(best_candidate[ko_genes$gene_id])
ko_genes$contrast_hit <- unname(best_contrast[ko_genes$gene_id])
profile_role <- setNames(profiles$role, profiles$accession)
ko_genes$candidate_role <- unname(profile_role[ko_genes$candidate_hit])
# A protein agrees with its KO when its best candidate profile is an equivalog
# for the KO's own role.
ko_genes$agrees <- !is.na(ko_genes$candidate_role) & ko_genes$candidate_role == ko_genes$role

agreement <- aggregate(
  cbind(proteins = rep(1L, nrow(ko_genes))) ~ ko + role + genome_class +
    candidate_hit + contrast_hit,
  data = transform(
    ko_genes,
    candidate_hit = ifelse(is.na(candidate_hit), "none", candidate_hit),
    contrast_hit = ifelse(is.na(contrast_hit), "none", contrast_hit)
  ),
  FUN = sum
)
genome_counts <- aggregate(
  org ~ ko + role + genome_class + candidate_hit + contrast_hit,
  data = transform(
    ko_genes,
    candidate_hit = ifelse(is.na(candidate_hit), "none", candidate_hit),
    contrast_hit = ifelse(is.na(contrast_hit), "none", contrast_hit)
  ),
  FUN = function(x) length(unique(x))
)
names(genome_counts)[names(genome_counts) == "org"] <- "genomes"
agreement <- merge(agreement, genome_counts, sort = FALSE)
agreement <- agreement[order(agreement$ko, agreement$genome_class, -agreement$proteins), ]
agreement$ncbifam_release <- release

# Per genome and role: does at least one KO-assigned protein pass the role's
# own equivalog? This is the genome-level KO/NCBIfam agreement.
role_genome <- unique(ko_genes[c("role", "org", "genome_class")])
role_genome$any_protein_agrees <- vapply(seq_len(nrow(role_genome)), function(i) {
  any(ko_genes$agrees[ko_genes$role == role_genome$role[[i]] &
                        ko_genes$org == role_genome$org[[i]]])
}, logical(1))
role_summary <- aggregate(
  cbind(genomes = 1L, genomes_with_agreeing_protein = as.integer(any_protein_agrees)) ~
    role + genome_class,
  data = role_genome, FUN = sum
)
role_summary <- role_summary[order(role_summary$role, role_summary$genome_class), ]

save_state <- file.path(cache_dir, "screen-state.rds")
saveRDS(list(
  ko_genes = ko_genes, profiles = profiles, domain = domain, phylum = phylum,
  order = order_, archaea = archaea, bacteria = bacteria, screen_core = screen_core,
  release = release
), save_state)

write_tsv(agreement, file.path(out_dir, "archaellum-ko-ncbifam-agreement.tsv"))
write_tsv(role_summary, file.path(out_dir, "archaellum-role-agreement.tsv"))
write_tsv(profiles, file.path(out_dir, "archaellum-ncbifam-profiles.tsv"))
say("Wrote archaellum-ko-ncbifam-agreement.tsv, archaellum-role-agreement.tsv and archaellum-ncbifam-profiles.tsv")

# ------------------------------------------- curated architecture prevalence
#
# The curated `archaellum` hierarchy is read from the source TSVs, so this
# section measures what the database claims rather than a proxy written here.
# Observed markers are the frame's KO assignments only: the frame carries no
# NCBIfam annotation, so NCBIfam markers cannot add a frame call and the
# accepted equivalogs are audited above against KO-assigned proteins instead.

`%||%` <- function(x, y) if (is.null(x)) y else x

gift_id <- "archaellum"
src <- function(name) read_tsv(file.path(source_dir, paste0(name, ".tsv")))
arch <- src("gift_architectures")
arch <- arch[arch$gift_id == gift_id, ]
af <- src("architecture_functions")
af <- af[af$architecture_id %in% arch$architecture_id, ]
systems <- src("structural_systems")
systems <- systems[systems$function_id %in% af$function_id, ]
components <- src("structural_components")
components <- components[components$system_id %in% systems$system_id, ]
evidence <- src("structural_component_markers")
evidence <- evidence[evidence$component_id %in% components$component_id, ]
ko_evidence <- evidence[evidence$namespace == "KO", ]

frame_kos <- sort(unique(ko_evidence$accession))
extra <- setdiff(frame_kos, unique(ko_genes$ko))
extra_genes <- do.call(rbind, lapply(extra, kegg_genes_for_ko, frame_orgs = frame_orgs))
marker_orgs <- c(
  lapply(split(ko_genes$org, ko_genes$ko), unique),
  lapply(split(extra_genes$org, extra_genes$ko), unique)
)[frame_kos]
candidates <- unique(unlist(marker_orgs, use.names = FALSE))

# ANY marker -> component, ALL components -> system, ANY system -> function.
component_orgs <- lapply(split(ko_evidence$accession, ko_evidence$component_id), function(kos) {
  unique(unlist(marker_orgs[kos], use.names = FALSE))
})
system_orgs <- lapply(split(components$component_id, components$system_id), function(ids) {
  Reduce(intersect, lapply(ids, function(id) component_orgs[[id]] %||% character()))
})
function_orgs <- lapply(split(systems$system_id, systems$function_id), function(ids) {
  unique(unlist(system_orgs[ids], use.names = FALSE))
})
required <- af$function_id[af$required == 1L]
accessory <- af$function_id[af$required == 0L]
support <- vapply(required, function(f) candidates %in% function_orgs[[f]], logical(length(candidates)))
rownames(support) <- candidates
n_missing <- rowSums(!support)
complete <- candidates[n_missing == 0L]
one_short <- candidates[n_missing == 1L]
missing_fn <- setNames(
  vapply(one_short, function(o) colnames(support)[!support[o, ]], character(1)), one_short
)

lineage <- function(orgs) paste(domain[orgs], phylum[orgs], order_[orgs], sep = " / ")
tab <- function(x) {
  t <- sort(table(x), decreasing = TRUE)
  paste0(names(t), "=", as.integer(t), collapse = "; ")
}
prevalence <- data.frame(
  gift_id = gift_id,
  architecture_id = paste(arch$architecture_id, collapse = ";"),
  required_functions = length(required),
  frame_archaea = length(archaea), frame_bacteria = length(bacteria),
  complete_archaea = sum(complete %in% archaea),
  complete_bacteria = sum(complete %in% bacteria),
  one_short_archaea = sum(one_short %in% archaea),
  one_short_bacteria = sum(one_short %in% bacteria),
  one_short_missing_function = tab(missing_fn),
  complete_by_lineage = tab(lineage(complete)),
  stringsAsFactors = FALSE
)
one_short_rows <- if (length(one_short)) {
  aggregate(
    genomes ~ missing_function + lineage,
    data = data.frame(missing_function = unname(missing_fn), lineage = lineage(one_short), genomes = 1L),
    FUN = sum
  )
} else {
  data.frame(missing_function = character(), lineage = character(), genomes = integer())
}
one_short_rows <- one_short_rows[order(one_short_rows$missing_function, -one_short_rows$genomes), ]

# Accessory functions never change the call; report how often each is
# supported among complete genomes, by lineage, so their lineage restriction is
# visible.
accessory_rows <- do.call(rbind, lapply(accessory, function(f) {
  data.frame(
    function_id = f,
    complete_genomes = length(complete),
    complete_with_accessory = sum(complete %in% function_orgs[[f]]),
    by_lineage = tab(lineage(intersect(complete, function_orgs[[f]] %||% character()))),
    stringsAsFactors = FALSE
  )
}))

# Named controls, re-read from KEGG and evaluated by gifter itself; the
# expectation is from the literature, never from the result.
controls <- data.frame(
  org = c("mmp", "sai", "hvo", "eco", "bsu"),
  strain = c(
    "Methanococcus maripaludis S2", "Sulfolobus acidocaldarius DSM 639",
    "Haloferax volcanii DS2", "Escherichia coli K-12 MG1655",
    "Bacillus subtilis 168"
  ),
  literature_expectation = c("archaellated", "archaellated", "archaellated", "flagellated bacterium", "flagellated bacterium"),
  stringsAsFactors = FALSE
)
if (requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(".", quiet = TRUE)
} else {
  library(gifter)
}
control_rows <- do.call(rbind, lapply(seq_len(nrow(controls)), function(i) {
  org <- controls$org[[i]]
  links <- readLines(fetch(paste0("https://rest.kegg.jp/link/ko/", org), file.path("kegg", paste0("genome-", org, ".tsv"))), warn = FALSE)
  links <- links[nzchar(links)]
  annotations <- data.frame(
    gene_id = sub("\t.*", "", links), namespace = "KO",
    accession = sub("^.*\tko:", "", links), stringsAsFactors = FALSE
  )
  result <- evaluate_gifts(annotations)
  call <- result$structural$gifts[
    result$structural$gifts$gift_id %in% c(gift_id, "flagellar_apparatus", "type_iva_pilus"),
  ]
  fns <- result$structural$functions
  a <- call[call$gift_id == gift_id, ]
  data.frame(
    controls[i, ],
    archaellum_complete = a$complete,
    archaellum_confidence = ifelse(a$complete, a$evidence_confidence, ""),
    archaellum_missing_functions = paste(a$missing_functions_best_architecture[[1]], collapse = ";"),
    supported_accessory = paste(intersect(accessory, fns$function_id[fns$supported]), collapse = ";"),
    flagellar_apparatus_complete = call$complete[call$gift_id == "flagellar_apparatus"],
    type_iva_pilus_complete = call$complete[call$gift_id == "type_iva_pilus"],
    agrees_with_frame_evaluator = a$complete == (org %in% complete) || !(org %in% frame_orgs),
    stringsAsFactors = FALSE
  )
}))
if (!all(control_rows$agrees_with_frame_evaluator)) {
  stop("the TSV evaluator and evaluate_gifts() disagree on a control genome")
}

say(
  "Curated archaellum: ", prevalence$complete_archaea, " of ", length(archaea),
  " archaea and ", prevalence$complete_bacteria, " of ", length(bacteria),
  " bacteria complete; ", length(one_short), " genomes one function short (",
  prevalence$one_short_missing_function, ")"
)

write_tsv(prevalence, file.path(out_dir, "archaellum-prevalence.tsv"))
write_tsv(one_short_rows, file.path(out_dir, "archaellum-one-short.tsv"))
write_tsv(accessory_rows, file.path(out_dir, "archaellum-accessory.tsv"))
write_tsv(control_rows, file.path(out_dir, "archaellum-controls.tsv"))
say("Wrote archaellum-prevalence.tsv, archaellum-one-short.tsv, archaellum-accessory.tsv and archaellum-controls.tsv")
