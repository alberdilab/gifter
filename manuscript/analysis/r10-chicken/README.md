# R10 chicken caecal MAG case study

This directory makes the R10 case study reproducible across two deliberately
separate locations:

- Mjolnir scratch holds the 822 MAG FASTAs, workflow intermediates and
  scheduler logs. The run uses the existing shared Drakkar conda environment;
  it does not install or update Drakkar.
- `manuscript/analysis/.cache/r10-chicken/` holds fetched public inputs and the
  compact Drakkar files copied back for local evaluation. The cache is ignored
  by git.
- committed scripts, manifests, derived summary tables and figures remain in
  this repository.

The biological invariant is that Drakkar supplies gene-resolved marker
evidence and gifter alone evaluates encoded capabilities. A positive call does
not assert expression, activity, growth, flux or phenotype. Sample detection
and abundance remain separate from genome calls; neither may turn an
unsupported call into a supported one. Cross-genome handoffs are reported only
through declared extracellular anchors and are potential compatibilities, not
observed interactions.

## Dataset identity

The case study is the 822 bacterial MAG catalogue from the two-trial chicken
caecal study (DOI `10.1093/ismeco/ycag091`). The archived analysis contains 825
MAG/count rows, but `taxonomy_v2.tsv` contains the published 822 bacterial MAGs.
`mag-manifest.tsv` is the exact inner join to those 822 rows. The excluded
archive-only rows are `cmag_274`, `cmag_430` and `cmag_554`.

Public analysis snapshot: Zenodo `10.5281/zenodo.18457570`, release 1.1.0.
Repository commit: `20e6ec3a873b7b14d9f194ec2cbcd602a3948e1d`.

## Remote layout

The project lives at:

```text
/projects/alberdilab/scratch/jpl786/projects/gifter-r10-chicken/
  tasks/01-mag-acquisition/{manifests,mags,logs}/
  tasks/02-drakkar-annotation/{output,logs}/
  tasks/03-result-transfer/{output,logs}/
```

The scripts under `remote/` are copied there verbatim. Run them in order:

1. `setup-scratch.sh`
2. submit `download-mags.sh` with `sbatch`
3. inspect `download.complete` and the checksum manifest
4. launch `screen-driver.sh` in a detached `screen` session on the login node;
   it runs `run-drakkar.sh` and submits `prepare-transfer.sh` only on success
5. run `monitor-and-fetch.sh` locally; it verifies and fetches
   `annotating/gifter_input.tsv.xz`, `annotation_manifest.yaml`,
   `annotation_qc.tsv`, `transfer-manifest.tsv` and `transfer.complete`, then
   launches `21-r10-chicken.R`

The existing conda environment at
`/projects/alberdilab/data/environments/conda/drakkar` reports Drakkar 2.6.6.
The five annotation resources are the versions recorded by Drakkar's generated
`annotation_manifest.yaml`; the local analysis treats that generated manifest,
not this prose, as authoritative provenance.

## Completed run

The acquisition sentinel is dated 2026-10-02T07:17:58Z. Drakkar completed all
5,758 workflow steps, and the validated transfer completed at
2026-10-03T02:26:34Z with exactly 822 genomes and 11,219,684 projected marker
rows. The fetched `gifter_input.tsv.xz` is 29,811,972 bytes with SHA-256
`1bc6f6a882223d1f86c417f5d0f9c8937fc70b370affc0c5399bc3e81fcfbd86`.

`annotation-manifest.yaml`, `transfer-manifest.tsv` and `transfer.complete` in
this directory are the small generated provenance records copied from that run.
The 28 MB projected marker table and 689 KB per-MAG/source QC table are fetched
under `manuscript/analysis/.cache/r10-chicken/drakkar/`, where
`21-r10-chicken.R` verifies them against the transfer manifest before use.

## Detection caveat

The archived abundance object does not retain the per-sample genome breadth
matrix used for the paper's 30% genome-coverage filter. Its positive entries
include one-read observations, so treating every nonzero value as detected
would saturate most sample networks. The local analysis must therefore report a
predeclared abundance/detection sensitivity analysis and withhold ecological
network claims if they are not stable. It must not silently substitute the
separate 734-genome, three-trial remapping catalogue found on Mjolnir.

## Local analysis products

`21-r10-chicken.R` verifies the public-input and remote-transfer checksums
before it evaluates a marker. It writes compact, reviewable tables under
`manuscript/analysis/output/` and Figure 7 under `manuscript/figures/`.
Full `gifter_dataset_traits` and exact plant-fibre `gifter_dataset_network`
objects stay in the ignored local cache, where their GIFT, genome, anchor and
edge traces remain available without committing a potentially very large edge
table.

The analysis reports four predeclared detection thresholds. Its primary
operational threshold is relative abundance greater than `0.001`; this is a
sensitivity choice necessitated by the missing breadth matrix, not a substitute
claimed to reproduce the paper's 30% breadth filter. Genome completeness below
90% can only make an unsupported call indeterminate. It never creates a
positive call.

`22-r10-handoff-bimodality.R` is the local follow-up. It consumes the exact
cached calls produced above, writes the all-exact-extracellular handoff
sensitivities and detected-count-matched null, and diagnoses the richness modes
without changing a call. Figure S3 links those modes to the abundance of the
data-selected driver MAG. All handoff language remains encoded potential only;
the script cannot observe exchange, cooperation or activity.

`24-r10-reference-frame-time.R` is the coarse temporal follow-up. It resolves
all 19 named frames from the audited database, checks its reconstructed values
against the cached public-API readings, and models community richness, mean
per-MAG richness and bounded coverage separately. A stable label requires
equivalence within one GIFT for count metrics or five percentage points for
bounded coverage at every detection threshold; complementary minimum-effect
tests distinguish a directional result outside those margins from an estimate
whose magnitude remains uncertain. Figure S5 shows adjusted effects, while
Figure S6 shows the population-standardised adjusted values at all three days
on shared within-metric scales. Its connecting lines join age-level model
estimates and are not individual-bird trajectories. Figure S7 decomposes each
clear frame-level decrease into member-GIFT carrier prevalence, with the six
largest descriptive declines displayed and every member retained in the source
table. The script verifies the GIFT fractions sum to the frame metric per
sample and performs no per-GIFT hypothesis tests. Figure S8 repeats the frame
models after weighting GIFTs by the relative abundance of their carrier MAGs,
closed within each detected community, and contrasts equal-weight carrier
fractions with abundance-weighted carrier shares for the displayed GIFTs. None
of the figures turns a frame into a composite GIFT or a change in carrier
distribution into expression, activity or flux. The script accepts
`R10_DB_PATH` for an archived SQLite artifact and refuses it unless its checksum
matches the R10 audit.
