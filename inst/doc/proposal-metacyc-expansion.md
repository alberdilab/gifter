# Proposal: systematic MetaCyc expansion reconnaissance

**Status:** reconnaissance complete; upstream siroheme GIFT implemented in
database 2026.20.3, downstream Ahb GIFT refused at current marker specificity

**Decision timestamp:** 2026-08-20T09:21Z

**MetaCyc knowledge base:** 30.0

**Database baseline inspected:** gifter 2026.20.2, schema 6

This document records a catalogue-wide discovery pass for GIFT candidates after
the curation of ectoine biosynthesis, heme-b biosynthesis, the
2,3-dihydroxybenzoate and enterobactin branches, glutathione-dependent
methylglyoxal detoxification, complete superoxide detoxification and
choline-to-betaine biosynthesis, and after the evidence-based refusal of
polyhydroxybutyrate biosynthesis.

This document began as a proposal. The implementation audit for database
2026.20.3 accepted `siroheme_biosynthesis` but overturned the proposed
`siroheme_to_heme_b` recommendation: AhbA and AhbB are both required, yet both
map to `K22225`, so the current evidence model cannot prove the heterodimer.
The outcome and retrigger are recorded below.

The invariant used throughout is:

> A MetaCyc pathway is discovery and provenance evidence, not a GIFT. A
> candidate is acceptable only when gifter can state a typed biological claim,
> defensible molecular boundaries or machinery model, a complete Boolean
> implementation, and markers no broader than that claim. A pathway endpoint,
> inferred taxonomic assignment, superpathway or reaction list is never adopted
> automatically.

## 1. Method and catalogue coverage

### 1.1 Structured retrieval

The official [BioCyc web-services API](https://websvc.biocyc.org/web-services.shtml#R9)
reported MetaCyc **30.0** through
[`kb-version?orgid=META`](https://websvc.biocyc.org/kb-version?orgid=META).
The complete pathway object set was retrieved on 2026-08-20 with the documented
BioVelo query:

```text
https://websvc.biocyc.org/xmlquery
  ?query=[x:x<-meta^^pathways]
  &detail=low
```

The response metadata reported 4,427 objects and `PGDB orgid='META'
version='30.0'`. Programmatic parsing of each object's class flag, parents,
direct `reaction-list` members and nested pathway members gave the counts below.

The decoded XML response had SHA-256
`d13a5cb4fc6fef15a128c83e0e44597f0ed4961a0ef60b5be5070e239c9c665f`;
the parsed catalogue table had SHA-256
`9eaecf50bb954520510bd61b48d1caf1b7574b847d0ad12e5668f7f689fb0ebf`.
The service response itself is not copied into the package.

| Object class | Count | Treatment |
|---|---:|---|
| Pathway ontology classes | 736 | Used to classify the catalogue; not candidates. |
| Pathway instances | 3,691 | Discovery pool before superpathway removal. |
| Superpathways | 386 | Removed as candidate capabilities. Their base members, or a seeded record's explicitly separated direct-reaction tail, were considered independently. |
| Base pathway records | **3,305** | The screened discovery universe. |

The 3,305 base records have overlapping top-level ontology ancestry. The pass
covered 1,992 biosynthesis, 1,047 degradation/utilisation/assimilation, 223
energy, 178 glycan, 81 macromolecule-modification, 64 detoxification, 51
activation/inactivation/interconversion, 67 metabolic-cluster and 13
bioluminescence/fluorescence/chromoprotein records. These counts overlap because
a pathway can have more than one ontology parent.

For selected candidates, the direct reaction objects were then retrieved in
batches through the same BioVelo service. That second pass supplied exact left
and right participants, EC identifiers, enzyme names and the orientation that
would need to be recorded separately in gifter. KEGG's official REST service was
used only to check whether a maintained orthology accession exists and how
specifically it is named. Rhea identity and direction remain mandatory
implementation work; this reconnaissance does not substitute a MetaCyc
reaction identifier or EC number for a Rhea master.

### 1.2 Early exclusions

The following were rejected before detailed scoring:

- all 386 superpathways as candidate capabilities;
- aerobic and anaerobic respiration records whose encoded chemistry requires
  an external terminal electron acceptor;
- inferred resistance outcomes, efflux, sequestration and mixed
  transport-regulation-detoxification bundles;
- plant-specialised and engineered pathways unless a distinct microbial base
  pathway remained after removing the superpathway;
- protein, lipid or cofactor activation that is nearly universal housekeeping
  and has no useful genome-partitioning claim;
- records whose only distinguishing evidence is a broad enzyme family, an NRPS
  domain, a generic C-P lyase or a reaction direction the marker cannot resolve;
- records requiring a gene cluster, gene order, secretion signal, expression or
  environmental state that the current evidence input does not observe; and
- isolated reactions without a stable product identity, useful branchpoint or
  complete defense mechanism.

This filter was not used to discard the seeded candidates silently. Every seed
family appears in the register below, including the ones that fail.

### 1.3 Local deduplication baseline

The inspected 2026.20.2 baseline contained 141 GIFTs: 131 metabolic, 2
structural, 3 regulatory and 5 defense, with 148 declared anchors. The catalogue, anchors,
facets, all proposal documents, `database_changes.tsv`, `change_gifts.tsv` and
the 11 current MetaCyc cross-references were inspected before candidate naming.

Important pre-existing decisions are carried forward:

- `salicylate_biosynthesis`, `dihydroxybenzoate_biosynthesis` and
  `enterobactin_biosynthesis` already provide the two reusable siderophore
  branchpoints and one assembled product;
- the amino-acid proposal already recommends arginine/agmatine/putrescine
  chemistry but defers the polyamine boundary;
- the cycles proposal already states that Calvin and reductive TCA chemistry
  must be cut into meaningful atomic spans and that cycle closure is derived;
- the vitamin proposal puts siroheme, ubiquinone, molybdopterin and lipoate
  outside the vitamin layer and refuses routine vitamin-to-cofactor activation;
- the defense proposal already defers nitrosative, peroxide, organic
  hydroperoxide, formaldehyde, tellurite and Cu(I) mechanisms;
- the current heme proposal explicitly defers `siroheme_to_heme_b` until an
  upstream siroheme capability exists; and
- PHB is already refused because `KO:K03821` cannot establish
  3-hydroxybutyrate-specific polymerisation.

Accordingly, a row marked **already covered** below is not a new discovery, and
a new refusal does not erase the prior decision that led to it.

## 2. Scoring and ranked shortlist

Each candidate receives 0–2 points on five axes: defensible boundary or
machinery model, marker specificity, fit to the Boolean hierarchy, composition
with current GIFTs, and biological usefulness/breadth. A score is triage, not a
completeness percentage.

- **recommend**: the claim and evidence shape are ready for a dedicated
  implementation proposal;
- **conditional**: one bounded biological or evidence check remains;
- **defer**: useful, but a boundary, context or architecture decision remains;
- **refuse**: the claim cannot be supported at its named specificity or violates
  the current ontology; and
- **already covered**: an existing GIFT, proposal decision or recorded refusal
  already answers it.

### Five strongest candidates

| Rank | Candidate | Score | Why it leads |
|---:|---|---:|---|
| 1 | `ectoine_degradation` | 10 | A four-reaction, product-specific route from the current `ECTOINE` anchor to the current `ASPARTATE` anchor; `K15783`–`K15786` distinguish all four steps and it composes directly with ectoine and aspartate-family synthesis. |
| 2 | `siroheme_biosynthesis` | 9 | `SIROHEME` is a defensible branchpoint and the upstream route has complete multifunctional and split evidence. It was implemented in 2026.20.3; the proposed downstream Ahb GIFT was refused when `K22225` proved unable to distinguish its two required subunits. |
| 3 | `glutathione_biosynthesis` | 10 | Two required ligases, exact product identity, existing amino-acid inputs and separate (`K01919` + `K01920`) and fused (`K28983`) systems. It partitions microbial low-molecular-weight thiol strategies without claiming redox state or stress tolerance. |
| 4 | `aerobactin_biosynthesis` | 10 | Four product-specific Iuc components (`K03894`–`K03897`) and existing `LYSINE`, `ACETYL_COA` and `CITRATE` inputs; no NRPS-domain or locus inference is needed. |
| 5 | `ergothioneine_biosynthesis` | 9 | The bacterial Egt route has a chemically exact product and specific KO spine (`K01919`, `K18911`–`K18913`, `K07008`) from existing histidine, cysteine and glutamate inputs. |

`salmochelin_s4_biosynthesis`, both complete 2-aminoethylphosphonate
utilisation routes, the three distinct DMSP branches, cyanophycin synthesis and
bacillithiol synthesis are the next tier. The exact one-enzyme
thiol-independent formaldehyde mechanism joins that tier after the final KO
definition audit. Their lower rank reflects narrower taxonomic breadth or one
remaining boundary/materialisation decision, not weak biology.

## 3. Implementation result of the proposed next release

Reconnaissance proposed a two-GIFT **siroheme branch closure**:

```text
UROGEN_III -> SIROHEME -> HEME_B
```

1. `siroheme_biosynthesis`: `UROGEN_III` to `SIROHEME`, equivalent in boundary
   to MetaCyc `PWY-5194` (4 reactions).
2. `siroheme_to_heme_b`: `SIROHEME` to the existing `HEME_B`, equivalent in
   boundary to MetaCyc `PWY-7552` (3 reactions).

The implementation audit accepted only the first GIFT. Database 2026.20.3 adds
`siroheme_biosynthesis`, the `SIROHEME` anchor, one three-Rhea-reaction route,
and multifunctional CysG, bifunctional Met8 and split SirC/SirB alternatives.
MetaCyc's four reaction records become three Rhea requirements because
`RHEA:32459` is the overall two-methyl-transfer reaction.

The second GIFT is **refused**, not merely deferred. Biochemistry requires an
AhbA-AhbB heterodimer, while both experimentally required *Methanosarcina
barkeri* genes map to `K22225`. Reusing one accession on two components would
let one observed gene satisfy both. Of the KEGG genomes with the complete
K22225-K22226-(K22227 or K25033) expression, 45 bacterial and three archaeal
genomes have only one `K22225` gene row. Reconsider only with maintained
AhbA/AhbB-distinguishing markers, a fusion-specific marker, or a general
multiplicity-aware evidence contract.

## 4. Compatible solutes and trehalose

The seven trehalose records do not share one input boundary. They resolve into
four candidate families, not seven alternative routes of one GIFT.

| Candidate and claim | Type and boundary | MetaCyc record and relation | Evidence, composition and breadth | Score, verdict and reconsideration |
|---|---|---|---|---|
| `trehalose_biosynthesis_glucose_6p`: forms trehalose through a trehalose-6-phosphate intermediate | metabolic, anabolic; glucose 6-phosphate plus an activated glucose donor to `TREHALOSE` | `TRESYN-PWY` (2, UDP donor), `PWY-881` (2, ADP donor), `TREHALOSESYN-PWY` (2, GDP donor); **related** until the donor boundary is settled | OtsA `K00697` and OtsB `K01087` are specific. The three records share glucose 6-phosphate and output, but UDP-, ADP- and GDP-glucose contribute half the carbon and cannot silently become one route-level input. Broad across bacteria, archaea, fungi and plants. | **6, defer.** Decide whether activated sugars are boundary co-substrates. If they are, these are three GIFTs; if a justified co-substrate rule excludes them, they can be three routes of one GIFT. |
| `maltose_trehalose_interconversion`: encodes TreS-mediated isomerisation | metabolic, interconversion; `MALTOSE` and `TREHALOSE` | `PWY-2622` (1), **equivalent** | `K05343` names TreS but also records its alpha-amylase activity; that multifunctionality does not widen the maltose/trehalose isomerisation claim. Two new exact disaccharide anchors would be needed. Moderate bacterial breadth. | **8, conditional.** Confirm that K05343 sequences assigned TreS retain the isomerase activity and map EC 5.4.99.16 to Rhea. |
| `glucan_to_trehalose`: releases trehalose from a branched alpha-glucan through TreY/TreZ | metabolic, catabolic with a chemically defined product; `GLYCOGEN` or a bounded alpha-glucan to `TREHALOSE` | `PWY-2661` (3), **equivalent** only if the polymer boundary matches | `K06044` TreY and `K01236` TreZ are jointly required; the debranching activity is broader. It could compose with a future glycogen-synthesis GIFT. Broad in actinobacteria and stress-adapted bacteria, not universal. | **6, defer.** Resolve whether the substrate is glycogen, maltodextrin or a broader alpha-glucan without exceeding the markers. |
| `glucose_to_trehalose`: forms trehalose directly from free glucose and an activated donor | metabolic, anabolic; glucose plus NDP-glucose to `TREHALOSE` | `PWY-5983` (1, generic NDP donor) and `PWY-5985` (1, UDP donor), **related** pending donor choice | `K13057` TreT supports EC 2.4.1.245; the seventh pathway record lacks an EC in the structured response. Taxonomically narrower, especially archaea. | **6, defer.** Require a marker audit that distinguishes the generic and UDP-specific activities and decide whether they can share an exact boundary. |
| `ectoine_degradation`: converts ectoine through N-acetyl-DABA and DABA to aspartate | metabolic, catabolic; existing `ECTOINE` to existing `ASPARTATE` | `PWY-7855` (4), **equivalent** | DoeA–D have exact KOs `K15783`–`K15786`. No transporter is required for the intracellular chemistry. It composes with `ectoine_biosynthesis` through ECTOINE and with the aspartate family at ASPARTATE. Moderate breadth among ectoine utilisers. | **10, recommend.** Reconsider only if a Doe accession proves directionally or substrate ambiguous during Rhea/KO mapping. |
| `glycine_to_betaine`: three successive methylations of glycine to glycine betaine | metabolic, anabolic; existing `GLYCINE` to existing `BETAINE`; SAM is a methyl donor, not an anchor | `P541-PWY` (3), **equivalent** | `K24071` names the multifunctional glycine/sarcosine/dimethylglycine methyltransferase; `K18897` covers only the latter methylations and cannot complete the route alone. It composes with `betaine_demethylation` and the current choline/carnitine branches. Moderate, halophile-weighted breadth. | **8, conditional.** Confirm whether a maintained marker identifies the separate first methyltransferase route; otherwise curate only the complete K24071 system. |
| `mannosylglycerate_biosynthesis_3pg` and `mannosylglycerate_biosynthesis_glycerate`: form the same compatible solute from different acceptors | metabolic, anabolic; `PG3` plus GDP-mannose, or glycerate plus GDP-mannose, to `MANNOSYLGLYCERATE` | `PWY-5656` (2) and `PWY-5658` (1), respectively **equivalent**, but not alternatives of one GIFT | `K05947` + `K07026` support the phosphorylated route and `K18818` the direct route. The different acceptor boundaries require separate GIFTs. Mostly thermophiles and halophiles. | **7, conditional.** Verify GDP-mannose boundary treatment and prevalence before spending two new anchors on a narrow family. |
| `glucosylglycerol_biosynthesis`: forms glucosylglycerol with GgpS/GgpP | metabolic, anabolic; glycerol 3-phosphate plus ADP-glucose to `GLUCOSYLGLYCEROL` | proposed tail is **subset_of** `PWY-7902` (5; last 2 product-defining reactions) | `K03692` and `K05978` are specific; the first three MetaCyc reactions are central precursor supply and should not be duplicated. Mainly cyanobacteria and a few halophiles. | **7, conditional.** Add only after an exact glycerol-3-phosphate boundary review and bacterial prevalence pass. |
| `sucrose_biosynthesis_microbial`: encoded sucrose formation without claiming osmoprotection | metabolic, anabolic; sugar phosphates to sucrose | `PWY-7347` (3), `PWY-7238` (8); plant/photosynthetic `SUCSYN-PWY` is a superpathway and excluded | Sucrose-phosphate synthase/phosphatase can be marked, but most records are plant or phototroph dominated and the long pathways duplicate central sugar-phosphate chemistry. | **5, defer.** Reconsider in a dedicated cyanobacterial compatible-solute layer with bacterial prevalence and product-specific markers. |

The current `compatible_solute` and `compatible_solute_biosynthesis` facet terms
are already sufficient. No candidate licenses osmotic tolerance, accumulation,
transport or environmental availability.

## 5. DMSP and volatile sulfur

All three base records start at dimethylsulfoniopropanoate, but their product
boundaries are different. They must never be a generic “DMSP degradation”
checklist.

| Candidate and claim | Type and boundary | MetaCyc record and relation | Evidence, composition and breadth | Score, verdict and reconsideration |
|---|---|---|---|---|
| `dmsp_cleavage_acrylate`: DMSP to dimethyl sulfide and acrylate | metabolic, catabolic; `DMSP` to `DIMETHYL_SULFIDE` + `ACRYLATE` | `PWY-6046` (1), **equivalent** | Product-specific DMSP lyase KOs include DddL `K16953`, DddP `K28067`, DddW `K28068` and DddY `K28069`; DddQ lacks a KO and is not an automatic alternative. Marine bacteria, moderate within that habitat and narrow globally. | **9, recommend.** Audit each KO against EC 4.4.1.3 and refuse family-only DddQ evidence until another namespace resolves it. |
| `dmsp_cleavage_hydroxypropionyl_coa`: DMSP to dimethyl sulfide and 3-hydroxypropionyl-CoA, with acetate as coproduct | metabolic, catabolic; `DMSP` + acetyl-CoA to `DIMETHYL_SULFIDE` + `HYDROXYPROPIONYL_COA` | `PWY-6056` (1), **equivalent** | DddD `K28073` names the DMSP lyase/CoA-transfer chemistry. It has a distinct carbon product and is not a route of the acrylate GIFT. Marine, narrower than the first cleavage family. | **8, recommend.** Verify the multifunctional DddD system and whether 3-hydroxypropionyl-CoA is useful enough to declare as an anchor. |
| `dmsp_demethylation`: removes the DMSP methyl group to 3-(methylsulfanyl)propanoate (MMPA) | metabolic, catabolic; `DMSP` to `MMPA`; the folate pair is a carrier, not a graph boundary | `PWY-6052` (1), **equivalent** when run opposite the stored MetaCyc equation | DmdA `K17486` is named specifically. The route orientation must be stored explicitly because the structured reaction is written MMPA + 5-methyl-THF to DMSP + THF. Marine bacteria, often broader than cleavage. | **8, recommend.** Map the reverse orientation to Rhea and confirm that MMPA is a stable branchpoint rather than an arbitrary internal intermediate. |

`PWY-6049` is a superpathway and is not a capability. The three candidates may
share a DMSP input and, for the cleavage pair, a dimethyl-sulfide output; they do
not share a complete route or a common carbon-product boundary.

## 6. Carbon-fixation chemistry

| Candidate and claim | Type and boundary/model | MetaCyc record and relation | Evidence, composition and problem | Score and verdict |
|---|---|---|---|---|
| `calvin_cycle_segments` (family placeholder, not a GIFT): Calvin-Benson-Bassham carbon fixation | metabolic, anabolic, but **not one GIFT**; candidate spans include ribulose-5-phosphate to RuBP and RuBP + CO2 to 3-phosphoglycerate | `CALVIN-PWY` (13); each atomic span would be **subset_of** | Rubisco and phosphoribulokinase are specific, but most regeneration reactions are shared central chemistry. Existing `PG3`, `GAP`, `DHAP`, `FRUCTOSE_6P`, `XYLULOSE_5P` and `RIBULOSE_5P` make a compositional solution possible. Cycle closure must be derived, as already decided in the cycles proposal. | **5, defer.** Produce a boundary proposal that proves each new span is independently meaningful and avoids duplicating central reactions. |
| `co2_to_acetyl_coa_wood_ljungdahl`: bacterial reductive acetyl-CoA chemistry | metabolic, anabolic; CO2/formate to existing `ACETYL_COA` | `CODH-PWY` (12), provisionally **equivalent** | The methyl and carbonyl branches and CODH/ACS complex are jointly required. KO and EC evidence exists, but CODH paralogues, AcsCD fusions and formate-dehydrogenase direction require a system audit. Broad across acetogens and some anaerobes, ecologically important. | **7, conditional.** Demonstrate a marker set that separates acetyl-CoA synthase CODH from respiratory and methanogenic CODH complexes and does not infer energy conservation. |
| `methanogenic_co2_to_acetyl_coa` | metabolic chemistry embedded in methanogenesis; CO2 to acetyl-CoA | `PWY-7784` (6), provisionally **related** | The record is archaeal and tied to methanogenic cofactors and external-electron-acceptor energy metabolism. The current exclusion prevents importing methanogenesis as a carbon-fixation checklist. | **4, defer.** Reconsider only in an archaeal carbon-assimilation proposal that separates biosynthetic acetyl-CoA formation from methanogenic respiration. |
| `reductive_glycine_carbon_fixation` | would be metabolic, anabolic; C1 units to pyruvate/acetyl-CoA | `PWY-8303` (9), **no link while refused as named** | Glycine cleavage, methylene-THF chemistry and pyruvate synthase use the same markers in both directions; marker presence does not establish reductive flux. The pathway name is more specific than the evidence. | **3, refuse.** Reconsider if a validated direction-specific architecture or jointly required marker set distinguishes the reductive pathway from ordinary glycine cleavage and one-carbon metabolism. |
| `reductive_tca_segments` (family placeholder, not a GIFT) | metabolic atomic spans plus a derived cycle, not one GIFT | `P23-PWY` (11) and `PWY-5392` (12); atomic spans would be **subset_of** | ATP citrate lyase or the two-step citryl-CoA system and reductive 2-oxoacid synthases are informative. Reversible central reactions already belong to current TCA GIFTs. Bundling all 11/12 reactions would duplicate independently meaningful segments and violate the cycle model. | **6, defer.** Map the reverse-specific bypass spans onto the current anchor graph and add a curated `metabolic_cycle` name only after the graph closes. |
| `hydroxypropionate_cycle_segments` (family placeholder, not a GIFT) | metabolic atomic spans plus a derived cycle | `PWY-5743` (13); spans would be **subset_of** | Malonyl-CoA reductase and propionyl-CoA synthase are informative, but carboxylases and beta-oxidation-like enzymes are widely shared and several steps are fused. No current boundary pass shows which spans are independently useful. | **5, defer.** Require a cycle decomposition, fusion-aware systems and specificity negatives for shared acyl-CoA enzymes. |
| `hydroxypropionate_hydroxybutyrate_cycle_segments` (family placeholder, not a GIFT) | metabolic atomic spans plus a derived cycle | `PWY-5789` (18); spans would be **subset_of** | Archaeal, long and fusion-rich; many reactions overlap the 3HP cycle and general acyl-CoA metabolism. Treating 18 reactions as one trait would bundle meaningful segments. | **5, defer.** Reconsider with an archaeal cycle proposal and a curated marker architecture. |

No carbon-fixation candidate is recommended for the immediate release. The
Wood-Ljungdahl route is the strongest chemistry, but its marker architecture
must be shown to distinguish carbon assimilation from neighbouring CODH
systems.

## 7. Specific phosphonate utilisation

Phosphate never needs to become an anchor for the two acceptable routes. Their
carbon/nitrogen products already supply useful boundaries.

| Candidate and claim | Type and boundary | MetaCyc record and relation | Evidence, composition and breadth | Score, verdict and reconsideration |
|---|---|---|---|---|
| `aminoethylphosphonate_to_acetyl_coa`: 2-AEP through phosphonoacetaldehyde to acetyl-CoA | metabolic, catabolic; `AMINOETHYLPHOSPHONATE` to existing `ACETYL_COA`; the pyruvate/alanine transamination pair and released phosphate are boundary co-chemistry | `PHOSPHONOTASE-PWY` (3), **equivalent** in principal boundary | PhnW `K03430` and PhnX `K05306` identify the substrate and C-P cleavage; the final acetaldehyde dehydrogenase is broad but is downstream of the specific pair. It composes into SCFA and TCA chemistry. Moderate in bacteria exposed to 2-AEP. | **9, recommend.** Map all three reactions to Rhea and test that a broad aldehyde dehydrogenase alone never fires the GIFT. |
| `aminoethylphosphonate_to_phosphonoacetate`: oxidises 2-AEP but leaves the C-P bond intact | metabolic transformation; 2-AEP to phosphonoacetate | `PWY-6832` (2), MetaCyc boundary only | The endpoint is still a phosphonate and the record does not establish utilisation or phosphorus release. The second reaction has only a class-level EC in the structured response. | **2, refuse as a degradation GIFT.** Reconsider only as a composable transformation if a downstream phosphonoacetate-cleavage capability and independently useful boundary are curated. |
| `aminoethylphosphonate_to_glycine`: oxygen-dependent two-step cleavage | metabolic, catabolic; `AMINOETHYLPHOSPHONATE` to existing `GLYCINE`; phosphate is a coproduct, not an anchor | `PWY-7447` (2), **equivalent** | PhnY `K21195` and PhnZ `K21196` jointly resolve 2-AEP and glycine formation; `K05915` is broader and must not substitute without sequence-level validation. It composes with glycine metabolism. Narrower, oxygen-dependent bacterial route. | **9, recommend.** Preserve the oxygen requirement and refuse the broad PhnZ1 marker unless its accepted sequence set is validated for 2-AEP. |
| `substrate_named_c_p_lyase_utilisation` (refused placeholder) | would require an exact substrate-to-product boundary | `PWY0-1533` (5), `PWY-7399` (5), `PWY-8066` (2) and related records; **no link** | PhnGHIJKLM identifies a broad C-P lyase architecture, not methylphosphonate or another named substrate. Gene context cannot make the complex substrate-specific. | **1, refuse.** Reconsider only when a substrate-recognition marker distinguishes the named phosphonate, or propose a defensible broad capability that does not require a class-valued anchor. |

## 8. Polyamine boundaries

This pass confirms the amino-acid proposal's deferred polyamine network and
makes the unresolved point explicit: MetaCyc's pathway boundaries must be split
at agmatine, ornithine and putrescine. The spermidine variants then diverge again
by aminopropyl donor.

| Candidate and claim | Type and boundary | MetaCyc record and relation | Evidence, composition and problem | Score and verdict |
|---|---|---|---|---|
| `arginine_to_agmatine` | metabolic; existing `ARGININE` to new `AGMATINE`; mode unresolved across biosynthetic SpeA and acid-response AdiA systems | shared head of `PWY-40` (2), `PWY-43` (3), `PWY-6834` (4), `PWY2PN3-14` (4); **subset_of** each | The amino-acid proposal records `K01585`, `K01584`, `K02626` and `K01583`. Orthology separates several enzyme systems, but one GIFT mode would conflate biosynthetic and challenge-response uses, while separate phenotype-named GIFTs would overclaim physiology. Broad. | **6, defer.** Resolve the mode using a chemistry-only claim or prove that the enzyme-system split supports two typed capabilities without claiming acid resistance. |
| `agmatine_to_putrescine`: forms putrescine by agmatinase or agmatine-deiminase chemistry | metabolic, anabolic; `AGMATINE` to new `PUTRESCINE` | 1-reaction tail of `PWY-40` (2 total) and 2-reaction tail of `PWY-43` (3 total), each **subset_of** | Agmatinase `K01480`, or agmatine deiminase `K10536` plus N-carbamoylputrescine amidase `K12251`, give two explicit routes. Broad and useful. | **9, recommend** once the two anchors exist. |
| `arginine_to_ornithine`: arginase chemistry | metabolic, catabolic; existing `ARGININE` to existing `ORNITHINE`, with urea coproduct | 1-reaction head of `PWY-46` (2 total), **subset_of** | Arginase is markable but is shared across nitrogen disposal and polyamine supply. The chemistry is exact and composes with the next GIFT. | **7, conditional.** Verify a bacterial arginase marker set that does not confuse agmatinase or other ureohydrolases. |
| `ornithine_to_putrescine`: ornithine decarboxylation | metabolic, anabolic; existing `ORNITHINE` to new `PUTRESCINE` | 1-reaction tail of `PWY-46` (2 total), **subset_of** | Ornithine decarboxylase `K01581` is substrate-specific enough and already estimated in 26.7% of KEGG bacterial genomes by the amino-acid proposal. | **9, recommend.** Retest paralog specificity against lysine/arginine decarboxylases. |
| `spermidine_biosynthesis_routes` (family placeholder, not a GIFT) | at least four metabolic GIFTs because the routes begin from putrescine or agmatine and use decarboxylated SAM or aspartate semialdehyde | `BSUBPOLYAMSYN-PWY` (2), `PWY-6559` (4), `PWY-6834` (4), `PWY2PN3-14` (4); proposed tails are **subset_of** where MetaCyc includes precursor supply | SpeD/SpeE, carboxyspermidine dehydrogenase/decarboxylase and agmatine aminopropyl systems are individually markable. The inputs differ and cannot be alternative routes under one GIFT-level anchor set. Fusions and reverse `RXN-11566` matter. | **5, defer.** Materialise four exact input-boundary claims after AGMATINE and PUTRESCINE exist; do not make one generic spermidine GIFT. |
| `homospermidine_biosynthesis_routes` (family placeholder, not a GIFT) | two metabolic claims with different inputs | `PWY-8149` (1, putrescine) and `PWY-5907` (1, spermidine + putrescine), separately **equivalent** | The EC records overlap and the products are identical, but the substrates are not. Single-reaction product identity is meaningful; breadth is narrow and marker discrimination needs review. | **5, defer.** Reconsider after the spermidine layer and an accession audit separating EC 2.5.1.44/45. |

The polyamine trunk is biologically strong but is not the next release because
the arginine-to-agmatine mode remains unresolved and the downstream routes need
route-specific input boundaries. This explicitly preserves, rather than
rediscovers, the earlier deferral.

## 9. Siderophore and metallophore branches

The existing `SALICYLATE`, `DIHYDROXYBENZOATE_2_3` and `ENTEROBACTIN` anchors
are the correct reusable cuts. Product assembly must remain separate from
secretion, ferric-complex uptake, iron acquisition and virulence.

| Candidate and claim | Type and boundary | MetaCyc record and relation | Evidence, composition and problem | Score and verdict |
|---|---|---|---|---|
| `salicylate_biosynthesis` | existing metabolic GIFT, `CHORISMATE` to `SALICYLATE` | `PWY-6406` (2), `PWY-8321` (3) and `PWY-981` (2) are discovery records; exact xref relation still needs record-by-record comparison | Already curated with PchA/PchB and bifunctional MbtI/Irp9/YbtS systems. | **already covered.** A future release may add the correct MetaCyc xref; no new GIFT. |
| `dihydroxybenzoate_biosynthesis` and `enterobactin_biosynthesis` | existing composable metabolic GIFT pair | `PWY-5901` (3) and `ENTBACSYN-PWY` (8 direct + nested `PWY-5901`) | Already curated in database 2026.20.2; the superpathway is linked only as a wider record. | **already covered.** |
| `aerobactin_biosynthesis`: complete IucABCD assembly | metabolic, anabolic; existing `LYSINE` + `ACETYL_COA` + `CITRATE` to new `AEROBACTIN` | `AEROBACTINSYN-PWY` (4), **equivalent** | IucA–D are exact `K03894`–`K03897`; all four are required. No locus inference, transport or iron-uptake marker is needed. Moderate Enterobacterales and other Proteobacteria breadth. | **10, recommend.** Confirm no Iuc synthetase KO is shared with another hydroxamate product. |
| `salmochelin_s4_biosynthesis`: C-glucosylates enterobactin twice to salmochelin S4 | metabolic, anabolic; existing `ENTEROBACTIN` to new `SALMOCHELIN_S4` | first 2 of `PWY-8023`'s 3 reactions, **subset_of**; the third makes triglucosyl-enterobactin | IroB `K23725` catalyses all successive C-glucosylations. IroC export and IroD/E hydrolysis are excluded. Narrow Enterobacteriaceae breadth but high product specificity. | **9, recommend.** Represent the same IroB marker at both required reaction components and test that exporter/esterase markers alone remain negative. |
| `bacillibactin_biosynthesis` | metabolic, anabolic; existing `DIHYDROXYBENZOATE_2_3` plus glycine/threonine to bacillibactin | `PWY-5903` (9 direct + nested `PWY-5901`), proposed tail **subset_of** the superpathway | DhbE/F and carrier/transferase functions are product-defining, but generic NRPS domain evidence is not. Mostly Bacillales. | **6, defer.** Require product-specific KO/TIGRFAM/custom-HMM evidence for every assembly component without gene-order assumptions. |
| `vibriobactin_biosynthesis` | metabolic, anabolic; existing `DIHYDROXYBENZOATE_2_3` plus norspermidine to vibriobactin | `PWY-6374` (6 direct + nested `PWY-5901`), proposed tail **subset_of** | Vib assembly proteins are plausible markers, but the NRPS and carrier functions need a product-specific audit and norspermidine is not an anchor. Narrow Vibrio breadth. | **6, defer.** Reconsider after the norspermidine/polyamine boundary and marker audit. |
| `pyochelin_family_biosynthesis` (family placeholder, not a GIFT) | metabolic, anabolic; existing `SALICYLATE` plus cysteine to a named stereochemical product | `PWY-6408` (11), `PWY-8539` (12), `PWY-8540` (14); each proposed tail **subset_of** where salicylate synthesis is included | PchE/F-like NRPS evidence and tailoring enzymes must distinguish pyochelin, enantiopyochelin and related products. Locus context cannot be assumed. Narrow Pseudomonas/Burkholderia lineages. | **5, defer.** Require product- and stereochemistry-specific marker systems. |
| `yersiniabactin_biosynthesis` | metabolic, anabolic; existing `SALICYLATE` plus cysteine/malonyl units to yersiniabactin | `PWY-6407` (2 aggregate reactions), provisionally **related** | The two aggregate reactions hide a large NRPS/PKS architecture. Domain markers and a salicylate ligase do not establish the product; cluster context would currently be required. | **4, defer.** Reconsider with product-specific full-protein markers or locus-aware evidence support. |
| `other_named_siderophore_biosynthesis` (screening family, not a GIFT) | metabolic product synthesis, one exact product per eventual candidate | 33 further records listed in §9.1; **no relation proposed while deferred** | NIS synthetases may eventually provide product-specific systems; NRPS, RiPP and opine products usually need a marker/locus pass. Taxonomic breadth ranges from genus-specific to broad hydroxamate families. | **4–7, defer as a set.** Promote records individually only after product-specific assembly evidence clears invariant 16. |

### 9.1 Complete MetaCyc siderophore-class inventory

This is the full set of 40 pathway instances directly classified under
`Siderophores-Biosynthesis` in MetaCyc 30.0. The count is the direct reaction
count; “+ nested” identifies a superpathway-shaped record that must be split.
Deferred rows have no proposed xref relation until that split and their exact
product boundary have been established.

| MetaCyc record | Direct reactions | Assessment |
|---|---:|---|
| `PWY-5912`, 2'-deoxymugineic acid | 4 | defer; plant phytosiderophore |
| `PWY-8539`, enantiopyochelin | 12 | defer; salicylate/NRPS stereochemistry |
| `PWY-6574`, achromobactin | 8 | defer; audit NIS synthetase specificity |
| `PWY-7984`, acinetobactin | 9 | defer; mixed NRPS/non-NRPS assembly |
| `PWY-7989`, acinetoferrin | 4 | defer; audit product-specific synthetases |
| `AEROBACTINSYN-PWY`, aerobactin | 4 | **recommend** |
| `PWY-6379`, alcaligin | 5 | defer; hydroxamate synthetase audit |
| `PWY-7986`, anguibactin | 8 | defer; NRPS/locus dependence |
| `PWY-8558`, avaroferrin | 7 | defer; NIS product specificity |
| `PWY-5903`, bacillibactin | 9 + nested `PWY-5901` | defer; split at DHB and audit NRPS evidence |
| `PWY-7988`, baumannoferrin | 11 | defer; product-specific assembly audit |
| `PWY-6381`, bisucaberin | 5 | defer; hydroxamate synthetase audit |
| `PWY-6375`, desferrioxamine E | 5 | defer; distinguish product from related hydroxamates |
| `PWY-6376`, desferrioxamine B | 5 | defer; distinguish product from related hydroxamates |
| `ENTBACSYN-PWY`, enterobactin | 8 + nested `PWY-5901` | already covered by two current GIFTs |
| `PWY-7571`, ferrichrome A | 5 | defer; fungal/NRPS and narrow breadth |
| `PWY-7577`, ferrichrome | 2 | defer; aggregate NRPS reaction |
| `PWY-8484`, fimsbactin A | 12 | defer; NRPS/locus dependence |
| `PWY-5925`, hydroxylated mugineic acid | 3 | defer; plant phytosiderophore |
| `PWY-8540`, isopyochelin/thiazostatin/watasemycin | 14 | defer; one record has several product outcomes |
| `PWY-8370`, leporin B | 5 | defer; fungal specialised metabolite |
| `PWY-8640`, methanobactin | 7 | defer; RiPP precursor and modification context |
| `PWY-8639`, methylolanthanin | 9 | defer; RiPP precursor and modification context |
| `PWY185E-1`, mycobactin | 11 | defer; salicylate/NRPS and mycobacterial locus |
| `PWY-8383`, myxochelin A/B | 9 | defer; one record has two products |
| `PWY-6289`, petrobactin | 9 | defer; audit NIS synthetase specificity |
| `PWY-7983`, pseudomonine | 9 | defer; NRPS/locus dependence |
| `PWY-8641`, pseudopaline | 2 | defer; metallophore, not an iron-acquisition claim |
| `PWY-6378`, putrebactin | 4 | defer; hydroxamate synthetase audit |
| `PWY-6408`, pyochelin | 11 | defer; split at salicylate and audit NRPS evidence |
| `PWY-6409`, pyoverdine I | 11 | defer; product identity requires a large NRPS locus |
| `PWY-761`, rhizobactin 1021 | 7 | defer; product-specific assembly audit |
| `PWY-8023`, salmochelin | 3 | **recommend the 2-step S4 subset** |
| `PWY-7990`, staphyloferrin A | 3 | defer; audit NIS synthetase specificity |
| `PWY-8008`, staphyloferrin B | 7 | defer; audit NIS synthetase specificity |
| `PWY-8007`, staphylopine | 6 | defer; metallophore, not an iron-acquisition claim |
| `PWY-7987`, vanchrobactin | 8 | defer; NRPS/locus dependence |
| `PWY-6374`, vibriobactin | 6 + nested `PWY-5901` | defer; split at DHB and audit NRPS evidence |
| `PWY-6407`, yersiniabactin | 2 | defer; aggregate NRPS/PKS architecture |
| `PWY-8642`, yersinopine | 2 | defer; metallophore, not an iron-acquisition claim |

## 10. Cofactor and electron-carrier branches

| Candidate and claim | Type and boundary | MetaCyc record and relation | Evidence, usefulness and problem | Score and verdict |
|---|---|---|---|---|
| `siroheme_biosynthesis` | metabolic, anabolic; existing `UROGEN_III` to new `SIROHEME` | `PWY-5194` (4), **equivalent** | Multifunctional CysG `K02302` covers methylation, oxidation and iron insertion. Complete split alternatives use a maintained methyltransferase plus Met8, or SirC plus iron-specific SirB. Broad CbiX evidence remains excluded where metal specificity is unresolved. | **implemented in 2026.20.3.** The accepted expression calls 4,161 bacterial and one archaeal KEGG genome and knowingly under-calls ambiguous archaeal chelatases. |
| `siroheme_to_heme_b` | would be metabolic, anabolic; new `SIROHEME` to existing `HEME_B` | `PWY-7552` (3); **no link while refused** | AhbC `K22226` and AhbD `K22227` are specific, and `K25033` is an exact alternative for the last reaction. The first reaction requires AhbA AND AhbB, but both genes map to `K22225`; one accession cannot evidence two distinct required proteins in the current model. | **refuse.** Reconsider with distinct AhbA/AhbB markers, a fusion-specific marker, or multiplicity-aware evidence. |
| `ubiquinol_biosynthesis_routes` (family placeholder, not a GIFT) | would be metabolic, anabolic; chorismate/4-hydroxybenzoate to an exact ubiquinol | 16 base records: `PWY3O-19` (8), `PWY-8571` (8), `PWY-5855` (8), `PWY-5871` (8), `PWY-8534` (8), `PWY-8533` (8), `PWY-6708` (8), `PWY-5873` (8), `PWY-5870` (9), `PWY-7230` (9), `PWY-5857` (8), `PWY-5856` (8), `PWY-8630` (8), `PWY-5872` (10), `PWY-8535` (8), `PWY-8631` (9); superpathways excluded and **no relation proposed** | Core Ubi proteins are markable, but the polyprenyl-chain-length accession does not reliably establish UQ-6/7/8/9/10, while a generic “a ubiquinol” is not an exact molecular anchor. Anaerobic and early/late decarboxylation are route alternatives only after product identity is solved. | **4, defer.** Reconsider with validated UbiA chain-length subfamilies or an explicit architectural decision permitting a chemically bounded generic quinone anchor. |
| `molybdenum_cofactor_biosynthesis_routes` (family placeholder, not a GIFT) | metabolic cofactor assembly, but exact products include MPT, Mo-MPT and nucleotide-tailed forms | `PWY-6823` (6), `PWY-8171` (3), `PWY-6476` (1), `PWY-8163` (6), `PWY-5963` (1), `PWY-7639` (2), `PWY-8168` (1), `PWY-8165` (2), `PWY-5964` (1), `PWY-8164` (3), `PWY-8167` (4); **no relation proposed**. `PWY-7710` (6) is the FeMo-cofactor record already represented inside the current nitrogen-fixation architecture, not a separate candidate. | Moe/Moa proteins are markable and the capability partitions genomes, but the catalogue records several target-enzyme-specific cofactor forms. One “Moco biosynthesis” GIFT would bundle independently meaningful branches; routine insertion into target proteins is activation, not a trait. | **5, defer.** A dedicated cofactor proposal must cut MPT synthesis, metal insertion and nucleotide-tail branches and show which products merit anchors. |
| `lipoate_biosynthesis_and_incorporation` (refused placeholder) | protein modification rather than free-metabolite synthesis | `PWY0-501` (2), `PWY0-1275` (3), `PWY-6987` (3), `PWY-8572` (4), `PWY0-522` (2), `PWY-6984` (5), `PWY-7382` (10), `PWY0-501-1` (3); **no link while refused** | LipB/LipA chemistry modifies target lipoyl domains; the endpoint is a protein-bound cofactor, not a small-molecule anchor. Target-domain availability and salvage/incorporation are outside the metabolic route contract. | **2, refuse under the current types.** Reconsider only with an explicit protein-modification completeness model, not by inventing a free-lipoate boundary. |
| `factor_f420_biosynthesis_routes` (family placeholder, not a GIFT) | metabolic, anabolic; central precursor(s) to an exact deazaflavin cofactor | `PWY-8112` (5, archaea), `PWY-8113` (5, 3PG-F420) and `PWY-5198` (6, mycobacteria); **no relation proposed while split is unresolved** | CofC/D/E/G/H markers are comparatively specific and the product partitions methanogens, actinobacteria and some other bacteria. The three records differ in phospholactyl versus 3-phosphoglycerate-derived head groups and must not be routes of one exact-product GIFT. | **6, defer.** Resolve product nomenclature, alternative head-group boundaries and bacterial prevalence in a dedicated electron-carrier proposal. |

## 11. Storage and specialised cellular compounds

| Candidate and claim | Type and boundary | MetaCyc record and relation | Evidence, usefulness and problem | Score and verdict |
|---|---|---|---|---|
| `cyanophycin_biosynthesis`: encodes polymer assembly from aspartate and arginine | metabolic, anabolic; existing `ASPARTATE` + `ARGININE` to new `CYANOPHYCIN` | synthetic half is **subset_of** `PWY-7052` (6 total: synthesis and degradation) | CphA `K03802` carries both EC 6.3.2.29 and 6.3.2.30. MetaCyc lists primer and extension versions of the same activities; curation must materialise one minimal complete synthesis route, not require duplicated chemistry. Cyanobacteria and scattered bacteria. | **9, recommend.** Keep CphB `K13282` degradation separate and claim neither storage accumulation nor nitrogen status. |
| `branched_alpha_glucan_biosynthesis` (provisional evidence-bounded name) | metabolic, anabolic; existing `GLUCOSE_1P` to a defensibly named branched alpha-glucan | proposed three-step tail is **subset_of** `GLYCOGENSYNTH-PWY` (4); `PWY-7900` (8) is a distinct GlgE route; eukaryotic `PWY-5067` excluded | GlgC/GlgA/GlgB are jointly markable, but glycogen synthase/starch synthase naming and the GlgE product make “glycogen” more specific than some markers. Very broad and biologically useful. | **7, conditional.** Decide whether the evidence supports `glycogen_biosynthesis` or only `branched_alpha_glucan_biosynthesis`, and keep the GlgE boundary separate. |
| `polyhydroxyalkanoate_biosynthesis` (refused placeholder) | would be metabolic, anabolic; acyl-CoA monomer to a named polymer | `PWY1-3` (3), `PWY-6657` (3), engineered records excluded; **no link while refused** | `K03821` is a broad PHA polymerase and cannot establish PHB or polyhydroxydecanoate monomer identity. Upstream monomer-supply genes do not repair polymerase specificity. | **1, refuse; already recorded for PHB.** Reconsider only with validated PhaC subfamily/custom-HMM evidence. |
| `hopanoid_biosynthesis_segments` (family placeholder, not a GIFT) | metabolic product synthesis; squalene to an exact hopanoid | `PWY-7072` (11); proposed core/tails would be **subset_of** | Squalene-hopene cyclase can establish the hopene core, but the 11-reaction record bundles core cyclisation and extended side-chain products. Several Hpn proteins are poorly resolved by KO and taxonomically patchy. | **6, defer.** Split core hopene from bacteriohopanepolyol tailoring and require product-specific downstream markers. |
| `ergothioneine_biosynthesis` | metabolic, anabolic; existing `HISTIDINE`, `CYSTEINE` and `GLUTAMATE` to new `ERGOTHIONEINE` | `PWY-7255` (7), **equivalent** for the bacterial Egt route; fungal `PWY-7550` is a different route | EgtA/GshA `K01919`, EgtD `K18911`, EgtB `K18912`, EgtC `K07008` and EgtE `K18913` give a specific spine. Tautomerisation/spontaneous steps must not receive invented markers. Moderate Actinobacteria/Cyanobacteria/Proteobacteria breadth. | **9, recommend.** Audit known EgtB/Egt1 alternatives and fusions before materialising routes. |
| `glutathione_biosynthesis` | metabolic, anabolic; existing `GLUTAMATE` + `CYSTEINE` + `GLYCINE` to new `GLUTATHIONE` | `GLUTATHIONESYN-PWY` (2), **equivalent** | Separate `K01919` + `K01920` and fused GshAB `K28983` are two complete systems. Broad but not universal; complements bacillithiol/mycothiol lineages. No redox state, export or stress phenotype is claimed. | **10, recommend.** Validate `K06048` before considering it an alternative GshA marker because it is a broader carboxylate-amine ligase. |
| `bacillithiol_biosynthesis` | metabolic, anabolic; UDP-GlcNAc + malate + cysteine to new `BACILLITHIOL` | `PWY8J2-1` (3), **equivalent** | BshA `K00754`, BshB1/BshB2 `K01463`/`K22135` and BshC `K22136` give explicit alternatives and AND logic. Mostly Firmicutes; strongly partitions low-molecular-weight thiol strategies. | **9, recommend.** Confirm BshA's marker does not admit unrelated malate glycosyltransferases. |
| `mycothiol_biosynthesis` | metabolic, anabolic; glucose 6-phosphate/UDP-GlcNAc + cysteine to new `MYCOTHIOL` | `PWY1G-0` (6), **equivalent** only if every required step is evidenceable | MshA/B/C/D have specific `K15521`, `K15525`, `K15526`, `K15520`, but the structured record's phosphatase step `RXN-11015` has no named enzyme or EC. Ignoring it would collapse a required reaction. Mostly Actinobacteria. | **6, defer.** Identify a defensible marker or documented spontaneous/housekeeping completion rule for the phosphatase step. |

Glutathione, bacillithiol, mycothiol and ergothioneine were the strongest
unseeded discovery cluster. They should eventually be handled as a coherent
low-molecular-weight protective-metabolite layer, but mycothiol's marker gap is
why that layer is not the immediate release.

## 12. Chemical-defense mechanisms and formaldehyde classification

KO names in this section were rechecked against the current official entries
on 2026-08-20. In particular, [`K00148`](https://rest.kegg.jp/get/K00148) is
now explicitly glutathione-independent formaldehyde dehydrogenase, whereas
[`K04063`](https://rest.kegg.jp/get/K04063) is OsmC/Ohr lipoyl-dependent
peroxiredoxin. Those definitions supersede the broader marker descriptions in
the older defense proposal for this reconnaissance decision.

| Candidate and claim | Type and completeness model | MetaCyc record and relation | Evidence, overlap and problem | Score and verdict |
|---|---|---|---|---|
| `formaldehyde_detoxification_glutathione`: complete glutathione-dependent conversion to formate | defense; one mechanism requires FrmA dehydrogenase AND FrmB hydrolase; spontaneous adduct formation is not a component | `PWY-1801` (3), **equivalent** in chemical extent | `K00121` + `K01070` are the recorded pair. The same chemistry is carbon metabolism in methylotrophs, so the claim must remain enzymatic conversion, not purpose, survival or resistance. It is not already covered by `methylamine_degradation`, which leaves formaldehyde internal. | **8, recommend.** Verify that the KO pair, not FrmA alone, resolves the glutathione route. |
| `formaldehyde_detoxification_bacillithiol` and `formaldehyde_detoxification_mycothiol` | defense mechanisms with the cognate thiol-specific dehydrogenase/hydrolase functions | `PWY-7908` (3) and `PWY1G-170` (3), separately **equivalent** | The pathway records are chemically coherent, but enzyme markers and reducing-system completeness need review; the thiol biosynthesis GIFT should not be made a required component because substrate availability is separate from detox machinery. Narrow lineage-specific alternatives. | **6, defer.** Reconsider after bacillithiol/mycothiol marker audits and keep the two mechanisms separate. |
| `formaldehyde_detoxification_thiol_independent`: complete NAD-dependent conversion of formaldehyde to formate | defense; one complete, substrate-specific dehydrogenase system | `FORMASS-PWY` (1), **equivalent** in chemical extent | Current `K00148` is explicitly glutathione-independent formaldehyde dehydrogenase (EC 1.2.1.46), not a generic aldehyde-dehydrogenase marker. MetaCyc gives formaldehyde + NAD + water to formate + NADH + 2 H+. The same chemistry can support C1 metabolism, so the GIFT claims only the encoded toxicant-conversion mechanism, not purpose, resistance or survival. | **8, recommend.** Confirm Rhea identity/direction and check that every admitted sequence retains EC 1.2.1.46 specificity. |
| `formaldehyde_oxidation_h4mpt` and `formaldehyde_oxidation_thf` | metabolic C1 conversion, not automatically defense | `PWY-1723` (4) and `PWY-7909` (4); respectively **related** and **no link while refused as defense** | H4MPT chemistry is characteristic of methylotrophs; THF enzymes are shared one-carbon metabolism. Genomic evidence does not identify a detoxification purpose, and the THF route is directionally broad. | **4, defer H4MPT; refuse THF as defense.** Reconsider H4MPT as a metabolic GIFT with exact C1 boundaries. |
| `formaldehyde_assimilation_rump` | metabolic, anabolic/catabolic boundary pass required; formaldehyde + ribulose-5-phosphate to fructose-6-phosphate | product-defining subset of `RUMP-PWY` (6) | Hps/Phi can distinguish RuMP assimilation, while four listed reactions are central pentose-phosphate chemistry and should not be duplicated. This is an unseeded methylotrophy candidate, not a defense mechanism. | **7, conditional.** Cut the two product-defining reactions and audit direction-specific markers. |
| `nitric_oxide_detoxification` | defense; ANY complete Hmp or NorVW mechanism, not an NO-resistance trait | no dedicated base pathway in the MetaCyc 30.0 pathway catalogue; reaction-level provenance required | Hmp `K05916` is a complete aerobic NO-dioxygenase system; NorV `K12264` requires its reductase partner. Hcp `K05601` is not admitted without a validated electron-delivery/clearance architecture. Moderate bacterial breadth. | **8, conditional.** Resolve exact Rhea products, NorVW AND logic and oxygen-labelled alternatives. |
| `hydrogen_peroxide_detoxification` | defense; ANY complete catalase/peroxidase system | a standalone claim is **subset_of** `DETOX1-PWY` (2) and `DETOX1-PWY-1` (4 + nested), whose superoxide scope is wider | Catalase, catalase-peroxidase, manganese catalase and AhpC/AhpF systems are already curated as the peroxide-removal function inside `superoxide_detoxification`. A standalone GIFT would reuse those systems and call catalase-only genomes, but must not duplicate rows. | **8, conditional.** Demonstrate shared-function reuse and test that the existing superoxide GIFT still requires both functions. |
| `organic_hydroperoxide_detoxification` | defense; complete organic-hydroperoxide reducing system | no dedicated base pathway found | Current `K04063` names OsmC/Ohr as a lipoyl-dependent peroxiredoxin (EC 1.11.1.28), not as an organic-substrate-specific marker. It therefore cannot by itself license the proposed substrate class, and the required lipoyl reducing context is not yet represented. | **5, defer; refuse `K04063` alone.** Reconsider only with validated substrate-range evidence and a complete reducing architecture whose claim is no narrower than its markers. |
| `tellurite_methylation` | defense only if a complete conversion to a less harmful defined product is encoded | no dedicated base pathway found | TehB `K16868` is named tellurite methyltransferase, but one methyltransferase hit does not yet establish repeated methylation to volatile dimethyl telluride; transport/resistance genes are excluded. | **4, defer.** Require exact reaction stoichiometry, product and proof that K16868 completes the mechanism. |
| `cuprous_copper_oxidation` | defense only if periplasmic Cu(I) to Cu(II) conversion is encoded | no dedicated base pathway found | CueO `K14588` is a cuproxidase but also a multicopper oxidase; the protective chemistry depends on periplasmic localisation, which a bare KO hit does not observe. Copper efflux is transport and cannot be bundled. | **3, refuse under current evidence.** Reconsider with a localisation-aware, CueO-specific marker or evidence model. |
| `cyanide_detoxification_hydratase`: cyanide to formate/ammonium through a complete hydratase route | defense; cyanide hydratase plus formamidase, or a validated cyanide dihydratase system | `PWY-7142` (2), provisionally **equivalent** | `K10675` cyanide hydratase or `K18282` CynD can establish cyanide chemistry; the downstream formamidase is broad but required only in the two-step route. This is an unseeded, taxonomically patchy candidate. | **7, conditional.** Map the one- and two-step mechanisms separately. `P401-PWY` (1) and `ASPSYNII-PWY` (3) remain refused because beta-cyanoalanine synthase overlaps cysteine synthase chemistry. |

The defense-class definition already covers every acceptable mechanism. No
candidate creates a resistance facet or mixes transformation with efflux,
regulation, repair or survival.

## 13. Complete decision register

This compact register makes the disposition of every candidate family easy to
audit. Details and retriggers are in the cited sections.

| Candidate family | Verdict | Section |
|---|---|---:|
| Trehalose phosphosugar routes I–III | defer | 4 |
| Maltose/trehalose interconversion | conditional | 4 |
| Glucan-to-trehalose route V | defer | 4 |
| Free-glucose trehalose routes VI–VII | defer | 4 |
| Ectoine degradation | **recommend** | 4 |
| Glycine-to-betaine synthesis | conditional | 4 |
| Mannosylglycerate routes | conditional | 4 |
| Glucosylglycerol synthesis | conditional | 4 |
| Microbial sucrose synthesis | defer | 4 |
| DMSP cleavage to acrylate/DMS | **recommend** | 5 |
| DMSP cleavage to 3HP-CoA/DMS | **recommend** | 5 |
| DMSP demethylation | **recommend** | 5 |
| Calvin cycle | defer; atomic split required | 6 |
| Bacterial Wood-Ljungdahl pathway | conditional | 6 |
| Methanogenic Wood-Ljungdahl pathway | defer | 6 |
| Reductive glycine fixation | **refuse as named** | 6 |
| Reductive TCA variants | defer; derived-cycle model | 6 |
| 3HP and 3HP/4HB cycles | defer; derived-cycle model | 6 |
| 2-AEP to acetyl-CoA | **recommend** | 7 |
| 2-AEP to phosphonoacetate | **refuse as degradation** | 7 |
| 2-AEP to glycine | **recommend** | 7 |
| Substrate-specific claims from generic C-P lyase | **refuse** | 7 |
| Arginine-to-agmatine | defer on mode | 8 |
| Agmatine-to-putrescine | **recommend** after anchors | 8 |
| Arginine-to-ornithine | conditional | 8 |
| Ornithine-to-putrescine | **recommend** | 8 |
| Spermidine and homospermidine families | defer on route-level boundaries | 8 |
| Salicylate, 2,3-DHB and enterobactin | **already covered** | 9 |
| Aerobactin | **recommend** | 9 |
| Salmochelin S4 | **recommend** | 9 |
| Bacillibactin and vibriobactin | defer on product-specific assembly markers | 9 |
| Pyochelin and yersiniabactin families | defer on NRPS/PKS evidence | 9 |
| Remaining named siderophores/metallophores | defer individually | 9.1 |
| Siroheme synthesis | **implemented in 2026.20.3** | 10 |
| Ahb siroheme-to-heme tail | **refuse at current multisubunit evidence** | 10 |
| Ubiquinol family | defer on exact chain-length/product evidence | 10 |
| Molybdopterin/Moco family | defer to cofactor architecture pass | 10 |
| Lipoate synthesis/incorporation | **refuse under current types** | 10 |
| Factor F420 family | defer on product branches | 10 |
| Cyanophycin synthesis | **recommend** | 11 |
| Branched alpha-glucan/glycogen synthesis | conditional on claim name | 11 |
| PHB and other PHA products | **refuse; PHB already recorded** | 11 |
| Hopanoid synthesis | defer on core/tail split | 11 |
| Ergothioneine synthesis | **recommend** | 11 |
| Glutathione synthesis | **recommend** | 11 |
| Bacillithiol synthesis | **recommend** | 11 |
| Mycothiol synthesis | defer on missing phosphatase evidence | 11 |
| Glutathione-dependent formaldehyde detoxification | **recommend** | 12 |
| Bacillithiol/mycothiol formaldehyde mechanisms | defer | 12 |
| Thiol-independent formaldehyde detoxification | **recommend** | 12 |
| THF formaldehyde oxidation as defense | **refuse as named** | 12 |
| H4MPT formaldehyde oxidation | defer as metabolic, not defense | 12 |
| RuMP formaldehyde assimilation | conditional as metabolic | 12 |
| Nitric-oxide detoxification | conditional | 12 |
| Hydrogen-peroxide detoxification | conditional; reuse current function | 12 |
| Organic-hydroperoxide removal | defer; **refuse `K04063` alone** | 12 |
| Tellurite methylation | defer | 12 |
| Cu(I) oxidation | **refuse under current evidence** | 12 |
| Cyanide hydratase/dihydratase detoxification | conditional | 12 |

## 14. Follow-up required before any implementation

### 14.1 Work common to every recommended candidate

1. Map every reaction to the current Rhea master, record its route orientation,
   and refuse any reaction without a Rhea master unless another stable xref is
   available.
2. Retrieve ChEBI identities for every proposed new anchor and test whether the
   molecule is a meaningful boundary rather than an internal intermediate or
   class-valued placeholder.
3. Enumerate alternative enzyme systems and jointly required components. Check
   fusions, multifunctional proteins and non-homologous replacements explicitly.
4. Audit every KO against its current definition and add EC, TIGRFAM, PFAM or a
   validated custom HMM only where that namespace supports the same specificity.
5. Run a current bacterial/archaeal prevalence pass. Prevalence does not decide
   truth, but it exposes missing markers, lineage-only implementations and
   candidate claims that merely track universal housekeeping.
6. Compare the proposed edges to `gift_graph()` and the directed-mode cycle
   check. Shared internal participants must not create edges.
7. Write positive, one-component-missing, alternative-system, fusion,
   multifunctional-marker, broad-marker-negative and evidence-trace tests before
   changing biological TSVs.
8. Record accepted and refused evidence, boundary decisions, the database
   release and affected GIFTs in the source change tables at implementation
   time.

### 14.2 Outcome and remaining work for the siroheme branch

- Completed: `RHEA:32459` forward, `RHEA:15613` forward and `RHEA:24360`
  reverse define the upstream route; multifunctional and split systems are
  materialised; `SIROHEME` is the sole new anchor; and `PWY-5194` is linked as
  equivalent in boundary.
- Completed: positive CysG, Met8 and SirC/SirB alternatives; missing-reaction,
  broad-chelatase-negative, traceability and graph-boundary behavior are tested.
- Refused: do not attach `PWY-7552` to `heme_b_biosynthesis` or add an Ahb route
  while `K22225` can make one observed gene stand in for AhbA and AhbB.
- Reconsideration requires a maintained AhbA marker plus a distinct AhbB
  marker, a validated fusion-specific marker, or a model change that can demand
  two distinct observed genes carrying the same accession. At that point,
  materialise separate final-reaction routes for `RHEA:56520` AhbD and
  `RHEA:56516` peroxide-dependent heme synthase.

## 15. Recommendation to the maintainer

Retain the implemented upstream siroheme GIFT and the explicit downstream Ahb
refusal. Do not treat the absent graph edge from `SIROHEME` to `HEME_B` as a
data gap: it is the visible consequence of evidence specificity. Keep ectoine
degradation, glutathione, aerobactin, ergothioneine,
salmochelin S4, the two complete 2-AEP routes, the three distinct DMSP branches,
cyanophycin, bacillithiol and thiol-independent formaldehyde detoxification in
the ready queue, each as its own reviewable release or coherent layer.

Do not implement a generic trehalose, DMSP-degradation, carbon-fixation,
phosphonate-utilisation, siderophore, Moco, ubiquinone, PHA, resistance or
polyamine checklist. The catalogue-wide pass found strong chemistry, but the
value of the result is precisely that its boundaries, alternatives and refusals
remain visible rather than being flattened into MetaCyc pathway presence.
