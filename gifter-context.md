# gifter — complete context document

This document is a self-contained description of the R package **gifter**,
intended as the primary source of information for an AI assistant reasoning
about the project. It states what gifter is, what it deliberately is not, how
its data model and evaluation logic work, what its reference database
currently contains, what its public interface looks like, and which rules
govern changes to it.

Snapshot date: 2026-08-21. Package version 0.1.1 (in development), database
version 2026.12.1, schema version 5.

---

## 1. One-paragraph summary

gifter infers whether a genome encodes a biologically defined enzymatic
capability between curated molecular anchors. Such a capability is called a
**genome-inferred functional trait (GIFT)**: a directed claim of the form
"input anchor(s) → output anchor(s)", supported by at least one curated
enzymatic route. Evaluation resolves an explicit Boolean hierarchy —
routes OR, reactions AND, enzyme systems OR, protein components AND, genomic
markers OR — so that a call is discrete and traceable rather than a percentage
of expected genes. All biological content lives in a versioned, human-reviewable
TSV source that is compiled into a read-only SQLite artifact; the R code
contains only general operations over that content, never per-trait logic.

gifter deliberately occupies the space between **marker checklists** (KEGG
module completeness, DRAM, METABOLIC, MicrobeAnnotator — fast but biologically
flat) and **genome-scale metabolic models** (carveMe, gapseq, ModelSEED —
biologically rich but expensive, gap-filled, and hard to audit).

It is the successor to **distillR**, a package that matched KO and EC
identifiers against ~500 curated gene bundles and returned a "fullness" value
per bundle. gifter is a redesign around a different primitive, not a version
bump; no distillR 1.x code path survives, which is why the package was renamed
and versioned afresh at 0.1.0.

Author: Antton Alberdi (antton.alberdi@sund.ku.dk). Repository:
`alberdilab/gifter`. Dependencies: DBI, RSQLite, tibble; R >= 4.1.0.

---

## 2. What a GIFT is

A GIFT is a **directed biological capability between curated molecular
boundaries**. It claims that a genome contains sufficient genomic evidence for
at least one known enzymatic route connecting its declared input anchor(s) to
its declared output anchor(s).

```text
INPUT ANCHOR(S)
       |
       | curated enzyme/reaction route
       v
OUTPUT ANCHOR(S)
```

Examples: `PRPP > IMP`, `IMP > AMP`, `xylan > D-xylose`, `collagen > collagen
peptides`.

### What a positive call means

> The available genomic evidence supports at least one complete known enzymatic
> implementation of this capability.

It does **not** prove expression, enzyme activity, physiological flux,
substrate availability, environmental relevance, or phenotype. Genome
annotations are evidence, not certainty, and user-facing language must preserve
that distinction.

### A GIFT is not

- a KEGG module, pathway ID, KO list, EC list, or gene name;
- a marker checklist with a completeness percentage;
- a stoichiometric or flux model.

External databases contribute chemistry, identifiers, pathway suggestions, and
annotation evidence. They do not define the gifter ontology. A KEGG module is
not automatically a GIFT, and gifter boundaries may intentionally differ from
an external pathway's endpoints.

### Granularity

A GIFT should be interpretable in ecological, evolutionary, physiological, or
host-associated comparison. Avoid both extremes: neither arbitrary single-step
fragments, nor bundles of several independently meaningful capabilities. Good
cut points occur at an important branchpoint, a stable product, a change in
functional identity, the start or end of trait-specific chemistry, or a
molecule through which several meaningful traits naturally connect.

---

## 3. What gifter deliberately does not model

Unless an explicit architectural decision changes scope, gifter does not model:

- growth or biomass reactions;
- flux balance analysis or metabolic flux;
- thermodynamic feasibility;
- metabolite concentrations;
- environmental media or nutrient availability;
- exchange reactions, uptake rates, or secretion rates;
- membrane potential, transport stoichiometry, proton coupling, or
  intracellular metabolite inventories;
- cellular mass balance;
- complete pathway stoichiometry at runtime.

The package answers "Does this genome encode the machinery?" It does not answer
"Will this machinery operate in this environment?" Keeping those questions
separate is central to the design.

One narrow extension has been made deliberately: declared anchors carry a
two-state `compartment` qualifier so that transport and extracellular chemistry
can be stated. See §7.

---

## 4. The evaluation model

### The Boolean hierarchy

```text
GIFT
  |
  +-- OR --> ROUTE
                |
                +-- AND --> required REACTION
                                |
                                +-- OR --> ENZYME SYSTEM
                                               |
                                               +-- AND --> COMPONENT
                                                              |
                                                              +-- OR --> MARKER
```

Compactly:

```text
GIFT            = ANY complete route
route           = ALL required reactions
reaction        = ANY complete enzyme system
enzyme system   = ALL required components
component       = ANY accepted genomic marker
```

The evidence path runs the other way:

```text
observed marker -> enzyme component -> enzyme system -> reaction -> route -> GIFT
```

Each layer solves a distinct biological problem and must never be collapsed
into an adjacent one:

- multiple **routes** = alternative biochemical paths between the same anchors;
- multiple **enzyme systems** = alternative (often non-homologous) enzymes for
  one reaction;
- multiple **components** = proteins jointly required by a complex;
- multiple **markers** = alternative evidence for the same component.

Collapsing these into `KO -> trait` loses the ability to distinguish
alternative pathways, non-homologous replacement, protein complexes,
multifunctional proteins, and genuinely incomplete routes.

### Route completeness

Completeness is discrete and route-based. A GIFT is complete when any one of
its curated routes has support for every **required** reaction. Optional route
reactions (`required = 0`) do not determine completion — for example acetyl
de-blocking is an accessory reaction of xylan degradation.

For an incomplete GIFT the result reports interpretable diagnostics: the
closest valid route, the minimum number of missing required reactions, the
identity of those missing reactions, the supported and unsupported reactions,
and the systems, components, markers, and genes behind each decision.

A normalized `route_score` exists (`1 - missing/required` on the best route)
but is explicitly a secondary summary. "One reaction missing from route X" is
the meaningful output; "87% complete" is not. Closest-route selection and
tie-breaking are deterministic (ordered by missing count, then route ID).

### Explicit alternatives, materialised at build time

Alternative valid minimal routes are stored as separate route records:

```text
route_1 = R1 AND R2 AND R3
route_2 = R1 AND R2 AND R4
```

rather than as a runtime expression `R1 AND R2 AND (R3 OR R4)`. This duplicates
small route memberships but never duplicates reaction, enzyme, or marker
definitions. Runtime logic stays trivial: all required reactions in any route.

### Evidence confidence

Each call carries an `evidence_confidence` term, computed to follow the Boolean
structure: the **best** confidence among the alternative markers supporting each
component (they are OR), then the **weakest** across the components the best
route requires (they are AND). Terms are qualitative and ordered, never
averaged: `curated` > `high-confidence` > `putative` > `ambiguous` >
`insufficient evidence`. A GIFT resting on an ambiguous polyspecific CAZy
family must not read like one resting on curated orthology.

---

## 5. Anchors, boundaries, and composition

### Anchors are the public interface of a trait

Treat a GIFT's boundaries like an API. **Only declared anchors define
relationships among GIFTs.** Internal reaction intermediates are implementation
details: if two GIFTs share the same internal Rhea participant, that fact alone
must never create an edge. Promoting an intermediate to an anchor is a
deliberate decision that requires reconsidering the affected boundaries.

An anchor need not be a small molecule with a balanced equation. `ARABINOXYLAN`
and `COLLAGEN` are anchors; `ARABINOXYLAN` carries no ChEBI ID at all. What
makes something an anchor is that it is a defensible cut point. An entity with
no membership criterion — a generic "peptide pool" — is not a boundary, because
the question the layer exists to answer (is one GIFT's output another's input?)
would have no answer.

### Choosing boundaries

> Start at the nearest biologically meaningful shared precursor,
> host/environmental substrate, or metabolic junction before trait-specific
> chemistry begins. End at the first stable product or branchpoint that
> establishes the capability's identity, before broadly shared metabolism
> resumes.

Worked example, purine biosynthesis:

```text
shared metabolism
       |
      PRPP
======= input boundary =======
       |
purine-core chemistry
       |
      IMP
======= output/branch boundary =======
      /   \
   AMP     GMP
```

Adenylate biosynthesis stops at AMP rather than continuing to ADP and ATP:
phosphorylation is shared metabolism, and AMP already establishes adenylate
identity.

### Keeping the anchor vocabulary small

The anchor table is not a metabolite catalog. Good candidates: environmental or
host-derived substrates and products; stable biosynthetic products; major
precursors and branchpoints; electron donors/acceptors that define the trait.
Do not add ATP, ADP, water, phosphate, protons, cofactors, or every Rhea
participant. Prefer ChEBI identifiers where available.

### Composition without duplication

```text
PRPP > IMP  +  IMP > AMP  =  PRPP > IMP > AMP
```

Never create a separate `PRPP > AMP` GIFT by copying both sets of reactions. A
larger capability is a traversal of the derived graph, produced by
`gift_graph()` from matching output/input anchors.

### Modes and the acyclicity constraint

Every GIFT declares a `mode`:

```text
anabolic | catabolic | transport | interconversion
```

The build validator **rejects cycles in the derived composition graph within a
mode**, and permits them between modes. A catabolic route back to a metabolite
that biosynthesis produces is real biology, not a boundary error:

```text
FRUCTOSE_6P --> ... --> GLCNAC        (anabolic)
GLCNAC      --> ... --> FRUCTOSE_6P   (catabolic)
```

Acyclicity is a real design constraint. Sulfur metabolism is the worked case:
cysteine donates sulfur to methionine, and homocysteine donates sulfur back to
cysteine, so obvious boundary choices close a loop. The database resolves it by
declaring `HOMOCYSTEINE` an **input anchor only**, keeping it internal to both
methionine GIFTs, and not curating a methionine-to-homocysteine capability.
When a cycle appears, ask which boundary is the weakest biological claim
rather than deleting an edge to satisfy the validator.

A `mode = transport` GIFT must declare the same `molecule` as both input and
output — that is what distinguishes moving a substance from changing it.

---

## 6. Reactions, enzymes, and markers

### Reaction identity

A reaction is identified by a stable `reaction_id`, which is the **Rhea master
ID** wherever Rhea covers the chemistry (e.g. `RHEA:15753`). A reaction without
a Rhea master must carry at least one cross-reference; eight such reactions
currently exist for polymer-acting chemistry Rhea does not cover
(`RXN_XYLAN_ENDO_1_4`, `RXN_STARCH_DEBRANCH_1_6`,
`RXN_COLLAGEN_HELIX_CLEAVAGE`, and similar), for which `rhea_master` is `NA`.

Direction is **not** part of reaction identity. A route stores `orientation`
(`forward` / `reverse`) on its membership row. Forward and reverse directional
Rhea IDs are never modelled as unrelated reactions.

KEGG reaction IDs and EC numbers go in `reaction_xrefs.tsv`. gifter may query
Rhea while building and validating the database, but does not duplicate Rhea's
full metabolite/stoichiometry graph into the runtime artifact.

### Enzyme systems and components

Never assume one reaction = one gene.

```text
reaction
  +-- OR -- system A
  |           +-- component A
  |
  +-- OR -- system B
              +-- AND -- component B1
              +-- AND -- component B2
```

The same schema handles single-protein enzymes, heteromeric complexes,
non-homologous replacements, and taxon-specific alternatives without special
cases in R. A multifunctional protein may support components in several systems
or reactions; represent each justified relationship explicitly rather than
collapsing the affected reactions.

### Markers

Markers are annotation identifiers supporting **enzyme components** — never
reactions, routes, or GIFTs directly. The key is the open pair
`namespace + accession`:

```text
KO          K01939
EC          6.3.4.4
PFAM        PF01752
TIGRFAM     TIGRxxxxx
CAZY        GH10_e98
CUSTOM_HMM  gifter_purA
```

New evidence systems enter without a schema migration. `component_markers.tsv`
records `evidence_type`, `confidence`, `source`, and `notes` for each mapping.

### Invariant 16: marker specificity bounds trait specificity

A marker that cannot distinguish one substrate from another licenses only the
broader capability. Two consequences:

1. A generic activity marker never supports a substrate-specific claim —
   peptide-bond hydrolysis is not evidence of collagen cleavage.
2. Accepting an over-broad marker **damages the other traits it also matches**,
   by silently equating them with the one it was accepted for. Pseudolysin
   (EC 3.4.24.26) hydrolyses elastin, collagen, fibronectin and IgA; admitting
   it as evidence of elastin cleavage would also license a collagen call from a
   genome carrying no collagenase.

Where no marker reaches the required specificity, **refuse the trait and record
why**. This is not hypothetical: of eight candidate protein-degradation traits
evaluated, seven were refused and only `collagen_cleavage` was curated (MEROPS
family M9 collagenase evidence).

Sequence-family namespaces need particular care — a family is not an activity.
CAZy families GH5, GH13, GH30, GH43 are polyspecific. Prefer the dbCAN
subfamily accession (`GH13_e94`), accept a bare family only where it is
effectively monoactivity, record the reason in `notes`, and mark the mapping
`ambiguous` when it is.

---

## 7. Compartment and transport

Every anchor carries:

```text
molecule      stable identity shared by the compartment variants of one substance
compartment   extracellular | cytoplasmic | unspecified
```

This exists so that depolymerising a polymer outside the cell, importing the
product, and saccharifying it inside can be told apart — public-goods degrader,
selfish forager, and cross-feeder are different ecological strategies, and they
are invisible if every boundary molecule is compartment-blind.

**Compartment is a curated boundary claim, not a genomic inference.** A KO or
CAZy family identifies chemistry, not localisation, and a signal peptide is not
an accession. Two cases are intrinsic and need no genomic claim: a polymer is
extracellular because nothing imports it, and a transporter is membrane-located
because that is what a transporter is. Everything else is curation judgement,
recorded in the GIFT's notes.

Split an anchor by compartment only when **both** hold: the substrate can
physically occupy both locations, and substrate-specific transporter markers
exist to evidence the crossing. Otherwise leave it `unspecified`. An
unevidenced transporter made into a required reaction would silently break an
otherwise complete catabolic chain, turning a missing annotation into a false
negative for the whole capability.

Composition edges account for unresolved compartments:

| Output anchor | Input anchor | Edge |
|---|---|---|
| same anchor | same anchor | `exact` |
| same molecule, one side `unspecified` | | `compartment_inexact` |
| same molecule, both specified and different | | none |

The third row is what keeps transport meaningful: extracellular glucose reaches
cytoplasmic glucose only through an uptake GIFT. `gift_graph()` reports
`edge_quality` so a traversal that crossed an inexact edge is not mistaken for
a fully resolved claim.

Currently `XYLOSE` and `ARABINOSE` are the compartment-split anchors
(`XYLOSE_EX`/`XYLOSE_IN`, `ARABINOSE_EX`/`ARABINOSE_IN`), each crossed by an
ABC-transport GIFT.

---

## 8. Facets and the derived profile (schema 5)

Facets **classify** a capability; they never enter the completeness logic that
produces a call. The vocabulary is open across facets and closed within a
facet: `facet_term` registers every `(facet, value)` pair with its target and
definition, and the build rejects any unregistered assignment.

**GIFT facets**

- `substrate_class` — single-valued, so it partitions the database:
  `nucleotide`, `amino_acid`, `monosaccharide`, `amino_sugar`, `uronate`,
  `polysaccharide`, `protein`.
- `physiological_role` — multi-valued: `biosynthesis`, `carbon_acquisition`,
  `nutrient_uptake`, `fibre_degradation`, `host_glycan_foraging`,
  `host_tissue_degradation`.

**Anchor facets**

- `molecular_tier` — `polymer`, `oligosaccharide`, `peptide`, `monomer`,
  `small_molecule`.
- `resource_origin` — multi-valued: `plant_derived`, `animal_derived`,
  `host_derived`, `central_metabolism`, `inorganic`.
- `biomass_essential` — `yes` / `no`.

**Route facet:** `oxygen_requirement` is a property of a route, not of a GIFT,
because alternative routes to the same anchors genuinely differ. All 48 current
routes are `independent`.

Validation requires exactly one `substrate_class` and at least one
`physiological_role` per GIFT, and `molecular_tier` plus `biomass_essential`
per anchor.

### The derived profile

The `gift_profile` SQL view computes, from declared anchors, anchor facets, and
the composition graph — **nothing in it is curated**:

- `substrate_tier` — the coarsest input tier (polymer > oligosaccharide >
  monomer > small_molecule);
- `resource_strategy` — `uptake` (consumes outside, delivers inside),
  `public_good` (consumes and releases outside), `private` (stays internal), or
  `unresolved` (a compartment was never licensed, which is a real answer rather
  than a gap);
- `network_position` — `entry`, `intermediate`, `terminal`, or `isolated`;
- `cross_feeding_output` — releases extracellularly something another GIFT
  consumes;
- `auxotrophy_indicator` — anabolic GIFT whose output anchor is
  `biomass_essential = yes`.

`resource_strategy` is the degrader-versus-forager distinction that the anchor
compartment field exists to support.

---

## 9. The reference database

### Source of truth and lifecycle

```text
human-reviewable TSV sources   (inst/extdata/database-source/*.tsv)
        |
        v  validate_gifter_sources()
structural validation
        |
        v  build_gifter_database()
SQLite compilation + foreign-key and integrity checks
        |
        v
read-only runtime queries and evaluation   (inst/extdata/gifter.sqlite)
```

The TSVs are the biological source of truth. **`inst/extdata/gifter.sqlite` is a
compiled artifact and must never be edited by hand.** Compilation is atomic:
the output is replaced only after the new database passes integrity checks.

Build command:

```sh
Rscript data-raw/build_database.R
Rscript -e 'testthat::test_local(".")'
```

Documentation-only edits do not require a rebuild.

### Schema mapping

The reviewable source uses plural TSV filenames; the compiled SQLite uses
singular table names with internal integer primary keys. Stable public IDs
exist in both.

| Source file | Runtime table | Purpose and stable key |
|---|---|---|
| `gifts.tsv` | `gift` | Biological claim; `gift_id`, with `mode` |
| `anchors.tsv` | `anchor` | Boundary molecule; `anchor_id`, `molecule` + `compartment`, usually `chebi_id` |
| `gift_anchors.tsv` | `gift_anchor` | Input/output role and ordinal per boundary |
| `gift_xrefs.tsv` | `gift_xref` | External pathway link and boundary relation |
| `facet_terms.tsv` | `facet_term` | Registered facet vocabulary |
| `gift_facets.tsv` | `gift_facet` | GIFT facet assignments |
| `anchor_facets.tsv` | `anchor_facet` | Anchor facet assignments |
| `reactions.tsv` | `reaction` | Canonical chemistry; `reaction_id`, `rhea_master` where Rhea covers it |
| `reaction_xrefs.tsv` | `reaction_xref` | Namespaced external reaction cross-references |
| `gift_routes.tsv` | `gift_route` | Alternative minimal route; `route_id`, `oxygen_requirement` |
| `route_reactions.tsv` | `route_reaction` | Ordered membership, `orientation`, `required` |
| `enzyme_systems.tsv` | `enzyme_system` | Alternative catalyst implementation; `system_id` |
| `enzyme_components.tsv` | `enzyme_component` | Required protein within a system; `component_id` |
| `markers.tsv` | `marker` | Reusable evidence; `namespace + accession` |
| `component_markers.tsv` | `component_marker` | Evidence mapping with source and confidence |
| `database_changes.tsv` | `database_change` | Curation history entry; `change_id` |
| `change_gifts.tsv` | `change_gift` | GIFTs a change affects |
| `database_release.tsv` | `database_release` | Database, schema, upstream-source, date, commit |

Two SQL views: `gift_graph` (anchor-derived composition edges with
`edge_quality`) and `gift_profile` (§8). The SQL contract is
`inst/schema/gifter.sql`; the compiler and validator are `R/database-build.R`.

### Validation: errors vs warnings

Errors mean the content cannot produce a coherent runtime database: missing
files or columns; empty identifiers; duplicate stable IDs; broken references; a
GIFT without anchors or routes; a route without required reactions; invalid
roles, ordinals, orientations, step order, or required flags; malformed Rhea
IDs; a reaction without a system, a system without a component, or a component
without a marker; composition cycles within a mode; unregistered facet pairs;
unknown pathway relations; malformed release metadata.

Warnings identify structurally valid content that still needs biological
review. A warning must never permit broken relational structure, and an error
must not be used merely because a curator judgement is debatable.

### Linking to external pathways

`gift_xrefs.tsv` links a GIFT to an external pathway with a required
`relation`, which is part of the biological claim:

| Relation | Meaning |
|---|---|
| `equivalent` | Same capability between the same boundaries |
| `subset_of` | The GIFT is part of the external pathway |
| `superset_of` | The GIFT covers the external pathway and more |
| `overlaps` | Partial overlap in both directions |
| `related` | Biologically adjacent context, no shared-chemistry claim |

KEGG M00018 is `subset_of` for three different GIFTs because gifter cuts it at
two branchpoints; `cysteine_biosynthesis_homocysteine` is `superset_of` M00338
while only `overlaps` M00609. Namespaces (`KEGG_MODULE`, `KEGG_PATHWAY`, …) are
an open vocabulary. Read links with `get_gift_pathways()`, and go the other way
with `gifts_for_pathway()`.

### Provenance

Record what each source actually supports: Rhea defines reaction chemistry;
ChEBI identifies an anchor molecule; KEGG or MetaCyc may suggest pathway
organisation or a cross-reference; UniProt, HMM resources or literature may
support enzyme/marker mappings; **gifter chooses the capability, boundaries,
accepted routes, and curation interpretation.** Never imply that an upstream
database endorses a gifter-specific boundary. Dataset-level sources live in
`inst/extdata/database-source/SOURCES.md`; row-level evidence lives in the
relevant source columns.

### Three versions, two changelogs

```text
gifter package version     code and public API release      (0.1.0)
gifter database version    biological content release       (2026.12.1)
schema version            relational contract level        (5)
```

A package release must not silently change biological definitions. A schema
change requires an explicit schema-version bump plus coordinated updates to the
SQL schema, source specification, compiler, validation, tests, and docs, and an
updated `database_release.tsv` (which also records `rhea_release`,
`chebi_release`, `kegg_release`, `build_date`, `source_commit`).

- **Biological changes** are rows in `database_changes.tsv`, linked to affected
  GIFTs via `change_gifts.tsv`, compiled into the database and published in the
  HTML atlas. Each records the release, a UTC timestamp, the hierarchy layer
  touched, whether it broadens/narrows/leaves calls unchanged, and the
  rationale, evidence and effect. Read with `database_changelog()`.
- **Code, API, evaluation-logic and report changes** go in `CHANGELOG.md` at the
  repository root.

Never record a biological decision in `CHANGELOG.md` or a code decision in the
database. The separation is deliberate: a biological decision is versioned with
the content it describes and travels with the compiled artifact.

---

## 10. Current database content (2026.12.1, schema 5)

**29 GIFTs** — 14 anabolic, 13 catabolic, 2 transport. **43 anchors**,
**48 routes**, **91 reactions** (8 without a Rhea master), **98 enzyme
systems**, **112 components**, **424 markers** (282 CAZY, 141 KO, 1 PFAM),
**490 component–marker mappings** (216 curated, 114 high-confidence, 160
ambiguous), **53 external pathway links**, **29 recorded biological changes**.

### Nucleotides

| GIFT | Boundaries |
|---|---|
| `purine_core_biosynthesis` | PRPP → IMP |
| `adenylate_biosynthesis` | IMP → AMP |
| `guanylate_biosynthesis` | IMP → GMP |
| `pyrimidine_core_biosynthesis` | GLUTAMINE + PRPP → UMP |
| `cytidylate_biosynthesis` | UTP → CTP |

### Amino acids

| GIFT | Boundaries |
|---|---|
| `serine_biosynthesis` | PG3 → SERINE |
| `glycine_biosynthesis` | SERINE → GLYCINE |
| `aspartate_semialdehyde_biosynthesis` | ASPARTATE → ASA |
| `homoserine_biosynthesis` | ASA → HOMOSERINE |
| `threonine_biosynthesis` | HOMOSERINE → THREONINE |
| `methionine_biosynthesis_transsulfuration` | HOMOSERINE + CYSTEINE → METHIONINE |
| `methionine_biosynthesis_sulfhydrylation` | HOMOSERINE + SULFIDE → METHIONINE |
| `cysteine_biosynthesis_sulfide` | SERINE + SULFIDE → CYSTEINE |
| `cysteine_biosynthesis_homocysteine` | SERINE + HOMOCYSTEINE → CYSTEINE |

### Sugar catabolism

| GIFT | Boundaries |
|---|---|
| `xylose_degradation_isomerase` | XYLOSE_IN → XYLULOSE_5P |
| `arabinose_degradation` | ARABINOSE_IN → XYLULOSE_5P |
| `fucose_degradation_isomerase` | FUCOSE → DHAP + LACTALDEHYDE |
| `rhamnose_degradation` | RHAMNOSE → DHAP + LACTALDEHYDE |
| `galactose_degradation_leloir` | GALACTOSE → GLUCOSE_1P |
| `glcnac_degradation` | GLCNAC → FRUCTOSE_6P |
| `neuac_degradation` | NEUAC → FRUCTOSE_6P |
| `galacturonate_degradation` | GALACTURONATE → PYRUVATE + GAP |
| `glucuronate_degradation` | GLUCURONATE → PYRUVATE + GAP |

### Transport

| GIFT | Boundaries |
|---|---|
| `xylose_uptake_abc` | XYLOSE_EX → XYLOSE_IN |
| `arabinose_uptake_abc` | ARABINOSE_EX → ARABINOSE_IN |

### Polysaccharides and protein

| GIFT | Boundaries |
|---|---|
| `xylan_degradation` | XYLAN → XYLOSE_EX |
| `arabinoxylan_debranching` | ARABINOXYLAN → XYLAN + ARABINOSE_EX |
| `starch_degradation` | STARCH → GLUCOSE |
| `collagen_cleavage` | COLLAGEN → COLLAGEN_PEPTIDES |

Note the composition chain this produces:
`arabinoxylan_debranching → xylan_degradation → xylose_uptake_abc →
xylose_degradation_isomerase`, with the arabinose released extracellularly
feeding `arabinose_uptake_abc → arabinose_degradation`. That chain, plus the
compartment split, is what makes the degrader/forager/cross-feeder distinction
readable.

> **Caution:** `README.md` is currently out of date on this point — it still
> describes a five-GIFT nucleotide-only database.

---

## 11. Public API

All accessors take an optional `db` argument (an open connection); otherwise
they open and close the packaged database themselves. All return tibbles.

**Database access and metadata**

```r
gifter_db_connect(path = NULL, read_only = TRUE)
gifter_db_disconnect(db)
gifter_db_version(db = NULL)      # package, database and schema versions
```

**Browsing the ontology**

```r
list_gifts(status = NULL)
get_gift(gift_id)
get_gift_anchors(gift_id)        # role, ordinal, molecule, compartment
get_gift_routes(gift_id)
get_gift_reactions(gift_id)      # per route, ordered, with orientation
get_reaction(reaction)
get_reaction_systems(reaction)   # alternative systems and their components
get_gift_pathways(gift_id, namespace = NULL)
gifts_for_pathway(accession, namespace = NULL)
database_changelog(gift_id = NULL)
```

**Facets and profile**

```r
list_facets(facet = NULL)
get_facets(id, target = c("gift", "anchor"))
gifts_by_facet(facet, value)     # e.g. ("physiological_role", "fibre_degradation")
gift_profile()                   # derived, one row per GIFT
gift_graph(quality = NULL)       # quality: "exact" | "compartment_inexact"
```

**Evaluation**

```r
map_markers(annotation_table, namespace = NULL)
evaluate_reactions(annotation_table, namespace = NULL)
evaluate_gifts(annotation_table, namespace = NULL, gene_id = NULL, max_genes = 5000)
trace_gift(result, gift_id, route_id = NULL)
```

**Curation and build**

```r
validate_gifter_sources(source_dir, stop_on_error = TRUE)
build_gifter_database(source_dir, output, overwrite = FALSE, source_commit = NULL)
write_gifter_database_html(path, open = TRUE)
```

### Input format

`evaluate_gifts()` takes a marker table with `namespace` and `accession`
columns; `gene_id` is optional but recommended, because it is what makes the
evidence trace resolve to genes. Namespace can be supplied as a single argument
instead of a column, and is inferred where unambiguous.

Two input guardrails run before the evaluation, because both mistakes they
catch produce a well-formed result that answers a question the user never
asked. A table without a `gene_id` column is not guessed at: the first column
that is neither `namespace` nor `accession` is proposed for approval, and
without an answer the call fails rather than mislabelling the evidence chain.
Approve it with `gene_id = TRUE`, name the column with `gene_id = "locus_tag"`,
or number the markers with `gene_id = FALSE`. An input carrying more than
`max_genes` distinct gene identifiers is questioned as a possible collection of
genomes, whose pooled markers complete routes that no single genome encodes;
`max_genes = Inf` evaluates any table as one genome.

```r
annotations <- data.frame(
  gene_id   = paste0("gene_", 1:9),
  namespace = "KO",
  accession = c("K00764", "K01945", "K00601", "K01952", "K01933",
                "K01587", "K01756", "K00602", "K01939")
)
result <- evaluate_gifts(annotations)
```

### Result structure

`evaluate_gifts()` returns an S3 `gifter_result` list of tibbles, all of which
are retained so the call is auditable:

- `gifts` — the call summary: `gift_id`, `name`, `mode`, `substrate_class`,
  `complete`, `number_of_complete_routes`, `best_route`,
  `minimum_missing_reactions`, `missing_reactions_best_route`,
  `supporting_reactions`, `supporting_components`, `supporting_markers`,
  `supporting_genes`, `evidence_confidence`, `route_score`;
- `routes` — per route: `required_reactions`, `supporting_reactions`,
  `missing_reactions`, `complete`;
- `route_reactions` — ordered membership with `orientation`, `required`,
  `reaction_supported`, `best_system`;
- `reactions` — `supported`, `number_of_complete_systems`, `best_system`,
  `minimum_missing_components`;
- `systems` — `required_components`, `supported_components`,
  `missing_components`, `supported`;
- `components` — `supported`, `accepted_markers`, `supporting_markers`,
  `supporting_genes`;
- `marker_vocabulary`, `evidence`, `marker_map`, `observed_markers`,
  `database_version`.

`trace_gift(result, gift_id)` returns a long-form tibble walking the best (or a
named) route from reactions through selected systems and required components to
observed markers and gene IDs.

`evaluate_reactions()` returns a `gifter_reaction_result` — the same machinery
stopped below the route layer, for use when reaction support rather than trait
support is the question.

### The HTML atlas

`write_gifter_database_html()` writes a single self-contained interactive page
containing: release metadata and row counts; two whole-database network views
(GIFT composition, and GIFTs drawn with their declared anchors); a merged route
network per GIFT; the complete GIFT-to-marker evidence hierarchy; the curation
changelog linked to the traits each change affects; an entity map; and a
searchable browser for every SQLite table. The current public atlas lives at
`https://alberdilab.github.io/gifter/atlas/`; the package website workflow
generates it from the installed SQLite database. The installed package keeps
the generator and database, not a duplicate rendered snapshot.

---

## 12. Non-negotiable invariants

These are the repository's stated rules (from `AGENTS.md`); an AI reasoning
about gifter should treat them as constraints, not preferences.

1. A GIFT is a biological capability, not a KEGG module, pathway ID, KO list,
   EC list, or gene name. External links must state how the curated boundaries
   compare (`equivalent`, `subset_of`, `superset_of`, `overlaps`, `related`).
2. Declared anchors define GIFT boundaries and are the only way GIFTs connect.
   Shared internal reaction participants never create edges.
3. Keep the anchor vocabulary small — a meaningful boundary, branchpoint,
   environmental/host compound, precursor, or stable product, not merely
   anything that occurs in a reaction.
4. Identify a reaction by its stable `reaction_id` (Rhea master where Rhea
   covers it); a reaction without a Rhea master must carry a cross-reference;
   store route orientation separately.
5. Markers are evidence for enzyme components, never traits or reactions
   directly. Marker identity is the extensible pair `namespace + accession`.
6. Represent alternative routes, alternative enzyme systems, multisubunit
   systems, multifunctional proteins, and non-homologous replacements
   explicitly in their proper layers.
7. Call completeness from route logic, not a percentage of expected genes.
   Incomplete results must identify the closest route and missing reactions.
   Scores are secondary summaries only.
8. Build larger capabilities by composing GIFTs through shared declared
   anchors; never duplicate an atomic GIFT's reactions in a larger trait.
   Composition may not cycle within a mode; cycling between modes is expected.
9. Keep GIFTs biologically useful: neither arbitrary single-step fragments nor
   bundles of independently meaningful capabilities.
10. Keep biological definitions in the reference database, never in per-GIFT R
    conditionals.
11. Preserve traceability from every call to routes, reactions, systems,
    components, observed markers and gene identifiers.
12. Preserve provenance, and distinguish imported facts from gifter's own
    boundary and route curation decisions.
13. Version the package, biological database, and schema separately.
14. Treat SQLite as a compiled runtime artifact, not the ontology or the
    hand-edited source.
15. Express uncertainty honestly. A supported route does not prove expression,
    activity, flux, substrate availability, or phenotype.
16. Trait specificity must not exceed the specificity of its genomic evidence
    (see §6).

### Code rules

- Implement general operations over the hierarchy; never
  `if (gift == "purine_core") required_genes <- ...`.
- Keep the public API concept-oriented; users should never need SQL keys.
- Encapsulate database access behind the small internal DBI API.
- Normalize first; add indexes, views or caches only for a demonstrated
  read-path benefit, never by denormalising away biological meaning.
- Keep results deterministic, especially closest-route selection and missing
  reaction reporting.
- Preserve evidence rows and gene IDs through transformations. An unexplained
  classification is a regression even if `complete` is correct.
- Treat schema changes as migrations: SQL schema, source spec, compiler,
  validation, schema version, tests, and documentation move together.

### Decision framework

When several implementations are possible, prefer the one that preserves a
clear biological interpretation, minimises duplicated definitions, separates
chemistry/enzymology/evidence, supports alternatives explicitly, remains
auditable from GIFT to gene, avoids unnecessary metabolic-model complexity,
makes future curation easier, and keeps the GIFT abstraction visible.

The north-star question:

> Does this change make it easier to state, defend, test, and trace the claim
> that a genome encodes a particular biologically meaningful capability?

---

## 13. Curating a new or changed GIFT

The procedure, in order:

1. **Define the claim** — one sentence stating what a positive call means, plus
   why the capability is useful ecologically, evolutionarily, physiologically or
   in a host context. Multiple independent claims in one sentence means split it.
2. **Choose and defend the boundaries** — every input and output anchor, reusing
   existing anchors where the molecule and boundary are the same. Where does
   trait-specific chemistry begin? Where is the first stable product or
   branchpoint? Does an internal branchpoint deserve its own GIFT? Would
   extending the endpoint drift into housekeeping metabolism?
3. **Curate reaction routes** — map to Rhea master reactions, determine
   orientation per route, materialise each valid minimal route as its own record.
   Do not treat an upstream module as authoritative; verify its boundaries,
   chemistry, alternatives and direction against the gifter claim.
4. **Curate enzymes and components** — enumerate alternative systems per
   reaction, and all jointly required components per system. Check specifically
   for monomeric vs multisubunit forms, non-homologous replacements,
   multifunctional/fused proteins, taxon-specific alternatives, and generic vs
   chemically specific reactions.
5. **Curate marker evidence** — map namespaced markers to components with
   evidence type, source, confidence, and ambiguity. A convenient marker is not
   necessarily a specific marker.
6. **Check composition and redundancy** — which existing GIFTs share the new
   anchors; is the proposal atomic, a useful graph addition, already a chain,
   redundant, or a replacement?
7. **Edit source tables in dependency order** — gifts and anchors →
   gift_anchors, gift_xrefs, facets → reactions, reaction_xrefs → routes,
   route_reactions → enzyme_systems, enzyme_components → markers,
   component_markers → SOURCES.md, database_release.
8. **Validate, compile, test, review** — and record the decision in
   `database_changes.tsv` linked to affected GIFTs.

If steps 1–2 cannot be answered, **stop at a documented curation proposal**; do
not manufacture a precise implementation from ambiguous biology. Three such
proposals exist in `inst/doc/`: `proposal-amino-acid-biosynthesis.md`,
`proposal-polysaccharide-degradation.md`, `proposal-protein-degradation.md`, and
`proposal-gift-metadata.md` (the one that produced the facet layer).

---

## 14. Testing strategy

Tests protect the ontology, not the return type. `tests/testthat/` contains:

| File | Protects |
|---|---|
| `test-evaluation.R` | the evidence hierarchy and calls |
| `test-composition.R` | anchor-derived topology |
| `test-compartment.R` | compartment, mode, and edge quality |
| `test-reaction-identity.R` | reaction identity and cross-reference requirements |
| `test-database.R` | validation, compilation, accessors, versions |
| `test-facets.R` | facet vocabulary and derived profile |
| `test-pathway-links.R` | external pathway relations |
| `test-amino-acids.R`, `test-sugar-degradation.R`, `test-polysaccharide.R`, `test-protein-degradation.R`, `test-uptake.R` | curated biological content |
| `helper-markers.R`, `helper-sources.R` | synthetic fixtures; mutating a copy of the sources |

Beyond the five Boolean layers, tests must cover: alternative routes completing
independently; a complex failing when any component is absent; an alternative
system supporting the same reaction; a multifunctional marker supporting each
justified mapping; per-route orientation; deterministic missing-reaction and tie
behaviour; trace output containing the responsible genes/markers; graph edges
using only declared anchors; internal intermediates creating no topology;
compartment-split anchors composing only through a transport GIFT; cycles
rejected within a mode and accepted between modes; the weakest-confidence rule;
source and compiled integrity; and three distinguishable versions.

Explicitly insufficient: a test that only checks for a data-frame class or a
nonzero row count.

`PRPP > IMP`, `IMP > AMP`, and their `PRPP > IMP > AMP` composition are retained
as architectural fixtures and integration examples.

---

## 15. Repository map

```text
gifter/
├── DESCRIPTION, NAMESPACE, LICENSE
├── README.md                      user-facing intro (currently outdated on content scale)
├── AGENTS.md                      repository-wide rules for contributors and coding agents
├── CHANGELOG.md                   code / API / evaluation-logic history
├── R/
│   ├── database.R                 connection + concept-oriented accessors
│   ├── evaluation.R               marker mapping, Boolean evaluation, tracing
│   ├── database-build.R           source validation and SQLite compilation
│   └── database-visualization.R   the self-contained HTML atlas
├── inst/
│   ├── schema/gifter.sql           the relational contract (18 tables, 2 views)
│   ├── extdata/database-source/   the 18 hand-curated TSVs — the source of truth
│   ├── extdata/gifter.sqlite       compiled artifact (never hand-edited)
│   ├── templates/                 atlas CSS and JS
│   └── doc/
│       ├── architecture.md        the full development and architecture guide
│       └── proposal-*.md          curation proposals, including refusals
├── data-raw/
│   ├── build_database.R           validate + compile entry point
│   ├── extract_cazy_subfamilies.R dbCAN subfamily extraction
│   └── reference/                 dbCAN / CAZy substrate-mapping inputs
├── man/                           roxygen-generated .Rd
├── tests/testthat/
└── manuscript/manuscript.md       the paper draft (in progress)
```

---

## 16. Glossary

- **Anchor** — a curated input or output molecule (or molecular entity, such as
  a polymer or protein) defining a GIFT boundary. Only anchors connect GIFTs.
- **Component** — one required protein role within an enzyme system. Any
  accepted marker may support it.
- **Enzyme system** — one complete catalytic implementation of a reaction; one
  or several jointly required components.
- **Facet** — a registered classification term attached to a GIFT or anchor.
  Facets never enter completeness logic.
- **GIFT** — a directed, biologically meaningful genome-inferred capability
  between declared anchors, complete when any valid route is complete.
- **Internal intermediate** — a reaction participant inside a route that is not
  a declared anchor and therefore cannot connect GIFTs.
- **Marker** — a namespaced genomic annotation accession used as evidence for a
  component.
- **Mode** — `anabolic`, `catabolic`, `transport`, or `interconversion`; the
  scope within which the composition graph must be acyclic.
- **Reaction** — a biochemical transformation, identified preferentially by a
  Rhea master ID. Direction belongs to route membership, not to the reaction.
- **Route** — a curated minimal set of required reactions connecting a GIFT's
  boundaries. Routes are alternatives under OR.
- **Traceability** — the ability to explain a result through route, reaction,
  system, component, marker, and supplied gene evidence.

---

## 17. Open items and current state

- The manuscript (`manuscript/manuscript.md`) has a settled structure and
  complete prose through Section 6; the abstract is a draft to be rewritten
  last, citations are pending, and Sections 7–9 (evaluation, discussion,
  availability) need the empirical results.
- `README.md` describes only the original five nucleotide GIFTs and predates
  the amino-acid, sugar, polysaccharide, transport and protein content.
- Marker coverage is heavily KO- and CAZy-based; PFAM has a single entry, and
  TIGRFAM and custom HMM namespaces are supported but unused.
- All 48 routes are `oxygen_requirement = independent`; the facet exists for
  content not yet curated.
- Seven protein-degradation candidates (elastin, keratin, albumin, actin,
  glutelin and others) were evaluated and refused on evidence-specificity
  grounds; that refusal is itself curated content, recorded in
  `proposal-protein-degradation.md`.
