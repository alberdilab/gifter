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
