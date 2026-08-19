# Curation proposal: shikimate-derived aromatic biosynthesis

Status: **three of four candidates accepted and implemented in database version
2026.17.1 (schema 6); one refused.** The implementation record, including every
point where it departed from the provisional design, is §9.

Evidence test applied 2026-08-18 against database version 2026.16.1 (schema 6,
72 GIFTs), the KEGG release of 2026-08-18 (11 949 genomes, of which **10 151
bacterial** and **470 archaeal**), Rhea release 141 and ChEBI release 253. Every
genome count below is a set operation over `link/genes/ko:` membership
intersected with the bacterial or archaeal leaves of KEGG BRITE `br08601`, which
is the same method the vitamin layer used; it reproduces that layer's published
`paba_biosynthesis` figure of 5088 exactly, which is the check that the method
is the same one.

Scope: decide whether chorismate, salicylate, indole-3-acetate and gallate can
be stated as GIFTs, at what boundaries, and whether the four of them should be
grouped above the GIFT level.

---

## 1. Recommendation in one page

1. **Curate three GIFTs, refuse one.** `chorismate_biosynthesis` (7644
   bacteria, 90 archaea), `salicylate_biosynthesis` (646 bacteria, no
   archaeon) and `indole_3_acetate_biosynthesis` (86 bacteria) are added.
   `gallate_biosynthesis` is **refused**, and not on the specificity ground the
   brief anticipated — it fails earlier than that. §6.
2. **Do not make aromatic compound biosynthesis one GIFT.** It is a chemical
   family, not a directed capability between anchors. The four candidates share
   an origin and nothing else: two of them do not even touch chorismate at both
   ends. §2.
3. **Group them with a new `biosynthetic_family` facet**, value
   `shikimate_derived_aromatic`, assigned to the three new GIFTs and to the two
   chorismate consumers that already existed. `substrate_class` was **not**
   reused, and the reason is testable rather than stylistic. §7.
4. **Chorismate is the right terminal anchor** and PEP + E4P the right input
   pair. The pathway is not cut at 3-dehydroquinate or 3-dehydroshikimate
   despite an archaeal argument for doing so, because neither is a branchpoint
   in giftr today. §3.
5. **Curate the shikimate dehydrogenase step as not required.** Requiring it
   drops the route from 7644 to 5420 bacteria and removes 201 of 213
   Cyanobacteriota and 1061 of 1642 Actinomycetota — organisms that make
   aromatic amino acids and carry the gene. This is the vitamin layer's orphan
   step rule applied to a step whose KO has a taxonomic hole rather than a
   specificity problem, and it is the one place this layer widens a call. §4.
6. **PchA/PchB and MbtI are alternative enzyme systems, not alternative
   routes.** They run the same two transformations; MbtI merely does both in one
   active site. giftr already curates that shape once, as the bifunctional
   PabBC. Materialising a second route would assert a different minimal chemical
   path where there is none. §5.
7. **Curate only the IAM route to the auxin.** The indole-3-pyruvate, tryptamine,
   indole-3-acetonitrile and side-chain oxidase routes are refused: every one of
   them is real chemistry whose markers cannot distinguish it from ordinary
   transamination, decarboxylation or aldehyde oxidation. §5.
8. **No schema migration and no R change.** Everything the layer needs exists:
   `required = 0`, `oxygen_requirement = 'aerobic'`, multiple input anchors, an
   open facet vocabulary, and enzyme systems that attach to reactions so a
   reaction can be shared between GIFTs.

---

## 2. Why this is not one GIFT

The request named a family — shikimate-derived aromatics — and a family is not
a capability. A GIFT is a directed claim between declared anchors, and the four
candidates do not share a pair of anchors:

```text
PEP + E4P          -> chorismate
chorismate         -> salicylate
L-tryptophan       -> indole-3-acetate
3-dehydroshikimate -> gallate            (refused)
```

Two of the four do not have chorismate on either side of the arrow. A single
"aromatic compound biosynthesis" GIFT would have to declare an input set that no
route consumes and an output set no route produces, and its route table would be
the union of four unrelated reaction sequences under OR — meaning a genome that
can only make salicylate would be called an aromatic compound producer
indistinguishably from one that can only make the auxin. That is invariant 9's
"bundle of independently meaningful capabilities", and the composition model
already gives the grouping for free through the shared `CHORISMATE` anchor.

What the family *is* good for is classification, which is what §7 does with it.

---

## 3. Where to cut chorismate biosynthesis

### The terminal anchor

Chorismate is the strongest anchor in the layer. It is the last metabolite the
aromatic amino acids, folate's pABA half, menaquinone, salicylate and the
enterobactin aryl group have in common, and every one of those is a separately
callable capability. Two of them were already curated as GIFTs consuming
`CHORISMATE` with nothing producing it, so the anchor was already carrying its
weight before this layer existed; the layer supplies the missing producer.

Carrying the GIFT past chorismate to phenylalanine, tyrosine or tryptophan would
bundle three capabilities that genomes vary in independently. Stopping short of
it — at shikimate, say — would leave an anchor with exactly one consumer.

### The input anchors

`PEP` is new; `E4P` already existed as the input of `plp_biosynthesis_dxp`.
Phosphoenolpyruvate is consumed twice by the pathway, once by DAHP synthase and
once by EPSP synthase, and is declared once.

Neither is produced by any curated GIFT, so no directed cycle is created; the
build's acyclicity scan confirms it.

### Why the pathway is not cut at 3-dehydroquinate

There is a real argument for cutting it, and it is archaeal. Most archaea do not
build 3-dehydroquinate from PEP and erythrose 4-phosphate at all: they condense
6-deoxy-5-ketofructose 1-phosphate with L-aspartate semialdehyde and use a
non-homologous dehydroquinate synthase II. The numbers show it plainly:

| Segment | Bacteria | Archaea |
|---|---|---|
| PEP + E4P to 3-dehydroquinate | 8161 | **93** |
| 3-dehydroquinate to chorismate | 5539 | **352** |
| Second segment but not the first | 119 | **270** |

266 of those 270 archaea carry `K11646`, dehydroquinate synthase II — the
signature of the alternative early route.

The cut was still rejected, for three reasons. 3-dehydroquinate has exactly one
fate, so it is not a branchpoint, and invariant 3 asks for a branchpoint, a
stable product or an environmental compound rather than any metabolite that
happens to sit at a convenient join. The resulting upstream GIFT would be a
two-step fragment, which invariant 9 rules out. And in bacteria — the domain
giftr's content is aimed at — the split distinguishes only 119 genomes.

The archaeal route is therefore recorded as a **deliberate exclusion, not an
omission**: it consumes different precursors, so it cannot be a route between
these anchors at all. If it is ever curated it becomes its own GIFT, and the
anchor it needs is 3-dehydroquinate or 3-dehydroshikimate. The moment there is a
second consumer of either — the 3-dehydroshikimate dehydratase route to
protocatechuate is the obvious candidate — the cut should be revisited.

### KEGG M00022 was consulted, not copied

M00022 has the same endpoints, which is worth stating rather than hiding. The
curated definition differs in three ways, and the xref relation is `overlaps`
rather than `equivalent` because of them: giftr does not require the shikimate
dehydrogenase step (§4), accepts YdiB for it, and drops `K13830`, the
pentafunctional AROM polypeptide, which **no prokaryotic genome in KEGG
carries** — 0 of 10 151 bacteria and 0 of 470 archaea.

---

## 4. The shikimate dehydrogenase step

The pathway's seven steps are annotated very unevenly:

| Step | Orthology groups | Bacteria |
|---|---|---|
| DAHP synthase | K01626, K03856, K13853 | 8461 |
| dehydroquinate synthase | K01735, K13829 | 8839 |
| dehydroquinate dehydratase | K03785, K03786, K13832 | 9015 |
| **shikimate dehydrogenase** | **K00014, K13832** | **5833** |
| shikimate kinase | K00891, K13829 | 8865 |
| EPSP synthase | K00800, K24018 | 9020 |
| chorismate synthase | K01736 | 9149 |

Requiring all seven gives 5420 bacteria; requiring the other six gives 7644. The
2224 genomes in the gap are not a random sample:

| Phylum | In the gap | Total |
|---|---|---|
| Actinomycetota | 1061 | 1642 |
| Bacilli | 320 | 1321 |
| Clostridia | 220 | 395 |
| **Cyanobacteriota** | **201** | **213** |

94% of cyanobacteria is not biology. Two spot checks settle it: *Mycobacterium
tuberculosis* Rv2552c and *Synechocystis* slr1559 are both annotated "shikimate
5-dehydrogenase" in RefSeq and are assigned to **no KO at all**.

The step is therefore curated with `required = 0`, the orphan-step treatment the
vitamin layer established for the riboflavin phosphatase and the folate
pyrophosphatase. It differs from those in one way worth recording: there the
reaction had no marker anywhere, here the marker exists and does not reach the
taxa that need it. Two mitigations follow from that difference.

- **TIGRFAM `TIGR00507`** is added alongside `K00014`. NCBIfam built it to find
  the prokaryotic AroE and the equivalent domain of the fungal and plant
  multifunctional proteins, so a genome annotated against InterPro satisfies the
  step that KEGG cannot see. This is a coverage remedy, and it is the opposite of
  widening a marker: `TIGR00507` is *more* specific than the step, not less.
- **YdiB `K05887`** is accepted at `ambiguous` confidence. Rhea records
  EC 1.1.1.282 against RHEA:17737 alongside EC 1.1.1.25, so the chemistry is
  right; whether YdiB carries the flux in a genome that also has AroE is not
  something a marker can say. It moves the route by 180 bacteria.
- **QsuD `K25901` is refused.** EC 1.1.1.24 is the NAD(+) reaction RHEA:17741,
  a different Rhea master, and admitting it here would attach a marker to
  chemistry it does not catalyse.

The reaction is used in **reverse** relative to its Rhea master, which writes the
oxidation; the biosynthetic direction reduces 3-dehydroshikimate.

---

## 5. Salicylate and the auxin: where the layers actually sit

### Salicylate is one route with alternative systems

The brief asked whether PchA/PchB and the MbtI-type salicylate synthases are
distinct routes or alternative systems. They are alternative systems, and the
test is chemical rather than organisational.

Both implementations perform exactly two transformations: isomerise chorismate
to isochorismate, then eliminate pyruvate. PchA and PchB do it in two proteins
with a released intermediate; MbtI, Irp9 and YbtS do it in one active site with
the isochorismate enzyme-bound, releasing it slowly enough that they have been
characterised as isochorismate synthases in their own right. KEGG assigns
`K04781` **both** EC 5.4.4.2 and EC 4.2.99.21, which is the same reading.

giftr already curates this exact shape once. The bifunctional PabBC (`K03342`)
appears as a system of the 4-amino-4-deoxychorismate synthase reaction *and* as a
system of the lyase reaction, inside one route. The salicylate GIFT follows it:
one route, two reactions, `K04781` attached to both.

Materialising a second route would assert that MbtI reaches salicylate by a
different minimal chemical path. It does not, and the instruction not to collapse
mechanistically distinct reactions cuts the other way here — the reactions are
not distinct, only the proteins are.

### One consequence of that decision is not local

Enzyme systems attach to **reactions**, not to routes. The salicylate route
reuses the existing `RHEA:18985`, so accepting PchA and MbtI as systems of it
also makes them available to `menaquinone_biosynthesis`, and conversely MenF and
EntC become available to the salicylate route. Both directions were measured
before the decision:

- Adding PchA and MbtI moves the isochorismate step from 4047 to 4203 bacteria,
  but only **7 genomes** actually gain menaquinone, because the eight remaining
  *men* steps still have to be there.
- In the other direction the risk is real and is stated rather than hidden. The
  salicylate route is only two steps, so route completeness supplies much less
  specificity than it does for menaquinone: 183 bacteria complete it on
  EntC or MenF plus PchB, with no PchA and no MbtI.

`K04782` was examined directly because of that. It carries the claim almost
alone, and PchB shares the AroQ fold with chorismate mutase and retains mutase
activity. Two counts:

- 706 of its 1017 bacterial carriers have **no isochorismate synthase of any
  kind**, so they cannot complete the route whatever else is true of them. The
  route logic already excludes them.
- 90.3% of its carriers also carry a separate chorismate mutase KO, against an
  84.6% baseline across all bacteria. It is therefore not systematically standing
  in for the genome's mutase, which was the failure mode to rule out.

The trait is accepted on that evidence, with the residual risk recorded here and
in the marker note rather than argued away.

### Only one route to the auxin survives

Four bacterial routes to indole-3-acetate were assessed. One is curated.

| Route | Chemistry | Decision |
|---|---|---|
| **indole-3-acetamide (IAM)** | IaaM `K00466`, then IaaH `K21801` | **curated**, 86 bacteria |
| indole-3-pyruvate (IPyA) | aromatic aminotransferase, IpdC `K04103`, aldehyde dehydrogenase | refused |
| tryptamine | aromatic amino-acid decarboxylase `K01593`, amine oxidase, aldehyde dehydrogenase | refused |
| indole-3-acetonitrile | aldoxime formation, nitrilase `K01501` | refused |
| tryptophan side-chain oxidase | one step | refused |

The IAM route is curated because **`K00466` is diagnostic on its own**.
Tryptophan 2-monooxygenase exists for no other purpose, it is present in 92
bacteria that are almost all plant-associated Proteobacteria, and
indole-3-acetamide has no bacterial fate other than hydrolysis to the auxin. The
route consumes O2, so it is the layer's one `aerobic` route.

That is also why the second step accepts the broad amidase `K01426` at
`ambiguous` confidence, as a system alongside the dedicated `K21801`. On its own
`K01426` matches 4948 bacteria and would license nothing; inside a route already
restricted to 92 genomes by IaaM it recovers 37 genomes that would otherwise be
called negative on an annotation boundary — 49 becomes 86. The reaction is used
by no other GIFT, so the second consequence of invariant 16, that an over-broad
marker damages the neighbouring traits it also matches, does not arise.

The refusals are all the same failure. **IPyA** needs an aromatic aminotransferase
and an aldehyde dehydrogenase, both generic and near-universal, so the route
reduces in practice to "has `K04103`" — and `K04103` does not hold up: 417 of its
648 bacterial carriers are Enterobacteria, KEGG assigns it in *Salmonella* to a
protein annotated only as a putative thiamine pyrophosphate enzyme, and one
carrier is annotated "indolepyruvate/phenylpyruvate decarboxylase". **Tryptamine**
rests on `K01593`, which KEGG itself names aromatic-L-amino-acid/L-tryptophan
decarboxylase and which also produces dopamine and serotonin. **IAN** rests on the
broad nitrilase `K01501` and has no bacterial marker for the aldoxime step at
all. **Side-chain oxidase** has no marker in any namespace.

Curating any of them would name a trait for indole-3-acetate on evidence that
cannot distinguish it from ordinary decarboxylation. 86 genomes with defensible
evidence is the better answer than several hundred without.

---

## 6. Gallate is refused, and it fails earlier than expected

The brief anticipated that gallate would fail on marker specificity: that AroE
annotations support shikimate chemistry without supporting gallate formation.
That is true, and it is the *second* reason. The first is that there is nothing
to curate.

**There is no reaction.** Rhea release 141 records gallate in nine reactions.
Every one of them either consumes it — decarboxylase EC 4.1.1.59, dioxygenase
EC 1.13.11.57, glucosyltransferase EC 2.4.1.136 — or releases it from a
conjugate, as tannase does from digallate (RHEA:16365) and LigM from
3-O-methylgallate (RHEA:52280). **None forms it from 3-dehydroshikimate.** There
is no EC number for the transformation. Invariant 4 requires a Rhea master or at
minimum a cross-reference, and neither exists.

**There is no marker.** KEGG has eight gallate KOs and every one is degradative
or plant-specific: `K04099` galA/desB, `K22958`–`K22960` lpdBCD, `K15065` desZ,
`K15066` ligM, `K16516` galR and `K23279` UGT84A13. No TIGRFAM or Pfam family
describes a gallate-forming dehydrogenase.

**The only enzymes described as doing it are plant shikimate dehydrogenases**,
and their markers are the AroE markers of §4 — the same `K00014` and
`TIGR00507` that 5585 bacteria carry for core shikimate chemistry. Admitting
them would make every genome with a shikimate pathway a gallate producer, and by
invariant 16's second consequence it would simultaneously damage
`chorismate_biosynthesis`, whose AroE evidence would then be equivocal between
two traits. This is the pseudolysin failure in a new place.

**A CUSTOM_HMM would not rescue it either, today.** The brief asks whether one
could. It could in principle: a sequence-specific model built around an
experimentally characterised gallate-forming clade would be exactly the right
instrument, and it is the same move `TIGR03948` makes for butyrate. But the
prerequisite is a set of characterised sequences whose gallate-forming activity
is established and which are separable from the AroE background, and the
characterised examples are plant enzymes — *Vitis*, *Juglans*, *Arabidopsis* —
not bacterial ones. Until a bacterial clade is characterised there is nothing to
train on, and a model trained on plant sequences would make a claim about
bacterial genomes that its training set cannot support.

**What is evidenceable instead**, and is deferred rather than refused: bacteria
in the gut and in fermented plant foods do produce gallate, by hydrolysing
hydrolysable tannins. Tannase is EC 3.1.1.20, has a Rhea master (RHEA:16365) and
a dedicated KO (`K10759`). That is a *catabolic* capability between different
boundaries — gallotannin to gallate — and belongs to a polyphenol degradation
layer, not to this one. Recording it here is meant to keep the refusal from
reading as "bacteria do not make gallate", which is not what the evidence says.

---

## 7. The grouping: a new facet, not a reused one

The four capabilities share a biosynthetic origin. Nothing in the existing
vocabulary records that, and `substrate_class` must not be made to.

`substrate_class` answers *what chemistry is this capability about*. It is
single-valued and partitions the metabolic type. Overloading it to mean *what
chemical family is the product in* breaks it twice: `paba_biosynthesis` and
`menaquinone_biosynthesis` would have to give up `cofactor`, which is the
answer to the question the facet actually asks, and the class would stop
partitioning, since a capability can be about one chemistry and produce a
product in another family.

So a new facet is registered:

```text
biosynthetic_family = shikimate_derived_aromatic
```

It is assigned to five GIFTs — the three new ones plus the two chorismate
consumers that already existed — and the assignment is the demonstration that
the two facets are orthogonal rather than redundant:

| GIFT | substrate_class | biosynthetic_family |
|---|---|---|
| `chorismate_biosynthesis` | aromatic_compound | shikimate_derived_aromatic |
| `salicylate_biosynthesis` | aromatic_compound | shikimate_derived_aromatic |
| `indole_3_acetate_biosynthesis` | aromatic_compound | shikimate_derived_aromatic |
| `paba_biosynthesis` | **cofactor** | shikimate_derived_aromatic |
| `menaquinone_biosynthesis` | **cofactor** | shikimate_derived_aromatic |

Two facets, two different partitions, neither derivable from the other. If they
always agreed, one of them would be redundant and should be removed.

`indole_3_acetate_biosynthesis` carries the value although its input anchor is
tryptophan rather than chorismate: the facet classifies where the ring came
from, and the indole ring was built by the shikimate pathway.
`menaquinone_biosynthesis` carries it although its prenyl tail is not
shikimate-derived; the facet classifies the ring.

Facets classify a call and never enter the completeness logic that produces one,
so this changes no genome's result.

One new `substrate_class` value, `aromatic_compound`, and one new
`physiological_role` value, `secondary_metabolite_biosynthesis`, were also
registered. The role exists because neither `biosynthesis` ("builds a cellular
building block") nor `fermentative_end_product` describes a siderophore precursor
or a phytohormone: salicylate and the auxin are not building blocks and are not
fermentation products. The role names what the chemistry produces; giftr has no
evidence layer for secretion, for the receiving organism, or for any effect on it,
and the definition says so.

---

## 8. What the layer looks like when scored

| Capability | Bacteria | % | Archaea |
|---|---|---|---|
| `chorismate_biosynthesis` | 7644 | 75.3 | 90 |
| `salicylate_biosynthesis` | 646 | 6.4 | 0 |
| `indole_3_acetate_biosynthesis` | 86 | 0.8 | 0 |

Composition through declared anchors: 4604 bacteria complete both chorismate and
pABA; 598 complete both chorismate and salicylate. The graph gains three edges,
all `exact`, all out of `chorismate_biosynthesis`, and `paba_biosynthesis` moves
from `entry` to `intermediate` in the derived profile.

`indole_3_acetate_biosynthesis` is `isolated`: nothing in giftr produces
tryptophan yet. That is the correct report rather than a defect, and it names the
next thing worth curating.

---

## 9. Implementation record

Where the implementation departed from the provisional design in the brief:

1. **Gallate was refused**, as the brief allowed for, but on a stronger ground
   than anticipated: no Rhea reaction and no EC number exist for the
   transformation, so the failure precedes the marker question. §6.
2. **The salicylate implementations became systems, not routes.** The brief
   asked the question; the answer is that they are not mechanistically distinct
   reactions. §5.
3. **The shikimate dehydrogenase step is not required.** Nothing in the brief
   anticipated this; it came out of the evidence test. §4.
4. **A `TIGRFAM` marker was added to a metabolic component for the first time.**
   Previously the only non-KO metabolic markers were `PF01752` and `TIGR03948`,
   both added for specificity; `TIGR00507` is added for coverage. §4.
5. **`K01426` was accepted at `ambiguous` confidence** for the auxin hydrolase,
   which is a marker broader than the step, admitted only because a diagnostic
   marker upstream of it already bounds the route. §5.
6. **Two new facet values and one new facet** were registered. §7.
7. **Six `database_changes` entries** record the layer, the orphan step, the
   system decision, the IAA refusals, the gallate refusal and the facet.

Deferred, with the evidence that would settle each:

- **Aromatic amino acid biosynthesis** from chorismate. Phenylalanine, tyrosine
  and tryptophan are three separate branches and would make
  `indole_3_acetate_biosynthesis` composable rather than isolated.
- **Enterobactin and the 2,3-dihydroxybenzoate branch**, which shares
  `RHEA:18985` with both salicylate and menaquinone and would be the third
  consumer of that reaction.
- **The archaeal DKFP route to 3-dehydroquinate**, which needs its own anchor
  and a second consumer of it before the anchor earns its place. §3.
- **Gallate release from hydrolysable tannins** by tannase, `K10759`, as part of
  a polyphenol degradation layer. §6.
- **3-dehydroshikimate to protocatechuate** by AsbF/QuiC (`K15652`, `K09483`,
  `K26400`), which would make 3-dehydroshikimate a genuine branchpoint and
  reopen the question of where to cut the shikimate pathway. §3.
