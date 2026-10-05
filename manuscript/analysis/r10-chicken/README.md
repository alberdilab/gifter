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

## Giftag rerun and practical annotation benchmark

The same checksum-verified 822 nucleotide MAGs are being reannotated with
giftag 0.2.0 in a separate Mjolnir task:

```text
/projects/alberdilab/scratch/jpl786/projects/gifter-r10-chicken/
  tasks/04-giftag-benchmark/{pilot,full,transfer,drakkar-accounting,logs}/
```

The remote scripts `run-giftag.sbatch`, `prepare-giftag-transfer.sbatch`
and `collect-drakkar-accounting.py` are source controlled here. The
one-MAG pilot passed as Slurm job `45861710`; the full job is `45861711`
and its dependent transfer job is `45861732` (submitted 2026-10-05 UTC).
An initial pilot, `45861678`, stopped before annotation because Mjolnir has
no `/usr/bin/time`; its files are retained as
`pilot-failed-45861678/`. The corrected jobs use giftag's benchmark
`measure.py` wrapper.

The full job requests eight CPUs and 20 GB and processes the MAG directory
with `--input-type nucleotide --mode auto --threads 8`. It verifies every
FASTA against `mag-sha256.tsv` before timing, records a run manifest and
per-genome table, validates the exact 822-MAG output and marker rows, then
packages the result with a transfer checksum manifest. The pilot annotated
`cmag_001` (1,722 predicted proteins, 150 marker rows) in 28.729 seconds,
with 117.784 CPU seconds and a 1.328 GB peak child-process RSS. The pilot is
a functionality check, not a full-catalogue speed estimate. Its four-column
handoff evaluated in the current gifter database and supported 31 GIFTs;
the original 13-column evidence table remains available for inspection.
Drakkar's QC also reports 1,722 predicted proteins for that MAG.

The reused giftag profile database was built 2026-10-04 from the exact current
gifter marker vocabulary: both marker TSVs have SHA-256
`552fc134bb989ed37e0223ce05a17e0632a217416a197fbd6e36ce1d536667b9`
(1,576 markers; 1,571 searchable). Five markers lack a searchable profile or
published threshold in this build. Their absence from giftag output is an
annotation coverage limit, not evidence that the MAG lacks them. The installed
giftag code is version
0.2.0, source commit `ab5769fa216107eef551011ae1a4de6c1c676458`.
The profile build was based on gifter database 2026.37.1, but the marker
vocabulary is byte-identical to the current database 2026.39.1. Both sets of
marker observations will be evaluated against that *same current* gifter
SQLite file, SHA-256
`2aaecf7ef6cbb7531baf1d160ab5abbcc60c922463e21e2200100564c7d32987`.
The old Figure 7 and its original database run remain separate.

This is a warm annotation run: the existing giftag environment and profile
database are reused. The separately measured profile build took 59.0 seconds
after the source libraries were already present. The retained giftag database
occupies 1.492 GB; the pinned upstream KOfam and dbCAN source files used by
that build occupy 6.827 GB. Their acquisition and the environment installation
are outside the timed annotation. The exact byte and build records are in
`benchmark/giftag-*.tsv` and `giftag-build-measure.json`.

This is a practical workflow comparison, not an isolated implementation
benchmark. Drakkar searched broader annotation resources with up to 100
Snakemake jobs, while giftag searches only gifter's profile targets in one
eight-CPU job. Their KOfam and dbCAN releases differ; Drakkar searches
TIGRFAM 15.0 separately and giftag maps supported TIGRFAM identifiers through
NCBIFAM 20.0 models. Gene callers and thresholds can differ. Marker and GIFT
concordance therefore describe output differences; neither caller is ground
truth. Wall-time speed ratios must be shown beside actual CPU time, CPU
allocation, source scope and memory.

The original Drakkar run submitted 5,784 Slurm jobs, of which 5,757 completed
and 27 failed or timed out before retries. Its first Slurm job started at
2026-10-02T09:31:12 and the last ended at 2026-10-03T02:43:22, a 61,930
second span. The source-controlled `benchmark/drakkar-*.tsv` files retain
every job with its MAG and rule, per-MAG and per-rule totals, and the run
summary. The summed Slurm `TotalCPU` is
4,998,517 seconds; `CPUTimeRAW` sums to 3,071,393 allocated core-seconds.
Some one-CPU allocations consumed more than one CPU's elapsed time, so the
allocation field is not a reliable proxy for actual compute consumed by this
workflow. The accounting includes failed attempts. KOfam, Pfam and NCBIFAM
searches account for most of the actual CPU total. The largest per-job Slurm
step RSS is 1.601 GB; it is not a peak for the concurrently running workflow.

When `transfer/transfer.complete` appears on Mjolnir, run from the repository
root:

```sh
bash manuscript/analysis/r10-chicken/fetch-and-rerun-giftag.sh
Rscript manuscript/analysis/33-r10-giftag-compare.R
python3 manuscript/analysis/34-r10-giftag-markers.py
python3 manuscript/analysis/35-r10-giftag-resources.py
python3 manuscript/analysis/36-r10-giftag-genome-timing.py
```

`monitor-giftag-benchmark.sh` performs those commands when the Mjolnir
transfer becomes complete and stops with an error if either Slurm job fails.
It is safe to run from the repository root in an interactive session when a
long-running local monitor is preferred.

The fetch script verifies every transferred file, then runs the unchanged R10
trait, sample, age-contrast and Figure 7 workflow in isolated
`output/r10-giftag/` and `figures/r10-giftag/` directories. The matching
Drakkar run against the current gifter database writes to
`output/r10-drakkar-current/`. The comparison scripts require those two
outputs and report genome-GIFT call overlap, sample metric differences and
per-MAG marker presence within the same 1,576-marker vocabulary. The resource
script reports annotation wall time, CPU time, memory, throughput and
Drakkar-to-giftag ratios with each metric's scope. The per-MAG timing script
retains giftag's elapsed time and the original Drakkar jobs and CPU seconds
for each verified MAG, allowing genome-size and outlier audits.

## gifter runtime and memory benchmark

`36-r10-gifter-resources.R` times the gifter portion of this case study from
the already annotated, checksum-verified Drakkar marker table. Run it from the
repository root after fetching the R10 input:

```sh
Rscript manuscript/analysis/36-r10-gifter-resources.R
```

The fresh R process verifies and loads all 11,219,684 marker rows, evaluates
822 MAGs, builds the 822 × 388 abundance dataset, reads 11 R10 reference
frames at the primary 0.001 detection threshold with 90% completeness
assessability and `pairwise = FALSE`, then builds the exact plant-fibre network.
It bypasses R10's result caches. The default is one evaluation worker, giving
an interpretable process RSS; `GIFTER_BENCH_WORKERS` can change it. Optional
`GIFTER_BENCH_GENOMES` and `GIFTER_BENCH_SAMPLES` select a smaller smoke test.
Even a smoke test reads and verifies the full marker table before subsetting.

The controller samples resident memory every 0.05 seconds and records wall and
CPU time for each stage. Brief memory spikes between samples can be missed.
It writes the stage summary under `benchmark/` and
the raw memory samples and worker log under the ignored `.cache/` directory.
Stage RSS is the peak process memory during that stage, including objects
retained from prior stages. It is not an additional allocation to add to the
previous stage. With multiple workers the summed RSS includes copy-on-write
pages in more than one process, so it is an upper estimate of unique physical
memory. The full-workflow row is the observed process span and peak RSS across
all five stages. It excludes gene calling, profile search, software and profile
installation, data download, figure rendering and the case study's downstream
statistical contrasts. The separate Drakkar and giftag accounting above covers
annotation with different resource scopes; these timings should not be added
to a remote Slurm span as though they were one measured end-to-end execution.

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
