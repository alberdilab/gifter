# Curation proposal: organic acid formation GIFTs

Status: **accepted and implemented in database version 2026.14.1 (schema 6).**
Evidence test applied 2026-08-18 against database version 2026.13.1. The
implementation record, including where it departed from this proposal, is §14.

Scope: decide whether the capacity to form fumarate, succinate, citrate,
lactate and the neighbouring fermentation acids can be expressed as GIFTs, and
identify what must be architecturally true before any of it can be curated.

The short answer is that the four metabolites named in the request **do not form
one class**, and the assessment splits them two against two. Lactate is the
best-evidenced fermentation end product gifter has examined — better than
acetate, because unlike acetate its forming and consuming enzymes are different
orthology groups, so it passes the direction clause outright. Citrate,
fumarate and succinate fail, each for a different reason, and one of those
reasons is structural rather than evidential: **the citric acid cycle cannot be
anchored, because anchoring it closes a cycle in the composition graph and the
build fails.** That was verified against the validator, not predicted.

Four traits are recommended for curation, one conditionally, and five are
refused. No schema migration and no code change is required.

---

## 1. Recommendation in one page

1. **No schema migration, no code change.** Every mechanism this layer needs —
   the fourth `mode` value, per-route `oxygen_requirement`, input-only anchors,
   `evidence_confidence` — is already in the schema and already exercised by
   curated content. §3.
2. **Curate `lactate_formation`** (pyruvate → (S)-lactate, `K00016`). This is
   the strongest result in the assessment. The NAD-dependent enzyme that forms
   lactate and the quinone- or cytochrome-dependent enzymes that consume it are
   **different KEGG orthology groups**, so the direction is evidenced rather
   than asserted. 4143 organisms carry the forming KO, 3388 carry the
   L-consuming one, and only 573 carry both. §6.1.
3. **Curate `lactate_racemisation`** ((S)-lactate ⇄ (R)-lactate, `K22373`,
   560 organisms) with `mode = 'interconversion'` — the second use of that
   value, and a cleaner case for it than acetate. It resolves a real defect:
   `propionate_formation_acrylate` consumes `LACTATE` ((R)-lactate) and
   **nothing in the database produces it**, so the GIFT is an orphan at its
   input today. §6.2.
4. **Curate `malolactic_fermentation`** ((S)-malate → (S)-lactate, `K22212`,
   337 organisms). This is the one place a citric-acid-cycle metabolite may
   enter the model, and it enters as an **input-only** anchor, never as a
   product. The enzyme is a decarboxylase and therefore irreversible, so it
   passes the direction clause where fumarase and malate dehydrogenase cannot.
   §6.3.
5. **Curate `citrate_fermentation`** — the catabolic direction, not the
   synthetic one. Citrate lyase `citDEF` + the `citC` ligase is complete in 912
   organisms and lands on the existing `PYRUVATE` and `ACETATE` anchors. §6.6.
6. **Refuse `citrate_formation`.** Citrate synthase (`K01647`) is present in
   8467 of 11 855 organisms, citrate is a cycle intermediate rather than a
   bacterial excretion product, and the trait would mean "has a citric acid
   cycle". A marker that is near-universal is not evidence. §6.6.
7. **Refuse `fumarate_formation`**, on three independent grounds, the first of
   which is gifter's own curated content: adenylosuccinate lyase (`K01756`,
   **11 115 of 11 855 organisms**) releases fumarate, and gifter already curates
   that reaction twice, inside `purine_core_biosynthesis` and
   `adenylate_biosynthesis`. Essentially every genome forms fumarate. §6.5.
8. **Refuse `succinate_formation`.** Curated on `frdABCD` it calls *Vibrio*,
   *Escherichia* and *Klebsiella* positive — fumarate respirers — and
   *Bacteroides*, *Prevotella* and *Fibrobacter*, the dominant gut succinate
   producers, negative. Curated on the fused `sdh`/`frd` group instead it fires
   in 7276 organisms, 61% of the universe, including *Streptomyces* and
   *Chlamydia*. Both settings are wrong in opposite directions. §6.4.
9. **Record the structural finding: citric-acid-cycle intermediates may not be
   anchors.** Six catabolic GIFTs spanning citrate → 2-oxoglutarate →
   succinate → fumarate → malate → oxaloacetate → citrate closes a within-mode
   cycle, and `.find_graph_cycle()` reports it. This is not a validator
   formality to work around: the cycle really does run oxidatively, reductively
   and as a branched horseshoe in different organisms, so no single direction is
   curatable. §7.
10. **Curate `acetoin_formation`** (`K01575` + `K00004`, 406 organisms) and
    **conditionally curate `ethanol_formation`** (`K04072`, 2519 organisms) as
    the two defensible members of the "similar metabolites" set. **Refuse
    `formate_formation` on architecture rather than evidence**: anchors are
    declared per GIFT, not per route, and pyruvate formate-lyase is one of three
    routes of the existing `pyruvate_to_acetyl_coa`. §6.7.

---

## 2. Scope: four metabolites, two classes

The request names fumarate, succinate, citrate and lactate "and similar
metabolites". Those four do not belong to one class, and treating them as one
is the mistake the assessment is written to prevent.

```text
fermentation end products          citric acid cycle intermediates
-----------------------            -------------------------------
lactate     (2-hydroxy acid)       citrate
ethanol     (neutral)              cis-aconitate, isocitrate
acetoin     (neutral)              2-oxoglutarate
formate     (C1)                   succinate
succinate   (both, and that is     fumarate
             exactly the problem)  malate, oxaloacetate
```

**A fermentation end product is a boundary metabolite**: the organism makes it,
stops, and releases it, because the reaction is the terminal disposal of
reducing equivalents. That is a capability, and gifter can express it.

**A cycle intermediate is not a boundary.** It is consumed by the same pathway
that makes it, its concentration is set by flux rather than by gene content,
and every genome with a citric acid cycle contains all of them. Asking whether
a genome "can form citrate" is asking whether it has citrate synthase, which is
a question about the cycle, not about a trait.

Succinate sits in both columns and that is precisely why it fails. It is a
genuine fermentation end product in *Bacteroides*, *Prevotella* and
*Actinobacillus*, and it is a cycle intermediate in everything else, and the
same four genes serve both readings in opposite directions. §6.4.

This assessment therefore uses the cut: **a metabolite is a candidate GIFT
product only if a genome can be said to release it, and only if a marker exists
whose direction matches that release.** Lactate, ethanol, acetoin and — in the
catabolic direction — citrate pass that cut. Succinate, fumarate, malate,
oxaloacetate, 2-oxoglutarate and citrate-as-product do not.

Two neighbours are deliberately outside the assessment. **Fumarate respiration**
— fumarate as a terminal electron acceptor rather than as a product — is a real,
well-evidenced trait with clean markers, and it is the trait most people
actually mean when they ask about fumarate. gifter has no model for respiration
or electron acceptors at all, so it is out of scope here rather than refused;
§11 records it as the largest deferred capability the assessment touched.
**Itaconate, oxalate and the other specialist acids** are single-organism traits
without gut relevance and were not examined.

---

## 3. What the ontology and the runtime already support

Nothing in this layer requires a migration. Four things were checked, and the
notable result is that all four mechanisms the layer needs were introduced by
earlier proposals for other reasons and already carry curated content or an
enforced contract.

**`mode = 'interconversion'` now has a contract, and a second use for it.**
The SCFA layer introduced the value for `acetate_interconversion` and
`R/database-build.R` enforces its boundary rule: an interconversion GIFT must
declare **every** anchor as both input and output, and no other mode may declare
any anchor both ways. A racemase is the purest possible instance —
`(S)-lactate = (R)-lactate` has no other reading — and it is a better
demonstration of the value than acetate, because acetate's reversibility is
physiological while a racemase's is definitional. §9.

**Input-only anchors are established practice.** `HOMOCYSTEINE` is declared
input-only to keep the sulfur layer acyclic, and `LACTATE` is already input-only
today for the acrylate route. `MALATE` would be the third, and for the same
reason: malolactic fermentation consumes malate and nothing in gifter should
claim to produce it. §6.3.

**`oxygen_requirement` is a route property, and this layer needs it.** Every
recommended route is fermentative and would be declared `anaerobic`, with one
exception worth naming: citrate fermentation in *Escherichia coli* is an
anaerobic capability in a facultative organism, and the route-level declaration
says that without making a claim about the genome. §6.6.

**`evidence_confidence` exists for the case this layer produces twice.**
`evaluate_gifts()` reports the weakest confidence term among the markers
supporting the best route, and the terms are ordered rather than averaged. The
D-lactate dehydrogenase and the acetoin reductase are both real markers with
real direction ambiguity, and the mechanism to say so without either refusing
or overclaiming is already in place. §6.2, §6.7.

**Rhea covers every reaction in the layer.** Fifteen ECs were checked against
the Rhea API on 2026-08-18 and all fifteen returned a master. No reaction here
needs the nullable-`rhea_master` path that the polysaccharide, protein and
acrylate content opened. §10.

---

## 4. What each source actually supplies

| Source | What it gives this layer | What it does not |
|---|---|---|
| **KEGG orthology** | The layer's decisive result: separate KOs for the NAD-dependent and the quinone-dependent lactate dehydrogenases, which is the direction discrimination the SCFA layer could not get for acetate | Any separation of fumarate reductase from succinate dehydrogenase outside the Enterobacteriaceae. `K00239` is *named* `sdhA, frdA` |
| **KEGG modules** | `M00579` (already used) and nothing else applicable. There is no module for lactate formation, none for citrate fermentation, none for acetoin | Module boundaries for every candidate here |
| **Rhea** | A master for all fifteen ECs, including `RHEA:10960` for the racemase and `RHEA:10760` for citrate lyase, which resolves a three-subunit enzyme into one reaction | Nothing about which genes do it, and nothing about direction |
| **ChEBI** | Stereochemically explicit identities for both lactate enantiomers, which this layer needs and the SCFA layer did not | — |
| **InterPro / NCBIfam** | Not required. Unlike butyrate, every trait recommended here is evidenceable at the KO level | — |
| **MetaCyc** | Not consulted; the pathway pages remain subscription-gated and gifter cites no MetaCyc record | — |

The contrast with the SCFA layer is the headline of this table. **KEGG organises
lactate better than it organises any fermentation product gifter has examined,
and it organises succinate worse than any.** In the first case the orthology
groups encode the cofactor, and the cofactor is the direction. In the second
KEGG puts a single name, `sdhA, frdA`, on the group that would have to carry the
claim.

---

## 5. The test

The SCFA test, with a third clause the citric-acid-cycle candidates forced:

```text
does a marker exist whose specificity matches the product named in the trait?
        |
        +-- no  --> refuse the trait
        |
        +-- yes --> does that marker's direction match the claim?
                        |
                        +-- no  --> the call cannot distinguish production
                        |            from consumption; say so, or refuse
                        |
                        +-- yes --> does a positive call carry information?
                                        |
                                        +-- no  --> refuse: a marker present in
                                        |            nearly every genome states
                                        |            a fact about life, not a
                                        |            trait of this genome
                                        |
                                        +-- yes --> curate
```

The third clause is new, and citrate and fumarate are why. Both pass clause 1
cleanly — citrate synthase makes citrate and nothing else, adenylosuccinate
lyase makes fumarate and nothing else — and neither is a trait, because both
markers are near-universal. gifter states the underlying rule as *marker
specificity bounds trait specificity*; this is its other edge. A marker that
discriminates nothing because everything has it bounds the trait at "is a
living cell".

The clause is not a licence to refuse common traits. `acetate_interconversion`
fires in 56% of KEGG bacteria and was curated, because it is the node the
butyrate route consumes and the layer has no shape without it. The test is
whether a positive call **distinguishes** genomes, and whether the curator has
a reason to want the node in the graph — not whether the number is large.

---

## 6. Outcome when the test was applied, 2026-08-18

Marker prevalence is the number of KEGG organisms carrying the marker, out of
the **11 855** organisms that carry at least one of the **59** orthology groups
examined (the KEGG genome list holds 11 949 entries, so this is effectively all
of KEGG). Sets were built from `https://rest.kegg.jp/link/genes/ko:<KO>` and
intersected locally.

| Trait | Best marker set | Specific? | Directional? | Informative? | Outcome |
|---|---|---|---|---|---|
| Lactate formation, L | `K00016` | yes | **yes** | yes | **curate** |
| Lactate racemisation | `K22373` | yes | n/a (interconversion) | yes | **curate** |
| Malolactic fermentation | `K22212` | yes | yes | yes | **curate** |
| Lactate formation, D | `K03778` | yes | **no** | yes | conditional, `ambiguous` |
| Citrate fermentation | `K01643`+`K01644`+`K01646`+`K01910` | yes | yes | yes | **curate** |
| Citrate formation | `K01647` | yes | no | **no** | refused |
| Fumarate formation | `K01756`, `K01679` | yes | no | **no** | refused |
| Succinate formation | `K00244`–`K00247` | **no** | **no** | yes | refused |
| Malate / oxaloacetate / 2-oxoglutarate formation | — | — | — | **no** | refused |
| Ethanol formation | `K04072` | yes | no | yes | conditional |
| Acetoin formation | `K01575`+`K00004` | yes | yes | yes | **curate** |
| Formate formation | `K00656`+`K04069` | yes | yes | yes | refused on architecture, §6.7 |

### 6.1 Lactate — the direction clause passes, and this is the layer's result

The SCFA assessment added the direction clause because fermentative end-product
enzymes are near-equilibrium and their markers are direction-blind. Acetate had
to be curated as an interconversion for exactly that reason. **Lactate is the
first fermentation product examined where the markers are not direction-blind**,
and the reason is chemical rather than curatorial: forming lactate is a
cytoplasmic NADH-consuming reduction, while consuming it feeds electrons to the
respiratory chain through a quinone or a cytochrome. Those are different
enzymes with different cofactors, and KEGG gives them different orthology
groups.

| Direction | Enzyme | KO | Organisms |
|---|---|---|---:|
| **forming** | L-lactate dehydrogenase, NAD (EC 1.1.1.27) | `K00016` | 4143 |
| **forming** | D-lactate dehydrogenase, NAD (EC 1.1.1.28) | `K03778` | 3133 |
| consuming | L-lactate dehydrogenase, quinone (`lldD`) | `K29125` | 3388 |
| consuming | L-lactate dehydrogenase, cytochrome (`CYB2`) | `K00101` | 194 |
| consuming | D-lactate dehydrogenase, quinone (`dld`) | `K03777` | 1257 |
| consuming | D-lactate dehydrogenase, cytochrome | `K00102` | 2664 |

The two sets are largely disjoint. Of the 4143 organisms carrying `K00016`,
only **573 also carry `K29125`**; 3570 carry the forming KO and no L-consuming
KO at all. Across both enantiomers, 6516 organisms carry an NAD-dependent
lactate dehydrogenase, 5267 carry a quinone- or cytochrome-dependent one, and
3638 carry a forming KO with no consuming KO whatsoever.

The reference genomes separate perfectly along the line the chemistry predicts:

| Genome | `K00016` (NAD, forming) | `K29125` (quinone, consuming) |
|---|:--:|:--:|
| *Lactococcus lactis* Il1403 | + | − |
| *Lactobacillus delbrueckii* | + | − |
| *Lactiplantibacillus plantarum* | + | − |
| *Streptococcus pyogenes* | + | − |
| *Enterococcus faecalis* | + | − |
| *Bifidobacterium longum* | + | − |
| *Bacillus subtilis* 168 | + | − |
| *Escherichia coli* K-12 | − | + |
| *Salmonella* Typhimurium LT2 | − | + |
| *Pseudomonas aeruginosa* PAO1 | − | + |

Every lactic acid bacterium is positive for the forming enzyme and negative for
the consuming one; every aerobe and facultative respirer is the reverse.
*Bacillus subtilis* is a true positive here, not a false one — it produces
L-lactate under oxygen limitation through the *ldh* this KO names. And
*Faecalibacterium prausnitzii* L2-6, the archetype the butyrate assessment used,
carries **neither**, which is correct: it consumes lactate through enzymes KEGG
assigns elsewhere and produces butyrate.

Contrast that with the butyrate result, where a KO-evidenced trait would have
called *B. subtilis* positive and *F. prausnitzii* negative. Here the KO layer
gets both right.

`K00016` is present in 35% of the universe, which is comparable to acetate's
56%, and the top genera — *Streptococcus* (185), *Bacillus* (167),
*Corynebacterium* (162), *Staphylococcus* (110), *Clostridium* (71),
*Bifidobacterium* (64), *Listeria* (48), *Lactobacillus* (40), *Enterococcus*
(34) — are Bacillota and Actinomycetota fermenters almost without exception.
This passes clause 3 comfortably: it separates the fermentative half of the
tree from the respiratory half, which is exactly what a fermentation trait
should do.

**Recommendation: curate `lactate_formation`, `mode = 'catabolic'`, one route,
one reaction (`RHEA:23444`, reversed), evidenced by `K00016`.** Describe it as
NAD-dependent reduction of pyruvate, and say in the description that the
direction is evidenced by the cofactor — this is the one GIFT in the
fermentation layer where that sentence is a claim rather than a caveat.

### 6.2 The stereochemistry problem, and the GIFT that resolves it

Lactate is chiral, and gifter has already committed to one enantiomer. The
`LACTATE` anchor is **(R)-lactate**, `CHEBI:16004`, because
`propionate_formation_acrylate` consumes the D form. The enzyme recommended
above makes the **(S)** form. Naïvely curating `lactate_formation` therefore
produces a GIFT that shares no anchor with the acrylate route, and the orphan
stays an orphan.

The resolution is not to blur the anchor. It is that **the organisms which run
the acrylate route mostly do not have a D-lactate dehydrogenase either — they
have a racemase.** Checking the ten KEGG genomes behind the curated acrylate
route:

| Genome | `K00016` L-LDH | `K03778` D-LDH | `K22373` racemase |
|---|:--:|:--:|:--:|
| *Megasphaera elsdenii* | + | − | **+** |
| *M. stantonii* | + | − | **+** |
| *M. massiliensis* | − | − | **+** |
| *M. hexanoica* | + | − | **+** |
| *Pseudocoprococcus catus* | + | − | **+** |
| *Desulfosporosinus orientis* | − | − | **+** |
| *D. acidiphilus* | − | − | **+** |
| *D. meridiei* | − | − | **+** |
| *Anaerotignum propionicum* | + | **+** | − |
| *Anaerotignum* sp. MB30-C6 | + | **+** | − |

**All ten have a route to (R)-lactate**: eight through lactate racemase, two
through a D-lactate dehydrogenase. The racemase is the majority mechanism and
it is the one that composes with the recommended `lactate_formation`.

`K22373` (`larA`) is present in 560 organisms — *Clostridium* (48),
*Methanosarcina* (27), *Staphylococcus* (25), *Lactiplantibacillus* (13),
*Geobacter* (10), *Campylobacter* (8) — an anaerobe-dominated set of a size that
reads as a real trait rather than an annotation artefact.

**Recommendation: curate `lactate_racemisation`, `mode = 'interconversion'`,
one reaction (`RHEA:10960`), evidenced by `K22373`.** Both anchors are declared
as both input and output, per the interconversion contract. Do not mirror the
route; one traversal, as the contract requires.

The composition this creates was checked against the validator's own edge
derivation and cycle check (§7.3). It adds five edges and no cycle:

```text
galacturonate_degradation ─┐
glucuronate_degradation  ──┴─> lactate_formation ─> lactate_racemisation ─┐
malolactic_fermentation ─────────────────────────────────────────────────┴─> propionate_formation_acrylate
```

That last edge is the point. `propionate_formation_acrylate` currently has an
input anchor nothing produces, and the SCFA proposal recorded the reason:
lactate formation was out of scope for a layer defined by chain length. Bringing
it into scope closes the gap, and the acrylate GIFT stops being an island at its
input.

**D-lactate formation is a separate question and the recommendation is to
defer it.** `K03778` is specific to the right chemistry, but its top genera are
*Pseudomonas* (224), *Streptomyces* (158) and *Burkholderia* (90) — obligate
aerobes running the reaction oxidatively. It fails clause 2 the way acetate
does, without acetate's justification, because the racemase route already
reaches the anchor. If a curator wants it anyway, the honest form is a second
route on a D-lactate GIFT with the marker mapping recorded as `ambiguous`, so
`evidence_confidence` reports the weakness at the call. It should not be
curated as a peer of the L route.

### 6.3 Malate — the one cycle acid that may enter, and only as an input

Malolactic fermentation is the decarboxylation of (S)-malate to (S)-lactate,
the reaction that softens wine, and it is a clean trait by every clause of the
test.

`K22212` (`mleA`/`mleS`) is present in **337 organisms**: *Streptococcus* (38),
*Lacticaseibacillus* (23), *Enterococcus* (23), *Lactococcus* (21),
*Staphylococcus* (21), *Limosilactobacillus* (14), *Lactiplantibacillus* (13),
*Lactobacillus* (13), *Leuconostoc* (10). That is the lactic acid bacteria and
essentially nothing else — one of the most taxonomically coherent marker sets in
any gifter assessment.

It passes clause 2 outright and for a reason no other candidate in this
assessment can claim: **the reaction releases CO2**, so it is irreversible under
physiological conditions. There is no consuming direction for the marker to be
blind to.

`MALATE` enters the model here as an **input-only anchor**, exactly like
`HOMOCYSTEINE` and like `LACTATE` today. Nothing produces it, no malate-forming
GIFT is curated, and §7 explains why none can be. This is worth stating plainly
because it is the assessment's answer to the general question: a citric acid
cycle metabolite can appear in gifter as the **substrate** of a capability, and
that costs nothing, because a substrate anchor makes no claim about how the
genome obtained it.

**Recommendation: curate `malolactic_fermentation`, `mode = 'catabolic'`, one
reaction (`RHEA:46276`), evidenced by `K22212`.** Route `oxygen_requirement`
`independent`.

### 6.4 Succinate — refuse, and the two ways of getting it wrong

Succinate is the candidate most likely to be asked for again, so the refusal
needs its numbers on the record.

The reductive route is PEP or pyruvate → oxaloacetate → malate → fumarate →
succinate, and the only step that carries any trait information is the last:
fumarate reductase. Everything upstream is shared with the citric acid cycle
and with gluconeogenesis, and is present in most genomes.

**Setting A — require `frdABCD` (`K00244`–`K00247`).** 1041 organisms carry all
four; the complete reductive route including a carboxylase, a malate
dehydrogenase and a fumarase is complete in **1049**. The genus breakdown:

> *Vibrio* (91), *Escherichia* (70), *Enterobacter* (55), *Klebsiella* (55),
> *Salmonella* (54), *Yersinia* (51), *Mycobacterium* (39), *Serratia* (35),
> *Aeromonas* (32), *Pectobacterium* (24), *Citrobacter* (24),
> *Haemophilus* (21), *Mannheimia* (19)

This is a list of **fumarate respirers**, not succinate producers. The
Enterobacteriaceae carry Frd to use fumarate as a terminal electron acceptor
during anaerobic growth; succinate is the waste product of a respiratory
process, and the same operon is repressed and replaced by Sdh under oxygen.
Only *Mannheimia*, *Actinobacillus* and *Basfia* — the industrial succinate
producers — are in the list for the reason the trait names.

Meanwhile the organisms that dominate succinate production in the mammalian gut
are **all negative**:

| Genome | `frdA` | `frdB` | `sdhA` | `sdhB` |
|---|:--:|:--:|:--:|:--:|
| *Bacteroides thetaiotaomicron* VPI-5482 | − | − | + | + |
| *Bacteroides fragilis* YCH46 | − | − | + | + |
| *Prevotella melaninogenica* | − | − | + | + |
| *Fibrobacter succinogenes* | − | − | + | + |

Every one of them is named for or characterised by succinate production, and
every one of them is refused by setting A. That is the butyrate failure mode
again — archetypal producers called negative, non-producers called positive —
and the SCFA proposal already refused the succinate route to propionate on
overlapping grounds.

**Setting B — accept the fused group as an alternative.** The obvious repair is
to allow `K00239`/`K00240`, and it destroys the trait. KEGG names that group
**`sdhA, frdA`**: it is one orthology group for both enzymes, because outside
the Enterobacteriaceae the split does not exist. The complete route then fires
in **7276 organisms — 61% of the universe** — led by *Streptomyces* (249),
*Pseudomonas* (245), *Bacillus* (172), *Corynebacterium* (171),
*Staphylococcus* (109) and *Chlamydia* (90). This is not succinate formation;
it is "has a citric acid cycle", and it fails clause 3.

There is no third setting. Of the 1041 genomes with `frdABCD`, **943 also carry
`sdhABCD`** — the split is a paralogue duplication within one clade, not a
functional partition across bacteria, so it cannot be used to infer direction
anywhere else. And the enzyme is genuinely reversible: `RHEA:13713` is written
as succinate oxidation, and the same complex catalyses both readings.

**Recommendation: refuse `succinate_formation` and record the refusal**, with
the trigger condition for revisiting: an orthology group or sequence family that
separates fumarate reductase from succinate dehydrogenase outside the
Enterobacteriaceae, or a marker for the *Bacteroides* succinate release step
that KEGG does not currently resolve.

### 6.5 Fumarate — refuse, three ways, and the first way is gifter's own content

Fumarate fails clause 3 harder than any candidate examined in any gifter
assessment, and the demonstration is inside the curated database.

**Ground 1: gifter already curates fumarate formation, twice, and correctly did
not call it a trait.** Adenylosuccinate lyase releases fumarate; the reaction is
`RHEA:16853`, curated in `adenylate_biosynthesis`. The SAICAR lyase step,
`RHEA:23920`, releases fumarate too and is curated in
`purine_core_biosynthesis`. Its marker, `K01756`, is present in **11 115 of
11 855 organisms — 93.8%**. Purine biosynthesis is how most genomes on Earth
form fumarate, and no one would call that a fumarate-formation trait.

**Ground 2: the metabolic route is reversible and its marker is universal.**
Fumarase (`K01679`, 9098 organisms; class I `K01676`, 4667) interconverts malate
and fumarate, `RHEA:12460`, and the direction is set by flux. Aspartate
ammonia-lyase (`K01744`, 4202) is a genuine fumarate-releasing enzyme with a
clean reaction, but it is an aspartate-catabolism marker and the trait it
supports is aspartate deamination, not fumarate formation.

**Ground 3: anchoring fumarate would inject false edges into the composition
graph.** This was tested rather than argued. Declaring a `FUMARATE` anchor and
attaching it to the GIFTs whose curated reactions genuinely involve it —
`purine_core_biosynthesis` and `adenylate_biosynthesis` as outputs,
`pyrimidine_core_biosynthesis` as an input, since the fumarate-dependent
dihydroorotate dehydrogenase `RHEA:30059` is already curated there — adds
exactly two edges to the graph:

```text
purine_core_biosynthesis ─> pyrimidine_core_biosynthesis
adenylate_biosynthesis   ─> pyrimidine_core_biosynthesis
```

Both are chemically true and both are meaningless. Purine biosynthesis does not
feed pyrimidine biosynthesis in any sense a user of `gift_graph()` would want;
they share a co-product that happens to serve as an electron acceptor in one
step of one route. This is the concrete demonstration of the rule §7.1 of the
SCFA proposal stated abstractly for acetyl-CoA — that gifter derives edges from
**declared anchors only**, so a hub metabolite is harmless until someone
declares it, and harmful the moment they do.

The input half is worse still, and it is the formate defect (§6.7) arriving from
the opposite direction. `pyrimidine_core_biosynthesis` has **three** routes —
`PYR_DHODH_FUMARATE`, `PYR_DHODH_NAD` and `PYR_DHODH_QUINONE` — and only the
first uses fumarate at all; the other two reduce the same dihydroorotate with
NAD or a quinone. Because anchors are declared per GIFT and not per route,
declaring `FUMARATE` an input would claim that pyrimidine biosynthesis requires
fumarate in every genome, which is false in two of its three curated routes.

**Recommendation: refuse `fumarate_formation` and do not declare a `FUMARATE`
anchor.** Record that fumarate *respiration* — the trait people usually mean —
is deferred pending an electron-acceptor model, not refused on evidence.

### 6.6 Citrate — refuse the synthesis, curate the fermentation

Citrate splits cleanly into a refused trait and a recommended one, and the
recommended one is the direction the request did not name.

**`citrate_formation` — refuse.** Citrate synthase (`K01647`) is present in
**8467 organisms, 71% of the universe**. Citrate is the entry metabolite of the
citric acid cycle, consumed by aconitase in the same cell that made it, and
bacterial citrate excretion is a rarity rather than a capability class. The
trait would report "has a citric acid cycle" under a misleading name. Clause 3,
refused.

**`citrate_fermentation` — curate.** Citrate lyase cleaves citrate to
oxaloacetate and acetate, and the oxaloacetate is decarboxylated to pyruvate.
This is the classic Simmons-citrate trait, the *Lactococcus lactis* diacetyl
pathway, and the *Klebsiella* and *Salmonella* citrate-utilisation phenotype. It
passes all three clauses:

- **Specific.** Citrate lyase is a three-subunit enzyme with an acyl-carrier
  subunit and a dedicated activating ligase, and none of the four genes has
  another job.
- **Directional.** The lyase cleaves citrate and does not synthesise it; the
  synthetic direction is citrate synthase, a different enzyme with a different
  KO. This is a rare case where one metabolite's forming and consuming enzymes
  are entirely unrelated proteins.
- **Informative.** 912 of 11 855.

| Marker set | Organisms | Leading genera |
|---|---:|---|
| `citF`+`citE`+`citD` (`K01643`+`K01644`+`K01646`) | 960 | *Escherichia* 67, *Salmonella* 53, *Enterobacter* 52, *Klebsiella* 45, *Streptococcus* 44 |
| + `citC` ligase (`K01910`) | **912** | as above |
| + oxaloacetate decarboxylase (`K01571`/`K01003`) | 369 | *Salmonella* 50, *Streptococcus* 42, *Klebsiella* 36, *Lacticaseibacillus* 21, *Enterococcus* 16 |
| + `citT` transporter (`K09477`) | 222 | *Escherichia* 65, *Salmonella* 52, *Serratia* 29 |

*Bacillus subtilis*, *Bacteroides thetaiotaomicron* and *Pseudomonas
aeruginosa* are all negative for the lyase, which is correct.

Two curation decisions follow, and both have precedent.

**Where to stop the route.** Recommendation: `CITRATE → PYRUVATE + ACETATE`,
requiring the lyase, the ligase and an oxaloacetate decarboxylase — the 369-genome
setting. Oxaloacetate is an **internal intermediate of the route, not an
anchor**; §7.2 is about why that distinction carries the whole assessment.
Stopping at oxaloacetate instead would force a citric-acid-cycle anchor for no
gain, and the two products of the full route are anchors gifter already has.

**Whether to require the transporter.** Recommendation: **no**, and make it a
separate GIFT if anyone wants it. The classic phenotype is a transport
phenotype — *E. coli* K-12 is Cit− aerobically because CitT is not expressed
under oxygen, not because the chemistry is missing, and the Lenski long-term
evolution experiment's famous Cit+ mutant is a promoter rearrangement in front
of that transporter. gifter models gene content, not regulation, so a
transporter-requiring GIFT would still call *E. coli* K-12 positive and would
merely look as if it had said something about the phenotype. Declare the route
`anaerobic` — which is true for the facultative organisms and is exactly what
per-route `oxygen_requirement` is for — and if a transport claim is wanted
later, curate `citrate_uptake` as its own GIFT against a `CITRATE_EX` anchor, on
the `xylose_uptake_abc` pattern. Note in that case that `K09477` (222 genomes,
Enterobacteriaceae-only) and the *Lactococcus* plasmid-borne CitP are different
carriers, so one transport GIFT will not cover both.

### 6.7 The similar metabolites: ethanol, acetoin, formate

**Acetoin — curate.** `K01575` (acetolactate decarboxylase) + `K00004`
(2,3-butanediol dehydrogenase) is complete in **406 organisms**: *Bacillus*
(139), *Corynebacterium* (30), *Staphylococcus* (30), *Streptococcus* (29),
*Paenibacillus* (18), *Leuconostoc* (14), *Lactococcus* (11), *Weissella* (8).
That set is the Voges–Proskauer-positive organisms, which is to say the trait
has been a diagnostic test for a century and the marker reproduces it.

The curation decision mirrors butyrate exactly: **evidence the trait on the
specific terminal step, not on the synthase.** Acetolactate synthase is
`K01652`, which KEGG names `ilvB, ilvG, ilvI` — the *anabolic* branched-chain
amino acid enzyme, present in 9341 organisms. Requiring it changes the call in
two genomes out of 406 and imports a marker that means something else.
Acetolactate decarboxylase has no other role, and it is where the claim should
rest.

Anchor **`ACETOIN`** ((R)-acetoin, `CHEBI:15686`), not butane-2,3-diol. `K00004`
is a broad (R,R)-butanediol dehydrogenase and several genuine acetoin producers
— *Enterococcus faecalis*, *Klebsiella pneumoniae*, *Clostridium
acetobutylicum* — carry `K01575` without it, because their meso-butanediol
dehydrogenase sits elsewhere in KEGG. Acetoin is the defensible product
boundary; extending to butane-2,3-diol is a later pass, on `RHEA:24340`.

**Ethanol — conditionally curate.** `K04072` (`adhE`, the bifunctional
acetaldehyde/alcohol dehydrogenase that covers both steps from acetyl-CoA) is
present in 2519 organisms, led by *Streptococcus* (178), *Vibrio* (91),
*Bacillus* (80), *Escherichia* (71), *Clostridium* (66), *Bifidobacterium* (63)
— a fermentative set with a modest *Streptomyces* (41) tail. `ACETYL_COA →
ETHANOL`, `mode = 'catabolic'`, two reactions (`RHEA:23288` and `RHEA:25290`,
both reversed).

Two caveats put it at "conditional" rather than "curate". First, direction:
AdhE is reversible and *E. coli* uses it to oxidise ethanol; unlike lactate,
there is no cofactor split to lean on, so it inherits the acetate caveat.
Second and more concretely, **the archetypes are negative.** *Zymomonas
mobilis* and *Saccharomyces cerevisiae* — the two organisms most associated
with ethanol production — carry no `adhE`; they use pyruvate decarboxylase
(`K01568`) with a separate alcohol dehydrogenase. That route is complete in only
258 organisms and the set is fungus-dominated with an *Acetobacter* and
*Gluconobacter* tail, which are ethanol *oxidisers*. A curator who wants
ethanol should curate the AdhE route first and accept that the eukaryotic and
*Zymomonas* route is a second, weaker route rather than an equal one.

**Formate — refuse on architecture, not on evidence.** The evidence is fine:
pyruvate formate-lyase with its activase (`K00656`+`K04069`) is complete in 2843
organisms and the reaction is effectively irreversible toward formate in vivo.
The obstruction is structural, and it is worth recording because it is the only
place in this assessment where gifter's data model, rather than the biology or
the markers, is the binding constraint.

`gift_anchor` is keyed on `(gift_pk, role, ordinal)` — **anchors are declared
per GIFT, not per route.** Pyruvate formate-lyase is one of three routes of the
already-curated `pyruvate_to_acetyl_coa`; the other two are the pyruvate
dehydrogenase complex and pyruvate:ferredoxin oxidoreductase, and neither
produces formate. Declaring `FORMATE` as an output of that GIFT would assert
that all three routes produce it, which is false for two of them. Curating a
separate `formate_formation` GIFT over the same reaction would duplicate a
curated route, which the composition rule exists to prevent.

Neither option is acceptable, so formate is refused with its trigger recorded:
**per-route boundary anchors**, or a decision to split the PFL route out of
`pyruvate_to_acetyl_coa` into its own GIFT. The second is cheaper and probably
correct — pyruvate formate-lyase produces two boundary metabolites and the other
two routes produce one — but it re-cuts curated content and should be a
deliberate decision rather than a side effect of wanting formate.

---

## 7. The structural finding: the citric acid cycle cannot be anchored

This section is the part of the assessment that generalises beyond the four
metabolites named, and all three claims in it were checked against the
validator's own edge derivation and `.find_graph_cycle()` rather than reasoned
about.

### 7.1 A cycle in chemistry is a cycle in the graph

Curating the oxidative citric acid cycle the way the request implies — one
catabolic GIFT per span, each declaring its acid as an anchor — produces:

```text
citrate_formation       OXALOACETATE > CITRATE
oxoglutarate_formation  CITRATE      > OXOGLUTARATE
succinate_formation     OXOGLUTARATE > SUCCINATE
fumarate_formation      SUCCINATE    > FUMARATE
malate_formation        FUMARATE     > MALATE
oxaloacetate_formation  MALATE       > OXALOACETATE
```

Running the validator's edge derivation over the current `gift_anchors.tsv` plus
those six GIFTs and their six anchors, `.find_graph_cycle()` reports:

```text
Circular catabolic GIFT composition:
  citrate_formation -> oxoglutarate_formation -> succinate_formation ->
  fumarate_formation -> malate_formation -> oxaloacetate_formation ->
  citrate_formation
```

The build fails, and it fails correctly. gifter's guidance when a cycle appears
is to *ask which boundary is the weakest biological claim* rather than to delete
an edge — and here the answer is that **every** boundary is weak, because none
of the six metabolites is a boundary. The sulfur layer resolved its cycle by
demoting `HOMOCYSTEINE` to input-only; there is no analogous demotion here,
because there is no acid in the cycle that is only ever consumed.

The deeper reason not to reach for a workaround is that the cycle is not a
modelling artefact. The same six reactions run oxidatively in an aerobe,
reductively in *Bacteroides* and as a branched horseshoe in many anaerobes, with
the branch point differing by organism and by oxygen tension. `route_reaction.orientation`
is a curatorial claim about the chemistry, and here there is no single claim to
make.

### 7.2 A metabolite does not need an anchor to be modelled

The constructive half of the finding, and the reason three of this assessment's
four recommendations still touch citric-acid-cycle chemistry:

> An anchor is a **boundary** of a capability, not a participant in it.

`citrate_fermentation` passes through oxaloacetate and does not anchor it.
`malolactic_fermentation` consumes malate and anchors it only as an input.
Every curated gifter GIFT already relies on this: `purine_core_biosynthesis`
runs ten or eleven reactions per route and declares exactly two anchors,
`PRPP` and `IMP`. The
question "can gifter express the capacity to form citrate" therefore has two
different answers depending on which thing is being asked, and separating them
is most of the value of this assessment:

| Question | Answer |
|---|---|
| Can a GIFT's chemistry involve citrate, succinate, fumarate or malate? | Yes, freely, as internal steps or as input anchors |
| Can a GIFT claim the genome *forms and releases* one of them? | No, for the reasons in §6.4–§6.6 |

### 7.3 What the recommended layer does to the graph

The same derivation was run over the recommended lactate content. It adds five
edges and no cycle in any mode:

```text
lactate_formation        -> lactate_racemisation
malolactic_fermentation  -> lactate_racemisation
lactate_racemisation     -> propionate_formation_acrylate
galacturonate_degradation -> lactate_formation
glucuronate_degradation   -> lactate_formation
```

The last two are free: those GIFTs already declare `PYRUVATE` as an output, so
curating anything that consumes pyruvate extends the uronic acid layer without
re-cutting it — the same composition dividend the propanediol route collected
from `LACTALDEHYDE`.

One risk to record: a future `lactate_degradation` GIFT consuming `LACTATE` and
producing `PYRUVATE` would close a catabolic cycle against `lactate_formation`.
The markers for it exist and are clean (`K29125`, `K03777`, `K00101`,
`K00102` — §6.1), so this is a realistic future request rather than a
hypothetical. The resolution when it arrives is the acetate one: a single
`lactate_interconversion` in the fourth mode, not two opposed catabolic GIFTs.
It is worth deciding now whether to pre-empt that by curating lactate as an
interconversion from the start. The recommendation is **no** — the whole point
of §6.1 is that lactate's markers *do* carry direction, and collapsing to
interconversion would discard the assessment's strongest result to avoid a
problem that has not occurred.

---

## 8. Anchors required

| anchor_id | molecule | compartment | ChEBI | role |
|---|---|---|---|---|
| `LACTATE_L` | (S)-lactate | unspecified | `CHEBI:16651` | product of `lactate_formation` and `malolactic_fermentation`; both roles on the racemase |
| `MALATE` | (S)-malate | unspecified | `CHEBI:15589` | **input only**, `malolactic_fermentation` |
| `CITRATE` | citrate | unspecified | `CHEBI:16947` | **input only**, `citrate_fermentation` |
| `ETHANOL` | ethanol | unspecified | `CHEBI:16236` | product, conditional |
| `ACETOIN` | (R)-acetoin | unspecified | `CHEBI:15686` | product |

The existing `LACTATE` anchor ((R)-lactate, `CHEBI:16004`) gains an output role
through the racemase and stops being input-only. Every ChEBI identifier above
was read out of the Rhea equation of the reaction that uses it, so the anchor
and the reaction agree by construction.

No anchor is declared for oxaloacetate, acetaldehyde, acetolactate, fumarate or
succinate. The first three are internal route intermediates; the last two are
§6.4 and §6.5.

All compartments are `unspecified`, and the SCFA layer's limitation carries
over unchanged: `cross_feeding_output` will stay 0 for this layer too. Lactate
cross-feeding to butyrate producers is as well documented as acetate
cross-feeding and gifter still cannot say it, because the compartment split needs
a transport GIFT and lactate crosses membranes by permeases too broad to
evidence and by undissociated-acid diffusion that no marker can evidence. The
trigger condition is the same: a substrate-specific lactate transporter marker.

---

## 9. Modes

| GIFT | Mode | Why |
|---|---|---|
| `lactate_formation` | `catabolic` | the cofactor evidences the direction, §6.1 |
| `lactate_racemisation` | `interconversion` | a racemase has no direction to declare; both anchors mirrored, route not mirrored |
| `malolactic_fermentation` | `catabolic` | decarboxylation, irreversible |
| `citrate_fermentation` | `catabolic` | lyase and synthase are unrelated enzymes |
| `acetoin_formation` | `catabolic` | decarboxylation, irreversible |
| `ethanol_formation` | `catabolic` | see the §6.7 caveat; `interconversion` is the fallback if a curator finds the AdhE reversibility argument decisive |

`lactate_racemisation` is the assessment's argument that the fourth mode was not
a one-off for acetate. Acetate's reversibility is a physiological claim about
near-equilibrium chemistry; a racemase's is definitional, and the value
describes both without strain. Declaring it `catabolic` in either direction
would assert a stereochemical preference the enzyme does not have.

---

## 10. Reaction identifiers, verified 2026-08-18

Every reaction has a Rhea master. All fifteen ECs were queried and all returned
one.

| Step | EC | Rhea | Note |
|---|---|---|---|
| L-lactate dehydrogenase (NAD) | 1.1.1.27 | `RHEA:23444` | `(S)-lactate + NAD(+) = pyruvate + NADH + H(+)`; **reversed** for formation |
| D-lactate dehydrogenase (NAD) | 1.1.1.28 | `RHEA:16369` | reversed; deferred route, §6.2 |
| Lactate racemase | 5.1.2.1 | `RHEA:10960` | `(S)-lactate = (R)-lactate`; both anchors present in the equation |
| Malolactic enzyme | 4.1.1.101 | `RHEA:46276` | `(S)-malate + H(+) = (S)-lactate + CO2`; forward |
| Citrate lyase | 4.1.3.6 | `RHEA:10760` | `citrate = oxaloacetate + acetate`. Use this master, **not** `RHEA:19405`/`RHEA:20812`, which split the same chemistry into the citryl-CoA half-reactions of EC 2.8.3.10 and EC 4.1.3.34 and would make a three-subunit enzyme look like two curated steps |
| Oxaloacetate decarboxylase | 4.1.1.112 | `RHEA:15641` | forward |
| Acetaldehyde dehydrogenase (acylating) | 1.2.1.10 | `RHEA:23288` | reversed; first AdhE half |
| Alcohol dehydrogenase | 1.1.1.1 | `RHEA:25290` | `ethanol + NAD(+) = acetaldehyde + NADH + H(+)`, reversed. **Not** `RHEA:10736`, the generic `a primary alcohol` parent, which would let the route claim a chain length its chemistry does not fix |
| Acetolactate decarboxylase | 4.1.1.5 | `RHEA:21580` | forward |
| 2,3-butanediol dehydrogenase | 1.1.1.4 | `RHEA:24340` | later pass only, §6.7 |
| Fumarate reductase / succinate dehydrogenase | 1.3.5.1 | `RHEA:13713` | refused content; listed because the equation is written as succinate **oxidation**, which is §6.4's point in one line |
| Fumarase | 4.2.1.2 | `RHEA:12460` | refused content |
| Malate dehydrogenase | 1.1.1.37 | `RHEA:21432` | refused content |

The citrate lyase row is the same trap the SCFA assessment hit twice: the EC
number that names the trait maps to one master, and the neighbouring ECs map to
half-reactions or generic parents. Reaction identity has to be as specific as
the trait, and no more specific than the enzyme.

---

## 11. Open decisions for the curator

1. **Whether `lactate_formation` should be `catabolic` or `interconversion`.**
   Recommended: `catabolic`, on the §6.1 evidence. The counter-argument is
   §7.3 — a future lactate-consuming GIFT would force the change, and changing
   a curated GIFT's mode later is more disruptive than declaring it now. This is
   the single decision that most affects the layer's shape.
2. **Whether to curate D-lactate formation at all.** Recommended: no, reach
   `LACTATE` through the racemase, which is what 8 of the 10 acrylate-route
   organisms actually do. §6.2.
3. **Whether `ethanol_formation` earns curation given that *Zymomonas* and
   *Saccharomyces* are negative on its recommended route.** §6.7.
4. **Whether `citrate_fermentation` should require the transporter.**
   Recommended: no, and curate `citrate_uptake` separately if wanted. §6.6.
5. **Whether to split the pyruvate formate-lyase route out of
   `pyruvate_to_acetyl_coa`** so that formate can be an anchor. This is the only
   recommendation in the assessment that would re-cut existing curated content,
   and it should not be done as a side effect of wanting formate. §6.7.
6. **Whether fumarate respiration justifies an electron-acceptor model.** It is
   the largest capability this assessment touched and could not express: a real
   trait, with clean markers, that gifter has no vocabulary for. Anaerobic
   respiration on nitrate, sulfate, TMAO and DMSO would all arrive through the
   same door. Deferred, not refused. §6.5.

---

## 12. If accepted, the work is

| Table | Rows |
|---|---|
| `anchors.tsv`, `anchor_facets.tsv` | 5 anchors (§8); `LACTATE` gains an output role |
| `gifts.tsv`, `gift_anchors.tsv` | 6 GIFTs: lactate formation, lactate racemisation, malolactic, citrate fermentation, acetoin, ethanol (conditional) |
| `gift_routes.tsv`, `route_reactions.tsv` | 7 routes, ~12 route-reaction rows |
| `reactions.tsv`, `reaction_xrefs.tsv` | ~10 reactions (§10), all Rhea-mastered |
| `enzyme_systems.tsv`, `enzyme_components.tsv` | ~10 systems, ~14 components |
| `markers.tsv`, `component_markers.tsv` | ~12 KO markers, all KEGG; no new namespace |
| `gift_xrefs.tsv` | none. No KEGG module describes any of these boundaries, so there is no external boundary to compare |
| `facet_terms.tsv`, `gift_facets.tsv` | reuse `fermentative_end_product`; a new `substrate_class` value for the organic acid substrates of the two catabolic GIFTs |
| `database_changes.tsv`, `change_gifts.tsv` | one addition entry and **four refusal entries** — succinate, fumarate, citrate synthesis, formate — plus one `clarification` recording §7, which is the finding most likely to be rediscovered |
| `tests/testthat/` | extend `test-scfa.R` or add `test-organic-acid.R`, covering at minimum: that `K00016` completes `lactate_formation` in *L. lactis* and `K29125` alone does not; that `lactate_racemisation` satisfies the interconversion contract and adds the acrylate edge; that `propionate_formation_acrylate` is no longer an orphan at its input; and a **structural test asserting that no citric-acid-cycle metabolite is a declared anchor**, which is the only durable protection against §7 being rediscovered the expensive way |
| `SOURCES.md` | no new source family; ChEBI and Rhea entries pinned as usual |

The §7 refusal entry matters more than the additions. Succinate and citrate will
be requested again — they are two of the four metabolites in the request that
started this assessment — and the reasoning that refuses them is not obvious
from the marker tables alone.

---

## 13. Provenance of this assessment

All figures were retrieved on 2026-08-18.

- KEGG orthology-to-gene links: `https://rest.kegg.jp/link/genes/ko:<KO>`,
  reduced to organism codes and intersected locally. **59 orthology groups**,
  spanning 11 855 organisms.
- KEGG genome list: `https://rest.kegg.jp/list/genome` (11 949 entries), used
  for genus attribution.
- KEGG orthology names: `https://rest.kegg.jp/find/ko/<KO>`. The `sdhA, frdA`
  naming of `K00239`–`K00241` (§6.4) is quoted from that endpoint.
- Rhea: `https://www.rhea-db.org/rhea?query=ec:<EC>&format=tsv`, 15 ECs, plus
  equation and ChEBI lookups by Rhea ID. Every ChEBI identifier in §8 was taken
  from the `chebi-id` column of the reaction that uses it.
- The three graph results in §6.5, §7.1 and §7.3 were produced by running
  gifter's own edge derivation (`R/database-build.R`, the `gift_graph` rules) and
  `.find_graph_cycle()` over the current `gift_anchors.tsv` plus the
  hypothetical rows, in a scratch script. They are observations, not
  predictions. No file in the repository was modified.

Reference genomes used for the specificity checks, by KEGG organism code:
`lla`, `lde`, `lpl`, `lre`, `ppe`, `lme`, `efa`, `spy`, `san`, `blo`, `bsu`,
`cac`, `eco`, `stm`, `kpn`, `pae`, `bth`, `bfr`, `pmz`, `pit`, `fsu`, `msu`,
`bsun`, `asu`, `fpr`, `vpr`, `pfr`, `amu`, `zmo`, `sce`, and the ten
acrylate-route genomes `cpro`, `anv`, `med`, `mhw`, `meg`, `mmax`, `cct`, `dor`,
`dai`, `dmi`.


---

## 14. Implementation record, 2026-08-18

Accepted and curated as release **2026.14.1**. The schema is unchanged at
version 6 and `R/` is untouched, which was §1's first claim and the one most
worth confirming: the layer needed content, vocabulary and tests, not code. All
six recommended GIFTs were curated, including the two §11 listed as conditional,
and all five refusals are recorded in `database_changes.tsv`.

**Every open decision in §11 was resolved as recommended.** `lactate_formation`
is `catabolic` rather than pre-emptively `interconversion` (decision 1);
D-lactate formation is not curated (2); `ethanol_formation` was curated despite
*Zymomonas* and *Saccharomyces* being negative on its route (3);
`citrate_fermentation` does not require the transporter (4); the pyruvate
formate-lyase route was **not** split out of `pyruvate_to_acetyl_coa`, so
formate stays refused with its trigger recorded (5). Decision 6, an
electron-acceptor model for fumarate respiration, remains deferred.

**The facet vocabulary needed two new values, not one.** §12 planned "a new
`substrate_class` value". Ethanol and acetoin are not acids, so
`organic_acid` could not cover them and `neutral_fermentation_product` was
added alongside it — which is §2's two-column split reappearing one level down.
`physiological_role = fermentative_end_product` also had to be **broadened**:
its definition began "Forms a short-chain fatty acid as a terminal step of
fermentation", written when the SCFA layer was the only fermentation content,
and lactate, ethanol and acetoin are none of them. The proposal did not
anticipate that a facet definition would have to change.

**`citrate_fermentation` carries no external pathway link, and the gap is
real.** §12 predicted "no `gift_xrefs` rows" for the whole layer on the ground
that no KEGG module describes these boundaries. That was right about modules and
wrong about maps: five of the six GIFTs carry a `KEGG_PATHWAY` reference as
`subset_of`, four to map00620 and acetoin to map00650. Citrate is the exception
and it is not an oversight — `R00362` carries no pathway link at all, and the
citrate lyase orthology groups appear only in map02020, the two-component system
map, which describes the CitAB regulator rather than the chemistry. KEGG has no
metabolic map for fermentative citrate cleavage. `test-pathway-links.R` now
names it as a fifth unlinked GIFT with its own reason, separate from the four
BRITE-hierarchy cases.

**Acetoin rests on one marker, and the trait is larger than §6.7's number.**
The proposal quoted 406 organisms for `K01575` + `K00004`, then argued for
anchoring at acetoin rather than butane-2,3-diol — which drops `K00004` and
leaves the trait resting on `K01575` alone, in **1649** organisms. The two
statements were consistent but the consequence was not spelled out. The set is
*Streptococcus* (147), *Bacillus* (144), *Corynebacterium* (111),
*Staphylococcus* (110), *Klebsiella* (53), *Listeria* (48), *Enterococcus* (31),
*Lactococcus* (22) — still the Voges–Proskauer organisms, so the decision holds
at the larger number.

One thing §6.7 left open was settled during implementation: the acetolactate
synthase step is **curated with `required = 0`** rather than omitted. Omitting
it would have left a route whose only reaction starts from acetolactate while
the GIFT declares `PYRUVATE` as its input, so the boundary would have been
untrue. Curating it with the step not required keeps the chemistry honest and
keeps `K01652` — the anabolic `ilvB`/`ilvG`/`ilvI` group — out of the call. Its
marker mapping is recorded `ambiguous`, so `evidence_confidence` reports it if
anyone ever promotes the step.

**What the graph gained.** The five predicted edges (§7.3) appeared exactly as
derived, and nine more came with `citrate_fermentation` and `ethanol_formation`,
which §7.3 did not model. `propionate_formation_acrylate` had no edges at all
before this release — nothing produced `LACTATE` and nothing consumes
`PROPIONATE` — and now reports `network_position = terminal`, fed by
`lactate_racemisation`. That was the defect the layer set out to fix.

**Tests that had to move, and one that had to change meaning.**
`test-sugar-degradation.R` asserted the exact set of GIFTs downstream of sugar
catabolism. That set grows whenever any pyruvate-consuming capability is
curated, so it now asserts what the test was actually protecting: the shared
anchors are still only `PYRUVATE` and `LACTALDEHYDE`, and no downstream GIFT is
anabolic. This is the same lesson the SCFA release recorded about the same file.
Four inventory assertions in `test-database.R`, one in `test-pathway-links.R`
and one in `test-scfa.R` were updated for the new content.

`tests/testthat/test-organic-acid.R` is new and asserts, among other things,
that **no citric acid cycle metabolite is a declared output anchor**, that
malate and citrate appear only as inputs, that the four lactate-consuming
orthology groups complete nothing, and that `FUMARATE` creates no edge between
purine and pyrimidine biosynthesis. That last one protects §6.5 directly: the
chemistry is curated, the co-product is real, and the edge must still not exist.

**Final counts.** 48 GIFTs, 54 anchors, 118 reactions, 62 routes, 540 markers,
51 recorded biological changes. The full suite is 1649 passing tests.
