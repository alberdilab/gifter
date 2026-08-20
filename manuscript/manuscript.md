---
title: "gifter: auditable genome-inferred functional traits between curated molecular anchors"
short_title: "Genome-inferred functional traits with gifter"
authors:
  - name: Antton Alberdi
    affiliation: 1
    corresponding: true
    email: antton.alberdi@sund.ku.dk
  - name: "[co-authors to be added]"
    affiliation: "[]"
affiliations:
  - id: 1
    name: "Center for Evolutionary Hologenomics, Globe Institute, University of Copenhagen, Copenhagen, Denmark"
keywords:
  - genome-inferred functional traits
  - metagenome-assembled genomes
  - functional annotation
  - microbial ecology
  - metabolic inference
target: "Software/application paper (candidate venues: Bioinformatics, Microbiome, Methods in Ecology and Evolution, mSystems)"
software_version: "gifter 0.1.0 (in development)"
database_version: "2026.11.1 (schema 5)"
status: "Working draft — grows with the software. See the drafting roadmap at the end."
---

<!--
DRAFTING CONVENTIONS
  * Sections 1-6 describe behaviour that exists in the package today and can be
    written as final prose.
  * Section 7 (Evaluation) is a plan, not a result. Never write a number here
    that has not been produced by a script in `manuscript/analysis/`.
  * Every quantitative claim about the database must name the database version
    it was taken from; content grows between releases.
  * Keep the honest-uncertainty language of the package: a positive call is
    evidence for encoded machinery, never a phenotype.
-->

## Abstract

*[Draft — rewrite last, once the evaluation section exists.]*

Inferring what a microbial genome can do is a routine step in microbiome
research, but the tools available sit at two extremes. Marker checklists ask
whether a set of orthologue identifiers is present and report a percentage of
expected genes, which is fast and transparent but biologically flat. Genome-scale
metabolic models reconstruct a full stoichiometric network, which is
biologically rich but expensive to curate, hard to audit, and dependent on gap
filling that invents chemistry the genome does not encode. We present gifter,
an R package that occupies the space between them. gifter evaluates
**genome-inferred functional traits (GIFTs)**: directed biological capabilities
defined between curated molecular anchors and resolved through an explicit
Boolean hierarchy of routes, reactions, enzyme systems, protein components and
genomic markers. A trait is called complete when at least one curated route is
fully supported, rather than when an arbitrary fraction of expected genes is
observed; an incomplete trait reports its closest route and the specific
reactions that are missing. Every call can be traced back through the hierarchy
to the annotated genes responsible for it, and each call carries the weakest
evidence term among the markers supporting it. The biological content lives in a
versioned, human-reviewable reference database that is compiled into a read-only
SQLite artifact, is versioned independently of the code, and carries its own
biological changelog. Traits compose only through their declared anchors, which
yields a derived trait graph in which longer capabilities are traversals rather
than duplicated curation. *[Add: scale of the reference database at submission;
headline evaluation result; availability statement.]*

## 1. Introduction

*[Status: structure settled, prose complete, citations pending.]*

Genome-resolved metagenomics routinely yields hundreds to thousands of
metagenome-assembled genomes (MAGs) per study, and the analytical bottleneck has
moved from recovering genomes to interpreting them. The question asked of each
genome is almost always functional: does this organism degrade this substrate,
synthesise this compound, respire this electron acceptor, or depend on a partner
for a metabolite it cannot make? *[cite: MAG-based ecology reviews; HoloFood /
Earth Hologenome Initiative style datasets.]*

Three families of tools currently answer that question, and each answers a
different version of it.

**Marker checklists** map annotation identifiers onto predefined gene sets and
report the fraction observed. KEGG module completeness and the pathway summaries
of tools such as DRAM, METABOLIC and MicrobeAnnotator are of this kind. *[cite:
KEGG/KofamScan; DRAM; METABOLIC; MicrobeAnnotator; anvi'o estimate-metabolism.]*
They are fast, reproducible and easy to explain, but the abstraction they use —
a flat list of expected identifiers with a percentage attached — cannot
distinguish four situations that are biologically distinct: an organism that
uses an alternative route to the same product; an organism that uses a
non-homologous enzyme for one step; an organism that is missing one subunit of
an otherwise complete complex; and an organism whose annotation is simply
incomplete. All four can produce "80% complete", and the number carries no
statement of which chemistry is unsupported.

**Genome-scale metabolic models** reconstruct a stoichiometric network and
simulate flux. *[cite: carveMe; gapseq; ModelSEED/KBase; CarveFungi et al.]*
They represent alternatives, cofactors and mass balance properly, but they
require gap filling to become simulable, which introduces reactions that the
genome does not encode, and the provenance of an individual conclusion is
difficult to recover. For comparative ecology across thousands of partially
complete MAGs, the modelling machinery answers a question — *will this organism
grow on this medium?* — that the underlying evidence often cannot support.

**Trait databases and curated schemes** assign organisms to functional
categories from literature or taxonomy. *[cite: FAPROTAX; MDB/ Madin et al.
trait database; BacDive.]* They are biologically meaningful but are not derived
from the genome at hand, so they cannot describe a novel or uncultured lineage.

gifter's predecessor, distillR *[cite: distillR 1.x usage papers]*, belonged to
the first family. It matched KEGG orthologue and Enzyme Commission identifiers
against roughly five hundred curated gene bundles and returned a fullness value
per bundle, aggregated into compounds, functions and domains. That design was
useful for comparative work and is still in use, but its limits were the limits
of the abstraction: a bundle was a set of identifiers rather than a biological
claim; a fullness value could not say which step was missing; alternative
routes, protein complexes, non-homologous replacements and multifunctional
enzymes were all flattened into the same list; and a value could not be traced
back to the genes that produced it.

gifter is a redesign around a different primitive. Rather than scoring
membership in a gene set, it asks whether a genome contains sufficient evidence
for **at least one known enzymatic implementation of a biologically defined
capability**, where the capability is defined by the molecules at its boundaries
rather than by the identifiers inside it. This paper describes that primitive
(Section 2), the Boolean evaluation model that resolves it (Section 3), the
anchor-based composition and compartment model that lets traits connect
(Section 4), the curated reference database and its version and provenance
model (Section 5), and the R implementation and interface (Section 6).

We state the scope plainly, because a large part of the design is what gifter
refuses to do. gifter reports what a genome *encodes*. It does not model
growth, flux, thermodynamics, media, metabolite concentrations, transport
stoichiometry or cellular mass balance, and a positive call is not a claim about
expression, activity or phenotype in any particular environment.

## 2. The GIFT: a capability between curated anchors

*[Status: complete.]*

A **genome-inferred functional trait (GIFT)** is a directed biological
capability declared between one or more curated input molecules and one or more
curated output molecules, called **anchors**.

```text
INPUT ANCHOR(S)
       |
       | curated enzymatic route
       v
OUTPUT ANCHOR(S)
```

`PRPP > IMP`, `IMP > AMP`, `L-arabinose > D-xylulose 5-phosphate` and
`xylan > D-xylose` are GIFTs. A positive call means, approximately:

> The available genomic evidence supports at least one complete known enzymatic
> implementation of this capability.

Three consequences follow from defining a trait by its boundaries rather than by
its contents.

**A GIFT is not a pathway record.** It is not a KEGG module, an EC list, a KO
list or a gene name, and gifter boundaries deliberately differ from external
pathway endpoints where the biology justifies it. External resources contribute
chemistry, identifiers and evidence; they do not define the ontology. Links to
external pathways are recorded explicitly, and each link must state how the
curated boundaries compare with the external record — `equivalent`, `subset_of`,
`superset_of`, `overlaps` or `related` — so that a familiar identifier never
implies an equivalence the boundaries do not support. KEGG module M00018, for
example, is `subset_of` three separate gifter traits, because gifter cuts
that module at two biologically meaningful branchpoints.

**Boundaries are a modelling decision that must be defended.** The working rule
used during curation is to start at the nearest biologically meaningful shared
precursor, host- or environment-derived substrate, or metabolic junction before
trait-specific chemistry begins, and to end at the first stable product or
branchpoint that establishes the capability's identity before broadly shared
metabolism resumes. Purine biosynthesis illustrates both cuts:

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

`PRPP > IMP` and `IMP > AMP` are separate traits because IMP is a real
branchpoint, and adenylate biosynthesis stops at AMP rather than continuing to
ADP and ATP because generic nucleotide phosphorylation is shared metabolism that
adds nothing to the claim.

**The anchor vocabulary is kept deliberately small.** Anchors are boundaries,
not a metabolite catalogue: environmental or host-derived substrates, stable
biosynthetic products, major precursors, important branchpoints, and electron
donors or acceptors when they define the trait. ATP, water, phosphate, protons
and transient intermediates are not anchors. At database version 2026.11.1 the
whole anchor vocabulary comprises 41 entries for 28 curated traits.

## 3. Evaluation: an explicit Boolean hierarchy

*[Status: complete.]*

gifter separates biological meaning, chemistry, enzymology and genomic
evidence into five layers that alternate between disjunction and conjunction:

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

Each layer exists because it solves a biological problem that the adjacent
layers cannot:

| Layer | Represents | Collapsing it would lose |
|---|---|---|
| Routes (OR) | Alternative biochemical paths between the same anchors | Alternative pathways |
| Reactions (AND) | The chemistry a route requires | Which step is missing |
| Enzyme systems (OR) | Alternative enzymes for one reaction | Non-homologous replacement |
| Components (AND) | Proteins jointly required by a complex | Partial complexes |
| Markers (OR) | Alternative evidence for the same protein | Annotation redundancy |

A flat `marker -> trait` mapping conflates all five. This is the concrete reason
the redesign was necessary: the distinctions above are exactly what a percentage
of observed identifiers destroys.

### 3.1 Route-based completeness

Completeness is discrete and route-based. A trait is complete when any one of
its curated routes has support for every required reaction; optional reactions
in a route do not affect the call. Alternative routes are materialised at build
time as separate records rather than stored as runtime expressions:

```text
route_1 = R1 AND R2 AND R3
route_2 = R1 AND R2 AND R4
```

is preferred over `R1 AND R2 AND (R3 OR R4)`. This duplicates small route
memberships but never duplicates the reaction, enzyme or marker definitions
themselves, and it keeps the runtime rule to a single sentence: all required
reactions of any one route.

### 3.2 Diagnostics for incomplete traits

An incomplete trait is more informative than a complete one, and gifter
reports it accordingly. For each trait the result gives the closest valid route,
the minimum number of missing required reactions, the identity of those missing
reactions, the supported reactions, and the systems, components, markers and
genes behind each decision. Route selection and tie-breaking are deterministic.

"One reaction missing from route *X*, namely RHEA:*n*" is a statement a
biologist can act on; "87% complete" is not. A normalised `route_score` is
retained for plotting and ranking, but it is a secondary summary and never the
call.

### 3.3 Evidence confidence reaches the call

Each marker-to-component mapping carries a qualitative confidence term
(`curated`, `high-confidence`, `putative`, `ambiguous`, `insufficient
evidence`). Each call reports `evidence_confidence`: the weakest term among the
markers supporting its best route. The terms are ordered and never averaged into
a score, because a call is only as strong as its weakest accepted marker.

This matters most for sequence-family markers, where a family is not an
activity. Polyspecific CAZy families such as GH5, GH13, GH30 and GH43 would
silently attribute every activity in the family to a genome that carries any
member; gifter prefers dbCAN subfamily accessions where they exist, accepts a
bare family only where it is effectively monoactivity, records the reason, and
marks the mapping `ambiguous` where it is. A trait resting on an ambiguous
family must not read like one resting on curated orthology.

### 3.4 Worked example

*[Status: expand into a full figure-backed walkthrough once the case-study
dataset is chosen. The purine example below is stable and is retained as an
architectural fixture in the test suite.]*

Given a marker table of KEGG orthologue accessions, `evaluate_gifts()` resolves
every trait in the database and returns a list of tibbles — `gifts`, `routes`,
`reactions`, `systems`, `components` and `evidence` — that share stable
identifiers. `trace_gift(result, "adenylate_biosynthesis")` returns the
long-form path from the called route through its reactions, selected enzyme
systems and required components to the observed markers and, where supplied, the
gene identifiers responsible.

## 4. Composition, compartments and classification

*[Status: complete.]*

### 4.1 Anchors are the public interface of a trait

Only declared anchors connect traits. Internal reaction participants are
implementation details and are not runtime entities, so two traits that happen
to share an intermediate never acquire an edge because of it. The trait graph is
therefore derived, not maintained: `gift_graph()` matches one trait's declared
output anchor to another's declared input anchor.

```text
purine_core_biosynthesis --IMP--> adenylate_biosynthesis
purine_core_biosynthesis --IMP--> guanylate_biosynthesis
```

A longer capability is a traversal of that graph, not a separate curated object.
gifter does not store a `PRPP > AMP` trait that copies the reactions of the
two atomic traits; it stores the atomic traits and lets the chain be read from
the graph. Composition without duplication is what keeps the curation internally
consistent as the database grows.

### 4.2 Cycles are a design constraint, not a formality

Every trait declares a mode — `anabolic`, `catabolic`, `transport` or
`interconversion` — and the build rejects cycles in the derived composition
graph *within* a mode. Cycles *between* modes are accepted, because catabolism
legitimately returns to metabolites that biosynthesis produces:

```text
FRUCTOSE_6P --> ... --> GLCNAC        (anabolic)
GLCNAC      --> ... --> FRUCTOSE_6P   (catabolic)
```

Sulfur metabolism is the worked case. Cysteine donates sulfur to methionine and
homocysteine donates sulfur back to cysteine, so the obvious boundary choices
close an anabolic loop. The database resolves this by declaring homocysteine an
input anchor only, keeping it internal to both methionine traits. When the
validator reports a cycle, the correct response is to ask which boundary is the
weakest biological claim, not to delete an edge.

### 4.3 A deliberately narrow compartment model

Every anchor carries a stable `molecule` identity and a `compartment` qualifier
with three states: `extracellular`, `cytoplasmic` or `unspecified`. This is the
single extension beyond pure chemistry, and it exists for one reason:
depolymerising a polymer outside the cell, importing the product and
saccharifying it inside are different ecological strategies — public-goods
degrader, selfish forager, cross-feeder — and they are invisible if every
boundary molecule is compartment-blind.

The model is narrow by construction. Compartment is a **curated boundary claim,
not a genomic inference**: a KO or CAZy family identifies chemistry, not
localisation. An anchor is split by compartment only when the substrate can
physically occupy both locations *and* substrate-specific transporter markers
exist to evidence the crossing; otherwise the chemistry stays `unspecified`. An
unevidenced transporter promoted to a required reaction would turn a missing
annotation into a false negative for an entire catabolic chain. A trait with
`mode = transport` must declare the same molecule as both input and output — the
formal difference between moving a substance and changing it — and the validator
enforces it. gifter still models no membrane potential, transport
stoichiometry, proton coupling or compartment-aware mass balance.

Composition accounts for unresolved compartments explicitly:

| Output anchor | Input anchor | Edge |
|---|---|---|
| Same anchor | Same anchor | `exact` |
| Same molecule, one side `unspecified` | | `compartment_inexact` |
| Same molecule, both specified and different | | none |

The third row is what makes transport meaningful: extracellular glucose reaches
cytoplasmic glucose only through an uptake trait. The second keeps an unresolved
boundary from breaking a chain, while the reported `edge_quality` prevents a
traversal that crossed one from being read as a fully resolved claim.

### 4.4 Facets and the derived profile

Traits and anchors carry classification from a registered facet vocabulary
(`substrate_class`, `physiological_role` for traits; `molecular_tier`,
`resource_origin`, `biomass_essential` for anchors). Every `(facet, value)` pair
must be registered with the target it applies to and a definition, and the build
rejects unregistered pairs, facets attached to the wrong target, a trait without
exactly one substrate class, and a trait without at least one physiological
role.

From declared anchors, anchor facets and the composition graph, the database
derives a per-trait profile — `substrate_tier`, `resource_strategy`,
`network_position`, `cross_feeding_output`, `auxotrophy_indicator` — in which
nothing is curated. `resource_strategy` makes the degrader-versus-forager
distinction directly readable as `uptake`, `public_good`, `private` or
`unresolved`. Facets and the derived profile classify a call; neither enters the
logic that produces one.

## 5. The reference database

*[Status: complete; update the counts at submission.]*

### 5.1 Human-reviewable source, compiled artifact

The biological source of truth is a set of version-controlled TSV files that a
curator can read in a diff. The runtime object is a read-only SQLite database
compiled from them:

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

Compilation is atomic: the target file is replaced only after the new database
passes foreign-key and integrity checks. SQLite is treated as an implementation
detail throughout — never the ontology, and never hand-edited.

### 5.2 Schema

The normalised model has two complementary paths, one biological and one
evidential:

```text
anchor -> GIFT -> anchor

marker -> component -> enzyme system -> reaction -> route -> GIFT
```

Reactions are identified by their Rhea master identifier wherever Rhea covers
the chemistry, and a reaction without one must carry at least one
cross-reference. Direction is not part of reaction identity: a route stores the
orientation (`forward` or `reverse`) in which it uses that chemistry, so
directional Rhea identifiers are never modelled as unrelated reactions. Markers
use the open key `namespace + accession` (KO, EC, PFAM, TIGRFAM, CAZY,
CUSTOM_HMM, …), so a new evidence system can be added without a schema
migration. Anchors carry ChEBI identifiers where available.

**Table 1.** Reference database content at version 2026.11.1 (schema 5).
*[Regenerate at submission — this content grows continuously.]*

| Entity | Count |
|---|---|
| GIFTs | 28 |
| Anchors | 41 |
| Reactions | 90 |
| Routes | 47 |
| Enzyme systems | 97 |
| Enzyme components | 111 |
| Markers | 422 |
| Marker-to-component mappings | 488 |
| External pathway links | 53 |

Current content covers nucleotide biosynthesis, the aspartate and serine amino
acid families with alternative sulfur-assimilation routes, monosaccharide and
uronate catabolism, amino-sugar and sialic-acid catabolism, sugar uptake, and
plant and host polysaccharide degradation. *[Extend as curation proceeds; state
the target scope for the release accompanying this paper.]*

### 5.3 Validation separates broken structure from debatable biology

Source validation fails on conditions that cannot produce a coherent database:
missing files or columns, empty or duplicated stable identifiers, broken
references, a trait without anchors or routes, a route without required
reactions, invalid roles or orientations, malformed Rhea identifiers, a reaction
without an enzyme system, a system without a component, a component without a
marker, within-mode composition cycles, unknown external pathway relations, and
inconsistent release metadata. Curator warnings flag structurally valid content
that still needs biological review. The distinction is enforced: a warning never
permits broken relational structure, and an error is never used for a debatable
curation judgement.

### 5.4 Three versions and two changelogs

Code, biological content and relational contract are versioned separately:

```text
package version    code and public API
database version   biological content
schema version     relational contract / migration level
```

A package release cannot silently change biological definitions, because the
definitions carry their own version and provenance, including the upstream Rhea,
ChEBI and KEGG releases they were curated against.

Correspondingly there are two changelogs, and they are kept apart. Every change
to biological content is a row *inside the database*, recording the release it
shipped in, a UTC timestamp, the hierarchy layer it touched, whether it
broadens, narrows or leaves calls unchanged, and the rationale, evidence and
effect behind the decision — linked to the traits it affects, so the history is
readable from the trait as well as from the release. Package, API and evaluation
changes live in the repository changelog. A biological decision is versioned
with the content it describes and travels with the compiled artifact; a code
decision is versioned with the code.

### 5.5 Provenance

Each source is credited with what it actually supports: Rhea defines reaction
chemistry, ChEBI identifies anchor molecules, KEGG and MetaCyc may suggest a
pathway organisation or cross-reference, and UniProt, curated HMM collections
and primary literature support enzyme and marker mappings. The capability, its
boundaries, the accepted routes and the curation interpretation are gifter's
own, and the documentation is explicit that no upstream database endorses a
gifter boundary decision.

### 5.6 A self-contained database atlas

`write_gifter_database_html()` renders the whole compiled database as a
single, self-contained interactive HTML report: release metadata and row counts,
two whole-database network views (trait composition, and traits drawn with their
declared anchors), a merged route network per trait, the full trait-to-marker
evidence hierarchy, the curation changelog linked to the traits each entry
affects, an entity map, and a searchable browser over every table. It is the
review surface for curation and the reference that accompanies a database
release. *[Candidate for a supplementary file and a figure.]*

## 6. Implementation and interface

*[Status: written; revisit once the API is frozen for release.]*

gifter is an R package (R >= 4.1) with a deliberately small dependency
surface — DBI, RSQLite and tibble — and its public interface is concept-oriented
rather than relational: users work with traits, anchors, routes, reactions,
enzyme systems and markers, never with SQL keys.

```r
library(gifter)

annotations <- data.frame(
  gene_id   = paste0("gene_", 1:9),
  namespace = "KO",
  accession = c("K00764", "K01945", "K00601", "K01952",
                "K01933", "K01587", "K01756", "K00602", "K01939")
)

result <- evaluate_gifts(annotations)
result$gifts[, c("gift_id", "complete", "number_of_complete_routes",
                 "best_route", "minimum_missing_reactions")]

trace_gift(result, "adenylate_biosynthesis")
gift_graph()
```

Input is a marker table of `namespace` and `accession`; `gene_id` is optional
but is retained through the whole evidence chain when supplied. Namespaces and
accessions are normalised before indexed lookup, and unmatched observations are
kept in the result so that marker use is auditable in both directions —
`map_markers()` reports which annotations were used and which were not.

The database accessors (`list_gifts()`, `get_gift()`, `get_gift_anchors()`,
`get_gift_routes()`, `get_gift_reactions()`, `get_reaction_systems()`,
`get_gift_pathways()`, `gifts_for_pathway()`, `list_facets()`, `get_facets()`,
`gifts_by_facet()`, `gift_profile()`, `database_changelog()`,
`gifter_db_version()`) expose the reference content, and
`validate_gifter_sources()` and `build_gifter_database()` expose the
curation pipeline so that users can extend the database with their own content.

Two implementation rules keep the design honest and are enforced in review.
First, no biological definition may appear in R: adding a trait is a database
change plus tests, never a branch in the code, and per-trait conditionals are
prohibited. Second, traceability is treated as a feature rather than debug
output — an evaluation change that produces a correct Boolean answer without the
evidence responsible for it is a regression.

The test suite encodes the biological invariants directly rather than asserting
return types: OR across routes, systems and markers; AND across required
reactions and components; deterministic closest-route and missing-reaction
reporting; complexes failing when one subunit is absent; alternative systems
supporting the same reaction; multifunctional markers; per-route orientation;
composition through declared anchors only; the absence of implicit edges through
internal intermediates; compartment-split anchors composing only through a
transport trait; within-mode cycle rejection with between-mode acceptance;
weakest-confidence propagation; and independence of the three version fields.

*[Add at submission: runtime and memory for a realistic MAG catalogue; the
recommended annotation upstream; parallel/batch usage over many genomes.]*

## 7. Evaluation

*[Status: PLAN ONLY — no results yet. Nothing in this section may be written
before the corresponding script exists under `manuscript/analysis/` and its
output is committed. Prioritise 7.1 and 7.3; they are the reviewer's first two
questions.]*

Planned analyses, in order of importance:

**7.1 Behaviour under genome incompleteness.** Progressively subsample genes
from complete reference genomes to simulate MAG incompleteness, and compare how
route-based calls and percentage-based module completeness degrade. Hypothesis:
the route-based call is more conservative and, critically, reports *which*
reaction was lost, whereas the percentage decays smoothly and uninformatively.
Report call retention against genome completeness, and the distribution of
`minimum_missing_reactions`.

**7.2 Comparison with existing tools.** On a common genome set, compare
gifter calls with KEGG module completeness and with the pathway summaries of
DRAM and METABOLIC. This is a comparison of abstractions, not a benchmark with a
winner: quantify where the tools agree, and characterise the disagreements by
cause (alternative route, non-homologous enzyme, incomplete complex,
boundary difference).

**7.3 Agreement with observed phenotypes.** Evaluate genomes of organisms with
documented substrate-use or auxotrophy phenotypes and report agreement,
including a frank analysis of the disagreements. Candidate sources: curated
phenotype databases, growth-substrate panels for gut isolates. *[Decide the
reference set; this determines what can be claimed.]*

**7.4 Ecological case study.** Apply gifter to a genome-resolved metagenomic
dataset and show what the trait abstraction adds — for example, separating
public-goods polysaccharide degraders from selfish foragers and cross-feeders
using `resource_strategy`, and identifying candidate auxotrophies through the
derived profile. *[Choose the dataset; a host-associated system with paired
metadata would show the trait framing best.]*

**7.5 Reproducibility of curation.** Report inter-curator agreement on boundary
choice for a sample of traits, or, more modestly, document the curation protocol
and the review record that the biological changelog already provides.
*[Decide whether this is a section or a supplementary note.]*

## 8. Discussion

*[Status: skeleton with argued points; finalise after Section 7.]*

**What the abstraction buys.** The recurring argument of this paper is that the
unit of inference determines what can be said. A gene-set percentage cannot
express alternative routes, complexes or non-homologous replacement, and cannot
name the missing step; a full metabolic model can, but requires gap filling and
sacrifices auditability. A capability defined between curated boundaries and
resolved through explicit Boolean layers keeps both the biological alternatives
and the audit trail.

**Curation is the cost.** Every trait requires a defended boundary, materialised
routes, enumerated enzyme systems and evidenced markers. gifter's answer is
not to reduce that cost but to make it reviewable and cumulative: a
human-readable source of truth, a validator that rejects incoherent structure, a
biological changelog attached to the content, and composition that forbids
duplicating an atomic trait inside a larger one. *[Add: contribution pathway;
whether third-party trait sets are supported.]*

**Limitations, stated plainly.**
1. A positive call is evidence that the machinery is encoded — not that it is
   expressed, active, or relevant in a given environment.
2. Coverage is the current limit. The database is curated rather than
   automatically derived, so absence of a trait is not absence of a capability.
3. Calls inherit the quality of upstream annotation, and inherit the specificity
   of the marker namespace used; sequence-family evidence is weaker than
   orthologue evidence, which is why confidence is propagated to the call.
4. Compartment assignment is a curation claim, not a genomic inference.
5. Boundary choices are defensible modelling decisions, not unique truths;
   different endpoints would yield different traits, which is why every boundary
   carries a documented rationale.

**Outlook.** *[Sketch: broader substrate coverage; nitrogen, sulfur and
respiration traits; community-level aggregation across MAGs with abundance
weighting (the distillR community functionality re-expressed on the new primitive);
evidence namespaces beyond orthology; interoperability with metabolic
modelling as a source of curated, non-gap-filled capability claims.]*

## 9. Availability and reproducibility

*[Status: fill at submission.]*

- Source code: <https://github.com/alberdilab/gifter> *[add release tag,
  Zenodo DOI]*
- Licence: MIT No Attribution (MIT-0)
- Documentation: package manual, architecture guide, and the self-contained
  database atlas published with the package website and reproducible locally
  from the packaged database.
- Reference database version used in this paper: *[version, schema, and the
  upstream Rhea/ChEBI/KEGG releases it was curated against]*
- Analysis code and data for Section 7: *[repository/DOI]*

## Figures

*[Planned; none produced yet.]*

- **Figure 1.** The GIFT abstraction and its Boolean hierarchy, with the purine
  example resolved through all five layers from markers to the call.
- **Figure 2.** Anchors as boundaries: the purine cut points, composition
  through declared anchors, and the derived trait graph.
- **Figure 3.** Compartment and strategy: the same polysaccharide substrate
  resolved as public-goods degradation, selfish foraging and cross-feeding.
- **Figure 4.** Data lifecycle: curated TSV sources, validation, compilation,
  runtime evaluation, and the two version tracks.
- **Figure 5.** Case-study results *[Section 7.4]*.
- **Supplementary.** The interactive database atlas.

## References

*[To be assembled. Minimum set to cite: Rhea; ChEBI; KEGG/KofamScan; UniProt;
Pfam; TIGRFAM; dbCAN/CAZy; DRAM; METABOLIC; MicrobeAnnotator; anvi'o
estimate-metabolism; carveMe; gapseq; ModelSEED; FAPROTAX; Madin et al. trait
database; MAG-recovery and MAG-quality standards (MIMAG); distillR 1.x
application papers.]*

---

## Drafting roadmap

This manuscript is written alongside the software. Each item names what must be
true in the code before the text can be finalised.

| Section | Depends on | Status |
|---|---|---|
| 1. Introduction | Nothing; citations only | Prose complete, citations pending |
| 2. GIFT concept | Stable — architectural fixture | Complete |
| 3. Evaluation model | Boolean layers frozen | Complete |
| 4. Composition and compartments | Compartment model frozen (schema 5) | Complete |
| 5. Reference database | Counts regenerated at submission | Complete, counts to refresh |
| 6. Implementation | Public API frozen for 0.1.0 release | Written, revisit at freeze |
| 7. Evaluation | Analysis scripts + chosen datasets | **Not started** |
| 8. Discussion | Section 7 | Skeleton |
| 9. Availability | Release tag, Zenodo DOI, licence | Pending release |
| Abstract | Everything | Draft, rewrite last |
| Figures | Sections 3, 4, 7 | Not started |

**Open decisions**

1. Target venue, which sets length and whether Section 7 must be a full
   benchmark or an illustrative case study.
2. Case-study dataset for Section 7.4.
3. Phenotype reference set for Section 7.3 — this bounds what can be claimed
   about accuracy.
4. Whether community-level aggregation over MAG abundances (the distillR
   `to.community()` functionality) ships in 0.1.0; if so it needs a section.
5. Author list and contributions.
6. Whether the database release is cited separately (own DOI) from the software.

**Standing rules for this document**

- Refresh every database count and version before submission; regenerate them
  from the compiled database rather than copying from an earlier draft.
- Never write a performance or accuracy number that no committed script
  produced.
- Keep the scope disclaimers of Sections 1 and 8 intact through every revision;
  they are the paper's honest-uncertainty contract, not boilerplate.
