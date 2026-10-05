# Run by 36-r10-gifter-resources.R in a fresh R process. This is the gifter
# portion of R10: the input is an already annotated, gene-resolved marker table.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 4L)
event_path <- args[[1L]]
workers <- as.integer(args[[2L]])
genome_limit <- as.integer(args[[3L]])
sample_limit <- as.integer(args[[4L]])
stopifnot(!is.na(workers), workers > 0L)

suppressPackageStartupMessages(pkgload::load_all(".", quiet = TRUE))
case_dir <- "manuscript/analysis/r10-chicken"
cache_dir <- "manuscript/analysis/.cache/r10-chicken"
annotation_path <- file.path(cache_dir, "drakkar/gifter_input.tsv.xz")
manifest_path <- file.path(cache_dir, "drakkar/transfer-manifest.tsv")
public_dir <- file.path(cache_dir, "public-data")

required <- c(annotation_path, manifest_path,
              file.path(case_dir, "mag-manifest.tsv"),
              file.path(public_dir, c("mag_counts.tsv", "stats.tsv", "metadata.tsv")))
if (any(!file.exists(required))) {
  stop("Missing R10 benchmark input: ", paste(required[!file.exists(required)], collapse = ", "))
}

read_tsv <- function(path) {
  utils::read.delim(path, check.names = FALSE, stringsAsFactors = FALSE)
}
sha256 <- function(path) {
  command <- if (nzchar(Sys.which("shasum"))) "shasum" else "sha256sum"
  args <- if (identical(command, "shasum")) c("-a", "256", path) else path
  result <- system2(command, args, stdout = TRUE)
  sub("[[:space:]].*$", "", result[[1L]])
}
record <- function(event, stage, cpu = NA_real_) {
  cat(event, stage, sprintf("%.6f", as.numeric(Sys.time())), cpu,
      sep = "\t", file = event_path, append = TRUE)
  cat("\n", file = event_path, append = TRUE)
}
stage <- function(name, expression) {
  before <- proc.time()
  record("start", name)
  value <- force(expression)
  elapsed_cpu <- proc.time() - before
  cpu <- sum(elapsed_cpu[c("user.self", "sys.self", "user.child", "sys.child")])
  record("end", name, sprintf("%.6f", cpu))
  value
}

cat("event\tstage\tepoch_seconds\tcpu_seconds\n", file = event_path)
annotations <- stage("input_read", {
  manifest <- read_tsv(manifest_path)
  target <- manifest[manifest$file == "gifter_input.tsv.xz", , drop = FALSE]
  stopifnot(nrow(target) == 1L, file.info(annotation_path)$size == target$bytes)
  stopifnot(identical(sha256(annotation_path), target$sha256))
  markers <- read_tsv(annotation_path)
  stopifnot(identical(names(markers), c("genome_id", "gene_id", "namespace", "accession")))
  manifest_genomes <- read_tsv(file.path(case_dir, "mag-manifest.tsv"))$genome_id
  stopifnot(setequal(unique(markers$genome_id), manifest_genomes))
  if (!is.na(genome_limit)) {
    selected <- sort(unique(markers$genome_id))[seq_len(min(genome_limit, 822L))]
    markers <- markers[markers$genome_id %in% selected, , drop = FALSE]
  }
  markers
})

community <- stage("genome_evaluation", evaluate_gifts_community(
  annotations, genome_id = "genome_id", gene_id = "gene_id",
  max_genes = Inf, workers = workers, progress = FALSE
))
rm(annotations)
gc(verbose = FALSE)

dataset_input <- stage("dataset_assembly", {
  counts <- read_tsv(file.path(public_dir, "mag_counts.tsv"))
  stats <- read_tsv(file.path(public_dir, "stats.tsv"))
  metadata <- read_tsv(file.path(public_dir, "metadata.tsv"))
  counts <- counts[match(community$genome_id, counts$mag_id), , drop = FALSE]
  stats <- stats[match(community$genome_id, stats$mag_id), , drop = FALSE]
  stopifnot(identical(counts$mag_id, community$genome_id),
            identical(stats$mag_id, community$genome_id))
  values <- as.matrix(counts[-1L])
  storage.mode(values) <- "double"
  rownames(values) <- counts$mag_id
  if (!is.na(sample_limit)) {
    values <- values[, seq_len(min(sample_limit, ncol(values))), drop = FALSE]
  }
  length_corrected <- sweep(values, 1L, stats$mag_length, "/")
  abundance <- sweep(length_corrected, 2L, colSums(length_corrected), "/")
  metadata$sample_id <- metadata$animal_code
  metadata <- metadata[match(colnames(abundance), metadata$sample_id), , drop = FALSE]
  stopifnot(!anyNA(metadata$sample_id), all(is.finite(abundance)))
  list(dataset = gifter_dataset(community, abundance, metadata),
       quality = stats::setNames(stats$completeness_score, stats$mag_id))
})

frames <- list(
  reference_frame(type = "metabolic", label = "All metabolic GIFTs"),
  reference_frame(preset = "carbohydrate_degradation"),
  reference_frame(preset = "plant_fibre_utilisation"),
  reference_frame(preset = "fermentation_products"),
  reference_frame(preset = "short_chain_fatty_acids"),
  reference_frame(preset = "biomass_essential_anabolism"),
  reference_frame(preset = "amino_acid_autonomy"),
  reference_frame(preset = "nucleotide_autonomy"),
  reference_frame(preset = "cofactor_autonomy"),
  reference_frame(preset = "extracellular_public_goods"),
  reference_frame(preset = "nutrient_uptake")
)

traits <- stage("sample_traits", suppressWarnings(dataset_traits(
  dataset_input$dataset, frames = frames, quality = dataset_input$quality,
  policy = "completeness", threshold = 90, detection = 1e-3,
  pairwise = FALSE, progress = FALSE
)))
network <- stage("sample_network", dataset_network(
  dataset_input$dataset, frame = frames[[3L]], quality = "exact",
  detection = 1e-3
))

stopifnot(length(community$genome_id) == nrow(dataset_input$dataset$abundance),
          length(dataset_input$dataset$sample_id) == ncol(dataset_input$dataset$abundance),
          length(unique(traits$metrics$sample_id)) == ncol(dataset_input$dataset$abundance),
          length(unique(network$metrics$sample_id)) == ncol(dataset_input$dataset$abundance))
cat("genomes=", length(community$genome_id),
    " samples=", length(dataset_input$dataset$sample_id),
    " gift_db_version=", gifter_db_version()$gifter_db_version,
    " supported_calls=", sum(community$matrix), "\n", sep = "")
