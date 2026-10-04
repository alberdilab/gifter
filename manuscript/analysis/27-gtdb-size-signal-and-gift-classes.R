# GTDB overview follow-up: two questions about repertoire and genome size.
#
# 1. Is a genome's deviation from the size expectation of
#    26-gtdb-repertoire-genome-size.R phylogenetically clustered? Phylogenetic
#    signal is measured on the pruned GTDB bac120 tree with Blomberg's K and
#    Pagel's lambda, and its depth with a correlogram of Moran's I over
#    patristic distance.
# 2. Do some classes of GIFT follow genome size more closely than others? A
#    class is always resolved from curated metadata -- gift_type, mode or a
#    database facet -- never from a list of gift_ids written here.
#
# Every Boolean call is the one made by 23-gtdb-phylogeny.R. An association
# with genome size describes how encoded, curated capabilities are distributed
# over this panel and this catalogue; it is not activity, phenotype or a claim
# about functions the catalogue does not hold. Tests in part 2 treat genomes
# as independent, which part 1 shows they are not.
#
# Run from the repository root after 26-gtdb-repertoire-genome-size.R:
#   Rscript manuscript/analysis/27-gtdb-size-signal-and-gift-classes.R

suppressWarnings(suppressPackageStartupMessages({
  library(ggplot2)
  library(patchwork)
}))

devtools::load_all(".", quiet = TRUE)

root <- "manuscript/analysis"
case_dir <- file.path(root, "gtdb-phylogeny")
output_dir <- Sys.getenv("GTDB_PHYLOGENY_OUTPUT_DIR", file.path(root, "output"))
figure_dir <- Sys.getenv("GTDB_PHYLOGENY_FIGURE_DIR", "manuscript/figures")

SEED <- 20261004L
PERMUTATIONS <- 9999L
BOOTSTRAPS <- 2000L
DISTANCE_CLASSES <- 12L
FDR <- 0.05
MIN_CLASS_GIFTS <- 5L
MIN_GIFT_GENOMES <- 10L
CLASS_FACETS <- c("physiological_role", "substrate_class")
LABELLED_PER_DIRECTION <- 6L

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

tree_path <- file.path(case_dir, "selected-genomes.tree")
deviation_path <- file.path(output_dir, "gtdb-size-expectation-genomes.tsv")
calls_path <- file.path(output_dir, "gtdb-phylogeny-calls.tsv.xz")
missing <- c(tree_path, deviation_path, calls_path)
missing <- missing[!file.exists(missing)]
if (length(missing)) {
  stop("Run 23-gtdb-phylogeny.R and 26-gtdb-repertoire-genome-size.R first. Missing:\n  ",
       paste(missing, collapse = "\n  "), call. = FALSE)
}

tree <- ape::read.tree(tree_path)
genomes <- read_tsv(deviation_path)
if (anyDuplicated(genomes$genome_id) ||
    !setequal(genomes$genome_id, tree$tip.label)) {
  stop("The deviation table and the panel tree do not describe the same genomes",
       call. = FALSE)
}
genomes <- genomes[match(tree$tip.label, genomes$genome_id), ]
genomes$log2_genome_size <- log2(genomes$genome_size)

set.seed(SEED)

# ------------------------------------------------- 1. phylogenetic clustering

signal_traits <- list(
  "deviation from the size expectation (standardised)" = genomes$standardised_residual,
  "deviation from the size expectation (GIFTs)" = genomes$residual,
  "supported GIFTs" = genomes$supported,
  "log10 genome size" = log10(genomes$genome_size)
)
phylogenetic_signal <- do.call(rbind, lapply(names(signal_traits), function(trait) {
  values <- stats::setNames(signal_traits[[trait]], genomes$genome_id)
  k <- phytools::phylosig(tree, values, method = "K", test = TRUE, nsim = PERMUTATIONS)
  lambda <- phytools::phylosig(tree, values, method = "lambda", test = TRUE)
  data.frame(
    trait = trait, genomes = length(values),
    blomberg_k = k$K, k_permutation_p = k$P,
    pagel_lambda = lambda$lambda, lambda_log_likelihood = lambda$logL,
    lambda_zero_log_likelihood = lambda$logL0,
    lambda_likelihood_ratio_p = lambda$P,
    stringsAsFactors = FALSE
  )
}))

# Moran's I among pairs of genomes in successive patristic-distance classes of
# equal pair count. Positive values at short distance mean that close relatives
# deviate in the same direction.
patristic <- ape::cophenetic.phylo(tree)[genomes$genome_id, genomes$genome_id]
pair <- which(upper.tri(patristic), arr.ind = TRUE)
pair_distance <- patristic[upper.tri(patristic)]
class_breaks <- unique(stats::quantile(
  pair_distance, probs = seq(0, 1, length.out = DISTANCE_CLASSES + 1L)
))
pair_class <- cut(pair_distance, breaks = class_breaks, include.lowest = TRUE, labels = FALSE)
n_classes <- length(class_breaks) - 1L
pairs_per_class <- tabulate(pair_class, nbins = n_classes)

moran_by_class <- function(values) {
  z <- values - mean(values)
  products <- z[pair[, 1L]] * z[pair[, 2L]]
  class_sum <- as.numeric(rowsum(products, pair_class, reorder = TRUE))
  (length(z) / sum(z^2)) * class_sum / pairs_per_class
}
observed_moran <- moran_by_class(genomes$standardised_residual)
null_moran <- vapply(
  seq_len(PERMUTATIONS),
  function(i) moran_by_class(sample(genomes$standardised_residual)),
  numeric(n_classes)
)
correlogram <- data.frame(
  distance_class = seq_len(n_classes),
  lower_patristic_distance = class_breaks[-length(class_breaks)],
  upper_patristic_distance = class_breaks[-1L],
  median_patristic_distance = as.numeric(tapply(pair_distance, pair_class, stats::median)),
  genome_pairs = pairs_per_class,
  moran_i = observed_moran,
  null_lower = apply(null_moran, 1L, stats::quantile, probs = 0.025),
  null_upper = apply(null_moran, 1L, stats::quantile, probs = 0.975),
  p_value = (rowSums(abs(null_moran - rowMeans(null_moran)) >=
                       abs(observed_moran - rowMeans(null_moran))) + 1) /
    (PERMUTATIONS + 1),
  stringsAsFactors = FALSE
)
correlogram$q_value <- stats::p.adjust(correlogram$p_value, method = "BH")
correlogram$clustered <- correlogram$q_value < FDR

# ------------------------------------------------- 2. classes of GIFT and size

calls <- read_xz_tsv(calls_path)
calls$complete <- as.logical(calls$complete)
gift_metadata <- unique(calls[c("gift_id", "gift_type", "mode", "gift_name")])
supported <- tapply(calls$complete, list(calls$genome_id, calls$gift_id), any)
supported <- supported[genomes$genome_id, gift_metadata$gift_id, drop = FALSE]
if (anyNA(supported) || anyDuplicated(gift_metadata$gift_id)) {
  stop("The call table does not hold one call per genome and GIFT", call. = FALSE)
}

facet_terms <- list_facets()
facet_terms <- facet_terms[
  facet_terms$applies_to == "gift" & facet_terms$facet %in% CLASS_FACETS, ,
  drop = FALSE
]
facet_classes <- do.call(rbind, lapply(seq_len(nrow(facet_terms)), function(i) {
  members <- gifts_by_facet(facet_terms$facet[[i]], facet_terms$value[[i]])
  if (!nrow(members)) return(NULL)
  data.frame(
    grouping = facet_terms$facet[[i]], class = facet_terms$value[[i]],
    gift_id = members$gift_id, stringsAsFactors = FALSE
  )
}))
classes <- rbind(
  data.frame(grouping = "all GIFTs", class = "all GIFTs",
             gift_id = gift_metadata$gift_id, stringsAsFactors = FALSE),
  data.frame(grouping = "gift_type", class = gift_metadata$gift_type,
             gift_id = gift_metadata$gift_id, stringsAsFactors = FALSE),
  data.frame(grouping = "mode", class = gift_metadata$mode,
             gift_id = gift_metadata$gift_id,
             stringsAsFactors = FALSE)[!is.na(gift_metadata$mode) &
                                         nzchar(gift_metadata$mode), ],
  facet_classes
)
classes <- classes[classes$gift_id %in% gift_metadata$gift_id, ]
class_key <- paste(classes$grouping, classes$class, sep = "\r")
classes <- classes[class_key %in% names(which(table(class_key) >= MIN_CLASS_GIFTS)), ]

class_association <- do.call(rbind, lapply(
  split(classes, list(classes$grouping, classes$class), drop = TRUE),
  function(rows) {
    members <- unique(rows$gift_id)
    count <- rowSums(supported[, members, drop = FALSE])
    rho <- suppressWarnings(stats::cor(genomes$genome_size, count, method = "spearman"))
    boot <- vapply(seq_len(BOOTSTRAPS), function(i) {
      index <- sample.int(length(count), replace = TRUE)
      suppressWarnings(stats::cor(
        genomes$genome_size[index], count[index], method = "spearman"
      ))
    }, numeric(1))
    fit <- stats::glm(
      cbind(count, length(members) - count) ~ genomes$log2_genome_size,
      family = stats::quasibinomial()
    )
    slope <- summary(fit)$coefficients[2L, ]
    data.frame(
      grouping = rows$grouping[[1L]], class = rows$class[[1L]],
      gifts = length(members), genomes = length(count),
      mean_supported_share = mean(count) / length(members),
      spearman_rho = rho,
      rho_lower = unname(stats::quantile(boot, 0.025, na.rm = TRUE)),
      rho_upper = unname(stats::quantile(boot, 0.975, na.rm = TRUE)),
      log_odds_per_doubling = slope[["Estimate"]],
      log_odds_standard_error = slope[["Std. Error"]],
      stringsAsFactors = FALSE
    )
  }
))
grouping_order <- c("all GIFTs", "gift_type", "mode", CLASS_FACETS)
class_association <- class_association[order(
  match(class_association$grouping, grouping_order), -class_association$spearman_rho
), ]
rownames(class_association) <- NULL

# One logistic regression per GIFT. A GIFT carried, or lacked, by too few
# genomes has no estimable association and is reported without one.
carriers <- colSums(supported)
gift_association <- do.call(rbind, lapply(gift_metadata$gift_id, function(gift) {
  present <- supported[, gift]
  estimable <- min(sum(present), sum(!present)) >= MIN_GIFT_GENOMES
  slope <- c(Estimate = NA_real_, `Std. Error` = NA_real_, `Pr(>|z|)` = NA_real_)
  if (estimable) {
    fit <- stats::glm(present ~ genomes$log2_genome_size, family = stats::binomial())
    slope <- summary(fit)$coefficients[2L, ]
  }
  data.frame(
    gift_id = gift, supporting_genomes = sum(present),
    prevalence = mean(present),
    log_odds_per_doubling = slope[["Estimate"]],
    log_odds_standard_error = slope[["Std. Error"]],
    p_value = slope[["Pr(>|z|)"]],
    stringsAsFactors = FALSE
  )
}))
gift_association <- merge(gift_metadata, gift_association, by = "gift_id", sort = FALSE)
gift_association$q_value <- stats::p.adjust(gift_association$p_value, method = "BH")
gift_association$association <- ifelse(
  is.na(gift_association$q_value), "not estimable",
  ifelse(gift_association$q_value >= FDR, "no association",
         ifelse(gift_association$log_odds_per_doubling > 0,
                "more frequent in larger genomes", "more frequent in smaller genomes"))
)
gift_association <- gift_association[order(-gift_association$log_odds_per_doubling), ]
rownames(gift_association) <- NULL

# ----------------------------------------------------------------------- tables

round_columns <- function(table, columns, digits) {
  for (column in columns) table[[column]] <- round(table[[column]], digits)
  table
}
signal_table <- round_columns(
  phylogenetic_signal,
  c("blomberg_k", "pagel_lambda", "lambda_log_likelihood", "lambda_zero_log_likelihood"), 4
)
signal_table$k_permutation_p <- signif(signal_table$k_permutation_p, 4)
signal_table$lambda_likelihood_ratio_p <- signif(signal_table$lambda_likelihood_ratio_p, 4)
write_tsv(signal_table, file.path(output_dir, "gtdb-size-deviation-phylogenetic-signal.tsv"))

correlogram_table <- round_columns(correlogram, c(
  "lower_patristic_distance", "upper_patristic_distance",
  "median_patristic_distance", "moran_i", "null_lower", "null_upper"
), 4)
correlogram_table$p_value <- signif(correlogram_table$p_value, 4)
correlogram_table$q_value <- signif(correlogram_table$q_value, 4)
write_tsv(correlogram_table, file.path(output_dir, "gtdb-size-deviation-correlogram.tsv"))

class_table <- round_columns(class_association, c(
  "mean_supported_share", "spearman_rho", "rho_lower", "rho_upper",
  "log_odds_per_doubling", "log_odds_standard_error"
), 4)
write_tsv(class_table, file.path(output_dir, "gtdb-gift-class-genome-size.tsv"))

gift_table <- round_columns(gift_association, c(
  "prevalence", "log_odds_per_doubling", "log_odds_standard_error"
), 4)
gift_table$p_value <- signif(gift_table$p_value, 4)
gift_table$q_value <- signif(gift_table$q_value, 4)
write_tsv(gift_table, file.path(output_dir, "gtdb-gift-genome-size.tsv"))

method_table <- data.frame(
  item = c(
    "genomes", "current GIFTs", "random seed", "permutations",
    "phylogenetic signal", "correlogram", "patristic distance classes",
    "false discovery rate", "class definitions", "minimum GIFTs per class",
    "class association", "bootstrap resamples", "GIFT association",
    "minimum genomes with and without a GIFT", "GIFTs with an estimable association",
    "GIFTs more frequent in larger genomes", "GIFTs more frequent in smaller genomes"
  ),
  value = c(
    nrow(genomes), nrow(gift_metadata), SEED, PERMUTATIONS,
    "phytools::phylosig on the pruned GTDB bac120 tree: Blomberg's K with a tip-permutation test and Pagel's lambda with a likelihood-ratio test against lambda = 0",
    "Moran's I of the standardised deviation among genome pairs in equal-count patristic-distance classes; two-sided tip-permutation test, Benjamini-Hochberg over classes",
    n_classes, FDR,
    paste("gift_type, mode and the database facets", paste(CLASS_FACETS, collapse = ", ")),
    MIN_CLASS_GIFTS,
    "Spearman correlation of the supported count in the class with assembly size, percentile bootstrap interval over genomes; quasi-binomial log-odds per doubling of assembly size",
    BOOTSTRAPS,
    "binomial logistic regression of support on log2 assembly size, Wald test, Benjamini-Hochberg over estimable GIFTs",
    MIN_GIFT_GENOMES, sum(!is.na(gift_association$q_value)),
    sum(gift_association$association == "more frequent in larger genomes"),
    sum(gift_association$association == "more frequent in smaller genomes")
  ),
  stringsAsFactors = FALSE
)
write_tsv(method_table, file.path(output_dir, "gtdb-size-signal-and-classes-methods.tsv"))

# ------------------------------------------------------------------- Figure S11

annotation_theme <- theme(
  legend.position = "bottom",
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
    legend.key.height = grid::unit(2.5, "mm")
  )

tree_plot <- ggtree::ggtree(tree, linewidth = 0.18, colour = "#777772")
tip_data <- tree_plot$data[tree_plot$data$isTip, c("label", "y")]
names(tip_data)[[1L]] <- "genome_id"
tip_deviation <- merge(genomes, tip_data, by = "genome_id", sort = FALSE)
n_tips <- length(tree$tip.label)
shared_y <- scale_y_continuous(limits = c(0.5, n_tips + 0.5), expand = c(0, 0))

# Name each phylum once, beside its longest run of consecutive tips.
tip_order <- tip_deviation[order(tip_deviation$y), ]
phylum_counts <- sort(table(tip_order$phylum), decreasing = TRUE)
major_phyla <- names(phylum_counts)[seq_len(min(12L, length(phylum_counts)))]
runs <- rle(tip_order$phylum)
run_end <- cumsum(runs$lengths)
run_start <- run_end - runs$lengths + 1L
runs <- data.frame(
  phylum = runs$values, tips = runs$lengths,
  y = (tip_order$y[run_start] + tip_order$y[run_end]) / 2,
  stringsAsFactors = FALSE
)
runs <- runs[runs$phylum %in% major_phyla, ]
phylum_labels <- do.call(rbind, lapply(
  split(runs, runs$phylum), function(rows) rows[which.max(rows$tips), ]
))
phylum_labels$label <- sub("^p__", "", phylum_labels$phylum)

residual_limit <- max(abs(genomes$residual))
panel_tree <- tree_plot + shared_y +
  labs(title = "a  GTDB bac120 tree") +
  theme_void(base_size = 7) +
  theme(
    plot.title = element_text(size = 8, face = "bold", hjust = 0),
    plot.margin = margin(4, 0, 4, 4)
  )
panel_names <- ggplot(phylum_labels, aes(x = 1, y = y, label = label)) +
  geom_text(hjust = 1, size = 1.75, colour = "#252522") +
  shared_y +
  scale_x_continuous(limits = c(0, 1), expand = expansion(add = c(0, 0.04))) +
  coord_cartesian(clip = "off") +
  theme_void(base_size = 7) +
  theme(plot.margin = margin(4, 0, 4, 0))
panel_deviation <- ggplot(tip_deviation, aes(y = y)) +
  geom_segment(
    aes(x = 0, xend = residual, yend = y, colour = residual), linewidth = 0.3
  ) +
  geom_vline(xintercept = 0, colour = "#252522", linewidth = 0.25) +
  shared_y +
  scale_colour_gradient2(
    low = "#2f6f9f", mid = "#cfcec8", high = "#c8553d", midpoint = 0,
    limits = c(-residual_limit, residual_limit), guide = "none"
  ) +
  labs(title = "b  Deviation", x = "observed − expected GIFTs") +
  base_theme +
  theme(
    panel.grid.major.y = element_blank(), axis.text.y = element_blank(),
    axis.title.y = element_blank(), axis.title.x = element_text(size = 6),
    plot.margin = margin(4, 6, 4, 0)
  )
panel_correlogram <- ggplot(correlogram, aes(x = median_patristic_distance)) +
  geom_ribbon(aes(ymin = null_lower, ymax = null_upper), fill = "#e4e3de") +
  geom_hline(yintercept = 0, colour = "#252522", linewidth = 0.25) +
  geom_line(aes(y = moran_i), colour = "#555550", linewidth = 0.35) +
  geom_point(aes(y = moran_i, fill = clustered), shape = 21, size = 1.6,
             colour = "#252522", stroke = 0.3) +
  scale_fill_manual(
    values = c(`TRUE` = "#c8553d", `FALSE` = "white"),
    labels = c(`TRUE` = paste("differs from the null, FDR", FDR), `FALSE` = "within the null"),
    name = NULL, drop = FALSE
  ) +
  labs(
    title = "c  Depth of the clustering",
    x = "patristic distance between genomes (median of class)",
    y = "Moran's I of the deviation"
  ) +
  base_theme

main_signal <- phylogenetic_signal[1L, ]
format_p <- function(p) if (p < 0.001) "< 0.001" else paste("=", signif(p, 2))
figure_s11 <- panel_tree + panel_names + panel_deviation + panel_correlogram +
  plot_layout(widths = c(1.2, 0.55, 0.9, 2)) +
  plot_annotation(
    title = "Deviation from the size expectation is phylogenetically clustered",
    subtitle = wrap_text(paste0(
      "Standardised deviation of ", format(nrow(genomes), big.mark = ","),
      " genomes from the Figure S9 expectation: Pagel's λ = ",
      round(main_signal$pagel_lambda, 2), " (likelihood-ratio P ",
      format_p(main_signal$lambda_likelihood_ratio_p), "), Blomberg's K = ",
      round(main_signal$blomberg_k, 3), " (permutation P ",
      format_p(main_signal$k_permutation_p), "). The band in c is the 95% range of ",
      format(PERMUTATIONS, big.mark = ","), " tip permutations."
    ), 150),
    caption = wrap_text(paste0(
      "Positive Moran's I means that genomes at that distance deviate in the same direction. ",
      "Clustering describes how encoded, curated capabilities are distributed over this panel; it is not an ancestral-state reconstruction."
    ), 165),
    theme = annotation_theme
  )
ggsave(
  file.path(figure_dir, "figure-s11-gtdb-size-deviation-phylogeny.pdf"), figure_s11,
  width = 190, height = 150, units = "mm", device = grDevices::cairo_pdf, bg = "white"
)
ggsave(
  file.path(figure_dir, "figure-s11-gtdb-size-deviation-phylogeny.png"), figure_s11,
  width = 190, height = 150, units = "mm", dpi = 320, bg = "white"
)

# ------------------------------------------------------------------- Figure S12

grouping_labels <- c(
  "all GIFTs" = "all", gift_type = "GIFT type", mode = "metabolic mode",
  physiological_role = "physiological role", substrate_class = "substrate class"
)
class_plot <- class_association
class_plot$grouping_label <- factor(
  grouping_labels[class_plot$grouping], levels = unname(grouping_labels)
)
class_plot$axis_label <- paste0(gsub("_", " ", class_plot$class), " (", class_plot$gifts, ")")
class_plot$row <- factor(
  paste(class_plot$grouping, class_plot$class),
  levels = rev(paste(class_plot$grouping, class_plot$class))
)
panel_classes <- ggplot(class_plot, aes(x = spearman_rho, y = row)) +
  geom_vline(xintercept = 0, colour = "#252522", linewidth = 0.25) +
  geom_segment(aes(x = rho_lower, xend = rho_upper, yend = row),
               colour = "#8a8984", linewidth = 0.35) +
  geom_point(size = 1.1, colour = "#234f84") +
  facet_grid(rows = vars(grouping_label), scales = "free_y", space = "free_y") +
  scale_y_discrete(labels = setNames(class_plot$axis_label, class_plot$row)) +
  labs(
    title = "a  Classes of GIFT",
    x = "Spearman ρ, supported GIFTs in class and genome size", y = NULL
  ) +
  base_theme +
  theme(
    axis.text.y = element_text(size = 5.6), panel.grid.major.y = element_blank(),
    strip.text.y = element_text(size = 5.6, angle = 0, hjust = 0),
    axis.title.x = element_text(size = 6)
  )

gift_plot <- gift_association[!is.na(gift_association$log_odds_per_doubling), ]
gift_plot$class <- ifelse(
  gift_plot$gift_type == "metabolic", paste("metabolic,", gift_plot$mode),
  gift_plot$gift_type
)
class_medians <- tapply(gift_plot$log_odds_per_doubling, gift_plot$class, stats::median)
gift_plot$class <- factor(gift_plot$class, levels = names(sort(class_medians)))
association_colours <- c(
  "more frequent in larger genomes" = "#c8553d", "no association" = "#b9b8b2",
  "more frequent in smaller genomes" = "#2f6f9f"
)
gift_plot$association <- factor(gift_plot$association, levels = names(association_colours))
gift_plot$label <- gsub("_", " ", gift_plot$gift_id)
gift_labelled <- rbind(
  utils::head(gift_plot, LABELLED_PER_DIRECTION),
  utils::tail(gift_plot, LABELLED_PER_DIRECTION)
)
panel_gifts <- ggplot(gift_plot, aes(x = log_odds_per_doubling, y = class)) +
  geom_vline(xintercept = 0, colour = "#252522", linewidth = 0.25) +
  geom_boxplot(outlier.shape = NA, linewidth = 0.2, width = 0.6,
               colour = "#8a8984", fill = NA) +
  geom_point(
    aes(colour = association), size = 0.8,
    position = position_jitter(height = 0.16, width = 0, seed = 1L)
  ) +
  ggrepel::geom_text_repel(
    data = gift_labelled, aes(label = label), size = 1.6, colour = "#252522",
    min.segment.length = 0, segment.size = 0.15, box.padding = 0.2,
    max.overlaps = Inf, seed = 1L
  ) +
  scale_colour_manual(
    values = association_colours, drop = FALSE, name = "more frequent in",
    labels = c("larger genomes", "neither", "smaller genomes")
  ) +
  labs(
    title = "b  Individual GIFTs",
    x = "log-odds of support per doubling of genome size", y = NULL
  ) +
  base_theme +
  theme(
    axis.text.y = element_text(size = 5.6), panel.grid.major.y = element_blank(),
    axis.title.x = element_text(size = 6)
  ) +
  guides(colour = guide_legend(nrow = 1))

figure_s12 <- panel_classes + panel_gifts +
  plot_layout(widths = c(1, 1.15), guides = "collect") +
  plot_annotation(
    title = "Which GIFTs follow genome size",
    subtitle = wrap_text(paste0(
      "a: correlation between genome size and the number of supported GIFTs in each class with at least ",
      MIN_CLASS_GIFTS, " GIFTs (count in brackets), with 95% bootstrap intervals. ",
      "b: one logistic regression per GIFT with at least ", MIN_GIFT_GENOMES,
      " genomes carrying and lacking it; coloured at a false discovery rate of ", FDR, "."
    ), 150),
    caption = wrap_text(paste0(
      "Classes come from gift_type, mode and curated database facets, and a GIFT can belong to several. ",
      "Genomes are treated as independent although related genomes are not. ",
      "An association describes encoded capability over this panel, not activity or phenotype."
    ), 165),
    theme = annotation_theme
  )
ggsave(
  file.path(figure_dir, "figure-s12-gtdb-gift-classes-genome-size.pdf"), figure_s12,
  width = 190, height = 165, units = "mm", device = grDevices::cairo_pdf, bg = "white"
)
ggsave(
  file.path(figure_dir, "figure-s12-gtdb-gift-classes-genome-size.png"), figure_s12,
  width = 190, height = 165, units = "mm", dpi = 320, bg = "white"
)

cat("Wrote GTDB phylogenetic-signal and GIFT-class tables and Figures S11 and S12.\n")
