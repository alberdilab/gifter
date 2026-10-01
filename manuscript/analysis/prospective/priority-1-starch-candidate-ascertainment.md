# Priority 1 candidate ascertainment: starch-degradation specificity

Status: candidate ascertainment and exact-assembly annotation audit completed
2026-10-01T12:29Z. This is neither a prospective assay result nor a GIFT
redefinition. The candidate roster is
[`starch-specificity-candidates.tsv`](starch-specificity-candidates.tsv).

## Question and invariant

`starch_degradation` is a metabolic GIFT from extracellular starch to free
D-glucose. Its sole curated route, `STARCH_SACCHARIFICATION`, requires both
the endo-acting alpha-amylase reaction (`RXN_STARCH_ENDO_1_4`) and the
exo-acting alpha-glucosidase reaction (`RXN_MALTOOLIGO_EXO`). Alpha-1,6
debranching is accessory. A positive call means that the genome encodes the
complete curated saccharification route. It does not show expression, activity,
growth on starch, polymer degradation in culture, or any phenotype.

The required components have resolving orthologues and CAZy subfamilies, but
the current marker vocabulary also contains broad, ambiguous CAZy families.
`GH13` is attached to both required components and `GH57` to alpha-amylase;
their family membership cannot identify alpha-amylase or alpha-glucosidase on
its own. Generic CAZy/family evidence therefore cannot support the named
starch claim. This audit tests that boundary rather than assuming the
confidence label makes it effective.

No historical substrate-use record was used to select either candidate. The
labels below describe genomic ascertainment only, and neither row belongs in
`observations.tsv` or the prospective registry.

## Candidates

### Specific-positive candidate: *Bacillus licheniformis* DSM 13

NCBI's exact, complete type-material assembly
[`GCA_000008425.1`](https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/008/425/GCA_000008425.1_ASM842v1/GCA_000008425.1_ASM842v1_assembly_report.txt)
is strain-matched to DSM 13 / ATCC 14580. It was admitted because the
pre-screen found the resolving alpha-amylase orthologue `K01176` and
alpha-glucosidase orthologue `K01187`, which together cover the two required
reactions. This is evidence for an encoded route, not an observation that this
strain degrades starch.

### Broad-family control: *Hydrogenobacter thermophilus* TK-6

NCBI's exact, complete type-material assembly
[`GCA_000010785.1`](https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/010/785/GCA_000010785.1_ASM1078v1/GCA_000010785.1_ASM1078v1_assembly_report.txt)
is strain-matched to TK-6. The screening profiles found only broad `GH13` and
`GH57` CAZy hits among the markers for the required starch reactions: no
accepted starch orthologue and no resolving CAZy marker. It is a genomic
specificity control, not an expected negative for a future assay and not a
claim about its growth or substrate use.

*Dehalogenimonas lykanthroporepellens* BL-DC-9 was an initially attractive
one-`GH13` contrast, but NCBI labels its exact assembly `GCA_000143165.1`
contaminated. It is recorded as excluded in the roster rather than silently
used as a single-genome control.

## Exact-assembly audit — not a prospective outcome

[`15-priority1-starch-annotation.R`](../15-priority1-starch-annotation.R)
searched both exact NCBI protein FASTAs with every KOfam and CAZy marker
currently attached to the two required reactions. Its
[input manifest](starch-annotation-audit/input-manifest.tsv) pins both
proteomes, the KOfam models and adaptive thresholds, the dbCAN family and
subfamily libraries, their full-library `-Z` sizes, and gifter database
`2026.27.1` by SHA-256. The [marker-hit table](starch-annotation-audit/candidate-marker-hits.tsv)
retains each profile hit with score, independent E-value, profile coverage,
threshold and call. The [traces](starch-annotation-audit/starch-gift-traces.tsv)
end at the NCBI protein identifiers.

| Exact assembly | Resolving-marker route | Native call from all currently mapped marker rows | Specificity result |
| --- | --- | --- | --- |
| *B. licheniformis* DSM 13 `GCA_000008425.1` | complete through `AAU39594.1` (`K01176`) and `AAU39602.1` (`K01187`) | complete | expected specific-positive genomic evidence |
| *H. thermophilus* TK-6 `GCA_000010785.1` | incomplete; both required reactions lack resolving support | complete, with ambiguous evidence | **failure of the specificity contrast under the current database** |

The control's raw trace shows exactly why the second row is a failure:
`BAI68505.1` passes broad `GH13`, which currently maps to both required
components, while `BAI68730.1` passes broad `GH57` for alpha-amylase. With
only those two family annotations, the unmodified evaluator completes the
named starch GIFT at ambiguous confidence. When the same deposited hit set is
restricted to the resolving markers, the call is incomplete with both required
reactions missing. The audit's `broad_marker_only_completes_named_claim` value
is therefore `TRUE`, where the validation plan's curation contract expects
zero.

This result does not license starch degradation for TK-6. Broad CAZy families
cannot support the named substrate-specific claim; their current ability to
complete it is a biological-curation question exposed by the audit. No marker,
route, database source, SQLite artifact, schema, package API, or prospective
registry row has been changed here.

## Decisions still required before a prospective study

1. Review the `GH13`/`GH57` evidence rows and the Boolean consequences as a
   separate biological curation decision; do not remedy this audit finding by
   silently filtering an experimental annotation table.
2. Lock a named-polymer endpoint, the starch preparation and adjacent-substrate
   panel, culture/assay conditions, controls, biological replicate count and
   the rule for checking the relevant enzyme identities.
3. State how that endpoint relates to the starch-to-glucose boundary and retain
   the checksum-pinned profiles and gene traces alongside any later assay.
4. Only after that protocol is locked and matched observations exist, add
   registry rows and run `11-prospective-validation.R`.
