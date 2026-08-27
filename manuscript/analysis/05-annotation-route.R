#!/usr/bin/env Rscript
# R9, the annotation route: how much of the reported recall is gifter, and how
# much is an idealised annotation.
#
# Every other number in R9 runs on KEGG's own per-genome KO assignment. That
# assignment is curated, orthology-resolved and, for the organisms KEGG has
# annotated, about as good as a KO call gets. It is not what a user's annotator
# produces, so every recall measured on it is an **upper bound**, and the size
# of that bound has never been reported by a comparable tool. This measures it.
#
# The design is a three-way comparison on one matched set of genomes, because
# the difference between the KEGG route and an annotation run has two signs and
# pooling them would hide both:
#
#   kegg_ko     KEGG's per-genome KO assignment, the upper bound
#   annot_ko    KofamScan's KO assignment on the same proteins, the pipeline a
#               user runs. kegg_ko -> annot_ko is the annotation cost.
#   annot_full  the same run plus the namespaces the KEGG route cannot reach at
#               all: NCBIfam profiles, dbCAN families and subfamilies, Pfam.
#               annot_ko -> annot_full is what those namespaces buy back.
#
# The second step is the only way to see part of the curation at all. Database
# 2026.25.1 admitted nine NCBIfam equivalogs to the histidine biosynthesis
# steps; on a KO-only genome set that curation is invisible by construction,
# because no NCBIfam accession can appear in the evidence.
#
# What is pinned, and the rule each pipeline applies:
#
#   KOfam     a profile hits when the full sequence score (score_type "full") or
#             the best domain score (score_type "domain") reaches that profile's
#             own adaptive threshold. This is KofamScan's rule. Restricting the
#             library to the curated KO profiles cannot change a single hit,
#             because each threshold is independent of every other profile.
#   NCBIfam   hmm_PGAP with --cut_ga, each profile's own curated cutoff -- the
#             same cutoffs PGAP, bakta and AMRFinderPlus apply.
#   dbCAN     run_dbcan's published filter: independent E-value below 1e-15 and
#             profile coverage above 0.35, with -Z set to the whole library size
#             so that filtering the library down to curated profiles does not
#             inflate the E-value. run_dbcan runs these libraries under hmmscan;
#             hmmsearch is the same comparison with the operands reversed and
#             returns an identical filtered hit set far faster.
#
# Gene calling is held fixed. The proteins searched are the deposited protein
# set of the same assembly the KEGG genome entry names, so this measures the
# cost of assigning markers, not the cost of calling genes. A MAG pipeline pays
# a further and separate penalty at the gene-calling step; R7 is where that
# belongs, and this script must not be read as having measured it.
#
# The two test sets are rebuilt here rather than read from the tables 03 and 04
# committed. That is deliberate: a BacDive sweep grows between runs, and a
# recall figure is only comparable to another one measured on the same sweep.
# Both routes are therefore scored inside one run, against one sweep, and the
# delta between them is the only quantity this script claims.
#
# Products, all written to manuscript/analysis/output/:
#
#   annotation-route-genomes.tsv    the matched genome set and its provenance
#   annotation-route-markers.tsv    per marker, what each route observed
#   annotation-route-calls.tsv      per GIFT, calls under each of the three routes
#   annotation-route-agreement.tsv  the R9 recall tables, recomputed per route
#
# Proteomes and profile libraries stay in the cache. They are large, and they
# are somebody else's data.
#
# Usage:
#   Rscript manuscript/analysis/05-annotation-route.R [--genomes=400]
#          [--workers=3] [--threads=2]
#
# First run downloads about 1.6 GB of profile libraries plus one protein FASTA
# per genome, then runs three HMMER searches per genome. Budget several hours.
# Everything is cached; a second run is minutes.

source("manuscript/analysis/_common.R")
suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
opt <- function(name, default) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit) == 0) default else sub(paste0("^--", name, "="), "", hit[[1]])
}
n_genomes   <- as.integer(opt("genomes", "400"))
threads     <- as.integer(opt("threads", "2"))
workers     <- as.integer(opt("workers", "3"))
bacdive_max <- as.integer(opt("bacdive-max", "180000"))
out_dir     <- "manuscript/analysis/output"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

DBCAN_RELEASE <- "db_v5-2-9_5-5-2026"

ANNOT <- function(...) cache_path(file.path("annotation", ...))
for (d in c("profiles", "proteomes", "hmm", "listing")) dir.create(ANNOT(d), showWarnings = FALSE, recursive = TRUE)

# HMMER is the one external binary this analysis needs. It is not an R
# dependency and it is not vendored; the path is stated rather than assumed.
HMMER <- function(tool) {
  path <- Sys.getenv("GIFTER_HMMER", "")
  if (nzchar(path)) return(file.path(path, tool))
  found <- Sys.which(tool)
  if (!nzchar(found)) stop("HMMER not found; set GIFTER_HMMER to the directory holding hmmsearch")
  unname(found)
}

con <- gifter_db()
crosswalk <- read_phenotype_crosswalk(con)
alias     <- read_chebi_aliases()

# ------------------------------------------------------- 1. the two test sets
# Sections 3 and 4 of 03-phenotype.R, and sections 2 and 3 of 04-auxotrophy.R,
# repeated here so that both routes are scored against one sweep.
rule("1. Rebuilding the R9 test sets")

genome_set <- read.delim(file.path(out_dir, "kegg-genome-set.tsv"), stringsAsFactors = FALSE)
genome_set$assembly_base <- sub("[.].*", "", genome_set$assembly)

observed <- bacdive_reduce(seq_len(bacdive_max), list(
  assemblies  = bd_assemblies,
  utilisation = bd_utilisation,
  production  = bd_production,
  enzymes     = bd_enzymes,
  motility    = bd_motility))
kv("BacDive records read", attr(observed, "records"))

assemblies <- observed$assemblies
assemblies <- assemblies[!is.na(assemblies$assembly), ]
assemblies$assembly_base <- sub("[.].*", "", assemblies$assembly)
assemblies <- assemblies[order(assemblies$bacdive_id, -assemblies$score), ]
assemblies <- assemblies[!duplicated(assemblies$bacdive_id), ]
joined <- merge(assemblies, genome_set[, c("org", "assembly_base", "binomial", "name")],
                by = "assembly_base")
joined <- joined[!joined$org %in% unique(joined$org[duplicated(joined$org)]), ]
strain_genome <- setNames(joined$org, joined$bacdive_id)
lineage <- setNames(sub(" .*", "", joined$binomial), joined$org)
kv("strains matched to a reference genome", nrow(joined))

as_logical_activity <- function(x) ifelse(x == "+", TRUE, ifelse(x == "-", FALSE, NA))
collect_observations <- function() {
  out <- list()
  add <- function(i, ids, value) {
    r <- crosswalk[i, ]
    out[[length(out) + 1]] <<- data.frame(
      row = i, layer = r$layer, target = r$target_id, relation = r$relation,
      bacdive_id = ids, observed = value, stringsAsFactors = FALSE)
  }
  u <- observed$utilisation
  u$observed <- as_logical_activity(u$activity)
  u <- u[!is.na(u$observed), ]
  u$chebi_full <- paste0("CHEBI:", u$chebi)
  for (i in which(crosswalk$source_field == "metabolite utilization")) {
    hit <- u[u$chebi_full == crosswalk$source_id[[i]] & u$kind %in% crosswalk$kinds[[i]], ]
    if (nrow(hit)) add(i, hit$bacdive_id, hit$observed)
  }
  p <- observed$production
  p$observed <- p$produced %in% c("yes", "+")
  p$chebi_full <- paste0("CHEBI:", p$chebi)
  for (i in which(crosswalk$source_field == "metabolite production")) {
    hit <- p[p$chebi_full == crosswalk$source_id[[i]], ]
    if (nrow(hit)) add(i, hit$bacdive_id, hit$observed)
  }
  e <- observed$enzymes
  e$observed <- as_logical_activity(e$activity)
  e <- e[!is.na(e$observed) & !is.na(e$ec), ]
  for (i in which(crosswalk$source_field == "enzymes")) {
    hit <- e[paste0("EC:", e$ec) == crosswalk$source_id[[i]], ]
    if (nrow(hit)) add(i, hit$bacdive_id, hit$observed)
  }
  m <- observed$motility
  m$observed <- m$motility %in% c("yes", "flagella")
  for (i in which(crosswalk$source_field == "cell morphology")) add(i, m$bacdive_id, m$observed)
  do.call(rbind, out)
}
obs <- collect_observations()
obs$org <- unname(strain_genome[obs$bacdive_id])
obs <- obs[!is.na(obs$org), ]
key <- paste(obs$row, obs$org)
conflicted <- unique(key[duplicated(key) & !duplicated(paste(key, obs$observed))])
obs <- obs[!key %in% conflicted, ]
obs <- obs[!duplicated(paste(obs$row, obs$org)), ]
kv("strain-target observations with a genome", nrow(obs))

# The anabolic half: MediaDive defined media, growth-positive pairs, and the
# readable-composition filter 04-auxotrophy.R applies.
media <- fromJSON(cached_get("https://mediadive.dsmz.de/rest/media", "mediadive/media.json"))$data
defined <- media[media$complex_medium == 0, ]
ingredients <- fromJSON(cached_get("https://mediadive.dsmz.de/rest/ingredients",
                                   "mediadive/ingredients.json"))$data
ingredient_chebi <- setNames(
  ifelse(is.na(ingredients$ChEBI), NA_character_, paste0("CHEBI:", ingredients$ChEBI)),
  as.character(ingredients$id))
media_ids <- as.character(defined$id)
invisible(cached_get_many(paste0("https://mediadive.dsmz.de/rest/medium-composition/", media_ids),
                          file.path("mediadive", "composition", paste0(media_ids, ".json"))))
invisible(cached_get_many(paste0("https://mediadive.dsmz.de/rest/medium-strains/", media_ids),
                          file.path("mediadive", "strains", paste0(media_ids, ".json"))))
read_rows <- function(kind, id) {
  path <- cache_path(file.path("mediadive", kind, paste0(id, ".json")))
  if (!file.exists(path)) return(NULL)
  d <- tryCatch(fromJSON(path), error = function(e) NULL)
  if (is.null(d) || is.null(d$data) || !length(d$data)) return(NULL)
  d$data
}
composition <- list(); growth <- list()
for (id in media_ids) {
  comp <- read_rows("composition", id)
  if (!is.null(comp)) composition[[id]] <- as.character(comp$id)
  st <- read_rows("strains", id)
  if (!is.null(st) && !is.null(st$bacdive_id))
    growth[[length(growth) + 1]] <- data.frame(
      medium = id, bacdive_id = as.character(st$bacdive_id), growth = st$growth,
      stringsAsFactors = FALSE)
}
growth <- do.call(rbind, growth)
growth <- growth[!is.na(growth$bacdive_id) & growth$growth == 1, ]
growth$org <- unname(strain_genome[growth$bacdive_id])
growth <- growth[!is.na(growth$org), ]
resolution <- vapply(names(composition), function(id) {
  ing <- composition[[id]]
  if (!length(ing)) return(0)
  mean(!is.na(ingredient_chebi[ing]))
}, numeric(1))
readable <- names(resolution)[resolution >= 0.75]
growth <- growth[growth$medium %in% readable, ]
kv("growth pairs on a readable defined medium", nrow(growth))

# ---------------------------------------------------------------- 2. selection
rule("2. The matched genome set")

catabolic <- sort(unique(obs$org))
anabolic  <- sort(unique(growth$org))
kv("genomes with a BacDive observation", length(catabolic))
kv("genomes on a readable defined medium", length(anabolic))

# The anabolic genomes are taken whole rather than sampled. They are few, they
# carry the only external check the quantitative layer has, and they are where
# the NCBIfam curation of database 2026.25.1 can be seen at all.
set.seed(9)
fill <- setdiff(catabolic, anabolic)
selected <- sort(c(anabolic,
                   sample(fill, min(length(fill), max(0L, n_genomes - length(anabolic))))))
selection <- genome_set[match(selected, genome_set$org), ]
selection$half <- ifelse(selection$org %in% anabolic,
                         ifelse(selection$org %in% catabolic, "both", "anabolic"), "catabolic")
kv("genomes selected", nrow(selection))
print(table(selection$half))
kv("dropped: no GenBank assembly", sum(is.na(selection$assembly)))
selection <- selection[!is.na(selection$assembly), ]

# -------------------------------------------------------------- 3. the proteomes
rule("3. Proteomes")

# NCBI throttles: a first pass over a few hundred accessions on four
# connections comes back with 503s on a third of them, and cached_get_many
# treats any status at or above 400 as a miss and deletes the file. Silently
# accepting that would shrink the genome set by whichever assemblies happened to
# be asked for during a busy minute, which is a sampling rule nobody chose. So
# the misses are retried on fewer connections until they stop being misses.
fetch_persistently <- function(urls, dests, attempts = 5L, host_con = 2L) {
  paths <- rep(NA_character_, length(urls))
  for (attempt in seq_len(attempts)) {
    todo <- which(is.na(paths))
    if (!length(todo)) break
    if (attempt > 1L) {
      message("  retry ", attempt - 1L, " on ", length(todo), " that came back empty")
      Sys.sleep(15)
    }
    paths[todo] <- cached_get_many(urls[todo], dests[todo], host_con = host_con)
  }
  paths
}

# NCBI's genome tree is addressed by the accession's digits, and the leaf
# directory carries an assembly name that has to be read rather than guessed.
assembly_dir <- function(accession) {
  digits <- sub("[.].*", "", sub("^GC[AF]_", "", accession))
  paste0("https://ftp.ncbi.nlm.nih.gov/genomes/all/", substr(accession, 1, 3), "/",
         substr(digits, 1, 3), "/", substr(digits, 4, 6), "/", substr(digits, 7, 9), "/")
}
listing <- fetch_persistently(assembly_dir(selection$assembly),
                              file.path("annotation", "listing",
                                        paste0(selection$assembly, ".html")))
selection$directory <- vapply(seq_along(listing), function(i) {
  if (is.na(listing[[i]])) return(NA_character_)
  text <- paste(readLines(listing[[i]], warn = FALSE), collapse = " ")
  hit <- regmatches(text, gregexpr("GC[AF]_[0-9]+[.][0-9]+_[^\"/<> ]+", text))[[1]]
  hit <- unique(hit[startsWith(hit, paste0(selection$assembly[[i]], "_"))])
  if (!length(hit)) NA_character_ else hit[[1]]
}, character(1))
kv("assemblies resolved to a directory", sum(!is.na(selection$directory)))
# What is left after five attempts is an assembly the current NCBI release no
# longer carries under the accession KEGG recorded, which is a real absence
# rather than a throttled request.
selection <- selection[!is.na(selection$directory), ]

selection$proteome <- fetch_persistently(
  paste0(assembly_dir(selection$assembly), selection$directory, "/",
         selection$directory, "_protein.faa.gz"),
  file.path("annotation", "proteomes", paste0(selection$assembly, ".faa.gz")))
# An assembly deposited without a protein set is dropped and counted. It is not
# a gifter result and it must not silently shrink a denominator.
kv("dropped: assembly deposited with no protein set", sum(is.na(selection$proteome)))
selection <- selection[!is.na(selection$proteome), ]
kv("genomes carried forward", nrow(selection))

# ------------------------------------------------------ 4. the profile libraries
rule("4. Profile libraries")

markers <- dbGetQuery(con, "select distinct namespace, accession from marker")
print(table(markers$namespace))

# KOfam and dbCAN publish one large archive each and no per-profile endpoint.
# Each is fetched or streamed once, and only the curated profiles are kept:
# gifter consumes 753 of KOfam's 28 000 profiles and 520 of dbCAN's.
# Both hosts serve a few hundred kB/s per connection and both accept byte
# ranges, so a one-time multi-gigabyte archive is fetched in parallel pieces
# rather than in one stream that would run for hours and lose everything if it
# dropped. The pieces are returned rather than joined, because the dbCAN
# libraries are filtered on the way past and never need to exist whole.
#
# R supervises the connections rather than trusting curl to. S3 stops delivering
# on a long-lived range request without closing it or erroring, and a curl that
# is merely waiting never triggers its own --retry: observed here as eight live
# connections, zero bytes for six minutes, and a --max-time of three hours still
# to run before anything would have noticed. So each piece is polled, and one
# that has not grown for two minutes has its connection killed and restarted
# from the byte it actually reached -- which is why the range is recomputed on
# every launch and the output appended rather than overwritten.
fetch_ranged_parts <- function(url, prefix, connections = 8L,
                               poll = 20, stall_polls = 6L) {
  head <- system2("curl", c("-sSI", "--max-time", "60", shQuote(url)), stdout = TRUE)
  len <- as.numeric(sub(".*: *", "", trimws(grep("^[Cc]ontent-[Ll]ength", head, value = TRUE)[[1]])))
  size <- ceiling(len / connections)
  # %.0f throughout, not %d: a 5 GB library puts the later offsets past R's
  # integer range, where sprintf("%d") refuses outright.
  starts <- (seq_len(connections) - 1L) * size
  ends <- pmin(starts + size - 1, len - 1)
  parts <- sprintf("%s.part%d", prefix, seq_len(connections))
  pids <- sprintf("%s.pid%d", prefix, seq_len(connections))
  want <- ends - starts + 1

  have <- function(i) if (file.exists(parts[[i]])) file.size(parts[[i]]) else 0
  launch <- function(i) {
    from <- starts[[i]] + have(i)
    if (from > ends[[i]]) return(invisible(NULL))
    system(sprintf(paste("curl -sSL --speed-limit 10240 --speed-time 60 --max-time 3600",
                         "-r %.0f-%.0f %s >> %s 2>/dev/null & echo $! > %s"),
                   from, ends[[i]], shQuote(url), shQuote(parts[[i]]), shQuote(pids[[i]])))
  }
  stop_part <- function(i) {
    if (!file.exists(pids[[i]])) return(invisible(NULL))
    pid <- suppressWarnings(as.integer(readLines(pids[[i]], warn = FALSE)[[1]]))
    if (!is.na(pid)) system(sprintf("kill %d 2>/dev/null", pid))
    unlink(pids[[i]])
  }

  message("  fetching ", format(len, big.mark = " "), " bytes on ", connections,
          " connections (", format(sum(vapply(seq_len(connections), have, numeric(1))),
                                   big.mark = " "), " already on disk)")
  for (i in seq_len(connections)) launch(i)

  last <- rep(-1, connections)
  stalled <- rep(0L, connections)
  repeat {
    sizes <- vapply(seq_len(connections), have, numeric(1))
    if (all(sizes >= want)) break
    stalled <- ifelse(sizes == last & sizes < want, stalled + 1L, 0L)
    last <- sizes
    for (i in which(stalled >= stall_polls)) {
      message("    connection ", i, " delivered nothing for ", poll * stall_polls,
              "s; restarting it at ", format(sizes[[i]], big.mark = " "), " bytes")
      stop_part(i)
      Sys.sleep(2)
      launch(i)
      stalled[[i]] <- 0L
    }
    message("    ", format(sum(sizes), big.mark = " "), " / ", format(len, big.mark = " "))
    Sys.sleep(poll)
  }
  for (i in seq_len(connections)) stop_part(i)
  # A resumed range can only ever append the bytes it was asked for, but a part
  # that is the wrong length would corrupt the library silently, so it is
  # checked rather than assumed.
  final <- vapply(seq_len(connections), have, numeric(1))
  if (!all(final == want))
    stop("range download finished with a piece of the wrong length")
  parts
}

fetch_ranged <- function(url, dest, connections = 8L) {
  if (file.exists(dest) && file.size(dest) > 0) return(invisible(dest))
  parts <- fetch_ranged_parts(url, dest, connections)
  system(sprintf("cat %s > %s", paste(shQuote(parts), collapse = " "), shQuote(dest)))
  unlink(parts)
  invisible(dest)
}

ko_wanted <- sort(markers$accession[markers$namespace == "KO"])
ko_library <- ANNOT("profiles", "curated-ko.hmm")
if (!file.exists(ko_library)) {
  archive <- ANNOT("profiles", "kofam-profiles.tar.gz")
  fetch_ranged("https://www.genome.jp/ftp/db/kofam/profiles.tar.gz", archive)
  members <- paste0("profiles/", ko_wanted, ".hmm")
  member_file <- tempfile(); writeLines(members, member_file)
  system(sprintf("tar -xzf %s -C %s -T %s 2>/dev/null || true",
                 shQuote(archive), shQuote(ANNOT("profiles")), shQuote(member_file)))
  files <- file.path(ANNOT("profiles"), members)
  files <- files[file.exists(files)]
  system(sprintf("cat %s > %s",
                 paste(shQuote(files), collapse = " "), shQuote(ko_library)))
  unlink(ANNOT("profiles", "profiles"), recursive = TRUE)
}
ko_list_path <- cached_get("https://www.genome.jp/ftp/db/kofam/ko_list.gz",
                           file.path("annotation", "profiles", "ko_list.gz"))
# quote = "" is not cosmetic. ko_list's definition column carries apostrophes
# and quotation marks, and R's default quoting swallows a third of the table --
# 391 of the 753 curated profiles lose their threshold and are silently never
# called, which would turn a parsing bug into a reported annotation cost.
ko_list <- read.delim(gzfile(ko_list_path), stringsAsFactors = FALSE,
                      quote = "", comment.char = "")
names(ko_list)[[1]] <- "knum"
ko_list <- ko_list[ko_list$knum %in% ko_wanted, ]
ko_list$threshold <- suppressWarnings(as.numeric(ko_list$threshold))
stopifnot(all(ko_wanted %in% ko_list$knum))
kv("curated KO profiles", length(ko_wanted))
kv("of those in the library", length(grep("^NAME", readLines(ko_library, warn = FALSE))))
# A profile with no adaptive threshold is one KofamScan reports nothing for by
# default. That is a hole in the annotation route the KEGG route does not have,
# and naming it is part of the answer.
kv("curated KOs KofamScan cannot call at all",
   length(setdiff(ko_wanted, ko_list$knum[!is.na(ko_list$threshold)])))

ncbi_wanted <- markers$accession[markers$namespace %in% c("NCBIFAM", "TIGRFAM")]
pfam_wanted <- markers$accession[markers$namespace == "PFAM"]
ncbi_library <- ANNOT("profiles", "curated-ncbifam.hmm")
if (!file.exists(ncbi_library)) {
  pgap <- cached_get("https://ftp.ncbi.nlm.nih.gov/hmm/current/hmm_PGAP.tsv",
                     file.path("annotation", "profiles", "hmm_PGAP.tsv"))
  meta <- read.delim(pgap, stringsAsFactors = FALSE, quote = "", comment.char = "")
  hit <- meta[[1]][sub("[.][0-9]+$", "", meta[[1]]) %in% sub("[.][0-9]+$", "", ncbi_wanted)]
  paths <- cached_get_many(
    paste0("https://ftp.ncbi.nlm.nih.gov/hmm/current/hmm_PGAP.HMM/", hit, ".HMM"),
    file.path("annotation", "profiles", "ncbifam", paste0(hit, ".HMM")))
  system(sprintf("cat %s > %s", paste(shQuote(paths[!is.na(paths)]), collapse = " "),
                 shQuote(ncbi_library)))
  for (pf in pfam_wanted) {
    p <- cached_get(paste0("https://www.ebi.ac.uk/interpro/wwwapi//entry/pfam/", pf,
                           "?annotation=hmm"),
                    file.path("annotation", "profiles", paste0(pf, ".hmm.gz")))
    if (!is.na(p)) cat(readLines(gzfile(p), warn = FALSE), file = ncbi_library,
                       sep = "\n", append = TRUE)
  }
}
kv("NCBIfam, TIGRFAM and Pfam profiles in the library",
   length(grep("^NAME", readLines(ncbi_library, warn = FALSE))))

cazy_wanted <- markers$accession[markers$namespace == "CAZY"]
sizes_path <- ANNOT("profiles", "dbcan-library-sizes.tsv")
stream_dbcan <- function(file, wanted, dest) {
  if (file.exists(dest) && file.size(dest) > 0) return(invisible(NULL))
  want_file <- tempfile(); writeLines(wanted, want_file)
  script <- sprintf('
    BEGIN { while ((getline line < "%s") > 0) want[line] = 1 }
    /^HMMER3/ { n = 0; buf[n++] = $0; keep = 0; total++; next }
    { buf[n++] = $0 }
    /^NAME/ { name = $2; sub(/\\|.*$/, "", name); sub(/\\.hmm$/, "", name)
              if (name in want) { keep = 1; got[name] = 1 } }
    /^\\/\\/$/ { if (keep) for (i = 0; i < n; i++) print buf[i]; n = 0; keep = 0 }
    END { c = 0; for (k in got) c++; printf("%%s\\t%%d\\t%%d\\n", "%s", c, total) >> "%s" }',
    want_file, file, sizes_path)
  parts <- fetch_ranged_parts(
    paste0("https://dbcan.s3.us-west-2.amazonaws.com/", DBCAN_RELEASE, "/", file),
    paste0(dest, ".download"))
  system(sprintf("cat %s | awk %s > %s", paste(shQuote(parts), collapse = " "),
                 shQuote(script), shQuote(dest)))
  unlink(parts)
}
stream_dbcan("dbCAN.hmm", grep("_e[0-9]", cazy_wanted, value = TRUE, invert = TRUE),
             ANNOT("profiles", "dbcan-family.hmm"))
stream_dbcan("dbCAN_sub.hmm", grep("_e[0-9]", cazy_wanted, value = TRUE),
             ANNOT("profiles", "dbcan-sub.hmm"))
dbcan_sizes <- read.delim(sizes_path, header = FALSE,
                          col.names = c("library", "matched", "profiles"),
                          stringsAsFactors = FALSE)
dbcan_sizes <- dbcan_sizes[!duplicated(dbcan_sizes$library), ]
print(dbcan_sizes)
dbcan_libraries <- data.frame(
  file = c("dbcan-family.hmm", "dbcan-sub.hmm"),
  source = c("dbCAN.hmm", "dbCAN_sub.hmm"), stringsAsFactors = FALSE)
dbcan_libraries$Z <- dbcan_sizes$profiles[match(dbcan_libraries$source, dbcan_sizes$library)]
# Without the whole-library size the E-value cutoff would be computed against
# the filtered library, which is roughly two orders of magnitude smaller and
# would let hits through that a real dbCAN run rejects. Better to stop.
if (anyNA(dbcan_libraries$Z))
  stop("dbcan-library-sizes.tsv is missing a row; delete the filtered library and re-stream it")
dbcan_libraries$kept <- vapply(dbcan_libraries$file, function(lib)
  length(grep("^NAME", readLines(ANNOT("profiles", lib), warn = FALSE))), integer(1))
print(dbcan_libraries)
for (lib in dbcan_libraries$file) {
  if (!file.exists(paste0(ANNOT("profiles", lib), ".h3i")))
    system2(HMMER("hmmpress"), shQuote(ANNOT("profiles", lib)), stdout = NULL, stderr = NULL)
}

# --------------------------------------------------------------- 5. annotation
rule("5. Running the pinned pipelines")

read_tblout <- function(path) {
  empty <- data.frame(target = character(), accession = character(), query = character(),
                      score = numeric(), dom_score = numeric(), stringsAsFactors = FALSE)
  if (!file.exists(path)) return(empty)
  lines <- grep("^#", readLines(path, warn = FALSE), value = TRUE, invert = TRUE)
  lines <- lines[nzchar(trimws(lines))]
  if (!length(lines)) return(empty)
  f <- strsplit(trimws(lines), "[ \t]+")
  data.frame(target = vapply(f, `[`, character(1), 1),
             accession = vapply(f, `[`, character(1), 4),
             query = vapply(f, `[`, character(1), 3),
             score = as.numeric(vapply(f, `[`, character(1), 6)),
             dom_score = as.numeric(vapply(f, `[`, character(1), 9)),
             stringsAsFactors = FALSE)
}
# A hmmsearch domain table, where the model is the *query* and the protein is
# the target -- the opposite of hmmscan, which puts the model in column 1 and
# its length in column 3. dbCAN's coverage rule is a fraction of the model, so
# reading the wrong column silently divides by the protein length instead and
# changes which hits pass.
read_domtblout <- function(path) {
  empty <- data.frame(sequence = character(), model = character(),
                      model_length = numeric(), i_evalue = numeric(),
                      hmm_from = numeric(), hmm_to = numeric(),
                      stringsAsFactors = FALSE)
  if (!file.exists(path)) return(empty)
  lines <- grep("^#", readLines(path, warn = FALSE), value = TRUE, invert = TRUE)
  lines <- lines[nzchar(trimws(lines))]
  if (!length(lines)) return(empty)
  f <- strsplit(trimws(lines), "[ \t]+")
  data.frame(sequence = vapply(f, `[`, character(1), 1),
             model = vapply(f, `[`, character(1), 4),
             model_length = as.numeric(vapply(f, `[`, character(1), 6)),
             i_evalue = as.numeric(vapply(f, `[`, character(1), 13)),
             hmm_from = as.numeric(vapply(f, `[`, character(1), 16)),
             hmm_to = as.numeric(vapply(f, `[`, character(1), 17)),
             stringsAsFactors = FALSE)
}

# One search at the lowest curated threshold, then each profile's own threshold
# applied to the score type ko_list names for it. A full sequence score is never
# below the best domain score of the same comparison, so one floor on the former
# cannot lose a hit the latter would have kept.
ko_floor <- floor(min(ko_list$threshold, na.rm = TRUE)) - 1
kv("KofamScan reporting floor (lowest curated threshold)", ko_floor)

annotate <- function(org, proteome) {
  dest <- ANNOT("hmm", paste0(org, ".rds"))
  if (file.exists(dest)) return(readRDS(dest))
  faa <- tempfile(fileext = ".faa")
  system(sprintf("gunzip -c %s > %s", shQuote(proteome), shQuote(faa)))
  tbl <- tempfile()

  system2(HMMER("hmmsearch"), c("--noali", "--cpu", threads, "-T", ko_floor,
                                "--tblout", shQuote(tbl), shQuote(ko_library), shQuote(faa)),
          stdout = NULL, stderr = NULL)
  ko <- read_tblout(tbl)
  if (nrow(ko)) {
    ko$threshold <- ko_list$threshold[match(ko$query, ko_list$knum)]
    ko$score_type <- ko_list$score_type[match(ko$query, ko_list$knum)]
    ko <- ko[!is.na(ko$threshold) &
               ifelse(ko$score_type == "domain", ko$dom_score, ko$score) >= ko$threshold, ]
  }

  system2(HMMER("hmmsearch"), c("--noali", "--cpu", threads, "--cut_ga",
                                "--tblout", shQuote(tbl), shQuote(ncbi_library), shQuote(faa)),
          stdout = NULL, stderr = NULL)
  nf <- read_tblout(tbl)

  # run_dbcan drives these libraries with hmmscan; hmmsearch is the same
  # comparison with the operands the other way round, and with -Z pinned to the
  # whole library it reports the same bit scores and the same independent
  # E-values. Verified to return an identical filtered hit set on both
  # libraries, at about an eighth of the run time -- which is the difference
  # between a five-hour pass over the genome set and a one-hour one.
  cazy <- do.call(rbind, lapply(seq_len(nrow(dbcan_libraries)), function(i) {
    dom <- tempfile()
    system2(HMMER("hmmsearch"), c("--noali", "--cpu", threads,
                                  "-Z", format(dbcan_libraries$Z[[i]], scientific = FALSE),
                                  "--domtblout", shQuote(dom),
                                  shQuote(ANNOT("profiles", dbcan_libraries$file[[i]])),
                                  shQuote(faa)), stdout = NULL, stderr = NULL)
    d <- read_domtblout(dom); unlink(dom)
    if (!nrow(d)) return(NULL)
    d$coverage <- (d$hmm_to - d$hmm_from) / d$model_length
    d <- d[d$i_evalue < 1e-15 & d$coverage > 0.35, ]
    if (!nrow(d)) NULL else d
  }))

  rows <- rbind(
    if (nrow(ko)) data.frame(namespace = "KO", accession = ko$query,
                             gene_id = ko$target, stringsAsFactors = FALSE),
    # NCBIfam profiles carry their accession in the tblout accession column and
    # a human-readable label in the name column; the accession is the identity
    # gifter curated, so it is the one that is read.
    if (nrow(nf)) data.frame(namespace = ifelse(grepl("^PF", nf$accession), "PFAM", "NCBIFAM"),
                             accession = sub("[.][0-9]+$", "", nf$accession),
                             gene_id = nf$target, stringsAsFactors = FALSE),
    if (!is.null(cazy) && nrow(cazy))
      data.frame(namespace = "CAZY",
                 accession = sub("[.]hmm$", "", sub("[|].*$", "", cazy$model)),
                 gene_id = cazy$sequence, stringsAsFactors = FALSE))
  if (is.null(rows))
    rows <- data.frame(namespace = character(), accession = character(), gene_id = character(),
                       stringsAsFactors = FALSE)
  unlink(c(faa, tbl))
  saveRDS(rows, dest)
  rows
}

# HMMER's threads scale sub-linearly, so three genomes on two threads each
# finish sooner than one genome on six. Forking is safe here only because the
# database handle is closed first: a child that inherits an open SQLite
# connection aborts the session with no traceback, which is the failure
# _common.R documents and 01-marker-matrix.R avoids by staying serial. Nothing
# between here and the reconnection touches the database.
dbDisconnect(con)
started <- Sys.time()
done <- 0L
annotate_reporting <- function(i) {
  rows <- annotate(selection$org[[i]], selection$proteome[[i]])
  if (!nrow(rows)) return(NULL)
  data.frame(genome_id = selection$org[[i]], rows, stringsAsFactors = FALSE)
}
chunks <- split(seq_len(nrow(selection)), ceiling(seq_len(nrow(selection)) / 24))
parts <- list()
for (k in seq_along(chunks)) {
  parts <- c(parts, parallel::mclapply(chunks[[k]], annotate_reporting,
                                       mc.cores = workers, mc.preschedule = FALSE))
  done <- done + length(chunks[[k]])
  message("  annotated ", done, "/", nrow(selection), "  (",
          round(difftime(Sys.time(), started, units = "mins")), " min)")
}
# mclapply reports a child that died as a try-error rather than stopping, and a
# silently dropped genome would shrink a denominator nobody chose.
failed <- vapply(parts, function(x) inherits(x, "try-error"), logical(1))
if (any(failed)) stop(sum(failed), " genomes failed to annotate")
con <- gifter_db()
annotated <- do.call(rbind, parts[!vapply(parts, is.null, logical(1))])
kv("marker observations, annotation route", nrow(annotated))
print(table(annotated$namespace))

# Restore the exact identity gifter curated, namespace included. The suffix is
# what separates the two profile namespaces -- a bare TIGR03948 is the
# unversioned TIGRFAM identity, TIGR04545.1 is the same library's profile as the
# pinned NCBIfam release publishes it -- so neither the accession nor the
# namespace may be guessed from the search output. Both come from the marker
# table, keyed on the version-stripped accession, which is unique across the
# curated profile namespaces.
curated <- markers[markers$namespace %in% c("NCBIFAM", "TIGRFAM", "PFAM"), ]
curated$base <- sub("[.][0-9]+$", "", curated$accession)
stopifnot(!any(duplicated(curated$base)))
profile_row <- match(sub("[.][0-9]+$", "", annotated$accession), curated$base)
hit <- !is.na(profile_row) & annotated$namespace %in% c("NCBIFAM", "PFAM")
annotated$namespace[hit] <- curated$namespace[profile_row[hit]]
annotated$accession[hit] <- curated$accession[profile_row[hit]]
kv("profile hits resolved to a curated marker", sum(hit))

# ------------------------------------------------------------ 6. the three routes
rule("6. Calls under each route")

kos <- sort(unique(markers$accession[markers$namespace == "KO"]))
kegg <- kegg_annotation_table(kos)
kegg <- kegg[kegg$genome_id %in% selection$org, ]
kv("marker observations, KEGG route", nrow(kegg))

call_table <- function(annotation, label) {
  orgs <- sort(unique(selection$org))
  parts <- list()
  chunks <- split(orgs, ceiling(seq_along(orgs) / 200))
  for (i in seq_along(chunks)) {
    subset <- annotation[annotation$genome_id %in% chunks[[i]], ]
    if (!nrow(subset)) next
    community <- evaluate_gifts_community(subset, genome_id = "genome_id",
                                          gene_id = "gene_id", max_genes = Inf,
                                          workers = 1L)
    parts[[length(parts) + 1]] <- do.call(rbind, lapply(names(community$results), function(g) {
      row <- community$results[[g]]$gifts
      data.frame(route = label, org = g, gift_id = row$gift_id, complete = row$complete,
                 confidence = row$evidence_confidence,
                 missing = row$minimum_missing_requirements, stringsAsFactors = FALSE)
    }))
    rm(community); gc(FALSE)
    message("  ", label, " chunk ", i, "/", length(chunks))
  }
  do.call(rbind, parts)
}

calls <- rbind(
  call_table(kegg[, c("genome_id", "namespace", "accession", "gene_id")], "kegg_ko"),
  call_table(annotated[annotated$namespace == "KO", ], "annot_ko"),
  call_table(annotated, "annot_full"))

gifts <- dbGetQuery(con, "select gift_id, gift_type, mode, name from gift")
complete <- function(route) {
  x <- calls[calls$route == route & calls$complete, ]
  setNames(as.integer(table(factor(x$gift_id, levels = gifts$gift_id))), gifts$gift_id)
}
per_gift <- data.frame(
  gifts,
  genomes = nrow(selection),
  kegg_ko = complete("kegg_ko"),
  annot_ko = complete("annot_ko"),
  annot_full = complete("annot_full"), stringsAsFactors = FALSE)
per_gift$annotation_cost <- per_gift$annot_ko - per_gift$kegg_ko
per_gift$namespace_gain  <- per_gift$annot_full - per_gift$annot_ko
per_gift$net             <- per_gift$annot_full - per_gift$kegg_ko

cat("\n  Calls over ", nrow(selection), " genomes, totalled over the catalogue:\n", sep = "")
kv("kegg_ko", sum(per_gift$kegg_ko))
kv("annot_ko", sum(per_gift$annot_ko))
kv("annot_full", sum(per_gift$annot_full))
kv("retained by the annotation route, KO only",
   sprintf("%.3f", sum(per_gift$annot_ko) / sum(per_gift$kegg_ko)))
kv("retained once every namespace is read",
   sprintf("%.3f", sum(per_gift$annot_full) / sum(per_gift$kegg_ko)))

cat("\n  GIFTs the annotation route calls in most fewer genomes:\n")
print(head(per_gift[order(per_gift$annotation_cost),
                    c("gift_id", "kegg_ko", "annot_ko", "annot_full", "annotation_cost")], 12),
      row.names = FALSE)
cat("\n  GIFTs the non-KO namespaces recover, which the KEGG route cannot see:\n")
print(head(per_gift[order(-per_gift$namespace_gain),
                    c("gift_id", "kegg_ko", "annot_ko", "annot_full", "namespace_gain")], 12),
      row.names = FALSE)

# ------------------------------------------------- 7. the same recall, per route
rule("7. Recall on the matched test set, per route")

reaction_targets <- unique(obs$target[obs$layer == "reaction"])
reaction_calls <- function(annotation, label) {
  parts <- list()
  for (g in sort(unique(selection$org))) {
    rows <- annotation[annotation$genome_id == g, ]
    if (!nrow(rows)) next
    res <- evaluate_reactions(rows[, c("namespace", "accession")])$reactions
    res <- res[res$reaction_id %in% reaction_targets, ]
    if (nrow(res)) parts[[length(parts) + 1]] <-
      data.frame(route = label, org = g, reaction_id = res$reaction_id,
                 supported = res$supported, stringsAsFactors = FALSE)
  }
  message("  ", label, ": reaction layer done")
  do.call(rbind, parts)
}
reactions <- rbind(
  reaction_calls(kegg[, c("genome_id", "namespace", "accession", "gene_id")], "kegg_ko"),
  reaction_calls(annotated[annotated$namespace == "KO", ], "annot_ko"),
  reaction_calls(annotated, "annot_full"))

matched <- obs[obs$org %in% selection$org, ]
kv("observations on the matched genome set", nrow(matched))

summaries <- list()
for (route in c("kegg_ko", "annot_ko", "annot_full")) {
  gl <- setNames(calls$complete[calls$route == route],
                 paste(calls$org[calls$route == route], calls$gift_id[calls$route == route]))
  rl <- setNames(reactions$supported[reactions$route == route],
                 paste(reactions$org[reactions$route == route],
                       reactions$reaction_id[reactions$route == route]))
  part <- matched
  part$call <- ifelse(part$layer == "reaction", rl[paste(part$org, part$target)],
                      gl[paste(part$org, part$target)])
  part$call[is.na(part$call)] <- FALSE
  part$call <- as.logical(part$call)
  for (i in unique(part$row)) {
    rows <- part[part$row == i, ]
    r <- crosswalk[i, ]
    a <- agreement(rows$call, rows$observed, polarity = r$polarity)
    summaries[[length(summaries) + 1]] <- data.frame(
      route = route, term = r$source_label, layer = r$layer, target = r$target_id,
      relation = r$relation, recall_usable = r$recall_usable,
      n = a$n, both_positive = a$concordant_positive,
      encoded_not_observed = a$encoded_not_observed,
      observed_not_encoded = a$observed_not_encoded,
      recall = round(a$recall, 3),
      genera = length(unique(lineage[rows$org])), stringsAsFactors = FALSE)
  }
}
route_agreement <- do.call(rbind, summaries)

wide <- reshape(route_agreement[route_agreement$recall_usable,
                                c("target", "term", "layer", "n", "route", "recall")],
                idvar = c("target", "term", "layer", "n"), timevar = "route", direction = "wide")
names(wide) <- sub("^recall[.]", "", names(wide))
wide <- wide[order(-wide$n), ]
cat("\n  Recall per target, same test set, three routes:\n\n")
print(wide[wide$n >= 20, ], row.names = FALSE)

# --------------------------------------------- 8. the anabolic half, per route
rule("8. The anabolic half, per route")

# 04-auxotrophy.R excludes frame members no KO can evidence, because on a
# KO-only genome set testing them would measure the reference rather than
# gifter. That exclusion is deliberately lifted here: what those members do
# under an annotator that reads NCBIfam and dbCAN is the question this script
# was written to answer, and removing them would remove the answer.
frame <- dbGetQuery(con, "
  select p.gift_id, p.substrate_class, a.anchor_id, a.chebi_id
  from gift_profile p
  join gift g on g.gift_id = p.gift_id
  join gift_anchor ga on ga.gift_pk = g.gift_pk and ga.role = 'output'
  join anchor a on a.anchor_pk = ga.anchor_pk
  where p.auxotrophy_indicator = 1 and p.mode = 'anabolic'")
voids <- crosswalk[crosswalk$relation == "voids", ]
medium_anchors <- lapply(composition, function(ing) {
  chebi <- unname(ingredient_chebi[ing]); chebi <- chebi[!is.na(chebi)]
  unique(c(chebi, resolve_chebi(alias, chebi)))
})
medium_voids <- lapply(composition, function(ing) voids$target_id[voids$source_id %in% ing])

anabolic_tests <- function(route) {
  lookup <- setNames(calls$complete[calls$route == route],
                     paste(calls$org[calls$route == route], calls$gift_id[calls$route == route]))
  rows <- list()
  pairs <- growth[growth$org %in% selection$org, ]
  for (i in seq_len(nrow(pairs))) {
    p <- pairs[i, ]
    anchors <- medium_anchors[[p$medium]]
    voided <- medium_voids[[p$medium]]
    for (j in seq_len(nrow(frame))) {
      f <- frame[j, ]
      if (!is.null(anchors) && f$chebi_id %in% anchors) next
      if (length(voided) && ("biomass_essential_anabolism" %in% voided ||
                             paste0(f$substrate_class, "_autonomy") %in% voided)) next
      siblings <- frame$gift_id[frame$chebi_id == f$chebi_id]
      rows[[length(rows) + 1]] <- data.frame(
        route = route, org = p$org, medium = p$medium, nutrient = f$anchor_id,
        substrate_class = f$substrate_class,
        # Single-bracket lookup on purpose: a genome that carries no curated
        # marker at all under this route never reaches the call table, and
        # `[[` on the missing name would abort the run rather than record the
        # unsupported call that absence actually means.
        call = any(vapply(siblings, function(g)
          isTRUE(unname(lookup[paste(p$org, g)])), logical(1))),
        stringsAsFactors = FALSE)
    }
  }
  out <- do.call(rbind, rows)
  out[!duplicated(paste(out$org, out$medium, out$nutrient)), ]
}
anabolic_route <- do.call(rbind, lapply(c("kegg_ko", "annot_ko", "annot_full"), anabolic_tests))
essential <- anabolic_route[anabolic_route$substrate_class %in% c("amino_acid", "nucleotide"), ]
for (route in c("kegg_ko", "annot_ko", "annot_full")) {
  part <- essential[essential$route == route, ]
  cat("\n  ", route, ", biomass-essential classes:\n", sep = "")
  print(agreement(part$call, rep(TRUE, nrow(part))))
}
histidine <- anabolic_route[anabolic_route$nutrient == "HISTIDINE", ]
if (nrow(histidine)) {
  cat("\n  HISTIDINE, the class database 2026.25.1 curated NCBIfam evidence for:\n")
  print(aggregate(call ~ route, histidine, function(x) c(n = length(x), supported = sum(x))))
}

# ------------------------------------------------------------------ 9. outputs
rule("9. Writing")

marker_reach <- merge(
  aggregate(genome_id ~ namespace + accession, annotated, function(x) length(unique(x))),
  aggregate(genome_id ~ accession, kegg, function(x) length(unique(x))),
  by = "accession", all = TRUE, suffixes = c("_annotation", "_kegg"))
names(marker_reach) <- sub("genome_id", "genomes", names(marker_reach))

write.table(selection[, c("org", "name", "binomial", "taxid", "assembly", "half", "directory")],
            file.path(out_dir, "annotation-route-genomes.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
write.table(marker_reach, file.path(out_dir, "annotation-route-markers.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
write.table(per_gift, file.path(out_dir, "annotation-route-calls.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
write.table(route_agreement, file.path(out_dir, "annotation-route-agreement.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
kv("annotation-route-genomes.tsv", nrow(selection))
kv("annotation-route-markers.tsv", nrow(marker_reach))
kv("annotation-route-calls.tsv", nrow(per_gift))
kv("annotation-route-agreement.tsv", nrow(route_agreement))

cat("\n  Pinned: KOfam ", basename(ko_list_path), ", NCBIfam hmm_PGAP current, dbCAN ",
    DBCAN_RELEASE, ",\n  ", system2(HMMER("hmmsearch"), "-h", stdout = TRUE)[[2]], "\n", sep = "")
