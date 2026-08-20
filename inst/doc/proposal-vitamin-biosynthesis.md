# Curation proposal: vitamin biosynthesis GIFTs

Status: **accepted and implemented in database version 2026.15.1 (schema 6).**
The implementation record, including every point where it departed from this
proposal, is §14. Evidence test applied 2026-08-18 against
database version 2026.13.1 and re-checked the same day against **2026.14.1**
(schema 6, 48 GIFTs, 54 anchors, 62 routes, 118 reactions), KEGG release of
2026-08-18 (11 949 genomes, of which 10 151 bacterial), Rhea release 141, ChEBI
release 253. The organic acid layer released as 2026.14.1 shares no anchor and
no reaction with this one.

The five open questions of §13 were **resolved by the maintainer on 2026-08-18**
and the layer was curated the same day. §13 records each decision with the
evidence behind it; §14 records what implementation changed.

Scope: decide whether the capacity to produce vitamins can be expressed under
the gifter ontology, at what boundaries, and which candidate traits the available
evidence actually supports.

The short answer is that this is the **largest layer gifter can currently curate
without a schema migration or an R change**, that its main difficulty is neither
ontology nor chemistry but a recurring evidence pattern this document names the
**orphan step** — a reaction that is certainly present and has no marker that
identifies it — and that the single most requested trait in the layer,
"produces vitamin B12", must be **refused as named** and replaced by four
narrower capabilities, because a genome that completes the corrin ring is not
thereby a producer of a cobamide the host can use.

Nineteen GIFTs are recommended across nine vitamins; twelve further
candidates are refused or deferred, each with the evidence that decided it.

---

## 1. Recommendation in one page

1. **No schema migration and no R change.** Everything the layer needs already
   exists: `route_reaction.required = 0` for non-evidenceable steps (four rows
   use it today), `gift_route.oxygen_requirement = 'aerobic'` (the third and so
   far unused value), multiple output anchors per GIFT, and the
   `biomass_essential` anchor facet that makes `gift_profile.auxotrophy_indicator`
   fire without being told about vitamins. §3.
2. **Curate nine vitamin capabilities** — B1, B2, B3, B5, B6, B7, B9, B12 and
   K2 — as **19 composable GIFTs**, not nine. Every split is at a branchpoint
   where genomes measurably differ, not at a convenience. §7.
3. **Adopt the orphan-step rule.** Where a reaction is required chemistry but no
   marker identifies it at the specificity of the step, curate it with
   `required = 0` and say so in the route notes. The alternative is measured:
   requiring the riboflavin phosphatase step drops riboflavin biosynthesis from
   7943 bacteria to 2682, and requiring the folate dihydroneopterin
   triphosphate pyrophosphatase drops folate from 5898 to 1634. Neither drop is
   biology. §5, §8.3.
4. **Refuse "vitamin B12 biosynthesis" as a single trait** and curate four:
   `corrin_ring_biosynthesis` (two routes, one aerobic and one anaerobic, the
   first use of `oxygen_requirement = 'aerobic'`), `cobinamide_biosynthesis`,
   `cobamide_nucleotide_loop_assembly`, and `dmb_biosynthesis_aerobic`. Only
   1081 of 10 151 bacteria complete the first three; only 538 also carry BluB,
   and **without a lower ligand the product is a cobamide, not vitamin B12**.
   3044 genomes carry the nucleotide loop and no ring at all: those are
   salvagers, and calling them producers would be the layer's worst error. §6.8.
5. **Cut folate at 4-aminobenzoate** and curate `paba_biosynthesis` separately.
   5898 bacteria complete the pterin branch and 5088 the pABA branch, and the
   two sets are not nested: 4099 complete both, 1799 the pterin branch only and
   989 the pABA branch only. pABA auxotrophy is a real and separately callable
   phenotype. The same cut adds `CHORISMATE`, which menaquinone also needs. §6.2.
6. **Cut thiamine into three GIFTs plus a salvage GIFT**, at HMP-P and THZ-P.
   The de novo layer completes in 4640 bacteria and the salvage layer in 3095,
   and salvage composes into de novo through the same two anchors rather than
   duplicating the ThiE condensation. §6.3.
7. **Cut NAD at nicotinate D-ribonucleotide**, giving
   `quinolinate_biosynthesis_aspartate`, `namn_biosynthesis_quinolinate`,
   `nad_biosynthesis_namn` and `namn_salvage_nicotinate`. Cutting now avoids
   re-cutting when salvage is curated, exactly as the amino acid proposal
   argued for L-aspartate 4-semialdehyde. §6.4.
8. **Do not curate cofactor activation.** Riboflavin to FAD, pantothenate to
   CoA, TMP to TPP and folate to polyglutamates are housekeeping steps whose
   presence tracks annotation rather than biology: the flavin kinase step is
   complete in all 18 reference genomes, including the six that cannot make
   riboflavin. The vitamin is the claim; the cofactor is not. §8.2.
9. **State the cofactor-anchor rule before the first vitamin anchor is added.**
   A cofactor may be declared an anchor only where the reaction *consumes* it as
   a substrate — BluB destroys FMNH2 to build the benzimidazole ring — and never
   where it is recycled catalytically. Without that rule, THF, PLP and NAD
   become input anchors of half the database and the anabolic acyclicity check
   collapses. §8.1.
10. **Refuse twelve candidates and record them**: vitamin C (0 of 10 151
    bacteria), the tryptophan route to NAD (55 bacteria; 490 of its 545
    completions are eukaryotes), cobalamin uptake (`btuBFCD` markers are
    Proteobacterial; the Bacteroidetes receptors that dominate the gut have no
    KO), biotin precursor supply, the anaerobic DMB route, the GMP-to-GTP
   phosphorylation (§13.1), and six more. §10.

The resulting layer is informative rather than universal. Scored across all
10 151 bacterial genomes, half complete four or fewer of the nine capabilities:
1087 genomes (10.7%) complete none, 228 (2.2%) complete all nine, and the rest
spread evenly between.

---

## 2. Scope: what counts as a vitamin here

"Vitamin" is a nutritional relation, not a chemical class or a capability, and
the relation is to a *consumer* that cannot make the compound. gifter models
neither consumers nor communities, so the layer needs a stated cut. This
proposal uses:

> a compound that is essential to bacterial or host metabolism, that a
> substantial fraction of bacteria cannot synthesise, and whose biosynthesis
> ends at a chemically defined product rather than at its own activated
> cofactor form.

Under that cut the layer is the eight B vitamins with bacterial biosynthesis
(B1 thiamine, B2 riboflavin, B3 niacin/NAD, B5 pantothenate, B6 pyridoxal
phosphate, B7 biotin, B9 folate, B12 cobalamin) plus **menaquinone (K2)**, which
is included because it is the one fat-soluble vitamin whose bacterial synthesis
is quantitatively relevant to a host and because 3838 bacteria encode it.

Five neighbours are deliberately outside it.

- **Vitamin C.** Both KEGG routes (M00114 plants, M00129 animals) complete in
  **zero** bacterial genomes. Refused on evidence, not on scope.
- **Vitamin E (tocopherol).** 88 bacterial completions of M00112, essentially
  all phototrophs. Deferred: real chemistry, no relevance to the host-associated
  communities gifter's curated content is aimed at.
- **Provitamin A (β-carotene).** 751 bacterial completions of M01045, again
  dominated by phototrophs, and the carotenoid layer needs its own proposal to
  decide whether the markers can name an end product. Deferred as a layer.
- **Heme, siroheme, lipoate, ubiquinone, molybdopterin.** Cofactors, not
  vitamins for any consumer gifter describes. Out of scope — but note that
  **uroporphyrinogen III**, added here as the input anchor of the corrin ring,
  is the exact branchpoint at which heme and siroheme leave, so this layer
  prepares that one without curating it.
- **Cofactor activation of the vitamins themselves** — FMN/FAD, CoA, TPP,
  folylpolyglutamate, PLP-from-pyridoxal. §8.2 argues these are not traits.

One inclusion needs defending. **B3 is curated as NAD biosynthesis**, not as
"niacin production", because the capability that matters genomically is whether
the genome needs an exogenous pyridine ring. The trait names what the chemistry
does; the nutritional reading is a derivation.

---

## 3. What the ontology and the runtime already support

Nothing in this layer requires a migration. Five things were checked against
`inst/schema/gifter.sql` and `R/evaluation.R`.

**`route_reaction.required = 0` exists and is used.** The column is
`INTEGER NOT NULL DEFAULT 1 CHECK (required IN (0, 1))`
(`inst/schema/gifter.sql:164`), `R/evaluation.R:376` counts only required
reactions towards completeness, and four curated rows already use it:
galactose mutarotase in `GAL_LELOIR`, acetylxylan esterase in
`XYLAN_SACCHARIFICATION`, pullulanase in `STARCH_SACCHARIFICATION`, and the
spontaneous acetoin step in `ACETOIN_ALS_BUDA`. That is the
mechanism §5 needs for orphan steps, and it keeps the step visible in
`trace_gift()` rather than deleting it from the biology.

**`oxygen_requirement = 'aerobic'` exists and has never been used.** The CHECK
admits `aerobic`, `anaerobic` and `independent` (`inst/schema/gifter.sql:154`);
the 62 curated routes use only the last two. The two corrin ring routes differ
in exactly this property and in nothing else the model records, which is what
the field was for.

**Multiple output anchors are already curated.** `fucose_degradation_isomerase`
declares two, so `thiamine_precursor_salvage` — two inputs, two outputs — needs
no new capability.

**`gift_profile.auxotrophy_indicator` already covers vitamins.** The view derives
it from `mode = 'anabolic'` plus an output anchor carrying
`biomass_essential = yes` (`inst/schema/gifter.sql:570`). Declaring the vitamin
anchors that way makes every GIFT in this layer an auxotrophy indicator without
a line of new logic — and it is the correct claim, because a genome that cannot
complete `biotin_biosynthesis` must import biotin.

**Rhea covers the whole layer.** One hundred EC numbers spanning every reaction
proposed here were queried against the Rhea API on 2026-08-18 and **all one
hundred returned at least one reaction**, including the two most obscure: BluB
(EC 1.13.11.79, `RHEA:27345`) and CbiZ (EC 3.5.1.90, `RHEA:23504`). Unlike the
polysaccharide and protein layers, no reaction here needs the nullable
`rhea_master` path. §11 lists representative identifiers.

Two additions are needed, and both are content, not schema:

| Table | Addition |
|---|---|
| `facet_terms.tsv` | `substrate_class = cofactor`; `physiological_role = vitamin_biosynthesis` (§13.2) |
| `anchors.tsv` | 30 new anchors, §7 |

---

## 4. What each source actually supplies

| Source | What it gives this layer | What it does not |
|---|---|---|
| **Rhea** | A reaction for all 100 ECs, including BluB and CbiZ | Nothing about which genes do it |
| **KEGG modules** | Pathway organisation for every vitamin, and the aerobic/anaerobic corrin distinction gifter wants to keep | Usable trait boundaries. Its `DEFINITION` expressions are **not** the pathway: M00125 defines riboflavin completeness without lumazine synthase or riboflavin synthase, M00119 defines pantothenate without PanC or PanD, and M00127 defines thiamine as ThiF+ThiS+ThiI, without ThiC, ThiG or ThiE. Importing module completeness would import those defects |
| **KEGG orthology** | Clean, reaction-accurate KOs for most steps of B1, B2, B3, B5, B6, B7, B9 and K2 | Any KO for four orphan steps (§5); any KO for the anaerobic DMB pathway; any KO for the Bacteroidetes corrinoid receptors; and correct assignment of **fused** genes (§6.8) |
| **ChEBI** | Anchor identity for all 24 new anchors | — |
| **InterPro / Pfam** | Nothing this layer can use for its hardest case. The obvious rescue for the fused corrin methyltransferases is a domain marker, and PF00590 is "Tetrapyrrole (Corrin/Porphyrin) Methylases" — one family covering CbiE, CbiF, CbiH, CbiL, CobM and diphthine synthase. It cannot say which step a protein performs, so under invariant 16 it licenses none of them |

The headline is the second row. **KEGG's module definitions are not curatable
boundaries in this layer**, and the failure is not subtle: three of the nine
vitamins have a module whose `DEFINITION` omits the step that gives the pathway
its name.

---

## 5. The test

The protein and SCFA layers each added a clause to the same test. This layer
adds a third, because its characteristic failure is new: the marker is missing
not for a *trait* but for a single *step* inside an otherwise well-evidenced
route.

```text
does a marker exist whose specificity matches the product named in the trait?
        |
        +-- no  --> refuse the trait
        |
        +-- yes --> does that marker's direction match the claim?
                        |
                        +-- no --> refuse, or state the ambiguity in the claim
                        |
                        +-- yes --> is every required step of the route
                                    evidenced at the specificity of the step?
                                        |
                                        +-- yes --> curate
                                        |
                                        +-- no  --> is the unevidenced step
                                        |           chemistry that no genome
                                        |           completing the rest could
                                        |           be missing?
                                        |
                                        +-- yes --> curate with required = 0
                                        |           and record why
                                        |
                                        +-- no  --> the step is a real
                                                    biological alternative;
                                                    curate it as a route or
                                                    system alternative, or
                                                    refuse the trait
```

The third clause matters because the two wrong answers are both damaging in
ways the model cannot see afterwards. Requiring an unevidenceable step turns a
missing annotation into a false negative for the whole capability — the effect
the compartment section of the architecture guide already warns about for
transport reactions. Deleting the step from the route hides real chemistry and
makes `trace_gift()` describe a pathway that does not exist.

Four orphan steps were found, and one candidate that looked like an orphan and
was not:

| Step | EC | Best KO evidence | Bacteria with it | Effect if required |
|---|---|---|---|---|
| Riboflavin: 5-amino-6-(5-phospho-D-ribitylamino)uracil phosphatase | 3.1.3.104 | six KOs, all lineage-restricted (K22912 has **0** bacterial members) | 2682 | riboflavin 7943 → 2682 |
| Folate: dihydroneopterin triphosphate pyrophosphatase | 3.6.1.67 | K08310 (1695), K19965 (47) | 1742 | folate 5898 → 1634 |
| Menaquinone: MenH, and DHNA-CoA thioesterase | 4.2.99.20, 3.1.2.28 | K08680, K19222 | Proteobacteria-biased | menaquinone 3109 → 1355 |
| Thiamine: ThiS/ThiF sulfur carrier | 2.7.7.73 | K03148 (1724), K03154 | 1724 | thiazole branch 5396 → 1554 |
| **Not an orphan:** folate dihydroneopterin phosphatase | 3.1.3.1 | K01077/K01113, alkaline phosphatase | 3202 | **refuse the marker** |

The last row is the counter-example that keeps the rule honest. A generic
alkaline phosphatase is not evidence of a folate step; accepting it would damage
every other trait it also matches, which is invariant 16 exactly. The step is
handled as an orphan (`required = 0`), *not* by widening the marker.

The ThiS/ThiF row deserves its own note. It is an orphan for a second reason:
ThiF is homologous to MoeB and ThiI also serves tRNA thiolation, so those
markers are not specific to thiamine even where they are present. They neither
gate the claim nor add to it, and the curated thiazole system requires ThiG
alone.

---

## 6. Outcome when the test was applied, 2026-08-18

Prevalence is the number of the 10 151 KEGG **bacterial** genomes completing the
route as this proposal would curate it — computed from `link/genes/ko:` sets
intersected locally, not from KEGG module completeness. Where KEGG's own module
count differs materially, both are given.

### 6.1 B2 riboflavin — curate, one GIFT

`riboflavin_biosynthesis`: GTP + D-ribulose 5-phosphate → riboflavin, via RibA,
RibD (deaminase and reductase), RibB, RibH, RibE, with the phosphatase step at
`required = 0`. **7943 bacteria (78.2%)**; KEGG's M00125 says 2664, because its
definition stops the pathway before lumazine synthase and then demands a flavin
kinase. Bifunctional RibAB (K14652) and RibD-fusion (K11752) are accepted as
alternative systems, which is what the enzyme-system layer is for.

Boundary: **end at riboflavin, not FAD** (§8.2).

### 6.2 B9 folate — curate, two GIFTs

`folate_biosynthesis`: GTP + 4-aminobenzoate → tetrahydrofolate, via FolE, FolB,
FolK, FolP, FolC, FolA, with dihydroneopterin triphosphate pyrophosphatase and
dihydroneopterin phosphatase at `required = 0`. **5898 (58.1%)**.

`paba_biosynthesis`: chorismate → 4-aminobenzoate, via PabAB/PabB and PabC.
**5088 (50.1%)**. 4099 genomes complete both branches, 1799 only the pterin
branch, and 989 only the pABA branch.

The cut is not cosmetic. Among the reference genomes, *Bifidobacterium longum*,
*B. adolescentis*, *Lactiplantibacillus plantarum*, *Limosilactobacillus
reuteri* and *Enterococcus faecalis* complete the pterin branch and **not** the
pABA branch. A single GIFT would call all five negative and lose the distinction
between "cannot make folate" and "cannot make one of its two halves".

PabA is deliberately excluded from the required components: it is a glutamine
amidotransferase interchangeable with TrpG, so it is neither specific nor
limiting.

### 6.3 B1 thiamine — curate, four GIFTs

| GIFT | Boundaries | Bacteria |
|---|---|---|
| `hmp_phosphate_biosynthesis` | AIR → HMP-P (ThiC, ThiD) | 5963 |
| `thiazole_phosphate_biosynthesis` | DXP + glycine or tyrosine → THZ-P (ThiG, ThiH/ThiO) | 5396 |
| `thiamine_phosphate_biosynthesis` | HMP-P + THZ-P → TMP (ThiE, or ThiDE/ThiDN fusion) | 7916 |
| `thiamine_precursor_salvage` | HMP + HET → HMP-P + THZ-P (ThiD, ThiM) | 3095 |

De novo TMP — the composition of the first three — completes in **4640 (45.7%)**.

Two boundary decisions. First, **end at thiamine phosphate, not TPP**: ThiL
(K00946) is absent from the KEGG annotation of ten of the eighteen reference
genomes, including organisms that certainly make TPP, so requiring it would
convert an annotation gap into a thiamine auxotrophy call. Second, **salvage is a
separate GIFT that composes through HMP-P and THZ-P**, so ThiE is curated once;
duplicating it into a salvage route would violate invariant 8.

### 6.4 B3 NAD — curate, four GIFTs, refuse the tryptophan route

| GIFT | Boundaries | Bacteria |
|---|---|---|
| `quinolinate_biosynthesis_aspartate` | L-aspartate → quinolinate (NadB/NadA) | 6398 |
| `namn_biosynthesis_quinolinate` | quinolinate → NaMN (NadC) | — |
| `nad_biosynthesis_namn` | NaMN → NAD+ (NadD, NadE) | 6791 for the pair |
| `namn_salvage_nicotinate` | nicotinate → NaMN (PncB) | 6921 with the trunk |

Cutting at NaMN now, rather than curating `quinolinate → NAD` and re-cutting
when salvage arrives, follows the precedent set for L-aspartate 4-semialdehyde
in the amino acid proposal. It also avoids duplicating NadD and NadE across a de
novo and a salvage GIFT.

`quinolinate_biosynthesis_aspartate` composes with the existing `ASPARTATE`
anchor, which is the first time this layer touches curated content.

**Refuse the tryptophan route (M00912).** 545 completions, of which 490 are
eukaryotes and 55 bacteria. Recorded, not curated.

### 6.5 B5 pantothenate — curate, one GIFT

`pantothenate_biosynthesis`: 2-oxoisovalerate + L-aspartate → (R)-pantothenate,
via PanB, ketopantoate reductase, PanD, PanC. **5143 (50.7%)** when the
reductase reaction accepts either PanE (K00077) or IlvC (K00053), against 3435
with PanE alone. IlvC is a genuine non-homologous replacement for that step, not
a widened marker: it is accepted for the *reaction*, and the route's other three
reactions carry the pathway specificity.

Note that KEGG's M00119 defines this module as BCAA aminotransferase + PanB +
PanE, which contains neither PanC nor PanD and therefore never reaches
pantothenate.

### 6.6 B6 pyridoxal phosphate — curate, two GIFTs

`plp_biosynthesis_r5p`: D-ribose 5-phosphate + D-glyceraldehyde 3-phosphate +
L-glutamine → PLP, via the PdxS/PdxT synthase complex. **2848 (28.1%)**.

`plp_biosynthesis_dxp`: D-erythrose 4-phosphate + DXP → PLP, six steps.
**1351 (13.3%)**.

These are two GIFTs and not two routes of one GIFT, because their input anchors
differ — the same reason `methionine_biosynthesis_transsulfuration` and
`..._sulfhydrylation` are separate. The two sets are near-disjoint and together
cover 4199 genomes.

The DXP route shares phosphoserine aminotransferase (K00831) with the curated
`serine_biosynthesis`. That is a shared marker on a shared reaction, which the
model handles: markers are evidence for components, and one KO legitimately
evidences components in two GIFTs.

### 6.7 B7 biotin — curate the core, refuse the precursor supply

`biotin_biosynthesis`: pimeloyl-ACP/CoA → biotin, via BioF, BioA, BioD, BioB.
**5294 (52.2%)**, and cleanly discriminating among the reference genomes:
*Escherichia*, *Salmonella*, *Bacillus*, *Bacteroides* and *Akkermansia*
positive; every *Bifidobacterium* and *Lactobacillus* negative.

**Refuse the precursor supply trait** (malonyl-ACP → pimeloyl-ACP). BioC/BioH is
one of at least four non-homologous solutions (BioH, BioG, BioK, BioJ, and the
BioI and BioW routes KEGG curates as M00573 and M00577, complete in 42 and 328
genomes). Curating "biotin from fatty acid metabolism" would need a marker set
that does not exist; curating only the BioC/BioH version would silently equate
the trait with the Proteobacterial solution.

### 6.8 B12 — refuse the trait as named, curate four

This is the hardest case in the layer and the reason the proposal exists in this
shape. A single `cobalamin_biosynthesis` GIFT is refused, on four independent
grounds, each measured.

**(a) Most of the pathway's prevalence is salvage, not synthesis.** 4139
bacteria (40.8%) complete the nucleotide loop; **3044 of them have no corrin
ring capability at all**. *Escherichia coli* is the textbook case and is in that
set: it assembles cobalamin from imported cobinamide and cannot build a ring.
Calling those 3044 genomes B12 producers would be the layer's worst error.

**(b) The ring itself splits by oxygen, and the schema already says so.** The
anaerobic route (uroporphyrinogen III → cobyrinate a,c-diamide, cobalt inserted
early) completes in 1017 genomes; the aerobic route (cobalt inserted late, via
CobG/CobF/CobNST) in 340. Same boundaries, different chemistry, different
oxygen requirement: **one GIFT, two routes**, and the first curated use of
`oxygen_requirement = 'aerobic'`.

**(c) A complete cobamide is not vitamin B12.** The lower ligand decides. Of the
1081 genomes completing ring + cobinamide + nucleotide loop, only **538 also
carry BluB**, the O2-dependent DMB synthase. *Limosilactobacillus reuteri*
completes the whole corrinoid path in this analysis and has no BluB — consistent
with its documented production of a cobamide rather than of cobalamin. The
honest trait names the chemistry: `cobamide_nucleotide_loop_assembly` takes DMB
as an input anchor, and `dmb_biosynthesis_aerobic` (BluB, 2027 genomes) is the
separate capability that supplies it. A genome negative for BluB may still make
DMB anaerobically through the *bza* cluster — which has **no KO at all**, and is
therefore refused and recorded rather than modelled.

**(d) Recall on the ring is poor, and the cause is gene fusion.** Of the
eighteen reference genomes, only *Salmonella* Typhimurium and *L. reuteri*
complete the ring. *Propionibacterium freudenreichii* — the organism industrial
B12 comes from — is called incomplete, missing cobalt chelatase, CbiH and CbiG.
Its genome has all three: `PFREUD_07710` is annotated `cysG_cbiX` and
`PFREUD_07700` is annotated `cobJ_cbiE_cbiG_cbiH`, two **fusion proteins** that
KEGG does not assign to the component KOs. The obvious rescue is a domain
marker, and §4 shows why it fails: every cobalt-precorrin methyltransferase is
PF00590.

The recommendation is nonetheless to curate the ring, because gifter's incomplete
output is designed for exactly this: the call names the closest route and the
three missing reactions, which is a true and useful statement about the
evidence. The limitation belongs in the GIFT description and in
`database_changes.tsv`, not in a silent widening of the markers.

| GIFT | Boundaries | Bacteria |
|---|---|---|
| `corrin_ring_biosynthesis` | uroporphyrinogen III → cobyrinate a,c-diamide, 2 routes | 1017 anaerobic + 340 aerobic |
| `cobinamide_biosynthesis` | cobyrinate a,c-diamide → adenosylcobinamide (CbiP/CobQ, CobC/CobD, adenosyltransferase) | 4428 for the CbiP/CobD pair |
| `cobamide_nucleotide_loop_assembly` | adenosylcobinamide + DMB → cobalamin (CobU, CobT, CobS) | 4139 |
| `dmb_biosynthesis_aerobic` | FMNH2 + O2 → DMB (BluB) | 2027 |

### 6.9 K2 menaquinone — curate, one GIFT, two routes

`menaquinone_biosynthesis`: chorismate → menaquinone. Classic *men* route and
futalosine *mqn* route share both anchors, so this is one GIFT with two routes —
the cleanest non-homologous replacement in the layer.

**3838 bacteria (37.8%)**: 3109 by the classic route as curated here, 729 by
futalosine. The strict reading of KEGG's M00116 gives 1355, and the difference
is two orphan steps (MenH, DHNA-CoA thioesterase) plus one marker decision:
the isochorismate synthase reaction accepts **EntC (K02361) as well as MenF
(K02552)**. *Bacteroides thetaiotaomicron* is the worked case — its
`BT_4700` is annotated `entC`, and with MenF alone the genome is called
menaquinone-negative, which it is not.

The GIFT ends at menaquinone and declares no demethylmenaquinone anchor. MenG
(K03183) is a required reaction, and the cost of requiring it is 93 genomes:
3202 bacteria complete the classic route through the polyprenyltransferase and
3109 of them also carry MenG. Those 93 are reported as a missing terminal
methylation, which is the right answer — DMK is a functional quinone in some
anaerobic respiration, but that is a redox claim this layer does not make, and
the vitamin the host obtains is menaquinone. §13.3.

The isochorismate decision is worth stating as a general principle, because it
looks like a violation of invariant 16 and is its mirror image: **EntC and MenF
catalyse the same reaction**. A marker may be accepted when it is accurate at the level of
the *reaction* even though its pathway assignment is elsewhere; what invariant 16
forbids is a marker whose *chemistry* is broader than the claim. Route
completeness supplies the pathway specificity.

---

## 7. The proposed GIFT set and its composition graph

Nineteen GIFTs, all `gift_type = metabolic`, all `mode = anabolic`.

```text
B2    GTP + ribulose-5P            -> [riboflavin_biosynthesis]            -> RIBOFLAVIN

B9    chorismate                   -> [paba_biosynthesis]                  -> PABA
      GTP + PABA                   -> [folate_biosynthesis]                -> THF

K2    chorismate                   -> [menaquinone_biosynthesis]           -> MENAQUINONE
                                      (men route | futalosine route)

B1    AIR                          -> [hmp_phosphate_biosynthesis]         -> HMP_P
      DXP + glycine/tyrosine       -> [thiazole_phosphate_biosynthesis]    -> THZ_P
      HMP + HET                    -> [thiamine_precursor_salvage]         -> HMP_P + THZ_P
      HMP_P + THZ_P                -> [thiamine_phosphate_biosynthesis]    -> TMP

B3    L-aspartate                  -> [quinolinate_biosynthesis_aspartate] -> QUINOLINATE
      QUINOLINATE                  -> [namn_biosynthesis_quinolinate]      -> NAMN
      nicotinate                   -> [namn_salvage_nicotinate]            -> NAMN
      NAMN                         -> [nad_biosynthesis_namn]              -> NAD

B5    2-oxoisovalerate + aspartate -> [pantothenate_biosynthesis]          -> PANTOTHENATE

B6    R5P + G3P + glutamine        -> [plp_biosynthesis_r5p]               -> PLP
      E4P + DXP                    -> [plp_biosynthesis_dxp]               -> PLP

B7    pimeloyl-ACP/CoA             -> [biotin_biosynthesis]                -> BIOTIN

B12   uroporphyrinogen III         -> [corrin_ring_biosynthesis]           -> COBYRINATE_DIAMIDE
                                      (aerobic route | anaerobic route)
      COBYRINATE_DIAMIDE           -> [cobinamide_biosynthesis]            -> ADENOSYLCOBINAMIDE
      FMNH2 + O2                   -> [dmb_biosynthesis_aerobic]           -> DMB
      ADENOSYLCOBINAMIDE + DMB     -> [cobamide_nucleotide_loop_assembly]  -> COBALAMIN
```

Five edges are internal to the layer and derive from shared anchors: pABA into
folate, HMP_P and THZ_P into thiamine phosphate (from both the de novo and the
salvage GIFT), quinolinate and nicotinate into NaMN, NaMN into NAD, and the
corrin chain into the nucleotide loop.

`dmb_biosynthesis_aerobic` is deliberately *not* joined to
`riboflavin_biosynthesis`. BluB consumes FMNH2, not riboflavin, and §8.2
declines to curate the flavin kinase step, so `FMNH2` is declared as an
input-only anchor with no producer — the same treatment `HOMOCYSTEINE` already
receives. It is nonetheless the layer's one legitimate cofactor input, because
BluB destroys the flavin to build the benzimidazole ring (§8.1).

Two anchors cross into existing curated content: `ASPARTATE` feeds the B3 and
B5 GIFTs, and `GLUTAMINE` feeds `plp_biosynthesis_r5p`.

Anchors to add (30), none of which collides with the 54 curated today. The ChEBI
identifiers below are provisional: curation must select the Rhea microspecies,
as the existing anchor rows do.

| Anchor | Role in the layer | Provisional ChEBI |
|---|---|---|
| `GTP` | input of riboflavin and folate; **input-only**, §13.1 | to assign |
| `CHORISMATE` | input of pABA and menaquinone | CHEBI:17333 |
| `PABA` | folate ⟷ pABA junction | CHEBI:17836 |
| `THF` | output of folate | CHEBI:20506 |
| `RIBOFLAVIN` | output of B2 | CHEBI:17015 |
| `FMNH2` | input-only anchor of `dmb_biosynthesis_aerobic` | to assign |
| `AIR`, `DXP`, `HMP_P`, `THZ_P`, `TMP`, `HMP`, `HET` | thiamine layer | to assign |
| `PANTOTHENATE` | output of B5 | CHEBI:29032 |
| `OXOISOVALERATE` | input of B5 | to assign |
| `PLP` | output of both B6 GIFTs | CHEBI:18405 |
| `R5P`, `E4P` | inputs of the B6 GIFTs | to assign |
| `PIMELOYL_ACP` | input of biotin | to assign |
| `BIOTIN` | output of biotin | CHEBI:15956 |
| `QUINOLINATE`, `NAMN`, `NAD`, `NICOTINATE` | B3 layer | CHEBI:132942, CHEBI:57502, to assign, to assign |
| `UROGEN_III`, `COBYRINATE_DIAMIDE`, `ADENOSYLCOBINAMIDE`, `COBALAMIN`, `DMB` | B12 layer | CHEBI:15437, to assign, to assign, CHEBI:30411, CHEBI:15890 |
| `MENAQUINONE` | output of K2 | CHEBI:16374 |

Facets: every output vitamin anchor gets `biomass_essential = yes` and
`resource_origin = central_metabolism`; every GIFT gets
`substrate_class = cofactor` — the facet the build enforces as single-valued —
plus `physiological_role = biosynthesis` and `vitamin_biosynthesis`, which the
build allows to be multi-valued. Both words the layer needs are kept, each on
the facet where it is true. §13.2.

**Acyclicity.** All 19 are anabolic, so the mode-scoped cycle check applies to
all of them at once. Neither `ASPARTATE` nor `GLUTAMINE` is an output anchor of
any curated GIFT, so the layer creates no anabolic cycle.

---

## 8. Three architectural decisions

### 8.1 A cofactor may be an anchor only where it is consumed

This is the decision that must be taken before the first vitamin anchor is
added, because it cannot be retrofitted.

The architecture guide already says not to add cofactors as anchors. This layer
*produces* cofactors, so it needs a sharper rule:

> A cofactor may be declared an input anchor only where the reaction consumes it
> as a substrate and it does not leave the reaction chemically unchanged. It may
> never be declared an input anchor where it is recycled catalytically.

FMNH2 → BluB passes: the dimethylbenzimidazole ring is built *from* the flavin,
which is destroyed. It is declared input-only, so it adds a boundary without
adding an edge. THF in serine hydroxymethyltransferase fails: it carries a
one-carbon unit and comes back. So does PLP in every transaminase, NAD in every
dehydrogenase, and CoA in most acyl chemistry.

Without the rule, the curated `glycine_biosynthesis` would want `THF` as an
input anchor, `folate_biosynthesis` declares it as an output, and the anabolic
graph acquires an edge that says folate biosynthesis is a precursor of glycine
biosynthesis. Extend that to PLP and NAD and every anabolic GIFT in the database
becomes downstream of this layer — no longer a graph of biosynthetic
composition, but a graph of cofactor dependence, which gifter explicitly does not
model. The `HOMOCYSTEINE` input-only precedent is the same instinct applied to a
different problem.

### 8.2 The claim ends at the vitamin, not at the cofactor

Every vitamin in the layer has an activation step: riboflavin → FMN → FAD,
pantothenate → CoA, TMP → TPP, folate → polyglutamate, pyridoxal → PLP.
None is curated, for a reason that is measurable rather than aesthetic: the
flavin kinase / FAD synthetase step is complete in **all eighteen** reference
genomes, including the six that cannot make riboflavin. A trait complete in
every genome partitions nothing and carries no information; what it does carry
is annotation noise, since its absence in any genome would be an annotation gap
rather than a biological fact.

The one apparent exception, PLP, is not one: PLP *is* the product of both B6
routes, and there is no separate vitamin form to cut at.

TPP deserves the explicit note made in §6.3: ThiL's patchy annotation is
precisely the annotation-gap failure mode, and it is avoided by ending at TMP.

### 8.3 Orphan steps are curated with `required = 0`, never deleted and never widened

Stated as a rule for the source tables:

- the reaction row is created, with its Rhea master and its cross-references;
- `route_reaction.required = 0`;
- `gift_route.description` states which step is not gating and why;
- if a marker of the correct specificity later appears, flipping the column to 1
  is a one-row content change with a changelog entry.

The three wrong alternatives, for the record: requiring an unevidenceable step
(riboflavin loses 5261 genomes), deleting the step (the route describes
chemistry that does not exist), or widening the marker until something matches
(alkaline phosphatase for a folate step, which damages every other trait
alkaline phosphatase touches).

---

## 9. Validation against eighteen reference genomes

Calls computed with the curated definitions proposed above, over KEGG KO
assignments as of 2026-08-18. `+` complete, `.` incomplete.

```text
GIFT                                 eco stm bsu bth bfr bvu fpr ere rim blo bad lpl lre amu efa pfr cdf lla
riboflavin_biosynthesis               +   +   +   +   +   +   .   +   .   .   .   .   +   +   .   +   +   +
folate_biosynthesis                   +   +   +   +   +   +   .   .   .   +   +   +   +   .   +   +   .   +
paba_biosynthesis                     +   +   .   +   +   +   .   .   .   .   .   .   .   +   .   +   +   +
hmp_phosphate_biosynthesis            +   +   +   +   +   +   +   +   +   +   .   .   .   +   .   +   +   .
thiazole_phosphate_biosynthesis       +   +   +   +   +   +   .   +   +   .   .   .   .   +   .   +   +   .
thiamine_phosphate_biosynthesis       +   +   +   +   +   +   +   +   +   .   +   +   +   +   +   +   +   +
thiamine_precursor_salvage            +   +   +   .   .   .   +   +   +   +   +   +   +   +   +   +   +   +
pantothenate_biosynthesis             +   +   +   +   +   +   .   +   +   .   .   .   .   +   +   .   .   .
plp_biosynthesis_r5p                  .   .   +   .   .   .   .   +   .   +   +   .   .   .   .   +   .   .
plp_biosynthesis_dxp                  +   +   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .
biotin_biosynthesis                   +   +   +   +   +   .   .   .   .   .   .   .   .   +   .   .   .   .
quinolinate_biosynthesis_aspartate    +   +   +   +   +   +   .   +   +   +   .   .   .   +   .   +   +   .
nad_biosynthesis_namn                 +   +   +   +   +   +   +   +   +   +   +   +   +   +   +   +   +   +
namn_salvage_nicotinate               +   +   +   +   +   .   +   +   +   +   +   +   +   .   +   +   +   +
menaquinone_biosynthesis              +   +   +   +   +   +   .   .   .   .   .   .   .   +   .   +   .   .
corrin_ring_biosynthesis              .   +   .   .   .   .   .   .   .   .   .   .   +   .   .   .   .   .
cobinamide_biosynthesis               .   +   .   .   +   +   +   +   .   .   .   .   +   +   .   +   .   .
cobamide_nucleotide_loop_assembly     +   +   .   .   +   +   .   +   +   .   .   .   +   +   .   +   +   .
dmb_biosynthesis_aerobic              .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .

eco Escherichia coli K-12   stm Salmonella Typhimurium LT2   bsu Bacillus subtilis 168
bth Bacteroides thetaiotaomicron   bfr B. fragilis   bvu Phocaeicola vulgatus
fpr Faecalibacterium prausnitzii   ere Agathobacter rectalis   rim Roseburia intestinalis
blo Bifidobacterium longum   bad B. adolescentis   lpl Lactiplantibacillus plantarum
lre Limosilactobacillus reuteri   amu Akkermansia muciniphila   efa Enterococcus faecalis
pfr Propionibacterium freudenreichii   cdf Clostridioides difficile   lla Lactococcus lactis
```

What the table gets right, and it is worth checking these before accepting the
layer: *E. coli* assembles cobalamin from cobinamide but cannot make the ring;
*B. thetaiotaomicron* has neither, and is a corrinoid consumer; *L. reuteri*
completes the corrinoid path without BluB; the two *Bifidobacterium* genomes
make folate but not pABA; the butyrate producers *F. prausnitzii*,
*A. rectalis* and *R. intestinalis* are folate-negative; the biotin calls follow
the known split between the Bacteroidetes and the gut Firmicutes; and the two
B6 routes partition the panel almost perfectly.

What it gets wrong, and this must be recorded with the content:
*P. freudenreichii* is corrin-ring-negative because of two fusion proteins
(§6.8d), and `menaquinone_biosynthesis` calls *C. difficile* negative.

The `dmb_biosynthesis_aerobic` row is empty across the panel and complete in
2027 bacteria overall — the panel is gut-anaerobe-weighted and BluB is an
oxygen-dependent enzyme, which is the expected result rather than a defect.

---

## 10. Refusals

Recorded as results, in the form `database_changes.tsv` expects.

| # | Refused | Evidence | Why |
|---|---|---|---|
| 1 | `cobalamin_biosynthesis` as one trait | 3044 of 4139 nucleotide-loop genomes have no ring | Would call salvagers producers |
| 2 | Vitamin C, both routes | 0 of 10 151 bacteria complete M00114 or M00129 | No bacterial chemistry to curate |
| 3 | NAD from tryptophan | 545 completions, 490 eukaryotic, 55 bacterial | Not a bacterial capability at gifter's scope |
| 4 | Biotin precursor supply | ≥4 non-homologous solutions; BioI 42 and BioW 328 genomes | No marker set spans the trait |
| 5 | Anaerobic DMB (*bza*) | no KO for any *bza* gene | Unevidenceable; makes BluB-negative calls provisional |
| 6 | Cobalamin uptake (`btuBFCD`) | 734 genomes, Proteobacteria-biased; *B. thetaiotaomicron* carries none of the three | The dominant gut corrinoid importers would be called negative |
| 7 | Alkaline phosphatase as folate evidence | K01077 in 3202 bacteria, generic activity | Invariant 16 |
| 8 | Cofactor activation (FAD, CoA, TPP, folylpolyglutamate) | flavin kinase complete in 18 of 18 reference genomes | A trait that partitions nothing |
| 9 | Vitamin E, provitamin A | 88 and 751 bacterial completions, phototroph-dominated | Deferred as their own layer, not refused on evidence |
| 10 | Corrinoid remodelling (`cbiZ`) | 170 bacteria, single KO, clean Rhea | Deferred: real but narrow; revisit with the transport layer |
| 11 | "Vitamin provision" / "B12 producer" as a GIFT | — | Invariant 18: an ecological relation, to be derived from typed GIFTs and `gift_profile` |
| 12 | `gtp_biosynthesis_gmp` (GMP → GDP → GTP) | Gmk in 9625 bacteria, Ndk in 8897, both in 8541 | Housekeeping phosphorylation the architecture guide already excludes; §13.1 |

Refusal 11 is the one users will push back on, and the answer is that the layer
already supplies the parts: `auxotrophy_indicator` names the genomes that must
import a vitamin, and a producer/consumer summary is a derivation over the same
anchors — not a primary trait.

---

## 11. Identifiers

All 100 ECs queried returned Rhea reactions. Representative masters, one per
GIFT, for the curation to start from:

| GIFT | Step | EC | Rhea |
|---|---|---|---|
| `riboflavin_biosynthesis` | lumazine synthase | 2.5.1.78 | RHEA:26152 |
| | riboflavin synthase | 2.5.1.9 | RHEA:20772 |
| `folate_biosynthesis` | dihydropteroate synthase | 2.5.1.15 | RHEA:19949 |
| | dihydrofolate reductase | 1.5.1.3 | RHEA:15009 |
| `paba_biosynthesis` | ADC synthase / lyase | 2.6.1.85 / 4.1.3.38 | RHEA:11672 / RHEA:16201 |
| `hmp_phosphate_biosynthesis` | ThiC | 4.1.99.17 | RHEA:24840 |
| `thiazole_phosphate_biosynthesis` | ThiG | 2.8.1.10 | RHEA:26297 |
| `thiamine_phosphate_biosynthesis` | ThiE | 2.5.1.3 | RHEA:22328 |
| `thiamine_precursor_salvage` | ThiM | 2.7.1.50 | RHEA:24212 |
| `pantothenate_biosynthesis` | PanC | 6.3.2.1 | RHEA:10912 |
| `plp_biosynthesis_r5p` | PdxST | 4.3.3.6 | RHEA:31507 |
| `plp_biosynthesis_dxp` | PdxJ | 2.6.99.2 | (queried, covered) |
| `biotin_biosynthesis` | BioB | 2.8.1.6 | RHEA:22060 |
| `quinolinate_biosynthesis_aspartate` | NadA | 2.5.1.72 | RHEA:25888 |
| `namn_biosynthesis_quinolinate` | NadC | 2.4.2.19 | RHEA:12733 |
| `nad_biosynthesis_namn` | NadE | 6.3.5.1 | RHEA:24384 |
| `namn_salvage_nicotinate` | PncB | 6.3.4.21 | RHEA:36163 |
| `corrin_ring_biosynthesis` | CbiK/CbiX | 4.99.1.3 | RHEA:15893 |
| | CbiA/CobB | 6.3.5.11 | RHEA:26289 |
| `cobinamide_biosynthesis` | CbiP/CobQ | 6.3.5.10 | RHEA:23256 |
| `cobamide_nucleotide_loop_assembly` | CobT | 2.4.2.21 | RHEA:11196 |
| | CobS | 2.7.8.26 | RHEA:16049 |
| `dmb_biosynthesis_aerobic` | BluB | 1.13.11.79 | RHEA:27345 |
| `menaquinone_biosynthesis` | MenB | 4.1.3.36 | RHEA:26562 |
| | MqnD | 4.1.99.29 | RHEA:33087 |

KEGG module cross-references, with the relation each would carry in
`gift_xrefs.tsv`: M00125 `overlaps` (riboflavin), M00126 `superset_of` (folate,
which absorbs pABA), M00127/M00895 `overlaps` (thiamine), M00119 `superset_of`
(pantothenate), M00124 and M00916 `equivalent` (B6), M00123 `equivalent`
(biotin), M00115 `superset_of` (B3, split at NaMN), M00924/M00925 `equivalent`
(corrin ring), M00122 `superset_of` (split into cobinamide and loop), M00116 and
M00930/M00931 `overlaps` (menaquinone).

---

## 12. Cost, risk, and what to build first

**Cost.** 19 GIFTs, 30 anchors, ~26 routes, ~95 reactions, ~110 enzyme systems,
~130 components, ~150 markers. Against 2026.14.1 that is ~40% growth in GIFTs
(48 → 67), ~56% in anchors (54 → 84) and ~80% in reactions (118 → ~213) — the
largest single content release the database would have taken.

**Risks, in order.**

1. *Recall on the corrin ring.* Documented in §6.8d and unavoidable with KO
   evidence. Mitigation is honesty in the GIFT description and the changelog.
2. *The orphan-step rule being applied too easily.* Four steps qualify here.
   The test in §5 requires that no genome completing the rest of the route could
   plausibly lack the step; that clause is what keeps it from becoming a way to
   make any inconvenient reaction optional.
3. *Anchor inflation.* 30 anchors grows the anchor table by more than half.
   Each is a branchpoint, a stable product, or an environmental precursor.
   Several — `GTP`, `FMNH2`, `R5P`, `E4P`, `AIR`, `DXP`, `PIMELOYL_ACP`,
   `UROGEN_III` — are declared input-only and have no producer GIFT, which is a deliberate boundary rather than a gap (§13.1, §13.4) and is
   the same treatment `HOMOCYSTEINE` already receives.
4. *The layer is not yet connected to a consumer.* No vitamin transport GIFT is
   evidenceable (refusal 6), so `cross_feeding_output` stays 0 for the whole
   layer, exactly as it does for SCFAs. Vitamin sharing is the most interesting
   thing about these traits ecologically, and gifter still cannot say it.

**Build order, if accepted.** B2, B9 + pABA, and B7 first: they are the largest,
cleanest, most discriminating traits and they exercise the orphan-step rule once
each. B1 and B3 next, because they add the multi-anchor and trunk-cutting
patterns. B12 last, with its four GIFTs, its two-route oxygen split, and its
documented recall limitation — it is the trait most worth having and the one
whose curation notes will take the longest to write.

---

## 13. Decisions on the open questions

Resolved by the maintainer on 2026-08-18. Each decision is recorded with the
evidence that was gathered to answer it, because these are boundary claims and
will need defending later.

### 13.1 `GTP` is an anchor, and the GMP → GTP link stays open

**Decision: accept `GTP` as an input anchor; do not curate a GIFT linking it to
`GMP`.** The link is left open deliberately, and the refusal is recorded (§10,
row 12).

The question was whether `guanylate_biosynthesis` should be joined to the
vitamin layer by a `GMP → GTP` GIFT. Three things argue against it, and the
first is decisive.

*The architecture guide has already decided this, for adenylate.* "Adenylate
biosynthesis stops at AMP rather than automatically continuing through ADP and
ATP: phosphorylation is shared metabolism and AMP has already established
adenylate identity" (`inst/doc/architecture.md:524`). A `GMP → GTP` GIFT asserts
the opposite for guanylate, and the two statements cannot both be curated.

*The evidence makes it an uninformative trait with false negatives.* Guanylate
kinase (K00942) is in 9625 of 10 151 bacteria and nucleoside-diphosphate kinase
(K00940) in 8897; 8541 carry both. The GIFT would therefore be complete in 84%
of bacteria and, worse, its ~1600 negatives would be dominated by genomes whose
Ndk role is filled by another kinase — the orphan-step failure of §5 in a trait
where the whole trait is the orphan. Ndk is also base-generic: it phosphorylates
every NDP, so it adds no guanylate specificity to the claim.

*It is the same question as §13.4, on a different molecule.* Skipping the flavin
kinase step and skipping the guanylate kinase step are one decision about
housekeeping activation chemistry; answering them differently would leave the
database inconsistent.

**The gap already exists in curated content, and is the precedent.**
`pyrimidine_core_biosynthesis` outputs `UMP`, `cytidylate_biosynthesis` consumes
`UTP`, and nothing curated joins them. The vitamin layer's `GTP` is that
situation a second time, and treating them alike is the consistent answer.

*If this is ever overridden*, the change is symmetric or it is nothing: closing
`GMP → GTP` without also closing `UMP → UTP` would make the graph inconsistent
in a way a user would reasonably read as biology. The two GIFTs would be
`gtp_biosynthesis_gmp` (Gmk, `RHEA:20780`, plus Ndk) and `utp_biosynthesis_ump`
(PyrH plus Ndk), both `anabolic`, both near-universal, and both should then carry a description saying plainly that
they partition almost nothing.

### 13.2 Keep both words — on different facets

**Decision: `substrate_class = cofactor` and `physiological_role` carrying both
`biosynthesis` and `vitamin_biosynthesis`.**

Both terms can be kept, but not on the same facet.
`.gifter_required_gift_facets` (`R/database-build.R:83`) declares
`substrate_class` the **single-valued** class facet of the metabolic type and `physiological_role` the multi-valued one, and
`gift_profile.substrate_class` reads it with a scalar subquery, so a second
`substrate_class` row would make that column non-deterministic. Multi-valued
`physiological_role` is already routine — `galactose_degradation_leloir` carries
three.

Which word goes where follows from what each facet asks. `substrate_class`
answers "what chemistry is this capability about", and the nine products are
chemically diverse but functionally one class: they are enzyme cofactors or
their immediate precursors. "Vitamin" is not a chemical class at all — it is a
relation to a consumer that cannot make the compound, which is exactly the kind
of statement `physiological_role` already carries in `host_glycan_foraging` and
`fibre_degradation`.

So: `cofactor` describes what the molecules are, `vitamin_biosynthesis` describes
what making them means for something else, and a user can filter on either.

### 13.3 One `MENAQUINONE` anchor; no demethylmenaquinone

**Decision: skip the DMK anchor and keep MenG as a required reaction.**

The cost was measured. 3202 bacteria complete the classic route through the
1,4-dihydroxy-2-naphthoate polyprenyltransferase, and 3109 of those also carry
MenG (K03183) — so requiring the terminal methylation excludes 93 genomes
(2.9%), which are reported as one missing reaction rather than scored away.

DMK is a real quinone and is used in some anaerobic respiration, but that is a
redox-physiology claim, and this layer's claim is nutritional: the vitamin K a
host obtains is menaquinone. A second anchor would split the trait on a
distinction the layer does not make.

### 13.4 The flavin kinase step stays uncurated

**Decision: skip it, as recommended in §8.2.** `dmb_biosynthesis_aerobic`
therefore takes `FMNH2` as an input-only anchor with no producer GIFT, and does
not compose with `riboflavin_biosynthesis`.

This is the same decision as §13.1 and it should be read with it: gifter does not
curate the activation step between a product and its working form, whether that
step is a phosphorylation or a kinase-plus-adenylyltransferase. The composition
edge is the price, and it is the smaller cost — the alternative is a trait
complete in all 18 reference genomes, including the six that cannot make
riboflavin at all.

### 13.5 `namn_salvage_nicotinate` is in the first release

**Decision: curate it.** It is included in the nineteen.

It is the layer's first explicit separation of "can live without the vitamin"
from "can make the vitamin", and the two are genuinely different claims about a
genome: 6921 bacteria can build NAD from exogenous nicotinate, while 6398 can
make the pyridine ring from aspartate. A genome in the first set and not the
second is niacin-dependent, which is the statement a vitamin layer exists to
make. Cutting at NaMN (§6.4) is what lets both GIFTs exist without either
duplicating NadD and NadE.


---

## 14. Implementation record

Curated on 2026-08-18 as database release **2026.15.1**, schema unchanged at 6,
no R change. The layer validates and builds clean, and the package test suite
passes at 2256 assertions, 356 of them in `tests/testthat/test-vitamins.R`.

What was built:

| Table | Added |
|---|---|
| `gifts` | 20 (48 → 68) |
| `anchors` | 31 (54 → 85) |
| `gift_routes` | 26 (62 → 88) |
| `reactions` | 94 (118 → 212) |
| `enzyme_systems` | 104 |
| `enzyme_components` | 107 |
| `markers` | 125 new KO accessions |
| `component_markers` | 151 |
| `facet_terms` | `substrate_class = cofactor`, `physiological_role = vitamin_biosynthesis`, `resource_origin = microbially_derived` |
| `database_changes` | 13 entries, of which 11 record a refusal or a boundary decision |

Where the implementation departed from the proposal:

1. **Twenty GIFTs, not nineteen.** The proposal's §7 diagram always listed
   twenty; the "nineteen" in §1 was a miscount, corrected here rather than by
   dropping a capability.
2. **Glyceraldehyde 3-phosphate is not declared as an anchor of
   `plp_biosynthesis_r5p`.** It was in the proposal, and it was wrong: the
   curated database already declares PRPP for purine core biosynthesis without
   declaring the glycine, aspartate and formate that route also consumes.
   Declaring it produced a catabolic-to-anabolic edge from uronate degradation
   into vitamin B6 that no reader would have read as biology, and it broke the
   sugar layer's own test that catabolism exits only at pyruvate and
   lactaldehyde. Recorded as `DBC-20260818-COSUBSTRATE-ANCHORS`.
3. **`PIMELOYL_COA`, not `PIMELOYL_ACP`.** ChEBI has no entry for the
   acyl-carrier-protein thioester under a name the anchor table could cite, and
   the BioF marker does not distinguish the two thioesters anyway. The anchor
   names the CoA form and the GIFT description says the claim covers both.
4. **`RIBULOSE_5P` was added** as a second input anchor of riboflavin
   biosynthesis. The proposal's anchor table omitted it while its own diagram
   used it; the four-carbon unit of the xylene ring has to come from somewhere.
5. **The thiamine pyrimidine anchor is the diphosphate**, `HMP_PP`, because that
   is what thiamine phosphate synthase consumes. The GIFT keeps the name
   `hmp_phosphate_biosynthesis`.
6. **Two reactions are curated against Rhea entries whose EC assignment differs
   from KEGG's.** The ThiO reaction (`RHEA:33343`, glycine + O2 = 2-iminoacetate
   + H2O2) carries no EC in Rhea at all, and the aspartate dehydrogenase step is
   curated as `RHEA:42440` (EC 1.4.1.29), the iminosuccinate-forming chemistry
   that feeds quinolinate synthase, rather than KEGG's EC 1.4.1.21, whose Rhea
   equation ends at oxaloacetate. Both are recorded in the reaction notes.
7. **The futalosine route carries the terminal prenylation and methylation.**
   KEGG's M00930 stops at MqnD; a route that stopped there would not reach the
   GIFT's output anchor. MenA and MenG are shared with the classical route.
8. **Two orphan steps were nearly shipped as required.** MenH and the
   DHNA-CoA thioesterase were curated `required = 1` in the first pass, which
   made *Bacteroides*-profile genomes menaquinone-negative; the test written for
   §8.3 caught it. This is the failure mode the orphan-step rule exists to
   prevent, and it is worth recording that the rule needs a test and not only a
   paragraph.

What the proposal predicted and the implementation confirmed:

- No schema migration and no R change. §3 was right about `required = 0`,
  `oxygen_requirement = 'aerobic'` (now used by four routes), multi-output
  anchors, and `auxotrophy_indicator`, which fires for 12 of the 20 GIFTs
  without a line of new logic.
- Rhea covers the layer completely: 94 curated reactions, every one with a
  master, no use of the nullable path.
- `gift_profile` reports `cross_feeding_output` as 0 for all 20 and
  `resource_strategy` as `private`, exactly as §12 predicted, because no vitamin
  transport GIFT is evidenceable.
- The composition graph gained 13 edges, all inside the layer: pABA into folate,
  both thiamine moieties into the condensation from both the de novo and the
  salvage side, quinolinate into NaMN, NaMN from both suppliers into both NAD
  and the cobamide loop, and the corrinoid chain and the lower ligand into the
  loop. Nothing outside the layer connects to it, which is the expected result
  of declaring GTP, FMNH2, AIR, DXP, chorismate and uroporphyrinogen III as
  input-only boundaries.
