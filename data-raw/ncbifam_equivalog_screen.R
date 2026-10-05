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
# does. Those are the rows we read.
#
# What the screen is not: an authority on whether a profile is correct evidence
# for a curated component. EC agreement is a necessary condition, never a
# sufficient one -- two proteins can share an EC and be different subunits of
# one enzyme, which is exactly the case that motivated admitting the namespace.
# The screen finds the reactions worth reading; we decide them.
#
# The EC join has a blind spot, and it is most of the namespace. Two thirds of
# the equivalog profiles carry no EC number at all, so nothing above can see
# them -- `TIGR04546.1` *ahbC* is one of them, which means the EC join would
# never have found half the route the namespace was admitted for. Discovery
# therefore runs on a second join, by name rather than by chemistry: the anchor
# vocabulary is turned into search terms and matched against `product_name` and
# `gene_symbol`. That join is weaker than the KO screen's and the product says
# so in a column -- a string inside a product name is not a reaction, and a
# match is a question, never a verdict.
#
# Five products:
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
#   ncbifam-discovery-candidates.tsv   equivalog profiles the EC join cannot
#                                      see, whose product name or gene symbol
#                                      names a declared anchor
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

# Read only by the discovery section below, to demote hub metabolites the same
# way `marker_specificity_screen.R` does. Both screens must rank an anchor by
# the same measurement or their candidate lists cannot be compared.
rhea_dir <- read_tsv(fetch("rhea-directions.tsv",
                           file.path(rhea_ftp, "tsv/rhea-directions.tsv")))
reactions_txt <- readLines(gzfile(fetch("rhea-reactions.txt.gz",
                                        file.path(rhea_ftp, "ctfiles/rhea-reactions.txt.gz"))),
                           warn = FALSE)

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

# ---------------------------------------------------------------------------
# Discovery: the profiles the EC join cannot see
#
# 8,711 of the 13,888 equivalog profiles carry no EC number, several hundred
# more carry only an incomplete one, and several hundred carry a complete EC
# that reaches no Rhea master. Together they are the majority of the namespace
# and everything above is blind to them. `TIGR04546.1` *ahbC* sits in the first
# group: the EC join would have found two steps of the Ahb route and missed the
# third, which is the whole reason this section exists.
#
# The second join is by name. Each declared anchor contributes search terms --
# its ChEBI name, that name with its stereochemical and charge decorations
# stripped, and its `molecule` token -- and those are matched against
# `product_name` and `gene_symbol`. Three properties of the match are
# deliberate:
#
#   * It is left-permissive and right-anchored. Chemical names compose by
#     prefixing, so `siroheme` must match `12,18-didecarboxysiroheme`, which a
#     word-boundary match would miss. The right side is anchored so that a term
#     may not match the middle of a longer word.
#   * A shorter term subsumed by a longer one on the same profile is dropped.
#     Otherwise every homocysteine methyltransferase would also read as a
#     cysteine candidate, and `HOMOSERINE` and `SERINE` would answer together
#     for every product naming either.
#   * A term matched inside a phrase that names a protein residue or a protein
#     substrate is not a match on the free metabolite. `histidine kinase` is
#     the largest single false positive in the raw match and it is not about
#     histidine at all. Those rows are kept in the output and marked, not
#     silently dropped, because a suppressed match nobody can re-read is
#     indistinguishable from one that was never made.
#
# The join is weaker than the KO screen's, which reaches an anchor through a
# reaction's ChEBI participants and therefore states chemistry. A string inside
# a product name states nothing. This product is a reading queue: every row
# needs its `comment` and `product_name` read before it is anything else, and
# in the release that admitted this namespace roughly one profile in fourteen
# that passed the grade filter was refused on biology after being read.

anchors <- read_tsv(file.path(source_dir, "anchors.tsv"))
gift_anchors <- read_tsv(file.path(source_dir, "gift_anchors.tsv"))

# Anchor terms shorter than this are acronyms -- GTP, NAD, AIR, PLP -- and a
# substring search on three characters finds noise rather than chemistry. The
# anchors that lose every term are named in the run log so the blind spot of
# the blind-spot screen is visible too.
min_term_nchar <- 5L

# Phrases in which an anchor's name denotes a protein residue, a protein-
# modifying activity or a protein substrate rather than the free metabolite.
# Named rather than inlined for the same reason `equivalog_grades` is: widening
# or narrowing it is a biological decision and should be a visible edit.
protein_context_phrases <- c(
  "histidine kinase", "histidine phosphotransferase", "histidine phosphatase",
  "serine/threonine", "serine protease", "serine endopeptidase",
  "serine peptidase", "serine hydrolase", "serine carboxypeptidase",
  "cysteine protease", "cysteine peptidase", "cysteine endopeptidase",
  "twin-arginine", "twin arginine",
  "alanine amidase", "alanine ligase", "alanyl",
  "glutamate ligase", "aspartate ligase", "lysine ligase",
  "serine acetyltransferase family", "trna", "ribosomal"
)

normalise <- function(x) {
  x <- tolower(ifelse(is.na(x), "", x))
  x <- gsub("\\([0-9]*[+-]\\)", "", x)
  trimws(gsub("[[:space:]]+", " ", x))
}

# Strip the leading stereochemical, anomeric and configurational decorations
# that a ChEBI name carries and a product name usually does not.
strip_decoration <- function(x) {
  repeat {
    y <- sub("^(\\([a-z0-9,'-]+\\)|[ld]|alpha|beta|meso|aldehydo)-", "", x)
    if (identical(y, x)) break
    x <- y
  }
  x
}

anchor_terms <- do.call(rbind, lapply(seq_len(nrow(anchors)), function(i) {
  term <- unique(c(normalise(anchors$name[i]),
                   strip_decoration(normalise(anchors$name[i])),
                   normalise(gsub("_", "-", anchors$molecule[i])),
                   normalise(gsub("_", " ", anchors$molecule[i]))))
  term <- term[nzchar(term) & nchar(term) >= min_term_nchar]
  if (!length(term)) return(NULL)
  data.frame(anchor_id = anchors$anchor_id[i], term = term,
             stringsAsFactors = FALSE)
}))
anchor_terms <- unique(anchor_terms)
unsearchable <- setdiff(anchors$anchor_id, anchor_terms$anchor_id)

say("\nAnchor search terms: ", nrow(anchor_terms), " over ",
    length(unique(anchor_terms$anchor_id)), " of ", nrow(anchors), " anchors")
if (length(unsearchable)) {
  say("  anchors with no term of ", min_term_nchar,
      " characters or more, and therefore unsearchable by name: ",
      paste(sort(unsearchable), collapse = ", "))
}

# The blind spot itself, classified so a reader can tell why each profile is
# invisible: no EC at all, only an incomplete EC, or a complete EC that reaches
# no Rhea master.
ec_raw <- ifelse(is.na(equivalog$ec_numbers), "", equivalog$ec_numbers)
has_any_ec <- nzchar(trimws(ec_raw))
with_complete_ec <- unique(profile_ec$id[complete_ec(profile_ec$value)])
with_master <- names(profile_masters)[lengths(profile_masters) > 0]

screen_class <- ifelse(
  !has_any_ec, "no_ec",
  ifelse(!(equivalog$ncbi_accession %in% with_complete_ec), "partial_ec_only",
         ifelse(!(equivalog$ncbi_accession %in% with_master),
                "ec_without_rhea", "reaches_rhea"))
)
names(screen_class) <- equivalog$ncbi_accession
blind <- equivalog[screen_class != "reaches_rhea", ]

say("\nEquivalog profiles invisible to the EC join: ", nrow(blind), " of ",
    nrow(equivalog))
print(table(screen_class[screen_class != "reaches_rhea"]))

haystack <- normalise(paste(blind$product_name, blind$gene_symbol))
escape_re <- function(s) gsub("([.|()^{}+$*?\\[\\]\\\\])", "\\\\\\1", s)

match_rows <- lapply(seq_len(nrow(anchor_terms)), function(k) {
  which(grepl(paste0(escape_re(anchor_terms$term[k]), "([^a-z0-9]|$)"),
              haystack, perl = TRUE))
})
n_hit <- lengths(match_rows)
hit <- data.frame(
  row = unlist(match_rows, use.names = FALSE),
  anchor_id = rep(anchor_terms$anchor_id, n_hit),
  term = rep(anchor_terms$term, n_hit),
  stringsAsFactors = FALSE
)
say("\nRaw name matches: ", nrow(hit), " over ",
    length(unique(hit$row)), " profiles")

# Subsumption: a term that is a proper suffix of another term matched on the
# same profile is describing the longer molecule, not its own.
keep <- vapply(seq_len(nrow(hit)), function(i) {
  others <- hit$term[hit$row == hit$row[i]]
  others <- others[others != hit$term[i]]
  !any(nchar(others) > nchar(hit$term[i]) &
         endsWith(others, hit$term[i]))
}, logical(1))
say("  dropped as subsumed by a longer anchor name: ", sum(!keep))
hit <- hit[keep, ]

hit$protein_context <- vapply(seq_len(nrow(hit)), function(i) {
  any(vapply(protein_context_phrases,
             function(p) grepl(p, haystack[hit$row[i]], fixed = TRUE),
             logical(1)))
}, logical(1))
say("  marked as protein context rather than free metabolite: ",
    sum(hit$protein_context))

# Anchor hub degree, from Rhea, exactly as `marker_specificity_screen.R`
# computes it: the number of master reactions the anchor's ChEBI takes part in
# across all of Rhea. Ammonium and L-glutamate are declared anchors and also
# appear in thousands of reactions; a candidate that only names one of those is
# not much of a candidate, and the degree says so without anyone hand-writing a
# list of currency metabolites.
master_ids <- paste0("RHEA:", rhea_dir$RHEA_ID_MASTER)
entry_line <- grepl("^ENTRY ", reactions_txt)
entry_id <- trimws(sub("^ENTRY", "", reactions_txt[entry_line]))
entry_pos <- which(entry_line)
equation_line <- which(grepl("^EQUATION ", reactions_txt))
equation <- rep(NA_character_, length(entry_id))
equation[findInterval(equation_line, entry_pos)] <-
  trimws(sub("^EQUATION", "", reactions_txt[equation_line]))
names(equation) <- entry_id
equation <- equation[intersect(master_ids, names(equation))]
chebi_degree <- table(unlist(lapply(equation, function(eq)
  unique(unlist(regmatches(eq, gregexpr("CHEBI:[0-9]+", eq))))
)))

anchor_degree <- setNames(as.integer(chebi_degree[anchors$chebi_id]),
                          anchors$anchor_id)

gift_of_anchor <- tapply(gift_anchors$gift_id, gift_anchors$anchor_id,
                         function(x) paste(sort(unique(x)), collapse = ";"))
curated_accession <- unique(component_markers$accession[
  component_markers$namespace == "NCBIFAM"
])

discovery <- data.frame(
  accession = blind$ncbi_accession[hit$row],
  family_type = blind$family_type[hit$row],
  gene_symbol = blind$gene_symbol[hit$row],
  product_name = blind$product_name[hit$row],
  ec_numbers = blind$ec_numbers[hit$row],
  screen_class = unname(screen_class[blind$ncbi_accession[hit$row]]),
  refseq_hits = blind$n_refseq_protein_hits[hit$row],
  anchor_id = hit$anchor_id,
  matched_term = hit$term,
  anchor_rhea_degree = unname(anchor_degree[hit$anchor_id]),
  anchor_gifts = unname(gift_of_anchor[hit$anchor_id]),
  already_curated = as.integer(blind$ncbi_accession[hit$row] %in%
                                 curated_accession),
  stringsAsFactors = FALSE
)
discovery$anchor_gifts[is.na(discovery$anchor_gifts)] <- ""
discovery$excluded_because <- ifelse(
  discovery$already_curated == 1L, "already a curated marker",
  ifelse(hit$protein_context, "protein context, not the free metabolite", "")
)
# A comment is the single most load-bearing field in this table and it is free
# text, so newlines and tabs are flattened rather than allowed to break the TSV.
discovery$comment <- trimws(gsub("[[:space:]]+", " ",
                                 blind$comment[hit$row]))
discovery <- discovery[order(discovery$excluded_because != "",
                             discovery$anchor_rhea_degree,
                             -as.numeric(discovery$refseq_hits),
                             discovery$accession), ]
rownames(discovery) <- NULL

utils::write.table(discovery,
                   file.path(out_dir, "ncbifam-discovery-candidates.tsv"),
                   sep = "\t", quote = FALSE, row.names = FALSE, na = "")

survivors <- discovery[discovery$excluded_because == "", ]
say("\nCandidates surviving the anchor join: ",
    length(unique(survivors$accession)), " profiles over ",
    nrow(survivors), " profile-anchor rows")
say("  touching an anchor of Rhea degree 50 or less: ",
    length(unique(survivors$accession[
      !is.na(survivors$anchor_rhea_degree) &
        survivors$anchor_rhea_degree <= 50
    ])))
say("  touching an anchor of Rhea degree 20 or less: ",
    length(unique(survivors$accession[
      !is.na(survivors$anchor_rhea_degree) &
        survivors$anchor_rhea_degree <= 20
    ])))

say("\nwritten to ", out_dir)
