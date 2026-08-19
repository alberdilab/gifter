# Design proposal: quantitative genome and community traits derived from GIFT calls

Status: **accepted and implemented, phases 1-4, in package 0.1.0.**
Assessment performed 2026-08-19 against database version 2026.19.1 (130 GIFTs).
This document supersedes the externally drafted
`proposal-quantitative-genome-community-traits.md`, which was the starting
point. Sections 2 and 3 record what that draft got right, what it duplicated,
and where it is not implementable as written. Section 13 is the implementation
record, including the two places where the build departed from this plan.

Scope: decide how giftr should summarise sets of GIFT calls into quantitative
traits describing a genome and a genome-resolved community, without inventing a
fifth GIFT type, without claiming activity or flux, and without letting a
derived number outlive the evidence that produced it.

This layer is the one [the architecture guide](architecture.md#derived-capabilities)
already anticipated: "a derived layer would read their calls rather than adding
a fifth type." Nothing here is curated. Everything here is computed from calls,
curated facets, and the two existing derived views.

---

## 1. Recommendation in one page

1. **Accept the source draft's rules, reject roughly a third of its metrics.**
   Its design rules (§49 of the draft — explicit denominators, declared
   reference universes, presence/abundance/context kept separate, no ecological
   inference from overlap) are correct and become this layer's invariants. Its
   metric catalogue is about 30% redundant with machinery giftr already ships.
   §2, §3.
2. **Three of its "new" metric families already exist and must be read, not
   re-derived.** `gift_profile` already classifies every metabolic GIFT as
   `uptake` / `public_good` / `private` with a `substrate_tier`; `gift_graph`
   already emits 197 anchor-derived GIFT edges with an `edge_quality`;
   `evaluate_gifts()` already returns `number_of_complete_implementations`,
   which *is* the draft's §15 within-genome implementation redundancy.
   Re-implementing any of them would duplicate a biological definition in R,
   against [rule 10](../../AGENTS.md). §3.1.
3. **The draft's central data model has no producer, and this is the one real
   blocker.** Its `x_ig ∈ {1, 0, NA}` three-state matrix carries §6, §8, §20,
   §43 and §44. giftr's evaluator emits Boolean `complete` and has no genome
   quality input, no completeness estimate, and no notion of assessability.
   Every proportion in the draft therefore currently has an undefined
   denominator. §4 states the minimal honest fix. §3.2, §4.
4. **There is no multi-genome container.** `evaluate_gifts()` evaluates one
   annotation table. The draft's `profiles` argument is assumed into existence
   and never defined. A `giftr_community()` constructor is a prerequisite for
   all of Part II, not an implementation detail. §3.3, §6.
5. **Typed repertoire breadth is currently near-vacuous and must not be a
   headline trait.** The database is 122 metabolic, 3 defense, 3 regulatory, 2
   structural GIFTs. The draft's §13/§14/§15 breadth metrics would be computed
   over universes of two and three. Implement them generically so they become
   useful as curation grows; do not advertise them now. §3.4.
6. **Partition by `mode`, which the draft almost ignores.** `gift_type` barely
   partitions this database (94% metabolic). `mode` splits it 57 anabolic / 58
   catabolic / 4 interconversion / 3 transport and is curated, checked, and
   already load-bearing in the cycle rules. Richness by mode is as cheap as
   richness by type and far more informative today. §5.2.
7. **Add cycle closure, which the draft misses entirely.** `gift_cycles()` and
   `evaluate_gift_cycles()` already exist. "Does this genome close the
   oxidative citric acid cycle?" is a genome trait, and "is a cycle closed by
   the community but by no single member?" is a distinctive community trait
   that the draft's §31 gestures at without connecting to the machinery that
   would compute it. §5.5, §7.4.
8. **Every derived edge inherits `edge_quality`.** `gift_graph` distinguishes
   `exact` from `compartment_inexact` edges precisely so a compartment
   assumption stays visible. A community handoff edge built on an inexact GIFT
   edge is an inexact handoff. The draft never mentions this. §7.2.
9. **Refuse the composite indices, now and explicitly.** Entropy of functional
   repertoire (draft §16), inverse-Simpson provider diversity (§23),
   context relevance weights (§34) and the whole of its Tier 4 (§39) are not
   implemented. Two of them the draft already defers; the refusals are recorded
   here with reasons so they are not silently reopened. §8.
10. **One return shape: a long-form metric table plus a trace table.** The
    draft's §41 is right and its §17 wide "trait vector" is wrong. Every metric
    row carries `numerator`, `denominator`, `assessable`, `reference_universe`
    and `database_version`; every row is joinable to the GIFTs that produced it.
    §9.

---

## 2. What the source draft gets right

These become the invariants of this layer and are restated in §11.

- **Reference universes are part of the metric, not a footnote** (draft §4). A
  richness of 40 means nothing without the set it was counted over, and the
  catalogue will grow. Carrying `reference_universe` and `database_version` on
  every row is the difference between a comparable number and a number that
  silently changes meaning between releases.
- **Presence, abundance and context are three axes and never one** (§35). A
  GIFT present in a genome, a genome abundant in a sample, and a substrate
  available in an environment are independent facts. giftr can speak to the
  first, can carry the second if supplied, and deliberately models nothing of
  the third.
- **Traceability survives aggregation** (§40). This is
  [invariant 11](../../AGENTS.md) applied one layer up. A community metric that
  cannot name the genomes and GIFTs behind it is a regression even when the
  number is right.
- **Functional overlap is not cooperation** (§7 of its rules). Two genomes with
  disjoint repertoires are not thereby complementary, and an anchor-compatible
  pair is not thereby cross-feeding. The draft is disciplined about this
  throughout and the language it proposes — "potential provider interface",
  "potential resource handoff" — is the right register.
- **Genome quality modifies absence, never presence** (§43). No completeness
  estimate may promote an unsupported GIFT to supported. This is correct and
  becomes a hard constraint in §4.
- **Prefer interpretable components to composite indices** (its rules 10–11).

## 3. What the source draft gets wrong

### 3.1 Roughly a third of the catalogue already exists

| Draft section | Metric proposed | What already produces it |
|---|---|---|
| §9 resource acquisition breadth | substrates degraded / transported | `gift_profile.resource_strategy`, `.substrate_tier`, `gift_anchor` + `anchor.compartment` |
| §10 extracellular processing | public-good outputs | `gift_profile.resource_strategy = 'public_good'` (3 GIFTs), `.cross_feeding_output` |
| §11 uptake breadth | extracellular → cytoplasmic transport | `gift_profile.resource_strategy = 'uptake'` (3 GIFTs), `gift.mode = 'transport'` |
| §12 handoff interfaces | outputs matching curated inputs | `gift_graph` out-degree / in-degree per GIFT |
| §15 implementation redundancy | complete implementations per GIFT | `evaluate_gifts()$gifts$number_of_complete_implementations` |
| §28 resource-provision edges | genome → genome compatible handoffs | `gift_graph` joined against two call sets |
| §8 biosynthetic autonomy universe | biomass-relevant anabolic outputs | `gift_profile.auxotrophy_indicator` (40 GIFTs), `anchor_facet.biomass_essential` |

None of these should be recomputed from anchors in R. They are reads of
`gift_profile`, `gift_graph`, and the existing call columns. Recomputing them
would put a biological definition in two places, which is exactly what
[rule 10](../../AGENTS.md) forbids, and the two definitions would drift.

The consequence for effort estimation is favourable: the draft reads as a large
new subsystem and is mostly a projection layer over machinery that shipped with
the typed-GIFT migration.

### 3.2 The three-state matrix has no producer — the blocking gap

The draft's §3 defines the analytical state as

```text
x_ig = 1    supported
x_ig = 0    not supported with adequate opportunity to observe
x_ig = NA   indeterminate / inadequate opportunity to infer absence
```

and then builds `supported_fraction` (§6), `biosynthetic_autonomy` (§8),
`coverage_C` (§20), "assessable genomes" (§21) and the whole of Part VI on it.

giftr produces no such state. `evaluate_gifts()` returns `complete` as a
Boolean over all 130 GIFTs, and the package has no genome-quality input at all —
no completeness estimate, no contamination estimate, no assembly statistics, no
argument anywhere that accepts them. The phrase "adequate opportunity to
observe" has no referent in the current codebase.

This is not a detail the implementation can paper over. It means every
proportion the draft proposes currently has an undefined denominator, and the
draft treats the problem as a Part VI caveat (§43) rather than as the
prerequisite it is.

It is also a genuinely hard biological question, not an engineering one. A MAG
at 68% completeness that misses one of eight reactions in a route and a MAG at
99% completeness that misses eight of eight are both `complete = FALSE`, and
they mean very different things. Deciding when absence is informative is a
claim about genomes that giftr has never made.

§4 states the minimal version of that claim that can be defended today.

### 3.3 No multi-genome container is defined

Part II is written against a `profiles` object that the draft never constructs.
`evaluate_gifts()` takes one annotation table, returns one `giftr_result`, and
that result carries no genome identifier. Before any community metric exists
there must be an object that binds named results together, refuses to mix
database versions, and materialises the call matrix once. §6.

### 3.4 Typed repertoire breadth is currently vacuous

Current content:

```text
metabolic   122
defense       3
regulatory    3
structural    2
```

The draft devotes §13, §14 and §15 to structural, regulatory and defense
repertoire breadth. Over a universe of two structural GIFTs, "structural
repertoire breadth" takes values in {0, 1, 2} and `defense_class` has exactly
three registered terms for exactly three defense GIFTs, so defense mechanism
breadth and defense richness are the same number by construction.

The metrics are not wrong; they are premature as *headline* traits. The
resolution is the one the draft itself proposes for a different reason: drive
them from `gift_facet` metadata rather than hard-coded classes, so they need no
code change when curation grows. Implement them, compute them, and let the
`reference_universe` and `denominator` columns tell the reader that the
denominator is 2.

Similarly, `uptake_breadth` and `extracellular_processing_richness` currently
have universes of three GIFTs each. Computable; low discriminative power today.

### 3.5 Smaller corrections

- **§26 total-repertoire Jaccard is dominated by one type.** With 94% of GIFTs
  metabolic, an unstratified pairwise overlap is a metabolic overlap wearing a
  general name. Stratification by type, mode or facet should be the default
  call signature, not an option mentioned in passing.
- **§29 interaction density's `N * (N - 1)` denominator** counts ordered pairs,
  so a genome pair connected in both directions — common, since both members
  may encode both halves of a chain — contributes 2. That is defensible but
  must be stated, and the molecule-resolved variant the draft mentions is the
  more informative one.
- **§17's wide trait vector conflicts with §41's long table.** Pick the long
  table; a wide frame cannot carry per-metric denominators and universes.
- **`profile_genome()` / `profile_community()` (§45, §46) collide with the
  existing exported `gift_profile()`**, which is a GIFT-level database view and
  has nothing to do with genomes. §5.1 renames.

---

## 4. Assessability: the minimal defensible claim

**Recommendation: model assessability as an explicit, optional, named policy
layered on top of `complete`, never as a change to `complete` itself.**

```text
state(gift, genome) ∈ { supported, unsupported, indeterminate }

supported      ⟺  complete == TRUE          (never overridable)
unsupported    ⟸  complete == FALSE  and policy says absence is informative
indeterminate  ⟸  complete == FALSE  and policy says it is not
```

Two hard constraints:

1. **No policy may promote `unsupported` to `supported`.** Genome quality
   informs absence only. This is the draft's §43 and it is correct.
2. **The default policy is `"none"`, and it declares nothing indeterminate.**
   A user who supplies no quality information gets Boolean behaviour identical
   to today, and every proportion reports `assessable == denominator` so the
   assumption is visible in the output rather than buried in a vignette.

Two policies to consider, of which one ships:

**`"completeness"` — ship in phase 4.** Given a user-supplied per-genome
completeness estimate `c`, every `complete == FALSE` call on a genome with
`c < threshold` is `indeterminate`. Crude, transparent, and honest: below some
completeness you cannot assert the absence of anything, and pretending
otherwise is the failure mode the metric exists to avoid. The threshold is the
user's declared choice with no default, and it is recorded in the result.

**`"near_miss"` — record as a candidate, do not ship.** A call missing `k` of
`n` requirements is indeterminate when `k <= ceil((1 - c) * n)`. This uses only
data giftr already returns (`minimum_missing_requirements` and the requirement
count of the best implementation) and is more discriminating than a flat
threshold. It is also an unvalidated quantitative model of MAG gene loss, and
giftr does not ship unvalidated quantitative models of genomes. It needs an
empirical check against fragmented genomes of known content before it becomes a
default — that check is a piece of work, not a code review comment.

The policy name, its parameters, and the resulting per-genome assessable count
are carried in the result. A low assessable fraction raises a warning, per draft
§44.

---

## 5. Genome-level layer

### 5.1 Public API

```r
gift_universe(type = NULL, mode = NULL, facet = NULL, value = NULL,
              strategy = NULL, label = NULL, db = NULL)

genome_traits(result, universes = NULL, quality = NULL, policy = "none")
```

`gift_universe()` returns a `giftr_universe`: a set of `gift_id`s, a
human-readable `label`, the filter that produced it, and `database_version`.
Universes are built **only** from curated metadata — `gift.gift_type`,
`gift.mode`, `gift_facet`, `anchor_facet` and the `gift_profile` view. A
universe may never be a literal list of `gift_id`s in R source; that would put
biological content in code.

`genome_traits()` returns a `giftr_traits` object: `$metrics` (long form),
`$trace` (metric → contributing GIFTs), `$universes`, `$quality`,
`$database_version`.

Names avoid `profile_*` because `gift_profile()` is taken and means something
else (§3.5).

### 5.2 Metrics to implement

Partitioned by every universe supplied; the default universe set is
`type × {all}` plus `mode × {all}` plus the bounded universes below.

```text
gift_richness              count of supported GIFTs in the universe
supported_fraction         richness / assessable            (bounded universes only)
facet_breadth              distinct facet values with >= 1 supported GIFT
biosynthetic_autonomy      supported / assessable over auxotrophy_indicator = 1
resource_strategy_richness supported GIFTs per gift_profile.resource_strategy
substrate_tier_breadth     distinct substrate tiers with >= 1 supported GIFT
handoff_out_degree         supported GIFTs whose gift_graph out-edges exist
handoff_in_degree          supported GIFTs whose gift_graph in-edges exist
implementation_redundancy  distribution of number_of_complete_implementations
closed_cycles              cycles from evaluate_gift_cycles() closed by this genome
```

`supported_fraction` is emitted **only** for universes flagged bounded at
construction — the draft's §6 warning that an arbitrary denominator is worse
than no denominator, enforced in code rather than in prose.

### 5.3 Current universe sizes

Anyone shipping a metric should see this table first.

```text
all GIFTs                           130
  metabolic                         122
  defense                             3
  regulatory                          3
  structural                          2

  anabolic                           57
  catabolic                          58
  interconversion                     4
  transport                           3

biomass-essential anabolic (autonomy)  40
resource_strategy = private           115
resource_strategy = uptake              3
resource_strategy = public_good         3
resource_strategy = unresolved          1

substrate_class terms in use           17
physiological_role terms in use        14
defense_class terms in use              3
```

### 5.4 What a genome trait may not say

A trait counts encoded capabilities in the current giftr ontology. It is not a
measure of biological complexity, metabolic versatility in an environment,
growth independence, or phenotype. `biosynthetic_autonomy = 0.82` means 82% of
the curated biomass-essential anabolic capabilities that were assessable are
genomically supported. It does not mean the organism grows without
supplementation.

### 5.5 Cycle closure

`evaluate_gift_cycles()` already reports, for a call set, which elementary
cycles of the anchor graph are closed. Exposing `closed_cycles` as a genome
trait costs almost nothing and is a real topological statement about a genome
that no other metric in the draft captures.

---

## 6. The community container

```r
giftr_community(..., abundance = NULL)
```

Named `giftr_result` objects in, one `giftr_community` out. Responsibilities:

- assign and validate genome identifiers from the argument names;
- **refuse to combine results from different `database_version`s** — comparing
  calls across releases silently compares different universes;
- materialise the call matrix once (`genome × gift`, plus the assessability
  state from §4);
- carry the optional abundance vector, validated to be non-negative and named
  over the same genomes, and normalised with the original values retained.

The matrix is built once here rather than recomputed inside each metric.

---

## 7. Community-level layer

### 7.1 Distributional metrics

```r
community_traits(community, universes = NULL)
```

```text
community_richness       GIFTs supported by >= 1 genome
community_coverage       richness / assessable        (bounded universes only)
provider_count           per GIFT: genomes supporting it
provider_fraction        provider_count / assessable genomes
abundance_coverage       sum of a_i over supporting genomes   (if abundance given)
singleton_fraction       represented GIFTs with exactly one provider
unique_contribution      per genome: GIFTs it alone provides
repertoire_overlap       pairwise Jaccard, stratified by default (§3.5)
community_gain           community richness vs mean genome richness, both reported
```

Presence-based and abundance-weighted quantities are separate columns with
separate `unit` values and are never combined into one score.

### 7.2 Topology

```r
community_network(community, interaction = "metabolic_handoff")
```

A directed edge `genome i → genome j` exists when `i` supports a GIFT with an
extracellular output anchor, `j` supports a GIFT consuming a compatible input
anchor, and `gift_graph` already records that GIFT edge. The community layer
adds no new compatibility semantics; it projects an existing GIFT edge onto a
genome pair.

**Every edge carries the underlying `edge_quality`.** An edge built on a
`compartment_inexact` GIFT edge is an inexact handoff, and collapsing that
distinction would erase the reason the compartment qualifier exists. The draft
omits this entirely.

Edge table: `from_genome, to_genome, from_gift, to_gift, shared_anchor,
edge_quality`. Derived: `provider_degree`, `recipient_degree`,
`handoff_richness`, `interaction_density` (with the §3.5 caveat recorded in the
metric's own `derivation_method`).

`interaction = "metabolic_handoff"` is the only interaction type. Others are
added when the ontology defines a defensible compatibility rule, never from
co-occurrence.

### 7.3 Distributed chain coverage

For each path in `gift_graph`, classify against the community:

```text
within_genome_complete        one genome supports every GIFT in the chain
community_distributed         the chain is covered only by combining genomes
not_represented
```

The genome contributing each segment is retained. This is the draft's §31 and is
the most distinctive thing in the whole layer.

### 7.4 Distributed cycle closure

The same question for the elementary cycles of `gift_cycles()`: closed within a
genome, closed only across the community, or not closed. The draft misses this;
the machinery already exists.

### 7.5 Bottlenecks

Report the components — `provider_count`, downstream handoff degree, chain
membership — and do **not** collapse them into a bottleneck score. The draft
reaches the same conclusion in its §32 and it is correct.

---

## 8. Recorded refusals

Not implemented, with reasons, so they are not silently reopened.

1. **Entropy / effective number of functional categories** (draft §16). Depends
   on ontology balance and facet granularity, both of which are curation
   artefacts. The number would move when curation moved and would be read as
   biology.
2. **Inverse-Simpson provider diversity `D_g`** (§23). Requires abundances that
   are comparable across genomes in a way MAG relative abundance generally is
   not. `provider_count` and `abundance_coverage` carry the same information
   without the implied precision.
3. **Context relevance weights `w_gc`** (§34, Tier 3). giftr does not model
   media, metabolite concentrations, or environmental availability
   ([AGENTS.md, mission](../../AGENTS.md)). A user-supplied weight vector
   multiplied through a call matrix would be presented as a giftr inference
   while being entirely the user's assumption. Deferred until a formal context
   model exists as an architectural decision — and that decision is not this
   proposal's to take.
4. **The entire Tier 4** (§39): generalist/specialist indices, resilience,
   cooperation, competition, ecological importance, universal bottleneck
   scores. Each names an ecological property that genomic capability presence
   does not measure.
5. **The `"near_miss"` assessability policy** (§4), pending empirical
   validation.

---

## 9. Result shape

One long-form metric table, one trace table. Applies to both layers.

```text
metrics:
  target_type        genome | community | gift | genome_pair
  target_id
  metric_id
  value
  unit               count | proportion | index
  numerator
  denominator
  assessable
  reference_universe
  database_version
  derivation_method

trace:
  target_type, target_id, metric_id, gift_id, genome_id, contribution
```

`community_network()` returns nodes and edges separately, since an edge is not a
metric row.

The question the shape must answer without re-running anything:

> Why does this genome have `biosynthetic_autonomy = 0.82`?

`trace` names the 14 supporting GIFTs; `denominator` and `assessable` say 17 of
20; `reference_universe` says which 20.

---

## 10. Implementation plan

Phases are ordered so each is independently shippable and testable. Nothing in
a later phase is a prerequisite for an earlier one.

### Phase 0 — lock the decisions

Confirm §5.1 naming, the §4 default (`policy = "none"`), and the §9 long-form
shape. These are cheap to decide now and expensive to change after the API is
exported.

### Phase 1 — reference universes and genome traits

| File | Change |
|---|---|
| `R/universe.R` | new — `gift_universe()`, `giftr_universe` class, `print` method, bounded flag |
| `R/traits.R` | new — `genome_traits()`, `giftr_traits` class, `print` method |
| `NAMESPACE`, `man/` | regenerated |
| `tests/testthat/test-universes.R` | new |
| `tests/testthat/test-genome-traits.R` | new |

Tests must cover: a universe built from each metadata source; a bounded
universe emitting `supported_fraction` and an unbounded one refusing to; every
metric of §5.2 against a synthetic fixture with hand-computed expected values;
`trace` rows summing to `numerator`; a metric row's `database_version` matching
the result's.

### Phase 2 — community container and distributional traits

| File | Change |
|---|---|
| `R/community.R` | new — `giftr_community()`, `community_traits()` |
| `tests/testthat/test-community.R` | new — container contract, version mismatch refusal, abundance validation |
| `tests/testthat/test-community-traits.R` | new |

### Phase 3 — topology

| File | Change |
|---|---|
| `R/community-network.R` | new — `community_network()`, chain coverage, distributed cycle closure |
| `tests/testthat/test-community-network.R` | new |

The arabinoxylan fixture from the draft's §48 is the integration test, and it is
real: all four GIFTs exist and the chain is already wired in `gift_graph`.

```text
arabinoxylan_debranching --XYLAN--> xylan_degradation
xylan_degradation --XYLOSE_EX--> xylose_uptake_abc
xylose_uptake_abc --XYLOSE_IN--> xylose_degradation_isomerase
```

Assigning these to genomes A/B/C/D as the draft proposes gives hand-checkable
expected values for provider counts, singleton fraction, unique contribution,
the edge set `A→B, B→C, B→D`, and a chain that no single genome completes.

### Phase 4 — assessability

| File | Change |
|---|---|
| `R/assessability.R` | new — policy dispatch, `"none"` and `"completeness"` |
| `R/traits.R`, `R/community.R` | accept `quality` and `policy`, thread the three-state through denominators |
| `tests/testthat/test-assessability.R` | new — including the negative test that no policy promotes unsupported to supported |

Deliberately last. Phases 1–3 are correct and useful under `policy = "none"`,
and building them first means the assessability layer is added to a working
system rather than designed against a hypothetical one.

### Phase 5 — documentation

Per the table below.

---

## 11. Documentation plan

| Document | Change |
|---|---|
| `inst/doc/architecture.md` | new top-level section **Quantitative traits**, placed after [Derived capabilities](architecture.md#derived-capabilities), which already promises this layer. Covers the three-layer hierarchy, the reference-universe contract, the three-state model, what a trait may not say, and the recorded refusals. Add entries to the quick topic index. |
| `AGENTS.md` | one row in *Work in the correct files* (`Quantitative traits → R/universe.R, R/traits.R, R/community.R, R/community-network.R`); the §11 invariants added to *Non-negotiable biological invariants* as rules 20–23; a bullet in *Test biological behavior* requiring that every proportion has a tested denominator. |
| `inst/doc/proposal-quantitative-traits.md` | this file — updated to *accepted and implemented*, with an implementation record stating where the build departed from the plan, in the house style of [proposal-central-metabolic-cycles.md](proposal-central-metabolic-cycles.md) §18. |
| `README.md` | short subsection with one genome example and one community example. No new concepts. |
| `CHANGELOG.md` | one entry per phase, each stating change, reason and effect. Code change, not biological — nothing here goes in `database_changes.tsv`, because the database does not change. |
| `man/*.Rd` | roxygen for every exported function. Each `@return` states the unit and the reference universe; each function carrying an interpretation risk gets a `@section Interpretation:` naming what the number does not mean. |
| ~~`proposal-quantitative-genome-community-traits.md`~~ | **Not done, and deliberately.** See §13.2. |

No database rebuild is required at any phase. This layer reads the database and
changes nothing in it, so `database_release.tsv`, `database_changes.tsv` and the
SQLite artifact are untouched.

---

## 12. Invariants this layer must preserve

Restating the source draft's rules where they survived, plus the ones this
assessment adds. These are the candidates for AGENTS.md rules 20–23.

1. No metric without a biological definition, and no proportion without an
   explicit denominator and a declared reference universe.
2. A reference universe is derived from curated metadata, never written as a
   list of `gift_id`s in R source.
3. Presence, abundance and context are three axes and are never combined into
   one number.
4. Genome quality modifies the interpretation of absence only. Nothing may
   convert an unsupported GIFT into a supported one.
5. Interaction edges come only from explicit compatibility semantics already in
   the database, and inherit the `edge_quality` of the GIFT edge beneath them.
6. Every metric retains the GIFTs, genomes and anchors that produced it.
7. Prefer interpretable components to composite indices; add a composite only
   when it is clearer than its ingredients.
8. A quantitative trait describes encoded capability in the current ontology.
   It never describes activity, flux, phenotype or ecological effect, and the
   current database is not the universe of microbial function.

---

## 13. Implementation record

Phases 1 to 4 shipped in package 0.1.0 across four commits, each with its own
`CHANGELOG.md` entry. No schema, database content or evaluation change was
required at any phase: the compiled artifact is byte-identical and no Boolean
call moved. The full suite went from 3435 to 3566 assertions.

| Phase | Files | Exports |
|---|---|---|
| 1 | `R/universe.R`, `R/traits.R` | `gift_universe()`, `genome_traits()` |
| 2 | `R/community.R` | `giftr_community()`, `community_traits()` |
| 3 | `R/community-network.R` | `community_network()` |
| 4 | `R/assessability.R` | `quality`, `policy`, `threshold` arguments |

### 13.1 Departure: a cross-genome edge requires an extracellular anchor

**This plan did not anticipate the rule, and the fixture found it.**

§7.2 said the community layer "adds no new compatibility semantics; it projects
an existing GIFT edge onto a genome pair." Implemented literally, the
arabinoxylan fixture produced five edges rather than the three §10 predicted:
the extra two were `C -> D` and `D -> C` through `XYLOSE_IN`.

`XYLOSE_IN` is a **cytoplasmic** anchor. Genomes C and D each encode both xylose
uptake and xylose catabolism, so the composition link exists inside each of
them — but projecting it across the pair asserts that one organism hands another
a molecule that never leaves a cell.

The rule added: a cross-genome edge requires the producing GIFT's output anchor
to be declared `extracellular`. A `cytoplasmic` anchor is inside one cell by
construction, and an `unspecified` one was never evidenced as leaving it, which
is not the same as evidence that it does. With the rule the fixture yields
exactly `A -> B`, `B -> C`, `B -> D`.

This is a second compatibility rule, so it needed justifying rather than
assuming. It is defensible because `gift_graph` and this layer ask different
questions. The graph asks whether one GIFT's product is another's substrate,
which is true wherever the molecules match, inside a cell or not. The community
layer asks whether one *organism's* product can become another *organism's*
substrate, and that additionally requires the molecule to cross a membrane. The
compartment qualifier exists precisely to carry that distinction, and the
draft's own §28 stated it — "an **extracellular** output anchor" — without
noticing that its own §12 handoff counts did not.

Two consequences followed:

- `chain_coverage` gained a fourth status, `not_transferable`, for a link whose
  two halves fall in different genomes but whose molecule stays internal.
  Nothing completes such a link; classifying it `community_distributed` would
  have been the error, and classifying it `not_represented` would have been
  false, since both halves are encoded.
- Distributed cycle closure carries the same restriction. The oxidative citric
  acid cycle therefore reports `not_closed` however a community is composed,
  because central metabolism runs on intermediates that never leave a cell.
  §7.4 proposed distributed cycle closure as a distinctive metric; it is
  implemented, and the honest answer it currently gives is always negative.

### 13.2 Departure: the source draft was not copied into the repository

§11 planned to add the externally drafted
`proposal-quantitative-genome-community-traits.md` to `inst/doc/` for
provenance, on the model of how the other proposals preserve superseded
reasoning. It was not added.

The precedent does not transfer. What the other proposals preserve is giftr's
own reasoning at the moment a decision was taken — the refusal of
`succinate_formation`, the evidence behind an ambiguous marker — and that
reasoning is not recoverable from anywhere else. The source draft is an
externally generated document whose substance is already recorded here: §2
states what it got right, §3 records every duplication and every gap with the
evidence for each, and every metric it proposed is either implemented, renamed
with the rename stated, or refused in §8 with a reason. Adding 1400 lines that
say the same thing less accurately would make the design record harder to read
rather than more complete.

### 13.3 Departure: biosynthetic autonomy is not its own metric

§5.2 listed `biosynthetic_autonomy` beside `supported_fraction`. They are the
same quantity: autonomy is `supported_fraction` computed over the bounded
biomass-essential anabolic universe. Implementing it separately would have put
one biological definition in two places and given the ontology a special case in
R, so the metric was dropped and the universe kept. The default universe set
includes it, and it is the only bounded universe giftr ships.

### 13.4 Two metrics added that the plan did not list

`assessable_fraction` reports how much of the intended universe the
assessability policy could assess. It implements the draft's §44 and turned out
to be load-bearing rather than cosmetic: at 30% completeness a genome reports
`supported_fraction = 1.0` over a single assessable GIFT, which is
arithmetically correct and biologically empty. The fraction is what tells the
reader so, and a proportion over a universe less than half assessable now warns.

`provider_fraction` divides a provider count by the genomes that could assess
the GIFT rather than by all genomes, which only becomes a distinct quantity once
assessability exists.

### 13.5 What was implemented as planned

Reference universes from curated metadata only, with `bounded` as a declared
biological claim enforced in code; the long-form metric and trace tables of §9;
the community container refusing mixed database releases and mismatched
abundance vectors; presence and abundance in separate rows; overlap stratified
by universe; the `"none"` and `"completeness"` assessability policies with no
default threshold, and the constraint — tested — that no policy promotes an
unsupported GIFT to supported.

The `"near_miss"` policy of §4 was not implemented, as planned. Every refusal in
§8 stands.

### 13.6 Not yet done

Phase 5's documentation shipped with this record. Nothing else from this
proposal is outstanding. The natural next questions, none of which this document
decides:

- whether `community_network()` should gain a molecule-resolved interaction
  density beside the genome-pair one (§3.5);
- whether the typed repertoire metrics of §3.4 become worth reporting as
  curation grows the structural, regulatory and defense catalogues past their
  current 2, 3 and 3 members;
- whether `"near_miss"` can be validated against fragmented genomes of known
  content.
