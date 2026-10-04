# GTDB overview follow-up: near misses and the phylogenetic signal of each GIFT.
#
# 1. A GIFT is unsupported when no curated implementation is complete. The call
#    table of 23-gtdb-phylogeny.R keeps the closest implementation and what it
#    lacks, so an unsupported call can be read: here a near miss is an
#    unsupported GIFT whose closest implementation has at least two
#    requirements and lacks exactly one. A requirement that most of a lineage
#    lacks while the rest of the implementation is present is a candidate for
#    an enzyme, component or route the catalogue has not curated -- or for a
#    capability that lineage really does not encode. The table ranks those
#    candidates; it decides nothing, and nothing here changes a call.
# 2. Fritz and Purvis's D measures how each GIFT is distributed over the pruned
#    GTDB bac120 tree: about 0 when it is as clumped as a trait evolving by
#    Brownian motion, about 1 when it is scattered at random, below 0 when it
#    is more conserved than Brownian motion.
#
# A near miss is not partial support and is never counted as a call. Signal
# describes how encoded, curated capabilities are distributed over this panel;
# it is not an ancestral-state reconstruction. The test against Brownian motion
# is one-sided, so a negative D is read as "as conserved as Brownian motion".
#
# Run from the repository root after 26-gtdb-repertoire-genome-size.R:
#   Rscript manuscript/analysis/29-gtdb-near-misses-and-gift-signal.R

suppressWarnings(suppressPackageStartupMessages({
  library(ggplot2)
  library(patchwork)
}))

root <- "manuscript/analysis"
case_dir <- file.path(root, "gtdb-phylogeny")
output_dir <- Sys.getenv("GTDB_PHYLOGENY_OUTPUT_DIR", file.path(root, "output"))
figure_dir <- Sys.getenv("GTDB_PHYLOGENY_FIGURE_DIR", "manuscript/figures")

SEED <- 20261004L
FDR <- 0.05
NEAR_MISS_SCORE <- 0.5
MIN_TAXON_GENOMES <- 5L
MIN_GIFT_GENOMES <- 10L
D_PERMUTATIONS <- 1000L
HEATMAP_GAPS <- 30L
LABELLED_PER_DIRECTION <- 6L
workers <- suppressWarnings(as.integer(Sys.getenv("GTDB_PHYLOGENY_WORKERS", "8")))
if (is.na(workers) || workers < 1L) workers <- 1L

read_tsv <- function(path) {
  utils::read.delim(path, check.names = FALSE, stringsAsFactors = FALSE)
}
write_tsv <- function(x, path) {
  utils::write.table(
    x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = ""
  )
}
read_xz_tsv <- function(path) {
  connection <- xzfile(path, open = "rt")
  on.exit(close(connection), add = TRUE)
  read_tsv(connection)
}
wrap_text <- function(x, width) paste(strwrap(x, width = width), collapse = "\n")
pretty_name <- function(x) gsub("_", " ", x)
strip_rank <- function(x) sub("^[a-z]__", "", x)

tree_path <- file.path(case_dir, "selected-genomes.tree")
deviation_path <- file.path(output_dir, "gtdb-size-expectation-genomes.tsv")
taxa_path <- file.path(output_dir, "gtdb-size-expectation-taxa.tsv")
calls_path <- file.path(output_dir, "gtdb-phylogeny-calls.tsv.xz")
missing <- c(tree_path, deviation_path, taxa_path, calls_path)
missing <- missing[!file.exists(missing)]
if (length(missing)) {
  stop("Run 23-gtdb-phylogeny.R and 26-gtdb-repertoire-genome-size.R first. Missing:\n  ",
       paste(missing, collapse = "\n  "), call. = FALSE)
}

tree <- ape::read.tree(tree_path)
tree$node.label <- NULL
genomes <- read_tsv(deviation_path)
if (anyDuplicated(genomes$genome_id) ||
    !setequal(genomes$genome_id, tree$tip.label)) {
  stop("The deviation table and the panel tree do not describe the same genomes",
       call. = FALSE)
}
genomes <- genomes[match(tree$tip.label, genomes$genome_id), ]
rownames(genomes) <- genomes$genome_id

calls <- read_xz_tsv(calls_path)
calls$complete <- as.logical(calls$complete)
gift_metadata <- unique(calls[c("gift_id", "gift_type", "mode", "gift_name")])
n_gifts <- nrow(gift_metadata)

# ---------------------------------------------------------------- 1. near misses

calls$near_miss <- !calls$complete &
  calls$minimum_missing_requirements == 1L &
  calls$completeness_score >= NEAR_MISS_SCORE
near <- calls[calls$near_miss, ]
if (any(grepl(";", near$missing_requirements, fixed = TRUE))) {
  stop("A near miss lists more than one missing requirement", call. = FALSE)
}

count_by_genome <- function(rows) {
  as.integer(table(factor(rows$genome_id, levels = genomes$genome_id)))
}
genomes$near_misses <- count_by_genome(near)
genomes$unsupported <- n_gifts - genomes$supported
genomes$supported_with_near_misses <- genomes$supported + genomes$near_misses

near_fit <- phylolm::phylolm(
  residual ~ near_misses, data = genomes, phy = tree, model = "lambda"
)
near_coefficient <- summary(near_fit)$coefficients["near_misses", ]
near_rank <- suppressWarnings(stats::cor.test(
  genomes$residual, genomes$near_misses, method = "spearman"
))

taxa <- read_tsv(taxa_path)
phyla <- taxa[taxa$rank == "phylum", ]
phylum_sizes <- table(genomes$phylum)
near_by_phylum <- do.call(rbind, lapply(phyla$taxon, function(phylum) {
  rows <- genomes[genomes$phylum == phylum, ]
  data.frame(
    phylum = phylum, genomes = nrow(rows),
    size_deviation = phyla$deviation[phyla$taxon == phylum],
    median_residual = stats::median(rows$residual),
    median_supported = stats::median(rows$supported),
    median_near_misses = stats::median(rows$near_misses),
    mean_near_misses = mean(rows$near_misses),
    median_residual_counting_near_misses =
      stats::median(rows$residual + rows$near_misses),
    stringsAsFactors = FALSE
  )
}))
near_by_phylum <- near_by_phylum[order(near_by_phylum$median_residual), ]

# One row per GIFT, implementation and missing requirement: how many genomes are
# one step short on it, and how concentrated they are in one phylum.
near$phylum <- genomes[near$genome_id, "phylum"]
gap_key <- paste(near$gift_id, near$best_implementation, near$missing_requirements, sep = "\r")
gaps <- do.call(rbind, lapply(split(near, gap_key), function(rows) {
  by_phylum <- table(rows$phylum)
  tested <- by_phylum[names(by_phylum) %in% phyla$taxon]
  share <- tested / as.numeric(phylum_sizes[names(tested)])
  top <- if (length(share)) names(share)[which.max(share)] else NA_character_
  gift <- rows$gift_id[[1L]]
  data.frame(
    gift_id = gift, gift_type = rows$gift_type[[1L]], mode = rows$mode[[1L]],
    implementation = rows$best_implementation[[1L]],
    missing_requirement = rows$missing_requirements[[1L]],
    genomes_one_step_short = nrow(rows),
    genomes_supporting_gift = sum(calls$complete[calls$gift_id == gift]),
    phyla_affected = length(by_phylum),
    most_affected_phylum = top,
    genomes_in_that_phylum = if (is.na(top)) NA_integer_ else as.integer(phylum_sizes[[top]]),
    one_step_short_in_that_phylum = if (is.na(top)) NA_integer_ else as.integer(tested[[top]]),
    share_of_that_phylum = if (is.na(top)) NA_real_ else as.numeric(share[[top]]),
    stringsAsFactors = FALSE
  )
}))
gaps <- gaps[order(-gaps$genomes_one_step_short), ]
rownames(gaps) <- NULL

# ---------------------------------------------- 2. phylogenetic signal per GIFT

supported <- tapply(calls$complete, list(calls$genome_id, calls$gift_id), any)
supported <- supported[genomes$genome_id, gift_metadata$gift_id, drop = FALSE]
estimable <- gift_metadata$gift_id[
  pmin(colSums(supported), colSums(!supported)) >= MIN_GIFT_GENOMES
]

RNGkind("L'Ecuyer-CMRG")
set.seed(SEED)
signal <- parallel::mclapply(estimable, function(gift) {
  data <- data.frame(
    genome_id = genomes$genome_id, present = as.integer(supported[, gift]),
    stringsAsFactors = FALSE
  )
  d <- caper::phylo.d(
    data, tree, names.col = genome_id, binvar = present, permut = D_PERMUTATIONS
  )
  data.frame(
    gift_id = gift, supporting_genomes = sum(data$present),
    prevalence = mean(data$present), d_statistic = unname(d$DEstimate),
    p_random = unname(d$Pval1), p_brownian = unname(d$Pval0),
    stringsAsFactors = FALSE
  )
}, mc.cores = workers, mc.set.seed = TRUE)
failed <- !vapply(signal, is.data.frame, logical(1))
if (any(failed)) {
  stop("The D statistic failed for: ", paste(estimable[failed], collapse = ", "),
       call. = FALSE)
}
signal <- merge(gift_metadata, do.call(rbind, signal), by = "gift_id", sort = FALSE)
signal$q_random <- stats::p.adjust(signal$p_random, method = "BH")
signal$q_brownian <- stats::p.adjust(signal$p_brownian, method = "BH")
signal$distribution <- ifelse(
  signal$q_random >= FDR, "not distinguishable from random",
  ifelse(signal$q_brownian >= FDR, "as conserved as Brownian motion",
         "between Brownian motion and random")
)
signal$class <- ifelse(
  signal$gift_type == "metabolic", paste("metabolic,", signal$mode), signal$gift_type
)
signal <- signal[order(signal$d_statistic), ]
rownames(signal) <- NULL

signal_by_class <- do.call(rbind, lapply(split(signal, signal$class), function(rows) {
  data.frame(
    class = rows$class[[1L]], gifts = nrow(rows),
    median_d = stats::median(rows$d_statistic),
    lower_quartile_d = unname(stats::quantile(rows$d_statistic, 0.25)),
    upper_quartile_d = unname(stats::quantile(rows$d_statistic, 0.75)),
    stringsAsFactors = FALSE
  )
}))
signal_by_class <- signal_by_class[order(signal_by_class$median_d), ]
rownames(signal_by_class) <- NULL
mode_test <- suppressWarnings(stats::wilcox.test(
  signal$d_statistic[signal$class == "metabolic, catabolic"],
  signal$d_statistic[signal$class == "metabolic, anabolic"], exact = FALSE
))
prevalence_rank <- suppressWarnings(stats::cor.test(
  signal$prevalence, signal$d_statistic, method = "spearman"
))

# ----------------------------------------------------------------------- tables

signif_columns <- function(table, columns, digits = 4) {
  for (column in columns) table[[column]] <- signif(table[[column]], digits)
  table
}
write_tsv(
  genomes[c(
    "genome_id", "phylum", "class", "species", "genome_size", "supported",
    "near_misses", "unsupported", "supported_with_near_misses", "expected",
    "residual"
  )],
  file.path(output_dir, "gtdb-near-miss-genomes.tsv")
)
write_tsv(
  signif_columns(near_by_phylum, c(
    "median_residual", "mean_near_misses", "median_residual_counting_near_misses"
  )),
  file.path(output_dir, "gtdb-near-miss-phyla.tsv")
)
write_tsv(
  signif_columns(gaps, "share_of_that_phylum"),
  file.path(output_dir, "gtdb-near-miss-requirements.tsv")
)
write_tsv(
  signif_columns(signal[c(
    "gift_id", "gift_type", "mode", "supporting_genomes", "prevalence",
    "d_statistic", "p_random", "p_brownian", "q_random", "q_brownian",
    "distribution"
  )], c("prevalence", "d_statistic", "q_random", "q_brownian")),
  file.path(output_dir, "gtdb-gift-phylogenetic-signal.tsv")
)
write_tsv(
  signif_columns(signal_by_class, c("median_d", "lower_quartile_d", "upper_quartile_d")),
  file.path(output_dir, "gtdb-gift-phylogenetic-signal-classes.tsv")
)
write_tsv(
  data.frame(
    item = c(
      "genomes", "current GIFTs", "random seed", "near-miss definition",
      "unsupported genome-GIFT pairs", "near-miss genome-GIFT pairs",
      "median near misses per genome", "Spearman rho, size deviation and near misses",
      "Spearman p value",
      "phylogenetic slope, size deviation per near miss", "phylogenetic slope p value",
      "distinct one-step gaps", "D statistic", "D permutations",
      "GIFTs with an estimable D", "median D",
      "GIFTs not distinguishable from random",
      "GIFTs as conserved as Brownian motion",
      "GIFTs between Brownian motion and random",
      "catabolic against anabolic D, Wilcoxon p value",
      "Spearman rho, prevalence and D", "false discovery rate"
    ),
    value = c(
      nrow(genomes), n_gifts, SEED,
      paste0("unsupported, closest implementation lacks exactly one requirement and has a completeness score of at least ", NEAR_MISS_SCORE),
      sum(!calls$complete), nrow(near), stats::median(genomes$near_misses),
      signif(unname(near_rank$estimate), 4), signif(near_rank$p.value, 4),
      signif(near_coefficient[["Estimate"]], 4), signif(near_coefficient[["p.value"]], 4),
      nrow(gaps),
      "caper::phylo.d (Fritz and Purvis) on the pruned GTDB bac120 tree, for GIFTs carried and lacked by at least ten genomes",
      D_PERMUTATIONS, nrow(signal), signif(stats::median(signal$d_statistic), 4),
      sum(signal$distribution == "not distinguishable from random"),
      sum(signal$distribution == "as conserved as Brownian motion"),
      sum(signal$distribution == "between Brownian motion and random"),
      signif(mode_test$p.value, 4), signif(unname(prevalence_rank$estimate), 4), FDR
    ),
    stringsAsFactors = FALSE
  ),
  file.path(output_dir, "gtdb-near-misses-and-signal-methods.tsv")
)

# ----------------------------------------------------------------------- themes

annotation_theme <- theme(
  legend.position = "bottom", legend.box = "vertical",
  legend.box.just = "left", legend.margin = margin(0, 0, 0, 0),
  plot.title = element_text(size = 10, face = "bold"),
  plot.subtitle = element_text(size = 7.5, colour = "#555550"),
  plot.caption = element_text(size = 6.5, colour = "#666660", hjust = 0)
)
base_theme <- theme_minimal(base_size = 7) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(size = 8, face = "bold", hjust = 0),
    legend.position = "bottom", legend.text = element_text(size = 6),
    legend.title = element_text(size = 6.5),
    legend.key.height = grid::unit(2.5, "mm"),
    axis.title.x = element_text(size = 6)
  )
deviation_colours <- c(
  "more than expected" = "#c8553d", "within expectation" = "#b9b8b2",
  "fewer than expected" = "#2f6f9f"
)

# ------------------------------------------------------------------- Figure S16

phylum_levels <- near_by_phylum$phylum
phylum_axis <- setNames(
  paste0(strip_rank(phylum_levels), " (", near_by_phylum$genomes, ")"), phylum_levels
)
near_plot <- genomes[genomes$phylum %in% phylum_levels, ]
near_plot$phylum <- factor(near_plot$phylum, levels = phylum_levels)
near_plot$size_deviation <- factor(
  near_by_phylum$size_deviation[match(near_plot$phylum, near_by_phylum$phylum)],
  levels = names(deviation_colours)
)
panel_near <- ggplot(near_plot, aes(x = near_misses, y = phylum)) +
  geom_boxplot(aes(fill = size_deviation), outlier.shape = NA, linewidth = 0.2,
               width = 0.65, colour = "#555550", alpha = 0.55) +
  geom_point(size = 0.4, colour = "#252522", alpha = 0.5,
             position = position_jitter(height = 0.18, width = 0.15, seed = 1L)) +
  scale_y_discrete(labels = phylum_axis) +
  scale_fill_manual(values = deviation_colours, drop = FALSE,
                    name = "phylum against the size expectation") +
  labs(title = "a  GIFTs one step short, per genome", x = "near misses", y = NULL) +
  base_theme +
  theme(axis.text.y = element_text(size = 5.6), panel.grid.major.y = element_blank())

top_gaps <- utils::head(gaps, HEATMAP_GAPS)
top_gaps$label <- paste0(
  pretty_name(top_gaps$gift_id), "  –  ", top_gaps$missing_requirement,
  " (", top_gaps$genomes_one_step_short, ")"
)
gap_cells <- do.call(rbind, lapply(seq_len(nrow(top_gaps)), function(i) {
  rows <- near[
    near$gift_id == top_gaps$gift_id[[i]] &
      near$best_implementation == top_gaps$implementation[[i]] &
      near$missing_requirements == top_gaps$missing_requirement[[i]], ]
  counts <- table(factor(rows$phylum, levels = phylum_levels))
  data.frame(
    label = top_gaps$label[[i]], phylum = phylum_levels,
    share = as.numeric(counts) / near_by_phylum$genomes, stringsAsFactors = FALSE
  )
}))
gap_cells$label <- factor(gap_cells$label, levels = rev(top_gaps$label))
gap_cells$phylum <- factor(gap_cells$phylum, levels = phylum_levels)
panel_gaps <- ggplot(gap_cells, aes(x = phylum, y = label, fill = 100 * share)) +
  geom_tile(colour = "white", linewidth = 0.2) +
  scale_x_discrete(labels = strip_rank) +
  scale_fill_gradient(low = "#f6f5f1", high = "#234f84", limits = c(0, 100),
                      name = "% of phylum one step short") +
  labs(title = "b  Most frequent single gaps", x = NULL, y = NULL) +
  base_theme +
  theme(
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 40, hjust = 1, size = 5.6),
    axis.text.y = element_text(size = 5.2),
    legend.key.width = grid::unit(8, "mm")
  )

figure_s16 <- panel_near + panel_gaps +
  plot_layout(widths = c(1, 1.5), guides = "collect") +
  plot_annotation(
    title = "Where genomes fall one step short of a GIFT",
    subtitle = wrap_text(paste0(
      "A near miss is an unsupported GIFT whose closest implementation lacks exactly one of at least two requirements: ",
      format(nrow(near), big.mark = ","), " of ", format(sum(!calls$complete), big.mark = ","),
      " unsupported calls. a: phyla with at least ", MIN_TAXON_GENOMES,
      " genomes, ordered by median size deviation. b: the ", nrow(top_gaps),
      " requirements most often missing alone (genomes in brackets)."
    ), 150),
    caption = wrap_text(paste0(
      "A near miss is never counted as support. A requirement missing across a lineage is a candidate for an uncurated alternative, ",
      "or for a capability the lineage does not encode; the table ranks candidates and decides nothing."
    ), 165),
    theme = annotation_theme
  )
ggsave(
  file.path(figure_dir, "figure-s16-gtdb-near-misses.pdf"), figure_s16,
  width = 190, height = 165, units = "mm", device = grDevices::cairo_pdf, bg = "white"
)
ggsave(
  file.path(figure_dir, "figure-s16-gtdb-near-misses.png"), figure_s16,
  width = 190, height = 165, units = "mm", dpi = 320, bg = "white"
)

# ------------------------------------------------------------------- Figure S17

distribution_colours <- c(
  "as conserved as Brownian motion" = "#234f84",
  "between Brownian motion and random" = "#e0a458",
  "not distinguishable from random" = "#b9b8b2"
)
signal_plot <- signal
signal_plot$class <- factor(signal_plot$class, levels = signal_by_class$class)
signal_plot$distribution <- factor(
  signal_plot$distribution, levels = names(distribution_colours)
)
signal_plot$label <- pretty_name(signal_plot$gift_id)
signal_labelled <- rbind(
  utils::head(signal_plot, LABELLED_PER_DIRECTION),
  utils::tail(signal_plot, LABELLED_PER_DIRECTION)
)
reference_lines <- geom_hline(
  yintercept = c(0, 1), colour = "#252522", linewidth = 0.25, linetype = c(1, 2)
)
panel_signal <- ggplot(signal_plot, aes(x = d_statistic, y = class)) +
  geom_vline(xintercept = c(0, 1), colour = "#252522", linewidth = 0.25,
             linetype = c(1, 2)) +
  geom_boxplot(outlier.shape = NA, linewidth = 0.2, width = 0.6,
               colour = "#8a8984", fill = NA) +
  geom_point(aes(colour = distribution), size = 0.8,
             position = position_jitter(height = 0.16, width = 0, seed = 1L)) +
  scale_colour_manual(values = distribution_colours, drop = FALSE, name = NULL) +
  labs(title = "a  By type and metabolic mode",
       x = "D (0 = Brownian motion, 1 = random)", y = NULL) +
  base_theme +
  theme(axis.text.y = element_text(size = 5.8), panel.grid.major.y = element_blank()) +
  guides(colour = guide_legend(nrow = 1))
panel_prevalence <- ggplot(signal_plot, aes(x = 100 * prevalence, y = d_statistic)) +
  reference_lines +
  geom_point(aes(colour = distribution), size = 0.8) +
  ggrepel::geom_text_repel(
    data = signal_labelled, aes(label = label), size = 1.6, colour = "#252522",
    min.segment.length = 0, segment.size = 0.15, box.padding = 0.2,
    max.overlaps = Inf, seed = 1L
  ) +
  scale_colour_manual(values = distribution_colours, drop = FALSE, name = NULL) +
  labs(title = "b  Against prevalence", x = "genomes supporting the GIFT (%)",
       y = "D (0 = Brownian motion, 1 = random)") +
  base_theme +
  guides(colour = guide_legend(nrow = 1))

figure_s17 <- panel_signal + panel_prevalence +
  plot_layout(widths = c(1, 1.1), guides = "collect") +
  plot_annotation(
    title = "How each GIFT is distributed over the phylogeny",
    subtitle = wrap_text(paste0(
      "Fritz and Purvis's D for the ", nrow(signal), " GIFTs carried and lacked by at least ",
      MIN_GIFT_GENOMES, " of ", format(nrow(genomes), big.mark = ","),
      " genomes, on the pruned GTDB bac120 tree (", format(D_PERMUTATIONS, big.mark = ","),
      " permutations; categories at a false discovery rate of ", FDR, "). Lower D means the GIFT is confined to related genomes."
    ), 150),
    caption = wrap_text(paste0(
      "D describes how an encoded, curated capability is distributed over this enriched panel; ",
      "it is not an ancestral-state reconstruction and does not measure gain or loss rates."
    ), 165),
    theme = annotation_theme
  )
ggsave(
  file.path(figure_dir, "figure-s17-gtdb-gift-phylogenetic-signal.pdf"), figure_s17,
  width = 190, height = 120, units = "mm", device = grDevices::cairo_pdf, bg = "white"
)
ggsave(
  file.path(figure_dir, "figure-s17-gtdb-gift-phylogenetic-signal.png"), figure_s17,
  width = 190, height = 120, units = "mm", dpi = 320, bg = "white"
)

cat("Wrote GTDB near-miss and per-GIFT signal tables and Figures S16 and S17.\n")
