# Genomic context as optional evidence: contig identity and gene distance

Status: **assessment only. Nothing is implemented, and one prior refusal must be
explicitly revisited before anything can be.**

The question put to this assessment: can gifter use the genomic context of the
genes behind a call — whether two markers sit on the same contig, and how far
apart they are — as optional evidence that refines a prediction without ever
being required?

The short answer is yes, but only in one of the four places it could plausibly
go, and only on an axis of its own. Folding gene neighbourhood into
`evidence_confidence` or into the Boolean call would break invariants 15, 16
and 21, and would silently penalise exactly the taxa whose biology gifter is
weakest at already. What follows is the argument, the recommended shape, and
the parts that should stay refused.

---

## 1. The prior refusal, and what it actually forbids

`inst/doc/proposal-polysaccharide-degradation.md` §12, decision 1c:

> **No genomic-context evidence.** Ruled out because gifter operates on chunked
> MAGs, where contig fragmentation makes gene neighbourhood unreliable. Nothing
> in the evaluation may depend on co-localisation, operon structure or PUL
> membership.

That decision was taken for a specific purpose: to stop SusC/SusD substrate
specificity being assigned from PUL context (§4.6). It is the correct answer to
that question and it should not be reopened — see §5.4 below.

But read precisely, 1c forbids the *evaluation* from **depending** on genomic
context. It does not settle whether context may be reported alongside a call
that was reached without it. That is a different proposal, with a different risk
profile, and it deserves its own decision rather than inheriting this one. It
also deserves an honest acknowledgement that the two are adjacent: everything
below exists to keep them from touching.

## 2. The two levels are two different signals

They are asked for together and behave nothing alike.

| | Same contig | Distance between genes |
|---|---|---|
| Measures | assembly contiguity, plus real adjacency | operonic linkage |
| Informative when present | weakly | yes |
| Informative when absent | **no** | **no** |
| Confounded by | fragmentation, binning, co-assembly chunking | genome architecture, taxon |
| Needs | `contig_id` | `contig_id`, coordinates, `strand` |

Both signals share the property that makes them usable and also makes them
dangerous: **they are one-directional**. Two markers on one contig 300 bp apart
on the same strand are positive evidence they belong to one system. Two markers
on different contigs are evidence of *nothing* — the contigs may be adjacent in
the real chromosome, and in a 200-contig MAG they very often are.

Worse, the confound is anticorrelated with the signal. A poor assembly both
splits contigs *and* loses genes, so any rule that reads dispersion as weak
evidence would downgrade precisely the genomes that are already hardest to call,
compounding a bias rather than correcting one.

The distance signal carries a second, sharper hazard. Operonic organisation is
taxon-structured. Bacteroidetes cluster glycan machinery into PULs; the
equivalent Firmicutes machinery is frequently scattered. A rule that rewards
co-localisation *and* penalises dispersion would systematically prefer
Bacteroidetes calls over Firmicutes ones for the same underlying capability —
the mirror image of the marker bias already documented in
`proposal-polysaccharide-degradation.md` §4.6, and just as unacceptable.

**Consequence for any design: co-localisation may corroborate, dispersion may
never refute.** Every rule below obeys this.

## 3. What gifter does with these inputs today

Nothing, silently. `.prepare_observed_markers()` ([R/evaluation.R:47](../../R/evaluation.R#L47))
keeps `gene_id`, `namespace` and `accession` and drops every other column
without comment. A user who already has `contig_id` and coordinates in their
annotation table can pass them today and receive a result that ignores them and
never says so.

There is also a live hazard in the interaction with the `gene_id` resolution
added for pooled inputs. `.gene_id_candidate()` ([R/evaluation.R:863](../../R/evaluation.R#L863))
proposes *the first column that is not a marker column*. A table written as
`contig_id, start, end, locus_tag, namespace, accession` — the natural column
order for anyone exporting from a GFF — would today be asked to approve
`gene_id = "contig_id"`. The question is asked rather than assumed, which is why
this is a hazard and not a bug, but any work in this area should fix the
candidate rule to skip recognised context columns.

## 4. Where context could act, assessed

Four insertion points. One is worth having.

### 4.1 The AND layer: jointly required components of one system — **recommended**

This is the real case, and it addresses a genuine, currently unaddressed
weakness in the evaluation model.

A system is complete when all its required components are supported
(AGENTS.md, the evaluation contract). Support is per-component and
set-based: `SYS_24628_NASDE` is complete when *some* gene matches NasD and
*some* gene matches NasE. Nothing checks that those two genes belong to the same
nitrite reductase. In a genome carrying three unrelated ABC transporters, an SBP
from one, a permease from another and an ATPase from a third complete a
transporter that does not exist.

gifter has no evidence layer for this today, and marker evidence cannot supply
one — the markers are correct, it is their *assignment to one complex* that is
unevidenced. Genomic context is the only available evidence, and it is
well-matched to the claim: subunits of one complex are co-transcribed far more
often than paralogues of different complexes are adjacent.

This is also where the one-directional rule is easiest to honour. A multisubunit
system whose components are co-localised has independent corroboration that the
AND layer resolved to one machine. A system whose components are dispersed has
the support it always had, reported as `dispersed` rather than as anything
worse.

### 4.2 The route layer — **refuse**

A metabolic route is not an operon. Route reactions are curated as a chemical
path between anchors; nothing in the biology says the enzymes are linked, and
central metabolic routes are typically scattered. Reading route-level
co-localisation as evidence would be a claim about genome architecture that the
route model never made. Refuse.

### 4.3 The architecture, circuit and mechanism layers — **refuse for now**

Superficially attractive: the *mer* operon, the *cas* operon and the flagellar
regulons really are clustered. But `mercury_detoxification` is already curated
so that a lone *merA* is a positive call, deliberately, because "requiring
*merT* and *merP* would refuse such a genome on the strength of an operon
architecture that varies" (`gifts.tsv`, and `database_changes.tsv`
DBC-20260819-MERCURY-DEFENSE). Introducing operon structure one layer up would
re-import through the back door the assumption that curation just rejected on
the front. If the mechanism layer ever gets context evidence, it should be after
§4.1 has been in use long enough to show what it does to real MAG collections.

### 4.4 Marker specificity from context — **refuse, permanently**

Assigning a SusC/SusD pair a substrate because it sits beside a GH family, or
promoting a polyspecific CAZy family because its neighbourhood "looks like" a
pectin PUL, violates invariant 16 directly. The specificity of the claim would
exceed the specificity of the evidence, and the excess would come from a
neighbourhood that is an inference, not an observation. Decision 1c stands
unchanged for this case, and any implementation of §4.1 must be shaped so that
it cannot be extended here by accident — which is the main reason the design
below refuses to let context touch marker acceptance at all.

## 5. The axis question, and why it decides the design

The tempting implementation is to let co-localisation raise
`evidence_confidence`. It should not, for a reason that is structural rather
than cautious.

`confidence` is a **curated property of a marker-to-component assignment**,
stored in `component_marker.confidence`, identical for every genome, and
ordered as a statement about how well an accession identifies a component
([R/evaluation.R:225-261](../../R/evaluation.R#L225-L261)). Genomic context is a
**per-genome observation about one assembly**. Folding the second into the first
would make the same curated term mean two different things, would make a
database-versioned quantity vary by input file, and would put an assembly
artifact on the same ordinal scale as curated orthology. `curated` would no
longer mean what it means.

Invariant 21 already fixes the correct shape for this class of problem:
presence, abundance and context are three axes and never one number. Genomic
context is a fourth such axis — distinct from the environmental context
invariant 21 names, and governed by the same rule.

**Recommendation: report genomic context as its own axis, beside the call, never
inside it.**

## 6. Recommended design

### 6.1 Input contract

Three optional columns on the annotation table, recognised when present and
ignored when absent, with no behaviour change for anyone who omits them:

| Column | Required for | Notes |
|---|---|---|
| `contig_id` | level 1 | scoped per genome in the community path |
| `start`, `end` | level 2 | integer coordinates on the contig |
| `strand` | level 2 | needed for operonic linkage; `+`/`-` |

The two levels nest: coordinates without `contig_id` are meaningless and should
be refused with a message saying so, not silently half-used. Level 1 alone is
accepted.

Assemblers routinely emit `contig_1` in every bin, so contig identifiers are
only meaningful within one genome. `evaluate_gifts_community()` already splits
the table per genome before evaluating, which isolates them for free; the
requirement is that nothing later undoes that isolation, and that a test pins it
(§10.3). Cross-genome co-localisation would be the worst failure mode this
feature could have.

Partial provision — context for some genes and not others — must be treated as
missing for any system that touches an uncovered gene, never as dispersion.

### 6.2 What is reported

Per call, on the `gifts` tibble, a small closed vocabulary:

```text
context_support ∈ {
  colocalised     # the supporting components of the best implementation
                  # are on one contig within the declared window
  partial         # some are, some are not
  dispersed       # supported, on more than one contig or beyond the window
  split_assembly  # supporting genes sit at contig ends: context is unreadable
  not_assessed    # no context supplied, or single-component systems only
}
```

with `not_assessed` the default so that a user who supplies nothing sees the
axis exist and read as unused, exactly as `assessable` does for the quality
layer ([R/assessability.R:15-18](../../R/assessability.R#L15-L18)).

`trace_gift()` gains `contig_id`, `start`, `end` and `strand` on its evidence
rows, which is where this becomes genuinely useful: a curator can see that the
three components of a supposedly complete transporter came from three different
contigs.

### 6.3 The window

There is no defensible default distance, for the same reason
`assessability()` refuses a default completeness threshold: how close two genes
must be before adjacency means anything is the analyst's declared choice, and
the honest values differ by taxon and by assembly. Follow the existing
precedent — require an explicit window when the level-2 policy is requested,
and state it in the output. Intergenic distance rather than gene count, since
gene count is not comparable across annotations of different density.

A later, better version curates the expectation per system rather than globally
(`enzyme_system.expected_linkage`, and the machinery equivalents), because
operonic organisation is a property of the machine and the lineage, not of the
analysis. That is a schema change and a substantial curation effort, and it
should not be attempted until §4.1 has shown its worth. Note it as deferred.

### 6.4 Absence, and the contig-quality level

The second, weaker use of contig information is on the reading of absence, where
`assessability()` already lives. A `fragmentation` policy alongside
`completeness` is coherent and follows invariant 21 without argument, but it is
mostly redundant: contig count correlates strongly with CheckM completeness, and
the blunt version of the policy would add a second axis carrying nearly the same
information.

The sharp version is worth having, and is the one place contig data beats a
completeness statistic outright: **a missing requirement whose supported
neighbours in the same route or system sit within a few genes of a contig end
is indeterminate rather than negative.** That is a locus-specific statement
about *this* absence, which no genome-level completeness value can make. It
still declares nothing about which capability was lost, so it stays inside the
constraint stated at [R/assessability.R:112-116](../../R/assessability.R#L112-L116).

Both remain opt-in policies, and neither may promote an unsupported GIFT to
supported.

## 7. Hard rules any implementation must satisfy

1. Genomic context never changes `complete`, `best_route`,
   `best_implementation`, or any missing-requirement output.
2. Co-localisation may corroborate; dispersion may never refute, downgrade, or
   reduce support.
3. Context never enters `evidence_confidence`, and never enters marker
   acceptance.
4. Context never licenses a specificity claim (invariant 16). §4.4 stays
   refused.
5. Absent context is `not_assessed`, never `dispersed`.
6. Contig identifiers are scoped per genome before any community use.
7. Every context claim is traceable to the genes and coordinates that produced
   it, per invariant 11.
8. Deterministic, with a declared window. No learned thresholds, no scoring
   model.

## 8. Verdict

Worth doing, in the narrow form of §4.1 plus the sharp absence rule of §6.4, and
worth refusing in the other three forms.

The case for it is not that gifter's calls are wrong without it. It is that the
AND layer currently makes an assignment claim — these components are one machine
— that it has no evidence for, and this is the only evidence available.
Reporting it on its own axis states the claim's support honestly without letting
an assembly artifact move a biological call.

The case against doing more than that is that every richer use runs into the
same wall: gene neighbourhood in a chunked MAG is a measurement of the assembly
at least as much as of the genome, and gifter has no validated model separating
the two. Decision 1c was right about that and stays right.

## 9. Decision requested

- [ ] Amend decision 1c to state what it forbids (dependence, specificity) and
      what it now permits (an optional, reportable, non-decisive context axis).
- [ ] Accept or reject §4.1 as the single insertion point.
- [ ] Accept or reject the fourth-axis rule of §5 as an addition to invariant 21.
- [ ] Accept or reject the locus-specific absence rule of §6.4.
- [ ] Confirm §4.4 stays permanently refused, and record the refusal in
      `database_changes.tsv` if any of the above is adopted.

---

## 10. Implementation plan for §4.1

Stage one only: the component-assignment axis. §6.4 (the locus-specific absence
rule) is a separate, later change against `R/assessability.R`, and the deferred
curation of `expected_linkage` per system is not planned here.

No schema change, no database rebuild, no compiled-artifact change. Every
Boolean call this stage produces must be byte-identical to what 0.4.1 produces
for the same markers, with or without context columns supplied.

### 10.1 New file: `R/context.R`

The whole axis lives in one file, for the same reason `R/assessability.R` is one
file: it is a bounded layer over the evaluation, and keeping it separable is what
makes it auditable and removable.

| Function | Responsibility |
|---|---|
| `.gifter_context_columns` | the recognised names: `contig_id`, `start`, `end`, `strand` |
| `.gifter_context_states` | the closed vocabulary of §6.2, ordered |
| `.normalize_context()` | pull the columns off the annotation table, validate, return `NULL` when absent |
| `.context_window()` | validate and normalize the declared window (§6.3) |
| `.component_context()` | per system: are the supporting genes of its required components co-localised |
| `.call_context()` | fold system states into one call state for the best implementation |

`.normalize_context()` decides the level: `contig_id` alone is level 1;
`contig_id` with `start`, `end` and `strand` is level 2. Coordinates without
`contig_id` are refused with a message naming what is missing. Coordinates that
are not finite integers, or where `end < start`, are refused. A `strand` outside
`+`/`-` is refused. Genes carrying no context are recorded as uncovered, not as
dispersed.

`.call_context()` folds with the rule of §2: any uncovered gene in a system makes
that system `not_assessed`; a system whose required components are all on one
contig within the window is `colocalised`; on one contig beyond the window, or on
more than one contig, is `dispersed`; both, across the systems of one
implementation, is `partial`; a supporting gene within the declared contig-end
margin makes it `split_assembly`, which outranks `dispersed` because an unreadable
context must never present as a read one. Single-component systems contribute
nothing — there is no assignment claim to corroborate — so a call resting only on
those is `not_assessed`, and this must be stated in the docs or every metabolic
GIFT with one-subunit enzymes will look unassessed by accident.

### 10.2 `R/evaluation.R`

1. `.prepare_observed_markers()` ([R/evaluation.R:47](../../R/evaluation.R#L47))
   carries the context columns through instead of dropping them, keyed on
   `observed_marker_id`. Keep them out of the marker-identity path: context is
   never part of what a marker *is*, so `.normalize_marker_accession()` and the
   hierarchy lookup are untouched.
2. `.gene_id_candidate()` ([R/evaluation.R:863](../../R/evaluation.R#L863)) skips
   `.gifter_context_columns` when proposing a gene column, so a GFF-ordered table
   is never asked to approve `gene_id = "contig_id"`. This is a fix worth having
   on its own merits.
3. `.annotate_system_support()` ([R/evaluation.R:474](../../R/evaluation.R#L474))
   gains `context` alongside `supported`, computed by `.component_context()`.
   It is already shared by the metabolic and machinery models, which is exactly
   the layer this belongs in — write it once there and all four GIFT types get it.
4. `.evaluate_metabolic_model()` and `.evaluate_machinery_model()` set
   `context_support` and `context_evidence` on their `gifts` tibbles beside
   `evidence_confidence`, over the best implementation's systems only.
5. `.gifter_call_columns` and `.blank_call_columns()`
   ([R/evaluation.R:684-712](../../R/evaluation.R#L684-L712)) gain the two
   columns, defaulting to `not_assessed` and an empty list.
6. `trace_gift()` evidence rows gain `contig_id`, `start`, `end`, `strand`,
   carried from the observed marker. `NA` throughout when no context was given.
7. `evaluate_gifts()` gains `context_window`, defaulting to `NULL`. Supplied
   context with no window is refused, following the precedent of the
   assessability threshold: there is no defensible default, and the choice is
   the analyst's.

### 10.3 `R/evaluation-community.R`

The split at [R/evaluation-community.R:391](../../R/evaluation-community.R#L391)
gives every genome its own table, so contig identifiers are already isolated per
genome and no namespacing code is needed. That is a property worth pinning rather
than assuming: add a test with two genomes both using `contig_1` and assert that
no cross-genome co-localisation is ever reported, so that a future change which
maps markers once across the community cannot break it silently.

`evaluate_gifts_community()` passes `context_window` through unchanged.

### 10.4 Tests

New `tests/testthat/test-genomic-context.R`, on synthetic fixtures rather than
curated content, covering:

- no context supplied → every call `not_assessed`, and every Boolean call
  identical to the same input evaluated without the feature;
- a two-component system, both genes on one contig within the window →
  `colocalised`; the same genes beyond the window → `dispersed`; on two contigs →
  `dispersed`; near a contig end → `split_assembly`;
- **dispersion never refutes**: the `dispersed` case and the `colocalised` case
  have identical `complete`, `best_implementation`, `missing_requirements` and
  `evidence_confidence`;
- context never promotes: no input with context makes an unsupported GIFT
  supported;
- partial coverage → `not_assessed`, never `dispersed`;
- a single-component system contributes no context state;
- coordinates without `contig_id`, `end < start`, a bad strand, and a missing
  window are each refused with a message that names the problem;
- the two-genome `contig_1` collision case of §10.3;
- `trace_gift()` carries coordinates through for both a metabolic and a
  machinery GIFT;
- `.gene_id_candidate()` skips context columns.

Add to `test-input-guardrails.R` rather than duplicating its idiom.

### 10.5 Documentation

- Roxygen for `evaluate_gifts()`, `evaluate_gifts_community()`, `trace_gift()`;
  regenerate `.Rd`.
- `vignettes/evaluating-a-genome.Rmd`: a short section on the optional columns
  and on reading `context_support`, stating plainly that dispersion is not
  evidence against and that the axis never moves a call.
- `AGENTS.md`: the fourth-axis rule as an extension of invariant 21, and a row
  in the work-in-the-correct-files table.
- This document: change the status line, and record what shipped.
- `CHANGELOG.md`: a minor version, since the API gains an argument and the
  result gains columns while no existing call changes.
- `proposal-polysaccharide-degradation.md` §12 decision 1c: amend to state what
  it forbids and what this permits, per §9.

### 10.6 Order of work

1. `R/context.R` with `.normalize_context()` and its validation, plus tests.
2. The `.prepare_observed_markers()` and `.gene_id_candidate()` changes, plus the
   regression test that no context supplied changes nothing.
3. `.component_context()` and the `.annotate_system_support()` hook.
4. Call-level folding, the two new columns, `trace_gift()` coordinates.
5. The community pass-through and its collision test.
6. Documentation, changelog, and the 1c amendment.

Each step keeps the suite green. Step 2 is the one that proves the
no-behaviour-change claim, so it should land before anything that reads context.
