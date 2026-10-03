#!/usr/bin/env Rscript
# Figures 1--5 and their worked-example traces.
#
# These figures explain behaviour that is already fixed by the public API. They
# do not analyse R8 or R10 data. The worked examples are deliberately small:
#
#   * PRPP -> IMP -> AMP is the curated integration fixture used throughout the
#     package tests. Figure 1 follows its AMP branch through every evidence
#     layer, and Figure 2 shows why the two atomic GIFTs compose at IMP.
#   * The four-genome arabinoxylan chain is an illustrative fixture, not a
#     sampled community. Figures 3 and 5 use it to distinguish public-goods
#     degradation, uptake, intracellular catabolism and potential handoffs.
#
# Figure 4 constructs one synthetic marker profile from accepted markers in the
# current database. It completes five members of each displayed frame. The
# example is about the denominator contract, not about an organism.
#
# Products:
#   manuscript/figures/figure-{1,...,5}-*.{pdf,png}
#   manuscript/analysis/output/worked-example-*.tsv
#
# Usage:
#   Rscript manuscript/analysis/20-figures-core.R

suppressWarnings(suppressMessages({
  devtools::load_all(".", quiet = TRUE)
  library(ggplot2)
  library(patchwork)
}))

fig_dir <- "manuscript/figures"
out_dir <- "manuscript/analysis/output"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

INK       <- "#1c1c1a"
MUTED     <- "#6b6b66"
GRID      <- "#deddd7"
SURFACE   <- "#fcfcfb"
BLUE      <- "#2a78d6"
ORANGE    <- "#eb6834"
GREEN     <- "#27845f"
PURPLE    <- "#7656a8"
PALE_BLUE <- "#e8f0fb"
PALE_ORG  <- "#fbece5"
PALE_GRN  <- "#e7f3ed"
PALE_GREY <- "#efefec"
PALE_PURP <- "#eee9f5"

theme_gifter <- function(base_size = 7.2) {
  theme_minimal(base_size = base_size) +
    theme(
      text = element_text(colour = INK),
      plot.background = element_rect(fill = SURFACE, colour = NA),
      panel.background = element_rect(fill = SURFACE, colour = NA),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = "#e6e5e0", linewidth = 0.25),
      axis.text = element_text(colour = MUTED),
      axis.title = element_text(colour = MUTED),
      strip.text = element_text(colour = INK, face = "bold", hjust = 0),
      plot.title = element_text(face = "bold", size = rel(1.12), hjust = 0),
      plot.subtitle = element_text(colour = MUTED, size = rel(0.92), hjust = 0),
      plot.caption = element_text(colour = MUTED, size = rel(0.84), hjust = 0),
      legend.position = "bottom",
      legend.title = element_blank()
    )
}

save_figure <- function(plot, stem, width, height) {
  pdf <- file.path(fig_dir, paste0(stem, ".pdf"))
  png <- file.path(fig_dir, paste0(stem, ".png"))
  ggsave(pdf, plot, width = width, height = height, units = "mm",
         device = grDevices::cairo_pdf, bg = SURFACE)
  ggsave(png, plot, width = width, height = height, units = "mm", dpi = 320,
         bg = SURFACE)
  message("wrote ", pdf)
  message("wrote ", png)
}

arrow_head <- grid::arrow(length = grid::unit(2.2, "mm"), type = "closed")
write_tsv <- function(x, name) {
  utils::write.table(
    x, file.path(out_dir, name), sep = "\t", quote = FALSE,
    row.names = FALSE, na = ""
  )
}

# -------------------------------------------------------------------- examples

purine_annotations <- data.frame(
  gene_id = paste0("purine_gene_", seq_len(9)),
  namespace = "KO",
  accession = c(
    "K00764", "K01945", "K00601", "K01952", "K01933",
    "K01587", "K01756", "K00602", "K01939"
  ),
  stringsAsFactors = FALSE
)
purine_result <- evaluate_gifts(purine_annotations)
amp_trace <- as.data.frame(trace_gift(purine_result, "adenylate_biosynthesis"))
purine_calls <- purine_result$gifts[
  purine_result$gifts$gift_id %in%
    c("purine_core_biosynthesis", "adenylate_biosynthesis"),
]
stopifnot(
  nrow(purine_calls) == 2L,
  all(purine_calls$complete),
  nrow(amp_trace) == 2L,
  identical(amp_trace$reaction_id, c("RHEA:15753", "RHEA:16853")),
  identical(amp_trace$accession, c("K01939", "K01756")),
  all(amp_trace$confidence == "curated")
)
write_tsv(amp_trace, "worked-example-purine-trace.tsv")

namespaced_annotations <- function(markers, genome_id = NULL, prefix = "gene") {
  out <- data.frame(
    gene_id = paste0(prefix, "_", seq_along(markers)),
    namespace = sub(":.*", "", markers),
    accession = sub(".*:", "", markers),
    stringsAsFactors = FALSE
  )
  if (!is.null(genome_id)) out$genome_id <- genome_id
  out
}

arabinoxylan_markers <- list(
  A = "KO:K01209",
  B = c("CAZY:GH11", "CAZY:GH39"),
  C = c("KO:K10543", "KO:K10544", "KO:K10545", "KO:K01805", "KO:K00854"),
  D = c("KO:K10543", "KO:K10544", "KO:K10545", "KO:K01805", "KO:K00854")
)
community_input <- do.call(rbind, lapply(names(arabinoxylan_markers), function(id) {
  namespaced_annotations(arabinoxylan_markers[[id]], id, paste0(id, "_gene"))
}))
community_input <- community_input[c("genome_id", "gene_id", "namespace", "accession")]
community <- evaluate_gifts_community(
  community_input, workers = 1, progress = FALSE, max_genes = Inf
)
all_frame <- reference_frame(label = "all curated GIFTs")
community_summary <- community_traits(
  community, frames = list(all_frame), pairwise = FALSE, progress = FALSE
)
community_handoffs <- community_network(community)
stopifnot(
  community_summary$metrics$value[
    community_summary$metrics$metric_id == "community_richness"
  ] == 4,
  community_summary$metrics$value[
    community_summary$metrics$metric_id == "singleton_fraction"
  ] == 0.5,
  nrow(community_handoffs$edges) == 3L,
  identical(sort(unique(community_handoffs$edges$shared_anchor)),
            c("XYLAN", "XYLOSE_EX")),
  all(community_handoffs$edges$edge_quality == "exact")
)
write_tsv(as.data.frame(community_summary$metrics),
          "worked-example-community-metrics.tsv")
write_tsv(as.data.frame(community_handoffs$edges),
          "worked-example-community-edges.tsv")

# Select one accepted marker per component of one deterministic minimal route.
# This is synthetic evidence assembled from the current database, never an
# annotation of a named organism. The evaluator, not this helper, decides which
# GIFTs it actually completes.
confidence_rank <- c(
  "insufficient evidence" = 1L, ambiguous = 2L, putative = 3L,
  "high-confidence" = 4L, curated = 5L
)
markers_for_gift <- function(gift_id) {
  reactions <- as.data.frame(get_gift_reactions(gift_id))
  route <- sort(unique(reactions$route_id))[[1L]]
  reactions <- reactions[
    reactions$route_id == route & reactions$required == 1L, , drop = FALSE
  ]
  selected <- list()
  for (reaction_id in unique(reactions$reaction_id)) {
    systems <- as.data.frame(get_reaction_systems(reaction_id))
    sizes <- aggregate(
      component_id ~ system_id, systems,
      function(x) length(unique(x))
    )
    system_id <- sizes$system_id[order(sizes$component_id, sizes$system_id)][[1L]]
    system <- systems[systems$system_id == system_id, , drop = FALSE]
    for (component_id in unique(system$component_id)) {
      candidates <- system[system$component_id == component_id, , drop = FALSE]
      rank <- unname(confidence_rank[candidates$confidence])
      candidates <- candidates[
        order(-rank, candidates$namespace, candidates$accession), , drop = FALSE
      ]
      selected[[length(selected) + 1L]] <- candidates[
        1L, c("namespace", "accession"), drop = FALSE
      ]
    }
  }
  unique(do.call(rbind, selected))
}

aa_frame <- reference_frame(preset = "amino_acid_autonomy")
carb_frame <- reference_frame(preset = "carbohydrate_degradation")
frame_targets <- c(utils::head(aa_frame$gift_id, 5L),
                   utils::head(carb_frame$gift_id, 5L))
frame_annotations <- unique(do.call(rbind, lapply(frame_targets, markers_for_gift)))
frame_annotations$gene_id <- paste0("frame_gene_", seq_len(nrow(frame_annotations)))
frame_annotations <- frame_annotations[c("gene_id", "namespace", "accession")]
frame_result <- evaluate_gifts(frame_annotations)
frame_default <- genome_traits(
  frame_result, frames = list(aa_frame, carb_frame), genome_id = "illustrative_profile",
  quality = c(illustrative_profile = 0.60), policy = "none"
)
frame_policy <- suppressWarnings(genome_traits(
  frame_result, frames = list(aa_frame, carb_frame), genome_id = "illustrative_profile",
  quality = c(illustrative_profile = 0.60), policy = "completeness", threshold = 0.90
))
frame_supported <- frame_result$gifts$gift_id[frame_result$gifts$complete]
stopifnot(
  sum(aa_frame$gift_id %in% frame_supported) == 5L,
  sum(carb_frame$gift_id %in% frame_supported) == 5L
)
frame_metrics <- rbind(
  transform(as.data.frame(frame_default$metrics), policy = "none"),
  transform(as.data.frame(frame_policy$metrics), policy = "completeness")
)
write_tsv(frame_metrics, "worked-example-frame-metrics.tsv")

# -------------------------------------------------------------------- Figure 1

vocabulary <- data.frame(
  gift_type = rep(c("metabolic", "structural", "regulatory", "defense"), each = 6),
  layer = rep(seq_len(6), 4),
  label = c(
    "GIFT", "route", "reaction", "enzyme\nsystem", "component", "marker",
    "GIFT", "architecture", "structural\nfunction", "system", "component", "marker",
    "GIFT", "circuit", "regulatory\nfunction", "system", "component", "marker",
    "GIFT", "mechanism", "defense\nfunction", "system", "component", "marker"
  ),
  stringsAsFactors = FALSE
)
vocabulary$y <- 5L - match(vocabulary$gift_type,
                           c("metabolic", "structural", "regulatory", "defense"))
vocabulary$fill <- rep(c(PALE_BLUE, PALE_ORG, PALE_GRN, PALE_PURP), each = 6)

panel_1a <- ggplot(vocabulary) +
  geom_tile(aes(layer, y, fill = fill), width = 0.84, height = 0.68,
            colour = "white", linewidth = 0.5) +
  geom_text(aes(layer, y, label = label), size = 2.45, lineheight = 0.9) +
  geom_text(
    data = data.frame(x = 0.28, y = 4:1,
                      label = c("metabolic", "structural", "regulatory", "defense")),
    aes(x, y, label = label), hjust = 1, fontface = "bold", size = 2.6
  ) +
  geom_text(
    data = data.frame(x = seq(1.5, 5.5, 1), y = 4.72,
                      label = c("OR", "AND", "OR", "AND", "OR")),
    aes(x, y, label = label), colour = MUTED, fontface = "bold", size = 2.2
  ) +
  geom_segment(
    data = data.frame(x = seq(1.42, 5.42, 1), xend = seq(1.58, 5.58, 1)),
    aes(x = x, xend = xend, y = 4.43, yend = 4.43),
    arrow = grid::arrow(length = grid::unit(1.5, "mm")), colour = MUTED
  ) +
  scale_fill_identity() +
  coord_cartesian(xlim = c(-0.8, 6.45), ylim = c(0.55, 4.92), clip = "off") +
  labs(
    title = "a   One Boolean hierarchy, four biological vocabularies",
    subtitle = "The operators do not change with GIFT type; the biological nouns do"
  ) +
  theme_void(base_size = 7.2) +
  theme(
    plot.background = element_rect(fill = SURFACE, colour = NA),
    plot.title = element_text(face = "bold", colour = INK),
    plot.subtitle = element_text(colour = MUTED),
    plot.margin = margin(4, 8, 2, 25)
  )

trace_rows <- amp_trace[c(
  "reaction_id", "system_id", "component_id", "gene_id", "namespace", "accession"
)]
trace_rows$branch <- seq_len(nrow(trace_rows))
trace_nodes <- rbind(
  data.frame(x = 1, y = trace_rows$branch,
             label = paste0(trace_rows$namespace, ":", trace_rows$accession,
                            "\n", trace_rows$gene_id), type = "marker"),
  data.frame(x = 2, y = trace_rows$branch, label = trace_rows$component_id,
             type = "component"),
  data.frame(x = 3, y = trace_rows$branch, label = trace_rows$system_id,
             type = "system"),
  data.frame(x = 4, y = trace_rows$branch, label = trace_rows$reaction_id,
             type = "reaction"),
  data.frame(x = 5, y = 1.5, label = unique(amp_trace$route_id), type = "route"),
  data.frame(x = 6, y = 1.5, label = "adenylate\nbiosynthesis", type = "gift")
)
trace_edges <- rbind(
  do.call(rbind, lapply(seq_len(nrow(trace_rows)), function(branch) data.frame(
    x = 1:3 + 0.2, xend = 2:4 - 0.2, y = branch, yend = branch
  ))),
  data.frame(x = 4.2, xend = 4.8, y = trace_rows$branch, yend = 1.5),
  data.frame(x = 5.2, xend = 5.8, y = 1.5, yend = 1.5)
)

panel_1b <- ggplot() +
  geom_segment(
    data = trace_edges, aes(x, y, xend = xend, yend = yend),
    colour = MUTED, linewidth = 0.35, arrow = arrow_head
  ) +
  geom_label(
    data = trace_nodes,
    aes(x, y, label = label, fill = type),
    linewidth = 0.18, label.padding = grid::unit(1.5, "mm"),
    size = 2.05, lineheight = 0.9, colour = INK
  ) +
  geom_text(
    data = data.frame(x = seq(1, 6), y = 2.72,
                      label = c("marker", "component", "system", "reaction", "route", "GIFT")),
    aes(x, y, label = label), colour = MUTED, size = 2.15, fontface = "bold"
  ) +
  annotate("text", x = 4.5, y = 0.62, label = "AND: both required reactions", size = 2.2,
           colour = MUTED) +
  annotate("label", x = 6, y = 0.62,
           label = "complete = TRUE\nconfidence = curated", size = 2.05,
           fill = PALE_GRN, linewidth = 0.2, label.padding = grid::unit(1.2, "mm")) +
  scale_fill_manual(values = c(
    marker = PALE_GREY, component = "white", system = PALE_GRN,
    reaction = PALE_ORG, route = PALE_BLUE, gift = BLUE
  )) +
  coord_cartesian(xlim = c(0.55, 6.45), ylim = c(0.32, 2.9), clip = "off") +
  labs(
    title = "b   A complete AMP call remains traceable to two genes",
    subtitle = "The current database and evaluate_gifts() produced every identifier shown"
  ) +
  theme_void(base_size = 7.2) +
  theme(
    plot.background = element_rect(fill = SURFACE, colour = NA),
    plot.title = element_text(face = "bold", colour = INK),
    plot.subtitle = element_text(colour = MUTED),
    legend.position = "none",
    plot.margin = margin(3, 8, 4, 8)
  )

figure_1 <- panel_1a / panel_1b + plot_layout(heights = c(1, 0.78))
save_figure(figure_1, "figure-1-hierarchy", 190, 135)

# -------------------------------------------------------------------- Figure 2

nodes_2 <- data.frame(
  x = c(0, 1.35, 2.7, 4.05, 4.05, 5.4, 5.4),
  y = c(1.5, 1.5, 1.5, 2.18, 0.82, 2.18, 0.82),
  label = c(
    "PRPP", "purine core\nbiosynthesis", "IMP", "adenylate\nbiosynthesis",
    "guanylate\nbiosynthesis", "AMP", "GMP"
  ),
  kind = c("anchor", "gift", "anchor", "gift", "gift", "anchor", "anchor"),
  stringsAsFactors = FALSE
)
edges_2 <- data.frame(
  x = c(0.22, 1.70, 2.92, 2.92, 4.40, 4.40),
  y = c(1.5, 1.5, 1.5, 1.5, 2.18, 0.82),
  xend = c(1.00, 2.48, 3.70, 3.70, 5.18, 5.18),
  yend = c(1.5, 1.5, 2.18, 0.82, 2.18, 0.82)
)
panel_2a <- ggplot() +
  geom_segment(
    data = edges_2, aes(x, y, xend = xend, yend = yend),
    colour = MUTED, linewidth = 0.45, arrow = arrow_head
  ) +
  geom_label(
    data = nodes_2[nodes_2$kind == "gift", ],
    aes(x, y, label = label), fill = PALE_BLUE, linewidth = 0.22,
    label.padding = grid::unit(2, "mm"), size = 2.4, lineheight = 0.9
  ) +
  geom_point(
    data = nodes_2[nodes_2$kind == "anchor", ],
    aes(x, y), shape = 21, size = 8, stroke = 0.55, colour = BLUE, fill = "white"
  ) +
  geom_text(
    data = nodes_2[nodes_2$kind == "anchor", ],
    aes(x, y, label = label), size = 2.3, fontface = "bold"
  ) +
  annotate("text", x = 1.35, y = 0.97,
           label = "8 alternative routes\n10–11 required reactions", size = 2.0,
           colour = MUTED) +
  annotate("text", x = 4.05, y = 2.63, label = "2 required reactions", size = 2.0,
           colour = MUTED) +
  annotate("text", x = 4.05, y = 0.37, label = "2 required reactions", size = 2.0,
           colour = MUTED) +
  coord_cartesian(xlim = c(-0.45, 5.85), ylim = c(0.05, 2.85), clip = "off") +
  labs(
    title = "a   Declared anchors are the public interface",
    subtitle = "IMP is a defended branchpoint, so one curated core composes with two branches"
  ) +
  theme_void(base_size = 7.2) +
  theme(
    plot.background = element_rect(fill = SURFACE, colour = NA),
    plot.title = element_text(face = "bold"),
    plot.subtitle = element_text(colour = MUTED)
  )

panel_2b <- ggplot() +
  annotate("rect", xmin = 0.25, xmax = 2.45, ymin = 0.65, ymax = 2.25,
           fill = PALE_BLUE, colour = BLUE, linewidth = 0.35) +
  annotate("text", x = 1.35, y = 2.02, label = "one atomic GIFT", fontface = "bold",
           size = 2.6) +
  annotate("text", x = 1.35, y = 1.48,
           label = "PRPP  →  10 reaction steps  →  IMP", size = 2.4) +
  annotate("text", x = 1.35, y = 1.02,
           label = "internal intermediates are not graph nodes", colour = MUTED,
           size = 2.15) +
  annotate("segment", x = 2.65, xend = 4.15, y = 1.45, yend = 1.45,
           colour = MUTED, linewidth = 0.45, arrow = arrow_head) +
  annotate("label", x = 5.1, y = 1.45,
           label = "PRPP → AMP\nis a traversal\nnot a stored GIFT", fill = PALE_GRN,
           linewidth = 0.22, size = 2.35, lineheight = 0.95,
           label.padding = grid::unit(2, "mm")) +
  annotate("text", x = 3.4, y = 1.78, label = "compose at IMP", colour = GREEN,
           fontface = "bold", size = 2.2) +
  coord_cartesian(xlim = c(0, 6.0), ylim = c(0.35, 2.55), clip = "off") +
  labs(
    title = "b   Longer capabilities are traversals, not duplicated curation",
    subtitle = "Shared internal reaction participants create no edge"
  ) +
  theme_void(base_size = 7.2) +
  theme(
    plot.background = element_rect(fill = SURFACE, colour = NA),
    plot.title = element_text(face = "bold"),
    plot.subtitle = element_text(colour = MUTED)
  )

figure_2 <- panel_2a / panel_2b + plot_layout(heights = c(1, 0.72))
save_figure(figure_2, "figure-2-anchors-composition", 190, 125)

# -------------------------------------------------------------------- Figure 3

strategy_panel <- function(kind) {
  base <- ggplot() +
    annotate("rect", xmin = 0, xmax = 6, ymin = 0, ymax = 1.0,
             fill = PALE_BLUE, colour = NA) +
    annotate("rect", xmin = 0, xmax = 6, ymin = 1.0, ymax = 1.10,
             fill = MUTED, colour = NA) +
    annotate("text", x = 5.75, y = 2.47, label = "extracellular", hjust = 1,
             colour = MUTED, size = 2.0) +
    annotate("text", x = 5.75, y = 0.18, label = "cytoplasmic", hjust = 1,
             colour = MUTED, size = 2.0) +
    coord_cartesian(xlim = c(0, 6), ylim = c(0, 2.65), clip = "off") +
    theme_void(base_size = 7) +
    theme(
      plot.background = element_rect(fill = SURFACE, colour = NA),
      plot.title = element_text(face = "bold", size = rel(1.02)),
      plot.subtitle = element_text(colour = MUTED, size = rel(0.88)),
      plot.margin = margin(2, 4, 2, 4)
    )

  if (kind == "public") {
    base +
      annotate("text", x = 0.6, y = 1.88, label = "xylan", fontface = "bold", size = 2.5) +
      annotate("segment", x = 1.05, xend = 2.0, y = 1.88, yend = 1.88,
               arrow = arrow_head, colour = MUTED) +
      annotate("label", x = 3.0, y = 1.88, label = "xylan\ndegradation",
               fill = PALE_ORG, linewidth = 0.2, size = 2.2) +
      annotate("segment", x = 4.0, xend = 4.9, y = 1.88, yend = 1.88,
               arrow = arrow_head, colour = MUTED) +
      annotate("text", x = 5.35, y = 1.88, label = "xylose", fontface = "bold",
               colour = ORANGE, size = 2.5) +
      annotate("label", x = 3.0, y = 0.52, label = "genome A encodes\npublic-good release",
               fill = "white", linewidth = 0.2, size = 2.15) +
      labs(title = "a   Public-goods degrader",
           subtitle = "an extracellular product is accessible beyond the producer")
  } else if (kind == "selfish") {
    base +
      annotate("text", x = 0.42, y = 1.90, label = "xylan", fontface = "bold", size = 2.3) +
      annotate("segment", x = 0.82, xend = 1.45, y = 1.90, yend = 1.90,
               arrow = arrow_head, colour = MUTED) +
      annotate("label", x = 2.12, y = 1.90, label = "degrade", fill = PALE_ORG,
               linewidth = 0.2, size = 2.1) +
      annotate("segment", x = 2.77, xend = 3.15, y = 1.90, yend = 1.90,
               arrow = arrow_head, colour = MUTED) +
      annotate("text", x = 3.48, y = 1.90, label = "xylose", fontface = "bold",
               colour = ORANGE, size = 2.2) +
      annotate("segment", x = 3.48, xend = 3.48, y = 1.65, yend = 0.75,
               arrow = arrow_head, colour = BLUE) +
      annotate("label", x = 4.25, y = 1.20, label = "uptake", fill = PALE_GRN,
               linewidth = 0.2, size = 2.05) +
      annotate("segment", x = 3.75, xend = 4.78, y = 0.56, yend = 0.56,
               arrow = arrow_head, colour = MUTED) +
      annotate("text", x = 5.35, y = 0.56, label = "private\ncatabolism",
               fontface = "bold", size = 2.15) +
      annotate("text", x = 2.25, y = 0.20,
               label = "one genome supports degradation + uptake + catabolism",
               colour = MUTED, size = 1.95) +
      labs(title = "b   Selfish forager",
           subtitle = "the same genome retains the released monomer")
  } else {
    base +
      annotate("label", x = 1.10, y = 0.53, label = "genome A\ndegrades",
               fill = "white", linewidth = 0.2, size = 2.1) +
      annotate("segment", x = 1.10, xend = 1.10, y = 0.78, yend = 1.68,
               arrow = arrow_head, colour = ORANGE) +
      annotate("text", x = 2.75, y = 1.88, label = "extracellular xylose",
               fontface = "bold", colour = ORANGE, size = 2.3) +
      annotate("segment", x = 3.65, xend = 4.72, y = 1.75, yend = 0.73,
               arrow = arrow_head, colour = BLUE) +
      annotate("label", x = 4.95, y = 0.53, label = "genome B\nuptakes + catabolises",
               fill = "white", linewidth = 0.2, size = 2.1) +
      annotate("text", x = 2.75, y = 1.42, label = "declared transferable anchor",
               colour = MUTED, size = 1.95) +
      labs(title = "c   Potential cross-feeder",
           subtitle = "compatibility is encoded; exchange, co-occurrence and activity are not")
  }
}

figure_3 <- strategy_panel("public") / strategy_panel("selfish") /
  strategy_panel("cross") + plot_layout(heights = c(1, 1, 1))
save_figure(figure_3, "figure-3-compartment-strategy", 190, 170)

# -------------------------------------------------------------------- Figure 4

frame_calls <- frame_result$gifts[c("gift_id", "complete")]
frame_tiles <- do.call(rbind, lapply(list(aa_frame, carb_frame), function(frame) {
  supported <- frame_calls$gift_id[frame_calls$complete]
  data.frame(
    frame = frame$label,
    member = seq_along(frame$gift_id),
    row = ceiling(seq_along(frame$gift_id) / 11),
    col = (seq_along(frame$gift_id) - 1L) %% 11L + 1L,
    state = ifelse(frame$gift_id %in% supported, "supported", "unsupported"),
    bounded = frame$bounded,
    stringsAsFactors = FALSE
  )
}))
frame_order <- c(aa_frame$label, carb_frame$label)
frame_tiles$frame <- factor(frame_tiles$frame, levels = frame_order)

headline <- frame_metrics[
  frame_metrics$policy == "none" &
    frame_metrics$metric_id %in% c("gift_richness", "supported_fraction"),
]
richness <- headline[headline$metric_id == "gift_richness", ]
fraction <- headline[headline$metric_id == "supported_fraction", ]
frame_labels <- vapply(frame_order, function(label) {
  r <- richness[richness$reference_frame == label, ]
  f <- fraction[fraction$reference_frame == label, ]
  if (nrow(f)) {
    sprintf("%s\n%d supported of %d; fraction = %.3f",
            label, r$numerator, r$assessable, f$value)
  } else {
    sprintf("%s\n%d supported of %d; fraction withheld",
            label, r$numerator, r$assessable)
  }
}, character(1))
names(frame_labels) <- frame_order

panel_4a <- ggplot(frame_tiles, aes(col, -row, fill = state)) +
  geom_tile(width = 0.82, height = 0.82, colour = "white", linewidth = 0.35) +
  facet_wrap(~ frame, ncol = 1, labeller = as_labeller(frame_labels)) +
  scale_fill_manual(values = c(supported = BLUE, unsupported = PALE_GREY)) +
  coord_equal() +
  labs(
    title = "a   The same count does not license the same fraction",
    subtitle = "Five supported GIFTs in each current frame; each square is one frame member"
  ) +
  theme_void(base_size = 7.2) +
  theme(
    plot.background = element_rect(fill = SURFACE, colour = NA),
    plot.title = element_text(face = "bold"),
    plot.subtitle = element_text(colour = MUTED),
    strip.text = element_text(face = "bold", hjust = 0, colour = INK),
    legend.position = "bottom",
    plot.margin = margin(4, 4, 4, 4)
  )

aa_ids <- aa_frame$gift_id
aa_supported <- frame_result$gifts$gift_id[
  frame_result$gifts$complete & frame_result$gifts$gift_id %in% aa_ids
]
policy_tiles <- rbind(
  data.frame(
    policy = "default: every negative is assessed", member = seq_along(aa_ids),
    row = ceiling(seq_along(aa_ids) / 11),
    col = (seq_along(aa_ids) - 1L) %% 11L + 1L,
    state = ifelse(aa_ids %in% aa_supported, "supported", "unsupported")
  ),
  data.frame(
    policy = "60% complete MAG; threshold = 90%", member = seq_along(aa_ids),
    row = ceiling(seq_along(aa_ids) / 11),
    col = (seq_along(aa_ids) - 1L) %% 11L + 1L,
    state = ifelse(aa_ids %in% aa_supported, "supported", "indeterminate")
  )
)
policy_order <- c("default: every negative is assessed", "60% complete MAG; threshold = 90%")
policy_tiles$policy <- factor(policy_tiles$policy, levels = policy_order)

metric_value <- function(metrics, policy, id) {
  row <- metrics[
    metrics$policy == policy & metrics$reference_frame == aa_frame$label &
      metrics$metric_id == id, , drop = FALSE
  ]
  row$value[[1L]]
}
policy_labels <- c(
  sprintf(
    "default: every negative is assessed\nsupported_fraction = %.3f; assessable_fraction = %.3f",
    metric_value(frame_metrics, "none", "supported_fraction"),
    metric_value(frame_metrics, "none", "assessable_fraction")
  ),
  sprintf(
    "60%% complete MAG; threshold = 90%%\nsupported_fraction = %.3f; assessable_fraction = %.3f",
    metric_value(frame_metrics, "completeness", "supported_fraction"),
    metric_value(frame_metrics, "completeness", "assessable_fraction")
  )
)
names(policy_labels) <- policy_order

panel_4b <- ggplot(policy_tiles, aes(col, -row, fill = state)) +
  geom_tile(width = 0.82, height = 0.82, colour = "white", linewidth = 0.35) +
  facet_wrap(~ policy, ncol = 1, labeller = as_labeller(policy_labels)) +
  scale_fill_manual(values = c(
    supported = BLUE, unsupported = PALE_GREY, indeterminate = "#d8c7a4"
  )) +
  coord_equal() +
  labs(
    title = "b   Assessability moves the denominator, never a call",
    subtitle = paste(
      "The same five positives remain blue;",
      "fragmented-genome silence becomes indeterminate",
      sep = "\n"
    )
  ) +
  theme_void(base_size = 7.2) +
  theme(
    plot.background = element_rect(fill = SURFACE, colour = NA),
    plot.title = element_text(face = "bold"),
    plot.subtitle = element_text(colour = MUTED),
    strip.text = element_text(face = "bold", hjust = 0, colour = INK),
    legend.position = "bottom",
    plot.margin = margin(4, 4, 4, 4)
  )

figure_4 <- panel_4a | panel_4b
figure_4 <- figure_4 + plot_annotation(
  caption = paste(
    "Synthetic accepted-marker profile; not a named genome.",
    "Unbounded fractions are withheld; supported_fraction is read beside assessable_fraction."
  ),
  theme = theme(plot.caption = element_text(size = 6.6, hjust = 0))
)
save_figure(figure_4, "figure-4-reference-frames", 190, 128)

# -------------------------------------------------------------------- Figure 5

chain_gifts <- c(
  "arabinoxylan_debranching", "xylan_degradation",
  "xylose_uptake_abc", "xylose_degradation_isomerase"
)
chain_labels <- c(
  arabinoxylan_debranching = "debranch\narabinoxylan",
  xylan_degradation = "degrade\nxylan",
  xylose_uptake_abc = "take up\nxylose",
  xylose_degradation_isomerase = "catabolise\nxylose"
)
heat <- expand.grid(
  gift_id = chain_gifts, genome_id = community$genome_id,
  stringsAsFactors = FALSE
)
heat$complete <- mapply(function(gift, genome) {
  community$matrix[gift, genome]
}, heat$gift_id, heat$genome_id)
heat$gift_id <- factor(heat$gift_id, levels = rev(chain_gifts),
                       labels = rev(unname(chain_labels[chain_gifts])))
heat$genome_id <- factor(heat$genome_id, levels = community$genome_id)

panel_5a <- ggplot(heat, aes(genome_id, gift_id, fill = complete)) +
  geom_tile(colour = "white", linewidth = 0.7) +
  geom_text(aes(label = ifelse(complete, "supported", "")), size = 2.0,
            colour = "white", fontface = "bold") +
  scale_fill_manual(values = c(`TRUE` = BLUE, `FALSE` = PALE_GREY), guide = "none") +
  coord_equal() +
  labs(
    title = "a   Capability remains assigned to genomes",
    subtitle = "an illustrative four-genome community",
    x = "genome", y = NULL
  ) +
  theme_gifter() +
  theme(panel.grid = element_blank(), axis.ticks = element_blank())

providers <- as.data.frame(community_summary$metrics)
providers <- providers[
  providers$metric_id == "provider_count" & providers$target_id %in% chain_gifts,
  , drop = FALSE
]
providers$label <- factor(
  unname(chain_labels[providers$target_id]),
  levels = rev(unname(chain_labels[chain_gifts]))
)
community_richness <- community_summary$metrics$value[
  community_summary$metrics$metric_id == "community_richness"
][[1L]]
singleton_fraction <- community_summary$metrics$value[
  community_summary$metrics$metric_id == "singleton_fraction"
][[1L]]

panel_5b <- ggplot(providers, aes(value, label)) +
  geom_col(width = 0.58, fill = GREEN) +
  geom_text(aes(label = value), hjust = -0.55, size = 2.4, fontface = "bold") +
  scale_x_continuous(limits = c(0, 2.55), breaks = 0:2) +
  labs(
    title = "b   Presence and redundancy stay separate",
    subtitle = sprintf("community richness = %d; singleton fraction = %.1f",
                       community_richness, singleton_fraction),
    x = "provider genomes", y = NULL
  ) +
  theme_gifter() +
  theme(panel.grid.major.y = element_blank(), legend.position = "none")

network_nodes <- data.frame(
  genome_id = c("A", "B", "C", "D"),
  x = c(0, 1.8, 3.8, 3.8), y = c(1.0, 1.0, 1.65, 0.35),
  role = c("debrancher", "backbone degrader", "consumer", "consumer"),
  stringsAsFactors = FALSE
)
network_edges <- unique(as.data.frame(community_handoffs$edges)[
  c("from_genome", "to_genome", "shared_anchor", "edge_quality")
])
network_edges <- merge(network_edges, network_nodes[c("genome_id", "x", "y")],
                       by.x = "from_genome", by.y = "genome_id")
names(network_edges)[names(network_edges) %in% c("x", "y")] <- c("x", "y")
network_edges <- merge(network_edges, network_nodes[c("genome_id", "x", "y")],
                       by.x = "to_genome", by.y = "genome_id", suffixes = c("", "end"))
network_edges$x_start <- network_edges$x + 0.25
network_edges$x_stop <- network_edges$xend - 0.25
network_edges$y_start <- network_edges$y
network_edges$y_stop <- network_edges$yend
network_edges$label_x <- (network_edges$x_start + network_edges$x_stop) / 2
network_edges$label_y <- (network_edges$y_start + network_edges$y_stop) / 2 + 0.16

panel_5c <- ggplot() +
  geom_segment(
    data = network_edges,
    aes(x_start, y_start, xend = x_stop, yend = y_stop),
    colour = ORANGE, linewidth = 0.55, arrow = arrow_head
  ) +
  geom_label(
    data = network_nodes, aes(x, y, label = genome_id),
    fill = PALE_BLUE, linewidth = 0.3, label.padding = grid::unit(2.1, "mm"),
    fontface = "bold", size = 3
  ) +
  geom_text(
    data = network_nodes, aes(x, y - 0.38, label = role),
    colour = MUTED, size = 2.0
  ) +
  geom_text(
    data = network_edges,
    aes(label_x, label_y, label = shared_anchor),
    colour = ORANGE, size = 2.0, fontface = "bold"
  ) +
  annotate("text", x = 1.95, y = -0.12,
           label = "XYLOSE_IN is cytoplasmic: no cross-genome edge",
           colour = MUTED, size = 2.0) +
  coord_cartesian(xlim = c(-0.45, 4.35), ylim = c(-0.28, 2.02), clip = "off") +
  labs(
    title = "c   Curated extracellular anchors project potential handoffs",
    subtitle = "three exact edges; compatibility is not evidence of exchange"
  ) +
  theme_void(base_size = 7.2) +
  theme(
    plot.background = element_rect(fill = SURFACE, colour = NA),
    plot.title = element_text(face = "bold"),
    plot.subtitle = element_text(colour = MUTED)
  )

figure_5 <- (panel_5a | panel_5b) / panel_5c +
  plot_layout(heights = c(1, 0.78))
save_figure(figure_5, "figure-5-community", 190, 145)

message("Figures 1--5 and worked-example traces are complete.")
