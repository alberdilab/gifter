# Priority 3 structural pilot: future flagellar microscopy test

Status: v1 protocol specification locked 2026-10-01T16:42Z; **not yet a
prospective study and not eligible for the registry**. This document fixes the
future microscopy endpoint, conditions, replication and control requirements
before any image is collected. It contains no working-stock record, control
record, image, microscopy observation, motility result, assembly result or
biological outcome.

## Scope and carried-forward annotation evidence

The target is the structural GIFT `flagellar_apparatus`, not motility,
chemotaxis, rotation, expression in general, or a proton- or sodium-coupling
claim. Its positive genomic call is evidence that a genome encodes at least one
complete curated flagellar architecture; it does not say that a particular
culture makes an observable flagellum.

The only current candidate evidence is the exact PAO1 RefSeq proteome audit in
[the flagellar candidate ascertainment](priority-3-flagellar-candidate-ascertainment.md).
It is pinned to `GCF_000006765.1`, protein-FASTA SHA-256
`f1640583fef81a2ed8fbd12a0f6d7186fe1923640e2855111a7087a5e7485fe0`, database
`2026.27.1` (SQLite SHA-256
`724b810ba2489299edccf20caad12ff48e0989c1dd39696b45490cddc91beaaa`) and the
content-addressed profile inputs in its
[manifest](priority-3-flagellar-annotation-audit/input-manifest.tsv). The
preserved [gene-level trace](priority-3-flagellar-annotation-audit/flagellar-gift-trace.tsv)
supports all required diderm functions, selects `ARCH_FLAGELLUM_DIDERM`, and
also completes the monoderm architecture. That is the annotation-level
conclusion carried forward; it is not a microscopy observation.

The future direct endpoint is necessarily narrower than the genomic claim. A
negative-stain TEM image can show a surface-attached flagellar filament under a
specified culture condition, but cannot identify every curated component, prove
the stator is functioning, or distinguish MotA/MotB from PomA/PomB coupling.
The eventual registry crosswalk must therefore be `related`, not `equivalent`
or `subset_of`. The runner will retain raw paired observations and gene traces,
but a `related` row cannot be turned into a GIFT-validation denominator or a
score.

## Locked microscopy protocol

The following choices are fixed for the first eligible PAO1 parent/control
pair. A different medium, endpoint, stain, field-selection procedure,
replicate definition or decision rule requires a new dated protocol version
before data collection.

| Element | Locked decision |
| --- | --- |
| Primary endpoint | Negative-stain transmission electron microscopy (TEM): a cell is flagellated only when an unbroken filament is visibly continuous with its cell envelope. A detached filament, a putative basal body alone, a motility track or a soft-agar zone is not a positive endpoint. |
| Culture | For each replicate, revive one low-passage frozen aliquot, streak to LB agar for 16--18 h at 37 degrees C, inoculate one colony into 5 mL LB, grow 16--18 h at 37 degrees C and 200 rpm, then subculture 1:100 into 10 mL LB at 37 degrees C and 200 rpm. Sample only at OD600 0.40--0.60. Parent and loss-control cultures are processed in the same block. |
| Grid preparation | Dilute the sampled culture 1:20 in PBS. Apply 2 microlitres to a glow-discharged carbon TEM grid (30 s), blot after 60 s, stain with 1.5% uranyl acetate for 30 s, blot and air-dry. Record grid lot, stain lot, operator, microscope, calibrated pixel size and acquisition time for every grid. |
| Biological replication | Three independent parent cultures and three independent loss-control cultures, each revived from a distinct frozen aliquot on separate calendar days. Two independently prepared grids per culture are required. |
| Sampling and blinding | Before imaging, generate a random field list for each grid. Acquire the first 50 assessable intact cells from each grid (100 cells per biological replicate) at a calibrated resolution that resolves a 20-nm filament. Mask genotype and replicate labels during image scoring; retain the randomisation key and the full unedited image set. |
| Per-replicate call | `positive` if at least 10 of 100 eligible cells have a visibly envelope-attached filament; `negative` if fewer than 10 do; `indeterminate` if fewer than 100 eligible cells are acquired, a required metadata/image hash is absent, blinding is broken, or the paired loss control fails its acceptance rule. |
| Control acceptance | The real loss control must be `negative` in all three biological replicates. Otherwise the entire paired block is `indeterminate`, not evidence for or against the parent. |

This is a structural-imaging protocol. No swimming, swarming, soft-agar,
chemotaxis, rotation or ion-substitution measurement is part of its primary
endpoint. Such measurements may be separately recorded as context, but cannot
replace, rescue or change the TEM observation.

Published PAO1 work makes a `Delta fliC` control a reasonable *candidate class*:
it has been imaged as flagellum-deficient by TEM in isogenic PAO1 experiments
([Murray and Kazmierczak 2008](https://pmc.ncbi.nlm.nih.gov/articles/PMC2293233/);
[Liu et al. 2007](https://pmc.ncbi.nlm.nih.gov/articles/PMC1950964/)). Those
reports neither supply a living culture nor establish the identity of a future
stock here, so they are protocol precedent, not an admitted control or a
biological observation.

## Required physical control and identity evidence

The required control is an actual, strain-matched, isogenic PAO1 `Delta fliC`
derivative paired with its immediate PAO1 parent. In the curated trace, FliC is
`COMP_SF_FLIC` (`KO:K02406`; deposited protein `NP_249783.1`), jointly required
with FliD for `SF_FLAGELLAR_FILAMENT`; that function is required in both curated
architectures. A verified loss of FliC is consequently a loss of one required
structural function, rather than a motility surrogate.

Admission requires all of the following before imaging begins:

1. A physical-stock record for parent and control: supplier or construction
   record, stock identifier, passage history, freezer location and the exact
   aliquot allocated to every replicate. The current deposited PAO1 proteome is
   not a working stock.
2. A pre-assay whole-genome identity check for both working stocks. Retain raw
   reads, their SHA-256 values, read-mapping/assembly method and a comparison
   to `GCF_000006765.1`; establish and record parent--control derivation before
   assigning either culture to the study. A species label, 16S result or a
   substituted PAO1 assembly is insufficient.
3. Two independent checks that the control has lost the required FliC function:
   sequence evidence for the intended `fliC` loss at the locus, and a
   condition-matched FliC-specific protein assay showing its absence. Preserve
   the raw data, reagents/assay method and checksums for both checks.
4. A deposited or generated genome assembly and the same pinned annotation
   workflow for each physical stock. The parent and control must each retain
   their own annotation rows and `trace_gift()` output; the control trace must
   show the missing filament requirement. Deleting `KO:K02406` from an
   annotation table is expressly not a biological control and cannot satisfy
   any item above.

No stock, WGS identity record, independently verified `Delta fliC` culture,
control annotation or control trace currently exists in this repository. These
are concrete blockers, not empty fields to fill with the reference assembly or
a synthetic deletion.

## Data lock and registry admission

Before a registry row can be created, create a study-owned manifest that pins
the following by SHA-256: parent/control raw reads and assemblies, raw
annotations, the exact gifter SQLite file and its version, microscopy protocol,
randomisation key, every raw image, calibration image, image metadata table,
FliC-loss verification data and the analysis script. Store the unedited images
under stable image identifiers; a selected figure is not the raw dataset.

Only after those inputs exist may a `studies.tsv` row be created with
`status = locked`, `priority = machinery`, `target_layer = gift`,
`target_id = flagellar_apparatus`, `crosswalk_relation = related`, and a lock
time preceding every culture/image timestamp. The corresponding `samples.tsv`
rows must name each verified parent/control assembly and the raw
`annotations.tsv` rows used by gifter. One `observations.tsv` row per biological
replicate must carry the locked condition string, raw-image manifest reference,
TEM endpoint value and `not_applicable` nutrient fields. The existing
annotation-audit tables must remain alongside—not be overwritten by—those
stock-specific inputs.

Until the stock, identity, control, raw data and registry-lock conditions are
met, no registry row, biological denominator or statement that PAO1 has
assembled a flagellum under these conditions exists. The current conclusion
remains limited to checksum-pinned gene-level structural annotation evidence.
