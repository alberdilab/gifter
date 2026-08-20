# Curation proposal: nitrogen compound catabolism GIFTs

Status: **accepted and implemented in database version 2026.18.1 (schema 6).**
The implementation record, including every point where implementation departed
from this proposal, is §17. The six open questions of §14 were resolved on
2026-08-18 and are recorded there. Evidence test applied
2026-08-18 against database version **2026.16.1** (schema 6, 72 GIFTs of which
65 metabolic, 89 anchors, 97 routes, 226 reactions, 700 markers), KEGG release
of 2026-08-18 (11 949 genomes, of which **10 151 bacterial**), Rhea release 141,
ChEBI release 253.

Scope: decide whether the catabolism of nitrate, urea, urate, GlcNAc,
allantoin, creatinine, betaine, L-carnitine, methylamine, phenylethylamine,
hypotaurine and taurine can be expressed as GIFTs, at what boundaries, and
which of them the available evidence actually supports.

Those twelve compounds are not an arbitrary list. They are, one for one, the
elements of **distillR 1.x bundle D06, "Nitrogen compound degradation"**
(`D0601`–`D0613`, with `D0605` absent from the legacy table). This proposal is
therefore also the migration assessment that
[Migration of legacy definitions](architecture.md#migration-of-legacy-definitions)
requires, and it uses that section's labels.

Three things decide the layer, and none of them is chemistry.

First, **gifter has no nitrogen boundary at all.** Ammonium appears in exactly
four curated reactions and in zero anchors. Nitrogen has never been a boundary
molecule, only a co-product. Making it one is the layer's central architectural
decision, and it needs a stated rule before the first anchor is added, exactly
as the vitamin layer needed the cofactor-anchor rule.

Second, **the twelve compounds are not one class.** They split five ways by
what the genome actually gets — nitrogen, carbon, sulfur, or a bioactive
product — and in three cases the compound's best-evidenced capability delivers
something other than nitrogen. "Nitrogen compound degradation" is a chemical
description of the substrate, not a capability, and it is not a facet value
gifter can adopt.

Third, **the largest single element of the legacy bundle is mostly
uncurateable, and for an architectural reason gifter already committed to.**
distillR's `D0601 Nitrate` merges assimilatory nitrate reduction with
respiratory nitrate reduction, denitrification and DNRA. gifter models no
electron acceptors. Only the assimilatory arm survives.

**Eleven GIFTs are recommended and two more conditionally; one existing GIFT
pair gains a boundary; six traits and two routes are refused, and three of the
refusals rest on evidence that also identifies a quantified error in the legacy
database.** No schema migration and no R change is required.

---

## 1. Recommendation in one page

1. **Adopt the nitrogen-anchor rule before adding `AMMONIUM`.** Ammonium may be
   declared an anchor only where the reaction's purpose is to liberate or to
   assimilate it, never where it is a leaving group of chemistry aimed at
   something else. Applied to the database as it stands, the rule admits
   **one** of the four existing NH4+ reactions and excludes three. Without it,
   riboflavin and menaquinone biosynthesis become ammonium sources and NAD
   biosynthesis becomes an ammonium sink. §7.
2. **Curate the ureide chain as three composable GIFTs, not one.** Urate →
   allantoin (1214 bacteria), allantoin → glyoxylate + urea (893), urea →
   ammonium (3725). Only **88** genomes complete all three. A single
   "purine nitrogen mineralisation" GIFT would be a trait that essentially
   nothing has, while the three-way cut describes 4242 genomes and exposes the
   cross-feeding structure — allantoin degraders that carry no uricase, urease
   carriers that make no urea. §6.1.
3. **Curate assimilatory nitrate reduction; refuse the other three nitrate
   capabilities architecturally.** `nitrate_assimilation` (nitrate → ammonium)
   completes in 3045 bacteria on markers that are specific to the assimilatory
   enzymes. Respiratory NarGHI (2393), periplasmic NapAB (1326), DNRA NrfAH
   (499) and denitrification (1512) all require an electron acceptor gifter does
   not model — the refusal already recorded on the `FUMARATE` anchor. NarG is
   independently disqualified: K00370 is *"nitrate reductase / nitrite
   oxidoreductase"*, one accession for two opposite reactions. §6.2, §8.
4. **Cut the methylated amines at sarcosine.** Betaine → sarcosine (759) and
   creatinine → sarcosine + urea (194) both converge on sarcosine, and
   sarcosine → glycine (2097) is far commoner than either. Cutting there
   composes creatinine into betaine chemistry, avoids duplicating the sarcosine
   step in two GIFTs, and is the same branchpoint argument that put
   `HOMOSERINE` between threonine and methionine. §6.3, §6.4.
5. **Curate carnitine → trimethylamine with two routes** (CntAB monooxygenase,
   271; CdhA/CdhC 3-dehydrocarnitine transfer, 733; union 972, overlap 32). The
   two routes are genuinely alternative implementations with almost disjoint
   carriage, which is what the OR-over-routes layer exists for. §6.5.
6. **Refuse phenylethylamine degradation.** No marker matches the specificity of
   the compound. K00276 is by its own name a *primary-amine* oxidase and
   K00274 a *monoamine* oxidase; both act on tyramine, histamine and putrescine
   as well. Accepting either would license a phenylethylamine claim from a
   genome that only degrades histamine, and would damage every other amine
   trait the same accession matches. Invariant 16, verbatim. §6.6, §11.
7. **Refuse hypotaurine degradation.** The only KO that names hypotaurine,
   K00485, has **zero** bacterial members. §6.7.
8. **Curate two taurine capabilities and refuse the one everybody wants.**
   Aerobic desulfonation by TauD (1065) and the anaerobic
   transamination/deamination route through sulfoacetaldehyde (397) are both
   well evidenced. **"Taurine to hydrogen sulfide" must be refused**: the step
   that makes H2S is dissimilatory sulfite reduction, which is respiration.
   gifter can state that a genome desulfonates taurine; it cannot state that
   sulfide comes out. §6.7, §8.
9. **Amend two existing GIFTs instead of writing a new one for GlcNAc.**
   `glcnac_degradation` and `neuac_degradation` both end at RHEA:12172, whose
   purpose is deamination. Under the rule in §7 they qualify to declare
   `AMMONIUM` as a second output anchor. This is the cheapest result in the
   layer: two nitrogen-source capabilities and no new route. §6.8.
10. **The layer is informative rather than universal.** 5587 of 10 151
    bacteria (55%) complete at least one recommended GIFT; **4564 complete
    none**. That distribution is the same shape as the vitamin layer's and is
    the reason the layer is worth curating. §9.4.

---

## 2. Scope: the legacy bundle, and why it is not one class

The request names twelve compounds. They are `D0601`–`D0613` of distillR's
`Nitrogen compound degradation`, reproduced here verbatim from the installed
package so that the migration is assessed against what the legacy database
actually says rather than against what it was meant to say:

| Legacy | Element | Legacy definition (EC or KO) |
|---|---|---|
| D0601 | Nitrate | `((K00370+K00371+K00374),(K02567+K02568)) ((K00362+K00363),(K03385+K15876))`; `1.7.5.1 1.7.2.1 1.7.2.5 1.7.2.4`; `1.9.6.1 1.7.2.2`; `1.7.7.2 1.7.7.1` |
| D0602 | Urea | `6.3.4.6 3.5.1.54`; `3.5.1.5` |
| D0603 | Urate | `1.7.3.3 3.5.2.17 4.1.1.97`; `1.14.13.113 3.5.2.17 4.1.1.97` |
| D0604 | GlcNAc | `2.7.1.59 3.5.1.25 3.5.99.6`; `3.5.1.25 3.5.99.6` |
| D0606 | Allantoin | `3.5.2.5 3.5.3.9 3.5.3.26 (1.1.1.350,1.1.1.154) 2.1.3.5`; `3.5.2.5 3.5.3.4 4.3.2.3`; `3.5.2.5 3.5.3.9 3.5.3.26 4.3.2.3` |
| D0607 | Creatinine | `3.5.4.21 3.5.2.14 3.5.1.59 1.5.3.1` |
| D0608 | Betaine | `2.1.1.5 1.5.3.10 (1.5.3.24,1.5.3.1)` |
| D0609 | L-carnitine | `1.14.13.239 1.2.1.4 1.1.1.38` |
| D0610 | Methylamine | `1.4.9.1`; `6.3.4.12 2.1.1.21 1.5.99.5` |
| D0611 | Phenylethylamine | `(1.4.3.4,1.4.3.21) 1.2.1.39` |
| D0612 | Hypotaurine | `2.6.1.77 1.2.1.3` |
| D0613 | Taurine | `2.6.1.77`; `2.5.1.55` |

The bundle name asserts that these belong together. They do not, and the
grouping principle is the substrate's element rather than the organism's
capability. Sorted by what a genome completing the route actually obtains:

| Group | Compounds | What the genome gets |
|---|---|---|
| **A. Ureide nitrogen** | urate, allantoin, urea | Nitrogen, and glyoxylate carbon |
| **B. Inorganic nitrogen** | nitrate | Nitrogen only; no carbon, no energy without an acceptor |
| **C. Methylated host amines** | betaine, L-carnitine, creatinine | Carbon and nitrogen — *or* a released trimethylamine that is not a nutrient at all |
| **D. Amines** | methylamine, phenylethylamine | Carbon and nitrogen |
| **E. Organosulfonates** | taurine, hypotaurine | **Sulfur** first; nitrogen and carbon incidentally |
| **F. Amino sugar** | GlcNAc | Already curated as carbon acquisition |

Group E is the clearest counter-example to the bundle. The dominant reason a
bacterium encodes TauD is sulfur starvation, not nitrogen acquisition: the
enzyme is an α-ketoglutarate-dependent dioxygenase whose product is sulfite,
and the aminoacetaldehyde is a by-product. Curating taurine as a nitrogen
capability would mis-state the biology in the facet layer even while getting the
routes right.

Group C is the second. `carnitine → trimethylamine` releases a compound the
organism does not use and the host converts to TMAO. That is neither carbon
acquisition nor nitrogen acquisition; it is the closest thing in this layer to
the `fermentative_end_product` role, and §10 proposes to say so.

**Consequence for facets.** `substrate_class` is single-valued per GIFT and its
current vocabulary has no value covering any of these twelve. Nor should a
single value cover them, since they are five classes. §10 proposes four new
`substrate_class` values and two new `physiological_role` values, and
deliberately does **not** propose a `nitrogen_compound` value that would
re-import the legacy conflation.

---

## 3. What the ontology and the runtime already support

Nothing in this layer requires a schema migration. Six things were checked
against `inst/schema/gifter.sql`, `R/database-build.R` and `R/evaluation.R`.

**Multiple output anchors are curated and validated.** `fucose_degradation_isomerase`
and `thiamine_precursor_salvage` both declare two. Allantoin degradation needs
two (glyoxylate and urea) and the anaerobic taurine route needs two (sulfite and
ammonium).

**Alternative routes under OR are the layer's dominant pattern.** Nitrate
assimilation needs 2 × 3 route alternatives, allantoin degradation 2, urate
degradation 2, carnitine 2. All of this is `gift_route` as it stands.

**`oxygen_requirement` is already three-valued and now has a second real user.**
The vitamin layer introduced `aerobic` for the corrin ring. TauD is
O2-dependent and the Tpa/Xsc route is not, so `taurine_desulfonation_aerobic`
and `taurine_degradation_sulfoacetaldehyde` differ in exactly this field.

**The within-mode acyclicity check tolerates the proposed graph.** The check in
`validate_gifter_sources()` (`R/database-build.R:1051`) scans directed modes
separately. The proposed catabolic subgraph is a forest converging on
`AMMONIUM` — urate → allantoin → urea → ammonium, creatinine → sarcosine →
glycine, betaine → sarcosine — with no back edge, because nothing in gifter
produces urate, allantoin, betaine, creatinine, carnitine or taurine. The one
edge that crosses modes, catabolic ammonium into anabolic assimilation, is the
case the rule explicitly expects.

**`gift_profile` needs no change and gains real signal.** Declaring the acquired
compounds `extracellular` where a transporter licenses it makes
`resource_strategy` report `uptake` for exactly the GIFTs where uptake is
evidenced — in this layer, taurine and only taurine. Note what that costs:
`cross_feeding_output` fires only on an `extracellular` output anchor, so the
allantoin hand-off of §6.1 will **not** be flagged by the view even though it is
the clearest cross-feeding relation in the layer. The compartment evidence is
what the flag depends on, and no allantoin transporter licenses the split.

**`biomass_essential` already covers nitrogen without being told about it.** If
`AMMONIUM` carries `biomass_essential = yes`, then any anabolic GIFT producing
it becomes an auxotrophy indicator by the existing view logic. This is the
correct claim for nitrate assimilation.

Two things the runtime does **not** support, and neither should be added for
this layer:

- **No electron acceptors, no respiration.** §8.
- **No mode for assimilatory reduction.** `mode` admits `anabolic`,
  `catabolic`, `transport`, `interconversion`. Nitrate → ammonium is a
  reductive assimilation of an inorganic nutrient and is none of them
  comfortably. §14.1 recommends `anabolic` on the `SULFIDE` precedent rather
  than a fifth mode, and records the argument for deferring the alternative.

---

## 4. What each source actually supplies

| Source | What it gives this layer | What it does not |
|---|---|---|
| **Rhea** | A master reaction for **43 of the 44** EC numbers tested, including the obscure ones: betaine monooxygenase 1.14.13.251 → `RHEA:45700`, cdhC 2.3.1.317 → `RHEA:47044`, betaine reductase 1.21.4.4 → `RHEA:11848`, cuyA 4.4.1.25 → `RHEA:13441` | A reaction for EC 1.7.99.4, the deleted assimilatory nitrate reductase EC. The chemistry is instead `RHEA:21068`, written on a generic acceptor — §14.2 |
| **KEGG orthology** | Clean, activity-specific KOs for the ureides, nitrate assimilation, the betaine demethylation chain, both carnitine routes, methylamine dehydrogenase and the whole taurine layer | Any KO that separates phenylethylamine oxidation from tyramine, histamine or putrescine oxidation (§6.6). Any KO for hypotaurine chemistry in bacteria (§6.7). A KO that separates nitrate reduction from nitrite oxidation — K00370 is *both* (§6.2) |
| **KEGG modules** | Little. M00546 and the purine-degradation maps organise the ureides, but no module states any of the twelve as a capability | Usable boundaries — the same finding as the vitamin layer |
| **ChEBI** | Identity for all proposed anchors | — |
| **MetaCyc** | **Reachable again, and this is a change.** `https://websvc.biocyc.org/getxml?id=META:<id>` returned a full pathway record on 2026-08-18. Two earlier proposals recorded MetaCyc as subscription-gated and returning no content | Search. The `/search` endpoint is HTML- and captcha-gated, so records can be cited by ID but not discovered programmatically. **gifter still cites no MetaCyc row, and this layer gives no reason to start** — but `SOURCES.md` should be corrected, because the reason recorded there is now wrong |
| **distillR 1.x `GIFT_db`** | A coverage check, and nothing else, per the rule set in the polysaccharide proposal §3. Used here to enumerate the twelve elements and, in §12, to identify three definitions that are wrong rather than merely coarse | Evidence. Three of its twelve definitions do not survive contact with the marker specificity invariant |

The MetaCyc row is worth a sentence of its own, since the request raised it.
distillR leaned on MetaCyc pathway boundaries; gifter does not, and the reason
is not access. It is that a pathway record is not a capability: it fixes no
input and output boundary a genome can be scored against, states no alternative
minimal routes as separate objects, and carries no marker layer. The
boundaries this proposal cuts — at sarcosine, at allantoin, at ammonium — come
from where genomes measurably differ, and MetaCyc agrees with some of them and
not others. Restoring MetaCyc as a *citable* source is worthwhile for
provenance; restoring it as a *structural* source would undo the reason gifter
exists.

---

## 5. The test

The protein, SCFA and vitamin layers each added a clause to the same test. This
layer adds a fourth, because its characteristic failure is new: the chemistry
is fine, the markers are specific, and the capability still cannot be stated
because its completion depends on something gifter does not model.

```text
does a marker exist whose specificity matches the compound named in the trait?
        |
        +-- no  --> refuse the trait                        (phenylethylamine,
        |                                                    hypotaurine)
        +-- yes --> does that marker's direction match the claim?
                        |
                        +-- no --> refuse, or state the ambiguity  (K00370:
                        |          nitrate reductase *or* nitrite oxidoreductase)
                        |
                        +-- yes --> is every required step evidenced at the
                                    specificity of the step?
                                        |
                                        +-- no --> orphan-step rule, as before
                                        |
                                        +-- yes --> does completing the route
                                                    require an external electron
                                                    acceptor, a membrane
                                                    potential, or any other
                                                    quantity gifter does not
                                                    model?
                                                      |
                                                      +-- no  --> curate
                                                      |
                                                      +-- yes --> refuse the
                                                                  trait as named,
                                                                  and curate the
                                                                  part that ends
                                                                  before the
                                                                  acceptor
```

The fourth clause is what separates this layer from every previous one. It
fires three times, and in each case it converts a popular trait into a narrower
one that is actually defensible:

| Trait as usually named | What the acceptor clause leaves |
|---|---|
| "nitrate respiration" / "denitrification" | `nitrate_assimilation`, ending at ammonium |
| "taurine to hydrogen sulfide" | `taurine_degradation_sulfoacetaldehyde`, ending at sulfite |
| "dissimilatory nitrate reduction to ammonium" | nothing; DNRA is respiration end to end |

Refusing to model respiration is not a gap this layer should close. It is the
scope statement in `AGENTS.md` — no growth, no flux balance, no exchange
reactions — applied to the one substrate class where users most want it broken.

---

## 6. Outcome when the test was applied, 2026-08-18

Prevalence is the number of the 10 151 KEGG **bacterial** genomes completing the
route as this proposal would curate it, computed from `link/genes/ko:` sets
intersected locally against the `br08601` bacterial organism list, not from
KEGG module completeness.

### 6.1 The ureides — curate three, and the cut is what makes them useful

Migration label: **candidate split** (`D0603`, `D0606`, `D0602` become three
GIFTs that compose, and the composition is the point).

| Proposed GIFT | Boundaries | Routes | Bacteria |
|---|---|---|---|
| `urate_degradation` | `URATE` → `ALLANTOIN` | uricase (K00365 / K16838) or FAD urate hydroxylase HpxO (K16839), then HIU hydrolase (K07127) | **1214** |
| `allantoin_degradation` | `ALLANTOIN` → `GLYOXYLATE` + `UREA` | allantoicase (K01477), or allantoate deiminase + ureidoglycine aminohydrolase (K02083 + K14977); both then ureidoglycolate lyase (K01483) | **893** |
| `urea_hydrolysis` | `UREA` → `AMMONIUM` | urease UreABC (K01428 + K01429/K14048 + K01430/K14048) | **3725** |

The numbers that justify the split are the ones for the chain rather than the
parts. **113 bacterial genomes complete urate → glyoxylate + urea, and only 88 also
hydrolyse the urea they release.** A single
GIFT covering the legacy `D0603` and `D0606` together would therefore be a trait
that 1.1% of bacteria have, and its negative call would be uninformative for
everyone else. Split at allantoin and at urea, the same chemistry describes
4242 distinct genomes and says something different about each:

- 1214 can open the purine ring, but **1101 of them cannot go past allantoin**;
- 893 consume allantoin, and **774 of those carry no uricase of any kind** — they
  are consumers of a compound something else released. That is a cross-feeding
  relation, but `gift_profile.cross_feeding_output` will not report it: the flag
  requires an `extracellular` output anchor and no allantoin transporter is
  evidenceable, so `ALLANTOIN` stays compartment-unresolved;
- 3725 hydrolyse urea, overwhelmingly from host or dietary urea rather than
  from ureide catabolism.

**Two curation decisions inside urease.** First, the accessory nickel-maturation
proteins UreD/E/F/G are *not* proposed as components of the catalytic system.
They are a maturation function, not part of the enzyme that hydrolyses urea,
and requiring all four drops the trait from 3725 to **2741**. UreE in
particular is absent or replaced in many genomes that unambiguously have active
urease. Since `enzyme_component` membership is jointly required with no
optional-component mechanism, the only honest choices are to include them and
lose 984 genomes or to exclude them and say why. This proposal excludes them
and records the number. Second, the fused `ureAB` gene (K14048, 560 genomes) is
an alternative for two components rather than a separate system — the
multifunctional-protein case the model already handles.

**The urea amidolyase route is refused for bacteria, on evidence.** distillR's
`D0602` offers `6.3.4.6 3.5.1.54` (urea carboxylase then allophanate
hydrolase) as an alternative to urease. The fused KO for that pathway, K14541,
has **zero** bacterial members; the standalone allophanate hydrolase K01457
(1612) is an atrazine- and cyanuric-acid-degradation enzyme that cannot by
itself evidence urea carboxylation. Rhea covers the chemistry
(`RHEA:20896`, `RHEA:19029`), so this is a marker refusal, not a chemistry one,
and it should be revisited if a bacterial urea-carboxylase KO appears.

### 6.2 Nitrate — curate the assimilatory arm, refuse the other three

Migration label: **candidate split**, and the split discards most of the legacy
element.

`D0601` is a single element whose four definitions cover, in order:
membrane-bound respiratory nitrate reductase with NADH nitrite reductase or
cytochrome *c* nitrite reductase; the quinol- and NO-forming denitrification
ECs; periplasmic nitrate reductase with DNRA; and, last, the ferredoxin-linked
assimilatory pair. A genome scoring positive on `D0601` might be denitrifying,
respiring nitrate to nitrite, performing DNRA, or assimilating nitrate into
biomass. Those are four different organisms.

**Curate `nitrate_assimilation`: `NITRATE` → `AMMONIUM`, 3045 bacteria.**

| Step | Alternatives | Bacteria |
|---|---|---|
| nitrate → nitrite | NasA/NasC (K00372, 2796) or ferredoxin-NarB (K00367, 422) | 3185 |
| nitrite → ammonium | NirA ferredoxin (K00366, 803), NirBD NADH (K00362 + K00363), or NasDE (K26139 + K26138) | 4708 |
| **both** | | **3045** |

The markers are specific in the direction that matters: NasA/NasC and NarB are
assimilatory enzymes, and NirA/NirBD/NasDE reduce nitrite all the way to
ammonium rather than to nitric oxide. The output is ammonium, a molecule gifter
can then assimilate, so the trait ends inside the model.

**Refuse `nitrate_respiration`, `denitrification` and `dnra`.** Two independent
reasons, and either alone is sufficient.

1. *The acceptor clause.* NarGHI (2393), NapAB (1326), NrfAH (499) and
   NirK/NirS (1512) all reduce nitrate or nitrite using a quinol pool or a
   cytochrome as the electron donor and the nitrogen species as the terminal
   acceptor. Curating them would require quinone/quinol boundaries, and the
   trait's meaning — "can respire nitrate" — is a statement about energy
   conservation that gifter has no layer for. This is the refusal already
   recorded on the `FUMARATE` anchor, applied to a second acceptor.
2. *Marker direction.* K00370 is named, by KEGG, **`narG, narZ, nxrA; nitrate
   reductase / nitrite oxidoreductase`**. The same accession identifies the
   enzyme that reduces nitrate and the enzyme that oxidises nitrite — opposite
   reactions, and in nitrite-oxidising bacteria the second is the physiological
   one. A marker that cannot say which direction the enzyme runs cannot license
   a directed catabolic claim. This is the second clause of the test, and it is
   the same failure as `acetate_interconversion`, except that here there is no
   `interconversion` mode to retreat to, because nitrate and nitrite are not a
   near-equilibrium couple.

**Nitrate transport is deferred.** NrtABCD (K15576–K15579) completes in 1582
genomes and is specific, which would license an `extracellular`/`cytoplasmic`
split on `NITRATE` under the polysaccharide layer's splitting licence. But
NarK/NRT2 (K02575, 4298) is an MFS carrier shared by nitrate and nitrite and by
both assimilatory and respiratory contexts, so the commoner transporter cannot
support the split. §14.3 leaves `NITRATE` as `unspecified` and records the
consequence: no `uptake` resource strategy for this GIFT.

### 6.3 Betaine — curate two, cut at sarcosine, defer the reductase

Migration label: **candidate split** plus **boundary curation required**.

distillR's `D0608` is `2.1.1.5 1.5.3.10 (1.5.3.24,1.5.3.1)`: betaine-homocysteine
methyltransferase, then dimethylglycine oxidase, then sarcosine oxidase. The
first EC is the problem. **BHMT (K00544) has 87 bacterial members**, and it is
a methionine-cycle enzyme whose physiological role in the organisms that have
it is regenerating methionine, not catabolising betaine. The oxidative
demethylation route the legacy definition skips — glycine betaine monooxygenase
GbcAB — has **883**.

| Proposed GIFT | Boundaries | Systems | Bacteria |
|---|---|---|---|
| `betaine_demethylation` | `BETAINE` → `SARCOSINE` | GbcAB (K00479 + K21832) → dimethylglycine; then DgcAB (K21833 + K21834), DMGDH (K00315) or Dmg oxidase (K00309) | **759** |
| `sarcosine_demethylation` | `SARCOSINE` → `GLYCINE` | heterotetrameric sarcosine oxidase SoxABG(D), monomeric SoxA (K00301), or DgcAB | **2097** |

**Why cut at sarcosine.** Sarcosine is a genuine convergence point, not a
convenience: it is reached from betaine by demethylation and from creatinine by
amidinohydrolysis, and its own demethylation is nearly three times commoner
than either upstream capability. Curating one `betaine → glycine` GIFT (745)
and one `creatinine → glycine` GIFT would duplicate the sarcosine step in both,
which invariant 8 forbids. The cut is the same one that put `HOMOSERINE`
between threonine and methionine biosynthesis.

**Defer `betaine_reduction_trimethylamine`.** The Stickland betaine reductase
(GrdHI, K21578 + K21579, plus the shared GrdA/GrdC/GrdD components) releases
trimethylamine and acetyl phosphate, which makes it the most host-relevant
chemistry in the group. It completes in **37** bacterial genomes. That is an
order of magnitude below the lowest carriage any previous proposal accepted —
the vitamin layer's `dmb_biosynthesis_aerobic`, at 538 — and a five-component
complex at that prevalence carries a high false-negative risk from single
missing subunits. Deferred, not refused: the markers are specific
(GrdH/GrdI are the betaine-specific B component) and the chemistry has a Rhea
master, `RHEA:11848`.

**The better-evidenced trimethylamine trait is next door, and is not on the
list.** Choline TMA-lyase CutC/CutD (K20038 + K20037) completes in **212**
genomes on two specific markers and one reaction (`RHEA` via EC 4.3.99.4), and
it is the capability the TMAO literature is actually about. It is out of scope
here because choline is not on the request, but §15 recommends it as the
natural companion.

### 6.4 Creatinine — curate one route, refuse the other on marker specificity

Migration label: **reaction mapping required**, and the legacy definition picks
the wrong route.

distillR's `D0607` is `3.5.4.21 3.5.2.14 3.5.1.59 1.5.3.1`: creatinine
deiminase, N-methylhydantoinase, N-carbamoylsarcosine amidase, sarcosine
oxidase. That chain completes in **15** bacterial genomes. The route it omits,
creatininase followed by creatinase, completes in **194**.

**Curate `creatinine_degradation`: `CREATININE` → `SARCOSINE` + `UREA`, 194
bacteria**, on creatinine amidohydrolase (K01470, EC 3.5.2.10, `RHEA:14533`)
then creatinase (K08688, EC 3.5.3.3, `RHEA:22456`).

Two things about this GIFT are worth recording.

First, it is the layer's clearest illustration of why a single marker is not a
capability. **K01470 alone occurs in 2431 genomes; K08688 in 402; both in
194.** Most carriers of the creatininase fold are not creatinine degraders, and
a trait built on the first enzyme would over-call by more than tenfold.

Second, the deiminase route is refused on the first clause of the test, not on
prevalence. **K01485 is `codA; cytosine/creatinine deaminase`** — one accession
for two activities, and the cytosine deaminase activity is the common one
(2702 genomes carry K01485; pyrimidine salvage, not creatinine catabolism).
Under invariant 16 that accession licenses neither claim specifically, and
accepting it for creatinine would damage any future cytosine-salvage trait.
The route is therefore refused even though its remaining three steps have clean
markers (K01473, K01474, K08687) and Rhea masters.

Composition does the rest: `creatinine_degradation` reaches glycine through
`sarcosine_demethylation` and reaches ammonium through `urea_hydrolysis`,
without duplicating a reaction from either.

### 6.5 L-carnitine — curate, two routes, and the legacy definition's tail is generic

Migration label: **enzyme curation required**.

distillR's `D0609` is `1.14.13.239 1.2.1.4 1.1.1.38`. The first EC is carnitine
monooxygenase and is right. The second is NADP-dependent aldehyde dehydrogenase
(K14519) and the third is malic enzyme (K00027); both are general metabolism
present in most genomes and neither says anything about carnitine. In practice
the legacy element is carried by its first EC alone.

**Curate `carnitine_degradation_trimethylamine`: `CARNITINE` →
`TRIMETHYLAMINE`.**

| Route | Components | Bacteria | O2 |
|---|---|---|---|
| CntAB Rieske monooxygenase | K22443 + K22444, `RHEA:55368` | 271 | aerobic |
| CdhA/CdhC dehydrogenase–transferase | K17735 (or K27497) + K27837, `RHEA:19265`, `RHEA:47044` | 733 | independent |
| **either** | | **972** | |

The two routes overlap in only **32** genomes. That is close to the ideal case
for the OR-over-routes layer: two chemically distinct implementations of one
capability, carried by almost disjoint sets of organisms, which a single
flattened definition would have to represent either as a false AND or as a
marker union that loses the distinction. `oxygen_requirement` separates them.

**CaiTABCDE is not this GIFT and must not be merged into it.** The carnitine
CoA-transferase / dehydratase operon (K08298 + K02182 + K05245, 219 genomes)
converts carnitine to γ-butyrobetaine and releases **no trimethylamine**. It is
a distinct capability with a distinct product, and adding its markers to the
TMA trait would be the over-broad-marker error in its most seductive form,
since the genes are genuinely carnitine-specific. If it is curated later it is
a separate GIFT ending at a `BUTYROBETAINE` anchor.

### 6.6 Phenylethylamine — refuse

Migration label: **deprecated**.

`D0611` is `(1.4.3.4,1.4.3.21) 1.2.1.39`. Both first-step alternatives fail the
first clause of the test on their own names:

| KO | KEGG name | Bacteria |
|---|---|---|
| K00276 | `AOC3, AOC2, tynA; **primary-amine** oxidase [EC:1.4.3.21]` | 975 |
| K00274 | `MAO, aofH; **monoamine** oxidase [EC:1.4.3.4]` | 1704 |

A primary-amine oxidase oxidises 2-phenylethylamine, tyramine, histamine,
putrescine and cadaverine. The accession identifies the chemistry —
oxidative deamination of a primary amine — and cannot identify the amine. Under
invariant 16 it licenses only the broader trait, and accepting it for
phenylethylamine would silently equate a histamine-degrading genome with a
phenylethylamine-degrading one.

The second EC, phenylacetaldehyde dehydrogenase (K00146, `RHEA:21392`, 1165
genomes), is substrate-specific but is the *wrong step*: it evidences that a
genome can oxidise phenylacetaldehyde, which arises from phenylalanine
transamination and from styrene degradation as well as from phenylethylamine.
Requiring both gives 353 genomes, but the pair still does not exclude a genome
whose amine oxidase acts on tyramine while its aldehyde dehydrogenase serves a
different pathway.

**Refuse the trait as named.** The nearest defensible capability is "oxidative
deamination of primary amines", which is an activity rather than a compound
capability and which gifter has no business naming as a GIFT. Recorded as a
refusal with its evidence, per the standard set by the collagen and CAZy cases.

### 6.7 Taurine and hypotaurine — curate two, refuse two

Migration label: **candidate split** for taurine, **deprecated** for
hypotaurine.

**Hypotaurine: refuse.** The only KEGG orthology group whose name contains
"hypotaurine" is K00485 (`FMO; dimethylaniline monooxygenase (N-oxide forming)
/ hypotaurine monooxygenase`), which has **zero bacterial members**. distillR's
`D0612` defines hypotaurine as `2.6.1.77 1.2.1.3` — taurine—pyruvate
aminotransferase and generic NAD-dependent aldehyde dehydrogenase. The first is
a **taurine** enzyme, so the legacy hypotaurine element cannot distinguish
hypotaurine from taurine; the second (K00128) is present in a large fraction of
genomes. There is no bacterial hypotaurine capability to curate at present.

**Taurine: curate two GIFTs, which differ in oxygen and in product.**

| Proposed GIFT | Boundaries | Route | Bacteria | O2 |
|---|---|---|---|---|
| `taurine_desulfonation_aerobic` | `TAURINE` → `SULFITE` | TauD α-KG dioxygenase (K03119), `RHEA:15909` | **1065** | aerobic |
| `taurine_degradation_sulfoacetaldehyde` | `TAURINE` → `SULFITE` + `AMMONIUM` | Tpa transaminase (K03851, `RHEA:10420`) or TauXY dehydrogenase (K07255 + K07256, `RHEA:18709`), then Xsc (K03852, `RHEA:24204`) | **397** | independent |

These are genuinely different capabilities, not two routes of one. The first
releases the sulfonate sulfur and leaves the nitrogen on aminoacetaldehyde; the
second deaminates or transaminates first and releases both. The first is a
sulfur-starvation response; the second is the fermentative route associated
with *Bilophila* and with taurine-conjugated bile acid metabolism.

**"Taurine to hydrogen sulfide" is refused.** This is the trait the gut
literature wants and the acceptor clause forbids. Both routes above end at
sulfite. Converting sulfite to sulfide is dissimilatory sulfite reduction —
DsrAB (K11180 + K11181, 228 genomes) or AsrABC (284) — which is respiration
with sulfite as terminal electron acceptor. gifter can state that a genome
desulfonates taurine. It cannot state that H2S comes out, and a GIFT that
implied it would be the layer's worst error.

Two smaller decisions. `TauABC` (K15551 + K10831 + K15552, 1462 genomes) is a
specific ABC importer and **does** license an `extracellular`/`cytoplasmic`
split on `TAURINE` plus a `taurine_uptake_abc` transport GIFT, on exactly the
grounds the polysaccharide layer used for xylose and arabinose; §14.3 proposes
it. And Xsc's product, acetyl phosphate, is left as an internal intermediate
rather than declared, which costs a graph edge into `acetate_interconversion`;
§14.4 records that as an open decision rather than deciding it here.

### 6.8 GlcNAc — no new GIFT; amend two existing ones

Migration label: **redundant**, with a boundary amendment.

`D0604` is `2.7.1.59 3.5.1.25 3.5.99.6` — GlcNAc kinase, GlcNAc-6-P deacetylase,
glucosamine-6-P deaminase. gifter already curates exactly that chain as
`glcnac_degradation` (`GLCNAC` → `FRUCTOSE_6P`, route `GLCNAC_KINASE`,
RHEA:17417 → RHEA:22936 → RHEA:12172). No new GIFT is warranted.

One amendment is. The final reaction, **RHEA:12172**, is
`alpha-D-glucosamine 6-phosphate + H2O = beta-D-fructose 6-phosphate +
ammonium`, and the whole purpose of a deaminase is to remove the amino group.
Under the rule in §7 it therefore qualifies to declare `AMMONIUM` as an output
anchor. **The same reaction terminates `neuac_degradation`**, so both amino
sugar GIFTs gain the boundary from one decision and one row each in
`gift_anchors.tsv`.

The effect is that the two capabilities gifter already scores as host-glycan
foraging become, correctly, nitrogen sources as well, and they connect to
`ammonium_assimilation` in the graph. No route, reaction, system, component or
marker changes, and no call changes. This is the cheapest result in the layer.

### 6.9 Methylamine — curate one route, refuse the other on prevalence

Migration label: **direct migration**, narrowed.

`D0610` offers `1.4.9.1` (methylamine dehydrogenase) and
`6.3.4.12 2.1.1.21 1.5.99.5` (the N-methylglutamate pathway).

**Curate `methylamine_degradation`: `METHYLAMINE` → `AMMONIUM`, 213 bacteria**,
on the MauAB tryptophan-tryptophylquinone dehydrogenase (K15228 + K15229,
`RHEA:30207`). Both subunits are jointly required, and the enzyme is
distinctive enough that its accessions carry no other activity.

The N-methylglutamate route (GmaS K01949 + MgdABCD K22084–K22087) completes in
**46** genomes. Deferred on prevalence rather than refused: its markers are
specific, but four jointly required subunits at that carriage make single
missing annotations dominate the call.

Formaldehyde, the carbon product, is left internal. Declaring it would create a
boundary molecule that gifter has no consumer for and that is chemically a
transient the cell detoxifies immediately.

---

## 7. The nitrogen-anchor rule

This layer's equivalent of the vitamin layer's cofactor-anchor rule, and it must
be stated before `AMMONIUM` is added rather than after.

> **A nitrogen species may be declared an anchor only where the reaction's
> purpose is to liberate it from an organic substrate or to assimilate it into
> one. It may not be declared where it is a leaving group of chemistry aimed at
> a different product, or a co-substrate of amidation.**

Without the rule, `AMMONIUM` becomes an anchor of much of the existing database
by accident, because ammonium is a common participant. The rule's effect is
exactly measurable against the four reactions that mention NH4+ today:

| Reaction | GIFT | Role of NH4+ | Rule |
|---|---|---|---|
| `RHEA:12172` glucosamine-6-P deaminase | `glcnac_degradation`, `neuac_degradation` | The reaction *is* the deamination | **admitted** |
| `RHEA:21868` diaminohydroxyphosphoribosylaminopyrimidine deaminase | `riboflavin_biosynthesis` | Leaving group of a pyrimidine ring modification | rejected |
| `RHEA:40075` aminodeoxyfutalosine deaminase | `menaquinone_biosynthesis` | Leaving group en route to a naphthoquinone | rejected |
| `RHEA:21188` NAD synthetase (ammonia) | `nad_biosynthesis_namn` | Co-substrate of an amidation | rejected |

One admitted, three rejected — and each rejection prevents a specific absurdity.
Admitting the riboflavin and menaquinone deaminases would make two vitamin
biosynthesis GIFTs into nitrogen sources. Admitting the NAD synthetase would
make NAD biosynthesis an ammonium *sink*, so that every ammonium-releasing
catabolic GIFT in this proposal would gain a composition edge into it, and
`nad_biosynthesis_namn` would acquire an input boundary that its ATP-dependent
glutamine-hydrolysing variant does not even use.

The rule generalises the reasoning of the cofactor rule rather than repeating
it. The cofactor rule asks whether the molecule is *consumed*; that test is not
enough here, because the NAD synthetase genuinely consumes ammonium. The
nitrogen rule asks what the reaction is *for*. Both are curator judgements
recorded in the anchor's description, and both are enforced by review rather
than by the validator — which is the honest place for them, since no schema
constraint can express "what the chemistry is aimed at".

The same rule, applied forward, is what keeps the layer's own boundaries
defensible. `taurine_degradation_sulfoacetaldehyde` declares `AMMONIUM` because
Tpa and TauXY exist to remove the amino group. `methylamine_degradation`
declares it for the same reason. `taurine_desulfonation_aerobic` does **not**,
because TauD leaves the nitrogen on the aldehyde.

---

## 8. The electron-acceptor boundary, stated once

gifter's scope statement excludes growth, flux balance, thermodynamics, media,
metabolite concentrations, exchange reactions and runtime stoichiometry. It
does not, in so many words, exclude respiration — but the `FUMARATE` anchor
already records the consequence: *"gifter models no electron acceptors, so this
anchor supports no fumarate respiration claim."*

This layer is where that sentence has to become a general rule, because it
decides four candidate traits at once and because users will ask about all four.

> **A capability whose completion requires an external terminal electron
> acceptor is out of scope. Curate the part of the chemistry that ends before
> the acceptor, and name the trait for what that part does.**

Applied here:

| Refused as named | Why | Curated instead |
|---|---|---|
| nitrate respiration | Quinol → nitrate; energy conservation | `nitrate_assimilation` |
| denitrification | NO, N2O, N2 as successive acceptors | — |
| dissimilatory nitrate reduction to ammonium | Respiratory end to end | — |
| taurine → hydrogen sulfide | Sulfite as terminal acceptor (DsrAB) | `taurine_degradation_sulfoacetaldehyde` |

Two consequences worth stating plainly, because they are costs.

**gifter will under-describe anaerobic ecology.** A genome with a complete
denitrification pathway will score negative on everything in this layer except
whatever else it carries. That is correct under the model and will still
surprise users, so the refusals belong in `database_changes.tsv` where the
atlas surfaces them, not only in this document.

**The refusal is architectural, not evidential, and must not be quietly
reversed.** The markers for NarGHI, NirK, NorBC, NosZ and DsrAB are specific,
abundant and easy to curate. That is precisely why the boundary needs writing
down: nothing in the evidence layer will stop someone adding them, and the
resulting GIFTs would make positive claims about energy metabolism that the
completeness model cannot bound. Reversing this is an architectural decision
with its own proposal, its own completeness contract, and probably its own
`gift_type`.

---

## 9. The proposed GIFT set

### 9.1 GIFTs

| GIFT | Type | Mode | Boundaries | Bacteria |
|---|---|---|---|---|
| `urate_degradation` | metabolic | catabolic | `URATE` → `ALLANTOIN` | 1214 |
| `allantoin_degradation` | metabolic | catabolic | `ALLANTOIN` → `GLYOXYLATE`, `UREA` | 893 |
| `urea_hydrolysis` | metabolic | catabolic | `UREA` → `AMMONIUM` | 3725 |
| `nitrate_assimilation` | metabolic | anabolic | `NITRATE` → `AMMONIUM` | 3045 |
| `betaine_demethylation` | metabolic | catabolic | `BETAINE` → `SARCOSINE` | 759 |
| `sarcosine_demethylation` | metabolic | catabolic | `SARCOSINE` → `GLYCINE` | 2097 |
| `creatinine_degradation` | metabolic | catabolic | `CREATININE` → `SARCOSINE`, `UREA` | 194 |
| `carnitine_degradation_trimethylamine` | metabolic | catabolic | `CARNITINE` → `TRIMETHYLAMINE` | 972 |
| `methylamine_degradation` | metabolic | catabolic | `METHYLAMINE` → `AMMONIUM` | 213 |
| `taurine_desulfonation_aerobic` | metabolic | catabolic | `TAURINE` → `SULFITE` | 1065 |
| `taurine_degradation_sulfoacetaldehyde` | metabolic | catabolic | `TAURINE` → `SULFITE`, `AMMONIUM` | 397 |
| *conditional:* `ammonium_assimilation` | metabolic | anabolic | `AMMONIUM`, `OXOGLUTARATE` → `GLUTAMATE` | 9482 |
| *conditional:* `taurine_uptake_abc` | metabolic | transport | `TAURINE_EX` → `TAURINE_IN` | 1462 |

Eleven unconditional, two conditional. The two conditional ones are §14.5 and
§14.3.

### 9.2 Amendments to existing GIFTs

| GIFT | Change | Effect on calls |
|---|---|---|
| `glcnac_degradation` | declare `AMMONIUM` as output anchor 2 | none |
| `neuac_degradation` | declare `AMMONIUM` as output anchor 2 | none |

### 9.3 Anchors

Fifteen new anchors, plus one compartment split if §14.3 is accepted. Each is
defended as a boundary rather than as a metabolite, per invariant 3.

| Anchor | ChEBI | Why it is a boundary |
|---|---|---|
| `AMMONIUM` | CHEBI:28938 | The convergence point of every nitrogen-liberating capability in the layer and the entry point of assimilation. Governed by §7 |
| `NITRATE` | CHEBI:17632 | Environmental inorganic nitrogen source |
| `UREA` | CHEBI:16199 | Host- and diet-derived, and independently the product of two curated catabolic routes. The layer's clearest shared boundary |
| `URATE` | CHEBI:17775 | Host purine end product; the entry point of ureide catabolism. This is the species `RHEA:21368` itself uses, though ChEBI displays it under its systematic name |
| `ALLANTOIN` | CHEBI:15676 | Branchpoint: released by urate degraders and consumed by genomes that carry no uricase |
| `GLYOXYLATE` | CHEBI:36655 | Carbon fate of allantoin degradation. Output-only; the glyoxylate shunt is not curated |
| `SARCOSINE` | CHEBI:57433 | Convergence point of betaine and creatinine catabolism, and the reason both are split there (§6.3) |
| `BETAINE` | CHEBI:17750 | Host- and diet-derived osmolyte |
| `CARNITINE` | CHEBI:16347 | Host- and diet-derived; the substrate of the layer's most host-relevant capability |
| `CREATININE` | CHEBI:16737 | Host muscle metabolite |
| `TRIMETHYLAMINE` | CHEBI:18139 | Released product that the organism does not use. Output-only |
| `METHYLAMINE` | CHEBI:59338 | Environmental and host-derived methylated amine |
| `TAURINE` | CHEBI:507393 | Host-derived, bile-acid-conjugated; carbon, nitrogen and sulfur source |
| `SULFITE` | CHEBI:17359 | Product of both taurine capabilities. Output-only under this proposal — the sulfite → sulfide step is respiration (§8) |
| `GLUTAMATE` | CHEBI:29985 | Only if `ammonium_assimilation` is accepted (§14.5) |

Every ChEBI identifier above was resolved on 2026-08-18. Five resolve to a
protonation or tautomer state whose ChEBI label differs from the anchor name —
`ammonium`, `methylammonium`, `sarcosine zwitterion`, `taurine zwitterion`,
`L-glutamate(1-)` — which is the same convention the existing `GLYCINE`
(CHEBI:57305, glycine zwitterion) and `NEUAC` (CHEBI:173083, aceneuramate)
anchors already follow.

`GLYOXYLATE`, `TRIMETHYLAMINE` and `SULFITE` are declared output-only, on the
precedent of `HOMOCYSTEINE`, `AIR` and `FMNH2` being declared input-only: a
boundary with no counterpart in the database is a statement about where the
claim stops, not a gap.

### 9.4 The composition graph

Edges are derived, not curated. Within the catabolic mode the proposed layer is
a forest converging on `AMMONIUM`:

```text
URATE ──urate_degradation──▶ ALLANTOIN ──allantoin_degradation──┬──▶ GLYOXYLATE
                                                                 └──▶ UREA
CREATININE ──creatinine_degradation──┬──▶ SARCOSINE ──sarcosine_demethylation──▶ GLYCINE
                                     └──▶ UREA
BETAINE ──betaine_demethylation──────▶ SARCOSINE
                                    UREA ──urea_hydrolysis──▶ AMMONIUM
TAURINE ──taurine_degradation_sulfoacetaldehyde──┬──▶ SULFITE
                                                  └──▶ AMMONIUM
METHYLAMINE ──methylamine_degradation────────────────▶ AMMONIUM
GLCNAC ──glcnac_degradation (amended)────────────────▶ AMMONIUM
NEUAC ──neuac_degradation (amended)──────────────────▶ AMMONIUM
CARNITINE ──carnitine_degradation_trimethylamine─────▶ TRIMETHYLAMINE

NITRATE ──nitrate_assimilation (anabolic)────────────▶ AMMONIUM
AMMONIUM ──ammonium_assimilation (anabolic)──────────▶ GLUTAMATE
```

No within-mode cycle exists, and none can arise from this content: nothing in
gifter produces urate, allantoin, betaine, creatinine, carnitine, taurine or
nitrate, so every catabolic chain here is a path with a source outside the
model. The single cross-mode edge, catabolic ammonium into anabolic
assimilation, is the case the acyclicity rule explicitly expects — the same
shape as a catabolic route feeding a biosynthetic one.

`AMMONIUM` becomes the most connected anchor in the database, with seven
incoming GIFTs. That is a hub, not a boundary error: every one of those edges
is a real biological statement that a genome carrying the upstream capability
supplies nitrogen to the downstream one.

**Coverage.** Across all 10 151 bacterial genomes, **5587 (55%) complete at
least one** of the eleven unconditional GIFTs and **4564 complete none**. The
layer is therefore discriminating rather than universal, like the vitamin
layer and unlike the central-carbon one.

---

## 10. Facet vocabulary

`substrate_class` is single-valued and closed within the facet. The layer needs
four new values and deliberately does **not** propose a `nitrogen_compound`
value, which would re-import the legacy conflation §2 rejects.

| Facet | New value | Definition | GIFTs |
|---|---|---|---|
| `substrate_class` | `inorganic_nitrogen` | Inorganic nitrogen species used as a nitrogen source, such as nitrate, nitrite and ammonium. | `nitrate_assimilation`, `ammonium_assimilation` |
| `substrate_class` | `ureide` | Urea and the cyclic and open-chain ureides of purine catabolism. | `urate_degradation`, `allantoin_degradation`, `urea_hydrolysis` |
| `substrate_class` | `methylated_amine` | Quaternary ammonium compounds and methylated amines, such as glycine betaine, L-carnitine, creatinine and methylamine. | `betaine_demethylation`, `sarcosine_demethylation`, `creatinine_degradation`, `carnitine_degradation_trimethylamine`, `methylamine_degradation` |
| `substrate_class` | `organosulfonate` | Carbon–sulfonate compounds such as taurine and its metabolites. | both taurine GIFTs |
| `physiological_role` | `nitrogen_acquisition` | Liberates or assimilates nitrogen the cell can incorporate into biomass. Names what the chemistry does, not that the nitrogen is incorporated. | nine GIFTs, plus the two amended amino sugar ones |
| `physiological_role` | `sulfur_acquisition` | Liberates sulfur from an organic substrate in a form the cell can assimilate. | both taurine GIFTs |

Existing values carry the rest. `host_glycan_foraging` already applies to the
two amended amino sugar GIFTs. `carbon_acquisition` applies to betaine,
sarcosine, creatinine and allantoin degradation. And
`fermentative_end_product` is the closest existing role for
`carnitine_degradation_trimethylamine`, whose product the organism does not
use — §14.6 asks whether that role should be broadened or whether a
`released_bioactive_product` role is warranted, since trimethylamine is not a
fermentation product in any conventional sense.

Anchor facets follow the existing vocabulary without additions:
`resource_origin = host_derived` for urate, urea, creatinine, taurine and
carnitine; `plant_derived` and `host_derived` both for betaine;
`inorganic` for nitrate and ammonium; `molecular_tier = small_molecule`
throughout; and `biomass_essential = yes` for ammonium, which is what makes
`nitrate_assimilation` an auxotrophy indicator with no new logic.

---

## 11. Refusals

Recorded as results, with the evidence that decided each.

| Refused | Clause | Evidence |
|---|---|---|
| `phenylethylamine_degradation` | specificity | K00276 is a *primary-amine* oxidase (975) and K00274 a *monoamine* oxidase (1704); neither can name the amine. K00146 is the wrong step |
| `hypotaurine_degradation` | specificity | K00485, the only hypotaurine KO, has 0 bacterial members. The legacy definition uses a taurine enzyme and a generic ALDH |
| `nitrate_respiration` | acceptor + direction | NarGHI 2393, NapAB 1326; and K00370 is `nitrate reductase / **nitrite oxidoreductase**` |
| `denitrification` | acceptor | NirK/NirS 1512; NO, N2O and N2 are successive terminal acceptors |
| `dissimilatory_nitrate_reduction_to_ammonium` | acceptor | NrfAH 499; respiratory end to end |
| `taurine_to_hydrogen_sulfide` | acceptor | Requires DsrAB (228) or AsrAB (284); sulfite as terminal acceptor |
| urea amidolyase route | specificity | K14541 has 0 bacterial members; K01457 alone cannot evidence urea carboxylation |
| creatinine deiminase route | specificity | K01485 is `cytosine/**creatinine** deaminase`, one accession for two activities, 2702 genomes |

Deferred rather than refused, because the markers are sound and only the
carriage is low: `betaine_reduction_trimethylamine` (37),
`methylamine_degradation` via N-methylglutamate (46), `caiTABCDE`
γ-butyrobetaine formation (219), nitrate transport (§14.3).

---

## 12. Three quantified errors in the legacy definitions

The coverage check found three legacy definitions that are wrong rather than
merely coarse. They are recorded because they bear on how much weight the
legacy database should carry in any future migration, and because the third one
is severe.

**1. `D0613 Taurine`, second definition: `2.5.1.55`.**
EC 2.5.1.55 is **3-deoxy-8-phosphooctulonate synthase (KDO 8-phosphate
synthase)**, KEGG orthology **K01627 `kdsA`** — a lipopolysaccharide core
biosynthesis enzyme with no connection to taurine of any kind. It is present in
**5537 of 10 151 bacterial genomes (55%)**. Any analysis that scored `D0613`
therefore reported a taurine-degradation signal in more than half of all
bacteria on the strength of an LPS gene. The intended EC was almost certainly
**2.5.1.76, cysteate synthase** (K15527, 39 bacterial genomes) — a single
transposed digit, and a four-order-of-magnitude difference in what the trait
means.

**2. `D0612 Hypotaurine`: `2.6.1.77 1.2.1.3`.**
EC 2.6.1.77 is taurine—pyruvate aminotransferase, a **taurine** enzyme, and it
is also the whole of `D0613`'s first definition. The hypotaurine element is
therefore evidenced by the taurine element's enzyme plus a generic
NAD-dependent aldehyde dehydrogenase. It cannot distinguish the two compounds,
and one of the two ECs would fire on most genomes.

**3. `D0601 Nitrate`.**
Not an error of identity but of scope: four definitions spanning assimilation,
respiration, denitrification and DNRA under one element name, so that a
positive call does not say which of four different physiologies the genome has.
§6.2.

Two further definitions are not wrong but are carried entirely by their first
enzyme, their remaining ECs being general metabolism: `D0609 L-carnitine`
(`1.2.1.4` NADP-aldehyde dehydrogenase, `1.1.1.38` malic enzyme) and
`D0608 Betaine`, whose first EC (BHMT, 87 genomes) is a methionine-cycle enzyme
rather than a betaine catabolic one.

None of this is an argument against distillR, which was doing something
different with a different primitive. It is an argument for the rule the
polysaccharide proposal already set: the legacy database is a coverage
checklist, never an evidence source.

---

## 13. Identifiers, verified 2026-08-18

All Rhea master IDs below were resolved from `rhea2ec.tsv` (release 141) or the
Rhea REST API on 2026-08-18. Forty-three of the forty-four EC numbers tested
returned a master reaction.

| Step | EC | Rhea master |
|---|---|---|
| urease | 3.5.1.5 | RHEA:20557 |
| urate oxidase | 1.7.3.3 | RHEA:21368 |
| FAD urate hydroxylase (HpxO) | 1.14.13.113 | RHEA:27329 |
| 5-hydroxyisourate hydrolase | 3.5.2.17 | RHEA:23736 |
| OHCU decarboxylase | 4.1.1.97 | RHEA:26301 |
| allantoinase | 3.5.2.5 | RHEA:17029 |
| allantoate deiminase | 3.5.3.9 | RHEA:27485 |
| ureidoglycine aminohydrolase | 3.5.3.26 | RHEA:25241 |
| allantoicase | 3.5.3.4 | RHEA:11016 |
| ureidoglycolate lyase | 4.3.2.3 | RHEA:11304 |
| creatinine amidohydrolase | 3.5.2.10 | RHEA:14533 |
| creatinase | 3.5.3.3 | RHEA:22456 |
| sarcosine oxidase | 1.5.3.1 | RHEA:13313 |
| dimethylglycine dehydrogenase | 1.5.8.4 | RHEA:52856 |
| dimethylglycine/sarcosine dehydrogenase | 1.5.7.3 | RHEA:74155, RHEA:74167 |
| glycine betaine monooxygenase | 1.14.13.251 | RHEA:45700 |
| betaine reductase | 1.21.4.4 | RHEA:11848 |
| carnitine monooxygenase | 1.14.13.239 | RHEA:55368, RHEA:55396 |
| carnitine 3-dehydrogenase | 1.1.1.108 | RHEA:19265 |
| 3-dehydrocarnitine:acetyl-CoA TMA transferase | 2.3.1.317 | RHEA:47044 |
| methylamine dehydrogenase | 1.4.9.1 | RHEA:30207 |
| taurine dioxygenase | 1.14.11.17 | RHEA:15909 |
| taurine—pyruvate aminotransferase | 2.6.1.77 | RHEA:10420 |
| taurine dehydrogenase | — | RHEA:18709 (generic acceptor), RHEA:81555 (cytochrome *c*) |
| sulfoacetaldehyde acetyltransferase | 2.3.3.15 | RHEA:24204 |
| ferredoxin-nitrate reductase | 1.7.7.2 | RHEA:21828 |
| assimilatory nitrate reductase | 1.7.99.- | RHEA:21068 (generic acceptor) — §14.2 |
| ferredoxin-nitrite reductase | 1.7.7.1 | RHEA:18041 |
| nitrite reductase (NADH) | 1.7.1.15 | RHEA:24628 |
| glutamine synthetase | 6.3.1.2 | RHEA:16169 |
| glutamate synthase (NADPH) | 1.4.1.13 | RHEA:15501 |
| glutamate dehydrogenase (NADP+) | 1.4.1.4 | RHEA:11612 |

---

## 14. Open decisions for the maintainer

### 14.1 What `mode` does assimilatory nitrate reduction take?

`mode` admits `anabolic`, `catabolic`, `transport`, `interconversion`. Nitrate →
ammonium is a reductive assimilation of an inorganic nutrient: it consumes
reducing power rather than yielding it, produces no carbon, and exists to feed
biosynthesis.

**Recommended: `anabolic`**, on the `SULFIDE` precedent — gifter already treats
assimilable inorganic sulfur as an input to anabolic GIFTs — and because the
`gift_profile` consequence is correct: an anabolic GIFT whose output anchor
carries `biomass_essential = yes` becomes an auxotrophy indicator, which is
exactly what a genome unable to reduce nitrate and lacking other nitrogen
sources is.

The alternative, a fifth `assimilatory` mode, is deferred. Adding a mode changes
the acyclicity contract and the compartment validation, and one GIFT is not
enough to justify it. Revisit if sulfate assimilation is curated, since that
layer would face the identical question.

### 14.2 Is a generic-acceptor Rhea reaction acceptable here?

`RHEA:21068` is `nitrite + A + H2O = nitrate + AH2` — written on a generic
acceptor, because the assimilatory nitrate reductase EC was deleted and its
replacement is `1.7.99.-`. `SOURCES.md` records that gifter previously
*avoided* a generic-acceptor reaction (`RHEA:18073`) in favour of the
chemically specific quinone form, on the grounds that the corresponding
ortholog is quinone-dependent.

Here the situation differs: NasA/NasC is genuinely NAD(P)H-linked through NasB,
but Rhea offers no NAD(P)H-specific master for it, and the ferredoxin form
(`RHEA:21828`) covers only NarB. Options are to use `RHEA:21068` for the
NasA/NasC route and record the imprecision, or to curate only the
ferredoxin route and lose 2 800 genomes. **Recommended: use `RHEA:21068`, and
state in the route description that the acceptor is unspecified in the
reaction record while the marker is specific to the assimilatory enzyme.**

### 14.3 Which compartments are split?

Two of the layer's substrates have specific, complete ABC importers and would
license a compartment split under the polysaccharide layer's rule:

- **Taurine**: TauABC (K15551 + K10831 + K15552), 1462 genomes. **Recommended:
  split**, and curate `taurine_uptake_abc`. The resulting
  `gift_profile.resource_strategy = uptake` is a real distinction, since
  taurine arrives from host bile-acid deconjugation performed by other
  organisms.
- **Urea**: UrtABCDE (K11959–K11963), 2540 genomes, plus the Utp channel
  (K08717, 957) and the acid-activated UreI channel (K03191, 134).
  **Recommended: do not split.** Three unrelated transport mechanisms, of which
  the two channels are passive, and urea also arises intracellularly from
  allantoin and creatinine degradation. A cytoplasmic/extracellular split would
  break the intracellular chain at exactly the point where composition is the
  layer's main result.
- **Nitrate**: NrtABCD is specific (1582) but NarK/NRT2 (K02575, 4298) is
  shared with nitrite and with respiratory contexts. **Recommended: do not
  split**, and record that the consequence is no `uptake` strategy for
  `nitrate_assimilation`.

### 14.4 Should `ACETYL_PHOSPHATE` become an anchor?

Xsc releases acetyl phosphate, which `acetate_interconversion` already carries
as an internal intermediate. Declaring it would connect the anaerobic taurine
route to acetate formation and would be biologically true. It would also
promote an intermediate of an existing GIFT to a boundary, which is the pattern
invariant 2 exists to restrain, and it would create a second high-degree hub.
**Recommended: leave it internal for now**, and record the missing edge.

### 14.5 Is `ammonium_assimilation` in scope?

The GS–GOGAT and GDH routes give `AMMONIUM` a consumer and close the layer's
graph. GS + GOGAT completes in 6085 genomes, GDH in 6775, either in **9482** —
93% of bacteria, which is uninformative as a positive call. Its **negative**
call, the 669 genomes with neither, is informative: they are overwhelmingly
reduced-genome symbionts dependent on host amino acids.

Arguments for: without it, every nitrogen GIFT is graph-terminal and
`network_position` reports `terminal` for capabilities that are biologically
central. Arguments against: it belongs to an amino acid layer, not a nitrogen
catabolism one, and it introduces `GLUTAMATE`, which is the entry point to a
much larger curation surface.

**Recommended: include it**, scoped narrowly to ammonium assimilation and not
to glutamate metabolism generally, precisely so that the anchor is introduced
under a rule rather than under pressure later.

### 14.6 What role does a released, unused product take?

`carnitine_degradation_trimethylamine` produces a compound the organism does not
use and the host converts to TMAO. `fermentative_end_product` is the closest
existing `physiological_role` and is a poor fit — trimethylamine is not a
fermentation product. The choice is to broaden that role's definition, as it
was already broadened once when the organic acid layer added lactate and
ethanol, or to add a `released_bioactive_product` role. **Recommended: add the
new role**, since the distinction it draws — a product that matters to the host
rather than to the producer — is one users will filter on.

---

## 15. If accepted, the work is

1. Record the nitrogen-anchor rule (§7) and the electron-acceptor rule (§8) in
   `inst/doc/architecture.md`, and the refusals of §11 in
   `database_changes.tsv` linked to the GIFTs they bound.
2. Add 6 facet terms (§10), 15 anchors and their anchor facets (§9.3).
3. Add 11 GIFTs, ~18 routes, ~35 reactions, ~40 enzyme systems and the
   marker rows for ~55 KOs.
4. Amend `gift_anchors.tsv` for `glcnac_degradation` and `neuac_degradation`
   (§6.8) — two rows, no call change.
5. Add tests: the OR across nitrate's 2 × 3 route alternatives; the AND across
   UreABC with the fused `ureAB` alternative; the two carnitine routes and
   their near-disjoint carriage; **negative tests that a primary-amine oxidase
   marker does not fire a phenylethylamine trait and that K01485 does not fire
   creatinine degradation**; and a composition test that
   `urate_degradation → allantoin_degradation → urea_hydrolysis →
   ammonium_assimilation` is a path and not a cycle.
6. Correct `SOURCES.md`: MetaCyc is reachable through
   `websvc.biocyc.org/getxml` and the recorded reason for not citing it is now
   wrong. Replace it with the structural reason (§4), which does not depend on
   access.
7. Bump the database version and record the release.

The natural companion layer, not proposed here because it is outside the
request: **choline TMA-lyase CutC/CutD** (212 genomes, two specific markers,
one reaction). It shares `TRIMETHYLAMINE` with the carnitine GIFT and is the
capability the TMAO literature is actually about.

---

## 16. Provenance of this assessment

- KEGG orthology and `link/genes/ko:` gene-to-organism sets, retrieved
  2026-08-18 from `https://rest.kegg.jp/`. Prevalence is the intersection of
  those sets with the 10 151 bacterial organism codes extracted from BRITE
  `br08601`, computed locally; KEGG module completeness was not used.
- Rhea release 141, `rhea2ec.tsv` and the Rhea REST API, 2026-08-18.
- ChEBI release 253 for anchor identity.
- MetaCyc `websvc.biocyc.org/getxml`, tested 2026-08-18: reachable for records
  addressed by ID, not for search. No MetaCyc record is cited by this proposal.
- distillR 1.x `GIFT_db` as installed, read 2026-08-18, used only as a coverage
  checklist and, in §12, as the object of assessment.
- gifter database version 2026.16.1, schema 6, and the validation logic in
  `R/database-build.R`.

Every prevalence figure in this document was computed rather than recalled. No
figure is carried over from a published source, and none should be quoted
without the KEGG release date above.

---

## 17. Implementation record, 2026-08-18

Implemented as database version **2026.18.1**, schema 6 unchanged. Fourteen
GIFTs, 16 anchors, 7 facet terms, 26 routes, 37 reactions, 39 enzyme systems,
55 components and 57 new markers; two existing GIFTs amended. No R change. The
full suite passes at 2750 assertions, of which 101 are the new
`tests/testthat/test-nitrogen.R`.

### 17.1 The open questions, as resolved

| § | Question | Resolution |
|---|---|---|
| 14.1 | Mode for assimilatory nitrate reduction | `anabolic`, on the `SULFIDE` precedent. No fifth mode. |
| 14.2 | Generic-acceptor Rhea reaction | `RHEA:21068` used, with the imprecision stated in the reaction description. The marker remains specific to the assimilatory enzyme. |
| 14.3 | Compartment splits | Taurine split, and `taurine_uptake_abc` curated. Urea and nitrate left unresolved, as recommended. |
| 14.4 | `ACETYL_PHOSPHATE` as an anchor | Left internal. The missing edge to `acetate_interconversion` stands. |
| 14.5 | `ammonium_assimilation` in scope | Included, scoped to ammonium assimilation only. `GLUTAMATE` added. |
| 14.6 | Role for a released, unused product | New `released_bioactive_product` role added rather than broadening `fermentative_end_product`. |

### 17.2 Where implementation departed from the proposal

Three departures, all found by checking reactions against Rhea before curating
rather than after.

**The carnitine dehydrogenase route makes betaine, not trimethylamine — so it
is a second GIFT.** §6.5 proposed `carnitine_degradation_trimethylamine` with
two routes, CntAB and CdhA/CdhC, on the strength of KEGG naming CdhC a
*3-dehydrocarnitine:acetyl-CoA trimethylamine transferase*. The reactions say
otherwise: `RHEA:47044` yields `N,N,N-trimethylglycyl-CoA + acetoacetate` and
`RHEA:45716` hydrolyses that thioester to **glycine betaine**. No free amine is
released anywhere in the route. Implemented as two GIFTs:
`carnitine_degradation_trimethylamine` (CntAB only, **271** genomes) and
`carnitine_to_betaine` (**944**). The trimethylamine claim is therefore made
for 271 genomes rather than the 972 the proposal implied, which is a narrowing,
and carnitine still reaches glycine — through `BETAINE` into
`betaine_demethylation` and on to `sarcosine_demethylation`. The composition
argument survives; only the product claim changed.

**The anaerobic taurine GIFT declares no ammonium.** §6.7 proposed `TAURINE` →
`SULFITE` + `AMMONIUM`. But the two routes dispose of the nitrogen differently:
Tpa *transaminates* (`RHEA:10420`, nitrogen leaves as L-alanine) while TauXY
*deaminates* (`RHEA:18709`, nitrogen leaves as ammonium). A GIFT anchor must
hold for every route, so `AMMONIUM` is not declared and the capability makes no
nitrogen claim at all. Both routes still converge on sulfite through Xsc, so
`SULFITE` is unaffected. The layer consequently has five ammonium sources, not
six.

**`allantoin_degradation` declares no ammonium either, for the same reason.**
The deiminase route releases two ammonium and the allantoicase route none. The
declared outputs are `GLYOXYLATE` and `UREA`, which both routes produce, and
the nitrogen reaches ammonium one step later through `urea_hydrolysis`.

### 17.3 What the graph does

Every composition edge is `exact`; none required the compartment-inexact path.

```text
URATE ─▶ ALLANTOIN ─▶ UREA ─┐
CREATININE ─▶ SARCOSINE ─▶ GLYCINE
CREATININE ─▶ UREA ─────────┤
CARNITINE ─▶ BETAINE ─▶ SARCOSINE
                            ├─▶ AMMONIUM ─▶ GLUTAMATE
METHYLAMINE ────────────────┤
GLCNAC / NEUAC ─────────────┤
NITRATE ────────────────────┘
TAURINE(out) ─▶ TAURINE(in) ─▶ SULFITE
CARNITINE ─▶ TRIMETHYLAMINE
```

`AMMONIUM` has five incoming GIFTs and one outgoing, making it the most
connected anchor in the database. `gift_profile` confirms the two intended
derivations: `taurine_uptake_abc` is the layer's only `uptake` resource
strategy, and `nitrate_assimilation` and `ammonium_assimilation` are the only
new `auxotrophy_indicator` GIFTs, both of them because `AMMONIUM` and
`GLUTAMATE` carry `biomass_essential = yes` and neither GIFT had to be told
about nitrogen. No directed mode cycles: nothing in gifter
produces urate, allantoin, betaine, creatinine, carnitine, taurine or nitrate,
so every catabolic chain has its source outside the model, and the one
catabolic-to-anabolic edge is the case the acyclicity rule expects.

### 17.4 Tests, and the four that had to move

`tests/testthat/test-nitrogen.R` asserts the nitrogen-anchor rule against the
compiled database (the three rejected reactions' GIFTs must not gain the
anchor), the electron-acceptor scope (eleven respiratory accessions match no
marker and complete no GIFT), urease AND-across-components with the fused
`ureAB` marker satisfying two of them, the 2 × 2 nitrate route alternatives,
sarcosine curated once and reached from both upstream capabilities, the
taurine compartment gate, and the negative cases that a primary-amine oxidase
does not fire a phenylethylamine trait and `K01470` alone does not fire
creatinine degradation.

Four existing inventory assertions moved, none of them protecting an invariant
this layer breaks:

- `test-compartment.R` — `TAURINE` joins `ARABINOSE` and `XYLOSE` as a
  compartment-split molecule.
- `test-pathway-links.R` — the two carnitine GIFTs and `taurine_uptake_abc`
  join the list of GIFTs with no external pathway link. KEGG assigns the
  carnitine orthology groups to no metabolic map at all.
- `test-uptake.R` — the dual-specificity importer test filtered on
  `mode == "transport"` and so swept in the new taurine importer. Rescoped to
  the two pentose GIFTs the claim is about.
- `test-sugar-degradation.R` — the amino sugar GIFTs now have an outgoing
  `AMMONIUM` edge into `ammonium_assimilation`, which is anabolic, and the test
  asserted no anabolic GIFT downstream of a sugar capability. The invariant it
  actually protects is that no *carbon* anchor reaches a biosynthesis GIFT, and
  it now asserts that, plus the identity of the nitrogen edge.

### 17.5 What was not done

The refusals of §11 stand and are recorded in `database_changes.tsv` so the
atlas surfaces them: phenylethylamine, hypotaurine, nitrate respiration,
denitrification, DNRA, taurine-to-hydrogen-sulfide, the urea amidolyase route
and the creatinine deiminase route. The deferrals also stand — betaine
reductase (37 genomes), the N-methylglutamate route to methylamine (46),
γ-butyrobetaine formation by CaiTABCDE (219), and nitrate transport.

Choline TMA-lyase CutC/CutD, recommended in §15 as the natural companion, was
**not** curated: choline is outside the requested scope. It remains the
best-evidenced trimethylamine capability in KEGG at 212 genomes and would share
the `TRIMETHYLAMINE` anchor this layer added.
