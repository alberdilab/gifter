# Curation proposal: aromatic compound degradation and mercury detoxification GIFTs

Status: **accepted and implemented in database version 2026.19.1 (schema 6),
except for mercury, which was carved out to be assessed separately.** Evidence
test applied 2026-08-18 against database version 2026.16.1 (schema 6), the KEGG
release of 2026-08-18 (11 949 genome entries), Rhea release 141, and
InterPro/NCBIfam as served on the same day. The implementation record, including
every point where the curated result departs from what §8 proposed, is §16.

Scope: decide whether the 21 requested "xenobiotic degradation" capabilities can
be expressed as GIFTs, and identify what must be architecturally true before any
of them can be curated.

The short answer is that **the request is a KEGG module category, not a
biological layer**, that the ontology and the runtime need **no change** for the
part that survives, and that **the compounds that survive the evidence test are
almost none of the xenobiotics**. Of 24 candidates examined, 6 are recommended
for curation, 2 conditionally, 2 deferred, and 14 refused — the refusals almost
all for the same reason, which is that ring-hydroxylating dioxygenase substrate
specificity is not resolvable by any marker in any namespace giftr can use.
What survives is the *natural* aromatic core: benzoate, catechol, phenylacetate,
phenylpropanoate, anthranilate — plant, host and fermentation chemistry that
happens to sit in KEGG's xenobiotics drawer. Mercury survives too, but not as a
metabolic GIFT.

---

## 1. Recommendation in one page

1. **Do not create a `xenobiotic_degradation` GIFT, facet value, or layer name.**
   "Xenobiotic" is a statement about a compound's *origin relative to an
   organism*, not about chemistry, and the requested list proves it: caffeine
   and *trans*-cinnamate are plant products, anthranilate is a tryptophan
   catabolite, phenylacetate is a fermentation product of phenylalanine, and
   mercury is an element. The coherent layer is **aromatic ring catabolism**,
   with mercury as a separate one-GIFT case. §3.
2. **Curate five metabolic GIFTs first**, in this order:
   `benzoate_degradation_catechol`, `catechol_ortho_cleavage`,
   `catechol_meta_cleavage`, `oxopentenoate_degradation`,
   `phenylacetate_degradation`. All are KEGG-module-backed, Rhea-backed at every
   step, and complete in 648–2300 genomes. §8.1–§8.5.
3. **Split KEGG's modules where its OR mixes substrates.** M00569 hides the
   generic lower *meta* pathway that four other upper pathways also use; curating
   it once as `oxopentenoate_degradation` is what invariant 8 requires, and it is
   the anchor any future biphenyl, cumate or xylene route would attach to.
   M00545 ORs two *different input substrates* into one "*trans*-cinnamate"
   module; giftr may not do that, because a route must connect the GIFT's own
   declared boundaries. §8.5, §8.6, §10.5.
4. **Curate mercury as a `defense` GIFT, not a metabolic one.** Hg(II) → Hg(0)
   is real chemistry with a Rhea master, but it is neither anabolic, catabolic,
   transport nor interconversion, and inventing a fifth `mode` for one trait is
   the wrong trade. The defense contract already says "biological *or chemical*
   challenge", the machinery model already supports the accessory
   organomercurial and transport functions with `required = 0`, and merA has a
   specific NCBIfam HMM. It needs one new `defense_class` facet value,
   `chemical_detoxification` — named for the mechanism, because a class named
   for the metal would hold three curatable members ever and a class named for
   resistance would name an outcome giftr does not claim. §8.8, §10.3, §10.6.
5. **Refuse every capability whose claim rests on a ring-hydroxylating
   dioxygenase α subunit**: toluene (both routes), benzene, xylene, cumate,
   *p*-cymene, biphenyl, carbazole, naphthalene, terephthalate. The refusal is
   not about annotation coverage — it is that the only sequence families
   available are `IPR001663` "aromatic-ring-hydroxylating dioxygenase, alpha
   subunit" and the Rieske domain, both substrate-blind, and KEGG's own KO names
   admit the promiscuity (`K03268` is "benzene/toluene/chlorobenzene
   dioxygenase"). Unlike butyrate, **no namespace change rescues these.** §9.1.
6. **Re-scope KEGG's benzene module rather than refusing it outright.** M00548's
   marker set (`dmpKLMNOP`) is a phenol 2-monooxygenase. It cannot evidence
   benzene oxidation, but it does evidence `phenol_hydroxylation`
   (phenol → catechol) in 206 genomes — and phenol is a real product of gut
   tyrosine fermentation, which makes the re-scoped trait more useful than the
   one requested. §8.7.
7. **Refuse caffeine on evidence, not on interest.** `ndmA`/`ndmB`/`ndmC` are
   annotated in 5, 2 and 10 KEGG genomes, **zero** genomes complete M00915, the
   NdmD reductase that all three demethylases require has no KO at all, and the
   alternative caffeine dehydrogenase route has none either. §9.3.
8. **Accept one architectural gap and work around it by curation, not by
   migration.** `enzyme_component` has no `required` column, so a Rieske
   system's generic ferredoxin and reductase subunits — which are shared,
   interchangeable and systematically under-annotated (`andAa` 101 genomes
   against `andAc` 281; `pht2` 99 against `pht3` 279) — would turn into false
   negatives under AND. Curate the substrate-determining subunits only and say
   so in the system description. Do not add a `required` flag to
   `enzyme_component` for this layer. §10.1.
9. **Do not accept `K07104` as evidence of catechol 2,3-dioxygenase.** It is
   assigned in 2081 genomes dominated by *Bacillus*, *Streptococcus*,
   *Staphylococcus* and *Listeria*, only 276 of which carry any downstream *meta*
   pathway gene. Use `K00446` (335 genomes), optionally with NCBIfam `TIGR03211`.
   The route AND-logic would mask most of the damage inside this GIFT, but the
   marker would still be in the database for the next GIFT to reuse. §10.2.
10. **Expect the whole aromatic layer to be silent in strict anaerobes**, because
    every accepted route is oxygen-dependent, and record that per route in
    `gift_route.oxygen_requirement` rather than on the GIFT. The one anaerobic
    entry point in the request — benzoyl-CoA reduction — is annotated in 16 to 31
    genomes and is refused for now. §10.4, §9.2.

Cost of the recommended set: 8 metabolic GIFTs and 1 defense GIFT, ~11 new
anchors on the current 89, ~34 new reactions on 226, 3 new `gift` facet values
and 1 new `defense_class` value. No schema migration, no R change.

---

## 2. What was actually requested

The 21 lines supplied are, with two exceptions, the exact contents of KEGG's
`Pathway modules; Xenobiotics biodegradation; Aromatics degradation` category —
including its duplicate compound names, which are duplicate *modules*, not
duplicate requests. Reading them as modules is what makes the list answerable:

| Requested | KEGG module | Module name |
|---|---|---|
| Toluene | M00538 | Toluene degradation, toluene => benzoate |
| Toluene | M00418 | Toluene degradation, **anaerobic**, toluene => benzoyl-CoA |
| Xylene | M00537 | Xylene degradation, xylene => methylbenzoate |
| Benzene | M00548 | Benzene degradation, benzene => catechol |
| Benzoate | M00551 | Benzoate degradation, benzoate => catechol / methylbenzoate => methylcatechol |
| Benzoate | M00540 | Benzoate degradation, **cyclohexanecarboxylate** => pimeloyl-CoA |
| Anthranilate | M00637 | Anthranilate degradation, anthranilate => catechol |
| Catechol | M00568 | Catechol **ortho**-cleavage, catechol => 3-oxoadipate |
| Catechol | M00569 | Catechol **meta**-cleavage, catechol => acetyl-CoA |
| Cumate | M00539 | Cumate degradation, p-cumate => 2-oxopent-4-enoate + 2-methylpropanoate |
| Biphenyl | M00543 | Biphenyl degradation, biphenyl => 2-oxopent-4-enoate + benzoate |
| Carbazole | M00544 | Carbazole degradation, carbazole => 2-oxopent-4-enoate + anthranilate |
| Benzoyl-CoA | M00541 | Benzoyl-CoA degradation, benzoyl-CoA => 3-hydroxypimeloyl-CoA |
| Naphthalene | M00534 | Naphthalene degradation, naphthalene => salicylate |
| Salicylate | M00638 | Salicylate degradation, salicylate => gentisate |
| Terephthalate | M00624 | Terephthalate degradation, terephthalate => 3,4-dihydroxybenzoate |
| Phthalate | M00623 | Phthalate degradation, phthalate => protocatechuate (4,5-dioxygenase) |
| Phenylacetate | M00878 | Phenylacetate degradation, phenylacetate => acetyl-CoA/succinyl-CoA |
| Trans-cinnamate | M00545 | Trans-cinnamate degradation, trans-cinnamate => acetyl-CoA |
| Caffeine | M00915 | Caffeine degradation, caffeine => xanthine |
| Mercury | — | **not a KEGG module**; the *mer* operon, §8.8 |

Three modules of the same KEGG category were not requested and are assessed
anyway, because refusing a compound while its sibling module goes unexamined
would leave the register incomplete: M00419 (*p*-cymene), M00547
(benzene/toluene dioxygenase) and M00636 (phthalate 3,4-dioxygenase).

Two of the requested lines are misread if taken as compounds. "Benzoate"
M00540 is not benzoate degradation: it is the **cyclohexanecarboxylate** entry
into the anaerobic benzoyl-CoA route, and its input is an alicyclic acid. And
the two "Catechol" lines are not two ways of describing one capability — ortho
and meta cleavage produce entirely different products and connect to central
metabolism at different points, which is exactly the OR-over-routes case giftr
exists to represent, except that here the two are different enough to be
different GIFTs (§8.2, §8.3).

---

## 3. "Xenobiotic" is not a giftr category

A GIFT names a capability. `xenobiotic` names a *relationship between a compound
and an organism that did not evolve with it*, which is neither chemistry nor
genome content, and it partitions the requested list in a way biology does not
recognise:

- **Plant secondary metabolites**: *trans*-cinnamate, 3-phenylpropanoate,
  salicylate, caffeine, benzoate (also a food preservative).
- **Amino acid catabolites**: anthranilate (tryptophan, via kynurenine),
  phenylacetate (phenylalanine fermentation), phenol (tyrosine fermentation).
- **Genuine anthropogenic pollutants**: toluene, xylene, benzene, biphenyl,
  carbazole, naphthalene, phthalate, terephthalate, *p*-cymene/cumate.
- **An element**: mercury.

Only the third group is xenobiotic in any defensible sense, and it is precisely
the group that fails the evidence test. The name for what survives is
**aromatic ring catabolism**, and the file is named accordingly.

This also settles the facet question. There must be no
`physiological_role = xenobiotic_degradation`, because a facet classifies what a
call *is*, and the same enzyme set that acts on benzoate from a plant acts on
benzoate from a factory. Compound origin belongs where giftr already puts
origin: on the anchor, as `resource_origin`, multi-valued (§11).

Invariant 18 is the deeper reason. "Pollutant degrader", "bioremediation
potential" and "xenobiotic metabolism" are higher-order ecological descriptions.
They are derivable — a filter over `anchor_facet.resource_origin` and the
substrate class — and must not be curated as primary GIFTs.

---

## 4. What the ontology and the runtime already support

Four things were checked, and only one is a gap.

**Nothing in the accepted set needs a schema migration.** Every accepted
metabolic GIFT is anchors + routes + reactions + systems + components +
markers, with `mode = 'catabolic'`. Mercury is one `gift_mechanism` with four
`defense_function` rows, two of them accessory — the same shape the type I-E
CRISPR mechanism already uses for spacer acquisition.

**`oxygen_requirement` is already a route property, and this layer needs it
badly.** Aerobic ring hydroxylation and anaerobic ring reduction are alternative
solutions to the same problem, and recording oxygen per route is what lets a
future anaerobic benzoyl-CoA route sit beside an aerobic one under the same
GIFT without either claim contaminating the other.

**Multifunctional markers are already handled, and this layer needs that too.**
`K00074` (`paaH`/`hbd`/`fadB`/`mmgB`) is already curated in giftr as a component
marker of `butyrate_formation`, and the phenylacetate route's β-oxidation tail
needs the same KO. That is the multifunctional-marker case working as designed,
not a collision. It is the only one of the 146 KOs in the requested modules that
giftr already uses.

**The gap: `enzyme_component` has no `required` column.** The three machinery
models can mark a function accessory (`architecture_function.required`,
`circuit_function.required`, `mechanism_function.required`), and a route can mark
a reaction accessory (`route_reaction.required`), but every component of an
enzyme system is jointly required with no way to say otherwise. §10.1 explains
why that matters here and why the answer is a curation decision rather than a
migration.

---

## 5. What each source supplies

| Source | What it gives this layer | What it does not |
|---|---|---|
| **Rhea** | A master reaction for **all 66** ECs queried across all 24 candidates, including class-level ones (`RHEA:18777`, "an alkylmercury + H(+) = an alkane + Hg(2+)") | Nothing about which genes do it — and in two cases it *contradicts* KEGG's gene-to-reaction assignment (§10.5) |
| **KEGG modules** | Boundaries for 23 of the 24 candidates, and the observation that its OR sometimes crosses substrates | A module for mercury; module boundaries that survive giftr's route contract unedited |
| **KEGG orthology** | 146 KOs, of which the substrate-determining ones are frequently explicit about their promiscuity in the KO *name* — `benzoate/toluate`, `benzene/toluene/chlorobenzene`, `phenol/toluene`, `3-phenylpropionate/trans-cinnamate` | Any orthology group that separates the substrates of a Rieske dioxygenase |
| **InterPro / NCBIfam** | The markers that make three traits curatable: `TIGR02053` (MerA), `NF033555`/`IPR004927` (MerB), `TIGR02155` (PaaK), plus `TIGR03211` (catechol 2,3-dioxygenase) | Any substrate-specific family for a ring-hydroxylating dioxygenase α subunit. The closest entries are `IPR001663` and `PS00570`, both of which are *the family signature itself* |
| **ChEBI** | Anchor identity for all 11 proposed anchors | — |

The InterPro row is the decisive one, and it is the difference between this layer
and the SCFA layer. There, KEGG organised the biology badly and a TIGRFAM
rescued the trait. Here, **the sequence families themselves do not carry the
distinction the traits are named for**, because substrate range in the Rieske
oxygenases is set by a handful of active-site residues, and an HMM over the
family cannot see them.

---

## 6. The test

The SCFA test, with a third clause this layer forces:

```text
does a marker exist whose specificity matches the substrate named in the trait?
        |
        +-- no  --> refuse the trait, or rename it to the substrate range the
        |            marker actually resolves
        |
        +-- yes --> does the marker's chemistry match the reaction it is
                    attached to?
                        |
                        +-- no  --> the module is wrong, not the trait; re-scope
                        |            to the chemistry the marker does catalyse
                        |
                        +-- yes --> is the trait complete in enough genomes to
                                    be a claim rather than an annotation artefact?
                                        |
                                        +-- no  --> refuse, with a re-test
                                        |            condition
                                        +-- yes --> curate
```

The second clause is new. In the SCFA layer, every KEGG marker at least
catalysed the reaction KEGG attached it to; the question was only whether it was
substrate- and direction-specific. Here two modules attach a marker set to
chemistry it does not perform (§10.5), which is a different failure and needs a
different remedy: re-scope rather than refuse.

The third clause needs a stated threshold, and this proposal uses **complete in
≥ 50 KEGG genomes** as the line for curating now, with anything between 20 and
50 deferred with a re-test condition and anything below 20 refused. The number
is not biological — it is a statement about when an annotation-derived trait
stops being a description of one sequenced isolate's plasmid.

---

## 7. Outcome when the test was applied, 2026-08-18

Prevalence is the number of KEGG genomes carrying a KO, out of 11 949 genome
entries; "complete" is KEGG's own module completeness count, which applies the
module's AND/OR logic. Marker sets were taken from module `DEFINITION` lines and
gene lists from `https://rest.kegg.jp/link/genes/ko:<KO>`, intersected locally.

| Candidate | Bottleneck KO (genomes) | Complete | Substrate-specific marker? | Verdict |
|---|---|---|---|---|
| Benzoate → catechol (M00551) | `K05783` (802) | **718** | yes for benzoate; also accepts toluate | **curate** §8.1 |
| Catechol ortho-cleavage (M00568) | `K14727` (573) / `K01055` (2579) | **873** | yes | **curate** §8.2 |
| Catechol meta-cleavage (M00569) | `K18365` (300) | **312** | yes, if `K07104` is refused | **curate**, split §8.3 |
| Phenylacetate (M00878) | `K02615` (235) | **214** | yes (`TIGR02155`) | **curate** §8.4 |
| *trans*-Cinnamate (M00545) | `K05709` (145) | 417 | yes for the pair 3-phenylpropanoate/cinnamate | **curate**, split, renamed §8.5 |
| 2-Oxopent-4-enoate lower route (inside M00569) | `K04073` (1277) | 1083 | yes | **curate** as its own GIFT §8.6 |
| Anthranilate → catechol (M00637) | `K18249` (101) | **252** | yes (`TIGR03228`/`TIGR03231`) | **conditional** §8.7 |
| Benzene → catechol (M00548) | `K16249` (219) | 205 | **no — the markers are a phenol monooxygenase** | **re-scope** to phenol §8.7 |
| Mercury (*mer*) | `K00520` (951) | n/a | yes (`TIGR02053`) | **curate as defense** §8.8 |
| 3-Oxoadipate exit (`pcaIJ` + thiolase) | `K02615` (235) | 98 | yes | **curate with the funnel** §8.2 |
| Salicylate → gentisate (M00638) | `K14581` (86) | 74 | yes (`nagGH`) | **defer** §9.4 |
| Phthalate 4,5 (M00623) | `K18069` (99) | 83 | yes | **defer** §9.4 |
| Toluene → benzoate (M00538) | `K15761` (91) | 6 | no, **and the marker set is a ring monooxygenase** | refuse §9.1, §10.5 |
| Benzene/toluene dioxygenase (M00547) | `K18090` (8) | 6 | no (`K03268` is benzene/toluene/chlorobenzene) | refuse §9.1 |
| Xylene → methylbenzoate (M00537) | `K15758` (7) | 3 | downstream indistinguishable from benzoate | refuse §9.1 |
| Cumate (M00539) | `K18227` (11) | 7 | no | refuse §9.1 |
| *p*-Cymene (M00419) | `K10617` (10) | 8 | no | refuse §9.1 |
| Biphenyl (M00543) | `K18088` (13) | 3 | no | refuse §9.1 |
| Carbazole (M00544) | `K15753` (**1**) | 9 | no | refuse §9.1 |
| Naphthalene (M00534) | `K00152` (12) | 4 | no (`K14579` is also nitrobenzene/dinitrotoluene) | refuse §9.1 |
| Terephthalate (M00624) | `K18075` (8) | 7 | no | refuse §9.1 |
| Phthalate 3,4 (M00636) | `K18253` (11) | 10 | no | refuse §9.1 |
| Toluene, anaerobic (M00418) | `K07547` (12) | 10 | `bssA` is specific; prevalence is not | refuse §9.2 |
| Benzoyl-CoA (M00541) | `K19516` (16) | 29 | yes | refuse §9.2 |
| Cyclohexanecarboxylate (M00540) | `K07534` (24) | 23 | yes | refuse §9.2 |
| Caffeine (M00915) | `K21723` (**2**) | **0** | yes, but the required reductase has no KO | refuse §9.3 |

Six curate, two conditional, two deferred, fourteen refused.

---

## 8. The accepted layer

Every route below was checked against Rhea; identifiers are in §12. All reaction
orientations are `forward` as written. All routes are `aerobic` unless stated.

### 8.1 `benzoate_degradation_catechol` — benzoate → catechol

- Boundaries: `BENZOATE` (new) → `CATECHOL` (new). `mode = catabolic`.
- One route, two reactions: benzoate 1,2-dioxygenase (`RHEA:12633`) then
  dihydroxycyclohexadiene carboxylate dehydrogenase (`RHEA:11560`).
- Systems and markers: `benABC` (`K05549`+`K05550`+`K05784`) and `benD`
  (`K05783`). Complete in 718 genomes; all four markers co-occur in
  the same genome in 719, so nothing is lost to a partial operon.
- Taxa: *Pseudomonas* (141), *Burkholderia* (86), *Acinetobacter* (66),
  *Klebsiella* (43), *Rhodococcus* (41). One *Escherichia* genome.
- **Specificity statement that must be in the description**: `benA`/`benB` are
  KEGG's "benzoate/toluate 1,2-dioxygenase". A positive call is honest for
  benzoate, because benzoate is within the enzyme's range. It is *not* honest for
  toluate, and therefore **no separate methylbenzoate or xylene-derived GIFT may
  be curated on these markers** — that would create two traits the evidence
  cannot distinguish, which is the failure mode invariant 16 exists to prevent.

### 8.2 `catechol_ortho_cleavage` — catechol → 3-oxoadipate

- Boundaries: `CATECHOL` → `OXOADIPATE` (new). `mode = catabolic`.
- One route, four reactions: catechol 1,2-dioxygenase (`RHEA:23852`), muconate
  cycloisomerase (`RHEA:30031`, reverse as written in Rhea), muconolactone
  isomerase (`RHEA:12348`), 3-oxoadipate enol-lactonase (`RHEA:10184`).
- Markers: `catA` (`K03381`, 1313), `catB` (`K01856`, 1130), `catC` (`K03464`,
  1150), and the lactonase as two alternative systems, `pcaD` (`K01055`) or the
  fused `pcaL` (`K14727`). All four steps co-occur in 874 genomes. KEGG
  separates chlorocatechol 1,2-dioxygenase as `K15253` (26 genomes), so `catA`
  is not carrying the chlorinated chemistry.
- **This is the hub the layer exists for.** With `benzoate_degradation_catechol`
  and `anthranilate_degradation_catechol` upstream, the composition graph gets
  its first convergent funnel: two entry GIFTs, one shared anchor, one exit.
- Companion GIFT `oxoadipate_to_succinyl_coa` (`OXOADIPATE` →
  `SUCCINYL_COA` (new) + `ACETYL_COA`): `pcaIJ` (`K01031`/`K01032`, 1279/1269)
  then 3-oxoadipyl-CoA thiolase (`K02615`, 235). Complete in 98 genomes. It is
  proposed **as a separate GIFT, and its curation is optional in the first
  release**: without it the funnel terminates at an anchor nothing consumes and
  `gift_profile.network_position` reports `terminal`, which is honest. With it,
  the thiolase annotation gap becomes a reported missing reaction rather than a
  silent absence — the same treatment the serine phosphatase already gets.

### 8.3 `catechol_meta_cleavage` — catechol → 2-oxopent-4-enoate

- Boundaries: `CATECHOL` → `OXOPENTENOATE` (new). `mode = catabolic`.
- **Two routes**, which is the reason to curate it: the hydrolytic branch
  (`RHEA:17337` then `RHEA:14549`, markers `K00446` + `K10216`, 356) and the
  4-oxalocrotonate branch (`RHEA:17337`, `RHEA:34219`, `RHEA:33431`,
  `RHEA:24260`; markers `K00446` + `K10217` + `K01821` + `K01617`). Genuine
  alternative minimal routes to one product, which is what OR-over-routes is for.
- Complete in 312 genomes by KEGG's count; `K00446` with a full lower pathway
  co-occurs in 139–147.
- **`K07104` must not be accepted** (§10.2).

### 8.4 `phenylacetate_degradation` — phenylacetate → acetyl-CoA

- Boundaries: `PHENYLACETATE` (new) → `ACETYL_COA` + `SUCCINYL_COA` (new).
  `mode = catabolic`.
- One route, eight reactions: `paaK` CoA ligation (`RHEA:20956`), `paaABC(DE)`
  ring epoxidation (`RHEA:32171`), `paaG` isomerisation (`RHEA:31843`), `paaZ`
  ring opening and semialdehyde oxidation (`RHEA:31755`, `RHEA:31747`), then the
  β-oxidation tail: hydration (`RHEA:16105`), dehydrogenation (`RHEA:16197`) and
  thiolysis (`RHEA:19481`).
- Markers: `K01912`, `K02609`–`K02613`, `K15866`, `K02618`, `K01692`, `K00074`,
  `K02615`, plus NCBIfam `TIGR02155` (PaaK), `TIGR02158`/`TIGR02159` (PaaC/PaaD)
  as second-namespace support. The core five (`paaK`+`paaA`+`paaE`+`paaG`+`paaZ`)
  co-occur in **950** genomes; adding the `paaJ` thiolase drops it to 217, which
  is the module's real bottleneck and should be reported as a missing reaction,
  not scored away.
- Taxa: *Pseudomonas* (76), *Klebsiella* (52), *Enterobacter* (50),
  *Acinetobacter* (45), *Escherichia* (26). **This is the most host-relevant
  trait in the request**: phenylacetate is a phenylalanine fermentation product,
  and the *paa* route is the canonical *Escherichia coli* aerobic disposal of it.
- Note the deliberate reuse: `K00074` and `K01692` are generic β-oxidation
  markers, one already curated for `butyrate_formation`. The specificity of the
  claim rests on `paaK` and the epoxidase, not on the tail.

### 8.5 The phenylpropanoid node — three GIFTs, not KEGG's one module

M00545 is named "*trans*-cinnamate degradation" and is complete in 417 genomes,
but its first step is an OR between two enzymes acting on **two different
substrates**: `hcaEFCD`+`hcaB` on 3-phenylpropanoate/*trans*-cinnamate, and
`mhpA` on 3-(3-hydroxyphenyl)propanoate. A giftr route must connect the GIFT's
own declared input anchor, so this cannot be one GIFT with two routes. It is
three GIFTs around a shared anchor:

- `phenylpropanoate_dihydroxylation`: `PHENYLPROPANOATE` (new) → `DHPP` (new),
  markers `K05708`+`K05709`+`K05710`+`K00529`+`K05711` (`RHEA:20357`,
  `RHEA:25062`). Bottleneck `K05709` at 145 genomes.
- `hydroxyphenylpropanoate_hydroxylation`: `HPP` (new) → `DHPP`, marker `K05712`
  (`RHEA:24785`), 1606 genomes. Optional in the first release.
- `dihydroxyphenylpropanoate_degradation`: `DHPP` → `SUCCINATE` + `PYRUVATE` +
  `ACETYL_COA`, markers `K05713`+`K05714`+`K02554`+`K01666`+`K04073`
  (`RHEA:23840`, `RHEA:34187`, `RHEA:22580`, `RHEA:22624`, `RHEA:23288`).
- The full *hca*+*mhp* chain co-occurs in 91 genomes: *Escherichia* (42),
  *Citrobacter* (13). `SUCCINATE`, `PYRUVATE` and `ACETYL_COA` are **existing
  anchors**, so this node composes straight into the curated central metabolism
  and the citric acid cycle segments.
- **The requested compound cannot be the anchor, and a separate cinnamate GIFT
  is refused.** Rhea does distinguish the two substrates — `RHEA:20357` for
  3-phenylpropanoate and `RHEA:25058` for (E)-cinnamate, both under EC 1.14.12.19
  — but no marker does: KEGG names `K05708` "3-phenylpropionate/*trans*-cinnamate
  dioxygenase" and NCBIfam `NF042946` carries the same dual name. Curating both
  as GIFTs would create two traits with byte-identical evidence, which is the
  §8.1 failure mode again. Declare the input anchor as `PHENYLPROPANOATE`, the
  substrate the *Escherichia coli* *hca* system is characterised on, and state in
  the description that *trans*-cinnamate lies within the same enzyme's range and
  is not separately claimed. If cinnamate is the compound of interest, that is a
  reason to look for a cinnamate-specific marker, not to rename this GIFT.

### 8.6 `oxopentenoate_degradation` — 2-oxopent-4-enoate → pyruvate + acetyl-CoA

- Boundaries: `OXOPENTENOATE` → `PYRUVATE` + `ACETYL_COA`. `mode = catabolic`.
- Three reactions (`RHEA:22580`, `RHEA:22624`, `RHEA:23288`), two alternative
  systems per step: the *mhp* set (`K02554`/`K01666`/`K04073`, co-occurring in
  1083 genomes) and the *bph*/*xyl*/*tes* set (`K18364`/`K18365`/`K18366`, ~300).
- **Why it is a separate GIFT.** This is the common lower *meta* pathway. KEGG
  duplicates it inside M00569, M00539, M00543, M00544 and M00537. Invariant 8
  forbids duplicating an atomic GIFT's reactions inside larger traits, so it is
  curated once and everything upstream composes through the anchor. If the
  biphenyl or cumate evidence ever improves, the new GIFT is three markers, not
  eight.

### 8.7 Two conditional accepts

**`anthranilate_degradation_catechol`** (`ANTHRANILATE` (new) → `CATECHOL`,
`RHEA:11072`). Two alternative systems: `antABC` (`K05599`+`K05600`+`K11311`,
all three at 166 genomes) and `andAabcd` (`K16319`+`K16320`+`K18248`+`K18249`,
101–292). Complete in 252 genomes, NCBIfam `TIGR03228`/`TIGR03231` available.
The chemistry and markers are sound; the condition is a *usefulness* one, in that
the positives are *Burkholderia* (89), *Pseudomonas* (83) and *Acinetobacter*
(43) with no host-associated genus at all. Curate it because it is the second
entry into the catechol funnel and because anthranilate is a tryptophan
catabolite rather than a pollutant — not because anyone's gut genomes will fire it.

**`phenol_hydroxylation`** (`PHENOL` (new) → `CATECHOL`, `RHEA:57952`,
phenol + NADH + O2 + H(+) = catechol + NAD(+) + H2O).
This replaces the requested benzene trait. M00548's marker set,
`dmpKLMNOP`/`poxABCDEF`/`tomA0-A5` (`K16242`–`K16249`), is a **phenol 2-monooxygenase**;
KEGG attaches it to both benzene → phenol (`R10042`) and phenol → catechol
(`R10043`), and only the second is what the enzyme does. All six subunits
co-occur in 206 genomes. Phenol is a tyrosine fermentation product as well as an
industrial compound, so the re-scoped trait is the more useful of the two.
The condition is that the multicomponent monooxygenase be curated with all six
subunits jointly required, which is correct here — unlike the Rieske ferredoxin
case in §10.1, these subunits are the enzyme.

### 8.8 `mercury_detoxification` — a defense GIFT

**Curated on 2026-08-19, as proposed here.** What the implementation changed is
recorded in §17.

Mercury is the one candidate that does not fit the metabolic model, and the
reason is instructive. The chemistry is real and Rhea-covered
(`RHEA:23856`, Hg + NADP(+) + H(+) = Hg(2+) + NADPH, run in reverse by MerA;
`RHEA:18777` for the organomercurial lyase). But the capability is not a
directed conversion of a nutrient into another nutrient — it is the execution of
a resistance mechanism, and `mode` offers no honest value for it. `catabolic`
would claim carbon or energy metabolism, `interconversion` would claim
reversibility the cell never uses, and `transport` describes only the *merTP*
part. Adding a fifth `mode` for one trait is a worse trade than typing the
capability correctly.

The `defense` contract already covers it: the schema comment defines a mechanism
as acting against "a defined biological **or chemical** challenge", and the
machinery model provides exactly the required/accessory distinction the *mer*
operon needs.

Proposed mechanism `MECH_MER_HG` with four functions:

| Function | Required | Systems and markers | Genomes |
|---|---|---|---|
| Mercuric ion reduction | yes | MerA: `K00520`, NCBIfam `TIGR02053`, InterPro `IPR021179` | 951 |
| Mercuric ion import to the reductase | no | MerT+MerP (`K08363`+`K08364`); MerC (`K19058`); MerE (`K19059`) as alternative systems | 410 with MerA+MerT+MerP |
| Operon induction by Hg(II) | no | MerR (`K08365`), MerD (`K19057`) | 434 with MerA |
| Organomercurial C–Hg lysis | no | MerB (`K00221`, `NF033555`, `IPR004927`) | 124 with MerA |

Design decisions to review:

1. **Reduction is the only required function.** A genome with *merA* alone
   detoxifies Hg(II) that reaches the cytoplasm; that is the claim. Requiring the
   transporter would refuse 541 *merA* genomes on the strength of an operon
   architecture that varies (MerC and MerE substitute for MerT/MerP in several
   lineages), and giftr has no evidence layer for "the metal gets in anyway".
2. **Organomercurial lysis is accessory, not a second GIFT** — for now. Broad-
   spectrum (phenylmercury) resistance is a genuinely different claim from
   narrow-spectrum resistance and could be a second mechanism later; 124 genomes
   would support it. Recorded as an open question rather than decided here.
3. **A new `defense_class` facet value is needed, and it is
   `chemical_detoxification`** — named for the mechanism, not for the metal and
   not for the phenotype. This is the first non-phage defense GIFT, so it is a
   real widening of what the type carries and was reviewed as such (invariant
   19's spirit, although the type itself already exists). The rosters that
   decided the name, and the two rejected alternatives
   (`metal_detoxification`, `metal_resistance`), are in §10.6.
4. Taxa: *merA*+*merT*+*merP* positives are *Pseudomonas* (32), *Klebsiella* (12),
   *Marinobacter* (11), *Shewanella* (10); *merA* alone reaches *Staphylococcus*
   (10), *Streptococcus* (9), *Salmonella* (7), *Enterobacter* (7),
   *Escherichia* (6). Plasmid-borne mercury resistance in host-associated
   Enterobacteriaceae is one of the few traits in this whole request that a
   microbiome dataset will actually see.
5. **Mercury methylation (*hgcAB*) is a different capability and is not
   proposed here.** It is not detoxification, it is the reaction that makes
   mercury more toxic, and it belongs in its own assessment.

---

## 9. The refusals, with evidence

A refusal recorded with its evidence is a result. All fourteen are grouped by
failure mode, because the modes are what generalise.

### 9.1 No marker resolves the substrate (nine candidates)

Toluene (M00538, M00547), benzene (M00547, M00548 as requested), xylene
(M00537), *p*-cymene (M00419), cumate (M00539), biphenyl (M00543), carbazole
(M00544), naphthalene (M00534), terephthalate (M00624), phthalate 3,4 (M00636).

Every one of these traits is named for a substrate whose recognition happens in
the active site of a Rieske non-heme iron ring-hydroxylating oxygenase, and
three independent lines of evidence say the substrate is not recoverable from
sequence at the level giftr can use:

1. **KEGG's own KO names admit it.** `K03268` is "benzene/toluene/chlorobenzene
   dioxygenase subunit alpha"; `K14579` is "naphthalene 1,2-dioxygenase subunit
   alpha" with EC numbers for nitrobenzene and dinitrotoluene dioxygenase
   attached and gene names `nbzAc`/`dntAc`; `K16242`–`K16249` are
   "phenol/toluene 2-monooxygenase"; `K05549` is "benzoate/toluate".
2. **InterPro has no substrate-specific family.** Searching for the α subunit of
   toluene, benzene or naphthalene dioxygenase returns `IPR001663`
   "aromatic-ring-hydroxylating dioxygenase, alpha subunit", `IPR015879` (its
   C-terminal domain), `PS00570` "bacterial ring hydroxylating dioxygenases
   alpha-subunit signature" and the Rieske domain profiles. These are the family,
   not the specificity. The only sub-family-level entries are CDD conserved
   domains (`cd08879`, `cd08881`) built from single named enzymes, which are not
   HMMs giftr's evaluator accepts and would not be defensible as trait evidence
   anyway.
3. **Accepting one would damage the others.** These enzymes overlap in substrate
   range in the laboratory. A marker admitted as evidence of toluene
   dihydroxylation is simultaneously evidence of benzene and chlorobenzene
   dihydroxylation, so the three traits would cease to be distinguishable — the
   pseudolysin failure mode, restated for aromatics.

The prevalence numbers reinforce the refusal independently: the bottleneck KO is
in 1 genome for carbazole, 7 for xylene, 8 for benzene/toluene dioxygenase and
terephthalate, 10–13 for cymene, cumate, biphenyl and naphthalene. Even if the
specificity problem were solved, these would fail the ≥ 50 threshold.

For M00538 there is a second, independent refusal in §10.5.

### 9.2 The anaerobic aromatic routes: specific enough, far too rare (three candidates)

Anaerobic toluene (M00418), benzoyl-CoA (M00541), cyclohexanecarboxylate
(M00540).

These are the opposite case, and it is worth being explicit that the refusal is
different in kind. `bssABC` benzylsuccinate synthase (`RHEA:10416`, toluene +
fumarate = 2-benzylsuccinate) is a glycyl radical enzyme with distinctive
chemistry, and the *bbs* β-oxidation genes are specific to the route. Benzoyl-CoA
reductase (`RHEA:30199`) is the central anaerobic ring-reduction step and has two
alternative systems in KEGG (`bcrABCD` and `bamBC`), which is exactly the
alternative-systems representation giftr wants. The problem is coverage: 12
genomes at the `bbsC`/`bbsD` bottleneck, 16 at `bamC`, 24 at `badK`, and the
complete-module positives are *Thauera*, *Azoarcus*, *Aromatoleum*, *Geobacter*
and *Rhodopseudomonas* — sediment and soil denitrifiers, 29 and 23 genomes
respectively.

**Re-test condition**: revisit when the benzoyl-CoA reductase bottleneck exceeds
50 genomes, or when a curation campaign specifically targets anaerobic aromatic
catabolism. Of everything refused here, benzoyl-CoA is the one to revisit first:
it is the hub of anaerobic aromatic metabolism the way catechol is the hub of the
aerobic kind, and curating it would make the anaerobic side of the layer possible
in one step.

### 9.3 Caffeine: the marker exists, the system cannot be assembled

`ndmA` (`K21722`) is in 5 genomes, `ndmB` (`K21723`) in 2, `ndmC` (`K21724`) in
10, and **no KEGG genome completes M00915**. Worse, the module is incomplete as
chemistry: NdmA, NdmB and NdmC are all Rieske monooxygenases that require the
NdmD reductase to turn over, and NdmD has no KO — so even a perfectly annotated
*Pseudomonas putida* CBB5 would be curated in giftr as a system missing its
reductase component. The alternative caffeine dehydrogenase (*cdhABC*) route to
trimethyluric acid has no KO either.

Rhea covers the chemistry cleanly (`RHEA:30315`, `RHEA:30319`, `RHEA:30307`), and
the demethylases are genuinely regiospecific, so this is not a specificity
refusal — it is an availability refusal, and the honest statement is that
caffeine degradation is a well-characterised capability that the public marker
layer cannot currently evidence.

**Re-test condition**: revisit when NdmD receives a KO or when an NCBIfam family
covers the *ndm* reductase, and if `ndmA` prevalence rises above 50. Note also
that N-demethylation of methylxanthines is a plausible *gut* trait; if that is
the interest, the assessment to run is on the anaerobic xanthine pathways, not
on this module.

### 9.4 Two defers

**Salicylate → gentisate (M00638).** `nagG`/`nagH` are specific salicylate
5-hydroxylase subunits (172/179 genomes) and Rhea covers the reaction
(`RHEA:35307`), but the module's completeness of 74 rests on the shared
naphthalene dioxygenase ferredoxin/reductase components (`K14578` 216,
`K14581` 86) — the §10.1 problem — and the positives (*Pandoraea*, *Ralstonia*,
*Variovorax*) are environmental. Defer until §10.1's curation convention is
settled by the first accepted Rieske system. Note that salicylate degradation
via `nahG`-type hydroxylation to catechol would compose into the funnel, which is
the version worth curating later.

**Phthalate 4,5-dioxygenase (M00623).** Bottleneck `K18069` at 99 genomes,
83 complete, all environmental (*Burkholderia*, *Bordetella*, *Polaromonas*).
Phthalates are the one genuinely anthropogenic compound class in the request
with plausible human exposure relevance, which is why this is a defer rather
than a refusal. Its product, protocatechuate, would need its own funnel exit
(`pcaGH` ring cleavage, `K00448`/`K00449`, 1933/2166 genomes — well annotated),
so accepting phthalate later brings a second hub with it.

**Re-test condition for both**: when the layer is extended past the catechol hub
to protocatechuate, reassess together, because protocatechuate cleavage is the
shared prerequisite.

---

## 10. Architectural findings

### 10.1 Rieske electron-transfer subunits break AND-over-components

Multicomponent ring-hydroxylating oxygenases consist of a catalytic α subunit
(and usually a small β subunit) plus a ferredoxin and a ferredoxin reductase
that shuttle electrons. The latter two are frequently **shared between systems**,
sometimes **interchangeable**, and consistently **worse annotated** than the
catalytic core:

| System | Catalytic subunit | Electron transfer | Ratio |
|---|---|---|---|
| Anthranilate 1,2-dioxygenase (*and*) | `K16319` 281 | `K18249` 101 | 2.8× |
| Phthalate 4,5-dioxygenase | `K18068` 279 | `K18069` 99 | 2.8× |
| Naphthalene 1,2-dioxygenase | `K14578` 216 | `K14581` 86 | 2.5× |
| Salicylate 5-hydroxylase | `K18243` 179 | `K14581` 86 | 2.1× |

Because `enzyme_component` has no `required` column, curating the reductase as a
component makes it a hard AND: a genome carrying the specificity-determining
subunit and a reductase that KEGG assigned to a different KO is called negative.
Curating it as a separate `enzyme_system` would be worse — it would claim the
reductase alone can perform the reaction.

**Recommendation: solve it in curation, not in the schema.** For a Rieske
system, curate the components that determine the chemistry and the substrate,
state in the system `description` that the shared electron-transfer components
are deliberately not required, and record the reason in the component `notes`.
This is a curation claim of the same kind giftr already makes when it chooses
which markers evidence a component, and it is reviewable in the TSV.

Do **not** add `enzyme_component.required` for this layer. It would be a schema
migration serving one enzyme family, it would invite "optional component" as a
way to soften every AND in the database, and the case for it should be made — if
ever — by a layer where the accessory component is genuinely accessory to the
*chemistry* rather than merely to the *annotation*. Recorded here as the strongest
candidate reason to revisit that decision.

### 10.2 `K07104` is an over-broad marker whose damage would outlive this GIFT

`K07104` (*catE*) and `K00446` (*dmpB*/*xylE*) are both labelled "catechol
2,3-dioxygenase [EC:1.13.11.2]". Their distributions are not comparable:

| | Genomes | Top genera | With any lower *meta* pathway gene |
|---|---|---|---|
| `K00446` | 335 | *Microbacterium*, *Cupriavidus*, *Burkholderia*, *Pseudomonas* | most |
| `K07104` | 2081 | *Bacillus* (161), *Streptococcus* (105), *Staphylococcus* (100), *Listeria* (48), *Enterococcus* (34) | 276 of 2081 |

`K07104` is the generic extradiol/glyoxalase-family assignment, and the
organisms carrying it are overwhelmingly Firmicutes that do not degrade
aromatics. Within `catechol_meta_cleavage` the route AND-logic hides most of the
damage — `K07104` plus a complete lower pathway occurs in only 125 genomes
against 139 for `K00446` — but that is the wrong reason to accept it. Once the
marker is in `component_markers.tsv` it is available to the next GIFT that
declares a catechol 2,3-dioxygenase component, and any such GIFT would fire in
2081 genomes.

**Recommendation**: evidence the component with `K00446`, optionally with
NCBIfam `TIGR03211`, and record the `K07104` exclusion in the component `notes`
so the next curator does not re-add it.

### 10.3 `mode` has no value for detoxification, and that is the right answer

§8.8 argues mercury into the `defense` type rather than inventing a fifth `mode`.
The general form of that finding is worth stating: **a chemical transformation
whose purpose is neither building, breaking down, nor moving a metabolite is not
a metabolic GIFT in giftr's sense**, and the fact that Rhea has an equation for
it does not make it one. Other capabilities in this space — tellurite
methylation, Cu(I) oxidation, superoxide dismutation, methylglyoxal disposal —
will raise the same question, and typing them as defense mechanisms with a
`chemical_detoxification` class (§10.6) is a decision that scales, whereas a
`detoxification` mode would put them in the anchor graph, where they would form
edges through metal-ion and reactive-oxygen anchors that mean nothing.

### 10.4 The layer is aerobic, and the profile view will say almost nothing

Every accepted route requires molecular oxygen: dioxygenases and monooxygenases
are the entire aerobic strategy for activating an aromatic ring. Two consequences
to record honestly:

- `oxygen_requirement = 'aerobic'` on every accepted route, and the layer will
  be silent in obligate anaerobes even where the biology is present by another
  mechanism. That is a coverage limitation of the layer, not a false negative in
  the evaluator.
- The aromatic anchors will be declared `compartment = 'unspecified'`, as the
  SCFAs were, because there is no evidenceable transport GIFT for them
  (aromatics cross membranes by diffusion and by porins nothing distinguishes).
  So `cross_feeding_output` stays 0 for the whole layer, even though catechol is
  exactly the kind of intermediate that gets exchanged, and
  `gift_profile.resource_strategy` reports `private` for every member — not
  `unresolved`, as this section first predicted: the view reads two unspecified
  compartments as neither extracellular, which is the honest reading of a
  boundary that was never licensed, but it is a stronger word than the evidence
  behind it. Measured after curation, §16.

### 10.5 KEGG attaches two marker sets to chemistry they do not perform

Both cases were found by cross-checking KEGG's reaction assignment against Rhea,
and both are worth recording because they are the clearest possible support for
invariant 1.

- **M00538** assigns the `tmoABCDEF`/`tbu`/`tou` system (`K15760`–`K15765`) to
  `R02550`, toluene → benzyl alcohol. But Rhea's master for EC 1.14.13.236, the
  EC KEGG itself lists for `K15760`, is `RHEA:41380`: **toluene → 4-methylphenol**.
  The *tmo* systems hydroxylate the *ring*, not the methyl group. Side-chain
  hydroxylation to benzyl alcohol is `xylMA` (EC 1.14.15.26, `RHEA:51592`) —
  which is M00537's marker set, in a different module. The module is internally
  inconsistent, and a GIFT built from it would claim chemistry its markers do
  not catalyse.
- **M00548** assigns the *dmp* phenol 2-monooxygenase to both benzene → phenol
  and phenol → catechol. Only the second is that enzyme's reaction. §8.7
  re-scopes the trait accordingly.

Neither of these is discoverable from a module's KO list alone. They were found
because giftr requires a Rhea master per reaction, which forced the comparison.
That is the invariant earning its cost.

### 10.6 A defense class is named for the mechanism, never for the challenge or the outcome

§8.8 needs one `defense_class` value, and the obvious candidates were
`metal_detoxification` (challenge chemistry plus mechanism shape) and
`metal_resistance` (challenge chemistry plus outcome). Both were rejected. The
finding generalises, because `defense_class` is single-valued and **partitions**
the defense type: the name is not a label on one GIFT, it is the bucket every
future defense GIFT must fall into exactly once. The way to choose it is to
write out what each candidate name would have to hold.

**What a `*_resistance` class would hold.** Every mechanism that lets a cell
survive a chemical challenge, by any means:

| Capability | Best markers | Which GIFT type it actually is |
|---|---|---|
| Hg(II) reduction | `K00520` MerA | defense |
| Arsenite efflux | `K03893` ArsB, `K03325` Acr3 | transport, not defense |
| Chromate efflux | `K07240` ChrA | transport |
| Cu(I), Zn/Cd/Co efflux | `K17686` CopA, `K01534` ZntA, `K15726` CzcA/CusA/CnrA | transport |
| Tellurite resistance | `K03304` TehA, `K05792`–`K05794` TerABC | transport, mechanism unresolved |
| Metal-responsive induction | `K08365` MerR, `K21885` CmtR, `K21903` CadC/SmtB | **regulatory** |
| Metal sequestration | no bacterial metallothionein orthology group; `K14739`–`K14741` are eukaryotic | not curatable |
| Antibiotic destruction, target modification, target protection, efflux | `K01467` AmpC, `K00561` ErmA/C, `K18220` TetM, `K18138` AcrB | mixed |
| Antimicrobial peptide resistance | `K07264` ArnT, `K10011` ArnA, `K03367` DltA | envelope modification, structural |

Three reasons that is not a `defense_class`:

1. **The roster is not one GIFT type.** Most of it is transport, some is
   regulatory, some structural. A class that partitions the defense type cannot
   name a group whose members are mostly not defense GIFTs. The *ars* operon
   alone splits three ways: ArsC transformation, ArsB efflux, ArsR regulation.
2. **Resistance is an outcome, and giftr does not claim outcomes.**
   `proposal-defense-gifts.md` refuses it twice — "explicitly **not**: this
   organism resists phage", and "any claim about an outcome … is not curatable
   from a genome" — and §15 below already states that this GIFT does not claim
   mercury detoxification confers resistance. A `metal_resistance` facet would
   assert in the classification exactly what the GIFT disclaims in its
   description, and `defense_class == 'metal_resistance'` would become a filter
   returning a claim nothing behind it supports.
3. **Invariant 18** puts phenotypic descriptions in a derived layer. Resistance
   is the archetype: it is what a repertoire of transformation, efflux and
   regulation would derive, the way `gift_profile` derives resource strategy.

The curated vocabulary already says this. `restriction_modification` and
`crispr_cas` are both anti-phage and were deliberately *not* merged into a
`phage_resistance` class.

**What a `metal_detoxification` class would hold.** Almost nothing:

| Candidate | Verdict |
|---|---|
| Hg(II) reduction, `K00520` (+ `K00221` MerB) | curatable |
| Tellurite methylation, `K16868` TehB — Te(IV) to volatile dimethyl telluride | curatable |
| Cu(I) oxidation, `K14588` CueO | curatable |
| Chromate reduction, `K19784` ChrR | refused: the orthology group is defined as an NAD(P)H:quinone dehydrogenase and does not resolve chromate — the §9.1 failure mode |
| Arsenite methylation, ArsM | refused: no orthology group exists |
| Arsenate reduction, `K00537` / `K18064` ArsC | refused on chemistry: As(III) is *more* toxic than As(V). The detoxification is done by ArsB efflux downstream, which a detoxification class excludes |

Three members, ever, and the class would exclude the traits that a
host-associated dataset will actually see.

**What `chemical_detoxification` holds.** Scoping the class by mechanism shape
rather than by the periodic table gives a populated roster in which every member
has usable markers:

| Capability | Markers |
|---|---|
| Superoxide dismutation | `K04564` Fe/Mn SOD, `K04565` Cu/Zn SOD; `K05919` Dfx superoxide reductase in anaerobes |
| H(2)O(2) removal | `K03781` KatE, `K03782` KatG, `K03386`/`K24119` AhpC, `K00432` Gpx |
| Nitrosative defense | `K05916` Hmp NO dioxygenase, `K12264` NorV flavorubredoxin, `K05601` Hcp |
| Organic hydroperoxide removal | `K04063` Ohr/OsmC |
| Methylglyoxal disposal | `K01759` GloA with `K01069` GloB |
| Formaldehyde disposal | `K00121` FrmA with `K01070` FrmB/FghA; `K00148` FdhA |
| Metal and metalloid | mercury, tellurite and Cu(I) as above |

This is also the class that answers §14.1's objection to the layer as a whole:
defense against the host oxidative and nitrosative burst fires in gut genomes,
where six of the nine metabolic GIFTs proposed here will not.

**The definition is a mechanism test, and it must stay falsifiable:**

> A system whose curated function is the enzymatic conversion of a toxic
> chemical challenge into a less harmful chemical species. The class names the
> mechanism, not the outcome: a positive call does not claim that the organism
> tolerates or survives exposure.

Which settles the boundary cases before a curator meets them:

- **Efflux is excluded** — no chemical conversion. A future arsenite-efflux GIFT
  belongs to another class, and that is correct rather than a defect: it is the
  same cut that keeps *merT*/*merP* an accessory function of `MECH_MER_HG`
  instead of a class-mate of MerA.
- **Repair is excluded.** MsrA/MsrB (`K07304`, `K12267`) restore the damaged
  protein rather than converting the toxicant.
- **Regulators are excluded**; a metal-responsive two-component or MerR-family
  circuit is a regulatory GIFT.

Two consequences to record:

1. If the "against what" axis is wanted later, it is a **separate multi-valued
   facet** (`challenge_class`: `metal`, `oxidative`, `nitrosative`,
   `electrophile`, `antimicrobial`), on the precedent of `substrate_class` plus
   `physiological_role` for metabolic GIFTs. It is not registered now: a facet
   vocabulary is registered when the first content needing it is curated.
2. Formaldehyde disposal will need the §10.3 test applied a second time. The
   curated `methylamine_degradation` runs `METHYLAMINE` to `AMMONIUM` and
   releases formaldehyde without declaring it as an anchor; the same FrmA/FrmB
   markers are detoxification in most organisms and carbon metabolism in
   methylotrophs. That decision belongs to whoever proposes the GIFT, not to
   this proposal.

---

## 11. Facet and anchor budget

**New anchors (11)**, all `molecular_tier = small_molecule`,
`biomass_essential = no`, `compartment = unspecified`:

| Anchor | Molecule | ChEBI | `resource_origin` |
|---|---|---|---|
| `BENZOATE` | benzoate | CHEBI:16150 | `plant_derived`, `anthropogenic` |
| `CATECHOL` | catechol | CHEBI:18135 | `microbially_derived` |
| `OXOADIPATE` | 3-oxoadipate | CHEBI:15775 | `microbially_derived` |
| `OXOPENTENOATE` | 2-oxopent-4-enoate | CHEBI:11641 | `microbially_derived` |
| `SUCCINYL_COA` | succinyl-CoA | CHEBI:57292 | `central_metabolism` |
| `PHENYLACETATE` | phenylacetate | CHEBI:18401 | `microbially_derived` |
| `PHENYLPROPANOATE` | 3-phenylpropanoate | CHEBI:51057 | `plant_derived` |
| `HPP` | 3-(3-hydroxyphenyl)propanoate | CHEBI:57277 | `plant_derived` |
| `DHPP` | 3-(2,3-dihydroxyphenyl)propanoate | CHEBI:46951 | `microbially_derived` |
| `ANTHRANILATE` | anthranilate | CHEBI:16567 | `microbially_derived`, `host_derived` |
| `PHENOL` | phenol | CHEBI:15882 | `microbially_derived`, `anthropogenic` |

Every identifier above was resolved against ChEBI and Rhea on 2026-08-18 rather
than recalled: four of the first eleven guessed during drafting were wrong, and
two of the wrong ones pointed at real but unrelated compounds
(`CHEBI:57348` is 3-oxoadipyl-CoA, `CHEBI:15586` is D-citramalate), which is the
kind of error that survives review if the table is not checked.

Eleven new anchors against 89 existing is a 12 % increase, the size of addition
invariant 3 exists to scrutinise. It is defensible only because each one is a
real cut point: two are entry substrates,
one is the funnel hub every entry converges on, three are branch nodes shared by
two or more GIFTs, and one (`SUCCINYL_COA`) is a central metabolite giftr will
need regardless of this layer.

**New facet values (4)**:

| Facet | Value | Definition |
|---|---|---|
| `substrate_class` | `aromatic_compound` | Compounds carrying a benzene ring, whether plant-derived, host-derived, microbially produced or industrial. The class names the chemistry the trait must solve — ring activation and cleavage — not the compound's origin. |
| `physiological_role` | `aromatic_ring_catabolism` | Activates or cleaves an aromatic ring, or degrades a ring-cleavage product, delivering carbon to central metabolism. |
| `resource_origin` (anchor) | `anthropogenic` | Enters the system from industrial or agricultural human activity, whether or not it also occurs naturally. |
| `defense_class` | `chemical_detoxification` | A system whose curated function is the enzymatic conversion of a toxic chemical challenge into a less harmful chemical species. The class names the mechanism, not the outcome: a positive call does not claim that the organism tolerates or survives exposure. Efflux, sequestration and repair are excluded by the definition; see §10.6. |

Note what is *not* proposed: no `xenobiotic_degradation` role (§3), and no
`bioremediation` or `pollutant_degrader` facet, both of which are derived
descriptions (invariant 18).

---

## 12. Rhea coverage

Sixty-seven EC numbers spanning all 24 candidates were queried against the Rhea
API on 2026-08-18; **all 67 returned a master reaction**, including the class-
level ones. No reaction in this layer needs the nullable-`rhea_master` path that
the polysaccharide and protein layers opened.

Masters for the accepted set:

| Reaction | EC | Rhea master |
|---|---|---|
| Benzoate 1,2-dioxygenase | 1.14.12.10 | `RHEA:12633` |
| Dihydroxycyclohexadiene carboxylate dehydrogenase | 1.3.1.25 | `RHEA:11560` |
| Catechol 1,2-dioxygenase | 1.13.11.1 | `RHEA:23852` |
| Muconate cycloisomerase | 5.5.1.1 | `RHEA:30031` |
| Muconolactone isomerase | 5.3.3.4 | `RHEA:12348` |
| 3-Oxoadipate enol-lactonase | 3.1.1.24 | `RHEA:10184` |
| 3-Oxoadipate CoA-transferase | 2.8.3.6 | `RHEA:12048` |
| 3-Oxoadipyl-CoA thiolase | 2.3.1.174 | `RHEA:19481` |
| Catechol 2,3-dioxygenase | 1.13.11.2 | `RHEA:17337` |
| 2-Hydroxymuconate semialdehyde hydrolase | 3.7.1.9 | `RHEA:14549` |
| 2-Hydroxymuconate semialdehyde dehydrogenase | 1.2.1.85 | `RHEA:34219` |
| 4-Oxalocrotonate tautomerase | 5.3.2.6 | `RHEA:33431` |
| 4-Oxalocrotonate decarboxylase | 4.1.1.77 | `RHEA:24260` |
| 2-Oxopent-4-enoate hydratase | 4.2.1.80 | `RHEA:22580` |
| 4-Hydroxy-2-oxovalerate aldolase | 4.1.3.39 | `RHEA:22624` |
| Acetaldehyde dehydrogenase (acylating) | 1.2.1.10 | `RHEA:23288` |
| Phenylacetate-CoA ligase | 6.2.1.30 | `RHEA:20956` |
| Phenylacetyl-CoA 1,2-epoxidase | 1.14.13.149 | `RHEA:32171` |
| Epoxyphenylacetyl-CoA isomerase | 5.3.3.18 | `RHEA:31843` |
| Oxepin-CoA hydrolase | 3.3.2.12 | `RHEA:31755` |
| Semialdehyde dehydrogenase | 1.2.1.91 | `RHEA:31747` |
| Enoyl-CoA hydratase | 4.2.1.17 | `RHEA:16105` |
| 3-Hydroxyacyl-CoA dehydrogenase | 1.1.1.157 | `RHEA:16197` |
| 3-Phenylpropanoate dioxygenase | 1.14.12.19 | `RHEA:20357` (and `RHEA:25058` for cinnamate) |
| Dihydrodiol dehydrogenase | 1.3.1.87 | `RHEA:25062` |
| 3-(3-Hydroxyphenyl)propanoate hydroxylase | 1.14.13.127 | `RHEA:24785` |
| DHPP 1,2-dioxygenase | 1.13.11.16 | `RHEA:23840` |
| 2-Hydroxy-6-oxononadienedioate hydrolase | 3.7.1.14 | `RHEA:34187` |
| Anthranilate 1,2-dioxygenase | 1.14.12.1 | `RHEA:11072` |
| Phenol 2-monooxygenase | 1.14.13.244 | `RHEA:57952` |
| Mercuric reductase | 1.16.1.1 | `RHEA:23856` |
| Alkylmercury lyase | 4.99.1.2 | `RHEA:18777` |

---

## 13. If accepted: curation order and effort

The order is chosen so that each step composes with what already exists and so
that the funnel is never left with an unusable hub.

1. `oxopentenoate_degradation` — three reactions, two alternative systems, exits
   into the existing `PYRUVATE` and `ACETYL_COA` anchors. Nothing depends on it
   yet, which makes it the safest first step.
2. `catechol_ortho_cleavage` and `catechol_meta_cleavage` — the hub. The second
   composes into step 1 through `OXOPENTENOATE`.
3. `benzoate_degradation_catechol` — the first entry. After this the composition
   graph has its first convergent funnel and `gift_graph` should show
   benzoate → catechol → two exits.
4. `phenylacetate_degradation` — the most host-relevant trait, independent of
   the funnel, and the one that exercises the multifunctional-marker path.
5. The phenylpropanoid node (§8.5) — two or three GIFTs, composing into the
   existing `SUCCINATE`, `PYRUVATE` and `ACETYL_COA` anchors.
6. `anthranilate_degradation_catechol` and `phenol_hydroxylation` — the second
   and third funnel entries.
7. `mercury_detoxification` — independent of everything above; can be done at
   any point, and is the only item needing a new facet value in a
   non-metabolic vocabulary.
8. Optional: `oxoadipate_to_succinyl_coa`, once the thiolase treatment in §8.2
   is agreed.

Tests the layer must add, beyond the existing suites:

- OR across the two *meta*-cleavage routes, and across the two lactonase systems
  in the ortho route.
- The negative specificity case: a genome carrying `K07104` and nothing else does
  **not** complete `catechol_meta_cleavage`; a genome carrying only
  `IPR001663`-level evidence completes no GIFT in this layer at all.
- Composition: benzoate → catechol → both exits, through declared anchors only,
  with no edge created by shared internal intermediates such as *cis,cis*-muconate.
- The funnel's convergence: two entry GIFTs reaching one hub anchor, which no
  existing curated content tests.
- Defense: mercury complete with MerA alone; complete with MerA plus accessory
  functions; incomplete with MerT/MerP but no MerA.
- Anchor facet validation for `anthropogenic`, and rejection of an unregistered
  facet value.

Rough size: 9 GIFTs, 11 anchors, ~34 reactions, ~40 enzyme systems, ~55
components, ~50 markers, of which 5 are non-KO. That is comparable to the
vitamin layer in volume and smaller in curation risk, because every accepted
route has a KEGG module boundary and a Rhea master at every step.

---

## 14. Open questions for the reviewer

1. **Is an environmental layer wanted at all?** giftr's anchors already admit
   "environmental or host compound", so nothing forbids it, but the curated
   content and the `physiological_role` vocabulary are currently gut-centric.
   Six of the nine proposed GIFTs will fire mostly in soil and water
   Proteobacteria. The three that will fire in host-associated genomes are
   `phenylacetate_degradation`, the phenylpropanoid node, and
   `mercury_detoxification`. **A defensible narrower decision is to curate only
   those three and leave the funnel unbuilt** — this proposal recommends the
   full nine because the funnel is what makes the entries composable, but the
   narrow option is coherent and cheaper.
2. **Should broad-spectrum (organomercurial) mercury resistance be a second
   defense GIFT** rather than an accessory function of one? 124 genomes would
   support it, and it is a genuinely different resistance phenotype.
3. ~~**Is `metal_detoxification` the right `defense_class` name**, or should the
   class be narrower (`mercury_resistance`)?~~ **Resolved, 2026-08-19: neither.**
   The class is `chemical_detoxification`, named for the mechanism and scoped
   wider than metals. `metal_detoxification` would hold three curatable members
   ever, and `metal_resistance` would name an outcome giftr does not claim and a
   roster that is mostly not defense GIFTs. §10.6 carries the evidence. Arsenate
   and chromate reduction are still assessed on their own evidence later, and
   §10.6 records that on today's markers both would be refused.
4. **Does `oxoadipate_to_succinyl_coa` belong in the first release?** Curating it
   removes a terminal anchor from the graph; not curating it keeps the layer's
   evidence cleaner.
5. **Should `SUCCINYL_COA` be introduced by this layer at all**, given that it is
   a central metabolite the citric acid cycle segments will want, and introducing
   it here fixes its ChEBI identity and facets before that work happens?

---

## 15. What this layer would deliberately not claim

- That a positive call means the organism degrades the compound in situ. Every
  accepted route is aerobic and most positives are environmental isolates.
- That a negative call means the capability is absent. Nine of the requested
  capabilities are refused because their markers cannot support them, not
  because genomes lack them; a toluene degrader will be silent in giftr.
- That the layer covers "xenobiotic degradation". It covers nine capabilities,
  named for the chemistry each one performs, and the phrase "xenobiotic
  degradation" appears nowhere in the database.
- That mercury detoxification confers resistance. It claims the encoded
  machinery for Hg(II) reduction, which is the mechanism resistance rests on and
  not the phenotype.

---

## 16. Implementation record, 2026-08-19

Curated into database version **2026.19.1**, schema unchanged at 6, with **no R
code change**. Twelve metabolic GIFTs, twelve anchors, thirty reactions,
thirty-six enzyme systems, fifty components and forty-nine markers. The refusals
of §9 stand as written and are recorded in `database_changes.tsv` as
`DBC-20260819-AROMATIC-REFUSALS`.

**Mercury was not curated in this release.** It was assessed separately and
curated the same day; §17 is its implementation record.

Six departures from §8, all of them made during curation and all of them in the
same direction — cutting where a segment is shared, so that composition does the
work instead of duplication.

1. **The phenylacetate route ends at 3-oxoadipyl-CoA, not at acetyl-CoA and
   succinyl-CoA.** Its final thiolysis is the same reaction, catalysed by the
   same PaaJ/PcaF orthologue, that ends the ortho-cleavage funnel. Curating it
   inside both routes would have duplicated an atomic capability in two larger
   traits, which invariant 8 forbids. It is now `oxoadipyl_coa_thiolysis`, and
   both routes compose into it through the new `OXOADIPYL_COA` anchor.
2. **The ortho exit is two GIFTs, not one.** `oxoadipate_activation` (the pcaIJ
   CoA transfer) and `oxoadipyl_coa_thiolysis` are separated for the same reason,
   because the thioester is where phenylacetate joins.
3. **The phenylpropanoid node is three GIFTs, and the third stops earlier than
   proposed.** `dihydroxyphenylpropanoate_degradation` ends at 2-oxopent-4-enoate
   and succinate rather than running on to pyruvate and acetyl-CoA, so that it
   composes into `oxopentenoate_degradation` instead of repeating it.
4. **Twelve anchors, not eleven.** `OXOADIPYL_COA` is the addition, and it is a
   consequence of departures 1 and 2. Four of the eleven ChEBI identifiers
   drafted in §11 were wrong and were corrected against ChEBI and Rhea before
   curation; the table now carries the verified ones.
5. **No new `substrate_class` was registered.** `aromatic_compound` already
   existed, added by the aromatic biosynthesis layer between the assessment and
   the implementation. Its definition was widened to cover ring-cleavage
   products rather than a second class being created for them
   (`DBC-20260819-AROMATIC-CLASS`).
6. **`trans`-cinnamate is not an anchor.** §8.5 proposed naming the trait for the
   pair; the curated form declares `PHENYLPROPANOATE` alone and states in the
   GIFT description that cinnamate lies within the same enzyme's range and is
   not claimed. Naming a boundary for two molecules would have made the anchor
   mean less than the molecule it names.

Three predictions were checked rather than assumed, and two of them were wrong.

- **The `K07104` refusal holds in evaluation**, not only in argument: a genome
  carrying it with a complete lower *meta* pathway is negative for
  `catechol_meta_cleavage`, and `K00446` or NCBIfam `TIGR03211` is required.
- **Adding MhpF and XylQ as alternative systems does not broaden ethanol
  formation.** §10 predicted it would. It does not: that route's second reaction
  rests on AdhE alone, and any genome carrying AdhE already satisfied the first,
  so no ethanol call moves. The change record was corrected from `broadens` to
  `none` after measuring, and a test now pins the behaviour.
- **`gift_profile.resource_strategy` reports `private`, not `unresolved`.** §10.4
  predicted the latter. The view classifies a GIFT with no extracellular
  boundary as private, so a layer whose compartments were never licensed reads
  as private metabolism rather than as an open question. Nothing is wrong with
  the view; the wording of §10.4 was, and it has been corrected there.

The §10.1 convention was applied as recommended: the benzoate, anthranilate and
phenylpropanoate oxygenases are curated with their substrate-determining subunits
only, and each system description says so. The phenol hydroxylase and the
phenylacetyl-CoA epoxidase keep every subunit, because there the components are
the enzyme. `enzyme_component` still has no `required` column.

What the curated layer looks like in the composition graph, which is the point of
having cut it this way:

```text
BENZOATE ─┐
ANTHRANILATE ─┼─> CATECHOL ─┬─> OXOADIPATE ─> OXOADIPYL_COA ─> SUCCINYL_COA + ACETYL_COA
PHENOL ───┘               └─> OXOPENTENOATE ─> PYRUVATE + ACETYL_COA
                                     ^
PHENYLPROPANOATE ─┐                  │
                  ├─> DHPP ──────────┘ (+ SUCCINATE)
HPP ──────────────┘
PHENYLACETATE ─────────────> OXOADIPYL_COA
```

Thirteen composition edges, all through declared anchors. `test-aromatic.R`
asserts the shape, including the two edges that must **not** exist: ortho
cleavage reaches neither the thiolysis nor the lower *meta* route directly,
because *cis,cis*-muconate and the lactones are internal and create nothing.

Tests added in `tests/testthat/test-aromatic.R` (209 assertions): evidence depth
for all twelve GIFTs, the funnel's edges and its two forbidden ones, the
`K07104` refusal in both branches, OR across the two *meta* routes and across the
alternative lactonase and lower-route systems, AND across oxygenase subunits with
the excluded reductase proved inert, all six phenol hydroxylase subunits required
one by one, either anthranilate oxygenase alone sufficient, the missing-reaction
report naming the thiolase, one bifunctional PaaZ accession evidencing two
consecutive reactions through one gene, curated reverse orientations, the
ethanol-formation non-effect, the facet classification including the absence of
any xenobiotic role, and the oxygen requirement of every route.

Two existing tests changed because the new content is genuinely visible to them:
`test-scfa.R` now expects the aromatic funnel among the producers of acetyl-CoA,
and `test-organic-acid.R` admits one non-cycle producer of succinate, keeping its
real guard — that no `_formation` trait may produce it — intact.

---

## 17. Implementation record: mercury, 2026-08-19

Curated into database version **2026.19.1**, schema unchanged at 6, with **no R
code change**. One defense GIFT, one mechanism, four defense functions, six
systems, seven components and eight markers. §8.8 was implemented as written;
four things were decided during curation and are recorded here.

1. **The function is `DF_MER_HG_DELIVERY`, not "import".** Curating it as import
   would have named a transport event the mechanism does not require and giftr
   cannot evidence. What the function claims is that the metal reaches MerA by a
   curated route, and it is accessory precisely because mercury reaches the
   cytoplasm without one.
2. **The three transporters are three systems, not one system with alternative
   components.** `SYS_DF_MERTP` holds MerT and MerP as jointly required, and
   `SYS_DF_MERC` and `SYS_DF_MERE` stand beside it under OR. This is the first
   defense function with alternative systems — RM and CRISPR both have one system
   per function — and it is the shape the biology has: *merC* and *merE* replace
   the pair rather than supplementing it.
3. **`TIGR02053` is curated beside `K00520` on the MerA component, at
   `high-confidence`.** Evidence rows are alternatives, so a genome hit only by
   the NCBIfam family calls the GIFT complete and reports the weaker confidence,
   which is the honest reading. `NF033555` for MerB and the InterPro entries
   `IPR021179` and `IPR004927` are **refused**: giftr's evidence layer normalises
   KO, EC, Pfam, TIGRFAM, CAZy and custom HMMs, so an NF or IPR accession would
   be stored and never matched — worse than absent, because it reads as evidence.
   MerB is therefore evidenced by `K00221` alone. Recorded as
   `DBC-20260819-MER-EVIDENCE-REFUSALS`.
4. **`K19057` (MerD) is refused** for the induction function. §8.8 listed it
   beside MerR, but evidence rows are alternatives within a component, and MerD
   is a co-regulator that modulates MerR-driven transcription rather than
   activating the promoter. Accepting it would let a genome carrying no activator
   claim induction. The induction function is evidenced by `K08365` alone.

**Facet.** One new value, `defense_class = chemical_detoxification`, registered
with the definition in §11 and argued in §10.6. `defense_class` now partitions
three defense GIFTs across three values.

**No KEGG link.** None of `K00520`, `K00221`, `K08363` or `K08365` belongs to any
KEGG pathway or module, so `mercury_detoxification` joins the eight GIFTs with no
external pathway record. The operon boundary is the biology's, not KEGG's, which
is why §7's table recorded mercury as "not a KEGG module" in the first place.

**Tests.** Five in `tests/testthat/test-regulatory-defense.R`: completeness on
*merA* alone and its absence without it; the three accessory functions
unsupported without changing the call; *merC* substituting for the *merT*-*merP*
pair and MerT alone failing it; the NCBIfam family completing the call at
`high-confidence`; the class facet, the description's refusal of a survival
claim and the three change records; and the *merD*, NF and IPR refusals. Four
inventory expectations updated for the new GIFT. Full suite green at 3354.

**Still open.** §14.2 — whether broad-spectrum organomercurial resistance should
be a second mechanism rather than an accessory function — is unchanged by this
curation and stays open. `hgcAB` mercury methylation remains out of scope: it
makes mercury more toxic, and it is a different assessment.
