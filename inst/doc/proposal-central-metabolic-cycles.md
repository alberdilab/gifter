# Design proposal: circular central metabolism and higher-order metabolic topology

Status: **accepted and implemented in database version 2026.16.1, then extended
with the isocitrate re-cut and glyoxylate cycle in 2026.20.1 (schema 6).**
Evidence test and graph experiments performed 2026-08-18 against database
version 2026.15.1. Section 16's recommendation — option 1, atomic segment GIFTs
plus derived cycle detection — was the one taken. The implementation record,
including where it departed from this proposal, is section 18.

Scope: decide how giftr should represent circular central metabolism, using the
citric acid cycle as the first worked example, without turning every reaction
into a GIFT and without curating a monolithic "TCA cycle" GIFT. The design must
solve a general topology problem, not a TCA-specific one.

This proposal **partly reverses** a recorded finding.
[`proposal-organic-acid-formation.md`](proposal-organic-acid-formation.md) §7
concluded that "the citric acid cycle cannot be anchored". That conclusion was
correct for the question it asked and is wrong for the question asked here, and
§2.3 below states exactly where the two questions part company. Sections 6.4,
6.5 and 6.6 of that proposal — the refusals of `succinate_formation`,
`fumarate_formation` and `citrate_formation` — are **not** reversed and are
reinforced by new evidence in §6.6 here.

---

## 1. Recommendation in one page

1. **Curate four atomic GIFTs, not six and not one**, named for their boundaries
   in the house style of `pyruvate_to_acetyl_coa`: `acetyl_coa_to_oxoglutarate`,
   `oxoglutarate_to_succinate`, `succinate_fumarate_interconversion`,
   `fumarate_oxaloacetate_interconversion`. §5.
2. **Two of the four are `interconversion`, and this is forced by evidence, not
   chosen for convenience.** `K00239` is named by KEGG `sdhA, frdA`: one
   orthology group for succinate dehydrogenase and fumarate reductase. 8047
   organisms carry it; the dedicated `frdAB` split exists in 1059, almost all
   Enterobacteriaceae. giftr may not claim a direction its markers cannot
   distinguish (invariant 16), so `SUCCINATE > FUMARATE` and
   `FUMARATE > SUCCINATE` become one reversible boundary, not two GIFTs. §6.4.
3. **Add four anchors and no others**: `OXALOACETATE`, `OXOGLUTARATE`,
   `SUCCINATE`, `FUMARATE`. `MALATE` and `CITRATE` already exist. §6.
4. **Citrate stays internal, and the reason is new and empirical.** Exposing
   `CITRATE` as an output anchor closes a *second, unrelated* cycle against
   already-curated content — `citrate_fermentation -> pyruvate_to_acetyl_coa ->
   citrate_synthesis -> citrate_fermentation` — which giftr's own edge
   derivation reports. This is a stronger argument than the near-universality
   argument previously recorded. §6.6.
5. **The citrate synthase step cannot be evidenced cleanly, and this is the
   layer's biggest evidential risk.** KEGG assigns the genuine citrate synthases
   of *Staphylococcus aureus* (`sau:SA1518`, `citZ`) and *Bacteroides
   thetaiotaomicron* (`bth:BT_2070`) to **`K01659`, which KEGG names `prpC;
   2-methylcitrate synthase`**. Requiring `K01647` alone calls both negative;
   accepting `K01659` also accepts 1429 organisms whose only member of that
   group is a real 2-methylcitrate synthase, including *Streptococcus* (64) and
   *Listeria* (48). Recommendation: accept `K01659` as an alternative enzyme
   system with `confidence = ambiguous`, and record the trigger for revisiting.
   §6.2.
6. **Do not add `metabolic_circuit` and `circuit_gift` tables.** Under the
   recommended curation the oxidative citric acid cycle is **already an
   elementary cycle of `gift_graph()`**. Enumerating the elementary cycles of
   the full recommended graph returns exactly three, and two of them are the
   oxidative cycle and the glyoxylate bypass cycle. Nothing needed curating for
   that to be true. §8.
7. **Also do not reuse the word "circuit".** `gift_circuit` is already the
   regulatory model's implementation table. A metabolic ring is a **cycle** or a
   **closure** in this document, never a circuit. §8.1.
8. **Change the within-mode acyclicity rule, but not to "allow declared
   circuits".** The rule is already inconsistent with `mode = interconversion`,
   independently of any TCA content: two interconversion GIFTs that share one
   anchor produce a two-node cycle *by construction*, because the mode declares
   every anchor in both roles. This was verified with two synthetic GIFTs and no
   citric acid chemistry at all. The correct rule is:

   > Within-mode acyclicity applies to the **directed** modes — `anabolic`,
   > `catabolic`, `transport`. `interconversion` is exempt, because a cycle
   > there is a syntactic consequence of the mode rather than evidence of a bad
   > boundary.

   This is a five-line change in one validator loop, no schema migration, and it
   is a bug fix that should land whether or not any TCA content is curated. §9.
9. **Under the recommended curation, no directed mode acquires a cycle.** The
   acyclicity heuristic keeps doing its job everywhere it is meaningful; the
   only reported cycle is the reversible succinate–fumarate–oxaloacetate arm,
   which is exempt for the reason above. Verified, not predicted. §9.3.
10. **Name the higher-order object with a facet, not a table.** If curators want
    to say "this GIFT belongs to the oxidative citric acid cycle", that is
    *classification*, and giftr's mechanism for classification is
    `facet_terms.tsv` + `gift_facets.tsv`, which is an open vocabulary needing no
    migration. Structure comes from the graph; naming comes from a facet. §8.4.
11. **Add one general accessor, `gift_cycles()`**, that enumerates elementary
    cycles of the composition graph and reports which of a genome's cycles are
    closed and where a broken one is broken. It contains no TCA-specific logic;
    it is a graph function that would find the Calvin cycle or the urea cycle on
    the day those are curated. §11.3.
12. **Boolean calls do not change.** Cycle closure is derived *after*
    `evaluate_gifts()` from its output. No atomic GIFT's `complete` value
    depends on whether a cycle closes. §12.1.

The recommendation is **option 1 as the user framed it — atomic GIFTs plus
derived cycle detection — with one curated addition that is a facet value rather
than a table.** §16 argues it against the alternatives.

---

## 2. Problem statement

### 2.1 What a user actually wants to know

Two questions look the same and are not:

```text
Q1  Does this genome have a citric acid cycle?
Q2  Which parts of citric acid cycle chemistry does this genome encode,
    and do they close?
```

Q1 has a yes/no answer for 62.9% of the 11 783 KEGG organisms in this analysis
and is uninformative for the rest, because "no" covers *Helicobacter pylori*, which
encodes a complete oxidative branch to 2-oxoglutarate, and *Erysipelatoclostridium*,
which encodes none of it. Q2 separates those two, and Q2 is the question
comparative genomics asks.

giftr cannot answer Q2 today. It has no anchor for any citric acid cycle
metabolite except `MALATE` and `CITRATE`, and both are declared input-only.

### 2.2 The two failure modes to avoid

```text
     one GIFT                                   one GIFT per reaction
     "tca_cycle"                                citrate_synthase_gift
          |                                     aconitase_gift
   complete or not                              isocitrate_dh_gift
          |                                     ...
   62.9% of genomes say yes;                    a reaction catalogue with
   H. pylori says no for the                    a GIFT-shaped wrapper; the
   same reason M. genitalium                    ontology stops being about
   says no                                      capabilities
```

Sections 3 and 4 argue each of these out properly.

### 2.3 Why the previous refusal does not bind this proposal

`proposal-organic-acid-formation.md` §2 drew this cut:

> a metabolite is a candidate GIFT product only if a genome can be said to
> release it, and only if a marker exists whose direction matches that release.

That is the right test for **`succinate_formation`**, a claim about what a
genome excretes. It is the wrong test for **`succinate_oxidation`**, a claim
about what chemistry a genome encodes between two boundaries. The distinction is
not a technicality; it is the difference between a product claim and a
capability claim, and giftr's other 68 GIFTs are capability claims.

`purine_core_biosynthesis` is the proof. It is complete in most genomes on
Earth, it releases nothing, IMP is consumed by the same cell that made it, and
nobody has proposed deleting it. Its anchors are boundaries of a capability, not
predictions of excretion. The same standard applied to citric acid cycle
segments gives a different answer than the standard applied to fermentation end
products, and it should.

What survives from the earlier assessment, unchanged:

| Earlier finding | Status here |
|---|---|
| `succinate_formation` refused — `frdABCD` calls fumarate respirers positive and *Bacteroides* negative | **Upheld.** §6.4 uses the same numbers to force `interconversion` rather than to curate a directional trait |
| `fumarate_formation` refused — adenylosuccinate lyase makes fumarate in 93.8% of genomes | **Upheld.** §6.5 shows declaring the `FUMARATE` anchor still creates no purine→pyrimidine edge |
| `citrate_formation` refused | **Upheld and strengthened** by a graph result the earlier assessment did not have. §6.6 |
| "The citric acid cycle cannot be anchored" | **Reversed**, and §9 explains that the obstacle was a validator rule that is independently wrong |

---

## 3. Why a monolithic TCA GIFT is insufficient

Curated as one GIFT with routes spanning acetyl-CoA back to oxaloacetate, the
trait is complete in **7415 of 11 783 organisms (62.9%)** and its negative class
is uninterpretable. The four segments defined in §5 were evaluated
independently across KEGG. All **16 of the 16 possible configurations are
occupied**, and each is populated by taxa that belong together:

| Config | n | % | Leading genera |
|---|---:|---:|---|
| `ULSF` | 7415 | 62.9% | Streptomyces 246, Pseudomonas 243, Corynebacterium 169, Bacillus 143, Mycobacterium 103 |
| `----` | 1529 | 13.0% | Streptococcus 187, Listeria 48, Clostridium 46, Lactobacillus 40, Enterococcus 34 |
| `-LSF` | 983 | 8.3% | Staphylococcus 109, Chlamydia 90, Paenibacillus 74, Bacillus 29, Geobacillus 20 |
| `U-SF` | 313 | 2.7% | Acetobacter 20, Moraxella 15, Neisseria 15, Actinomyces 5, Methanosarcina 5 |
| `--SF` | 272 | 2.3% | Bacteroides 15, Paenibacillus 10, Synechocystis 10, Alistipes 9, Porphyromonas 9 |
| `U--F` | 195 | 1.7% | **Helicobacter 80**, Methanosarcina 21, Campylobacter 14, Arcobacter 10, Gluconobacter 7 |
| `--S-` | 179 | 1.5% | Nostoc 17, Dolichospermum 7, Gardnerella 5, Synechococcus 5, Anabaena 4 |
| `U---` | 168 | 1.4% | Clostridium 27, Caldicellulosiruptor 11, Pseudodesulfovibrio 11, Zymomonas 8 |
| `UL-F` | 137 | 1.2% | Campylobacter 51, Sulfurospirillum 8, Malaciobacter 5, Halarcobacter 3 |
| `-L-F` | 118 | 1.0% | Chlamydia 13, Methanococcus 12, Methanobacterium 11, Methanothermobacter 9 |
| `---F` | 100 | 0.8% | Campylobacter 17, Dehalococcoides 12, Prochlorococcus 11, Synechococcus 7 |
| `-L--` | 100 | 0.8% | Fervidobacterium 7, Methanobrevibacter 5, Dehalobacter 4, Thermosipho 4 |
| `U-S-` | 95 | 0.8% | **Bifidobacterium 59**, Corynebacterium 5, Clostridium 3 |
| `ULS-` | 86 | 0.7% | Ferroplasma 3, Halorhabdus 3, Sulfuriferula 3, Thiorhodovibrio 3 |
| `-LS-` | 77 | 0.7% | Chlamydia 12, Nitrosopumilus 8, Desulfosporosinus 3, Staphylococcus 3 |
| `UL--` | 16 | 0.1% | Oxalobacter 3, Syntrophus 2, Desulfomicrobium 1, Desulforapulum 1 |

`U` = `acetyl_coa_to_oxoglutarate`, `L` = `oxoglutarate_to_succinate`,
`S` = `succinate_fumarate_interconversion`, `F` =
`fumarate_oxaloacetate_interconversion`. Universe: 11 783 KEGG organisms,
2026-08-18.

A monolithic GIFT collapses rows 2–16 — **4368 genomes, 37.1%** — into one
undifferentiated "incomplete". The `U--F` row alone is the textbook branched
*Helicobacter* architecture, and it is 80 *Helicobacter* genomes reported as
identical to *Mycoplasma genitalium*.

A "percentage complete" summary is no better. It would put *H. pylori* and a
genome missing a single dehydrogenase subunit at similar percentages while
saying nothing about which chemistry either encodes, and giftr's evaluation
contract already refuses percentage completeness for exactly this reason.

---

## 4. Why one GIFT per reaction is also undesirable

The citric acid cycle has eight to ten reactions depending on how the aconitase
and dehydrogenase steps are counted. As GIFTs they would fail four tests at
once.

**They would not be capabilities.** `aconitase_gift` claims that a genome can
isomerise citrate to isocitrate. No comparative-genomic question is phrased that
way, and no ecological, evolutionary or host-associated comparison consumes it.
The architecture guide's granularity rule — do not split a pathway into
arbitrary tiny reactions simply because the schema permits it — is written
against exactly this.

**They would erase the OR layer that carries the biology.** The
2-oxoglutarate-to-succinate span has three genuinely alternative
implementations, and which one a genome uses is a real trait:

| Implementation | Markers | Organisms | % |
|---|---|---:|---:|
| 2-oxoglutarate dehydrogenase complex | `K00164`+`K00658`+`K00382` | 6902 | 58.6% |
| 2-oxoglutarate:ferredoxin oxidoreductase | `K00174`+`K00175` | 3288 | 27.9% |
| Kgd bypass via succinate semialdehyde | `K01616` + `K00135`/`K17761`/`K08324`/`K00139` | 1420 | 12.1% |

As one GIFT with three routes this is a textbook OR-over-routes case and
`get_gift_routes()` reports which one a genome satisfies. As per-reaction GIFTs
the three become unrelated traits and the fact that they are alternatives is
lost. *Mycobacterium tuberculosis* and *Corynebacterium glutamicum* are both
negative for the dehydrogenase complex and positive through Kgd — a well-known
actinobacterial substitution that the route layer states and a reaction
catalogue cannot.

**They would multiply anchors.** Every reaction GIFT needs an input and an
output anchor, so `ISOCITRATE`, `CIS_ACONITATE`, `SUCCINYL_COA` and
`SUCCINATE_SEMIALDEHYDE` would all be promoted. Invariant 3 asks the opposite.

**They would fragment the cycle in the graph.** Ten nodes with nine edges
between them is not more informative than four nodes with four edges; it is the
same information with the biology diluted.

Single-reaction GIFTs are not forbidden — `malolactic_fermentation` and
`lactate_racemisation` are both one reaction, and both are capabilities. The
objection is to one-reaction GIFTs that are *only* reactions.

---

## 5. Boundary-selection principle, and the proposed decomposition

### 5.1 The rule this proposal tests

The request offered:

> Expose a metabolite as a GIFT boundary when hiding that boundary would erase a
> biologically useful distinction between genomes.

That rule is good and incomplete. Taken alone it says nothing about *which*
distinction is worth keeping, so it would license promoting any metabolite whose
enzyme is sometimes missing. Isocitrate is the case that shows the gap: it sits
between two steps that are almost never separated — only 204 genomes carry a
citrate synthase without an aconitase — so exposing it would buy a distinction
almost no genome makes, while costing an anchor. The rule needs a second clause
that giftr's existing content already implies:

> **Expose a metabolite as a boundary when (a) hiding it would erase a
> distinction between genomes that some other capability also cares about, and
> (b) the chemistry on each side of the cut can be evidenced separately.**

Clause (a) is what makes a boundary *compositional* rather than merely variable:
a boundary earns its place by being a place where something else can attach.
Clause (b) is invariant 16 arriving at the boundary layer — a cut that no marker
set can evidence on both sides is a cut that produces two GIFTs with the same
call.

Against that rule:

| Metabolite | (a) other capabilities attach? | (b) separately evidenced? | Verdict |
|---|---|---|---|
| oxaloacetate | yes — anaplerosis, gluconeogenesis, aspartate family, citrate fermentation | yes | **anchor** |
| 2-oxoglutarate | yes — glutamate/glutamine, nitrogen assimilation, lysine, arginine | yes | **anchor** |
| succinate | yes — propionate (Wood–Werkman), heme, succinate release | yes | **anchor** |
| fumarate | yes — fumarate respiration, aspartate deamination, purine chemistry | yes | **anchor** |
| malate | already an anchor — malolactic fermentation, malic enzyme, glyoxylate shunt | yes | **already an anchor**; see §6.7 |
| citrate | already an anchor as an input — citrate fermentation, citrate uptake | as an *output*, no: §6.2 and §6.6 | **stays input-only** |
| isocitrate | glyoxylate shunt only | aconitase and ICDH separable | **internal**, revisit with the shunt (§13.2) |
| cis-aconitate | nothing | no | internal |
| succinyl-CoA | heme, lysine, methionine in some clades | poorly | internal; §15 Q4 |

### 5.2 The proposed decomposition

```text
                    PYRUVATE ──(pyruvate_to_acetyl_coa, curated)──> ACETYL_COA
                                                                        │
   ┌────────────────────────────────────────────────────────────────────┤
   │                                                                    │
   │  OXALOACETATE ─────────────────────────┐                           │
   │                                        ▼                           ▼
   │                        acetyl_coa_to_oxoglutarate  ◄───────────────┘
   │                        catabolic · [citrate] · [isocitrate]
   │                                        │
   │                                        ▼
   │                                  OXOGLUTARATE ──────> glutamate family
   │                                        │
   │                          oxoglutarate_to_succinate
   │                          catabolic · [succinyl-CoA]
   │                                        │
   │                                        ▼
   │                                    SUCCINATE ────────> propionate, heme
   │                                        ▲
   │                   succinate_fumarate_interconversion
   │                   interconversion · SDH / FRD
   │                                        ▼
   │                                     FUMARATE ────────> fumarate respiration
   │                                        ▲
   │                fumarate_oxaloacetate_interconversion
   │                interconversion · fumarase + MDH · [malate]
   │                                        ▼
   └────────────────────────────────── OXALOACETATE ──────> gluconeogenesis,
                                                            aspartate family
```

Square brackets mark internal intermediates that are **not** anchors.

| GIFT | mode | input anchors | output anchors |
|---|---|---|---|
| `acetyl_coa_to_oxoglutarate` | `catabolic` | `ACETYL_COA`, `OXALOACETATE` | `OXOGLUTARATE` |
| `oxoglutarate_to_succinate` | `catabolic` | `OXOGLUTARATE` | `SUCCINATE` |
| `succinate_fumarate_interconversion` | `interconversion` | `SUCCINATE`, `FUMARATE` | `SUCCINATE`, `FUMARATE` |
| `fumarate_oxaloacetate_interconversion` | `interconversion` | `FUMARATE`, `OXALOACETATE` | `FUMARATE`, `OXALOACETATE` |

### 5.3 On the provisional names

The request's names — `tca_oxidative_upper`, `tca_oxidative_lower` — are
positional descriptions of a pathway diagram, and invariant 1 says a GIFT is not
a pathway record. The database's own convention names a metabolic GIFT for its
boundaries (`pyruvate_to_acetyl_coa`) or for its chemistry
(`acetate_interconversion`, `malolactic_fermentation`). `acetyl_coa_to_oxoglutarate`
survives a curator later deciding that the same span is not "upper TCA" in an
organism that runs it as a horseshoe; `tca_oxidative_upper` does not.

`succinate_oxidation` and `fumarate_to_oxaloacetate` are renamed for a stronger
reason: they name a direction the evidence cannot support. §6.4.

---

## 6. Biological justification, boundary by boundary

Every figure in this section was retrieved from KEGG and Rhea on 2026-08-18
against a universe of **11 783 organisms**. Provenance is §17.

### 6.1 Reaction identity, verified

| Step | Rhea master | Equation |
|---|---|---|
| Citrate synthase | `RHEA:16845` | oxaloacetate + acetyl-CoA + H2O = citrate + CoA + H(+) |
| Aconitase, overall | `RHEA:10336` | citrate = D-threo-isocitrate |
| Isocitrate dehydrogenase, NADP | `RHEA:19629` | D-threo-isocitrate + NADP(+) = 2-oxoglutarate + CO2 + NADPH |
| Isocitrate dehydrogenase, NAD | `RHEA:23632` | D-threo-isocitrate + NAD(+) = 2-oxoglutarate + CO2 + NADH |
| 2-oxoglutarate dehydrogenase, overall | `RHEA:27786` | 2-oxoglutarate + NAD(+) + CoA = succinyl-CoA + CO2 + NADH |
| 2-oxoglutarate:ferredoxin oxidoreductase | `RHEA:17297` | 2 oxidized ferredoxin + 2-oxoglutarate + CoA = succinyl-CoA + 2 reduced ferredoxin + CO2 + H(+) |
| 2-oxoglutarate decarboxylase (Kgd) | `RHEA:10524` | 2-oxoglutarate + H(+) = succinate semialdehyde + CO2 |
| Succinate-semialdehyde dehydrogenase | `RHEA:13217` / `RHEA:13213` | succinate semialdehyde + NAD(P)(+) + H2O = succinate + NAD(P)H + 2 H(+) |
| Succinyl-CoA synthetase, ADP-forming | `RHEA:17661` | succinate + ATP + CoA = succinyl-CoA + ADP + phosphate |
| Succinyl-CoA synthetase, GDP-forming | `RHEA:22120` | GTP + succinate + CoA = succinyl-CoA + GDP + phosphate |
| Succinate dehydrogenase / fumarate reductase, ubiquinone | `RHEA:13713` | a ubiquinone + succinate = a ubiquinol + fumarate |
| … menaquinone | `RHEA:27834` | a menaquinone + succinate = a menaquinol + fumarate |
| Fumarase | `RHEA:12460` | (S)-malate = fumarate + H2O |
| Malate dehydrogenase, NAD | `RHEA:21432` | (S)-malate + NAD(+) = oxaloacetate + NADH + H(+) |
| Malate:quinone oxidoreductase | `RHEA:30095` / `RHEA:46012` | a quinone + (S)-malate = a quinol + oxaloacetate |

Two of these carry design lessons.

**`RHEA:16845` is returned by both EC 2.3.3.1 and EC 2.3.3.3.** The si- and
Re-citrate synthases are different enzymes with the same chemistry, which is
exactly the reaction/system split giftr's layers exist for: one reaction, two
enzyme systems.

**Succinate dehydrogenase and fumarate reductase share their Rhea masters.**
Rhea writes `RHEA:13713` and `RHEA:27834` in the succinate-oxidising direction,
and the same complexes catalyse the reduction. Reaction identity therefore
carries no direction here, and `route_reaction.orientation` is the only place a
direction could be stated — which is exactly the mechanism §6.4 shows the
markers cannot license.

### 6.2 `acetyl_coa_to_oxoglutarate` — sound boundary, contested first marker

**The claim.** The genome encodes the oxidative condensation of acetyl-CoA with
oxaloacetate and its oxidative decarboxylation to 2-oxoglutarate.

**Why the boundary is right.** 2-oxoglutarate is the largest carbon–nitrogen
junction in bacterial metabolism: glutamate dehydrogenase and glutamine
synthetase/GOGAT both consume it, and glutamate is the amino donor for most
transaminations. A genome that can make 2-oxoglutarate from acetyl-CoA and
oxaloacetate but cannot oxidise it further is a real and common physiology —
1.7% of KEGG genomes, led by 80 *Helicobacter* — and it is the biosynthetic
half of the branched TCA. Making 2-oxoglutarate a boundary is also what will let
the amino acid layer attach without re-cutting anything.

**Evidence, and the problem in it.**

| Component | Markers | Organisms | % |
|---|---|---:|---:|
| Citrate synthase, si | `K01647` | 8467 | 71.9% |
| Citrate synthase, Re | `K05942` | 295 | 2.5% |
| "2-methylcitrate synthase" | `K01659` | 4736 | 40.2% |
| Aconitase | `K01681` ∪ `K01682` ∪ `K27802` | 10031 | 85.1% |
| Isocitrate dehydrogenase | `K00031` ∪ `K00030` | 10305 | 87.5% |

Note `K27802` (`acnA`, aconitate hydratase A). KEGG split it out of `K01681`
recently; without it the aconitase set is 4565 organisms and both *B. subtilis*
and *M. tuberculosis* are wrongly called aconitase-negative. Any curation of
this layer must use all three groups.

**The citrate synthase problem.** KEGG assigns two unambiguous citrate synthases
to the group it names `prpC; 2-methylcitrate synthase`:

```text
sau:SA1518   citZ; citrate synthase II            -> ko:K01659
bth:BT_2070  citrate synthase                     -> ko:K01659
bth:BT_2071  isocitrate dehydrogenase (NADP)      -> ko:K00031
bth:BT_2072  aconitate hydratase                  -> ko:K27802
```

The *Bacteroides thetaiotaomicron* case is decisive: `BT_2070`, `BT_2071` and
`BT_2072` are consecutive genes forming the oxidative branch, and only the
citrate synthase falls outside the canonical group.

| Setting | Complete for `acetyl_coa_to_oxoglutarate` | % | Consequence |
|---|---:|---:|---|
| `K01647` ∪ `K05942` only | 8425 | 71.5% | *S. aureus*, *B. thetaiotaomicron*, *B. fragilis*, *Synechocystis* all **false negative** |
| … ∪ `K01659` | 9717 | 82.5% | adds 1292 genomes with aconitase and ICDH whose only synthase is in the 2-methylcitrate group, including *Streptococcus* 64 and *Listeria* 48 — **false positives** |

Neither setting is right, which is the shape of the succinate failure recorded
in the earlier proposal, one step upstream. Three responses were considered:

1. *Refuse the GIFT.* Rejected: the aconitase and ICDH steps are clean, and the
   comparative signal in §3's table is real. Refusing would discard 15 usable
   configurations because one marker is untidy.
2. *Require `K01647` only.* Rejected: it makes the trait a proxy for
   Proteobacteria and calls the gut's dominant genus negative, which is the
   documented butyrate/succinate failure mode.
3. **Accept `K01659` as an alternative enzyme system with
   `confidence = ambiguous`.** Recommended. giftr already carries 165 markers at
   that confidence, `evaluate_gifts()` propagates the weakest confidence into
   `evidence_confidence`, and a curator or user can filter on it. The claim
   becomes "supported, on an orthology group that also contains
   2-methylcitrate synthases", which is true.

Response 3 has a cost that must be stated: **it over-broadens the GIFT for the
2-methylcitrate cycle's own organisms.** Invariant 16 warns that accepting an
over-broad marker damages the other traits it matches. giftr does not currently
curate a 2-methylcitrate/propionate-catabolism GIFT; on the day it does, `K01659`
must be re-examined for both, and the honest resolution may be to refuse it here
rather than to keep it. §15 Q1 records the trigger.

### 6.3 `oxoglutarate_to_succinate` — the cleanest of the four

**The claim.** The genome encodes the oxidative conversion of 2-oxoglutarate to
succinate by at least one of three known routes.

**Why the boundary is right.** Succinate is a boundary in four independent
senses: it is the substrate of the Wood–Werkman route to propionate, a precursor
of heme through succinyl-CoA, a genuine fermentation end product in *Bacteroides*,
*Prevotella* and *Actinobacillus*, and the reduced partner of the
succinate/fumarate redox couple that separates respiratory architectures.

**Routes.** The three implementations in §4 are curated as three routes of one
GIFT. Two carry an oxygen distinction worth recording per route: the
dehydrogenase complex is `independent`, the ferredoxin oxidoreductase is
`anaerobic`.

**The directionality caveat, recorded not resolved.** The dehydrogenase and Kgd
routes are irreversible — both release CO2 — so `catabolic` is a defensible
claim for them. The ferredoxin oxidoreductase route is the reductive-TCA enzyme
and is genuinely reversible, and *Bacteroides* is the organism that runs it. A
GIFT carries one `mode` for all its routes, so declaring `catabolic` slightly
over-claims for that one route. Two ways out were considered and neither is
recommended for the first cut:

- declare the whole GIFT `interconversion`, which discards the evidenced
  direction of the 6902-genome dehydrogenase route;
- split the ferredoxin route into a separate `interconversion` GIFT between the
  same anchors, which is defensible — different chemistry, different physiology
  — but doubles the node for a distinction nobody has asked for yet.

Recommendation: curate all three routes as `catabolic`, and record in
`gifts.notes` that the ferredoxin route's direction is a route-level claim the
markers do not independently support. §15 Q2 asks whether `mode` should become
route-scoped; that is a real gap in the model and this is the first content to
expose it.

### 6.4 `succinate_fumarate_interconversion` — the direction cannot be claimed

This is the section that changes the request's design.

The request asks for `SUCCINATE -> FUMARATE` and notes that the opposite
transformation is a different physiological role. Biologically that is correct.
**Genomically it is not evidenced**, and giftr's invariant 16 makes evidence the
bound on the claim.

| Marker set | KEGG's own name | Organisms | % |
|---|---|---:|---:|
| `K00239`+`K00240` | **`sdhA, frdA`** / `sdhB, frdB` | 8047 | 68.3% |
| `K00234`+`K00235` | `SDHA, SDH1` / `SDHB` (mitochondrial type) | 1257 | 10.7% |
| `K00244`+`K00245` | `frdA` / `frdB`, dedicated | 1059 | 9.0% |
| any of the three | | 9420 | 79.9% |

KEGG names `K00239` `sdhA, frdA` because outside the Enterobacteriaceae the
split does not exist. The earlier assessment recorded that of 1041 genomes with
`frdABCD`, 943 also carry `sdhABCD` — the split is a paralogue duplication
within one clade, not a functional partition across bacteria.

Two GIFTs, `succinate_oxidation` and `fumarate_reduction`, would therefore be
complete on the same markers in 8047 genomes and would report identical calls
under different names. That is not a distinction; it is a duplicated call with
two labels.

`mode = interconversion` is the mechanism the database already has for exactly
this, introduced for `acetate_interconversion` and reused for
`lactate_racemisation`:

> `interconversion` is for a near-equilibrium node whose enzymes run both ways
> in different organisms and whose markers cannot say which.

Succinate/fumarate is a better example of that definition than acetate is.
`RHEA:13713` is written in the oxidising direction and the same complex
catalyses both readings; the dedicated `frd` group exists but only in a clade
that also has `sdh`.

**What is preserved.** The route still records one traversal with per-reaction
`orientation`, so the chemistry stays directional inside the GIFT. The atlas
draws `SUCCINATE <-> FUMARATE` with a head at each end, as it already does for
acetate. The distinction the request wanted is not lost, only deferred: §15 Q3
records the trigger for splitting — an orthology group or protein family that
separates the two enzymes outside the Enterobacteriaceae, or the quinone-species
distinction (`RHEA:13713` ubiquinone versus `RHEA:27834` menaquinone versus
`RHEA:75711` rhodoquinone) becoming markerable, since rhodoquinone use is
diagnostic of fumarate respiration.

### 6.5 `fumarate_oxaloacetate_interconversion` — reversible for a second reason

| Component | Markers | Organisms | % |
|---|---|---:|---:|
| Fumarase | `K01679` ∪ `K01676` ∪ (`K01677`+`K01678`) | 10618 | 90.1% |
| Malate dehydrogenase / MQO | `K00024` ∪ `K00025` ∪ `K00026` ∪ `K00116` | 9752 | 82.8% |
| both | | 9533 | 80.9% |

Fumarase is a hydratase at equilibrium; Rhea writes `RHEA:12460` as
`(S)-malate = fumarate + H2O`, the *reverse* of the direction the request
proposes. NAD-dependent malate dehydrogenase is likewise reversible and runs
towards malate in every genome using the reductive branch. Only
malate:quinone oxidoreductase is effectively unidirectional towards
oxaloacetate, and it is one alternative system out of four.

So this segment is `interconversion` for the same reason as §6.4, though the
evidence is weaker: here the enzymes are genuinely at equilibrium rather than
genuinely indistinguishable. Declaring it `catabolic` would assert that a genome
with fumarase and Mdh runs malate towards oxaloacetate, which is false in every
succinate-producing *Bacteroides*.

**Fumarate as an anchor does not resurrect the refused edge.** The earlier
proposal refused `fumarate_formation` partly because declaring `FUMARATE` and
attaching it to the GIFTs whose curated reactions release it —
`purine_core_biosynthesis`, `adenylate_biosynthesis` — would create meaningless
edges into `pyrimidine_core_biosynthesis`. This proposal declares the anchor and
**does not attach it to those GIFTs**, because fumarate is a co-product of one
step of some of their routes, not a boundary of their capability. Their
boundaries stay `PRPP > IMP` and `IMP > AMP`. `test-organic-acid.R` already
asserts that no purine→pyrimidine edge exists; that assertion survives this
proposal unchanged and should be kept as the durable protection.

### 6.6 Citrate stays internal — and now there is a graph proof

The earlier proposal refused `citrate_formation` because citrate synthase is
present in 71% of genomes and citrate is consumed by the cell that makes it.
That argument is sound. A stronger one is now available, and it was produced by
running giftr's own edge derivation rather than reasoned about.

Splitting `acetyl_coa_to_oxoglutarate` at citrate — a one-reaction
`citrate_synthesis` GIFT with `ACETYL_COA + OXALOACETATE > CITRATE`, exactly the
option the request said not to dismiss for being one reaction — produces this,
reported by `.find_graph_cycle()` over `gift_anchors.tsv` plus the hypothetical
rows:

```text
Circular catabolic GIFT composition:
  citrate_fermentation -> pyruvate_to_acetyl_coa -> citrate_synthesis
    -> citrate_fermentation
```

This cycle has nothing to do with the citric acid cycle. It closes through
**already-curated content**: `citrate_fermentation` cleaves citrate to pyruvate
and acetate, `pyruvate_to_acetyl_coa` carries pyruvate to acetyl-CoA, and a
citrate synthase GIFT would carry acetyl-CoA back to citrate. All three claims
are true, all three are catabolic, and the loop is a genuine metabolic
possibility — but it is not a *circuit anyone runs*, and it is the kind of loop
the acyclicity heuristic exists to surface.

The request asked whether a one-reaction citrate GIFT should be rejected merely
for containing one reaction. It should not, and it is not. It is rejected
because the boundary is not compositional in the sense of §5.1 clause (a): the
only capability that would attach to citrate-as-output is a citrate-consuming
GIFT whose own product feeds straight back.

Citrate therefore keeps the role it has: an **input-only** anchor, consumed by
`citrate_fermentation` and a future `citrate_uptake`, and an internal
intermediate of `acetyl_coa_to_oxoglutarate`. The existing test that no citric
acid cycle metabolite is a declared *output* anchor will have to be narrowed to
citrate and malate; §11.4 says exactly how.

### 6.7 Malate: the boundary this proposal deliberately does not move

Malate is already an anchor, declared input-only for `malolactic_fermentation`,
and it is internal to `fumarate_oxaloacetate_interconversion` as proposed.
Splitting that GIFT at malate into `fumarate_malate_interconversion` and
`malate_oxaloacetate_interconversion` was evaluated and has three real
attractions:

- it separates fumarase (90.1%) from malate dehydrogenase (82.8%), which are
  independently lost;
- it isolates malate:quinone oxidoreductase, the one directional enzyme in the
  arm;
- it would give `malolactic_fermentation` an upstream. That GIFT has **no
  incoming edge today** — nothing in the database produces malate — and
  `test-organic-acid.R` currently asserts that absence.

It is not recommended for the first cut, for one reason: `MALATE` as an output
anchor arrives free with the glyoxylate bypass (§13.2), which produces malate
through malate synthase and is a much better-evidenced malate producer than a
reversible fumarase. Curating the split now would spend the boundary on the weak
producer. §15 Q5 keeps it open.

---

## 7. Worked examples: real architectures through the four GIFTs

`U`/`L`/`S`/`F` as in §3. `ODH`, `OFOR`, `Kgd` are the three routes of `L`;
`GLX` is the glyoxylate shunt; `ANA` is anaplerotic oxaloacetate formation.

| Genome | U | L | S | F | ODH | OFOR | Kgd | GLX | ANA | Reading |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|---|
| *E. coli* K-12 `eco` | + | + | + | + | + | − | − | + | + | complete oxidative cycle, closes |
| *B. subtilis* `bsu` | + | + | + | + | + | − | − | − | + | complete oxidative cycle, no shunt |
| *P. aeruginosa* `pae` | + | + | + | + | + | − | − | + | + | complete, shunt present |
| *M. tuberculosis* `mtu` | + | + | + | + | − | + | **+** | + | + | complete **through the Kgd bypass**, not the E1o complex |
| *C. glutamicum* `cgb` | + | + | + | + | − | − | **+** | + | + | same actinobacterial substitution |
| *R. prowazekii* `rpr` | + | + | + | + | + | − | − | − | − | complete cycle in a reduced obligate intracellular genome |
| *H. pylori* `hpy` | + | − | − | + | − | + | − | − | − | **branched / horseshoe**: oxidative arm to 2-OG, reductive arm to fumarate, no closure |
| *C. jejuni* `cje` | + | + | − | + | − | + | − | − | + | branched with the lower arm present, succinate/fumarate step unmatched |
| *B. thetaiotaomicron* `bth` | − | + | + | + | − | + | − | − | − | reductive/branched: no canonical citrate synthase call (§6.2), full reductive arm |
| *B. fragilis* `bfr` | − | + | + | + | − | + | − | − | − | as above |
| *P. melaninogenica* `pmz` | − | + | + | + | − | + | − | − | − | as above, aconitase and ICDH also absent |
| *F. succinogenes* `fsu` | + | − | + | + | − | − | − | − | − | oxidative entry plus the succinate–oxaloacetate arm, no 2-OG oxidation |
| *Synechocystis* `syn` | − | − | + | + | − | − | − | − | + | cyanobacterial split cycle |
| *C. tepidum* `cte` | + | + | + | + | − | + | − | − | + | **reductive TCA**: also the only archetype positive for ATP-citrate lyase |
| *S. aureus* `sau` | − | + | + | + | + | + | − | − | + | complete but for the citrate synthase call — the §6.2 false negative |
| *B. longum* `blo` | + | − | + | − | − | − | − | − | + | fragments only |
| *F. prausnitzii* `fpr` | − | − | + | − | − | − | − | − | − | one segment |
| *L. lactis* `lla` | − | − | − | − | − | − | − | − | + | no citric acid cycle chemistry |
| *S. pyogenes* `spy` | − | − | − | − | − | − | − | − | + | none |
| *E. rectale* `ere` | − | − | − | − | − | − | − | − | − | none |
| *M. genitalium* `mge` | − | − | − | − | − | − | − | − | − | none |
| *Buchnera* APS `buc` | − | − | − | − | + | − | − | − | − | genome reduction: the E1o complex without anything to feed it |

Five things this table shows that a monolithic GIFT cannot.

**Complete cycles are reached by different chemistry.** *E. coli* and
*M. tuberculosis* are both `ULSF`, and the route layer says one uses the E1o
complex and the other the Kgd bypass. That is a real actinobacterial trait and
it survives because `L` has three routes rather than three GIFTs.

**The *Helicobacter* horseshoe is legible.** `U--F` is not "62% complete"; it is
"oxidative arm present, reductive arm present, the two do not meet". That is the
published description of *H. pylori* central metabolism, produced without a
single line of TCA-specific logic.

**Reductive and oxidative genomes are separable, and the marker for it is
outside the four GIFTs.** *C. tepidum* is `ULSF` like *E. coli*, and what
distinguishes it is ATP-citrate lyase (`K15230`+`K15231`, 75 organisms, 0.6%).
§13.1 turns that into a fifth GIFT rather than a mode.

**A false negative is visible as a false negative.** *S. aureus* shows `-LSF`
with `ODH` and `OFOR` both present — an obviously odd pattern that points at the
citrate synthase call rather than hiding inside an aggregate percentage.

**Genome reduction has a shape.** *Buchnera* retains the 2-oxoglutarate
dehydrogenase complex and nothing else; *Rickettsia* retains the whole cycle and
loses anaplerosis. Both are `----`-adjacent under a monolithic trait and clearly
different here.

---

## 8. Representing the higher-order structure

### 8.1 First, a vocabulary collision

`gift_circuit` is **already a table** in schema 6. It is the regulatory model's
implementation table — a regulatory circuit is to a regulatory GIFT what a route
is to a metabolic one — and `circuit_functions.tsv` hangs off it. Introducing
`metabolic_circuit` and `circuit_gift` would put two unrelated meanings of
"circuit" one join apart in the same schema, and a curator reading
`circuit_functions` would have no way to know which.

Whatever the higher-order object is called, it is not a circuit. This document
uses **cycle** for the topological object and **closure** for the property of a
genome completing one.

### 8.2 The layering the request proposed, and where it lands

```text
reaction              RHEA:16845, RHEA:10336, RHEA:19629, ...
   |                  identity from Rhea; direction from route_reaction.orientation
   v
atomic GIFT           acetyl_coa_to_oxoglutarate, oxoglutarate_to_succinate, ...
   |                  a capability with declared boundaries and a Boolean call
   v
topology              chains, branches, convergences, CYCLES
                      derived from gift_graph(); nothing curated
```

The third layer is the question. The answer this proposal reaches is that the
third layer already exists and has never been read.

### 8.3 The cycle is already in the graph

The four proposed GIFTs plus a glyoxylate bypass and an anaplerotic
oxaloacetate GIFT were added to the current `gift_anchors.tsv` and the full
composition graph was derived with giftr's own rules. Enumerating **elementary
cycles** of the resulting 55-node, 72-edge graph returns exactly three:

```text
1  fumarate_oxaloacetate_interconversion -> succinate_fumarate_interconversion
     -> fumarate_oxaloacetate_interconversion

2  fumarate_oxaloacetate_interconversion -> acetyl_coa_to_oxoglutarate
     -> oxoglutarate_to_succinate -> succinate_fumarate_interconversion
     -> fumarate_oxaloacetate_interconversion

3  fumarate_oxaloacetate_interconversion -> glyoxylate_bypass
     -> succinate_fumarate_interconversion -> fumarate_oxaloacetate_interconversion
```

Cycle 2 **is** the oxidative citric acid cycle. Cycle 3 **is** the glyoxylate
bypass cycle. Cycle 1 is the reversible succinate–fumarate–oxaloacetate arm,
which is an artefact of two adjacent `interconversion` GIFTs and is discussed in
§9.2.

No table was consulted to find these. They fell out of four curated anchor
declarations. That is the single strongest argument in this proposal: **a
curated `metabolic_circuit` table would store, by hand, information the database
already derives, and would then have to be kept in agreement with it.**

### 8.4 What curation *does* still owe

Derivation gives structure and not meaning. It finds cycle 2; it does not know
that cycle 2 is called the citric acid cycle, that cycle 3 is called the
glyoxylate bypass, or that cycle 1 is not a biological cycle at all.

giftr has a mechanism for attaching curated meaning to a GIFT without changing
what the GIFT claims, and it is `facet_terms.tsv` + `gift_facets.tsv`. The facet
vocabulary is explicitly open to new facets and closed within a facet, so
registering one costs two source rows and no migration:

```text
facet_terms.tsv
  metabolic_cycle  citric_acid_cycle_oxidative  gift  "…definition…"
  metabolic_cycle  glyoxylate_bypass            gift  "…definition…"

gift_facets.tsv
  acetyl_coa_to_oxoglutarate             metabolic_cycle  citric_acid_cycle_oxidative
  oxoglutarate_to_succinate              metabolic_cycle  citric_acid_cycle_oxidative
  succinate_fumarate_interconversion     metabolic_cycle  citric_acid_cycle_oxidative
  fumarate_oxaloacetate_interconversion  metabolic_cycle  citric_acid_cycle_oxidative
  glyoxylate_bypass                      metabolic_cycle  glyoxylate_bypass
```

`metabolic_cycle` must be **multi-valued** — `fumarate_oxaloacetate_interconversion`
belongs to both named cycles — and must **not** be added to
`.giftr_required_gift_facets`, since most metabolic GIFTs belong to no cycle.

This is deliberately weaker than a `circuit_gift` table. It records membership
and nothing else: no `required` flag, no `role`, no declared topology. Those
three fields are precisely the ones the graph already knows, and a curated copy
of them is a second source of truth waiting to drift. The one thing curation
knows and the graph does not is the *name*, and a facet value is a name.

### 8.5 What a genome-level report then looks like

Nothing below is a new call; all of it is assembled from `evaluate_gifts()`
output plus the graph.

```text
Genome: Helicobacter pylori 26695

  acetyl_coa_to_oxoglutarate             complete    route OXOGLU_ICDH_NADP
  oxoglutarate_to_succinate              incomplete  closest OG_SUC_OFOR,
                                                     missing succinyl-CoA synthetase
  succinate_fumarate_interconversion     incomplete  closest SF_QUINONE,
                                                     missing sdh/frd flavoprotein
  fumarate_oxaloacetate_interconversion  complete    route FUM_MDH

  cycle citric_acid_cycle_oxidative      OPEN
        supported segments   2 of 4
        broken at            oxoglutarate_to_succinate,
                             succinate_fumarate_interconversion
        longest closed chain acetyl_coa_to_oxoglutarate (entry from ACETYL_COA)
```

Compare the same report for *E. coli* K-12, where the cycle is `CLOSED`, and for
*Erysipelatoclostridium*, where every segment is absent and the cycle is
`ABSENT` rather than `OPEN` — a distinction worth keeping, because a genome
missing one segment and a genome missing all four are not the same result.

---

## 9. The within-mode acyclicity invariant

### 9.1 What the rule actually is, and what depends on it

`R/database-build.R` derives composition edges exactly as the `gift_graph` view
does, partitions them by `mode`, and calls `.find_graph_cycle()` on each
partition. A cycle is a **build error**.

Nothing at runtime requires the graph to be acyclic. This was checked rather
than assumed:

| Consumer | Behaviour on a cyclic graph |
|---|---|
| `gift_graph()` | flat `SELECT` over a view; unaffected |
| `gift_profile` | in-degree and out-degree counts; unaffected |
| `gifts_for_pathway()`, `trace_gift()`, `evaluate_gifts()` | do not read the graph |
| atlas composition SVG | `.report_graph_levels()` is a longest-path relaxation bounded by `seq_along(node_ids)` with a `changed` flag: it **terminates**, but pushes every node of a cycle to a high column, so a cycle renders as a long diagonal rather than a ring |

So acyclicity is a **curation heuristic enforced at build time**, not a
structural requirement of the model. That matters for how it should be changed:
relaxing it cannot break a consumer, and tightening it protects nothing but
curation quality — which is a good thing to protect, and a reason to keep the
rule rather than delete it.

### 9.2 The rule is already wrong, and TCA is not why

Two synthetic GIFTs were added to the current source tables — no citric acid
chemistry, no new content of any kind:

```text
xy_interconversion   mode = interconversion   anchors MOL_X, MOL_Y (both roles)
yz_interconversion   mode = interconversion   anchors MOL_Y, MOL_Z (both roles)
```

The validator reports:

```text
Circular interconversion GIFT composition:
  xy_interconversion -> yz_interconversion -> xy_interconversion
```

This is not a curation error. It is arithmetic. `interconversion` requires every
anchor to be declared in **both** roles, so two interconversion GIFTs sharing one
anchor produce an edge in each direction *by construction*. The rule and the
mode contradict each other, and the contradiction fires on the third
interconversion GIFT that happens to touch an existing one.

The database is currently safe only by accident: `acetate_interconversion`
(`ACETYL_COA`, `ACETATE`) and `lactate_racemisation` (`LACTATE`, `LACTATE_L`)
share no anchor. `proposal-scfa-biosynthesis.md` §8 argued that `interconversion`
"partitions them correctly on the first try" for the acetyl-CoA/acetate/`acs`
case. That is true when the second GIFT is directed; it is false when both are
reversible, and the proposal did not distinguish the two.

### 9.3 The recommended rule

> Undeclared cycles within a **directed** mode — `anabolic`, `catabolic`,
> `transport` — remain validation errors. `interconversion` is exempt, because a
> cycle there is a syntactic consequence of the mode's own boundary contract
> rather than evidence of a bad cut.

Implementation: one `setdiff()` in the loop that already exists.

```r
# Cycles are forbidden within a directed mode and expected between modes. An
# interconversion GIFT declares every anchor in both roles, so two adjacent
# interconversions cycle by construction; the mode, not the boundary, is what
# makes the loop, and the check would be reporting its own contract back.
for (mode in intersect(setdiff(.giftr_gift_modes, "interconversion"),
                       unique(tables$gifts$mode))) {
```

**This is the whole architectural change.** No schema migration, no new table,
no new column, no change to any accessor.

The same derivation was run over the full recommended content — four TCA
segments, the glyoxylate bypass, anaplerotic oxaloacetate formation, on top of
the current 68 GIFTs:

```text
         no cycle in anabolic
         no cycle in catabolic
         no cycle in transport
[EXEMPT] cycle in interconversion
         fumarate_oxaloacetate_interconversion
           -> succinate_fumarate_interconversion
           -> fumarate_oxaloacetate_interconversion
```

The directed modes stay clean. The heuristic keeps working everywhere it is
meaningful, and the sulfur-metabolism worked example in the architecture guide —
where `HOMOCYSTEINE` was demoted to input-only to break an anabolic loop — is
untouched, because that loop was and remains anabolic.

### 9.4 What was deliberately not done

**Not "permit cycles that a curated circuit declares".** That was the request's
own suggested rule, and it inverts the relationship between structure and
curation: it would make the validator's correctness depend on a table whose
contents the validator cannot check. It also does not fix §9.2, which has no
circuit to declare.

**Not assigning artificial modes.** The request forbade this and was right to.
It is worth being explicit that the recommendation is *not* a disguised version
of it: `succinate_fumarate_interconversion` and
`fumarate_oxaloacetate_interconversion` are reversible because of §6.4 and §6.5,
and those sections were written from marker evidence before the graph was run.
The fact that the mode assignment also happens to relieve the catabolic cycle is
a consequence, not the motive — and it is a *fragile* consequence: the same
experiment with `interconversion` still under the acyclicity rule fails, which is
why the rule change is required rather than optional.

**Not removing the rule.** A catabolic loop is still almost always a boundary
error, and the `citrate_fermentation -> pyruvate_to_acetyl_coa ->
citrate_synthesis` result in §6.6 is this proposal's own evidence for keeping
the check: it caught a bad boundary during this analysis.

---

## 10. Alternatives considered

| # | Alternative | Verdict |
|---|---|---|
| 1 | **One `tca_cycle` GIFT** with routes spanning the whole ring | Refused. §3: 37.1% of genomes collapse into one uninterpretable class, and *H. pylori* is indistinguishable from *M. genitalium* |
| 2 | **One GIFT per reaction** | Refused. §4: not capabilities, destroys the OR-over-routes layer that carries the ODH/OFOR/Kgd distinction, promotes four extra anchors |
| 3 | **Six directional GIFTs**, the earlier proposal's construction | Refused. Closes a catabolic cycle; three of the six are refused traits (`citrate_formation`, `fumarate_formation`, `succinate_formation`); the direction of at least three is unevidenced |
| 4 | **Four GIFTs, all `catabolic`**, the request's literal proposal | Refused on evidence, not on topology. §6.4 and §6.5: two of the four claim directions their markers cannot distinguish, which is invariant 16 |
| 5 | **A fifth `gift_type`, e.g. `cyclic`** | Refused. Invariant 19 requires a completeness contract per type, and a cycle has none of its own — its members are ordinary metabolic GIFTs. Invariant 18 says higher-order descriptions are derived, not typed |
| 6 | **`metabolic_circuit` + `circuit_gift` tables** | Refused. §8.3: the cycles are already derivable; the tables would duplicate `role` and topology the graph knows, and the `required` flag would let a curated circuit disagree with the graph. Also collides with the regulatory `gift_circuit` (§8.1) |
| 7 | **Redefine a GIFT as a circular object** | Refused, as the request itself suggested. It would change the completeness contract of every metabolic GIFT to accommodate one topology |
| 8 | **Split at citrate** (one-reaction `citrate_synthesis`) | Refused, on a graph result rather than on reaction count. §6.6 |
| 9 | **Split at malate** | Deferred, not refused. §6.7 and §15 Q5 |
| 10 | **Route-scoped `mode`** | Deferred. It would resolve §6.3's ferredoxin-route caveat properly and is a schema change; §15 Q2 |
| 11 | **Keep the acyclicity rule and exempt nothing**, curating only three of the four segments so the ring never closes | Refused. It would mean deleting a true capability to satisfy a check, which is the failure mode the architecture guide warns about when it says to ask which boundary is the weakest claim rather than to delete an edge |

---

## 11. Implications for schema, validation, API and evaluation

### 11.1 Schema

**None.** No table, column, constraint or view changes. `schema_version` stays
6. This is the proposal's main structural claim and it follows from §8.3 and
§9.3.

### 11.2 Validation

One change, in `R/database-build.R`, shown in §9.3: exclude `interconversion`
from the within-mode cycle scan. It is a bug fix independent of this content and
can land first, with the synthetic two-GIFT fixture from §9.2 as its test.

### 11.3 Public API

One new accessor, and it must contain no TCA-specific logic:

```r
gift_cycles(db = NULL)
#> A tibble: elementary cycles of the metabolic composition graph
#>   cycle_index  length  gift_id                                position
#>             1       2  fumarate_oxaloacetate_interconversion         1
#>             1       2  succinate_fumarate_interconversion            2
#>             2       4  fumarate_oxaloacetate_interconversion         1
#>             2       4  acetyl_coa_to_oxoglutarate                    2
#>             ...
```

and an argument on the evaluation side that reads a genome's calls against those
cycles:

```r
evaluate_gift_cycles(markers, db = NULL)
#> cycle_index  named_cycle                   status  supported  total  broken_at
#>           2  citric_acid_cycle_oxidative   OPEN            2      4  <2 gift_ids>
```

`named_cycle` comes from the `metabolic_cycle` facet when every member of the
derived cycle carries the same value, and is `NA` otherwise — so an unnamed
cycle is still reported, which is what makes the accessor general.

Both functions are graph operations over `gift_graph()` and
`evaluate_gifts()$gifts`. Neither mentions any GIFT by name. On the day the
Calvin–Benson–Bassham cycle is curated they find it without modification.

Elementary-cycle enumeration is exponential in the worst case. It is safe here
because the metabolic composition graph is small and sparse — 55 nodes and 72
edges under the full recommended content, returning three cycles — but the
implementation should cap enumeration and warn rather than hang, and the cap
should be a documented argument.

### 11.4 Evaluation and tests

`evaluate_gifts()` is **unchanged**. Cycle status is computed from its output
and never feeds back into it; this is invariant-level and §12.1 restates it as a
test.

Tests that must change:

| Test | Change |
|---|---|
| `test-organic-acid.R` — "no citric acid cycle intermediate is a declared anchor" | Narrows to what remains true: **citrate and malate are declared input-only**, and no GIFT claims to *form and release* a cycle acid. The name should change with it; the current name will otherwise assert something the database contradicts |
| `test-organic-acid.R` — "malolactic fermentation … nothing produces malate" | Unchanged by this proposal, but §13.2's glyoxylate bypass will change it. Flag it now |
| `test-organic-acid.R` — fumarate creates no purine→pyrimidine edge | **Keep, unchanged.** It becomes more valuable once `FUMARATE` is a declared anchor, because it then protects a live risk rather than a hypothetical one |
| `test-composition.R` | Add the §9.2 synthetic interconversion pair as an explicit non-error, and keep a directed-mode cycle as an explicit error |
| new `test-central-cycles.R` | The four segments to full evidence depth; the ODH/OFOR/Kgd OR; the archetype calls of §7 as fixtures; `gift_cycles()` returning the oxidative cycle; and the negative case that a genome completing three of four segments reports `OPEN`, not `complete` |

### 11.5 The atlas

The composition SVG will draw the ring as a diagonal (§9.1). That is cosmetic
and should be recorded as a known limitation rather than fixed speculatively; a
ring layout is only worth building once more than one cycle exists.

---

## 12. Genome- and community-level interpretation

### 12.1 The invariant that must not be broken

> Cycle closure is derived from Boolean calls. It never changes one.

`acetyl_coa_to_oxoglutarate` is complete in *H. pylori* whether or not the cycle
closes. A design in which "the cycle is open" downgraded a member GIFT would be
inferring a capability's absence from a neighbour's absence, which is the
opposite of what the composition model is for. This deserves an explicit test.

### 12.2 Genome level

The four segments plus derived closure give a genome one of a small number of
interpretable states, all of them stated as gene content:

```text
CLOSED           all members of a named cycle complete
OPEN             some but not all members complete; the broken segments named
ABSENT           no member complete
BYPASSED         a named cycle is open, and an alternative cycle sharing
                 two or more of its anchors is closed
```

`BYPASSED` is the glyoxylate case and is derived, not curated: cycle 3 in §8.3
shares `FUMARATE`, `OXALOACETATE` and `SUCCINATE` with cycle 2.

None of these is a phenotype. A `CLOSED` call means the genome encodes at least
one complete route for every segment of a ring in the composition graph. It does
not mean the cycle carries flux, that it runs oxidatively, that the organism
respires, or that any of it is expressed. The `succinate_fumarate_interconversion`
segment in particular is `interconversion` precisely because giftr cannot say
which way it runs, so a `CLOSED` oxidative cycle is a statement about encoded
chemistry and not about the direction of that chemistry.

### 12.3 Community level, and the claim not to make

For a set of genomes, the same derivation supports statements such as the
following. The figures are illustrative, not measured:

```text
Community of 42 MAGs, named cycle citric_acid_cycle_oxidative

  CLOSED in 11 MAGs
  OPEN   in 19 MAGs
  ABSENT in 12 MAGs

  segment coverage across the community
    acetyl_coa_to_oxoglutarate             28 MAGs
    oxoglutarate_to_succinate              24
    succinate_fumarate_interconversion     33
    fumarate_oxaloacetate_interconversion  31

  every segment is present in at least one MAG
```

That last line is the one that must be phrased with care. It means **the union
of the community's gene content covers every segment.** It does **not** mean:

- that succinate leaves one organism and enters another;
- that the segments are used in the order the cycle draws them;
- that any exchange occurs, or could occur, in this environment;
- that the community "has a citric acid cycle" in any physiological sense.

giftr's compartment model is the only mechanism it has for even the *possibility*
of exchange, and none of the four segments' anchors is compartment-resolved:
every one is `unspecified`, because no transporter marker is specific enough to
license a split for these acids. The earlier proposal recorded the same
limitation for lactate and acetate. A community-level statement here is
therefore strictly weaker than the cross-feeding statement `gift_profile`
already declines to make for extracellular polymers, and the wording should
reflect that.

The useful and defensible community claim is the negative one: **no member
encodes a complete cycle, and the segments are distributed across members.**
That is a statement about genomes, it is checkable, and it is often the
interesting result.

---

## 13. Generalisation beyond the citric acid cycle

The design contains no TCA-specific logic. The test of that claim is whether
other cyclic systems fall out of the same three mechanisms — anchors, `mode`,
derived cycles.

### 13.1 Reductive citric acid cycle

The rTCA runs the same ring backwards and needs different enzymes at exactly two
steps: ATP-citrate lyase in place of citrate synthase, and
2-oxoglutarate:ferredoxin oxidoreductase in place of the dehydrogenase complex.
`K15230`+`K15231` is present in **75 organisms (0.6%)** — rare, clean and
diagnostic, which is what a marker for a directional claim should look like and
what §6.4's succinate markers are not.

Representation: **one additional GIFT**, `oxaloacetate_to_acetyl_coa_reductive`
or similar, `anabolic`, `OXALOACETATE + CITRATE`-internal, running
`OXALOACETATE > ACETYL_COA`. It composes with the existing reversible arm
through `OXALOACETATE` and `SUCCINATE`, and a genome carrying it plus the
reversible arm closes a *different* elementary cycle in a *different* mode —
which the acyclicity rule permits, since anabolic and catabolic partitions are
scanned separately. No new mechanism. The reductive cycle then gets its own
`metabolic_cycle` facet value.

This also settles the request's directionality question at the right layer: the
oxidative and reductive cycles are distinguished by **which GIFTs a genome
carries**, not by opposed directional claims on shared reversible ones.

### 13.2 Glyoxylate bypass

Isocitrate lyase (`K01637`) and malate synthase (`K01638`/`K01639`) are jointly
present in **4834 organisms (41.0%)**; 4399 of those also complete all four
segments and 435 do not. Representation: one `catabolic` GIFT,
`ACETYL_COA + OXALOACETATE > SUCCINATE + MALATE`, which bypasses `OXOGLUTARATE`
— which is precisely what the shunt is for.

Two things to note. It **reuses** `RHEA:16845` and `RHEA:10336` from
`acetyl_coa_to_oxoglutarate` rather than duplicating them, which is what the
shared `reactions.tsv` is for; the invariant against duplication forbids
re-deriving a *composition* the graph already expresses, and this bypass is not
expressible as a composition of the four segments because it skips an anchor.
And it produces `MALATE`, which finally gives `malolactic_fermentation` an
upstream edge (§6.7) and closes cycle 3 of §8.3.

An alternative is to expose `ISOCITRATE` and split `acetyl_coa_to_oxoglutarate`
there. That is cleaner in the diagram and costs an anchor and a boundary whose
only consumer is the shunt. §15 Q6.

### 13.3 Calvin–Benson–Bassham cycle

Regenerative rather than catalytic in the same sense — it consumes CO2 and
exports triose phosphate — but topologically identical: a ring through
ribulose-1,5-bisphosphate, 3-phosphoglycerate and ribulose-5-phosphate with an
export branch. giftr already has `PG3`, `GAP`, `DHAP`, `FRUCTOSE_6P` and
`XYLULOSE_5P` as anchors, so the carbon-fixation segment
(`PG3 > RIBULOSE_1_5_BP`, carboxylation, regeneration) would need one or two new
anchors and would compose into the existing sugar-phosphate content. The
mechanism is the same; the boundary work is a separate proposal.

### 13.4 Urea and ornithine cycles

The complete urea cycle is rare in bacteria; the arginine deiminase pathway and
the arginine/ornithine antiporter systems are common and are the traits people
actually want. The relevant lesson is the compartment one rather than the cycle
one: the antiporter means an ornithine boundary would be a genuine
compartment-split candidate, which is a different mechanism from this proposal
and already exists.

### 13.5 The general statement

A cyclic metabolic system is representable when, and only when:

1. its ring can be cut into spans that are separately meaningful capabilities;
2. the cut points satisfy §5.1 — something else attaches, and each side is
   separately evidenced;
3. each span's direction is either evidenced or honestly declared
   `interconversion`.

If (1) fails the system is one GIFT. If (2) fails the cut is in the wrong place.
If (3) fails on a span, that span is reversible and the ring will close in the
graph — which is now legal.

---

## 14. Recommended implementation path

Four phases, each independently testable, each able to stop without leaving the
database inconsistent.

**Phase 0 — the validator fix, no biological content.** Exempt `interconversion`
from the within-mode cycle scan (§9.3). Add the §9.2 synthetic pair to
`test-composition.R` as a passing case and a directed-mode cycle as a failing
one. `CHANGELOG.md` entry. This is a bug fix and should land whether or not the
rest of the proposal is accepted.

**Phase 1 — the four anchors and four GIFTs.**

| anchor_id | molecule | compartment | ChEBI |
|---|---|---|---|
| `OXALOACETATE` | OXALOACETATE | unspecified | `CHEBI:16452` |
| `OXOGLUTARATE` | OXOGLUTARATE | unspecified | `CHEBI:16810` |
| `SUCCINATE` | SUCCINATE | unspecified | `CHEBI:30031` |
| `FUMARATE` | FUMARATE | unspecified | `CHEBI:29806` |

All four ChEBI identifiers were taken from the `chebi-id` column of the Rhea
reactions that use them. `MALATE` (`CHEBI:15589`) and `CITRATE`
(`CHEBI:16947`) already exist and match.

Required facets are already registered: `substrate_class = central_metabolite`
and `physiological_role = central_carbon_metabolism` were added by the SCFA
layer for `pyruvate_to_acetyl_coa`. Anchors need `molecular_tier` and
`biomass_essential`, and `resource_origin` is expected.

Then the four GIFTs of §5.2 with their routes, systems, components and markers,
and `gift_xrefs` rows against KEGG `map00020` with `relation = subset_of` for
each — never `equivalent`, since no segment covers the map.

Composition dividends that arrive free, verified by derivation:
`pyruvate_to_acetyl_coa -> acetyl_coa_to_oxoglutarate` and
`acetate_interconversion -> acetyl_coa_to_oxoglutarate`, both through
`ACETYL_COA`.

**Phase 2 — derived cycles.** `gift_cycles()`, `evaluate_gift_cycles()`, the
`metabolic_cycle` facet with `citric_acid_cycle_oxidative`, and
`test-central-cycles.R`.

**Phase 3 — the neighbours, in this order.** `glyoxylate_bypass` (41.0%,
completes cycle 3 and gives malate a producer); anaplerotic oxaloacetate
formation from pyruvate/PEP (79.1%, connects the uronate and citrate content —
derivation shows `galacturonate_degradation`, `glucuronate_degradation` and
`citrate_fermentation` all gaining edges into it); then the reductive cycle
(§13.1). Each is a separate curation decision with its own `database_changes`
entry.

Every phase records a `database_changes.tsv` entry with `change_gifts.tsv` links
for biological content, and a `CHANGELOG.md` entry for Phase 0 and Phase 2 code.

---

## 15. Open biological and architectural questions

**Q1 — the citrate synthase marker.** Is `K01659` acceptable as an
`ambiguous`-confidence alternative system (§6.2), given that it will over-broaden
a future 2-methylcitrate/propionate-catabolism GIFT? The trigger for revisiting
is either that GIFT being curated, or KEGG splitting the group. A defensible
alternative is to require `K01647`/`K05942` and record *Bacteroides* and
*Staphylococcus* as known false negatives in `gifts.notes` — which is more honest
about the evidence and less useful about the gut.

**Q2 — route-scoped `mode`.** §6.3 exposes a genuine gap: the dehydrogenase and
ferredoxin routes of one GIFT have different reversibility. `oxygen_requirement`
is already per-route for the same kind of reason. Should direction follow it?
This is a schema change and should not be made for one GIFT.

**Q3 — splitting succinate/fumarate.** The trigger is an orthology group or
protein family separating succinate dehydrogenase from fumarate reductase
outside the Enterobacteriaceae, or markers resolving the quinone species
(`RHEA:13713` ubiquinone / `RHEA:27834` menaquinone / `RHEA:75711`
rhodoquinone), since rhodoquinone use is diagnostic of fumarate respiration.

**Q4 — succinyl-CoA.** It is a real branchpoint for heme, lysine (DAP pathway)
and methionine in some clades. It stays internal here because nothing in the
database attaches to it yet. It should be reconsidered the first time a
tetrapyrrole GIFT is curated.

**Q5 — splitting at malate.** §6.7. Recommended after the glyoxylate bypass
exists, not before.

**Q6 — isocitrate.** §13.2. Exposing it makes the glyoxylate bypass a clean
two-GIFT composition instead of a span that reuses two reactions; it costs an
anchor whose only consumer is the shunt.

**Q7 — fumarate respiration.** Still deferred, still the trait most users mean
when they say "fumarate". It needs an electron-acceptor model giftr does not
have. `succinate_fumarate_interconversion` deliberately does **not** claim it,
and its `notes` should say so, because the anchor names will invite the reading.

**Q8 — the `BYPASSED` state.** §12.2 defines it by anchor overlap between two
cycles. Two or more shared anchors is a threshold chosen for the glyoxylate
case and not derived from anything. It may want a better definition, or none.

**Q9 — cycle enumeration cost.** §11.3. Three cycles from 55 nodes is
comfortable; the cap and its default should be decided before the graph grows
by another order of magnitude.

---

## 16. Recommendation among the three options

**Option 1 — atomic GIFTs plus purely derived cycle detection. Recommended,
with one qualification.**

It is the smallest change that solves the problem: no schema migration, one
five-line validator fix, one new accessor, and four curated GIFTs. It preserves
every invariant the request listed — declared anchors remain the only
composition mechanism, four anchors are added and no more, no GIFT-specific R
logic exists, reactions are reused rather than duplicated, traceability from
call to marker is untouched, and directionality is stated wherever the evidence
supports it and honestly withheld where it does not. Crucially, §8.3 shows the
cycles are *already there*: the oxidative citric acid cycle and the glyoxylate
bypass both appear as elementary cycles of the composition graph without a
single curated row describing them.

The qualification is §8.4. Pure derivation cannot supply a name, and a name is a
biological fact worth recording. The proposal therefore adds one **facet**, not
a table: `metabolic_cycle`, multi-valued, open vocabulary, two source rows per
named cycle. Structure stays derived; naming is curated; the two cannot drift,
because the facet says only what the graph cannot infer.

**Option 2 — atomic GIFTs plus curated circuit definitions. Not recommended.**

`metabolic_circuit` and `circuit_gift` would store `role`, `topology` and
`required` for member GIFTs — three fields the graph already knows and can
therefore contradict. A curated circuit that omits a member the graph places in
the cycle, or marks a member `required = 0` that the ring cannot do without, is
a silent inconsistency with no validator to catch it. It is also, structurally, a
curated list of GIFT identifiers standing for a pathway, which is what invariant
1 refuses. And the name collides with the regulatory model's existing
`gift_circuit` table (§8.1).

Option 2 becomes the right answer if — and only if — a metabolic ring is found
whose membership is *not* derivable from anchors: a cycle that closes through a
relationship the anchor graph cannot express. No such case is known today, and
the honest position is to wait for one rather than to build for it.

**Option 3 — a different abstraction.** Considered and rejected: a fifth
`gift_type` (§10 row 5), redefining a GIFT as circular (row 7), and permitting
cycles only where a curated circuit declares them (§9.4). The last is the one
worth naming explicitly, because it was the request's own suggestion and it is
attractive: it fails because it makes a validator's correctness depend on a
curated table, and because it does not fix the interconversion defect in §9.2,
which has no circuit to declare and is a live bug today.

**What tips the balance.** Options 1 and 2 give the same biological
interpretability and the same traceability. They differ in generality and in the
number of ways they can be wrong. Option 1 finds the Calvin cycle on the day it
is curated, with no new rows; option 2 finds it when somebody remembers to write
the circuit down. Option 1 has one source of truth for topology; option 2 has
two.

---

## 17. Provenance

All figures retrieved 2026-08-18 against database version 2026.15.1, schema 6.

- **KEGG orthology-to-gene links**: `https://rest.kegg.jp/link/genes/ko:<KO>`,
  reduced to organism codes and intersected locally. **67 orthology groups**,
  spanning **11 783 organisms**. The universe differs slightly from the 11 855
  of `proposal-organic-acid-formation.md` because it is the union over a
  different KO set.
- **KEGG orthology names**: `https://rest.kegg.jp/find/ko/<KO>`. The
  `sdhA, frdA` naming of `K00239` and the `prpC; 2-methylcitrate synthase`
  naming of `K01659` are quoted from that endpoint.
- **KEGG gene-to-orthology assignments**: `https://rest.kegg.jp/link/ko/<gene>`
  for `sau:SA1518`, `bth:BT_2070`, `bth:BT_2071`, `bth:BT_2072`. These four
  lookups are the whole of §6.2's evidence and were checked individually.
- **KEGG genome list**: `https://rest.kegg.jp/list/genome`, used for genus
  attribution in §3.
- **Rhea**: `https://www.rhea-db.org/rhea?query=ec:<EC>&format=tsv` for 19 ECs,
  plus equation and `chebi-id` lookups by Rhea ID. Every ChEBI identifier in
  §14 was taken from the `chebi-id` column of a reaction that uses it.
- **Graph results** in §6.6, §8.3, §9.2 and §9.3 were produced by running
  giftr's own edge derivation (`R/database-build.R`, the `gift_graph` rules) and
  `.find_graph_cycle()` over the current `gift_anchors.tsv` plus hypothetical
  rows, in a scratch script. They are observations, not predictions. The
  elementary-cycle enumeration in §8.3 is a depth-first enumeration over the
  same derived edges. **No file in the repository was modified by any
  experiment.**
- **Runtime cycle-sensitivity audit** in §9.1 was performed by reading
  `R/database.R`, `R/evaluation.R` and `R/database-visualization.R`; the
  relevant function is `.report_graph_levels()`.

Reference genomes used for the specificity checks, by KEGG organism code:
`eco`, `bsu`, `pae`, `stm`, `bth`, `bfr`, `pmz`, `fsu`, `msu`, `cac`, `fpr`,
`blo`, `lla`, `spy`, `mtu`, `cgb`, `hpy`, `cje`, `syn`, `cte`, `aae`, `dvu`,
`rpr`, `buc`, `mge`, `ctc`, `sau`, `ere`.

---

## 18. Implementation record, 2026-08-18

Accepted and curated as release **2026.16.1**. Section 11.1's central claim held:
the schema is unchanged at version 6, no table, column, constraint or view was
touched, and the only change to existing code is the five-line scope fix of
section 9.3. Phases 0, 1 and 2 of section 14 are implemented. **Phase 3 is
not** — the glyoxylate bypass, anaplerotic oxaloacetate formation and the
reductive cycle remain separate curation decisions.

**KEGG independently agrees with the section 6.2 recommendation, and the
proposal did not know it.** The assessment argued from four gene-level lookups
that `K01659` must be accepted as a citrate synthase alternative despite its
name. KEGG's own definition of module `M00010` is
`(K01647,K05942,K01659) (K01681,K27802,K01682) (K00031,K00030)` — the same three
citrate synthase groups and the same three aconitase groups, including
`K27802`. That is a stronger corroboration than anything in section 6.2 and it
was found while writing the `gift_xrefs` rows, not while making the decision.
The marker is still recorded at `ambiguous` confidence, so a call that depends
on it says so, and open question Q1 stands unchanged.

**`oxoglutarate_to_succinate` has four routes, not the three the proposal
described.** Succinate-semialdehyde dehydrogenase has distinct Rhea masters for
its NAD (`RHEA:13217`) and NADP (`RHEA:13213`) forms with partly distinct
markers, so the decarboxylase bypass materialises as two routes rather than one.
Reaction identity is the Rhea master and two masters cannot be merged, so this
follows from the rule rather than departing from it — but section 6.3 said
"three routes" and should have said four.

**Succinyl-CoA synthetase is one reaction with two enzyme systems, not two
reactions.** `K01899` and `K01900` carry both the ADP- and the GDP-forming EC
numbers in KEGG, so no marker separates the nucleotide specificities and
curating `RHEA:17661` and `RHEA:22120` as alternatives would have doubled the
routes for a distinction nothing can evidence.

**Two subunit decisions were taken on the "false negative" rule.** The
succinate/fumarate systems require only the catalytic flavoprotein and
iron-sulfur subunits: adding the cytochrome b anchor `K00241`, as KEGG's
`M00011` does, calls a further 402 genomes negative on a poorly conserved
membrane subunit. The ferredoxin oxidoreductase requires only its alpha and beta
subunits, for the same reason with respect to the four-subunit forms. Both
choices are recorded in the system descriptions.

**`gift_cycles()` had to exclude one of the three cycles section 8.3
predicted.** All three appeared exactly as derived. The two-node loop between
the reversible succinate–fumarate and fumarate–oxaloacetate segments is a mode
artefact, and reporting it would have been worse than untidy: both members carry
the `metabolic_cycle` facet, so it would have been reported as a second thing
named `citric_acid_cycle_oxidative`. The accessor now drops a two-node cycle
whose members are both `interconversion`, which is the same rule, stated the
same way, that the validator uses to exempt it. Section 8.3 should have
anticipated this; it described the cycle as an artefact and then listed it as a
result.

**One implementation bug is worth recording because it was silent.**
`evaluate_gift_cycles()` first computed `status` and `broken_at` inside the
`tibble()` call that also creates a `supported` column. `tibble()` evaluates its
arguments in order and exposes earlier ones to later ones, so `all(supported)`
read the integer count rather than the logical vector, and `all(2)` is `TRUE`:
every partially supported cycle was reported `closed` with an empty
`broken_at`. The archetype fixtures caught it because *H. pylori* is the case
the whole layer exists to distinguish. Both values are now computed before the
tibble is built, with a comment saying why.

**Tests that changed, and what they now protect.**
`test-organic-acid.R`'s "no citric acid cycle intermediate is a declared anchor"
asserted the finding this proposal reverses, so it was rewritten rather than
deleted: it now asserts what the refusals were actually about — that citrate and
malate stay input-only, that nothing named `*_formation` outputs a cycle acid,
and that every GIFT declaring succinate, fumarate or oxaloacetate as an output
is a segment of the curated cycle. The fumarate/purine/pyrimidine assertion was
**strengthened**: it protected a hypothetical before `FUMARATE` was an anchor
and now protects a live risk, so it checks the anchor creates no edge touching
the nucleotide GIFTs, not merely that no such edge exists. Four inventory
assertions in `test-database.R` and one edge-set assertion in `test-scfa.R`
were updated for the new content. `test-central-cycles.R` and two new cases in
`test-composition.R` are new.

**What the graph gained.** Exactly the edges section 9.3 derived, and no others:
`pyruvate_to_acetyl_coa` and `acetate_interconversion` now reach
`acetyl_coa_to_oxoglutarate` through `ACETYL_COA`, so neither is a terminal
node any more, and the four segments close the ring through `OXOGLUTARATE`,
`SUCCINATE`, `FUMARATE` and `OXALOACETATE`. Every directed mode remains
acyclic, which `test-composition.R` now asserts against the compiled database
rather than against a fixture.

**Final counts.** 72 GIFTs, 89 anchors, 226 reactions, 97 routes, 700 markers,
65 recorded biological changes. The full suite is 2406 passing tests.

---

## 19. Phase 3 implementation: isocitrate and the glyoxylate bypass, 2026-08-20

Database release **2026.20.1** implements the first Phase 3 item and supersedes
the earlier statement that malate must remain input-only. No schema or R API
change was required.

The decisive cut is `ISOCITRATE` (`CHEBI:15562`):

```text
ACETYL_COA + OXALOACETATE
  --acetyl_coa_to_isocitrate--> ISOCITRATE
     |--isocitrate_to_oxoglutarate--> OXOGLUTARATE
     `--glyoxylate_bypass + ACETYL_COA--> SUCCINATE + MALATE
```

The former `acetyl_coa_to_oxoglutarate` is replaced by two atomic GIFTs.
`acetyl_coa_to_isocitrate` retains `RHEA:16845` and `RHEA:10336` and all their
existing enzyme-system decisions. `isocitrate_to_oxoglutarate` owns the
NADP-dependent `RHEA:19629` and NAD-dependent `RHEA:23632` alternatives.
`glyoxylate_bypass` owns only isocitrate lyase (`RHEA:13245`, `K01637`) and
direct malate synthase (`RHEA:18181`, `K01638`). Thus no reaction is duplicated
and each branch is independently callable.

Glyoxylate is deliberately **not** an input anchor of the bypass. The complete
route produces it in step one and consumes it in step two; declaring it as an
input would change the route boundary. It remains an output-only boundary of
allantoin degradation. Malate, in contrast, is the final product of the bypass
and becomes a justified output boundary, creating one new edge to
`malolactic_fermentation`.

Two proposed markers were rejected or deferred:

- `K01639` is N-acetylneuraminate lyase and is not malate synthase. It is
  already valid evidence in sialic-acid degradation and accepting it here would
  equate unrelated traits.
- `K19282` implements the alternative via (S)-malyl-CoA lyase plus thioesterase
  (`R00473` and `R10612`). It is not an alternative system for the one-step
  `RHEA:18181` reaction and is deferred until those two masters and their
  route-level evidence are curated.

The graph now derives two named cycles. The oxidative cycle has five members,
because its upper segment is split at isocitrate. The glyoxylate cycle has four:
`acetyl_coa_to_isocitrate`, `glyoxylate_bypass`,
`succinate_fumarate_interconversion` and
`fumarate_oxaloacetate_interconversion`. The shared anchors are respectively
`ISOCITRATE`, `SUCCINATE`, `FUMARATE` and `OXALOACETATE`. The
`metabolic_cycle = glyoxylate_cycle` facet supplies only the name; membership
and closure remain derived, and neither cycle can change a member call.
