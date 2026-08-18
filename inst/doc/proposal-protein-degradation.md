# Curation proposal: protein degradation GIFTs

Status: **evidence test applied 2026-08-18; one of eight candidates curated.**
Prepared against database version 2026.11.1 (schema 5).

Scope: decide whether and how host- and diet-derived protein degradation should
be expressed under the giftr ontology, and identify what must be
architecturally true before any of it can be curated.

The short answer is that the ontology needed **no schema change at all**, and
that seven of the eight candidate traits do not survive contact with the
available genomic evidence. Both results are recorded here because both are
useful, and because the temptation to fix the second by relaxing the first is
the failure this document exists to prevent.

---

## 1. Recommendation in one page

1. **No schema migration.** Every capability the protein layer needs already
   exists (§2). Anchors are not restricted to small molecules, `rhea_master` is
   already nullable, and the marker namespace vocabulary is already open.
2. **Curate `collagen_cleavage` only.** It is the single candidate whose
   genomic evidence is as specific as the trait name claims (§4).
3. **Refuse the other seven** — elastin, keratin, albumin, actin, glutelin,
   tropomyosin, troponin — for the reasons in §4, and record the refusals so
   they can be revisited when evidence changes rather than rediscovered.
4. **Do not anchor on a generic `PEPTIDES` pool** (§5). The cleavage product is
   anchored substrate-specifically, and a shared peptide tier is deferred
   behind the same transporter-evidence licence that governs oligosaccharides.
5. **Promote the evidence-specificity rule to a named invariant** in
   `AGENTS.md` (§6). It is the rule the whole layer turns on and it was
   previously only implicit in the marker policy.

---

## 2. What the ontology already supports

Three things were proposed as prerequisites for this layer. All three were
already true, and checking them was most of the design work.

**Anchors are not restricted to small molecules.** `ARABINOXYLAN`, `XYLAN` and
`STARCH` are already anchors; `ARABINOXYLAN` carries no ChEBI ID at all and its
own description calls it "a substrate class rather than a single compound".
There is no restriction to lift. A generalised definition — *a biologically
meaningful molecular entity or molecular state used as a GIFT boundary* — is a
clarification of `architecture.md`, not a change to the model.

**A classification of anchor kind belongs in the facet layer, not in a column.**
`facet_term` / `anchor_facet` already register an open, build-validated
vocabulary, and `molecular_tier` already partitions anchors by size class. A
parallel `anchor_type` column would give two answers to one question — is
collagen a protein or a polymer? — and would require a migration to do it. The
protein layer instead extends the existing vocabulary (§7).

**`reaction` already holds non-Rhea chemistry.** Seven curated reactions carry
no `rhea_master` today, because §8.1 of the polysaccharide proposal made the
column nullable precisely for substrate-class chemistry. Collagenolysis is the
same shape as endoxylanase action on xylan: an activity defined against a
substrate class rather than a balanced equation. Verified 2026-08-18: Rhea
covers collagen hydroxylation, glycosylation and crosslinking, and contains no
proteolytic cleavage of the triple helix. The reaction therefore carries
`rhea_master = NULL` and an EC cross-reference, exactly the path §8.1 opened.

Renaming `reaction` to `functional_step` was considered and rejected. It would
touch roughly 400 references across the schema, the six chemistry source
tables, `evaluation.R`, `database-build.R`, `database-visualization.R`, four
exported functions, the `giftr_reaction_result` class and the
`missing_reactions` field users read, in exchange for no expressiveness the
layer does not already have. `AGENTS.md` forbids exactly this refactor.

---

## 3. The test

The test is the one §14 of the polysaccharide proposal applied to transporters,
restated for substrates:

```text
does a marker exist whose specificity matches the substrate named in the trait?
        |
        +-- yes --> curate the substrate-specific GIFT
        |
        +-- no  --> refuse it
                    a generic proteolysis marker licenses no substrate claim
```

The reason this bites harder for proteases than for carbohydrate-active enzymes
is structural, and worth stating before the results:

1. **There is no dbCAN-subfamily equivalent.** The CAZy layer works because
   subfamilies are activity-coherent. MEROPS families are not: S8 subtilisins
   and M4 thermolysins cleave keratin, albumin, casein and elastin
   indifferently.
2. **Substrate specificity in proteases is frequently not sequence-encoded.**
   "Keratinase" is a label applied to a subtilisin that was assayed on keratin.
   It is a phenotype of an enzyme, not a clade.
3. **The exception is mechanistic specificity.** Where an enzyme family is
   defined by an activity that generic proteases physically cannot perform, the
   family *is* the substrate claim. Native triple-helical collagen is the
   textbook case, and it is why exactly one candidate survives.

---

## 4. Outcome when the test was applied, 2026-08-18

| Trait | Marker candidate | Substrate-specific? | Outcome |
|---|---|---|---|
| Collagen cleavage | `KO K01387`, `PFAM PF01752` | yes, mechanistically | **curated** |
| Elastin cleavage | `KO K01399` (lasB, pseudolysin) | **no** — see below | refused |
| Keratin cleavage | none | **no** — no orthologue exists | refused |
| Albumin cleavage | none | — | refused |
| Actin cleavage | none | — | refused |
| Glutelin cleavage | none | — | refused |
| Tropomyosin cleavage | none | — | refused |
| Troponin cleavage | none | — | refused |

**Collagen passes on mechanism.** EC 3.4.24.3 is defined as "digestion of
native collagen in the triple helical region at Gly bonds" — an activity
generic endopeptidases do not have, because the intact triple helix is
resistant to them. KEGG assigns `K01387` (colA) to MEROPS family M9 and to
extracellular-matrix-damaging toxins, and keeps the host collagenases MMP-1
(`K01388`) and MMP-8 (`K01402`) as separate orthologues, so the marker is
microbial-only. Pfam `PF01752` is named Collagenase and described as "this
family of enzymes break down collagens". Marker and trait make the same claim.

**Elastin fails by marker, and instructively.** `K01399` exists and is named
elastase, which is what makes it tempting. But EC 3.4.24.26 defines pseudolysin
as "hydrolysis of proteins including elastin, collagen types III and IV,
fibronectin and immunoglobulin A", and places it in family M4 alongside
thermolysin, bacillolysin and aureolysin. Accepting it as evidence for elastin
cleavage would attribute an elastin-specific claim to a broadly proteolytic
enzyme — and worse, it would be *incoherent* with the collagen GIFT, because
the same evidence would equally license a collagen call. Any genome carrying
lasB would then be called collagenolytic without an M9 collagenase, which is
the specificity the collagen GIFT exists to assert. This is the protein-layer
form of the GH5 failure mode in §10 of the polysaccharide proposal, and the
first case where accepting a marker would have corrupted a *different* trait.

An honest trait for lasB would be broad host-protein degradation, whose
boundaries are the several substrates the EC record names. That is a real
capability and a defensible future GIFT. It is not elastin cleavage.

**Keratin fails for want of any orthologue.** KEGG returns no orthologue
matching keratinase. Keratinolysis is an assay result reported for S8 and M4
proteases, and the accessory disulfide-reducing activity that makes it possible
is generic. A two-step route requiring "keratinolytic protease AND disulfide
reduction" would be a route whose first step has no marker.

**The remaining five fail for the same reason, visible in a striking way.**
Searching KEGG for albumin, actin, tropomyosin and troponin returns the
*substrate proteins themselves* — `K16141` ALB, `K10373` TPM1, `K05865` TNNC1 —
host and eukaryotic structural genes, not microbial proteases that cleave them.
Glutelin returns nothing at all. There is no candidate marker to assess.

**One of eight.** The polysaccharide proposal predicted seven passing uptake
GIFTs and got two. This document's own earlier estimate was one to three. The
pattern is consistent enough to be treated as the expected outcome of the test
rather than a disappointment: substrate-specific naming is much commoner in the
literature than substrate-specific evidence.

---

## 5. Why the product anchor is `COLLAGEN PEPTIDES` and not `PEPTIDES`

A shared `PEPTIDES` anchor consumed by a generic peptide-degradation GIFT is
the obvious design and is rejected for three reasons.

**It would hub the composition graph.** `gift_graph` joins GIFTs on shared
anchors. Every substrate-specific cleavage GIFT outputting `PEPTIDES`, and one
or more peptidase GIFTs consuming it, produces a complete bipartite blob in
which every protein degrader is graph-adjacent to every other one's downstream.
`gift_profile.network_position` and `cross_feeding_output` are computed from
that graph and would return noise for the whole layer.

**A generic downstream GIFT fails the granularity rule.** §5 rule 2 requires
independent variation: genomes must exist with the capability and without its
neighbour. Essentially every genome encodes generic peptidases, so
`PEPTIDES > AMINO ACIDS` would be true of nearly every genome and carry
correspondingly little information. Rule 3, interpretive consequence, fails with
it.

**A pool is not a boundary.** `XYLAN` is a substrate class with a defined
linkage; a bare peptide pool has no membership criterion, so the question the
anchor layer exists to answer — does this GIFT's output equal that GIFT's input
— has no answer.

`COLLAGEN PEPTIDES` is deliberately substrate-specific and deliberately
terminal. The GIFT reports `network_position = isolated`, which is honest: the
cleavage product's fate is not modelled. This mirrors the treatment of
oligosaccharides, which are internal intermediates until an importer can be
evidenced. A shared extracellular oligopeptide tier is **deferred on the same
licence**: peptide ABC importers (Opp, Dpp, Tpp) are well characterised and
KO-annotated, so unlike the oligosaccharide case this test may well be passed.
It should be taken as its own decision, with the uptake GIFT curated first, and
not smuggled in with a protease.

Nothing here depends on that answer.

---

## 6. The evidence-specificity invariant

> The specificity of a GIFT must not exceed the specificity supported by its
> genomic evidence.

This was already implicit — it is what §10 rule 1 of the polysaccharide
proposal enforces for CAZy families, and what §14 applied to transporters — but
it was stated as marker policy rather than as an invariant, and marker policy
reads as advice about confidence values. It is not. It is a constraint on what a
GIFT may be called. Promoted to invariant 16 of `AGENTS.md`.

Two corollaries the protein layer makes concrete:

- A generic proteolytic marker licenses a generic proteolysis trait, never a
  substrate-specific one. Peptide-bond hydrolysis is not evidence of collagen,
  keratin or albumin cleavage.
- Accepting an over-broad marker damages **other** traits, not only the one it
  is accepted for, because it silently equates them. The lasB case in §4 is the
  worked example.

---

## 7. Vocabulary added

Four new facet terms and two broadened definitions. No column, no table, no
migration.

| Facet | Value | Target | Why |
|---|---|---|---|
| `substrate_class` | `protein` | gift | The layer's partition value. |
| `physiological_role` | `host_tissue_degradation` | gift | Parallels `host_glycan_foraging`; the role is colonisation and tissue damage, not carbon acquisition. |
| `molecular_tier` | `peptide` | anchor | The product tier, absent from a glycan-only vocabulary. |
| `resource_origin` | `animal_derived` | anchor | The vocabulary had `plant_derived` and no counterpart; dietary collagen is a real and probably dominant source in a gut community. |

`molecular_tier.polymer` and `resource_origin.host_derived` were both worded for
glycans and are broadened to cover proteins. Neither reclassifies an existing
anchor.

**`gift.mode` needed no new value.** Extracellular collagenolysis for tissue
invasion is not catabolism in the physiological sense, which initially looked
like a gap in the four-value enum. It is not: the schema comment is explicit
that `mode` is the *direction* of a capability, used for the mode-aware
acyclicity check. Collagen to peptides is a degradative direction. The
physiological claim belongs to `physiological_role`, which is exactly where
`host_tissue_degradation` goes. A fifth mode would have fragmented the cycle
check to record something the facet layer records better.

---

## 8. The curated GIFT

```text
collagen_cleavage : COLLAGEN(ex) -> COLLAGEN PEPTIDES(ex)      mode catabolic

route COLLAGEN_M9   (oxygen independent)
  required  RXN_COLLAGEN_HELIX_CLEAVAGE   rhea_master NULL, xref EC 3.4.24.3
    system  SYS_COLLAGENASE_M9            single-protein hydrolase
      component COMP_COLLAGENASE_M9
        marker  KO K01387      orthology       curated
        marker  PFAM PF01752   sequence_family high-confidence
```

**One required reaction is correct here.** §2 of the polysaccharide proposal
warns against making a GIFT equivalent to a reaction, but its complaint was that
a single endoglucanase is a *fragment* of xylan saccharification. Collagenolysis
is not a fragment of anything — the M9 activity is the whole capability, and
"can this genome cleave native collagen" is answered completely by it. The
existing `arabinoxylan_debranching` is the precedent, and its curator note says
so: "One reaction, but a complete capability with its own product."

**One enzyme system, not two.** Following the correction recorded at §6.1 of the
polysaccharide proposal: an annotation pipeline cannot tell whether a Pfam hit
and a KO hit describe the same protein, and they usually do. Modelling them as
alternative systems would imply two enzymes where there is one. They are
alternative markers for one component.

**EC 3.4.24.3 is deliberately not a marker.** Marker policy rule 3 says an EC
alone is never sufficient evidence for a required reaction. This GIFT has
exactly one required reaction, so admitting an EC marker would let it carry the
entire call by itself. It stays as the reaction cross-reference, where it
establishes reaction identity without licensing a call. The cost is a false
negative for genomes annotated only to EC level; that is the conservative
direction, and it is recorded here rather than silently accepted.

**MEROPS is not used as a namespace.** Family M9 is the right concept, but
MEROPS is not part of the default output of the annotation pipelines giftr
targets, and its redistribution terms would need checking before a derived
table could be shipped. `PF01752` covers the same clade and is standard
pipeline output. Should MEROPS become available, adding it is a marker-layer
change requiring no schema work — the namespace vocabulary is open.

---

## 9. What was rejected and why

| Proposed | Decision | Reason |
|---|---|---|
| `anchor_type` column | rejected | Duplicates `molecular_tier`; needs a migration to answer a question the facet layer already answers (§2). |
| `reaction` → `functional_step` rename | rejected | ~400 references and four exported functions for no expressiveness the layer lacks (§2). |
| `step_type` column | rejected | `rhea_reaction` versus the rest is derivable from `rhea_master IS NOT NULL`. |
| Generic `PEPTIDES` anchor | rejected | Hubs the graph; a pool is not a boundary (§5). |
| `PEPTIDES > AMINO ACIDS` GIFT | rejected | True of nearly every genome; fails granularity rules 2 and 3 (§5). |
| GIFT ontology / specialization relation | deferred | Would be the first non-anchor edge between GIFTs, amending invariant 2, and needs inference semantics — transitivity, evidence inheritance — that nothing yet requires. `gifts_by_facet("substrate_class", "protein")` answers the rollup question at no cost. |
| Fifth `gift.mode` value | rejected | `mode` is a direction field for the cycle check; the physiological claim is a facet (§7). |

---

## 10. Deferred

**Broad host-protein degradation.** The honest trait for lasB and the M4
elastases: a GIFT whose boundaries are the several host substrates the EC record
names, rather than one of them. Worth curating; needs its own boundary decision,
because "host protein" as an anchor has the same pool problem as "peptides".

**Extracellular oligopeptide tier and peptide uptake** (§5). Licensed by
transporter evidence, curated uptake-first, decided separately.

**A peptide branch in `gift_profile.substrate_tier`.** The view maps
`molecular_tier` to a tier name and has no branch for `peptide`, so a peptide
anchor would report `small_molecule`. This is latent and not wrong today,
because no GIFT takes a peptide as input and the tier is computed from input
anchors only. The branch should ship with the first peptide-consuming GIFT
rather than as a view migration on its own.

**Keratin, if evidence appears.** A substrate-specific HMM for keratinolytic
subtilisins, or a MEROPS subfamily that tracks the phenotype, would reopen it.
The route shape proposed — accessory disulfide reduction AND keratinolytic
protease — is the right shape; it has no marker for its first step today.

No open questions remain.
