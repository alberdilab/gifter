---
title: "gifter: auditable genome-inferred functional traits with declared completeness contracts"
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
target: "Microbiome (BMC, Methodology) or mSystems (Research article) — Results-first structure"
software_version: "gifter 0.5.0 (in development)"
database_version: "2026.21.3 (schema 7)"
status: "Working draft. Structure follows manuscript/outline.md (agreed 2026-08-22)."
---

<!--
DRAFTING CONVENTIONS
  * Structure follows the venue: Background / Results / Discussion /
    Conclusions / Materials and Methods. See manuscript/outline.md.
  * R1-R3 and R6 describe behaviour that exists in the package today and are
    written as final prose.
  * R4 and R5 are drafted from a stable API and need a worked example each.
  * R7-R10 are results. Never write a number there that has not been produced
    by a committed script in `manuscript/analysis/`.
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

## Background

*[Status: prose complete, citations pending.]*

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
Their measured members are, however, what R9 validates against, and the
distinction between a measured phenotype and a taxonomically propagated one
decides which of them can serve that purpose.

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
membership in a gene set, it asks whether a genome carries sufficient
evidence for **at least one complete known implementation of a biologically
defined capability**, where each capability declares in advance what would
count as a complete implementation. That declaration — the completeness
contract — is curated content rather than a fixed rule applied to every
biological question, which is what allows one framework to treat an
enzymatic route, a cellular structure, a signalling circuit and a defense
mechanism without pretending they are the same kind of object.

We present the primitive and its four completeness contracts (R1), the
single Boolean hierarchy that resolves all of them (R2), the anchor-based
composition and compartment model through which metabolic capabilities
connect (R3), the declared reference frames that make a quantitative trait
interpretable (R4), the community layer that projects curated composition
onto genome-resolved assemblages (R5), and the curated reference database
behind all of it (R6). Sections R7-R10 evaluate the result, and Materials
and Methods describes the curation protocol, schema, algorithm and
implementation.

We state the scope plainly, because a large part of the design is what gifter
refuses to do. gifter reports what a genome *encodes*. It does not model
growth, flux, thermodynamics, media, metabolite concentrations, transport
stoichiometry or cellular mass balance, and a positive call is not a claim about
expression, activity or phenotype in any particular environment.

## Results

### R1. The GIFT: a capability with a declared completeness contract

*[Status: complete.]*

A **genome-inferred functional trait (GIFT)** is a biologically meaningful
capability whose genomic support is evaluated through an explicit, curated and
traceable completeness model. Each GIFT declares a `gift_type` naming the model
under which it is resolved, and four exist:

```text
GIFT
├── metabolic     a directed capability between curated molecular anchors
├── structural    the machinery to build a defined cellular structure
├── regulatory    the machinery to sense a signal and execute a response
└── defense       the machinery to execute a defined defense mechanism
```

A positive call means, in every type:

> The available genomic evidence supports at least one complete known
> implementation of this capability.

The word *implementation* carries the generalisation. In a metabolic GIFT it is
an enzymatic route between declared molecules; in a structural GIFT a curated
architecture; in a regulatory GIFT a signalling circuit; in a defense GIFT a
defense mechanism. `PRPP > IMP`, `L-arabinose > D-xylulose 5-phosphate`,
`flagellar_apparatus`, `aspartate_chemoreception` and
`type_i_restriction_modification` are all GIFTs, and all four types are resolved
by one evaluation (R2) and returned in one table.

**The completeness contract is declared rather than assumed.** This is the
substantive difference from a marker checklist, which applies a single implicit
contract — *what fraction of an expected identifier list was observed* — to
every biological question it is asked. A percentage of expected genes is a
defensible summary for none of the four types and is used for none of them.
Instead, each type names in advance what would count as complete, and the
declaration is part of the curated content rather than a branch in the code.

**A GIFT is not a pathway record.** It is not a KEGG module, an EC list, a KO
list, a gene name or an operon, and gifter boundaries deliberately differ from
external endpoints where the biology justifies it. External resources contribute
chemistry, identifiers and evidence; they do not define the ontology. Links to
external records are stored explicitly, and each must state how the curated
boundaries compare with the external record — `equivalent`, `subset_of`,
`superset_of`, `overlaps` or `related` — so that a familiar identifier never
implies an equivalence the boundaries do not support.

KEGG module M00018, *threonine biosynthesis, aspartate => homoserine =>
threonine*, illustrates the point. It is recorded as `subset_of` three separate
gifter traits, because gifter cuts it at two branchpoints where curated
chemistry genuinely diverges:

```text
L-aspartate
    |   aspartate_semialdehyde_biosynthesis
    v
L-aspartate 4-semialdehyde  ===== branchpoint =====> dap_biosynthesis
    |                                                ectoine_biosynthesis
    |   homoserine_biosynthesis
    v
L-homoserine                ===== branchpoint =====> methionine_biosynthesis_*
    |
    |   threonine_biosynthesis
    v
L-threonine
```

Neither cut is arbitrary. L-aspartate 4-semialdehyde is consumed by
diaminopimelate and ectoine biosynthesis as well as by the route to homoserine,
and L-homoserine is consumed by two curated methionine routes as well as by the
route to threonine. Treating the module as one trait would bury both
branchpoints inside it, and would force the aspartate-to-homoserine head to be
re-curated inside every downstream capability that depends on it. Cutting there
instead curates the head once and lets the module be read back as a traversal of
the trait graph (R3). At database version 2026.21.3 the reference database
carries 204 such external links.

**Each type declares only the boundaries it can defend.** A metabolic GIFT is
declared between curated input and output molecules called **anchors**, which
serve as its public interface and are the sole means by which metabolic traits
compose (R3). The other three types declare no anchors at all. A flagellum has
no input molecule and no output molecule; inventing one so that structural
content would fit the metabolic schema would be a boundary claim nobody could
defend, and the asymmetry is therefore preserved in the schema rather than
smoothed over. A structural, regulatory or defense GIFT is individually
callable and individually traceable, and simply does not participate in
anchor-based composition.

**Completeness is discrete in every type.** A GIFT is complete when at least one
of its curated implementations is fully supported, and incomplete otherwise.
An incomplete call names the closest implementation and states what is missing
from it — one reaction, or one structural function — never a fraction of
expected genes. The consequences of this choice for diagnosis are the subject of
R2.

### R2. One Boolean hierarchy resolves four capability types

*[Status: complete.]*

gifter separates biological meaning, chemistry or architecture, molecular
machinery and genomic evidence into five layers that alternate strictly between
disjunction and conjunction:

```text
GIFT
  |
  +-- OR --> IMPLEMENTATION
                   |
                   +-- AND --> required REQUIREMENT
                                     |
                                     +-- OR --> SYSTEM
                                                   |
                                                   +-- AND --> COMPONENT
                                                                   |
                                                                   +-- OR --> MARKER
```

In Boolean form:

```text
GIFT             = ANY complete implementation
implementation   = ALL required requirements
requirement      = ANY complete system
system           = ALL required components
component        = ANY accepted genomic marker
```

The four `gift_type` values are not four models. They are this one hierarchy
under four vocabularies, and the naming is the only thing that changes:

**Table 1.** The five-layer hierarchy across the four GIFT types, with entity
counts at database version 2026.21.3.

| `gift_type` | Implementation | Requirement | System | Component |
|---|---|---|---|---|
| metabolic | route (204) | reaction (432) | enzyme system (495) | enzyme component (595) |
| structural | architecture (3) | structural function (17) | structural system | structural component (36) |
| regulatory | circuit (4) | regulatory function (10) | regulatory system (13) | regulatory component |
| defense | mechanism (5) | defense function (14) | defense system (20) | defense component |

Because the shape is shared, one call evaluates a mixed-type database and the
result carries a type-neutral answer for every GIFT — `best_implementation`,
`minimum_missing_requirements` and `missing_requirements` — beside the
type-specific columns. Those columns are a consequence of the model rather than
a convenience of the interface.

Each layer exists because it solves a biological problem that the adjacent
layers cannot:

| Layer | Represents | Collapsing it would lose |
|---|---|---|
| Implementations (OR) | Alternative ways to achieve the same capability | Alternative routes; alternative architectures |
| Requirements (AND) | The chemistry or the parts the implementation needs | Which step or which part is missing |
| Systems (OR) | Alternative machinery for one requirement | Non-homologous replacement |
| Components (AND) | Proteins jointly required by a complex | Partial complexes |
| Markers (OR) | Alternative evidence for the same protein | Annotation redundancy |

A flat `marker -> trait` mapping conflates all five. This is the concrete reason
the redesign was necessary: the four situations that a percentage cannot
distinguish are separated by exactly these five layers, and by nothing else.

#### R2.1 Implementations are materialised, not evaluated as expressions

Alternative implementations are expanded at build time into separate records
rather than stored as runtime Boolean expressions:

```text
route_1 = R1 AND R2 AND R3
route_2 = R1 AND R2 AND R4
```

is preferred over `R1 AND R2 AND (R3 OR R4)`. This duplicates small membership
lists but never duplicates the reaction, system, component or marker definitions
themselves, and it reduces the runtime rule to a single sentence that holds in
every type: **all required requirements of any one implementation**. Optional
requirements are recorded but do not affect the call.

#### R2.2 An incomplete call is the informative one

An incomplete GIFT is more useful than a complete one, and gifter reports it
accordingly. For every GIFT the result gives the closest valid implementation,
the minimum number of missing required requirements, the identity of those
requirements, the requirements that were supported, and the systems, components,
markers and genes behind each decision. Implementation selection and
tie-breaking are deterministic (M4).

"One reaction missing from route *X*, namely RHEA:*n*" and "one structural
function missing from the *Vibrio*-type architecture, namely the distal rod" are
statements a biologist can act on. "87% complete" is not: it is consistent with
an alternative route, a non-homologous enzyme, one absent subunit, or a gap in
the annotation, and it distinguishes none of them. A normalised score is
retained for plotting and ranking, but it is a secondary summary and never the
call.

#### R2.3 Evidence confidence reaches the call

Each marker-to-component mapping carries a qualitative confidence term
(`curated`, `high-confidence`, `putative`, `ambiguous`, `insufficient
evidence`). Each call reports `evidence_confidence`: the weakest term among the
markers supporting its best implementation. The terms are ordered and never
averaged into a score, because a call is only as strong as its weakest accepted
marker. At database version 2026.21.3, of 1,315 mappings, 866 are `curated`,
293 `high-confidence` and 156 `ambiguous`.

This matters most for sequence-family markers, where a family is not an
activity. Polyspecific CAZy families such as GH5, GH13, GH30 and GH43 would
silently attribute every activity in the family to a genome carrying any member;
gifter prefers dbCAN subfamily accessions where they exist, accepts a bare
family only where it is effectively monoactivity, records the reason, and marks
the mapping `ambiguous` where it is not. A trait resting on an ambiguous family
must not read like one resting on curated orthology, and propagating the weakest
term is what prevents it from doing so.

#### R2.4 The specificity of a claim never exceeds the specificity of its evidence

The same principle produces a merge in one case and a split in another, and the
pair shows that it is a rule rather than a preference.

KEGG assigns the sodium-driven PomA/PomB stator of *Vibrio* to the same
orthologues as the proton-driven MotA/MotB of *Escherichia coli*. Two traits
distinguished by ion coupling would therefore be indistinguishable in evidence,
so gifter curates one ion-agnostic `flagellar_apparatus` rather than two traits
its markers cannot separate.

Where evidence does separate two claims, both are curated and kept apart. A
generic chemoreceptor accession is assigned to 34 genes in a single *Vibrio
cholerae* genome, so it supports `chemotaxis_signal_transduction` and nothing
narrower; the Tar orthologue is anchored on a characterised ligand, so it
additionally supports `aspartate_chemoreception`. A genome carrying only the
generic receptor completes the first and not the second, and the correct
response is never to widen the generic marker until it does.

Every such refusal is recorded in the curation changelog that ships inside the
database (M3), so a boundary that was declined is as auditable as one that was
drawn.

#### R2.5 Worked example

*[Status: expand into a full figure-backed walkthrough once the case-study
dataset is chosen. The purine example below is stable and is retained as an
architectural fixture in the test suite.]*

Given a marker table of KEGG orthologue accessions, `evaluate_gifts()` resolves
every GIFT in the database, of any type, and returns a list of tibbles — `gifts`,
`routes`, `reactions`, `systems`, `components` and `evidence`, plus `structural`,
`regulatory` and `defense` views — that share stable identifiers.
`trace_gift(result, "adenylate_biosynthesis")` returns the long-form path from
the called route through its reactions, selected enzyme systems and required
components to the observed markers and, where supplied, the gene identifiers
responsible. `trace_gift(result, "flagellar_apparatus")` returns the same shape
of evidence through architectures and structural functions.

### R3. Anchors bound metabolic traits and compose them without duplication

*[Status: complete. This section concerns the metabolic type alone; the other
three types declare no anchors and do not compose (R1).]*

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

#### R3.1 Cycles are a design constraint, not a formality

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

#### R3.2 A deliberately narrow compartment model

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

#### R3.3 Facets and the derived profile

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

### R4. Quantitative traits are reported only against a declared frame

*[Status: drafted from a stable API; needs a worked example and Figure 4.]*

Calls are the primary result. A quantitative layer summarises sets of them
without changing any, and every number it produces carries the set it was
counted over.

**What a quantitative trait is.** Once every GIFT has been called supported or
unsupported for a genome (R2), the obvious next step is to count: how many
capabilities does this organism encode, how varied are the substrates it acts
on, how much of some biological space does it cover. Those counts are what we
call quantitative traits, and they are what actually reaches downstream
analysis — ordinations, comparisons between hosts or treatments, correlations
with a measured phenotype. They are also the point at which a result stops
being self-explanatory. A call names its own subject: *this genome supports
adenylate biosynthesis*. A count does not.

**A quantitative trait is uninterpretable without its denominator.** "This
genome supports 14 GIFTs" is not yet a statement about the genome. Fourteen of
the curated host-glycan-foraging capabilities and fourteen of everything the
database curates are entirely different biological claims, and the number 14
carries no trace of which one it is. Proportions are worse, because they look
self-contained: `0.6` reads as *this organism has six tenths of something*,
and whether that something is a meaningful biological whole or an arbitrary
slice of a curation effort is invisible in the number. Two studies can report
the same statistic, computed over different sets, and be compared as though
they measured the same thing.

**A reference frame is that set, made explicit and citable.** A frame is
a named, curated object in the database that states which GIFTs a metric is
counted over, the biological question that set answers, which metrics are
appropriate in it, and what the resulting numbers may not be read as. At
database version 2026.21.3 the database ships 19 of them — carbohydrate
degradation, plant fibre utilisation, host glycan foraging, nitrogen and
sulfur acquisition, fermentation products, vitamin biosynthesis, amino acid
autonomy and others. Every metric gifter reports names the frame it was
computed in and the database version it was computed against, so a number
remains readable away from the session that produced it.

**Membership is a query, not a list.** A frame does not store the
identifiers of its members. It stores a rule over curated metadata — trait
type, mode, the registered facet vocabulary of R3.3, the derived profile —
and its membership is resolved against the database release in use.
Amino-acid autonomy is three clauses: `mode = anabolic`, the trait facet
`substrate_class = amino_acid`, and the derived `auxotrophy_indicator`,
which is true when a trait's declared output anchor carries the anchor facet
`biomass_essential = yes`. The rule selects 22 of the 37 curated GIFTs in
the amino-acid substrate class, and the fifteen it rejects show what each
clause does. `threonine_deamination` fails on mode: its substrate is an
amino acid, but it consumes one rather than producing one.
`homoserine_biosynthesis` fails on the derived clause: it is anabolic and
its substrate class is amino acid, but homoserine is a branchpoint
intermediate rather than a residue a growing cell must obtain, so its output
anchor is curated `biomass_essential = no`. `threonine_biosynthesis` — the
next step on the same carbon, from that same homoserine — passes all three,
because `THREONINE` is a building block and `HOMOSERINE` is not. The frame
names none of the three.

Membership therefore moves when curation moves, with no edit to the frame.
Release 2026.19.1 corrected `ASPARTATE` and `GLUTAMINE` from
`biomass_essential = no` to `yes`: both are proteinogenic, and both had been
curated `no` while they existed in the database only as input boundaries to
other chemistry. The correction touched one facet on two anchors. The
derived profile recomputed, `aspartate_biosynthesis` and
`glutamine_biosynthesis` acquired `auxotrophy_indicator`, and amino-acid
autonomy covered all twenty proteinogenic amino acids on the next build —
while no Boolean call anywhere in the database changed, because the facet is
read by the derived profile alone. A stored list would have had to be
maintained in parallel with the curation it describes, and would have
silently drifted out of agreement with it.

**gifter refuses a fraction it cannot defend.** Each frame declares whether
it is `bounded`: whether curation intends to cover that biological space
completely. The distinction decides what an unsupported member is allowed to
mean.

| | Bounded frame | Unbounded frame |
|---|---|---|
| Example | Amino-acid autonomy | Carbohydrate degradation |
| The underlying biology | Closed and enumerable — the proteinogenic amino acids are a known, finite set | Open-ended — the polysaccharides microorganisms degrade are not an enumerable list |
| Curation intent | Every member the question needs is curated | A growing, deliberately incomplete selection |
| An unsupported member means | The genome plausibly lacks that capability | Either the genome lacks it, or the database does not yet curate it |
| `supported_fraction` | Reported | Refused |

Reporting that a genome supports 12 of 139 curated metabolic GIFTs would
invite the reading that it lacks 127 capabilities. It mostly means the
database curates 139 capabilities so far. gifter therefore offers no
fraction of the catalogue at all, and offers `supported_fraction` only
within a bounded frame, where the denominator is a biological whole rather
than a snapshot of curation progress. Four of the 19 shipped frames are
bounded — biomass- essential anabolism and the amino-acid, nucleotide and
cofactor autonomy frames nested inside it — which makes the refusal the
ordinary case rather than an edge case, and makes `supported_fraction` a
number that means what it appears to mean wherever it is reported at all.
Unbounded frames still report counts, richness and breadth, which are honest
as counts; what they do not report is a percentage of a set that has no
defensible size.

**Every metric names the GIFTs behind it.** `genome_traits()` returns metrics
beside a trace, so a richness value resolves to the specific calls that
produced it, and each of those resolves through R2 to the annotated genes. A
number in a figure is therefore never a dead end: the path from a point in an
ordination back to a gene identifier is open at every step.

**Absences on fragmented genomes are withheld rather than counted.** Presence
and absence are not symmetric evidence on a MAG. A capability that is called
supported was supported by markers that were actually observed, and incomplete
assembly does not manufacture them. A capability called unsupported on a genome
recovered at 55% completeness may simply sit in the fraction that was never
assembled. Counting such absences in a denominator converts assembly quality
into apparent biology, and does so in a direction that correlates with sample
depth, host species and extraction protocol.

gifter makes the choice explicit rather than choosing silently. Under the
default policy every negative call is counted, exactly as a Boolean analysis
would, and the output carries `assessable_fraction` to state that this is
what happened. Under the completeness policy the analyst supplies genome
completeness estimates and a threshold, and every negative call on a genome
below that threshold is treated as indeterminate and removed from every
denominator; `assessable_fraction` then reports how much of the frame the
data could actually speak to. No threshold is supplied by default, because
how complete a genome must be before its silence is informative is a
judgement about the study, not a constant. The policy is deliberately blunt
— a per-capability model of gene loss from fragmented assemblies would imply
a precision gifter cannot support — and it changes only the reading of
absence: no policy can turn an unsupported GIFT into a supported one. This
is the methodological counterpart of R7.

*[Add: worked example over a real MAG catalogue; the bounded/unbounded contrast
shown on one figure.]*

### R5. Capability distribution and potential handoffs across a community

*[Status: drafted from a stable API; needs a worked example and Figure 5.]*

A genome-resolved community is a set of per-genome results, and the community
layer asks how curated capability is distributed across it.

**Evaluation is per genome, always.** `evaluate_gifts_community()` splits one
annotation table on its `genome_id` column, evaluates every genome separately
and in parallel, and returns the community container. A genome evaluated inside
a community is identical to the same genome evaluated alone, and the number of
workers changes wall time and nothing else. Pooling genomes before evaluation
would manufacture capabilities no organism encodes, so the interface refuses it:
an input carrying more than `max_genes` distinct genes is questioned as a
possible collection of genomes rather than silently evaluated as one.

**Distribution metrics.** `community_traits()` reports community richness,
provider counts per GIFT, singletons and redundancy, and abundance coverage.
Presence and abundance are separate arguments because they answer separate
questions and carry separate costs: how many genomes encode a capability is not
how much of the community does.

**Potential handoffs are projected, never invented.** `community_network()`
introduces no compatibility rule of its own. The curated composition graph (R3)
already decides when one GIFT's output meets another's input; the community layer
projects that decision onto the genomes that carry them. An edge additionally
requires the producing GIFT's output anchor to be **extracellular**, so a
cytoplasmic molecule never crosses between genomes, and a genome that supports
both ends composes the chain internally and produces no edge at all. Every edge
carries the `edge_quality` of the curated edge beneath it, so a traversal that
crossed an unresolved compartment cannot be read as a fully resolved claim.

**An edge is a potential compatibility relationship.** It states that one genome
encodes a capability whose declared extracellular product another genome's
capability can consume. It is not evidence that the exchange occurs, that the
organisms co-occur, or that either capability is expressed.

*[Add: worked example on the case-study community; Figure 5.]*

### R6. The curated reference database

*[Status: complete; regenerate every count at submission.]*

The biological content is a curated resource in its own right, versioned and
released independently of the code (M3). Its scale at the version used here is
given below; the curation protocol, schema and validation are described in
Materials and Methods.

**Table 2.** Reference database content at version 2026.21.3 (schema 7).

*[Regenerate at submission — this content grows continuously.]*

| Entity | Count |
|---|---|
| GIFTs (total) | 149 |
| — metabolic | 139 |
| — structural | 2 |
| — regulatory | 3 |
| — defense | 5 |
| Anchors | 154 |
| Reactions | 432 |
| Routes | 204 |
| Enzyme systems | 495 |
| Enzyme components | 595 |
| Markers | 1,271 |
| Marker-to-component mappings | 1,315 |
| External pathway links | 204 |
| Reference frames | 19 |
| Curation changelog entries | 112 |

Current metabolic content spans amino acid biosynthesis and catabolism (37

traits), cofactor and vitamin biosynthesis (22), aromatic compound degradation
(17), central metabolic branchpoints (9), plant and host polysaccharide
degradation (9), methylated amine and one-carbon metabolism (7), monosaccharide,
amino-sugar and uronate catabolism (11), nucleotide biosynthesis (5), organic
acid and short-chain fatty acid formation (8), and inorganic nitrogen and sulfur
transformations (7). Non-metabolic content covers the flagellar apparatus and
type IVa pilus; chemotaxis, aspartate chemoreception and phosphate-response
signalling; and type I restriction-modification, type I-E CRISPR-Cas and
mercury-detoxification machinery. *[Extend as curation proceeds; state the
target scope for the release accompanying this paper.]*

Evidence is dominated by two namespaces: of 1,271 markers, 743 are KEGG
orthologues and 520 are CAZy or dbCAN accessions, with small numbers of TIGRFAM,
EC and Pfam entries. The confidence distribution of the 1,315
marker-to-component mappings is reported in R2.3. These figures are stated
plainly because they are the resource's honest self-description: a database
whose carbohydrate content rests substantially on sequence-family evidence must
be read with R2.3 in view. What each upstream resource contributes, and what it
is not permitted to decide, is set out in Table 3.

`write_gifter_database_html()` renders the whole compiled database as a
single, self-contained interactive HTML report: release metadata and row counts,
two whole-database network views (trait composition, and traits drawn with their
declared anchors), a merged route network per trait, the full trait-to-marker
evidence hierarchy, the curation changelog linked to the traits each entry
affects, an entity map, and a searchable browser over every table. It is the
review surface for curation and the reference that accompanies a database
release. *[Candidate for a supplementary file and a figure.]*

<!--
R7-R10 ARE RESULTS. Nothing below may be written as prose before a committed
script under `manuscript/analysis/` has produced it. Priority order is
R7 > R10 > R9 > R8: R7 is the reviewer's first question, R10 is what makes this
a Microbiome/mSystems paper rather than a software note.
-->

### R7. Behaviour under genome incompleteness

*[Status: NOT STARTED — submission blocker. Needs
`manuscript/analysis/01-incompleteness.R` and a reference genome set.]*

**Design.** Progressively subsample genes
from complete reference genomes to simulate MAG incompleteness, and compare how
route-based calls and percentage-based module completeness degrade. Hypothesis:
the route-based call is more conservative and, critically, reports *which*
reaction was lost, whereas the percentage decays smoothly and uninformatively.
Report call retention against genome completeness, and the distribution of
`minimum_missing_requirements`. A second panel should show that the
assessability policy of R4 recovers interpretability that a naive denominator
destroys.

### R8. Comparison with existing tools

*[Status: NOT STARTED. Needs a common genome set and tool runs.]*

**Design.** On a common genome set, compare
gifter calls with KEGG module completeness and with the pathway summaries of
DRAM and METABOLIC. This is a comparison of abstractions, not a benchmark with a
winner: quantify where the tools agree, and characterise the disagreements by
cause (alternative route, non-homologous enzyme, incomplete complex,
boundary difference). The classification of disagreements is the result, not the
agreement rate.

### R9. Agreement with observed phenotypes

*[Status: written from the committed tables of `manuscript/analysis/output/`,
produced by `03-phenotype.R`, `04-auxotrophy.R`, `05-annotation-route.R`,
`06-figure-phenotype.R` and `07-madin.R` at database 2026.27.1. Backed by
Figure 8.]*

A capability call is not a phenotype prediction, so a section comparing the two
has to settle in advance what a disagreement means. Under the scope statement of
the Background, a positive call says that the genomic evidence supports at least
one complete known implementation of a capability: a *necessary* condition for
the phenotype, not a sufficient one. Expression, regulation, transport and assay
conditions all sit between the call and the observation, and gifter models none
of them. The two directions of disagreement therefore mean different things, and
a statistic that averages them destroys the only information it had.

**The statistic, and the reason it is not accuracy.** An organism that encodes a
capability and does not show it is **permitted**: regulatory silence, a missing
transporter, an assay run under conditions the pathway does not operate in, or a
strain–genome mismatch all produce that cell, and scoring it as a false positive
would assert precisely the claim the model declines to make. An organism that
shows a capability its genome does not support is a **failure**, and it is the
only cell that is a result about gifter. R9 therefore reports **recall against
observed-positive phenotype, per target, with the size and the taxonomic spread
of each test set stated beside it**, together with a classification of every
disagreement. No accuracy, precision, F1, MCC or AUC appears in the section, and
the helper that computes the two-by-two deliberately offers none of them to
compute. No rate is pooled across targets either: the targets differ so much in
how testable they are that a pooled figure would describe the test set rather
than the tool. For the same reason no confidence interval is attached — the test
sets are strongly clustered taxonomically, and a binomial interval would assume
an independence between strains that does not hold.

**Reference sets.** BacDive is the primary reference: strain-resolved measured
phenotypes with linked genome assemblies, joining onto three identifier
systems gifter already carries — ChEBI metabolites onto declared anchors, EC
activities onto reaction cross-references, and INSDC accessions onto the
genome under evaluation. A sweep of the whole resource returned 102,187
records, of which 3,081 strains carry an assembly that resolves to a genome in
the reference set; 1,577 of those genomes carry at least one usable
observation. MediaDive's chemically defined media cover the anabolic half, and
the Madin trait synthesis is a second, species-level catabolic reference whose
independence from BacDive is what it is used for.
Everything BacDive labels as a genome-based prediction is dropped at
ingestion, because a reference set that quietly contained another tool's
genomic inferences would make R9 a tool comparison with the wrong label on it.
FAPROTAX is **refused** as a reference: it propagates function by taxonomic
name rather than observing it, so a disagreement cannot say which side was
wrong, and its discriminating categories are the electron-acceptor class this
framework declines by design. It belongs in R8 as one more abstraction to
compare with.

The mapping from an observation to something gifter claims is curated rather
than mechanical. `phenotype-crosswalk.tsv` holds 56 reviewed rows across the
three adopted sources, all of them exercised, each
carrying an explicit boundary relation from the vocabulary the database
already uses, and only `equivalent` and `subset_of` rows may enter a recall
table. The `kind of utilization tested` field is part of the claim rather than
metadata: an API-panel acidification is a fermentation observation and only
`subset_of` "degrades this substrate", so it is kept as a separate row from a
growth-on-substrate record of the same sugar. Free sugars needed one further
piece of curation, because BacDive records the parent compound where the
anchors are anomeric and charge-resolved — the anchors inherit that resolution
from Rhea's participants — and the bridge between them is a reviewed alias
table rather than an automatic traversal, which would turn a specific anchor
into a compound class.

**The catabolic half.** Thirty crosswalk rows reached the genome set, yielding
12,531 strain–target observations over 1,577 genomes; 21 of those rows, covering
17 distinct targets, are recall-usable at *n* ≥ 20 and are what Figure 8a draws.
Recall is highest where the observation is an EC-resolved enzyme assay, which is
the layer that needs no phenotype caveat at all: α-L-arabinofuranosidase 1.000
(*n* = 121, 79 genera), α-L-fucosidase 0.912 (*n* = 874, 442 genera), urease
0.866 (*n* = 1,012, 481 genera), α-glucosidase 0.825 (*n* = 856), glutamate
decarboxylase 0.818 (*n* = 121) and arginine deiminase 0.791 (*n* = 622). At the
GIFT layer, where the whole necessary-not-sufficient argument applies, urea
hydrolysis reaches 0.822 (*n* = 661, 330 genera) and indole formation 0.721
(*n* = 1,011, 492 genera).

Two low rows are worth naming rather than burying. Tryptophanase activity scores
0.348 (*n* = 361) at the reaction layer while indole production — the same
capability, observed the other way — scores 0.721 at the GIFT layer, and the
reference-consistency measurement below shows that most of that gap is the
reference disagreeing with itself. N-acetylglucosamine utilisation scores 0.205
(*n* = 229), which is a real under-call and was curated against: reading the
disagreements down to the reaction identified a second route through the PTS,
and curating it raised the figure from 0.128 on a matched test set. Two further
leads read the same way — histidine biosynthesis was curated in 2026.25.1, while
a serine lead was measured and the proposed second route was **not** curated
because the premise did not survive the measurement.

Where the same substrate carries both kinds of test, the acidification panel
scores consistently higher than the growth or assimilation record: L-arabinose
0.562 against 0.294, D-galactose 0.759 against 0.557, L-rhamnose 0.667 against
0.098, D-xylose 0.816 against 0.769. The two rows are different claims measured
on different strain sets, so the gap is not a single effect with a single cause;
what it does show is that collapsing them into one number per substrate — which
is what a crosswalk without the `kinds` column would do — would have produced an
average of two things that are not the same observation.

**A second reference tests the crosswalk rather than the catalogue.** The Madin
trait synthesis is a species-level compilation of published trait records, and
16 crosswalk rows reach it. Its intersection with the reference genome set is
3,738 species covering 6,377 genomes, and eight targets reach *n* ≥ 20 there.
Its value is not additional *n*: it is that a reference assembled by different
people from different evidence makes the acidification-versus-growth split above
a falsifiable prediction. Madin's `carbon_substrates` records substrate use, so
it should track BacDive's growth records and diverge from its acidification
panels. It does, and by a wide margin — the mean absolute difference from
BacDive's carbon-source rows is **0.057** and from its acidification rows
**0.274**. Two of the five growth comparisons agree to within 0.015 (L-arabinose
0.309 against 0.294, D-galactose 0.559 against 0.557), while every acidification
comparison is at least 0.15 apart and L-rhamnose is 0.487 apart. The `kinds`
column is not bookkeeping; it separates two claims that two independent
references also separate.

That reference costs a join the strain-resolved one does not, and the cost is
measured rather than assumed. A Madin record names a species, 574 of the shared
species carry more than one reference genome, and gifter calls each genome
separately, so a representative has to be chosen. Across all targets the genomes
of one species agree on the call **90.8%** of the time — from 98.1% on
phenylacetate down to 79.3% on the flagellar apparatus — and repeating every
recall over 100 independent draws of the representative moves no figure by more
than 0.013. That range is the sensitivity of a number to a choice the reference
cannot make; it is not a confidence interval, and the clustering argument above
applies to this test set exactly as it does to the others.

Two targets reach *n* ≥ 20 here and nowhere else, which is why the coverage row
below moves. Galacturonate degradation scores 0.400 (*n* = 20). Phenylacetate
degradation scores **0.000** over 32 species, and that is a curation lead rather
than a rounding artefact: gifter calls the capability complete in 215 of 11,908
reference genomes, and 31 of the 32 failures name a missing requirement on the
closest route rather than an absence of evidence, 17 of them three reactions
short. Motility reaches 1,869 species, the structural type's only external check
at scale, and stays outside the recall table for the same reason BacDive's does
— `flagellar_apparatus` is narrower than motility, so the relation is
`superset_of` and the observation cannot imply the target.

**The disagreements are the result; the ratio is its summary.** Across the 21
primary rows, 1,569 genomes fall in the permitted cell and 705 in the failure
cell. Every failure carries gifter's own trace, so the classification is
mechanical rather than anecdotal: 489 name a specific missing requirement on the
closest route, and 216 carry no evidence for the capability at all. The
distinction matters because the two have different remedies — a named missing
step is a curation lead, while an absence of evidence is either an annotation
gap or a genome that genuinely lacks the machinery, and the annotation route
below is what separates those. The failures are also taxonomically concentrated:
*Streptomyces* (31), *Paraburkholderia* (21), *Corynebacterium* (19) and
*Burkholderia* (15) lead the list, so the Actinomycetota and the
Burkholderiaceae carry a disproportionate share of them. That concentration is
reported beside every count, and it is the reason the section attaches no
interval to any rate.

**The anabolic half is tested the same way, not the opposite way.** The design
anticipated that auxotrophy would invert the polarity and make a *positive* call
refutable, and it does not: MediaDive records the media a strain grows on and
nothing else, so every medium–strain row carries growth, and the falsifiable
cell is still the unsupported call. What defined media buy is leverage rather
than polarity. A strain that grows on a chemically defined medium containing no
L-tryptophan makes its own L-tryptophan, so one growth observation tests every
anabolic capability whose product the medium omits, and 264 strain–medium pairs
over 201 genomes become 9,050 nutrient-level tests. Where the medium does supply
a nutrient — a vitamin solution, casamino acids — the test is void rather than
negative, and the ingredient list says which; media whose composition is less
than three-quarters resolvable to identifiers are dropped rather than counted,
because a medium that cannot be read cannot support the inference that a
nutrient is absent. The strain-to-genome join runs through the same BacDive
sweep as the catabolic half, so the two halves of this section are measured on
one reference set; a recall is only comparable with another taken from the same
sweep, and that rule is applied to these tables and not only to the literature.

Two constraints bound the premise and both are stated rather than absorbed.
It holds only where the nutrient is biomass-essential: menaquinone is not
universal, and an organism handed ammonium has no reason to fix nitrogen at all,
so those classes are measured and reported (menaquinone 0.091, ammonium 0.508)
but excluded from the headline, because a low rate there is a false question
rather than a failed call. And alternative curated routes to one product must be
OR-ed rather than required separately, since an organism needs either the
sulfide or the homocysteine route to cysteine and testing them individually
scores whichever it does not use as a failure. Restricted to the
biomass-essential classes and with alternatives OR-ed, recall is **0.844 over
5,803 tests**.

This is also the only external check the quantitative layer of R4 has ever
had, and the bounded frames are what make it possible: a proportion is emitted
against them only because curation declares their coverage complete, so a
strain growing on a mineral medium should score 1.0 and every point below is a
named, traceable, falsified call. On strains observed to grow on media
supplying none of it, **170 of 201 genomes score a full 1.0 on
`nucleotide_autonomy`**; 7 do on `amino_acid_autonomy` and none on
`cofactor_autonomy`. Per nutrient, the nucleotide rows run from 0.905 to 0.996
and the amino-acid rows from serine's 0.302 to the 0.979 of glycine and valine,
while the cofactor rows have a median of 0.531. The cofactor row is the honest
one to dwell on: the cofactor classes contribute 1,404 of the 2,470 failing
tests, and menaquinone, DMB, cobalamin, PLP and folate alone account for 906 of
those — the first three being exactly where the biomass-essential premise is
weakest. The anabolic test set is clustered too, and differently from the
catabolic one — *Methanocaldococcus* (128 failing tests),
*Acidithiobacillus* (93), *Nitrosopumilus* (86) and *Geobacter* (59) lead its
failures across 155 genera, because defined media are written for methanogens,
chemolithotrophs and anaerobes, not for the taxa a clinical phenotype panel
covers.

**The reference measured against itself.** Where BacDive records one capability
twice through independent assays, the two records bound how well any caller could
possibly score, and that bound has to be measured before any recall above it is
interpreted. Urease activity and urea utilisation agree on 560 of 563
genome-backed strains (16,350 of 16,364 across the whole reference), which is as
clean as a reference gets. Tryptophanase activity and indole production agree on
only 321 of 351, disagreeing in both directions — 19 strains produce indole with
no tryptophanase recorded, 11 the reverse. The indole recall of 0.721 and the
tryptophanase recall of 0.348 therefore sit under very different ceilings, and
the second figure should not be read as a statement about the model without the
first beside it.

**The annotation route, and what it costs.** Everything above runs on KEGG's
own per-genome KO assignment. That assignment is curated and orthology-resolved,
and it is not what a user's annotator produces, so every figure above is an
upper bound. How large a bound has not been reported for a comparable tool, so
it is measured here: 398 genomes drawn from both test sets, annotated with a
pinned pipeline at each library's own published cutoffs — KofamScan's adaptive
per-profile thresholds for KO, NCBIfam's curated GA cutoffs for its profiles,
and run_dbcan's E-value and coverage filter for dbCAN, with the E-value computed
against the whole 53,411-profile library rather than the curated subset of it.
Gene calling is held fixed: the proteins searched are the deposited protein set
of the same assembly the KEGG entry names, so what is measured is the cost of
assigning markers, not of calling genes. A MAG pipeline pays a further penalty
at the gene-calling step, and R7 is where that belongs.

The difference has two signs, and reporting one number would hide both. Against
21,771 complete calls on the KEGG route, KofamScan alone returns **19,735 —
90.6%**. That 9.4% is the annotation cost, and it is what a reader should
subtract from every recall above. Reading the namespaces the KEGG route cannot
reach at all — NCBIfam, dbCAN and Pfam — returns **20,955, or 96.3%** of the
KEGG route from a pipeline anyone can run.

Neither figure is uniform, and the per-GIFT table is the result rather than the
totals. The annotation cost falls hardest on biosynthetic capabilities with long
routes, where losing any one marker loses the call: pyrimidine core biosynthesis
drops from 350 genomes to 162, NAD biosynthesis from 336 to 209, and the
`flagellar_apparatus` from 157 to 95. The recovery falls almost entirely on
carbohydrate chemistry, where CAZy is the evidence and orthology never was:
`arabinoxylan_debranching` rises from 42 genomes to 322, `starch_degradation`
from 61 to 302, `xylan_degradation` from 25 to 177. Six GIFTs the KEGG route
cannot call in a single genome are called on the annotation route —
`mucin_galnac_release` in 222 of the 398, `siroheme_to_heme_b` in 52,
`assimilatory_sulfate_reduction` in 49, `pectin_degradation` in 33. Across the
catalogue 47 GIFTs come out ahead of the KEGG route and 82 behind, which is the
honest shape of the comparison: an annotator is worse at the orthology KEGG
curates by hand and better at everything KEGG does not carry.

This is also the only place part of the curation is visible at all. Database
2026.25.1 admitted nine NCBIfam equivalogs to the two histidine biosynthesis
steps that orthology splits across unrelated families. On a KO-only genome set
that curation cannot appear, by construction. Here it does: histidine
biosynthesis is called in 160 of the 398 genomes from KofamScan's KO assignment
alone and in 206 once the NCBIfam profiles are read, and at the nutrient level
the equivalogs recover 10 of the 39 tests the annotation route otherwise loses.
The same holds for the amino-sugar equivalogs of 2026.26.1. Curation aimed at a
namespace an evaluation cannot see is curation that evaluation will score as
worthless; running the annotator is what makes it measurable.

At the reaction layer the two directions are visible in single rows. Urease
recall falls from 0.822 to 0.711 — annotation cost, plainly. α-glucosidase
falls from 0.852 to 0.667 on KO evidence alone and then rises to **1.000**
once dbCAN is read, and β-N-acetylhexosaminidase ends at 0.875 against the
KEGG route's 0.719. On the anabolic half, restricted to the biomass-essential
classes, recall runs 0.844 on the KEGG route, 0.774 on KofamScan alone and
0.776 with every namespace read; the anabolic content is orthology-shaped, so
there is little for the other namespaces to give back.

Two things follow for anyone reading the rest of the section. Subtract about a
tenth from the catabolic recalls to get what a user's own annotation would
produce, more where the capability is a long biosynthetic route and less where
it rests on CAZy. And note that the composed measurement is what a user
experiences: gifter is only ever as good as the markers it is handed, which is
why every call carries the evidence that produced it.

**Coverage, stated in the section itself.** Measured rather than estimated:
**17 of 153 GIFTs are individually testable** at *n* ≥ 20 — two of them only
because the second reference exists — a further 44 only as a bounded-frame
aggregate, and the remaining 92 have no phenotype reference
of any kind. Figure 8e names what falls in each. The 92 are not a gap another
database would close: they are the aromatic catabolic layer, most amino-acid
catabolism, the cofactor and nucleotide interior, every anchor-to-anchor
segment that is not a growth substrate, and all three regulatory and all five
defense GIFTs. Nobody has measured those at scale, and for the regulatory and
defense types the observation would not be a phenotype in the assay sense in
the first place.

Coverage of this kind is not only a limit; read the other way it is a
prioritisation signal, naming the capabilities whose absence from the catalogue
costs the most external testability. Counted over the second reference — 106
carbon substrates, each scored by the number of species with a reference genome
behind them — the five most-measured are ones no curated boundary can be tested
against: glucose (364 species), maltose (275), mannose (263), fructose (228) and
sucrose (227). All five outrank L-arabinose (216), the best-covered substrate
gifter *can* be tested on, and mannitol (183), trehalose (169) and cellobiose
(165) all outrank D-xylose (150). Sixteen of the 106 terms carry a reviewed
crosswalk row.

The absence is not an oversight in every case, and the table says which is
which: D-glucose is a declared anchor, so the catalogue reaches the molecule
but bounds no capability on its consumption, while maltose, sucrose, trehalose
and cellobiose have neither. This is a prevalence signal of a kind the deferral
register does not currently use — not what is present in genomes, but what the
field has bothered to measure — and it ranks curation candidates by how much
external testability their absence costs. That ordering is different from the
one genomic prevalence gives, and it is the one a validation section is in a
position to produce.

A reader told which 60% of the catalogue was untestable can weigh the 11% that
was. That is why the coverage table is in the section rather than in a
supplement.

### R10. Ecological case study

*[Status: NOT STARTED. **Blocked on dataset choice.** This is what makes the
paper a Microbiome/mSystems contribution rather than a software note.]*

**Design.** Apply gifter to a genome-resolved metagenomic
dataset and show what the trait abstraction adds — for example, separating
public-goods polysaccharide degraders from selfish foragers and cross-feeders
using `resource_strategy`, and identifying candidate auxotrophies through the
derived profile, and reading the community handoff topology of R5 over a real
assemblage. *[Choose the dataset; a host-associated system with paired metadata
would show the trait framing best.]*

*[Reproducibility of curation — inter-curator agreement on boundary choice, or
more modestly the curation protocol and the review record the biological
changelog already provides — is folded into M1 rather than given its own
results section.]*

## Discussion

*[Status: skeleton with argued points; finalise after R7-R10.]*

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

## Conclusions

*[Status: not started. Microbiome requires this section; mSystems does not.
Write last, after the Discussion. ~200 words: the unit of inference determines
what can be said; a declared completeness contract and a declared denominator
are what make a capability claim auditable.]*

## Materials and Methods

### M1. Curation protocol

*[Status: to write. Boundary rules, the defended-boundary requirement, the
refusal cases of R2.4, and the review record. Much of the raw material is in
the type proposals under `inst/doc/`.]*

The working boundary rule for a metabolic GIFT is to start at the nearest
biologically meaningful shared precursor, host- or environment-derived
substrate, or metabolic junction before trait-specific chemistry begins, and to
end at the first stable product or branchpoint that establishes the
capability's identity before broadly shared metabolism resumes. The purine cut
worked through in R3 illustrates both ends.

### M2. Schema, validation and compilation

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

### M3. Versioning, changelogs and provenance

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

Each external resource is credited with what it actually supports, and with
nothing beyond it (Table 3). The division is deliberate: chemistry, molecular
identity and annotation evidence are imported, whereas the capability, its
boundaries, its accepted implementations and the interpretation of the evidence
are gifter's own. No upstream database endorses a gifter boundary decision, and
the documentation states so explicitly.

**Table 3.** External resources, the gifter process each one feeds, and the
decision each one is not permitted to make. Releases are those pinned by
database version 2026.24.1; counts are distinct markers at that version.

*[Regenerate with Table 2 at submission, at a single database version.]*

| Resource (pinned release) | Process | Contribution | Does not determine |
|---|---|---|---|
| Rhea (141) | Reaction identity | The canonical identifier and stoichiometry of every curated reaction | Direction, curated per implementation; and whether a reaction belongs to a given capability |
| ChEBI (253) | Anchor identity | Stable identifiers for declared boundary molecules | Which molecules are boundaries. Internal intermediates carry no identifier and are not runtime entities |
| KEGG modules and pathways (2026-08-22) | External cross-reference | Candidate organisation of steps into a pathway | Trait boundaries. A module is not a GIFT; every link states its boundary relation, and M00018 is `subset_of` three separate traits |
| KEGG orthology (2026-08-22; 750 markers) | Marker evidence | Orthologue accessions at the component layer | The specificity of a call. Where one orthologue groups genes of different function the trait is widened, never the marker (R2.4) |
| dbCAN / CAZy (db_v5-2-9_5-5-2026; 520) | Marker evidence for carbohydrate-active enzymes | Family, subfamily and eCAMI-cluster accessions, with quantified EC agreement per cluster | Confidence, which follows the measured EC agreement; a cluster below 50 % agreement is refused outright |
| NCBIfam (hmm_PGAP 20.0; 57), with legacy TIGRFAM and Pfam profiles (6) | Marker evidence where orthology is too coarse | Versioned profile accessions and the family grade each one carries | Admission. Only `equivalog` and `equivalog_domain` grades are eligible, and 229 profiles that reach a curated reaction are refused on grade alone |
| EC numbers | Cross-namespace join | The vocabulary linking orthologues, sequence families, profiles and Rhea reactions during curation and screening | Evidence for a call. An EC number is a cross-reference; only two are admitted as markers |
| UniProt (reviewed) | Marker specificity screening | The number of reviewed proteins supporting each EC-to-reaction assignment | Anything at runtime. Screening outputs are curation inputs and are not compiled into the database |
| BacDive, MediaDive, Madin *et al.* | External phenotype reference (R9) | Measured strain phenotypes, defined-medium compositions, and their genome links | Any database content. An observation about a strain is not a claim gifter makes, and the compiled artifact holds no phenotype table |

Three properties of this arrangement matter more than the individual rows.

**A marker namespace is admitted, not accumulated.** Each namespace enters
because it resolves a distinction the existing ones cannot, and its admission is
a versioned curation decision rather than a coverage improvement. NCBIfam was
admitted because two equivalog profiles sharing one EC number separate the two
subunits that a single orthologue conflates; dbCAN subfamilies were admitted
because bare CAZy families are polyspecific across substrates. The converse
holds too: a namespace that would raise annotation coverage without raising
specificity buys nothing the model can use.

**Upstream releases are pinned because accession identity is release-scoped and
the failure mode is silent.** dbCAN's eCAMI cluster identifiers are regenerated
positionally at each build, so annotating against a different release yields
accessions that mostly fail to match — and an unmatched marker is
indistinguishable from an absent capability, which presents as a genome that
appears to lack traits rather than as an error. NCBIfam accessions carry a
version suffix that the compiler requires for exactly this reason, making the
mismatch visible instead. An upstream upgrade is therefore handled as a
marker-layer migration with its own changelog entry, not as a refresh. The
evidence tables that informed each decision are retained in the repository
although they are never compiled or loaded, so any curation call can be
re-checked against the input that produced it.

**Two classes of resource are excluded on principle.** Genome-derived or
taxonomy-propagated trait predictions — including FAPROTAX, ProTraits and
BacDive's own genome-based prediction section — are refused as phenotype
references, because benchmarking a genome-based caller against genome-derived
labels measures agreement between two predictors rather than agreement with
observation. They may appear in R8 as comparators, never in R9 as a reference.
Separately, gifter queries no resource at runtime: a genome enters as a table of
`namespace` and `accession` pairs, so the annotation tool is the user's choice
and the marker key remains an open vocabulary.

### M4. Evaluation algorithm

*[Status: to write. Marker normalisation and indexed lookup; resolution order
through the five layers; deterministic closest-implementation selection and
tie-breaking; confidence propagation; parallelisation and its invariance.
Several of these are currently asserted in R2 and must be specified here.]*

### M5. Implementation and testing

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

### M6. Datasets and analysis

*[Status: blocked on R7-R10. Genome sets, tool versions and parameters, and the
analysis scripts under `manuscript/analysis/`.]*

## Availability and reproducibility

*[Status: fill at submission.]*

- Source code: <https://github.com/alberdilab/gifter> *[add release tag,
  Zenodo DOI]*
- Licence: MIT No Attribution (MIT-0)
- Documentation: package manual, architecture guide, and the self-contained
  database atlas published with the package website and reproducible locally
  from the packaged database.
- Reference database version used in this paper: *[version, schema, and the
  upstream Rhea/ChEBI/KEGG releases it was curated against]*
- Analysis code and data for R7-R10: *[repository/DOI]*

## Figures

| # | Content | Supports | Status |
|---|---|---|---|
| 1 | The five-layer hierarchy under four vocabularies; purine resolved through all layers from markers to call | R1, R2 | Not started |
| 2 | Anchors as boundaries: purine cut points, composition through declared anchors, derived trait graph | R3 | Not started |
| 3 | Compartment and strategy: one polysaccharide resolved as public-goods degradation, selfish foraging, cross-feeding | R3, R5 | Not started |
| 4 | Frames and honest denominators: bounded vs. unbounded, assessability under MAG incompleteness | R4 | Not started |
| 5 | Community: capability distribution, redundancy, potential handoff topology | R5 | Not started |
| 6 | Call retention vs. genome completeness, route-based vs. percentage | R7 | Blocked on analysis |
| 7 | Case-study results | R10 | Blocked on dataset |
| 8 | Phenotype agreement: recall per target with test-set size and taxonomic spread (a), the anabolic half on defined media (b), every disagreement classified by gifter's own trace (c), the reference measured against itself (d), the coverage panel naming what has no reference at all (e), and the same genomes annotated three ways (f) | R9 | **Drawn**; `06-figure-phenotype.R` |
| S1 | Data lifecycle: TSV sources, validation, compilation, runtime, and the version tracks | M2, M3 | Not started |
| S2 | The interactive database atlas | R6 | Exists; needs packaging |

Figures 1-5 are derivable from the software as it stands and are not blocked.

## References

*[To be assembled. Minimum set to cite: Rhea; ChEBI; KEGG/KofamScan; UniProt;
Pfam; TIGRFAM; dbCAN/CAZy; DRAM; METABOLIC; MicrobeAnnotator; anvi'o
estimate-metabolism; carveMe; gapseq; ModelSEED; FAPROTAX; Madin et al. trait
database; BacDive (NAR 2025 database issue); MediaDive; MAG-recovery and
MAG-quality standards (MIMAG); distillR 1.x application papers.]*

---

## Drafting roadmap

Structure follows `manuscript/outline.md`. Each row names what must be true
before the text can be finalised.

| Section | Depends on | Status |
|---|---|---|
| Background | Citations only | Prose complete, citations pending |
| R1. GIFT primitive | Type model frozen | **Complete** |
| R2. Boolean hierarchy | Five layers frozen across four types | **Complete** |
| R3. Anchors and composition | Compartment model frozen (schema 7) | Complete |
| R4. Quantitative traits | Frame API stable | **Drafted; needs worked example + Fig 4** |
| R5. Community | Community API stable | **Drafted; needs worked example + Fig 5** |
| R6. Reference database | Counts regenerated at submission | Complete, counts to refresh |
| R7. Incompleteness | `analysis/01-incompleteness.R` + genome set | **Not started — blocker** |
| R8. Tool comparison | Genome set + tool runs | Not started |
| R9. Phenotype agreement | Nothing outstanding | **Complete**; prose, Figure 8 and the annotation route all from committed scripts |
| R10. Case study | **Dataset undecided** | Not started |
| Discussion | R7-R10 | Skeleton |
| Conclusions | Discussion | Not started |
| M1. Curation protocol | Nothing; `inst/doc/` proposals are the raw material | Stub |
| M2. Schema and validation | Schema 7 frozen | Complete |
| M3. Versioning and provenance | — | Complete |
| M4. Evaluation algorithm | Assertions made in R2 must be specified | Stub |
| M5. Implementation | Public API frozen for 1.0.0 | Written, revisit at freeze |
| M6. Datasets and analysis | R7-R10 | Blocked |
| Availability | Release tag, Zenodo DOI | Pending release |
| Abstract | Everything | Draft, rewrite last |
| Figures 1-5 | Nothing — derivable today | Not started |

**Open decisions**

1. ~~Phenotype reference set for R9~~ — **decided**: BacDive, MediaDive and Madin
   adopted, FAPROTAX refused, in `inst/doc/proposal-phenotype-validation.md`.
   What remains is the curated phenotype-to-GIFT crosswalk and the analysis
   script.
2. **Case-study dataset for R10** — determines whether the ecological argument lands.
3. Reference genome set for R7 and R8, and which comparison tools to actually run.
4. Microbiome vs. mSystems (both fit this structure; affects whether Conclusions
   is required, and overall length).
5. Author list and contributions.
6. Whether the database is cited separately (own DOI) from the software.

**Standing rules for this document**

- Nothing in R7-R10 may be written before a committed script in
  `manuscript/analysis/` has produced it.
- Refresh every database count and version before submission; regenerate them
  from the compiled database rather than copying from an earlier draft.
- Keep the scope disclaimers in Background and Discussion intact through every
  revision; they are the paper's honest-uncertainty contract, not boilerplate.
