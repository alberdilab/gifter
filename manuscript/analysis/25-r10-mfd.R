#!/usr/bin/env Rscript
# R10b: distinct environmental communities from Microflora Danica.
#
# Preparation locks one deposited representative per 95% ANI species cluster
# and a habitat-balanced sample panel before annotation or GIFT calls are read.
# Drakkar supplies gene-resolved marker evidence; gifter evaluates immutable
# per-representative calls. Detection, abundance, habitat and genome quality can
# only change how those calls are read. Nothing here establishes activity,
# flux, substrate availability, realised interaction or ecological effect.
#
# From the repository root:
#   Rscript manuscript/analysis/25-r10-mfd.R --prepare
#   Rscript manuscript/analysis/25-r10-mfd.R

suppressWarnings(suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(readxl)
}))

root <- "manuscript/analysis"
case_dir <- file.path(root, "r10-mfd")
cache_dir <- Sys.getenv("R10_MFD_CACHE_DIR", file.path(root, ".cache", "r10-mfd"))
source_dir <- file.path(cache_dir, "sources")
remote_dir <- Sys.getenv("R10_MFD_REMOTE_DIR", file.path(cache_dir, "remote"))
output_dir <- Sys.getenv("R10_MFD_OUTPUT_DIR", file.path(root, "output"))
figure_dir <- Sys.getenv("R10_MFD_FIGURE_DIR", "manuscript/figures")
dir.create(source_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

source_manifest_path <- file.path(case_dir, "source-manifest.tsv")
habitat_design_path <- file.path(case_dir, "habitat-design.tsv")
representative_manifest_path <- file.path(case_dir, "representative-genomes.tsv")
selected_samples_path <- file.path(case_dir, "selected-samples.tsv")
design_audit_path <- file.path(case_dir, "design-audit.tsv")
archive_alias_path <- file.path(case_dir, "archive-aliases.tsv")

read_tsv <- function(path) {
  utils::read.delim(path, check.names = FALSE, stringsAsFactors = FALSE)
}

write_tsv <- function(x, path) {
  utils::write.table(
    x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = ""
  )
}

write_xz_tsv <- function(x, path) {
  connection <- xzfile(path, open = "wt", compression = 9)
  on.exit(close(connection), add = TRUE)
  write_tsv(x, connection)
}

read_xz_tsv <- function(path) {
  connection <- xzfile(path, open = "rt")
  on.exit(close(connection), add = TRUE)
  read_tsv(connection)
}

file_checksum <- function(path, algorithm = "sha256") {
  if (identical(algorithm, "md5")) {
    return(unname(tools::md5sum(path)))
  }
  if (!identical(algorithm, "sha256")) {
    stop("Unsupported checksum algorithm: ", algorithm, call. = FALSE)
  }
  command <- if (nzchar(Sys.which("shasum"))) "shasum" else "sha256sum"
  args <- if (identical(command, "shasum")) c("-a", "256", path) else path
  output <- system2(command, args, stdout = TRUE, stderr = TRUE)
  if (!length(output)) stop("Could not checksum ", path, call. = FALSE)
  sub("[[:space:]].*$", "", output[[1L]])
}

sha256 <- function(path) file_checksum(path, "sha256")

validate_source_manifest <- function(manifest) {
  expected <- c(
    "file", "source_url", "bytes", "checksum_algorithm", "checksum",
    "role", "local_prepare"
  )
  if (!identical(names(manifest), expected) || anyDuplicated(manifest$file) ||
      !all(manifest$checksum_algorithm %in% c("md5", "sha256")) ||
      !all(manifest$local_prepare %in% c(TRUE, FALSE))) {
    stop("source-manifest.tsv has an invalid schema or value", call. = FALSE)
  }
  invisible(manifest)
}

fetch_local_sources <- function(manifest) {
  local <- manifest[manifest$local_prepare, , drop = FALSE]
  paths <- file.path(source_dir, local$file)
  for (i in seq_len(nrow(local))) {
    path <- paths[[i]]
    if (!file.exists(path)) {
      message("fetching ", local$file[[i]])
      utils::download.file(local$source_url[[i]], path, mode = "wb")
    }
    if (file.info(path)$size != local$bytes[[i]]) {
      stop("Source byte count mismatch: ", local$file[[i]], call. = FALSE)
    }
    observed <- file_checksum(path, local$checksum_algorithm[[i]])
    if (!identical(observed, local$checksum[[i]])) {
      stop("Source checksum mismatch: ", local$file[[i]], call. = FALSE)
    }
  }
  stats::setNames(paths, local$file)
}

extract_support_files <- function(archive) {
  members <- c(
    "./Nitrifiers/data/mags_shallow_all.tsv",
    "./Nitrifiers/metadata/2023-10-11_samples_minimal_metadata_collapsed.csv",
    "./Nitrifiers/metadata/2025-02-19_mfd_db.xlsx"
  )
  paths <- file.path(source_dir, sub("^\\./", "", members))
  if (any(!file.exists(paths))) {
    utils::untar(archive, files = members, exdir = source_dir)
  }
  if (any(!file.exists(paths))) {
    stop("Could not extract the required Microflora Danica support files", call. = FALSE)
  }
  stats::setNames(paths, basename(paths))
}

read_abundance_header <- function(archive) {
  member <- "./Nitrifiers/data/MFD_SRnodrep_tax_relative_abundance.tsv"
  command <- paste(
    "tar -xOf", shQuote(archive), shQuote(member),
    "2>/dev/null | head -n 1"
  )
  header <- suppressWarnings(system(command, intern = TRUE))
  if (length(header) != 1L || !nzchar(header)) {
    stop("Could not read the published abundance header", call. = FALSE)
  }
  fields <- strsplit(header, "\t", fixed = TRUE)[[1L]]
  if (length(fields) != 10508L || fields[[1L]] != "clade_name") {
    stop("Published abundance table no longer has 10,507 sample columns", call. = FALSE)
  }
  fields[-1L]
}

great_circle_matrix <- function(latitude, longitude) {
  radius_km <- 6371.0088
  latitude <- latitude * pi / 180
  longitude <- longitude * pi / 180
  delta_latitude <- outer(latitude, latitude, "-")
  delta_longitude <- outer(longitude, longitude, "-")
  haversine <- sin(delta_latitude / 2)^2 +
    outer(cos(latitude), cos(latitude), "*") * sin(delta_longitude / 2)^2
  haversine[haversine < 0] <- 0
  haversine[haversine > 1] <- 1
  2 * radius_km * asin(sqrt(haversine))
}

maximin_spatial_selection <- function(candidates, target) {
  candidates <- candidates[order(candidates$sample_id), , drop = FALSE]
  candidates <- candidates[!duplicated(candidates$cell.10km), , drop = FALSE]
  if (nrow(candidates) < target) {
    stop(
      "Only ", nrow(candidates), " distinct reliable 10-km cells for ",
      unique(candidates$habitat_class), "; need ", target, call. = FALSE
    )
  }
  distance <- great_circle_matrix(candidates$latitude, candidates$longitude)
  centre_latitude <- mean(candidates$latitude)
  centre_longitude <- mean(candidates$longitude)
  centre_distance <- great_circle_matrix(c(
    centre_latitude, candidates$latitude
  ), c(centre_longitude, candidates$longitude))[1L, -1L]
  selected <- order(centre_distance, candidates$sample_id)[[1L]]
  selection_distance <- 0
  while (length(selected) < target) {
    available <- setdiff(seq_len(nrow(candidates)), selected)
    minimum_distance <- apply(
      distance[available, selected, drop = FALSE], 1L, min
    )
    best <- available[order(-minimum_distance, candidates$sample_id[available])[[1L]]]
    selected <- c(selected, best)
    selection_distance <- c(selection_distance, min(distance[best, selected[-length(selected)]]))
  }
  result <- candidates[selected, , drop = FALSE]
  result$selection_rank <- seq_len(nrow(result))
  result$selection_stage <- c(
    "nearest-to-class-centroid seed",
    rep("maximise minimum great-circle distance", nrow(result) - 1L)
  )
  result$minimum_distance_to_earlier_selection_km <- selection_distance
  result$eligible_distinct_10km_cells <- nrow(candidates)
  result
}

prepare_case <- function() {
  sources <- read_tsv(source_manifest_path)
  validate_source_manifest(sources)
  design <- read_tsv(habitat_design_path)
  expected_design <- c(
    "selection_order", "habitat_class", "habitat_label", "mfd_sampletype",
    "mfd_areatype", "mfd_hab1", "target_samples"
  )
  if (!identical(names(design), expected_design) ||
      anyDuplicated(design$habitat_class) || any(design$target_samples < 1L)) {
    stop("habitat-design.tsv has an invalid schema or value", call. = FALSE)
  }

  local_sources <- fetch_local_sources(sources)
  support_archive <- unname(local_sources[["Nitrifiers.tar.gz"]])
  representative_source <- unname(local_sources[["mfd-sr-mags_meta.tsv"]])
  support <- extract_support_files(support_archive)

  mags <- data.table::fread(
    support[["mags_shallow_all.tsv"]], data.table = FALSE,
    na.strings = c("", "N/A", "NA")
  )
  representatives <- data.table::fread(
    representative_source, data.table = FALSE, quote = ""
  )
  representatives$bin <- sub("^'", "", sub("'$", "", representatives$bin))
  if (nrow(mags) != 19253L || length(unique(mags$secondary_cluster)) != 5518L ||
      nrow(representatives) != 5518L || anyDuplicated(representatives$bin) ||
      !all(representatives$bin %in% mags$bin)) {
    stop("Pinned MAG tables do not reproduce the published 19,253/5,518 counts", call. = FALSE)
  }
  cluster_size <- table(mags$secondary_cluster)
  representative_rows <- mags[match(representatives$bin, mags$bin), , drop = FALSE]
  observed_cluster_size <- as.integer(unname(
    cluster_size[representative_rows$secondary_cluster]
  ))
  if (anyDuplicated(representative_rows$secondary_cluster) ||
      !setequal(representative_rows$secondary_cluster, names(cluster_size)) ||
      !identical(as.integer(representatives$bins_n), observed_cluster_size)) {
    stop("Deposited representatives do not map one-to-one to secondary clusters", call. = FALSE)
  }

  taxonomy <- do.call(
    rbind, strsplit(representative_rows$gtdb_classification, ";", fixed = TRUE)
  )
  if (ncol(taxonomy) != 7L) stop("GTDB taxonomy does not have seven ranks", call. = FALSE)
  colnames(taxonomy) <- c(
    "domain", "phylum", "class", "order", "family", "genus", "species"
  )
  representative_manifest <- data.frame(
    genome_id = representative_rows$bin,
    remote_filename = paste0(representative_rows$bin, ".fna.gz"),
    secondary_cluster = representative_rows$secondary_cluster,
    cluster_size = observed_cluster_size,
    representative_phylum = representatives$phylum,
    checkm2_completeness = representative_rows$Completeness_CheckM2,
    checkm2_contamination = representative_rows$Contamination_CheckM2,
    checkm1_completeness = representative_rows$Completeness_CheckM1,
    checkm1_contamination = representative_rows$Contamination_CheckM1,
    mag_status = representative_rows$MAG_status,
    genome_size = representative_rows$Genome_Size,
    total_contigs = representative_rows$Total_Contigs,
    contig_n50 = representative_rows$Contig_N50,
    coding_density = representative_rows$Coding_Density,
    gtdb_classification = representative_rows$gtdb_classification,
    as.data.frame(taxonomy, stringsAsFactors = FALSE),
    selection_rule = paste0(
      "deposited mfd_sr_mags representative; exactly one representative per ",
      "published 95% ANI secondary_cluster"
    ),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  representative_manifest <- representative_manifest[
    order(representative_manifest$secondary_cluster, representative_manifest$genome_id),
    , drop = FALSE
  ]

  abundance_columns <- read_abundance_header(support_archive)
  abundance_basename <- basename(abundance_columns)
  flat_name <- sub("_R1\\.fastq\\.gz$", ".fastq.gz", abundance_basename)
  if (anyDuplicated(flat_name)) {
    stop("Published abundance columns do not map uniquely to flat sample names", call. = FALSE)
  }
  abundance_map <- data.frame(
    flat_name = flat_name,
    abundance_column = abundance_columns,
    abundance_basename = abundance_basename,
    stringsAsFactors = FALSE
  )
  minimal <- data.table::fread(
    support[["2023-10-11_samples_minimal_metadata_collapsed.csv"]],
    data.table = FALSE
  )
  metadata <- as.data.frame(readxl::read_excel(
    support[["2025-02-19_mfd_db.xlsx"]]
  ), stringsAsFactors = FALSE)
  if (anyDuplicated(minimal$flat_name) || anyDuplicated(minimal$fieldsample_barcode) ||
      anyDuplicated(metadata$fieldsample_barcode)) {
    stop("Sample identifiers are not unique in the pinned metadata", call. = FALSE)
  }
  barcode_by_flat_name <- stats::setNames(
    minimal$fieldsample_barcode, minimal$flat_name
  )
  mag_flat_name <- paste0(sub("\\.[0-9]+$", "", mags$bin), ".fastq.gz")
  mag_barcode <- barcode_by_flat_name[mag_flat_name]
  mag_bin <- sub("^.*\\.", "", mags$bin)
  expected_archive_basename <- paste0(
    mag_barcode, "_ilm_asm_bin", mag_bin, ".fa"
  )
  names(expected_archive_basename) <- mags$bin
  aliases <- read_tsv(archive_alias_path)
  expected_alias_columns <- c(
    "genome_id", "expected_archive_basename", "actual_archive_basename",
    "evidence"
  )
  if (!identical(names(aliases), expected_alias_columns) || nrow(aliases) != 4L ||
      anyDuplicated(aliases$genome_id) ||
      anyDuplicated(aliases$expected_archive_basename) ||
      anyDuplicated(aliases$actual_archive_basename) ||
      !all(aliases$genome_id %in% mags$bin) ||
      anyNA(mag_barcode) || any(!grepl("^[0-9]+$", mag_bin)) ||
      !identical(
        unname(expected_archive_basename[aliases$genome_id]),
        aliases$expected_archive_basename
      ) ||
      !identical(
        sub("^.*_bin([0-9]+)[.]fa$", "\\1", aliases$expected_archive_basename),
        sub("^.*_bin([0-9]+)[.]fa$", "\\1", aliases$actual_archive_basename)
      ) ||
      !all(grepl("^unknown_ilm_asm_bin[0-9]+[.]fa$", aliases$actual_archive_basename))) {
    stop("archive-aliases.tsv does not match the pinned MAG metadata", call. = FALSE)
  }
  representative_expected <- expected_archive_basename[representative_manifest$genome_id]
  representative_alias <- stats::setNames(
    aliases$actual_archive_basename, aliases$genome_id
  )[representative_manifest$genome_id]
  representative_manifest$archive_basename <- ifelse(
    is.na(representative_alias), representative_expected, representative_alias
  )
  representative_manifest$archive_mapping_method <- ifelse(
    is.na(representative_alias),
    "published flat_name-to-fieldsample_barcode plus terminal bin number",
    "explicit complete-archive reconciliation in archive-aliases.tsv"
  )
  if (anyNA(representative_expected) ||
      anyDuplicated(representative_manifest$archive_basename)) {
    stop("Representatives do not map uniquely to archived MFD bin names", call. = FALSE)
  }
  representative_manifest <- representative_manifest[c(
    "genome_id", "remote_filename", "archive_basename",
    setdiff(
      names(representative_manifest),
      c("genome_id", "remote_filename", "archive_basename")
    )
  )]
  write_tsv(representative_manifest, representative_manifest_path)

  sample_map <- merge(
    abundance_map, minimal[c("fieldsample_barcode", "flat_name")],
    by = "flat_name", all.x = TRUE, sort = FALSE
  )
  sample_map <- merge(
    sample_map, metadata, by = "fieldsample_barcode", all.x = TRUE, sort = FALSE
  )
  sample_map$sample_id <- sample_map$fieldsample_barcode
  if (nrow(sample_map) != 10507L || anyNA(sample_map$sample_id) ||
      anyDuplicated(sample_map$sample_id)) {
    stop("Not all 10,507 abundance columns join uniquely to sample metadata", call. = FALSE)
  }

  selected <- lapply(seq_len(nrow(design)), function(i) {
    rule <- design[i, , drop = FALSE]
    index <- which(
      sample_map$mfd_sampletype == rule$mfd_sampletype &
        sample_map$mfd_areatype == rule$mfd_areatype &
        sample_map$mfd_hab1 == rule$mfd_hab1 &
        sample_map$coords_reliable == "Yes" &
        is.finite(sample_map$latitude) & is.finite(sample_map$longitude) &
        !is.na(sample_map$cell.10km) & nzchar(sample_map$cell.10km)
    )
    candidates <- sample_map[index, , drop = FALSE]
    candidates$habitat_class <- rule$habitat_class
    candidates$habitat_label <- rule$habitat_label
    candidates$habitat_order <- rule$selection_order
    maximin_spatial_selection(candidates, as.integer(rule$target_samples))
  })
  selected <- do.call(rbind, selected)
  selected <- selected[order(selected$habitat_order, selected$selection_rank), ]
  rownames(selected) <- NULL
  if (nrow(selected) != sum(design$target_samples) ||
      anyDuplicated(selected$sample_id) ||
      any(duplicated(selected[c("habitat_class", "cell.10km")])) ||
      !identical(
        as.integer(table(factor(selected$habitat_class, levels = design$habitat_class))),
        as.integer(design$target_samples)
      )) {
    stop("Selected sample panel violates its habitat or 10-km-cell contract", call. = FALSE)
  }
  selected <- selected[c(
    "sample_id", "flat_name", "abundance_column", "abundance_basename",
    "habitat_class", "habitat_label", "habitat_order", "selection_rank",
    "selection_stage", "minimum_distance_to_earlier_selection_km",
    "eligible_distinct_10km_cells", "project_id", "sampling_date", "latitude",
    "longitude", "cell.10km", "cell.1km", "coords_reliable", "mfd_sampletype",
    "mfd_areatype", "mfd_hab1", "mfd_hab2", "mfd_hab3", "sitename",
    "habitat_typenumber", "accession", "sampling_comment"
  )]
  selected$selection_rule <- paste0(
    "published abundance column; reliable coordinates; first sample_id per ",
    "habitat-class x 10-km cell; centroid seed then deterministic geographic ",
    "maximin selection; sample_id tie-break"
  )
  write_tsv(selected, selected_samples_path)

  habitat_audit <- do.call(rbind, lapply(seq_len(nrow(design)), function(i) {
    rows <- selected$habitat_class == design$habitat_class[[i]]
    data.frame(
      item = paste0("habitat:", design$habitat_class[[i]]),
      value = paste0(
        sum(rows), " samples; ", unique(selected$eligible_distinct_10km_cells[rows]),
        " eligible distinct reliable 10-km cells"
      ),
      stringsAsFactors = FALSE
    )
  }))
  source_values <- paste0(
    sources$file, ":", sources$checksum_algorithm, ":", sources$checksum
  )
  audit <- rbind(
    data.frame(
      item = c(
        "Nature article DOI", "Zenodo record DOI", "published MAGs",
        "secondary clusters", "deposited representatives", "selected samples",
        "selected habitat classes", "selection independent of annotation"
      ),
      value = c(
        "10.1038/s41586-025-09794-2", "10.5281/zenodo.17162544",
        nrow(mags), length(cluster_size), nrow(representative_manifest),
        nrow(selected), nrow(design), TRUE
      ),
      stringsAsFactors = FALSE
    ),
    habitat_audit,
    data.frame(
      item = c(
        paste0("source:", sources$file), "archive aliases sha256",
        "representative manifest sha256", "selected samples sha256",
        "habitat design sha256"
      ),
      value = c(
        source_values, sha256(archive_alias_path),
        sha256(representative_manifest_path), sha256(selected_samples_path),
        sha256(habitat_design_path)
      ),
      stringsAsFactors = FALSE
    )
  )
  write_tsv(audit, design_audit_path)
  message("wrote ", representative_manifest_path)
  message("wrote ", selected_samples_path)
  message("wrote ", design_audit_path)
}

if ("--prepare" %in% commandArgs(trailingOnly = TRUE)) {
  prepare_case()
  quit(save = "no", status = 0L)
}

devtools::load_all(".", quiet = TRUE)

annotation_path <- file.path(remote_dir, "gifter_input.catalogue.tsv.xz")
annotation_manifest_path <- file.path(remote_dir, "annotation_manifest.yaml")
annotation_qc_path <- file.path(remote_dir, "annotation_qc.tsv")
transfer_manifest_path <- file.path(remote_dir, "transfer-manifest.tsv")
transfer_complete_path <- file.path(remote_dir, "transfer.complete")
database_path <- file.path(remote_dir, "gifter.sqlite")
marker_catalogue_path <- file.path(remote_dir, "markers.tsv")
abundance_path <- file.path(
  remote_dir, "MFD_SRnodrep_tax_relative_abundance.tsv.xz"
)
mag_metadata_path <- file.path(remote_dir, "mags_shallow_all.tsv")
transferred_representatives_path <- file.path(remote_dir, "representative-genomes.tsv")
transferred_samples_path <- file.path(remote_dir, "selected-samples.tsv")

required <- c(
  representative_manifest_path, selected_samples_path, design_audit_path,
  annotation_path, annotation_manifest_path, annotation_qc_path,
  transfer_manifest_path, transfer_complete_path, database_path,
  marker_catalogue_path, abundance_path, mag_metadata_path,
  transferred_representatives_path, transferred_samples_path,
  file.path(remote_dir, "gifter-input-full-sha256.txt"),
  file.path(remote_dir, "gifter-database-sha256.txt"),
  file.path(remote_dir, "marker-catalogue-sha256.txt"),
  file.path(remote_dir, "public-data-sha256.tsv")
)
missing <- required[!file.exists(required)]
if (length(missing)) {
  stop(
    "Microflora Danica inputs are incomplete. Missing:\n  ",
    paste(missing, collapse = "\n  "),
    "\nPrepare the panels, then complete monitor-and-fetch.sh.",
    call. = FALSE
  )
}

cat("Validating the locked transfer...\n")
transfer_manifest <- read_tsv(transfer_manifest_path)
if (!identical(names(transfer_manifest), c("file", "bytes", "sha256")) ||
    anyDuplicated(transfer_manifest$file)) {
  stop("transfer-manifest.tsv has an invalid schema", call. = FALSE)
}
transfer_paths <- file.path(remote_dir, transfer_manifest$file)
if (any(!file.exists(transfer_paths))) {
  stop("Fetched transfer is incomplete", call. = FALSE)
}
observed_sha <- vapply(transfer_paths, sha256, character(1))
observed_bytes <- unname(file.info(transfer_paths)$size)
if (!identical(unname(observed_sha), transfer_manifest$sha256) ||
    !identical(as.numeric(observed_bytes), as.numeric(transfer_manifest$bytes))) {
  stop("Fetched files do not match transfer-manifest.tsv", call. = FALSE)
}
if (!identical(
      sha256(representative_manifest_path), sha256(transferred_representatives_path)
    ) ||
    !identical(sha256(selected_samples_path), sha256(transferred_samples_path))) {
  stop("The remotely processed panels differ from the locked local panels", call. = FALSE)
}

representatives <- read_tsv(representative_manifest_path)
samples <- read_tsv(selected_samples_path)
if (nrow(representatives) != 5518L || nrow(samples) != 360L ||
    anyDuplicated(representatives$genome_id) || anyDuplicated(samples$sample_id) ||
    anyDuplicated(representatives$secondary_cluster)) {
  stop("Locked genome or sample panel has changed", call. = FALSE)
}

annotations <- data.table::fread(
  cmd = paste("xzcat", shQuote(annotation_path)), data.table = FALSE
)
expected_annotation_columns <- c("genome_id", "gene_id", "namespace", "accession")
if (!identical(names(annotations), expected_annotation_columns) ||
    anyNA(annotations) || any(!nzchar(annotations$genome_id)) ||
    !setequal(unique(annotations$genome_id), representatives$genome_id)) {
  stop("Filtered Drakkar evidence does not cover exactly the locked panel", call. = FALSE)
}
marker_catalogue <- read_tsv(marker_catalogue_path)
observed_marker <- paste(annotations$namespace, annotations$accession, sep = "\r")
allowed_marker <- paste(marker_catalogue$namespace, marker_catalogue$accession, sep = "\r")
if (any(!observed_marker %in% allowed_marker)) {
  stop("Transferred annotation contains a marker outside the pinned catalogue", call. = FALSE)
}
marker_counts <- as.data.frame(
  xtabs(~ genome_id + namespace, annotations), stringsAsFactors = FALSE
)
names(marker_counts)[[3L]] <- "curated_marker_rows"
marker_counts <- marker_counts[marker_counts$curated_marker_rows > 0, ]
write_tsv(marker_counts, file.path(output_dir, "mfd-drakkar-marker-counts.tsv"))

complete_record <- read_tsv(transfer_complete_path)
if (!identical(names(complete_record), c("item", "value"))) {
  stop("transfer.complete has an invalid schema", call. = FALSE)
}
complete_value <- stats::setNames(complete_record$value, complete_record$item)
if (as.integer(complete_value[["genomes"]]) != nrow(representatives) ||
    as.numeric(complete_value[["catalogue_marker_rows"]]) != nrow(annotations) ||
    as.integer(complete_value[["samples"]]) != nrow(samples)) {
  stop("transfer.complete does not match the fetched inputs", call. = FALSE)
}

database_sha <- sha256(database_path)
annotation_sha <- sha256(annotation_path)
analysis_sha <- sha256("manuscript/analysis/25-r10-mfd.R")
cache_version <- "r10-mfd-2026-10-03-v1"
cache_key <- paste(annotation_sha, database_sha, analysis_sha, cache_version, sep = "-")
community_cache <- file.path(cache_dir, paste0("community-", cache_key, ".rds"))

database <- gifter_db_connect(database_path)
database_version <- as.data.frame(gifter_db_version(database))

if (file.exists(community_cache)) {
  cat("Reading cached representative calls...\n")
  community <- readRDS(community_cache)
} else {
  workers <- suppressWarnings(as.integer(Sys.getenv("R10_MFD_WORKERS", "8")))
  if (is.na(workers) || workers < 1L) workers <- 1L
  workers <- min(workers, 8L, nrow(representatives))
  cat("Evaluating 5,518 representatives with ", workers, " workers...\n", sep = "")
  community <- evaluate_gifts_community(
    annotations, genome_id = "genome_id", gene_id = "gene_id", db = database,
    max_genes = Inf, workers = workers, progress = interactive()
  )
  saveRDS(community, community_cache, compress = "xz")
}
if (!setequal(community$genome_id, representatives$genome_id)) {
  stop("Evaluated community differs from the locked representatives", call. = FALSE)
}

supported_calls <- do.call(rbind, lapply(community$genome_id, function(genome_id) {
  calls <- as.data.frame(community$results[[genome_id]]$gifts)
  calls <- calls[calls$complete, c(
    "gift_id", "gift_type", "name", "mode", "best_implementation",
    "evidence_confidence", "supporting_genes"
  )]
  calls$supporting_genes <- vapply(
    calls$supporting_genes, paste, collapse = ";", FUN.VALUE = character(1)
  )
  calls$genome_id <- genome_id
  calls[c(
    "genome_id", "gift_id", "gift_type", "name", "mode",
    "best_implementation", "evidence_confidence", "supporting_genes"
  )]
}))
rownames(supported_calls) <- NULL
write_xz_tsv(
  supported_calls, file.path(output_dir, "mfd-supported-gift-calls.tsv.xz")
)

cat("Collapsing the published MAG profiles to 95% ANI clusters...\n")
abundance_table <- data.table::fread(
  cmd = paste("xzcat", shQuote(abundance_path)),
  select = c("clade_name", samples$abundance_column),
  check.names = FALSE, data.table = TRUE
)
if (!identical(names(abundance_table)[-1L], samples$abundance_column)) {
  stop("Selected sample columns differ from the locked abundance mapping", call. = FALSE)
}
strain_rows <- abundance_table[
  grepl("|t__", abundance_table$clade_name, fixed = TRUE)
]
strain_rows[, genome_id := sub("^.*\\|t__", "", clade_name)]
strain_rows[, genome_id := sub("\\.fa$", "", genome_id)]
mags <- data.table::fread(mag_metadata_path, data.table = FALSE)
cluster_for_mag <- stats::setNames(mags$secondary_cluster, mags$bin)
strain_rows[, secondary_cluster := unname(cluster_for_mag[genome_id])]
if (nrow(strain_rows) != 19246L || anyNA(strain_rows$secondary_cluster) ||
    anyDuplicated(strain_rows$genome_id)) {
  stop("Published strain abundance rows do not map uniquely to MAG clusters", call. = FALSE)
}
value_columns <- samples$abundance_column
cluster_abundance <- strain_rows[, lapply(.SD, sum), by = secondary_cluster,
                                 .SDcols = value_columns]
abundance <- matrix(
  0, nrow = nrow(representatives), ncol = nrow(samples),
  dimnames = list(representatives$genome_id, samples$sample_id)
)
cluster_index <- match(cluster_abundance$secondary_cluster, representatives$secondary_cluster)
if (anyNA(cluster_index) || anyDuplicated(cluster_index)) {
  stop("Collapsed abundance contains an unknown or duplicate cluster", call. = FALSE)
}
abundance[cluster_index, ] <- as.matrix(cluster_abundance[, ..value_columns]) / 100
if (any(!is.finite(abundance)) || any(abundance < 0)) {
  stop("Collapsed abundance contains a missing, infinite or negative value", call. = FALSE)
}
profile_sum <- colSums(abundance)
if (any(profile_sum < 0.99 | profile_sum > 1.01)) {
  stop("Published strain rows do not sum to approximately 100%", call. = FALSE)
}

metadata <- samples
metadata <- metadata[match(colnames(abundance), metadata$sample_id), , drop = FALSE]
dataset <- gifter_dataset(community, abundance, metadata)
quality <- stats::setNames(
  representatives$checkm2_completeness, representatives$genome_id
)

frame_ids <- c(
  "carbon_acquisition", "aromatic_catabolism", "nitrogen_acquisition",
  "sulfur_acquisition", "chemical_detoxification",
  "biomass_essential_anabolism"
)
frames <- lapply(frame_ids, function(frame_id) {
  reference_frame(preset = frame_id, db = database)
})
names(frames) <- frame_ids

detection_thresholds <- c(0, 1e-4, 1e-3)
primary_detection <- 1e-3
detection_audit <- do.call(rbind, lapply(detection_thresholds, function(detection) {
  detected <- colSums(abundance > detection)
  data.frame(
    detection = detection,
    minimum_detected_clusters = min(detected),
    median_detected_clusters = stats::median(detected),
    maximum_detected_clusters = max(detected),
    stringsAsFactors = FALSE
  )
}))
write_tsv(detection_audit, file.path(output_dir, "mfd-detection-sensitivity.tsv"))

cat("Computing descriptive habitat readings at three detection thresholds...\n")
trait_reads <- lapply(detection_thresholds, function(detection) {
  trait_cache <- file.path(
    cache_dir,
    paste0("dataset-traits-d", format(detection, scientific = TRUE), "-", cache_key, ".rds")
  )
  if (file.exists(trait_cache)) return(readRDS(trait_cache))
  reading <- suppressWarnings(dataset_traits(
    dataset, frames = frames, quality = quality, policy = "completeness",
    threshold = 90, detection = detection, pairwise = FALSE, db = database,
    progress = interactive()
  ))
  saveRDS(reading, trait_cache, compress = "xz")
  reading
})
names(trait_reads) <- format(detection_thresholds, scientific = TRUE)

strict_cache <- file.path(cache_dir, paste0("dataset-traits-high-confidence-", cache_key, ".rds"))
if (file.exists(strict_cache)) {
  strict_traits <- readRDS(strict_cache)
} else {
  strict_traits <- suppressWarnings(dataset_traits(
    dataset, frames = frames, quality = quality, policy = "completeness",
    threshold = 90, min_confidence = "high-confidence",
    detection = primary_detection, pairwise = FALSE, db = database,
    progress = interactive()
  ))
  saveRDS(strict_traits, strict_cache, compress = "xz")
}

sample_metrics <- do.call(rbind, Map(function(reading, detection) {
  rows <- as.data.frame(reading$metrics)
  rows <- rows[rows$target_type == "community", , drop = FALSE]
  rows$detection <- detection
  rows
}, trait_reads, detection_thresholds))
rownames(sample_metrics) <- NULL
sample_metrics <- merge(
  sample_metrics, samples[c(
    "sample_id", "habitat_class", "habitat_label", "habitat_order",
    "project_id", "sampling_date", "latitude", "longitude", "cell.10km",
    "mfd_sampletype", "mfd_areatype", "mfd_hab1", "mfd_hab2", "mfd_hab3"
  )], by = "sample_id", sort = FALSE
)
sample_metrics <- sample_metrics[order(
  sample_metrics$detection, sample_metrics$reference_frame,
  sample_metrics$metric_id, sample_metrics$habitat_order, sample_metrics$sample_id
), ]
write_xz_tsv(sample_metrics, file.path(output_dir, "mfd-sample-traits.tsv.xz"))

primary_index <- which(detection_thresholds == primary_detection)
gift_sample_metrics <- as.data.frame(trait_reads[[primary_index]]$metrics)
gift_sample_metrics <- gift_sample_metrics[
  gift_sample_metrics$target_type == "gift" &
    gift_sample_metrics$metric_id %in%
      c("provider_count", "provider_fraction", "abundance_coverage"),
  , drop = FALSE
]
gift_sample_metrics <- merge(
  gift_sample_metrics,
  samples[c("sample_id", "habitat_class", "habitat_label", "habitat_order")],
  by = "sample_id", sort = FALSE
)
gift_catalogue <- as.data.frame(list_gifts(db = database))
gift_sample_metrics <- merge(
  gift_sample_metrics, gift_catalogue[c("gift_id", "name", "gift_type")],
  by.x = "target_id", by.y = "gift_id", all.x = TRUE, sort = FALSE
)
gift_sample_metrics$detection <- primary_detection
gift_sample_metrics <- gift_sample_metrics[order(
  gift_sample_metrics$reference_frame, gift_sample_metrics$metric_id,
  gift_sample_metrics$habitat_order, gift_sample_metrics$sample_id,
  gift_sample_metrics$target_id
), ]
write_xz_tsv(
  gift_sample_metrics,
  file.path(output_dir, "mfd-gift-sample-provider-abundance.tsv.xz")
)

summarise_values <- function(table, keys) {
  groups <- interaction(table[keys], drop = TRUE, lex.order = TRUE)
  result <- lapply(split(seq_len(nrow(table)), groups), function(index) {
    key <- table[index[[1L]], keys, drop = FALSE]
    values <- table$value[index]
    values <- values[is.finite(values)]
    key$n <- length(values)
    if (length(values)) {
      key$median <- stats::median(values)
      key$q25 <- as.numeric(stats::quantile(values, 0.25))
      key$q75 <- as.numeric(stats::quantile(values, 0.75))
      key$minimum <- min(values)
      key$maximum <- max(values)
    } else {
      key$median <- key$q25 <- key$q75 <- key$minimum <- key$maximum <- NA_real_
    }
    key
  })
  result <- do.call(rbind, result)
  rownames(result) <- NULL
  result
}

habitat_summary <- summarise_values(
  sample_metrics,
  c(
    "detection", "habitat_order", "habitat_class", "habitat_label",
    "reference_frame", "metric_id", "unit"
  )
)
habitat_summary <- habitat_summary[order(
  habitat_summary$detection, habitat_summary$reference_frame,
  habitat_summary$metric_id, habitat_summary$habitat_order
), ]
write_tsv(habitat_summary, file.path(output_dir, "mfd-habitat-summary.tsv"))

confidence_metrics <- rbind(
  transform(
    as.data.frame(trait_reads[[primary_index]]$metrics),
    confidence_floor = "all accepted"
  ),
  transform(as.data.frame(strict_traits$metrics), confidence_floor = "high-confidence")
)
confidence_metrics <- confidence_metrics[
  confidence_metrics$target_type == "community", , drop = FALSE
]
confidence_metrics <- merge(
  confidence_metrics,
  samples[c("sample_id", "habitat_class", "habitat_label", "habitat_order")],
  by = "sample_id", sort = FALSE
)
confidence_summary <- summarise_values(
  confidence_metrics,
  c(
    "confidence_floor", "habitat_order", "habitat_class", "habitat_label",
    "reference_frame", "metric_id", "unit"
  )
)
confidence_summary <- confidence_summary[order(
  confidence_summary$confidence_floor, confidence_summary$reference_frame,
  confidence_summary$metric_id, confidence_summary$habitat_order
), ]
write_tsv(
  confidence_summary, file.path(output_dir, "mfd-confidence-sensitivity.tsv")
)

quality_summary <- data.frame(
  genomes = nrow(representatives),
  median_checkm2_completeness = stats::median(representatives$checkm2_completeness),
  q25_checkm2_completeness = as.numeric(stats::quantile(
    representatives$checkm2_completeness, 0.25
  )),
  q75_checkm2_completeness = as.numeric(stats::quantile(
    representatives$checkm2_completeness, 0.75
  )),
  checkm2_at_least_90_contamination_below_5 = sum(
    representatives$checkm2_completeness >= 90 &
      representatives$checkm2_contamination < 5
  ),
  high_quality_status = sum(representatives$mag_status == "HQ"),
  medium_quality_status = sum(representatives$mag_status == "MQ"),
  stringsAsFactors = FALSE
)
write_tsv(quality_summary, file.path(output_dir, "mfd-representative-quality.tsv"))

input_audit <- data.frame(
  item = c(
    "Nature article DOI", "Zenodo record DOI", "representatives", "samples",
    "habitat classes", "Drakkar catalogue-marker rows", "Drakkar full-marker rows",
    "annotation sha256", "archived gifter database sha256", "gifter database version",
    "schema version", "analysis sha256", "representative manifest sha256",
    "selected samples sha256", "abundance sha256", "abundance profile-sum range",
    "detection thresholds", "operational detection", "abundance interpretation"
  ),
  value = c(
    "10.1038/s41586-025-09794-2", "10.5281/zenodo.17162544",
    nrow(representatives), nrow(samples), length(unique(samples$habitat_class)),
    nrow(annotations), complete_value[["full_marker_rows"]], annotation_sha,
    database_sha, database_version$gifter_db_version,
    database_version$schema_version, analysis_sha, sha256(representative_manifest_path),
    sha256(selected_samples_path), sha256(abundance_path),
    paste(format(range(profile_sum), digits = 10), collapse = "--"),
    paste(detection_thresholds, collapse = ";"), primary_detection,
    "fraction of published MFD-MAG-assigned abundance; cluster-summed; not renormalised"
  ),
  stringsAsFactors = FALSE
)
write_tsv(input_audit, file.path(output_dir, "mfd-input-audit.tsv"))

plot_table <- habitat_summary[
  habitat_summary$detection == primary_detection &
    habitat_summary$metric_id == "community_richness",
]
detected_plot <- habitat_summary[
  habitat_summary$detection == primary_detection &
    habitat_summary$metric_id == "detected_genomes",
  c("habitat_class", "reference_frame", "median")
]
names(detected_plot)[[3L]] <- "median_detected_clusters"
plot_table <- merge(
  plot_table, detected_plot,
  by = c("habitat_class", "reference_frame"), all.x = TRUE, sort = FALSE
)
plot_table$cell_label <- paste0(
  format(round(plot_table$median, 1), trim = TRUE), "\nn=",
  format(round(plot_table$median_detected_clusters, 1), trim = TRUE)
)
plot_table$habitat_label <- factor(
  plot_table$habitat_label,
  levels = rev(unique(samples$habitat_label[order(samples$habitat_order)]))
)
plot_table$reference_frame <- factor(
  plot_table$reference_frame,
  levels = vapply(frames, `[[`, character(1), "label")
)
richness_figure <- ggplot(plot_table, aes(reference_frame, habitat_label, fill = median)) +
  geom_tile(colour = "white", linewidth = 0.5) +
  geom_text(aes(label = cell_label), size = 2.8, lineheight = 0.9) +
  scale_fill_viridis_c(option = "C", name = "Median\nGIFTs") +
  labs(
    x = NULL, y = NULL,
    title = "Encoded capability richness across distinct environmental communities",
    subtitle = paste0(
      "45 spatially distributed samples per habitat; representative clusters >0.1% ",
      "of the MFD MAG profile"
    ),
    caption = paste0(
      "Counts are descriptive database-frame readings, not activity or total functional diversity. ",
      "Cell labels give median GIFT richness and median detected clusters (n)."
    )
  ) +
  theme_minimal(base_size = 10) +
  theme(
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 35, hjust = 1),
    plot.caption = element_text(hjust = 0)
  )
ggsave(
  file.path(figure_dir, "mfd-environmental-community-richness.pdf"),
  richness_figure, width = 11.5, height = 6.5
)
ggsave(
  file.path(figure_dir, "mfd-environmental-community-richness.png"),
  richness_figure, width = 11.5, height = 6.5, dpi = 300
)

gifter_db_disconnect(database)
cat(
  "Completed the Microflora Danica environmental analysis for ",
  nrow(representatives), " representative clusters and ", nrow(samples),
  " samples.\n", sep = ""
)
