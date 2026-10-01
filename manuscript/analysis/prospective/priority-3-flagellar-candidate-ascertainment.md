# Priority 3 structural pilot: flagellar-apparatus candidate ascertainment

Status: candidate ascertainment and exact-assembly annotation audit completed
2026-10-01T16:11Z. The later microscopy plan is archived because this project
uses existing phenotype/genome databases only. This remains a structural
annotation audit, not a microscopy experiment, a motility experiment, a
prospective assay outcome, or a GIFT redefinition, and it adds no row to the
prospective registry.

## Question and invariant

`flagellar_apparatus` is a structural GIFT. A positive call means that a genome
encodes at least one complete curated architecture of the bacterial flagellum:
the export gate and ATPase, MS ring, rod, C ring, hook, hook--filament junction,
filament and stator; the diderm architecture additionally requires the L and P
rings. It does **not** mean that the cells express, assemble or retain a
flagellum in a specified culture condition, that they are motile, or that their
stator has a particular coupling ion.

The audit preserves the component-level Boolean contract. `K02401` and `K13820`
are alternative accepted markers for FlhB, and `K02421` and `K13820` are
alternatives for FliR. An absent alternative marker is therefore not a missing
component. The runner checks completeness against `trace_gift()` component rows,
while retaining every searched marker hit and every unhit accepted accession.

## Candidate and selection boundary

The sole convenience candidate is the exact, complete *Pseudomonas aeruginosa*
PAO1 RefSeq assembly
[`GCF_000006765.1`](https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/006/765/GCF_000006765.1_ASM676v1/GCF_000006765.1_ASM676v1_assembly_report.txt).
It was already an exact-assembly input for the Priority 1 generic-MCP annotation
control and is used here because that deposited protein FASTA is a reproducible,
strain-resolved structural-pilot input. The selection happened after the current
GIFT curation and before any new microscopy data: it is not a pre-registered
biological cohort and will not contribute to a biological denominator.

The [candidate roster](priority-3-flagellar-candidates.tsv) and
[input pin](priority-3-flagellar-annotation-inputs.tsv) identify the one
assembly and require the protein FASTA SHA-256
`f1640583fef81a2ed8fbd12a0f6d7186fe1923640e2855111a7087a5e7485fe0` before an
audit can run. They contain no assay observation or claimed cellular structure.

## Exact-assembly annotation evidence only

[`18-priority3-flagellar-annotation.R`](../18-priority3-flagellar-annotation.R)
extracts the 26 currently accepted KOfam models from the content-addressed
library, applies their adaptive thresholds to the exact NCBI protein FASTA, and
evaluates only the accepted `KO` rows with the pinned gifter database. It writes
the profile hits, threshold/model/database manifest and the full
[`trace_gift()` output](priority-3-flagellar-annotation-audit/flagellar-gift-trace.tsv).
The [audit row](priority-3-flagellar-annotation-audit/candidate-annotation-audit.tsv)
records 25 accepted marker accessions and 29 protein hits. `K13820` has no hit,
but that is an unused alternative marker rather than a missing FlhB or FliR
component: `K02401` and `K02421` each support their respective components.

Under database `2026.27.1`, every required component in the diderm trace is
supported, `ARCH_FLAGELLUM_DIDERM` is the best architecture, and the deposited
protein set also completes the monoderm architecture (two complete
architectures). This is **annotation evidence for the encoded structural
architecture only**. It is not an image of a flagellum, a measurement of
assembly, ion coupling, rotation, swimming, chemotaxis, growth, virulence or
any other biological outcome.

## Database-only structural context

The [former microscopy plan](priority-3-flagellar-microscopy-test.md) is
archived, not deferred for local simulation. No synthetic annotation deletion,
motility result, gene name or generic stator marker can serve as its biological
control or outcome.

The active structural context is instead the existing public-record comparison
in `07-madin.R`: BacDive and Madin motility rows are explicitly
`superset_of` `flagellar_apparatus`. They remain visible in the database-only
coverage audit but cannot validate complete machinery, assembly under a
condition, rotation or ion coupling. No currently pinned phenotype/genome
record directly tests the structural GIFT. The regulatory and defense portions
of Priority 3 likewise have no admissible public observation in the current
sources.
