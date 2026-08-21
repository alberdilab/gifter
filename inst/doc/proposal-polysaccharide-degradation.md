# Curation proposal: complex polysaccharide and sugar degradation GIFTs

Status: **steps 1-6 implemented; step 7 in progress — three of ten substrates
curated.**
Prepared 2026-08-17 against database version 2026.09.1 (schema 3).

Steps 1 and 2 of §13 shipped the same day as database 2026.09.2, schema 4:
reaction identity (§8.1), anchor compartment with the `molecule` key (§8.2),
`gift.mode` with the mode-aware cycle check (§8.3), confidence propagation
(§8.4), CAZy namespace inference (§8.5), the scope amendment (§8.6), and
compartment-inexact graph edges (§8.7). See `CHANGELOG.md` for the code record
and `database_changes.tsv` for the three schema entries.

Step 3 shipped on 2026-08-18 as database 2026.09.3: the nine sugar degradation
GIFTs of §7, with every accession verified against KEGG and Rhea. Two candidates
in this document did not survive that verification and are corrected in §7.

Step 4 shipped on 2026-08-18 as database 2026.09.4. Applying the §14 test to
real evidence licensed **two** substrates, not the seven this document
predicted; the assessment is corrected in §14 below.

Step 5 shipped on 2026-08-18 as database 2026.10.1: the arabinoxylan and starch
tiers of §6.2 and §6.3, with CAZy evidence taken from the pinned dbCAN mapping.
Two things changed at implementation and are corrected below — none of the six
polymer EC numbers has a Rhea master (§8.1 was load-bearing, not precautionary),
and the per-family enzyme systems suggested in §6.1 were collapsed to one system
per reaction (§6.1).

Step 6, the marker-confidence checkpoint, was carried out on 2026-08-21 and is
recorded in §16. It licensed continuing, but only after two corrections: an
agreement floor on dbCAN-sub markers, and making confidence reach the metrics
layer that had been discarding it.

Step 7 is **in progress**. Chitin and mucin O-glycan shipped on 2026-08-21 as
database 2026.21.1, and the hydrolytic half of pectin as 2026.21.2 the same day;
the other seven substrates remain outstanding, and every CAZy family, EC number
and KO named for them is still a candidate. Two candidates named in §6.3 for
mucin did not survive verification and are corrected in §16.3; the pectate lyase
route is assessed and deferred in §16.5. The dbCAN family-to-substrate mapping
that supplies the evidence is pinned in `data-raw/reference/`. No open questions
remain; two items are deferred (§15, §16.5).

Scope: decide how complex polysaccharide degradation and sugar degradation
should be expressed under the gifter ontology, and identify what must
change in the schema and code before they can be curated honestly.

All open questions were resolved on 2026-08-17. The answers are recorded in
section 12 and worked into the design below: compartment is part of the model,
with no default and a transporter-evidence licence (§4); the legacy database is
not an evidence source (§3); an explicit granularity rule constrains atomisation
(§5); acetate and ferulate were assessed and settled (§9); genomic-context
evidence is ruled out because gifter operates on chunked MAGs (§4.6);
monosaccharide uptake breadth was assessed (§14); compartment-inexact graph
edges are traversed and flagged (§8.7); and substrate-level reporting stays in
the reporting layer (§12.5).

Accessions in this document were **candidates**, recorded so the design could be
judged concretely. Those in §7 have since been verified and curated; everything
named for steps 4 to 7 remains a candidate and must be verified against the
resource it names before it is recorded.

---

## 1. Recommendation in one page

Curate on **three anchor tiers plus an explicit transport step**, one GIFT per
chemically real transformation between adjacent tiers:

```text
POLYMER (extracellular by definition)
   |  one GIFT per substrate capability: endo + exo chemistry together,
   |  accessory de-blocking at required = 0
MONOSACCHARIDE(out)
   |  ==== UPTAKE GIFT, where transporter evidence licenses it ====
MONOSACCHARIDE(in)
   |  sugar degradation
CENTRAL ENTRY (cytoplasmic by definition)

Oligosaccharides are internal intermediates, not anchors. They would be
promoted to anchors only if an oligosaccharide importer could be evidenced,
which is what would make selfish foraging independently meaningful.
```

Four consequences make this the right shape:

1. **Composition does the work.** "This MAG degrades arabinoxylan to central
   metabolism" is a traversal of the anchor-derived graph, not a stored trait —
   the same mechanism as `PRPP > IMP > AMP`, satisfying invariant 8 with no
   duplicated reactions.
2. **The tier boundaries are the ecological signal.** Depolymerisation without
   uptake is a public-goods degrader; oligosaccharide uptake plus intracellular
   saccharification is selfish Bacteroidetes-style foraging; monosaccharide
   uptake alone is a cross-feeder. That trichotomy is the main thing microbiome
   ecology wants from a carbohydrate database, and it is legible only if
   transport is a first-class GIFT.
3. **Each GIFT stays small enough to defend.** Most degradation GIFTs will have
   one or two required reactions; the enormous CAZy/EC diversity lives in the
   enzyme-system and marker layers, which is where it belongs.
4. **Sugar degradation (tier 3) needs no new machinery** beyond the cycle fix.
   It should be curated first.

The polysaccharide layer needs **five architectural decisions** (§8), three of
them schema changes that should ship as a single schema-4 migration, plus an
amendment to the scope statement in `AGENTS.md` and `architecture.md`.

---

## 2. Granularity: one GIFT per substrate capability

> **Corrected 2026-08-18.** This section originally concluded that each tier
> boundary should be its own GIFT. That was wrong, and the first polysaccharide
> release was rebuilt because of it. The reasoning and the correction are both
> kept here, because the mistake is instructive.

The legacy shape is genuinely wrong. `cellulose_degradation` as one GIFT whose
route is every activity involved in saccharifying cellulose is not minimal:
endoglucanase, cellobiohydrolase, LPMO and β-glucosidase are a mixture of
required chemistry and accessory chemistry, not a conjunction of required steps.
It also inverts the layers, putting alternative chemistries on different
substrates at the marker layer where the ontology expects alternative evidence
for one component.

**The original error** was concluding from that failure that each step should
become its own GIFT. That produced six single-reaction traits — depolymerisation,
saccharification, debranching — which made a GIFT equivalent to a reaction. That
is the marker-checklist shape the whole ontology exists to avoid, and it left the
question a user actually asks, *can this genome degrade xylan*, unanswerable by
any single trait.

**The correct shape** is one GIFT per substrate capability, with a *minimal*
required route:

```text
xylan_degradation : XYLAN -> D-xylose
  required   endo-1,4-beta-xylanase
  required   beta-xylosidase
  accessory  acetylxylan esterase        (required = 0)
```

Two required reactions, and accessory chemistry at `required = 0` so it
enriches the trace without gating the call.

Both are required as a **curation decision about sufficient evidence**, not
because either enzyme is individually incapable. EC 3.2.1.37 is defined as
xylan 1,4-β-xylosidase and removes successive D-xylose residues from the
non-reducing termini of xylans, so it can release xylose from the polymer
directly; EC 3.2.1.20 behaves the same way on α-glucan termini. What the
endo-acting enzyme contributes is the additional chain ends that make exo-acting
release productive on a polymer rather than marginal. Stating this as "neither
alone liberates a monosaccharide" would be chemically false, and the curator
notes were corrected accordingly.

**The several meaningful states are not lost — they move to the diagnostics.**
A genome carrying only the endo-acting enzyme reports `complete = FALSE`,
`minimum_missing_reactions = 1`, `missing = RXN_XYLOOLIGO_EXO`. That is the
primary-degrader state, and it says more than a positive call for a fragment
would, because it names what is absent. This is what route completeness and
closest-route reporting are for; the first release worked around them instead of
using them.

The general rule: **a GIFT must remain a capability someone would ask about.**
If the answer to "what does a positive call mean" is "it has one enzyme", the
boundaries are wrong.

---

## 3. Evidence sources

CAZy and dbCAN are the reference for carbohydrate-active enzyme identity,
family/subfamily assignment, and characterised activity. Substrate scope,
family-to-activity mapping, and marker confidence are taken from them and from
primary literature, not from any earlier gifter release.

Planned additions to `SOURCES.md`:

- CAZy database — family definitions and characterised-activity records
- dbCAN3 / dbCAN-sub — HMM libraries and subfamily assignment used by the
  annotation pipelines that produce gifter input
- Rhea, ChEBI, KEGG — as already used, for reaction chemistry, anchor identity
  and orthology markers

**The distillR 1.x `GIFT_db` is explicitly not an evidence source.** Its
polysaccharide definitions are lists of EC numbers with no stated provenance,
mixed evidence namespaces between rows, and no separation of required from
accessory chemistry. It may be consulted once, at the end, as a *coverage
check* — did the new database lose a substrate class distillR users depend on — and
that comparison belongs in `CHANGELOG.md`, not in any source table's `source`
column.

---

## 4. Compartment

Accepted as a scope extension. This is a deliberate, bounded amendment to the
"gifter does not model compartments" statement in
[architecture.md](architecture.md#what-gifter-deliberately-does-not-model),
and both that file and `AGENTS.md` must be updated when it ships.

### 4.1 What is in scope

A two-valued **location qualifier on declared anchors only**:

```text
anchor.compartment ∈ { extracellular, cytoplasmic, unspecified }
```

Nothing else. Reactions, internal intermediates and markers gain no location.
There is no membrane potential, no transport stoichiometry, no proton coupling,
no compartment-aware mass balance, and no intracellular metabolite inventory.
Those remain out of scope and the amended scope statement must say so
explicitly, or this decision will be read as permission to build a metabolic
model.

### 4.2 Compartment is a curated boundary, not a genomic inference

This is the sentence the whole design rests on.

A KO or CAZy family identifies chemistry, not localisation. Signal peptides are
not accessions and do not fit the `namespace + accession` marker model.
gifter therefore **cannot infer from a genome whether a given hydrolase is
secreted**, and must not pretend to.

What gifter *can* do is state, as a curation decision, where a chemistry
occurs for a given substrate class — exactly as it already states where a
capability's boundaries fall. Two cases are evidenced without any genomic claim:

- **Polymers are extracellular by definition.** No cell imports cellulose. A
  polymer-cleaving GIFT is extracellular because its substrate is.
- **Transporters are membrane-located and directional by definition.** A
  transport GIFT's compartment claim is intrinsic to what a transporter is.

Everything else — where a β-xylosidase acts — is a curated judgement about the
substrate class, recorded per GIFT in `gifts.notes` with a `database_changes`
entry, and defensible or contestable as such.

### 4.3 Where anchors are split

Compartment splitting is **demand-driven, not systematic**. An anchor is split
only when a transport GIFT is actually curated for it. Unsplit anchors keep
`compartment = unspecified`, which is also the value for the 19 existing
biosynthesis anchors, so no existing content is disturbed.

| Tier | Split? | Reason |
|---|---|---|
| Polymer | No | Extracellular intrinsically; nothing to distinguish |
| Oligosaccharide | Yes, where uptake is curated | This is where selfish foraging is visible |
| Monosaccharide | Yes, where a substrate-specific transporter is curated | Distinguishes cross-feeders |
| Central entry | No | Cytoplasmic intrinsically |

### 4.4 The splitting licence: substrate physics plus transporter evidence

There is no default compartment. Assuming intracellularity would bias the
database toward host-associated physiology and misread every environmental
dataset; assuming extracellularity would do the reverse. Instead, a chemistry is
split by compartment only when **both** conditions hold:

- **(a) The substrate's physical properties make both locations possible.**
  A polymer cannot cross a membrane, so polymer-cleaving chemistry is
  extracellular and unsplit. Oligosaccharides and monosaccharides can cross, so
  both locations are physically open to them.
- **(b) Substrate-specific transporter markers exist to evidence the
  crossing.** Without them the split is an assertion, not an inference.

If either fails, curate **one compartment-unspecified GIFT** for the chemistry
and say so in its notes. This is the rule that keeps the model honest: gifter
splits where it can evidence the split and declines where it cannot, substrate
by substrate, rather than applying a global prior.

The rule also protects against the worst failure mode. An unevidenced
transporter that becomes a required reaction would silently break an otherwise
complete catabolic chain, turning a missing annotation into a false negative for
the whole capability. Coupling the split to transporter evidence means no chain
can be broken by a transporter gifter was never able to identify.

### 4.5 Separating exo-activities by compartment

Exo-activities are separated, per 4.4(a)–(b). Where the licence is granted, the
two variants are constructed asymmetrically, and the asymmetry is what makes
them evidentially distinct rather than duplicate columns:

```text
  XYLO-OLIGOSACCHARIDE(out)                XYLO-OLIGOSACCHARIDE(out)
        |                                        |  [xylooligosaccharide_uptake]
        |  EXTRACELLULAR variant           XYLO-OLIGOSACCHARIDE(in)
        |  route = β-xylosidase                  |  INTRACELLULAR variant
        |        + xylose translocation          |  route = β-xylosidase
        v          (both required)               v
    D-XYLOSE(in)  <---------------------->  D-XYLOSE(in)
```

- **The extracellular variant carries the translocation inside its own
  boundaries.** Its declared output is the cytoplasmic sugar, so reaching that
  output genuinely requires both the hydrolysis and the transport reaction. The
  transporter is a required route reaction, not an adjacent GIFT. This is the
  architecture working as intended: the anchors determine the route content.
- **The intracellular variant carries only the hydrolysis.** Its input anchor is
  already cytoplasmic, put there by the upstream uptake GIFT, so composition
  supplies the transport requirement instead. Keeping oligosaccharide uptake as
  its own GIFT is right because selfish foraging is a strong standalone signal.

The asymmetry is principled, not ad hoc: the extracellular variant must cross
the membrane within its boundaries, and the intracellular variant does not.

Both variants share the same reaction, system, component and marker rows for the
hydrolysis; only the GIFT, route and route-membership rows differ, which the
architecture explicitly permits.

**Cost, stated plainly.** A genome that secretes an exo-enzyme and releases free
sugar without importing it — a pure public-goods donor — is negative for both
variants. That state remains visible at the reaction layer and in the trace, and
can be promoted to its own GIFT later if cross-feeding donation becomes a
curation target. It is not represented as a trait in this proposal, because
distinguishing a donor from a periplasmic enzyme with an unannotated transporter
is not something the markers can do.

### 4.6 Transport GIFTs

Transport maps onto the existing hierarchy unusually well:

| Layer | Transport content |
|---|---|
| Route | alternative transporter architectures (ABC vs MFS vs PTS vs TonB-dependent) |
| System | one transporter complex |
| Component | **SBP + permease + ATPase are jointly required** — the AND layer earning its keep |
| Marker | substrate-specific transporter KOs; characterised SBP families |

Two nuances worth curating correctly:

- **PTS is group translocation.** Glucose PTS uptake yields cytoplasmic
  glucose 6-phosphate, not cytoplasmic glucose. Different output anchor, so it
  is a different GIFT — `glucose_uptake_pts` (GLUCOSE(out) → GLUCOSE_6P) versus
  `glucose_uptake_permease` (GLUCOSE(out) → GLUCOSE(in)), with hexokinase as a
  separate GIFT. This is forced by anchors being per-GIFT, and it is also the
  right biology: PTS possession is a real ecological signal.
- **SusC/SusD substrate specificity cannot be assigned, and will not be.**
  It comes from PUL context — co-localisation with CAZymes — and genomic-context
  evidence is ruled out because gifter operates on chunked MAGs where contig
  fragmentation makes gene neighbourhood unreliable (§12.6). Curate transport
  GIFTs only where substrate-specific markers exist: characterised ABC
  substrate-binding proteins, substrate-specific PTS components, and
  characterised MFS permeases. A generic "has a TonB-dependent transporter"
  trait would be worthless and must not be created.

**This has a taxonomic consequence that must be documented.** Substrate-specific
uptake markers are far better developed for ABC and PTS systems, which dominate
in Firmicutes, than for the SusCD systems that dominate Bacteroidetes glycan
foraging. The selfish-forager phenotype will therefore be resolved well in
Firmicutes and poorly in Bacteroidetes — precisely the taxon where it is most
biologically real. Under the licence rule of §4.4 the correct response is not to
guess: where Bacteroidetes-type uptake cannot be evidenced for a substrate, the
chemistry stays compartment-unspecified for that substrate rather than being
split into variants that systematically call Bacteroidetes negative.

---

## 5. Granularity rule

To prevent the tier design from atomising the database, a candidate GIFT earns
its own row only if **all three** hold:

1. **Chemically distinct boundaries.** Its input and output anchors differ from
   those of every neighbouring GIFT.
2. **Independent variation.** Real genomes exist that have it without the
   adjacent capability. If every genome carrying the endo-enzyme also carries
   the exo-enzyme, the intermediate anchor is noise.
3. **Interpretive consequence.** Knowing it separately changes an ecological or
   physiological reading.

Otherwise it is folded into the adjacent GIFT as an additional required or
accessory (`required = 0`) reaction.

Three standing corollaries:

- **Polymer anchors split by ecological substrate identity; oligomer and
  monomer tiers are shared and never duplicated.** Mixed-linkage glucan keeps
  its own polymer anchor because cereal β-glucan is a distinct dietary
  substrate, but it feeds the same gluco-oligosaccharide and glucose tiers as
  cellulose — no parallel downstream GIFTs.
- **Side-chain release earns a GIFT only when the released sugar is itself
  fermentable and anchored** (arabinose, glucuronate). De-blocking chemistry
  whose product is not a useful anchor is an accessory reaction (§9).
- **Compartment variants require a licence** (§4.4): the substrate must be
  physically able to occupy both locations, and substrate-specific transporter
  markers must exist. Unlicensed chemistries stay compartment-unspecified.

---

## 6. Worked examples

### 6.1 Cellulose — the core pattern

**`cellulose_depolymerisation`** — CELLULOSE → CELLOBIOSE(out)

| Layer | Content |
|---|---|
| Route `CELL_HYDROLYTIC` | endo-β-1,4-glucanase (EC 3.2.1.4) **required**; cellobiohydrolase (EC 3.2.1.91 / 3.2.1.176) `required = 0`; LPMO (EC 1.14.99.54 / 1.14.99.56) `required = 0` |
| Systems | **revised at implementation:** one system per reaction. These are single-protein hydrolases, and an annotation pipeline cannot tell whether a family hit and an orthology hit describe the same protein — they usually do. Modelling them as alternative systems would imply two enzymes where there is one. The layer stays available for multi-subunit CAZyme architectures. |
| Components | single catalytic protein each; CBM appendages are not components |
| Markers | `CAZY GH9`, `EC 3.2.1.4`, `KO K01179` are OR alternatives for the same component |

`required = 0` is the honest place for accessory chemistry: a genome with only
an endoglucanase does depolymerise cellulose, while LPMOs and CBHs raise
efficiency and belong in the trace rather than in the call.

**`cellobiose_uptake`** — CELLOBIOSE(out) → CELLOBIOSE(in), ABC or MFS routes.

**`cellobiose_utilisation`** — CELLOBIOSE(in) → D-GLUCOSE(in)

| Route | Chemistry |
|---|---|
| `CELB_HYDROLYTIC` | β-glucosidase, EC 3.2.1.21 (GH1, GH3; KO K01188) |
| `CELB_PHOSPHOROLYTIC` | cellobiose phosphorylase, EC 2.4.1.20 (GH94) |

Both routes release free glucose, so D-GLUCOSE(in) is a defensible sole output;
α-D-glucose 1-phosphate stays internal to the phosphorolytic route, exactly as
homocysteine stays internal to the methionine GIFTs.

The graph then distinguishes a public-goods cellulolytic degrader, a selfish
cellobiose forager, and a cellobiose cross-feeder — three states that a single
`cellulose_degradation` trait would have collapsed into one.

### 6.2 Arabinoxylan — the heteropolymer pattern

```text
        ARABINOXYLAN
         /         \
  α-L-arabinofuranosidase   EC 3.2.1.55 (GH43, GH51, GH54, GH62)
        |            \
  L-ARABINOSE(out)    XYLAN
        |               | endo-1,4-β-xylanase EC 3.2.1.8 (GH10, GH11, GH30, GH5)
        |        XYLO-OLIGOSACCHARIDE(out)
        |               | ==== uptake ====
        |        XYLO-OLIGOSACCHARIDE(in)
        |               | β-xylosidase EC 3.2.1.37 (GH3, GH39, GH43, GH52, GH120)
        |          D-XYLOSE(in)
        |               |
        \--uptake--> D-xylulose 5-phosphate
```

Arabinofuranose release earns a GIFT under §5 corollary 2 because L-arabinose
is fermentable and anchored, and because the same L-arabinose GIFTs then serve
arabinoxylan, arabinan and arabinogalactan without triplicate curation.
α-Glucuronidase (EC 3.2.1.139; GH67, GH115) earns one for the same reason.
Acetyl and feruloyl esterases do not — see §9.

### 6.3 Remaining substrates

| Substrate | Tier 1→2 | Tier 2→3 |
|---|---|---|
| Starch | α-amylase EC 3.2.1.1 (GH13); pullulanase EC 3.2.1.41 as separate debranching GIFT | α-glucosidase EC 3.2.1.20 or maltose phosphorylase EC 2.4.1.8 |
| Pectin | pectate lyase EC 4.2.2.2 (PL1/PL9/PL10) or polygalacturonase EC 3.2.1.15 (GH28); methylesterase EC 3.1.1.11 (CE8) as its own GIFT | exo-polygalacturonase / unsaturated glucuronyl hydrolase → D-galacturonate |
| β-mannan | endo-β-1,4-mannanase EC 3.2.1.78 (GH5, GH26) | β-mannosidase EC 3.2.1.25 |
| Chitin | chitinase EC 3.2.1.14 (GH18, GH19) → chitobiose | β-N-acetylhexosaminidase EC 3.2.1.52 (GH20) → GlcNAc |
| Mixed-linkage glucan | licheninase EC 3.2.1.73 | shares the cellulose tier-2/3 GIFTs |
| **Mucin O-glycan** | **no endo tier** | parallel exo-glycosidases: sialidase EC 3.2.1.18 (GH33), α-fucosidase EC 3.2.1.51 (GH29, GH95), β-galactosidase, α-GalNAcase EC 3.2.1.49 |

Mucin is the exception that proves the tier rule. There is no polymer→oligomer
cut, so it is curated as parallel monosaccharide-release GIFTs from one
MUCIN_O_GLYCAN anchor. Each passes the granularity rule on its own — sialidase
and fucosidase possession vary independently across gut taxa and mean different
things — and "how much of a mucin forager" is answered by counting complete
GIFTs, not by a route score.

---

## 7. Sugar degradation (tier 3): curate this first

Short routes, real alternatives, no new machinery beyond the cycle fix.

| GIFT | Input | Output | Candidate route |
|---|---|---|---|
| `xylose_degradation_isomerase` | D-XYLOSE(in) | XYLULOSE_5P | xylA (RHEA:22816 only), xylB |
| `xylose_degradation_oxidative` | D-XYLOSE(in) | 2-OXOGLUTARATE | Weimberg |
| `arabinose_degradation` | L-ARABINOSE(in) | XYLULOSE_5P | araA, araB, araD (**K03077**, not K01786) |
| `fucose_degradation_isomerase` | L-FUCOSE(in) | DHAP + L-LACTALDEHYDE | fucI, fucK, fucA |
| `fucose_degradation_oxidative` | L-FUCOSE(in) | PYRUVATE + L-LACTATE | dehydrogenase route |
| `rhamnose_degradation` | L-RHAMNOSE(in) | DHAP + L-LACTALDEHYDE | rhaA, rhaB, rhaD |
| `galactose_degradation_leloir` | D-GALACTOSE(in) | GLUCOSE_6P | galM, galK, galT, galE |
| `galactose_degradation_tagatose` | D-GALACTOSE(in) | DHAP + G3P | tagatose-6-phosphate route |
| `mannose_degradation` | D-MANNOSE(in) | FRUCTOSE_6P | hexokinase/PTS + manA — **deferred**, see below |
| `glcnac_degradation` | GLCNAC(in) | FRUCTOSE_6P | nagK, nagA, nagB |
| `neuac_degradation` | NEUAC(in) | FRUCTOSE_6P | nanA, nanK, nanE |
| `galacturonate_degradation` | D-GALACTURONATE(in) | PYRUVATE + G3P | uxaC, uxaB, uxaA, kdgK, eda |
| `glucuronate_degradation` | D-GLUCURONATE(in) | PYRUVATE + G3P | uxaC-shared route |

Splitting by product is forced, not chosen: the isomerase and oxidative xylose
routes end at different central metabolites, and anchors are declared per GIFT,
so they cannot be two routes of one GIFT. The same applies to the two fucose
routes and the two galactose routes. This is the anchor model doing its job —
the split tracks a real difference in what the cell gets out of the sugar.

---

## 8. Architectural decisions required first

### 8.1 Reaction identity for polymer chemistry — schema

`reaction.rhea_master` is `NOT NULL UNIQUE`, and
[database-build.R:327](../../R/database-build.R#L327) rejects anything not
matching `^RHEA:[0-9]+$`. Rhea coverage of polymer-acting hydrolases is
incomplete and often generic over an undefined substrate class, because a
polysaccharide is not a ChEBI compound with a balanced equation.

Add `reaction.reaction_id` (TEXT, UNIQUE, curator-facing), make `rhea_master`
nullable, and require at least one `reaction_xrefs` entry (RHEA or EC) per
reaction. Rhea stays preferred and stays the identity wherever it exists.
Minting local pseudo-Rhea IDs was rejected as dishonest provenance; restricting
curation to Rhea-covered reactions was rejected as excluding most of the layer.

Note this also serves transport, though Rhea does carry many transport
reactions with location-qualified ChEBI participants.

### 8.2 Anchor compartment — schema

Add `anchor.compartment` with the three values of §4.1, defaulting existing rows
to `unspecified`.

**`chebi_id TEXT UNIQUE` at [gifter.sql:18](../schema/gifter.sql#L18) is a
hard blocker** — two location states of the same molecule cannot both carry
their ChEBI ID. Relax to `UNIQUE (chebi_id, compartment)`.

Add `anchor.molecule`, a stable key shared by the compartment variants of one
molecule and defaulting to the `anchor_id` for unsplit anchors, with
`UNIQUE (molecule, compartment)` as the natural key. ChEBI cannot serve this
role: oligosaccharide anchors such as xylo-oligosaccharide are substrate classes
with no single ChEBI entry, so both variants would carry a null and fail to
match. `molecule` is what §8.7 traverses on.

The validator must also gain a check that a GIFT with `mode = transport` has
input and output anchors sharing a `chebi_id` and differing in `compartment`,
since that is what makes it a transport GIFT rather than a chemistry GIFT. The
check is conditional on the mode: a catabolic GIFT may legitimately contain a
transport reaction inside its route (§4.5) without being a transport GIFT.

### 8.3 Acyclicity versus catabolism — schema

The validator rejects cycles in the anchor-derived composition graph. Correct
for a biosynthesis-only database; broken the moment catabolism arrives:

```text
FRUCTOSE_6P --> ... --> GLCNAC       (amino sugar biosynthesis, future)
GLCNAC      --> ... --> FRUCTOSE_6P  (glcnac_degradation, this proposal)
```

Not a boundary error — both directions are real, separately encoded and
separately meaningful. Add `gift.mode` ∈ {`anabolic`, `catabolic`,
`transport`, `interconversion`} and forbid cycles only within a mode.
Downgrading the check to a warning was rejected: it loses the invariant that
caught the homocysteine problem.

This cannot be deferred. The first sugar degradation GIFT sharing an anchor with
a future biosynthesis GIFT fails the build.

### 8.4 Confidence does not reach the call — code

`component_marker.confidence` is stored, compiled and carried into the evidence
trace ([evaluation.R:516](../../R/evaluation.R#L516)), but the GIFT-level result
has no confidence field, so a call made entirely from ambiguous CAZy families is
indistinguishable from one made from curated KOs.

Add `evidence_confidence` to the `gifts` tibble: the weakest confidence among
the markers supporting the best route. Qualitative, not numeric, consistent with
the prohibition on uncalibrated scores. This is what makes the marker policy of
§10 enforceable rather than advisory, and it matters most for transport, where
substrate specificity is frequently `putative`.

### 8.5 CAZy namespace inference — code

`.normalize_marker_accession` already uppercases `CAZY`
([evaluation.R:32](../../R/evaluation.R#L32)), but `.infer_marker_namespace`
([evaluation.R:13](../../R/evaluation.R#L13)) has no CAZy pattern, so a bare
vector of dbCAN calls fails with "unknown namespace" unless `namespace = "CAZY"`
is passed. Add `^(GH|GT|PL|CE|AA|CBM)[0-9]+(_[0-9]+)?$`. A subfamily accession
should **not** implicitly match its parent family marker — if both are accepted,
the curator lists both.

### 8.6 Scope statement — documentation

`AGENTS.md` and `architecture.md` both state that gifter does not model
compartments. Amend to admit the two-valued anchor qualifier and to enumerate
what remains excluded (§4.1). Shipping §8.2 without this leaves the repository
contradicting itself.

### 8.7 Compartment-inexact graph edges — schema view and code

When a chemistry stays unsplit for lack of transporter evidence (§4.4), its
output anchor is `unspecified` while a neighbouring GIFT declares `(in)`. Those
are different anchor rows, so the `gift_graph` view — which joins on
`anchor_pk` — would not connect them and the chain would break. Breaking it
would reintroduce exactly the false negative the licence rule exists to prevent.

Traverse, and flag the edge. The rule is three-way and the third case is the one
that matters:

| Output anchor | Input anchor | Edge |
|---|---|---|
| same `anchor_pk` | same `anchor_pk` | **exact** |
| same `molecule`, one side `unspecified` | | **compartment_inexact** — traversed, flagged |
| same `molecule`, both specified and different | | **no edge** |

The third row is what keeps transport GIFTs meaningful: `XYLOSE(out)` must never
connect freely to `XYLOSE(in)`, or the uptake GIFT becomes decorative and the
whole compartment layer collapses.

Implementation: extend the `gift_graph` view with an `edge_quality` column,
surface it in `gift_graph()`, and carry it into any chain-level reporting so a
traversal that relied on an inexact edge says so. A chain assembled entirely
from exact edges is a stronger claim than one that crossed an unresolved
boundary, and the difference must be visible rather than silently averaged away.

---

## 9. Assessment: acetate and ferulate as anchors

Both were candidates because esterases release them during fibre degradation.
Assessed on physiological and ecological value:

**Acetate — rejected.** The ecological value of an acetylxylan esterase is not
that it makes acetate; esterase-released acetate is negligible against
fermentative acetate flux. Its value is **de-blocking**: acetyl decorations
sterically prevent backbone xylanases from accessing the chain. Modelling it as
acetate-producing would misstate the biology and would make ACETATE a graph hub
that every future fermentation GIFT connects to, with cycles through acetate
consumers. Curate acetyl esterases as `required = 0` accessory reactions inside
the xylan and mannan depolymerisation GIFTs. ACETATE should become an anchor
only when SCFA and fermentation metabolism is curated, where it is genuinely
load-bearing.

**Ferulate — deferred, then yes.** Ferulate has standalone value that acetate
lacks: it is a distinct phenolic compound with host relevance, it is
microbially catabolised by a real and unevenly distributed capability, and
feruloyl esterase releases the cross-links tethering arabinoxylan to lignin, so
its ecological meaning is unlocking recalcitrant substrate. But an anchor whose
downstream GIFTs do not exist is a dead end in the graph. Curate feruloyl
esterase as an accessory reaction now; promote FERULATE to an anchor and split
out the release GIFT when phenolic-acid catabolism is curated.

---

## 10. Marker policy

For carbohydrate-active enzymes, CAZy and dbCAN are the reference (§3). All
namespaces sit at the same OR-at-marker layer, but they assert different things
and `component_markers.confidence` must say so.

| Namespace | Asserts | Use as |
|---|---|---|
| `CAZY` subfamily | sequence family, usually activity-coherent | **preferred for CAZymes**; `high-confidence` |
| `CAZY` family | sequence family, often polyspecific | `ambiguous` unless the family is monoactivity |
| `KO` | orthologous group, activity-specific where one exists | preferred for non-CAZyme steps and transporters; `curated` |
| `EC` | activity, no sequence claim | secondary; never the sole evidence for a required reaction |

The failure mode is concrete: GH5 spans endoglucanase, mannanase, licheninase
and exo-glucanase, so accepting bare `CAZY GH5` for the cellulose endoglucanase
component makes every mannan degrader a cellulose degrader. GH13, GH30 and GH43
behave the same way.

Rules:

1. Prefer subfamily accessions (`GH5_4`, `GH43_29`) for polyspecific families.
   Accept a bare family only where it is effectively monoactivity — GH11, GH48,
   GH28, GH33, GH20 are candidates — and record why in `component_markers.notes`.
2. Never let an `ambiguous` marker be the sole accepted evidence for a
   route-critical reaction. Where no better marker exists, that is a fact about
   the evidence and must be visible in the call (§8.4).
3. EC alone is not sufficient for a required reaction. In most annotation
   pipelines the EC assignment for a CAZyme is itself derived from the same HMM
   that produced the CAZy call, so treating it as independent evidence
   double-counts. Pair it with the family or subfamily.
4. CBMs and dockerins are not markers for catalytic components. They may later
   justify a separate accessory-module claim; they do not support a chemistry
   claim.

---

## 11. What users will notice

distillR 1.x produced graded fibre-degradation scores because a polysaccharide
was one many-step element. Here most degradation GIFTs have one or two required
reactions, so per-GIFT values will be largely binary.

The graded signal moves to the reporting layer: the count of complete GIFTs
within a substrate family, and the depth of traversal achieved from polymer to
central metabolism. That is a better quantity — interpretable, traceable to
genes, and it distinguishes degrader from forager from cross-feeder, which the
old score could not.

This belongs in `CHANGELOG.md` when implemented, because it changes
community-level indices computed with the distillR database.

---

## 12. Decisions taken

1. **Compartment is in scope.** Split by compartment, because it carries real
   ecological characterisation. Implemented as §4, bounded to a two-valued
   anchor qualifier, with the localisation claim held as a curation decision
   rather than a genomic inference.
   1a. **Exo-activities are separated by compartment** (§4.5), with the
   extracellular variant carrying the translocation inside its own boundaries so
   that the split is evidenced by transporter genes rather than asserted.
   1b. **No default compartment** (§4.4). Substrate physics decides what is
   possible; transporter evidence decides what is curated. Unlicensed
   chemistries stay compartment-unspecified.
   1c. **No genomic-context evidence.** Ruled out because gifter operates on
   chunked MAGs, where contig fragmentation makes gene neighbourhood unreliable.
   Nothing in the evaluation may depend on co-localisation, operon structure or
   PUL membership. The cost is documented in §4.6.
   1d. **Compartment-inexact edges are traversed and flagged** (§8.7), never
   broken and never silent. Two anchors with different specified compartments
   remain unconnected, so transport GIFTs stay load-bearing.
2. **The legacy database is not an evidence source.** CAZy, dbCAN and primary
   literature are (§3). The distillR definitions may be used once as a coverage
   check for the changelog.
3. **No over-atomisation.** Formalised as the granularity rule in §5 and its
   three corollaries, which decide the mixed-linkage glucan question (shared
   downstream tiers), the compartment-variant question (one variant by
   default), and the side-chain question (anchor-worthy products only).
4. **Acetate and ferulate assessed** (§9): acetate rejected outright as an
   anchor for this domain; ferulate deferred until phenolic catabolism exists.
   Both curated as accessory de-blocking reactions in the meantime.
5. **Substrate-level reporting stays in the reporting layer** — a traversal of
   `gift_graph()` filtered by `category`. A named collection of GIFTs is not a
   biological entity and does not become one.

---

## 13. Proposed order of work

1. Schema 4 in one migration: reaction identity (§8.1), anchor compartment with
   the `molecule` key and the ChEBI uniqueness relaxation (§8.2), `gift.mode`
   and the mode-aware cycle check (§8.3), and the `edge_quality` column on the
   `gift_graph` view (§8.7) — with validator, compiler, accessors, tests and
   documentation together, including the scope amendment (§8.6).
2. Code: confidence propagation (§8.4), CAZy inference (§8.5), and
   compartment-inexact traversal in `gift_graph()` (§8.7).
3. Tier 3, sugar degradation (§7). Proves the central-entry anchors and the
   mode-aware cycle check on real content, and is independently valuable if the
   polysaccharide layer stalls.
4. **The uptake layer**, substrate by substrate, against the test in §14. This
   comes before the compartment splits it licenses, and its outcome determines
   which chemistries are split at all.
5. Tier 1–2 for **starch** and **arabinoxylan**. Starch is KO-rich;
   arabinoxylan exercises side-chain release, the oligomer tier and — if the
   uptake layer supports it — the compartment split.
6. Review marker-confidence behaviour and the compartment split on those two
   before continuing. This is the checkpoint for whether the split earns its
   schema cost.
7. Remaining substrates: cellulose, β-mannan, chitin, pectin, mixed-linkage
   glucan, β-galactan, α-galactan, xyloglucan, arabinan, mucin O-glycan.

---

## 14. Assessment: which monosaccharides warrant an uptake GIFT

**In favour of curating monosaccharide uptake broadly.** Under the compartment
model, uptake GIFTs are what close the chain to the cytoplasm — without them,
sugar released by extracellular saccharification never reaches central
metabolism and the traversal dead-ends. Uptake-only genomes are also a
phenotype worth naming: a cross-feeder that consumes fucose or sialic acid
liberated by others is a well-documented and ecologically important strategy.
And for several sugars the transporters are genuinely specific and
well-characterised — fucose permease, sialic acid transporters, the xylose and
arabinose ABC importers, GlcNAc and mannose PTS systems.

**Against.** Sugar transport is dominated by promiscuous carriers. Broad MFS
sugar porters and general PTS systems move several hexoses each, so a
family-level marker attributes a substrate the protein may not prefer. Transport
annotation is also the weakest link in most MAG pipelines, and novel or
diverged transporters are common. That combination produces the asymmetric
failure identified in §4.4: a false-negative transporter, made required, would
silently break an otherwise complete catabolic chain and hide a real capability
— a much worse error than omitting the uptake GIFT altogether. Curating uptake
for all twelve monosaccharides against every transporter family would also
multiply the trait table for little interpretive gain.

**Recommendation.** Curate a monosaccharide uptake GIFT only where a
substrate-specific, characterised transporter marker exists — and let that same
test license the compartment split of the chemistry upstream. The two decisions
are one decision:

```text
substrate-specific transporter markers exist
        |
        +-- yes --> curate the uptake GIFT
        |           and split the upstream chemistry by compartment
        |
        +-- no  --> curate neither
                    chemistry stays compartment-unspecified, chain unbroken
```

**Outcome when the test was applied, 2026-08-18.** The prediction in the
paragraph above was too optimistic. Two substrates passed, not seven, and the
test failed in two distinct ways worth distinguishing:

| Substrate | Markers substrate-specific? | Verified reaction identity? | Outcome |
|---|---|---|---|
| D-xylose | yes, XylFGH and XacGHI | yes, RHEA:29899 | **curated** |
| L-arabinose | yes, AraFGH and XacGHI | yes, RHEA:30007 | **curated** |
| N-acetylneuraminate | yes, nanT | no | deferred |
| Hexuronates | yes, exuT | no | deferred |
| N-acetylglucosamine | yes, NgcEFG | no | deferred |
| L-fucose | **no** | — | refused |
| Galactose, mannose, fructose | **no** | — | refused |

*Failure by marker.* L-fucose was expected to pass. Its KEGG orthologue K02429
is annotated as an MFS **fucose-galactose-glucose** symporter, so accepting it
would attribute fucose uptake to any genome carrying that family — exactly the
promiscuity the test exists to catch. The prediction was wrong because it
assumed a named `fucP` implied specificity.

*Failure by reaction identity.* Sialic acid, hexuronate and N-acetylglucosamine
have genuinely substrate-specific transporter orthologues, but their symporters
and importers carry no EC number and therefore no Rhea master, and TCDB could
not be queried reliably enough to record a verified cross-reference. Under §8.1
a reaction without a Rhea master needs one, so the translocation cannot yet be
curated. This is a provenance gap, not a biological one, and it reopens if a
verifiable transporter reaction vocabulary becomes available.

Both failures produce the same safe outcome: no uptake GIFT, anchor stays
`unspecified`, catabolic chain unbroken.

Glucose PTS remains the exception worth revisiting, since it yields G6P directly
and is therefore a distinct GIFT on chemical grounds anyway (§4.6). The same
applies to N-acetylglucosamine PTS, which yields GlcNAc 6-phosphate and would
require promoting that intermediate — currently internal to
`glcnac_degradation` — to an anchor. That is a boundary change to an existing
GIFT and deserves its own decision rather than being smuggled in with a
transporter.

This also means the uptake layer must be curated **before** the compartment
splits it licenses, which is reflected in the order of work.

---

## 15. Deferred

**Generic glycan-foraging capacity.** Ruling out genomic context (§12.1c) makes
SusCD substrate assignment impossible, yet possession of many SusCD pairs is
itself a real and measurable signal in gut Bacteroidetes. It is not a GIFT — no
anchors, no chemistry claim — so it cannot enter the ontology as one. Deferred
rather than rejected: revisit once the compartment layer has been used on real
datasets and it is clear whether the Bacteroidetes blind spot documented in §4.6
is costing real interpretation. Nothing in this proposal depends on the answer.

No open questions remain. The design is ready to implement in the order of §13.

---

## 16. Step 6: the marker-confidence checkpoint

Carried out 2026-08-21 against database 2026.20.4, on the xylan, arabinoxylan
and starch layers shipped in steps 4 and 5. The checkpoint asked whether the
marker-confidence behaviour earns its cost before eight more substrates are
curated on the same rule. **It licensed continuing, after two corrections.**

### 16.1 What worked

Confidence propagation (§8.4) is correct. `.call_confidence()` takes the best
marker within a component, because alternatives are OR, and the weakest
component across the route, because components are AND. The consequence worth
checking is that adding a weak marker beside a strong one must not make a call
look worse, and it does not: `GH11_e15` and `GH120` together with the
polyspecific `GH43` and `GH3` still call `xylan_degradation` at `curated`.

A CAZy-only genome reaches the same `curated` grade as a KO-only genome. dbCAN
annotation is a first-class input, not a second-tier one, which was the point of
§8.5.

### 16.2 What did not, and what was changed

**Confidence never reached a metric.** `evidence_confidence` was computed,
returned and then discarded: `traits.R`, `universe.R`, `community.R` and
`community-network.R` contained no reference to it. Every metric —
`gift_richness`, `breadth_*`, `community_richness`, `provider_count`,
`abundance_coverage` — read `complete` alone. §8.4 claimed the field made the
§10 marker policy "enforceable rather than advisory"; it did not, because
nothing consumed it. Measured cost: `GH2`, `GH3`, `GH13`, `GH31` and `GH43`, five
families carried by essentially every gut Bacteroidetes genome, produced
`gift_richness = 3` over `carbohydrate_degradation` — the whole polysaccharide
layer, called complete, on no real evidence.

`genome_traits()` and `community_traits()` now take `min_confidence`. A positive
call below the floor becomes **indeterminate, not negative**: weak evidence is
not evidence of absence, so the capability moves out of the richness count and
out of the assessable denominator, exactly as the completeness policy treats a
fragmented genome. On the five-family genome, a `high-confidence` floor takes
richness from 3 to 0 and `assessable_fraction` from 1.00 to 0.75. The default is
`NULL`, which counts every positive call, so no existing result changes.

**The admission threshold was too loose.** Grading was consistent — `curated` at
93% EC agreement and ten or more supporting members, `high-confidence` at 70% —
but `ambiguous` reached down to 3%. `GH13_e486` was admitted as α-amylase
evidence on 3 of 96 EC-annotated members, and with `GH31` it called
`starch_degradation` complete on its own. That is not weak evidence for the
assignment, it is quantified evidence against it, and it is a different thing
from a polyspecific family that genuinely carries the activity among others.
Forty marker rows below 50% agreement were withdrawn; the floor now governs new
CAZy curation as well.

**Two confidence terms are dead.** `putative` and `insufficient evidence` are
defined in the ordering but used nowhere in the database. Left in place: the
ordering is the vocabulary the policy is written against, and transport markers
are the intended home of `putative` (§8.4). Worth revisiting if the uptake layer
grows without ever using it.

### 16.3 Correction to §6.3: mucin candidates that did not survive

§6.3 named four parallel exo-glycosidases for mucin. Three were curated —
sialidase, α-L-fucosidase and α-N-acetylgalactosaminidase — and **β-galactosidase
was rejected**, along with β-N-acetylhexosaminidase, which had been an implicit
candidate as the GlcNAc-releasing activity of the mucin core.

Both fail on the same ground, which is the §10 failure mode rather than a new
one. `GH2`, `GH35` and `GH42` β-galactosidases act on lactose, lacto-N-biose,
galactan and mucin alike, and `lacZ` is carried by an enormous share of gut
genomes; the marker cannot separate mucin galactose release from lactose
hydrolysis, so the GIFT would have called mucin foraging from housekeeping
chemistry. `NagZ` β-N-acetylhexosaminidase is primarily peptidoglycan recycling,
with the same result. The three that were curated all cleave linkages that are
host-glycan-specific — α-2,3/2,6-sialyl, α-fucosyl, and the α-GalNAc-Ser/Thr core
attachment — which is what makes the trait mean what its name says.

This is the granularity rule (§5) and the marker policy (§10) doing their work
before curation rather than after. Both activities remain visible at the reaction
layer for any genome that carries them.

### 16.4 A modelling gap the new substrates exposed

Curating chitin and mucin surfaced an inconsistency that predates them. The
`gift_graph` view called an edge `exact` whenever both GIFTs named the same
anchor, without asking where the upstream chemistry happens. A secreted
glycosidase releases its sugar outside the cell; the catabolic GIFT consumes it
inside. Where no transporter evidence licensed splitting that sugar into
compartment variants, both sides name one unsplit anchor and the membrane
between them vanished from the graph — collapsing exactly the public-goods
degrader, selfish forager and cross-feeder distinction that §4.4 and §4.5 exist
to carry.

The database already held two conventions. `xylan_degradation` and
`collagen_cleavage` declare extracellular products; `starch_degradation`
declares an unspecified `GLUCOSE`. Starch's version had never bitten only
because no glucose catabolism GIFT exists to compose with it.

Resolved in the view rather than in the anchors: an edge out of a GIFT that
declares an extracellular input, through an anchor that leaves the compartment
unresolved, is `compartment_inexact`. The chain stays traversable — breaking it
would turn a missing transporter marker into a false negative for the whole
capability, which §8.7 already rejected — but the graph now says plainly that
the transport step is assumed rather than evidenced. Three edges are
reclassified, 214 are unaffected, and no call changes. Fixing it in the view
also covers starch in advance, and every substrate still to come in step 7.

### 16.5 Deferred: the pectate lyase route

Pectin was curated on its hydrolytic chemistry only — endo-polygalacturonase
(EC 3.2.1.15, GH28) then exo-polygalacturonase (EC 3.2.1.67, GH28 and GH4), with
pectinesterase (EC 3.1.1.11, CE8) accessory in the same way acetyl removal is
accessory to xylan. The lyase chemistry is **deferred, not rejected**, and the
reason is an anchor gap rather than an evidence gap.

The markers are not the problem. PL1, PL2, PL3, PL9 and PL10 supply 32 clusters
for EC 4.2.2.2 above the agreement floor, and pectate lyases are more common
than polygalacturonases in gut Bacteroidetes, so excluding them means the GIFT
misses degraders it should catch. That cost is real and is accepted knowingly.

The problem is where the products land. A lyase cleaves by β-elimination and
yields **unsaturated** oligogalacturonides, which are processed by unsaturated
glucuronyl hydrolase or oligogalacturonate lyase into 5-keto-4-deoxyuronate and
enter catabolism at **2-dehydro-3-deoxy-D-gluconate**. The hydrolytic route
yields D-galacturonate proper. The two chemistries therefore end at different
metabolites, and §7 already settled what follows from that: anchors are declared
per GIFT, so routes ending at different products cannot be two routes of one
GIFT. They would be two GIFTs.

A lyase GIFT cannot be written today because its output boundary does not exist.
2-dehydro-3-deoxy-D-gluconate is an internal intermediate of
`galacturonate_degradation`, not a declared anchor, and §5 is explicit that
internal intermediates are not promoted casually.

**What would unblock it.** Promoting that intermediate to an anchor. The case is
better than it looks: it is where galacturonate catabolism, glucuronate
catabolism and the pectate lyase route all converge, and it is the
Entner-Doudoroff node, which is a genuine branchpoint rather than a convenience.
Doing it means re-cutting `galacturonate_degradation` and
`glucuronate_degradation` to declare it, which is a change to shipped GIFTs and
belongs in its own proposal rather than inside a substrate addition. Nothing
else in step 7 depends on the answer.
