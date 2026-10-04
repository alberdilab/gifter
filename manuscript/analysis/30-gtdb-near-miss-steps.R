# GTDB overview follow-up: is it always the same step that is missing?
#
# 29-gtdb-near-misses-and-gift-signal.R counts unsupported GIFTs whose closest
# implementation lacks exactly one requirement. This script asks which one. For
# every implementation it measures how concentrated the missing requirement is
# over its near-miss genomes, and reads that against the requirements that are
# present, because the same pattern has three different explanations:
#
#   - the present requirements are shared with other GIFTs, so their presence
#     says nothing about this one and the missing, GIFT-specific requirement is
#     a correct refusal;
#   - the present requirements are specific to this GIFT and one requirement is
#     missing in the same place: a candidate for an alternative enzyme or
#     component the catalogue has not curated, or for a marker that fails in
#     that lineage;
#   - the missing requirement varies between genomes: incomplete or eroded
#     machinery, or scattered annotation gaps, with no single target.
#
# "Shared" is read from the curated database, never from a list written here: a
# requirement is shared when another GIFT requires the same reaction or function,
# or when one of its markers is accepted for a requirement of another GIFT. A
# marker that is biologically broad but accepted only once is not detected by
# that rule. Nothing here changes a call, and a candidate is a prompt for
# curation, not a finding that the capability is encoded.
#
# Run from the repository root after 29-gtdb-near-misses-and-gift-signal.R:
#   Rscript manuscript/analysis/30-gtdb-near-miss-steps.R

suppressWarnings(suppressPackageStartupMessages({
  library(ggplot2)
  library(patchwork)
}))

root <- "manuscript/analysis"
source_dir <- "inst/extdata/database-source"
output_dir <- Sys.getenv("GTDB_PHYLOGENY_OUTPUT_DIR", file.path(root, "output"))
figure_dir <- Sys.getenv("GTDB_PHYLOGENY_FIGURE_DIR", "manuscript/figures")

NEAR_MISS_SCORE <- 0.5
MIN_NEAR_MISS_GENOMES <- 20L
SAME_STEP_SHARE <- 0.8
MIN_TAXON_GENOMES <- 5L
BAR_CANDIDATES <- 25L
BAR_PHYLA <- 7L

read_tsv <- function(path) {
  utils::read.delim(path, check.names = FALSE, stringsAsFactors = FALSE, quote = "")
}
read_source <- function(table) read_tsv(file.path(source_dir, paste0(table, ".tsv")))
write_tsv <- function(x, path) {
  utils::write.table(
    x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = ""
  )
}
read_xz_tsv <- function(path) {
  connection <- xzfile(path, open = "rt")
  on.exit(close(connection), add = TRUE)
  utils::read.delim(connection, check.names = FALSE, stringsAsFactors = FALSE)
}
wrap_text <- function(x, width) paste(strwrap(x, width = width), collapse = "\n")
pretty_name <- function(x) gsub("_", " ", x)
strip_rank <- function(x) sub("^[a-z]__", "", x)

calls_path <- file.path(output_dir, "gtdb-phylogeny-calls.tsv.xz")
genomes_path <- file.path(output_dir, "gtdb-near-miss-genomes.tsv")
missing <- c(calls_path, genomes_path)
missing <- missing[!file.exists(missing)]
if (length(missing)) {
  stop("Run 29-gtdb-near-misses-and-gift-signal.R first. Missing:\n  ",
       paste(missing, collapse = "\n  "), call. = FALSE)
}

# ------------------------------------------- requirements of each implementation

# One row per implementation and required reaction or function, in every type.
implementation_tables <- list(
  metabolic = list("gift_routes", "route_id", "route_reactions", "reaction_id"),
  structural = list("gift_architectures", "architecture_id", "architecture_functions", "function_id"),
  regulatory = list("gift_circuits", "circuit_id", "circuit_functions", "function_id"),
  defense = list("gift_mechanisms", "mechanism_id", "mechanism_functions", "function_id")
)
requirements <- do.call(rbind, lapply(names(implementation_tables), function(type) {
  spec <- implementation_tables[[type]]
  owners <- read_source(spec[[1L]])
  members <- read_source(spec[[3L]])
  members <- members[members$required == 1L, ]
  data.frame(
    gift_type = type,
    gift_id = owners$gift_id[match(members[[spec[[2L]]]], owners[[spec[[2L]]]])],
    implementation = members[[spec[[2L]]]],
    requirement = members[[spec[[4L]]]],
    stringsAsFactors = FALSE
  )
}))
if (anyNA(requirements$gift_id)) {
  stop("A required reaction or function belongs to no implementation", call. = FALSE)
}

# Markers accepted for each requirement, through its systems and components.
marker_tables <- list(
  metabolic = list("enzyme_systems", "reaction_id", "enzyme_components", "component_markers"),
  structural = list("structural_systems", "function_id", "structural_components", "structural_component_markers"),
  regulatory = list("regulatory_systems", "function_id", "regulatory_components", "regulatory_component_markers"),
  defense = list("defense_systems", "function_id", "defense_components", "defense_component_markers")
)
requirement_markers <- do.call(rbind, lapply(names(marker_tables), function(type) {
  spec <- marker_tables[[type]]
  systems <- read_source(spec[[1L]])
  components <- read_source(spec[[3L]])
  markers <- read_source(spec[[4L]])
  components$requirement <- systems[[spec[[2L]]]][match(components$system_id, systems$system_id)]
  data.frame(
    requirement = components$requirement[match(markers$component_id, components$component_id)],
    system_id = components$system_id[match(markers$component_id, components$component_id)],
    marker = paste(markers$namespace, markers$accession, sep = ":"),
    stringsAsFactors = FALSE
  )
}))
requirement_markers <- unique(requirement_markers[!is.na(requirement_markers$requirement), ])

gifts_of_requirement <- tapply(requirements$gift_id, requirements$requirement, unique)
marker_gifts <- merge(
  requirement_markers[c("requirement", "marker")],
  unique(requirements[c("requirement", "gift_id")]), by = "requirement"
)
gifts_of_marker <- tapply(marker_gifts$gift_id, marker_gifts$marker, unique)
markers_of_requirement <- tapply(requirement_markers$marker, requirement_markers$requirement, unique)
systems_of_requirement <- tapply(
  requirement_markers$system_id, requirement_markers$requirement,
  function(x) length(unique(x))
)

# A requirement is specific to a GIFT when no other GIFT requires it and none of
# its markers is accepted for a requirement of another GIFT.
is_specific <- function(requirement, gift) {
  if (length(setdiff(gifts_of_requirement[[requirement]], gift))) return(FALSE)
  markers <- markers_of_requirement[[requirement]]
  if (is.null(markers)) return(TRUE)
  !any(vapply(markers, function(marker) {
    length(setdiff(gifts_of_marker[[marker]], gift)) > 0L
  }, logical(1)))
}
requirements$specific <- mapply(is_specific, requirements$requirement, requirements$gift_id)

# ------------------------------------------------------------------ near misses

genomes <- read_tsv(genomes_path)
rownames(genomes) <- genomes$genome_id
calls <- read_xz_tsv(calls_path)
calls$complete <- as.logical(calls$complete)
near <- calls[
  !calls$complete & calls$minimum_missing_requirements == 1L &
    calls$completeness_score >= NEAR_MISS_SCORE, ]
near$phylum <- genomes[near$genome_id, "phylum"]
known <- paste(near$best_implementation, near$missing_requirements) %in%
  paste(requirements$implementation, requirements$requirement)
if (!all(known)) {
  stop("A near miss names a requirement the database source does not define; ",
       "the calls were made against another database version", call. = FALSE)
}

phylum_sizes <- table(genomes$phylum)
tested_phyla <- names(phylum_sizes)[phylum_sizes >= MIN_TAXON_GENOMES]

implementations <- do.call(rbind, lapply(
  split(near, near$best_implementation),
  function(rows) {
    implementation <- rows$best_implementation[[1L]]
    required <- requirements[requirements$implementation == implementation, ]
    counts <- sort(table(rows$missing_requirements), decreasing = TRUE)
    share <- counts / sum(counts)
    data.frame(
      gift_id = rows$gift_id[[1L]], gift_type = rows$gift_type[[1L]],
      mode = rows$mode[[1L]], implementation = implementation,
      requirements = nrow(required),
      near_miss_genomes = nrow(rows),
      genomes_supporting_gift = sum(calls$complete[calls$gift_id == rows$gift_id[[1L]]]),
      distinct_missing_requirements = length(counts),
      most_missing_requirement = names(counts)[[1L]],
      share_missing_that_requirement = as.numeric(share[[1L]]),
      effective_missing_requirements = exp(-sum(share * log(share))),
      stringsAsFactors = FALSE
    )
  }
))
rownames(implementations) <- NULL

gaps <- do.call(rbind, lapply(
  split(near, paste(near$best_implementation, near$missing_requirements, sep = "\r")),
  function(rows) {
    implementation <- rows$best_implementation[[1L]]
    requirement <- rows$missing_requirements[[1L]]
    gift <- rows$gift_id[[1L]]
    required <- requirements[requirements$implementation == implementation, ]
    present <- required[required$requirement != requirement, ]
    by_phylum <- table(rows$phylum)
    tested <- by_phylum[names(by_phylum) %in% tested_phyla]
    phylum_share <- tested / as.numeric(phylum_sizes[names(tested)])
    top <- if (length(phylum_share)) names(phylum_share)[which.max(phylum_share)] else NA_character_
    summary <- implementations[implementations$implementation == implementation, ]
    data.frame(
      gift_id = gift, gift_type = rows$gift_type[[1L]], mode = rows$mode[[1L]],
      implementation = implementation, missing_requirement = requirement,
      genomes_one_step_short = nrow(rows),
      share_of_implementation_near_misses = nrow(rows) / summary$near_miss_genomes,
      requirements = nrow(required),
      present_requirements = nrow(present),
      present_requirements_specific_to_gift = sum(present$specific),
      missing_requirement_specific_to_gift =
        required$specific[required$requirement == requirement],
      missing_requirement_systems =
        if (is.na(systems_of_requirement[requirement])) 0L else
          as.integer(systems_of_requirement[[requirement]]),
      missing_requirement_markers = paste(
        sort(unique(markers_of_requirement[[requirement]])), collapse = ";"
      ),
      genomes_supporting_gift = summary$genomes_supporting_gift,
      phyla_affected = length(by_phylum),
      largest_phylum_share_of_these_genomes = max(by_phylum) / nrow(rows),
      most_affected_phylum = top,
      share_of_that_phylum = if (is.na(top)) NA_real_ else as.numeric(phylum_share[[top]]),
      stringsAsFactors = FALSE
    )
  }
))
gaps$reading <- ifelse(
  gaps$present_requirements_specific_to_gift == 0L,
  "present steps all shared with other GIFTs",
  ifelse(gaps$share_of_implementation_near_misses >= SAME_STEP_SHARE,
         "same step missing, GIFT-specific steps present",
         "missing step varies, GIFT-specific steps present")
)
gaps <- gaps[order(
  match(gaps$reading, c(
    "same step missing, GIFT-specific steps present",
    "missing step varies, GIFT-specific steps present",
    "present steps all shared with other GIFTs"
  )), -gaps$genomes_one_step_short
), ]
rownames(gaps) <- NULL

reading_summary <- do.call(rbind, lapply(split(gaps, gaps$reading), function(rows) {
  data.frame(
    reading = rows$reading[[1L]], gaps = nrow(rows),
    near_miss_calls = sum(rows$genomes_one_step_short),
    share_of_near_miss_calls = sum(rows$genomes_one_step_short) / nrow(near),
    gifts = length(unique(rows$gift_id)), stringsAsFactors = FALSE
  )
}))
rownames(reading_summary) <- NULL

# ----------------------------------------------------------------------- tables

signif_columns <- function(table, columns, digits = 4) {
  for (column in columns) table[[column]] <- signif(table[[column]], digits)
  table
}
write_tsv(
  signif_columns(gaps, c(
    "share_of_implementation_near_misses", "largest_phylum_share_of_these_genomes",
    "share_of_that_phylum"
  )),
  file.path(output_dir, "gtdb-near-miss-steps.tsv")
)
write_tsv(
  signif_columns(
    implementations[order(-implementations$near_miss_genomes), ],
    c("share_missing_that_requirement", "effective_missing_requirements")
  ),
  file.path(output_dir, "gtdb-near-miss-implementations.tsv")
)
write_tsv(
  signif_columns(reading_summary, "share_of_near_miss_calls"),
  file.path(output_dir, "gtdb-near-miss-readings.tsv")
)

# ------------------------------------------------------------------- Figure S18

reading_colours <- c(
  "same step missing, GIFT-specific steps present" = "#c8553d",
  "missing step varies, GIFT-specific steps present" = "#e0a458",
  "present steps all shared with other GIFTs" = "#8a8984"
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

frequent <- gaps[gaps$genomes_one_step_short >= MIN_NEAR_MISS_GENOMES, ]
frequent$reading <- factor(frequent$reading, levels = names(reading_colours))
frequent$specific_share <-
  frequent$present_requirements_specific_to_gift / frequent$present_requirements
frequent$label <- paste0(pretty_name(frequent$gift_id), " – ", frequent$missing_requirement)
candidates <- frequent[
  frequent$reading == "same step missing, GIFT-specific steps present", ]

panel_scatter <- ggplot(frequent, aes(
  x = 100 * share_of_implementation_near_misses, y = 100 * specific_share
)) +
  geom_vline(xintercept = 100 * SAME_STEP_SHARE, colour = "#252522",
             linewidth = 0.25, linetype = 2) +
  geom_point(aes(size = genomes_one_step_short, colour = reading), alpha = 0.75,
             position = position_jitter(width = 1, height = 2, seed = 1L)) +
  scale_colour_manual(
    values = reading_colours, drop = FALSE, name = NULL,
    labels = c(
      "same step missing, specific steps present",
      "missing step varies, specific steps present",
      "present steps all shared with other GIFTs"
    )
  ) +
  scale_size_area(max_size = 4, name = "genomes one step short",
                  breaks = c(50, 200, 600)) +
  labs(
    title = "a  Is it the same step, and are the present steps specific?",
    x = "near misses of the implementation that lack this step (%)",
    y = "present steps specific to the GIFT (%)"
  ) +
  base_theme +
  guides(colour = guide_legend(nrow = 1, override.aes = list(size = 2)))

bar_gaps <- utils::head(candidates[order(-candidates$genomes_one_step_short), ], BAR_CANDIDATES)
bar_rows <- near[
  paste(near$best_implementation, near$missing_requirements) %in%
    paste(bar_gaps$implementation, bar_gaps$missing_requirement), ]
bar_rows$label <- bar_gaps$label[match(
  paste(bar_rows$best_implementation, bar_rows$missing_requirements),
  paste(bar_gaps$implementation, bar_gaps$missing_requirement)
)]
main_phyla <- names(sort(table(bar_rows$phylum), decreasing = TRUE))[seq_len(BAR_PHYLA)]
bar_rows$phylum_group <- ifelse(
  bar_rows$phylum %in% main_phyla, strip_rank(bar_rows$phylum), "other phyla"
)
bar_rows$phylum_group <- factor(
  bar_rows$phylum_group, levels = c(strip_rank(main_phyla), "other phyla")
)
bar_rows$label <- factor(bar_rows$label, levels = rev(bar_gaps$label))
panel_bars <- ggplot(bar_rows, aes(y = label, fill = phylum_group)) +
  geom_bar(width = 0.75) +
  scale_fill_manual(
    values = c(grDevices::hcl.colors(BAR_PHYLA, "Dark 3"), "#d5d4cf"), name = NULL
  ) +
  labs(
    title = "b  Most frequent candidates, by phylum",
    x = "genomes one step short", y = NULL
  ) +
  base_theme +
  theme(axis.text.y = element_text(size = 5.2), panel.grid.major.y = element_blank()) +
  guides(fill = guide_legend(nrow = 1))

figure_s18 <- panel_scatter + panel_bars +
  plot_layout(widths = c(1, 1.05), guides = "collect") +
  plot_annotation(
    title = "Which step is missing when a GIFT is one step short",
    subtitle = wrap_text(paste0(
      "Each point is one implementation and missing requirement with at least ",
      MIN_NEAR_MISS_GENOMES, " near-miss genomes. A present step is specific when no other GIFT requires it or accepts one of its markers. ",
      "Right of the dashed line, at least ", 100 * SAME_STEP_SHARE,
      "% of the implementation's near misses lack the same step."
    ), 150),
    caption = wrap_text(paste0(
      "Candidates (b) are the red points of a: the same step missing while GIFT-specific steps are present. A candidate is a prompt for curation: an uncurated alternative, a marker that fails in a lineage, or a capability that is not encoded. ",
      "A near miss is never counted as support."
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
  file.path(figure_dir, "figure-s18-gtdb-near-miss-steps.pdf"), figure_s18,
  width = 190, height = 140, units = "mm", device = grDevices::cairo_pdf, bg = "white"
)
ggsave(
  file.path(figure_dir, "figure-s18-gtdb-near-miss-steps.png"), figure_s18,
  width = 190, height = 140, units = "mm", dpi = 320, bg = "white"
)

cat("Wrote GTDB near-miss step tables and Figure S18.\n")
