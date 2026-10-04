# GTDB overview follow-up: origin and other genome annotations.
#
# The panel manifest carries nonexclusive origin tags derived from the raw
# isolation source, and assembly annotations from GTDB and NCBI. This script
# explores how they relate to genome size, encoded repertoire size, the
# deviation from the size expectation of 26-gtdb-repertoire-genome-size.R, and
# the classes of GIFT and individual GIFTs a genome supports.
#
# Three things bound every reading. An origin tag is a coarse label parsed from
# a free-text field, not a habitat assignment, and the panel was balanced on
# those tags by design. Origin is confounded with phylogeny, so genome-level
# and class-level models are phylogenetic regressions on the pruned GTDB tree;
# the per-GIFT screen is not, and says so. And every Boolean call is the one
# made by 23-gtdb-phylogeny.R: an association is a difference in encoded,
# curated capability, never activity, phenotype or ecological function.
#
# Run from the repository root after 26-gtdb-repertoire-genome-size.R:
#   Rscript manuscript/analysis/28-gtdb-origin-and-annotations.R

suppressWarnings(suppressPackageStartupMessages({
  library(ggplot2)
  library(patchwork)
}))

devtools::load_all(".", quiet = TRUE)

root <- "manuscript/analysis"
case_dir <- file.path(root, "gtdb-phylogeny")
output_dir <- Sys.getenv("GTDB_PHYLOGENY_OUTPUT_DIR", file.path(root, "output"))
figure_dir <- Sys.getenv("GTDB_PHYLOGENY_FIGURE_DIR", "manuscript/figures")

FDR <- 0.05
MIN_ORIGIN_GENOMES <- 20L
MIN_CLASS_GIFTS <- 5L
MIN_GIFT_GENOMES <- 10L
CLASS_FACETS <- c("physiological_role", "substrate_class")
HEATMAP_GIFTS <- 45L

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

tree_path <- file.path(case_dir, "selected-genomes.tree")
summary_path <- file.path(output_dir, "gtdb-phylogeny-genome-summary.tsv")
deviation_path <- file.path(output_dir, "gtdb-size-expectation-genomes.tsv")
calls_path <- file.path(output_dir, "gtdb-phylogeny-calls.tsv.xz")
missing <- c(tree_path, summary_path, deviation_path, calls_path)
missing <- missing[!file.exists(missing)]
if (length(missing)) {
  stop("Run 23-gtdb-phylogeny.R and 26-gtdb-repertoire-genome-size.R first. Missing:\n  ",
       paste(missing, collapse = "\n  "), call. = FALSE)
}

tree <- ape::read.tree(tree_path)
genomes <- read_tsv(summary_path)
deviation <- read_tsv(deviation_path)
if (anyDuplicated(genomes$genome_id) ||
    !setequal(genomes$genome_id, tree$tip.label) ||
    !setequal(deviation$genome_id, tree$tip.label)) {
  stop("The panel tables and the panel tree do not describe the same genomes",
       call. = FALSE)
}
genomes <- genomes[match(tree$tip.label, genomes$genome_id), ]
deviation <- deviation[match(tree$tip.label, deviation$genome_id), ]
genomes$supported <- deviation$supported
genomes$residual <- deviation$residual
genomes$log2_genome_size <- log2(genomes$genome_size)
rownames(genomes) <- genomes$genome_id

# One phylogenetic regression: Pagel's lambda is estimated with the
# coefficients, so the correction is as strong as the data ask for.
phylogenetic_fit <- function(formula, data, phy = tree) {
  fit <- phylolm::phylolm(formula, data = data, phy = phy, model = "lambda")
  coefficients <- as.data.frame(summary(fit)$coefficients)
  data.frame(
    term = rownames(coefficients), estimate = coefficients$Estimate,
    standard_error = coefficients$StdErr, p_value = coefficients$p.value,
    lambda = fit$optpar, stringsAsFactors = FALSE
  )
}

# ------------------------------------------------------------------- 1. origin

origin_columns <- setdiff(
  grep("^origin_", names(genomes), value = TRUE), "origin_source_available"
)
for (column in origin_columns) genomes[[column]] <- as.logical(genomes[[column]])
origin_counts <- colSums(genomes[origin_columns])
tested_origins <- names(origin_counts)[origin_counts >= MIN_ORIGIN_GENOMES]
origin_label <- function(x) pretty_name(sub("^origin_", "", x))
origin_terms <- paste0("`", tested_origins, "`")

responses <- c(
  "log2 genome size" = "log2_genome_size",
  "supported GIFTs" = "supported",
  "deviation from the size expectation (GIFTs)" = "residual"
)
origin_genome <- do.call(rbind, lapply(names(responses), function(label) {
  response <- responses[[label]]
  fit <- phylogenetic_fit(
    stats::reformulate(tested_origins, response = response), genomes
  )
  fit <- fit[fit$term != "(Intercept)", ]
  fit$term <- sub("TRUE$", "", fit$term)
  data.frame(
    response = label, origin = fit$term,
    genomes_in_group = unname(origin_counts[fit$term]),
    naive_difference = vapply(fit$term, function(origin) {
      mean(genomes[[response]][genomes[[origin]]]) -
        mean(genomes[[response]][!genomes[[origin]]])
    }, numeric(1)),
    phylogenetic_estimate = fit$estimate,
    standard_error = fit$standard_error, p_value = fit$p_value,
    lambda = fit$lambda, stringsAsFactors = FALSE
  )
}))
origin_genome$q_value <- stats::ave(
  origin_genome$p_value, origin_genome$response,
  FUN = function(p) stats::p.adjust(p, method = "BH")
)
rownames(origin_genome) <- NULL

# Classes of GIFT, resolved from curated metadata as in script 27.
calls <- read_xz_tsv(calls_path)
calls$complete <- as.logical(calls$complete)
gift_metadata <- unique(calls[c("gift_id", "gift_type", "mode", "gift_name")])
supported <- tapply(calls$complete, list(calls$genome_id, calls$gift_id), any)
supported <- supported[genomes$genome_id, gift_metadata$gift_id, drop = FALSE]
if (anyNA(supported)) {
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
has_mode <- !is.na(gift_metadata$mode) & nzchar(gift_metadata$mode)
classes <- rbind(
  data.frame(grouping = "gift_type", class = gift_metadata$gift_type,
             gift_id = gift_metadata$gift_id, stringsAsFactors = FALSE),
  data.frame(grouping = "mode", class = gift_metadata$mode[has_mode],
             gift_id = gift_metadata$gift_id[has_mode], stringsAsFactors = FALSE),
  facet_classes
)
classes <- classes[classes$gift_id %in% gift_metadata$gift_id, ]
class_key <- paste(classes$grouping, classes$class, sep = "\r")
classes <- classes[class_key %in% names(which(table(class_key) >= MIN_CLASS_GIFTS)), ]

# The supported count in each class is standardised, so an estimate is in
# standard deviations of that class and comparable between classes. Genome size
# is a covariate: the question is what an origin adds beyond size.
origin_class <- do.call(rbind, lapply(
  split(classes, list(classes$grouping, classes$class), drop = TRUE),
  function(rows) {
    members <- unique(rows$gift_id)
    data <- genomes
    data$class_count <- as.numeric(scale(rowSums(supported[, members, drop = FALSE])))
    fit <- phylogenetic_fit(
      stats::reformulate(c(tested_origins, "log2_genome_size"), response = "class_count"),
      data
    )
    fit$term <- sub("TRUE$", "", fit$term)
    fit <- fit[fit$term %in% tested_origins, ]
    data.frame(
      grouping = rows$grouping[[1L]], class = rows$class[[1L]],
      gifts = length(members), origin = fit$term,
      standardised_estimate = fit$estimate, standard_error = fit$standard_error,
      p_value = fit$p_value, lambda = fit$lambda, stringsAsFactors = FALSE
    )
  }
))
origin_class$q_value <- stats::p.adjust(origin_class$p_value, method = "BH")
rownames(origin_class) <- NULL

# Per-GIFT screen: prevalence inside against outside each origin group, Fisher's
# exact test. It adjusts for neither genome size nor phylogeny.
estimable_gifts <- gift_metadata$gift_id[
  pmin(colSums(supported), colSums(!supported)) >= MIN_GIFT_GENOMES
]
origin_gift <- do.call(rbind, lapply(tested_origins, function(origin) {
  member <- genomes[[origin]]
  do.call(rbind, lapply(estimable_gifts, function(gift) {
    present <- supported[, gift]
    test <- stats::fisher.test(table(
      factor(member, levels = c(FALSE, TRUE)), factor(present, levels = c(FALSE, TRUE))
    ))
    data.frame(
      origin = origin, gift_id = gift,
      prevalence_in_group = mean(present[member]),
      prevalence_outside = mean(present[!member]),
      odds_ratio = unname(test$estimate), p_value = test$p.value,
      stringsAsFactors = FALSE
    )
  }))
}))
origin_gift$prevalence_difference <-
  origin_gift$prevalence_in_group - origin_gift$prevalence_outside
origin_gift$q_value <- stats::p.adjust(origin_gift$p_value, method = "BH")
origin_gift <- merge(
  origin_gift, gift_metadata[c("gift_id", "gift_type", "mode")], by = "gift_id",
  sort = FALSE
)

# -------------------------------------------------------- 2. other annotations

parse_latitude <- function(x) {
  match <- regmatches(x, regexec("^\\s*([0-9.]+)\\s*([NS])", x))
  vapply(match, function(parts) {
    if (length(parts) != 3L) return(NA_real_)
    as.numeric(parts[[2L]]) * if (parts[[3L]] == "S") -1 else 1
  }, numeric(1))
}
genomes$metagenome_derived <- genomes$ncbi_genome_category == "derived from metagenome"
genomes$single_cell_derived <- genomes$ncbi_genome_category == "derived from single cell"
genomes$type_strain <- grepl("^type strain", genomes$gtdb_type_designation_ncbi_taxa)
genomes$release_year <- as.numeric(substr(genomes$ncbi_seq_rel_date, 1L, 4L))
genomes$log2_contigs <- log2(genomes$contig_count)
genomes$absolute_latitude <- abs(parse_latitude(genomes$ncbi_lat_lon))

annotation_terms <- c(
  metagenome_derived = "derived from a metagenome",
  type_strain = "type strain of a species or subspecies",
  checkm2_completeness = "CheckM2 completeness (per s.d.)",
  checkm2_contamination = "CheckM2 contamination (per s.d.)",
  log2_contigs = "contig count, log2 (per s.d.)",
  release_year = "sequence release year (per s.d.)"
)
continuous_terms <- c(
  "checkm2_completeness", "checkm2_contamination", "log2_contigs", "release_year"
)
annotation_data <- genomes[!genomes$single_cell_derived, ]
annotation_data <- annotation_data[
  stats::complete.cases(annotation_data[names(annotation_terms)]), ,
  drop = FALSE
]
annotation_tree <- ape::keep.tip(tree, annotation_data$genome_id)
annotation_spread <- vapply(annotation_data[continuous_terms], stats::sd, numeric(1))
for (term in continuous_terms) {
  annotation_data[[term]] <- as.numeric(scale(annotation_data[[term]]))
}
annotation_models <- do.call(rbind, lapply(
  c("deviation from the size expectation (GIFTs)" = "residual",
    "supported GIFTs" = "supported"),
  function(response) {
    fit <- phylogenetic_fit(
      stats::reformulate(names(annotation_terms), response = response),
      annotation_data, annotation_tree
    )
    fit$term <- sub("TRUE$", "", fit$term)
    fit <- fit[fit$term %in% names(annotation_terms), ]
    data.frame(
      response = response, term = fit$term,
      annotation = unname(annotation_terms[fit$term]),
      genomes = nrow(annotation_data),
      one_standard_deviation = unname(annotation_spread[fit$term]),
      phylogenetic_estimate = fit$estimate, standard_error = fit$standard_error,
      p_value = fit$p_value, lambda = fit$lambda, stringsAsFactors = FALSE
    )
  }
))
annotation_models$response <- ifelse(
  annotation_models$response == "residual",
  "deviation from the size expectation (GIFTs)", "supported GIFTs"
)

# Latitude is recorded for a minority of genomes, so it gets its own model.
latitude_data <- genomes[!is.na(genomes$absolute_latitude), ]
latitude_tree <- ape::keep.tip(tree, latitude_data$genome_id)
latitude_spread <- stats::sd(latitude_data$absolute_latitude)
latitude_data$absolute_latitude_scaled <- as.numeric(scale(latitude_data$absolute_latitude))
latitude_models <- do.call(rbind, lapply(
  c("deviation from the size expectation (GIFTs)" = "residual",
    "supported GIFTs" = "supported"),
  function(response) {
    fit <- phylogenetic_fit(
      stats::reformulate("absolute_latitude_scaled", response = response),
      latitude_data, latitude_tree
    )
    fit <- fit[fit$term == "absolute_latitude_scaled", ]
    data.frame(
      response = response, term = "absolute_latitude",
      annotation = "absolute latitude (per s.d.)", genomes = nrow(latitude_data),
      one_standard_deviation = latitude_spread,
      phylogenetic_estimate = fit$estimate, standard_error = fit$standard_error,
      p_value = fit$p_value, lambda = fit$lambda, stringsAsFactors = FALSE
    )
  }
))
latitude_models$response <- ifelse(
  latitude_models$response == "residual",
  "deviation from the size expectation (GIFTs)", "supported GIFTs"
)
annotation_models <- rbind(annotation_models, latitude_models)
annotation_models$q_value <- stats::ave(
  annotation_models$p_value, annotation_models$response,
  FUN = function(p) stats::p.adjust(p, method = "BH")
)
rownames(annotation_models) <- NULL

# ----------------------------------------------------------------------- tables

signif_columns <- function(table, columns, digits = 4) {
  for (column in columns) table[[column]] <- signif(table[[column]], digits)
  table
}
write_tsv(
  signif_columns(origin_genome, c(
    "naive_difference", "phylogenetic_estimate", "standard_error", "p_value",
    "lambda", "q_value"
  )),
  file.path(output_dir, "gtdb-origin-genome-traits.tsv")
)
write_tsv(
  signif_columns(origin_class, c(
    "standardised_estimate", "standard_error", "p_value", "lambda", "q_value"
  )),
  file.path(output_dir, "gtdb-origin-gift-classes.tsv")
)
write_tsv(
  signif_columns(origin_gift[order(origin_gift$q_value), c(
    "origin", "gift_id", "gift_type", "mode", "prevalence_in_group",
    "prevalence_outside", "prevalence_difference", "odds_ratio", "p_value",
    "q_value"
  )], c(
    "prevalence_in_group", "prevalence_outside", "prevalence_difference",
    "odds_ratio", "p_value", "q_value"
  )),
  file.path(output_dir, "gtdb-origin-gifts.tsv")
)
write_tsv(
  signif_columns(annotation_models, c(
    "one_standard_deviation", "phylogenetic_estimate", "standard_error",
    "p_value", "lambda", "q_value"
  )),
  file.path(output_dir, "gtdb-annotation-associations.tsv")
)
write_tsv(
  data.frame(
    item = c(
      "genomes", "origin groups tested", "origin groups below the minimum",
      "minimum genomes per origin group", "genome-level model",
      "class-level model", "GIFT-level screen", "annotation model",
      "latitude model", "false discovery rate",
      "origin and class pairs tested", "origin and class pairs at the false discovery rate",
      "origin and GIFT pairs tested", "origin and GIFT pairs at the false discovery rate"
    ),
    value = c(
      nrow(genomes), paste(origin_label(tested_origins), collapse = "; "),
      paste(origin_label(setdiff(origin_columns, tested_origins)), collapse = "; "),
      MIN_ORIGIN_GENOMES,
      "phylolm, Pagel's lambda: response on all tested origin tags jointly",
      "phylolm, Pagel's lambda: standardised supported count in the class on all tested origin tags jointly and log2 genome size; Benjamini-Hochberg over all pairs",
      "Fisher's exact test of support inside against outside each origin group, unadjusted for genome size and phylogeny; Benjamini-Hochberg over all pairs",
      "phylolm, Pagel's lambda: response on all annotations jointly, continuous annotations per standard deviation, single-cell assemblies excluded",
      paste0("phylolm, Pagel's lambda: response on absolute latitude, ", nrow(latitude_data), " genomes with coordinates"),
      FDR, nrow(origin_class), sum(origin_class$q_value < FDR),
      nrow(origin_gift), sum(origin_gift$q_value < FDR)
    ),
    stringsAsFactors = FALSE
  ),
  file.path(output_dir, "gtdb-origin-and-annotations-methods.tsv")
)

# ----------------------------------------------------------------------- themes

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
    legend.key.height = grid::unit(2.5, "mm"),
    axis.title.x = element_text(size = 6)
  )
fdr_fill <- scale_fill_manual(
  values = c(`TRUE` = "#234f84", `FALSE` = "white"),
  labels = c(`TRUE` = paste("FDR <", FDR), `FALSE` = "not significant"),
  name = NULL, drop = FALSE
)
diverging <- function(limit, name) scale_fill_gradient2(
  low = "#2f6f9f", mid = "#f6f5f1", high = "#c8553d", midpoint = 0,
  limits = c(-limit, limit), name = name
)

# ------------------------------------------------------------------- Figure S13

origin_order <- names(sort(origin_counts[tested_origins]))
origin_axis <- setNames(
  paste0(origin_label(origin_order), " (", origin_counts[origin_order], ")"),
  origin_order
)
origin_plot <- origin_genome
origin_plot$origin <- factor(origin_plot$origin, levels = origin_order)
origin_plot$response <- factor(origin_plot$response, levels = names(responses))
origin_plot$significant <- factor(origin_plot$q_value < FDR, levels = c(FALSE, TRUE))
panel_origin <- ggplot(origin_plot, aes(x = phylogenetic_estimate, y = origin)) +
  geom_vline(xintercept = 0, colour = "#252522", linewidth = 0.25) +
  geom_segment(aes(
    x = phylogenetic_estimate - stats::qnorm(0.975) * standard_error,
    xend = phylogenetic_estimate + stats::qnorm(0.975) * standard_error,
    yend = origin
  ), colour = "#8a8984", linewidth = 0.35) +
  geom_point(aes(fill = significant), shape = 21, size = 1.5,
             colour = "#234f84", stroke = 0.35) +
  facet_wrap(vars(response), nrow = 1, scales = "free_x") +
  scale_y_discrete(labels = origin_axis) +
  fdr_fill +
  labs(
    title = "a  Genome size, repertoire and deviation",
    x = "difference for genomes carrying the origin tag (phylogenetic regression)",
    y = NULL
  ) +
  base_theme +
  theme(
    panel.grid.major.y = element_blank(), axis.text.y = element_text(size = 5.8),
    strip.text = element_text(size = 6, face = "bold")
  )

class_plot <- origin_class
class_levels <- unique(class_plot[order(
  match(class_plot$grouping, c("gift_type", "mode", CLASS_FACETS)), class_plot$class
), c("grouping", "class", "gifts")])
class_plot$row <- factor(
  paste(class_plot$grouping, class_plot$class),
  levels = rev(paste(class_levels$grouping, class_levels$class))
)
class_plot$origin <- factor(class_plot$origin, levels = rev(origin_order))
class_plot$grouping_label <- factor(
  c(gift_type = "type", mode = "mode", physiological_role = "physiological role",
    substrate_class = "substrate class")[class_plot$grouping],
  levels = c("type", "mode", "physiological role", "substrate class")
)
class_limit <- max(abs(class_plot$standardised_estimate))
panel_class <- ggplot(class_plot, aes(x = origin, y = row)) +
  geom_tile(aes(fill = standardised_estimate), colour = "white", linewidth = 0.2) +
  geom_point(data = class_plot[class_plot$q_value < FDR, ], size = 0.5,
             colour = "#252522") +
  facet_grid(rows = vars(grouping_label), scales = "free_y", space = "free_y") +
  scale_x_discrete(labels = function(x) origin_label(x)) +
  scale_y_discrete(labels = setNames(
    paste0(pretty_name(class_levels$class), " (", class_levels$gifts, ")"),
    paste(class_levels$grouping, class_levels$class)
  )) +
  diverging(class_limit, "supported GIFTs in class, s.d.") +
  labs(title = "b  Classes of GIFT, given genome size", x = NULL, y = NULL) +
  base_theme +
  theme(
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 40, hjust = 1, size = 5.8),
    axis.text.y = element_text(size = 5.6),
    strip.text.y = element_text(size = 5.6, angle = 0, hjust = 0),
    legend.key.width = grid::unit(8, "mm")
  )

figure_s13 <- panel_origin / panel_class +
  plot_layout(heights = c(1, 2.1)) +
  plot_annotation(
    title = "Encoded repertoire by origin of the genome",
    subtitle = wrap_text(paste0(
      "Nonexclusive origin tags of ", format(nrow(genomes), big.mark = ","),
      " GTDB genomes (count in brackets), fitted jointly in phylogenetic regressions on the pruned bac120 tree. ",
      "a: points with 95% intervals. b: a dot marks a false discovery rate below ", FDR,
      " over all ", nrow(origin_class), " pairs."
    ), 150),
    caption = wrap_text(paste0(
      "Origin tags are coarse labels parsed from the free-text isolation source, and the panel was balanced on them by design. ",
      "A difference describes encoded, curated capability, not activity, phenotype or ecological function."
    ), 165),
    theme = annotation_theme
  )
ggsave(
  file.path(figure_dir, "figure-s13-gtdb-origin-repertoire.pdf"), figure_s13,
  width = 190, height = 205, units = "mm", device = grDevices::cairo_pdf, bg = "white"
)
ggsave(
  file.path(figure_dir, "figure-s13-gtdb-origin-repertoire.png"), figure_s13,
  width = 190, height = 205, units = "mm", dpi = 320, bg = "white"
)

# ------------------------------------------------------------------- Figure S14

strongest <- stats::aggregate(
  abs(prevalence_difference) ~ gift_id,
  origin_gift[origin_gift$q_value < FDR, ], max
)
names(strongest)[[2L]] <- "largest_difference"
strongest <- utils::head(
  strongest[order(-strongest$largest_difference), ], HEATMAP_GIFTS
)
gift_plot <- origin_gift[origin_gift$gift_id %in% strongest$gift_id, ]
gift_wide <- tapply(
  gift_plot$prevalence_difference, list(gift_plot$gift_id, gift_plot$origin), mean
)
gift_levels <- rownames(gift_wide)[stats::hclust(stats::dist(gift_wide))$order]
gift_plot$gift_id <- factor(gift_plot$gift_id, levels = gift_levels)
gift_plot$origin <- factor(gift_plot$origin, levels = rev(origin_order))
gift_plot$percentage_points <- 100 * gift_plot$prevalence_difference
figure_s14 <- ggplot(gift_plot, aes(x = origin, y = gift_id)) +
  geom_tile(aes(fill = percentage_points), colour = "white", linewidth = 0.2) +
  geom_point(data = gift_plot[gift_plot$q_value < FDR, ], size = 0.5,
             colour = "#252522") +
  scale_x_discrete(labels = function(x) origin_label(x)) +
  scale_y_discrete(labels = pretty_name) +
  diverging(max(abs(gift_plot$percentage_points)),
            "prevalence inside minus outside the group, percentage points") +
  labs(x = NULL, y = NULL) +
  base_theme +
  theme(
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 40, hjust = 1, size = 5.8),
    axis.text.y = element_text(size = 5.4),
    legend.key.width = grid::unit(8, "mm")
  ) +
  plot_annotation(
    title = "Individual GIFTs by origin of the genome",
    subtitle = wrap_text(paste0(
      "The ", nrow(strongest), " GIFTs with the largest prevalence difference among the ",
      length(unique(origin_gift$gift_id[origin_gift$q_value < FDR])),
      " that differ between an origin group and the rest of the panel. A dot marks Fisher's exact test at a false discovery rate below ",
      FDR, " over all ", format(nrow(origin_gift), big.mark = ","), " pairs."
    ), 120),
    caption = wrap_text(paste0(
      "This screen adjusts for neither genome size nor phylogeny, so a difference may reflect which lineages were sampled from an origin. ",
      "It describes encoded, curated capability, not activity or ecological function."
    ), 130),
    theme = annotation_theme
  )
ggsave(
  file.path(figure_dir, "figure-s14-gtdb-origin-gifts.pdf"), figure_s14,
  width = 150, height = 190, units = "mm", device = grDevices::cairo_pdf, bg = "white"
)
ggsave(
  file.path(figure_dir, "figure-s14-gtdb-origin-gifts.png"), figure_s14,
  width = 150, height = 190, units = "mm", dpi = 320, bg = "white"
)

# ------------------------------------------------------------------- Figure S15

annotation_plot <- annotation_models
annotation_plot$annotation <- paste0(
  annotation_plot$annotation, " (", annotation_plot$genomes, ")"
)
annotation_plot$annotation <- factor(
  annotation_plot$annotation, levels = rev(unique(annotation_plot$annotation))
)
annotation_plot$significant <- factor(annotation_plot$q_value < FDR, levels = c(FALSE, TRUE))
panel_annotations <- ggplot(annotation_plot, aes(x = phylogenetic_estimate, y = annotation)) +
  geom_vline(xintercept = 0, colour = "#252522", linewidth = 0.25) +
  geom_segment(aes(
    x = phylogenetic_estimate - stats::qnorm(0.975) * standard_error,
    xend = phylogenetic_estimate + stats::qnorm(0.975) * standard_error,
    yend = annotation
  ), colour = "#8a8984", linewidth = 0.35) +
  geom_point(aes(fill = significant), shape = 21, size = 1.5,
             colour = "#234f84", stroke = 0.35) +
  facet_wrap(vars(response), nrow = 1, scales = "free_x") +
  fdr_fill +
  labs(
    title = "a  Assembly annotations",
    x = "difference in GIFTs (phylogenetic regression)", y = NULL
  ) +
  base_theme +
  theme(
    panel.grid.major.y = element_blank(), axis.text.y = element_text(size = 5.8),
    strip.text = element_text(size = 6, face = "bold")
  )

category_data <- genomes[!genomes$single_cell_derived, ]
category_data$category <- ifelse(
  category_data$metagenome_derived, "metagenome-derived", "isolate"
)
category_counts <- table(category_data$category)
panel_category <- ggplot(category_data, aes(x = category, y = residual)) +
  geom_hline(yintercept = 0, colour = "#252522", linewidth = 0.25) +
  geom_boxplot(outlier.shape = NA, linewidth = 0.25, width = 0.55,
               colour = "#555550", fill = "#e4e3de") +
  geom_point(size = 0.4, alpha = 0.5, colour = "#252522",
             position = position_jitter(width = 0.16, height = 0, seed = 1L)) +
  scale_x_discrete(labels = function(x) paste0(x, "\n(", category_counts[x], ")")) +
  labs(title = "b  Genome category", x = NULL, y = "observed − expected GIFTs") +
  base_theme
panel_completeness <- ggplot(genomes, aes(x = checkm2_completeness, y = residual)) +
  geom_hline(yintercept = 0, colour = "#252522", linewidth = 0.25) +
  geom_point(aes(colour = metagenome_derived), size = 0.6, alpha = 0.8) +
  scale_colour_manual(
    values = c(`FALSE` = "#8a8984", `TRUE` = "#c8553d"),
    labels = c(`FALSE` = "isolate or single cell", `TRUE` = "metagenome-derived"),
    name = NULL
  ) +
  labs(title = "c  Estimated completeness", x = "CheckM2 completeness (%)",
       y = "observed − expected GIFTs") +
  base_theme
panel_latitude <- ggplot(latitude_data, aes(x = absolute_latitude, y = residual)) +
  geom_hline(yintercept = 0, colour = "#252522", linewidth = 0.25) +
  geom_point(size = 0.6, alpha = 0.8, colour = "#8a8984") +
  labs(title = "d  Latitude", x = "absolute latitude (degrees)",
       y = "observed − expected GIFTs") +
  base_theme

figure_s15 <- panel_annotations /
  (panel_category + panel_completeness + panel_latitude) +
  plot_layout(heights = c(1, 1.15)) +
  plot_annotation(
    title = "Encoded repertoire by assembly annotation",
    subtitle = wrap_text(paste0(
      "a: annotations fitted jointly in a phylogenetic regression (genomes in brackets; latitude fitted alone on the genomes with coordinates), ",
      "points with 95% intervals. b to d: deviation from the Figure S9 size expectation."
    ), 150),
    caption = wrap_text(paste0(
      "Completeness and contamination are CheckM2 estimates, which are themselves marker-based. ",
      "A difference describes encoded, curated capability in this panel, not activity or phenotype."
    ), 165),
    theme = annotation_theme
  )
ggsave(
  file.path(figure_dir, "figure-s15-gtdb-annotation-repertoire.pdf"), figure_s15,
  width = 190, height = 150, units = "mm", device = grDevices::cairo_pdf, bg = "white"
)
ggsave(
  file.path(figure_dir, "figure-s15-gtdb-annotation-repertoire.png"), figure_s15,
  width = 190, height = 150, units = "mm", dpi = 320, bg = "white"
)

cat("Wrote GTDB origin and annotation tables and Figures S13 to S15.\n")
