# Priority 3 structural pilot: flagellar-apparatus candidate ascertainment

Status: candidate ascertainment and exact-assembly annotation audit completed
2026-10-01T16:11Z. A future microscopy protocol specification was subsequently
locked on 2026-10-01T16:42Z, but no study, working stock, control, image or
observation exists. This starts only the structural portion of Priority 3. It is
not a direct microscopy experiment, a motility experiment, a prospective assay
outcome, or a GIFT redefinition, and it adds no row to the prospective registry.

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

## Future direct test and remaining blockers

The [future flagellar microscopy test](priority-3-flagellar-microscopy-test.md)
now locks the TEM endpoint, LB mid-exponential culture condition, three
independent biological replicates, image sampling/blinding, per-replicate
decision rule, and use of an isogenic real `Delta fliC` required-function-loss
control. It is a pre-registry protocol specification, not a biological result.

No observation has been placed in `observations.tsv`, and no study has been
locked in `studies.tsv`. The following concrete inputs remain absent and block a
prospective structural result:

1. A strain-matched working stock and a pre-assay identity check linked to the
   deposited assembly, including checksum-pinned stock DNA data. The reference
   proteome cannot establish the identity of a future culture.
2. A real, strain-matched `Delta fliC` control with independently verified
   locus and protein loss, plus its own deposited or generated genome,
   annotation and trace. No synthetic annotation deletion is used here, because
   it is an evaluator exercise rather than a strain or microscopy control.
3. The actual culture, FliC-verification and image data manifests. A published
   PAO1 control class or an image selected for a figure is not a record of this
   future study.

Only after these inputs exist may a registry row be locked and processed by
`11-prospective-validation.R`. The direct TEM endpoint will remain a
condition-specific structural observation related to, rather than equivalent
to, the full genomic GIFT; it cannot establish motility or ion coupling. The
remaining regulatory and defense portions of Priority 3 have not been started
by this structural pilot.
