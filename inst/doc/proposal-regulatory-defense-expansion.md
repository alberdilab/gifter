# Regulatory and defense GIFT expansion: October 2026 assessment

Status: **curated 2026-10-04**. This bounded pass reopens the previously proposed
antimicrobial detoxification mechanisms and screens additional regulatory and
defense capabilities against the typed completeness and marker-specificity
contracts. It revisits GEA-20260818-REGULATORY, GEA-20260818-DEFENSE,
GEA-20260820-NEXT-RELEASE and GEA-20260822-ANTIMICROBIAL-DETOX.

## Decision

| Candidate | Decision | Evidence boundary |
|---|---|---|
| `serine_chemoreception` | Curate | Tsr-specific NCBIfam equivalog plus the four required chemotaxis functions. |
| `beta_lactam_detoxification` | Curate | EC 3.5.2.6 enzyme orthologies partitioned among four Ambler-class systems. |
| `chloramphenicol_detoxification` | Curate | Two chloramphenicol O-acetyltransferase orthologies as alternative systems. |
| PhoQ/PhoP magnesium response | Defer | The pair is biologically defined, but a frame-wide orthology and pairing calibration has not been made. |
| OxyR/PerR peroxide response | Defer | The known regulator does not identify a complete lineage-specific response circuit. |
| Additional CRISPR-Cas subtype | Defer | No subtype-complete protein inventory was audited here; an array remains outside the marker input. |

The biological invariant is that a positive call means **encoded, complete
machinery at the specificity of its markers**. None of these calls claims
expression, taxis, antimicrobial susceptibility, or successful interference.

## Serine chemoreception

The existing `aspartate_chemoreception` GIFT uses Tar as its distinct receptor
function and shares CheA-CheW, CheY and CheR-CheB with the core chemotaxis
circuit. The new serine circuit has the same Boolean shape with a Tsr-specific
reception function. The receptor requires NCBIfam `NF011615.0`, previously
identified as an equivalog distinct from Tar `NF011622.0` in
[`proposal-ncbifam-namespace.md`](proposal-ncbifam-namespace.md). The
[experimentally characterised *E. coli* Tsr protein](https://www.uniprot.org/uniprotkb/P02942/entry)
binds L-serine and matches the NCBIfam profile. [KEGG K05874](https://www.kegg.jp/entry/K05874)
names Tsr as a serine sensor, but the group also assigns multiple paralogues in
some genomes. That is not evidence that every assigned receptor has the same
ligand-binding domain. K05874 remains accepted only for the broad core
chemoreceptor function; the serine-specific function accepts `NF011615.0`
alone. `NF011615.0` also supports the core characterised-receptor component:
a complete serine circuit must imply the broader core chemotaxis circuit, even
when the Tsr annotation uses only NCBIfam. This makes the new GIFT conservative
for KO-only input and broadens the core call for NCBIfam-only Tsr input.

The new circuit reuses the three downstream functions rather than copying their
systems. A Tsr marker alone is incomplete; the receptor and all three
downstream functions are required. A generic MCP or the Tar KO cannot complete
the serine call. The result says that serine-responsive input machinery is
encoded, not that cells swim toward serine. The NCBIfam profile is a Tsr
equivalog and will under-call unrelated serine receptors; widening the marker
requires a separate ligand-domain audit.

The circuit is linked to KEGG bacterial chemotaxis map02030 as `subset_of`:
the map includes other receptors and the flagellar motor.

## Antibiotic detoxification

The detailed prior evidence and refusal screen is
[`proposal-antimicrobial-detoxification.md`](proposal-antimicrobial-detoxification.md).
This pass accepted its two proposed GIFTs without changing the meaning of
`chemical_detoxification`: the toxic compound itself is enzymatically
converted. [Rhea `RHEA:20401`](https://www.rhea-db.org/rhea/20401) states
class-level beta-lactam hydrolysis, and [Rhea `RHEA:18421`](https://www.rhea-db.org/rhea/18421)
states chloramphenicol 3-O-acetylation. The chemistry is documented as evidence
for a defense function, not inserted into the metabolic route tables; defense
GIFTs have no anchors or mode.

The beta-lactam function has four alternative systems: Ambler classes A, B, C
and D. The 66 KO accessions were taken from the versioned
[`ko-reaction-specificity.tsv`](../../data-raw/reference/ko-reaction-specificity.tsv)
screen, where each has EC 3.5.2.6 and maps to RHEA:20401: 18 class A, 8 class
B, 9 class C and 31 class D. Every accession names a beta-lactamase enzyme,
not merely the metallo-beta-lactamase fold; the class B fold also includes
glyoxalase II. An allele-specific KO is accepted as evidence for the broad
hydrolysis claim, never for its drug spectrum. The prior KEGG complete-genome
screen found the four-system union in 5,010 of 11,949 genomes. Those prevalence
figures date from 2026-08-22 and were not remeasured in this pass.

The chloramphenicol function has two alternative systems, with
[KEGG K19271](https://www.kegg.jp/entry/K19271) for type A and
[KEGG K00638](https://www.kegg.jp/entry/K00638) for type B. Both are assigned
EC 2.3.1.28 and reach RHEA:18421 in the same versioned specificity screen. The
prior KO-union prevalence was 1,777 genomes. Type B is a member of a wider
hexapeptide acyltransferase family, so its KO-to-EC assignment is the relevant
specificity test. A future widening of that KO requires regrading its marker.

These two functions each have one required step, like the existing MerA
mechanism. Their value in the atlas is the curated boundary, the alternative
enzyme implementations, the accepted marker inventory, and the refusal to
convert a biochemical call into an antimicrobial-resistance phenotype. The
`challenge_class` facet now records `antimicrobial` for both, and retrospectively
classifies mercury as `metal`, superoxide as `oxidative`, and methylglyoxal as
`electrophile`. This facet identifies the challenge; `defense_class` continues
to identify the mechanism.

## Candidates left open

PhoQ and PhoP have distinct orthology labels, and [PhoQ has a characterised
cognate PhoP partner](https://www.ncbi.nlm.nih.gov/gene/946326). The question
left by the existing PhoR/PhoB curation is whether those accessions uniquely
recover a *paired* magnesium-responsive circuit across the target genomes and
whether the signal name remains valid beyond the experimental lineage. This
pass did not obtain the multi-genome gene-count and pairing calibration that
licensed `phosphate_starvation_response`, so it does not create a PhoQ/PhoP
GIFT from two markers alone. A measured orthology/pairing audit plus a
lineage-bounded signal claim would retrigger it.

OxyR and PerR remain deferred for the reason in
[`proposal-next-gift-release.md`](proposal-next-gift-release.md): a regulator
orthology is not the complete response arm, and the regulons vary by lineage.
The retrigger is a specific circuit with independently markable signal and
output roles, or a general context-evidence model.

An additional CRISPR-Cas protein-machinery GIFT could be named for a subtype
only after auditing an entire subtype-specific surveillance and interference
inventory. It would still make no array or interference claim: a repeat-spacer
array is not an annotation accession. This pass did not find or audit such a
complete inventory, so adding a second subtype on a generic Cas marker would
violate the existing defense boundary. The standing retrigger is in
[`proposal-defense-gifts.md`](proposal-defense-gifts.md).

The earlier refusals of broad ligand-specific MCP evidence, antimicrobial
resistance phenotypes, target-sequence claims, efflux-as-detoxification and
generic Cas evidence remain in force. None was reopened by a new evidence
model or a measured specificity result.
