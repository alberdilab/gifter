# Curation proposal: short-chain fatty acid formation GIFTs

Status: **accepted and implemented in database version 2026.13.1 (schema 6).**
Evidence test applied 2026-08-18 against database version 2026.12.3. The
implementation record, including where it departed from this proposal, is §14.

Scope: decide whether and how bacterial short-chain fatty acid (SCFA) formation
should be expressed under the giftr ontology, and identify what must be
architecturally true before any of it can be curated.

The short answer is that the ontology and the runtime need **no change at all**,
that KEGG orthology is **not sufficient evidence for butyrate** — the single most
requested trait in this layer — and that the marker which *is* sufficient already
lives in a namespace giftr's evaluator recognises but no curated row has ever
used. Two of the eight candidates survive on KEGG evidence alone, one survives
only by moving to that second namespace, and four are refused.

---

## 1. Recommendation in one page

1. **No schema migration, no code change.** `marker.namespace` is an open text
   column with no `CHECK`, and `R/evaluation.R` already recognises `TIGRFAM`
   accessions (`^TIGR[0-9]{5}$`) and a `CUSTOM_HMM` namespace. Both are unused
   by curated content today. §3.
2. **Curate `acetate_interconversion` first** (acetyl-CoA ⇄ acetate, Pta–AckA).
   KEGG-module-backed, Rhea-backed, and complete in 6582 of 11 856 KEGG
   organisms. Give it `mode = 'interconversion'` — the schema's fourth mode
   value, so far unused — because the node is freely reversible and a
   `catabolic` declaration would both overclaim and set up a within-mode cycle
   with any future acetate-activation GIFT. §7.1, §8.
3. **Curate `butyrate_formation` with one route only**, and evidence its
   terminal step with **NCBIfam TIGR03948 / InterPro IPR023990**, not with a KO.
   The KO layer cannot do this trait: it calls *Faecalibacterium prausnitzii*,
   *Roseburia intestinalis* and *Agathobacter rectalis* negative and
   *Bacillus subtilis* positive. §6.2.
4. **Refuse the butyrate-kinase route.** Ptb/Buk are shared with *Bacillus*
   branched-chain acyl-CoA metabolism at KO *and* at TIGRFAM level, so no
   namespace change rescues it. §6.2.
5. **Curate `propionate_formation_propanediol`** (168 genomes, Enterobacteriaceae-
   clean) and note that it composes with the already-curated fucose and
   rhamnose GIFTs through the existing `LACTALDEHYDE` anchor. §6.3.
6. **Refuse `propionate_formation_succinate`** (the Wood–Werkman route). Its
   markers are the same genes used in the *degradative* direction by
   *Escherichia* and *Klebsiella*, its positives are dominated by
   *Corynebacterium*, and *Bacteroides thetaiotaomicron* — the dominant gut
   propionate producer — is negative. §6.3.
7. **Conditionally accept `propionate_formation_acrylate`**: 13 genomes carry
   pct + lcdAB and every one of them is a characterised acrylate-pathway
   propionate producer. Recall is poor and the reductase step is annotated in
   only 4 of the 13, which is reported as a missing reaction rather than scored
   away, exactly as the serine phosphatase already is. §6.3.
8. **Refuse `lactate_formation` and `formate_formation` on scope**, not on
   evidence: neither is an SCFA under the C2–C6 definition this layer uses. §2.
9. **Curate `pyruvate_to_acetyl_coa` as a prerequisite**, not as an SCFA GIFT.
   Without it the whole SCFA layer is an island: giftr's catabolic content
   currently ends at `PYRUVATE`, and the SCFA layer begins at acetyl-CoA. §7.2.
10. **Accept one honest limitation and record it**: with SCFA anchors declared
    `unspecified`, `gift_profile.cross_feeding_output` stays 0 for the whole
    layer. Acetate cross-feeding is the textbook case and the model still cannot
    say it, because no SCFA transport GIFT is evidenceable. §9.

---

## 2. Scope: what counts as an SCFA here

SCFA is a chemical class, not a capability, so the layer needs a stated cut.
This proposal uses **aliphatic monocarboxylates of two to six carbons produced
as fermentation end products**: acetate (C2), propionate (C3), butyrate (C4),
and in principle valerate and caproate (C5/C6).

Three neighbours are deliberately outside it.

- **Formate (C1)** is excluded by chain length. Pyruvate formate-lyase is
  nonetheless good chemistry with clean markers (K00656 + activase K04069,
  2843 organisms), and it belongs in giftr as one route of
  `pyruvate_to_acetyl_coa` (§7.2), where formate is a co-product rather than
  the claim.
- **Lactate (C3)** is a 2-hydroxy acid, not a fatty acid, and is conventionally
  reported alongside SCFAs rather than as one. It is excluded as a *product*
  claim but is required as an *input* anchor for the acrylate route (§6.3).
- **Branched isovalerate and isobutyrate** come from leucine and valine
  fermentation, are a protein-fermentation trait rather than a carbohydrate
  one, and share the *Bacillus* branched-chain acyl-CoA enzymes that this
  proposal spends §6.2 refusing. Deferred.

Valerate and caproate are in scope by definition but out of scope in practice:
chain elongation runs through the same generic short-chain acyl-CoA enzymes as
butyrate with no chain-length-specific marker at all, which is the §5 test's
clearest possible failure.

---

## 3. What the ontology and the runtime already support

Nothing in this layer requires a migration. Four things were checked.

**The marker namespace vocabulary is open, and already wider than the curated
content.** `marker.namespace` is `TEXT NOT NULL` with no `CHECK` constraint
(`inst/schema/giftr.sql:180`). More usefully,
`.infer_marker_namespace()` (`R/evaluation.R:13`) already maps
`^TIGR[0-9]{5}$` to `TIGRFAM`, `.normalize_marker_namespace()` already carries
`TIGRFAM` in its alias table, and `.normalize_marker_accession()` already
upper-cases accessions in `PFAM`, `TIGRFAM`, `CAZY` and `CUSTOM_HMM`. A user who hands
`evaluate_gifts()` a bare TIGRFAM accession is already handled; there is simply
no curated row for it to match. The collagenase precedent
(`PFAM PF01752`, `component_markers.tsv:491`) established that leaving KO for a
substrate-specific sequence family is a curation decision, not an
architectural one.

**`mode = 'interconversion'` exists and has never been used.** The `gift.mode`
`CHECK` admits `anabolic`, `catabolic`, `transport` and `interconversion`;
all 29 metabolic GIFTs use one of the first three. §8 argues the acetate node is
what the fourth value was for.

**`oxygen_requirement` is already a route property.** Three of the four routes
this proposal touches are strictly fermentative and one is not, and the schema
records that per route rather than per GIFT — which is correct here, because
`acetate_interconversion` really does have oxygen-independent chemistry while the
propanediol route really does not.

**Rhea covers every reaction in the layer.** Sixteen ECs were checked against
the Rhea API on 2026-08-18 and all sixteen returned a master. No reaction in
this layer needs the nullable-`rhea_master` path that the polysaccharide and
protein layers opened. §10 lists the identifiers.

---

## 4. What each source actually supplies

| Source | What it gives this layer | What it does not |
|---|---|---|
| **Rhea** | A master reaction for every step, including the substrate-specific `RHEA:30071` for the butyryl-CoA:acetate transfer | Nothing about which genes do it |
| **KEGG modules** | `M00579` only (Pta–AckA). There is **no KEGG module for butyrate formation and none for propionate formation** | Module boundaries for 3 of the 4 candidate GIFTs |
| **KEGG orthology** | Clean KOs for the acetate node and the propanediol route; chain-length-generic KOs for the butyrate core; a fused KO (`K01034`/`K01035`, EC 2.8.3.8 *and* 2.8.3.9) where butyrate needs specificity | Any orthologue specific to butyryl-CoA:acetate CoA-transferase |
| **MetaCyc** | Pathway boundaries (`CENTFERM-PWY`, `P108-PWY`, `PWY0-1312`) that agree with the cuts proposed here | Machine-readable, licence-clean markers. The pathway pages are subscription-gated and returned no content on 2026-08-18; giftr cites no MetaCyc record today and this layer gives no reason to start |
| **InterPro / NCBIfam / HAMAP** | The one marker that makes butyrate curatable: `IPR023990`, `TIGR03948`, `MF_03227` | Coverage — 178 proteins, see §6.2 |
| **ChEBI** | Anchor identity for every new anchor | — |

The headline is the middle two rows. **KEGG organises this layer worse than it
organises any layer giftr has curated so far**, and the gap is not one of
pathway bookkeeping — it is that the terminal enzyme defining the trait has no
orthology group of its own.

---

## 5. The test

The same test the protein layer applied to proteases, restated for fermentation
end products, with one clause added:

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
                        +-- yes --> curate
```

The second clause is new, and this layer is why. Every trait giftr has curated
so far is directionally unambiguous: nothing runs serine biosynthesis backwards
to make 3-phosphoglycerate, and no genome encodes a xylanase in order to
polymerise xylose. Fermentative end-product formation is different. The
terminal enzymes are near-equilibrium and physiologically bidirectional:
Pta–AckA runs both ways in *Escherichia coli*, the methylmalonyl-CoA mutase and
decarboxylase of the succinate route are the same genes KEGG module `M00741`
uses to *degrade* propanoyl-CoA, and butyryl-CoA:acetate CoA-transferase is the
enzyme *Syntrophomonas wolfei* uses to consume butyrate.

giftr stores direction per route, in `route_reaction.orientation`. That is a
curatorial claim about the chemistry, not an inference from the evidence. For
this layer the distinction has to be stated out loud in every GIFT description,
because the markers are direction-blind.

---

## 6. Outcome when the test was applied, 2026-08-18

Marker prevalence below is the number of KEGG organisms carrying the marker, out
of the 11 856 organisms that carry at least one of the 49 orthology groups examined
(the KEGG genome list holds 11 949 entries, so this is effectively all of KEGG).
Sets were built from `https://rest.kegg.jp/link/genes/ko:<KO>` and intersected
locally.

| Trait | Best marker set | Specific? | Directional? | Outcome |
|---|---|---|---|---|
| Acetate formation | `K00625`/`K13788`/`K15024` + `K00925` | yes | **no** | **curate**, reversibility stated |
| Butyrate formation, CoA-transferase route | `TIGR03948` | **yes** | yes | **curate**, non-KO marker |
| Butyrate formation, kinase route | `K00634`+`K00929`, `TIGR02706`+`TIGR02707` | **no** | yes | refused |
| Propionate formation, propanediol route | `K01699`+`K13919`+`K13920`+`K13922`+`K13923`+kinase | yes | yes | **curate** |
| Propionate formation, acrylate route | `K01026`+`K20626`+`K20627`(+`K20143`) | yes | yes | conditionally curate |
| Propionate formation, succinate route | `K01847`/`K01848`+`K01849`, `K01604`/`K11264`, `K01026`/`K18118` | no | **no** | refused |
| Valerate / caproate formation | none | no | — | refused |
| Branched SCFA formation | none chain-specific | no | — | refused, out of scope |

### 6.1 Acetate — passes, with a caveat that must be in the name

`M00579` is the only KEGG module in the layer, and it is a good one:
`(K00625,K13788,K15024) K00925`, two reactions, both Rhea-mastered
(`RHEA:19521`, `RHEA:11352`). Phosphate acetyltransferase in some form is
present in 6978 organisms, acetate kinase in 7614, and **6582 carry both** —
every organism with a phosphotransacetylase also has the kinase.

All fourteen reference genomes checked are positive except *Akkermansia
muciniphila*, which carries `K00625` and no acetate kinase despite excreting
acetate. That is a route-coverage observation rather than a refusal: an
ADP-forming acetate—CoA ligase (`K01905`, 167 organisms) and acetyl-CoA
hydrolase (`K01067`, 573) are the candidate second and third routes, and can be
added later without changing the anchors.

The caveat is §5's second clause. Pta–AckA is the standard acetate *uptake*
route as well, and 56% of KEGG bacteria carry it — this is close to a
housekeeping capability. The GIFT must therefore be named and described for the
chemistry, not for the physiology: *encodes the two-step interconversion of
acetyl-CoA and acetate through acetyl phosphate*. It must not be described as
"acetate production", and a positive call must not be read as SCFA output.

### 6.2 Butyrate — KO evidence fails, and the failure is measurable

This is the substantive result of the assessment.

The acetyl-CoA route core is thiolase (`K00626`), 3-hydroxybutyryl-CoA
dehydrogenase (`K00074`), crotonase (`K01715`) and butyryl-CoA dehydrogenase
(`K00248`), with electron-transfer flavoprotein `K03522`/`K03521`. Terminal
options are Ptb+Buk (`K00634`+`K00929`) or the CoA-transferase KEGG assigns to
`K01034`+`K01035`.

**Every one of those KOs is chain-length-generic or fused.** `K00074` is named
`paaH, hbd, fadB, mmgB` — the phenylacetate and β-oxidation dehydrogenases are
in it. `K01715` is EC 4.2.1.150, *short-chain*-enoyl-CoA hydratase. `K00248` is
`ACADS, bcd`, the generic short-chain acyl-CoA dehydrogenase. `K01034`/`K01035`
carry EC 2.8.3.8 **and** EC 2.8.3.9 together, so the accession that would have
to stand for butyryl-CoA:acetate CoA-transferase is the same one that stands for
the *Escherichia coli* acetoacetate degradation transferase.

What that costs, in numbers:

| KO-based rule | Organisms |
|---|---:|
| core (thiolase + hbd + crt + bcd) | 1042 |
| core + EtfAB | 957 |
| Ptb + Buk | 817 |
| `K01034` + `K01035` | 835 |
| **core + Ptb + Buk** | **366** |
| **core + `K01034`/`K01035`** | **344** |

The 366 genomes completing core + Ptb + Buk break down as **120 *Bacillus*,
58 *Clostridium*, 16 *Geobacillus*, 8 *Metabacillus*, 6 each of *Neobacillus*,
*Halobacillus*, *Cytobacillus* and *Anoxybacillus*** — aerobic Bacillota that do
not ferment to butyrate, and that carry Ptb/Buk and the acyl-CoA dehydrogenase
set for branched-chain fatty acid metabolism.

The false negatives are as bad as the false positives. Among the 39 KEGG
genomes in canonical butyrate-producing genera (*Faecalibacterium*,
*Roseburia*, *Agathobacter*, *Anaerostipes*, *Anaerobutyricum*,
*Butyricicoccus*, *Butyrivibrio*, *Pseudobutyrivibrio*, *Coprococcus*,
*Intestinimonas*, *Agathobaculum*, *Oscillibacter*, *Eubacterium*):

- 31 of 39 complete the KO core,
- 20 of 39 also carry both EtfAB subunits,
- **9 of 39 carry any terminal KO at all.**

Individually: *F. prausnitzii* L2-6 completes the core and has no terminal KO.
*A. rectalis* ATCC 33656 completes the core and has no terminal KO.
*Anaerostipes hadrus* completes the core and carries only `K01035`, half of the
transferase pair. *R. intestinalis* XB6B4 has no thiolase KO assigned at all.
Meanwhile *Bacillus subtilis* 168 completes the core, Ptb+Buk **and**
`K01034`+`K01035`.

A KO-evidenced `butyrate_production` GIFT would therefore call the four
archetypal gut butyrate producers negative and *Bacillus subtilis* positive.
Under invariant 16 that is not a trait to tune; it is a trait to refuse at that
evidence level.

**The marker that works is not a KO.** InterPro carries `IPR023990`,
*Butyryl-CoA:acetate CoA-transferase*, built from NCBIfam `TIGR03948` and HAMAP
`MF_03227`, and described as "one of at least two mechanisms for reclaiming CoA
from butyryl-CoA at the end of butyrate biosynthesis". `TIGR03948` matches 178
proteins in 171 proteomes across 315 taxa. The top genera among its matches are
*Peptoniphilus* (16), ***Faecalibacterium*** (16), *Brachyspira* (11),
***Roseburia*** (9), ***Eubacterium*** (8), ***Anaerostipes*** (8),
*Pseudoflavonifractor* (7), *Agathobaculum* (5), *Butyricicoccus* (4),
*Pseudobutyrivibrio* (3), *Anaerobutyricum* (3), *Intestinimonas* (2),
*Agathobacter* (2). **No *Bacillus*, *Escherichia*, *Salmonella* or
*Pseudomonas* match.** This is the collagenase situation exactly: the sequence
family is the substrate claim, because the family was built around the
characterised activity rather than around a fold.

Recommendation: curate `butyrate_formation` with **a single route** — the
acetyl-CoA condensation and reduction core, plus the CoA-transferase terminal
step evidenced by `TIGRFAM TIGR03948` — and record `IPR023990` and `MF_03227`
in the curation note as the corroborating entries.

Refuse the kinase route. `TIGR02707` (butyrate kinase, 2279 proteins) and
`TIGR02706` (phosphate butyryltransferase, 573) put *Bacillus* second and third
by genus count, so the non-specificity is real biology, not a KEGG artefact, and
changing namespace does not fix it. Record the refusal.

One open decision follows from the recall figures and is in §11: **EtfA/EtfB
should not be required components of the Bcd system.** `K03521`/`K03522` are
`fixA`/`fixB`, the electron-transfer flavoprotein orthologues shared with
nitrogen fixation, present in 7729 organisms — they carry no butyrate-specific
information, and requiring them costs 11 of the 31 core-completing reference
genomes for no gain in specificity. A marker that is near-universal is not
evidence.

### 6.3 Propionate — one route passes cleanly, one narrowly, one fails

**Propanediol route — curate.** `pduCDE` (`K01699`+`K13919`+`K13920`) is
present in 348 organisms; adding propionaldehyde dehydrogenase `K13922` gives
303, phosphotransacylase `K13923` gives 232, and a propionate kinase
(`K19697` or `K00932`) gives **168**. Those 168 are *Salmonella* (51),
*Klebsiella* (46), *Citrobacter* (24), *Yersinia* (18), *Escherichia* (9) — the
`pdu` operon of the Enterobacteriaceae, which is exactly right. *Salmonella*
Typhimurium LT2 completes it; *Propionibacterium freudenreichii*, which carries
`pduCDE` and `pduP` for a different purpose, correctly does not.

This route also does something no other candidate does: **it composes with
already-curated giftr content through an existing anchor.** `fucose_degradation_isomerase`
and `rhamnose_degradation` both terminate at `LACTALDEHYDE`
((S)-lactaldehyde, CHEBI:18041), and lactaldehyde reductase FucO (`K00048`,
`RHEA:15933`, 629 organisms) reduces exactly that anchor to
(S)-propane-1,2-diol. 145 of the 232 `pdu`-carrying organisms also carry
`K00048`. Curating this route extends the existing deoxyhexose layer into a
named fermentation product without re-cutting a single existing GIFT.

**Acrylate route — conditionally curate.** Propionate CoA-transferase
(`K01026`) with lactoyl-CoA dehydratase (`K20626`+`K20627`) is complete in
**13 organisms, and all 13 are characterised acrylate-pathway propionate
producers**: *Anaerotignum propionicum* (formerly *Clostridium propionicum*),
*Megasphaera elsdenii*, *M. stantonii*, *M. massiliensis*,
*Pseudocoprococcus catus*, *Fusobacterium necrophorum*, two *Desulfosporosinus*
and four other clostridia. Precision is perfect; recall is negligible, because
`K20626`/`K20627` are assigned in only 14 and 13 organisms respectively.

The catch is the acrylyl-CoA reductase step. `K20143` (`acrC`, NADH-dependent)
is assigned in 22 organisms total and in only **4 of the 13**. giftr's existing
policy decides this: the serine phosphatase step is kept required even though a
fifth of `serA`/`serC` genomes carry no recognised phosphatase orthologue,
because "the chemistry is required and the missing reaction is reported rather
than silently scored away". The same applies — curate the reductase as required,
expect four complete calls, and report the other nine as incomplete with the
named missing reaction. Whether a GIFT that fires in four genomes earns its
place is a curator's call, not an evidence question; it is listed as
conditional for that reason alone.

**Succinate (Wood–Werkman) route — refuse.** This is the route most people mean
by "*Bacteroides* propionate", and it fails both clauses of the test.

Methylmalonyl-CoA mutase in some form is present in 4480 organisms, a
methylmalonyl-CoA decarboxylase (`K01604`/`K11264`) in 958, and a candidate
CoA-transferase (`K01026`/`K18118`) in 2910. All three together: **177**.
Allowing the transcarboxylase `K17489` as an alternative to the decarboxylase
raises it to 293, and the genus breakdown of those 293 is *Corynebacterium* (70),
*Escherichia* (19), *Cutibacterium* (16), *Klebsiella* (13), *Tessaracoccus* (8),
*Veillonella* (7), *Selenomonas* (7). *Veillonella*, *Selenomonas*,
*Cutibacterium* and *Acidipropionibacterium* are genuine; *Escherichia* and
*Klebsiella* carry the mutase and decarboxylase for propanoyl-CoA **degradation**,
which is what KEGG module `M00741` describes.

Meanwhile *Bacteroides thetaiotaomicron* is negative — it carries the mutase and
the decarboxylase but no CoA-transferase KO, releasing propionate through
enzymes KEGG does not resolve. Its `K00634`+`K00929` pair is the same Ptb/Buk
that §6.2 refused for butyrate, and Ptb/Buk act on propanoyl-CoA as readily as
on butanoyl-CoA. Accepting them here would make one marker pair evidence for
two different SCFA traits at once — the precise damage invariant 16 describes.

Refuse, and record the trigger for revisiting: a CoA-transferase or
acyltransferase marker that resolves propionate release, and a way to separate
the biosynthetic from the degradative direction.

---

## 7. Anchors, and what they connect to

### 7.1 New anchors required

| anchor_id | molecule | compartment | ChEBI | role |
|---|---|---|---|---|
| `ACETYL_COA` | acetyl-CoA | unspecified | CHEBI:57288 | central branchpoint; input of the acetate and butyrate GIFTs |
| `ACETATE` | acetate | unspecified | CHEBI:30089 | product; also the CoA acceptor consumed by the butyrate transferase route |
| `BUTYRATE` | butanoate | unspecified | CHEBI:17968 | product |
| `PROPIONATE` | propanoate | unspecified | CHEBI:17272 | product |
| `PROPANEDIOL` | (S)-propane-1,2-diol | unspecified | CHEBI:29002 | input of the propanediol route; downstream of `LACTALDEHYDE`. See the stereochemistry note in §10 |
| `LACTATE` | (R)-lactate | unspecified | CHEBI:16004 | input-only, acrylate route |

`ACETYL_COA` deserves a sentence of justification, because it is the largest hub
in metabolism and invariant 3 asks for restraint. Two curated reactions already
consume acetyl-CoA internally — serine O-acetyltransferase (`RHEA:24560`) and
homoserine O-acetyltransferase (`RHEA:13701`) — and declaring the anchor does
**not** retroactively connect them to anything, because giftr derives edges from
declared anchors only and never from shared reaction participants. The model
protects itself here by construction; this is a good demonstration of why
invariant 2 is written the way it is.

`LACTATE` is declared input-only, like `HOMOCYSTEINE`. Lactate formation is out
of scope (§2), so nothing outputs it, and the acyclicity argument is the same
one already recorded for the methionine layer.

### 7.2 The prerequisite: pyruvate to acetyl-CoA

giftr's catabolic content currently ends at `PYRUVATE`, `GAP`, `DHAP`,
`FRUCTOSE_6P`, `GLUCOSE_1P` and `XYLULOSE_5P`. The SCFA layer starts at
acetyl-CoA. Without a GIFT spanning that gap, `acetate_interconversion` and
`butyrate_formation` are isolated nodes in `gift_graph` and
`gift_profile.network_position` reports them as `isolated` — technically
correct, biologically absurd for the terminal step of fermentation.

`pyruvate_to_acetyl_coa` closes it with three well-evidenced alternative routes:

| Route | Markers | Organisms | Rhea | Oxygen |
|---|---|---:|---|---|
| Pyruvate dehydrogenase complex | `K00161`+`K00162`+`K00627`+`K00382` | 5406 | `RHEA:19189` + E2/E3 steps | independent |
| Pyruvate:ferredoxin oxidoreductase | `K00169`+`K00170`+`K00171`+`K00172` | 499 | `RHEA:12765` | anaerobic |
| Pyruvate formate-lyase | `K00656` + activase `K04069` | 2843 | `RHEA:11844` (reverse) | anaerobic |

7694 organisms complete at least one. This is a textbook OR-over-routes,
AND-over-components case with a genuine oxygen distinction between routes, and
it is worth curating on its own merits even if no SCFA GIFT follows.

The single-subunit PFOR variants and the quinone-dependent PoxB (`K00156`,
which yields acetate directly from pyruvate and bypasses acetyl-CoA entirely)
are deliberately left out of the first cut and noted for a later pass.

---

## 8. Mode, and the first use of `interconversion`

`acetate_interconversion` should be declared `mode = 'interconversion'`, not
`catabolic`. Three reasons, in order of weight:

1. **It is true.** Pta–AckA is near-equilibrium and runs in both directions in
   the same organism depending on acetate concentration. Declaring it catabolic
   asserts a direction the markers do not evidence.
2. **It prevents a future cycle rather than repairing one.** Acetate activation
   (`acs`, acetyl-CoA synthetase) is an obvious later addition and would run
   `ACETATE → ACETYL_COA`. If both were `catabolic`, `.find_graph_cycle()`
   would reject the pair, and the fix would be to mislabel one of them.
   `interconversion` partitions them correctly on the first try.
3. **It exercises a declared schema value that has never been used**, which is
   worth something on its own: an unused `CHECK` branch is an untested one.

`butyrate_formation`, both propionate GIFTs and `pyruvate_to_acetyl_coa` are
straightforwardly `catabolic`.

---

## 9. Compartment and cross-feeding: the limitation to record

SCFA cross-feeding — acetate released by one organism and consumed by a
butyrate producer — is the single most cited interaction in gut microbial
ecology, and giftr already has machinery for it: `gift_profile.cross_feeding_output`
fires when a GIFT declares an **extracellular** output anchor that another GIFT
consumes as input. The butyrate transferase route consumes acetate. The wiring
is there.

It cannot be used, because the compartment claim cannot be evidenced. giftr's
rule is that a compartment split is licensed by a transport GIFT, and the
`GLUCOSE` anchor is already left `unspecified` for exactly this reason: "glucose
is moved mainly by promiscuous carriers, so no uptake GIFT licenses a split".
SCFAs are worse. The only candidate marker is `K07034`, an "acetate uptake
transporter family protein" — family-level, uptake-directed, and covering a
channel that is bidirectional; there is no butyrate or propionate transporter KO
at all. Undissociated SCFA also crosses membranes by diffusion, which no marker
can ever evidence.

So: declare all SCFA anchors `unspecified`, accept that
`cross_feeding_output` stays 0 and `resource_strategy` reports `private` for the
whole layer, and record it as a known limitation with its trigger condition — a
substrate-specific SCFA transporter marker. This is the same deferral the
polysaccharide proposal applied to oligosaccharide anchors, and it should be
recorded the same way rather than resolved by declaring a compartment the
evidence does not support.

---

## 10. Reaction identifiers, verified 2026-08-18

Every reaction has a Rhea master. Two need care.

| Step | Rhea | Note |
|---|---|---|
| Phosphate acetyltransferase | `RHEA:19521` | acetyl-CoA + phosphate = acetyl phosphate + CoA |
| Acetate kinase | `RHEA:11352` | reversed for acetate formation |
| Thiolase | `RHEA:21036` | 2 acetyl-CoA = acetoacetyl-CoA + CoA |
| 3-hydroxybutyryl-CoA dehydrogenase | `RHEA:30799` (NAD) / `RHEA:16197` (NADP) | two alternative enzyme systems, both reversed |
| Crotonase | **`RHEA:26558`** | (3S)-3-hydroxybutanoyl-CoA = (2E)-butenoyl-CoA + H2O. **Not `RHEA:17849`**, which is the (3R) reaction, and not `RHEA:52664`, which is the generic short-chain parent |
| Butyryl-CoA dehydrogenase | `RHEA:24004` | ETF-coupled |
| Butyryl-CoA:acetate CoA-transferase | **`RHEA:30071`** | butanoate + acetyl-CoA = butanoyl-CoA + acetate, reversed. **Not `RHEA:13381`**, the generic "an acyl-CoA + acetate" parent that EC 2.8.3.8 maps to |
| Propanediol dehydratase | `RHEA:14569` | Stereochemically unspecified: Rhea has only generic `propane-1,2-diol` (CHEBI:16997) here, while FucO makes the (S) form (CHEBI:29002). Anchor the (S) compound, matching the existing (S)-`LACTALDEHYDE` anchor, and record that the reaction is stated at lower stereochemical specificity than the boundary. B12-dependent; giftr models no cofactor availability |
| Propionaldehyde dehydrogenase | `RHEA:36027` | |
| Phosphate propanoyltransferase | `RHEA:28046` | |
| Propionate kinase | `RHEA:23148` | reversed |
| Propionate CoA-transferase | `RHEA:23520` | acrylate route |
| Lactoyl-CoA dehydratase | `RHEA:34691` | |
| Lactaldehyde reductase (FucO) | `RHEA:15933` | reversed; joins `LACTALDEHYDE` to `PROPANEDIOL` |
| Pyruvate formate-lyase | `RHEA:11844` | reversed |
| Pyruvate:ferredoxin oxidoreductase | `RHEA:12765` | |

Both "not this one" rows are the same trap in different clothing: the EC number
maps to a generic parent reaction, and picking the parent would let the route
claim a chain length its chemistry does not fix. Reaction identity has to be as
specific as the trait, for the same reason marker identity does.

---

## 11. Open decisions for the curator

1. **EtfA/EtfB in the Bcd system.** Recommended: not required, on the ground
   that `K03521`/`K03522` are the generic `fixA`/`fixB` orthologues present in
   7729 organisms and carry no butyrate-specific information, while requiring
   them costs 11 of 31 reference genomes. The counter-argument is that the
   electron-bifurcating complex genuinely needs them and giftr models machines,
   not minimum sufficient marker sets. §6.2.
2. **Whether `propionate_formation_acrylate` earns curation at four complete
   calls.** Evidence quality is the highest in the layer; coverage is the
   lowest. §6.3.
3. **Whether `acetate_interconversion` should exist at all**, given that 56% of KEGG
   bacteria complete it and the call cannot distinguish production from uptake.
   The argument for is that it is the anchor point the butyrate transferase
   route consumes, and the layer has no shape without it.
4. **Whether to name GIFTs `*_formation` or `*_production`.** This document uses
   `formation`, because "production" invites the reading that the organism
   exports the acid, which §5 and §9 both say the evidence cannot support.

---

## 12. If accepted, the work is

| Table | Rows |
|---|---|
| `anchors.tsv`, `anchor_facets.tsv` | 6 anchors (§7.1), plus `ACETYL_COA` facets |
| `gifts.tsv`, `gift_anchors.tsv` | 5 GIFTs: acetate, butyrate, two propionate, pyruvate-to-acetyl-CoA |
| `gift_routes.tsv`, `route_reactions.tsv` | 8 routes, ~30 route-reaction rows |
| `reactions.tsv`, `reaction_xrefs.tsv` | ~18 reactions (§10), all Rhea-mastered |
| `enzyme_systems.tsv`, `enzyme_components.tsv` | ~25 systems, ~40 components |
| `markers.tsv`, `component_markers.tsv` | ~40 KO markers, 1 TIGRFAM marker |
| `gift_xrefs.tsv` | `M00579` `equivalent`; `M00741` `related` with the direction noted |
| `facet_terms.tsv`, `gift_facets.tsv` | new `substrate_class` value `short_chain_fatty_acid`; new `physiological_role` value `fermentative_end_product` |
| `database_changes.tsv`, `change_gifts.tsv` | one addition entry, and **three refusal entries** — butyrate kinase route, propionate succinate route, valerate/caproate |
| `tests/testthat/` | a new `test-scfa.R`, covering at minimum: the TIGRFAM marker path end to end; the negative case that `K01034`+`K01035` do **not** fire `butyrate_formation`; the `LACTALDEHYDE` → `PROPANEDIOL` composition edge; and the `interconversion` mode not entering the catabolic cycle check |
| `SOURCES.md` | InterPro/NCBIfam as a new source family, with `TIGR03948` release pinned |

The three refusal entries matter as much as the addition. The butyrate-kinase
refusal in particular will be rediscovered by the next person who reads
`M00579`'s neighbourhood and wonders why `buk` is not in the database.

---

## 13. Provenance of this assessment

All figures were retrieved on 2026-08-18.

- KEGG orthology-to-gene links: `https://rest.kegg.jp/link/genes/ko:<KO>`,
  reduced to organism codes and intersected locally. 49 orthology groups.
- KEGG genome list: `https://rest.kegg.jp/list/genome` (11 949 entries), used
  for genus attribution.
- KEGG modules `M00579`, `M00088`, `M00741`: `https://rest.kegg.jp/get/<module>`.
- Rhea: `https://www.rhea-db.org/rhea?query=ec:<EC>&format=tsv`, 16 ECs, plus
  equation lookups by Rhea ID.
- InterPro: `https://www.ebi.ac.uk/interpro/api/` — entry search for
  butyryl-CoA:acetate, butyrate kinase and phosphate butyryltransferase; protein
  match listings for `TIGR03948`, `TIGR02706`, `TIGR02707`.
- MetaCyc pathway pages returned no content without a subscription and were not
  used as evidence for any claim above.

Reference genomes used for the specificity checks, by KEGG organism code:
`fpr`, `fpa`, `rix`, `rim`, `ere`, `bprl`, `cbut`, `bth`, `amu`, `blo`, `vpr`,
`pfr`, `eco`, `stm`, `pae`, `bsu`.


---

## 14. Implementation record, 2026-08-18

Accepted and curated as release **2026.13.1**. The schema is unchanged at
version 6 and `R/` is untouched, which was the proposal's first claim and the
one most worth confirming: the layer needed content and tests, not code.

**Six GIFTs, not five.** `propanediol_formation` was added as a one-reaction
GIFT over the lactaldehyde reductase (`RHEA:15933`, reversed). §6.3 promised
that the propanediol route "composes with the already-curated fucose and
rhamnose GIFTs through the existing `LACTALDEHYDE` anchor", and §7.1 declared
`PROPANEDIOL` as an anchor — but nothing produced it, so the promised edge did
not exist. The one-reaction GIFT is what makes it real, and it is independently
defensible on the same ground as `arabinoxylan_debranching`: propane-1,2-diol is
a boundary metabolite in its own right, and 87 of the 232 genomes carrying the
utilisation operon carry no lactaldehyde reductase at all.

**The acrylate route was curated**, resolving §11 decision 2 in favour of
curation. One fact surfaced during implementation that the assessment had not
checked: its first step has **no Rhea master**. Rhea's EC 2.8.3.1 master
`RHEA:23520` covers only the propanoate/acetyl-CoA transfer, so the
lactate-accepting transfer is curated as `RXN_LACTATE_COA_TRANSFER` through the
nullable-master path, identified by KEGG R01449 and EC 2.8.3.1. This does not
change the recommendation; it adds a fifth entry to the §10 list of places where
the obvious identifier is the wrong one.

**§8 was superseded during review.** This document argued for
`mode = 'interconversion'` but kept the anchors one-way, `ACETYL_COA > ACETATE`,
and named the GIFT `acetate_formation`. Both were wrong in the same way: they
asserted the direction the mode exists to say is unevidenced, and the one-way
arrow in the atlas is what surfaced it. The GIFT is now
`acetate_interconversion`, declares both boundaries in both roles, and
`interconversion` has a written contract — every anchor mirrored, and no other
mode may mirror one — enforced in `R/database-build.R`. The route was **not**
mirrored: a flipped copy completes on identical markers, so it would report two
complete routes for one capability and make closest-route selection
non-deterministic.

**§11 decision 1 was resolved as recommended**: EtfA and EtfB are not required
components of the butanoyl-CoA dehydrogenase system, and a test asserts that
adding them changes no call in either direction.

**M00741 carries no `gift_xrefs` row**, against §12's plan. The relation column
states how a curated boundary compares with an external record, and M00741
describes the opposite direction of chemistry that no curated GIFT contains, so
there is no boundary to compare. The refusal it belongs to is recorded in
`database_changes.tsv` instead, where the reasoning lives.

**What the graph gained.** The layer connects catabolism to fermentation for the
first time, and one existing test had to change to say so. `test-sugar-degradation.R`
asserted that "a degradation GIFT is never upstream of anything"; that was true
only because nothing downstream of pyruvate or lactaldehyde had been curated. It
now asserts the invariant the test was actually protecting — that a degradation
GIFT is never upstream of a **biosynthesis** GIFT, and that its only outgoing
edges run through the declared anchors `PYRUVATE` and `LACTALDEHYDE`.

**What the calls look like.** On KEGG orthology alone, `butyrate_formation` is
incomplete in *Bacillus subtilis* 168 and in *Faecalibacterium prausnitzii* L2-6
with the same single missing reaction, `RHEA:30071`. Adding `TIGR03948`
completes it for *F. prausnitzii* and leaves *B. subtilis* incomplete. That one
pair of results is the layer's reason for existing, and `test-scfa.R` asserts it.
