# giftr package changelog

Code, public API, evaluation logic, and report changes. Newest first.
Timestamps are UTC.

**Biological database changes are not recorded here.** They live in the
database itself, as `inst/extdata/database-source/database_changes.tsv` and
`change_gifts.tsv`, linked to the GIFTs they affect. Read them with
`database_changelog()`, or open the Changelog view of the HTML atlas. That
separation is deliberate: a biological decision is versioned with the content
it describes and travels with the compiled database, while a code decision is
versioned with the package.

---

## Package 0.1.0 (in development)

### 2026-08-18T12:00Z — Regulatory and defense models gain curated content

**Change.** Five GIFTs are curated, filling the two typed models that shipped
with schema only: `chemotaxis_signal_transduction`, `aspartate_chemoreception`
and `phosphate_starvation_response` (regulatory), and
`type_i_restriction_modification` and `type_i_e_crispr_cas_machinery`
(defense). Database version moves to 2026.12.3. **The schema is unchanged at
version 6** — this is a content release, which is the point: adding a
capability of an existing type is a data change plus tests, not an R branch.

**Code.** One line: `.giftr_required_gift_facets` now requires
`regulatory_class` of regulatory GIFTs and `defense_class` of defense ones, and
`facet_terms.tsv` registers the four values those two vocabularies use. Each
vocabulary was registered when the first content of its type was curated, not
ahead of it. No evaluator, validator or accessor change was needed.

**Why these five.** They were the sequence the type proposals recommended, and
each was blocked on a question that was then answered by measurement rather than
assumption:

- *Chemotaxis* needed no evidence the marker model lacks, and immediately
  exercises the specificity invariant. Requiring the generic chemoreceptor
  accession K03406 would have called *Escherichia coli* K-12 receptor-less — it
  carries none, its four receptors being assigned to characterised groups —
  while *Vibrio cholerae* carries 34. The reception function therefore accepts a
  generic *or* a characterised chemoreceptor.
- *Phosphate response* was blocked on whether orthology distinguishes a cognate
  PhoR/PhoB pair from a genome full of paralogous kinases and regulators. Gene
  counts across nine reference genomes showed the sensor single-copy where
  present and the two regulator groups mutually exclusive, with the *Bacillus*
  pair adjacent in the genome. That answer split one capability into two circuits
  sharing a sensor rather than one circuit that would have called *B. subtilis*
  negative.
- *Type I restriction-modification* was the cleanest multisubunit requirement
  available, and the KEGG groups are defined as type I subunits, so the type is
  part of the group definition rather than an inference from it.
- *Type I-E CRISPR-Cas* was curated under the narrowed claim its proposal
  recommended: encoded machinery, not interference, because an array is a
  structural feature no protein accession evidences.

**Refusals recorded with the content**, each enforced by a test:

- ligand-specific chemoreception beyond aspartate, because K05876 covers ribose
  and galactose in one group and K03406 covers everything;
- K07660, which shares the gene name *phoP* with the phosphate regulator and is
  the magnesium-sensing PhoP/PhoQ regulator, a different protein with the
  opposite genome distribution;
- the target sequence a type I system recognises, because HsdS specificity comes
  from variable target recognition domains an orthology group does not resolve;
- K07475, the HD module of a split Cas3, as evidence of the complete
  nuclease-helicase;
- CheV as a substitute for CheW.

**Effect on other types: none.** The 29 metabolic GIFTs and the two structural
ones are unchanged; the no-regression test now strips every non-metabolic model
rather than only the structural one.

**Report.** The atlas renders regulatory circuits and defense mechanisms through
the same machinery view the structural type already used, and the GIFT type
grouping axis now separates four groups.

**A note on what did not happen.** The first structural and regulatory GIFTs are
now both curated, so `flagellar_apparatus` + `chemotaxis_signal_transduction`
could be fused into a `motility` trait. They are not, and the architecture guide
says why: a derived statement should read the primary calls rather than hide
which half of it a genome satisfies.

### 2026-08-18T10:00Z — GIFT becomes an umbrella concept with an explicit type

**Change.** A GIFT is redefined as a biologically meaningful capability whose
genomic support is evaluated through an explicit, curated and traceable
completeness model, and every GIFT now declares a core `gift_type`:
`metabolic`, `structural`, `regulatory` or `defense`. Schema version moves from
5 to 6.

`gift_type` is not a facet. A facet classifies a call; the type decides which
completeness model produces one, which source tables may attach to the GIFT, and
what a positive call is allowed to mean. That is a change to the relational
contract, hence a migration rather than a new column.

**Reason.** A genome encodes capabilities that are not chemistry. Modelling a
flagellum or a restriction-modification system as a directed route between
molecular anchors would have required inventing input and output molecules the
structure does not have, and the call would then rest on a boundary claim nobody
could defend. Each type states its own completeness contract instead.

**Effect on the metabolic model: none.** All 29 previously curated GIFTs became
`gift_type = metabolic` with no change to their anchors, routes, reactions,
systems, components, markers, calls, traces, graph edges or derived profile.
`test-gift-types.R` proves this by compiling a database with the structural
content removed and comparing every metabolic call and trace against the shipped
one.

**Structural model.** Implemented in full, with its own biologically named
tables: `gift_architecture`, `architecture_function`, `structural_function`,
`structural_system`, `structural_component`, `structural_component_marker`. A
structural GIFT is complete when any curated architecture has every required
structural function supported; an incomplete call names the closest architecture
and the functions missing from it, never a fraction of expected genes.
`required = 0` marks an accessory function.

**Regulatory and defense models.** Schema and evaluator implemented under
`gift_circuit`/`circuit_function`/`regulatory_*` and
`gift_mechanism`/`mechanism_function`/`defense_*`; both ship with no curated
content, and their Boolean semantics are fixed by synthetic fixtures in
`test-regulatory-defense.R`. The design questions that block curation —
cognate sensor/regulator pairing, and whether a CRISPR claim needs evidence
beyond protein markers — are written down in the type proposals rather than
answered by convenient curation.

The three non-metabolic models are kept as parallel table families rather than
merged into one generic set. Their Boolean shape is identical; a structural
function, a regulatory function and a defense function are not the same
biological object, and a source row is reviewable because of what it is called.
Only the operations whose semantics genuinely are identical are shared in code:
marker matching, component support, system AND logic, confidence ordering,
deterministic tie-breaking and result assembly. Whether the data model should
converge is left for after all three carry curated content.

**Public API.**

- `list_gifts()` gains a `type` argument and returns `gift_type`;
- `get_gift()` returns `gift_type`; `gifts_by_facet()` returns it too;
- `evaluate_gifts()` evaluates a mixed-type database in one call. Its `gifts`
  summary gains `gift_type` and a type-neutral answer — `best_implementation`,
  `number_of_complete_implementations`, `minimum_missing_requirements`,
  `missing_requirements`, `completeness_score` — beside the unchanged metabolic
  route columns, which are `NA` for non-metabolic GIFTs. New `structural`,
  `regulatory` and `defense` members carry the type-specific detail under
  biological names (`best_architecture`, `missing_functions_best_architecture`);
- `trace_gift()` dispatches on the type and gains an `implementation` argument
  for the machinery types; passing `route_id` for a non-metabolic GIFT, or
  `implementation` for a metabolic one, is an error rather than being ignored;
- `map_markers()` searches every model and gains `gift_type` and `function_id`.
  Component keys are unique only within a model, so they must be compared
  together with the type;
- new `get_gift_machinery()` returns the implementation, function, system,
  component and marker hierarchy of a non-metabolic GIFT;
- `gift_profile()` is documented and implemented as metabolic-only, because
  every field it derives comes from declared anchors.

**Validation.** Unknown or missing types are rejected. `mode`, anchors and
routes are refused on non-metabolic GIFTs and required on metabolic ones. An
implementation may not name a GIFT of another type. Required facets are scoped
by type, and a facet required of one type may not classify another. Function,
system, component and implementation identifiers must be unique across models,
because a trace prints them without naming their table. An implementation with
no required function is rejected. A separate fix makes the composition cycle
check skip a GIFT whose mode is missing rather than failing on an unnamed node.

**Report.** The atlas renders non-metabolic GIFTs as their alternative
implementations over the functions they share, with accessory functions dashed,
and offers GIFT type as a grouping axis. The new tables appear in the schema and
table browsers.

### 2026-08-19T00:30Z — Package renamed from distillR to giftr

The package is renamed to `giftr` and developed in its own repository. Every
identifier that carried the old name follows: `build_giftr_database()`,
`validate_giftr_sources()`, `write_giftr_database_html()`, `giftr_db_connect()`,
`giftr_db_disconnect()` and `giftr_db_version()`; the result classes
`giftr_result` and `giftr_reaction_result`; the packaged artefacts
`inst/extdata/giftr.sqlite`, `inst/extdata/giftr-database.html` and
`inst/schema/giftr.sql`; and the `database_release.giftr_db_version` column.

Calling this work distillR 2.0 implied continuity with a package built on a
different primitive — fullness scores over curated gene bundles. The
evaluation model, schema, public API and biological claims are all new and no
1.x code path survives, so a distinct name states plainly what the software is.
The package version starts afresh at 0.1.0. References to distillR that
describe the predecessor are kept as such in the architecture guide, the
curation proposals and the manuscript.

**Effect.** No change to evaluation logic, schema, or database content. The
database version is unaffected and remains 2026.12.1 at schema 5. Code written
against the unreleased distillR 2.0 development branch must rename the
identifiers above.

**Also.** `DESCRIPTION` gains `Config/build/clean-inst-doc: FALSE`. `inst/doc`
holds developer documentation rather than built vignettes, and the build tooling
clears that directory by default.

### 2026-08-18T23:59Z — Schema 5: facet classification and derived profile

**Change.** Schema version 5 replaces the free-text `gift.category` column with
a registered facet vocabulary, and adds a derived profile view.

`facet_term` registers every `(facet, value)` pair with the target it applies to
and a definition. `gift_facet` and `anchor_facet` carry the assignments; the
build rejects any pair that is not registered, any facet attached to the wrong
target, a GIFT without exactly one `substrate_class`, a GIFT without at least
one `physiological_role`, and an anchor without `molecular_tier` or
`biomass_essential`. `gift_route` gains a required `oxygen_requirement`, which
is a route property rather than a GIFT property because alternative routes to
the same anchors genuinely differ.

The `gift_profile` view derives `substrate_tier`, `resource_strategy`,
`network_position`, `cross_feeding_output` and `auxotrophy_indicator` from
declared anchors, anchor facets and the composition graph. Nothing in it is
curated. Facets and profile classify a call; neither enters the completeness
logic that produces one.

**API.** New: `list_facets()`, `get_facets()`, `gifts_by_facet()`,
`gift_profile()`. `list_gifts()`, `get_gift()` and `evaluate_gifts()` no longer
return `category`; `evaluate_gifts()` returns `substrate_class` instead.

**Effect.** No GIFT call changes. `resource_strategy` makes the
degrader-versus-forager distinction directly readable: `uptake`, `public_good`,
`private`, or `unresolved` where a compartment was never licensed.

**Migration note.** Consumers reading `category` should read `substrate_class`,
either from `evaluate_gifts()` or via `get_facets(gift_id)`.

### 2026-08-18T21:00Z — Polysaccharide content restructured; no code change

Database 2026.10.2 replaces six single-reaction polysaccharide GIFTs with three
substrate-level capabilities. The decision and its effect on calls are in
`database_changes.tsv`; this entry records only that a published shape was
retracted.

The first polysaccharide release made a GIFT equivalent to a reaction, which is
the marker-checklist shape the ontology exists to avoid, and left the
substrate-level question unanswerable by any single trait. `xylan_degradation`
now spans endo- and exo-acting chemistry with acetyl de-blocking as an accessory
reaction, and a genome carrying only one side reports an incomplete capability
naming the missing reaction.

**Migration note.** `xylan_depolymerisation`,
`xylooligosaccharide_saccharification`, `arabinoxylan_arabinofuranose_release`,
`starch_depolymerisation`, `starch_debranching` and
`maltooligosaccharide_saccharification` no longer exist. Use
`xylan_degradation`, `arabinoxylan_debranching` and `starch_degradation`. The
`XYLOOLIGOSACCHARIDE` and `MALTOOLIGOSACCHARIDE` anchors are withdrawn.

### 2026-08-18T18:00Z — Confidence follows the Boolean structure

**Change.** `evidence_confidence` is now computed as the *best* confidence among
the alternative markers supporting each component, then the *weakest* across the
components a route requires. It previously took the weakest across all
supporting markers.

**Why.** Alternative markers for one component are OR. Under the old rule,
adding a weak marker alongside a strong one made the call look worse — a genome
annotated with both the polyspecific CAZy family GH5 and the specific orthologue
K01181 reported `ambiguous`, when the specific evidence was present and
sufficient. Components are AND, so the weakest-wins rule is correct there and is
retained.

**Effect.** Confidence can only improve or stay equal for a given genome. No
Boolean call changes. Newly visible on database 2026.10.1, which is the first
content mixing curated orthology with polyspecific sequence families.

**Migration note.** Reaction identity is `reaction_id`, and `rhea_master` is now
`NA` for the polymer-acting reactions. Code filtering results with
`reactions$rhea_master == x` will return `NA` rows; filter on `reaction_id`.

### 2026-08-18T14:00Z — `mode` reaches the evaluation result

**Change.** The `gifts` tibble returned by `evaluate_gifts()` now carries
`mode`, matching `list_gifts()` and `get_gift()`. Filtering a result down to
transport or catabolic traits previously required a second lookup.

**Effect.** Additive; no call changes. Database 2026.09.4 adds the first two
transport GIFTs and the first compartment-split anchors, so the column now
distinguishes rows that were all `anabolic` before.

### 2026-08-18T10:00Z — Sugar degradation content; no code change

Database 2026.09.3 adds nine catabolic GIFTs. This entry is a pointer only: the
biological decisions, their evidence and their effect on calls are recorded in
`database_changes.tsv` and readable with `database_changelog()`. No package
behaviour changed, and no existing GIFT call changed.

The content exercises schema 4 for the first time: `mode = catabolic` on all
nine, and `reaction_id` carrying identity for 29 new reactions. Compartment
remains `unspecified` throughout, because no uptake GIFT is curated yet and the
splitting licence requires substrate-specific transporter evidence first.

### 2026-08-17T21:30Z — Schema 4: reaction identity, compartment, and GIFT mode

Infrastructure for the polysaccharide and sugar degradation layer described in
`inst/doc/proposal-polysaccharide-degradation.md`. No biological content is
added here and no existing GIFT call changes.

**Change.** Schema version 4 makes four structural changes.

*Reaction identity.* `reaction` gains a stable `reaction_id`, and `rhea_master`
becomes optional. `reactions.tsv` gains a `reaction_id` column, and
`route_reactions.tsv`, `enzyme_systems.tsv` and `reaction_xrefs.tsv` reference
it in place of `rhea_master`. For all content curated so far `reaction_id`
equals the Rhea master, so no reference changed value. A reaction curated
without a Rhea master must carry at least one `reaction_xrefs` entry.

*Anchor compartment.* `anchor` gains `molecule`, a stable key shared by the
compartment variants of one substance, and `compartment`, one of
`extracellular`, `cytoplasmic`, `unspecified`. `UNIQUE (molecule, compartment)`
becomes the natural key and `chebi_id` is no longer unique, because two location
states of one molecule carry the same ChEBI identifier. Every existing anchor is
`unspecified` with `molecule` equal to its `anchor_id`.

*GIFT mode.* `gift` gains `mode`, one of `anabolic`, `catabolic`, `transport`,
`interconversion`. The composition cycle check now runs per mode: a cycle within
one mode is still an error, a cycle between modes is not. All existing content
is `anabolic`.

*Graph edge quality.* The `gift_graph` view matches on `molecule` and reports
`edge_quality`. An edge is `exact` when both GIFTs declare the same anchor, and
`compartment_inexact` when they declare the same molecule and exactly one side
is `unspecified`. Two anchors whose compartments are both specified and
different are not connected, so a transport GIFT is required to cross that
boundary. `gift_graph()` gains a `quality` filter and returns `to_anchor`,
`shared_molecule` and `edge_quality` alongside the existing columns.

**Validation.** New errors: an invalid mode or compartment, a repeated
molecule/compartment pair, an empty `molecule`, a transport GIFT whose anchors
do not translocate one molecule, a malformed or duplicated Rhea master, and a
reaction with neither a Rhea master nor a cross-reference. New warning: a GIFT
that translocates a molecule without declaring `mode = transport`.

**Evaluation.** `evaluate_gifts()` reports `evidence_confidence` per GIFT — the
weakest qualitative confidence among the markers supporting the best route, so a
call resting on ambiguous evidence is distinguishable from one resting on
curated orthology. `trace_gift()` gains `reaction_id`. Route
`supporting_reactions` and `missing_reactions` now carry `reaction_id`, which is
never null.

**Markers.** CAZy accessions are recognised without an explicit namespace
(`GH5`, `GH5_4`, `PL1`, `CE8`, `AA9`, `CBM6`). A subfamily is a distinct
accession and never implies its parent family.

**API.** `get_reaction()` and `get_reaction_systems()` take `reaction`, matching
either a `reaction_id` or a Rhea master; `get_reaction(15753)` still resolves.
`list_gifts()` and `get_gift()` return `mode`; `get_gift_anchors()` returns
`molecule` and `compartment`; `get_gift_reactions()` returns `reaction_id`.

**Reason.** Rhea does not cover polymer-acting chemistry, catabolism and
biosynthesis legitimately close loops through shared metabolites, and the
degrader/forager/cross-feeder distinction is invisible without compartment.
Each was a blocker for curating carbohydrate degradation honestly.

**Effect.** No change to any existing GIFT call; 531 tests pass. Compartment
remains a curated boundary claim rather than a genomic inference — the scope
statements in `AGENTS.md` and `inst/doc/architecture.md` were amended to say so
and to enumerate what stays out of scope.

### 2026-08-17T20:10Z — GIFTs can be linked to related external pathways

**Change.** Schema version 3 adds the `gift_xref` table, compiled from the new
source `gift_xrefs.tsv`. Two accessors read it: `get_gift_pathways(gift_id,
namespace = NULL)` lists the external pathways related to a GIFT, and
`gifts_for_pathway(accession, namespace = NULL)` resolves a pathway identifier
back to the GIFTs that relate to it. Every reference carries a `relation` from
the closed vocabulary `equivalent`, `subset_of`, `superset_of`, `overlaps`,
`related`. Source validation rejects an unknown relation, a link to an unknown
GIFT, a duplicate GIFT/namespace/accession triple, and an empty namespace,
accession or name. The HTML atlas gains a `Related pathways` section on every
GIFT, with the relation spelled out in words, and pathway accessions are
searchable from the GIFT explorer.

**Why.** Users arrive from the resource they already know, but a GIFT is a
curated capability between declared anchors and is usually not the same object
as a pathway record. A bare cross-reference would imply an equivalence that is
false for most GIFTs — giftr splits KEGG M00018 across three traits and
merges M00338 with part of M00609. Storing the set relation makes the link
useful without weakening the claim. The namespace is deliberately open so that
resources beyond KEGG can be linked without a schema change.

**Effect.** No GIFT call changes. `giftr_db_version()` reports schema
version 3. Consumers reading `gift_xref` should treat `namespace` as an open
vocabulary and `relation` as closed.

---

### 2026-08-17T18:05Z — Curation history stored in the database and published in the atlas

**Change.** Schema version 2 adds the `database_change` and `change_gift`
tables, compiled from `database_changes.tsv` and `change_gifts.tsv`. New
accessor `database_changelog(gift_id = NULL)` returns the history, newest
first, with the affected GIFTs as a list column. The HTML atlas gains a
`Changelog` view rendering the history as a table — release, UTC timestamp,
hierarchy layer, category, effect on calls, the decision with its rationale,
evidence and effect, and the GIFT identifiers it affects. Selecting a GIFT
identifier opens that trait in the GIFT explorer, and every GIFT detail now
carries its own change history.

**Why.** Biological decisions were recorded in a Markdown file next to the
code, where they were invisible to anyone holding only the compiled database,
unlinked from the traits they changed, and mixed in with code history.

**Design decisions.** The history is curated source data, not documentation, so
it passes the same validation as the rest of the database: controlled
vocabularies for layer, category and effect on calls; ISO 8601 UTC timestamps;
and a foreign key from every entry to the GIFTs it affects. Validation requires
that link for changes to biological layers, and allows provenance and schema
entries to stand alone. `call_effect` is a first-class field rather than prose
because whether a change broadens or narrows calls is the question a user
re-running an analysis actually has.

**Effect.** No change to evaluation. Schema version 1 to 2; database release
2026.08.2 to 2026.08.3.

### 2026-08-17T16:49Z — Network visualisations in the database atlas

**Change.** `write_giftr_database_html()` now renders three inline SVG
network views: the existing directed GIFT composition graph, a new network
drawing GIFTs together with their declared anchors, and a merged route network
for every GIFT. A shared layered-graph engine in `R/database-visualization.R`
backs all three; the composition graph was moved onto it without changing its
appearance.

**Why.** The atlas described the evaluation hierarchy in tables and nested
disclosure but never showed the two structures that curation decisions actually
turn on: where alternative routes diverge and reconverge inside one GIFT, and
which anchors are the boundaries where GIFTs meet.

**Design decisions.** Route networks merge alternative routes onto shared
reaction nodes, so a parallel branch is a genuine route alternative and edge
thickness reports how many routes traverse a step. Anchors are drawn once in
the anchor network, so an anchor with both an incoming and an outgoing edge is
exactly the boundary where two GIFTs compose. Both networks are built strictly
from `gift_anchor` and `route_reaction`; no node exists that is not a declared
anchor or a curated route reaction, so a drawing can never imply a boundary
that curation did not declare. Graphs render at natural size and scroll
horizontally rather than being scaled down, which keeps long routes legible.

**Effect.** No change to evaluation or to the database. Tests assert the node
accounting of both networks, the route overlay counts, and marker-ID
uniqueness across the report.
