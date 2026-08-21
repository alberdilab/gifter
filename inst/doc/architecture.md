# gifter development and architecture guide

This guide explains the biological model, database schema, development workflow,
and curation rules behind gifter. It is the detailed companion to the
repository-wide [agent instructions](../../AGENTS.md).

Use the headings and keywords below as a search index. The same terms are used
in source-table names and code wherever practical.

## Quick topic index

| Question or keyword | Go to |
|---|---|
| What is a GIFT? What is outside scope? | [Core concepts and scope](#core-concepts-and-scope) |
| GIFT type, metabolic, structural, regulatory, defense | [GIFT types](#gift-types) |
| Architecture, structural function, machinery model | [The machinery model](#the-machinery-model) |
| Motility, virulence, cross-feeding, higher-order traits | [Derived capabilities](#derived-capabilities) |
| Richness, breadth, reference universe, denominator | [Quantitative traits](#quantitative-traits) |
| Community, provider count, redundancy, handoff network | [Quantitative traits](#quantitative-traits) |
| Genome completeness, assessability, indeterminate call | [Assessability](#assessability-when-absence-is-informative) |
| OR/AND hierarchy, completeness, closest route | [Evaluation logic](#evaluation-logic) |
| Anchor, boundary, branchpoint, composition, graph | [GIFT boundaries, anchors, and composition](#gift-boundaries-anchors-and-composition) |
| Compartment, transport, uptake, extracellular | [Compartment and transport](#compartment-and-transport) |
| GIFT mode, catabolic cycle, acyclicity | [Composition without duplication](#composition-without-duplication) |
| Citric acid cycle, circular metabolism, closure | [Cycles in the composition graph](#cycles-in-the-composition-graph) |
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

A **genome-inferred functional trait (GIFT)** is a biologically meaningful
capability whose genomic support is evaluated through an explicit, curated and
traceable completeness model.

"Functional" is intentionally broad. A genome encodes capabilities that are not
chemistry: it encodes machines, circuits and defenses. The precision does not
come from narrowing the word, it comes from `gift_type` and from the explicit
completeness contract each type carries.

```text
GIFT
├── metabolic     a directed capability between curated molecular anchors
├── structural    the machinery to build a defined cellular structure
├── regulatory    the machinery to sense a signal and execute a response
└── defense       the machinery to execute a defined defense mechanism
```

Every type answers the same three questions in its own vocabulary: what is
claimed, what makes the claim complete, and what evidence supports it. What none
of them does is soften the answer into a score.

A **metabolic GIFT** is a directed biological capability between curated
molecular boundaries. It claims that a genome contains sufficient genomic
evidence for at least one known enzymatic route connecting its input anchor or
anchors to its output anchor or anchors.

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

Anchors, routes, reactions, orientation, enzyme systems, components and the
composition graph all belong to the metabolic model. A structural GIFT has none
of them, and must never acquire them: a flagellum has no input molecule, and
inventing one to satisfy a schema would make the boundary layer meaningless for
the GIFTs that genuinely use it. The build rejects it.

External databases contribute chemistry, identifiers, pathway suggestions, and
annotation evidence. They do not define the gifter ontology. A KEGG module is
not automatically a GIFT, and gifter boundaries may intentionally differ from
an external pathway's endpoints.

### What a positive call means

A positive result means approximately:

> The available genomic evidence supports at least one complete curated
> implementation of this capability.

It does not prove expression, enzyme activity, physiological flux, substrate
availability, environmental relevance, or phenotype under every condition.
Genome annotations are evidence rather than certainty, and user-facing language
must preserve that distinction.

This is not weaker for the non-metabolic types; it is the same claim in a
different vocabulary, and the gap between machinery and behaviour is wider there
because the behaviours have names people already use:

| Positive call | Does **not** mean |
|---|---|
| `flagellar_apparatus` | that the cell is motile, that the flagellum is expressed or assembled, or that it rotates in any environment |
| `type_iva_pilus` | twitching motility, natural competence, or adhesion to anything |
| a regulatory GIFT | that the circuit is active, or that its regulon responds |
| a defense GIFT | that an attacker is actually resisted |

A structural call says the genome encodes the parts list and the machine that
builds it. Everything after that is physiology.

### What gifter deliberately does not model

gifter is not a genome-scale metabolic model. Unless a future architectural
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
- complete pathway stoichiometry at runtime;
- **respiration, and any capability whose completion requires an external
  terminal electron acceptor.**

The last item is a rule with consequences, so it is stated separately rather
than left implicit:

> A capability whose completion requires an external terminal electron acceptor
> is out of scope. Curate the part of the chemistry that ends before the
> acceptor, and name the trait for what that part does.

It is what refuses nitrate respiration, denitrification, dissimilatory nitrate
reduction to ammonium, fumarate respiration, and "taurine to hydrogen sulfide",
and it is why `nitrate_assimilation` ends at ammonium and both taurine
capabilities end at sulfite. The refusal is architectural, not evidential: the
markers for NarGHI, NirK, NosZ and DsrAB are specific, abundant and easy to
curate, which is precisely why the boundary is written down. Curating them
would make positive claims about energy conservation that the completeness
model cannot bound. Reversing this needs its own proposal, its own completeness
contract, and probably its own `gift_type`.

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

## GIFT types

`gift_type` is a core ontology field, not a facet. A facet classifies a call;
`gift_type` decides which completeness model produces one, which source tables
may attach to the GIFT, and what a positive call is allowed to mean. Changing it
changes the relational contract, which is why introducing it was a schema
migration.

The vocabulary is closed and deliberately small:

```text
metabolic | structural | regulatory | defense
```

Adding a type is an architectural decision, not a data entry. A new type must
arrive with a stated completeness contract, its own validation rules, and a
curated or fixture-backed example. A vocabulary term with nothing behind it
teaches curators that the vocabulary does not mean anything.

### What each type contributes

| Type | Claim | Complete when | Missing element reported |
|---|---|---|---|
| `metabolic` | A directed capability between curated molecular anchors | any curated **route** has every required reaction supported | the missing **reactions** of the closest route |
| `structural` | The machinery to build a defined structure or molecular machine | any curated **architecture** has every required structural function supported | the missing **functions** of the closest architecture |
| `regulatory` | The machinery to detect a defined signal and execute a defined response | any curated **circuit** has every required regulatory function supported | the missing **functions** of the closest circuit |
| `defense` | The machinery to execute a defined defense mechanism | any curated **mechanism** has every required defense function supported | the missing **functions** of the closest mechanism |

Every type carries curated content:

| Type | Curated GIFTs |
|---|---|
| `metabolic` | 126, from purine biosynthesis and central metabolism to nutrient acquisition and polysaccharide saccharification |
| `structural` | `flagellar_apparatus`, `type_iva_pilus` |
| `regulatory` | `chemotaxis_signal_transduction`, `aspartate_chemoreception`, `phosphate_starvation_response` |
| `defense` | `type_i_restriction_modification`, `type_i_e_crispr_cas_machinery`, `mercury_detoxification` |

### Type-scoped structure

The build enforces which model a GIFT uses:

- a metabolic GIFT **must** declare input and output anchors, at least one
  route, and a `mode`; it may not own an architecture, circuit or mechanism;
- a structural, regulatory or defense GIFT **must** own at least one
  implementation of its own type; it may **not** declare anchors, routes or a
  `mode`;
- an implementation may not name a GIFT of another type, so an architecture
  cannot be attached to a metabolic GIFT;
- required facets are scoped by type: metabolic GIFTs carry `substrate_class`
  and `physiological_role`, structural GIFTs carry `structural_class`,
  regulatory GIFTs `regulatory_class` and defense GIFTs `defense_class`, and a
  facet required of one type may not classify another.

The last rule is what keeps the type honest. Without it a structural GIFT could
acquire a `substrate_class` and start looking like chemistry in every filter
that reads facets.

### Why the types are not one generic model

Structural, regulatory and defense GIFTs share a Boolean shape. They do not
share biology. A reaction has an identity independent of any organism — a Rhea
master, a direction within a route, and reuse across GIFTs that have nothing
else in common. A structural function does not: it is a part of a thing being
built. A regulatory function is an information-processing step. A defense
function is a step in resisting an attack.

Merging them into one table set named for their shape rather than their meaning
would make every curated row harder to review, which is the opposite of what the
source tables are for. They are therefore kept as parallel, biologically named
families, and only the operations whose semantics really are identical are
shared in code: marker matching, component support, system AND logic, confidence
ordering, deterministic tie-breaking, and result assembly.

Whether any of them should later share a representation is a question to revisit
once all three carry real curated content. It is not a question to answer in
advance.

## The machinery model

The three non-metabolic types share one relational shape, instantiated three
times under their own names:

```text
STRUCTURAL GIFT
  |
  +-- OR --> ARCHITECTURE
                  |
                  +-- AND --> STRUCTURAL FUNCTION
                                   |
                                   +-- OR --> SYSTEM
                                                  |
                                                  +-- AND --> COMPONENT
                                                                 |
                                                                 +-- OR --> MARKER
```

Substitute *circuit* and *regulatory function* for the regulatory type, and
*defense mechanism* and *defense function* for the defense type.

In Boolean form:

```text
structural GIFT   = ANY complete architecture
architecture      = ALL required structural functions
structural fn     = ANY complete system
system            = ALL required components
component         = ANY accepted genomic marker
```

Each layer answers a different biological question, exactly as in the metabolic
model:

- Multiple **architectures, circuits or mechanisms** are genuinely different ways
  to achieve the same capability. The diderm and monoderm flagella are one
  worked example: the monoderm envelope has no outer membrane for the L ring to
  sit in, so the bushings are absent by construction rather than unannotated.
  The PhoR/PhoB and PhoR/PhoP circuits are another: they share the sensor and
  differ in the cognate response regulator, and a genome carries one or the
  other.
- Multiple **systems** are alternative implementations of one function. PilB and
  PilF are non-interchangeable orthologues that both power pilus extension;
  CheZ, CheC and CheX are three unrelated families that all dephosphorylate
  CheY-P.
- Multiple **components** are proteins a machine jointly requires. The five
  proteins of the flagellar export gate are one system, not five functions, and
  so are the five subunits of the type I-E Cascade complex.
- Multiple **markers** are alternative evidence for one component. The
  chemoreception function accepts any characterised chemoreceptor, which is what
  keeps an *Escherichia coli* annotation — carrying no generic-MCP orthologue at
  all — from being called receptor-less.

### Accessory functions

`required = 0` marks a function whose absence does not make the implementation
incomplete. It is used where the biology says a machine works without a part,
not where evidence is inconvenient. The curated cases:

| Accessory function | Why the capability survives without it |
|---|---|
| type IVa pilus retraction ATPase | a genome without PilT builds a pilus it cannot retract |
| chemotaxis signal termination | CheY-P also autodephosphorylates; the phosphatase families are unevenly distributed |
| PstSCAB–PhoU | independently a transport capability the metabolic model already covers |
| CRISPR spacer acquisition | a system interferes using the spacers it already has |

An implementation whose functions are *all* accessory could never be defensibly
complete, so the build rejects it.

### Reuse rather than duplication

Functions are curated once and referenced by every implementation that needs
them, including across GIFTs. The nine functions shared by the two flagellar
architectures exist as nine rows, not eighteen; the PhoR sensor function is one
row serving two circuits; and the chemotaxis kinase, response-regulator and
adaptation functions are the same rows in `chemotaxis_signal_transduction` and
`aspartate_chemoreception`, which differ only in their reception function.

This is the machinery counterpart of not copying an atomic GIFT's reactions into
a larger trait: a definition that exists twice will eventually disagree with
itself.

### Structural GIFTs have no anchors

A structural GIFT must not declare molecular boundaries. This is not a
simplification; it is the point. Anchors are what make metabolic GIFTs compose,
and a fake anchor pair on a flagellum would inject a meaningless node into the
composition graph and the derived profile. Both are metabolic-only by
construction, and the validator rejects the attempt.

## Derived capabilities

Higher-order ecological and phenotypic descriptions — motility, virulence, host
association, cross-feeding, competition, public-good behaviour, community
resilience — are **not** new GIFT types and should not become curated primary
traits.

They are combinations of primary typed GIFTs:

```text
flagellar_apparatus              (structural)
  +  chemotaxis_signal_transduction  (regulatory)
  ->  potential chemotactic motility

metabolic extracellular substrate release by organism A
  +  metabolic uptake and catabolism by organism B
  ->  potential cross-feeding interaction
```

Both halves of the first example are now curated and separately callable, which
is the point: a genome can encode a flagellum without a chemosensory pathway, or
a chemosensory pathway that steers something else. Fusing them into a `motility`
trait would hide which half a particular genome actually satisfies, and would
add the physiological assumptions — expression, energisation, a gradient — that
neither call makes.

The precedent is already in the database. `gift_profile` derives resource
strategy, network position, cross-feeding output and auxotrophy indication from
declared anchors, anchor facets and the composition graph. Nothing in it is
curated, which is why adding it required no curation campaign: the signal was
already there and simply had no way out.

Curating "motility" directly would do the opposite. It would fuse a structural
claim, a regulatory claim and a set of physiological assumptions into one row
that no evidence supports as a unit, and it would hide which part of it a
particular genome actually satisfies.

This migration deliberately does **not** implement a general derived-capability
engine. It keeps the architecture able to carry one: primary types stay
separately callable, and a derived layer would read their calls rather than
adding a fifth type.

### Deferred: programmatic capabilities

Sporulation does not fit the structural model. Building an endospore is a
coordinated developmental programme — ordered compartment-specific regulons, an
asymmetric division, engulfment, a cascade of morphological stages — not the
assembly of one machine. It is recorded as a candidate for a future
`programmatic` type in
[the structural proposal](proposal-structural-gifts.md), and that type is
deliberately **not** in the schema until its completeness contract can be
stated.

## Quantitative traits

The derived layer the previous section anticipated now exists. It reads the
calls `evaluate_gifts()` produced and summarises them into quantitative traits
of a genome and of a genome-resolved community. Nothing in it is curated,
nothing in it changes a call, and it adds no GIFT type. The design record,
including the metrics deliberately refused, is
[the quantitative traits proposal](proposal-quantitative-traits.md).

```text
genomic evidence
      |
      v
  GIFT calls                      <- evaluate_gifts()
      |
      +----------------------+
      |                      |
      v                      v
genome traits          community traits     <- genome_traits(), community_traits()
      |                      |
      +----------+-----------+
                 |
                 v
        handoff topology                    <- community_network()
```

### A number without its universe is not a result

A count of supported GIFTs is meaningless without the set it was counted over,
and that set grows with every curation campaign. Every metric therefore names
its **reference universe**, and `gift_universe()` builds one from curated
metadata only — `gift_type`, `mode`, the registered facet vocabulary, and the
derived `gift_profile` view. A universe may never be a list of `gift_id`s
written in R source; that is [rule 10](../../AGENTS.md) one layer up, and it is
what keeps the biological content in the database where it can be validated and
versioned.

Every metric row carries `numerator`, `denominator`, `assessable`,
`reference_universe` and `database_version`, and a companion `trace` table names
the GIFTs behind it. The question the shape exists to answer without re-running
anything is:

> Why does this genome have `supported_fraction = 0.82`?

### Named reference universes

Recurring analytical questions are registered as named reference universes in
`reference_universes.tsv`, `reference_universe_filters.tsv` and
`reference_universe_metrics.tsv`. `list_gift_universes()` discovers them and
`gift_universe(preset = ...)` resolves one against the current database release.
The registry stores filter recipes, descriptions, interpretation limits and
recommended metrics. It never stores GIFT membership. The HTML atlas renders
that same registry as a searchable question-to-analysis guide, including the
current member count and the rationale for every genome, community or network
metric; the guide therefore changes with the database rather than becoming a
second source of analytical curation.

Filter values are ORed within one metadata key and distinct keys are ANDed. The
`carbohydrate_degradation` preset, for example, selects catabolic GIFTs whose
`substrate_class` is polysaccharide, monosaccharide, amino sugar or uronate. A
new GIFT enters that universe only through those curated assignments; no R list
needs updating. Presets do not become GIFTs, change calls, or add completeness
logic. Cycle closure and cross-genome handoffs remain dedicated derived
operations because their meaning depends on connections among GIFTs, not set
membership alone.

### Bounded and unbounded universes

`supported_fraction` is reported only for a universe explicitly declared
`bounded`, meaning it enumerates a biologically closed set that curation intends
to cover completely. The curated biomass-essential anabolic GIFTs are such a
set, and the fraction of them a genome supports is biosynthetic capability
coverage.

"All metabolic GIFTs" is not such a set. The catalogue is open and growing, and
a genome supporting 12 of 122 has not been shown to lack 110 capabilities. The
flag is therefore a biological claim, not a formatting option, and the refusal
is enforced in code rather than left to a caveat in prose.

### Assessability: when absence is informative

`evaluate_gifts()` answers whether the observed markers support a complete
curated implementation, and answers it identically for a closed isolate genome
and a 60%-complete MAG, because the markers are all it sees. That is correct for
a call and wrong for a denominator: a genome that was never fully observed has
not been shown to lack anything.

A third state therefore sits on top of the Boolean call, under a named policy:

```text
supported                  the markers support a complete implementation
confidently unsupported    they do not, and the policy reads that as absence
indeterminate              they do not, and the policy declines to read it
```

`"none"` is the default and declares nothing indeterminate, so a caller who
supplies no quality information keeps Boolean behaviour with
`assessable_fraction` stating the assumption. `"completeness"` takes a genome
completeness estimate and an explicit threshold and withdraws every negative
call below it from every denominator.

Two constraints bind any policy added later. **No policy may promote an
unsupported GIFT to supported** — quality informs the reading of absence and
nothing else. And **indeterminacy is resolved per genome**, so a fragmented
member's silence is withheld from a community provider denominator while a
complete member's is not.

Completeness is read on either scale. A set of values whose largest member
exceeds 1 can only be percentages, because a proportion cannot; a set that stays
at or below 1 is read as proportions, so 1 is a complete genome rather than a 1%
one. The scale is decided once over every value supplied and applies to the
threshold too, so an analysis stated entirely in percentages and the same
analysis stated in proportions are the same analysis. The one case the rule
cannot settle — a genome below 1% inside a percentage table — is warned about
rather than assumed.

The `"completeness"` policy has no default threshold. How complete a genome must
be before its silence is informative is the analyst's declared choice, and a
package default would be read as a recommendation.

### Community topology reuses the composition graph

`community_network()` invents no compatibility rule. `gift_graph` already
decides when one GIFT's declared output anchor reaches another's declared input,
and the community layer projects that decision onto the pair of genomes that
support its ends. Every edge inherits the `edge_quality` beneath it, so a
handoff resting on an unlicensed compartment reads as `compartment_inexact`
rather than as an ordinary edge.

One rule the graph itself does not impose is added here, because the graph is
not answering the same question. **A cross-genome edge requires the producing
GIFT's output anchor to be declared `extracellular`.** A `cytoplasmic` anchor is
inside one cell by construction; an `unspecified` one was never evidenced as
leaving it. Without the rule, two genomes that each encode xylose uptake and
xylose catabolism produce edges through `XYLOSE_IN` — a claim that one organism
hands another a molecule that never leaves a cell.

The same link inside one genome is an ordinary composition step and is still
reported as complete there, which is why a link whose halves fall in different
genomes but whose molecule stays internal is classified `not_transferable`
rather than `community_distributed`: nothing completes it. Distributed cycle
closure carries the same restriction, so the oxidative citric acid cycle is
never reported as closed across a community however it is composed.

### What these numbers may not say

A quantitative trait counts encoded capabilities in the current gifter ontology
within a stated universe. It is not a measure of biological complexity,
metabolic versatility in an environment, growth independence, activity, flux,
phenotype, or ecological effect.

Specifically:

- `biosynthetic_autonomy` is genomic coverage of curated biomass-essential
  anabolic capabilities. It does not mean the organism grows without
  supplementation.
- `abundance_coverage` is the share of observed genome abundance carrying a
  capability. It is not a share of activity, transcript production or effect,
  which is why it never merges with `provider_count`.
- `repertoire_overlap` measures repertoire difference. Two genomes with
  disjoint repertoires have different repertoires; they have not been shown to
  be complementary, and nothing here infers interaction from overlap.
- `unique_contribution` counts GIFTs no other **sampled** genome provides. It
  does not make a genome ecologically indispensable, and it moves when the
  sampling does.
- A handoff edge is a potential compatibility relationship. Cross-feeding is a
  hypothesis it can support, never a conclusion it establishes.

Entropy of functional repertoire, inverse-Simpson provider diversity, context
relevance weights, and every generalist, resilience, cooperation, competition
and importance score are refused with reasons in
[the proposal](proposal-quantitative-traits.md#8-recorded-refusals), so that
they are not silently reopened.

## Evaluation logic

Every GIFT type is evaluated through explicit Boolean layers, and the layers are
never collapsed. This section describes the metabolic model; the machinery types
are in [The machinery model](#the-machinery-model).

gifter separates biological meaning, chemistry, enzymology, and genomic
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

Two molecule classes are common enough as reaction participants that they need
an explicit admission rule, or they become boundaries of half the database by
accident.

**Cofactors.** A cofactor may be declared an anchor only where a reaction
*consumes* it as a substrate — BluB dismantles FMNH2 to build the benzimidazole
ring — and never where it is recycled catalytically. Without the rule, THF, PLP
and NAD become input anchors of most biosynthetic GIFTs and the anabolic
acyclicity check collapses.

**Inorganic nitrogen.** Ammonium may be declared an anchor only where the
reaction's *purpose* is to liberate it from an organic substrate or to
assimilate it into one, never where it is a leaving group of chemistry aimed at
a different product, or a co-substrate of amidation. The consumption test above
is not sufficient here, because the ammonia-dependent NAD synthetase genuinely
consumes ammonium; the nitrogen rule asks what the reaction is *for*.

Applied to the four curated reactions that mention NH4+, the rule admits one
and rejects three:

| Reaction | Role of NH4+ | Admitted |
|---|---|---|
| `RHEA:12172` glucosamine-6-phosphate deaminase | the reaction *is* the deamination | yes |
| `RHEA:21868` riboflavin pathway deaminase | leaving group of a ring modification | no |
| `RHEA:40075` aminodeoxyfutalosine deaminase | leaving group en route to a naphthoquinone | no |
| `RHEA:21188` NAD synthetase (ammonia) | co-substrate of an amidation | no |

Each rejection prevents a specific absurdity: admitting the first two would
make riboflavin and menaquinone biosynthesis nitrogen sources, and admitting
the third would make NAD biosynthesis an ammonium sink that every
ammonium-releasing catabolic GIFT composed into.

Both rules are curator judgements recorded in the anchor's description and
enforced by review rather than by the validator, which is the honest place for
them: no schema constraint can express "what the chemistry is aimed at".

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
directed GIFT mode**. Every GIFT declares one:

```text
anabolic | catabolic | transport | interconversion
```

The first three declare a direction the curated route travels. The fourth
declares that there is no single direction to state, and it carries its own
boundary contract:

```text
anabolic, catabolic   one direction, declared by the anchors
transport             one molecule, two compartments
interconversion       every anchor declared as BOTH input and output
```

`interconversion` is for a near-equilibrium node whose enzymes run both ways in
different organisms and whose markers cannot say which. `acetate_interconversion`
is the worked example: the same phosphotransacetylase and acetate kinase that
release acetate from acetyl-CoA assimilate acetate into acetyl-CoA in a genome
growing on it, and 6582 KEGG organisms carry the pair without the evidence
distinguishing the two physiologies. Declaring only `ACETYL_COA > ACETATE`
would assert a direction nothing supports; splitting it into two GIFTs would
assert a distinction the same two genes cannot make.

The validator enforces the contract in both directions. A GIFT that is not an
interconversion may not declare an anchor as both input and output, and an
interconversion GIFT must declare **every** anchor that way -- declaring some
reversibly and others not would claim a direction for half the boundary.

The route layer is unaffected, and deliberately so. A route is an ordered list
of reactions with per-reaction orientation, and it records **one** traversal of
the node. A mirror route with every orientation flipped would complete on
exactly the same markers, so it would report two complete routes for one
capability and make closest-route selection non-deterministic. Direction lives
in the anchors for composition and in `route_reaction.orientation` for
chemistry; those answer different questions and are not kept in step.

The HTML atlas follows the same rule. A reversible GIFT draws each anchor once,
with a double-headed arrow between the sides, rather than listing both roles on
both sides -- `ACETYL_COA <-> ACETATE`, not
`ACETYL_COA ACETATE -> ACETATE ACETYL_COA`. In the whole-database anchor network
the two opposing edges collapse into one edge with a head at each end, and the
per-GIFT route network draws the whole chain both ways, for the same reason: a
one-way arrow asserts the direction the mode exists to deny. Each reaction still
carries its own `forward` or `reverse` badge inside that chain, which is not a
contradiction -- see the note below on what `orientation` is relative to.

Note that `route_reaction.orientation` is relative to how Rhea writes that
reaction's own equation, not to the direction of the GIFT. In
`ACETATE_PTA_ACKA` the phosphotransacetylase step is `forward` and the acetate
kinase step is `reverse`, and both run towards acetate: Rhea writes acetate
kinase in its named, acetate-consuming direction, so chaining the two requires
flipping one of them.

Within a directed mode, a cycle still usually indicates that the chosen
boundaries or directions need review. Between modes it is expected, because
catabolism legitimately returns to metabolites biosynthesis produces:

```text
FRUCTOSE_6P --> ... --> GLCNAC        (anabolic)
GLCNAC      --> ... --> FRUCTOSE_6P   (catabolic)
```

Rejecting that pair would reject correct biology. Rejecting an anabolic loop
would not, which is why the check is scoped rather than removed.

`interconversion` is exempt from the check altogether, and the exemption is not
a concession to any particular biology. That mode's contract requires every
anchor to be declared in **both** roles, so two interconversion GIFTs sharing
one anchor produce an edge in each direction by construction:

```text
X <-> Y   and   Y <-> Z        gives     XY --> YZ  and  YZ --> XY
```

The loop is made by the mode, not by the boundary, and reporting it would be
the check reading its own contract back as a curation error. Nothing about the
chemistry is involved: two synthetic reversible GIFTs sharing one fixture anchor
reproduce it, which is what `test-composition.R` asserts.

Acyclicity is a real design constraint in the directed modes, not a formality.
Sulfur metabolism is the worked example: cysteine donates sulfur to methionine, and homocysteine
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

### Cycles in the composition graph

Some real metabolism closes a ring. The oxidative citric acid and glyoxylate
cycles are the worked examples, and gifter represents them with no new kind of
object: ordinary metabolic GIFTs whose declared anchors happen to close.

```text
reaction              RHEA:16845, RHEA:10336, RHEA:19629, ...
   |                  identity from Rhea, direction from route_reaction
   v
atomic GIFT           acetyl_coa_to_isocitrate, isocitrate_to_oxoglutarate,
   |                  glyoxylate_bypass, oxoglutarate_to_succinate,
   |                  succinate_fumarate_interconversion,
   |                  fumarate_oxaloacetate_interconversion
   v
topology              chains, branches, convergences, CYCLES
                      derived from gift_graph(); nothing curated
```

`gift_cycles()` enumerates the elementary cycles of that graph. It is graph
code and contains no biology, so it already finds both curated central cycles
and will find the reductive citric acid cycle or Calvin cycle on the day those
are curated, without being changed. There is no circuit table, and there should not be one: a
curated list of member GIFTs would duplicate `role` and shape the graph already
knows, and could then disagree with it. It would also collide with
`gift_circuit`, which is the **regulatory** model's implementation table.

The one thing derivation cannot supply is a name, so that much is curated, as a
facet rather than a table:

```text
metabolic_cycle = citric_acid_cycle_oxidative | glyoxylate_cycle
```

`gift_cycles()` reports that value as `named_cycle` when every member of a
derived cycle carries it, and `NA` otherwise -- an unnamed cycle is still
reported, which is what keeps the accessor general instead of a lookup for the
rings somebody remembered to label.

Two kinds of ring are excluded, and both are excluded because the **mode** makes
them rather than the chemistry. A two-node loop between `interconversion` GIFTs
is produced by that mode's boundary contract, which declares every anchor in
both roles. A ring containing both an `anabolic` and a `catabolic` member says
that a genome can build a metabolite and also break it down -- true of arginine,
proline, threonine and cysteine once the amino acid layer is curated -- and
composition is *expected* to cycle between modes, which is why the source
validator checks acyclicity per mode. Neither loop is circular metabolism, and
reporting them would bury the rings that do run one way: before the exclusion,
mixed-mode rings outnumbered the citric acid cycle by more than thirty to one.

`evaluate_gift_cycles()` reads a genome's calls against those cycles and reports
`closed`, `open` with the broken members named, or `absent`. **Closure is
derived from Boolean calls and never changes one.** A segment is complete on its
own routes and markers whether or not its neighbours are; inferring a
capability's absence from a neighbour's absence is the opposite of what the
composition model is for. And a `closed` cycle is a statement about encoded
chemistry, not about flux, direction or expression -- two of the oxidative
cycle's five segments are `interconversion` precisely because gifter cannot say
which way they run.

A two-node loop between two `interconversion` GIFTs is not reported, for the
same reason the validator exempts it: it is made by the mode's boundary
contract rather than by chemistry.

The full analysis, including why a monolithic cycle GIFT and a per-reaction
decomposition were both rejected, is in
[the central metabolic cycles proposal](proposal-central-metabolic-cycles.md).

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
three different GIFTs because gifter cuts it at two branchpoints, and
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

gifter may query or import Rhea chemistry while constructing and validating
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
CUSTOM_HMM  gifter_purA
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

### Evidence specificity bounds claim specificity

The invariant is type-independent:

> The specificity of any GIFT claim must not exceed the specificity of the
> genomic evidence supporting it.

It has an instance in every type:

| Type | Over-broad evidence | Claim it must not license |
|---|---|---|
| metabolic | a polyspecific CAZy family | one of the family's activities as a substrate-specific trait |
| metabolic | EC 3.4.24.26, which hydrolyses elastin, collagen, fibronectin and IgA | cleavage of any one of them |
| structural | K02556/K02557, which KEGG assigns to both *E. coli* MotA/MotB and *Vibrio* PomA/PomB | a proton- or sodium-driven flagellar apparatus |
| structural | a type IV pilus assembly machine | twitching motility, natural competence, or adhesion |
| regulatory | K03406, assigned to 34 genes in one *Vibrio cholerae* genome | chemotaxis toward a named chemoeffector |
| regulatory | K07660, which shares the gene name *phoP* with the phosphate regulator | a phosphate starvation response |
| defense | K01154, the type I specificity subunit | which target sequence the system recognises |
| defense | a generic Cas protein | a CRISPR subtype, or functional interference without a detectable array |

Each row above is enforced by a test, not only stated. The strongest case is
curated twice on purpose: `chemotaxis_signal_transduction` accepts a generic
chemoreceptor, `aspartate_chemoreception` accepts only Tar, and a genome with
the generic receptor completes the first and not the second.

The remedy is always the same, and it is never to widen the marker: state the
broader claim the evidence supports, or refuse the trait and record why. The
flagellar coupling-ion refusal is worked through in
[the structural proposal](proposal-structural-gifts.md); the ligand-specific
chemotaxis case in [the regulatory proposal](proposal-regulatory-gifts.md); the
CRISPR array case in [the defense proposal](proposal-defense-gifts.md); and the
aromatic substrate case, where nine requested capabilities were refused because
a ring-hydroxylating dioxygenase family cannot say which ring it hydroxylates,
in [the aromatic degradation proposal](proposal-aromatic-degradation.md). The
gallate case in
[the shikimate aromatics proposal](proposal-shikimate-aromatics.md) is the same
refusal reached from the other end: there the trait fails before specificity is
even in question, because no Rhea reaction and no EC number exist for the
chemistry, and the only markers on offer are the AroE markers the core shikimate
pathway already uses.

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

The normalized model has three complementary paths. The first two describe a
metabolic GIFT; the third describes a machinery GIFT of any non-metabolic type,
instantiated once per type under its own table names:

```text
anchor -> metabolic GIFT -> anchor

marker -> enzyme component -> enzyme system -> reaction -> route -> metabolic GIFT

marker -> component -> system -> function -> architecture/circuit/mechanism -> GIFT
```

The `marker` table is shared by every model, because a KO is the same object
whichever capability it evidences. Everything above it is per-model. Component,
system, function and implementation identifiers are validated to be unique
across the models, because a trace prints them without saying which table they
came from.

The reviewable source uses plural TSV filenames. The compiled SQLite database
uses singular table names and internal integer primary keys. Stable public IDs
remain present in both forms.

| Source file | Runtime table | Purpose and stable key |
|---|---|---|
| `gifts.tsv` | `gift` | Biological claim; `gift_id`, with `gift_type` and, for metabolic GIFTs, `mode` |
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
| `reference_universes.tsv` | `reference_universe` | Named analytical universe, boundedness claim and interpretation limits; `universe_id` |
| `reference_universe_filters.tsv` | `reference_universe_filter` | Metadata query defining dynamic membership; never a GIFT-ID list |
| `reference_universe_metrics.tsv` | `reference_universe_metric` | Scope-specific metric recommendations and rationale |
| `gift_architectures.tsv` | `gift_architecture` | Alternative complete architecture of a structural GIFT; `architecture_id` |
| `architecture_functions.tsv` | `architecture_function` | Architecture membership, ordinal, and required flag |
| `structural_functions.tsv` | `structural_function` | Reusable structural or assembly function; `function_id` |
| `structural_systems.tsv` | `structural_system` | Alternative implementation of a structural function; `system_id` |
| `structural_components.tsv` | `structural_component` | Jointly required protein within a structural system |
| `structural_component_markers.tsv` | `structural_component_marker` | Evidence mapping for a structural component |
| `gift_circuits.tsv`, `circuit_functions.tsv`, `regulatory_*.tsv` | `gift_circuit`, `circuit_function`, `regulatory_*` | The same six shapes for the regulatory model |
| `gift_mechanisms.tsv`, `mechanism_functions.tsv`, `defense_*.tsv` | `gift_mechanism`, `mechanism_function`, `defense_*` | The same six shapes for the defense model |
| `database_changes.tsv` | `database_change` | Curation history entry; `change_id` |
| `change_gifts.tsv` | `change_gift` | GIFTs a recorded change affects |
| `database_release.tsv` | `database_release` | Database, schema, upstream-source, date, and commit metadata |

The SQL contract is in `inst/schema/gifter.sql`; the compiler and structural
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
biological source of truth. `inst/extdata/gifter.sqlite` is generated output.
Never curate the SQLite file directly.

Provenance can come from Rhea, ChEBI, KEGG, MetaCyc, UniProt, primary literature,
curated HMM collections, or expert curation. Record what each source actually
supports:

- Rhea defines reaction chemistry.
- ChEBI identifies an anchor molecule.
- KEGG or MetaCyc may suggest a pathway organization or cross-reference.
- UniProt, HMM resources, or literature may support enzyme/marker mappings.
- gifter chooses the capability, boundaries, accepted routes, and curation
  interpretation.

Do not imply that an upstream database endorses a gifter-specific boundary or
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
reaction chemistry, alternatives, and direction match the gifter claim.

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
`validate_gifter_sources()`, and compiles
`inst/extdata/gifter.sqlite` with `build_gifter_database()`. Compilation is
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
gifter package version     code and public API release
gifter database version    biological content release
schema version               relational contract/migration level
```

For example:

```text
package:   2.3.1
database:  2027.04
schema:    2
```

Schema version 6 introduced `gift_type` and the three machinery models. Because
`gift_type` decides which tables may attach to a GIFT, it changed the relational
contract rather than adding an optional column, which is what made it a
migration rather than a field.

A package release must not silently change biological definitions without
database provenance. A schema change requires an explicit schema-version bump
and coordinated updates to the SQL schema, TSV source specification, compiler,
validation, tests, and documentation. Update `database_release.tsv` with the
database version, schema version, build date, upstream resource releases, and
source commit. Keep upstream release identifiers distinct from gifter's own
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
get_gift_machinery()
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
gift_cycles()
evaluate_gift_cycles()
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
- every GIFT curated before the typed migration is `metabolic`, and its calls,
  traces, graph edges and profile are unchanged by the migration;
- an unknown or missing `gift_type` is rejected, and a typed source row cannot
  be attached to a GIFT of another type;
- a structural GIFT cannot declare anchors, routes or a `mode`;
- alternative architectures complete independently, all required structural
  functions are jointly needed, alternative systems satisfy one function, a
  multisubunit system fails when a component is missing, and an accessory
  function does not enter the call;
- an incomplete machinery call names the closest implementation and the
  functions missing from it, deterministically;
- a mixed-type database evaluates in one `evaluate_gifts()` call, and
  `gift_type` reaches the result and the browsing API;
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
- `tests/testthat/test-gift-types.R` for the typed contract and the
  no-metabolic-regression guarantee;
- `tests/testthat/test-structural.R` for the structural model, on synthetic
  fixtures and on the curated flagellar and pilus content;
- `tests/testthat/test-regulatory-defense.R` for the regulatory and defense
  models, on synthetic fixtures and on the curated chemotaxis, phosphate,
  restriction-modification and CRISPR-Cas content;
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
- **Architecture:** One complete curated way to build the structure a structural
  GIFT claims. Architectures are alternatives under OR.
- **Circuit:** One complete curated implementation of a regulatory GIFT.
- **Defense mechanism:** One complete curated implementation of a defense GIFT.
- **GIFT:** A biologically meaningful capability whose genomic support is
  evaluated through an explicit, curated and traceable completeness model. Its
  `gift_type` names that model.
- **GIFT type:** `metabolic`, `structural`, `regulatory` or `defense`. A core
  ontology field, not a facet: it decides which completeness model applies and
  which tables may attach to the GIFT.
- **Metabolic GIFT:** A directed genome-inferred capability between declared
  anchors, complete when any valid route is complete.
- **Structural function:** A discrete structural or assembly function an
  architecture requires. The structural analogue of a reaction: the unit whose
  absence an incomplete structural call reports.
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
