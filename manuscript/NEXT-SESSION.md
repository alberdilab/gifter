# Manuscript handoff — active work only

Database 2026.27.1, schema 7, has 153 GIFTs. R7 and R9 are complete and their
analysis, outputs and Figures 6 and 8 are committed. Do not repeat the former
R9/R7 tasks: the current `manuscript.md`, `manuscript/analysis/README.md` and
`inst/doc/proposal-phenotype-validation.md` are the source of truth.

## Current priorities

1. **Run R8, the controlled comparison of abstractions.** Choose the common
   genome subset and pin the KEGG-module and DRAM versions/parameters before
   writing results. Analyse disagreement causes; do not frame this as a
   benchmark with a winner.
2. **Choose an R10 dataset.** It must be a genome-resolved metagenomic dataset
   with provenance adequate for community calls and enough contextual metadata
   to illustrate declared-anchor handoffs. This is an author decision; do not
   silently substitute a convenient dataset.
3. **Make submission decisions explicitly.** Select Microbiome or mSystems,
   settle author contributions, and decide the software/database DOI policy.
   A DOI remains an external release action; do not invent one.

## Decisions recorded

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
