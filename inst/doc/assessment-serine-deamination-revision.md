# Assessment: split serine ammonia-lyase and the `K01752` over-call

Status: **implemented in biological database 2026.37.1 on 2026-10-04.** This reopens the
split-enzyme lead in [the NCBIfam discovery assessment](proposal-ncbifam-discovery.md)
under attempt `GEA-20261004-SERINE-DEAMINATION-REVISION`. It is a proposed
revision of the existing metabolic GIFT `serine_deamination`, not a new GIFT.
The original assessment below describes the previous source where relevant;
the release decision and measured impact are recorded at the end.

## Invariant and existing call

A positive `serine_deamination` call must support one complete enzyme system
for `RHEA:19169`, L-serine to pyruvate and ammonium. The current source has one
system, `SYS_19169_SDAA`, with one component. Either `KO:K01752` or
`KO:K17989` completes it. This represents a single-chain enzyme correctly only
when the observed accession identifies a complete single-chain protein.

The chemistry and boundaries are sound: [Rhea 19169](https://www.rhea-db.org/rhea/19169)
is the curated reaction, and the existing `SERINE` and `PYRUVATE` anchors are
unchanged. The defect is at the enzyme-system layer.

## The unresolved KO assignment is resolved

[KEGG K01752](https://www.kegg.jp/entry/ko:K01752) assigns both
`bsu:BSU15850` (*sdaAB*, beta) and `bsu:BSU15860` (*sdaAA*, alpha) in
*Bacillus subtilis* 168. The same two rows are present in the repository's
cached `genome-bsu.tsv` from the prior archaellum audit. KEGG also assigns
`K01752` to the single-chain *E. coli* `sdaA`, `sdaB` and `tdcG` proteins.
Thus `K01752` denotes **either one complete chain or one part of a split
enzyme**. Its EC and reaction assignment identify the chemistry but do not
identify a complete protein system.

The [NCBIfam alpha profile](https://www.ncbi.nlm.nih.gov/Structure/cdd/TIGR00718)
and [beta profile](https://www.ncbi.nlm.nih.gov/Structure/cdd/TIGR00719)
describe distinct split chains. The [single-chain profile](https://www.ncbi.nlm.nih.gov/Structure/cdd/TIGR00720)
explicitly separates that form from the *Bacillus* split form. In NCBIfam
`hmm_PGAP/20.0` the three profiles are equivalogs: `TIGR00718.1`,
`TIGR00719.1` and `TIGR00720.1`. A [study of *B. subtilis* serine
metabolism](https://pmc.ncbi.nlm.nih.gov/articles/PMC6620397/) identifies
SdaAA/SdaAB as a two-subunit complex. The stored RefSeq hit counts (15,278,
12,514 and 69,887) count proteins, not complete genomes or prospective GIFT
calls. NCBI currently annotates the *B. subtilis* [alpha
protein](https://www.ncbi.nlm.nih.gov/gene/937109) with TIGR00718 and the
[beta protein](https://www.ncbi.nlm.nih.gov/gene/935964) with TIGR00719;
neither gene page reports a TIGR00720 conserved-domain hit. These two proteins
are useful profile-overlap controls, not a frame-wide overlap audit.

The runtime consequence is reproducible with the packaged database:

```r
pkgload::load_all(".", quiet = TRUE)
x <- evaluate_gifts(data.frame(
  gene_id = "BSU15860", namespace = "KO", accession = "K01752"
))
x$gifts[x$gifts$gift_id == "serine_deamination", "complete"]
# TRUE
```

The one observed marker in this example stands for the alpha chain only. The
current one-component system calls the GIFT complete. The beta chain is not
evidenced. `gene_id` is retained for traceability but does not turn one
accession into a subunit-resolving marker.

## Defensible revision

Keep the reaction and route. Represent the following as alternative systems
under `RHEA:19169`:

| System | Required components and accepted evidence |
|---|---|
| Iron–sulfur single chain | One component, `NCBIFAM:TIGR00720.1` |
| Iron–sulfur split form | Alpha `NCBIFAM:TIGR00718.1` **and** beta `NCBIFAM:TIGR00719.1` |
| Existing `K17989` form | Retain the current single-protein evidence, as its own system if the source is revised |

Remove `KO:K01752` from this reaction's accepted component markers. It cannot
be repaired by attaching the same KO to two required components: one observed
accession satisfies both in the current marker-to-component model, and even two
KO-assigned genes would not tell a single-chain paralogue from the two distinct
split chains. Lowering its confidence would still make an unsupported GIFT
positive. `NF011598.0` *sdaA* and `NF011614.0` *tdcG* are additional
single-chain equivalog candidates in the prior screen, but should be admitted
only after the same overlap audit as `TIGR00720.1`.

This revision **narrows** KO-only calls and **broadens** calls from inputs that
carry the three distinguishing NCBIfam profiles. It also restores the explicit
OR-across-systems and AND-across-subunits model. A KO-only input containing
`K01752` would no longer license a positive GIFT call; no available Boolean use
of that accession can distinguish the two protein architectures.

## Audit and release decision

`data-raw/serine_deamination_marker_audit.py` uses the repository's fixed KEGG
frame, current KEGG gene links, NCBIfam `hmm_PGAP/20.0` profiles and their
published gathering thresholds. It samples 40 genomes each with one, two, or
at least three `K01752` genes by deterministic SHA256 rank, then adds the
named *E. coli* and *B. subtilis* controls. The gene-level and genome-level
results are committed in `data-raw/reference/serine-deamination-*-audit.tsv`.
The cached downloaded sequences and HMMs are not source tables.

The flag-defined frame contains 11,908 entries; its `prokaryote` flag is known
to admit some eukaryotes, so this is an annotation frame, not a taxonomic
prevalence estimate. `K01752` occurs in 6,994 of its genomes (10,845 genes)
and `K17989` in 1,084; 283 genomes have both. A KO-only input would move from
7,795 positive genomes to 1,084 if `K01752` alone is retired. The resulting
6,711 lost KO-only calls describe missing architecture-resolving annotations,
not 6,711 biological absences.

The paired sample has 122 genomes and 257 `K01752`-assigned proteins. The
revised systems are supported on the audited proteins or by `K17989` in 120
genomes: 40/40 one-copy, 39/40 two-copy, 39/40 three-or-more-copy, and both
named controls. *B. subtilis* BSU15860 passes only the alpha profile and
BSU15850 only beta. The three *E. coli* single-chain controls pass only
`TIGR00720.1`. Two sampled genomes have no complete profile-supported system
on the audited `K01752` proteins: `lad` has an alpha hit and one no-hit protein;
`btm` has two beta hits and one no-hit protein. One protein,
`pcat:Pcatena_15640`, passes both alpha and beta profiles in non-overlapping
regions, a plausible gene fusion; two distinct subunit *functions* remain
required but two distinct gene identifiers do not.

The screen did not search every protein in the 11,908 genomes for NCBIfam
profiles. It therefore cannot give the exact mixed-input call delta or prove
the two sampled genomes lack an alternative unannotated protein. The
architecture-specificity defect is directly established by the *B. subtilis*
control, and the representative profile audit supports replacing the broad KO
without waiting for a full-frame prevalence estimate. The release gives the
iron–sulfur single-chain system `TIGR00720.1`, the split system both
`TIGR00718.1` and `TIGR00719.1`, and a separate unchanged `K17989`
single-protein system. `K01752` is removed. Reaction `RHEA:19169`, direction,
anchors and GIFT identity remain unchanged.
