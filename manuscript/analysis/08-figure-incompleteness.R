#!/usr/bin/env Rscript
# Figure 6: behaviour under genome incompleteness.
#
# The figure has to carry an argument the prose can state but not demonstrate:
# that two numbers falling as a genome loses genes are not the same kind of
# number. A percentage decays smoothly and says nothing about what went; a
# route-based call is lost outright and names the reaction that took it. A
# reader shown only the two curves would reasonably prefer the gentler one,
# which is why the second panel is not optional.
#
#   a  call retention against gene content, beside the marker-fraction score on
#      the same genomes and the same subsamples. The gap between the curves is
#      the conservatism, and it is the honest cost of the abstraction.
#   b  what a lost call still tells you: the share of lost calls that are
#      exactly one reaction short, which is the information the percentage
#      discards. This is the panel that decides whether the cost in a was worth
#      paying.
#   c  the assessability policy of R4 on the same subsamples. The naive
#      denominator makes an incomplete genome look like an organism that lost
#      capabilities. The policy does not replace that with a better proportion:
#      below the quality threshold it withholds every unsupported member, so
#      supported_fraction reads 1.000 by construction -- and where nothing at all
#      is assessable it is not emitted, which is why the policy line is a mean
#      over the cells that have one. The whole signal moves into
#      assessable_fraction, so the panel draws both: either alone is misleading.
#
# Everything is read from the committed tables that 02-incompleteness.R writes.
# Nothing is computed here.
#
# Usage:
#   Rscript manuscript/analysis/08-figure-incompleteness.R

source("manuscript/analysis/_common.R")
suppressWarnings(suppressMessages({
  library(ggplot2)
  library(patchwork)
}))

out_dir <- "manuscript/analysis/output"
fig_dir <- "manuscript/figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

INK      <- "#1c1c1a"
MUTED    <- "#6b6b66"
NEUTRAL  <- "#9a9a94"
BLUE     <- "#2a78d6"
ORANGE   <- "#eb6834"
SURFACE  <- "#fcfcfb"

theme_gifter <- function(base_size = 7.0) {
  theme_minimal(base_size = base_size) +
    theme(
      text             = element_text(colour = INK),
      plot.background  = element_rect(fill = SURFACE, colour = NA),
      panel.background = element_rect(fill = SURFACE, colour = NA),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = "#e6e5e0", linewidth = 0.25),
      axis.text        = element_text(colour = MUTED, size = rel(0.92)),
      axis.title       = element_text(colour = MUTED, size = rel(0.95)),
      strip.text       = element_text(colour = INK, face = "bold", size = rel(0.95), hjust = 0),
      plot.title       = element_text(face = "bold", size = rel(1.1), hjust = 0),
      plot.subtitle    = element_text(colour = MUTED, size = rel(0.92), hjust = 0),
      plot.caption     = element_text(colour = MUTED, size = rel(0.86), hjust = 0),
      legend.position  = "bottom",
      legend.title     = element_blank(),
      legend.key.size  = unit(3.2, "mm"),
      legend.text      = element_text(size = rel(0.92)))
}

decay <- read.delim(file.path(out_dir, "incompleteness-decay.tsv"), stringsAsFactors = FALSE)
kv("genomes", length(unique(decay$org)))
kv("gene-content levels", paste(sort(unique(decay$kept)), collapse = ", "))

# ------------------------------------------------------------------- panel A
rule("A. Call retention against gene content")
# Replicates are averaged within a genome first. Three subsamples of one genome
# are not three genomes, and pooling them would let a well-sampled organism
# count three times in the spread.
per_genome <- aggregate(cbind(retention, fullness_ratio) ~ org + kept, decay, mean)
long <- rbind(
  data.frame(org = per_genome$org, kept = per_genome$kept,
             measure = "route-based call", value = per_genome$retention),
  data.frame(org = per_genome$org, kept = per_genome$kept,
             measure = "marker-fraction score", value = per_genome$fullness_ratio))
long$measure <- factor(long$measure, levels = c("marker-fraction score", "route-based call"))

band <- do.call(rbind, lapply(split(long, list(long$kept, long$measure), drop = TRUE),
  function(x) data.frame(kept = x$kept[1], measure = x$measure[1],
                         mid = mean(x$value),
                         lo = quantile(x$value, 0.25), hi = quantile(x$value, 0.75))))
print(band[order(band$measure, -band$kept), ], row.names = FALSE, digits = 3)

panel_a <- ggplot(band, aes(kept, mid, colour = measure, fill = measure)) +
  geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.16, colour = NA) +
  geom_line(linewidth = 0.55) +
  geom_point(size = 1.2) +
  scale_colour_manual(values = c("marker-fraction score" = ORANGE,
                                 "route-based call" = BLUE)) +
  scale_fill_manual(values = c("marker-fraction score" = ORANGE,
                               "route-based call" = BLUE)) +
  scale_x_continuous(labels = function(x) paste0(100 * x, "%"),
                     breaks = sort(unique(band$kept))) +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.25),
                     labels = c("0", ".25", ".5", ".75", "1")) +
  labs(title = "a   The two numbers do not fall the same way",
       subtitle = sprintf("%d genomes, genes dropped at random; band is the interquartile range",
                          length(unique(decay$org))),
       x = "gene content retained", y = "fraction of the full-genome value") +
  theme_gifter()

# ------------------------------------------------------------------- panel B
rule("B. What a lost call still names")
lost <- decay[decay$kept < 1 & decay$lost > 0, ]
lost$share <- lost$one_reaction_short / lost$lost
share_by_level <- aggregate(cbind(one_reaction_short, lost) ~ kept, lost, sum)
share_by_level$share <- share_by_level$one_reaction_short / share_by_level$lost
print(share_by_level, row.names = FALSE, digits = 3)
kv("lost calls across all levels", sum(lost$lost))
kv("of those, exactly one reaction short",
   sprintf("%d (%.1f%%)", sum(lost$one_reaction_short),
           100 * sum(lost$one_reaction_short) / sum(lost$lost)))
kv("median missing reactions among lost calls",
   median(lost$median_missing, na.rm = TRUE))

panel_b <- ggplot(lost, aes(factor(kept), share)) +
  geom_boxplot(width = 0.55, outlier.size = 0.3, outlier.colour = NEUTRAL,
               colour = MUTED, fill = "#e8f0fb", linewidth = 0.3) +
  geom_point(data = share_by_level, aes(factor(kept), share),
             colour = BLUE, size = 1.6) +
  geom_text(data = share_by_level,
            aes(factor(kept), share, label = sprintf("%.0f%%", 100 * share)),
            colour = BLUE, size = 2.1, fontface = "bold", vjust = -1.3) +
  scale_y_continuous(limits = c(0, 1.06), breaks = seq(0, 1, 0.25),
                     labels = c("0", ".25", ".5", ".75", "1")) +
  scale_x_discrete(labels = function(x) paste0(100 * as.numeric(x), "%")) +
  labs(title = "b   A lost call names the step that was lost",
       subtitle = "box across genomes; the point is the pooled share at that level",
       x = "gene content retained", y = "one reaction short") +
  theme_gifter() +
  theme(panel.grid.major.x = element_blank())

# ------------------------------------------------------------------- panel C
rule("C. Assessability moves the denominator, never the call")
assess_path <- file.path(out_dir, "incompleteness-assessability.tsv")
panel_c <- NULL
if (file.exists(assess_path)) {
  assess <- read.delim(assess_path, stringsAsFactors = FALSE)
  supported <- assess[assess$metric == "supported_fraction", ]
  supported$label <- ifelse(supported$policy == "none",
                            "supported / whole frame (naive)",
                            "supported / assessable (policy)")
  sm <- aggregate(value ~ kept + frame + label, supported, mean)

  assessable <- assess[assess$metric == "assessable_fraction" &
                         assess$policy == "completeness", ]
  am <- aggregate(value ~ kept + frame, assessable, mean)
  am$label <- "assessable share of the frame"

  print(reshape(sm, idvar = c("kept", "frame"), timevar = "label", direction = "wide"),
        row.names = FALSE, digits = 3)

  # `reference_frame` in the metrics table already carries the frame's display
  # label rather than its identifier, so the facet strips are ordered here and
  # not renamed. Mapping from the identifier would silently produce NA strips,
  # which is what it did.
  order_by <- c("Nucleotide autonomy", "Amino-acid autonomy", "Cofactor autonomy")
  stopifnot(setequal(unique(sm$frame), order_by))
  sm$frame <- factor(sm$frame, levels = order_by)
  am$frame <- factor(am$frame, levels = order_by)

  # The two lines coincide exactly at and above the threshold, which is the
  # point of the panel and would read as the policy line simply stopping if both
  # were drawn at one width. The policy line is drawn first and wider, so the
  # agreement shows as a halo rather than as an absence.
  panel_c <- ggplot(sm, aes(kept, value, colour = label)) +
    geom_line(data = am, aes(kept, value), colour = NEUTRAL,
              linetype = "22", linewidth = 0.45) +
    geom_line(data = sm[grepl("policy", sm$label), ], linewidth = 1.15) +
    geom_line(data = sm[grepl("naive", sm$label), ], linewidth = 0.5) +
    geom_point(size = 1.1) +
    facet_wrap(~ frame, nrow = 1) +
    scale_colour_manual(values = c("supported / whole frame (naive)" = ORANGE,
                                   "supported / assessable (policy)" = BLUE)) +
    scale_x_continuous(labels = function(x) paste0(100 * x, "%"),
                       breaks = c(0.5, 0.6, 0.7, 0.8, 0.9, 1.0)) +
    scale_y_continuous(limits = c(0, 1.02), breaks = seq(0, 1, 0.25),
                       labels = c("0", ".25", ".5", ".75", "1")) +
    labs(title = "c   Below the quality threshold the policy refuses, rather than answering",
         subtitle = paste("dashed grey: assessable_fraction, the share of the frame the genome could speak to.",
                          "\nThe supported count is identical under both policies in all 5,263 cells that emit one"),
         x = "gene content retained", y = "proportion of the bounded frame") +
    theme_gifter()
} else {
  message("no incompleteness-assessability.tsv: run 02-incompleteness.R for panel c")
}

# -------------------------------------------------------------------- assemble
rule("Assembling")
figure <- if (is.null(panel_c)) {
  (panel_a | panel_b) + plot_layout(widths = c(1, 0.95))
} else {
  ((panel_a | panel_b) + plot_layout(widths = c(1, 0.95))) / panel_c +
    plot_layout(heights = c(1, 0.82))
}
figure <- figure & theme(plot.margin = margin(3, 3, 3, 3))

pdf_path <- file.path(fig_dir, "figure-6-incompleteness.pdf")
png_path <- file.path(fig_dir, "figure-6-incompleteness.png")
ggsave(pdf_path, figure, width = 190, height = 150, units = "mm", device = grDevices::cairo_pdf)
ggsave(png_path, figure, width = 190, height = 150, units = "mm", dpi = 320)
kv("figure-6-incompleteness.pdf", pdf_path)
kv("figure-6-incompleteness.png", png_path)
