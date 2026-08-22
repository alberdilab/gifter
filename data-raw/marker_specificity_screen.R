#!/usr/bin/env Rscript
# Screen KEGG orthology accessions for reaction-level specificity, and use the
# result to audit the curated marker layer and to discover markable candidates.
#
# Invariant 16 says the specificity of a GIFT claim must not exceed the
# specificity of the evidence supporting it. Until now that has been a curator
# judgement made one accession at a time. It is computable for the KO namespace,
# because two public mappings compose:
#
#   KO --(KEGG)--> EC --(Rhea)--> Rhea master reaction --> ChEBI participants
#
# A KO whose ECs reach exactly one Rhea master states one reaction and can carry
# a substrate-specific claim. A KO reaching several masters states only their
# union, whatever its KEGG name suggests. That is the whole screen; everything
# below is bookkeeping around it.
#
# What the screen is not: an authority on whether a marker is *correct*. It
# measures how many distinct reactions a marker's public annotation can license,
# which bounds the claim. A KO reaching one master may still be the wrong
# evidence for a curated component, and a KO reaching several may still be the
# only honest evidence for a deliberately broad GIFT. The flags are questions
# for a curator, not verdicts.
#
# Three products:
#
#   ko-reaction-specificity.tsv   every EC-bearing KO, its reaction fan-out and
#                                 verdict; a curation reference input
#   curated-marker-audit.tsv      every curated KO marker, the reaction it is
#                                 evidence for, whether public mappings
#                                 corroborate that link, its fan-out, and
#                                 whether it is the sole marker of its component
#   route-specificity.tsv         every curated route, how many of its required
#                                 reactions are evidenced by a single-reaction
#                                 marker, and whether any is
#   discovery-candidates.tsv      single-reaction KOs that are not curated and
#                                 whose reaction touches a declared anchor,
#                                 ranked by how specific that anchor is
#
# Usage:
#   Rscript data-raw/marker_specificity_screen.R [--cache=DIR] [--out=DIR]
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

rhea2ec <- read_tsv(fetch("rhea2ec.tsv", file.path(rhea_ftp, "tsv/rhea2ec.tsv")))
rhea_dir <- read_tsv(fetch("rhea-directions.tsv",
                           file.path(rhea_ftp, "tsv/rhea-directions.tsv")))
sprot <- read_tsv(fetch("rhea2uniprot_sprot.tsv",
                        file.path(rhea_ftp, "tsv/rhea2uniprot_sprot.tsv")))
reactions_txt <- readLines(
  fetch("rhea-reactions.txt.gz", file.path(rhea_ftp, "txt/rhea-reactions.txt.gz")),
  warn = FALSE
)
ko_names <- read_tsv(fetch("kegg-ko-list.tsv", file.path(kegg_rest, "list/ko")),
                     header = FALSE, col.names = c("ko", "name"))
ko_ec_link <- read_tsv(fetch("kegg-ko-enzyme.tsv",
                             file.path(kegg_rest, "link/enzyme/ko")),
                       header = FALSE, col.names = c("ko", "ec"))
chebi_names <- read_tsv(fetch("chebiId_name.tsv",
                              file.path(rhea_ftp, "tsv/chebiId_name.tsv")),
                        header = FALSE, col.names = c("chebi", "name"))
chebi_name <- setNames(trimws(chebi_names$name), chebi_names$chebi)

# ---------------------------------------------------------------------------
# KO -> EC
#
# Two KEGG statements of the same fact disagree at the margins: the link file
# omits some assignments that the orthology name carries in brackets, and the
# name carries incomplete ECs (`1.14.-.-`) that the link file drops. Take the
# union and keep only fully specified ECs, because a partial EC cannot resolve
# to a reaction.

ko_ec_link$ko <- sub("^ko:", "", ko_ec_link$ko)
ko_ec_link$ec <- sub("^ec:", "", ko_ec_link$ec)

bracket_ec <- function(name) {
  hit <- regmatches(name, regexpr("\\[EC:[^]]+\\]", name))
  if (!length(hit)) return(character(0))
  strsplit(trimws(sub("^\\[EC:", "", sub("\\]$", "", hit))), " +")[[1]]
}
name_ec <- lapply(ko_names$name, bracket_ec)
ko_ec_name <- data.frame(
  ko = rep(ko_names$ko, lengths(name_ec)),
  ec = unlist(name_ec, use.names = FALSE),
  stringsAsFactors = FALSE
)

ko_ec <- unique(rbind(ko_ec_link, ko_ec_name))
complete_ec <- grepl("^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$", ko_ec$ec)
partial_ec_kos <- unique(ko_ec$ko[!complete_ec])
ko_ec <- ko_ec[complete_ec, ]

# ---------------------------------------------------------------------------
# EC -> Rhea master, and master -> participants and reviewed-protein support

ec2master <- unique(data.frame(
  ec = rhea2ec$ID,
  master = paste0("RHEA:", rhea2ec$MASTER_ID),
  stringsAsFactors = FALSE
))

master_ids <- paste0("RHEA:", rhea_dir$RHEA_ID_MASTER)

entry_line <- grepl("^ENTRY ", reactions_txt)
entry_id <- trimws(sub("^ENTRY", "", reactions_txt[entry_line]))
entry_pos <- which(entry_line)

# An ENTRY block is not guaranteed to carry every field, so a field cannot be
# read off by position alone. Attribute each field line to the entry it falls
# under instead.
field_by_entry <- function(tag) {
  hit <- which(grepl(paste0("^", tag, " "), reactions_txt))
  out <- rep(NA_character_, length(entry_id))
  out[findInterval(hit, entry_pos)] <- trimws(sub(paste0("^", tag), "",
                                                  reactions_txt[hit]))
  setNames(out, entry_id)
}
equation <- field_by_entry("EQUATION")[master_ids]
definition <- field_by_entry("DEFINITION")[master_ids]
names(equation) <- master_ids
names(definition) <- master_ids
equation <- equation[!is.na(equation)]

chebi_of <- function(side) {
  if (is.na(side)) return(character(0))
  unique(unlist(regmatches(side, gregexpr("CHEBI:[0-9]+", side))))
}
split_equation <- function(eq) {
  if (is.na(eq)) return(list(left = character(0), right = character(0)))
  parts <- strsplit(eq, " = ", fixed = TRUE)[[1]]
  list(left = chebi_of(parts[[1]]),
       right = if (length(parts) > 1) chebi_of(parts[[2]]) else character(0))
}
participants <- lapply(equation, split_equation)

sprot_support <- table(paste0("RHEA:", sprot$MASTER_ID))

# How many master reactions a metabolite takes part in, across all of Rhea. This
# is the only honest way to separate a boundary molecule from a hub without
# hand-writing a list of "currency" metabolites, which would itself be a
# biological claim. Ammonium and L-glutamate are declared gifter anchors and
# also appear in thousands of reactions; a candidate that touches one of them as
# a by-product is not a candidate, and the degree says so.
chebi_degree <- table(unlist(lapply(participants, function(p)
  unique(c(p$left, p$right)))))

# ---------------------------------------------------------------------------
# The screen itself

ko_master <- merge(ko_ec, ec2master, by = "ec", all.x = TRUE)
ko_master <- unique(ko_master[!is.na(ko_master$master), c("ko", "master")])
by_ko <- split(ko_master$master, ko_master$ko)
by_ko <- lapply(by_ko, function(x) sort(unique(x)))

ec_by_ko <- split(ko_ec$ec, ko_ec$ko)
ec_by_ko <- lapply(ec_by_ko, function(x) sort(unique(x)))

# A KO reaching several masters is broad in one of two different ways, and the
# distinction decides what a curator can do about it. Several masters under one
# EC is substrate promiscuity recorded by Rhea: the enzyme class is one activity
# and the claim must name that activity, not one of its substrates. Several ECs
# is a KEGG ortholog that groups more than one activity: usually a genuinely
# bifunctional protein, sometimes an ortholog defined too loosely to be evidence
# for either.
verdict_of <- function(n_ec, n_master, partial) {
  if (n_ec == 0L) return(if (partial) "partial_ec_only" else "no_ec")
  if (n_master == 0L) return("ec_without_rhea")
  if (n_master == 1L) return("single_reaction")
  if (n_ec == 1L) return("multi_reaction_one_ec")
  "multi_reaction_multi_ec"
}

screen_kos <- sort(unique(c(names(ec_by_ko), partial_ec_kos)))
screen <- data.frame(
  ko = screen_kos,
  name = ko_names$name[match(screen_kos, ko_names$ko)],
  n_ec = lengths(ec_by_ko)[screen_kos],
  n_rhea_master = lengths(by_ko)[screen_kos],
  stringsAsFactors = FALSE
)
screen$n_ec[is.na(screen$n_ec)] <- 0L
screen$n_rhea_master[is.na(screen$n_rhea_master)] <- 0L
screen$partial_ec <- as.integer(screen$ko %in% partial_ec_kos)
screen$ec <- vapply(ec_by_ko[screen$ko], function(x) paste(x, collapse = ";"),
                    character(1))
screen$rhea_masters <- vapply(by_ko[screen$ko],
                              function(x) paste(x, collapse = ";"), character(1))
screen$ec[is.na(screen$ec)] <- ""
screen$rhea_masters[is.na(screen$rhea_masters)] <- ""
screen$verdict <- mapply(verdict_of, screen$n_ec, screen$n_rhea_master,
                         screen$partial_ec == 1L)
screen$reviewed_proteins <- vapply(by_ko[screen$ko], function(x) {
  if (!length(x)) return(0L)
  sum(as.integer(sprot_support[x]), na.rm = TRUE)
}, integer(1))
rownames(screen) <- NULL

utils::write.table(screen, file.path(out_dir, "ko-reaction-specificity.tsv"),
                   sep = "\t", quote = FALSE, row.names = FALSE, na = "")

say("KO reaction specificity: ", nrow(screen), " EC-bearing orthologs")
print(table(screen$verdict))

# ---------------------------------------------------------------------------
# Audit the curated marker layer

markers <- read_tsv(file.path(source_dir, "markers.tsv"))
component_markers <- read_tsv(file.path(source_dir, "component_markers.tsv"))
enzyme_components <- read_tsv(file.path(source_dir, "enzyme_components.tsv"))
enzyme_systems <- read_tsv(file.path(source_dir, "enzyme_systems.tsv"))
route_reactions <- read_tsv(file.path(source_dir, "route_reactions.tsv"))
gift_routes <- read_tsv(file.path(source_dir, "gift_routes.tsv"))
gifts <- read_tsv(file.path(source_dir, "gifts.tsv"))
anchors <- read_tsv(file.path(source_dir, "anchors.tsv"))

markers_per_component <- table(component_markers$component_id)

audit <- component_markers[component_markers$namespace == "KO",
                           c("component_id", "accession", "confidence")]
audit <- merge(audit, enzyme_components[, c("component_id", "system_id")],
               by = "component_id", all.x = TRUE)
audit <- merge(audit, enzyme_systems[, c("system_id", "reaction_id")],
               by = "system_id", all.x = TRUE)

route_gift <- merge(route_reactions[, c("route_id", "reaction_id")],
                    gift_routes[, c("route_id", "gift_id")], by = "route_id")
gift_of_reaction <- tapply(route_gift$gift_id, route_gift$reaction_id,
                           function(x) paste(sort(unique(x)), collapse = ";"))

audit$gifts <- gift_of_reaction[audit$reaction_id]
audit$markers_on_component <- as.integer(markers_per_component[audit$component_id])
audit$sole_marker <- as.integer(audit$markers_on_component == 1L)
audit$n_rhea_master <- screen$n_rhea_master[match(audit$accession, screen$ko)]
audit$n_rhea_master[is.na(audit$n_rhea_master)] <- 0L
audit$verdict <- screen$verdict[match(audit$accession, screen$ko)]
audit$verdict[is.na(audit$verdict)] <- "not_in_kegg_ec"
audit$rhea_masters <- screen$rhea_masters[match(audit$accession, screen$ko)]
audit$rhea_masters[is.na(audit$rhea_masters)] <- ""

# Does the public mapping corroborate the curated evidence link? Only askable
# where the system's reaction is a Rhea master and the KO reaches any master at
# all.
reaches <- mapply(function(rid, masters) {
  if (!nzchar(masters) || !grepl("^RHEA:", rid)) return(NA_integer_)
  as.integer(rid %in% strsplit(masters, ";", fixed = TRUE)[[1]])
}, audit$reaction_id, audit$rhea_masters, USE.NAMES = FALSE)
audit$mapping_corroborates <- reaches

# For a multi-reaction marker, what actually varies between the reactions it can
# license decides whether the breadth matters. Masters that differ only in an
# electron acceptor or a nicotinamide cofactor describe one activity; masters
# that differ in the substrate describe several, and only the second kind can
# make a substrate-specific claim unsupportable.
varying_participants <- function(masters) {
  if (!nzchar(masters)) return("")
  ids <- strsplit(masters, ";", fixed = TRUE)[[1]]
  sets <- lapply(ids, function(m) {
    part <- participants[[m]]
    if (is.null(part)) character(0) else c(part$left, part$right)
  })
  sets <- sets[lengths(sets) > 0]
  if (length(sets) < 2L) return("")
  shared <- Reduce(intersect, sets)
  varies <- setdiff(unique(unlist(sets)), shared)
  if (!length(varies)) return("")
  label <- chebi_name[varies]
  label[is.na(label)] <- varies[is.na(label)]
  paste(sort(unique(label)), collapse = "; ")
}
audit$varying_participants <- vapply(audit$rhea_masters, varying_participants,
                                     character(1), USE.NAMES = FALSE)

# The flag: this KO is the only evidence its component accepts, and its public
# annotation licenses more than one reaction.
audit$flag_sole_and_broad <- as.integer(
  audit$sole_marker == 1L & audit$n_rhea_master > 1L
)

audit <- audit[order(-audit$flag_sole_and_broad, -audit$n_rhea_master,
                     audit$accession), ]
rownames(audit) <- NULL

utils::write.table(audit, file.path(out_dir, "curated-marker-audit.tsv"),
                   sep = "\t", quote = FALSE, row.names = FALSE, na = "")

say("\nCurated KO marker rows audited: ", nrow(audit))
say("  sole marker of its component and multi-reaction: ",
    sum(audit$flag_sole_and_broad))
say("  evidence link not corroborated by KEGG/Rhea mapping: ",
    sum(audit$mapping_corroborates == 0L, na.rm = TRUE))
say("  KO carries no complete EC: ",
    sum(audit$verdict %in% c("no_ec", "partial_ec_only", "not_in_kegg_ec")))

# ---------------------------------------------------------------------------
# Route-level reading of the same evidence
#
# A broad marker inside a route is not by itself an invariant 16 problem. The
# claim belongs to the route, not to one accession: galactose mutarotase acts on
# several aldoses, but the Leloir route also requires a galactokinase and a
# galactose-1-phosphate uridylyltransferase, and those pin the substrate. What
# would break the invariant is a route in which *no* required reaction is
# evidenced by a marker that states one reaction, because then nothing in the
# evidence identifies the substrate the GIFT is named for.
#
# The screen covers the KO namespace only. A reaction evidenced by CAZy, EC,
# Pfam or TIGRFAM accessions is reported as not screened rather than as
# unanchored, because this pass has nothing to say about it.

marker_verdict <- setNames(screen$verdict, screen$ko)
reaction_of_system <- setNames(enzyme_systems$reaction_id, enzyme_systems$system_id)
system_of_component <- setNames(enzyme_components$system_id,
                                enzyme_components$component_id)

component_markers$reaction_id <-
  reaction_of_system[system_of_component[component_markers$component_id]]
component_markers$marker_verdict <- ifelse(
  component_markers$namespace == "KO",
  marker_verdict[component_markers$accession],
  NA_character_
)

by_reaction <- split(component_markers, component_markers$reaction_id)
reaction_state <- vapply(by_reaction, function(rows) {
  ko <- rows$marker_verdict[rows$namespace == "KO"]
  other <- sum(rows$namespace != "KO")
  if (!length(ko)) return("not_screened")
  if (any(!is.na(ko) & ko == "single_reaction")) return("specific")
  if (other > 0L) return("broad_ko_other_evidence")
  "broad_only"
}, character(1))

required <- route_reactions[route_reactions$required == 1L, ]
required$state <- reaction_state[required$reaction_id]
required$state[is.na(required$state)] <- "not_screened"

route_report <- data.frame(
  route_id = names(table(required$route_id)),
  stringsAsFactors = FALSE
)
count_state <- function(state) {
  tab <- table(required$route_id[required$state == state])
  out <- as.integer(tab[route_report$route_id])
  out[is.na(out)] <- 0L
  out
}
route_report$gift_id <- gift_routes$gift_id[match(route_report$route_id,
                                                  gift_routes$route_id)]
route_report$gift_type <- gifts$gift_type[match(route_report$gift_id, gifts$gift_id)]
route_report$required_reactions <- as.integer(
  table(required$route_id)[route_report$route_id]
)
route_report$specific <- count_state("specific")
route_report$broad_only <- count_state("broad_only")
route_report$not_screened <- count_state("not_screened")
route_report$broad_ko_other_evidence <- count_state("broad_ko_other_evidence")
route_report$flag_no_specific_reaction <- as.integer(
  route_report$specific == 0L & route_report$broad_only > 0L
)
route_report <- route_report[order(-route_report$flag_no_specific_reaction,
                                   route_report$gift_id, route_report$route_id), ]
rownames(route_report) <- NULL

utils::write.table(route_report, file.path(out_dir, "route-specificity.tsv"),
                   sep = "\t", quote = FALSE, row.names = FALSE, na = "")

say("\nRoutes screened: ", nrow(route_report))
say("  with no reaction evidenced by a single-reaction KO: ",
    sum(route_report$flag_no_specific_reaction))
say("  with at least one reaction evidenced only outside the KO namespace: ",
    sum(route_report$not_screened > 0L))
say("  with a broad KO alongside evidence this screen does not cover: ",
    sum(route_report$broad_ko_other_evidence > 0L))

# ---------------------------------------------------------------------------
# Discovery: single-reaction KOs touching a declared anchor

curated_ko <- unique(component_markers$accession[component_markers$namespace == "KO"])
anchor_chebi <- anchors$chebi_id[nzchar(anchors$chebi_id)]
anchor_label <- setNames(anchors$anchor_id, anchors$chebi_id)

candidate <- screen[screen$verdict == "single_reaction" &
                      !(screen$ko %in% curated_ko), ]

touch <- lapply(candidate$rhea_masters, function(master) {
  part <- participants[[master]]
  if (is.null(part)) return(NULL)
  left <- intersect(part$left, anchor_chebi)
  right <- intersect(part$right, anchor_chebi)
  if (!length(left) && !length(right)) return(NULL)
  list(left = left, right = right)
})
keep <- !vapply(touch, is.null, logical(1))
candidate <- candidate[keep, ]
touch <- touch[keep]

candidate$anchors_left <- vapply(touch, function(x)
  paste(anchor_label[x$left], collapse = ";"), character(1))
candidate$anchors_right <- vapply(touch, function(x)
  paste(anchor_label[x$right], collapse = ";"), character(1))
candidate$anchor_degree_min <- vapply(touch, function(x) {
  hit <- as.integer(chebi_degree[c(x$left, x$right)])
  if (!length(hit)) NA_integer_ else min(hit, na.rm = TRUE)
}, integer(1))
candidate$reaction <- definition[candidate$rhea_masters]
candidate <- candidate[order(candidate$anchor_degree_min,
                             -candidate$reviewed_proteins), ]
rownames(candidate) <- NULL

utils::write.table(candidate, file.path(out_dir, "discovery-candidates.tsv"),
                   sep = "\t", quote = FALSE, row.names = FALSE, na = "")

say("\nDiscovery candidates (single-reaction, uncurated, anchor-touching): ",
    nrow(candidate))
say("written to ", out_dir)
