#!/usr/bin/env Rscript
# Figure 8: agreement with observed phenotypes.
#
# The figure has one job the prose cannot do as well: show at a glance that the
# statistic is asymmetric and that most of the catalogue was not testable. A
# reader who is handed a single agreement rate has to take the caveats on trust.
# A reader who can see the permitted cell drawn separately from the failure
# cell, and the 61% of the catalogue with no reference drawn beside the 10%
# that has one, can check the caveats against the picture.
#
#   A  recall per target, catabolic half, with the test-set size and the number
#      of genera behind every point. Faceted by the layer the observation tests,
#      because an EC-resolved enzyme assay and a substrate-use record are
#      evidence about different things.
#   B  recall per nutrient, anabolic half. The classes where the premise
#      "grows without it, therefore makes it" does not hold are drawn in grey
#      and excluded from the headline rather than hidden.
#   C  the disagreements, classified. The permitted cell -- encoded but not
#      observed -- is grey because it is not an error under invariant 15, and
#      the failures are split by whether gifter can name the missing step.
#   D  the reference against itself. Where BacDive records the same capability
#      twice through independent assays, how often do the two agree. That bounds
#      every recall in the figure.
#   E  what could be tested at all: 15 GIFTs individually, 44 only as a
#      bounded-frame aggregate, 94 with no phenotype reference of any kind.
#   F  the annotation route, if 05-annotation-route.R has been run.
#
# Everything is read from the committed tables in output/ and from the compiled
# database. The one quantity computed here is panel D, because no earlier script
# writes it: 00-slice-urea.R measured it for one capability and printed it.
#
# Deliberately absent: any pooled rate across GIFTs, any confidence interval on
# a test set whose genera are as unevenly represented as these, and any
# accuracy, precision, F1, MCC or AUC. The reasoning is section 2 of
# inst/doc/proposal-phenotype-validation.md.
#
# Usage:
#   Rscript manuscript/analysis/06-figure-phenotype.R

source("manuscript/analysis/_common.R")
suppressWarnings(suppressMessages({
  library(ggplot2)
  library(patchwork)
}))

out_dir <- "manuscript/analysis/output"
fig_dir <- "manuscript/figures"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# One blue, one orange, and a neutral. The pair clears every colour-vision
# separation check at all-pairs; the neutral is deliberately achromatic because
# the class it carries is the one that is *not* an error, and it is always
# direct-labelled rather than left to colour alone.
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

con <- gifter_db()
agreement_table <- read.delim(file.path(out_dir, "phenotype-agreement.tsv"),
                              stringsAsFactors = FALSE)
disagreements   <- read.delim(file.path(out_dir, "phenotype-disagreements.tsv"),
                              stringsAsFactors = FALSE)
auxotrophy      <- read.delim(file.path(out_dir, "auxotrophy-agreement.tsv"),
                              stringsAsFactors = FALSE)

# ------------------------------------------------------------------- panel A
rule("A. Recall per target, catabolic half")

primary <- agreement_table[agreement_table$recall_usable & agreement_table$n >= 20, ]
# The kind of test is part of the claim: an API-panel acidification and a
# growth-on-substrate assay are different observations of one GIFT, and the
# committed table keeps them apart. Drawing them under one label would merge two
# claims silently, so the first recorded kind qualifies the row.
primary$kind <- vapply(strsplit(ifelse(is.na(primary$kinds), "", primary$kinds), ";"),
                       function(x) if (length(x)) x[[1]] else "", character(1))
primary$label <- ifelse(primary$layer == "reaction" | !nzchar(primary$kind), primary$term,
                        sprintf("%s: %s", primary$term, primary$kind))
primary$layer_label <- ifelse(primary$layer == "reaction",
                              "reaction layer: EC-resolved enzyme assay",
                              "GIFT layer: substrate use or product formation")
primary <- primary[order(primary$layer, primary$recall), ]
primary$label <- factor(primary$label, levels = unique(primary$label))
kv("targets drawn", nrow(primary))

panel_a <- ggplot(primary, aes(recall, label)) +
  geom_segment(aes(x = 0, xend = recall, yend = label), colour = "#dcdbd5", linewidth = 0.85) +
  geom_point(colour = BLUE, size = 1.7) +
  geom_text(aes(x = 1.05, label = sprintf("n = %d, %d genera", n, genera)),
            hjust = 0, size = 1.8, colour = MUTED) +
  facet_wrap(~ layer_label, ncol = 1, scales = "free_y") +
  scale_x_continuous(limits = c(0, 1.66), breaks = seq(0, 1, 0.25),
                     labels = c("0", ".25", ".50", ".75", "1")) +
  labs(title = "a   Recall against observed phenotype",
       subtitle = "one row per curated mapping; nothing pooled",
       x = "recall", y = NULL) +
  theme_gifter() +
  theme(panel.grid.major.y = element_blank())

# ------------------------------------------------------------------- panel B
rule("B. Recall per nutrient, anabolic half")

# The premise -- grew without it, therefore makes it -- holds only where the
# nutrient is biomass-essential. Menaquinone is not universal, and an organism
# handed ammonium has no reason to fix nitrogen. Those rows are drawn because
# they were measured, and greyed because they are not evidence about gifter.
auxotrophy$premise <- ifelse(auxotrophy$substrate_class %in% c("amino_acid", "nucleotide"),
                             "biomass-essential: the premise holds",
                             "not biomass-essential: premise fails")
auxotrophy <- auxotrophy[order(auxotrophy$recall), ]
auxotrophy$nutrient <- gsub("_", "-", auxotrophy$nutrient)
auxotrophy$nutrient <- factor(auxotrophy$nutrient, levels = auxotrophy$nutrient)
essential <- auxotrophy[auxotrophy$premise == "biomass-essential: the premise holds", ]
kv("nutrient-level recall, essential classes",
   sprintf("%.3f over %s tests", sum(essential$supported) / sum(essential$n),
           format(sum(essential$n), big.mark = " ")))

panel_b <- ggplot(auxotrophy, aes(recall, nutrient, colour = premise)) +
  geom_segment(aes(x = 0, xend = recall, yend = nutrient), colour = "#dcdbd5", linewidth = 0.7) +
  geom_point(size = 1.5) +
  scale_colour_manual(values = setNames(c(ORANGE, NEUTRAL), unique(auxotrophy$premise[order(auxotrophy$premise)]))) +
  scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.25),
                     labels = c("0", ".25", ".50", ".75", "1")) +
  guides(colour = guide_legend(nrow = 2)) +
  labs(title = "b   Anabolic half: defined media",
       subtitle = sprintf("%d tests on the essential classes; one point per nutrient",
                          sum(essential$n)),
       x = "proportion of tests with a supported call", y = NULL) +
  theme_gifter() +
  theme(panel.grid.major.y = element_blank(),
        axis.text.y = element_text(size = rel(0.78)))

# ------------------------------------------------------------------- panel C
rule("C. The disagreements, classified")

# gifter's own trace does the classification. A genome with no evidence at all
# may be an annotation gap or a real absence; a genome that carries markers and
# still falls short names the requirement that failed.
# The committed table names targets by identifier; the figure names them the way
# the observation does, so a reader can match a bar to a row of panel a.
readable <- unique(primary[, c("target", "term")])
readable <- readable[!duplicated(readable$target), ]
name_of <- setNames(readable$term, readable$target)

failures <- disagreements[disagreements$target %in% primary$target, ]
failure_counts <- as.data.frame(table(target = failures$target, class = failures$class),
                                stringsAsFactors = FALSE)
failure_counts$class <- ifelse(failure_counts$class == "no evidence",
                               "failure: no evidence at all",
                               "failure: incomplete route, step named")
permitted <- data.frame(target = primary$target,
                        class = "permitted: encoded, not observed",
                        Freq = primary$encoded_not_observed, stringsAsFactors = FALSE)
cells <- rbind(failure_counts, permitted)
cells <- cells[cells$Freq > 0, ]
# The stack reads left to right in the order the legend does: the failures
# first, because they are the result, and the permitted class trailing.
cells$class <- factor(cells$class, levels = c("failure: no evidence at all",
                                              "failure: incomplete route, step named",
                                              "permitted: encoded, not observed"))
cells$label <- sprintf("%s (%s)", name_of[cells$target],
                       ifelse(cells$target %in% primary$target[primary$layer == "reaction"],
                              "reaction", "GIFT"))
order_by <- tapply(cells$Freq, cells$label, sum)
cells$label <- factor(cells$label, levels = names(sort(order_by)))

panel_c <- ggplot(cells, aes(Freq, label, fill = class)) +
  geom_col(width = 0.68, colour = SURFACE, linewidth = 0.35,
           position = position_stack(reverse = TRUE)) +
  scale_fill_manual(values = c("permitted: encoded, not observed" = NEUTRAL,
                               "failure: incomplete route, step named" = BLUE,
                               "failure: no evidence at all" = ORANGE)) +
  guides(fill = guide_legend(nrow = 3)) +
  labs(title = "c   Every disagreement, classified",
       subtitle = "grey is permitted under invariant 15, never an error",
       x = "genomes", y = NULL) +
  theme_gifter() +
  theme(panel.grid.major.y = element_blank(),
        axis.text.y = element_text(size = rel(0.8)))

# ------------------------------------------------------------------- panel D
rule("D. The reference against itself")

# Where BacDive records one capability twice through independent assays, the two
# records bound how well any caller could possibly score. This is the only
# quantity in the figure that no earlier script writes out.
consistency_path <- file.path(out_dir, "phenotype-reference-consistency.tsv")
if (!file.exists(consistency_path)) {
  crosswalk <- read_phenotype_crosswalk(con)
  observed <- bacdive_reduce(seq_len(180000), list(
    assemblies = bd_assemblies, utilisation = bd_utilisation,
    production = bd_production, enzymes = bd_enzymes))
  as_logical_activity <- function(x) ifelse(x == "+", TRUE, ifelse(x == "-", FALSE, NA))

  # Two denominators, and the smaller one is the one that bounds panel A. The
  # whole reference says how self-consistent BacDive is; the strains that also
  # reach a genome are the ones a recall was actually measured on, and a
  # genome-backed strain is better characterised than an average one.
  genome_set <- read.delim(file.path(out_dir, "kegg-genome-set.tsv"), stringsAsFactors = FALSE)
  genome_set$assembly_base <- sub("[.].*", "", genome_set$assembly)
  asm <- observed$assemblies
  asm <- asm[!is.na(asm$assembly), ]
  asm$assembly_base <- sub("[.].*", "", asm$assembly)
  asm <- asm[order(asm$bacdive_id, -asm$score), ]
  asm <- asm[!duplicated(asm$bacdive_id), ]
  genome_backed <- unique(merge(asm, genome_set[, c("org", "assembly_base")],
                                by = "assembly_base")$bacdive_id)

  # A reaction-layer row is an observation about the GIFT that reaction serves,
  # which is what makes it comparable with a substrate or product record.
  via_reaction <- dbGetQuery(con, "
    select distinct r.reaction_id, g.gift_id from reaction r
    join route_reaction rr on rr.reaction_pk = r.reaction_pk
    join gift_route gr on gr.route_pk = rr.route_pk
    join gift g on g.gift_pk = gr.gift_pk")
  crosswalk$gift <- ifelse(crosswalk$layer == "reaction",
                           via_reaction$gift_id[match(crosswalk$target_id, via_reaction$reaction_id)],
                           crosswalk$target_id)

  strain_records <- function(i) {
    r <- crosswalk[i, ]
    if (r$source_field == "metabolite utilization") {
      x <- observed$utilisation
      x$value <- as_logical_activity(x$activity)
      x <- x[!is.na(x$value) & paste0("CHEBI:", x$chebi) == r$source_id & x$kind %in% r$kinds[[1]], ]
    } else if (r$source_field == "metabolite production") {
      x <- observed$production
      x$value <- x$produced %in% c("yes", "+")
      x <- x[paste0("CHEBI:", x$chebi) == r$source_id, ]
    } else if (r$source_field == "enzymes") {
      x <- observed$enzymes
      x$value <- as_logical_activity(x$activity)
      x <- x[!is.na(x$value) & !is.na(x$ec) & paste0("EC:", x$ec) == r$source_id, ]
    } else return(NULL)
    if (!nrow(x)) return(NULL)
    # A strain whose own records contradict each other within one assay is
    # dropped, not resolved. Keeping whichever row came first would manufacture
    # consistency out of an ambiguity the reference itself records.
    x <- unique(x[, c("bacdive_id", "value")])
    x[!x$bacdive_id %in% x$bacdive_id[duplicated(x$bacdive_id)], ]
  }

  usable <- which(crosswalk$source == "BACDIVE" & crosswalk$recall_usable &
                    crosswalk$source_field %in% c("metabolite utilization",
                                                  "metabolite production", "enzymes"))
  rows <- list()
  for (gift in unique(crosswalk$gift[usable])) {
    idx <- usable[crosswalk$gift[usable] == gift]
    fields <- unique(crosswalk$source_field[idx])
    if (length(fields) < 2) next
    for (a in seq_along(idx)) for (b in seq_along(idx)) {
      if (b <= a) next
      if (crosswalk$source_field[idx[a]] == crosswalk$source_field[idx[b]]) next
      x <- strain_records(idx[a]); y <- strain_records(idx[b])
      if (is.null(x) || is.null(y)) next
      m <- merge(x, y, by = "bacdive_id", suffixes = c("_1", "_2"))
      if (!nrow(m)) next
      g <- m[m$bacdive_id %in% genome_backed, ]
      rows[[length(rows) + 1]] <- data.frame(
        gift_id = gift,
        observation_1 = crosswalk$source_label[idx[a]],
        field_1 = crosswalk$source_field[idx[a]],
        observation_2 = crosswalk$source_label[idx[b]],
        field_2 = crosswalk$source_field[idx[b]],
        strains = nrow(m),
        both_positive = sum(m$value_1 & m$value_2),
        both_negative = sum(!m$value_1 & !m$value_2),
        disagree = sum(m$value_1 != m$value_2),
        strains_with_genome = nrow(g),
        agree_with_genome = sum(g$value_1 == g$value_2),
        only_1_positive = sum(g$value_1 & !g$value_2),
        only_2_positive = sum(!g$value_1 & g$value_2), stringsAsFactors = FALSE)
    }
  }
  consistency <- do.call(rbind, rows)
  consistency$agree <- consistency$both_positive + consistency$both_negative
  consistency <- consistency[order(-consistency$strains), ]
  write.table(consistency, consistency_path, sep = "\t", quote = FALSE,
              row.names = FALSE, na = "")
}
consistency <- read.delim(consistency_path, stringsAsFactors = FALSE)
consistency$agree <- consistency$both_positive + consistency$both_negative
print(consistency[, c("gift_id", "observation_1", "observation_2", "strains", "agree",
                      "strains_with_genome", "agree_with_genome")])
kv("whole reference, both observations present",
   sprintf("%d of %d agree", sum(consistency$agree), sum(consistency$strains)))
kv("restricted to strains carrying a reference genome",
   sprintf("%d of %d agree", sum(consistency$agree_with_genome),
           sum(consistency$strains_with_genome)))

# The panel draws the genome-backed denominator, because those are the strains
# a recall was actually measured on.
consistency$pair <- sprintf("%s\nvs %s", consistency$observation_1, consistency$observation_2)
consistency$rate <- consistency$agree_with_genome / consistency$strains_with_genome
consistency <- consistency[order(consistency$strains_with_genome), ]
consistency$pair <- factor(consistency$pair, levels = consistency$pair)

panel_d <- ggplot(consistency, aes(rate, pair)) +
  geom_segment(aes(x = 0, xend = rate, yend = pair), colour = "#dcdbd5", linewidth = 0.9) +
  geom_point(colour = ORANGE, size = 1.9) +
  geom_text(aes(x = 1.03, label = sprintf("%d of %d strains", agree_with_genome,
                                          strains_with_genome)),
            hjust = 0, size = 1.95, colour = MUTED) +
  scale_x_continuous(limits = c(0, 1.55), breaks = seq(0, 1, 0.25),
                     labels = c("0", ".25", ".50", ".75", "1")) +
  labs(title = "d   The reference against itself",
       subtitle = "two independent assays of one capability",
       x = "strains on which the two observations agree", y = NULL) +
  theme_gifter() +
  theme(panel.grid.major.y = element_blank(),
        axis.text.y = element_text(size = rel(0.8), lineheight = 0.95))

# ------------------------------------------------------------------- panel E
rule("E. Coverage of the catalogue")

gifts <- dbGetQuery(con, "select gift_id, gift_type from gift")
profile <- dbGetQuery(con, "select gift_id, substrate_class from gift_profile")
gifts$substrate_class <- profile$substrate_class[match(gifts$gift_id, profile$gift_id)]
via_reaction <- dbGetQuery(con, "
  select distinct r.reaction_id, g.gift_id from reaction r
  join route_reaction rr on rr.reaction_pk = r.reaction_pk
  join gift_route gr on gr.route_pk = rr.route_pk
  join gift g on g.gift_pk = gr.gift_pk")
tested <- unique(c(primary$target[primary$layer == "gift"],
                   via_reaction$gift_id[via_reaction$reaction_id %in%
                                          primary$target[primary$layer == "reaction"]]))
frame_only <- setdiff(dbGetQuery(con, "select gift_id from gift_profile
                                       where auxotrophy_indicator = 1 and mode = 'anabolic'")$gift_id,
                      tested)
gifts$reach <- ifelse(gifts$gift_id %in% tested, "individually testable",
               ifelse(gifts$gift_id %in% frame_only, "only as a bounded-frame aggregate",
                      "no phenotype reference at all"))
kv("individually testable", sum(gifts$reach == "individually testable"))
kv("bounded-frame aggregate only", sum(gifts$reach == "only as a bounded-frame aggregate"))
kv("no reference of any kind", sum(gifts$reach == "no phenotype reference at all"))

# Naming what has no reference is the point of the panel. A reader who is told
# which 62% was untestable can weigh the 9% that was.
gifts$group <- ifelse(gifts$gift_type != "metabolic",
                      paste0(gifts$gift_type, " GIFTs"),
                      ifelse(is.na(gifts$substrate_class), "other", gifts$substrate_class))
gifts$group <- gsub("_", " ", gifts$group)
coverage <- as.data.frame(table(group = gifts$group, reach = gifts$reach), stringsAsFactors = FALSE)
coverage <- coverage[coverage$Freq > 0, ]
coverage$reach <- factor(coverage$reach,
                         levels = c("individually testable",
                                    "only as a bounded-frame aggregate",
                                    "no phenotype reference at all"))
totals <- tapply(coverage$Freq, coverage$group, sum)
coverage$group <- factor(coverage$group, levels = names(sort(totals)))

panel_e <- ggplot(coverage, aes(Freq, group, fill = reach)) +
  geom_col(width = 0.7, colour = SURFACE, linewidth = 0.35,
           position = position_stack(reverse = TRUE)) +
  scale_fill_manual(values = c("individually testable" = BLUE,
                               "only as a bounded-frame aggregate" = "#9dc0ee",
                               "no phenotype reference at all" = "#e3e2dc")) +
  guides(fill = guide_legend(nrow = 3)) +
  labs(title = sprintf("e   Testable at all: %d of %d GIFTs",
                       sum(gifts$reach == "individually testable"), nrow(gifts)),
       subtitle = "the untestable majority is named, not a remainder",
       x = "GIFTs", y = NULL) +
  theme_gifter() +
  theme(panel.grid.major.y = element_blank(),
        axis.text.y = element_text(size = rel(0.82)))

# ------------------------------------------------------------------- panel F
rule("F. The annotation route")

route_path <- file.path(out_dir, "annotation-route-calls.tsv")
panel_f <- NULL
if (file.exists(route_path)) {
  route <- read.delim(route_path, stringsAsFactors = FALSE)
  # Levels reversed so the panel reads top to bottom in the order the routes
  # are argued: the upper bound first, then what an annotator costs, then what
  # the namespaces it can reach give back.
  label <- c("KEGG's own KO assignment", "KofamScan, KO only",
             "the whole pinned pipeline")
  totals <- data.frame(
    route = factor(label, levels = rev(label)),
    calls = c(sum(route$kegg_ko), sum(route$annot_ko), sum(route$annot_full)))
  totals$share <- totals$calls / totals$calls[[1]]
  print(totals)
  panel_f <- ggplot(totals, aes(calls, route)) +
    geom_col(width = 0.6, fill = c(NEUTRAL, ORANGE, BLUE)) +
    geom_text(aes(label = sprintf("%s (%.0f%%)", format(calls, big.mark = ","),
                                  100 * share)),
              hjust = 1.06, size = 2.1, colour = SURFACE, fontface = "bold") +
    scale_x_continuous(expand = expansion(mult = c(0, 0.04))) +
    labs(title = "f   The same genomes, three annotations",
         subtitle = sprintf("complete calls over %d genomes", max(route$genomes)),
         x = "complete calls", y = NULL) +
    theme_gifter() +
    theme(panel.grid.major.y = element_blank())
}

# -------------------------------------------------------------------- assemble
rule("Assembling")

left  <- panel_a / panel_c + plot_layout(heights = c(1.15, 1))
right <- panel_b / panel_d / panel_e + plot_layout(heights = c(1.6, 0.6, 0.9))
if (!is.null(panel_f))
  right <- panel_b / panel_d / panel_e / panel_f +
    plot_layout(heights = c(1.75, 0.52, 0.95, 0.42))
figure <- (left | right) +
  plot_layout(widths = c(1, 0.92)) &
  theme(plot.margin = margin(3, 3, 3, 3))

pdf_path <- file.path(fig_dir, "figure-8-phenotype.pdf")
png_path <- file.path(fig_dir, "figure-8-phenotype.png")
ggsave(pdf_path, figure, width = 190, height = 245, units = "mm", device = grDevices::cairo_pdf)
ggsave(png_path, figure, width = 190, height = 245, units = "mm", dpi = 320)
kv("figure-8-phenotype.pdf", pdf_path)
kv("figure-8-phenotype.png", png_path)
