# Archived Priority 3 flagellar microscopy plan

Status: archived 2026-10-01. The project is restricted to existing
phenotype/genome databases and has no laboratory access. No culture, mutant,
identity assay, microscopy preparation, image, observation or prospective
registry row will be created from this plan.

The former direct-TEM specification is retained in Git history at
`8f4ef1e` so its explicit boundary remains reviewable. It must not be simulated
with an annotation deletion, a motility record, a gene name or an ion-coupling
inference.

No strain-matched working stock and identity check, locked microscopy endpoint,
conditions and biological replicates, or independently verified
required-function-loss control is available. Those are concrete blockers to any
future direct structural study, not information that can be filled with a
database proxy.

The active evidence for `flagellar_apparatus` is the checksum-pinned PAO1
annotation audit and its component-level
[`trace_gift()` output](priority-3-flagellar-annotation-audit/flagellar-gift-trace.tsv).
It supports encoded structural machinery only. The database-only coverage audit
records BacDive and Madin motility as `superset_of` context rather than a
structural validation, because it cannot establish complete machinery,
assembly, rotation or a coupling ion. See the
[database-only validation plan](../../../inst/doc/biological-validation-plan.md)
for the active scope.
