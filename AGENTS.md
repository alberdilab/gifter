# gifter agent instructions

These instructions apply to the entire repository. They define how automated
agents should change gifter. The detailed rationale, schema reference, and
curation procedures live in [the development and architecture guide](inst/doc/architecture.md).

## Mission

gifter infers **genome-inferred functional traits (GIFTs)** from genomic
evidence. A GIFT is a biologically meaningful capability whose genomic support is
evaluated through an explicit, curated and traceable completeness model. Every
GIFT declares a `gift_type`, which names that model:

```text
GIFT
├── metabolic     directed capability between curated molecular anchors
├── structural    machinery to build a defined cellular structure
├── regulatory    machinery to sense a signal and execute a response
└── defense       machinery to execute a defined defense mechanism
```

`gift_type` is not a facet. A facet classifies a call; `gift_type` decides which
completeness model produces one, which source tables may attach to the GIFT, and
what a positive call is allowed to mean. It belongs to the core ontology and to
the relational contract.

A positive **metabolic** call means that the available markers support at least
one complete known enzymatic route between the declared boundaries. A positive
**structural**, **regulatory** or **defense** call means that they support at
least one complete curated architecture, circuit or defense mechanism. In no
case does a positive call mean expression, activity, physiological state, actual
motility, an actual defense outcome, environmental relevance, or phenotype.

Keep gifter in the space between marker checklists and genome-scale metabolic
models. It should be biologically explicit, composable, traceable,
curator-friendly, and focused on what a genome encodes.

gifter does not infer whether a capability is active in a particular
environment. Do not add growth, flux balance analysis, thermodynamics, media,
metabolite concentrations, exchange reactions, biomass equations, or complete
runtime stoichiometry without an explicit architectural decision.

One such decision has been taken. Declared anchors carry a two-state
`compartment` qualifier, so that transport and extracellular chemistry can be
stated explicitly. This is deliberately narrow: the qualifier applies to
anchors only, never to reactions, internal intermediates or markers, and
gifter still models no membrane potential, transport stoichiometry, proton
coupling, compartment-aware mass balance, or intracellular metabolite
inventory. Compartment is a curated boundary claim, not a genomic inference —
markers identify chemistry, not localisation.

## Start every task this way

1. Inspect the relevant R code, database source tables, schema, tests, and
   documentation before editing.
2. Classify the change as code, biological content, schema, public API,
   documentation, or a combination. A database-content change is not merely a
   data-entry task; it changes biological claims.
3. State the biological or architectural invariant the change must preserve.
4. Make the smallest coherent change. Preserve unrelated work in the worktree.
5. Add or update tests that exercise the biological behavior, then run the
   checks appropriate to the files changed.
6. Document any changed biological meaning, boundary choice, provenance,
   schema contract, or user-visible behavior.

Do not perform broad refactors just because another design looks cleaner in
isolation. Preserve compatibility when it does not compromise the model below.

## The evaluation contract

Every type keeps five Boolean layers. For a metabolic GIFT:

```text
metabolic GIFT  = ANY complete route
route           = ALL required reactions
reaction        = ANY complete enzyme system
enzyme system   = ALL required components
component       = ANY accepted genomic marker
```

For a structural, regulatory or defense GIFT, under its own names:

```text
structural GIFT = ANY complete architecture
architecture    = ALL required structural functions
structural fn   = ANY complete system
system          = ALL required components
component       = ANY accepted genomic marker
```

The complete evidence path is:

```text
observed marker
  -> component
  -> system
  -> reaction | structural, regulatory or defense function
  -> route | architecture, circuit or mechanism
  -> GIFT
```

Do not collapse adjacent layers. They separately represent alternative
markers, multisubunit machines, alternative implementations, required elements,
and alternative complete designs.

The three non-metabolic models are kept as parallel, biologically named table
families. Their Boolean shape is the same; a structural function, a regulatory
function and a defense function are not the same biological object. Share
lower-level evaluation code where the semantics really are identical -- marker
matching, component support, system AND logic, confidence ordering, determinism,
result assembly -- and do not merge the data model on the strength of shape
alone. Revisit that only once all three carry curated content.

## Non-negotiable biological invariants

1. A GIFT is a biological capability, not a KEGG module, pathway identifier,
   KO list, EC list, or gene name. It may be *linked* to external pathways in
   `gift_xrefs.tsv`, but every link must state how the curated boundaries
   compare with the external record: `equivalent`, `subset_of`, `superset_of`,
   `overlaps`, or `related`. Never record a link that implies an equivalence
   the boundaries do not support.
2. Declared anchors define GIFT boundaries and are the only way GIFTs connect.
   Shared internal reaction participants never create GIFT edges.
3. Keep the anchor vocabulary small. Add an anchor only when it is a meaningful
   boundary, branchpoint, environmental or host compound, precursor, or stable
   product—not merely because it occurs in a reaction.
4. Identify a reaction by its stable `reaction_id`, which is the Rhea master ID
   wherever Rhea covers the chemistry. A reaction without a Rhea master must
   carry at least one cross-reference. Store the route's `forward` or `reverse`
   orientation separately.
5. Treat markers as evidence for enzyme components, never as traits or reactions
   directly. Marker identity is the extensible pair `namespace + accession`.
6. Represent alternative routes, alternative enzyme systems, multisubunit
   systems, multifunctional proteins, and non-homologous replacements
   explicitly in their proper layers.
7. Call completeness from route logic, not a percentage of expected genes or
   markers. Incomplete results should identify the closest route and missing
   reactions. Scores may be secondary summaries only.
8. Build larger capabilities by composing GIFTs through shared declared anchors.
   Do not duplicate an atomic GIFT's reactions in a larger trait. Composition
   may not cycle within a **directed** `mode`; it is expected to cycle between
   modes, because a catabolic route back to a metabolite biosynthesis produces
   is real biology rather than a boundary error. `interconversion` is exempt:
   that mode declares every anchor in both roles, so two adjacent reversible
   GIFTs cycle by construction and the loop says nothing about the boundaries.
   A cycle that survives those rules is real circular metabolism -- the
   oxidative citric acid cycle is one -- and it is **derived** by
   `gift_cycles()` from the anchor graph, never curated as a circuit table.
   Only its name is curated, in the `metabolic_cycle` facet, and whether a
   genome closes it never changes a member's Boolean call.
9. Keep GIFTs biologically useful: neither arbitrary single-step fragments nor
   bundles of independently meaningful capabilities.
10. Keep biological definitions in the reference database, never in per-GIFT R
    conditionals.
11. Preserve traceability from every GIFT call to routes, reactions, systems,
    components, observed markers, and gene identifiers when supplied.
12. Preserve provenance and distinguish facts imported from external resources
    from gifter's own boundary and route curation decisions.
13. Version the package, biological database, and database schema separately.
14. Treat SQLite as a compiled runtime artifact and implementation detail, not
    the biological ontology or hand-edited source of truth.
15. Express uncertainty honestly. A supported route does not prove expression,
    activity, physiological flux, substrate availability, or phenotype.
16. The specificity of any GIFT claim must not exceed the specificity supported
    by its genomic evidence. This is type-independent: a broad CAZy family
    cannot license a substrate-specific metabolic trait, a stator accession
    shared by MotA and PomA cannot identify proton versus sodium coupling, a
    generic chemoreceptor cannot identify a chemoeffector, and a generic Cas
    protein cannot license a CRISPR subtype. A marker that cannot distinguish one substrate from
    another licenses only the broader trait. Two consequences: a generic
    activity marker never supports a substrate-specific claim -- peptide-bond
    hydrolysis is not evidence of collagen cleavage, and a polyspecific glycoside
    hydrolase family is not evidence for one of its activities -- and accepting
    an over-broad marker damages the *other* traits it also matches, by silently
    equating them with the one it was accepted for. Where a trait cannot be
    evidenced at the specificity its name implies, refuse it and record the
    refusal rather than widening the marker.

17. `gift_type` selects the completeness model and bounds the claim. A metabolic
    GIFT uses the anchor/route model and must declare anchors, routes and a
    `mode`. A structural, regulatory or defense GIFT uses its own machinery
    model and must not declare anchors, routes or a `mode` -- inventing a
    boundary molecule so that a structure fits the metabolic schema is a
    boundary claim nobody can defend, and the build rejects it.
18. Do not create a primary GIFT type for a higher-order ecological or
    phenotypic description -- motility, virulence, host association, ecological
    strategy, cross-feeding, competition, public-good behaviour, community
    resilience. Derive those from combinations of primary typed GIFTs, as
    `gift_profile` already derives resource strategy from curated anchors.
19. Adding a GIFT type is an architectural decision. A new type arrives with a
    stated completeness contract, its own validation rules, and a curated or
    fixture-backed example. Do not register a type with nothing behind it.
20. A quantitative trait derived from GIFT calls states its reference universe,
    and the universe is built from curated metadata -- `gift_type`, `mode`,
    facets, `gift_profile` -- never from a list of `gift_id`s written in R.
    No proportion without an explicit denominator; no fraction of the catalogue
    unless the universe was declared `bounded`, which is a claim that curation
    intends to cover that set completely. The database is not the universe of
    microbial function.
21. Presence, abundance and context are three axes and never one number. Genome
    quality modifies the reading of absence only: nothing may convert an
    unsupported GIFT into a supported one, and indeterminacy is resolved per
    genome.
22. A community interaction edge comes only from compatibility semantics
    already in the database, inherits the `edge_quality` of the GIFT edge
    beneath it, and crosses organisms only through an anchor declared
    `extracellular`. A cytoplasmic or unspecified anchor stays inside one cell.
    Never infer interaction from functional overlap or co-occurrence.
23. Every derived number retains the GIFTs, genomes and anchors that produced
    it. Prefer interpretable components to composite indices, and add a
    composite only when it is clearer than its ingredients. A derived trait
    describes encoded capability, never activity, flux, phenotype or ecological
    effect.

See [Core concepts](inst/doc/architecture.md#core-concepts-and-scope),
[GIFT types](inst/doc/architecture.md#gift-types),
[The machinery model](inst/doc/architecture.md#the-machinery-model),
[Evaluation logic](inst/doc/architecture.md#evaluation-logic), and
[Boundaries and composition](inst/doc/architecture.md#gift-boundaries-anchors-and-composition),
and [Quantitative traits](inst/doc/architecture.md#quantitative-traits)
for examples and rationale.

## Work in the correct files

| Change | Primary files | Also inspect |
|---|---|---|
| GIFT type or a new capability type | `gifts.tsv`, `inst/schema/gifter.sql`, `R/database-build.R` | `.gifter_machinery_models`, type tests, architecture guide |
| Structural GIFT content | `gift_architectures.tsv`, `architecture_functions.tsv`, `structural_functions.tsv`, `structural_systems.tsv`, `structural_components.tsv`, `structural_component_markers.tsv` | `test-structural.R`, `proposal-structural-gifts.md`, provenance |
| Regulatory or defense content | `gift_circuits.tsv`/`gift_mechanisms.tsv` and their `regulatory_*`/`defense_*` tables | the matching proposal document, `test-regulatory-defense.R` |
| GIFT boundaries or metadata | `gifts.tsv`, `anchors.tsv`, `gift_anchors.tsv` | routes, composition tests, provenance |
| Compartment, transport, or GIFT mode | `anchors.tsv`, `gifts.tsv` | graph edge quality, mode-aware cycle check, compartment tests |
| Cyclic metabolism or graph topology | `R/cycles.R`, `gift_facets.tsv` | `proposal-central-metabolic-cycles.md`, `test-central-cycles.R`, `test-composition.R` |
| Related external pathways | `gift_xrefs.tsv` | the relation must match the curated boundaries |
| Reaction routes or direction | `reactions.tsv`, `reaction_xrefs.tsv`, `gift_routes.tsv`, `route_reactions.tsv` | Rhea evidence, evaluation tests |
| Enzymes or marker evidence | `enzyme_systems.tsv`, `enzyme_components.tsv`, `markers.tsv`, `component_markers.tsv` | provenance, complex/alternative tests |
| Source validation or compilation | `R/database-build.R`, `inst/schema/gifter.sql` | every source table, database tests, version metadata |
| Runtime queries or public accessors | `R/database.R` | schema, generated `.Rd` files, database tests |
| Evaluation behavior or traceability | `R/evaluation.R` | Boolean invariants, synthetic fixtures, evaluation tests |
| Quantitative genome or community traits | `R/universe.R`, `R/traits.R`, `R/community.R`, `R/community-network.R`, `R/assessability.R`, `reference_universes.tsv`, `reference_universe_filters.tsv`, `reference_universe_metrics.tsv` | `proposal-quantitative-traits.md`, schema/compiler, reference universes, denominators, trait tests |
| GIFT graph or database reports | `R/database-visualization.R` | declared-anchor behavior, composition tests |
| Biological source provenance | `inst/extdata/database-source/SOURCES.md`, `database_release.tsv` | affected TSV records |
| Architecture or curator guidance | `AGENTS.md`, `inst/doc/architecture.md`, `README.md` | behavior and links remain consistent |
| User-facing tutorials | `vignettes/*.Rmd` | every chunk executes at `R CMD check`; illustrative marker sets are labelled as fixtures, never presented as annotation output from a named organism |
| Biological curation decisions | `database_changes.tsv`, `change_gifts.tsv` | affected GIFTs, `database_release.tsv`, atlas changelog view |
| Code, API, or report decisions | `CHANGELOG.md` | the entry states change, reason, and effect |

The reviewable database source is
`inst/extdata/database-source/*.tsv`. The compiled
`inst/extdata/gifter.sqlite` must never be edited manually. Change TSVs,
validate them, and rebuild the database.

## Rules for biological curation

Before adding or redefining a GIFT, be able to answer:

- Which `gift_type` is this, and does the capability actually fit that type's
  completeness contract?
- What exact capability is claimed, and why is it useful to infer from a genome?
- What are the input and output anchors, and why are they the right biological
  cut points?
- Should a branchpoint split this into composable GIFTs?
- Which Rhea master reactions connect the boundaries, in which direction, and
  through which alternative minimal routes?
- Which alternative enzyme systems catalyse each reaction, and which components
  are jointly required?
- Which namespaced markers support each component, with what provenance and
  confidence?
- Which existing GIFTs connect through the declared anchors, and would the new
  definition duplicate or supersede one?

For a non-metabolic GIFT the equivalent questions are: which alternative
complete implementations exist, which functional modules does each require,
which systems and jointly required components implement each function, are the
markers specific enough for the claim as named, and what does the claim
deliberately exclude.

If these questions cannot be answered, stop at a documented curation proposal;
do not manufacture a precise implementation from ambiguous biology. Three such
proposals exist and are the model to follow:
[structural](inst/doc/proposal-structural-gifts.md),
[regulatory](inst/doc/proposal-regulatory-gifts.md), and
[defense](inst/doc/proposal-defense-gifts.md). Recording a refusal with its
evidence is a result, not a gap. The full
procedure is in [Curating a GIFT](inst/doc/architecture.md#curating-a-new-or-changed-gift).

Materialize alternative valid minimal routes during curation. Do not store or
parse compact expressions such as `R1 AND (R2 OR R3)` at runtime.

## Rules for R and database code

- Implement general operations over the hierarchy. Never add logic such as
  `if (gift == "purine_core") required_genes <- ...`.
- Keep the public API concept-oriented (`list_gifts()`, `get_gift_routes()`,
  `evaluate_gifts()`, `trace_gift()`, `gift_graph()`). Do not require users to
  understand SQL keys.
- Encapsulate database access through the small internal DBI API. Avoid spreading
  SQLite-specific assumptions when a relational operation will do.
- Prefer normalized source concepts. Add indexes, views, or caches only for a
  demonstrated read-path benefit; do not denormalize away biological meaning.
- Keep results deterministic, especially closest-route selection and missing
  reaction reporting.
- Preserve evidence rows and gene IDs through transformations. An unexplained
  classification is a regression even if its final `complete` value is correct.
- Treat schema changes as migrations: update the SQL schema, source specification,
  compiler, validation, schema version, tests, and documentation together.

## Test biological behavior

Tests must protect the ontology, not merely assert that a function returns a
data frame. Depending on the change, cover:

- OR across routes, systems, and markers;
- AND across required reactions and components;
- incomplete-route selection and missing-reaction output;
- multi-component and alternative enzyme systems;
- multifunctional markers;
- route-specific reaction direction;
- composition only through declared anchors;
- trait specificity bounded by evidence specificity, in every type, including the
  negative case that a broad marker does not fire a specific GIFT;
- the typed contract: unknown types rejected, typed rows refused on the wrong
  GIFT type, structural GIFTs refused anchors, routes and a mode;
- alternative implementations, jointly required functions, alternative systems,
  multisubunit failure, and accessory functions in the machinery models;
- mixed-type evaluation in one call, and no metabolic regression from the
  migration;
- absence of implicit edges through internal metabolites;
- evidence tracing back to observed markers and genes;
- stable identifiers, foreign keys, source validation, and independent version
  fields;
- for derived quantitative traits: every proportion's denominator, that a
  fraction of the catalogue is withheld for an unbounded universe, that no
  assessability policy promotes an unsupported GIFT to supported, and that a
  cross-genome edge never carries a molecule that stays inside a cell.

Use small synthetic fixtures for logic tests. Retain `PRPP > IMP`, `IMP > AMP`,
and their `PRPP > IMP > AMP` composition as integration examples.

## Validation and rebuild commands

Run the narrowest relevant checks during development, followed by the full test
suite for changes to code, schema, or biological content.

```sh
# Validate TSV sources and rebuild the packaged SQLite artifact
Rscript data-raw/build_database.R

# Run package tests
Rscript -e 'testthat::test_local(".")'

# Full package check before release-level changes. Check the built tarball, not
# the source directory: DESCRIPTION declares authorship through `Authors@R`, and
# the `Author`/`Maintainer` fields it implies are derived by `R CMD build`. A
# check run against the directory therefore fails on missing fields that the
# built package has.
R CMD build .
R CMD check --no-manual gifter_*.tar.gz
```

Documentation-only changes do not require rebuilding SQLite. Biological source
changes are incomplete until source validation, database compilation, and the
relevant tests pass. A schema or release change must also update
`database_release.tsv` as described in
[Versioning and releases](inst/doc/architecture.md#versioning-and-releases).

## Completion standard

Before handing off a change, verify that:

- the biological claim and its boundaries remain clear;
- no biological definition was duplicated or hard-coded;
- alternatives and complexes use the correct Boolean layer;
- provenance and version implications were handled;
- every changed behavior is traceable and tested;
- the SQLite artifact, when affected, was generated from validated TSV sources;
- documentation explains why a biological or architectural decision changed;
- the decision is recorded with a UTC timestamp, its evidence, and its effect:
  biological changes as a `database_changes.tsv` entry linked to the GIFTs it
  affects, code changes in `CHANGELOG.md`;
- unrelated user changes were not overwritten.

When uncertain, prefer the design that makes it easiest to state, defend, test,
and trace the claim that a genome encodes a biologically meaningful capability.
