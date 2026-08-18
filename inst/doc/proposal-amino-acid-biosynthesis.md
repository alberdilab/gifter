# Curation proposal: serine, threonine, cysteine and methionine GIFTs

Status: **implemented in database release 2026.09.1.** Prepared 2026-08-17
against database version 2026.08.3 (schema 2); accepted and built the same day.

This document is kept as the reasoning record behind the boundary decisions.
The decisions themselves, with their evidence and effect on calls, are in
`database_changes.tsv` and readable with `database_changelog()`.

What changed between the proposal and the implementation:

- **Glycine biosynthesis was added** as a ninth GIFT, `SERINE > GLYCINE` via
  serine hydroxymethyltransferase (RHEA:15481, reverse). Threonine aldolase was
  excluded for the reason given in section 7.
- **K01739 is not accepted for RHEA:27826.** KEGG annotates MetB to the
  sulfide-dependent reaction R01288, and the proposal's route table repeated
  that. Accepting it makes every transsulfuration genome positive for direct
  sulfhydrylation, which destroys the distinction the two methionine GIFTs
  exist to draw. Only the dedicated sulfhydrylases are accepted.
- **Both homoserine dehydrogenase routes were kept** (open question 3).
- **All other open questions in section 8 were resolved as recommended.**
- **A pathway-linking layer was added** beyond this proposal's scope: schema
  version 3 adds `gift_xref`, so every GIFT records how its curated boundaries
  compare with the external pathway records it derives from.

Scope: evaluate the incorporation of KEGG modules M00020, M00018, M00021,
M00338, M00609 and M00017 as giftr GIFTs, and decide where the boundaries
should actually fall.

---

## 1. Recommendation in one page

Six KEGG modules become **eight GIFTs**, not six. Three module boundaries are
kept, three are cut, one module is split in two, two modules are merged, and one
module loses two thirds of its steps.

| # | Proposed GIFT | Input anchors | Output anchor | Derived from |
|---|---|---|---|---|
| 1 | `serine_biosynthesis` | 3-phospho-D-glycerate | L-serine | M00020 (boundaries kept) |
| 2 | `aspartate_semialdehyde_biosynthesis` | L-aspartate | L-aspartate 4-semialdehyde | head of M00018 + M00017 |
| 3 | `homoserine_biosynthesis` | L-aspartate 4-semialdehyde | L-homoserine | shared step of M00018 + M00017 |
| 4 | `threonine_biosynthesis` | L-homoserine | L-threonine | tail of M00018 |
| 5 | `methionine_biosynthesis_transsulfuration` | L-homoserine, L-cysteine | L-methionine | tail of M00017 |
| 6 | `methionine_biosynthesis_sulfhydrylation` | L-homoserine, hydrogen sulfide | L-methionine | **absent from M00017** |
| 7 | `cysteine_biosynthesis_sulfide` | L-serine, hydrogen sulfide | L-cysteine | M00021 (boundaries kept) |
| 8 | `cysteine_biosynthesis_homocysteine` | L-serine, L-homocysteine | L-cysteine | M00338 **merged with** the tail of M00609 |

Resulting composition graph (all edges derived from declared anchors):

```text
                3-phospho-D-glycerate
                          |
                 [1] serine_biosynthesis
                          |
                      L-serine
                       /      \
        hydrogen sulfide       L-homocysteine
              |                       |
   [7] cysteine_biosynthesis   [8] cysteine_biosynthesis
       _sulfide                    _homocysteine
              \                       /
                     L-cysteine
                          |
   L-aspartate            |
        |                 |
[2] aspartate_semialdehyde_biosynthesis
        |
 L-aspartate 4-semialdehyde
        |
[3] homoserine_biosynthesis
        |
   L-homoserine
    /         \
[4] threonine  [5] methionine ..._transsulfuration  <-- consumes L-cysteine
    |          [6] methionine ..._sulfhydrylation   <-- consumes hydrogen sulfide
L-threonine              |
                    L-methionine
```

Costs: 10 new anchors, 8 GIFTs, 18 routes, 24 new reactions, ~28 enzyme systems,
36 new markers. This roughly triples the current database.

---

## 2. Three structural problems with using the modules as drawn

### 2.1 M00018 and M00017 duplicate the aspartate trunk

Both modules start at L-aspartate and both contain aspartate kinase,
aspartate-semialdehyde dehydrogenase and homoserine dehydrogenase. Importing
them as two GIFTs would encode the same three reactions twice, in violation of
invariant 8.

Evidence: 6569 KEGG organisms satisfy the orthology of both modules, so the
duplication would be exercised in the majority of genomes carrying either.

The trunk must be cut. **L-homoserine** is the obvious cut point: it is the
branchpoint where carbon commits to threonine or to methionine, and both KEGG
modules name it in their own titles (`aspartate => homoserine => threonine`,
`aspartate => homoserine => methionine`).

I additionally propose cutting at **L-aspartate 4-semialdehyde**. ASA is the
branchpoint to lysine and diaminopimelate (M00016, M00525-M00527), which is
almost certainly the next amino acid family to be curated. Cutting now avoids
re-cutting `aspartate → homoserine` later and re-versioning every GIFT that
depends on it. The cost is that GIFT 3 contains a single reaction. That is
acceptable: `cytidylate_biosynthesis` is already a one-reaction GIFT, and
homoserine dehydrogenase is precisely the step that establishes
threonine/methionine identity against the lysine branch.

If you prefer to defer, the conservative alternative is a single
`homoserine_biosynthesis` GIFT spanning L-aspartate to L-homoserine, split later.
I recommend against it only because the later split is a breaking change.

### 2.2 M00017 omits the dominant methionine sulfur route

M00017 models only transsulfuration: acyl-homoserine plus **L-cysteine** to
cystathionine (K01739), then cystathionine beta-lyase (K01760/K14155), then
methionine synthase. It contains no direct sulfhydrylation, in which
O-acetyl- or O-succinyl-homoserine reacts with **inorganic sulfide** to give
homocysteine in one step (`metY` K01740, `metZ` K10764, `MET17` K17069).

Evidence over KEGG organisms carrying the complete aspartate-to-homoserine trunk
plus a homoserine acyltransferase:

| Sulfur route available | Organisms |
|---|---|
| Direct sulfhydrylation only | 4096 |
| Transsulfuration only | 985 |
| Both | 2353 |

3910 organisms complete methionine biosynthesis by sulfhydrylation and would be
called **incomplete** by M00017 as written. Following the module here would be a
worse claim than giftr is capable of making.

These are not merely alternative enzymes for one reaction. They have different
nutritional meaning: one consumes cysteine, the other consumes inorganic
sulfide. Because `gift_anchors` declares inputs per GIFT and not per route, a
single `homoserine → methionine` GIFT declaring both L-cysteine and hydrogen
sulfide as inputs would over-claim the requirements of both routes. Hence GIFTs
5 and 6, split by sulfur source. They share the acylation and methionine
synthase chemistry, which is reaction reuse across siblings, not GIFT
duplication.

### 2.3 M00609 is mostly not cysteine biosynthesis

M00609 is defined as a six-step AND chain:

```text
K00789 (metK)  K17462 (yrrT)  K01243 (mtnN)  K07173 (luxS)  K17216 (mccA)  K17217 (mccB)
```

Only the last two steps form cysteine. The first four are the activated methyl
cycle: SAM synthesis, an unspecified SAM-dependent methylation, SAH hydrolysis
and homocysteine release. Three objections:

1. **K17462 is a placeholder.** It is annotated `putative AdoMet-dependent
   methyltransferase [EC:2.1.1.-]`, its reaction R10404 has no Rhea master and
   no name. The SAM-to-SAH conversion it represents is performed by hundreds of
   unrelated methyltransferases in every genome that makes SAM. Requiring this
   specific KO is a pathway-drawing convention, exactly like the K00610 case
   retired in `DBC-20260817-ATCASE-PYRI`. Of 489 organisms carrying both mccA
   and mccB, only 332 carry K17462; **157 are called incomplete for a step that
   is not evidence of anything.**
2. **The methyl cycle is a different capability.** Methionine → homocysteine is
   methionine recycling. Bundling it into cysteine biosynthesis violates
   invariant 9 (do not bundle independently meaningful capabilities).
3. **Modelling it as a GIFT would make the composition graph cyclic** (see
   section 4), which the source validator rejects as a build error.

Proposal: drop the first four steps. The mccA/mccB pair becomes a second route
of GIFT 8. If methionine recycling is wanted later, curate it deliberately as
its own GIFT and resolve the cycle at that time.

---

## 3. M00338 and M00609 are one capability, not two

Both modules produce L-cysteine from L-homocysteine plus a serine-derived
acceptor, and both finish with cystathionine gamma-lyase acting on
L,L-cystathionine (KEGG R01001, RHEA:14005). They differ only in how
cystathionine is formed:

| | M00338 | M00609 tail |
|---|---|---|
| Acceptor | L-serine | O-acetyl-L-serine |
| Enzyme | cystathionine beta-synthase K01697/K10150 | mccA K17216 |
| Reaction | R01290 / RHEA:10112 | R10305 / RHEA:32743 |
| gamma-lyase | K01758 | K17217 |

**Zero of the 2592 organisms with K01697+K01758 also carry K17216+K17217.** The
two enzyme sets are taxonomically disjoint solutions to the same problem, which
is the textbook definition of alternative routes within one GIFT rather than two
GIFTs. Merging them means a Firmicute and a mammal both return one positive
`cysteine_biosynthesis_homocysteine` call with different supporting routes,
instead of two unrelated traits that a user has to know to OR together.

Note that the O-acetyl-L-serine route additionally requires serine
O-acetyltransferase (cysE, RHEA:24560), which M00609 does not list because
KEGG's diagram enters at O-acetyl-L-serine. Adding it keeps the route's input
anchor honestly at L-serine. 486 of the 489 mccA/mccB organisms carry cysE, so
this costs almost nothing in sensitivity.

O-acetyl-L-serine is therefore an internal intermediate shared by GIFTs 7 and 8.
It should **not** become an anchor: per invariant 2 that shared participant
creates no edge, and per invariant 3 the anchor vocabulary stays small.

---

## 4. The sulfur cycle, and why the boundaries must be asymmetric

This is the sharpest constraint on the design. `.find_graph_cycle()` in
`R/database-build.R` turns every output-anchor/input-anchor match into a
directed edge and rejects any cycle as a build error. Three natural-looking
boundary choices are mutually incompatible:

```text
A  homoserine + L-cysteine  -> L-methionine        (transsulfuration)
B  L-homocysteine + serine  -> L-cysteine          (reverse transsulfuration)
C  L-methionine             -> L-homocysteine      (M00609 head)

A -> C via METHIONINE, C -> B via HOMOCYSTEINE, B -> A via CYSTEINE.  Cycle.
```

Dropping C is necessary but not sufficient. If L-homocysteine is also promoted
to an **output** anchor — for example by splitting methionine biosynthesis at
homocysteine into `homoserine → homocysteine` and `homocysteine → methionine` —
then that GIFT outputs HOMOCYSTEINE into B, and B outputs CYSTEINE back into it.
Cycle again, with only two GIFTs.

Resolution adopted in this proposal:

- **L-homocysteine is declared only as an input anchor** (of GIFT 8) and never as
  an output. It remains an internal intermediate of GIFTs 5 and 6.
- **Methionine biosynthesis is not split at homocysteine.**
- **No methionine → homocysteine GIFT is curated in this batch.**

This is biologically defensible rather than merely convenient: in the organisms
that use the mcc route, the homocysteine consumed by cysteine biosynthesis comes
from methionine salvage and the SAM cycle, not from de novo methionine
biosynthesis. Declaring it as a dangling input, like PRPP, states exactly that.

It must be recorded, because the constraint is invisible from any single table:
**promoting L-homocysteine to an output anchor, or adding a methionine →
homocysteine GIFT, will make the database fail to build.** That belongs in a
`database_changes.tsv` entry and in `SOURCES.md`.

---

## 5. Anchor decisions

Ten new anchors. Each is defended below; anything not listed was deliberately
rejected.

| anchor_id | name | ChEBI | Why it is a boundary |
|---|---|---|---|
| `PG3` | (2R)-3-phosphoglycerate | CHEBI:58272 | Glycolytic intermediate; the junction where carbon leaves central metabolism for serine. |
| `SERINE` | L-serine | CHEBI:33384 | Stable product and the precursor of both cysteine GIFTs and of glycine. |
| `CYSTEINE` | L-cysteine | CHEBI:35235 | Stable product; also the sulfur donor input of transsulfuration. |
| `SULFIDE` | hydrogen sulfide | CHEBI:29919 | Environmental/assimilatory sulfur input; the boundary that will connect to assimilatory sulfate reduction (M00176). |
| `ASPARTATE` | L-aspartate | CHEBI:29991 | Central amino acid entering the aspartate family. |
| `ASA` | L-aspartate 4-semialdehyde | CHEBI:537519 | Branchpoint to lysine/diaminopimelate. |
| `HOMOSERINE` | L-homoserine | CHEBI:57476 | Branchpoint to threonine and methionine; named in both module titles. |
| `THREONINE` | L-threonine | CHEBI:57926 | Stable product. |
| `METHIONINE` | L-methionine | CHEBI:57844 | Stable product. |
| `HOMOCYSTEINE` | L-homocysteine | CHEBI:58199 | Input-only sulfur donor from methionine salvage (section 4). |

Rejected anchor candidates:

- **O-acetyl-L-serine** — internal to GIFTs 7 and 8 (section 3).
- **O-succinyl- / O-acetyl-L-homoserine** — internal branchpoint between
  transsulfuration and sulfhydrylation, but both branches are already separated
  at the GIFT level; promoting it would add an anchor without adding a callable
  capability.
- **L,L-cystathionine** — transient intermediate; appears in GIFTs 5, 6 and 8 but
  is never a meaningful endpoint.
- **O-phospho-L-serine, O-phospho-L-homoserine, 3-phosphooxypyruvate** — transient
  phosphorylated intermediates.
- **Glycine** — a genuine anchor, but only once a glycine GIFT exists
  (see section 7).

Anchor `SULFIDE` deserves comment. Declaring it makes explicit that GIFTs 6 and 7
require assimilable inorganic sulfur, which is real biology and the reason these
capabilities fail in sulfur-limited hosts. It creates no cycle because nothing in
this batch outputs sulfide.

---

## 6. Per-GIFT specification

Reaction orientation below is stated relative to the Rhea **master** equation, as
required by `route_reactions.orientation`. All Rhea masters, KEGG cross-references
and equations were verified against the Rhea `rhea2kegg_reaction` mapping and the
Rhea REST equations on 2026-08-17.

### GIFT 1 — `serine_biosynthesis` (PG3 → SERINE)

One route, `SER_PHOSPHORYLATED`:

| Step | Rhea | Orientation | KEGG | Enzyme | Markers |
|---|---|---|---|---|---|
| 1 | RHEA:12641 | forward | R01513 | 3-phosphoglycerate dehydrogenase | K00058 |
| 2 | RHEA:14329 | **reverse** | R04173 | phosphoserine aminotransferase | K00831 |
| 3 | RHEA:21208 | forward | R00582 | phosphoserine phosphatase | K01079, K02203, K22305, K25528 |

Step 2 is reverse: the Rhea master runs phosphoserine to 3-phosphooxypyruvate.

Critical note on step 3: 1622 of 8379 organisms carrying serA+serC carry **no**
recognised phosphoserine phosphatase KO. This is a well-known annotation gap
(promiscuous HAD-family phosphatases), not a real absence of the capability in
all 1622. I recommend **keeping the phosphatase required** rather than making it
optional: the chemistry is required, and giftr's value over KEGG here is
precisely that it reports the closest route and names RHEA:21208 as the missing
reaction, instead of silently scoring 2/3. This should be stated in the GIFT
`notes` so it is not later "fixed" by dropping the step.

K02203 (`thrH`) is bifunctional phosphoserine phosphatase / homoserine kinase and
also appears in GIFT 4. Multifunctional markers across GIFTs are already handled
(compare K11787).

### GIFT 2 — `aspartate_semialdehyde_biosynthesis` (ASPARTATE → ASA)

One route, `ASA_CANONICAL`:

| Step | Rhea | Orientation | KEGG | Enzyme | Markers |
|---|---|---|---|---|---|
| 1 | RHEA:23776 | forward | R00480 | aspartate kinase | K00928, K12524, K12525, K12526 |
| 2 | RHEA:24284 | **reverse** | R02291 | aspartate-semialdehyde dehydrogenase | K00133 |

K12526 (`lysAC`, bifunctional diaminopimelate decarboxylase / aspartate kinase)
carries EC 2.7.2.4 and is listed by M00018 but **not** by M00017. That
inconsistency is a KEGG artefact; accept it for the reaction in both cases.

### GIFT 3 — `homoserine_biosynthesis` (ASA → HOMOSERINE)

Two routes, differing in cofactor, both **reverse** relative to their masters:

| Route | Rhea | KEGG | Enzyme | Markers |
|---|---|---|---|---|
| `HSER_NAD` | RHEA:15757 | R01773 | homoserine dehydrogenase (NAD) | K00003, K12524, K12525 |
| `HSER_NADP` | RHEA:15761 | R01775 | homoserine dehydrogenase (NADP) | K00003, K12524, K12525 |

The two routes are chemically distinct reactions with the same markers, so they
change no call today. They are worth curating separately because the cofactor
preference is real and route-level reporting will show which chemistry is
claimed. If you consider this noise, collapse to `HSER_NAD` only and record the
decision.

### GIFT 4 — `threonine_biosynthesis` (HOMOSERINE → THREONINE)

One route, `THR_CANONICAL`:

| Step | Rhea | Orientation | KEGG | Enzyme | Markers |
|---|---|---|---|---|---|
| 1 | RHEA:13985 | forward | R01771 | homoserine kinase | K00872, K02204, K02203 |
| 2 | RHEA:10840 | forward | R01466 | threonine synthase | K01733 |

### GIFT 5 — `methionine_biosynthesis_transsulfuration` (HOMOSERINE + CYSTEINE → METHIONINE)

Three acylation/condensation variants x two methionine synthases = six routes.

Acylation and cystathionine formation:

| Variant | Acylation | Cystathionine formation |
|---|---|---|
| succinyl | RHEA:22008 (R01777), K00651/K00641 | RHEA:20397 (R03260), K01739 |
| acetyl | RHEA:13701 (R01776), K00641/K00651 | RHEA:30931 (R03217), K01739 |
| phospho (plant) | RHEA:13985 (R01771), K00872 | RHEA:80891 (R13363), K27857 |

Then, common to all three:

| Step | Rhea | KEGG | Enzyme | Markers |
|---|---|---|---|---|
| cystathionine beta-lyase | RHEA:13965 | R01286 | cystathionine beta-lyase | K01760, K14155 |
| methionine synthase (a) | RHEA:11172 | R00946 | B12-dependent | K00548, K24042 |
| methionine synthase (b) | RHEA:21196 | R04405 | B12-independent | K00549 |

The two methionine synthases use different methyl donors and are different Rhea
reactions, so they must be separate routes rather than alternative systems —
the same treatment already applied to folate- and formate-dependent purine
formylation.

Acyl specificity caveat: KEGG lists K00651 (`metA`) and K00641 (`metX`) as
interchangeable and assigns both to R01776 **and** R01777. At KO resolution the
succinyl/acetyl distinction is not reliably recoverable. I propose accepting both
markers for both acylation reactions and recording that in `component_markers.notes`,
rather than asserting a specificity the evidence layer cannot support.

### GIFT 6 — `methionine_biosynthesis_sulfhydrylation` (HOMOSERINE + SULFIDE → METHIONINE)

Two acylation variants x two methionine synthases = four routes.

| Variant | Acylation | Sulfhydrylation |
|---|---|---|
| succinyl | RHEA:22008 (R01777) | RHEA:27826 (R01288), K10764 (`metZ`), K01739 (`metB`) |
| acetyl | RHEA:13701 (R01776) | RHEA:27822 (R01287), K01740 (`metY`), K17069 (`MET17`) |

Then methionine synthase (a) or (b) as in GIFT 5.

This GIFT exists in no KEGG module and is the main biological addition of this
proposal. Its provenance must be recorded as giftr curation, not KEGG import.

### GIFT 7 — `cysteine_biosynthesis_sulfide` (SERINE + SULFIDE → CYSTEINE)

One route, `CYS_OAS_SULFIDE` (M00021 unchanged):

| Step | Rhea | Orientation | KEGG | Enzyme | Markers |
|---|---|---|---|---|---|
| 1 | RHEA:24560 | forward | R00586 | serine O-acetyltransferase | K00640, K23304 |
| 2 | RHEA:14829 | forward | R00897 | cysteine synthase | K01738, K13034, K17069 |

M00021's boundaries survive unchanged; the only addition is declaring the
sulfide input explicitly.

### GIFT 8 — `cysteine_biosynthesis_homocysteine` (SERINE + HOMOCYSTEINE → CYSTEINE)

Two routes (section 3):

`CYS_RT_SERINE` (from M00338):

| Step | Rhea | KEGG | Enzyme | Markers |
|---|---|---|---|---|
| 1 | RHEA:10112 | R01290 | cystathionine beta-synthase | K01697, K10150 |
| 2 | RHEA:14005 | R01001 | cystathionine gamma-lyase | K01758, K17217 |

`CYS_RT_OAS` (from the tail of M00609):

| Step | Rhea | KEGG | Enzyme | Markers |
|---|---|---|---|---|
| 1 | RHEA:24560 | R00586 | serine O-acetyltransferase | K00640, K23304 |
| 2 | RHEA:32743 | R10305 | cystathionine beta-synthase (O-acetyl-L-serine) | K17216 |
| 3 | RHEA:14005 | R01001 | cystathionine gamma-lyase | K17217, K01758 |

RHEA:14005 is shared by both routes; RHEA:24560 is shared with GIFT 7. Both are
reaction reuse, which the schema already supports.

---

## 7. Deliberate exclusions

Recorded so they are not re-proposed:

- **Glycine ↔ serine (`glyA`, K00600, RHEA:15481).** A separate capability with a
  different input anchor. Serine hydroxymethyltransferase runs mainly in the
  serine → glycine direction in biosynthesis. Curate as its own GIFT
  (`SERINE → GLYCINE`) when glycine is needed; do not add it as a route of GIFT 1.
- **Non-phosphorylated serine pathway** (glycerate → hydroxypyruvate → serine).
  Real in some organisms but with weak and ambiguous KO support; excluded until
  the evidence layer can distinguish it.
- **O-phospho-L-serine sulfhydrylase (K10150, RHEA:10252).** Would bypass the
  phosphatase step and enter cysteine biosynthesis from an intermediate internal
  to GIFT 1. Modelling it needs O-phospho-L-serine promoted to an anchor;
  deferred.
- **Methionine → homocysteine / SAM cycle** (M00609 steps 1-4). Section 4.
- **Methionine gamma-lyase (K01761)** and other methionine catabolism. Degradation,
  not biosynthesis.
- **Betaine-homocysteine methyltransferase (K00547).** Methionine from
  homocysteine using a betaine methyl donor; a real alternative to metE/metH but
  with a different one-carbon input. Candidate for a later route once methyl
  donor anchoring is decided.
- **Threonine → glycine, threonine catabolism, lysine/DAP branch from ASA.**
  Out of scope; ASA is anchored so the lysine branch can attach cleanly.

---

## 8. Open questions for the curator

1. **Split the trunk at ASA, or defer?** (section 2.1) Recommendation: split now.
2. **Split methionine by sulfur source, or one GIFT with a homoserine-only input?**
   (section 2.2) Recommendation: split; the nutritional difference is the point.
3. **Two homoserine dehydrogenase routes, or one?** (GIFT 3) No effect on calls
   today.
4. **Keep phosphoserine phosphatase required?** (GIFT 1) Recommendation: yes.
5. **Naming.** `cysteine_biosynthesis_sulfide` / `_homocysteine` and
   `methionine_biosynthesis_transsulfuration` / `_sulfhydrylation` name the
   *sulfur source*, which is the discriminating biology. Existing GIFT IDs are
   product-named (`adenylate_biosynthesis`), so this introduces a second naming
   convention that should be adopted deliberately.

---

## 9. Implementation impact if accepted

- `anchors.tsv` +10, `gifts.tsv` +8, `gift_anchors.tsv` +20, `gift_routes.tsv` +18,
  `reactions.tsv` +24, `route_reactions.tsv` +52, `reaction_xrefs.tsv` +48,
  `enzyme_systems.tsv` ~+28, `enzyme_components.tsv` ~+28,
  `markers.tsv` +36, `component_markers.tsv` ~+55.
- No schema change; no code change. Version bump of `giftr_db_version` only.
- New tests required: the acyclicity constraint of section 4; composition
  `PG3 → SERINE → CYSTEINE → METHIONINE`; alternative-route OR across
  `CYS_RT_SERINE` / `CYS_RT_OAS`; alternative-route OR across the sulfhydrylation
  and transsulfuration methionine GIFTs; absence of an implicit edge through
  O-acetyl-L-serine and L,L-cystathionine.
- `database_changes.tsv` entries needed for: the batch addition, the M00609
  reduction (`call_effect: broadens`), the M00338/M00609 merge, the M00017
  sulfhydrylation extension (`broadens`), and the homocysteine
  output-anchor prohibition (`clarification`).
- `SOURCES.md` must distinguish KEGG-imported orthology from giftr's boundary
  decisions, which here are substantial.

## 10. Evidence sources

KEGG REST (`rest.kegg.jp`, retrieved 2026-08-17): module definitions M00017,
M00018, M00020, M00021, M00338, M00609; KO entries and their reaction
assignments; gene-to-organism links used for every count in this document.
Rhea (`rhea2kegg_reaction.tsv`, Rhea REST equations, release 141): reaction
identity, direction and ChEBI participants. ChEBI release 253 via Rhea
participant identifiers.
