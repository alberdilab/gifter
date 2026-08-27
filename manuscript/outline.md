---
title: "gifter manuscript — restructured outline"
target: "Microbiome (BMC, Methodology article) / mSystems (Research article)"
scope: "All four GIFT types, unified framing"
software_version: "gifter 0.5.0"
database_version: "2026.21.3 (schema 7)"
status: "Outline agreed 2026-08-22. Supersedes the section order in manuscript.md."
---

# Restructured outline

## Why the structure changes

`manuscript.md` is currently built as a *software paper*: concept → design →
implementation → evaluation. That order suits Bioinformatics. Neither
Microbiome nor mSystems accepts it. Both require the substance to sit in
**Results**, with mechanism in **Methods**:

```text
Microbiome (Methodology)   Background · Methods · Results · Discussion · Conclusions
mSystems (Research)        Introduction · Results · Discussion · Materials and Methods
```

For a tool paper in these venues, "Results" conventionally carries *what the
tool is and does* (as demonstrated behaviour), not only benchmark numbers.
The design exposition therefore does not get cut — it gets re-homed and
re-voiced from "here is how it is built" to "here is what it does".

No existing prose is discarded. The re-homing map is at the end.

## The unifying claim this outline is built on

The four `gift_type` values are not four models. They are one five-layer
alternating Boolean hierarchy under four vocabularies:

```text
GIFT             OR   implementations
implementation   AND  required requirements
requirement      OR   systems
system           AND  components
component        OR   accepted genomic markers
```

| `gift_type` | implementation | requirement | system | component |
|---|---|---|---|---|
| metabolic | route (204) | reaction (432) | enzyme system (495) | enzyme component (595) |
| structural | architecture (3) | structural function (17) | structural system | structural component (36) |
| regulatory | circuit (4) | regulatory function (10) | regulatory system (13) | regulatory component |
| defense | mechanism (5) | defense function (14) | defense system (20) | defense component |

This is the paper's strongest structural argument and currently appears
nowhere in the draft. It also justifies the type-neutral result columns
(`best_implementation`, `minimum_missing_requirements`,
`missing_requirements`) as a consequence rather than a convenience.

What differs between types is not the logic but the **composition
interface**: only metabolic GIFTs declare anchors. A flagellum has no input
molecule, and inventing one to fit the metabolic schema would be a boundary
claim nobody could defend. That asymmetry is a result, not an omission.

---

# Section plan

## Background *(≈900 words)*

Carries the current Section 1 almost unchanged; it was already written as a
background section.

- **B1.** Genome-resolved metagenomics has moved the bottleneck from recovering
  MAGs to interpreting them.
- **B2.** Three existing families and the different question each answers:
  marker checklists (fast, flat, percentage-based); genome-scale metabolic
  models (rich, gap-filled, hard to audit); trait databases (meaningful, not
  derived from the genome at hand).
- **B3.** The four situations a percentage cannot distinguish — alternative
  route, non-homologous enzyme, missing subunit, incomplete annotation. This
  is the paper's founding argument; keep it prominent.
- **B4.** distillR as the honest predecessor and what its abstraction could not
  express. Establishes that the redesign was necessary, not cosmetic.
- **B5.** Scope statement: gifter reports what a genome *encodes*. Not
  expression, activity, flux, growth or phenotype.

**Status:** prose complete, citations pending. Reframe B4 lightly so the
comparison reads as motivation rather than self-criticism.

## Results

### R1. The GIFT: a capability with a declared completeness contract *(≈700 words)*

Generalises the current Section 2 beyond metabolism. **This is the section
that has to be written first, because everything downstream inherits its
definition.**

- A GIFT is a biologically meaningful capability whose genomic support is
  evaluated through an explicit, curated and traceable completeness model.
- Each GIFT declares a `gift_type` naming that model. Four exist.
- A positive call means: *the available genomic evidence supports at least one
  complete known implementation of this capability.*
- A GIFT is not a pathway record, KEGG module, EC list or gene name. External
  links must state their boundary relation (`equivalent`, `subset_of`,
  `superset_of`, `overlaps`, `related`) — M00018 is `subset_of` three gifter
  traits.
- Completeness is discrete in every type. An incomplete call names the closest
  implementation and what is missing from it, never a percentage.

**Depends on:** nothing further; the model is frozen. **Write now.**

### R2. One Boolean hierarchy resolves four capability types *(≈900 words)*

The unifying claim above, in full, with the four-vocabulary table and the
type-neutral result columns.

- The five layers and what collapsing each would lose (the existing table,
  extended to the non-metabolic types).
- Materialised implementations rather than runtime Boolean expressions, and
  why (`route_1 = R1∧R2∧R3`, `route_2 = R1∧R2∧R4`).
- **Diagnostics are the point.** Closest implementation, minimum missing
  requirements, their identity, and deterministic tie-breaking. "One reaction
  missing from route *X*, namely RHEA:*n*" versus "87% complete".
- Evidence confidence reaches the call: ordered qualitative terms, weakest term
  wins, never averaged. The CAZy polyspecificity case (GH5/GH13/GH30/GH43,
  dbCAN subfamilies, 156 mappings marked `ambiguous`).
- **Evidence specificity bounds every call.** The two worked refusals: one
  ion-agnostic `flagellar_apparatus` because KEGG cannot separate PomA/PomB
  from MotA/MotB; but `chemotaxis_signal_transduction` and
  `aspartate_chemoreception` kept apart because the Tar orthologue *can* be
  separated. This pair — one merge, one split, same principle — is the single
  most persuasive passage available and belongs here, not in a README.

**Depends on:** nothing. **Write now.** Backed by Figure 1.

### R3. Anchors bound metabolic traits and compose them without duplication *(≈900 words)*

Current Section 4, narrowed explicitly to the metabolic type.

- Anchors are the public interface; internal intermediates are not runtime
  entities, so a shared intermediate never creates an edge.
- The trait graph is derived, not maintained. A longer capability is a
  traversal, not a curated object.
- Boundary rule and the purine worked cut (PRPP → IMP → AMP/GMP).
- Anchor vocabulary kept small: 154 entries for 149 traits.
- Modes and the cycle constraint; within-mode cycles rejected, between-mode
  accepted; the sulfur/homocysteine worked case.
- The narrow compartment model, and why it exists: public-goods degrader vs.
  selfish forager vs. cross-feeder is invisible if boundaries are
  compartment-blind. Compartment is a curated claim, not a genomic inference.
- Composition edge quality: `exact`, `compartment_inexact`, none.
- Facets and the derived profile (`resource_strategy`, `network_position`,
  `auxotrophy_indicator`); classification never enters the logic.

**Depends on:** nothing. **Write now.** Backed by Figures 2 and 3.

### R4. Quantitative traits are reported only against a declared frame *(≈800 words)* — **NEW**

Absent from the current draft. Half the package, and the "honest denominator"
argument is distinctive enough to be a selling point rather than a caveat.

- Calls are the primary result; the quantitative layer summarises sets of them
  without changing any.
- A quantitative trait is uninterpretable without the set it was counted over.
  Reference frames make that set explicit, versioned and reusable
  (19 presets; membership resolved from curated metadata, not stored ID lists).
- **`bounded` is the crux.** A fraction of the catalogue is offered only where
  curation intends complete coverage. Supporting 12 of 139 metabolic GIFTs does
  not mean a genome lacks 127 capabilities, so gifter refuses the fraction.
  Only 4 of 19 frames are bounded — the refusal is the common case.
- Metrics and their trace: every number names the GIFTs behind it.
- **Assessability under MAG incompleteness.** Absences on fragmented genomes are
  withheld from denominators rather than counted as capabilities the genome
  lacks. This is the direct methodological answer to the field's most common
  silent error, and it ties straight into R7.

**Depends on:** API stable (it is). **Write after R1–R3.**

### R5. Capability distribution and potential handoffs across a community *(≈800 words)* — **NEW**

Also absent. Carries the ecological weight the venue expects.

- `evaluate_gifts_community()`: one table split on `genome_id`, evaluated in
  parallel; a genome evaluated in a community is identical to the same genome
  evaluated alone, and worker count changes wall time and nothing else.
- Community metrics: richness, provider counts, redundancy, singletons,
  abundance coverage.
- Presence versus abundance kept as separate arguments because they are
  separate costs and separate claims.
- **`community_network()` invents no compatibility rule.** An edge exists where
  one genome's declared extracellular output anchor meets another's declared
  input anchor — the curated `gift_graph()` decides, the community projects.
  A cytoplasmic molecule never crosses between genomes. A genome supporting
  both ends composes internally and produces no edge.
- An edge is a **potential** compatibility relationship, never evidence that
  exchange occurs. Every edge carries its underlying `edge_quality`.

**Depends on:** API stable (it is). **Write after R4.**

### R6. The curated reference database *(≈700 words)*

Scale, coverage and the review surface. Curation *mechanics* move to Methods;
what stays here is what a reader needs to judge the resource.

- Table 1 (already refreshed): 149 GIFTs / 154 anchors / 432 reactions /
  204 routes / 495 systems / 595 components / 1,271 markers / 1,315 mappings /
  19 frames / 112 changelog entries, at db 2026.21.3, schema 7.
- Coverage by substrate class, and the non-metabolic content.
- Marker namespace distribution (KO 743, CAZY 520, TIGRFAM 5, EC 2, PFAM 1) and
  the confidence distribution (curated 866, high-confidence 293, ambiguous 156)
  — state these plainly; they are the resource's honest self-description.
- The self-contained interactive atlas as the review surface and a
  supplementary file.

**Depends on:** regenerate every count at submission. **Write now, refresh later.**

### R7. Behaviour under genome incompleteness *(evaluation — highest priority)*

Progressive gene subsampling from complete reference genomes; compare
route-based calls against percentage-based module completeness.

- Report call retention vs. genome completeness, and the distribution of
  `minimum_missing_requirements` as completeness falls.
- **Hypothesis:** the route-based call degrades conservatively *and names the
  lost requirement*, whereas the percentage decays smoothly and
  uninformatively.
- Second panel: assessability policy (R4) recovers interpretability that a
  naive denominator destroys.

**Depends on:** reference genome set; `manuscript/analysis/02-incompleteness.R`
and `08-figure-incompleteness.R`.
**Written.** The hypothesis holds in both halves and the cost is stated with it:
the call falls faster than the percentage (0.792 against 0.911 at 90% gene
content, 0.260 against 0.474 at half), and 66.9% of lost calls are exactly one
named reaction short. Figure 6 carries all three panels.

### R8. Comparison with existing tools *(evaluation)*

gifter calls vs. KEGG module completeness, DRAM and METABOLIC pathway
summaries on a common genome set. A comparison of abstractions, not a
benchmark with a winner: quantify agreement, then classify each disagreement by
cause (alternative route, non-homologous enzyme, incomplete complex, boundary
difference). The classification *is* the result.

**Depends on:** genome set + tool runs. **Not started.**

### R9. Agreement with observed phenotypes *(evaluation)*

Genomes of organisms with documented substrate-use or auxotrophy phenotypes;
report agreement and analyse disagreements frankly. **This section bounds what
the paper may claim about accuracy — the reference set must be chosen before
anything here is written.** mSystems and Microbiome will both expect it.

**Depends on:** phenotype reference set (undecided). **Not started.**

### R10. Ecological case study *(evaluation)*

A genome-resolved metagenomic dataset showing what the trait abstraction adds:
public-goods degraders vs. selfish foragers vs. cross-feeders via
`resource_strategy`; candidate auxotrophies via the derived profile;
community handoff topology via R5. A host-associated system with paired
metadata would show the framing best.

**Depends on:** dataset choice (undecided). **Not started.** This is what makes
it a Microbiome paper rather than a Bioinformatics note.

## Discussion *(≈1200 words)*

- **What the abstraction buys.** The unit of inference determines what can be
  said. Percentages cannot express alternatives, complexes or non-homologous
  replacement and cannot name the missing step; full metabolic models can but
  require gap filling and sacrifice auditability.
- **Curation is the cost**, and the answer is not to reduce it but to make it
  reviewable and cumulative: human-readable sources, a validator that rejects
  incoherent structure, a changelog attached to the content, composition that
  forbids duplicating an atomic trait.
- **Limitations, stated plainly.** Encoded ≠ expressed; coverage is the current
  limit and absence of a trait is not absence of capability; calls inherit
  upstream annotation quality and marker specificity; compartment is curation,
  not inference; boundaries are defensible decisions, not unique truths.
- **Outlook.** Broader coverage; deeper non-metabolic curation; evidence
  namespaces beyond orthology; interoperability with metabolic modelling as a
  source of curated, non-gap-filled capability claims.

## Conclusions *(Microbiome only, ≈200 words)*

## Materials and Methods

Mechanism, moved out of the narrative. Existing prose re-homes here largely
verbatim.

- **M1. Curation protocol.** Boundary rules, the defended-boundary requirement,
  refusal cases, review record.
- **M2. Schema, validation and compilation.** The two paths
  (`anchor → GIFT → anchor`; `marker → component → system → requirement →
  implementation → GIFT`); Rhea identity with direction stored per
  implementation; open `namespace + accession` marker keys; validation
  separating broken structure from debatable biology; atomic compilation.
- **M3. Versioning and provenance.** Three versions (package / database /
  schema), two changelogs, upstream release pinning (Rhea 141, ChEBI 253,
  KEGG 2026-08-20), and the explicit statement that no upstream database
  endorses a gifter boundary decision.
- **M4. Evaluation algorithm.** Marker normalisation and indexed lookup;
  resolution order; deterministic closest-implementation and tie-breaking;
  confidence propagation; parallelisation and its invariance.
- **M5. Implementation and testing.** R ≥ 4.1, small dependency surface,
  concept-oriented API, the two enforced rules (no biological definition in R;
  traceability is a feature, not debug output), and the invariant-based test
  suite.
- **M6. Datasets and analysis.** Genome sets, tool versions and parameters,
  and the analysis scripts for R7–R10.

## Availability

Source, release tag, Zenodo DOI, MIT-0 licence, database version and its own
DOI decision, analysis repository.

---

# Figures

| # | Content | Supports | Status |
|---|---|---|---|
| 1 | The five-layer hierarchy under four vocabularies; purine resolved through all layers from markers to call | R1, R2 | Not started |
| 2 | Anchors as boundaries: purine cut points, composition through declared anchors, derived trait graph | R3 | Not started |
| 3 | Compartment and strategy: one polysaccharide resolved as public-goods degradation, selfish foraging, cross-feeding | R3, R5 | Not started |
| 4 | Frames and honest denominators: bounded vs. unbounded, assessability under MAG incompleteness | R4 | Not started |
| 5 | Community: capability distribution, redundancy, potential handoff topology | R5 | Not started |
| 6 | Call retention vs. genome completeness, route-based vs. percentage | R7 | Blocked on analysis |
| 7 | Case-study results | R10 | Blocked on dataset |
| S1 | Data lifecycle: TSV sources → validation → compilation → runtime, and the version tracks | M2, M3 | Not started |
| S2 | The interactive database atlas | R6 | Exists; needs packaging |

Figures 1–5 are all derivable from the software today and are not blocked.

---

# Re-homing map

Nothing in `manuscript.md` is discarded.

| Current | Becomes | Change needed |
|---|---|---|
| §1 Introduction | Background | Light reframe of the distillR passage; citations |
| §2 GIFT concept | R1 | **Generalise beyond metabolism** — anchors stop being definitional |
| §3 Evaluation model | R2 + M4 | Extend to four vocabularies; move algorithm detail to M4 |
| §4 Composition/compartments | R3 | Narrow explicitly to metabolic type |
| §5 Reference database | R6 + M1/M2/M3 | Split resource description from curation mechanics |
| §6 Implementation | M5 | Move wholesale; re-voice |
| §7 Evaluation plan | R7–R10 | Becomes results |
| §8 Discussion | Discussion | Keep; finalise after results |
| §9 Availability | Availability | Fill at release |
| — | **R4, R5** | **Write from scratch** |

# Open decisions

1. **Phenotype reference set for R9** — bounds every accuracy claim in the paper.
2. **Case-study dataset for R10** — determines whether the ecological argument lands.
3. Reference genome set for R7 and R8, and which comparison tools to actually run.
4. Microbiome vs. mSystems (both fit this outline; affects Conclusions section and length).
5. Author list and contributions.
6. Whether the database gets its own DOI separate from the software.

# Standing rules

- Nothing in R7–R10 may be written before a committed script in
  `manuscript/analysis/` has produced it.
- Regenerate every database count from the compiled artifact at submission.
- The scope disclaimers in Background and Discussion are the paper's
  honest-uncertainty contract, not boilerplate. They survive every revision.
