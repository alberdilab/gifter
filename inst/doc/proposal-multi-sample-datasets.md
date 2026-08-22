# Design proposal: multi-sample datasets over one genome catalogue

Status: **accepted and implemented, phases 1-5, in package 0.6.0.**
Assessed 2026-08-22 against package 0.5.0, database version 2026.21.3
(149 GIFTs, schema 7, 14 default reference universes).

This document extends the layer
[the quantitative traits proposal](proposal-quantitative-traits.md) created. It
adds no GIFT type, no schema, no curated content and no completeness logic.
Every number it defines is a re-reading of calls that already exist, and every
refusal recorded in §8 of that proposal stands unchanged here. §10 below adds
five more.

Scope: decide how gifter should represent one genome catalogue observed across
many samples, how per-sample quantitative traits are derived without evaluating
anything more than once, and — the decision that matters most — where gifter
stops and a statistics package begins.

---

## 1. Recommendation in one page

1. **Add one container, `gifter_dataset`, composed of an existing
   `gifter_community` plus a genome × sample abundance matrix.** Composition
   rather than a parallel container: the release check, the distinct-name check
   and the `gifter_genome` membership check are inherited rather than
   reimplemented, and every existing function keeps working on one sample. §5.
2. **Calls are a property of a genome, not of a sample.** The catalogue is
   evaluated once and a dataset holds exactly one call matrix. Across samples
   only two things vary: which genomes are members, and how they are weighted.
   This is the whole design; everything else follows from it. §3.
3. **Every per-sample distributional metric is a matrix product over all
   samples at once.** Three products per reference universe answer every
   sample. A loop calling `community_traits()` once per sample would be
   S × U × G² and is not acceptable at the sizes this layer exists for. §6.
4. **`repertoire_overlap` is sample-invariant and moves to the catalogue.**
   The Jaccard index of two genomes' repertoires is a property of the two
   genomes; so is `gift_richness`. Recomputing them per sample would re-emit
   the same numbers S times and reintroduce the quadratic cost the 0.5.0
   release removed. The result therefore carries **two** metric tables, not one
   nullable column. §7, §11.
5. **Detection is to samples what assessability is to genomes.** Both may only
   move denominators. This is the invariant the layer exists to establish, it
   extends [invariant 21](../../AGENTS.md), and it is proposed as AGENTS.md
   rule 24. §12.
6. **Absence from a sample may be below detection rather than genuinely
   absent, and gifter models no sequencing depth.** Every sample-level richness
   row therefore reports `detected_genomes` beside it, exactly as
   `supported_fraction` is reported beside `assessable_fraction`. No
   imputation, no depth correction, no rarefaction. §6.5, §10.
7. **`detection` is a reading of an abundance, not a property of one**, so it
   is an argument of `dataset_traits()` and `dataset_network()`, not of the
   constructor — on the same terms, and for the same reason, that `threshold`
   is an argument of `community_traits()` rather than of
   `gifter_community()`. §5.4.
8. **gifter runs no hypothesis test, differential-abundance analysis,
   ordination or effect size between groups of samples.** It emits per-sample
   traits joined to sample metadata, and an assessability-aware matrix with a
   declared reference universe. That export is the deliverable. §8, §10.
9. **The export surface is small and is what makes the layer useful.**
   `gift_matrix()` promotes the existing internal `.assessable_matrix()` to a
   public three-state genomes × GIFTs matrix; `dataset_matrix()` reshapes one
   metric to samples × target for `vegan`; a tidy accessor joins metrics to
   metadata. Three functions. §8.
10. **One composite is added, and only one.** `mean_repertoire_overlap` per
    sample is reported because its ingredients stay exactly recoverable from
    the catalogue table and the detection matrix, and because functional
    redundancy between groups of samples is the question this layer exists to
    make answerable. Its sample-size sensitivity is stated rather than
    hidden. §7.3.

---

## 2. The gap

`gifter_community` is one sample: one genome set, one optional abundance vector
supplied at `community_traits()`. The analyses this package is built for are not
shaped like that. A user assembles one MAG catalogue, maps every sample against
it, and holds a genome × sample abundance table in which different genomes are
detected in different samples at different abundances. They then want to compare
groups of samples.

Today there is no container for that, and building one by binding N communities
is wrong twice over:

- it would evaluate the same genomes N times, at N times the cost, for calls
  that cannot differ;
- it would permit inconsistent call sets between samples. That is the failure
  the `database_version` check in `.gifter_community()` already guards against
  at the release level, and nothing currently guards against it at the sample
  level.

The second is the more serious. A provider count taken over genomes whose calls
came from different evaluations counts capabilities that were not offered to
every genome, and the number looks entirely normal.

## 3. The organising insight

A call is a property of a genome. `evaluate_gifts()` reads markers; it has never
seen a sample and cannot. Across a dataset exactly two things vary:

- **membership** — which genomes are part of a sample's community;
- **weight** — how much of that sample each genome represents.

Both are per genome. Neither can change a call, and neither may promote an
unsupported GIFT to supported. So the dataset is one call matrix, one detection
matrix and one weight matrix, and every per-sample metric is arithmetic over the
three.

Write:

```text
C   GIFT x genome    three-state calls, after assessability and confidence
S   genome x sample  detection, logical
W   genome x sample  abundance, closed within each sample's detected set
```

`C` is produced once, by the machinery that already exists —
`.assessable_matrix()` for the assessability policy, `.confidence_state()` for
the marker floor. `quality`, `policy`, `threshold` and `min_confidence` are
genome properties and are applied to the catalogue before any sample is read.

Then, per reference universe, restricting `C` to that universe's members:

| metric | expression | shape |
|---|---|---|
| `provider_count` | `(C %in% TRUE) %*% S` | GIFT × sample |
| assessor count | `(!is.na(C)) %*% S` | GIFT × sample |
| `provider_fraction` | providers / assessors | GIFT × sample |
| `abundance_coverage` | `(C %in% TRUE) %*% W` | GIFT × sample |
| `community_richness` | `colSums(providers > 0)` | sample |
| `mean_genome_richness` | `(gift_richness %*% S) / colSums(S)` | sample |
| `singleton_fraction` | `colSums(providers == 1) / colSums(providers > 0)` | sample |
| `unique_contribution` | `crossprod(C %in% TRUE, providers == 1) * S` | genome × sample |
| `assessable_fraction` | `colSums(assessors > 0) / nrow(C)` | sample |

Three products per universe cover every sample and every GIFT. The masking by
`S` in `unique_contribution` is not decoration: `crossprod` counts, for each
genome, the GIFTs it supports that have exactly one provider *in that sample*,
which includes genomes that are not in that sample and are therefore not the
provider. Masking removes exactly those.

Two consequences worth stating separately, because they are what stops this
layer being quadratic:

- **`repertoire_overlap` is sample-invariant.** The Jaccard index of two
  genomes' repertoires is a property of the two genomes. It is computed once at
  catalogue level; the only per-sample quantity is a summary over detected
  pairs. Re-emitting pair rows per sample would multiply the one metric the
  0.5.0 release had to rescue by the sample count.
- **Handoff edges are catalogue properties too.** `community_network()` builds
  them from `gift_graph` and the call matrix; only the per-sample metrics vary,
  by filtering the catalogue edge set to detected genomes.

## 4. Decisions taken

Each decision is recorded here so it cannot be reopened without amending this
document.

### 4.1 Name: `gifter_dataset`

Accepted. `gifter_study` and `gifter_survey` were considered and rejected:
both are design words. A study has hypotheses and a survey has a sampling
frame, and gifter has neither and refuses to acquire them (§8). `gifter_dataset`
names what the object holds, which is the register `gifter_community` already
sets — a container named after its contents, not after what a reader intends to
do with them.

### 4.2 Composition, not a parallel container

```r
gifter_dataset(catalogue, abundance, metadata = NULL)
```

`catalogue` is a `gifter_community`. Accepted, and the reasons are worth
enumerating because they are the argument against every alternative shape:

- the mixed-release refusal, the distinct-name requirement and the
  `gifter_genome` membership check are inherited rather than duplicated;
- `catalogue$results` is referenced, never copied, so a dataset costs the
  abundance matrix and nothing else;
- `sample_community()` can hand any existing function an ordinary
  `gifter_community`, so nothing in the package needs a dataset-aware variant
  to keep working on one sample.

### 4.3 Abundance input

Canonical form: a genome × sample numeric matrix with **both** dimnames.

Also accepted: a long data frame with `sample_id`, `genome_id` and `abundance`
columns, pivoted internally, because that is the shape coverM and its relatives
emit.

Refused: anything without both sets of identifiers, for the reason
`.normalize_abundance()` already gives — position is not a substitute for an
identifier, and a silent off-by-one credits one genome's abundance to another.
A matrix with only row names, a matrix with only column names, and a bare
numeric matrix are all errors.

**The long form must be rectangular.** Every sample must carry a row for every
genome. Treating an absent row as zero was considered and refused: a dropped row
and a true zero are indistinguishable after the pivot, and the pivot is exactly
where a failed join hides. A dropped row for an abundant genome silently removes
it from that sample's community, and nothing downstream can notice. The error
names the first missing combination and says that completing the table is one
call to `tidyr::complete()`. The consequence is that the long form and the
matrix form are strictly the same input, so no metric depends on which was
supplied.

Duplicate `(sample_id, genome_id)` pairs are refused rather than summed.

### 4.4 Genome coverage

`setequal(rownames(abundance), catalogue$genome_id)` is required. A catalogue
genome missing from the abundance matrix is an error, not a silent zero, and an
abundance row naming a genome the catalogue does not hold is an error too. Both
are almost always a failed join between a quality table and a mapping table, and
a silent zero converts that mistake into a genome that is simply never detected
anywhere — which is indistinguishable from a real biological result.

### 4.5 Detection

A `detection` argument, default `0`, meaning a genome is present in a sample
when its abundance is **strictly greater** than the threshold.

`detection` belongs to `dataset_traits()` and `dataset_network()`, not to the
constructor. This is the same decision, on the same grounds, that put `quality`,
`policy` and `threshold` on `community_traits()` rather than on
`gifter_community()`: a detection threshold says how far a reader is willing to
read a small abundance, which is not a property of the abundance. One dataset can
then be read at two thresholds without being rebuilt, and the parallel with
`threshold` is not an analogy — it is the invariant of §12 stated in the API.

Refusals:

- negative abundance, `NA` abundance, and non-finite abundance, at construction;
- a sample whose abundances are all zero, at construction, naming it: no
  threshold can ever detect a genome in it;
- a sample with no genome above `detection`, at read time, naming it. A
  community of no genomes has no richness, no denominator and no honest metric,
  and returning `NA` rows for it would put an empty result where a mistake is.

### 4.6 Closure

Abundance is closed within each sample's **detected** set, after detection is
applied. `abundance_coverage` is therefore a share of the community actually
being described.

This differs from closing over the full catalogue whenever `detection > 0`, and
the difference is deliberate: once a reader has declared that a genome below the
threshold is not part of the community, leaving its abundance in the denominator
would report a coverage of a community the same reader just said does not
include it. The docs must state this explicitly, because at `detection = 0` the
two closures coincide and the difference only appears when a threshold is
raised.

### 4.7 Metadata

A data frame with a `sample_id` column covering **exactly** the abundance
columns — no missing sample, no extra sample, no duplicate `sample_id`. Every
other column is carried through untouched and interpreted by nothing in gifter.
Group labels, timepoints, treatments and covariates are the user's, and §8 is
the reason they stay that way.

### 4.8 Where gifter stops

**gifter computes per-sample traits and emits them tidily joined to sample
metadata. gifter runs no hypothesis test, differential-abundance analysis,
ordination, or effect size between groups of samples.**

This is the decision that matters most, and the grounds are already in the
record rather than invented here:

- [§8 refusal 4](proposal-quantitative-traits.md#8-recorded-refusals) refuses
  generalist indices, resilience, cooperation, competition and ecological
  importance — every one of them a lighter ecological claim than "this
  capability differs between these two groups of samples";
- [§8 refusal 3](proposal-quantitative-traits.md#8-recorded-refusals) refuses a
  user-supplied weight vector multiplied through the call matrix and presented
  as a gifter inference. **A group label is exactly such a vector.** The design
  is the user's, the contrasts are the user's, and the multiple-testing
  correction is the user's; gifter would be lending its name to all three;
- vegan, lme4, MaAsLin and ALDEx2 already do the statistics, and do them
  better than a side-project implementation in a package whose subject is
  curated biology;
- a test statistic computed here would be the first number in gifter that could
  not be taken apart into a numerator, a denominator, an assessable count and a
  reference universe.

What those packages lack, and what gifter uniquely can give them, is an
**assessability-aware design matrix with a declared reference universe** — a
matrix in which a genome's silence about a capability it was never well enough
observed to assess is `NA` rather than `0`. That export is the deliverable
(§8, Phase 3), and it is what makes the boundary useful rather than merely
restrictive.

### 4.9 A separate `dataset_traits()`

Accepted, rather than an S3 method on `community_traits()`. The metric set
genuinely differs: two tables instead of one, a `sample_id` column, a
`detected_genomes` row, `detection` and no `pair_trace`. A method promising the
same contract and returning a different shape would be worse than a second
function with its own documentation. `community_traits()` remains the single-
sample reader and is unchanged.

### 4.10 Per-sample overlap summary

`mean_repertoire_overlap` is reported per sample. See §7.3 for the argument,
which is the closest call in this document.

---

## 5. The container

### 5.1 Shape

```r
dataset <- gifter_dataset(catalogue, abundance, metadata = NULL)
```

```text
gifter_dataset
  catalogue        the gifter_community, referenced
  genome_id        from the catalogue
  sample_id        the abundance columns, in their supplied order
  abundance        genome x sample numeric matrix, as supplied
  metadata         data frame or NULL
  database_version from the catalogue
```

Nothing is normalised at construction. The values are kept as they were given,
as `.normalize_abundance()` already does for one vector, because a reader may
want them back; closure happens at read time, after detection, where it belongs.

### 5.2 Accessors

```r
sample_id(dataset)
sample_community(dataset, sample)
```

`sample_community()` returns an ordinary `gifter_community` holding that
sample's detected genomes, so `community_traits()`, `community_network()`,
`trace_gift()` and everything else keep working unchanged on one sample. It
takes `detection` on the same terms as `dataset_traits()`.

**One refinement to the round-trip.** `sample_community()` preserves the
catalogue's `gift_id` set rather than recomputing the union over the subset.
`.gifter_community()` derives its universe as the union of the GIFTs its genomes
were evaluated over, which for a homogeneous catalogue — every genome evaluated
in one `evaluate_gifts_community()` call — is identical either way. It differs
only when genomes were evaluated over different GIFT subsets, and there the
recomputed union would make each sample's `assessable` denominator a different
set of GIFTs. That is the sample-level form of exactly the failure the release
check exists to prevent. The dataset's reference universe is the catalogue's,
and it does not shrink because a sample is small.

The Phase 1 test therefore asserts identity with the naively subset community
for the homogeneous case, and asserts the preserved universe for the
heterogeneous one.

### 5.3 Printing

```text
<gifter_dataset> 418 genomes x 96 samples
  detected per sample: 31-207 (median 118)   [at detection = 0]
  metadata: 4 columns
  database version: 2026.21.3
```

### 5.4 What a dataset does not hold

A dataset holds membership evidence and weights. It does not hold a detection
threshold, an assessability policy, a completeness table, a confidence floor, a
group label, a design or a hypothesis. The first four are readings and belong to
`dataset_traits()`; the last three are the user's and belong to §4.8.

---

## 6. Per-sample distributional traits

```r
dataset_traits(dataset, universes = NULL, quality = NULL, policy = "none",
               threshold = NULL, min_confidence = NULL, detection = 0,
               pairwise = TRUE, db = NULL, progress = NULL)
```

### 6.1 Order of operations

1. `quality`, `policy`, `threshold`, `min_confidence` resolved against the
   catalogue's genomes — **once**, before any sample is read. They are genome
   properties. `.assessable_matrix()` and `.confidence_state()` are called
   exactly as `community_traits()` calls them, on exactly the same matrix.
2. `detection` applied to the abundance matrix, producing `S`.
3. Abundance closed within each sample's detected set, producing `W`.
4. Per universe: the three products of §3, and the rows they yield.

### 6.2 Metrics reported per sample per universe

| metric | `target_type` | denominator |
|---|---|---|
| `community_richness` | community | — (count) |
| `community_coverage` | community | assessable members, bounded universes only |
| `mean_genome_richness` | community | detected genomes |
| `assessable_fraction` | community | universe members |
| `detected_genomes` | community | catalogue genomes |
| `singleton_fraction` | community | represented GIFTs in that sample |
| `provider_count` | gift | genomes in that sample that could assess it |
| `provider_fraction` | gift | genomes in that sample that could assess it |
| `abundance_coverage` | gift | detected genomes in that sample |
| `unique_contribution` | genome | GIFTs that genome supports |
| `mean_repertoire_overlap` | community | comparable detected pairs |

`target_type` keeps its existing vocabulary — `community`, `gift`, `genome` —
with the sample named by its own `sample_id` column rather than folded into
`target_id`. `genome_pair` does not appear in this table at all; it lives in
`catalogue_metrics`.

`abundance_coverage` is emitted only when the closure produced a usable weight
for that sample, which after §4.5's refusals is always.

### 6.3 `detected_genomes`, and why it is beside every richness row

A genome absent from a sample may be below detection rather than genuinely
absent, and gifter models no sequencing depth, no library size and no
rarefaction. A community richness of 40 in a sample where 31 genomes were
detected and one of 40 in a sample where 207 were is not the same result, and
nothing in the richness row says which one it is.

`detected_genomes` is therefore emitted once per sample per universe, alongside
the rows it must be read with. Detection does not vary by universe, so the row
is redundant across universes — deliberately, on the same argument that puts
`assessable_fraction` in every universe: a metrics table filtered to one
universe must still carry the denominator its richness has to be read against.

**No imputation or depth correction is added.** See §10.

### 6.4 Cost

Per universe, the work is three matrix products of size |M| × G × S plus row and
column reductions, where |M| is the universe's membership. For 418 genomes, 96
samples and the whole 149-GIFT catalogue that is under 6 million multiply-adds —
milliseconds. The output row count, not the arithmetic, is the size of the
result: represented GIFTs × samples dominates, at roughly |M| × S rows per
universe.

Reference universes stay the progress unit, through `.universe_progress()` in
`R/progress.R` unchanged, because the sample loop is vectorized away and there
is no sample-shaped work to count.

### 6.5 The trace

The trace stays at catalogue level. A sample's providers are the catalogue's
providers intersected with its detected genomes, so per-sample trace rows are
**derivable rather than stored**, and storing them would multiply the trace by
the sample count for no information.

```r
trace_sample(traits, sample)
```

derives them on demand. This is the same reasoning, and should carry the same
documentation, as the `pair_trace = FALSE` default of `community_traits()`: the
values are identical either way, and what is at stake is only whether gigabytes
of derivable rows are carried around by default.

---

## 7. Catalogue-level, sample-invariant traits

### 7.1 What belongs here

`catalogue_metrics` holds every row that cannot vary between samples:

| metric | `target_type` |
|---|---|
| `gift_richness` | genome |
| `repertoire_overlap` | genome_pair |

Both are properties of genomes. A genome supports the same GIFTs in every sample
it is detected in, and two genomes share the same repertoire wherever both are
detected. Emitting them per sample would report the same number S times and, for
the pair metric, would reintroduce a quadratic cost per sample on top of the
quadratic cost per universe — the exact shape the 0.5.0 release had to remove.

`catalogue_metrics` uses `.metric_columns` unchanged, with no `sample_id`
column. That absence is the claim: a row without a sample is a row no sample can
change.

### 7.2 Reading a catalogue row for one sample

Everything sample-specific about these metrics is a restriction of the row set:

- `gift_richness` for a sample is the catalogue rows for its detected genomes;
- `repertoire_overlap` for a sample is the catalogue rows for pairs both of
  whose genomes it detected.

`trace_sample()` and the tidy accessor of §8 both perform that restriction, so a
user never has to.

### 7.3 The one composite: `mean_repertoire_overlap`

This is the closest call in the proposal, so the argument is given in full.

**Against.** [Invariant 23](../../AGENTS.md) prefers interpretable components to
composite indices. A mean of Jaccard indices is a mean of ratios; it hides the
distribution it summarises; and it is sample-size sensitive in a way that is not
obvious — a sample detecting more genomes averages over a different and larger
pair set, so two samples' means are not comparisons of the same thing. There is
also a schema obstacle: `.metric_row()` coerces `numerator` with `as.integer()`,
and a sum of Jaccard indices is not a count.

**For.** Functional redundancy between groups of samples is precisely the
question this layer exists to make answerable, and refusing the summary would
push every user to compute the same mean themselves, less carefully, from the
matrix gifter exported. `singleton_fraction` is already a composite of the same
family and is already reported. And the decisive point: **the ingredients remain
exactly recoverable.** The catalogue overlap rows plus the sample's detected
genome set reproduce every term of the mean, which is a stronger traceability
guarantee than a trace table gives.

**Decision.** Report it, per sample per universe, with:

- `value` — the mean;
- `numerator` — `NA_integer_`, because the sum of a set of ratios is not a
  count and the schema's numerator is one. `denominator` already carries
  `NA_integer_` for `community_richness` and `gift_richness`, so `NA` in these
  slots has precedent meaning "there is no count here";
- `denominator` — comparable detected pairs, where a pair is comparable when the
  union of the two repertoires within the universe is non-empty, on exactly the
  terms `community_traits()` already uses to withhold an undefined overlap;
- `derivation_method` — states the sample-size sensitivity and points at
  `catalogue_metrics` for the terms.

It is gated by `pairwise`, the existing argument, default `TRUE`. Setting
`pairwise = FALSE` drops both `catalogue_metrics`' pair rows and this summary,
and changes nothing else — the same lever, with the same meaning, as in
`community_traits()`.

---

## 8. The export surface

Small, and the reason the layer is worth building.

### 8.1 `gift_matrix()`

```r
gift_matrix(x, universe = NULL, quality = NULL, policy = "none",
            threshold = NULL, min_confidence = NULL, db = NULL)
```

Genomes × GIFTs, three-state: `TRUE` supported, `FALSE` confidently
unsupported, `NA` indeterminate. Works on a `gifter_community` and on a
`gifter_dataset` (which delegates to its catalogue).

`.assessable_matrix()` already computes exactly this and is currently internal.
**Exporting it is the single highest-value line in this plan**: it is the object
every downstream statistics package wants, and the `NA` state is the thing
gifter can give it that nothing else can. A `0` where a fragmented genome was
never observed well enough to assess a capability is a fabricated absence, and
every model fitted on it inherits the fabrication.

Orientation is genomes × GIFTs — the transpose of the internal
`community$matrix` — because rows are observations in every package that will
receive it. The docs must say so, since the internal orientation is the other
way.

`universe = NULL` means the whole catalogue, and the returned matrix carries
`reference_universe` and `database_version` attributes so an exported matrix
does not lose the two facts that make its column set meaningful.

### 8.2 `dataset_matrix()`

```r
dataset_matrix(traits, metric_id, universe = NULL)
```

Samples × target, ready for `vegan::vegdist()` and friends. The `universe`
argument is required in effect: a metric identifier appears once per universe,
and reshaping across universes would silently stack incomparable columns, so
omitting it is an error whenever the metric appears in more than one.

### 8.3 The tidy accessor

`as.data.frame()` on a `gifter_dataset_traits`, joining `metrics` to `metadata`
by `sample_id`. A left join from metrics, so a metric row is never dropped and
never duplicated — which is exactly what §4.7's exact-coverage requirement makes
provable rather than hoped for.

The vignette must end by handing one of these to an external statistics package,
so that the boundary of §4.8 is visible in a worked example rather than merely
asserted in prose.

---

## 9. Topology per sample

```r
dataset_network(dataset, interaction = "metabolic_handoff", universe = NULL,
                quality = NULL, detection = 0, limit = 100L, db = NULL)
```

The catalogue edge set is built once with the existing `community_network()`
machinery — `gift_graph`, `.transferable_anchors()`, `.handoff_edges()` — and
then filtered to each sample's detected genomes. Per sample:

- `nodes` — `provider_degree`, `recipient_degree`, `handoff_richness`, over
  that sample's edges;
- `edges` — the catalogue edges both of whose genomes it detected;
- `chain_coverage` — recomputed, because `within_genome` requires a *detected*
  genome to hold both ends;
- `cycle_coverage` — recomputed for the same reason: a sample lacking the
  genome that closes a cycle does not close it. The per-genome closure vector is
  computed once at catalogue level and masked by detection;
- `metrics` — `interaction_density`, `handoff_edges`, `distributed_chain_links`,
  with `interaction_density`'s denominator being the ordered pairs of *detected*
  genomes, d(d−1).

**[Invariant 22](../../AGENTS.md) is untouched.** No new compatibility semantics
are introduced, the extracellular gate stays exactly where it is, and
`edge_quality` is inherited unchanged. Detection removes genomes from a sample;
it never creates an edge, never relaxes the compartment rule, and never changes
what an edge means.

Distributed cycle closure will continue to report `not_closed` in every sample,
for the reason recorded in
[§13.1](proposal-quantitative-traits.md#131-departure-a-cross-genome-edge-requires-an-extracellular-anchor).
That is the honest answer and it does not become less honest per sample.

---

## 10. Recorded refusals

Not implemented, with reasons, so they are not silently reopened. These extend
[§8 of the quantitative traits proposal](proposal-quantitative-traits.md#8-recorded-refusals),
every item of which continues to stand.

1. **No group testing of any kind.** No t-test, no Wilcoxon, no PERMANOVA, no
   differential abundance, no mixed model, no ordination, no effect size, no
   multiple-testing correction, no group contrast. A group label is a
   user-supplied vector multiplied through the call matrix, which §8 refusal 3
   of the prior proposal already refuses; the design, the contrasts and the
   correction are the analyst's and gifter would be lending its name to all
   three. The deliverable is the assessability-aware matrix (§8). §4.8.
2. **No depth correction, rarefaction, or detection imputation.** gifter models
   no sequencing depth, no library size and no detection limit, and it has no
   validated model of how a genome falls below detection. A correction would be
   an assumption presented as a gifter inference. Absence below detection is
   reported honestly through `detected_genomes` (§6.3) and nothing else.
3. **No claim that a GIFT is more active, more expressed, more important or
   more available in a group of samples because its carriers are more abundant
   there.** `abundance_coverage` is a share of observed genome abundance, and
   this is invariant 21 and
   [§13.4](proposal-quantitative-traits.md#134-two-metrics-added-that-the-plan-did-not-list)
   applied one axis further out. Presence in a genome, presence in a sample and
   abundance in a sample are three axes, and a difference between groups on the
   third says nothing about the first.
4. **No per-sample re-evaluation of calls.** A call is a property of a genome.
   Anything that would make a genome's call depend on the sample it was observed
   in — a sample-specific marker filter, a per-sample confidence floor, a
   coverage-weighted call — is refused. §3.
5. **No per-sample re-emission of sample-invariant metrics.** `gift_richness`
   and `repertoire_overlap` live in `catalogue_metrics` and are restricted, not
   recomputed. A user who wants them per sample gets them by restriction (§7.2),
   which is the same numbers without the multiplication.

---

## 11. Result shape

`dataset_traits()` returns a `gifter_dataset_traits` object with **two** metric
tables rather than one table with a nullable `sample_id`. A nullable column
would mean "this row happens not to have a sample"; two tables mean "this row
cannot have one", which is the actual claim.

```text
metrics:
  sample_id                       prefixed to .metric_columns
  target_type                     community | gift | genome
  target_id
  metric_id
  value, unit, numerator, denominator, assessable
  reference_universe, database_version, derivation_method

catalogue_metrics:
  .metric_columns unchanged       target_type: genome | genome_pair

trace:
  .trace_columns unchanged        catalogue level; trace_sample() restricts it

metadata, sample_id, genome_id, detection, assessability, universes,
database_version
```

The questions the shape must answer without re-running anything:

> Why does sample S have `community_richness = 40`?

`trace_sample(traits, "S")` names the 40 GIFTs and the detected genomes behind
them; `detected_genomes` says 118 of 418 genomes were detected;
`assessable_fraction` says how much of the universe could be assessed at all;
`reference_universe` says which universe the 40 was counted over.

> Why is sample S's `mean_repertoire_overlap` higher than sample T's?

`catalogue_metrics` holds every pair term, and the two detection sets say which
terms each mean was taken over — including whether the two means were taken over
comparable numbers of pairs at all.

---

## 12. Invariants this layer must preserve

The prior layer's eight invariants
([§12](proposal-quantitative-traits.md#12-invariants-this-layer-must-preserve))
carry over unchanged. This layer adds one, which is proposed as **AGENTS.md rule
24** subject to the reviewer agreeing it belongs there:

> **Detection is to samples what assessability is to genomes.** Both may only
> move denominators. Assessability decides whether a genome's silence about a
> GIFT is informative; detection decides whether a genome is part of a sample's
> community at all. Neither may promote an unsupported GIFT to supported,
> neither may change a call, and both are resolved per genome.

It extends rule 21 — presence-in-a-genome, presence-in-a-sample and
abundance-in-a-sample are three axes and never one number — and it is directly
testable rather than aspirational:

- raising `detection` never turns a `FALSE` or `NA` call into `TRUE`, in any
  sample, in any universe;
- raising `detection` changes only denominators and the row sets derived from
  them, never a call;
- a sample's call matrix is `identical()` to the catalogue's, restricted to its
  detected genomes;
- for every sample, everything `dataset_traits()` reports agrees with
  `community_traits()` on `sample_community(dataset, s)` given that sample's
  abundance vector.

A second caveat is stated rather than corrected, parallel to genome
completeness: **absence from a sample may be below detection rather than
genuinely absent, and gifter models no sequencing depth.** `detected_genomes`
reports it; nothing imputes it.

---

## 13. Implementation plan

Phases are independently shippable. No database rebuild is required at any
phase: this layer reads the database and changes nothing in it, so
`database_release.tsv`, `database_changes.tsv` and the SQLite artifact are
untouched. No GIFT identifier appears in R source; universes continue to come
from curated metadata only.

### Phase 0 — this document

Decisions locked. No code.

### Phase 1 — the container

`R/dataset.R`, new: `gifter_dataset()`, `print.gifter_dataset()`,
`sample_id()`, `sample_community()`.

`tests/testthat/test-dataset.R`, new: mismatched genomes refused; unnamed
abundance refused; negative and `NA` abundance refused; an all-zero sample
refused at construction and an undetected sample refused at read time; metadata
not covering the samples refused; duplicate `sample_id` refused; a non-
rectangular long frame refused; long and matrix forms producing identical
datasets; `sample_community()` round-trip identical to the subset community.

### Phase 2 — per-sample distributional traits

`R/dataset-traits.R`, new: `dataset_traits()`, `trace_sample()`,
`print.gifter_dataset_traits()`. `.metric_row()`, `.trace_rows()`,
`.metric_columns`, `.trace_columns` and `.universe_progress()` are reused
unchanged.

One small extraction is expected and is permitted by the constraint that the
existing functions' returns must not change: `.warn_thin_denominators()`'s
message counts "universes", and in a dataset the thin rows are sample-universe
readings. It gains an optional argument naming the unit, defaulting to the
current text, so `community_traits()`'s warning is byte-identical.

`tests/testthat/test-dataset-traits.R`, new. The decisive test is
self-verifying against the existing engine: **for every sample, every metric
`dataset_traits()` reports equals what `community_traits()` reports on
`sample_community(dataset, s)` with that sample's abundance vector** — matched
either against a `metrics` row for that sample or, for `gift_richness` and
`repertoire_overlap`, against `catalogue_metrics` restricted to that sample's
detected genomes and pairs. Also: detection never changes a call; raising
`detection` moves denominators only; a bounded universe still emits
`community_coverage` and an unbounded one still refuses it; abundance closure is
per sample and over the detected set.

### Phase 3 — the export surface

`gift_matrix()`, `dataset_matrix()`, `as.data.frame()`.

`tests/testthat/test-dataset-export.R`, new: three states survive the export
(and in particular that `NA` is not silently `FALSE`); the universe restriction
is honoured and its attributes are carried; the metadata join neither drops nor
duplicates samples.

### Phase 4 — topology per sample

`dataset_network()` in `R/dataset-network.R`.

`tests/testthat/test-dataset-network.R`, new: per-sample density equals
`community_network()` on that sample's community; a genome undetected in a
sample contributes no edge there; `edge_quality` is inherited unchanged; a
cytoplasmic anchor still crosses no genome boundary.

### Phase 5 — documentation

- `inst/doc/architecture.md`: a new subsection under **Quantitative traits**
  covering the container, the detection invariant, the vectorized derivation and
  where gifter stops; added to the quick topic index.
- `vignettes/multi-sample-datasets.Rmd`, new, registered in `_pkgdown.yml`
  under Tutorials, **ending by handing the exported matrix to an external
  statistics package**.
- Roxygen on every new export, in the register of the existing docs: what the
  number is, what it is not, and what its denominator is.
- `CHANGELOG.md` entry with a UTC timestamp.
- §14 below filled in, including every departure from this plan and why.

### Checks

`Rscript -e 'testthat::test_local(".")'` after each phase;
`R CMD build . && R CMD check --no-manual gifter_*.tar.gz` before handing off.

---

## 14. Implementation record

Phases 1 to 5 shipped in package 0.6.0. No schema, database content or
evaluation change was required: the compiled artifact is untouched and no
Boolean call moved. The suite went from 4,316 to 4,498 assertions, and
`R CMD check --no-manual` is clean.

| Phase | Files | Exports |
|---|---|---|
| 1 | `R/dataset.R` | `gifter_dataset()`, `sample_id()`, `sample_community()` |
| 2 | `R/dataset-traits.R` | `dataset_traits()`, `trace_sample()` |
| 3 | `R/dataset-export.R` | `gift_matrix()`, `dataset_matrix()`, `as.data.frame()` |
| 4 | `R/dataset-network.R` | `dataset_network()` |
| 5 | architecture guide, `vignettes/multi-sample-datasets.Rmd`, `CHANGELOG.md` | — |

### 14.1 The decisive test held, unchanged, over every default universe

§13's Phase 2 test is the one that mattered, and it passed as specified without
any of the metrics being adjusted to make it pass. For every sample, every
metric row `dataset_traits()` reports equals what `community_traits()` reports
on `sample_community(dataset, s)` with that sample's abundance — matched on
`value`, `numerator`, `denominator` and `assessable`, over all fourteen default
reference universes. `trace_sample()` matches `community_traits()`'s trace the
same way, and Phase 4's per-sample topology matches `community_network()`'s
`nodes`, `edges`, `chain_coverage`, `cycle_coverage` and metric numbers.

This is what the vectorized derivation had to earn. Three matrix products per
universe now stand in for a per-sample walk, and the walk is still the
definition.

### 14.2 Departure: `assessable` on a catalogue row is the catalogue's

§7.1 said `gift_richness` and `repertoire_overlap` are sample-invariant, and
their *values* are. The `assessable` column beside them is not: it counts what
the universe's members could be assessed by, and a sample's genomes are a subset
of the catalogue's. A `catalogue_metrics` row belongs to no sample, so it
carries the catalogue's count.

The equality of §12 is therefore stated on `value`, `numerator` and
`denominator` for those two metrics — the quantities the metric *is* — and the
test says so explicitly rather than quietly dropping a column. The alternative,
moving both metrics back into the per-sample table so the column could be
per-sample, was rejected: it would have re-emitted the same numbers once per
sample and made the pair metric quadratic per sample, which is exactly what §7.1
exists to prevent.

### 14.3 Departure: `gift_matrix()` has no `db` argument

§8.1 listed one. Nothing in the function reads the database: a universe carries
its own release string and a community carries its own release row, so the
version check is local. An argument that is accepted and never used is worse
documentation than one that is absent.

### 14.4 Departure: `dataset_matrix()` gained a `fill` argument

Not in §8.2. A metric is reported only where it exists — `provider_count` has no
row for a GIFT no genome in a sample supports — and whether an absent cell is a
true zero or a GIFT nothing there could assess is exactly the distinction the
assessability layer exists to keep. The default is `NA` and gifter does not
guess. `fill = 0` is available and is then the caller's claim, made under the
caller's name, which is the same reasoning §4.8 uses for a group label.

### 14.5 Refinement: `dataset_network()` also recounts cycle closure per sample

§9 named `interaction_density`, `handoff_edges` and `distributed_chain_links` as
the per-sample quantities and left `cycle_coverage` unmentioned. It varies too:
a cycle is closed within a genome only if a *detected* genome closes it, so a
sample lacking that genome does not close it. It is recounted per sample, from a
cycle enumeration performed once. `community_distributed` closure remains
`not_closed` in every sample for the reason recorded in
[§13.1](proposal-quantitative-traits.md#131-departure-a-cross-genome-edge-requires-an-extracellular-anchor),
and that answer does not become less honest per sample.

### 14.6 Two extractions from existing code, neither changing a return

Both were anticipated by §13's Phase 2 note and by the constraint that existing
behaviour must not move.

`.warn_thin_denominators()` gained an optional argument naming what the thin
readings are counted in, defaulting to the current text. A dataset reports one
`assessable_fraction` per sample per universe, and calling those universes would
undercount them by the sample count. A test asserts the single-community wording
is byte-identical.

`.distributed_cycles()` now takes the enumerated cycles rather than enumerating
them, so `dataset_network()` enumerates once for every sample rather than once
per sample. `community_network()` passes `gift_cycles()` at the one call site
and returns exactly what it returned before.

### 14.7 One refinement the plan did not anticipate

`sample_community()` preserves the catalogue's `gift_id` set rather than
recomputing the union over the detected genomes (§5.2). The two are identical
for a catalogue whose genomes were evaluated together, which is the ordinary
case; they differ only when genomes were evaluated over different GIFT subsets,
and there the recomputed union would give every sample a different `assessable`
denominator. That is the sample-level form of the failure the mixed-release
refusal exists to prevent, and it is what makes the §14.1 equality exact rather
than approximately true. Both cases are tested.

### 14.8 What was implemented as planned

The container and every refusal of §4.3 to §4.7, including the rectangular
long-form requirement and its `tidyr::complete()` hint; `detection` on the
readers rather than the container; closure within the detected set; the
vectorized derivation of §3 exactly as tabulated; `detected_genomes` beside
every sample-level richness in every universe; two metric tables; the catalogue
trace as the primitive with `trace_sample()` deriving from it; reference
universes as the progress unit; `mean_repertoire_overlap` reported with an `NA`
numerator and the comparable detected pair count as its denominator, gated by
`pairwise`; and the three-function export surface ending, in the vignette, at a
`vegan` call that gifter does not make.

Every refusal in §10 stands. No GIFT identifier was written in R source, no
database or schema change was made, and `community_traits()`, `genome_traits()`
and `community_network()` return exactly what they returned in 0.5.0.

### 14.9 Not yet done

Nothing from this proposal is outstanding. The natural next questions, none of
which this document decides:

- whether `dataset_network()`'s per-sample `edges` table should be replaced by a
  catalogue edge set plus a restriction accessor, once a dataset large enough
  for the row count to hurt has been measured. The metrics are vectorized; the
  edges are not, and cannot be;
- whether `mean_repertoire_overlap`'s sample-size sensitivity is better handled
  by reporting it over a fixed pair set rather than by documenting it;
- whether the `assessable_fraction` warning should fire per sample rather than
  once over the whole reading, which is a question about how loud a warning
  should be and not about what it means.
