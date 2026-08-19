# Curation proposal: the rest of amino acid metabolism

Status: **accepted and implemented in database version 2026.19.1 (schema 6).**
The implementation record, including every point where it departed from this
proposal, is §16. Prepared 2026-08-18 against database
version 2026.16.1 (schema 6, 72 GIFTs, 89 anchors, 97 routes, 226 reactions,
700 markers), KEGG release of 2026-08-18 (11 949 genomes, of which 10 151
bacterial), Rhea release 141, ChEBI release 253. Every count below is over
those 10 151 bacterial genomes unless stated otherwise.

Scope: decide whether the fifteen proteinogenic amino acids giftr does not yet
cover can be curated, and whether amino acid **degradation** and **microbial
transformation** — deamination, decarboxylation to biogenic amines, Stickland
chemistry, indole and cresol formation, sulfur volatiles — can be expressed
under the same ontology.

The short answer is that **biosynthesis is ready now and is the largest single
gain available to the database**: twenty new capabilities close four of the
thirty-three orphan input anchors, turn `auxotrophy_indicator` from a five-amino
acid partial view into a twenty amino acid one, and need no schema or code
change. **Degradation is where giftr becomes distinctive for host–microbiota
work and is also where the evidence breaks**: of the candidates assessed, ten
are supported at the specificity their names imply — two of them only by
deliberately under-calling — six are deferred pending a boundary decision
elsewhere, and six must be refused as named.

Two architectural decisions must be taken before the first row is written, and
neither is a data-entry question. The first is the **amino-donor rule** (§4):
glutamate is a co-substrate of nearly every reaction in this layer, and
declaring it an anchor wherever it is consumed would collapse the composition
graph into a star. The second is the **GS/GOGAT collision** (§6.1): ammonia
assimilation is a genuine metabolic cycle between two anabolic capabilities, and
the source validator rejects anabolic cycles by design, so the cycle must be
curated inside one GIFT rather than composed from two.

---

## 1. Recommendation in one page

1. **No schema migration and no R change.** Everything the layer needs exists:
   multiple input anchors per GIFT, `route_reaction.required = 0` for
   non-evidenceable steps, four modes, the open `marker.namespace` column, and
   the `biomass_essential` anchor facet that makes `gift_profile` report
   auxotrophy without being told what an amino acid is. §3.
2. **Adopt the amino-donor rule before curating anything.** The nitrogen donor
   of a transamination is never an anchor; the nitrogen *source* of an
   assimilation is. This is the nitrogen analogue of the sulfur decision the
   methionine and cysteine GIFTs already encode, and it follows the
   co-substrate precedent recorded as `DBC-20260818-COSUBSTRATE-ANCHORS`. §4.
3. **Curate twenty biosynthesis GIFTs (Layer A)** covering the fifteen missing
   amino acids plus chorismate, ornithine, meso-DAP and the two branched-chain
   2-oxo acids. Six of the twenty are cuts KEGG does not make,
   and each cut is at a branchpoint where genomes measurably differ. §6.
4. **Close four orphan input anchors.** `ASPARTATE`, `CHORISMATE`,
   `GLUTAMINE` and `OXOISOVALERATE` are declared as inputs today and produced by
   nothing, so pantothenate, folate, menaquinone, the nucleotide layer and the
   entire aspartate family currently hang off the graph. Layer A gives all four
   a producer. §3.2.
5. **Cut lysine at meso-diaminopimelate**, with four alternative routes from
   L-aspartate 4-semialdehyde in one GIFT. The four KEGG modules score 51.4%,
   5.6%, 6.8% and 17.2% separately; as alternative routes of one capability
   they score **75.3%**, and meso-DAP is where the peptidoglycan layer will
   attach. §6.3.
6. **Cut the branched-chain family at 2-oxoisovalerate and 2-oxobutanoate**,
   not by KEGG's valine/isoleucine fusion. This produces one GIFT per amino
   acid, gives pantothenate its missing producer, and makes threonine an
   upstream neighbour of isoleucine through a deamination step that is
   catabolic chemistry feeding an anabolic capability. §6.4.
7. **Widen the last-step transaminase rather than requiring the KEGG one.**
   Requiring `K00832`/`K00838` calls phenylalanine biosynthesis in 2296 genomes
   and tyrosine in 1558; the aryl skeleton that actually discriminates is
   present in 7796 and 5893. Widening the marker set to the aspartate and
   branched-chain aminotransferases recovers 7733 and 5852 — that is, the step
   becomes almost free, which is the empirical statement that it carries no
   information. §7.
8. **Curate ten degradation and transformation GIFTs (Layers B–D)** whose
   markers are specific enough for the trait as named: the arginine deiminase
   pathway, histidine degradation to glutamate, threonine and serine
   deamination, glutamate decarboxylation to GABA, tryptophanase indole
   formation, methionine γ-lyase, cysteine desulfidase, glycine reductase and
   D-proline reductase. §8–§11.
9. **Refuse four traits as named**: tyramine formation (no bacterial orthology
   group at all), tryptamine formation (only a polyspecific aromatic
   decarboxylase), p-cresol formation (33 genomes, all of them the wrong
   clades for a gut claim), and glutamate fermentation to butyrate (zero
   genomes complete either route at KO level). Each refusal is recorded with
   the evidence that decided it. §12.
10. **Do not curate amino acid uptake in this layer.** The branched-chain and
    polar-amino-acid ABC systems transport three to five substrates with one
    marker set, so a per-amino-acid transport claim would exceed its evidence
    exactly as invariant 16 describes. §12.5.

Cost if all of Layer A and the ten supported degradation GIFTs are accepted:
**30 GIFTs, ~28 anchors, ~60 routes, ~110 reactions, ~135 enzyme systems and
~215 KO markers** — roughly a doubling of the database, comparable to what the
vitamin layer did. §13.

---

## 2. What is covered today, and what is missing

giftr curates five amino acids: serine, glycine, cysteine, methionine and
threonine, plus the two aspartate-family branchpoint GIFTs
(`aspartate_semialdehyde_biosynthesis`, `homoserine_biosynthesis`). All of it is
biosynthesis. There is no amino acid degradation content of any kind, for the
five covered amino acids or for any other.

Missing biosynthesis, by family:

| Family | Missing | Precursor already anchored? |
|---|---|---|
| Glutamate | glutamate, glutamine, proline, ornithine, arginine | yes — `OXOGLUTARATE` |
| Aspartate | aspartate, asparagine, lysine | yes — `OXALOACETATE`, `ASA` |
| Pyruvate | alanine, valine, leucine, isoleucine | yes — `PYRUVATE`, `OXOISOVALERATE`, `THREONINE` |
| Aromatic | phenylalanine, tyrosine, tryptophan (and chorismate) | yes — `E4P`, `CHORISMATE` |
| Histidine | histidine | yes — `PRPP` |

Every family already has its entry anchor. That is not a coincidence: the
aspartate 4-semialdehyde anchor was created in the 2026.09.1 amino acid layer
explicitly so "the lysine branch can attach cleanly", the 2-oxoglutarate anchor
was created in the cycle layer because "making 2-oxoglutarate a boundary is what
will let the amino acid layer attach without re-cutting anything", and
2-oxoisovalerate was created for pantothenate. **The database has been built
toward this layer for three releases.**

## 3. What the ontology and the runtime already support

### 3.1 Nothing new is needed

- Multiple input anchors per GIFT: used by `methionine_biosynthesis_transsulfuration`
  (homoserine + cysteine) and `pantothenate_biosynthesis`.
- `route_reaction.required = 0` for a step that is real chemistry with no marker
  at the specificity of the step — the orphan-step rule adopted for vitamins.
- `interconversion` mode, for reversible pairs; used by four GIFTs today.
- Non-KO marker namespaces: `TIGRFAM` and `PF*` accessions are already curated
  (`TIGR03948` for butyryl-CoA:acetate CoA-transferase, `PF01752`), and
  `R/evaluation.R` recognises both.
- `biomass_essential = yes` on an anchor, which is what drives
  `gift_profile.auxotrophy_indicator`. Twenty-four anchors carry it today.

### 3.2 The four orphan anchors this layer closes

Thirty-three anchors are declared as an input by some GIFT and produced by no
GIFT. Layer A closes four of them:

| Orphan input anchor | Consumed today by | Closed by |
|---|---|---|
| `ASPARTATE` | `aspartate_semialdehyde_biosynthesis`, `pantothenate_biosynthesis`, `quinolinate_biosynthesis_aspartate` | `aspartate_biosynthesis` (§6.3) |
| `CHORISMATE` | `paba_biosynthesis`, `menaquinone_biosynthesis` | `chorismate_biosynthesis` (§6.5) |
| `GLUTAMINE` | `pyrimidine_core_biosynthesis`, `plp_biosynthesis_r5p` | `glutamine_biosynthesis` (§6.1) |
| `OXOISOVALERATE` | `pantothenate_biosynthesis` | `oxoisovalerate_biosynthesis` (§6.4) |

This is the strongest structural argument for the layer. Four existing GIFTs
that today look like isolated nodes gain an upstream neighbour, and the
composition claim "this genome can make pantothenate from its own carbon"
becomes answerable for the first time.

### 3.3 What it does to the auxotrophy profile

`gift_profile.auxotrophy_indicator` is derived from `biomass_essential` anchors.
With five amino acids curated it reports on a quarter of the requirement. With
twenty it reports on all of it. Using KEGG orthology as a stand-in for the
proposed route logic, and testing seventeen capabilities — the fifteen missing
amino acids plus ornithine and chorismate — the number complete per bacterial
genome distributes like this:

```text
capabilities  0    1    2    3    4    5    6    7    8
genomes     219  248  409  208  198  234  197  232  193

capabilities  9   10   11   12   13   14   15   16   17
genomes     243  354  500  814 1379 1736 1370  822  795
```

795 genomes (7.8%) complete all seventeen; the mode is fourteen. The
distribution is graded rather than bimodal, which is the biologically
interesting result and the one a five-amino-acid database cannot show.

### 3.4 Relationship to the two assessments filed the same day

Two sibling assessments were filed on 2026-08-18 and overlap this one at
precisely two points. Neither conflict is deep, but both must be settled before
curation rather than after.

**`proposal-nitrogen-compound-catabolism.md`** proposes the `AMMONIUM` anchor
and, in its §14.5, an `ammonium_assimilation` GIFT covering the same glutamate
dehydrogenase and GS/GOGAT chemistry as §6.1 here. It also states the
**nitrogen-anchor rule**: a nitrogen species is an anchor only where the
reaction's purpose is to liberate or assimilate it. This proposal adopts that
rule unchanged, and every `AMMONIUM` declaration below satisfies it — assimilation
in §6.1, liberation in every Layer B GIFT. The two documents must agree on one
GIFT, not curate two; §6.1 recommends which.

They also disagree on one number, and the difference matters. That proposal
reports ammonium assimilation as complete in 9482 genomes (93%), taking
glutamine synthetase alone as the second route. Glutamine synthetase without a
glutamate synthase produces glutamine, not glutamate, so it is not a net
assimilation route: **796 of those 9482 genomes carry `glnA` with no glutamate
synthase of any kind and no glutamate dehydrogenase.** Requiring a complete
glutamate synthase gives **8686 (85.6%)**, which is the figure used throughout
this document. The negative call that assessment finds informative — reduced
genome symbionts — grows from 669 to 1465 genomes and stays informative.

**`proposal-aromatic-degradation.md`** curates the downstream ring-degradation
funnels and explicitly names three of their substrates as amino acid
catabolites: anthranilate from tryptophan, phenylacetate from phenylalanine
fermentation, and phenol from tyrosine fermentation. Those are the *next* step
after the transformations proposed here, and the boundary between the two layers
is clean: this layer stops at the first stable product released from the amino
acid, that one starts at the ring. The one place they would meet is p-cresol,
which this proposal refuses on evidence (§11.4).

---

## 4. The amino-donor rule

This is the decision that determines whether the layer produces a usable
composition graph or an unreadable one.

Almost every reaction in amino acid metabolism consumes L-glutamate and releases
2-oxoglutarate, or the reverse. Transaminations, glutamine amidotransfer, the
DAP aminotransferase route, the aromatic and branched-chain final steps, and
histidine biosynthesis all do it. If glutamate is declared an anchor wherever a
route consumes it, then sixteen new GIFTs each gain an input edge from
`glutamate_biosynthesis`, and `gift_graph()` returns a star whose centre is the
one node nobody needs to be told about.

**The rule.** Declare the nitrogen compound as an anchor only when it is the
carbon skeleton of the product, or when the *identity of the nitrogen source* is
the discriminating biology of the trait. Never declare it because the reaction
consumes it.

Under the rule:

- `GLUTAMATE` is an input anchor of proline, ornithine and glutamine
  biosynthesis, because in each of those the glutamate carbon becomes the
  product carbon. It is **not** an anchor of aspartate, alanine, valine,
  leucine, isoleucine, lysine, phenylalanine, tyrosine or histidine
  biosynthesis, all of which merely transaminate.
- `AMMONIUM` is an input anchor of glutamate and glutamine biosynthesis, and of
  every degradation GIFT that *releases* ammonia as a declared product — the
  arginine deiminase pathway, histidine degradation, tryptophanase. Ammonia
  release is the point of those traits, not a side effect.
- `GLUTAMINE` is an input anchor of the amidotransfer-dependent GIFTs that
  already declare it (`pyrimidine_core_biosynthesis`, `plp_biosynthesis_r5p`)
  and stays that way; the layer adds a producer, not a new convention.

This is the nitrogen analogue of a decision giftr has already taken twice. The
methionine and cysteine GIFTs are split by *sulfur source* and declare `SULFIDE`,
`CYSTEINE` and `HOMOCYSTEINE` as inputs, because which sulfur a genome can use
is the trait. And `DBC-20260818-COSUBSTRATE-ANCHORS` records the general form:
"a co-substrate is not declared as an anchor merely because the reaction
consumes it", decided when declaring glyceraldehyde 3-phosphate for vitamin B6
would have produced edges "no reader would have read as biology".

Consequence to accept openly: a genome that cannot make glutamate but has every
transaminase will still be called positive for valine biosynthesis. That is
correct under giftr's contract — the GIFT claims the encoded chemistry between
2-oxoisovalerate and valine, not the availability of the donor — and the
nitrogen limitation is reported by `glutamate_biosynthesis` being negative,
which is where a reader should look for it.

---

## 5. Method and reference counts

Every count is the number of the 10 151 KEGG bacterial genomes carrying a gene
in each orthology group, combined by the Boolean logic shown, retrieved from the
KEGG REST API on 2026-08-18. Where a count is attributed to a KEGG module, the
module's own `DEFINITION` expression was evaluated unchanged, so module figures
and giftr figures are directly comparable. Reaction identity and direction were
checked against Rhea release 141; the EC-to-Rhea mapping was verified for every
unusual reaction in Layers B–D, including the two Stickland reductases
(`RHEA:12232`, `RHEA:12737`), 4-hydroxyphenylacetate decarboxylase
(`RHEA:22732`) and tryptophanase (`RHEA:19553`). Rhea covers every reaction this
proposal recommends; no candidate was dropped for lack of a reaction identifier.

Baseline reference points from the existing database, for calibration under the
same method: the three curated steps of `serine_biosynthesis` complete in 5342
genomes (52.6%), its first two in 7158 (70.5%), `glycine_biosynthesis` in 9792
(96.5%), and `riboflavin_biosynthesis` in 7943 (78.2%) as reported by the
vitamin layer. A candidate at 20% is therefore not unusual for this database,
and rarity is not a reason to refuse a trait; unevidenced specificity is.

---

## 6. Layer A — biosynthesis

Sixteen GIFTs. Cuts that KEGG does not make are marked **cut**.

### 6.1 Nitrogen entry, and the GS/GOGAT collision

| GIFT | Boundaries | Mode | Complete |
|---|---|---|---|
| `glutamate_biosynthesis` | 2-oxoglutarate + ammonium → L-glutamate | anabolic | **85.6%** (8686) |
| `glutamine_biosynthesis` | L-glutamate + ammonium → L-glutamine | anabolic | 91.0% (9241) |

`glutamate_biosynthesis` needs two routes, and they are not interchangeable
biology: glutamate dehydrogenase (`K00260`, `K00261`, `K00262`; 6775 genomes) is
the low-affinity, high-ammonium route, and glutamine synthetase with glutamate
synthase (`K01915` with `K00265`+`K00266`, `K00284` or `K00264`; 6557) is the
ATP-dependent high-affinity route. The two sets are not nested: 2129 genomes
have only the dehydrogenase and **1911 (18.8%) have only GS/GOGAT**. Curating
one route would misclassify a fifth of bacteria.

**The collision.** Written as the biology reads — GS makes glutamine from
glutamate, GOGAT makes glutamate from glutamine — the two GIFTs form an
anabolic 2-cycle in the anchor graph, and `validate_giftr_sources()` rejects it:
`.find_graph_cycle()` runs per directed mode and errors with "Circular anabolic
GIFT composition". The check is right to fire. The rule it enforces assumes a
cycle within one mode indicates a badly chosen boundary; here the cycle is real,
because GS/GOGAT *is* a cycle whose net effect per turn is
2-oxoglutarate + ammonium + ATP + NAD(P)H → glutamate.

**Recommendation.** Curate the GS/GOGAT pair as one *route* of
`glutamate_biosynthesis`, with L-glutamine internal to that route, and state the
route's net stoichiometry in its description. `glutamine_biosynthesis` remains a
separate single-reaction GIFT because glutamine is a required precursor
elsewhere (pyrimidines, PLP, purines) and its own capability. The glutamine
synthetase reaction (`RHEA:16169`) then appears in both, which is the one place
this layer knowingly departs from invariant 8's "do not duplicate an atomic
GIFT's reactions in a larger trait". The departure is unavoidable: composing
them through the anchor is exactly what the acyclicity rule forbids, and the
alternative — dropping the GOGAT route — loses 1911 genomes. The general
statement worth recording is that **an assimilatory cycle cannot be decomposed
by anchors, because both halves are anabolic**; the citric acid cycle could be
cut only because two of its four segments are `interconversion`.

The fallback, if the maintainer prefers the invariant intact: curate GDH only,
and record the 1911-genome cost as a known under-call. This proposal does not
recommend it.

**One GIFT, one name.** The nitrogen catabolism assessment proposes the same
capability as `ammonium_assimilation`, scoped narrowly and introduced there so
that `AMMONIUM` arrives "under a rule rather than under pressure later". That
reasoning is sound and this proposal does not contest it; what must not happen
is two GIFTs for one chemistry. Recommended: **one GIFT named
`glutamate_biosynthesis`**, curated by whichever layer lands first, declaring
`OXOGLUTARATE` + `AMMONIUM` in and `GLUTAMATE` out, with both routes. The
product-naming convention is the database's existing one, and the assimilation
reading is preserved in the description and in the `AMMONIUM` input anchor,
which is what a nitrogen-focused user will filter on. §14 Q2 puts the naming
choice to the maintainer alongside the cycle decision.

### 6.2 Alanine

| GIFT | Boundaries | Complete |
|---|---|---|
| `alanine_biosynthesis` | pyruvate → L-alanine | 81.7% (8298) |

Two routes: the alanine-synthesising transaminases (`K14260` 4064, `K14261`
2449, `K00835` 1153; union 5747) and alanine dehydrogenase (`K00259` 5464,
`K19244` 59; union 5484). KEGG has no module for alanine, which is itself the
warning: `K00814` (`GPT`, the textbook alanine transaminase) is annotated in
**one** bacterial genome, so a naive curation from the EC number would produce a
trait nobody has.

Note honestly in the GIFT description that alanine dehydrogenase runs
catabolically in *Bacillus* and several Firmicutes. giftr claims encoded
chemistry between boundaries, not flux direction, so an anabolic declaration is
defensible; a separate catabolic alanine GIFT is deferred rather than refused
(§12.6).

### 6.3 Aspartate family completion — **cut** at meso-DAP

| GIFT | Boundaries | Complete |
|---|---|---|
| `aspartate_biosynthesis` | oxaloacetate → L-aspartate | 70.5% (7159) |
| `asparagine_biosynthesis` | L-aspartate → L-asparagine | 66.2% (6725) |
| `dap_biosynthesis` | L-aspartate 4-semialdehyde → meso-2,6-diaminopimelate | **75.3%** (7641) |
| `lysine_biosynthesis_dap` | meso-2,6-diaminopimelate → L-lysine | 85.6% (8691) |

`aspartate_biosynthesis` is one reaction (`RHEA:21824`, aspartate
aminotransferase `K00812` 5507, `K00813` 1889, `K11358` 591). A single-reaction
GIFT is allowed where it establishes an identity that other capabilities depend
on — `cytidylate_biosynthesis` is the precedent — and this one closes the
`ASPARTATE` orphan and connects the citric acid cycle segments to three existing
GIFTs.

`asparagine_biosynthesis` has two routes distinguished by nitrogen source:
ammonia-dependent AsnA (`K01914`, 1766) and glutamine-dependent AsnB (`K01953`,
6066). Under §4 the ammonia-dependent route declares `AMMONIUM`; the
glutamine-dependent route declares `GLUTAMINE`. This is the same split as
methionine's, and it is the second case where the nitrogen source is the trait
rather than a co-substrate.

**The lysine cut is the layer's clearest win.** KEGG draws four separate modules
from L-aspartate to lysine, each repeating the aspartate kinase and
semialdehyde steps giftr already curates, and each scoring badly alone:

| Route from ASA to meso-DAP | KEGG module | Module complete | Route alone |
|---|---|---|---|
| Succinylated | M00016 | 51.4% | 52.6% (5344) |
| Acetylated | M00525 | 5.6% | 5.6% (570) |
| DAP dehydrogenase | M00526 | 6.5% | 6.8% (686) |
| DAP aminotransferase | M00527 | 15.5% | 17.2% (1741) |
| **any of the four, one GIFT** | — | — | **75.3% (7641)** |

The four are alternative implementations of one capability — the exact object
the route layer exists to represent — and a database that reports them as four
traits reports the wrong thing. Cutting at meso-DAP rather than at lysine costs
one anchor and buys two things: `lysA` (`K01586`, 8691) becomes separately
callable, and meso-DAP is where a future peptidoglycan layer attaches, since it
is the cross-link residue of most Gram-negative and many Gram-positive walls.

The aminoadipate routes (M00030, M00031, M00433: 0, 63 and 43 bacterial
genomes) are refused for this layer — §12.4.

### 6.4 Branched-chain family — **cut** at 2-oxoisovalerate and 2-oxobutanoate

KEGG fuses valine and isoleucine into M00019 because IlvBN, IlvC, IlvD and IlvE
catalyse both branches. That is an enzyme fact, not a capability, and it makes
the module unable to say which amino acid a genome can make.

| GIFT | Boundaries | Complete |
|---|---|---|
| `oxoisovalerate_biosynthesis` | pyruvate → 3-methyl-2-oxobutanoate | 78.1% (7929) |
| `valine_biosynthesis` | 3-methyl-2-oxobutanoate → L-valine | 87.5% (8887) |
| `leucine_biosynthesis` | 3-methyl-2-oxobutanoate → L-leucine | 75.6% (7671) |
| `oxobutanoate_biosynthesis_citramalate` | pyruvate → 2-oxobutanoate | 3.3% (340) |
| `isoleucine_biosynthesis` | 2-oxobutanoate → L-isoleucine | 75.7% (7680) |
| `threonine_deamination` (Layer B) | L-threonine → 2-oxobutanoate | 76.3% (7742) |

Four consequences worth stating:

1. `oxoisovalerate_biosynthesis` closes the `OXOISOVALERATE` orphan, so
   pantothenate biosynthesis stops being a trait whose substrate appears from
   nowhere. It is also the first GIFT whose product is a 2-oxo acid rather than
   an amino acid, which is what makes the valine/leucine split possible.
2. Valine and isoleucine biosynthesis use *the same four enzymes on different
   substrates*. Their reactions are different Rhea entries and their markers are
   identical. This is legitimate under invariant 16 because the discriminating
   chemistry is the 2-oxo acid supply, which is separately evidenced: the
   isoleucine GIFT is reachable only through 2-oxobutanoate. State this in both
   descriptions so a reader is not surprised that one marker set fires twice.
3. Both known 2-oxobutanoate sources should be curated, and they are wildly
   asymmetric: threonine deaminase (`K01754`/`K17989`, 7742) versus citramalate
   synthase (`K09011` with `K01703`+`K01704` and `K00052`, 340). The citramalate
   route is the *Leptospira*, *Geobacter* and *Methanocaldococcus* solution and
   is the one that matters for genomes that cannot make threonine.
4. Threonine deamination is **catabolic chemistry that feeds an anabolic
   capability**. It should be curated once, in Layer B, with `mode = catabolic`,
   and isoleucine biosynthesis should compose from the `OXOBUTANOATE` anchor.
   Curating it twice, once per mode, would duplicate a reaction; classifying it
   as anabolic because of where its product goes would misname the chemistry.
   The cross-mode edge threonine → deamination → isoleucine is exactly the case
   invariant 8 anticipates when it says composition "is expected to cycle
   between modes".

### 6.5 Aromatic family — **cut** at chorismate, which the database already needs

| GIFT | Boundaries | Complete |
|---|---|---|
| `chorismate_biosynthesis` | PEP + erythrose 4-phosphate → chorismate | 48.9% (4960) |
| `phenylalanine_biosynthesis` | chorismate → L-phenylalanine | 76.2% (7733) |
| `tyrosine_biosynthesis` | chorismate → L-tyrosine | 57.6% (5852) |
| `tryptophan_biosynthesis` | chorismate → L-tryptophan | 59.9% (6076) |

`chorismate_biosynthesis` closes the `CHORISMATE` orphan that folate and
menaquinone both depend on, and costs one new anchor, phosphoenolpyruvate. PEP
satisfies the anchor test independently: glycolysis, gluconeogenesis, the PTS
sugar uptake systems and the oxaloacetate anaplerotic reactions all attach to
it, and a future central-carbon layer will need it regardless.

The shikimate count deserves a caveat that belongs in the GIFT description
rather than in a refusal. 4960 genomes complete all seven steps, but the
limiting step is the dehydroquinate dehydratase/shikimate dehydrogenase pair
(5634) whose type I and type II enzymes are non-homologous and unevenly
annotated, while chorismate synthase alone is present in 9149. Curate all
alternative KOs as parallel systems rather than requiring the type I enzymes,
and the trait tracks the biology rather than the annotation.

The phenylalanine and tyrosine figures above already apply the transaminase
decision of §7; on KEGG's own module logic they would be 22.6% and 15.3%.

The arogenate routes (M00910, M00040) are **not** curated as routes: `K01850`
and `K15849` are annotated in zero bacterial genomes, and M00040 completes in
615, all through the same `K04092` chorismate mutase already accepted. There is
no bacterial evidence layer for arogenate at KO resolution. §12.3.

### 6.6 Histidine

| GIFT | Boundaries | Complete |
|---|---|---|
| `histidine_biosynthesis` | PRPP → L-histidine | 52.3% (5314) |

Nine reactions, one operon in most genomes, and no branchpoint worth cutting at:
the pathway has no stable intermediate that anything else consumes. It is the
one family where the KEGG module boundary can be kept unchanged.

Two details for curation. HisB is bifunctional in *E. coli* (`K01089`) and split
in *B. subtilis* (`K01693`, `K04486`), so both must be alternative systems.
And the pathway releases AICAR into purine metabolism; AICAR should **not**
become an output anchor, for the reason already recorded for L-homocysteine —
declaring it would create an anabolic edge into `purine_core_biosynthesis`,
whose route already contains AICAR internally.

### 6.7 Glutamate family — proline, ornithine, arginine

| GIFT | Boundaries | Complete |
|---|---|---|
| `proline_biosynthesis` | L-glutamate → L-proline | 76.4% (7753) |
| `ornithine_biosynthesis` | L-glutamate → L-ornithine | 66.0% (6699) |
| `arginine_biosynthesis` | L-ornithine → L-arginine | 73.6% (7469) |

These are the three GIFTs where `GLUTAMATE` is a legitimate input anchor under
§4: the glutamate carbon becomes the product carbon in all three chains.

`ornithine_biosynthesis` keeps KEGG's M00028 boundaries and carries both
acetyl-recycling variants as alternative systems — the linear route with
N-acetylglutamate synthase and acetylornithine deacetylase, and the cyclic
ArgJ route (`K00620`), which is the dominant one outside the
Enterobacteriaceae. The LysW-carrier route (M00763) is refused for bacteria:
`K19412` is annotated in zero bacterial genomes (§12.4).

`arginine_biosynthesis` runs ornithine → citrulline → argininosuccinate →
arginine. **Citrulline stays internal.** It is tempting to anchor it, because
the arginine deiminase pathway (§8.1) also passes through citrulline, but the
two GIFTs run in opposite directions with opposite modes, and giftr composes
through declared anchors only — an internal citrulline in each is exactly the
"absence of an implicit edge" behaviour the composition tests protect. Anchoring
it would additionally require deciding whether ornithine carbamoyltransferase,
one reversible enzyme shared by both traits, is one GIFT or two.

The `ORNITHINE` anchor, by contrast, is required: it separates the two arginine
capabilities, it is the polyamine precursor (§9), and the cycles proposal
already flagged it as "a genuine compartment-split candidate" because of the
arginine/ornithine antiporter. Declare it `unspecified` for now, exactly as that
proposal recommends, and revisit when transport is curated.

---

## 7. The last-step transaminase, measured

The final step of phenylalanine, tyrosine, valine, leucine, isoleucine and
aspartate biosynthesis is a transamination from glutamate. It is the single
most damaging evidence problem in the layer, and it has a measurable answer.

| Trait | Aryl or oxo-acid skeleton | + KEGG module's transaminase | + widened transaminase |
|---|---|---|---|
| Phenylalanine | 7796 (76.8%) | **2296 (22.6%)** | 7733 (76.2%) |
| Tyrosine | 5893 (58.1%) | **1558 (15.3%)** | 5852 (57.6%) |

The KEGG modules require `K00832` (`tyrB`, 2372 genomes) or `K00838` (`ARO8`,
zero bacterial genomes). Requiring them removes three quarters of the genomes
that have the entire discriminating chemistry. The widened set adds the
aspartate aminotransferases (`K00812`, `K00813`, `K11358`) and the
branched-chain aminotransferase (`K00826`) — enzymes that are documented to
transaminate aromatic 2-oxo acids and that any textbook would accept.

Widening recovers 7733 of 7796 and 5852 of 5893. **The step becomes almost
free, and that is the finding**: after widening, the transaminase requirement
excludes 63 and 41 genomes respectively, so it carries essentially no
information about whether a genome can make phenylalanine.

Three options, and why the third is recommended:

1. *Require the KEGG transaminase.* Rejected: a 3.4× under-call driven by
   orthology-group naming, not biology.
2. *Mark the step `required = 0`* under the orphan-step rule. Defensible and
   consistent with riboflavin and folate, but not accurate here — the step is
   not unevidenceable, it is evidenced by enzymes KEGG files under a different
   name.
3. **Widen the marker set and keep the step required.** Recommended. The claim
   stays honest, the chemistry stays complete, and the few genomes excluded are
   those with no aminotransferase of any kind, which is an annotation state
   worth reporting.

The invariant-16 consequence must be stated in the change record: accepting
`K00812` as evidence for a component of phenylalanine biosynthesis means the
same marker supports aspartate biosynthesis, the DAP aminotransferase route and
the aromatic branch. That is chemically true of the enzyme — AspC transaminates
phenylpyruvate — so it does not equate two unlike traits. It is the *specificity
of the skeleton*, not of the transaminase, that separates the traits, and every
skeleton in this layer is separately evidenced. The same reasoning licenses
`K00826` firing for valine, leucine and isoleucine.

---

## 8. Layer B — deamination and ammonia release

Amino acid deamination is the metabolism a host-microbiome study actually asks
about: it is where microbial protein fermentation, ammonia production and
several energy-conserving strategies live. Four candidates are supported.

### 8.1 `arginine_deiminase_pathway` — recommended

L-arginine → L-ornithine + ammonium + CO2, with substrate-level ATP.
Mode: catabolic. `arcA` (`K01478`, 2839), ornithine carbamoyltransferase
(`K00611`, 8042) and carbamate kinase (`K00926`, 2466); all three: **1733
(17.1%)**.

The trait giftr users mean when they say "arginine metabolism". It is the
principal acid-resistance and ATP-generating strategy of streptococci,
lactobacilli, *Mycoplasma* and many oral and vaginal taxa. Ornithine
carbamoyltransferase is shared with `arginine_biosynthesis` running the other
way, which is precisely why the requirement of all three components matters:
`arcA` plus carbamate kinase is what distinguishes the catabolic pathway from a
biosynthetic genome, and requiring the trio costs nothing a biosynthetic genome
should have gained.

Composition: `ARGININE` in, `ORNITHINE` and `AMMONIUM` out, so it forms a
cross-mode cycle with `arginine_biosynthesis` through both anchors. That is
allowed and correct — it is the same shape as proline biosynthesis versus
proline degradation, and `gift_cycles()` will report it as a two-GIFT cycle
spanning modes, which is real biology, not a boundary error.

### 8.2 `histidine_degradation_glutamate` — recommended

L-histidine → L-glutamate + ammonium + formamide/formate. Mode: catabolic.
Histidase (`K01745`, 5003), urocanate hydratase (`K01712`), imidazolonepropionase
(`K01468`) and the formiminoglutamase step: **36.3% (3688)**; the first three
steps alone 45.1% (4579). The last step has four non-homologous alternatives
(`K01479`, `K00603`, `K13990`, `K05603`+`K01458`), which is a textbook case for
the enzyme-system layer.

### 8.3 `threonine_deamination` — recommended (also the isoleucine precursor)

L-threonine → 2-oxobutanoate + ammonium. `K01754`/`K17989`, **76.3% (7742)**.
See §6.4 point 4: curated once, catabolic, and composed into isoleucine
biosynthesis across modes.

### 8.4 `serine_deamination` — recommended

L-serine → pyruvate + ammonium. `sdaA`/`sdaB`/`tdcG` (`K01752`), **68.2%
(6922)**. Its product is the `PYRUVATE` anchor, so it connects the amino acid
layer to the entire fermentation layer in one edge, and it is the step that
makes serine a fermentable substrate rather than only a biosynthetic product.

### 8.5 Deferred deaminations

- **Aspartate ammonia-lyase** (`aspA`, `K01744`, 41.1%) produces fumarate and is
  a real trait, but the organic acid proposal already recorded that what its
  markers support "is aspartate deamination, not fumarate formation". It should
  be curated — as `ASPARTATE` → `FUMARATE`, catabolic — but the boundary
  interacts with the fumarate respiration question that proposal deferred.
  Recommend curating it with the rest of Layer B, flagged in §14 Q6.
- **Glutaminase** (`K01425`, 40.6%) and **asparaginase** (`K01424`, 66.3%) are
  single reversal steps of two GIFTs in this proposal. They are honest traits
  with specific markers and clinical relevance, and each creates a cross-mode
  cycle that is allowed. Deferred only to keep the first batch reviewable.

---

## 9. Layer C — decarboxylation and biogenic amines

This is the layer with the highest host relevance and the worst evidence, and
the two facts are related: the enzymes are clade-restricted, plasmid-borne and
under-represented in KEGG's reference genomes.

| Candidate | Markers | Genomes | Verdict |
|---|---|---|---|
| Glutamate → GABA | `K01580` | 1684 (16.6%) | **curate** |
| Arginine → agmatine | `K01585`, `K01584`, `K02626`, `K01583` | 5643 (55.6%) | **curate, split by physiology** |
| Agmatine → putrescine | `K01480` (3321), `K10536` (2909) | — | **curate** |
| Ornithine → putrescine | `K01581` | 2711 (26.7%) | **curate** |
| Lysine → cadaverine | `K01582` | 605 (6.0%) | **curate** |
| Histidine → histamine | `K01590` | 337 (3.3%) | **curate** |
| Tyrosine → tyramine | `K01592` | **0** | **refuse** — §12.1 |
| Tryptophan → tryptamine | `K01593` | 849 | **refuse as named** — §12.2 |

Recommended for the first degradation batch: `glutamate_decarboxylation_gaba`
only. It has the clearest claim (`gadA`/`gadB` are substrate-specific), the
clearest host relevance, and its product anchor `GABA` is immediately reused by
the GABA shunt and by 4-aminobutyrate fermentation, so the anchor pays for
itself. The remaining five are recommended but as a second batch, because they
need a decision on the polyamine boundary: agmatine, putrescine and spermidine
form a small network whose anchors should be chosen once rather than
per-decarboxylase.

The arginine decarboxylase split is worth flagging now. `speA` (4652) is the
biosynthetic polyamine enzyme and `adiA` (1386) is the acid-resistance enzyme;
they share EC 4.1.1.19 and produce the same molecule but are different traits
physiologically. giftr has no way to distinguish them except by orthology group,
which here is sufficient — two systems, one reaction, and a note in each
description.

---

## 10. Layer D — Stickland chemistry and amino acid fermentation

Stickland metabolism — coupled oxidation and reduction of amino acid pairs — is
the energy metabolism of *Clostridioides difficile*, *Clostridium sporogenes*
and much of the proteolytic gut community. Its reductive half has two
selenoprotein complexes with highly specific markers, and Rhea covers both.

| Candidate | Markers | Genomes | Verdict |
|---|---|---|---|
| Glycine reductase | `K10670` + `K10671`/`K10672` (+ `K21576`, `K21577`) | 162; full complex 128 | **curate** |
| D-proline reductase | `K10793` + `K10794` (+ `K01777` racemase) | 91; with racemase 90 | **curate** |
| Lysine → butyrate + acetate | `K01843`, `K01844`+`K18011`, `K18012`, `K18013`, `K18014` | 266 (2.6%) | **defer** — §12.6 |
| Glutamate fermentation | methylaspartate or hydroxyglutarate route | **0** and 31 | **refuse** — §12.3 |

The two reductases are rare (1.6% and 0.9%) and that is fine: rarity is not the
test, and both are decisively diagnostic when present. Each is a multi-subunit
complex, which is the enzyme-component layer working as designed, and each needs
one product anchor — acetyl phosphate for glycine reductase, 5-aminopentanoate
for D-proline reductase.

**The acetyl phosphate question is now forced.** Glycine reductase produces
acetyl phosphate, which `acetate_interconversion` currently holds *internally*
between phosphotransacetylase and acetate kinase. The nitrogen catabolism
assessment reached this question first, from the taurine route, and recommended
leaving the intermediate internal and recording the missing edge (§14.4 there).
That resolution is not available here: `validate_giftr_sources()` rejects any
metabolic GIFT with no output anchor, and acetyl phosphate is the *only* product
of glycine reductase. The choices are therefore to promote it, to include the
acetate kinase step in the route — which duplicates a reaction of an existing
atomic GIFT — or not to curate glycine reductase at all.

Recommended: **promote it**, and note that two independent layers now need it.
It passes the anchor test on its own merits: acetate kinase,
phosphotransacetylase, the phosphoketolase pathway and several sugar
phosphotransferase systems all attach. §14 Q4.

Lysine fermentation to butyrate is the deferral this proposal most regrets. The
pathway is complete in 266 genomes, its markers are specific, and it is a
documented butyrate source in the gut that the SCFA layer's single curated
route cannot see. It is deferred only because composing it into
`butyrate_formation` requires butyryl-CoA as an anchor, which is a boundary
change to the trait the SCFA proposal was most careful about.

---

## 11. Sulfur and aromatic transformations of host relevance

### 11.1 `methionine_degradation_methanethiol` — recommended

L-methionine → methanethiol + 2-oxobutanoate + ammonium. Methionine γ-lyase
(`K01761`, EC 4.4.1.11, `RHEA:23800`), **22.9% (2320)**. One reaction, one
specific orthology group, and a product with direct host relevance: methanethiol
is a principal volatile sulfur compound of oral malodour and a documented
colonocyte irritant. Its 2-oxobutanoate output composes into isoleucine
biosynthesis, and its `METHIONINE` input makes the two existing methionine
biosynthesis GIFTs non-terminal for the first time.

The enzyme also accepts homocysteine and cysteine. Name the GIFT for methionine,
state the promiscuity in the description, and do **not** use this marker as
evidence for a cysteine-degradation trait — that is the invariant 16 failure
mode where one over-broad marker silently equates two traits.

### 11.2 `cysteine_degradation_sulfide` — recommended, deliberately under-called

L-cysteine → hydrogen sulfide + pyruvate + ammonium. Mode: catabolic.
Dedicated L-cysteine desulfidases `K20021`, `K26607`, `K28981`: **23.3%
(2365)**.

Microbial hydrogen sulfide production from cysteine is one of the most requested
traits in gut microbiome work, and the reason it is hard is that the activity is
carried out by many PLP enzymes as a side activity — CysK in reverse, MetC,
MalY, CyuA. Accepting those broad markers would raise the count and destroy the
claim: `K01760` (`metC`, 4117 genomes) is curated in giftr today as evidence for
cysteine *biosynthesis* via transsulfuration, and accepting it here would make
every transsulfuration genome a sulfide producer. That is exactly the damage
invariant 16 warns about.

Recommendation: curate the trait using the dedicated desulfidases only, and
record in the change entry that the trait is knowingly under-called, that the
promiscuous PLP enzymes are refused as markers, and what evidence would change
the decision (a protein family separating desulfidase-competent CyuA/CdsB
sequences from the biosynthetic enzymes).

This is also the layer's connection back to existing content: the product is the
`SULFIDE` anchor, which today is an orphan input to
`cysteine_biosynthesis_sulfide` and `methionine_biosynthesis_sulfhydrylation`.
Curating it closes a fifth orphan and creates a cross-mode cycle
cysteine → sulfide → cysteine, which is real and allowed.

### 11.3 `tryptophan_degradation_indole` — recommended

L-tryptophan → indole + pyruvate + ammonium. Tryptophanase (`tnaA`, `K01667`,
EC 4.1.99.1, `RHEA:19553`), **7.3% (741)**.

One reaction, one orthology group, no ambiguity, and the strongest host-signal
claim in the whole layer: bacterial indole is an aryl hydrocarbon receptor
ligand, modulates epithelial barrier function, and is the basis of the classic
clinical indole test. A single-reaction GIFT is justified here on the same
grounds as `cytidylate_biosynthesis`: the transformation is independently
meaningful and establishes a product identity nothing else produces.

Requires `INDOLE` as a new output anchor, facets `microbially_derived` and
`small_molecule`.

### 11.4 Refused: p-cresol

4-hydroxyphenylacetate decarboxylase (`hpdB`+`hpdC`, `K18427`+`K18428`,
`RHEA:22732`) is complete in **32 bacterial genomes**. p-Cresol is a genuine
uraemic toxin and a *Clostridioides difficile* competitive weapon, and the
chemistry is well described — but at 32 genomes the KEGG evidence layer is not
sampling the clades that carry it, and a trait curated on it would be a trait
about KEGG's reference set. Refuse for now, record the candidate markers, and
revisit with a protein-family marker in the `TIGRFAM` or `CUSTOM_HMM`
namespace, exactly as the SCFA layer did for butyrate. §12.1.

---

## 12. Refusals and deferrals, with the evidence that decided them

Recorded so they are not re-proposed.

### 12.1 Refused for lack of any bacterial evidence layer

- **Tyramine formation** (tyrosine decarboxylase). `K01592` is annotated in
  **zero** bacterial genomes; KEGG files bacterial TDC nowhere. The trait is
  real, well documented in *Enterococcus faecalis* and *Lactobacillus brevis*,
  and clinically relevant through dietary amine pressor response. It cannot be
  curated from KEGG orthology at all. Candidate rescue: a Pfam or TIGRFAM
  accession for the group II PLP decarboxylase clade, which is the same move
  that rescued butyrate.
- **p-Cresol formation**: 32 genomes. §11.4.

### 12.2 Refused as named, for insufficient specificity

- **Tryptamine formation.** The only marker is `K01593`, "aromatic-L-amino-acid
  decarboxylase", 849 genomes — an enzyme class that decarboxylates tryptophan,
  tyrosine and DOPA. A marker that cannot distinguish tryptophan from tyrosine
  cannot license a tryptophan-specific trait. If curated at all it must be named
  for what the marker supports — aromatic amino acid decarboxylation — which is
  a weaker claim than anyone asking for it wants.
- **"Hydrogen sulfide production"** as a single trait. Curate
  `cysteine_degradation_sulfide` with dedicated markers instead (§11.2);
  sulfate reduction and taurine respiration are separate capabilities with
  separate evidence and must not be merged into one sulfide trait.

### 12.3 Refused for zero or near-zero completeness

- **Glutamate fermentation to butyrate.** The methylaspartate route completes in
  **0** genomes and the hydroxyglutarate core in 31; the shared glutaconyl-CoA
  decarboxylase `K01615` is annotated in 58. The pathway is real in
  *Acidaminococcus* and *Fusobacterium*; the orthology layer does not capture
  it.
- **Arogenate routes to phenylalanine and tyrosine** (M00910, M00040): the
  distinguishing KOs `K01850` and `K15849` are annotated in zero bacterial
  genomes. §6.5.
- **Urea cycle** (M00029): 0 bacterial genomes, because `K01948` is the
  eukaryotic carbamoyl-phosphate synthase. The bacterial equivalent chemistry is
  the arginine deiminase pathway (§8.1) and the ornithine–ammonia cycle
  (M00978, 1052), which the cycles proposal already deferred with reasons that
  still hold.

### 12.4 Refused for this layer as clade-restricted

- **Aminoadipate lysine routes**: M00030 completes in 0 bacterial genomes,
  M00433 in 43, M00031 in 63 — *Thermus* and archaeal biology. The DAP routes
  cover bacteria at 75.3%.
- **LysW-mediated ornithine biosynthesis** (M00763): `K19412` in 0 bacterial
  genomes.
- **Lysine degradation modules** M00956 (189), M00957 (200) and M00960 (29) are
  aerobic soil-organism catabolism, not gut protein fermentation. Not refused on
  principle; simply not the first content to curate.
- **Kynurenine route of tryptophan degradation** (M00038, 44 genomes).

### 12.5 Deferred: amino acid transport

The branched-chain (LIV) and polar amino acid ABC systems carry three to five
substrates on one marker set, so a per-amino-acid uptake GIFT would claim a
specificity the markers cannot support — the same reasoning that refused
substrate-specific claims from polyspecific glycoside hydrolase families. Two
exceptions are worth a later look because the transported molecule *is* the
trait: the arginine/ornithine antiporter that completes the ADI pathway, and
the glutamate/GABA antiporter that completes acid resistance. Both need the
compartment split the cycles proposal described.

### 12.6 Deferred pending a boundary decision elsewhere

- **Lysine fermentation to butyrate** — needs butyryl-CoA as an anchor. §10.
- **Glycine reductase composition into acetate** — needs acetyl phosphate as an
  anchor. §10.
- **Catabolic alanine, glycine and aspartate GIFTs** — the glycine cleavage
  system (M00621, 69.2%) is a strong candidate and a one-carbon supplier, but
  its product is methylene-tetrahydrofolate, and the one-carbon pool has no
  anchors yet. Curate with a folate one-carbon layer, not before.
- **Polyamine network beyond agmatine and putrescine** — spermidine synthase and
  the aminopropyl donors need their own boundary pass. §9.

---

## 13. Implementation impact if accepted

Layer A (20 GIFTs) plus the ten supported degradation and transformation GIFTs
of Layers B–D:

| Table | Added |
|---|---|
| `anchors.tsv` | ~28 (§14 Q1 lists them) |
| `gifts.tsv` | 30 |
| `gift_anchors.tsv` | ~66 |
| `gift_routes.tsv` | ~55 |
| `reactions.tsv` | ~105 |
| `route_reactions.tsv` | ~150 |
| `reaction_xrefs.tsv` | ~210 |
| `enzyme_systems.tsv` | ~130 |
| `enzyme_components.tsv` | ~145 |
| `markers.tsv` | ~210 |
| `component_markers.tsv` | ~230 |
| `gift_facets.tsv` | ~60 |
| `anchor_facets.tsv` | ~84 |

No schema migration. No R change. `giftr_db_version` bumps; `schema_version`
does not.

New facet values needed: `substrate_class = amino_acid` already exists and
covers most of Layer A; Layers B–D need `biogenic_amine`, `volatile_compound`
and `protein_fermentation` as gift facet values, and `AMMONIUM` needs
`resource_origin = inorganic` alongside `SULFIDE`.

Tests required, beyond re-running the suite:

- the amino-donor rule: assert that no GIFT declares `GLUTAMATE` as an input
  unless glutamate carbon is in the product, and that `gift_graph()` has no node
  with more than *n* incoming edges from one anchor;
- OR across the four DAP routes, and the negative case that no single route's
  markers alone complete the GIFT;
- the shared branched-chain marker set firing for valine, leucine and isoleucine
  while the isoleucine GIFT stays negative without a 2-oxobutanoate source;
- cross-mode composition threonine → `threonine_deamination` → isoleucine, and
  the cross-mode cycles arginine ⇄ ornithine and cysteine ⇄ sulfide;
- absence of an implicit edge through citrulline, carbamoyl phosphate, AICAR,
  anthranilate and prephenate;
- the widened transaminase: assert `K00812` supports components in three GIFTs
  and that removing the aryl skeleton markers makes all three negative;
- `cysteine_degradation_sulfide` stays negative in a genome carrying only
  `K01760`, which is the under-call the curation decision commits to.

`database_changes.tsv` entries needed for: the batch addition; the amino-donor
rule as a `clarification`; the lysine four-route consolidation (`broadens`
relative to any KEGG module reading); the widened transaminase (`broadens`); the
GS/GOGAT internal-cycle decision; the deliberate under-call of
`cysteine_degradation_sulfide`; and each refusal in §12 that a user might
otherwise re-request — tyramine, tryptamine, p-cresol and glutamate
fermentation.

`SOURCES.md` must list every KEGG module consulted, and must distinguish the
modules used as pathway organisation from the six boundary decisions that are
giftr's own: the meso-DAP cut, the 2-oxoisovalerate and 2-oxobutanoate cuts, the
chorismate cut, the transaminase widening, the GS/GOGAT merge, and the
citrulline-internal decision.

---

## 14. Open questions for the curator

**Q1 — the anchor vocabulary.** This layer adds roughly 28 anchors, the largest
single addition giftr has made, and invariant 3 says to keep the vocabulary
small. Proposed: `AMMONIUM`, `GLUTAMATE`, `ALANINE`, `VALINE`, `LEUCINE`,
`ISOLEUCINE`, `OXOBUTANOATE`, `MESO_DAP`, `LYSINE`, `ORNITHINE`, `ARGININE`,
`PROLINE`, `ASPARAGINE`, `HISTIDINE`, `PHENYLALANINE`, `TYROSINE`,
`TRYPTOPHAN`, `PEP` (Layer A); `GABA`, `INDOLE`, `METHANETHIOL`,
`AMINOPENTANOATE`, `ACETYL_PHOSPHATE` (Layers B–D). Each is a product identity
another capability consumes or a documented branchpoint. Is that acceptable, or
should the twenty amino acids arrive first and the transformation products
follow with their layer?

**Q2 — the GS/GOGAT departure, and the name.** §6.1 recommends curating the
glutamine synthetase reaction in two places to keep the anabolic graph acyclic,
which is a knowing exception to invariant 8. Accept the exception, or accept the
1911-genome under-call of curating glutamate dehydrogenase only? And is the
resulting GIFT `glutamate_biosynthesis`, as recommended here, or
`ammonium_assimilation`, as the nitrogen catabolism assessment proposes? It must
be one GIFT under one name, whichever layer curates it first.

**Q3 — the transaminase widening.** §7 recommends accepting `K00812`,
`K00813`, `K11358` and `K00826` as evidence for the aromatic final step.
Accept, or mark the step `required = 0` instead?

**Q4 — acetyl phosphate as an anchor.** Two layers now need it, and unlike the
taurine case it cannot be deferred here: glycine reductase has no other product
to declare, and the validator requires an output anchor. Promote it, or drop
glycine reductase from the layer?

**Q5 — batch size.** Layer A is 20 GIFTs and roughly doubles the database. Split
it — nitrogen entry and the aspartate/pyruvate families first, aromatics and
histidine second — or curate it as one release, as the vitamin layer was?

**Q6 — aspartate ammonia-lyase.** §8.5. Curate as `ASPARTATE` → `FUMARATE` now,
or hold it with the fumarate respiration question?

**Q7 — naming.** Biosynthesis GIFTs are product-named
(`lysine_biosynthesis_dap` keeps the existing route-suffix convention).
Degradation GIFTs are proposed as substrate-plus-product
(`tryptophan_degradation_indole`, `cysteine_degradation_sulfide`) because the
product is the host-relevant fact. Confirm that convention before thirty
identifiers are minted.

**Q8 — should this be two proposals?** Biosynthesis is ready and uncontroversial
apart from Q2 and Q3. Degradation carries every hard evidence decision. They
could be accepted independently, and the degradation layer would benefit from
the non-KO marker work that the tyramine and p-cresol refusals both point at.

---

## 15. Evidence sources

KEGG REST (`rest.kegg.jp`, retrieved 2026-08-18): module entries and
`DEFINITION` expressions for M00015, M00016, M00019, M00022–M00032, M00036,
M00038, M00040, M00044, M00045, M00118, M00133, M00134, M00432, M00433,
M00525–M00527, M00535, M00570, M00621, M00763, M00844, M00845, M00879, M00910,
M00947, M00948, M00956, M00957, M00960, M00970, M00972 and M00978; KO-to-gene
links for 327 orthology groups; the organism list of KEGG BRITE `br08601`, from
which the 10 151 bacterial genomes used as the denominator were taken.

Rhea release 141: reaction identity and direction, including the EC-to-Rhea
mapping (`rhea2ec.tsv`) used to confirm that every recommended reaction has a
master identifier. ChEBI release 253 through Rhea participants for anchor
identity.

Sibling assessments consulted and reconciled against:
`proposal-nitrogen-compound-catabolism.md` (the nitrogen-anchor rule, the
`AMMONIUM` and `GLUTAMATE` anchors, `ammonium_assimilation`, and the acetyl
phosphate question) and `proposal-aromatic-degradation.md` (the ring-degradation
funnels that begin where this layer's aromatic transformations end).

Existing giftr curation records consulted for precedent:
`DBC-20260818-COSUBSTRATE-ANCHORS` (the co-substrate rule), the L-homocysteine
input-only decision of release 2026.09.1 (acyclicity), the orphan-step rule of
the vitamin layer, and the TIGRFAM marker decision of the SCFA layer.


---

## 16. Implementation record, 2026-08-19

Curated the day after the assessment, against database version 2026.18.1, which
by then contained two layers that did not exist when §1 to §15 were written.
**Twenty-eight GIFTs were curated rather than the thirty proposed**, and the
difference is entirely that the sibling layers had already curated two of them.

What changed between the proposal and the implementation:

1. **`chorismate_biosynthesis` and `glutamate_biosynthesis` were already
   curated.** The aromatic degradation layer curated the shikimate pathway with
   the boundaries §6.5 proposed, and the nitrogen layer curated glutamate
   formation as `ammonium_assimilation` with the two-route structure §6.1
   recommended, glutamine internal to the GS-GOGAT route. Both were reused, and
   the naming question of §14 Q2 is settled in favour of the existing name.
2. **`glutamine_biosynthesis` is curated as proposed**, sharing `RHEA:16169`
   with `ammonium_assimilation`. The departure from invariant 8 that §6.1
   feared is smaller than expected: the reaction is shared, but the composition
   is not, because the GS-GOGAT route consumes its glutamine internally. There
   is no cycle, and the source validator is satisfied without an exemption.
3. **The anchor rule of §4 was sharpened during curation.** An anchor is a claim
   about every route of a GIFT, so alanine and asparagine biosynthesis declare
   only their carbon precursor although one route of each assimilates ammonium.
   The nitrogen-anchor rule of the sibling proposal is otherwise applied
   unchanged, and `test-nitrogen.R` now encodes the boundary case.
4. **The transaminase widening of §7 was implemented as recommended**, with
   `K05821` added to the set. The step stays required.
5. **`ACETYL_PHOSPHATE` was promoted**, resolving §14 Q4 in the only direction
   available: source validation requires an output anchor, and glycine
   reduction has no other product. It is output-only, on the precedent of
   `GLYOXYLATE` and `SULFITE`.
6. **One reaction was simplified deliberately.** The NADH-linked variant of the
   diaminopimelate reductase (`RHEA:35323`) is not curated as a second route:
   one orthology group serves both cofactors, so it would multiply the four
   routes without adding genomic discrimination. Recorded in the reaction
   description.
7. **The acetohydroxyacid synthase small subunit is not required**, on the
   precedent recorded for the PyrI regulatory subunit of aspartate
   carbamoyltransferase. The same reasoning leaves the PrdD and PrdE stabilising
   proteins out of the proline reductase system.
8. **A code change was needed that this proposal did not anticipate.**
   `gift_cycles()` reported every biosynthesis/degradation pair as a metabolic
   cycle -- arginine, proline, threonine, cysteine, methionine -- and the
   combinatorial explosion of longer mixed rings exhausted the enumeration
   limit, burying the citric acid cycle at position 34 of a truncated list. A
   ring that alternates anabolic and catabolic members says that a genome can
   both build a metabolite and break it down, which the composition rule already
   treats as expected rather than as circular metabolism, so those rings are now
   excluded. The exclusion is in `R/cycles.R`, documented in the accessor, and
   tested in both `test-amino-acids.R` and `test-central-cycles.R`.
9. **Layer C was curated only for GABA**, as §9 recommended. The five remaining
   biogenic amine decarboxylations are still recommended and still wait on the
   polyamine boundary decision.
10. **One existing row was corrected.** `ASPARTATE` and `GLUTAMINE` carried
    `biomass_essential = no` from when they were input boundaries with no
    producer. Both are proteinogenic, and the facet drives
    `gift_profile.auxotrophy_indicator`, so the layer would otherwise have left
    two of the twenty amino acids reporting as though nothing depended on them.
11. **Every refusal of §12 stands**, and the two that bound a curated claim --
    the promiscuous PLP enzymes for cysteine desulfidation, and the arogenate
    and LysW routes -- are recorded in `database_changes.tsv` and in
    `SOURCES.md` rather than only here.

Measured impact: 28 new GIFTs, 19 new anchors, 35 routes, 81 new reactions, 91
new enzyme systems, 121 KO markers new to the database, 33 external pathway
links and 7 change records. Three reactions the layer uses were already curated
and were reused rather than duplicated: glutamine synthetase, acetolactate
synthase and ornithine carbamoyltransferase. The
database went from 89 to 129 GIFTs and from 109 to 140 anchors. Four orphan
input anchors closed -- `ASPARTATE`, `GLUTAMINE`, `OXOISOVALERATE` and
`SULFIDE` -- and `CHORISMATE` had been closed by the sibling layer the week the
proposal was written. No existing GIFT call changed: no curated route, system,
component or marker was edited.
