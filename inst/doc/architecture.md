# giftr development and architecture guide

This guide explains the biological model, database schema, development workflow,
and curation rules behind giftr. It is the detailed companion to the
repository-wide [agent instructions](../../AGENTS.md).

Use the headings and keywords below as a search index. The same terms are used
in source-table names and code wherever practical.

## Quick topic index

| Question or keyword | Go to |
|---|---|
| What is a GIFT? What is outside scope? | [Core concepts and scope](#core-concepts-and-scope) |
| OR/AND hierarchy, completeness, closest route | [Evaluation logic](#evaluation-logic) |
| Anchor, boundary, branchpoint, composition, graph | [GIFT boundaries, anchors, and composition](#gift-boundaries-anchors-and-composition) |
| Compartment, transport, uptake, extracellular | [Compartment and transport](#compartment-and-transport) |
| GIFT mode, catabolic cycle, acyclicity | [Composition without duplication](#composition-without-duplication) |
| Rhea, reaction identity, direction, stoichiometry | [Reaction chemistry](#reaction-chemistry) |
| Enzyme alternatives, complexes, components | [Enzyme systems and components](#enzyme-systems-and-components) |
| KO, EC, Pfam, TIGRFAM, HMM, marker namespace | [Genomic markers and evidence](#genomic-markers-and-evidence) |
| Trait specificity, over-broad marker, refusing a trait | [Genomic markers and evidence](#genomic-markers-and-evidence) |
| TSV table or SQLite table | [Reference database schema](#reference-database-schema) |
| Add or change a GIFT | [Curating a new or changed GIFT](#curating-a-new-or-changed-gift) |
| Validate, build, or edit SQLite | [Build and runtime workflow](#build-and-runtime-workflow) |
| Package/database/schema version | [Versioning and releases](#versioning-and-releases) |
| Linking a GIFT to a KEGG module or other pathway | [Linking to external pathways](#linking-to-external-pathways) |
| R code, public API, DBI | [Code architecture](#code-architecture) |
| Tests and invariants | [Testing strategy](#testing-strategy) |
| Migrate an old trait | [Migration of legacy definitions](#migration-of-legacy-definitions) |
| PRPP, IMP, AMP examples | [Canonical examples](#canonical-examples) |
| Meaning of a term | [Glossary](#glossary) |

## Core concepts and scope

### What a GIFT means

A **genome-inferred functional trait (GIFT)** is a directed biological
capability between curated molecular boundaries. It claims that a genome
contains sufficient genomic evidence for at least one known enzymatic route
connecting its input anchor or anchors to its output anchor or anchors.

```text
INPUT ANCHOR(S)
       |
       | curated enzyme/reaction route
       v
OUTPUT ANCHOR(S)
```

Examples include `PRPP > IMP`, `IMP > AMP`, `NO3 > NO2`, and `SO4 > H2S`.
The primary objects of inference are the genes and enzymes conferring the
capability. Anchors give that capability a clear biological identity and allow
it to compose with other GIFTs.

External databases contribute chemistry, identifiers, pathway suggestions, and
annotation evidence. They do not define the giftr ontology. A KEGG module is
not automatically a GIFT, and giftr boundaries may intentionally differ from
an external pathway's endpoints.

### What a positive call means

A positive result means approximately:

> The available genomic evidence supports at least one complete known enzymatic
> implementation of this capability.

It does not prove expression, enzyme activity, physiological flux, substrate
availability, environmental relevance, or phenotype under every condition.
Genome annotations are evidence rather than certainty, and user-facing language
must preserve that distinction.

### What giftr deliberately does not model

giftr is not a genome-scale metabolic model. Unless a future architectural
decision explicitly changes scope, it does not model:

- growth or biomass reactions;
- flux balance analysis or metabolic flux;
- thermodynamic feasibility;
- metabolite concentrations;
- environmental media or nutrient availability;
- exchange reactions, uptake rates, or secretion rates;
- membrane potential, transport stoichiometry, proton coupling, or complete
  intracellular metabolite inventories;
- cellular mass balance;
- complete pathway stoichiometry at runtime.

Declared anchors do carry a two-state `compartment` qualifier, added
deliberately so that transport and extracellular chemistry can be stated. See
[Compartment and transport](#compartment-and-transport) for exactly how narrow
that extension is.

The package answers, “Does this genome encode the machinery?” It does not answer,
“Will this machinery operate in this environment?” Keeping those questions
separate is central to the design.

### Biological usefulness and granularity

A GIFT should be interpretable in ecological, evolutionary, physiological, or
host-associated comparisons. Do not retain a trait merely because an external
database names a pathway.

Avoid both extremes:

- Do not split a pathway into arbitrary tiny reactions simply because the
  schema permits it.
- Do not combine several independently meaningful capabilities into one large
  trait.

Good cut points often occur at an important branchpoint, a stable product, a
change in functional identity, the start or end of trait-specific chemistry, or
a molecule through which several meaningful traits naturally connect.

## Evaluation logic

giftr separates biological meaning, chemistry, enzymology, and genomic
evidence into explicit layers:

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

In Boolean form:

```text
GIFT            = ANY complete route
route           = ALL required reactions
reaction        = ANY complete enzyme system
enzyme system   = ALL required components
component       = ANY accepted genomic marker
```

Each layer solves a different biological problem:

- Multiple routes represent alternative biochemical paths between the same
  anchors.
- Multiple enzyme systems represent alternative enzymes for one reaction.
- Multiple components represent proteins jointly required by a complex.
- Multiple markers represent alternative evidence for the same component.

Collapsing these layers into `KO -> trait` loses the ability to distinguish
alternative pathways, non-homologous replacement, protein complexes,
multifunctional proteins, and genuinely incomplete routes.

### Route completeness

Completeness is primarily discrete and route-based. A GIFT is complete when any
one of its curated routes contains support for every required reaction.
Optional route reactions (`required = 0`) do not determine completion.

For an incomplete GIFT, report interpretable diagnostics:

- the closest valid route;
- the minimum number of missing required reactions;
- missing reactions on that route;
- supported and unsupported reactions;
- the systems, components, markers, and genes behind each decision.

A normalized score can support plotting or ranking, but it must not replace the
route-based call. “One reaction missing from route X” is more meaningful than an
arbitrary “87% complete.” Closest-route and tie-breaking behavior must be
deterministic.

### Explicit alternatives

Store valid minimal routes as separate records. Prefer build-time expansion:

```text
route_1 = R1 AND R2 AND R3
route_2 = R1 AND R2 AND R4
```

over a runtime expression:

```text
R1 AND R2 AND (R3 OR R4)
```

This duplicates small route memberships where necessary, but it does not
duplicate the reaction, enzyme, or marker definitions themselves. Runtime logic
stays simple: all required reactions in any route.

## GIFT boundaries, anchors, and composition

### Anchors are the public interface

Treat a GIFT's boundaries like an API:

```text
             GIFT
  input anchor -> internal chemistry -> output anchor
```

An anchor is a biologically meaningful molecular entity or molecular state used
as a boundary, not necessarily a small molecule. `ARABINOXYLAN` and `COLLAGEN`
are anchors and neither is a compound with a balanced equation; `ARABINOXYLAN`
carries no ChEBI identifier at all. What makes something an anchor is that it is
a defensible cut point, and the vocabulary stays small for that reason rather
than because of any restriction on chemical class. An entity with no membership
criterion -- a generic peptide pool, for instance -- is not a boundary, because
the question the layer exists to answer, whether one GIFT's output is another's
input, then has no answer.

Only declared anchors define relationships among GIFTs. Internal intermediates
are implementation details. If two GIFTs contain the same internal Rhea
participant, that fact alone must not create an edge. If an intermediate becomes
important enough to divide independently meaningful capabilities, promote it to
an anchor deliberately and reconsider the affected boundaries.

`gift_graph()` derives directed edges by matching one GIFT's declared output
anchor to another GIFT's declared input anchor. Do not maintain a second manual
edge list unless it represents semantics that cannot be inferred from anchors.

### Choosing boundaries

Use this working rule:

> Start at the nearest biologically meaningful shared precursor,
> host/environmental substrate, or metabolic junction before trait-specific
> chemistry begins. End at the first stable product or branchpoint that
> establishes the capability's identity before broadly shared metabolism
> resumes.

Boundary choice is a biological modeling decision. Document why each endpoint
is meaningful, especially when it differs from an external resource.

For purine biosynthesis:

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

`PRPP > IMP` and `IMP > AMP` are distinct because IMP is a meaningful
branchpoint. Adenylate biosynthesis stops at AMP rather than automatically
continuing through ADP and ATP: phosphorylation is shared metabolism and AMP has
already established adenylate identity.

### Keeping the anchor vocabulary small

The anchor table is not a metabolite catalog. Good candidates include:

- environmental or host-derived substrates and products;
- biologically active or stable biosynthetic products;
- major precursors and important branchpoints;
- electron donors or acceptors when they define the trait.

Do not add ATP, ADP, water, phosphate, protons, cofactors, transient
intermediates, or every Rhea participant unless one independently defines a
meaningful GIFT boundary. Prefer stable identifiers such as ChEBI for declared
anchors when available.

### Composition without duplication

Composition follows shared declared anchors:

```text
PRPP > IMP
      +
IMP > AMP
      =
PRPP > IMP > AMP
```

Do not create a separate `PRPP > AMP` route by copying the reactions from both
atomic traits. Reusable GIFTs avoid inconsistent curation and make biological
branching visible. A larger capability is a traversable chain in the derived
GIFT graph when the chain remains biologically meaningful.

The source validator rejects cycles in this derived composition graph **within a
GIFT mode**. Every GIFT declares one:

```text
anabolic | catabolic | transport | interconversion
```

Within a mode, a cycle still usually indicates that the chosen boundaries or
directions need review. Between modes it is expected, because catabolism
legitimately returns to metabolites biosynthesis produces:

```text
FRUCTOSE_6P --> ... --> GLCNAC        (anabolic)
GLCNAC      --> ... --> FRUCTOSE_6P   (catabolic)
```

Rejecting that pair would reject correct biology. Rejecting an anabolic loop
would not, which is why the check is scoped rather than removed.

Acyclicity is a real design constraint, not a formality. Sulfur metabolism is
the worked example: cysteine donates sulfur to methionine, and homocysteine
donates sulfur back to cysteine, so the obvious boundary choices close a loop.

```text
homoserine + L-cysteine -> L-methionine     (transsulfuration)
L-methionine            -> L-homocysteine   (methionine salvage)
L-homocysteine + serine -> L-cysteine       (reverse transsulfuration)
                          ^--- closes through CYSTEINE
```

The database resolves this by declaring `HOMOCYSTEINE` as an **input anchor
only**, keeping it internal to both methionine GIFTs, and not curating a
methionine-to-homocysteine capability. Promoting it to an output, or splitting
methionine biosynthesis at homocysteine, makes the build fail. When a cycle
appears, ask which boundary is the weakest biological claim rather than
deleting an edge to satisfy the validator.

### Compartment and transport

Every anchor carries two extra fields:

```text
molecule      stable identity shared by the compartment variants of one substance
compartment   extracellular | cytoplasmic | unspecified
```

This exists so that depolymerising a polymer outside the cell, importing the
product, and saccharifying it inside can be told apart. Those are different
ecological strategies — public-goods degrader, selfish forager, cross-feeder —
and they are invisible if every boundary molecule is compartment-blind.

**Compartment is a curated boundary claim, not a genomic inference.** A KO or
CAZy family identifies chemistry, not localisation, and a signal peptide is not
an accession. Two cases are intrinsic and need no genomic claim: a polymer is
extracellular because nothing imports it, and a transporter is membrane-located
because that is what a transporter is. Everything else is a curation judgement
about the substrate class, recorded in the GIFT's notes.

Split an anchor by compartment only when both hold:

- the substrate can physically occupy both locations, and
- substrate-specific transporter markers exist to evidence the crossing.

Otherwise leave the chemistry `unspecified`. An unevidenced transporter made
into a required reaction would silently break an otherwise complete catabolic
chain, turning a missing annotation into a false negative for the whole
capability.

A GIFT with `mode = transport` must declare the same `molecule` as both input
and output; that is what distinguishes moving a substance from changing it. The
validator enforces it, and warns when a GIFT translocates without saying so.

Composition edges account for unresolved compartments:

| Output anchor | Input anchor | Edge |
|---|---|---|
| same anchor | same anchor | `exact` |
| same molecule, one side `unspecified` | | `compartment_inexact` |
| same molecule, both specified and different | | none |

The third row is what keeps transport meaningful: extracellular glucose reaches
cytoplasmic glucose only through an uptake GIFT. The second row keeps an
unresolved boundary from breaking a chain, while `gift_graph()` reports
`edge_quality` so a traversal that crossed one is not mistaken for a fully
resolved claim.

### Linking to external pathways

A GIFT is not a pathway record, but users arrive from the resources they
already know. `gift_xrefs.tsv` links a GIFT to an external pathway together
with a required `relation`:

| Relation | Meaning |
|---|---|
| `equivalent` | Same capability between the same boundaries |
| `subset_of` | The GIFT is part of the external pathway |
| `superset_of` | The GIFT covers the external pathway and more |
| `overlaps` | Partial overlap in both directions |
| `related` | Biologically adjacent context, no shared-chemistry claim |

The relation is part of the biological claim. KEGG M00018 is `subset_of` for
three different GIFTs because giftr cuts it at two branchpoints, and
`cysteine_biosynthesis_homocysteine` is `superset_of` M00338 while only
`overlaps` M00609. Never record a link that implies an equivalence the declared
anchors do not support.

The namespace is an open vocabulary, like marker namespaces. `KEGG_MODULE` and
`KEGG_PATHWAY` are curated today; other resources can be added without a schema
change. Do not record an accession that has not been verified against the
resource it names.

Read the links with `get_gift_pathways()`, and go the other way — from a
pathway identifier to the GIFTs that relate to it — with
`gifts_for_pathway()`.

## Reaction chemistry

### Rhea master IDs and contextual direction

Rhea is the preferred canonical source for biochemical reaction identity.
Store the Rhea master reaction ID in `reactions.tsv`, for example
`RHEA:15753`. Store how a route uses that chemistry in
`route_reactions.tsv`:

```text
rhea_master = RHEA:15753
orientation = forward
```

Do not model forward and reverse directional Rhea IDs as unrelated reactions.
Reaction identity belongs to the reaction; pathway direction belongs to the
route/reaction relationship.

External cross-references such as KEGG reaction IDs or EC numbers belong in
`reaction_xrefs.tsv`. They aid provenance and lookup but do not replace the
canonical reaction identity.

### Runtime chemistry boundary

giftr may query or import Rhea chemistry while constructing and validating
the database. It should not duplicate Rhea's complete metabolite and
stoichiometric graph into the runtime database without a concrete need. The
runtime ontology needs the curated anchor boundaries and the reaction IDs that
connect them, not a second metabolic model.

## Enzyme systems and components

Never assume `one reaction = one gene`. A reaction may have several alternative
enzyme systems, and a system may require one or several protein components.

```text
reaction
  +-- OR -- system A
  |           +-- component A
  |
  +-- OR -- system B
              +-- AND -- component B1
              +-- AND -- component B2
```

The reaction is supported if system A or system B is complete. System B is
complete only when both B1 and B2 are supported. The same schema handles
single-protein enzymes, heteromers, non-homologous alternatives, and other
replacements without special cases in R.

A multifunctional protein may support components in several systems or
reactions. Represent each justified component/marker relationship explicitly;
do not collapse the affected reactions into one marker-defined trait.

## Genomic markers and evidence

Markers are observations or annotation identifiers supporting enzyme
components. They are not themselves reactions, routes, or GIFTs.

Use the generic key:

```text
namespace + accession
```

Examples include:

```text
KO          K01939
EC          6.3.4.4
PFAM        PFxxxxx
TIGRFAM     TIGRxxxxx
CAZY        GHxx
CUSTOM_HMM  giftr_purA
```

Do not add a fixed column for every evidence system. Namespaced rows let new
marker systems enter without a core schema migration.

`component_markers.tsv` records the type, confidence, source, and notes for the
mapping. Use defined qualitative confidence terms such as `curated`,
`high-confidence`, `putative`, `ambiguous`, or `insufficient evidence` when
appropriate. Do not invent numeric confidence scores unless their meaning and
calibration are documented.

Confidence reaches the call. `evaluate_gifts()` reports `evidence_confidence`
per GIFT: the weakest term among the markers supporting the best route. A call
is only as good as its weakest accepted marker, and a GIFT resting on an
ambiguous polyspecific family must not read like one resting on curated
orthology. The terms are ordered, never averaged into a score.

Marker specificity bounds trait specificity (invariant 16). A marker that cannot
distinguish one substrate from another licenses only the broader capability, and
a trait must not be named for a substrate its evidence cannot single out. The
cost of breaking this is not confined to the trait in question: an over-broad
marker also matches the neighbouring traits, so accepting it equates them.
Pseudolysin is the worked case -- EC 3.4.24.26 hydrolyses elastin, collagen,
fibronectin and IgA, so admitting it as evidence of elastin cleavage would also
license a collagen call from a genome carrying no collagenase, and the two
traits would cease to be distinguishable. Where no marker reaches the required
specificity, refuse the trait and record why; see
[the protein degradation proposal](proposal-protein-degradation.md).

Sequence-family namespaces need particular care because a family is not an
activity. CAZy families such as GH5, GH13, GH30 and GH43 are polyspecific;
accepting the bare family as evidence for one of its activities silently
attributes the others. Prefer the subfamily accession where dbCAN reports one,
accept a bare family only where it is effectively monoactivity, record the
reason in `notes`, and mark the mapping `ambiguous` when it is.

When gene identifiers are provided during evaluation, retain them through the
evidence trace. Multiple markers supporting one component are OR alternatives;
they are not implicitly separate required genes.

## Reference database schema

### Logical model

The normalized model has two complementary paths:

```text
anchor -> GIFT -> anchor

marker -> component -> enzyme system -> reaction -> route -> GIFT
```

The reviewable source uses plural TSV filenames. The compiled SQLite database
uses singular table names and internal integer primary keys. Stable public IDs
remain present in both forms.

| Source file | Runtime table | Purpose and stable key |
|---|---|---|
| `gifts.tsv` | `gift` | Biological claim; `gift_id`, with `mode` |
| `anchors.tsv` | `anchor` | Curated boundary molecule; `anchor_id`, `molecule` + `compartment`, usually with `chebi_id` |
| `gift_anchors.tsv` | `gift_anchor` | Input/output role and ordinal for each GIFT boundary |
| `gift_xrefs.tsv` | `gift_xref` | Related external pathway and how the curated boundaries compare |
| `reactions.tsv` | `reaction` | Canonical chemistry; `reaction_id`, with `rhea_master` where Rhea covers it |
| `reaction_xrefs.tsv` | `reaction_xref` | Namespaced external reaction cross-references |
| `gift_routes.tsv` | `gift_route` | Alternative minimal route; `route_id` |
| `route_reactions.tsv` | `route_reaction` | Ordered route membership, orientation, and required flag |
| `enzyme_systems.tsv` | `enzyme_system` | Alternative catalyst implementation; `system_id` |
| `enzyme_components.tsv` | `enzyme_component` | Required protein within a system; `component_id` |
| `markers.tsv` | `marker` | Reusable genomic evidence; `namespace + accession` |
| `component_markers.tsv` | `component_marker` | Evidence mapping with source and confidence |
| `database_changes.tsv` | `database_change` | Curation history entry; `change_id` |
| `change_gifts.tsv` | `change_gift` | GIFTs a recorded change affects |
| `database_release.tsv` | `database_release` | Database, schema, upstream-source, date, and commit metadata |

The SQL contract is in `inst/schema/giftr.sql`; the compiler and structural
validator are in `R/database-build.R`.

### Stable identifiers and foreign keys

Stable IDs are curator-facing and should not be changed casually. Internal
SQLite primary keys are compilation details. All relationships must resolve to
an existing parent, and the compiled database must pass SQLite foreign-key and
integrity checks.

When an entity's biological identity changes substantially, consider a new ID
and a documented deprecation rather than silently reusing an old stable ID for a
different claim.

### Source of truth and provenance

The version-controlled TSV files in `inst/extdata/database-source` are the
biological source of truth. `inst/extdata/giftr.sqlite` is generated output.
Never curate the SQLite file directly.

Provenance can come from Rhea, ChEBI, KEGG, MetaCyc, UniProt, primary literature,
curated HMM collections, or expert curation. Record what each source actually
supports:

- Rhea defines reaction chemistry.
- ChEBI identifies an anchor molecule.
- KEGG or MetaCyc may suggest a pathway organization or cross-reference.
- UniProt, HMM resources, or literature may support enzyme/marker mappings.
- giftr chooses the capability, boundaries, accepted routes, and curation
  interpretation.

Do not imply that an upstream database endorses a giftr-specific boundary or
trait interpretation. Dataset-level sources and deliberate curation choices are
documented in `inst/extdata/database-source/SOURCES.md`; row-level evidence is
kept in the relevant source columns.

## Curating a new or changed GIFT

### 1. Define the biological claim

Write one sentence that states what a positive call means. Explain why the
capability is useful in ecological, evolutionary, physiological, or host
contexts. If the statement contains multiple independently meaningful claims,
consider splitting it.

### 2. Choose and defend the boundaries

Identify every input and output anchor. Reuse an existing anchor when it denotes
the same molecule and biological boundary. Ask:

- Where does trait-specific chemistry begin?
- Where is the first stable product or meaningful branchpoint?
- Does an internal branchpoint deserve its own composable GIFT?
- Would extending the endpoint drift into shared housekeeping metabolism?

Record the rationale in GIFT/anchor descriptions, notes, provenance docs, and
tests where it defines a durable invariant.

### 3. Curate reaction routes

Map the chemistry to Rhea master reactions and determine the contextual
orientation of each step. Identify every supported alternative biochemical
implementation. Materialize each valid minimal route as its own `gift_routes.tsv`
record with ordered rows in `route_reactions.tsv`.

Do not treat an upstream module as authoritative. Verify that its boundaries,
reaction chemistry, alternatives, and direction match the giftr claim.

### 4. Curate enzymes and components

For every reaction, enumerate alternative enzyme systems. For each system,
enumerate all jointly required protein components. Check specifically for:

- monomeric versus multisubunit forms;
- non-homologous enzyme replacements;
- multifunctional or fused proteins;
- taxon-specific alternatives;
- generic versus chemically specific reactions.

### 5. Curate marker evidence

Map namespaced markers to components, not directly to reactions or GIFTs.
Document evidence type, source, confidence, and ambiguity. A convenient marker
is not necessarily a specific marker; avoid overclaiming.

### 6. Check composition and redundancy

Inspect which existing GIFTs share the new input or output anchors. Decide
whether the proposal is atomic, a useful addition to the derived graph, a
composite already represented by a chain, redundant, or a candidate replacement
for an older definition.

### 7. Edit source tables in dependency order

A practical order is:

1. `gifts.tsv` and any new `anchors.tsv` rows;
2. `gift_anchors.tsv`, then `gift_xrefs.tsv`;
3. new `reactions.tsv` and `reaction_xrefs.tsv` rows;
4. `gift_routes.tsv` and `route_reactions.tsv`;
5. `enzyme_systems.tsv` and `enzyme_components.tsv`;
6. reusable `markers.tsv` rows and `component_markers.tsv` links;
7. `SOURCES.md` and `database_release.tsv`.

Reuse existing reactions, systems, components, and markers when they represent
the same entity. Never duplicate them merely to make a new route self-contained.

### 8. Validate, compile, test, and review

Run the source validator before compilation. Rebuild SQLite from the TSVs, run
logic and integration tests, and inspect the resulting GIFT with public
accessors. Confirm that its call can be traced to observed genes/markers and
that its graph edges arise only from declared anchors.

## Build and runtime workflow

The data lifecycle is:

```text
human-reviewable TSV sources
        |
        v
structural validation
        |
        v
SQLite compilation + integrity checks
        |
        v
read-only runtime queries and evaluation
```

Run from the package root:

```sh
Rscript data-raw/build_database.R
Rscript -e 'testthat::test_local(".")'
```

`data-raw/build_database.R` loads the development package, calls
`validate_giftr_sources()`, and compiles
`inst/extdata/giftr.sqlite` with `build_giftr_database()`. Compilation is
atomic: the intended output is replaced only after the new database passes
foreign-key and integrity checks.

Do not rebuild SQLite for a documentation-only edit. Do rebuild it whenever the
TSV source content, SQL schema, or compiler changes in a way that affects the
artifact.

### Structural errors and curator warnings

Validation errors mean the content cannot produce a coherent runtime database.
Current error classes include:

- missing source files or required columns;
- empty required identifiers;
- duplicate stable IDs or compound keys;
- broken references;
- a GIFT without input/output anchors or routes;
- a route without required reactions;
- invalid anchor roles, ordinals, directions, step order, or required flags;
- malformed Rhea master IDs;
- a reaction without a system, a system without a component, or a component
  without a marker;
- cycles in anchor-derived GIFT composition;
- unknown external pathway relations, and pathway links to unknown GIFTs;
- malformed or inconsistent release metadata.

Warnings should identify structurally valid content that still needs biological
review. Keep that distinction clear: a warning must not permit broken relational
structure, and an error should not be used merely because a curator judgment is
debatable.

## Versioning and releases

Three versions describe different things:

```text
giftr package version     code and public API release
giftr database version    biological content release
schema version               relational contract/migration level
```

For example:

```text
package:   2.3.1
database:  2027.04
schema:    2
```

A package release must not silently change biological definitions without
database provenance. A schema change requires an explicit schema-version bump
and coordinated updates to the SQL schema, TSV source specification, compiler,
validation, tests, and documentation. Update `database_release.tsv` with the
database version, schema version, build date, upstream resource releases, and
source commit. Keep upstream release identifiers distinct from giftr's own
curation release.

### Two changelogs

Biological history and code history are different records and are kept apart.

Every change to the biological content is a row in `database_changes.tsv`,
compiled into the `database_change` table and published in the HTML atlas. An
entry records the release it shipped in, a UTC timestamp, the hierarchy layer
it touched, whether it broadens, narrows or leaves GIFT calls unchanged, and
the rationale, evidence and effect behind the decision. `change_gifts.tsv`
names the GIFTs each change affects, so the history is readable from the trait
as well as from the release. Validation requires a linked GIFT for any change
to a gift, anchor, route, reaction, enzyme system, component, or marker;
provenance and schema entries may stand alone. Read it with
`database_changelog()`.

Package behaviour, public API, evaluation logic, and report changes belong in
`CHANGELOG.md` at the repository root. Do not record biological decisions
there, and do not record code decisions in the database.

## Code architecture

### Biological content belongs in data

R code implements general operations:

- retrieve GIFTs, anchors, routes, reactions, and enzyme definitions;
- normalize and map genomic markers;
- evaluate components, systems, reactions, routes, and GIFTs;
- report closest incomplete routes;
- trace evidence;
- derive the GIFT topology.

Never introduce per-GIFT conditionals containing required genes or reactions.
Adding a GIFT should normally be a database-content change plus tests, not an R
branch.

### SQLite is an implementation detail

The runtime database uses DBI and RSQLite, but relational concepts should remain
reasonably backend-independent. Keep connections and queries behind a small
internal API. Public users should work with GIFT concepts, not internal SQL
primary keys.

Normalize first. If profiling finds a bottleneck, consider an index, cached view,
or compiled lookup table without erasing the biological layers from the source
model.

### Concept-oriented public API

Preferred operations include:

```r
list_gifts()
get_gift()
get_gift_anchors()
get_gift_pathways()
gifts_for_pathway()
get_gift_routes()
get_gift_reactions()
get_reaction_systems()
map_markers()
evaluate_reactions()
evaluate_gifts()
trace_gift()
gift_graph()
```

These functions form a conceptual API that may outlive the current SQLite
implementation. Preserve their clarity, deterministic ordering, and audit
information when changing internals.

### Traceability is a feature, not debug output

A user must be able to navigate:

```text
GIFT call
  -> chosen or complete route
  -> required and missing reactions
  -> candidate enzyme systems
  -> required components
  -> accepted and observed markers
  -> supplied gene IDs
```

Any evaluation change must preserve or improve that path. A correct Boolean
answer without the evidence responsible for it is incomplete behavior.

## Testing strategy

Tests should encode the biological invariants directly. At minimum, protect:

```text
GIFT            = ANY complete route
route           = ALL required reactions
reaction        = ANY complete enzyme system
enzyme system   = ALL required components
component       = ANY accepted marker
```

Also test that:

- alternative routes complete independently;
- a protein complex fails when any required component is absent;
- an alternative enzyme system can support the same reaction;
- a multifunctional marker supports each justified component mapping;
- reaction orientation is retained per route;
- missing-reaction calculations and route ties are deterministic;
- trace output contains the genes/markers responsible for the call;
- GIFT graph edges use only declared anchors;
- internal intermediates never create topology;
- compartment-split anchors compose only through a transport GIFT, and an
  unresolved compartment traverses as a flagged inexact edge;
- composition cycles are rejected within a mode and accepted between modes;
- a call reports the weakest confidence among the markers behind it;
- source identifiers and references validate;
- compiled SQLite foreign keys and integrity hold;
- package, database, and schema versions remain distinguishable.

Use small synthetic fixtures for Boolean logic. Use curated biological examples
as integration tests. Tests that only check for a data-frame class or nonzero row
count are insufficient when the biological interpretation can regress.

Relevant test locations are:

- `tests/testthat/test-evaluation.R` for the evidence hierarchy and calls;
- `tests/testthat/test-composition.R` for anchor-derived topology;
- `tests/testthat/test-compartment.R` for compartment, mode, and edge quality;
- `tests/testthat/test-reaction-identity.R` for reaction identity and
  cross-reference requirements;
- `tests/testthat/test-database.R` for validation, compilation, accessors, and
  versions;
- `tests/testthat/helper-markers.R` for small marker fixtures, and
  `helper-sources.R` for mutating a copy of the source tables.

## Migration of legacy definitions

Do not migrate old distillR traits mechanically. For each legacy definition,
ask:

1. What capability was intended?
2. Which input and output anchors defend that meaning?
3. Does it mix independently useful capabilities?
4. Which Rhea reactions connect the boundaries, and in which direction?
5. Are there alternative routes or alternative enzymes?
6. Which components are jointly required?
7. Which markers support those components, and how strong is the evidence?
8. Is the trait redundant with an existing GIFT or graph path?
9. Should it be split, merged, composed, deprecated, or re-curated?

Useful migration labels are:

```text
direct migration
boundary curation required
reaction mapping required
enzyme curation required
candidate split
candidate merge
candidate composite
redundant
deprecated
```

Preserve semantic compatibility where biologically justified, but do not retain
an incoherent historical definition merely because it already exists.

## Canonical examples

### Purine core biosynthesis: PRPP to IMP

Claim: the genome encodes a complete de novo enzymatic route constructing the
purine nucleotide core from PRPP to IMP.

`PRPP` is the shared precursor before trait-specific purine chemistry. `IMP` is
the stable purine core and a meaningful branchpoint. Alternative biochemical
routes are separate route records. Their internal metabolites are not anchors.

### Adenylate biosynthesis: IMP to AMP

Claim: the genome encodes the machinery required to convert IMP to AMP through
adenylosuccinate synthetase and adenylosuccinate lyase chemistry.

`IMP` is the input branchpoint; `AMP` establishes adenylate identity. The GIFT
does not continue automatically to ADP or ATP because generic nucleotide
phosphorylation is not required to establish this capability.

### Guanylate biosynthesis: IMP to GMP

Claim: the genome encodes the machinery required to oxidize IMP to XMP and
aminate XMP to GMP.

`IMP` is the shared purine branchpoint; `GMP` establishes guanylate identity.
As for adenylate biosynthesis, the GIFT does not continue to GDP or GTP because
generic nucleotide phosphorylation is shared metabolism rather than part of
the branch-specific capability.

### Composition: purine core to adenylate and guanylate branches

The output anchor of purine core biosynthesis and the input anchors of both
purine branch GIFTs are `IMP`. The derived graph therefore contains:

```text
purine_core_biosynthesis --IMP--> adenylate_biosynthesis
purine_core_biosynthesis --IMP--> guanylate_biosynthesis
```

When the corresponding atomic GIFTs are complete, the supported chains are
`PRPP > IMP > AMP` and `PRPP > IMP > GMP`. No separate copy of the purine-core
reactions is needed.

These examples are architectural fixtures. Preserve them when changing
boundaries, graph derivation, route logic, or evidence tracing unless a deliberate
and documented biological decision supersedes them.

## Decision framework

When several implementations are possible, prefer the one that:

1. preserves a clear biological interpretation;
2. minimizes duplicated biological definitions;
3. separates chemistry, enzymology, and genomic evidence;
4. supports alternative biological implementations explicitly;
5. remains auditable from GIFT to gene;
6. avoids unnecessary metabolic-model complexity;
7. makes future curation easier;
8. keeps the GIFT abstraction visible in code and documentation.

The north-star question is:

> Does this change make it easier to state, defend, test, and trace the claim
> that a genome encodes a particular biologically meaningful capability?

If not, reconsider the design.

## Glossary

- **Anchor:** A curated input or output molecule defining a GIFT boundary. Only
  anchors connect GIFTs.
- **Component:** One required protein role within an enzyme system. Any accepted
  marker may support a component.
- **Enzyme system:** One complete catalytic implementation of a reaction. It may
  contain one or several jointly required components.
- **GIFT:** A directed, biologically meaningful genome-inferred capability
  between declared anchors, complete when any valid route is complete.
- **Internal intermediate:** A reaction participant inside a route that is not a
  declared anchor and cannot connect GIFTs.
- **Marker:** A namespaced genomic observation or annotation accession used as
  evidence for a component.
- **Reaction:** A biochemical transformation identified preferentially by a
  Rhea master ID. Its direction within a capability is stored on route
  membership.
- **Route:** A curated minimal set of required reactions that connects a GIFT's
  declared boundaries. Routes are alternatives under OR logic.
- **Traceability:** The ability to explain a GIFT result through route, reaction,
  enzyme system, component, marker, and supplied gene evidence.
