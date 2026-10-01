# Priority 1 candidate ascertainment: Type I-E CRISPR-Cas machinery

Status: candidate ascertainment and exact-assembly annotation audit completed
2026-10-01T13:00Z. This is neither a prospective assay result nor a GIFT
redefinition. The candidate roster is
[`type-ie-crispr-candidates.tsv`](type-ie-crispr-candidates.tsv).

## Question and invariant

`type_i_e_crispr_cas_machinery` is a defense GIFT with one curated mechanism,
`MECH_TYPE_I_E_CRISPR`. Its required functions are a five-component Type I-E
Cascade surveillance system—CasA (`K19123`), CasB (`K19046`), CasC (`K19124`),
CasD (`K19125`) and CasE (`K19126`) jointly—and fused Cas3
(`K07012`). Cas1 (`K15342`) plus Cas2 (`K09951`) spacer acquisition is
accessory. `K07475`, the standalone HD module of split Cas3, is explicitly
refused: it is not the required fused nuclease-helicase.

A positive call means only that a genome encodes that complete, curated protein
architecture. It does not establish a CRISPR array, guide RNAs, interference,
phage defence, expression, protein assembly, activity, or phenotype. An array
is a repeat-spacer genomic feature and is outside this protein-annotation audit.
Generic Cas1/Cas2 evidence and a partial Cascade cannot license the named
Type I-E machinery claim. Neither candidate is entered in `observations.tsv` or
the prospective registry.

## Candidates

### Specific-positive candidate: *Escherichia coli* K-12 MG1655

The exact complete MG1655 reference assembly
[`GCF_000005845.2`](https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_assembly_report.txt)
is strain-matched to K-12 substr. MG1655. It was selected from genomic evidence
only: the pre-screen found every required Cascade/Cas3 marker, together with
the accessory Cas1/Cas2 pair. This is not an observation of an assembled
Cascade complex, an array, or defense in MG1655.

### Incomplete-machinery control: *Alkalilimnicola ehrlichii* MLHE-1

The exact complete type-material assembly
[`GCA_000014785.1`](https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/014/785/GCA_000014785.1_ASM1478v1/GCA_000014785.1_ASM1478v1_assembly_report.txt)
is strain-matched to MLHE-1. Its pre-screen found Cas1/Cas2, fused Cas3 and
three of the five Type I-E Cascade markers, but no accepted CasA or CasE marker.
It is therefore an AND-logic control: the generic and partial machinery must
not complete the named architecture. It is not evidence that MLHE-1 lacks a
CRISPR array, another subtype, interference, defense, or any phenotype.

## Exact-assembly audit — not a prospective outcome

[`16-priority1-type-ie-crispr-annotation.R`](../16-priority1-type-ie-crispr-annotation.R)
searched both exact NCBI protein FASTAs with the eight KOfam profiles attached
to the pinned GIFT. Its [input manifest](type-ie-crispr-annotation-audit/input-manifest.tsv)
pins both proteomes, the content-addressed KOfam library and threshold table,
all extracted models, HMMER version, and gifter database `2026.27.1` by
SHA-256. The [marker-hit table](type-ie-crispr-annotation-audit/candidate-marker-hits.tsv)
retains every reported profile hit, score, adaptive threshold and call; the
[trace](type-ie-crispr-annotation-audit/type-ie-crispr-gift-traces.tsv) follows
the supported and missing functions to protein accessions.

| Exact assembly | Required I-E protein evidence | Accessory evidence | GIFT result |
| --- | --- | --- | --- |
| MG1655 `GCF_000005845.2` | `NP_417240.1`, `NP_417239.1`, `NP_417238.1`, `NP_417237.2`, `NP_417236.1` cover Cascade; `NP_417241.1` covers fused Cas3 | Cas1 and Cas2 both pass | complete; zero missing requirements |
| MLHE-1 `GCA_000014785.1` | CasB `ABI56306.1`, CasC `ABI56305.1`, CasD `ABI56304.1` and fused Cas3 `ABI56308.1` pass; CasA and CasE are unsupported | Cas1 `ABI56303.1` and accepted Cas2-family hits | incomplete; the one required Cascade system remains unsupported |

The MLHE-1 result is the intended specificity boundary: its accepted
generic/accessory Cas evidence and three supported Cascade components cannot
substitute for the two missing components of the jointly required surveillance
complex. The audit records `FALSE` with one missing requirement because Cascade
is one system; its trace retains CasA and CasE as the unsupported components.
It does not turn either candidate into a claim about arrays or defense outcomes.

No marker, biological source, SQLite artifact, schema or package API changed.
The audit also deliberately does not add a structural array detector: that
would be the separately deferred genomic-feature evidence-model decision in
the defense proposal, not a filtering choice for this analysis.

## Decisions still required before a prospective study

1. Lock a protein-machinery endpoint and independent component-identity rule
   that can distinguish a complete Type I-E complex from partial or other-subtype
   Cas evidence; define controls, culture conditions and biological replicates.
2. If array context matters to the study question, record it as a separately
   specified repeat-spacer genomic-feature assay. Do not silently use a protein
   call as array evidence.
3. Keep any interference or phage-challenge observation separate from this
   machinery claim; it needs guides, array context and its own pre-registered
   endpoint.
4. Only after that protocol is locked and matched observations exist, add
   registry rows and run `11-prospective-validation.R`.
