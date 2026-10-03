# R10b Microflora Danica environmental-community case study

This directory contains the environmental complement to the host-associated
chicken case study in `../r10-chicken/`. It uses the Microflora Danica atlas
(Nature article DOI `10.1038/s41586-025-09794-2`; data snapshot DOI
`10.5281/zenodo.17162544`) and keeps public acquisition, Mjolnir annotation and
local gifter evaluation as separate, checksum-verified stages. The pinned
Zenodo record is open under CC BY 4.0.

The biological invariant is that Drakkar supplies gene-resolved marker
evidence and gifter evaluates the encoded capability of one deposited
representative genome per 95% ANI species cluster. Habitat, detection,
abundance and genome quality never change a call. They only decide which
already-evaluated representative is read in a sample, how its evidence is
weighted, and whether silence from an incomplete genome is informative. A
cluster-level abundance attached to its representative does not establish that
every strain in the cluster carries the representative's accessory GIFTs.
Nothing in this analysis establishes expression, activity, flux, substrate
availability, realised interaction or ecological effect.

## Locked genome and sample panels

`source-manifest.tsv` pins the 2025 Zenodo record, its 19.8 GB MAG archive and
the smaller supporting archive, plus the exact Git commit and SHA-256 of the
deposited species-representative manifest. `25-r10-mfd.R --prepare` joins all
5,518 representatives to the 19,253-MAG quality and secondary-cluster table and
writes `representative-genomes.tsv`. Every secondary cluster occurs exactly
once. Drakkar therefore annotates 5,518 genomes rather than treating the
19,253 overlapping MAGs as independent providers.

Zenodo names a FASTA as `MFD#####_ilm_asm_binN.fa`, while the representative
table names that same bin as `LIB-MJ….N`. The committed manifest makes this
crosswalk explicit in `archive_basename`: the published collapsed metadata maps
the library `flat_name` to its `fieldsample_barcode`, and the terminal bin
number supplies `N`. The complete 19,253-MAG archive index has four and only
four exceptions: its four expected barcoded names are absent and four members
are instead labelled `unknown_ilm_asm_binN.fa`, with distinct matching bin
numbers 1, 3, 6 and 7. `archive-aliases.tsv` records the resulting one-to-one
crosswalk; three of those bins are selected representatives and the fourth is
the other member of one affected secondary cluster. All 5,518 mappings remain
unique. Remote extraction requires an exact archive-basename match, verifies
each extracted sequence length against the published `Genome_Size`, and
renames the selected FASTA to the published representative ID; it never
guesses by taxonomy or cluster membership.

The same preparation step locks 360 samples before any annotation or GIFT call
is examined. `habitat-design.tsv` declares eight exact atlas metadata classes:
agricultural field, natural grassland, natural forest, urban greenspace, bog or
fen soils; natural freshwater and saltwater sediments; and urban wastewater.
Each contributes 45 samples. Eligibility requires a published abundance
column, reliable coordinates and a 10-km grid cell. The first deterministic
choice is the sample nearest the class centroid; subsequent samples maximise
their minimum great-circle distance to those already selected. Only the
lexicographically first sample in a class and 10-km cell is eligible, so no
class contributes two samples from the same cell. `selected-samples.tsv` and
`design-audit.tsv` retain the decision and its checksums.

Run the preparation from the repository root:

```sh
Rscript manuscript/analysis/25-r10-mfd.R --prepare
```

The supporting archive is cached under the ignored
`manuscript/analysis/.cache/r10-mfd/sources/` directory. The 19.8 GB MAG archive
is deliberately not downloaded locally.

## Abundance contract

The published Sylph table contains profiles for the non-dereplicated MAG set.
The analysis retains only strain (`t__`) rows, maps each MAG to its published
`secondary_cluster`, and sums rows within cluster before joining the one
deposited representative. Source values are percentages and are divided by 100
without renormalisation. Abundance coverage is therefore the share of
MFD-MAG-assigned abundance carried by representative clusters encoding a GIFT,
not a fraction of all DNA in the environmental sample.

Detection is reported at three predeclared thresholds: positive abundance,
greater than 0.01%, and greater than 0.1% of the MFD MAG profile. The 0.1%
reading is the operational display threshold; the other two are retained as
sensitivity readings. Detection can remove a representative from a sample's
denominator but cannot promote or demote a GIFT.

## Analysis scope

The environmental comparison is descriptive and uses six database-defined
reference frames: carbon acquisition, aromatic catabolism, nitrogen
acquisition, sulfur acquisition, chemical detoxification and bounded
biomass-essential anabolism. It reports community richness, mean encoded
repertoire per detected representative, provider redundancy, abundance
coverage and explicit denominators. It runs no habitat significance test,
ordination or differential-abundance model. The bundled archive was released
with the atlas nitrifier analysis, but this case study makes no nitrification
claim: nitrification is not a current gifter reference frame.

## Mjolnir layout

The remote project is isolated at:

```text
/projects/alberdilab/scratch/jpl786/projects/gifter-r10-mfd/
  tasks/01-input-acquisition/{archives,manifests,mags,public-data,logs}/
  tasks/02-drakkar-annotation/{output,logs}/
  tasks/03-result-transfer/{output,logs}/
```

`submit-mjolnir.sh` copies only the locked manifests, remote scripts, the
current compiled database and its marker catalogue. It submits public
acquisition and launches a detached driver that waits for the verified
acquisition sentinel, runs the pre-existing shared Drakkar 2.6.6 environment,
and submits the transfer stage only after annotation succeeds. No environment
or annotation database is installed or updated.

`prepare-transfer.sh` keeps the full Drakkar projection on Mjolnir and produces
a much smaller, lossless projection against the pinned gifter marker catalogue
for local evaluation. It transfers both checksums, the exact database artifact,
the representative and sample manifests, MAG quality/cluster metadata, the
selected abundance source and Drakkar's generated annotation manifest and QC.

After submission, run `monitor-and-fetch.sh` locally. It reports acquisition
and per-source annotation progress, checksum-verifies the transfer into the
ignored `.cache/r10-mfd/remote/` directory and launches the final analysis.

## Active run

The Mjolnir workflow was restarted from its verified downloads at
2026-10-03T07:03:59Z after its archive-name gate exposed and the workflow
recorded the four `unknown` aliases described above. Acquisition job
`45837109` is followed by detached screen `r10-mfd-drakkar`; the driver will not
start Drakkar until `acquisition.complete` exists. The submitted database is
version 2026.33.1, schema 7, with SQLite SHA-256
`f97d1119b424e84d099e793d24990ce6de72b28e9b4e6a24796650147f81e834`.
The copied marker catalogue has SHA-256
`f0acc4749db5f12bd501915fe2da03af937792bc3446ffac7f2308e7728603eb`.
The representative and sample manifests have SHA-256
`ea526c47cabf67643e95edbd635a60c7701b4654c529f69f6c1cee61b369b70d`
and `2d7b684cf915e76e0c35e24900a2bfeb6bdb6c869e04342ec651cba2948b2776`,
respectively. The remote copies of both artifacts and both locked panels were
verified before representative extraction or annotation began.
