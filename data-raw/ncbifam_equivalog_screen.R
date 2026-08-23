#!/usr/bin/env Rscript
# Screen NCBIfam equivalog profiles for reaction-level specificity, and report
# which curated reactions gain resolution that no KEGG ortholog offers.
#
# This is the NCBIfam counterpart of `marker_specificity_screen.R`, and it
# composes the same public mappings on the other side of the join:
#
#   NCBIfam profile --(hmm_PGAP.tsv)--> EC --(Rhea)--> Rhea master reaction
#   KO              --(KEGG)---------->  EC --(Rhea)--> Rhea master reaction
#
# A profile whose ECs reach exactly one Rhea master states one reaction. The
# screen keeps only the two **equivalog** grades, because those are the grades
# whose members share one function; every other `family_type` groups sequences
# more loosely than a function, which is the over-broad evidence invariant 16
# refuses. The grade is not a nuance to be recorded after the fact -- it is the
# filter, and it runs before anything else.
#
# The question the screen answers is comparative, not absolute. gifter's marker
# layer is overwhelmingly KO, and an NCBIfam profile that resolves a reaction a
# KO already resolves buys sensitivity at best. What buys *specificity* is a
# reaction that a single-reaction equivalog resolves and no single-reaction KO
# does. Those are the rows a curator reads.
#
# What the screen is not: an authority on whether a profile is correct evidence
# for a curated component. EC agreement is a necessary condition, never a
# sufficient one -- two proteins can share an EC and be different subunits of
# one enzyme, which is exactly the case that motivated admitting the namespace.
# The screen finds the reactions worth reading; a curator decides them.
#
# Two products:
#
#   ncbifam-equivalog-specificity.tsv  every equivalog-grade profile carrying a
#                                      complete EC, its Rhea fan-out and verdict
#   ncbifam-curated-reaction-gain.tsv  every curated reaction that a
#                                      single-reaction equivalog resolves,
#                                      with whether a single-reaction KO
#                                      already resolves it, the curated
#                                      components on the reaction, and the
#                                      candidate profiles
#   ncbifam-grade-refusals.tsv         profiles that reach a curated reaction
#                                      and are refused on grade alone -- what
#                                      the equivalog filter costs
#   ncbifam-curated-grades.tsv         every NCBIFAM accession in the database,
#                                      with the grade the pinned release gives
#                                      it
#
# Usage:
#   Rscript data-raw/ncbifam_equivalog_screen.R [--cache=DIR] [--out=DIR]
#           [--source=DIR] [--offline]
#
# Inputs are downloaded once into --cache and reused. Nothing downloaded is
# committed; only the derived tables in --out are.

args <- commandArgs(trailingOnly = TRUE)
opt <- function(name, default) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit)) sub(paste0("^--", name, "="), "", hit[[1]]) else default
}
cache_dir <- opt("cache", "data-raw/reference/.cache")
out_dir <- opt("out", "data-raw/reference")
source_dir <- opt("source", "inst/extdata/database-source")
offline <- "--offline" %in% args

dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

say <- function(...) cat(..., "\n", sep = "")

# The grades whose members share one function. Everything else is refused as a
# marker before it is ever scored, and the constant is named rather than
# inlined so that widening it is a visible edit.
equivalog_grades <- c("equivalog", "equivalog_domain")

# ---------------------------------------------------------------------------
# Inputs

fetch <- function(file, url) {
  path <- file.path(cache_dir, file)
  if (!file.exists(path)) {
    if (offline) stop("missing cached input and --offline was given: ", path)
    say("fetching ", url)
    ok <- utils::download.file(url, path, quiet = TRUE, mode = "wb")
    if (!identical(ok, 0L)) stop("download failed: ", url)
  }
  path
}

read_tsv <- function(path, ...) {
  utils::read.delim(path, quote = "", comment.char = "",
                    stringsAsFactors = FALSE, check.names = FALSE, ...)
}

rhea_ftp <- "https://ftp.expasy.org/databases/rhea"
kegg_rest <- "https://rest.kegg.jp"
ncbifam_ftp <- "https://ftp.ncbi.nlm.nih.gov/hmm/current"

hmm_path <- fetch("hmm_PGAP.tsv", file.path(ncbifam_ftp, "hmm_PGAP.tsv"))
notes_path <- fetch("ncbifam-release-notes.txt",
                    file.path(ncbifam_ftp, "RELEASE_NOTES.txt"))
hmm <- read_tsv(hmm_path)
names(hmm)[[1]] <- sub("^#", "", names(hmm)[[1]])

# Pin the release. `current/` moves, and an accession version suffix is only
# meaningful beside the release it was read from, so the release name is
# reported with every run and belongs in SOURCES.md beside the markers.
notes <- readLines(notes_path, warn = FALSE)
release <- trimws(sub(".*:", "", grep("Release number/name", notes, value = TRUE)[[1]]))
say("NCBIfam release ", release, ": ", nrow(hmm), " profile records")

rhea2ec <- read_tsv(fetch("rhea2ec.tsv", file.path(rhea_ftp, "tsv/rhea2ec.tsv")))
ko_names <- read_tsv(fetch("kegg-ko-list.tsv", file.path(kegg_rest, "list/ko")),
                     header = FALSE, col.names = c("ko", "name"))
ko_ec_link <- read_tsv(fetch("kegg-ko-enzyme.tsv",
                             file.path(kegg_rest, "link/enzyme/ko")),
                       header = FALSE, col.names = c("ko", "ec"))

ec2master <- unique(data.frame(
  ec = rhea2ec$ID,
  master = paste0("RHEA:", rhea2ec$MASTER_ID),
  stringsAsFactors = FALSE
))

complete_ec <- function(ec) grepl("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", ec)

# Split a delimited accession list into a long frame. NCBIfam separates EC
# numbers with commas; KEGG's own files are already long.
explode <- function(id, values, split) {
  parts <- strsplit(ifelse(is.na(values), "", values), split)
  data.frame(
    id = rep(id, lengths(parts)),
    value = trimws(unlist(parts, use.names = FALSE)),
    stringsAsFactors = FALSE
  )
}

masters_of <- function(long) {
  long <- long[complete_ec(long$value), ]
  hit <- merge(long, ec2master, by.x = "value", by.y = "ec")
  by_id <- split(hit$master, hit$id)
  lapply(by_id, function(x) sort(unique(x)))
}

# ---------------------------------------------------------------------------
# The KO baseline
#
# Recomputed here rather than read from `ko-reaction-specificity.tsv`, so that
# the comparison cannot silently be made against a stale screen. The KO->EC
# union is the same one `marker_specificity_screen.R` justifies: the link file
# and the orthology name each omit assignments the other carries.

ko_ec_link$ko <- sub("^ko:", "", ko_ec_link$ko)
ko_ec_link$ec <- sub("^ec:", "", ko_ec_link$ec)

bracket_ec <- function(name) {
  hit <- regmatches(name, regexpr("\\[EC:[^]]+\\]", name))
  if (!length(hit)) return(character(0))
  strsplit(trimws(sub("^\\[EC:", "", sub("\\]$", "", hit))), " +")[[1]]
}
name_ec <- lapply(ko_names$name, bracket_ec)
ko_ec <- unique(rbind(ko_ec_link, data.frame(
  ko = rep(ko_names$ko, lengths(name_ec)),
  ec = unlist(name_ec, use.names = FALSE),
  stringsAsFactors = FALSE
)))

ko_masters <- masters_of(data.frame(id = ko_ec$ko, value = ko_ec$ec,
                                    stringsAsFactors = FALSE))
ko_single <- ko_masters[lengths(ko_masters) == 1L]
masters_with_single_ko <- unique(unlist(ko_single, use.names = FALSE))

say("KO baseline: ", length(masters_with_single_ko),
    " Rhea masters resolved by a single-reaction KO")

# ---------------------------------------------------------------------------
# Equivalog profiles

equivalog <- hmm[hmm$family_type %in% equivalog_grades, ]
say("equivalog-grade profiles: ", nrow(equivalog),
    " of ", nrow(hmm), " (", paste(equivalog_grades, collapse = ", "), ")")

profile_ec <- explode(equivalog$ncbi_accession, equivalog$ec_numbers, ",")
profile_masters <- masters_of(profile_ec)

with_ec <- unique(profile_ec$id[complete_ec(profile_ec$value)])
screen <- equivalog[equivalog$ncbi_accession %in% with_ec, ]
ec_by_profile <- split(profile_ec$value[complete_ec(profile_ec$value)],
                       profile_ec$id[complete_ec(profile_ec$value)])
ec_by_profile <- lapply(ec_by_profile, function(x) sort(unique(x)))

collapse <- function(lst, ids) {
  out <- vapply(lst[ids], function(x) paste(x, collapse = ";"), character(1))
  out[is.na(out)] <- ""
  unname(out)
}

specificity <- data.frame(
  accession = screen$ncbi_accession,
  family_type = screen$family_type,
  gene_symbol = screen$gene_symbol,
  product_name = screen$product_name,
  n_ec = unname(lengths(ec_by_profile)[screen$ncbi_accession]),
  n_rhea_master = unname(lengths(profile_masters)[screen$ncbi_accession]),
  ec = collapse(ec_by_profile, screen$ncbi_accession),
  rhea_masters = collapse(profile_masters, screen$ncbi_accession),
  refseq_hits = screen$n_refseq_protein_hits,
  source = screen$source,
  stringsAsFactors = FALSE
)
specificity$n_rhea_master[is.na(specificity$n_rhea_master)] <- 0L
specificity$verdict <- ifelse(
  specificity$n_rhea_master == 0L, "ec_without_rhea",
  ifelse(specificity$n_rhea_master == 1L, "single_reaction",
         ifelse(specificity$n_ec == 1L, "multi_reaction_one_ec",
                "multi_reaction_multi_ec"))
)
specificity <- specificity[order(specificity$accession), ]
rownames(specificity) <- NULL

utils::write.table(specificity,
                   file.path(out_dir, "ncbifam-equivalog-specificity.tsv"),
                   sep = "\t", quote = FALSE, row.names = FALSE, na = "")

say("\nEquivalogs carrying a complete EC: ", nrow(specificity))
print(table(specificity$verdict))

single_profiles <- profile_masters[lengths(profile_masters) == 1L]
masters_with_single_equivalog <- unique(unlist(single_profiles, use.names = FALSE))
say("Rhea masters resolved by a single-reaction equivalog: ",
    length(masters_with_single_equivalog))
say("  and by no single-reaction KO: ",
    length(setdiff(masters_with_single_equivalog, masters_with_single_ko)))

# ---------------------------------------------------------------------------
# Where the curated database gains resolution
#
# A curated reaction is in scope when a single-reaction equivalog reaches it.
# `ko_already` says whether a single-reaction KO reaches it too, which is what
# separates a sensitivity gain from a specificity gain. Both are reported: the
# additive release curates the second, and the first is the evidence that it is
# additive.

reactions <- read_tsv(file.path(source_dir, "reactions.tsv"))
enzyme_systems <- read_tsv(file.path(source_dir, "enzyme_systems.tsv"))
enzyme_components <- read_tsv(file.path(source_dir, "enzyme_components.tsv"))
component_markers <- read_tsv(file.path(source_dir, "component_markers.tsv"))
route_reactions <- read_tsv(file.path(source_dir, "route_reactions.tsv"))
gift_routes <- read_tsv(file.path(source_dir, "gift_routes.tsv"))

route_gift <- merge(route_reactions[, c("route_id", "reaction_id")],
                    gift_routes[, c("route_id", "gift_id")], by = "route_id")
gift_of_reaction <- tapply(route_gift$gift_id, route_gift$reaction_id,
                           function(x) paste(sort(unique(x)), collapse = ";"))

component_of <- merge(
  enzyme_components[, c("component_id", "system_id", "name")],
  enzyme_systems[, c("system_id", "reaction_id")], by = "system_id"
)
markers_of_component <- tapply(
  paste(component_markers$namespace, component_markers$accession, sep = ":"),
  component_markers$component_id,
  function(x) paste(sort(unique(x)), collapse = ";")
)

# Curated reactions are keyed by Rhea master where one exists; a reaction with
# no master cannot be reached by an EC join at all and is out of scope here.
curated_master <- reactions$rhea_master[!is.na(reactions$rhea_master) &
                                          nzchar(reactions$rhea_master)]
curated_master <- sort(intersect(curated_master, masters_with_single_equivalog))

profile_of_master <- split(
  rep(names(single_profiles), lengths(single_profiles)),
  unlist(single_profiles, use.names = FALSE)
)

gain <- do.call(rbind, lapply(curated_master, function(master) {
  reaction_id <- reactions$reaction_id[
    !is.na(reactions$rhea_master) & reactions$rhea_master == master
  ]
  components <- component_of[component_of$reaction_id %in% reaction_id, , drop = FALSE]
  profiles <- profile_of_master[[master]]
  do.call(rbind, lapply(profiles, function(accession) {
    row <- hmm[hmm$ncbi_accession == accession, ][1, ]
    data.frame(
      rhea_master = master,
      reaction_id = paste(sort(unique(reaction_id)), collapse = ";"),
      reaction_name = paste(unique(reactions$name[reactions$reaction_id %in%
                                                    reaction_id]), collapse = ";"),
      gifts = paste(unique(stats::na.omit(gift_of_reaction[reaction_id])),
                    collapse = ";"),
      ko_already = as.integer(master %in% masters_with_single_ko),
      accession = accession,
      family_type = row$family_type,
      gene_symbol = row$gene_symbol,
      product_name = row$product_name,
      ec = row$ec_numbers,
      refseq_hits = row$n_refseq_protein_hits,
      components = paste(sort(unique(components$component_id)), collapse = ";"),
      component_markers = paste(unique(stats::na.omit(
        markers_of_component[sort(unique(components$component_id))]
      )), collapse = " | "),
      stringsAsFactors = FALSE
    )
  }))
}))
gain <- gain[order(gain$ko_already, gain$reaction_id, gain$accession), ]
rownames(gain) <- NULL

utils::write.table(gain, file.path(out_dir, "ncbifam-curated-reaction-gain.tsv"),
                   sep = "\t", quote = FALSE, row.names = FALSE, na = "")

resolved <- unique(gain$reaction_id[gain$ko_already == 0L])
say("\nCurated reactions reached by a single-reaction equivalog: ",
    length(unique(gain$reaction_id)))
say("  of which no single-reaction KO resolves: ", length(resolved))
say("\nTarget set for the additive release:")
for (reaction_id in sort(resolved)) {
  rows <- gain[gain$reaction_id == reaction_id & gain$ko_already == 0L, ]
  say("  ", reaction_id, "  ", rows$reaction_name[[1]], "  [",
      paste(rows$accession, collapse = ", "), "]")
}

# ---------------------------------------------------------------------------
# What the grade filter costs
#
# The two equivalog grades are the whole admission rule, so it is worth knowing
# what they exclude. These are profiles whose ECs reach a curated reaction and
# which are refused for one reason only: their family groups sequences more
# loosely than a function. A `subfamily` or `domain` profile on a reaction
# gifter curates is precisely the over-broad evidence invariant 16 refuses, and
# the point of writing them down is that the refusal stays re-readable -- and
# testable, because no accession in this table may ever appear as a marker.

curated_all <- reactions$rhea_master[!is.na(reactions$rhea_master) &
                                       nzchar(reactions$rhea_master)]
refused_grades <- setdiff(unique(hmm$family_type), equivalog_grades)
refused <- hmm[hmm$family_type %in% refused_grades, ]
refused_ec <- explode(refused$ncbi_accession, refused$ec_numbers, ",")
refused_masters <- masters_of(refused_ec)
refused_masters <- refused_masters[lengths(refused_masters) > 0]
reaches_curated <- vapply(refused_masters,
                          function(x) any(x %in% curated_all), logical(1))
refused_hit <- names(refused_masters)[reaches_curated]

refusal <- hmm[match(refused_hit, hmm$ncbi_accession),
               c("ncbi_accession", "family_type", "gene_symbol", "product_name",
                 "ec_numbers", "n_refseq_protein_hits", "source")]
names(refusal)[[1]] <- "accession"
refusal$rhea_masters <- collapse(refused_masters, refusal$accession)
refusal$curated_masters <- vapply(refused_masters[refusal$accession], function(x)
  paste(intersect(x, curated_all), collapse = ";"), character(1))
refusal$refused_because <- "family_type is not equivalog or equivalog_domain"
refusal <- refusal[order(refusal$family_type, refusal$accession), ]
rownames(refusal) <- NULL

utils::write.table(refusal, file.path(out_dir, "ncbifam-grade-refusals.tsv"),
                   sep = "\t", quote = FALSE, row.names = FALSE, na = "")

say("\nProfiles refused on grade alone that reach a curated reaction: ",
    nrow(refusal))
print(table(refusal$family_type))

# ---------------------------------------------------------------------------
# The grade of every accession gifter actually admits
#
# The set of rows comes from gifter; the `family_type` column comes from
# NCBIfam. That asymmetry is the point: it is what lets a test assert that
# every admitted accession is equivalog-graded in the pinned release without
# the database being asked to vouch for itself. An accession that is absent
# from the release at all appears here with an empty grade, which is the
# symptom of an accession copied from an annotator rather than curated against
# a pinned release.

admitted <- unique(component_markers[component_markers$namespace == "NCBIFAM",
                                     c("component_id", "accession")])
grades <- data.frame(
  accession = sort(unique(admitted$accession)),
  stringsAsFactors = FALSE
)
if (nrow(grades)) {
  hit <- match(grades$accession, hmm$ncbi_accession)
  grades$family_type <- hmm$family_type[hit]
  grades$gene_symbol <- hmm$gene_symbol[hit]
  grades$product_name <- hmm$product_name[hit]
  grades$ec_numbers <- hmm$ec_numbers[hit]
  grades$refseq_hits <- hmm$n_refseq_protein_hits[hit]
  grades$source <- hmm$source[hit]
  grades$in_release <- as.integer(!is.na(hit))
  grades$admitted_grade <- as.integer(grades$family_type %in% equivalog_grades)
  grades$components <- vapply(grades$accession, function(a)
    paste(sort(admitted$component_id[admitted$accession == a]), collapse = ";"),
    character(1), USE.NAMES = FALSE)
} else {
  grades <- data.frame(accession = character(0), family_type = character(0),
                       gene_symbol = character(0), product_name = character(0),
                       ec_numbers = character(0), refseq_hits = character(0),
                       source = character(0), in_release = integer(0),
                       admitted_grade = integer(0), components = character(0),
                       release = character(0), stringsAsFactors = FALSE)
}
if (nrow(grades)) grades$release <- release
rownames(grades) <- NULL

utils::write.table(grades, file.path(out_dir, "ncbifam-curated-grades.tsv"),
                   sep = "\t", quote = FALSE, row.names = FALSE, na = "")

say("\nNCBIFAM accessions curated as markers: ", nrow(grades))
if (nrow(grades)) {
  print(table(grades$family_type, useNA = "ifany"))
  bad <- grades$accession[grades$admitted_grade == 0L]
  if (length(bad)) {
    say("REFUSED GRADE PRESENT IN THE DATABASE: ", paste(bad, collapse = ", "))
  }
}

say("\nwritten to ", out_dir)
