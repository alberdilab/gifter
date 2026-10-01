# Priority 1 candidate ascertainment: collagen specificity

Status: candidate ascertainment and exact-assembly annotation audit completed
2026-10-01T08:05Z. This is not a prospective result and not a GIFT redefinition.
The machine-readable roster is
[`collagen-specificity-candidates.tsv`](collagen-specificity-candidates.tsv).

## Question and invariant

The first Priority 1 contrast tests `collagen_cleavage`. Its positive claim is
not generic extracellular proteolysis: the current GIFT means that a genome
encodes family-M9 evidence for cleavage of native triple-helical collagen. A
gelatin plate, a broad host-protein assay, or a `lasB` hit cannot be promoted to
that claim.

Candidates were selected from published phenotype and strain/assembly records
before reading gifter calls. Every historical result below is selection
evidence only. The future assay must use the deposited strain/genome pair and
record its own raw endpoint, conditions and biological replicates.

## Candidates admitted to the next protocol draft

### Specific-positive candidate: *Hathewaya histolytica* ATCC 19401

The 1994 characterisation used *Clostridium histolyticum* JCM 1403 and found
that its ColH collagenase degrades native as well as denatured collagen
([Yoshihara et al.](https://pubmed.ncbi.nlm.nih.gov/7961400/)). The current
name is *Hathewaya histolytica*. The strain registry identifies JCM 1403, ATCC
19401 and NCTC 503 as the same type strain and connects NCTC 503 to assembly
[`GCA_901482605.1`](https://www.ncbi.nlm.nih.gov/assembly/GCA_901482605.1/)
([strain record](https://registry.seqco.de/strains/27507)). This makes it a
valid candidate for an intact type-I-collagen endpoint, whose relation to the
generic collagen boundary is `subset_of`.

The planned generic-protease comparator must be measured separately. The
historical result is not copied into `observations.tsv`, and no growth, secreted
activity or phenotype is inferred from the genome.

### Broad-marker control: *Pseudomonas aeruginosa* PAO1

PAO1 has an exact reference assembly,
[`GCF_000006765.1`](https://www.ncbi.nlm.nih.gov/bioproject/57945/), and the
reference gene record identifies `lasB` / pseudolysin
([NCBI Gene 880368](https://www.ncbi.nlm.nih.gov/gene/880368)). It is useful
because it is a broad extracellular metalloprotease rather than a family-M9
collagenase. In a PAO1 secretome study, LasB-dependent degradation was strong
for fibronectin and vitronectin while type-I-collagen degradation was limited
([Beaufort et al.](https://pubmed.ncbi.nlm.nih.gov/21501369/)).

This is deliberately a **broad-marker-only genetic control**, not a guaranteed
negative intact-collagen control. Other experimental contexts report direct
collagen effects of PAO1 elastase, which is precisely why the planned experiment
needs the native-collagen assay and generic-protease assay side by side. Before
any call is interpreted, an independent domain/sequence check must establish
whether this exact assembly contains M9 evidence; a `lasB` assignment alone
cannot stand in for that check.

## Exclusion recorded now

*Vibrio alginolyticus* CIP 82.01 was reported to cleave native collagen in its
helical region ([Emod et al.](https://doi.org/10.1099/00207713-33-3-451)), but
this screen did not establish a deposited assembly for that strain. The sequenced
ATCC 17749 type strain is therefore not substituted. A same-species genome would
turn a strain-specific observation into a species-level assumption, exactly the
confound this plan excludes.

Similarly, the existing BacDive gelatin observations remain excluded: gelatin
is denatured collagen and the retrospective crosswalk already marks it
`refused` for `collagen_cleavage`.

## Initial annotation audit — explicitly not a prospective outcome

After the candidate screen, the existing annotation-route cache was inspected
for the admitted *H. histolytica* assembly. Its stored annotation input is
`manuscript/analysis/.cache/annotation/hmm/hhw.rds`, from the manuscript's
KOfam/NCBIfam/Pfam/dbCAN comparison. Evaluated against gifter database
`2026.27.1`, it completes `COLLAGEN_M9`: two annotated proteins,
`VTQ92554.1` and `VTQ90952.1`, each carry `KO:K01387` and `PFAM:PF01752`.
`trace_gift()` therefore reports a complete `RXN_COLLAGEN_HELIX_CLEAVAGE` and
the route's minimum missing requirement is zero.

This is a useful annotation audit only. The cached run predates this protocol
and does not record an immutable release identifier for every profile library,
so it cannot enter the prospective registry or serve as the study's annotation
version. It also supplies no new assay observation.

## Exact-assembly M9 audit — still not a prospective outcome

The new reproducible audit reran only the relevant M9 contrast on freshly
downloaded NCBI protein FASTAs for both exact assemblies. Its
[input manifest](collagen-annotation-audit/input-manifest.tsv) records the
source URLs and SHA-256 hashes of both proteomes, the content-addressed KOfam
library and threshold table, extracted `K01387` model, `PF01752.24` Pfam model,
and the evaluated gifter SQLite (`2026.27.1`). It used HMMER 3.4 and records all
retained hits and the final gifter trace in
[`collagen-annotation-audit/`](collagen-annotation-audit/). The runner is
[`12-priority1-collagen-annotation.R`](../12-priority1-collagen-annotation.R).

| Exact assembly | Independent M9/domain evidence | gifter result | Control interpretation |
| --- | --- | --- | --- |
| *H. histolytica* `GCA_901482605.1` | `VTQ90952.1` and `VTQ92554.1` pass KOfam `K01387` (domain scores 499.8 and 498.3; threshold 186.63) and Pfam `PF01752` at its gathering threshold | `collagen_cleavage` complete through `COLLAGEN_M9`; zero missing requirements | `specific_evidence` |
| PAO1 `GCF_000006765.1` | no `PF01752` gathering-threshold hit; the sole low-scoring `K01387` comparison (domain score 5) fails the 186.63 threshold | `collagen_cleavage` incomplete; one missing requirement | `broad_marker_only`: the exact FASTA header identifies `NP_252413.1` as elastase LasB, but that header was not given to gifter |

The PAO1 result is a genomic specificity control, not an intact-collagen
phenotype-negative result. Conversely, the *H. histolytica* call means genomic
support for the curated M9 route only. Neither row measures secretion, growth,
cleavage under a culture condition, or any physiological outcome. The audit
therefore remains outside `studies.tsv`, `samples.tsv`, `annotations.tsv`, and
`observations.tsv` until a protocol has been locked and matched assays exist.

## What must happen before the runner is used

1. Decide the exact intact-collagen and generic-protease endpoints, culture
   conditions, inclusion/exclusion rules and replicate count, then lock them.
2. Reuse or independently reproduce the checksum-pinned exact-assembly audit
   above, retaining the annotation rows and gene identifiers selected under the
   locked study protocol.
3. Collect the matched assays. Only then add rows to `studies.tsv`,
   `samples.tsv`, `annotations.tsv` and `observations.tsv` and run
   `11-prospective-validation.R`.

No database source, GIFT claim, marker assignment or SQLite artifact changes
follow from this candidate screen.
