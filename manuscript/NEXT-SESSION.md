# Manuscript handoff — active work only

Database 2026.30.1, schema 7, has 156 GIFTs. R7, R9 and R10 are complete and
their analysis, outputs and Figures 6, 7, 8, S3 and S5 are present. Do not repeat
those tasks: the current `manuscript.md`, `manuscript/analysis/README.md`, the R10
case-study directory and `inst/doc/proposal-phenotype-validation.md` are the
source of truth.

## Current priorities

1. **Monitor the active Microflora Danica environmental run.** Mjolnir
   acquisition job `45837109` and detached screen `r10-mfd-drakkar` implement
   the locked 5,518-representative × 360-sample R10b workflow under
   `manuscript/analysis/r10-mfd/`. Run `monitor-and-fetch.sh`; it will fetch and
   verify the transfer and launch `25-r10-mfd.R` only after Drakkar succeeds.
   Do not write habitat results before those generated tables exist.
2. **Write R6.1 from the evaluated GTDB R232 phylogenetic panel.** Drakkar
   annotation and evaluation finished on 2026-10-04 for the 696 selected
   complete assemblies, and Figure S4 is drawn. They are
   all tips in the main bac120 tree, each
   have at least one reviewed origin-group assignment, and all retain raw origin
   metadata plus BioSample/BioProject identifiers. The transfer is fetched and
   checksum-verified under `manuscript/analysis/.cache/gtdb-phylogeny/drakkar/`.
   Replace the pending R6.1 language with results from the
   `analysis/output/gtdb-phylogeny-*` tables and Figure S4, and from the
   follow-ups (`26-gtdb-repertoire-genome-size.R`,
   `27-gtdb-size-signal-and-gift-classes.R`,
   `28-gtdb-origin-and-annotations.R` and
   `29-gtdb-near-misses-and-gift-signal.R` and `30-gtdb-near-miss-steps.R`,
   Figures S9 to S18). `gtdb-near-miss-steps.tsv` is also a ranked list of
   curation candidates, each read as same-step, varying-step or shared-steps;
   deciding between an uncurated alternative and a failing marker needs the
   sub-threshold KOfam hits still on Mjolnir. The most frequent candidate,
   indole-3-acetate biosynthesis, is not a real one: its present step rests on
   the generic amidase K01426, which the sharing rule cannot see because the
   marker is accepted only once. That marker deserves a specificity review.
   The full to-do list for polishing GIFT definitions from these analyses is
   `inst/doc/assessment-gtdb-near-miss-leads.md` (attempt
   `GEA-20261004-GTDB-NEAR-MISS-SCREEN`).
3. **Decide how R10 reports the size reading.** `31-r10-size-expectation.R`
   applies the GTDB size expectation to the chicken MAGs (Figure S19, tables
   `r10-size-expectation-*`). Genome size reproduces about two thirds of the
   fall in per-MAG repertoire (80% among MAGs at least 90% complete); the
   anabolic frames fall about twice as far as size predicts; and the turnover
   is between orders, not phyla. No prose is written yet. The analysis stands
   on database 2026.37.1, R10 on 2026.30.1, so the contrasts differ slightly
   (-7.13 and -9.32 against -6.77 and -8.83): either state both or re-run R10
   on one database before quoting them together. The deviation rises with MAG
   completeness (Spearman 0.63), so quote the high-completeness variant beside
   the primary one.
4. **Run R8, the controlled comparison of abstractions.** Choose the common
   genome subset and pin the KEGG-module and DRAM versions/parameters before
   writing results. Analyse disagreement causes; do not frame this as a
   benchmark with a winner.
5. **Make submission decisions explicitly.** Select Microbiome or mSystems,
   settle author contributions, and decide the software/database DOI policy.
   A DOI remains an external release action; do not invent one.

## Decisions recorded

- **2026-10-03T06:33:00Z — R10b uses a locked Microflora Danica environmental
  panel.** All 5,518 deposited 95% ANI secondary-cluster representatives are
  selected independently of annotations. Eight exact atlas habitat classes
  contribute 45 samples each after requiring a published abundance column,
  reliable coordinates and no repeated 10-km cell within class; deterministic
  geographic maximin selection yields 360 samples. Published non-dereplicated
  MAG abundances will be summed by secondary cluster before being attached to
  the representative. The Mjolnir run uses Drakkar 2.6.6 and an archived copy
  of gifter database 2026.33.1. Habitat, abundance, detection and completeness
  cannot change calls. Evidence: `25-r10-mfd.R`, `r10-mfd/design-audit.tsv`,
  acquisition job `45837109` and detached screen `r10-mfd-drakkar`. The complete
  archive index contains four barcoded-name omissions paired one-to-one with
  four `unknown_ilm_asm_binN.fa` members; the explicit crosswalk is checksum
  pinned and every extracted representative must reproduce its published
  sequence length before annotation.

- **2026-10-03T05:01:07Z — R10 temporal interpretation is made at the curated
  reference-frame level.** All 19 database-defined frames are read from the
  audited calls without creating composite GIFTs. Stability requires
  equivalence within one GIFT for count metrics or five percentage points for
  bounded coverage at all four detection thresholds. Fifteen community unions
  are stable and amino-acid and nucleotide autonomy are invariant; aromatic
  catabolism and carbon acquisition are detection-sensitive. Mean per-MAG
  repertoires decline outside the count margin for amino-acid autonomy,
  biomass-essential anabolism and vitamin biosynthesis at both later ages at
  the operational threshold. Carbon acquisition at day 35 is age-associated,
  but its interval crosses the one-GIFT margin and leaves its magnitude
  uncertain. Figure S6 shows the corresponding population-standardised values
  at days 7, 21 and 35; its lines connect model estimates rather than individual
  birds. Figure S7 resolves the three clear decreases to member-GIFT carrier
  prevalence without per-GIFT testing; carrier fractions sum exactly to their
  frame metric per sample. Figure S8 shows that carrier-abundance weighting
  retains all six negative associations and five of six larger-than-margin
  conclusions; vitamin biosynthesis at day 21 becomes magnitude-uncertain.
  Evidence: `24-r10-reference-frame-time.R` and Figures S5--S8.

- **2026-10-03T04:42:59Z — The bacterial phylogenetic overview uses a locked
  GTDB R11-RS232 panel.** Eligibility requires a species representative that is
  a tip in the official bac120 reference tree and has NCBI `Complete Genome`
  assembly level plus `full` representation and at least one reviewed origin
  group from the raw isolation source. The origin requirement retains 4,116 of
  12,094 assembly-eligible genomes. One medoid per eligible order guarantees
  taxonomic breadth. The complete 85-genome food/fermentation group defines the
  balance target for every sufficiently large group; smaller groups are
  exhaustive, and marginal rooted Faith diversity decides among
  balance-compatible additions. This yields 696 genomes without using
  annotations or calls and spans all 49 eligible phyla, 120 classes and 321
  orders. Animal-associated and plant-associated counts are each 85 rather than
  being pooled as host-associated; raw metadata and BioSample/BioProject
  identifiers are retained. The panel is stated as 696 throughout: one
  food/fermentation genome chosen by the procedure, `GCA_002285495.1`, could
  not be annotated and is removed in `--prepare` through
  `gtdb-phylogeny/excluded-genomes.tsv`, so that group holds 84 genomes. Figure S4 remains pending until the genomes are
  annotated with Drakkar and evaluated against the current database.

- **2026-10-03T03:13:00Z — R10 uses the Marcos et al. chicken caecal
  dataset.** The case study is the exact published set of 822 bacterial MAGs
  across 388 samples (DOI `10.1093/ismeco/ycag091`; Zenodo snapshot
  `10.5281/zenodo.18457570`, release 1.1.0). All MAGs were reannotated with the
  existing shared Drakkar 2.6.6 environment and the gifter projection; no
  Drakkar installation or update was performed. The archived abundance data do
  not retain the study's 30% breadth matrix, so Figure 7 uses relative
  abundance greater than 0.001 as an explicitly operational threshold and the
  analysis reports sensitivity from nonzero abundance through 0.001. Community
  handoff edges are exact extracellular-anchor compatibilities, not observed
  interactions.

- **2026-10-03T03:49:00Z — R10 does not support increasing encoded handoff
  potential with age, and its richness modes are threshold-driven.** The exact
  extracellular graph has only three links. Pair density, provider fraction
  and recipient fraction decline with age across accepted and high-confidence
  readings, and a 499-replicate null matched for detected-MAG count does not
  reverse the direction. The 78/310 lower/upper richness split is matched
  exactly by whether *Escherichia coli* MAG `cmag_510` exceeds the operational
  0.001 threshold; it is above 10^-5 in every sample, while its continuous
  relative abundance decreases with age. Do not describe either result as
  cooperation, realised cross-feeding or two biological community states.
  Evidence: `22-r10-handoff-bimodality.R` and Figure S3.

- **2026-10-02T03:40:42Z — R8 excludes a METABOLIC comparison.** R8 compares gifter,
  KEGG module completeness and DRAM only, from a fixed per-gene marker table.
  METABOLIC v4 accepts genome or protein FASTA and reruns its own profile and
  motif-validation workflow before it emits summaries; it cannot consume that
  shared marker table. Its native output would therefore confound annotation
  with completeness logic. Do not select a METABOLIC version, parameters or
  run for R8. Raw METABOLIC gene-level marker hits may later be normalised into
  gifter input, but METABOLIC pathway/module summaries are not gifter evidence.
  Evidence: the [METABOLIC-G input and output contract](https://github.com/AnantharamanLab/METABOLIC/blob/master/METABOLIC-G.pl).

## Fixed evidence rules

- A GIFT call is genomic support, not a phenotype prediction. R9 reports
  target-specific recall against observed positives; never emit accuracy,
  precision, F1, MCC, AUC, a pooled rate or binomial intervals.
- Do not write an R7–R10 number unless a committed script in
  `manuscript/analysis/` produced it. Refresh all database counts from the
  compiled artifact at submission.
- Do not rerun the phenotype analyses while the database is being rebuilt.
  `manuscript/analysis/README.md` documents the input-manifest check that
  prevents a silently blended result.
- Prospective laboratory templates under `manuscript/analysis/prospective/`
  are archived. This project uses public phenotype/genome records and must not
  create or simulate assay observations.

## Already closed

- Manuscript priority 3 is closed: Figures 1–5 have PDF and PNG outputs, their
  source values are committed as trace tables, and the non-data-blocked prose
  is complete. The examples are explicitly fixtures, not R10 data.
- The two R9 halves share the current analysis inputs; `04-auxotrophy.R` now
  reports 241–242 nutrient-level tests.
- `07-madin.R` exercises all 16 reviewed Madin rows and reports the
  representative-genome sensitivity of its species-level join.
- `07-madin.R` also produces the committed substrate-frequency table used by
  R9; the claim is no longer a placeholder.
- R7 and Figure 6 were written from `02-incompleteness.R`,
  `08-figure-incompleteness.R`, `09-cooccurrence.R` and `10-block-drop.R`.
- R10 and Figure 7 were written from `21-r10-chicken.R`; the handoff follow-up
  and Figure S3 were written from `22-r10-handoff-bimodality.R`, and the
  reference-frame temporal follow-up and Figures S5--S8 from
  `24-r10-reference-frame-time.R`. The 822-MAG Drakkar
  run completed all workflow steps, its transfer was checksum-verified, and the
  local analysis produced compact summary tables plus compressed detailed
  traces. The large marker projection and cached gifter objects remain in the
  ignored local cache; their hashes are in `r10-input-audit.tsv`.
