#!/usr/bin/env Rscript
# A broad phylogenetic overview of encoded GIFT repertoires.
#
# The panel is selected before annotation from the latest pinned GTDB release.
# Eligible tips are bacterial species representatives whose NCBI assembly level
# is Complete Genome and whose isolation-source text assigns them to at least
# one reviewed origin group. One phylogenetic medoid per eligible GTDB order
# guarantees broad taxonomic coverage, all high-confidence food/fermentation-
# origin candidates are retained, and the other nonexclusive origin groups are
# balanced to the same reference count where their eligible populations allow.
# Marginal Faith phylogenetic diversity decides among balance-compatible
# choices. No marker, GIFT call or phenotype can affect selection.
#
# Drakkar supplies gene-resolved marker evidence for the locked panel. gifter
# evaluates each genome independently. The resulting tree and heatmap describe
# encoded capabilities; they do not assert expression, activity, phenotype,
# ecological function or ancestral state.
#
# Usage from the repository root:
#   Rscript manuscript/analysis/23-gtdb-phylogeny.R --prepare
#   Rscript manuscript/analysis/23-gtdb-phylogeny.R

suppressWarnings(suppressPackageStartupMessages({
  library(ape)
  library(ggplot2)
  library(ggtree)
  library(patchwork)
}))

root <- "manuscript/analysis"
case_dir <- file.path(root, "gtdb-phylogeny")
cache_dir <- Sys.getenv(
  "GTDB_PHYLOGENY_CACHE_DIR",
  file.path(root, ".cache", "gtdb-phylogeny")
)
source_dir <- file.path(cache_dir, "sources")
drakkar_dir <- Sys.getenv(
  "GTDB_PHYLOGENY_DRAKKAR_DIR",
  file.path(cache_dir, "drakkar")
)
output_dir <- Sys.getenv("GTDB_PHYLOGENY_OUTPUT_DIR", file.path(root, "output"))
figure_dir <- Sys.getenv("GTDB_PHYLOGENY_FIGURE_DIR", "manuscript/figures")
dir.create(source_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

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

read_key_value <- function(path) {
  table <- utils::read.delim(
    path, header = FALSE, check.names = FALSE, stringsAsFactors = FALSE
  )
  if (ncol(table) != 2L) {
    stop(basename(path), " must have exactly two columns", call. = FALSE)
  }
  if (nrow(table) && identical(as.character(table[1L, ]), c("item", "value"))) {
    table <- table[-1L, , drop = FALSE]
  }
  names(table) <- c("item", "value")
  if (!nrow(table) || anyNA(table$item) || any(!nzchar(table$item)) ||
      anyDuplicated(table$item)) {
    stop(basename(path), " has invalid or duplicate item names", call. = FALSE)
  }
  table
}

manifest_value <- function(lines, key) {
  matched <- grep(paste0("^", key, ":[[:space:]]*"), lines, value = TRUE)
  if (length(matched) != 1L) {
    stop("annotation_manifest.yaml must define ", key, " exactly once", call. = FALSE)
  }
  value <- sub(paste0("^", key, ":[[:space:]]*"), "", matched)
  gsub("^['\"]|['\"]$", "", trimws(value))
}

collapse_values <- function(x) {
  vapply(x, function(value) {
    value <- as.character(value)
    value <- value[!is.na(value) & nzchar(value)]
    paste(value, collapse = ";")
  }, character(1))
}

sha256 <- function(path) {
  command <- if (nzchar(Sys.which("shasum"))) "shasum" else "sha256sum"
  args <- if (identical(command, "shasum")) c("-a", "256", path) else path
  output <- system2(command, args, stdout = TRUE, stderr = TRUE)
  if (!length(output)) stop("Could not checksum ", path, call. = FALSE)
  sub("[[:space:]].*$", "", output[[1L]])
}

strip_rank <- function(x) sub("^[a-z]__", "", x)

classify_origin_groups <- function(isolation_source, rules) {
  expected <- c("origin_group", "pattern", "exclude_pattern", "description")
  if (!identical(names(rules), expected) || anyDuplicated(rules$origin_group) ||
      any(!grepl("^[a-z][a-z0-9_]+$", rules$origin_group))) {
    stop("origin-group-rules.tsv has an invalid schema or group identifier", call. = FALSE)
  }
  source <- tolower(trimws(ifelse(is.na(isolation_source), "", isolation_source)))
  source[source == "none"] <- ""
  flags <- data.frame(origin_source_available = nzchar(source))
  for (i in seq_len(nrow(rules))) {
    matched <- nzchar(source) & grepl(rules$pattern[[i]], source, perl = TRUE)
    exclusion <- rules$exclude_pattern[[i]]
    if (!is.na(exclusion) && nzchar(exclusion)) {
      matched <- matched & !grepl(exclusion, source, perl = TRUE)
    }
    flags[[paste0("origin_", rules$origin_group[[i]])]] <- matched
  }
  flags
}

source_manifest_path <- file.path(case_dir, "source-manifest.tsv")
origin_rules_path <- file.path(case_dir, "origin-group-rules.tsv")
panel_manifest_path <- file.path(case_dir, "selected-genomes.tsv")
panel_tree_path <- file.path(case_dir, "selected-genomes.tree")
panel_audit_path <- file.path(case_dir, "selection-audit.tsv")
origin_summary_path <- file.path(case_dir, "origin-group-summary.tsv")
panel_exclusions_path <- file.path(case_dir, "excluded-genomes.tsv")
species_size_path <- file.path(case_dir, "species-genome-size.tsv")
ORIGIN_BALANCE_TARGET <- 85L

# Genomes the selection chose but that could not be annotated. They are removed
# after selection, without replacement and without reference to any GIFT call.
read_panel_exclusions <- function(path) {
  exclusions <- utils::read.delim(
    path, check.names = FALSE, stringsAsFactors = FALSE, quote = ""
  )
  if (!identical(
        names(exclusions), c("genome_id", "excluded_at_utc", "stage", "reason")
      ) || anyNA(exclusions) || anyDuplicated(exclusions$genome_id) ||
      any(!nzchar(exclusions$stage)) || any(!nzchar(exclusions$reason))) {
    stop(basename(path), " must name each excluded genome once, with a reason",
         call. = FALSE)
  }
  exclusions
}

rooted_faith_pd <- function(tree, tips) {
  root <- length(tree$tip.label) + 1L
  nodes <- unique(unlist(lapply(
    match(tips, tree$tip.label),
    function(tip) ape::nodepath(tree, from = root, to = tip)
  )))
  sum(tree$edge.length[tree$edge[, 2L] %in% nodes])
}

balanced_origin_panel <- function(tree, seeds, origin_membership, origin_targets) {
  n_tips <- length(tree$tip.label)
  if (anyDuplicated(seeds) || any(!seeds %in% tree$tip.label)) {
    stop("Invalid seed outside the candidate tree", call. = FALSE)
  }
  if (is.null(rownames(origin_membership)) || is.null(names(origin_targets)) ||
      any(!tree$tip.label %in% rownames(origin_membership)) ||
      any(!names(origin_targets) %in% names(origin_membership))) {
    stop("Origin membership does not match the candidate tree", call. = FALSE)
  }
  origin_membership <- as.matrix(origin_membership[
    match(tree$tip.label, rownames(origin_membership)),
    names(origin_targets), drop = FALSE
  ])
  storage.mode(origin_membership) <- "logical"
  if (anyNA(origin_membership) || any(origin_targets < 1L) ||
      any(origin_targets > colSums(origin_membership))) {
    stop("Origin balance targets are not attainable", call. = FALSE)
  }

  edge <- tree$edge
  edge_length <- tree$edge.length
  if (is.null(edge_length) || anyNA(edge_length) || any(edge_length < 0)) {
    stop("GTDB tree needs non-negative branch lengths", call. = FALSE)
  }
  root <- setdiff(unique(edge[, 1L]), unique(edge[, 2L]))
  if (length(root) != 1L) stop("GTDB candidate tree is not singly rooted", call. = FALSE)

  children <- split(edge[, 2L], edge[, 1L])
  max_node <- max(edge)
  descendants <- vector("list", max_node)
  resolved <- rep(FALSE, max_node)
  old_expressions <- getOption("expressions")
  options(expressions = max(old_expressions, 500000L))
  on.exit(options(expressions = old_expressions), add = TRUE)
  descendant_tips <- function(node) {
    if (resolved[[node]]) return(descendants[[node]])
    descendants[[node]] <<- if (node <= n_tips) {
      node
    } else {
      unlist(lapply(children[[as.character(node)]], descendant_tips), use.names = FALSE)
    }
    resolved[[node]] <<- TRUE
    descendants[[node]]
  }
  descendant_tips(root)

  parent_edge <- rep(NA_integer_, max_node)
  parent_edge[edge[, 2L]] <- seq_len(nrow(edge))
  scores <- ape::node.depth.edgelength(tree)[seq_len(n_tips)]
  covered <- rep(FALSE, nrow(edge))
  selected <- rep(FALSE, n_tips)

  cover_tip <- function(tip) {
    node <- tip
    marginal <- 0
    while (node != root) {
      edge_index <- parent_edge[[node]]
      if (is.na(edge_index)) stop("Broken parent path in GTDB tree", call. = FALSE)
      if (!covered[[edge_index]]) {
        marginal <- marginal + edge_length[[edge_index]]
        below <- descendants[[node]]
        scores[below] <<- scores[below] - edge_length[[edge_index]]
        covered[[edge_index]] <<- TRUE
      }
      node <- edge[edge_index, 1L]
    }
    selected[[tip]] <<- TRUE
    scores[[tip]] <<- -Inf
    marginal
  }

  seed_index <- match(seeds, tree$tip.label)
  seed_marginal <- vapply(seed_index, cover_tip, numeric(1))
  selected_labels <- tree$tip.label[seed_index]
  stages <- rep("GTDB order medoid", length(seeds))
  marginals <- seed_marginal
  origin_counts <- colSums(origin_membership[selected, , drop = FALSE])

  while (any(origin_counts < origin_targets)) {
    incomplete <- origin_counts < origin_targets
    representation <- origin_counts / origin_targets
    least_represented <- min(representation[incomplete])
    focus <- which(incomplete & abs(representation - least_represented) <= 1e-12)
    available <- which(
      !selected & rowSums(origin_membership[, focus, drop = FALSE]) > 0
    )
    if (!length(available)) {
      stop("An origin balance target became unattainable", call. = FALSE)
    }
    completed <- origin_counts >= origin_targets
    completed_inflation <- if (any(completed)) {
      rowSums(origin_membership[available, completed, drop = FALSE])
    } else {
      rep(0L, length(available))
    }
    available <- available[completed_inflation == min(completed_inflation)]
    best <- max(scores[available])
    tied <- available[abs(scores[available] - best) <= 1e-12]
    tip <- tied[order(tree$tip.label[tied])][[1L]]
    selected_labels <- c(selected_labels, tree$tip.label[[tip]])
    stages <- c(stages, "origin balance + marginal phylogenetic diversity")
    marginals <- c(marginals, cover_tip(tip))
    origin_counts <- origin_counts + origin_membership[tip, ]
  }

  list(
    genome_id = selected_labels,
    selection_stage = stages,
    marginal_phylogenetic_diversity = marginals,
    covered_edge = covered,
    origin_target = origin_targets,
    origin_count = origin_counts
  )
}

prepare_panel <- function() {
  sources <- read_tsv(source_manifest_path)
  origin_rules <- read_tsv(origin_rules_path)
  required_origin_groups <- c(
    "food_fermentation", "animal_associated", "plant_associated"
  )
  if (!all(required_origin_groups %in% origin_rules$origin_group) ||
      "host_associated" %in% origin_rules$origin_group) {
    stop(
      "Origin rules must keep food/fermentation, animal and plant groups, ",
      "and must not collapse animal and plant origins into host_associated",
      call. = FALSE
    )
  }
  expected_columns <- c("file", "source_url", "sha256", "role")
  if (!identical(names(sources), expected_columns)) {
    stop("source-manifest.tsv must contain exactly: ",
         paste(expected_columns, collapse = ", "), call. = FALSE)
  }

  paths <- file.path(source_dir, sources$file)
  for (i in seq_len(nrow(sources))) {
    if (!file.exists(paths[[i]])) {
      message("fetching ", sources$file[[i]])
      utils::download.file(sources$source_url[[i]], paths[[i]], mode = "wb")
    }
    observed <- sha256(paths[[i]])
    if (!identical(observed, sources$sha256[[i]])) {
      stop("Source checksum mismatch: ", sources$file[[i]], call. = FALSE)
    }
  }

  checksum_path <- paths[sources$role == "GTDB published checksum manifest"]
  if (length(checksum_path) != 1L) {
    stop("The GTDB checksum manifest must occur exactly once", call. = FALSE)
  }
  checksum_fields <- strsplit(trimws(readLines(checksum_path)), "[[:space:]]+")
  published_md5 <- setNames(
    vapply(checksum_fields, `[[`, character(1), 1L),
    basename(vapply(checksum_fields, `[[`, character(1), 2L))
  )
  content_index <- sources$role != "GTDB published checksum manifest"
  expected_md5 <- unname(published_md5[sources$file[content_index]])
  observed_md5 <- unname(tools::md5sum(paths[content_index]))
  if (anyNA(expected_md5) || !identical(observed_md5, expected_md5)) {
    stop("GTDB inputs do not match its published MD5 manifest", call. = FALSE)
  }

  tree_path <- paths[sources$role == "GTDB bacterial reference tree"]
  metadata_path <- paths[sources$role == "GTDB bacterial metadata"]
  if (length(tree_path) != 1L || length(metadata_path) != 1L) {
    stop("Each required source role must occur exactly once", call. = FALSE)
  }

  tree <- ape::read.tree(tree_path)
  metadata_columns <- c(
    "accession", "checkm2_completeness", "checkm2_contamination",
    "checkm_completeness", "checkm_contamination", "contig_count",
    "genome_size", "gtdb_representative", "gtdb_taxonomy",
    "gtdb_type_designation_ncbi_taxa", "mimag_high_quality",
    "ncbi_assembly_level", "ncbi_assembly_name", "ncbi_assembly_type",
    "ncbi_bioproject", "ncbi_biosample", "ncbi_country", "ncbi_date",
    "ncbi_genbank_assembly_accession", "ncbi_genome_category",
    "ncbi_genome_representation", "ncbi_isolate", "ncbi_isolation_source",
    "ncbi_lat_lon", "ncbi_organism_name", "ncbi_refseq_category",
    "ncbi_seq_rel_date", "ncbi_species_taxid", "ncbi_strain_identifiers",
    "ncbi_submitter", "ncbi_taxid", "ncbi_taxonomy",
    "ncbi_type_material_designation", "ncbi_wgs_master"
  )
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("Panel preparation requires the data.table package", call. = FALSE)
  }
  metadata <- data.table::fread(
    cmd = paste("gzip -dc", shQuote(metadata_path)),
    select = metadata_columns,
    na.strings = c("", "na", "NA"),
    data.table = FALSE
  )
  candidates <- metadata[
    metadata$gtdb_representative == "t" &
      metadata$ncbi_assembly_level == "Complete Genome" &
      metadata$ncbi_genome_representation == "full" &
      metadata$accession %in% tree$tip.label,
    , drop = FALSE
  ]
  candidates$gtdb_accession <- candidates$accession
  candidates$genome_id <- candidates$ncbi_genbank_assembly_accession
  candidates$gtdb_tree <- "bac120_r232.tree"
  candidates$in_gtdb_bac120_tree <- TRUE
  ranks <- do.call(rbind, strsplit(candidates$gtdb_taxonomy, ";", fixed = TRUE))
  if (ncol(ranks) != 7L) stop("GTDB taxonomy does not have seven ranks", call. = FALSE)
  colnames(ranks) <- c("domain", "phylum", "class", "order", "family", "genus", "species")
  candidates <- cbind(candidates, as.data.frame(ranks, stringsAsFactors = FALSE))
  origin_flags <- classify_origin_groups(candidates$ncbi_isolation_source, origin_rules)
  candidates <- cbind(candidates, origin_flags)
  origin_columns <- names(origin_flags)
  origin_group_columns <- paste0("origin_", origin_rules$origin_group)
  food_column <- "origin_food_fermentation"
  complete_candidates <- candidates
  complete_has_origin_group <- rowSums(
    complete_candidates[origin_group_columns]
  ) > 0
  if (nrow(complete_candidates) != 12094L || anyNA(complete_candidates$genome_id) ||
      anyDuplicated(complete_candidates$genome_id) ||
      length(unique(complete_candidates$order)) != 552L ||
      sum(complete_candidates[[food_column]]) != 85L) {
    stop(
      "Pinned R232 inputs should yield 12,094 complete species representatives ",
      "in 552 orders and 85 food/fermentation-origin candidates; observed ",
      nrow(complete_candidates), ", ",
      length(unique(complete_candidates$order)), " and ",
      sum(complete_candidates[[food_column]]), call. = FALSE
    )
  }
  candidates <- complete_candidates[complete_has_origin_group, , drop = FALSE]
  if (nrow(candidates) != 4116L || length(unique(candidates$phylum)) != 49L ||
      length(unique(candidates$class)) != 120L ||
      length(unique(candidates$order)) != 321L ||
      !all(rowSums(candidates[origin_group_columns]) > 0)) {
    stop(
      "Origin rules should yield 4,116 eligible representatives in 49 phyla, ",
      "120 classes and 321 orders", call. = FALSE
    )
  }

  candidate_tree <- ape::keep.tip(tree, candidates$gtdb_accession)
  accession_to_genbank <- setNames(candidates$genome_id, candidates$gtdb_accession)
  candidate_tree$tip.label <- unname(accession_to_genbank[candidate_tree$tip.label])
  groups <- split(candidates$genome_id, candidates$order)
  order_names <- sort(names(groups))
  seeds <- character(length(order_names))
  order_size <- integer(length(order_names))
  seed_mean_distance <- numeric(length(order_names))

  for (i in seq_along(order_names)) {
    ids <- sort(groups[[order_names[[i]]]])
    order_size[[i]] <- length(ids)
    if (length(ids) == 1L) {
      seeds[[i]] <- ids
      seed_mean_distance[[i]] <- 0
    } else {
      order_tree <- ape::keep.tip(candidate_tree, ids)
      distance <- ape::cophenetic.phylo(order_tree)
      means <- rowMeans(distance)
      tied <- names(means)[means == min(means)]
      seeds[[i]] <- sort(tied)[[1L]]
      seed_mean_distance[[i]] <- unname(means[seeds[[i]]])
    }
  }

  order_seeds <- sort(unique(seeds))
  origin_membership <- candidates[origin_group_columns]
  rownames(origin_membership) <- candidates$genome_id
  origin_eligible_counts <- colSums(origin_membership)
  origin_targets <- stats::setNames(
    pmin(ORIGIN_BALANCE_TARGET, origin_eligible_counts),
    names(origin_eligible_counts)
  )
  selection <- balanced_origin_panel(
    candidate_tree, seeds = order_seeds,
    origin_membership = origin_membership,
    origin_targets = origin_targets
  )
  selected <- data.frame(
    genome_id = selection$genome_id,
    selection_step = seq_along(selection$genome_id),
    selection_stage = selection$selection_stage,
    marginal_phylogenetic_diversity = selection$marginal_phylogenetic_diversity,
    stringsAsFactors = FALSE
  )
  order_audit <- data.frame(
    order = order_names, order_candidate_genomes = order_size,
    order_medoid = seeds, medoid_mean_patristic_distance = seed_mean_distance,
    stringsAsFactors = FALSE
  )
  panel <- merge(selected, candidates, by = "genome_id", sort = FALSE)
  panel <- merge(panel, order_audit, by = "order", all.x = TRUE, sort = FALSE)
  panel <- panel[match(selection$genome_id, panel$genome_id), , drop = FALSE]
  panel <- panel[c(
    "genome_id", "gtdb_accession", "gtdb_tree", "in_gtdb_bac120_tree",
    "domain", "phylum", "class", "order", "family", "genus", "species",
    "selection_step", "selection_stage",
    "marginal_phylogenetic_diversity", "order_candidate_genomes", "order_medoid",
    "medoid_mean_patristic_distance", "ncbi_organism_name", "ncbi_assembly_name",
    "ncbi_assembly_level", "ncbi_assembly_type", "ncbi_genome_representation",
    "ncbi_genome_category", "ncbi_bioproject", "ncbi_biosample", "ncbi_isolate",
    "ncbi_isolation_source", origin_columns, "ncbi_country", "ncbi_lat_lon", "ncbi_date",
    "ncbi_seq_rel_date", "ncbi_submitter", "ncbi_species_taxid", "ncbi_taxid",
    "ncbi_taxonomy", "ncbi_strain_identifiers", "ncbi_wgs_master",
    "ncbi_refseq_category",
    "gtdb_type_designation_ncbi_taxa", "ncbi_type_material_designation",
    "mimag_high_quality", "checkm2_completeness", "checkm2_contamination",
    "checkm_completeness", "checkm_contamination", "contig_count", "genome_size"
  )]
  panel$selection_rule <- paste0(
    "require at least one reviewed origin group; one eligible GTDB-order ",
    "phylogenetic medoid; balance every nonexclusive origin group toward 85 ",
    "genomes or retain all eligible genomes when fewer exist; avoid inflating ",
    "a completed group, then maximize marginal rooted Faith phylogenetic ",
    "diversity; accession tie-break"
  )
  panel$remote_filename <- paste0(panel$genome_id, ".fna.gz")
  panel <- panel[c(
    "genome_id", "remote_filename",
    setdiff(names(panel), c("genome_id", "remote_filename"))
  )]

  if (!setequal(unique(candidates$order), unique(panel$order)) ||
      !all(candidates$genome_id[candidates[[food_column]]] %in% panel$genome_id) ||
      !all(rowSums(panel[origin_group_columns]) > 0) ||
      any(colSums(panel[origin_group_columns]) < origin_targets) ||
      any(!panel$genome_id %in% candidate_tree$tip.label)) {
    stop("The selected GTDB panel violates its order, origin, or balance contract", call. = FALSE)
  }

  exclusions <- read_panel_exclusions(panel_exclusions_path)
  if (any(!exclusions$genome_id %in% panel$genome_id)) {
    stop("excluded-genomes.tsv names a genome the selection did not choose",
         call. = FALSE)
  }
  panel <- panel[!panel$genome_id %in% exclusions$genome_id, , drop = FALSE]
  if (!setequal(unique(candidates$order), unique(panel$order))) {
    stop("An excluded genome removes a GTDB order from the panel", call. = FALSE)
  }
  selected_pd <- rooted_faith_pd(candidate_tree, panel$genome_id)

  selected_tree <- ape::keep.tip(candidate_tree, panel$genome_id)
  write_tsv(panel, panel_manifest_path)
  ape::write.tree(selected_tree, file = panel_tree_path, digits = 10)
  any_candidate_group <- rowSums(candidates[origin_group_columns]) > 0
  any_panel_group <- rowSums(panel[origin_group_columns]) > 0
  origin_summary <- do.call(rbind, lapply(seq_len(nrow(origin_rules)), function(i) {
    column <- paste0("origin_", origin_rules$origin_group[[i]])
    selected_rows <- panel[[column]]
    data.frame(
      origin_group = origin_rules$origin_group[[i]],
      eligible_genomes = sum(candidates[[column]]),
      selected_genomes = sum(selected_rows),
      balance_target = unname(origin_targets[[column]]),
      selected_minus_balance_target = sum(selected_rows) - unname(origin_targets[[column]]),
      selected_panel_percent = round(100 * sum(selected_rows) / nrow(panel), 3),
      selected_phyla = length(unique(panel$phylum[selected_rows])),
      selected_classes = length(unique(panel$class[selected_rows])),
      selected_orders = length(unique(panel$order[selected_rows])),
      nonexclusive = TRUE,
      description = origin_rules$description[[i]],
      stringsAsFactors = FALSE
    )
  }))
  origin_summary <- rbind(
    origin_summary,
    data.frame(
      origin_group = "any_origin_group",
      eligible_genomes = sum(any_candidate_group),
      selected_genomes = sum(any_panel_group),
      balance_target = NA_integer_,
      selected_minus_balance_target = NA_integer_,
      selected_panel_percent = round(100 * sum(any_panel_group) / nrow(panel), 3),
      selected_phyla = length(unique(panel$phylum[any_panel_group])),
      selected_classes = length(unique(panel$class[any_panel_group])),
      selected_orders = length(unique(panel$order[any_panel_group])),
      nonexclusive = FALSE,
      description = "Genome assigned to at least one reviewed origin group",
      stringsAsFactors = FALSE
    )
  )
  write_tsv(origin_summary, origin_summary_path)
  has_value <- function(x) {
    !is.na(x) & nzchar(x) & !tolower(x) %in% c("none", "na")
  }

  audit <- data.frame(
    item = c(
      "GTDB release", "bacterial species representatives",
      "complete-genome species representatives", "complete-genome phyla",
      "complete-genome classes", "complete-genome orders",
      "origin-classified eligible representatives",
      "complete-genome representatives excluded without an origin group",
      "eligible phyla", "eligible classes", "eligible orders",
      "selected genomes", "selected phyla", "selected classes",
      "selected orders", "selected derived-from-metagenome assemblies",
      "selected derived-from-single-cell assemblies", "selected tree members",
      "selected with BioSample", "selected with BioProject",
      "selected with isolation source", "selected with country",
      "selected with latitude-longitude", "eligible food/fermentation origin",
      "selected food/fermentation origin", "selected animal-associated origin",
      "selected plant-associated origin", "selected with any origin group",
      "origin balance reference target", "GTDB order medoid seeds",
      "origin balance additions", "genomes excluded after selection",
      "minimum selected genomes per origin group",
      "median selected genomes per origin group",
      "maximum selected genomes per origin group", "selected rooted Faith PD",
      "eligible rooted Faith PD", "selected percent eligible rooted Faith PD",
      "selection rule", "tree sha256", "metadata sha256",
      "GTDB checksum manifest sha256", "origin rules sha256",
      "origin summary sha256", "selected manifest sha256",
      "selected tree sha256"
    ),
    value = c(
      "R11-RS232", sum(metadata$gtdb_representative == "t", na.rm = TRUE),
      nrow(complete_candidates), length(unique(complete_candidates$phylum)),
      length(unique(complete_candidates$class)),
      length(unique(complete_candidates$order)), nrow(candidates),
      sum(!complete_has_origin_group), length(unique(candidates$phylum)),
      length(unique(candidates$class)), length(unique(candidates$order)),
      nrow(panel), length(unique(panel$phylum)),
      length(unique(panel$class)), length(unique(panel$order)),
      sum(panel$ncbi_genome_category == "derived from metagenome", na.rm = TRUE),
      sum(panel$ncbi_genome_category == "derived from single cell", na.rm = TRUE),
      sum(panel$in_gtdb_bac120_tree), sum(has_value(panel$ncbi_biosample)),
      sum(has_value(panel$ncbi_bioproject)), sum(has_value(panel$ncbi_isolation_source)),
      sum(has_value(panel$ncbi_country)), sum(has_value(panel$ncbi_lat_lon)),
      sum(candidates[[food_column]]), sum(panel[[food_column]]),
      sum(panel$origin_animal_associated), sum(panel$origin_plant_associated),
      sum(any_panel_group), ORIGIN_BALANCE_TARGET, length(order_seeds),
      sum(panel$selection_stage ==
            "origin balance + marginal phylogenetic diversity"),
      nrow(exclusions),
      min(colSums(panel[origin_group_columns])),
      stats::median(colSums(panel[origin_group_columns])),
      max(colSums(panel[origin_group_columns])),
      selected_pd,
      sum(candidate_tree$edge.length),
      round(100 * selected_pd / sum(candidate_tree$edge.length), 3),
      unique(panel$selection_rule),
      sources$sha256[match("GTDB bacterial reference tree", sources$role)],
      sources$sha256[match("GTDB bacterial metadata", sources$role)],
      sources$sha256[match("GTDB published checksum manifest", sources$role)],
      sha256(origin_rules_path), sha256(origin_summary_path),
      sha256(panel_manifest_path), sha256(panel_tree_path)
    ),
    stringsAsFactors = FALSE
  )
  write_tsv(audit, panel_audit_path)

  # Assembly size of the GTDB species cluster each panel genome represents:
  # every R232 genome assigned to that representative, whatever its quality.
  # A cluster of one has no deviation.
  cluster_sizes <- data.table::fread(
    cmd = paste("gzip -dc", shQuote(metadata_path)),
    select = c("gtdb_genome_representative", "genome_size"),
    data.table = FALSE
  )
  cluster_sizes <- cluster_sizes[
    cluster_sizes$gtdb_genome_representative %in% panel$gtdb_accession, ,
    drop = FALSE
  ]
  if (anyNA(cluster_sizes$genome_size) ||
      !setequal(cluster_sizes$gtdb_genome_representative, panel$gtdb_accession)) {
    stop("GTDB metadata does not give a genome size for every panel species cluster",
         call. = FALSE)
  }
  by_cluster <- split(
    cluster_sizes$genome_size,
    factor(cluster_sizes$gtdb_genome_representative, levels = panel$gtdb_accession)
  )
  species_size <- data.frame(
    genome_id = panel$genome_id,
    gtdb_accession = panel$gtdb_accession,
    species = panel$species,
    cluster_genomes = lengths(by_cluster),
    mean_genome_size_bp = round(vapply(by_cluster, mean, numeric(1))),
    sd_genome_size_bp = round(vapply(by_cluster, stats::sd, numeric(1))),
    stringsAsFactors = FALSE
  )
  write_tsv(species_size, species_size_path)
  message("wrote ", species_size_path)
  message("wrote ", panel_manifest_path)
  message("wrote ", panel_tree_path)
  message("wrote ", origin_summary_path)
  message("wrote ", panel_audit_path)
}

if ("--prepare" %in% commandArgs(trailingOnly = TRUE)) {
  prepare_panel()
  quit(save = "no", status = 0L)
}

devtools::load_all(".", quiet = TRUE)

annotation_path <- Sys.getenv(
  "GTDB_PHYLOGENY_GIFTER_INPUT",
  file.path(drakkar_dir, "gifter_input.tsv.xz")
)
annotation_manifest_path <- file.path(drakkar_dir, "annotation_manifest.yaml")
annotation_qc_path <- file.path(drakkar_dir, "annotation_qc.tsv")
transfer_manifest_path <- file.path(drakkar_dir, "transfer-manifest.tsv")
transfer_complete_path <- file.path(drakkar_dir, "transfer.complete")
transferred_panel_path <- file.path(drakkar_dir, "selected-genomes.tsv")
download_resolution_path <- file.path(drakkar_dir, "resolved-downloads.tsv")
genome_checksum_path <- file.path(drakkar_dir, "genome-sha256.tsv")
assembly_summary_checksum_path <- file.path(drakkar_dir, "assembly-summary-sha256.txt")
remote_panel_checksum_path <- file.path(drakkar_dir, "selected-manifest-sha256.txt")
transferred_exclusions_path <- file.path(drakkar_dir, "excluded-genomes.tsv")

required <- c(
  panel_manifest_path, panel_tree_path, panel_audit_path, origin_rules_path,
  origin_summary_path, panel_exclusions_path, species_size_path,
  transferred_exclusions_path,
  annotation_path,
  annotation_manifest_path, annotation_qc_path, transfer_manifest_path,
  transfer_complete_path, transferred_panel_path, download_resolution_path,
  genome_checksum_path, assembly_summary_checksum_path, remote_panel_checksum_path
)
missing <- required[!file.exists(required)]
if (length(missing)) {
  stop(
    "GTDB phylogeny inputs are incomplete. Missing:\n  ",
    paste(missing, collapse = "\n  "),
    "\nPrepare the panel with --prepare, then complete the Drakkar transfer.",
    call. = FALSE
  )
}

panel <- read_tsv(panel_manifest_path)
tree <- ape::read.tree(panel_tree_path)
panel_size <- nrow(panel)
if (panel_size != 696L || anyDuplicated(panel$genome_id) ||
    length(tree$tip.label) != panel_size ||
    !setequal(panel$genome_id, tree$tip.label)) {
  stop("Selected manifest and tree do not describe the locked 696-genome panel",
       call. = FALSE)
}

transfer_manifest <- read_tsv(transfer_manifest_path)
expected_transfer_files <- c(
  "gifter_input.tsv.xz", "annotation_manifest.yaml", "annotation_qc.tsv",
  "selected-genomes.tsv", "resolved-downloads.tsv", "genome-sha256.tsv",
  "assembly-summary-sha256.txt", "selected-manifest-sha256.txt",
  "excluded-genomes.tsv"
)
if (!identical(names(transfer_manifest), c("file", "bytes", "sha256")) ||
    anyDuplicated(transfer_manifest$file) ||
    !setequal(transfer_manifest$file, expected_transfer_files)) {
  stop("transfer-manifest.tsv does not describe the expected GTDB transfer",
       call. = FALSE)
}
transfer_paths <- file.path(drakkar_dir, transfer_manifest$file)
transfer_paths[transfer_manifest$file == "gifter_input.tsv.xz"] <- annotation_path
if (any(!file.exists(transfer_paths))) {
  stop("Fetched transfer is incomplete", call. = FALSE)
}
observed_sha <- vapply(transfer_paths, sha256, character(1))
observed_bytes <- unname(file.info(transfer_paths)$size)
if (!identical(unname(observed_sha), transfer_manifest$sha256) ||
    !identical(as.numeric(observed_bytes), as.numeric(transfer_manifest$bytes))) {
  stop("Fetched Drakkar files do not match transfer-manifest.tsv", call. = FALSE)
}
# Mjolnir acquired every genome the selection chose. The annotated set is that
# manifest minus the exclusion record, and must be exactly the locked panel.
if (!identical(sha256(transferred_exclusions_path), sha256(panel_exclusions_path))) {
  stop("The transferred exclusion record differs from the committed one", call. = FALSE)
}
exclusions <- read_panel_exclusions(panel_exclusions_path)
transferred_panel <- read_tsv(transferred_panel_path)
transferred_panel <- transferred_panel[
  !transferred_panel$genome_id %in% exclusions$genome_id, , drop = FALSE
]
rownames(transferred_panel) <- NULL
if (!isTRUE(all.equal(transferred_panel, panel, check.attributes = FALSE)) ||
    !identical(names(transferred_panel), names(panel))) {
  stop("The remotely annotated panel differs from the locked local panel", call. = FALSE)
}

manifest_lines <- readLines(annotation_manifest_path, warn = FALSE)
manifest_schema <- manifest_value(manifest_lines, "schema_version")
drakkar_version <- manifest_value(manifest_lines, "drakkar_version")
if (manifest_schema != "drakkar-annotation-manifest-v1" ||
    drakkar_version != "2.6.6") {
  stop(
    "Expected Drakkar 2.6.6 with annotation manifest schema v1; observed ",
    drakkar_version, " and ", manifest_schema, call. = FALSE
  )
}

annotation_qc <- read_tsv(annotation_qc_path)
expected_qc_columns <- c(
  "mag", "level", "source", "reported_records", "retained_records",
  "rejected_records", "unmapped_records", "unique_entities", "filter_stage",
  "database_release", "database_source_version", "database_checksums"
)
expected_annotation_sources <- c(
  "cazy", "kegg", "ncbifam", "pfam", "prodigal", "tigrfam"
)
qc_key <- paste(annotation_qc$mag, annotation_qc$source, sep = "\r")
if (!identical(names(annotation_qc), expected_qc_columns) ||
    anyNA(annotation_qc[c("mag", "level", "source")]) ||
    anyDuplicated(qc_key) ||
    !setequal(annotation_qc$mag, panel$genome_id) ||
    !setequal(annotation_qc$source, expected_annotation_sources) ||
    any(table(annotation_qc$mag) != length(expected_annotation_sources)) ||
    any(annotation_qc$level != "gene")) {
  stop("annotation_qc.tsv does not contain one record per source and panel genome",
       call. = FALSE)
}

annotations <- read_xz_tsv(annotation_path)
expected_columns <- c("genome_id", "gene_id", "namespace", "accession")
if (!identical(names(annotations), expected_columns) || anyNA(annotations) ||
    any(!nzchar(annotations$genome_id)) || any(!nzchar(annotations$gene_id)) ||
    any(!nzchar(annotations$namespace)) || any(!nzchar(annotations$accession))) {
  stop("Drakkar gifter input has an invalid schema or missing values", call. = FALSE)
}
if (!setequal(unique(annotations$genome_id), panel$genome_id)) {
  stop("Drakkar output does not cover exactly the selected GTDB panel", call. = FALSE)
}
marker_rows <- nrow(annotations)

complete_record <- read_key_value(transfer_complete_path)
completed_genomes <- suppressWarnings(as.integer(
  complete_record$value[complete_record$item == "genomes"]
))
completed_rows <- suppressWarnings(as.numeric(
  complete_record$value[complete_record$item == "marker_rows"]
))
if (!identical(completed_genomes, panel_size) || length(completed_rows) != 1L ||
    completed_rows != marker_rows) {
  stop("transfer.complete does not match the marker table", call. = FALSE)
}

annotation_sha <- sha256(annotation_path)
database_sha <- sha256("inst/extdata/gifter.sqlite")
cache_key <- paste(annotation_sha, database_sha, sep = "-")
community_cache <- file.path(cache_dir, paste0("community-", cache_key, ".rds"))
workers <- suppressWarnings(as.integer(Sys.getenv("GTDB_PHYLOGENY_WORKERS", "8")))
if (is.na(workers) || workers < 1L) workers <- 1L
workers <- min(workers, panel_size)

if (file.exists(community_cache)) {
  cat("Reading cached GTDB genome calls...\n")
  community <- readRDS(community_cache)
} else {
  cat(
    "Evaluating ", panel_size,
    " GTDB origin-classified complete-genome species representatives with ",
    workers, " workers...\n", sep = ""
  )
  community <- evaluate_gifts_community(
    annotations, genome_id = "genome_id", gene_id = "gene_id",
    max_genes = Inf, workers = workers, progress = TRUE
  )
  community_cache_part <- paste0(community_cache, ".part")
  saveRDS(community, community_cache_part, compress = "xz")
  if (!file.rename(community_cache_part, community_cache)) {
    stop("Could not finalize the GTDB call cache", call. = FALSE)
  }
}
rm(annotations)
invisible(gc(FALSE))

expected_gifts <- as.data.frame(list_gifts())$gift_id
if (!setequal(community$genome_id, panel$genome_id) ||
    !setequal(community$gift_id, expected_gifts) ||
    !identical(dim(community$matrix), c(length(expected_gifts), panel_size))) {
  stop("The evaluated community does not match the panel and current catalogue",
       call. = FALSE)
}

calls <- do.call(rbind, lapply(panel$genome_id, function(genome_id) {
  row <- as.data.frame(community$results[[genome_id]]$gifts)
  result <- data.frame(
    genome_id = genome_id,
    gift_id = row$gift_id,
    gift_type = row$gift_type,
    mode = row$mode,
    gift_name = row$name,
    complete = row$complete,
    evidence_confidence = row$evidence_confidence,
    best_implementation = row$best_implementation,
    number_of_complete_implementations = row$number_of_complete_implementations,
    minimum_missing_requirements = row$minimum_missing_requirements,
    completeness_score = row$completeness_score,
    stringsAsFactors = FALSE
  )
  result$missing_requirements <- collapse_values(row$missing_requirements)
  result$supporting_components <- collapse_values(row$supporting_components)
  result$supporting_markers <- collapse_values(row$supporting_markers)
  result$supporting_genes <- collapse_values(row$supporting_genes)
  result
}))

if (nrow(calls) != panel_size * length(expected_gifts) ||
    !setequal(unique(calls$gift_id), expected_gifts) ||
    any(table(calls$genome_id) != length(expected_gifts)) ||
    any(table(calls$gift_id) != panel_size)) {
  stop("The result does not contain one call per current GIFT and genome", call. = FALSE)
}

confidence_rank <- c(
  "insufficient evidence" = 0L, ambiguous = 1L, putative = 2L,
  "high-confidence" = 3L, curated = 4L
)
calls$confidence_rank <- unname(confidence_rank[calls$evidence_confidence])
if (anyNA(calls$confidence_rank[calls$complete])) {
  stop("A supported call has an unknown evidence-confidence value", call. = FALSE)
}
calls$confidence_rank[is.na(calls$confidence_rank)] <- 0L
calls$passes_high_confidence <- calls$complete & calls$confidence_rank >= 3L

supported <- calls[calls$complete, , drop = FALSE]
count_rows <- function(rows, label) {
  count <- table(factor(rows$genome_id, levels = panel$genome_id))
  data.frame(genome_id = panel$genome_id, metric = label, value = as.integer(count))
}
genome_metrics <- rbind(
  count_rows(supported, "all supported GIFTs"),
  count_rows(calls[calls$passes_high_confidence, ], "supported at high-confidence or curated"),
  do.call(rbind, lapply(sort(unique(calls$gift_type)), function(type) {
    count_rows(supported[supported$gift_type == type, ], paste(type, "GIFTs"))
  }))
)

metric_wide <- reshape(genome_metrics, idvar = "genome_id", timevar = "metric", direction = "wide")
names(metric_wide) <- sub("^value[.]", "", names(metric_wide))
genome_summary <- merge(panel, metric_wide, by = "genome_id", sort = FALSE)
genome_summary <- genome_summary[match(panel$genome_id, genome_summary$genome_id), ]

gift_summary <- aggregate(
  cbind(
    complete = as.integer(calls$complete),
    high_confidence = as.integer(calls$passes_high_confidence)
  ) ~ gift_id,
  calls, sum
)
gift_metadata <- unique(calls[c("gift_id", "gift_type", "mode", "gift_name")])
if (anyDuplicated(gift_metadata$gift_id)) {
  stop("GIFT metadata changed between genome evaluations", call. = FALSE)
}
gift_summary <- merge(gift_metadata, gift_summary, by = "gift_id", sort = FALSE)
gift_summary$genomes <- panel_size
gift_summary$prevalence <- gift_summary$complete / gift_summary$genomes
gift_summary$high_confidence_prevalence <- gift_summary$high_confidence / gift_summary$genomes
gift_summary <- gift_summary[order(gift_summary$gift_type, gift_summary$mode, gift_summary$gift_name), ]
gift_summary$heatmap_column <- seq_len(nrow(gift_summary))

calls <- calls[order(
  match(calls$genome_id, panel$genome_id),
  match(calls$gift_id, gift_summary$gift_id)
), ]
rownames(calls) <- NULL

phylum_summary <- aggregate(
  cbind(
    supported = genome_summary$`all supported GIFTs`,
    high_confidence = genome_summary$`supported at high-confidence or curated`
  ) ~ phylum,
  genome_summary,
  function(x) c(genomes = length(x), median = stats::median(x), min = min(x), max = max(x))
)
phylum_summary <- data.frame(
  phylum = phylum_summary$phylum,
  genomes = phylum_summary$supported[, "genomes"],
  median_supported = phylum_summary$supported[, "median"],
  min_supported = phylum_summary$supported[, "min"],
  max_supported = phylum_summary$supported[, "max"],
  median_high_confidence = phylum_summary$high_confidence[, "median"],
  min_high_confidence = phylum_summary$high_confidence[, "min"],
  max_high_confidence = phylum_summary$high_confidence[, "max"],
  stringsAsFactors = FALSE
)
phylum_summary <- phylum_summary[order(-phylum_summary$genomes, phylum_summary$phylum), ]

write_xz_tsv(calls, file.path(output_dir, "gtdb-phylogeny-calls.tsv.xz"))
write_tsv(genome_summary, file.path(output_dir, "gtdb-phylogeny-genome-summary.tsv"))
write_tsv(gift_summary, file.path(output_dir, "gtdb-phylogeny-gift-summary.tsv"))
write_tsv(phylum_summary, file.path(output_dir, "gtdb-phylogeny-phylum-summary.tsv"))

audit <- data.frame(
  item = c(
    "GTDB release", "selected genomes", "selected orders", "selected classes",
    "selected phyla", "current GIFTs", "genome-GIFT calls",
    "marker rows", "supported genome-GIFT pairs", "represented GIFTs",
    "evaluation function", "community cache key", "package version",
    "database version", "database schema version",
    "Drakkar version", "annotation manifest schema",
    "panel selection audit sha256", "origin rules sha256",
    "origin summary sha256", "selected manifest sha256", "selected tree sha256",
    "gifter input sha256", "annotation manifest sha256", "annotation QC sha256",
    "transfer manifest sha256", "transfer completion record sha256",
    "remote selected-manifest checksum record sha256",
    "download resolution sha256", "genome checksum manifest sha256",
    "NCBI assembly summary checksum record sha256",
    "exclusion record sha256", "species genome-size summary sha256",
    "gifter SQLite sha256", "analysis script sha256"
  ),
  value = c(
    "R11-RS232", nrow(panel), length(unique(panel$order)),
    length(unique(panel$class)), length(unique(panel$phylum)),
    length(expected_gifts), nrow(calls),
    marker_rows, nrow(supported), length(unique(supported$gift_id)),
    "evaluate_gifts_community()", cache_key, gifter_db_version()$package_version,
    gifter_db_version()$gifter_db_version, gifter_db_version()$schema_version,
    drakkar_version, manifest_schema,
    sha256(panel_audit_path), sha256(origin_rules_path), sha256(origin_summary_path),
    sha256(panel_manifest_path), sha256(panel_tree_path), sha256(annotation_path),
    sha256(annotation_manifest_path), sha256(annotation_qc_path),
    sha256(transfer_manifest_path), sha256(transfer_complete_path),
    sha256(remote_panel_checksum_path),
    sha256(download_resolution_path), sha256(genome_checksum_path),
    sha256(assembly_summary_checksum_path),
    sha256(panel_exclusions_path), sha256(species_size_path),
    database_sha, sha256("manuscript/analysis/23-gtdb-phylogeny.R")
  ),
  stringsAsFactors = FALSE
)
write_tsv(audit, file.path(output_dir, "gtdb-phylogeny-input-audit.tsv"))

# -------------------------------------------------------------------- Figure S4

tree_plot <- ggtree::ggtree(tree, linewidth = 0.18, colour = "#777772")
tip_data <- tree_plot$data[tree_plot$data$isTip, c("label", "y")]
names(tip_data)[[1L]] <- "genome_id"

figure_calls <- merge(
  calls, tip_data, by = "genome_id", all.x = TRUE, sort = FALSE
)
gift_order <- gift_summary$gift_id
figure_calls$gift_id <- factor(figure_calls$gift_id, levels = gift_order)
figure_calls$gift_type <- factor(
  figure_calls$gift_type,
  levels = c("metabolic", "structural", "regulatory", "defense")
)
figure_calls$status <- "unsupported"
figure_calls$status[figure_calls$complete & figure_calls$evidence_confidence == "ambiguous"] <- "ambiguous"
figure_calls$status[figure_calls$complete & figure_calls$evidence_confidence == "putative"] <- "putative"
figure_calls$status[figure_calls$complete & figure_calls$evidence_confidence == "high-confidence"] <- "high-confidence"
figure_calls$status[figure_calls$complete & figure_calls$evidence_confidence == "curated"] <- "curated"
figure_calls$status <- factor(
  figure_calls$status,
  levels = c("unsupported", "ambiguous", "putative", "high-confidence", "curated")
)

tip_panel <- merge(panel, tip_data, by = "genome_id", sort = FALSE)
phylum_counts <- sort(table(tip_panel$phylum), decreasing = TRUE)
major_phyla <- names(phylum_counts)[seq_len(min(12L, length(phylum_counts)))]
tip_panel$phylum_group <- ifelse(tip_panel$phylum %in% major_phyla,
                                 strip_rank(tip_panel$phylum), "other phyla")
phylum_levels <- c(strip_rank(major_phyla), "other phyla")
tip_panel$phylum_group <- factor(tip_panel$phylum_group, levels = phylum_levels)
phylum_colours <- setNames(
  c(grDevices::hcl.colors(length(major_phyla), "Dark 3"), "#d5d4cf"),
  phylum_levels
)

# Name each major phylum once, beside its longest run of consecutive tips.
tip_order <- tip_panel[order(tip_panel$y), ]
phylum_runs <- rle(as.character(tip_order$phylum_group))
run_end <- cumsum(phylum_runs$lengths)
run_start <- run_end - phylum_runs$lengths + 1L
phylum_runs <- data.frame(
  phylum_group = phylum_runs$values, tips = phylum_runs$lengths,
  y = (tip_order$y[run_start] + tip_order$y[run_end]) / 2,
  stringsAsFactors = FALSE
)
phylum_runs <- phylum_runs[phylum_runs$phylum_group != "other phyla", ]
phylum_labels <- do.call(rbind, lapply(
  split(phylum_runs, phylum_runs$phylum_group),
  function(runs) runs[which.max(runs$tips), ]
))

species_size <- read_tsv(species_size_path)
if (!identical(species_size$genome_id, panel$genome_id) ||
    anyNA(species_size$mean_genome_size_bp) ||
    any(species_size$cluster_genomes < 1L) ||
    any(is.na(species_size$sd_genome_size_bp) != (species_size$cluster_genomes == 1L))) {
  stop("species-genome-size.tsv does not describe the locked panel", call. = FALSE)
}
species_size <- merge(species_size, tip_data, by = "genome_id", sort = FALSE)
species_size$mean_mb <- species_size$mean_genome_size_bp / 1e6
species_size$sd_mb <- species_size$sd_genome_size_bp / 1e6

n_tips <- length(tree$tip.label)
shared_y <- scale_y_continuous(limits = c(0.5, n_tips + 0.5), expand = c(0, 0))

panel_a <- tree_plot +
  shared_y +
  labs(title = "a  GTDB bac120 tree") +
  theme_void(base_size = 7) +
  theme(
    plot.title = element_text(size = 8, face = "bold", hjust = 0),
    plot.margin = margin(4, 0, 4, 4)
  )

panel_phylum_names <- ggplot(phylum_labels, aes(x = 1, y = y, label = phylum_group)) +
  geom_text(hjust = 1, size = 1.75, colour = "#252522") +
  shared_y +
  scale_x_continuous(limits = c(0, 1), expand = expansion(add = c(0, 0.04))) +
  coord_cartesian(clip = "off") +
  theme_void(base_size = 7) +
  theme(plot.margin = margin(4, 0, 4, 0))

panel_b <- ggplot(tip_panel, aes(x = 1, y = y, fill = phylum_group)) +
  geom_tile(width = 1, height = 1) +
  shared_y +
  scale_fill_manual(values = phylum_colours, drop = FALSE) +
  labs(title = "b", fill = "GTDB phylum") +
  theme_void(base_size = 7) +
  theme(
    plot.title = element_text(size = 8, face = "bold", hjust = 0),
    legend.position = "bottom",
    legend.text = element_text(size = 5.5),
    legend.key.height = grid::unit(2, "mm"),
    legend.key.width = grid::unit(2, "mm"),
    plot.margin = margin(4, 0, 4, 0)
  ) +
  guides(fill = guide_legend(nrow = 2, byrow = TRUE))

panel_c <- ggplot(figure_calls, aes(x = gift_id, y = y, fill = status)) +
  geom_raster() +
  facet_grid(
    cols = vars(gift_type), scales = "free_x", space = "free_x",
    labeller = as_labeller(c(
      metabolic = "metabolic", structural = "str.",
      regulatory = "reg.", defense = "def."
    ))
  ) +
  shared_y +
  scale_fill_manual(values = c(
    unsupported = "#f2f1ed", ambiguous = "#efc46d", putative = "#a8c7e8",
    `high-confidence` = "#5689c5", curated = "#234f84"
  ), drop = FALSE) +
  labs(title = "c  Encoded GIFTs", fill = "Call evidence") +
  theme_void(base_size = 7) +
  theme(
    strip.text = element_text(size = 5.6, face = "bold", colour = "#252522"),
    strip.background = element_rect(fill = "#e9e8e3", colour = NA),
    panel.spacing.x = grid::unit(0.7, "mm"),
    plot.title = element_text(size = 8, face = "bold", hjust = 0),
    legend.position = "bottom",
    legend.text = element_text(size = 6),
    legend.key.height = grid::unit(2, "mm"),
    legend.key.width = grid::unit(3, "mm"),
    plot.margin = margin(4, 0, 4, 0)
  ) +
  guides(fill = guide_legend(nrow = 1))

richness <- merge(
  genome_summary[c(
    "genome_id", "all supported GIFTs",
    "supported at high-confidence or curated"
  )],
  tip_data, by = "genome_id", sort = FALSE
)
panel_d <- ggplot(richness, aes(y = y)) +
  geom_segment(aes(
    x = `supported at high-confidence or curated`,
    xend = `all supported GIFTs`, yend = y
  ), colour = "#bab9b4", linewidth = 0.25) +
  geom_point(aes(x = `all supported GIFTs`, colour = "all accepted"), size = 0.55) +
  geom_point(aes(
    x = `supported at high-confidence or curated`, colour = "high-confidence+"
  ), size = 0.55) +
  shared_y +
  scale_colour_manual(values = c("all accepted" = "#234f84", "high-confidence+" = "#ef8a47")) +
  scale_x_continuous(expand = expansion(mult = c(0.02, 0.08))) +
  labs(title = "d  Repertoire", x = "supported GIFTs", colour = NULL) +
  theme_minimal(base_size = 7) +
  theme(
    panel.grid.major.y = element_blank(), panel.grid.minor = element_blank(),
    axis.text.y = element_blank(), axis.title.y = element_blank(),
    plot.title = element_text(size = 8, face = "bold", hjust = 0),
    axis.title.x = element_text(size = 6),
    legend.position = "bottom", legend.text = element_text(size = 6),
    legend.key.width = grid::unit(2.5, "mm"),
    plot.margin = margin(4, 6, 4, 0)
  )

panel_e <- ggplot(species_size, aes(y = y)) +
  geom_segment(
    data = species_size[!is.na(species_size$sd_mb), ],
    aes(x = pmax(mean_mb - sd_mb, 0), xend = mean_mb + sd_mb, yend = y),
    colour = "#bab9b4", linewidth = 0.25
  ) +
  geom_point(aes(x = mean_mb), colour = "#3f7a5c", size = 0.55) +
  shared_y +
  scale_x_continuous(expand = expansion(mult = c(0.02, 0.08))) +
  labs(title = "e  Genome size", x = "mean \u00b1 s.d. (Mb)") +
  theme_minimal(base_size = 7) +
  theme(
    panel.grid.major.y = element_blank(), panel.grid.minor = element_blank(),
    axis.text.y = element_blank(), axis.title.y = element_blank(),
    plot.title = element_text(size = 8, face = "bold", hjust = 0),
    axis.title.x = element_text(size = 6),
    plot.margin = margin(4, 4, 4, 0)
  )

wrap_text <- function(x, width) paste(strwrap(x, width = width), collapse = "\n")

figure <- panel_a + panel_phylum_names + panel_b + panel_c + panel_d + panel_e +
  plot_layout(widths = c(1.1, 0.5, 0.08, 3.2, 0.85, 0.85), guides = "collect") +
  plot_annotation(
    title = "Encoded GIFT repertoires across a broad bacterial phylogeny",
    subtitle = wrap_text(paste0(
      format(panel_size, big.mark = ","),
      " balanced origin-classified complete-genome GTDB R11-RS232 species representatives × ",
      format(length(expected_gifts), big.mark = ","),
      " current GIFTs, spanning every eligible order; ",
      "gene-resolved Drakkar evidence evaluated against gifter database ",
      gifter_db_version()$gifter_db_version
    ), 140),
    caption = wrap_text(paste0(
      "Rows follow the pruned GTDB bac120 tree; columns include every current GIFT. ",
      "Genome size is the mean and standard deviation over all GTDB genomes of the species each row represents; a species with one genome has no deviation. ",
      "Unsupported is not evidence of biological absence. The panel describes encoded capability, not activity or phenotype."
    ), 165),
    theme = theme(
      legend.position = "bottom", legend.box = "vertical",
      legend.box.just = "left", legend.spacing.y = grid::unit(0.5, "mm"),
      legend.margin = margin(0, 0, 0, 0),
      plot.title = element_text(size = 10, face = "bold"),
      plot.subtitle = element_text(size = 7.5, colour = "#555550"),
      plot.caption = element_text(size = 6.5, colour = "#666660", hjust = 0)
    )
  )

ggsave(
  file.path(figure_dir, "figure-s4-gtdb-phylogeny.pdf"), figure,
  width = 190, height = 230, units = "mm", device = grDevices::cairo_pdf,
  bg = "white"
)
ggsave(
  file.path(figure_dir, "figure-s4-gtdb-phylogeny.png"), figure,
  width = 190, height = 230, units = "mm", dpi = 320, bg = "white"
)

cat("Wrote GTDB phylogeny summaries and Figure S4.\n")
