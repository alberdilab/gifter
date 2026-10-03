#!/usr/bin/env Rscript
# KO-level prevalence screen for nine candidate structural machines.
#
# Initial assessment for attempt GEA-20261003-STRUCTURAL-MACHINES. The stored
# prokaryotic KEGG frame is KO-only, so every number here is a KO proxy and a
# diagnostic: none of the Boolean sets below is a curated GIFT architecture.
# For each candidate the script reports, over the full frame, how many genomes
# carry each KO, how many complete each proxy function set, and how many are
# exactly one function short and which function they miss.
#
# Usage:
#   Rscript data-raw/structural_machines_prevalence.R
#   Rscript data-raw/structural_machines_prevalence.R --offline
#
# Downloaded KO links are cached and are not committed. Only aggregate results
# are written, because KEGG's per-genome assignments are not redistributable.

args <- commandArgs(trailingOnly = TRUE)
opt <- function(name, default) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit)) sub(paste0("^--", name, "="), "", hit[[1L]]) else default
}

cache_dir <- opt("cache", "data-raw/reference/.cache/structural-machines")
out_dir <- opt("out", "data-raw/reference")
frame_path <- opt("frame", "manuscript/analysis/output/kegg-genome-set.tsv")
offline <- "--offline" %in% args

dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

say <- function(...) cat(..., "\n", sep = "")
read_tsv <- function(path, ...) {
  utils::read.delim(
    path, quote = "", comment.char = "", stringsAsFactors = FALSE,
    check.names = FALSE, ...
  )
}
write_tsv <- function(x, path) {
  utils::write.table(
    x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = ""
  )
  invisible(path)
}

fetch <- function(url, relative, attempts = 5L) {
  path <- file.path(cache_dir, relative)
  if (file.exists(path)) return(path)
  if (offline) stop("missing cached input and --offline was given: ", path)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  part <- paste0(path, ".part")
  for (attempt in seq_len(attempts)) {
    if (file.exists(part)) unlink(part)
    status <- tryCatch(
      utils::download.file(url, part, quiet = TRUE, mode = "wb"),
      error = function(e) 1L,
      warning = function(w) 1L
    )
    if (identical(status, 0L) && file.exists(part)) {
      if (!file.rename(part, path)) stop("could not install downloaded input: ", path)
      Sys.sleep(0.35)
      return(path)
    }
    if (attempt < attempts) Sys.sleep(2 * attempt)
  }
  if (file.exists(part)) unlink(part)
  stop("download failed after ", attempts, " attempts: ", url)
}

kegg_orgs_for_ko <- function(ko, frame_orgs) {
  path <- fetch(
    paste0("https://rest.kegg.jp/link/genes/ko:", ko),
    file.path("kegg", paste0(ko, ".tsv"))
  )
  lines <- readLines(path, warn = FALSE)
  lines <- lines[nzchar(lines)]
  org <- sub(":.*", "", sub("^[^\t]+\t", "", lines))
  intersect(unique(org), frame_orgs)
}

# ------------------------------------------------------------------------- frame

frame <- read_tsv(frame_path)
frame <- frame[!duplicated(frame$org), ]
prokaryote <- as.logical(frame$prokaryote)
frame_orgs <- frame$org[!is.na(prokaryote) & prokaryote]
say("Stored frame: ", nrow(frame), " genomes; ", length(frame_orgs), " prokaryotic")

# Domain and phylum come from the KEGG organism hierarchy (br08601). A genome
# the hierarchy does not list keeps an NA lineage; it still counts in the frame.
htext <- readLines(fetch("https://rest.kegg.jp/get/br:br08601", "kegg/br08601.keg"), warn = FALSE)
level <- substr(htext, 1L, 1L)
label <- trimws(sub(" \\([0-9]+\\)$", "", substring(htext, 2L)))
carry <- function(which) {
  idx <- cumsum(level == which)
  c(NA_character_, label[level == which])[idx + 1L]
}
is_org <- level == "E"
org_code <- sub(" .*", "", label[is_org])
domain <- setNames(carry("B")[is_org], org_code)[frame_orgs]
phylum <- setNames(carry("C")[is_org], org_code)[frame_orgs]
names(domain) <- names(phylum) <- frame_orgs
say("Lineage resolved for ", sum(!is.na(domain)), " of ", length(frame_orgs), " frame genomes")

# ------------------------------------------------------------------- candidates
#
# Each candidate is a named list of proxy function sets. A function is a
# character vector of KOs, any one of which satisfies it.

fn <- function(...) c(...)
candidates <- list(
  archaellum = list(
    core = list(
      archaellin = fn("K07324", "K07325"), FlaF = "K07329", FlaG = "K07330",
      FlaH = "K07331", FlaI = "K07332", FlaJ = "K07333"
    ),
    core_plus_peptidase = list(
      archaellin = fn("K07324", "K07325"), FlaF = "K07329", FlaG = "K07330",
      FlaH = "K07331", FlaI = "K07332", FlaJ = "K07333", FlaK = "K07991"
    ),
    euryarchaeal = list(
      archaellin = fn("K07324", "K07325"), FlaF = "K07329", FlaG = "K07330",
      FlaH = "K07331", FlaI = "K07332", FlaJ = "K07333",
      FlaCDE = fn("K07822", "K07327", "K07328", "K23986")
    )
  ),
  tad_pilus = list(
    diderm_core = list(
      Flp = "K02651", CpaA_TadV = "K02278", CpaB_RcpC = "K02279",
      CpaC_RcpA = "K02280", CpaE_TadZ = "K02282", CpaF_TadA = "K02283",
      TadB = "K12510", TadC = "K12511"
    ),
    without_pilin_peptidase = list(
      CpaB_RcpC = "K02279", CpaC_RcpA = "K02280", CpaE_TadZ = "K02282",
      CpaF_TadA = "K02283", TadB = "K12510", TadC = "K12511"
    ),
    secretin_free = list(
      Flp = "K02651", CpaA_TadV = "K02278", CpaE_TadZ = "K02282",
      CpaF_TadA = "K02283", TadB = "K12510", TadC = "K12511"
    )
  ),
  type_ii_secretion = list(
    core = list(
      GspC = "K02452", GspD = "K02453", GspE = "K02454", GspF = "K02455",
      GspG = "K02456", GspH = "K02457", GspI = "K02458", GspJ = "K02459",
      GspK = "K02460", GspL = "K02461", GspM = "K02462"
    ),
    core_plus_peptidase = list(
      GspC = "K02452", GspD = "K02453", GspE = "K02454", GspF = "K02455",
      GspG = "K02456", GspH = "K02457", GspI = "K02458", GspJ = "K02459",
      GspK = "K02460", GspL = "K02461", GspM = "K02462",
      peptidase = fn("K02464", "K02654")
    ),
    specific_only = list(
      GspC = "K02452", GspL = "K02461", GspM = "K02462"
    )
  ),
  type_iva_pilus_reference = list(
    proxy = list(
      pilin = fn("K02650", "K02655"), PilB = "K02652", PilC = "K02653",
      PilD = "K02654", PilM = "K02662", PilN = "K02663", PilO = "K02664",
      PilP = "K02665", PilQ = "K02666"
    )
  ),
  gas_vesicle = list(
    kegg_visible = list(GvpA = "K23262"),
    with_GvpC = list(GvpA = "K23262", GvpC = "K23263")
  ),
  bam_complex = list(
    BamA_only = list(BamA = "K07277"),
    essential_pair = list(BamA = "K07277", BamD = "K05807"),
    five_subunit = list(
      BamA = "K07277", BamB = "K17713", BamC = "K07287", BamD = "K05807",
      BamE = "K06186"
    )
  ),
  curli = list(
    core = list(
      CsgA = "K04334", CsgB = "K04335", CsgE = "K04337", CsgF = "K04338",
      CsgG = "K06214"
    ),
    secretion_only = list(CsgE = "K04337", CsgF = "K04338", CsgG = "K06214")
  ),
  chaperone_usher = list(
    class = list(
      usher = fn("K07347", "K07354", "K12518", "K21966"),
      chaperone = fn("K07346", "K07353", "K12519", "K15540"),
      major_subunit = fn("K07345", "K07352", "K12517")
    ),
    usher_chaperone = list(
      usher = fn("K07347", "K07354", "K12518", "K21966"),
      chaperone = fn("K07346", "K07353", "K12519", "K15540")
    ),
    type1_fim = list(
      FimA = "K07345", FimC = "K07346", FimD = "K07347", FimF = "K07348",
      FimG = "K07349", FimH = "K07350"
    ),
    pap = list(
      PapA = "K12517", PapC = "K12518", PapD = "K12519", PapE = "K12520",
      PapF = "K12521", PapG = "K12522", PapK = "K12523"
    )
  ),
  type_iv_secretion = list(
    virb_d4 = list(
      VirB2 = "K03197", VirB3 = "K03198", VirB4 = "K03199", VirB5 = "K03200",
      VirB6 = "K03201", VirB7 = "K03202", VirB8 = "K03203", VirB9 = "K03204",
      VirB10 = "K03195", VirB11 = "K03196", VirD4 = "K03205"
    ),
    virb_without_small = list(
      VirB3 = "K03198", VirB4 = "K03199", VirB6 = "K03201", VirB8 = "K03203",
      VirB9 = "K03204", VirB10 = "K03195", VirB11 = "K03196", VirD4 = "K03205"
    ),
    trb_p_type = list(
      TrbB = "K20527", TrbC = "K20528", TrbD = "K20529", TrbE = "K20530",
      TrbF = "K20531", TrbG = "K20532", TrbI = "K20533", TrbJ = "K20266",
      TrbL = "K07344"
    ),
    f_type = list(
      TraA = "K12069", TraL = "K12068", TraE = "K12067", TraK = "K12066",
      TraB = "K12065", TraV = "K12064", TraC = "K12063", TraW = "K12061",
      TraU = "K12060", TraF = "K12057", TraH = "K12072", TraG = "K12056",
      TraN = "K12058", TraD = "K12071"
    ),
    dot_icm = list(
      DotA = "K12202", DotB = "K12203", DotC = "K12204", DotD = "K12205",
      IcmB = "K12206", IcmE = "K12209", IcmG = "K12211", IcmK = "K12213",
      IcmO = "K12217"
    )
  ),
  microcompartment = list(
    shell_any = list(
      hexamer = fn("K27260", "K27266", "K27267", "K04027", "K04025", "K08696"),
      pentamer = fn("K27269", "K04028", "K08697")
    ),
    pdu_shell = list(
      PduA_J = fn("K27260", "K27266"), PduB = "K27263", PduN = "K27269"
    ),
    eut_shell = list(
      EutM = "K04027", EutL = "K04026", EutN = "K04028"
    ),
    beta_carboxysome_shell = list(
      CcmK = "K08696", CcmL = "K08697", CcmO = "K08700", CcmM = "K08698",
      CcmN = "K08699"
    )
  )
)

all_kos <- sort(unique(unlist(candidates, use.names = FALSE)))
say("Fetching ", length(all_kos), " KO gene links")
ko_orgs <- setNames(lapply(all_kos, kegg_orgs_for_ko, frame_orgs = frame_orgs), all_kos)

ko_names <- read_tsv(
  "data-raw/reference/.cache/kegg-ko-list.tsv", header = FALSE,
  col.names = c("ko", "definition")
)
ko_names <- setNames(ko_names$definition, ko_names$ko)

# ---------------------------------------------------------------------- results

n_frame <- length(frame_orgs)
n_archaea <- sum(domain == "Archaea", na.rm = TRUE)
n_bacteria <- sum(domain == "Bacteria", na.rm = TRUE)
# The frame's `prokaryote` flag is a genus-name filter and still admits
# eukaryotes, so the bacterial and archaeal denominators are reported beside it.
say(
  "Frame by KEGG hierarchy: ", n_bacteria, " bacteria, ", n_archaea,
  " archaea, ", n_frame - n_bacteria - n_archaea, " neither"
)
count_domain <- function(orgs, which) sum(domain[orgs] == which, na.rm = TRUE)

ko_rows <- do.call(rbind, lapply(names(candidates), function(candidate) {
  kos <- sort(unique(unlist(candidates[[candidate]], use.names = FALSE)))
  data.frame(
    candidate = candidate, ko = kos, definition = unname(ko_names[kos]),
    genomes = vapply(ko_orgs[kos], length, integer(1)),
    archaea = vapply(ko_orgs[kos], count_domain, integer(1), which = "Archaea"),
    bacteria = vapply(ko_orgs[kos], count_domain, integer(1), which = "Bacteria"),
    frame = n_frame, frame_bacteria = n_bacteria, frame_archaea = n_archaea,
    stringsAsFactors = FALSE
  )
}))
rownames(ko_rows) <- NULL

function_orgs <- function(kos) unique(unlist(ko_orgs[kos], use.names = FALSE))

set_rows <- do.call(rbind, lapply(names(candidates), function(candidate) {
  do.call(rbind, lapply(names(candidates[[candidate]]), function(set) {
    fns <- lapply(candidates[[candidate]][[set]], function_orgs)
    present <- vapply(fns, function(orgs) frame_orgs %in% orgs, logical(n_frame))
    if (is.null(dim(present))) present <- matrix(present, ncol = 1L, dimnames = list(NULL, names(fns)))
    n_present <- rowSums(present)
    complete <- frame_orgs[n_present == ncol(present)]
    short <- n_present == ncol(present) - 1L & ncol(present) > 1L
    missing <- if (any(short)) {
      table(factor(colnames(present)[apply(!present[short, , drop = FALSE], 1L, which)], colnames(present)))
    } else {
      integer()
    }
    missing <- missing[missing > 0L]
    top_phyla <- sort(table(phylum[complete]), decreasing = TRUE)
    data.frame(
      candidate = candidate, proxy_set = set, functions = ncol(present),
      complete = length(complete),
      complete_archaea = count_domain(complete, "Archaea"),
      complete_bacteria = count_domain(complete, "Bacteria"),
      one_short = sum(short),
      missing_function_when_one_short = paste0(
        names(missing), "=", as.integer(missing), collapse = ";"
      ),
      any_function = sum(n_present > 0L),
      top_phyla_complete = paste0(
        names(utils::head(top_phyla, 5L)), "=", as.integer(utils::head(top_phyla, 5L)),
        collapse = ";"
      ),
      frame = n_frame, frame_bacteria = n_bacteria, frame_archaea = n_archaea,
      stringsAsFactors = FALSE
    )
  }))
}))
rownames(set_rows) <- NULL

# Homology overlap: how often the candidate machines co-occur with, and how
# often their shared-family KOs are found without, the curated type IVa pilus.
complete_set <- function(candidate, set) {
  Reduce(intersect, lapply(candidates[[candidate]][[set]], function_orgs))
}
t4ap <- complete_set("type_iva_pilus_reference", "proxy")
overlap_pair <- function(label, a, b) {
  data.frame(
    comparison = label, a = length(a), b = length(b),
    both = length(intersect(a, b)), a_only = length(setdiff(a, b)),
    b_only = length(setdiff(b, a)), stringsAsFactors = FALSE
  )
}
overlap_rows <- rbind(
  overlap_pair("T2SS core vs type IVa pilus proxy", complete_set("type_ii_secretion", "core"), t4ap),
  overlap_pair("GspD K02453 vs PilQ K02666", ko_orgs[["K02453"]], ko_orgs[["K02666"]]),
  overlap_pair("GspE K02454 vs PilB K02652", ko_orgs[["K02454"]], ko_orgs[["K02652"]]),
  overlap_pair("GspF K02455 vs PilC K02653", ko_orgs[["K02455"]], ko_orgs[["K02653"]]),
  overlap_pair("GspG K02456 vs PilA K02650", ko_orgs[["K02456"]], ko_orgs[["K02650"]]),
  overlap_pair("GspO K02464 vs PilD K02654", ko_orgs[["K02464"]], ko_orgs[["K02654"]]),
  overlap_pair("Tad diderm core vs type IVa pilus proxy", complete_set("tad_pilus", "diderm_core"), t4ap),
  overlap_pair("CpaA K02278 vs PilD K02654", ko_orgs[["K02278"]], ko_orgs[["K02654"]]),
  overlap_pair("Tad diderm core vs T2SS core", complete_set("tad_pilus", "diderm_core"), complete_set("type_ii_secretion", "core")),
  overlap_pair("VirB/D4 vs Trb P-type", complete_set("type_iv_secretion", "virb_d4"), complete_set("type_iv_secretion", "trb_p_type")),
  overlap_pair("BamA K07277 vs LptD K04744", ko_orgs[["K07277"]], kegg_orgs_for_ko("K04744", frame_orgs)),
  overlap_pair("archaellum core vs FlaI K07332 (any)", complete_set("archaellum", "core"), ko_orgs[["K07332"]])
)

write_tsv(ko_rows, file.path(out_dir, "structural-machines-ko-prevalence.tsv"))
write_tsv(set_rows, file.path(out_dir, "structural-machines-proxy-prevalence.tsv"))
write_tsv(overlap_rows, file.path(out_dir, "structural-machines-homology-overlap.tsv"))
say("Wrote structural-machines-{ko,proxy}-prevalence.tsv and structural-machines-homology-overlap.tsv")
