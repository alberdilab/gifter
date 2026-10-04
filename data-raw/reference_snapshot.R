# Pin the external records gifter's source tables depend on.
#
# The source validator can prove the tables agree with each other. It cannot
# prove that an accession exists, that a Rhea identifier is a master, or that an
# anchor takes part in its route. This script downloads Rhea, ChEBI and KEGG,
# extracts the records the source tables reference, and writes them to
# inst/extdata/reference-snapshot, where `validate_gifter_sources()` compares
# the tables against them. Nothing in that directory is edited by hand.
#
# With --sync it also writes the values that are imported or derived rather
# than curated: `reactions.equation`, `anchors.chebi_name`, and the `basis` of
# every marker assignment.
#
# Rhea and ChEBI are CC BY 4.0 and are extracted in the detail the checks need.
# KEGG redistribution is under review (inst/doc/licensing-review.md), so the
# snapshot records only which KEGG accessions were confirmed current. KEGG's
# own links, which the basis derivation reads, stay in the ignored cache.
#
# NCBIfam and CAZy markers are checked against the pinned NCBIfam release and
# the dbCAN tables already committed under data-raw/reference. The snapshot
# records which of their accessions are current and each NCBIfam profile's
# grade; the EC numbers the basis derivation reads go to
# data-raw/reference/marker-links.tsv, beside the tables they come from.
#
# Usage:
#   Rscript data-raw/reference_snapshot.R [--cache=DIR] [--offline] [--sync]

suppressWarnings(suppressMessages(devtools::load_all(quiet = TRUE)))

args <- commandArgs(trailingOnly = TRUE)
opt <- function(name, default) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit) == 0) default else sub(paste0("^--", name, "="), "", hit[[1]])
}
cache_dir  <- opt("cache", "data-raw/reference/.cache/external")
source_dir <- opt("sources", "inst/extdata/database-source")
out_dir    <- opt("out", "inst/extdata/reference-snapshot")
offline    <- "--offline" %in% args
sync       <- "--sync" %in% args
dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

RHEA <- "https://ftp.expasy.org/databases/rhea/"
# The NCBIfam release is named, not `current`: accessions carry a version, and
# a profile's grade and EC numbers are properties of one release.
NCBIFAM_RELEASE <- "20.0"
DBCAN_RELEASE <- "db_v5-2-9_5-5-2026"
links_path <- opt("links", "data-raw/reference/marker-links.tsv")
SIDES_QUERY <- paste(
  "PREFIX rh: <http://rdf.rhea-db.org/>",
  "SELECT ?acc ?side ?chebi ?under WHERE {",
  "?r rh:accession ?acc ; rh:status rh:Approved ; rh:side ?side .",
  "?side rh:contains ?p . ?p rh:compound ?c .",
  "OPTIONAL { ?c rh:chebi ?chebi } OPTIONAL { ?c rh:underlyingChebi ?under } }"
)
downloads <- list(
  list("Rhea", "rhea-release.properties", paste0(RHEA, "rhea-release.properties"), "CC BY 4.0"),
  list("Rhea", "rhea-directions.tsv", paste0(RHEA, "tsv/rhea-directions.tsv"), "CC BY 4.0"),
  list("Rhea", "rhea2ec.tsv", paste0(RHEA, "tsv/rhea2ec.tsv"), "CC BY 4.0"),
  list("Rhea", "rhea2kegg_reaction.tsv", paste0(RHEA, "tsv/rhea2kegg_reaction.tsv"), "CC BY 4.0"),
  list("Rhea", "chebi_pH7_3_mapping.tsv", paste0(RHEA, "tsv/chebi_pH7_3_mapping.tsv"), "CC BY 4.0"),
  list("Rhea", "rhea-equations.tsv",
       "https://www.rhea-db.org/rhea/?query=&columns=rhea-id,equation&format=tsv&limit=100000",
       "CC BY 4.0"),
  list("Rhea", "rhea-sides.tsv",
       paste0("https://sparql.rhea-db.org/sparql?query=",
              utils::URLencode(SIDES_QUERY, reserved = TRUE)),
       "CC BY 4.0"),
  list("ChEBI", "chebi-compounds.tsv.gz",
       "https://ftp.ebi.ac.uk/pub/databases/chebi/flat_files/compounds.tsv.gz", "CC BY 4.0"),
  list("ChEBI", "chebi-archive.html",
       "https://ftp.ebi.ac.uk/pub/databases/chebi/archive/", "CC BY 4.0"),
  list("KEGG", "kegg-ko.tsv", "https://rest.kegg.jp/list/ko", "KEGG copyright; not redistributed"),
  list("KEGG", "kegg-reaction.tsv", "https://rest.kegg.jp/list/reaction", "KEGG copyright; not redistributed"),
  list("KEGG", "kegg-module.tsv", "https://rest.kegg.jp/list/module", "KEGG copyright; not redistributed"),
  list("KEGG", "kegg-pathway.tsv", "https://rest.kegg.jp/list/pathway", "KEGG copyright; not redistributed"),
  list("KEGG", "kegg-ko-reaction.tsv", "https://rest.kegg.jp/link/reaction/ko", "KEGG copyright; not redistributed"),
  list("KEGG", "kegg-ko-enzyme.tsv", "https://rest.kegg.jp/link/enzyme/ko", "KEGG copyright; not redistributed"),
  list("KEGG", "kegg-ko-module.tsv", "https://rest.kegg.jp/link/module/ko", "KEGG copyright; not redistributed"),
  list("NCBIfam", "hmm_PGAP.tsv", paste0("https://ftp.ncbi.nlm.nih.gov/hmm/", NCBIFAM_RELEASE, "/hmm_PGAP.tsv"),
       "NCBI data policy; under review")
)

fetch <- function(file, url) {
  path <- file.path(cache_dir, file)
  if (!file.exists(path)) {
    if (offline) stop("missing from cache and --offline given: ", file)
    utils::download.file(url, path, quiet = TRUE, mode = "wb",
                         headers = c(Accept = "text/tab-separated-values, */*"))
    Sys.sleep(1)
  }
  path
}
paths <- stats::setNames(
  vapply(downloads, function(d) fetch(d[[2]], d[[3]]), character(1)),
  vapply(downloads, function(d) d[[2]], character(1))
)
read_tsv <- function(path, header = TRUE) {
  utils::read.delim(path, header = header, sep = "\t", quote = "", comment.char = "",
                    colClasses = "character", check.names = FALSE, stringsAsFactors = FALSE)
}
write_tsv <- function(data, path) {
  utils::write.table(data, path, sep = "\t", quote = FALSE, row.names = FALSE, na = "")
}
strip <- function(x, prefix) sub(paste0("^", prefix, ":"), "", x)

tables <- gifter:::.read_gifter_sources(source_dir)

# ------------------------------------------------------------------------ Rhea
directions <- read_tsv(paths[["rhea-directions.tsv"]])
member_of <- c(
  stats::setNames(directions$RHEA_ID_MASTER, directions$RHEA_ID_MASTER),
  stats::setNames(directions$RHEA_ID_MASTER, directions$RHEA_ID_LR),
  stats::setNames(directions$RHEA_ID_MASTER, directions$RHEA_ID_RL),
  stats::setNames(directions$RHEA_ID_MASTER, directions$RHEA_ID_BI)
)
equations <- read_tsv(paths[["rhea-equations.tsv"]])
names(equations) <- c("rhea_id", "equation")

cited_rhea <- sort(unique(c(
  tables$reactions$rhea_master[!is.na(tables$reactions$rhea_master)],
  grep("^RHEA:", tables$reactions$reaction_id, value = TRUE)
)))
number <- strip(cited_rhea, "RHEA")
master <- unname(member_of[number])
rhea_reactions <- data.frame(
  rhea_id = cited_rhea,
  status = ifelse(is.na(master), "unknown", ifelse(master == number, "master", "directional")),
  master_id = ifelse(is.na(master), NA, paste0("RHEA:", master)),
  stringsAsFactors = FALSE
)
rhea_reactions$equation <- equations$equation[match(rhea_reactions$master_id, equations$rhea_id)]
masters <- sort(unique(stats::na.omit(rhea_reactions$master_id)))

sides <- read_tsv(paths[["rhea-sides.tsv"]])
names(sides) <- c("acc", "side", "chebi", "under")
sides$acc <- gsub('"', "", sides$acc, fixed = TRUE)
sides <- sides[sides$acc %in% masters, , drop = FALSE]
# A generic participant such as a polymer or a protein residue has no ChEBI
# entity of its own and is identified by the one it is built on.
chebi <- ifelse(nzchar(sides$chebi), sides$chebi, sides$under)
rhea_participants <- unique(data.frame(
  master_id = sides$acc,
  side = sub("^.*_([LR])$", "\\1", sides$side),
  chebi_id = sub("^.*CHEBI_", "CHEBI:", chebi),
  stringsAsFactors = FALSE
)[nzchar(chebi), ])
rhea_participants <- rhea_participants[
  order(rhea_participants$master_id, rhea_participants$side, rhea_participants$chebi_id), ]

mapping <- function(file, namespace) {
  data <- read_tsv(paths[[file]])
  data <- data[paste0("RHEA:", data$MASTER_ID) %in% masters, , drop = FALSE]
  data.frame(master_id = paste0("RHEA:", data$MASTER_ID), namespace = namespace,
             accession = data$ID, stringsAsFactors = FALSE)
}
rhea_xrefs <- unique(rbind(
  mapping("rhea2ec.tsv", "EC"), mapping("rhea2kegg_reaction.tsv", "KEGG_REACTION")
))
rhea_xrefs <- rhea_xrefs[order(rhea_xrefs$master_id, rhea_xrefs$namespace, rhea_xrefs$accession), ]

# ----------------------------------------------------------------------- ChEBI
compounds <- read_tsv(gzfile(paths[["chebi-compounds.tsv.gz"]]))
ph <- read_tsv(paths[["chebi_pH7_3_mapping.tsv"]])
rhea_form <- stats::setNames(paste0("CHEBI:", ph$CHEBI_PH7_3), paste0("CHEBI:", ph$CHEBI))
cited_chebi <- sort(unique(c(
  tables$anchors$chebi_id[!is.na(tables$anchors$chebi_id)], rhea_participants$chebi_id
)))
hit <- match(cited_chebi, compounds$chebi_accession)
chebi_compounds <- data.frame(
  chebi_id = cited_chebi,
  # ChEBI status 1 is a checked, current entity.
  status = ifelse(is.na(hit), "unknown",
                  ifelse(compounds$status_id[hit] %in% c("1", "3"), "current", "obsolete")),
  name = compounds$ascii_name[hit],
  rhea_form = unname(rhea_form[cited_chebi]),
  stringsAsFactors = FALSE
)

# ------------------------------------------------------------------------ KEGG
listed <- function(file, prefix = "") {
  paste0(prefix, sub("\t.*$", "", readLines(paths[[file]], warn = FALSE)))
}
kegg_known <- list(
  KO = listed("kegg-ko.tsv"), KEGG_REACTION = listed("kegg-reaction.tsv"),
  KEGG_MODULE = listed("kegg-module.tsv"), KEGG_PATHWAY = listed("kegg-pathway.tsv")
)
cited_kegg <- unique(rbind(
  data.frame(namespace = "KO",
             accession = tables$markers$accession[tables$markers$namespace == "KO"],
             stringsAsFactors = FALSE),
  tables$reaction_xrefs[tables$reaction_xrefs$namespace == "KEGG_REACTION",
                        c("namespace", "accession")],
  tables$gift_xrefs[tables$gift_xrefs$namespace %in% c("KEGG_MODULE", "KEGG_PATHWAY"),
                    c("namespace", "accession")]
))
cited_kegg <- cited_kegg[order(cited_kegg$namespace, cited_kegg$accession), ]
cited_kegg$status <- ifelse(
  mapply(function(namespace, accession) accession %in% kegg_known[[namespace]],
         cited_kegg$namespace, cited_kegg$accession),
  "current", "unknown"
)
rownames(cited_kegg) <- NULL

link <- function(file, kind, prefix) {
  data <- read_tsv(paths[[file]], header = FALSE)
  data.frame(namespace = "KO", accession = strip(data[[1]], "ko"), kind = kind,
             value = strip(data[[2]], prefix), stringsAsFactors = FALSE)
}
kegg_links <- rbind(
  link("kegg-ko-reaction.tsv", "reaction", "rn"),
  link("kegg-ko-enzyme.tsv", "ec", "ec"),
  link("kegg-ko-module.tsv", "module", "md")
)
kegg_links <- kegg_links[kegg_links$accession %in% cited_kegg$accession, , drop = FALSE]
write_tsv(kegg_links, file.path(cache_dir, "kegg-ko-links.tsv"))

# ------------------------------------------------------------ NCBIfam and CAZy
ec_pattern <- "[0-9]+\\.[0-9n-]+\\.[0-9n-]+\\.[0-9n-]+"
ec_links <- function(namespace, accession, text) {
  found <- regmatches(text, gregexpr(ec_pattern, text))
  data.frame(
    namespace = rep(namespace, sum(lengths(found))),
    accession = rep(accession, lengths(found)), kind = "ec", value = unlist(found),
    stringsAsFactors = FALSE
  )
}
cited_marker <- function(namespace) {
  sort(tables$markers$accession[tables$markers$namespace == namespace])
}

profiles <- read_tsv(paths[["hmm_PGAP.tsv"]])
names(profiles)[[1]] <- "accession"
ncbifam <- cited_marker("NCBIFAM")
profile <- profiles[match(ncbifam, profiles$accession), , drop = FALSE]

# A dbCAN subfamily supports an EC number only where at least half of its
# annotated members carry it; below that the cluster is evidence against the
# assignment. A bare CAZy family is listed with every EC number dbCAN maps it to.
subfamilies <- read_tsv("data-raw/reference/cazy-subfamily-ec.tsv")
families <- utils::read.delim(
  "data-raw/reference/fam-substrate-mapping.tsv", colClasses = "character",
  check.names = FALSE, stringsAsFactors = FALSE
)
cazy <- cited_marker("CAZY")
admitted <- subfamilies[as.numeric(subfamilies$ec_fraction) >= 0.5, , drop = FALSE]
family_of <- trimws(families$Family)

marker_accessions <- rbind(
  data.frame(
    namespace = rep("NCBIFAM", length(ncbifam)), accession = ncbifam,
    status = ifelse(is.na(profile$accession), "unknown", "current"),
    family_type = profile$family_type, stringsAsFactors = FALSE
  ),
  data.frame(
    namespace = rep("CAZY", length(cazy)), accession = cazy,
    status = ifelse(cazy %in% c(subfamilies$cazy_subfamily, family_of), "current", "unknown"),
    family_type = NA_character_, stringsAsFactors = FALSE
  )
)
marker_links <- unique(rbind(
  ec_links("NCBIFAM", ncbifam, ifelse(is.na(profile$ec_numbers), "", profile$ec_numbers)),
  ec_links("CAZY", admitted$cazy_subfamily[admitted$cazy_subfamily %in% cazy],
           admitted$ec[admitted$cazy_subfamily %in% cazy]),
  ec_links("CAZY", family_of[family_of %in% cazy], families$EC_Number[family_of %in% cazy])
))
marker_links <- marker_links[
  order(marker_links$namespace, marker_links$accession, marker_links$value), ]
write_tsv(marker_links, links_path)
all_links <- rbind(kegg_links, marker_links)

# -------------------------------------------------------------------- manifest
release_of <- function(resource) {
  if (resource == "Rhea") {
    line <- grep("^rhea.release.number=", readLines(paths[["rhea-release.properties"]]), value = TRUE)
    return(sub("^.*=", "", line))
  }
  if (resource == "ChEBI") {
    listing <- paste(readLines(paths[["chebi-archive.html"]], warn = FALSE), collapse = " ")
    found <- regmatches(listing, gregexpr("rel[0-9]+", listing))[[1]]
    return(as.character(max(as.integer(sub("rel", "", found)))))
  }
  if (resource == "NCBIfam") return(paste0("hmm_PGAP/", NCBIFAM_RELEASE))
  # KEGG publishes no release identifier through its REST interface, so the
  # retrieval date is the pin.
  format(as.Date(file.info(paths[["kegg-ko.tsv"]])$mtime), "%Y-%m-%d")
}
manifest <- do.call(rbind, lapply(downloads, function(d) {
  data.frame(
    resource = d[[1]], release = release_of(d[[1]]),
    retrieved = format(as.Date(file.info(paths[[d[[2]]]])$mtime), "%Y-%m-%d"),
    file = d[[2]], url = d[[3]],
    sha256 = as.character(openssl::sha256(file(paths[[d[[2]]]]))),
    licence = d[[4]], stringsAsFactors = FALSE
  )
}))

committed <- c("data-raw/reference/cazy-subfamily-ec.tsv",
               "data-raw/reference/fam-substrate-mapping.tsv")
manifest <- rbind(manifest, data.frame(
  resource = "dbCAN", release = DBCAN_RELEASE, retrieved = "2026-08-18",
  file = committed, url = NA_character_,
  sha256 = vapply(committed, function(path) as.character(openssl::sha256(file(path))),
                  character(1)),
  licence = "dbCAN and CAZy terms; under review", stringsAsFactors = FALSE
))
write_tsv(manifest, file.path(out_dir, "MANIFEST.tsv"))
write_tsv(marker_accessions, file.path(out_dir, "marker-accessions.tsv"))
write_tsv(rhea_reactions, file.path(out_dir, "rhea-reactions.tsv"))
write_tsv(rhea_participants, file.path(out_dir, "rhea-participants.tsv"))
write_tsv(rhea_xrefs, file.path(out_dir, "rhea-xrefs.tsv"))
write_tsv(chebi_compounds, file.path(out_dir, "chebi-compounds.tsv"))
write_tsv(cited_kegg, file.path(out_dir, "kegg-accessions.tsv"))
message("Wrote the reference snapshot to ", out_dir)

# ------------------------------------------------------------------------ sync
if (sync) {
  save <- function(table) {
    write_tsv(tables[[table]], file.path(source_dir, paste0(table, ".tsv")))
  }
  tables$reactions$equation <- rhea_reactions$equation[
    match(tables$reactions$rhea_master, rhea_reactions$rhea_id)
  ]
  tables$anchors$chebi_name <- chebi_compounds$name[
    match(tables$anchors$chebi_id, chebi_compounds$chebi_id)
  ]
  save("reactions")
  save("anchors")
  reference <- gifter:::.read_reference_snapshot(out_dir)
  derived <- gifter:::.derive_marker_basis(tables, reference, all_links)
  for (table in names(derived)) {
    tables[[table]]$basis <- derived[[table]]
    save(table)
  }
  message("Synchronised imported and derived columns in ", source_dir)
}
