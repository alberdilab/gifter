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
software_version: "gifter 0.7.3 (in development)"
database_version: "2026.27.1 (schema 7)"
status: "Working draft. Structure follows manuscript/outline.md (agreed 2026-08-22)."
---

<!--
DRAFTING CONVENTIONS
  * Structure follows the venue: Background / Results / Discussion /
    Conclusions / Materials and Methods. See manuscript/outline.md.
  * R1-R3 and R6 describe behaviour that exists in the package today and are
    written as final prose.
  * R4 and R5 include reproducible, deliberately illustrative worked examples.
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

*[Status: complete.]*

Genome-resolved metagenomics routinely yields hundreds to thousands of
metagenome-assembled genomes (MAGs) per study, and the analytical bottleneck has
moved from recovering genomes to interpreting them. The question asked of each
genome is almost always functional: does this organism degrade this substrate,
synthesise this compound, respire this electron acceptor, or depend on a partner
for a metabolite it cannot make? ([Bowers et al.,
2017](https://doi.org/10.1038/nbt.3893); [Alberdi et al.,
2022](https://doi.org/10.1038/s41576-021-00421-0)).

Three families of tools currently answer that question, and each answers a
different version of it.

**Marker checklists** map annotation identifiers onto predefined gene sets and
report the fraction observed. KEGG module completeness and the pathway summaries
of tools such as DRAM, METABOLIC and MicrobeAnnotator are of this kind
([Kanehisa et al., 2025](https://doi.org/10.1093/nar/gkae909); [Aramaki et al.,
2020](https://doi.org/10.1093/bioinformatics/btz859); [Shaffer et al.,
2020](https://doi.org/10.1093/nar/gkaa621); [Zhou et al.,
2022](https://doi.org/10.1186/s40168-021-01213-8); [Ruiz-Perez et al.,
2021](https://doi.org/10.1186/s12859-020-03940-5); [Eren et al.,
2021](https://doi.org/10.1038/s41564-020-00834-3)).
They are fast, reproducible and easy to explain, but the abstraction they use —
a flat list of expected identifiers with a percentage attached — cannot
distinguish four situations that are biologically distinct: an organism that
uses an alternative route to the same product; an organism that uses a
non-homologous enzyme for one step; an organism that is missing one subunit of
an otherwise complete complex; and an organism whose annotation is simply
incomplete. All four can produce "80% complete", and the number carries no
statement of which chemistry is unsupported.

**Genome-scale metabolic models** reconstruct a stoichiometric network and
simulate flux ([Henry et al., 2010](https://doi.org/10.1038/nbt.1672); [Machado
et al., 2018](https://doi.org/10.1093/nar/gky537); [Zimmermann et al.,
2021](https://doi.org/10.1186/s13059-021-02295-1)).
They represent alternatives, cofactors and mass balance properly, but they
require gap filling to become simulable, which introduces reactions that the
genome does not encode, and the provenance of an individual conclusion is
difficult to recover ([Bernstein et al.,
2021](https://doi.org/10.1186/s13059-021-02289-z)). For comparative ecology across thousands of partially
complete MAGs, the modelling machinery answers a question — *will this organism
grow on this medium?* — that the underlying evidence often cannot support.

**Trait databases and curated schemes** assign organisms to functional
categories from literature or taxonomy ([Louca et al.,
2016](https://doi.org/10.1126/science.aaf4507); [Madin et al.,
2020](https://doi.org/10.1038/s41597-020-0497-4); [Schober et al.,
2025](https://doi.org/10.1093/nar/gkae959)). They are biologically meaningful but are not derived
from the genome at hand, so they cannot describe a novel or uncultured lineage.
Their measured members are, however, what R9 validates against, and the
distinction between a measured phenotype and a taxonomically propagated one
decides which of them can serve that purpose.

gifter's predecessor, [distillR](https://github.com/anttonalberdi/distillR),
which has been used in comparative microbiome analysis ([Koziol et al.,
2023](https://doi.org/10.1128/mbio.01606-23)), belonged to
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

*[Status: complete; reproduced by `manuscript/analysis/20-figures-core.R`.]*

We followed a nine-marker purine fixture through every layer of the hierarchy
(Figure 1). The input is deliberately an architectural fixture rather than an
annotation of a named organism: nine supplied gene identifiers carry the KEGG
orthologues K00764, K01945, K00601, K01952, K01933, K01587, K01756, K00602 and
K01939. At database version 2026.27.1, `evaluate_gifts()` supports both
`purine_core_biosynthesis` and its downstream
`adenylate_biosynthesis` GIFT.

The adenylate call makes the alternating logic concrete. One complete route,
`AMP_ADENYLOSUCCINATE`, requires two ordered reactions. K01939 supports the
catalytic component of `SYS_15753_ADSS`, which supports RHEA:15753 in the
forward orientation; K01756 independently supports the catalytic component of
`SYS_16853_ADSL`, which supports forward RHEA:16853. Both required reactions
are supported, so the route is complete, and that one complete route is
sufficient for the GIFT. Each marker-to-component mapping in this trace carries
`curated` confidence, so the call does too.

`trace_gift(result, "adenylate_biosynthesis")` retains the route identifier,
step order, reaction orientation, selected system and component, marker,
confidence and the supplied `purine_gene_9` and `purine_gene_7` identifiers in
one long-form table. The exact rows underlying Figure 1 are written to
`worked-example-purine-trace.tsv`. The same evaluator returns parallel
structural, regulatory and defense views: for example, a flagellar trace passes
through an architecture and structural functions in place of a route and
reactions, without changing the Boolean operations between layers.

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
consistent as the database grows (Figure 2).

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
boundary molecule is compartment-blind (Figure 3).

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

*[Status: complete; worked example and Figure 4 reproduced by
`manuscript/analysis/20-figures-core.R`.]*

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

**Worked example.** We assembled a synthetic marker profile from accepted
markers for five members of the bounded amino-acid-autonomy frame and five
members of the unbounded carbohydrate-degradation frame. This is a controlled
demonstration of denominator behaviour, not an annotation of a named genome.
The same evaluated call set contains five supported GIFTs in each frame
(Figure 4a). For amino-acid autonomy, gifter reports both the count and
`supported_fraction = 5/22 = 0.227`, because the 22-member frame is intended to
be complete. For carbohydrate degradation it reports the count, five of the 18
capabilities currently selected by the frame, but withholds
`supported_fraction`: 18 is the current curated set, not the size of
carbohydrate-degradation biology.

The same example separates call status from assessability (Figure 4b). Under
the default policy, all 22 amino-acid-autonomy members are assessable, so the
five positives give `supported_fraction = 0.227` and
`assessable_fraction = 1.000`. When the illustrative profile is assigned 60%
genome completeness and evaluated at a 90% threshold, the five supported calls
remain supported while the 17 negative calls become indeterminate. The
resulting `supported_fraction` is 1.000 over five assessable members, but
`assessable_fraction` is only 0.227. The pair must therefore be read together:
the former describes the evidence-bearing part of the frame, and the latter
states how little of the full frame could be judged. All input-derived values
and denominators are retained in `worked-example-frame-metrics.tsv`.

### R5. Capability distribution and potential handoffs across a community

*[Status: complete; worked example and Figure 5 reproduced by
`manuscript/analysis/20-figures-core.R`.]*

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

**Worked example.** A four-genome fixture follows one extracellular
arabinoxylan chain without claiming that exchange occurs (Figure 5). Genome A
carries `arabinoxylan_debranching`; genome B carries `xylan_degradation`; and
genomes C and D each carry both `xylose_uptake_abc` and
`xylose_degradation_isomerase`. Each genome is evaluated independently from
its own marker rows. The community consequently contains four distinct
supported GIFTs across six genome–GIFT presences. Two GIFTs have one provider
and two have two providers, giving a singleton fraction of 2/4 = 0.5.

Projecting the declared composition graph produces exactly three
cross-genome edges: A to B through extracellular `XYLAN`, and B to each of C
and D through extracellular `XYLOSE_EX`. All three inherit `exact` edge
quality. `XYLOSE_IN` never becomes a cross-genome edge: uptake moves xylose to
the cytoplasmic boundary, where its composition with catabolism remains inside
C or D. Thus the network records three potential compatibility relationships,
not metabolite transfer or activity. The values and exact edge list are written
to `worked-example-community-metrics.tsv` and
`worked-example-community-edges.tsv`.

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

### R6.1. A phylogenetically broad bacterial overview

*[Status: the GTDB panel is annotated and evaluated and Figure S4 is drawn
(`23-gtdb-phylogeny.R`, tables under `analysis/output/gtdb-phylogeny-*`). The
GIFT-distribution prose below is still to be written from those tables; no
result is claimed yet.]*

To show how encoded GIFT repertoires vary across bacterial phylogeny, we
selected species representatives from the main GTDB R11-RS232 bac120 tree.
Eligibility required an NCBI assembly-level designation of `Complete
Genome` and `full` genome representation in the pinned GTDB metadata, producing
an initial pool of 12,094 candidates across 72 phyla, 182 classes and 552
orders. We further required assignment to at least one reviewed origin group
from the raw isolation-source field. This retained 4,116 eligible genomes
across 49 phyla, 120 classes and 321 orders. One phylogenetic medoid per
eligible order guarantees broad coverage. The 85 food/fermentation candidates
define a common balance target for every origin group with at least that many
eligible genomes, while smaller groups are retained exhaustively. Further
genomes advance the least-represented group, avoid increasing an already
complete group where possible, and maximise marginal rooted Faith phylogenetic
diversity. The resulting 696-genome panel contains 321 order medoids and 375
balance-aware additions. It retains all 49 eligible phyla, 120 classes and 321
orders and 164.466 of the eligible tree's 312.792 branch-length units (52.6%).
Selection used no marker, GIFT call or phenotype.

Every selected accession is an explicit R232 tree tip and retains its raw
GTDB/NCBI provenance. BioSample, BioProject and the isolation source required
for origin classification are present for all 696 genomes; country is populated
for 609 and latitude–longitude for 245. Every selected genome has at least one
nonexclusive origin tag. Animal-associated, plant-associated and the other
sufficiently large groups each contribute 85 genomes; food/fermentation
contributes 84, because one of its 85 candidates could not be annotated
(Methods), and aquatic origin contributes 87 because of nonexclusive overlap.
The
smaller fungal, air/built-environment and algal groups are represented
exhaustively by 6, 49 and 51 genomes. Animal and plant associations are
separate rather than pooled into a generic host category. Genome category,
isolate, dates, submitter, strain, taxon and WGS identifiers are also retained
when supplied. The cross-references permit later enrichment from BioSample
without inferring origin from a genome name or changing the selection.

The completed Drakkar run provides gene-resolved evidence for evaluation
against the current gifter database. Figure S4 places every current GIFT
beside the pruned bac120 tree and reports repertoire size separately. A coloured
cell means support for a complete encoded implementation, not expression,
activity, phenotype, ancestral state or ecological importance; an unsupported
cell does not establish biological absence.

<!--
R7-R10 ARE RESULTS. Nothing below may be written as prose before a committed
script under `manuscript/analysis/` has produced it. Priority order is
R7 > R10 > R9 > R8: R7 is the reviewer's first question, R10 is what makes this
a Microbiome/mSystems paper rather than a software note.
-->

### R7. Behaviour under genome incompleteness

*[Status: written from the committed tables of `manuscript/analysis/output/`,
produced by `02-incompleteness.R` at database 2026.27.1, with R7.1 from
`09-cooccurrence.R` and `10-block-drop.R`. Backed by Figure 6.]*

Most genomes gifter will ever be run on are incomplete. A recovered genome is
assembled from a metagenome and is missing genes it does not know it is missing,
so the question a reviewer asks first is not how the abstraction behaves on a
finished genome but how it fails on an unfinished one. This section answers it
by breaking genomes on purpose.

**Design.** 120 KEGG reference genomes, sampled stratified across the
marker-count distribution rather than from its top — from 21 to 1,060 curated
KO markers — because a set of unusually complete organisms would make the decay
look gentler than it is on the assemblies gifter is actually used on. Genes are
dropped at random to 90%, 80%, 70%, 60% and 50% of the gene content, three
independent subsamples at each level, and every subsample re-evaluated: 1,920
evaluations in all. The median genome carries a complete implementation of 58
GIFTs before anything is dropped.

**Genes are dropped, not markers**, and the distinction is the point rather
than a detail. A recovered genome loses genes and the markers follow, so a
multi-subunit system loses its components together with the contigs that
carried them. Dropping markers independently would break exactly the
correlation the five-layer model exists to see.

The comparator is computed here rather than cited. For each GIFT, the fraction
of its curated KO markers the genome carries — the marker-fraction score that a
percentage-based abstraction reports — is recomputed on the same subsamples of
the same genomes, so the two numbers are like for like.

**The two numbers do not fall the same way, and the route-based one falls
faster.** At 90% gene content the call retains 0.792 of the GIFTs it supported
at full content (interquartile range 0.718–0.824) while the marker-fraction
score still reads 0.911 of its full-genome value (0.864–0.962). At half the
genes, 0.260 against 0.474. A call is lost outright when any required reaction
loses its last marker; a fraction is merely reduced. Figure 6a is that gap, and
it is a cost, not a result in gifter's favour: a route-based call reports fewer
capabilities from a broken genome than a percentage does, and any comparison
that stops here should conclude that the percentage is the better-behaved
number.

It is worth stating what does *not* happen. Across all 1,800 subsampled
evaluations, **no GIFT was ever called in a subsample that was not called at
full gene content**. Removing evidence never manufactures a capability, which is
the monotonicity a Boolean resolution guarantees and a scoring threshold does
not.

**What makes the cost worth paying is that a lost call names what it lost.**
Across the 1,800 subsampled evaluations, 42,636 calls are lost; the median lost
call is missing a single reaction and **66.9% are exactly one reaction short**,
named by
`minimum_missing_requirements` and located by `missing_reactions_best_route`.
The share rises as the genome gets more complete — 83.7% at 90% gene content,
75.4% at 80%, and 58.7% at half — so in the completeness range where recovered
genomes actually sit, a lost call is overwhelmingly one identified reaction away
from being made. That is Figure 6b, and it is the panel that decides whether
Figure 6a was a fair trade. A marker-fraction score of 0.6 on the same genome is
compatible with any of those situations and distinguishes none of them: it
cannot say whether the missing 40% is one terminal step or the entire route, and
so it cannot be acted on. The route-based call reports less and says more.

The practical consequence is that a negative result becomes reviewable. An
absent capability in an 80%-complete MAG arrives with the reaction that would
have completed it, which a curator can check against the assembly, a reviewer
can challenge, and a downstream analysis can treat as a candidate rather than an
absence.

**A naive denominator turns the same loss into a false biological claim.** A
proportion is emitted against a bounded frame only because curation declares
its coverage complete, so the denominator is a claim rather than an artefact of
the data. Divide by the whole frame in an incomplete genome and every
unsupported member is asserted to be a member the organism lacks — precisely
the inference the genome cannot support. Measured on the same subsamples across
the three bounded frames, that is what happens: `supported_fraction` on
`nucleotide_autonomy` falls from 0.900 at full gene content to 0.710, 0.583,
0.487, 0.405 and 0.351, and `amino_acid_autonomy` from 0.676 to 0.245. Nothing
about the organisms changed. Read at face value, the curve says a bacterium
progressively loses the ability to make its own nucleotides, and it would be
reported that way.

**The assessability policy of R4 does not produce a better proportion. It
refuses to produce one, and says how much it refused** — and that turned out to
be a sharper result than the design anticipated. Under
`policy = "completeness"`, members whose absence the genome quality renders
uninformative are withheld from the denominator. Above the quality threshold
nothing is withheld and the two policies agree to the digit. Below it the
refusal takes two forms. In the 3,823 frame–genome–level cells below the
threshold where a proportion is still emitted, *every* unsupported member is
withheld, the denominator collapses onto the numerator, and
`supported_fraction` reads exactly 1.000 — in every one of them, never because
the numerator rose and never with a numerator of zero. In a further **497 cells
the metric is not emitted at all**: not `NA`, not zero, absent, because nothing
in the frame was assessable and there was no denominator to divide by. Those
497 are exactly the cells whose assessable numerator is zero, and the analysis
stops if they are ever anything else.

All of the information moves into `assessable_fraction`, which is emitted in
every cell and falls to 0.560, 0.448, 0.342 and 0.258 on `nucleotide_autonomy`
as gene content drops from 80% to 50%, and to 0.252 and 0.095 on
`cofactor_autonomy`.

Three things follow. The policy behaves exactly as invariant 21 requires: in all
5,263 cells where both policies emit a supported count, **the completeness
policy never moved one** — only a denominator — and `02-incompleteness.R` stops
if it ever does. The interpretability a naive denominator destroys is recovered
as a refusal rather than as a correction, which is the only honest form it could
take: there is no defensible proportion to report when absence carries no
information, and the strongest version of that is declining to report one. And
it imposes an obligation the paper should state plainly: `supported_fraction`
under this policy must never be read without `assessable_fraction` beside it,
because below the threshold it is 1.000 by construction and means only *nothing
here could be assessed as absent*. Figure 6c draws the pair together for that
reason.

The step at the threshold is a parameter, not a finding: `threshold = 0.9`
against a quality equal to the retained gene fraction puts only the 90% and
100% levels at or above it. A different threshold moves the step, and choosing
one is a judgement about how incomplete a genome has to be before absence stops
meaning anything — which is a decision the analyst makes and the software
records, not one gifter makes for them.

Two limits of this experiment are worth naming. Random gene loss is not how a
metagenomic assembly loses genes — recovery is biased by coverage, by GC
content and by repeat structure, so the real loss is correlated in ways this
does not reproduce, and the retention curve should be read as a shape rather
than as a calibration. R7.1 relaxes that assumption for the question it bears
on most directly, by dropping contiguous runs of adjacent genes rather than
independent ones; Figure 6 itself remains a random-loss result. And gene
calling is held fixed throughout: these are deposited protein sets with genes
removed, not assemblies re-called from fragmented contigs, so the annotation
cost measured in R9 sits on top of this one rather than inside it.

#### R7.1 Marker context does not license filling the gaps

The obvious response to a call that is one reaction short is to fill it. If the
rest of a route is present, and the missing reaction is one that in a reference
panel essentially never occurs without its neighbours, the absence looks more
like a gap in the assembly than a fact about the organism. That reasoning is
available to gifter in a form it is not available to a marker checklist,
because the Boolean hierarchy already declares which evidence is jointly
required: the conditioning set is curated rather than guessed. Whether it is
*sufficient* is an empirical question, and this section answers it. It is not.

**The estimand.** For every context the hierarchy defines — a component within
its enzyme system, a required unit within its route, mechanism, architecture or
circuit — `pi` is the probability that the target is supported given the rest
of its context is, estimated across the 11,766 reference genomes carrying at
least 20 curated markers. It is paired with the lift over the target's own
prevalence, because a marker that is simply common earns a high `pi` for free
and filling on that basis would insert it into genomes that genuinely lack the
capability. Writing `d` for the probability that a truly present gene goes
unobserved, the two feed

```text
P(present | not observed, context) = d*pi / (d*pi + (1 - pi))
```

which at 80% gene content, under `d = 1 - q`, reaches 0.90 only at `pi` of
0.978 or above. The question is therefore not whether gaps can be filled but
how many curated contexts are tight enough that filling one would be defensible
at all.

**The hierarchy's own layers separate as designed.** Across the 718 contexts
with at least 50 panel genomes behind them, median `pi` is 0.984 for a
component within its enzyme system and 0.957 for a required unit within its
container, the latter with a first quartile of 0.725. Subunits of a complex are
near-deterministically co-inherited; alternative steps of a route are ordinary
biological variation. The distinction the five-layer model draws is visible in
the co-occurrence structure of an independent panel, which is a result in its
own right and does not depend on what follows.

**Two controls remove most of what looked fillable.** 260 of the 718 contexts
clear the `pi` bar, measured on a Wilson lower bound rather than a point
estimate so that a `pi` of 1.000 over eleven genomes cannot pass. Recomputing
each over one genome per genus — 3,163 genera — drops 105 of them, so
**ancestry rather than functional coupling was doing the work in 40% of the
contexts that appeared tight**. A further 150 have lift below 2, the target's
own prevalence accounting for the result. Forty-three survive both, spanning 17
of the 153 GIFTs, and 17 of the 43 belong to the flagellar apparatus.

**The posterior that produced those 43 assumes something false.** Setting
`d = 1 - q` is correct only if losing one gene says nothing about whether its
neighbour was lost. A recovered genome is missing contigs, and a contig is a
run of adjacent genes, so a physically clustered system is present or absent
nearly as a unit. Conditional on seeing the rest of such a context, the region
was recovered, and the true dropout rate for its one missing member is far
below the genome-wide figure. The assumption was therefore replaced by a
measurement. Gene coordinates were taken from KEGG's per-organism gene lists
for 397 of the sampled genomes (median 3,658 genes), and contiguous runs of
adjacent genes removed — clipped at replicon boundaries, since a contig does
not span two chromosomes — until a fifth of the gene content was gone, with the
mean run length swept from one gene to fifty. A mean run of one gene is the
unlinked model and passes through the same code, so the assumption and its
replacement are measured on the same genomes, the same contexts and the same
replicates.

Matched context by context, the conditional dropout rate falls to 0.353 of its
unlinked value at a mean run of five genes, 0.216 at twenty and 0.186 at fifty.
**Independence overstates the case for filling roughly fivefold at realistic
contig lengths.**

Recounting with the measured dropout rate in place of the assumed one leaves
**three contexts at a mean run of five genes and two at twenty and at fifty,
from 43**. The flagellar block falls from twelve under unlinked loss to one at
twenty genes and none at fifty. It was an artefact of the independence
assumption, and it was concentrated there for the same reason it collapses
first: it is among the most tightly clustered operonic regions in bacteria,
which is precisely the condition under which linkage matters most. The two
contexts surviving at a mean run of twenty are not the two surviving at fifty,
so the residue does not replicate across run lengths and is best read as
sampling noise rather than as a usable set.

**The direction of the sensitivity is the last reason to decline.** Licensing
loosens as a genome gets worse: even under the unlinked model, two contexts
clear the bar at 95% gene content, 43 at 80% and 127 at 50%, because dropout
explains more when there is more of it. Every part of the inference is carried
by the prior, in exactly the regime where the prior is least able to be checked
against the genome in hand. A correction with that shape is one that grows most
confident where the evidence is weakest.

**gifter therefore fills no gaps, and the refusal is now measured rather than
asserted.** Invariant 21 holds that nothing may convert an unsupported GIFT
into a supported one, and the assessability layer of R4 stays a genome-level
refusal rather than becoming a per-GIFT correction. That is not merely a
consequence of the invariant — a rule that moved individual absences to
indeterminate rather than to supported would satisfy it — but a consequence of
the panel, which does not support one. Two contexts out of 718, not replicating
across loss models, is not a layer.

One defect in the estimator should be recorded for anyone who revisits this. In
4 of the 192 component contexts the target shares an accepted marker with a
member of its own context, which makes `pi` 1.000 by construction rather than
by biology; two of them are among the 43. They are a small share here and they
do not change the conclusion, but any future use of these statistics has to
exclude them rather than discover them again.

### R8. Comparison with existing tools

*[Scope decided 2026-10-02; result NOT STARTED. R8 needs a common genome subset
and the KEGG-module and DRAM runs only.]*

**Design.** On a common genome set and a fixed per-gene marker table, compare
gifter calls with KEGG module completeness and DRAM distillation. This is a
comparison of abstractions, not a benchmark with a winner: quantify where the
methods agree, and characterise the disagreements by cause (alternative route,
non-homologous enzyme, incomplete complex, boundary difference). The
classification of disagreements is the result, not the agreement rate.

METABOLIC is deliberately excluded from this controlled comparison. Its native
workflow accepts genome or protein FASTA, then generates and validates its own
profile evidence before emitting pathway and module summaries; it cannot consume
the shared marker table. A native METABOLIC run would therefore confound
annotation with completeness logic rather than answer R8's question. Its raw
gene-level marker hits can be normalised into gifter's `gene_id`, `namespace`,
`accession` input when they are retained, but its `FunctionHit`, module and
pathway summaries are already distillations and are not gifter evidence. No
METABOLIC run is pending for R8. *[cite: METABOLIC]*

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
framework declines by design. It is not an R9 reference; any comparison with
that taxonomy-propagated abstraction would need its own scope.

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
**0.274**. Two of the six growth comparisons agree to within 0.015 (L-arabinose
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

*[Status: complete from `21-r10-chicken.R`,
`22-r10-handoff-bimodality.R`, `24-r10-reference-frame-time.R` and their
generated outputs; backed by Figure 7 and Figures S3 and S5--S8.]*

We applied gifter to the 822 bacterial MAGs and 388 caecal metagenomes from two
chicken trials reported by Marcos et al. The MAGs were reannotated with
Drakkar's gifter projection rather than translated from the study's original
functional summaries. The resulting 11,219,684 gene--marker rows covered all
822 MAGs. Against database 2026.30.1 they supported 23,220 genome--GIFT pairs
in 821 MAGs, representing 133 of the catalogue's 156 GIFTs. Most calls were
metabolic (22,485); the remainder were defense (638), regulatory (64) or
structural (33). Evidence confidence was curated for 21,353 calls,
high-confidence for 435 and ambiguous for 1,432.

The database-derived resource profile separated capabilities that a flat
functional total would merge. Of the metabolic calls, 20,682 were classified
as private, 845 as extracellular public-good production and ten as uptake;
another 948 could not be assigned a resource strategy from their current
boundaries. The 845 public-good calls occurred in 639 MAGs, whereas the ten
uptake calls occurred in six. This imbalance describes the current catalogue
and evidence, not consumption in the caecum. Its dependence on marker
specificity was visible when ambiguous calls were excluded: at the primary
detection threshold, median community metabolic richness decreased from 111
to 105 GIFTs and plant-fibre richness from 12 to 11, while the median number
of public-good GIFTs per detected MAG decreased from 1.10 to 0.38 even though
median community public-good richness remained two.

The bounded anabolic frames made candidate encoded gaps equally explicit. Of
518 MAGs at least 90% complete, the median supported fraction was 0.64 for the
amino-acid frame, 0.13 for the cofactor frame, 0.45 for the combined
biomass-essential frame and 1.00 for the nucleotide frame. No MAG supported
every current amino-acid, cofactor or combined-frame GIFT, whereas 282/518
supported all four nucleotide GIFTs. Three catalogue members had no support in
these high-completeness MAGs: cysteine biosynthesis from homocysteine, aerobic
5,6-dimethylbenzimidazole biosynthesis and transsulfuration methionine
biosynthesis. These are reviewable gaps in encoded support, not auxotrophy
calls: catalogue coverage, marker specificity and annotation failure remain
alternatives to biological loss.

Community richness and per-genome repertoire told different temporal stories
(Figure 7). At the operational threshold of relative abundance greater than
0.001, the median number of detected MAGs rose from 133.5 at day 7 to 151 at
day 21 and 162 at day 35. Median community metabolic richness nevertheless
remained 111, 110 and 111 GIFTs, while the mean number encoded per detected MAG
fell from 38.26 to 30.53 and 29.08. In mixed models controlling trial,
treatment, breed and sex, with pen as a random intercept, the adjusted
differences from day 7 were -6.77 GIFTs at day 21 and -8.83 at day 35 (both
BH-adjusted *q* < 10^-55). Both contrasts remained negative at every tested
detection threshold from nonzero abundance through 0.001 (largest *q* =
0.028). The bounded biomass-essential repertoire showed the same separation:
community coverage stayed at a median 0.864, whereas mean per-MAG richness
fell by adjusted values of 3.67 and 4.78 GIFTs; both directions remained
supported throughout the detection sensitivity analysis (largest *q* =
0.041). Thus the community retained a broad capability union while its
detected members individually encoded narrower portions of that union.

The same separation became sharper when the unit of comparison was every
database-defined reference frame rather than individual GIFTs (Figure S5).
We read all 19 presets and required stability to be demonstrated, not inferred
from a nonsignificant test: both later-age contrasts had to be equivalent
within one GIFT for count metrics, or five percentage points for bounded
coverage, at all four detection thresholds. Community richness met that
criterion in 15 frames and was exactly invariant in amino-acid and nucleotide
autonomy. Aromatic catabolism and carbon acquisition were the only
detection-sensitive unions; no frame showed a threshold-robust community-union
change outside the one-GIFT margin. All four bounded frames likewise retained
coverage within five percentage points.

Redistribution among genomes was concentrated in three frames. At the
operational detection threshold, mean per-MAG richness fell beyond the
one-GIFT margin at both later ages for amino-acid autonomy (adjusted
differences -2.47 and -3.32 GIFTs), the combined biomass-essential frame
(-3.67 and -4.78), and vitamin biosynthesis (-1.50 and -1.91). All six
larger-than-margin contrasts remained supported when ambiguous marker evidence
was withheld, and their negative direction persisted across detection
thresholds, although the magnitude attenuated as the threshold was relaxed.
Carbon acquisition at day 35 was age-associated (-1.03), but its 95% interval
(-1.12 to -0.94) crossed the one-GIFT boundary and therefore left the magnitude
uncertain. The other 15 frames stayed within one GIFT at both ages. These are
changes in the distribution of encoded repertoires among detected MAGs, not
changes in expression, activity or flux; the frame memberships retain the
individual GIFTs behind every aggregate.

The corresponding adjusted values at days 7, 21 and 35 are shown directly in
Figure S6. These population-standardised means reproduce the two fitted
contrasts exactly. Lines connect age-level model estimates for visualisation;
they are not longitudinal trajectories of individual birds.

We then resolved the three frames that declined beyond the margin at both
later ages into their member GIFT carrier fractions (Figure S7). In every
sample, those fractions sum exactly to the frame's mean per-MAG richness. The
largest descriptive declines were distributed across several capabilities
rather than one GIFT: examples included proline, aromatic-amino-acid and
arginine biosynthesis in the amino-acid frame, and NAD, cobinamide and thiamine
capabilities in the vitamin-containing frames. Because this view was selected
to explain the aggregate, no individual GIFT was hypothesis-tested. Overlap
was retained explicitly: all 22 amino-acid GIFTs and 12 of the 20 vitamin GIFTs
also belong to the 44-member biomass-essential frame.

Weighting each call by the relative abundance of its carrier MAG preserved the
principal result (Figure S8). We summed the per-GIFT abundance coverage within
each frame after abundance was closed over the detected community. All six
focal age associations remained negative, BH-supported, directionally stable
across detection thresholds and supported when ambiguous marker evidence was
withheld. Amino-acid autonomy changed by -2.61 and -3.40 abundance-weighted
GIFTs at days 21 and 35, and biomass-essential anabolism by -3.51 and -4.49.
Vitamin biosynthesis changed by -1.10 and -1.42: the day-35 contrast remained
beyond the one-GIFT margin, whereas the day-21 interval (-1.28 to -0.92)
crossed it and left that contrast's magnitude uncertain. Thus abundance
weighting retained the temporal direction in all three frames and five of the
six larger-than-margin conclusions, but slightly weakened the early vitamin
result. Carrier abundance remains a distribution of encoded capability, not a
measure of activity, expression or flux.

The two modes visible within each age group were not two unexplained community
states (Figure S3). The largest gap in metabolic richness separated 78 samples
with 88--97 GIFTs from 310 with 108--119. Detection of one 99.97%-complete,
4.78-Mb *Escherichia coli* MAG (`cmag_510`) matched that split exactly
(phi = 1): it was above 0.001 in every upper-mode sample and below it in every
lower-mode sample. The MAG supported 90 metabolic and 11 plant-fibre GIFTs and,
when detected, was the sole detected provider of a median 19 and three of them,
respectively. Removing it computationally reduced median metabolic richness to
92 in both modes. Moreover, `cmag_510` exceeded 10^-5 in all samples and
10^-4 in 384/388; all samples consequently carried 12 plant-fibre GIFTs at the
first two thresholds, whereas the 0.001 reading split them into 310 samples
with 12 and 78 with 8--10. The bimodality is therefore the thresholded
contribution of one broad-repertoire MAG whose abundance spans the operational
cutoff, not evidence of two age-specific functional regimes. Its underlying
relative abundance nevertheless shifted with age: medians were 0.00456,
0.00292 and 0.00286, and adjusted day-21 and day-35 abundance ratios relative
to day 7 were 0.675 and 0.541 (*q* = 0.016 and 0.00024). Consequently, the
fraction falling below 0.001 rose from 10/122 samples at day 7 to 31/126 and
37/140. A continuous age-associated abundance shift was thus discretised into
the two richness bands by the operational threshold.

The declared extracellular anchors also bounded the cross-feeding question.
The entire exact catalogue graph contained only three links capable of crossing
between organisms: arabinoxylan debranching to arabinose uptake through
ARABINOSE_EX, arabinoxylan debranching to xylan degradation through XYLAN, and
xylan degradation to xylose uptake through XYLOSE_EX. At the primary threshold,
median potential-handoff density declined from 0.294 at day 7 to 0.213 at day
21 and 0.205 at day 35; the fractions of detected MAGs encoding a provider end
declined from 0.911 to 0.828 and 0.819, and the recipient fractions from 0.338
to 0.265 and 0.256. Adjusted density differences from day 7 were -0.080 and
-0.086 (both *q* < 10^-45). Every detection threshold gave a negative age
estimate, and subtracting the mean of 499 random catalogue communities matched
for detected-MAG count left the primary estimates effectively unchanged. The
separate abundance axis agreed for the XYLAN link: median provider abundance
coverage declined from 0.891 to 0.853 and 0.851, while recipient coverage
declined from 0.337 to 0.270 and 0.242.

Of the 1,164 exact extracellular sample--link statuses at the primary threshold,
1,008 were completed within at least one MAG, only two were completed solely
by distributing their ends across detected MAGs, and 154 were not represented.
Those two cases were the XYLOSE_EX link in one day-7 and one day-21 sample.
With ambiguous evidence withheld, the absolute topology changed substantially
(median density 0.043, 0.022 and 0.021; median distributed links two at every
age), because within-genome ambiguous matches were no longer accepted; the age
direction still did not reverse. Thus neither presence, abundance coverage,
the detected-count-matched null nor the high-confidence reading supported an
increase in encoded handoff potential with age. The analysis is also bounded by
only three currently curated exact extracellular links. Its edges are potential
compatibilities, not observations of exchange, cooperation, expression or
activity.

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

*[Status: complete.]*

Every new or changed GIFT began with a one-sentence definition of what a
positive call would mean and why that encoded capability was useful to infer.
We then assigned the claim to one of the four completeness contracts. A
metabolic claim had to be expressible as at least one complete directed
enzymatic route between declared molecular boundaries. A structural,
regulatory or defense claim instead had to be expressible as at least one
complete architecture, circuit or mechanism. Candidate descriptions that
combined independently useful capabilities were split; higher-order phenotypes
or ecological strategies were retained only as possible derived descriptions,
not made into primary GIFT types.

We read the deferral register before curating a candidate. If the proposed
specificity could not be supported by available markers, if the boundaries
could not be defended, or if a complete implementation could not be stated, we
stopped at a curation proposal and added a discoverable deferral record. Each
record states the blocking evidence and what would trigger reassessment. This
procedure makes a refusal—such as declining to infer substrate specificity
from a polyspecific enzyme family or ion coupling from a shared stator
orthologue—a curation result rather than an unrecorded omission.

For a metabolic GIFT, we placed the input boundary at the nearest meaningful
shared precursor, host- or environment-derived substrate, or metabolic
junction before trait-specific chemistry begins. We placed the output at the
first stable product or branchpoint that establishes the capability before
broadly shared metabolism resumes. Existing anchors were reused when molecule,
role and compartment denoted the same boundary; internal reaction participants
were not promoted to anchors merely because they occur in the chemistry. Each
GIFT was assigned an anabolic, catabolic, transport or interconversion mode,
and every anchor received only the boundary-level compartment required for
composition. The PRPP to IMP to AMP/GMP cut in R3 illustrates these rules.

Within those boundaries, reactions were matched to Rhea master identifiers
where available and their route-specific forward or reverse orientation was
recorded separately. Each supported alternative minimal route was materialised
as an ordered route rather than encoded as a Boolean expression. Upstream
pathway records were treated as evidence to inspect, not as trait definitions;
an external cross-reference was added only with an explicit boundary relation
(`equivalent`, `subset_of`, `superset_of`, `overlaps` or `related`). For every
reaction we enumerated alternative enzyme systems, and for every system all
jointly required components, including multisubunit forms, non-homologous
replacements, fused proteins and taxon-specific alternatives where the
evidence supported them.

For structural, regulatory and defense GIFTs, the parallel procedure replaced
anchors and routes with alternative complete architectures, circuits or
mechanisms. Curators enumerated their required and optional biological
functions, the alternative systems capable of each function, and all jointly
required components of each system. These GIFTs were prohibited from declaring
anchors or a metabolic mode: an invented boundary molecule would change the
biological claim rather than adapt its representation.

Markers were linked only to components, using the extensible
`namespace + accession` identity. Each mapping recorded its evidence type,
source, qualitative confidence and relevant ambiguity. We accepted a marker
only when its specificity was at least that of the component and the GIFT it
could support. Candidate markers were therefore screened for multifunctional
proteins, shared orthologues, polyspecific families and incomplete complexes;
adding a broad marker for one trait was also evaluated for the false
equivalences it would create in every other trait using that marker.

Before release, we inspected the existing anchor graph for composition,
redundancy and cycles and reused existing reactions, systems, components and
markers wherever they represented the same entity. Changes were made in the
human-readable TSV sources, with provenance updated beside them. Source
validation, SQLite compilation, foreign-key and integrity checks, logic tests
and public-accessor inspection then had to pass. Finally, we traced the new call
to observed markers and supplied gene identifiers and recorded the decision in
`database_changes.tsv` with a UTC timestamp, rationale, evidence, effect on
calls and links to every affected GIFT. The compiled SQLite file was generated
from the reviewed sources and was never edited directly.

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
observation. They are never R9 references. Separately, gifter queries no
resource at runtime: a genome enters as a table of
`namespace` and `accession` pairs, so the annotation tool is the user's choice
and the marker key remains an open vocabulary.

### M4. Evaluation algorithm

*[Status: complete.]*

`evaluate_gifts()` accepts either a character vector of marker accessions or a
table containing `namespace` and `accession`; an optional `gene_id` is retained
as evidence and never enters the call. Namespaces are trimmed, upper-cased and
normalised through explicit aliases (for example, `KEGG` to `KO`). KO and EC
prefixes are removed, profile accessions are case-normalised, and the
lower-case suffix of dbCAN eCAMI clusters is restored after normalisation.
Where no namespace is supplied, accession patterns can identify KO, EC, Pfam,
TIGRFAM, NCBIfam and CAZy markers; an accession whose namespace remains
ambiguous is rejected rather than guessed.

Unique normalised `namespace + accession` pairs are looked up through the
indexed marker table in parameterised batches of at most 300 pairs. The same
lookup traverses the metabolic and three machinery table families and labels
each row with its `gift_type`. The observed-marker table is then left-joined to
those results so unmatched annotations remain visible. Consequently a single
observed marker may support several components, whereas an unused marker is
retained with `matched = FALSE`; neither multiplicity is discarded before
evaluation.

Support is resolved bottom-up. Any accepted observed marker supports its
component. A system is supported only when all of its required components are
supported. Any supported system satisfies its owning reaction or machinery
function. An implementation is complete only when all requirements marked
required are satisfied; optional requirements are reported but excluded from
the Boolean call. Finally, any complete implementation supports the GIFT. The
metabolic path names the middle layers enzyme system, reaction and route; the
structural, regulatory and defense paths use their own system, function and
architecture, circuit or mechanism tables but apply the same operations.

Diagnostics are computed even for an unsupported call. For each reaction or
machinery function, systems are ordered first by the number of missing
components and then lexicographically by stable `system_id`. For each GIFT,
implementations are ordered first by the number of missing required
requirements and then by stable implementation identifier. The first row is
reported as the best system or implementation, so ties and all-complete cases
are deterministic. Missing and supporting identifiers are retained as lists;
the route score is the supported proportion of required reactions in the
selected route and is a secondary summary, never the completeness decision.

Evidence confidence follows the same Boolean structure. Alternative markers
for one component are disjunctive, so the highest-confidence accepted marker
sets that component's confidence. Required components are conjunctive, so the
weakest selected component confidence is propagated through the selected
implementation to the GIFT. The ordered vocabulary, from weakest to strongest,
is `insufficient
evidence`, `ambiguous`, `putative`, `high-confidence` and `curated`; the terms
are not averaged or converted to a numeric probability. Output tables retain
the database version and stable identifiers needed to join the call, its best
or complete implementation, all systems and components, the observed markers
and supplied genes. `trace_gift()` performs that join without re-evaluating the
claim.

Community evaluation preserves the genome as the unit of inference.
`evaluate_gifts_community()` splits the input by `genome_id`, creates one
transactionally consistent read-only SQLite snapshot, and evaluates each
genome against that snapshot. On platforms that support process forking, the
genome tables are divided among workers and each worker opens its own read-only
connection; otherwise the same routine runs sequentially. Results are restored
to deterministic genome order before assembly. Tests require a genome's result
to be identical whether evaluated alone, in a community, sequentially or with
multiple workers, preventing marker pooling and worker count from changing a
biological call.

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

**Computational cost.** We measured the gifter portion of the R10 chicken
case study from a checksum-verified, gene-resolved marker table: 11,219,684
annotation rows for 822 MAGs, followed by the 388-sample dataset. On an
eight-core Apple M3 laptop with 16 GB RAM, gifter 0.7.3 and database
2026.39.1 took 1,366 s wall time (1,329 s CPU) using one evaluation worker,
with 3.85 GB peak sampled resident memory. With eight workers, the same
workflow and calls took 852 s wall time (3,188 s summed CPU); aggregate
worker memory was not measurable in this sandbox. Genome evaluation in the
single-worker run accounted for
1,336 s; verifying and loading the markers took 13.6 s, dataset assembly
0.10 s, the 11-frame primary sample-trait reading 0.85 s, and the exact
plant-fibre network 14.5 s. Memory was sampled every 0.05 s. The measured
workflow excludes upstream gene calling and profile annotation, the case
study's other detection and confidence readings, statistical contrasts and
figure rendering. `evaluate_gifts_community()` can evaluate genomes with
multiple workers; the observed wall-time ratio for these two runs was 1.60,
with a single-core background pipeline active. The stage timings, CPU and memory,
input and database checksums, and measurement script are retained under
`manuscript/analysis/r10-chicken/benchmark/` and
`manuscript/analysis/36-r10-gifter-resources.R`. This is one descriptive run
on a shared machine, not a repeated performance estimate. Upstream Drakkar
and giftag annotation have separate resource scopes and are reported
separately.

### M6. Datasets and analysis

*[Status: R7, R9 and R10 scripted; the GTDB phylogenetic panel is annotated and
evaluated; R8 remains pending. Genome sets, tool versions and
parameters, and the analysis scripts are under
`manuscript/analysis/`.]*

**GTDB phylogenetic overview.** We pinned the GTDB R11-RS232 bacterial bac120
reference tree and metadata by SHA-256. Candidates were GTDB species
representatives present in the main tree with NCBI assembly level `Complete
Genome` and genome representation `full`. Eligibility additionally required at
least one reviewed origin-group assignment from the raw isolation-source field.
We chose one within-order phylogenetic medoid for each eligible order, breaking
ties by accession. The 85 eligible food/fermentation genomes define the common
target for every origin group with at least 85 candidates; smaller groups are
retained exhaustively. Each addition advances a least-represented group, avoids
increasing an already complete group where possible, then maximises marginal
rooted Faith phylogenetic diversity. The procedure stops when every target is
met, so panel size is an outcome rather than an input. Because the selection
sees neither annotations nor GIFT calls, the display cannot preferentially
retain genomes carrying a particular capability.
The final manifest keeps the source tree accession plus GTDB taxonomy,
BioSample, BioProject and all origin-related fields distributed in R232. Rules
over the raw isolation-source field provide nonexclusive food/fermentation,
animal-associated and plant-associated tags; animal and plant associations are
not collapsed into a generic host class.

One genome chosen by this procedure, `GCA_002285495.1` (food/fermentation),
failed KOfam annotation in every attempt and was removed without replacement
and without reference to any GIFT call; the removal is recorded with its
reason. The panel is therefore 696 genomes.

The genomes were annotated in Drakkar's `gifter` mode under the same
gene-resolved evidence contract used for R10. The generated annotation
manifest and projection were checksum-verified before each genome was
evaluated independently. Panel prevalence uses 696 as its explicit
denominator and describes this phylogenetically enriched selection, not a
frequency-weighted census of GTDB, bacterial organisms or communities.

**R10 chicken caecal case study.** We used the analysis archive accompanying
Marcos et al. (Zenodo 10.5281/zenodo.18457570, release 1.1.0; source commit
`20e6ec3a873b7b14d9f194ec2cbcd602a3948e1d`). The archive contained 825
abundance rows; an exact inner join to its bacterial taxonomy table retained
the 822 published bacterial MAGs and excluded three archive-only rows. All 822
assemblies were checksum-verified before annotation.

We ran Drakkar 2.6.6 from the pre-existing shared conda environment without
installing or updating the software. The gifter annotation projection used
Kofam 2026-07-02, dbCAN-HMMdb V15, Pfam 38.2, NCBIfam 20.0 and TIGRFAM 15.0.
Kofam hits used native model cutoffs, NCBIfam and TIGRFAM hits used native
trusted cutoffs without fallback, and the recorded general filters were an
E-value of 10^-10, 50% identity, 0.5 query coverage and 0.5 target coverage.
The generated annotation manifest pins database-file checksums and the final
four-column projection by SHA-256. The projected table comprised 11,219,684
rows over exactly 822 genome identifiers and was evaluated genome by genome
with `evaluate_gifts_community()`.

We reconstructed relative abundance by dividing each MAG count by its assembly
length and closing each sample to one. The archived files do not retain the
per-sample 30% genome-breadth matrix used in the source study. We therefore
analysed four explicit operational detection thresholds (relative abundance
greater than 0, 10^-5, 10^-4 or 10^-3), used 10^-3 for Figure 7, and do not
claim that threshold reproduces the original breadth filter. A MAG below 90%
estimated completeness had unsupported calls changed to indeterminate for
denominator calculations only; supported calls were never promoted, removed
or changed. Analyses were repeated with a high-confidence evidence floor as a
marker-specificity sensitivity.

Community and per-genome summaries used declared frames for all metabolic,
carbohydrate-degradation, plant-fibre, fermentation-product, short-chain-fatty-
acid, biomass-essential, amino-acid, nucleotide, cofactor, extracellular-
public-good and nutrient-uptake GIFTs. For each frame and metric we fitted a
linear mixed model on the original metric scale with sampling time, trial,
treatment, breed and sex as fixed effects and pen as a random intercept. Day
21 and day 35 were contrasted with day 7 and false-discovery rates were
controlled across reported contrasts by the Benjamini--Hochberg procedure.
Metrics with no numerical variation were labelled constant and were not
tested.

The primary plant-fibre network and the follow-up catalogue-wide screen both
required exact anchor identity and an explicitly extracellular shared anchor.
The latter recovered three graph links. For each detection threshold we kept
unique ordered-pair density, GIFT-resolved edge count, anchor richness,
within-genome and solely distributed chain status, and provider and recipient
genome fractions as separate quantities. Provider and recipient abundance
coverage were likewise reported separately from encoded presence. We repeated
the primary reading after withholding ambiguous evidence. A null distribution
of 499 uniformly sampled catalogue communities for every observed
detected-genome count tested whether topology followed community size alone;
age models were fitted to the observed-minus-null mean on the same terms as the
other contrasts. None of these quantities is an exchange, interaction or
activity measurement.

To investigate richness bimodality, we split primary-threshold samples at the
largest unoccupied gap in metabolic richness and screened all 822 MAGs for
agreement between detection and mode. We then removed the best-matching MAG
from each detected community without changing any genome call, counted the
GIFTs for which it had been the sole detected provider, and repeated the
richness comparison over all four detection thresholds. This diagnostic tests
the operational threshold, not whether the MAG was biologically absent.

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
| 1 | The five-layer hierarchy under four vocabularies; purine resolved through all layers from markers to call | R1, R2 | **Drawn**; `20-figures-core.R` |
| 2 | Anchors as boundaries: purine cut points, composition through declared anchors, derived trait graph | R3 | **Drawn**; `20-figures-core.R` |
| 3 | Compartment and strategy: one polysaccharide resolved as public-goods degradation, selfish foraging, cross-feeding | R3, R5 | **Drawn**; `20-figures-core.R` |
| 4 | Frames and honest denominators: bounded vs. unbounded, assessability under MAG incompleteness | R4 | **Drawn**; `20-figures-core.R` |
| 5 | Community: capability distribution, redundancy, potential handoff topology | R5 | **Drawn**; `20-figures-core.R` |
| 6 | Incompleteness: call retention against gene content beside the marker-fraction score (a), the share of lost calls that are exactly one reaction short (b), and the assessability policy against a naive denominator on three bounded frames (c) | R7 | **Drawn**; `08-figure-incompleteness.R` |
| 7 | Chicken caecal case study: community richness, per-MAG repertoire, plant-fibre richness and exact potential-handoff density | R10 | **Drawn**; `21-r10-chicken.R` |
| 8 | Phenotype agreement: recall per target with test-set size and taxonomic spread (a), the anabolic half on defined media (b), every disagreement classified by gifter's own trace (c), the reference measured against itself (d), the coverage panel naming what has no reference at all (e), and the same genomes annotated three ways (f) | R9 | **Drawn**; `06-figure-phenotype.R` |
| S1 | Data lifecycle: TSV sources, validation, compilation, runtime, and the version tracks | M2, M3 | Not started |
| S2 | The interactive database atlas | R6 | Exists; needs packaging |
| S3 | Richness-mode diagnostic against the abundance of the single matching high-repertoire MAG | R10 | **Drawn**; `22-r10-handoff-bimodality.R` |
| S4 | Current encoded GIFT calls beside a 696-tip, origin-balanced and order-covered GTDB R232 bacterial tree | R6.1 | **Drawn**; `23-gtdb-phylogeny.R` |
| S9 | Supported GIFTs against genome size across the GTDB panel, with a fitted expectation and each genome's deviation from it | R6.1 | **Drawn**; `26-gtdb-repertoire-genome-size.R` |
| S10 | Deviation from the size expectation by phylum and class | R6.1 | **Drawn**; `26-gtdb-repertoire-genome-size.R` |
| S11 | Phylogenetic signal of the deviation from the size expectation: deviations beside the tree and a correlogram over patristic distance | R6.1 | **Drawn**; `27-gtdb-size-signal-and-gift-classes.R` |
| S12 | Association with genome size by class of GIFT and for individual GIFTs | R6.1 | **Drawn**; `27-gtdb-size-signal-and-gift-classes.R` |
| S13 | Genome size, repertoire, size deviation and classes of GIFT by origin tag, from phylogenetic regressions | R6.1 | **Drawn**; `28-gtdb-origin-and-annotations.R` |
| S14 | Individual GIFTs whose prevalence differs between an origin group and the rest of the panel | R6.1 | **Drawn**; `28-gtdb-origin-and-annotations.R` |
| S15 | Repertoire and size deviation against assembly annotations: genome category, completeness, contamination, contigs, release year, latitude | R6.1 | **Drawn**; `28-gtdb-origin-and-annotations.R` |
| S16 | GIFTs one step short of support, by phylum, and the requirements most often missing alone | R6.1 | **Drawn**; `29-gtdb-near-misses-and-gift-signal.R` |
| S17 | Phylogenetic signal (Fritz and Purvis's D) of each GIFT, by type and mode and against prevalence | R6.1 | **Drawn**; `29-gtdb-near-misses-and-gift-signal.R` |
| S18 | Which requirement is missing in a near miss: concentration on one step against the specificity of the steps present, and the most frequent candidates by phylum | R6.1 | **Drawn**; `30-gtdb-near-miss-steps.R` |

**Figure 1. One Boolean hierarchy resolves four capability types and retains
the evidence path.** (a) The OR/AND operators are identical across metabolic,
structural, regulatory and defense GIFTs while their biological entities remain
distinct. (b) The complete adenylate-biosynthesis fixture is traced from two
observed KO–gene pairs through components, systems and Rhea reactions to one
complete route and GIFT. Identifiers and confidence are evaluator output from
database 2026.27.1, not diagram-only labels.

**Figure 2. Declared anchors bound and compose metabolic GIFTs.** (a) IMP is the
curated branchpoint between purine-core biosynthesis and the separate adenylate
and guanylate branches. (b) PRPP-to-AMP capability is consequently a traversal
of two atomic GIFTs through IMP, not a stored composite; shared internal
reaction participants create no graph edge.

**Figure 3. Anchor compartment distinguishes three resource strategies.**
Extracellular polysaccharide cleavage can produce (a) a public-good product,
(b) a selfish chain when one genome also encodes uptake and catabolism, or (c)
a potential cross-genome compatibility when another genome can take up the
declared extracellular product. The panels describe encoded machinery and
boundary compatibility, not realised secretion, uptake or exchange.

**Figure 4. Declared frames and assessability make denominators explicit.**
(a) A synthetic accepted-marker profile supports five GIFTs in each of two
current frames. Amino-acid autonomy is bounded, so 5/22 is reportable;
carbohydrate degradation is unbounded, so its five-of-18 count has no licensed
fraction. (b) Treating the same illustrative profile as a 60%-complete MAG at a
90% threshold leaves its five positive calls unchanged but moves 17
amino-acid-autonomy negatives to indeterminate. `supported_fraction` must be
read with `assessable_fraction`. The profile is not a named genome.

**Figure 5. Community summaries preserve per-genome calls and project only
curated potential handoffs.** (a) Four illustrative genomes distribute four
arabinoxylan-chain GIFTs across six presences. (b) Provider counts retain
redundancy separately from community richness (four) and singleton fraction
(0.5). (c) The declared extracellular boundaries yield three exact potential
handoffs: A–B through XYLAN and B–C/B–D through XYLOSE_EX. Cytoplasmic
XYLOSE_IN remains within a genome.

**Figure 7. Community capability richness remains broad while the encoded
repertoire per detected MAG narrows across chicken caecal maturation.** The
four panels show community metabolic GIFT richness, mean metabolic GIFT
richness per detected MAG, community plant-fibre GIFT richness and exact
potential-handoff density for 388 samples from trials CA and CB at days 7, 21
and 35. MAGs are detected at the operational threshold of relative abundance
greater than 0.001; the source archive lacks the study's original per-sample
breadth matrix. Genome completeness changes absence denominators only. Points
are samples and boxes show their distributions. Handoff density is a projection
through curated extracellular anchors, not evidence of exchange, interaction
or activity.

**Figure S3. One high-repertoire MAG explains the two R10 richness modes.**
Community metabolic and plant-fibre GIFT richness are plotted against the
relative abundance of *Escherichia coli* MAG `cmag_510`; points are samples and
colours denote age. The dashed line is the operational detection threshold of
0.001. `cmag_510` supports 90 metabolic and 11 plant-fibre GIFTs, and its
thresholded detection separates all 78 lower-mode from all 310 upper-mode
samples. This is a sensitivity of a binary community-union metric to the
declared detection threshold, not evidence that the organism, its encoded
capabilities or their activity is truly absent below the line.

**Figure S4. Encoded GIFT repertoires across a broad bacterial phylogeny.**
Rows follow 696 complete-assembly species representatives selected from the
GTDB R11-RS232 bac120 tree after requiring assignment to at least one reviewed
origin group, with coverage of every eligible order and balanced origin counts.
Every sufficiently large group targets 85 genomes and smaller groups are
included exhaustively. Columns are the current GIFT catalogue, grouped by type.
Calls are coloured by evidence confidence and repertoire size is shown
separately. Major phyla are named beside the phylum strip. The final panel
gives, for the GTDB species each row represents, the mean and standard
deviation of assembly size over all R232 genomes assigned to that species; a
species with a single genome has no deviation. The panel is
phylogenetically enriched rather than frequency weighted. Cells describe
encoded capability, not expression, activity, phenotype or ancestral state,
and unsupported cells are not proof of biological absence.

**Figure S5. Curated capability frames separate temporal change from
stability.** Rows are all 19 database-defined reference frames; columns are the
adjusted day-21 and day-35 differences from day 7 in community richness, mean
per-MAG richness and, for the four bounded frames, community coverage. Green
requires equivalence within one GIFT for count metrics or five percentage
points for bounded coverage at every tested detection threshold. Orange marks a
classification that changes with the detection threshold; purple marks a time
association whose interval crosses the stability margin; and vermilion marks a
decrease outside the margin at the operational threshold whose direction is
robust across thresholds. Printed values are adjusted differences. Frames
group unchanged genome-level GIFT calls and are not composite GIFTs. Effects
describe encoded capability distribution, not expression, activity or flux.

**Figure S6. Adjusted capability-frame values across three sampling days.**
Points are population-standardised means from the same mixed models used for
Figure S5 at the operational detection threshold (>0.001); labels give the
adjusted value and error bars its 95% confidence interval. Panels show (A)
community richness, (B) mean per-MAG richness, and (C) community coverage for
the four bounded frames. The scale is fixed across reference frames within each
metric, and bounded coverage is shown from 0 to 100%. Lines connect age-level
estimates for visualisation and do not represent repeated measurements of one
bird. Values describe encoded capability distribution, not expression,
activity or flux.

**Figure S7. Frame-level change resolves to named genome-inferred
capabilities.** (A) Adjusted mean per-MAG richness at days 7, 21 and 35 for the
three reference frames classified as decreasing beyond one GIFT at both later
ages. (B) Adjusted carrier prevalence among detected MAGs for the six member
GIFTs with the largest descriptive day-35 minus day-7 decline in each frame.
Labels give adjusted values and error bars are 95% confidence intervals. The
GIFT ranking is explanatory and was not subjected to individual hypothesis
tests; complete trajectories for every member are retained in the source
table. Frame overlap is intentional, so the same GIFT may appear in more than
one column. Member-GIFT carrier fractions sum exactly to mean per-MAG frame
richness in every sample. Finer route, system and marker evidence defines each
genome-level call but does not vary across samples, so it is not presented as a
temporal measurement.

**Figure S8. Abundance weighting preserves the principal frame-level
declines.** (A) Adjusted trajectories for the three focal reference frames when
detected MAGs receive equal weight or are weighted by their relative abundance.
Abundance is closed within each sample's detected set, and the weighted frame
metric is the sum of its member GIFTs' abundance coverage. Labels give adjusted
means and error bars are 95% confidence intervals. (B) Equal-weight changes in
carrier prevalence and abundance-weighted changes in carrier share from day 7
to day 35 for the GIFTs displayed in Figure S7. Five of six focal frame
contrasts remain beyond the one-GIFT margin; the abundance-weighted vitamin
biosynthesis contrast at day 21 remains negative but its interval crosses the
margin. Carrier abundance describes encoded capability distribution, not
activity, expression or flux.

**Figure S9. Encoded repertoire size against genome size.** (A) Supported GIFTs
for each of the 696 GTDB panel genomes against the size of the evaluated
assembly. The line is a smooth quasi-binomial expectation of the supported share
of the 163 current GIFTs given log genome size, and the band is its 95% range.
Points are coloured by the standardised deviation from that expectation, and
the eight most extreme genomes in each direction are named. (B) The same
deviations in GIFTs. No single genome departs from the expectation at a false
discovery rate of 0.05. A deviation is a difference in encoded, curated
capabilities relative to this panel and this catalogue; it is not activity,
phenotype or a statement about functions the catalogue does not hold.

**Figure S10. Taxa above and below the size expectation.** Deviations from the
Figure S9 expectation for every phylum (A) and class (B) with at least five
panel genomes; genome counts are in brackets and taxa are ordered by median
deviation. A box is coloured when the taxon's standardised residuals differ
from zero in a two-sided Wilcoxon signed-rank test at a false discovery rate of
0.05 within rank. (C) Median deviation of each phylum when the expectation is
refitted on isolates only, on genomes at least 95% complete and at most 5%
contaminated by CheckM2, and on all genomes with CheckM2 completeness and
metagenome origin as covariates; filled points differ from zero at the same
false discovery rate. Genomes within a taxon are not phylogenetically independent
and the panel is enriched rather than frequency weighted, so the tests screen
for departures and do not estimate lineage-wide effects.

**Figure S11. Deviation from the size expectation is phylogenetically
clustered.** (A) The pruned GTDB bac120 tree of the 696 panel genomes, with the
12 most represented phyla named. (B) Each genome's deviation from the Figure S9
expectation, in GIFTs. (C) Moran's I of the standardised deviation among genome
pairs in 12 patristic-distance classes of equal pair count; the band is the 95%
range of 9,999 tip permutations and filled points differ from it at a false
discovery rate of 0.05. Pagel's λ and Blomberg's K for the standardised
deviation are given above the panels. Clustering describes how encoded, curated
capabilities are distributed over this panel; it is not an ancestral-state
reconstruction.

**Figure S12. Which GIFTs follow genome size.** (A) Spearman correlation between
genome size and the number of supported GIFTs in each class with at least five
GIFTs, with 95% bootstrap intervals over genomes. Classes are resolved from
`gift_type`, `mode` and the curated physiological-role and substrate-class
facets, and a GIFT can belong to several. (B) Log-odds of support per doubling
of genome size from one logistic regression per GIFT with at least ten genomes
carrying and ten lacking it, grouped by type and metabolic mode and coloured at
a false discovery rate of 0.05. Genomes are treated as independent although
Figure S11 shows they are not, and an association describes encoded capability
over this panel, not activity or phenotype.

**Figure S13. Encoded repertoire by origin of the genome.** (A) Difference in
log2 genome size, supported GIFTs and deviation from the Figure S9 expectation
for genomes carrying each nonexclusive origin tag, from phylogenetic regressions
(Pagel's λ) on the pruned bac120 tree in which the 12 tags with at least 20
genomes are fitted jointly; points with 95% intervals, filled at a false
discovery rate of 0.05 within response. (B) The same model for the standardised
number of supported GIFTs in each class, with log2 genome size as a covariate;
a dot marks a false discovery rate below 0.05 over all pairs. Origin tags are
coarse labels parsed from the free-text isolation source and the panel was
balanced on them by design. Differences describe encoded, curated capability,
not activity, phenotype or ecological function.

**Figure S14. Individual GIFTs by origin of the genome.** Prevalence inside
minus outside each origin group for the 45 GIFTs with the largest significant
difference; a dot marks Fisher's exact test at a false discovery rate below
0.05 over all origin and GIFT pairs. This screen adjusts for neither genome
size nor phylogeny, so a difference may reflect which lineages were sampled
from an origin.

**Figure S15. Encoded repertoire by assembly annotation.** (A) Difference in
the size deviation and in supported GIFTs associated with each assembly
annotation, fitted jointly in a phylogenetic regression (single-cell
assemblies excluded; continuous annotations per standard deviation; latitude
fitted alone on the genomes with coordinates). (B–D) Deviation from the Figure
S9 expectation by genome category, CheckM2 completeness and absolute latitude.
Completeness and contamination are themselves marker-based estimates.

**Figure S16. Where genomes fall one step short of a GIFT.** A near miss is an
unsupported GIFT whose closest curated implementation has at least two
requirements and lacks exactly one. (A) Near misses per genome for phyla with
at least five genomes, ordered and coloured by their deviation from the size
expectation. (B) The 30 requirements most often missing alone, as the share of
each phylum's genomes one step short on them; genome counts are in brackets. A
near miss is never counted as support. A requirement missing across a lineage
is a candidate for an alternative the catalogue has not curated or for a
capability the lineage does not encode, and the most frequent ones are
committing steps whose remaining requirements are shared with another GIFT or
rest on a broad marker.

**Figure S17. How each GIFT is distributed over the phylogeny.** Fritz and
Purvis's D for the 140 GIFTs carried and lacked by at least ten genomes, on the
pruned GTDB bac120 tree with 1,000 permutations. D is about 0 for a trait as
clumped as Brownian motion predicts and about 1 for a trait scattered at random.
(A) By GIFT type and metabolic mode. (B) Against prevalence, with the most
extreme GIFTs named. Colours give the test outcome at a false discovery rate of
0.05. D describes the distribution of an encoded, curated capability over this
enriched panel; it is not an ancestral-state reconstruction and does not
measure rates of gain or loss.

**Figure S18. Which step is missing when a GIFT is one step short.** (A) Each
point is one implementation and missing requirement with at least 20 near-miss
genomes: the share of that implementation's near misses that lack this
requirement, against the share of the requirements present that are specific
to the GIFT. A requirement is specific when no other GIFT requires the same
reaction or function or accepts one of its markers. (B) The 25 most frequent
candidates, in which the same requirement is missing while GIFT-specific
requirements are present, by phylum. A candidate may be an alternative the
catalogue has not curated, a marker that fails in a lineage, or a capability
that is not encoded; a near miss is never counted as support.

## References

Alberdi A, Andersen SB, Limborg MT, Dunn RR, Gilbert MTP. 2022. Disentangling
host–microbiota complexity through hologenomics. *Nature Reviews Genetics*
23:281–297. <https://doi.org/10.1038/s41576-021-00421-0>

Aramaki T, Blanc-Mathieu R, Endo H, Ohkubo K, Kanehisa M, Goto S, Ogata H.
2020. KofamKOALA: KEGG Ortholog assignment based on profile HMM and adaptive
score threshold. *Bioinformatics* 36:2251–2252.
<https://doi.org/10.1093/bioinformatics/btz859>

Bernstein DB, Sulheim S, Almaas E, Segrè D. 2021. Addressing uncertainty in
genome-scale metabolic model reconstruction and analysis. *Genome Biology*
22:64. <https://doi.org/10.1186/s13059-021-02289-z>

Bowers RM et al. 2017. Minimum information about a single amplified genome and
a metagenome-assembled genome. *Nature Biotechnology* 35:725–731.
<https://doi.org/10.1038/nbt.3893>

Eren AM et al. 2021. Community-led, integrated, reproducible multi-omics with
anvi'o. *Nature Microbiology* 6:3–6.
<https://doi.org/10.1038/s41564-020-00834-3>

Henry CS et al. 2010. High-throughput generation, optimization and analysis of
genome-scale metabolic models. *Nature Biotechnology* 28:977–982.
<https://doi.org/10.1038/nbt.1672>

Kanehisa M, Furumichi M, Sato Y, Matsuura Y, Ishiguro-Watanabe M. 2025. KEGG:
biological systems database as a model of the real world. *Nucleic Acids
Research* 53:D672–D677. <https://doi.org/10.1093/nar/gkae909>

Koziol A et al. 2023. Mammals show distinct functional gut microbiome dynamics
to identical series of environmental stressors. *mBio* 14:e01606-23.
<https://doi.org/10.1128/mbio.01606-23>

Louca S et al. 2016. Function and functional redundancy in microbial systems.
*Science* 353:1272–1277. <https://doi.org/10.1126/science.aaf4507>

Machado D, Andrejev S, Tramontano M, Patil KR. 2018. Fast automated
reconstruction of genome-scale metabolic models for microbial species and
communities. *Nucleic Acids Research* 46:7542–7553.
<https://doi.org/10.1093/nar/gky537>

Marcos S et al. 2026. Functional gut microbiota dynamics of generalist and
specialist bacteria in association with chicken growth. *ISME Communications*
6:ycag091. <https://doi.org/10.1093/ismeco/ycag091>

Madin JS et al. 2020. A synthesis of bacterial and archaeal phenotypic trait
data. *Scientific Data* 7:170. <https://doi.org/10.1038/s41597-020-0497-4>

Parks DH et al. 2022. GTDB: an ongoing census of bacterial and archaeal
diversity through a phylogenetically consistent, rank-normalized and complete
genome-based taxonomy. *Nucleic Acids Research* 50:D785–D794.
<https://doi.org/10.1093/nar/gkab776>

Ruiz-Perez CA, Conrad RE, Konstantinidis KT. 2021. MicrobeAnnotator: a
user-friendly, comprehensive functional annotation pipeline for microbial
genomes. *BMC Bioinformatics* 22:11.
<https://doi.org/10.1186/s12859-020-03940-5>

Schober I et al. 2025. BacDive in 2025: the core database for prokaryotic strain
data. *Nucleic Acids Research* 53:D748–D756.
<https://doi.org/10.1093/nar/gkae959>

Shaffer M et al. 2020. DRAM for distilling microbial metabolism to automate the
curation of microbiome function. *Nucleic Acids Research* 48:8883–8900.
<https://doi.org/10.1093/nar/gkaa621>

Zhou Z et al. 2022. METABOLIC: high-throughput profiling of microbial genomes
for functional traits, metabolism, biogeochemistry, and community-scale
functional networks. *Microbiome* 10:33.
<https://doi.org/10.1186/s40168-021-01213-8>

Zimmermann J et al. 2021. gapseq: informed prediction of bacterial metabolic
pathways and reconstruction of accurate metabolic models. *Genome Biology*
22:81. <https://doi.org/10.1186/s13059-021-02295-1>

The distillR software cited in the Background is archived at
<https://github.com/anttonalberdi/distillR>. References for database resources
used specifically in M3 and the submission analyses will be added with the
release-specific bibliography.

---

## Drafting roadmap

Structure follows `manuscript/outline.md`. Each row names what must be true
before the text can be finalised.

| Section | Depends on | Status |
|---|---|---|
| Background | — | **Complete** |
| R1. GIFT primitive | Type model frozen | **Complete** |
| R2. Boolean hierarchy | Five layers frozen across four types | **Complete** |
| R3. Anchors and composition | Compartment model frozen (schema 7) | Complete |
| R4. Quantitative traits | Frame API stable | **Complete**; worked example + Figure 4 |
| R5. Community | Community API stable | **Complete**; worked example + Figure 5 |
| R6. Reference database | Counts regenerated at submission | Complete, counts to refresh |
| R6.1. Phylogenetic overview | Results prose from the generated tables | Panel evaluated; Figure S4 drawn; prose pending |
| R7. Incompleteness | Nothing outstanding | **Complete**; prose and Figure 6 from `02-incompleteness.R` |
| R8. Tool comparison | Common genome subset + pinned KEGG-module/DRAM runs; METABOLIC excluded | Not started |
| R9. Phenotype agreement | Nothing outstanding | **Complete**; prose, Figure 8 and the annotation route all from committed scripts |
| R10. Case study | Nothing outstanding | **Complete**; prose and Figures 7/S3/S5--S8 from `21-r10-chicken.R`, `22-r10-handoff-bimodality.R` and `24-r10-reference-frame-time.R` |
| Discussion | R7-R10 | Skeleton |
| Conclusions | Discussion | Not started |
| M1. Curation protocol | Nothing; `inst/doc/` proposals are the raw material | **Complete** |
| M2. Schema and validation | Schema 7 frozen | Complete |
| M3. Versioning and provenance | — | Complete |
| M4. Evaluation algorithm | Assertions made in R2 must be specified | **Complete** |
| M5. Implementation | Public API frozen for 1.0.0 | Written, revisit at freeze |
| M6. Datasets and analysis | R8 and GTDB panel annotation | R10 complete; GTDB design written; R8 comparison methods pending |
| Availability | Release tag, Zenodo DOI | Pending release |
| Abstract | Everything | Draft, rewrite last |
| Figures 1-5 | Nothing — derivable today | **Complete**; `20-figures-core.R` |
| Figure S4 | Nothing — derived from the evaluated 696-genome panel | **Complete**; `23-gtdb-phylogeny.R` |
| Figure S5 | Nothing — derived from the audited R10 cache | **Complete**; `24-r10-reference-frame-time.R` |
| Figure S6 | Nothing — derived from the audited R10 cache | **Complete**; `24-r10-reference-frame-time.R` |
| Figure S7 | Nothing — derived from the audited R10 cache | **Complete**; `24-r10-reference-frame-time.R` |
| Figure S8 | Nothing — derived from the audited R10 cache | **Complete**; `24-r10-reference-frame-time.R` |
| Figure S9 | Nothing — derived from the evaluated 696-genome panel | **Complete**; `26-gtdb-repertoire-genome-size.R` |
| Figure S10 | Nothing — derived from the evaluated 696-genome panel | **Complete**; `26-gtdb-repertoire-genome-size.R` |
| Figure S11 | Nothing — derived from the evaluated 696-genome panel | **Complete**; `27-gtdb-size-signal-and-gift-classes.R` |
| Figure S12 | Nothing — derived from the evaluated 696-genome panel | **Complete**; `27-gtdb-size-signal-and-gift-classes.R` |
| Figure S13 | Nothing — derived from the evaluated 696-genome panel | **Complete**; `28-gtdb-origin-and-annotations.R` |
| Figure S14 | Nothing — derived from the evaluated 696-genome panel | **Complete**; `28-gtdb-origin-and-annotations.R` |
| Figure S15 | Nothing — derived from the evaluated 696-genome panel | **Complete**; `28-gtdb-origin-and-annotations.R` |
| Figure S16 | Nothing — derived from the evaluated 696-genome panel | **Complete**; `29-gtdb-near-misses-and-gift-signal.R` |
| Figure S17 | Nothing — derived from the evaluated 696-genome panel | **Complete**; `29-gtdb-near-misses-and-gift-signal.R` |
| Figure S18 | Nothing — derived from the evaluated 696-genome panel | **Complete**; `30-gtdb-near-miss-steps.R` |

**Open decisions**

1. ~~Phenotype reference set for R9~~ — **decided**: BacDive, MediaDive and Madin
   adopted, FAPROTAX refused, in `inst/doc/proposal-phenotype-validation.md`.
   The curated phenotype-to-GIFT crosswalk and the committed analysis scripts
   now exercise the decision.
2. ~~Case-study dataset for R10~~ — **decided**: the 822-MAG, 388-sample
   chicken caecal dataset of Marcos et al., reannotated with Drakkar 2.6.6 and
   analysed by `21-r10-chicken.R`.
3. ~~Reference genome set for R7~~ — **decided**: the 11,908-genome KEGG
   prokaryote set of `01-marker-matrix.R`, sampled stratified for R7. R8 still
   needs a common subset and pinned KEGG-module/DRAM runs; METABOLIC is
   deliberately excluded because it cannot use the common marker table.
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
