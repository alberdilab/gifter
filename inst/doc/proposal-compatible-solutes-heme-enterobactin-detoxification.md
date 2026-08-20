# Proposal: compatible-solute and heme biosynthesis, enterobactin assembly,
# and two chemical-detoxification mechanisms

**Status:** implemented in database 2026.20.2
**Decision timestamp:** 2026-08-20T12:00Z
**Schema:** 6, unchanged

This proposal is the biological contract for seven requested candidates. It was
written before the source tables were changed. Its invariant is the one that
governs the rest of gifter: a positive metabolic call requires one complete
known route between declared molecular anchors, while a positive defense call
requires one complete curated detoxification mechanism. Neither call claims
expression, metabolite accumulation, environmental exposure, survival,
physiology, secretion, uptake, iron acquisition, osmotic tolerance, oxidative
stress resistance or any other phenotype.

## 1. Decisions

| Candidate | Type | Decision | Exact claim or durable reason |
|---|---|---|---|
| Ectoine biosynthesis | metabolic | implement | `ASA` to `ECTOINE` through EctB, EctA and EctC. The upstream aspartate kinase/dehydrogenase trunk and downstream hydroxyectoine chemistry are excluded. |
| Heme b biosynthesis | metabolic | implement | `UROGEN_III` to `HEME_B` through a complete protoporphyrin or coproporphyrin route. Siroheme-dependent heme formation has a different input and is excluded. |
| Enterobactin biosynthesis | metabolic | implement as two GIFTs | `CHORISMATE` to `DIHYDROXYBENZOATE_2_3`, then `DIHYDROXYBENZOATE_2_3` plus `SERINE` to `ENTEROBACTIN`. The shared branch is curated once. |
| Methylglyoxal detoxification | defense | implement one mechanism | Glutathione-dependent glyoxalases I and II, both required. The claim ends at D-lactate and regenerated glutathione. |
| Superoxide detoxification | defense | implement one mechanism | Superoxide removal followed by removal of the hydrogen peroxide it produces, both required. |
| Choline to glycine betaine | metabolic | implement | `CHOLINE` to the existing `BETAINE` anchor by complete BetA/BetB, GbsB/GbsA, choline-monooxygenase/BADH or choline-oxidase chemistry. |
| Polyhydroxybutyrate biosynthesis | metabolic | refuse for now | `K03821` names polyhydroxyalkanoate synthases across substrate classes and cannot identify PHB. PhaA/PhaB context cannot turn a broad polymerase marker into PHB-specific evidence. |

All implemented anchors are `unspecified` compartment. None of the accepted
markers establishes localisation, export or uptake.

## 2. Ectoine biosynthesis

### Claim and boundary

`ectoine_biosynthesis` is an anabolic metabolic GIFT from L-aspartate
4-semialdehyde (`ASA`) to L-ectoine (`ECTOINE`). This cut deliberately reuses
the output of `aspartate_semialdehyde_biosynthesis`. It excludes Ask and Asd,
which are already upstream of `ASA`, and excludes EctD, transport, regulation,
cellular ectoine concentration and osmotic protection.

MetaCyc `P101-PWY` contains five reactions: aspartate kinase,
aspartate-semialdehyde dehydrogenase and the EctB/A/C tail. The GIFT is therefore
`subset_of` that record. KEGG module `M00033` has the same wider aspartate to
ectoine scope and is also `subset_of`.

The one minimal route is:

| Order | Rhea 141 master | Direction | Enzyme system | Accepted marker |
|---:|---|---|---|---|
| 1 | `RHEA:11160` | reverse | EctB DABA aminotransferase | `KO:K00836` |
| 2 | `RHEA:16901` | forward | EctA DABA acetyltransferase | `KO:K06718` |
| 3 | `RHEA:17281` | forward | EctC ectoine synthase | `KO:K06720` |

The reverse orientation of `RHEA:11160` matters: its master equation forms
`ASA`, while biosynthesis consumes it. `K15785` is not admitted as an EctB
alternative because KEGG assigns it to ectoine degradation/recycling and it
does not establish the requested biosynthetic direction.

## 3. Heme b biosynthesis

### Claim and boundary

`heme_b_biosynthesis` is an anabolic metabolic GIFT from uroporphyrinogen III
(`UROGEN_III`) to heme b (`HEME_B`). `UROGEN_III` is already the branchpoint
used by corrin-ring biosynthesis. The GIFT claims encoded heme-b chemistry, not
heme use, respiratory capacity, haemoprotein assembly or a vitamin.

Three biological route families clear the contract:

1. the classical protoporphyrin route represented by MetaCyc
   `HEME-BIOSYNTHESIS-II`, with HemF/HemN and HemY/HemG/HemJ alternatives;
2. the oxygen-independent classical route context in MetaCyc `HEMESYN2-PWY`;
3. the coproporphyrin route of Firmicutes and Actinobacteria in MetaCyc
   `PWY-7766`, using HemY, the copro-specific activity of HemH, and HemQ.

All three MetaCyc records have the requested `UROGEN_III` and `HEME_B`
boundaries and are linked as `equivalent`. KEGG `M00121` and `M00926` start
upstream and are linked as `subset_of`.

The classical route begins with `RHEA:19865` (HemE) and ends with reverse
`RHEA:22584` (HemH). The two middle positions are independent OR choices in
KEGG `M00121`; gifter materialises their six minimal combinations:

| Position | Rhea 141 master | Enzyme | Marker | Oxygen consequence |
|---|---|---|---|---|
| coproporphyrinogen oxidation | `RHEA:18257` | HemF | `KO:K00228` | consumes O2 |
| coproporphyrinogen oxidation | `RHEA:15425` | HemN | `KO:K02495` | oxygen-independent radical-SAM chemistry |
| protoporphyrinogen oxidation | `RHEA:25576` | HemY | `KO:K00231` | consumes O2 |
| protoporphyrinogen oxidation | `RHEA:27409` | HemG | `KO:K00230` | menaquinone-dependent |
| protoporphyrinogen oxidation | `RHEA:62000` | HemJ | `KO:K08973` | acceptor remains abstract in Rhea |

A route is labelled `aerobic` if either middle reaction consumes oxygen and
`independent` otherwise. The Rhea 141 cross-reference file does not map KEGG
`R09489` to `RHEA:27409`; only Rhea's EC `1.3.5.3` cross-reference is stored,
and the KEGG reaction is mentioned in the marker provenance rather than asserted
as a Rhea xref.

The coproporphyrin route is `RHEA:19865`, `RHEA:43436`, reverse
`RHEA:49572`, and `RHEA:56516`. `KO:K00231` supports both its copro oxidation
and the classical proto oxidation, while `KO:K01772` supports both ferrochelatase
reactions. These are multifunctional markers attached to two reaction-specific
components, not collapsed reactions.

The siroheme-dependent Ahb route is not another route of this GIFT. It starts
from siroheme, so folding it into a `UROGEN_III`-bounded GIFT would silently
claim unmodelled siroheme synthesis. Database 2026.20.3 subsequently added the
upstream `siroheme_biosynthesis` GIFT and `SIROHEME` anchor, but refused
`siroheme_to_heme_b`: the first reaction requires AhbA AND AhbB, while both
experimentally required genes map to `K22225`. The current evidence model
cannot require two distinct observed genes carrying one accession. Reconsider
only with distinct subunit markers, a fusion-specific marker, or a
multiplicity-aware evidence contract.

## 4. Enterobactin: two composable GIFTs

MetaCyc `ENTBACSYN-PWY` crosses a branchpoint that is independently useful to
other catecholate siderophores. It is therefore split.

### 4.1 2,3-dihydroxybenzoate biosynthesis

`dihydroxybenzoate_biosynthesis` runs from `CHORISMATE` to
`DIHYDROXYBENZOATE_2_3` through forward `RHEA:18985`, `RHEA:11112` and
`RHEA:23824`. The first reaction and all of its already curated enzyme systems
are reused. EntB (`KO:K01252`) supplies the isochorismate lyase and EntA
(`KO:K00216`) the final dehydrogenase. The GIFT says nothing about which
siderophore, if any, receives the product.

### 4.2 Enterobactin assembly

`enterobactin_biosynthesis` consumes `DIHYDROXYBENZOATE_2_3` and `SERINE` and
forms `ENTEROBACTIN`. Rhea `RHEA:30571` gives the aggregate EC 6.3.2.14
chemistry. Its one enzyme system requires four components together:

| Component | Role | Marker |
|---|---|---|
| EntB aryl carrier | phosphopantetheinylated carrier for DHB | `KO:K01252` |
| EntD | activates EntB and EntF carrier domains | `KO:K02362` |
| EntE | loads DHB onto holo-EntB | `KO:K02363` |
| EntF | activates serine, condenses the units and cyclises the trilactone | `KO:K02364` |

The system is AND across all four components. `K01252` is deliberately reused
as a marker of two different components: its N-terminal lyase supplies the head
GIFT and its carrier domain participates in the tail. Neither GIFT claims
enterobactin export, uptake of ferric enterobactin, iron acquisition, virulence
or siderophore activity. Both are `subset_of` MetaCyc `ENTBACSYN-PWY` and KEGG
pathway `map01053`.

## 5. Methylglyoxal detoxification

`methylglyoxal_detoxification` is a defense GIFT in
`chemical_detoxification`. Its one mechanism requires both:

| Function | Rhea identity of chemistry | Required system and marker |
|---|---|---|
| glyoxalase I | reverse `RHEA:19069` | GloA, `KO:K01759` |
| glyoxalase II | forward `RHEA:25245` | GloB, `KO:K01069` |

The first enzyme consumes the spontaneously formed methylglyoxal-glutathione
hemithioacetal and makes S-lactoylglutathione; the second makes D-lactate and
regenerates glutathione. MetaCyc `PWY-5386` continues with D-lactate oxidation,
which is central metabolism after the toxic electrophile has been disposed of.
The defense mechanism therefore links as `subset_of` and stops before that
reaction.

Glutathione-independent glyoxalase-III/DJ-1/Hsp31 proteins and aldo-keto
reductase or aldehyde-dehydrogenase routes are not accepted. Their common
orthology groups cover chaperone/protease or broad carbonyl activities and do
not identify methylglyoxal as the substrate. Reconsider them only when a
marker, or a jointly required marker context, has been validated to distinguish
methylglyoxal conversion at the specificity of the GIFT.

## 6. Complete superoxide detoxification

`superoxide_detoxification` is a defense GIFT in
`chemical_detoxification`. A complete mechanism requires both superoxide
removal and peroxide removal. This is stricter than treating an SOD accession
as the trait: `RHEA:20696` produces hydrogen peroxide, so an SOD alone merely
changes the reactive species.

The superoxide-removal function has Fe/Mn SOD (`KO:K04564`) and Cu/Zn SOD
(`KO:K04565`) as alternative one-component systems. The peroxide-removal
function has four alternative systems:

- monofunctional catalase, `KO:K03781`;
- catalase-peroxidase, `KO:K03782`;
- manganese catalase, `KO:K07217`;
- the two-component AhpC/AhpF system, `KO:K03386` plus `KO:K03387`.

Catalases carry the exact `RHEA:20309` hydrogen-peroxide dismutation. Rhea
represents the peroxiredoxin chemistry at the generic hydroperoxide level as
`RHEA:62620`; primary genetic and clearance measurements establish Ahp as a
major bacterial H2O2 scavenger, so the specific AhpC/AhpF context is accepted
while a generic peroxiredoxin alone is not.

MetaCyc `DETOX1-PWY` contains superoxide dismutation plus catalase and has the
same chemical extent, so it is `equivalent`. `DETOX1-PWY-1` is a wider reactive
oxygen species pathway and is `superset_of` the GIFT, recorded from the GIFT
side as `subset_of`.

Two candidates are deliberately excluded from the alternatives. Nickel SOD
`KO:K00518` can require a cognate processing peptidase to expose its nickel-hook
active site, and no specific maturase marker has been established here; the KO
alone is not a complete system. Superoxide reductase `KO:K05919` is chemically
specific, but its in-vivo electron-delivery chain and the fate of its peroxide
product are lineage-dependent; it can be reconsidered as a second mechanism
once that complete architecture is markable. No call claims oxidative-stress
resistance or survival.

## 7. Choline to glycine betaine

`choline_to_betaine` is an anabolic metabolic GIFT from `CHOLINE` to the
existing `BETAINE` anchor. It composes with `betaine_demethylation` and with the
existing carnitine-to-betaine route without duplicating either.

Four genomically distinguishable routes are curated:

| Route | First oxidation | Final oxidation | Markers |
|---|---|---|---|
| BetA/BetB | `RHEA:17433` | `RHEA:15305` | `K00108`, `K00130` |
| GbsB/GbsA | `RHEA:33051` | `RHEA:15305` | `K11440`, `K00130` |
| choline monooxygenase/BADH | `RHEA:17769` | `RHEA:15305` | `K00499`, `K00130` |
| choline oxidase | `RHEA:13505` then `RHEA:20369` | same enzyme at both steps | `K17755` |

MetaCyc `BETSYN-PWY` and `PWY-3722` represent the Gram-negative BetAB and
Gram-positive GbsAB architectures respectively; both have the same declared
anchors and are linked as `equivalent`. KEGG `M00555` is also `equivalent` and
supplies the additional chemical alternatives.

`KO:K00130` is accepted because KEGG names it betaine-aldehyde dehydrogenase.
`KO:K14085` is refused even though KEGG includes it in `M00555`: it is ALDH7A1,
is assigned many aldehyde reactions, and cannot distinguish betaine aldehyde.
The NADP version of the BADH reaction is not materialised as another route
because the same accepted KO serves both cofactors; duplicating it would add no
genomic discrimination. Transporters, regulators, intracellular betaine
concentration and osmotic protection are outside the claim.

## 8. PHB refusal and retrigger

The proposed boundary, `ACETYL_COA` to a PHB polymer, is biologically sensible,
and Rhea 141 covers the three steps with the existing thiolase reaction,
acetoacetyl-CoA reductase chemistry and PHB-specific polymer extension
`RHEA:15405`. The evidence layer does not clear the same specificity.

KEGG `K03821` is poly[(R)-3-hydroxyalkanoate] polymerase PhaC and maps to the
generic PHA reaction `RHEA:66924`. PhaC classes differ in short- versus
medium-chain-length substrate use, and experimentally changing a few residues
can change 3-hydroxybutyrate incorporation. Requiring PhaA (`K00626`) and PhaB
(`K00023`) alongside it would provide 3-hydroxybutyryl-CoA but would not prove
that the broad polymerase accepts that monomer. The candidate is therefore
refused rather than widened to “PHA biosynthesis.”

Retrigger curation when a maintained marker namespace provides a validated
class/subfamily marker whose members accept (R)-3-hydroxybutyryl-CoA, or when a
curated sequence model with that validation can be added to a namespace gifter
can actually match. At that point the exact PHB boundary can be reconsidered;
the current refusal must not be bypassed by pairing `K03821` with upstream
enzymes.

## 9. Evidence and access record

- Rhea release 141 (2026-06-10), `rhea2kegg_reaction.tsv`, `rhea2ec.tsv`,
  reaction equations and ChEBI participants, retrieved 2026-08-20.
- KEGG orthology entries and modules `M00033`, `M00121`, `M00926` and `M00555`,
  retrieved 2026-08-20. A prevalence pass through `link/genes/ko:` was attempted
  but the KEGG REST host stopped resolving; no zero returned by that failed
  request is treated as a measurement. None of the decisions depends on a
  prevalence threshold.
- MetaCyc identifiers were checked against the addressed pathway records and a
  pathway/reaction export. On 2026-08-20 the BioCyc web service and pathway pages
  redirected anonymous requests to account creation, so this release records
  the identifiers and boundary comparison but does not claim that anonymous
  programmatic access remains available.
- EctABC chemistry: PMID 31921013 and PMID 20190082.
- Coproporphyrin heme pathway: PMID 25646457; HemG: PMID 19583219; HemJ:
  PMID 20823222.
- Enterobactin assembly: PMID 10375542.
- Glutathione-dependent methylglyoxal disposal: PMID 21143325; broad reductase
  alternatives: PMID 16077126.
- Bacterial H2O2 clearance by catalase and Ahp: PMID 15547258 and PMID 22609271;
  NiSOD maturation limitation: PMID 15516600; superoxide reductase boundary:
  PMID 12072973.
- GbsAB choline oxidation: PMID 8752328.
- PhaC substrate-specificity refusal: PMID 15205419, PMID 24564904 and
  PMID 21261834.

## 10. Release effect

Database 2026.20.2 adds seven GIFT rows because the enterobactin candidate is
split into two. It adds no GIFT type and changes no schema or R behavior. Source
tests must protect positive calls, one-step incomplete calls, alternative
routes/systems, the enterobactin multisubunit system, marker reuse, the BADH,
NiSOD, SOD-only and PHB specificity negatives, evidence traces and the new
composition edges.
