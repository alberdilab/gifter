# Database-only phenotype/genome validation

Status: revised 2026-10-01. This is a retrospective, database-only validation
plan. gifter has no laboratory access under this project, so it will not
collect cultures, make mutants, run microscopy, perform growth challenges or
manufacture prospective observations. The prior prospective templates and
candidate notes are retained as clearly marked historical planning material;
they are not an active study, a GIFT definition, or a condition for distributing
the current database.

## Scope and invariant

A GIFT call is genomic evidence for an encoded capability, not evidence that a
phenotype occurred. Existing phenotype/genome databases can test a call only
when an observation has an explicit boundary relation to the GIFT and a
defensible genome match. They cannot supply expression, activity, assembly,
motility, coupling-ion, ecological-effect or phenotype claims by proxy.

The unit of database-only evidence is an observation paired to an accessioned
genome or, where a source is necessarily species-level, an observation paired
to a declared representative genome with the cost of that choice measured. Each
row retains source release/input checksum, observation field and condition,
strain or species identifier, assembly accession or representative-selection
rule, annotation route, database version, crosswalk relation and the
gene-level `trace_gift()` evidence behind the call when it is available.

No synthetic annotation deletion, inferred phenotype, taxonomic predictor,
gene name, generic marker or functional overlap may stand in for an external
observation. A public record with the wrong boundary is retained as a
`related`, `overlaps`, `superset_of` or `refused` record where useful, never
promoted to an equivalent validation result.

## Evidence already available

- `03-phenotype.R` compares accession-matched BacDive observations with GIFT
  and reaction calls. It excludes BacDive's genome-based predictions, which are
  not independent phenotype evidence.
- `04-auxotrophy.R` uses MediaDive defined-medium compositions and observed
  growth only where a biomass-essential nutrient is absent from a sufficiently
  resolved medium. It tests bounded anabolic frames; it does not invent a
  nutrient-dropout or rescue experiment.
- `07-madin.R` uses Madin's species-level substrate and motility records. It
  reports the representative-genome draw sensitivity rather than presenting a
  species record as strain-level truth.
- `05-annotation-route.R` and the Priority 1--3 audits compare annotations and
  preserve marker/gene traces. They measure annotation or marker specificity,
  not independent biological activity.
- `02-incompleteness.R`, `10-block-drop.R` and the matched MAG-like audit test
  evaluator and assembly/annotation robustness. They never turn an unsupported
  GIFT into supported or stand in for a phenotype observation.

The source-specific rules, crosswalk decisions and existing R9 results remain
in [`proposal-phenotype-validation.md`](proposal-phenotype-validation.md) and
`manuscript/analysis/`. Database-only scope does not downgrade those measured
observations; it makes clear what they can and cannot establish.

## Workstream 1: marker specificity with public evidence

Use the current exact-assembly, checksum-pinned audits to audit whether a
marker can license the claim as named. Retain both accepted hits and rejected or
broad-marker inputs, then inspect `trace_gift()` down to genes. A discordance
between public phenotype evidence and a genomic call is investigated in this
order: strain/assembly identity, observation boundary and condition,
annotation, marker specificity, then route or machinery curation.

The current collagen, aspartate-chemoreception, starch and Type I-E records are
evidence-only annotation audits. They must not be converted into assay outcomes
or prospective registry rows. The starch result is a curation lead: broad CAZy
family evidence completing a named substrate claim requires separate curation
review, not a laboratory result invented from the annotation.

## Workstream 2: public genome and MAG robustness

Use deposited isolate assemblies, raw reads, metagenomes and MAGs only when
their provenance supports the comparison. Reannotate each input through the
same checksum-pinned pipeline and keep isolate, MAG-like draft, MAG and
contaminated bin as distinct sources. A call difference is an
annotation/assembly difference unless a source independently establishes a
biological difference.

The existing matched MG1655 isolate/MAG-like draft case study and its
fixed-annotation loss checks remain valid database-only evidence. A later real
MAG analysis must record binning, completeness and contamination metadata and
must not combine foreign genes into one organism's machinery.

## Workstream 3: underrepresented GIFT types

Existing phenotype/genome databases presently provide no individually usable
observation for the regulatory or defense GIFTs. A generic MCP, generic Cas
protein, stress response, phage outcome, motility record or resistance label
cannot substitute for the machinery/circuit/mechanism claim. Record this lack
of admissible evidence rather than expanding an over-broad proxy.

For `flagellar_apparatus`, the PAO1 audit preserves strong annotation evidence
for encoded structural machinery. BacDive and Madin motility records are
retained only as `superset_of` context: they cannot prove every structural
component, assembly under a condition, rotation or a coupling ion. The direct
microscopy protocol is archived because no laboratory work is in scope. A
future published microscopy observation may be used only if it can be matched
to an accessioned genome and its observation boundary is documented; it would
remain retrospective evidence, not data collected by this project.

## Workstream 4: bounded anabolic frames

Continue to use defined-media growth records from MediaDive for the existing
bounded anabolic-frame analysis. A nutrient counts as absent only when the
curated ingredient/anchor resolution and void rules support that statement.
Observed growth without a biomass-essential nutrient can test the necessary
genomic capability; absence of a record, a nonessential cofactor requirement,
or a supplied/undefined nutrient cannot. No dropout/rescue result is claimed
without a real experiment.

## Reporting and decision rules

Report an observation with its crosswalk relation, numerator, denominator and
taxonomic spread. For an equivalent or subset observation/claim pair, report
observed positives lacking a supported call and preserve their missing
requirements. Report supported calls without the observed phenotype separately.
Do not emit accuracy, precision, F1, AUC, a catalogue-wide score or a pooled
rate across different targets.

Keep five evidence states separate:

1. `individual_recall_usable`: an admissible observation with at least 20
   matched units; it supports a target-specific recall result.
2. `bounded_frame_aggregate`: a defined-medium observation that tests a
   curated bounded anabolic frame, not an individual direct phenotype.
3. `individual_below_threshold`: an otherwise admissible observation with fewer
   than 20 matched units; retain it, but do not read its fraction as a rate.
4. `related_context_only` or `refused_proxy_only`: a visible public record that
   cannot license the target; it is traceability, not validation.
5. `no_public_observation`: no admissible record in the pinned sources. This
   is not an absence call and must not be imputed from taxonomy or annotation.

A biological database change still requires a decision in
`database_changes.tsv`, affected-GIFT rows in `change_gifts.tsv`, source
provenance, a rebuilt SQLite artifact and regression coverage. A public
phenotype discrepancy alone is a curation lead, not permission to broaden a
marker or boundary.

## Repository implementation

`manuscript/analysis/11-prospective-validation.R` and
`manuscript/analysis/prospective/` are retained as archived templates for an
independently resourced future study. They are not run or populated in this
database-only project.

The active validation analyses are `03-phenotype.R`, `04-auxotrophy.R`,
`05-annotation-route.R`, `07-madin.R` and the checksum-pinned annotation/MAG
audits. [`19-phenotype-validation-coverage.R`](../../manuscript/analysis/19-phenotype-validation-coverage.R)
is the database-only coverage audit: it pins the committed R9 outputs and the
SQLite database by SHA-256, expands reaction observations to their owning
GIFTs, and writes an evidence row and one validation status per GIFT. It is
deliberately a coverage result, not another score.

## Current database-only status

At database `2026.27.1`, the coverage audit records 17 individually
recall-usable GIFTs, 44 additional GIFTs testable only through a bounded
anabolic-frame aggregate, and 92 without either form of usable test. Within
that remainder, `flagellar_apparatus` has related motility context only,
`collagen_cleavage` has a refused gelatin proxy only, and all three regulatory
and five defense GIFTs have no public observation in the pinned sources. These
are constraints on the interpretation of the manuscript, not claims of
biological absence.
