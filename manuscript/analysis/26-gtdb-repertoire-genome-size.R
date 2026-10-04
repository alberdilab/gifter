# GTDB overview follow-up: encoded repertoire size against genome size.
#
# The question is which genomes, and which taxa, support more or fewer GIFTs
# than the panel-wide trend predicts for an assembly of their size. The response
# is the number of supported GIFTs out of the current catalogue, exactly as
# called by 23-gtdb-phylogeny.R; nothing here changes a call. Genome size is the
# size of the evaluated assembly, not the species mean shown in Figure S4.
#
# The expectation is a smooth quasi-binomial fit, so it is descriptive of this
# panel and of this catalogue. A residual is a difference in encoded, curated
# capabilities; it is not activity, phenotype, metabolic versatility in an
# environment, or a statement about functions the catalogue does not hold. The
# tests screen for departures from the trend and treat genomes as independent,
# which related genomes are not.
#
# Run from the repository root after 23-gtdb-phylogeny.R:
#   Rscript manuscript/analysis/26-gtdb-repertoire-genome-size.R

suppressWarnings(suppressPackageStartupMessages({
  library(ggplot2)
  library(patchwork)
}))

root <- "manuscript/analysis"
output_dir <- Sys.getenv("GTDB_PHYLOGENY_OUTPUT_DIR", file.path(root, "output"))
figure_dir <- Sys.getenv("GTDB_PHYLOGENY_FIGURE_DIR", "manuscript/figures")

OUTLIER_FDR <- 0.05
MIN_TAXON_GENOMES <- 5L
LABELLED_PER_DIRECTION <- 8L

read_tsv <- function(path) {
  utils::read.delim(path, check.names = FALSE, stringsAsFactors = FALSE)
}
write_tsv <- function(x, path) {
  utils::write.table(
    x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = ""
  )
}
strip_rank <- function(x) sub("^[a-z]__", "", x)

genome_summary_path <- file.path(output_dir, "gtdb-phylogeny-genome-summary.tsv")
gift_summary_path <- file.path(output_dir, "gtdb-phylogeny-gift-summary.tsv")
missing <- c(genome_summary_path, gift_summary_path)
missing <- missing[!file.exists(missing)]
if (length(missing)) {
  stop("Run 23-gtdb-phylogeny.R first. Missing:\n  ",
       paste(missing, collapse = "\n  "), call. = FALSE)
}

genomes <- read_tsv(genome_summary_path)
gifts <- read_tsv(gift_summary_path)
n_gifts <- nrow(gifts)
panel_size <- unique(gifts$genomes)
if (length(panel_size) != 1L || nrow(genomes) != panel_size ||
    anyDuplicated(genomes$genome_id) || anyNA(genomes$genome_size) ||
    any(genomes$genome_size <= 0) ||
    anyNA(genomes[["all supported GIFTs"]]) ||
    any(genomes[["all supported GIFTs"]] > n_gifts)) {
  stop("GTDB genome and GIFT summaries do not describe one evaluated panel",
       call. = FALSE)
}

genomes$supported <- genomes[["all supported GIFTs"]]
genomes$log10_genome_size <- log10(genomes$genome_size)

# ------------------------------------------------------------------ expectation

model <- mgcv::gam(
  cbind(supported, n_gifts - supported) ~ s(log10_genome_size, k = 6),
  family = stats::quasibinomial(), data = genomes, method = "REML"
)
dispersion <- summary(model)$dispersion
fitted_share <- as.numeric(stats::fitted(model))

genomes$expected <- n_gifts * fitted_share
genomes$residual <- genomes$supported - genomes$expected
# Deviance residuals on a common scale: divided by the estimated dispersion and
# by each genome's own leverage on the fit.
genomes$standardised_residual <- as.numeric(
  stats::residuals(model, type = "deviance") /
    sqrt(dispersion * (1 - model$hat))
)
genomes$p_value <- 2 * stats::pnorm(-abs(genomes$standardised_residual))
genomes$q_value <- stats::p.adjust(genomes$p_value, method = "BH")
genomes$deviation <- ifelse(
  genomes$q_value >= OUTLIER_FDR, "within expectation",
  ifelse(genomes$residual > 0, "more than expected", "fewer than expected")
)

curve <- data.frame(log10_genome_size = seq(
  min(genomes$log10_genome_size), max(genomes$log10_genome_size),
  length.out = 200L
))
curve$share <- as.numeric(stats::predict(model, curve, type = "response"))
curve$expected <- n_gifts * curve$share
curve$spread <- sqrt(dispersion * n_gifts * curve$share * (1 - curve$share))
curve$lower <- pmax(curve$expected - stats::qnorm(0.975) * curve$spread, 0)
curve$upper <- pmin(curve$expected + stats::qnorm(0.975) * curve$spread, n_gifts)
curve$genome_size_mb <- 10^curve$log10_genome_size / 1e6

rank_correlation <- suppressWarnings(stats::cor.test(
  genomes$genome_size, genomes$supported, method = "spearman"
))

# ------------------------------------------------------------------------- taxa

summarise_taxa <- function(rank) {
  groups <- split(genomes, genomes[[rank]])
  groups <- groups[vapply(groups, nrow, integer(1)) >= MIN_TAXON_GENOMES]
  table <- do.call(rbind, lapply(names(groups), function(taxon) {
    rows <- groups[[taxon]]
    data.frame(
      rank = rank, taxon = taxon, genomes = nrow(rows),
      median_genome_size_mb = stats::median(rows$genome_size) / 1e6,
      median_supported = stats::median(rows$supported),
      median_expected = stats::median(rows$expected),
      median_residual = stats::median(rows$residual),
      median_standardised_residual = stats::median(rows$standardised_residual),
      genomes_more_than_expected = sum(rows$deviation == "more than expected"),
      genomes_fewer_than_expected = sum(rows$deviation == "fewer than expected"),
      p_value = suppressWarnings(stats::wilcox.test(
        rows$standardised_residual, mu = 0, exact = FALSE
      )$p.value),
      stringsAsFactors = FALSE
    )
  }))
  table$q_value <- stats::p.adjust(table$p_value, method = "BH")
  table$deviation <- ifelse(
    table$q_value >= OUTLIER_FDR, "within expectation",
    ifelse(table$median_residual > 0, "more than expected", "fewer than expected")
  )
  table[order(table$median_standardised_residual), ]
}
taxa <- rbind(summarise_taxa("phylum"), summarise_taxa("class"))
rownames(taxa) <- NULL

# ------------------------------------------------------------------ sensitivity

# Assembly quality shifts the deviation (28-gtdb-origin-and-annotations.R), so
# the taxon reading is repeated on better-assembled subsets and with quality in
# the expectation. A subset refits the expectation on its own genomes.
QUALITY_COMPLETENESS <- 95
QUALITY_CONTAMINATION <- 5
genomes$metagenome_derived <- genomes$ncbi_genome_category == "derived from metagenome"
isolate <- genomes$ncbi_genome_category == "none"
high_quality <- genomes$checkm2_completeness >= QUALITY_COMPLETENESS &
  genomes$checkm2_contamination <= QUALITY_CONTAMINATION
variants <- list(
  "all genomes" = list(keep = rep(TRUE, nrow(genomes)), adjusted = FALSE),
  "isolates only" = list(keep = isolate, adjusted = FALSE),
  "high CheckM2 quality only" = list(keep = high_quality, adjusted = FALSE),
  "quality-adjusted" = list(keep = rep(TRUE, nrow(genomes)), adjusted = TRUE)
)
sensitivity <- do.call(rbind, lapply(names(variants), function(name) {
  variant <- variants[[name]]
  data <- genomes[variant$keep, ]
  formula <- if (variant$adjusted) {
    cbind(supported, n_gifts - supported) ~ s(log10_genome_size, k = 6) +
      checkm2_completeness + metagenome_derived
  } else {
    cbind(supported, n_gifts - supported) ~ s(log10_genome_size, k = 6)
  }
  fit <- mgcv::gam(formula, family = stats::quasibinomial(), data = data, method = "REML")
  phi <- summary(fit)$dispersion
  data$variant_residual <- data$supported - n_gifts * as.numeric(stats::fitted(fit))
  data$variant_standardised <- as.numeric(
    stats::residuals(fit, type = "deviance") / sqrt(phi * (1 - fit$hat))
  )
  groups <- split(data, data$phylum)
  groups <- groups[vapply(groups, nrow, integer(1)) >= MIN_TAXON_GENOMES]
  table <- do.call(rbind, lapply(names(groups), function(taxon) {
    rows <- groups[[taxon]]
    data.frame(
      variant = name, genomes_in_variant = nrow(data),
      deviance_explained = summary(fit)$dev.expl, phylum = taxon,
      genomes = nrow(rows), median_residual = stats::median(rows$variant_residual),
      p_value = suppressWarnings(stats::wilcox.test(
        rows$variant_standardised, mu = 0, exact = FALSE
      )$p.value),
      stringsAsFactors = FALSE
    )
  }))
  table$q_value <- stats::p.adjust(table$p_value, method = "BH")
  table$deviation <- ifelse(
    table$q_value >= OUTLIER_FDR, "within expectation",
    ifelse(table$median_residual > 0, "more than expected", "fewer than expected")
  )
  table
}))
rownames(sensitivity) <- NULL

# ----------------------------------------------------------------------- tables

sensitivity_table <- sensitivity
sensitivity_table$deviance_explained <- round(sensitivity_table$deviance_explained, 4)
sensitivity_table$median_residual <- round(sensitivity_table$median_residual, 3)
sensitivity_table$p_value <- signif(sensitivity_table$p_value, 4)
sensitivity_table$q_value <- signif(sensitivity_table$q_value, 4)
write_tsv(sensitivity_table, file.path(output_dir, "gtdb-size-expectation-sensitivity.tsv"))

genome_table <- genomes[order(genomes$standardised_residual), c(
  "genome_id", "phylum", "class", "order", "family", "genus", "species",
  "genome_size", "supported", "expected", "residual", "standardised_residual",
  "p_value", "q_value", "deviation"
)]
genome_table$expected <- round(genome_table$expected, 2)
genome_table$residual <- round(genome_table$residual, 2)
genome_table$standardised_residual <- round(genome_table$standardised_residual, 3)
genome_table$p_value <- signif(genome_table$p_value, 4)
genome_table$q_value <- signif(genome_table$q_value, 4)
write_tsv(genome_table, file.path(output_dir, "gtdb-size-expectation-genomes.tsv"))

taxa_table <- taxa
for (column in c(
  "median_genome_size_mb", "median_expected", "median_residual",
  "median_standardised_residual"
)) taxa_table[[column]] <- round(taxa_table[[column]], 3)
taxa_table$p_value <- signif(taxa_table$p_value, 4)
taxa_table$q_value <- signif(taxa_table$q_value, 4)
write_tsv(taxa_table, file.path(output_dir, "gtdb-size-expectation-taxa.tsv"))

model_table <- data.frame(
  item = c(
    "genomes", "current GIFTs", "response", "predictor", "model",
    "smooth effective degrees of freedom", "dispersion", "deviance explained",
    "Spearman rho, genome size and supported GIFTs", "Spearman p value",
    "genome test", "taxon test", "false discovery rate",
    "minimum genomes per tested taxon", "genomes with more than expected",
    "genomes with fewer than expected", "phyla tested",
    "phyla with more than expected", "phyla with fewer than expected",
    "classes tested", "classes with more than expected",
    "classes with fewer than expected"
  ),
  value = c(
    nrow(genomes), n_gifts, "supported GIFTs out of the current catalogue",
    "log10 size of the evaluated assembly (bp)",
    "mgcv quasi-binomial GAM, logit link, s(log10 genome size, k = 6), REML",
    round(sum(model$edf) - 1, 3), round(dispersion, 3),
    round(summary(model)$dev.expl, 4),
    round(unname(rank_correlation$estimate), 4),
    signif(rank_correlation$p.value, 4),
    "two-sided normal test of the leverage- and dispersion-standardised deviance residual, Benjamini-Hochberg over genomes",
    "two-sided Wilcoxon signed-rank test of standardised residuals against zero, Benjamini-Hochberg within rank",
    OUTLIER_FDR, MIN_TAXON_GENOMES,
    sum(genomes$deviation == "more than expected"),
    sum(genomes$deviation == "fewer than expected"),
    sum(taxa$rank == "phylum"),
    sum(taxa$rank == "phylum" & taxa$deviation == "more than expected"),
    sum(taxa$rank == "phylum" & taxa$deviation == "fewer than expected"),
    sum(taxa$rank == "class"),
    sum(taxa$rank == "class" & taxa$deviation == "more than expected"),
    sum(taxa$rank == "class" & taxa$deviation == "fewer than expected")
  ),
  stringsAsFactors = FALSE
)
write_tsv(model_table, file.path(output_dir, "gtdb-size-expectation-model.tsv"))

# -------------------------------------------------------------------- Figure S9

deviation_colours <- c(
  "more than expected" = "#c8553d", "within expectation" = "#b9b8b2",
  "fewer than expected" = "#2f6f9f"
)
genomes$genome_size_mb <- genomes$genome_size / 1e6
genomes$deviation <- factor(genomes$deviation, levels = names(deviation_colours))
genomes$label <- strip_rank(genomes$species)

# The most extreme genomes in each direction are named whether or not the test
# flags them; a flagged genome is additionally ringed.
flagged <- genomes[genomes$deviation != "within expectation", ]
by_residual <- genomes[order(genomes$standardised_residual), ]
labelled <- rbind(
  utils::head(by_residual, LABELLED_PER_DIRECTION),
  utils::tail(by_residual, LABELLED_PER_DIRECTION)
)
residual_limit <- max(abs(genomes$standardised_residual))
residual_scale <- scale_colour_gradient2(
  low = "#2f6f9f", mid = "#cfcec8", high = "#c8553d", midpoint = 0,
  limits = c(-residual_limit, residual_limit),
  name = "standardised deviation"
)
flag_layer <- geom_point(
  data = flagged, shape = 21, size = 1.6, stroke = 0.35, colour = "#252522",
  fill = NA
)
genome_test_sentence <- if (nrow(flagged)) {
  paste0(
    nrow(flagged), " ringed genomes depart from it at a false discovery rate of ",
    OUTLIER_FDR, "."
  )
} else {
  paste0(
    "no single genome departs from it at a false discovery rate of ",
    OUTLIER_FDR, "; the most extreme in each direction are named."
  )
}

size_scale <- scale_x_log10(
  breaks = c(0.25, 0.5, 1, 2, 4, 8, 16), labels = c("0.25", "0.5", "1", "2", "4", "8", "16")
)
base_theme <- theme_minimal(base_size = 7) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(size = 8, face = "bold", hjust = 0),
    legend.position = "bottom", legend.text = element_text(size = 6),
    legend.title = element_text(size = 6.5),
    legend.key.height = grid::unit(2.5, "mm")
  )

panel_fit <- ggplot(genomes, aes(x = genome_size_mb, y = supported)) +
  geom_ribbon(
    data = curve, aes(x = genome_size_mb, ymin = lower, ymax = upper),
    inherit.aes = FALSE, fill = "#e4e3de"
  ) +
  geom_point(aes(colour = standardised_residual), size = 0.75) +
  flag_layer +
  geom_line(
    data = curve, aes(x = genome_size_mb, y = expected),
    inherit.aes = FALSE, colour = "#252522", linewidth = 0.45
  ) +
  ggrepel::geom_text_repel(
    data = labelled, aes(label = label), colour = "#252522",
    size = 1.7, fontface = "italic", min.segment.length = 0,
    segment.size = 0.15, box.padding = 0.25, max.overlaps = Inf,
    show.legend = FALSE, seed = 1L
  ) +
  size_scale +
  residual_scale +
  labs(
    title = "a  Supported GIFTs against genome size",
    x = "genome size (Mb, log scale)", y = "supported GIFTs"
  ) +
  base_theme

panel_residual <- ggplot(genomes, aes(x = genome_size_mb, y = residual)) +
  geom_hline(yintercept = 0, colour = "#252522", linewidth = 0.3) +
  geom_point(aes(colour = standardised_residual), size = 0.75) +
  flag_layer +
  size_scale +
  residual_scale +
  labs(
    title = "b  Deviation from the expectation",
    x = "genome size (Mb, log scale)", y = "observed − expected GIFTs"
  ) +
  base_theme

wrap_text <- function(x, width) paste(strwrap(x, width = width), collapse = "\n")

figure_s9 <- panel_fit + panel_residual +
  plot_layout(widths = c(1.25, 1), guides = "collect") +
  plot_annotation(
    title = "Encoded repertoire size against genome size",
    subtitle = wrap_text(paste0(
      format(nrow(genomes), big.mark = ","), " GTDB R11-RS232 genomes × ",
      n_gifts, " current GIFTs. The line is a smooth quasi-binomial expectation and the band its 95% range; ",
      genome_test_sentence
    ), 150),
    caption = wrap_text(paste0(
      "A deviation is a difference in encoded, curated capabilities relative to this panel and this catalogue, ",
      "not activity or phenotype. Genomes are treated as independent; related genomes are not."
    ), 165),
    theme = theme(
      legend.position = "bottom",
      plot.title = element_text(size = 10, face = "bold"),
      plot.subtitle = element_text(size = 7.5, colour = "#555550"),
      plot.caption = element_text(size = 6.5, colour = "#666660", hjust = 0)
    )
  )

ggsave(
  file.path(figure_dir, "figure-s9-gtdb-repertoire-genome-size.pdf"), figure_s9,
  width = 190, height = 115, units = "mm", device = grDevices::cairo_pdf,
  bg = "white"
)
ggsave(
  file.path(figure_dir, "figure-s9-gtdb-repertoire-genome-size.png"), figure_s9,
  width = 190, height = 115, units = "mm", dpi = 320, bg = "white"
)

# ------------------------------------------------------------------- Figure S10

taxon_panel <- function(rank, title) {
  table <- taxa[taxa$rank == rank, ]
  rows <- genomes[genomes[[rank]] %in% table$taxon, ]
  levels <- table$taxon[order(table$median_residual)]
  rows$taxon <- factor(rows[[rank]], levels = levels)
  table$taxon_factor <- factor(table$taxon, levels = levels)
  table$deviation <- factor(table$deviation, levels = names(deviation_colours))
  axis_labels <- setNames(
    paste0(strip_rank(levels), " (", table$genomes[match(levels, table$taxon)], ")"),
    levels
  )
  ggplot(rows, aes(x = residual, y = taxon)) +
    geom_vline(xintercept = 0, colour = "#252522", linewidth = 0.3) +
    geom_boxplot(
      data = merge(
        rows[c("taxon", "residual")],
        data.frame(taxon = table$taxon_factor, taxon_deviation = table$deviation),
        by = "taxon"
      ),
      aes(fill = taxon_deviation), outlier.shape = NA, linewidth = 0.2,
      width = 0.65, colour = "#555550", alpha = 0.55
    ) +
    geom_point(
      size = 0.45, colour = "#252522", alpha = 0.55,
      position = position_jitter(height = 0.18, width = 0, seed = 1L)
    ) +
    scale_y_discrete(labels = axis_labels) +
    scale_fill_manual(values = deviation_colours, drop = FALSE, name = "Taxon") +
    labs(title = title, x = "observed − expected GIFTs", y = NULL) +
    base_theme +
    theme(
      axis.text.y = element_text(size = 5.6),
      panel.grid.major.y = element_blank()
    )
}

phylum_order <- taxa$taxon[taxa$rank == "phylum"]
phylum_order <- phylum_order[order(taxa$median_residual[taxa$rank == "phylum"])]
sensitivity_plot <- sensitivity[sensitivity$phylum %in% phylum_order, ]
sensitivity_plot$phylum <- factor(sensitivity_plot$phylum, levels = phylum_order)
sensitivity_plot$variant <- factor(sensitivity_plot$variant, levels = names(variants))
sensitivity_plot$significant <- sensitivity_plot$deviation != "within expectation"
variant_counts <- tapply(sensitivity$genomes_in_variant, sensitivity$variant, unique)
panel_sensitivity <- ggplot(
  sensitivity_plot, aes(x = median_residual, y = phylum, colour = variant)
) +
  geom_vline(xintercept = 0, colour = "#252522", linewidth = 0.3) +
  geom_point(
    aes(shape = significant), size = 1.3, stroke = 0.45,
    position = position_dodge(width = 0.7)
  ) +
  scale_y_discrete(labels = strip_rank) +
  scale_colour_manual(
    values = c("#252522", "#3f7a5c", "#b07a1f", "#7a4fa3"),
    labels = paste0(names(variants), " (", variant_counts[names(variants)], ")"),
    name = NULL
  ) +
  scale_shape_manual(
    values = c(`FALSE` = 1, `TRUE` = 16),
    labels = c(`FALSE` = "within expectation", `TRUE` = paste("FDR <", OUTLIER_FDR)),
    name = NULL
  ) +
  labs(
    title = "c  Phyla under better-assembled subsets and a quality-adjusted expectation",
    x = "median observed \u2212 expected GIFTs", y = NULL
  ) +
  base_theme +
  theme(axis.text.y = element_text(size = 5.6), panel.grid.major.y = element_blank()) +
  guides(colour = guide_legend(nrow = 1), shape = guide_legend(nrow = 1))

figure_s10 <- (taxon_panel("phylum", "a  Phyla") + taxon_panel("class", "b  Classes")) /
  panel_sensitivity +
  plot_layout(heights = c(1.9, 1), guides = "collect") +
  plot_annotation(
    title = "Taxa above and below the size expectation",
    subtitle = wrap_text(paste0(
      "Deviation of each genome from the Figure S9 expectation, for every phylum and class with at least ",
      MIN_TAXON_GENOMES, " genomes (count in brackets). A box is coloured when the taxon's residuals ",
      "differ from zero at a false discovery rate of ", OUTLIER_FDR, "."
    ), 150),
    caption = wrap_text(paste0(
      "Taxa are ordered by median deviation. The panel is phylogenetically enriched, not frequency weighted, ",
      "and genomes within a taxon are not independent. In c, high CheckM2 quality is at least ",
      QUALITY_COMPLETENESS, "% complete and at most ", QUALITY_CONTAMINATION,
      "% contaminated, and the quality-adjusted expectation adds CheckM2 completeness and metagenome origin as covariates."
    ), 165),
    theme = theme(
      legend.position = "bottom", legend.box = "vertical",
      legend.box.just = "left", legend.margin = margin(0, 0, 0, 0),
      plot.title = element_text(size = 10, face = "bold"),
      plot.subtitle = element_text(size = 7.5, colour = "#555550"),
      plot.caption = element_text(size = 6.5, colour = "#666660", hjust = 0)
    )
  )

ggsave(
  file.path(figure_dir, "figure-s10-gtdb-size-deviation-taxa.pdf"), figure_s10,
  width = 190, height = 240, units = "mm", device = grDevices::cairo_pdf,
  bg = "white"
)
ggsave(
  file.path(figure_dir, "figure-s10-gtdb-size-deviation-taxa.png"), figure_s10,
  width = 190, height = 240, units = "mm", dpi = 320, bg = "white"
)

cat("Wrote GTDB size-expectation tables and Figures S9 and S10.\n")
