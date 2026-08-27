#!/usr/bin/env Rscript
# R9, the anabolic half: defined growth media against the bounded frames.
#
# Nothing in BacDive's substrate records or the Madin synthesis says anything
# about the 67 anabolic GIFTs -- 44% of the catalogue, and the part where a
# quantitative claim is made against a frame that curation declares complete.
# Growth media do, and the reasoning is one sentence: a strain that grows on a
# chemically defined medium containing no L-tryptophan makes its own
# L-tryptophan.
#
# One observation therefore tests every anabolic GIFT whose product the medium
# omits -- in practice all 44 members of biomass_essential_anabolism at once.
# Where the medium does supply a nutrient the test is **void**, not negative,
# and the ingredient list says which. That per-nutrient denominator is the same
# discipline the frame layer already enforces.
#
# It is also the only external check on a gifter *number*: a strain growing on a
# mineral medium should score 1.0 on the bounded amino_acid_autonomy frame, and
# every point below 1.0 is a named, traceable, falsified call.
#
# One correction to the assessment, found by running this. MediaDive records the
# media a strain grows on and nothing else -- every medium-strain row carries
# growth = 1. So this does NOT invert the polarity the way the assessment
# expected: there is no observed auxotrophy here, only observed prototrophy, and
# the falsifiable cell is still the unsupported call. The inverted direction --
# an organism that cannot grow without a nutrient whose biosynthesis gifter
# calls complete -- needs an auxotrophy panel, and none of the adopted sources
# has one. What MediaDive buys instead is leverage: one growth observation
# yields tens of GIFT-level tests.
#
# Usage:
#   Rscript manuscript/analysis/04-auxotrophy.R [--bacdive-max=180000]

source("manuscript/analysis/_common.R")
suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
opt <- function(name, default) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit) == 0) default else sub(paste0("^--", name, "="), "", hit[[1]])
}
bacdive_max <- as.integer(opt("bacdive-max", "180000"))
out_dir <- "manuscript/analysis/output"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

con <- gifter_db()
crosswalk <- read_phenotype_crosswalk(con)
alias     <- read_chebi_aliases()

# ------------------------------------------------------------ 1. the frame
rule("1. The bounded frame under test")
frame <- dbGetQuery(con, "
  select p.gift_id, p.substrate_class, a.anchor_id, a.chebi_id, a.name
  from gift_profile p
  join gift g on g.gift_id = p.gift_id
  join gift_anchor ga on ga.gift_pk = g.gift_pk and ga.role = 'output'
  join anchor a on a.anchor_pk = ga.anchor_pk
  where p.auxotrophy_indicator = 1 and p.mode = 'anabolic'")
kv("frame members with an output anchor", nrow(frame))
print(table(frame$substrate_class))

# A GIFT with a component no KO can evidence cannot be called on this genome
# set at all, so testing it here measures the reference set rather than gifter.
# siroheme_to_heme_b is the clearest case: it is unsupported in every one of the
# 11 908 genomes because its evidence is NCBIfam.
ko_ceiling <- dbGetQuery(con, "
  select distinct g.gift_id from gift g
  join gift_route gr on gr.gift_pk = g.gift_pk
  join route_reaction rr on rr.route_pk = gr.route_pk
  join enzyme_system es on es.reaction_pk = rr.reaction_pk
  join enzyme_component ec on ec.system_pk = es.system_pk
  where not exists (
    select 1 from component_marker cm join marker m on m.marker_pk = cm.marker_pk
    where cm.component_pk = ec.component_pk and m.namespace = 'KO')")$gift_id
excluded <- intersect(frame$gift_id, ko_ceiling)
frame <- frame[!frame$gift_id %in% excluded, ]
kv("excluded: no KO can evidence a component", paste(excluded, collapse = ", "))
kv("frame members testable on this genome set", nrow(frame))

# ------------------------------------------------------------- 2. MediaDive
rule("2. MediaDive")
media_path <- cached_get("https://mediadive.dsmz.de/rest/media", "mediadive/media.json")
media <- fromJSON(media_path)$data
defined <- media[media$complex_medium == 0, ]
kv("media", nrow(media))
kv("chemically defined", nrow(defined))

ing_path <- cached_get("https://mediadive.dsmz.de/rest/ingredients", "mediadive/ingredients.json")
ingredients <- fromJSON(ing_path)$data
ingredient_chebi <- setNames(
  ifelse(is.na(ingredients$ChEBI), NA_character_, paste0("CHEBI:", ingredients$ChEBI)),
  as.character(ingredients$id))
kv("ingredients", nrow(ingredients))
kv("of those carrying a ChEBI identifier", sum(!is.na(ingredient_chebi)))

ids <- as.character(defined$id)
invisible(cached_get_many(paste0("https://mediadive.dsmz.de/rest/medium-composition/", ids),
                          file.path("mediadive", "composition", paste0(ids, ".json"))))
invisible(cached_get_many(paste0("https://mediadive.dsmz.de/rest/medium-strains/", ids),
                          file.path("mediadive", "strains", paste0(ids, ".json"))))

read_rows <- function(kind, id) {
  path <- cache_path(file.path("mediadive", kind, paste0(id, ".json")))
  if (!file.exists(path)) return(NULL)
  d <- tryCatch(fromJSON(path), error = function(e) NULL)
  if (is.null(d) || is.null(d$data) || !length(d$data)) return(NULL)
  d$data
}

composition <- list(); pairs <- list()
for (id in ids) {
  comp <- read_rows("composition", id)
  if (!is.null(comp)) composition[[id]] <- as.character(comp$id)
  st <- read_rows("strains", id)
  if (!is.null(st) && !is.null(st$bacdive_id))
    pairs[[length(pairs) + 1]] <- data.frame(
      medium = id, bacdive_id = as.character(st$bacdive_id),
      growth = st$growth, stringsAsFactors = FALSE)
}
pairs <- do.call(rbind, pairs)
pairs <- pairs[!is.na(pairs$bacdive_id) & pairs$growth == 1, ]
kv("defined media with a composition", length(composition))
kv("growth-positive strain-medium pairs", nrow(pairs))
kv("distinct strains", length(unique(pairs$bacdive_id)))

# --------------------------------------------------- 3. strains to genomes
rule("3. Strain to genome")
genome_set <- read.delim(file.path(out_dir, "kegg-genome-set.tsv"), stringsAsFactors = FALSE)
genome_set$assembly_base <- sub("[.].*", "", genome_set$assembly)
observed <- bacdive_reduce(seq_len(bacdive_max), list(assemblies = bd_assemblies))
asm <- observed$assemblies
asm <- asm[!is.na(asm$assembly), ]
asm$assembly_base <- sub("[.].*", "", asm$assembly)
asm <- asm[order(asm$bacdive_id, -asm$score), ]
asm <- asm[!duplicated(asm$bacdive_id), ]
joined <- merge(asm, genome_set[, c("org", "assembly_base", "binomial")], by = "assembly_base")
joined <- joined[!joined$org %in% joined$org[duplicated(joined$org)], ]
strain_genome <- setNames(joined$org, joined$bacdive_id)

pairs$org <- unname(strain_genome[pairs$bacdive_id])
pairs <- pairs[!is.na(pairs$org), ]
kv("pairs whose strain has a reference genome", nrow(pairs))
kv("distinct genomes", length(unique(pairs$org)))
if (!nrow(pairs)) {
  cat("\nNo defined-medium strain reaches the KEGG genome set. That is the\n",
      "result: MediaDive's defined media are dominated by anaerobes,\n",
      "halophiles and phototrophs, and those lineages are thin in KEGG.\n", sep = "")
  quit(save = "no")
}

# ------------------------------------------------ 4. what each medium supplies
rule("4. What each medium supplies")
# A nutrient counts as supplied when an ingredient resolves, through the curated
# alias table, to the anchor a GIFT produces. Anything that does not resolve is
# treated as not supplying that nutrient, which is the conservative reading: it
# can only make a test happen, never make one pass.
voids <- crosswalk[crosswalk$relation == "voids", ]
medium_anchors <- lapply(composition, function(ing) {
  chebi <- unname(ingredient_chebi[ing])
  chebi <- chebi[!is.na(chebi)]
  unique(c(chebi, resolve_chebi(alias, chebi)))
})
medium_voids <- lapply(composition, function(ing) voids$target_id[voids$source_id %in% ing])

# How much of a medium this can actually read decides whether its silence about
# a nutrient means anything. Only 687 of 1244 MediaDive ingredients carry a
# ChEBI identifier at all, and a salt is not its ion -- NH4Cl does not resolve
# to the AMMONIUM anchor. A medium whose composition is mostly unreadable
# cannot support the inference "this nutrient is absent", so it is dropped
# rather than counted, and the threshold is stated rather than assumed.
resolution <- vapply(names(composition), function(id) {
  ing <- composition[[id]]
  if (!length(ing)) return(0)
  mean(!is.na(ingredient_chebi[ing]))
}, numeric(1))
readable <- names(resolution)[resolution >= 0.75]
kv("median ingredient resolution per defined medium", round(median(resolution), 2))
kv("media at least 75% readable", length(readable))

supplied <- vapply(medium_anchors, length, integer(1))
kv("median resolved ingredients per defined medium", median(supplied))
kv("media supplying at least one frame anchor",
   sum(vapply(medium_anchors, function(a) any(frame$chebi_id %in% a), logical(1))))
kv("media carrying a void ingredient", sum(lengths(medium_voids) > 0))

# ------------------------------------------------------------- 5. the tests
rule("5. Tests")
calls <- readRDS(cache_path("gift-calls-kegg.rds"))
call_lookup <- setNames(calls$complete, paste(calls$org, calls$gift_id))

tests <- list()
pairs <- pairs[pairs$medium %in% readable, ]
kv("pairs on a readable medium", nrow(pairs))
if (!nrow(pairs)) { cat("\nNo readable defined medium reaches the genome set.\n"); quit(save = "no") }

for (i in seq_len(nrow(pairs))) {
  p <- pairs[i, ]
  anchors <- medium_anchors[[p$medium]]
  voided <- medium_voids[[p$medium]]
  for (j in seq_len(nrow(frame))) {
    f <- frame[j, ]
    # Supplied nutrient: no test. Voided frame: no test. Neither is a negative.
    if (!is.null(anchors) && f$chebi_id %in% anchors) next
    if (length(voided) && ("biomass_essential_anabolism" %in% voided ||
                           paste0(f$substrate_class, "_autonomy") %in% voided)) next
    # The unit of the question is the nutrient, not the GIFT. Cysteine has two
    # curated routes and an organism needs one; testing each separately
    # guarantees that whichever it does not use is scored a failure. Members
    # sharing an output anchor are therefore OR-ed, which is the same Boolean
    # the evaluator uses one layer down.
    siblings <- frame$gift_id[frame$chebi_id == f$chebi_id]
    call <- any(vapply(siblings, function(g)
      isTRUE(call_lookup[[paste(p$org, g)]]), logical(1)))
    tests[[length(tests) + 1]] <- data.frame(
      org = p$org, medium = p$medium, nutrient = f$anchor_id,
      gift_id = paste(siblings, collapse = "|"),
      substrate_class = f$substrate_class,
      call = call, stringsAsFactors = FALSE)
  }
}
tests <- do.call(rbind, tests)
tests <- tests[!duplicated(paste(tests$org, tests$medium, tests$nutrient)), ]
kv("nutrient-level tests", nrow(tests))
kv("distinct genomes", length(unique(tests$org)))

# Growth without the nutrient means the organism makes it, so every row here is
# an observed positive and the statistic is recall.
a <- agreement(tests$call, rep(TRUE, nrow(tests)), polarity = "necessary")
cat("\n")
print(a)

per_gift <- aggregate(call ~ nutrient + gift_id + substrate_class, tests, function(x) c(n = length(x), hit = sum(x)))
per_gift <- data.frame(per_gift[, c("nutrient", "gift_id", "substrate_class")],
                       n = per_gift$call[, "n"], supported = per_gift$call[, "hit"])
per_gift$recall <- round(per_gift$supported / per_gift$n, 3)
per_gift <- per_gift[order(per_gift$recall), ]
cat("\n  weakest anabolic calls under this test:\n")
print(head(per_gift[, c("nutrient", "substrate_class", "n", "supported", "recall")], 14),
      row.names = FALSE)

# The premise -- grows without it, therefore makes it -- holds only for a
# nutrient the organism actually requires. Amino acids and nucleotides are
# biomass-essential in every bacterium; menaquinone, siroheme and DMB are not,
# and neither nitrogen fixation nor nitrate assimilation is required by an
# organism given ammonium. Those classes are reported and excluded from the
# headline, because a low rate there is a false premise rather than a failed
# call.
essential <- tests[tests$substrate_class %in% c("amino_acid", "nucleotide"), ]
cat("\n  Restricted to biomass-essential classes, where the premise holds:\n")
print(agreement(essential$call, rep(TRUE, nrow(essential))))

# ------------------------------------------------- 6. the frame-level number
rule("6. The frame proportion, which is what R4 claims")
frames <- c(amino_acid = "amino_acid", cofactor = "cofactor", nucleotide = "nucleotide")
for (cls in frames) {
  part <- tests[tests$substrate_class == cls, ]
  if (!nrow(part)) next
  per_genome <- aggregate(call ~ org, part, function(x) sum(x) / length(x))
  kv(paste0(cls, "_autonomy: genomes tested"), nrow(per_genome))
  kv("  median proportion supported", round(median(per_genome$call), 3))
  kv("  genomes scoring a full 1.0", sum(per_genome$call == 1))
}
cat("\n  A strain growing on a medium that supplies none of these should score\n",
    "  1.0. Every point below is a named, traceable, falsified anabolic call.\n", sep = "")

rule("7. Writing")
write.table(per_gift, file.path(out_dir, "auxotrophy-agreement.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
write.table(tests[!tests$call, ], file.path(out_dir, "auxotrophy-disagreements.tsv"),
            sep = "\t", quote = FALSE, row.names = FALSE, na = "")
kv("auxotrophy-agreement.tsv", nrow(per_gift))
kv("auxotrophy-disagreements.tsv", sum(!tests$call))
