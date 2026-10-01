# Database-only validation records and archived prospective templates

The active work described by [the biological validation plan](../../../inst/doc/biological-validation-plan.md)
uses existing phenotype/genome databases, deposited assemblies and cached
annotations only. The candidate records and checksum-pinned annotation audits
in this directory remain useful evidence and curation material, but they are
not assay observations or prospective biological outcomes.

`studies.tsv`, `samples.tsv`, `annotations.tsv`, `observations.tsv` and
`11-prospective-validation.R` are retained as **archived templates** for an
independently resourced future study. This project must not create a study row,
copy the templates into an active registry, simulate a control or add invented
observations. Do not put any external observation in the gifter reference
database: the database records genomic claims, not phenotypes.

The archived runner's constraints document what real prospective evidence would
need. They do not authorise a local phenotype study. The database-only analyses
instead preserve source version/checksum, assembly/representative selection,
crosswalk relation and gene-level trace, and never emit accuracy, precision,
F1, AUC or a catalogue-wide score.

## Existing evidence-only audits

[The collagen](priority-1-collagen-candidate-ascertainment.md),
[aspartate-chemoreception](priority-1-aspartate-chemoreception-candidate-ascertainment.md),
[starch](priority-1-starch-candidate-ascertainment.md), and
[Type I-E machinery](priority-1-type-ie-crispr-candidate-ascertainment.md)
records pin their exact assemblies, annotation inputs, marker hits and
`trace_gift()` output. They can identify a marker-specificity or curation
problem, but cannot become activity, receptor response, polymer-degradation,
CRISPR-interference or phenotype results.

[The matched-isolate/MAG-like audit](priority-2-matched-mag-robustness-candidate-ascertainment.md)
uses deposited WGS data to reannotate an isolate and one deterministic draft.
It retains every source-separated marker row, GIFT trace and call transition as
an annotation/assembly difference. Its fixed-table deletion and assessability
checks are evaluator-contract tests, not synthetic genomes, MAGs or biology.

[The flagellar structural audit](priority-3-flagellar-candidate-ascertainment.md)
pins the PAO1 proteome and reports complete encoded structural machinery at the
component level. The former [microscopy plan](priority-3-flagellar-microscopy-test.md)
is archived: it cannot be simulated with annotation deletion or motility data.
BacDive and Madin motility records remain visible only as `superset_of` context;
they cannot validate complete machinery, assembly, rotation or ion coupling.

## Active phenotype/genome validation

The manuscript-facing analyses live one directory up:

- `03-phenotype.R` uses accession-matched BacDive observations, excluding
  BacDive genome-based predictions.
- `04-auxotrophy.R` uses MediaDive defined-medium growth to test bounded
  anabolic frames only where nutrient absence is defensible from composition.
- `07-madin.R` uses species-level Madin records and reports the sensitivity to
  representative-genome selection.
- `19-phenotype-validation-coverage.R` checksum-pins those committed outputs
  and reports, per GIFT, whether evidence is individually recall-usable,
  bounded-frame-only, related context, a refused proxy, or absent from the
  current public sources.

The direct prospective registry remains empty by design. An absent public
record is never a negative phenotype or an unsupported genomic call.
