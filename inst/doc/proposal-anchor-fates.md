# Curation proposal: fates for anchors that had only one

Status: **assessed and implemented as database version 2026.22.1, schema 7
unchanged.** Three GIFTs, two anchors, four reactions, five markers. No new
`gift_type`, no new namespace, no schema change, no runtime conditional.

**Decision timestamp:** 2026-08-22T19:20Z

**Source:** the discovery half of
[the marker specificity screen](proposal-marker-specificity-screen.md).
`data-raw/reference/discovery-candidates.tsv` ranks uncurated single-reaction
KEGG orthologues by how specific the declared anchor they touch is; this release
is the top of that ranking, filtered by the rule below.

---

## 1. Decision summary

| Candidate | Decision | Decisive reason |
|---|---|---|
| `ectoine_degradation`, ectoine to L-2,4-diaminobutanoate | **implement** | DoeA and DoeB are the ectoine-specific steps, both single-reaction orthologues at 788 and 573 organisms. Cut at DABA for a structural reason, §3. |
| `hydroxyectoine_biosynthesis`, ectoine to 5-hydroxyectoine | **implement** | A distinct compatible solute, one specific orthologue at 903 organisms, and only some ectoine producers carry it. |
| `lactate_formation_lactaldehyde`, (S)-lactaldehyde to (S)-lactate | **implement** | Gives the lactaldehyde branchpoint its second branch and joins the sugar layer to the organic acid layer through an anchor both already declare. |
| Pantothenate to coenzyme A | **refused, already** | The vitamin proposal §8.2 refuses cofactor activation: a trait complete in every genome partitions nothing and carries annotation noise. |
| Pimelate to pimeloyl-CoA, BioW | **defer** | The biotin proposal refused precursor supply at the layer level. §5.1. |
| DoeD and DoeC, the rest of ectoine catabolism | **defer** | Their reaction is shared with ectoine biosynthesis and the schema has no route-scoped evidence. §3. |
| Chitin deacetylation, allantoin racemisation, the oxidative rhamnose route | **defer** | §5.2. |

The rule that filtered the queue: **a candidate is worth curating when it gives
a declared anchor a fate it did not have.** That is the composition dividend the
architecture guide asks for, and it is why a single-reaction GIFT can be
justified here while the same reaction elsewhere would be an arbitrary fragment.

## 2. What the discovery screen got wrong, and what that means

Two of the four candidates this release started from were already refused, in
prose, in proposals whose decision tables do not mention them. Pantothenate to
CoA is refused by the vitamin proposal's §8.2; the biotin precursor supply is
refused by its §6.7. Neither had a row in
[the deferral register](deferral-register.md) until this release added one.

The screen ranked pantothenate kinase highly because `PANTOTHENATE` is a
low-degree anchor and `coaA` is a single-reaction orthologue. Both are true, and
the trait would still be worthless, because **the screen has no saturation
filter**. A capability present in essentially every genome partitions nothing.
`coaA`, `coaX` and `coaW` together are near-universal in bacteria, and the
vitamin proposal measured exactly this failure mode for the flavin kinase step:
complete in all eighteen reference genomes, including the six that cannot make
riboflavin.

Recorded as a limitation of the screen, and as the next thing to add to it: a
prevalence column, and a flag for candidates whose prevalence is high enough
that the trait would be uninformative. Anchor specificity says a candidate is
*markable*; it says nothing about whether it is *worth marking*.

## 3. Ectoine degradation, and why it stops at DABA

`ectoine_degradation` is `metabolic`, `catabolic`, from `ECTOINE` to a new
`DABA` anchor (L-2,4-diaminobutanoate, CHEBI:58761).

| Step | Reaction | Orientation | Enzyme | Marker |
|---:|---|---|---|---|
| 1 | `RHEA:52304` | forward | DoeA ectoine hydrolase | `K15783` |
| 2 | `RHEA:40951` | forward | DoeB N2-acetyldiaminobutanoate deacetylase | `K15784` |

KEGG's module `M00919` runs on through DoeD and DoeC to L-aspartate, and is
linked `subset_of`. gifter stops two steps earlier, for a reason that is worth
stating plainly because it is a limitation of the evidence model rather than a
biological judgement.

DoeD catalyses `RHEA:11160`, the diaminobutanoate transamination. So does EctB —
`ectoine_biosynthesis` already curates that reaction, traversed in reverse. When
that GIFT was curated, `K15785` was explicitly refused as an EctB alternative,
because KEGG assigns it to degradation and it does not establish the
biosynthetic direction.

Enzyme systems attach to **reactions**, not to routes. Adding a DoeD system to
`RHEA:11160` would therefore make `K15785` admissible evidence wherever that
reaction appears, including the biosynthetic route — silently reversing a
recorded refusal. There is no route-scoped evidence layer to confine it to the
degradative direction.

Cutting at DABA avoids the problem, and it is also the right cut on the ordinary
rule: the ring hydrolysis and the deacetylation are ectoine-specific chemistry,
and everything after them is generic amino-acid chemistry. The cost is honest
and recorded: `DABA` is an output-only anchor with no consumer, and the two
remaining steps of the module are deferred rather than refused.

**The proper fix, if it is ever wanted, is route-scoped enzyme systems**, which
would let one reaction carry different evidence in different directions. That is
a schema change and belongs in its own proposal. Until then this boundary is
where the model can defend itself.

## 4. The other two

### 4.1 Hydroxyectoine

`hydroxyectoine_biosynthesis` is `metabolic`, `anabolic`, `ECTOINE` to a new
`HYDROXYECTOINE` anchor (CHEBI:85413), through `RHEA:45740` forward, evidenced by
`K10674` *ectD* at 903 organisms. The route is marked `aerobic`: EctD is a
2-oxoglutarate-dependent dioxygenase and the chemistry consumes O2.

Not a fourth step of the biosynthetic route, because the product is a different
solute rather than a modified intermediate, and because folding it in would give
every EctABC genome the same call as every EctABCD genome. The 2-oxoglutarate
co-substrate and its succinate product are internal chemistry and are not
declared anchors, following the taurine dioxygenase and the cofactor-anchor rule.

### 4.2 Lactaldehyde oxidation

`lactate_formation_lactaldehyde` is `metabolic`, `catabolic`, `LACTALDEHYDE` to
`LACTATE_L`, through `RHEA:14277` forward.

`LACTALDEHYDE` has been an anchor since the SCFA release with exactly one fate,
FucO's reduction to propane-1,2-diol. A branchpoint with one branch is not yet a
branchpoint. The oxidative fate is what fucose and rhamnose catabolism feed, and
it lands on `LACTATE_L`, which `lactate_formation`, `malolactic_fermentation`
and `lactate_racemisation` already declare.

A separate GIFT rather than a second route of `lactate_formation`, because the
input boundary differs and anchors are declared per GIFT — the same reasoning
that made the hydrolytic and beta-elimination pectin routes two capabilities.

Two markers on one component: `K19266` is a single-reaction orthologue at 59
organisms, and `K07248` *aldA* at 995 also carries EC 1.2.1.21 for
glycolaldehyde. The specificity screen's distinction decides it: AldA is a
promiscuous enzyme rather than an ambiguous orthologue, it genuinely performs
this reaction, and the route's input anchor states which substrate the GIFT is
about. Admitted as an OR alternative, with the breadth recorded in its `notes`.

## 5. Deferrals

### 5.1 Pimelate to pimeloyl-CoA

`K01906` *bioW* is a single-reaction orthologue at 365 organisms for
`RHEA:14781`, and `PIMELOYL_COA` is already a declared anchor — the input of
`biotin_biosynthesis`, which currently assumes a precursor nothing in the
database produces. On the surface this is the same "give an anchor its missing
fate" case as the three above.

Deferred, because the biotin proposal §6.7 refused the precursor supply trait at
the layer level: BioW is one of at least four non-homologous solutions, and
curating one of them would make "encodes biotin precursor supply" answerable
only for the lineage that scavenges free pimelate. Curating BioW alone would
also introduce `PIMELATE` as a source anchor that nothing else in the database
touches.

Unblocks when either the other precursor routes can be curated to the same
standard, or the claim is renamed for the specific chemistry rather than for
precursor supply. Both are judgements for a biotin-layer proposal, not for this
one.

### 5.2 Three smaller ones

- **Chitin deacetylation** (`K01452`, `RHEA:10464`). A real second fate for the
  `CHITIN` anchor, but chitosan would be an output-only anchor with no consumer,
  and unlike DABA there is no curated chemistry waiting on the other side.
- **Allantoin racemisation** (`K16841`, `RHEA:10804`). Would need an
  `ALLANTOIN_R` anchor whose only purpose is to be the other side of a racemase.
  `lactate_racemisation` is the precedent for admitting one, so this is a
  judgement about whether the (R) form is a boundary anyone reads.
- **The oxidative rhamnose route** (`K12660`, `K18339`, `RHEA:25784`). Not a new
  GIFT: it is an alternative *route* of the existing `rhamnose_degradation`,
  which would raise sensitivity rather than add a capability. It needs the LRA1
  to LRA3 steps checked before the route can be materialised, and that is a
  self-contained follow-up.

## 6. Tests

- AND across the two required reactions of ectoine degradation, in both
  directions of omission.
- **The boundary decision itself**: `K15785` matches no marker in the database,
  and `ectoine_degradation` declares `DABA` as its output. If a future change
  admits DoeD, this test fails and the curator is sent back to §3.
- Neither ectoine fate fires the biosynthetic GIFT, and EctABC does not fire the
  hydroxylase.
- `ECTOINE` is declared by exactly three GIFTs, and the graph now draws it as a
  shared anchor.
- OR across the two lactaldehyde markers, and the negative case that neither
  fires `lactate_formation` or `propanediol_formation`.

Inventory assertions updated in `test-database.R`, `test-dataset-traits.R`,
`test-organic-acid.R` and `test-sugar-degradation.R`, as every content release
has had to do.

## 7. Provenance

Rhea release 141: `RHEA:52304`, `RHEA:40951`, `RHEA:45740`, `RHEA:14277`. ChEBI
release 253 for `CHEBI:58761` and `CHEBI:85413`. KEGG orthology and organism
counts verified 2026-08-22 through `rest.kegg.jp`, counted as distinct organisms
carrying the accession; that denominator is not the same as the genome counts
used by earlier proposals and the two are not comparable. KEGG module `M00919`
and pathway maps `map00260` and `map00620`.
