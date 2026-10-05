# Catalogue expansion attempt log

The append-only source of truth for attempts to add GIFTs is
[`catalogue-expansion-attempts.tsv`](catalogue-expansion-attempts.tsv), and
the [expansion attempts](https://alberdilab.github.io/gifter/atlas/#attempts) page of the
documentation renders it for browsing. It records an effort even when it
produces no database content. Its purpose is to
make previous searches, refusals and unresolved candidates visible before a new
catalogue-expansion request repeats them.

This is a curation-process record, not biological database content. A candidate
listed here is not a GIFT, and `implemented_gifts` is informative only because
each identifier is also present in `gifts.tsv`. The register must never be used
to make calls or to imply that a deferred or refused capability is encoded by a
genome.

## Required workflow

1. Before investigating a request to add, discover or expand GIFTs, search the
   TSV's `candidate_terms`, `scope`, `deferred_or_open` and
   `refused_or_superseded` fields. Search synonyms and proposed identifiers, not
   only the wording in the request.
2. Read every matching row's `source` and any attempt named in `revisits`.
   Reuse its evidence and respect its stated retrigger. New evidence may reopen
   a decision; a repeated request by itself may not.
3. Append a row with `state = in_progress` and a UTC `started_at` **before new
   evidence collection or candidate screening begins**. Add candidate terms as
   the scope becomes concrete. This keeps abandoned, interrupted and
   unsuccessful efforts discoverable.
4. Close the row in the same change that records the result. Set `closed_at`,
   change `state` to `closed`, list exact curated identifiers under
   `implemented_gifts`, and record every unresolved and rejected candidate in
   the corresponding fields. Link a durable proposal or assessment under
   `source`.
5. A renewed investigation gets a new row and names the earlier `attempt_id` in
   `revisits`. Do not rewrite an earlier result to make the history look as if
   the first investigation reached the later conclusion. Correct factual or
   typographical errors in place and explain material reinterpretations in a
   new attempt.

One row represents one bounded expansion effort or screening pass. A pass may
assess many candidates. Candidate-level reasoning remains in its linked source;
the TSV is the searchable chronological index that says the work happened and
where its result lives.

## Columns

| Column | Contract |
|---|---|
| `attempt_id` | Stable identifier `GEA-YYYYMMDD-SLUG`; never reused. |
| `started_at`, `closed_at` | ISO 8601 UTC timestamp, or a date where the historical source recorded no time. New rows use timestamps. |
| `state` | `in_progress` or `closed`. An interrupted attempt remains `in_progress` until work resumes or is explicitly closed with its partial result. |
| `scope` | Plain-language boundary of the pass. |
| `gift_types` | Semicolon-separated types considered; a proposed new type may be named here without registering it in the ontology. |
| `candidate_terms` | Semicolon-separated searchable candidate names, aliases and proposed identifiers. It must cover every candidate actually assessed. |
| `implemented_gifts` | Exact semicolon-separated identifiers that this effort added. Empty when no new GIFT was curated. |
| `deferred_or_open` | Candidates worth revisiting and the terms future searches are likely to use. Detailed blockers and retriggers stay in the linked proposal and, while standing, in the deferral register. |
| `refused_or_superseded` | Candidates that failed the biological or architectural contract, or names replaced by a better boundary. |
| `revisits` | Earlier attempt identifiers re-examined by this pass. |
| `source` | Semicolon-separated repository paths containing evidence, boundaries and reasoning. |
| `result` | Concise outcome of the whole effort. |

## Relationship to the other records

These records answer different questions:

- this log asks **what catalogue-expansion work was attempted, including work
  that changed nothing?**;
- [`deferral-register.md`](deferral-register.md) asks **which blockers or
  refusals are standing, and what would retrigger them?**;
- `database_changes.tsv` and `change_gifts.tsv` ask **which biological decisions
  shipped with a database release?**;
- `gifts.tsv` states **which GIFTs the current database actually claims?**

Closing an attempt therefore does not replace the other records. A curated GIFT
still needs a database change and release. A standing refusal or deferral still
needs a deferral-register row. The attempt log links the full exercise across
both outcomes.

## Historical coverage

The initial rows were backfilled on 2026-10-02 from the versioned curation
proposals and biological change history. They account for every GIFT in the
current `gifts.tsv` and index the candidate families visible in those sources.
No repository can reconstruct an undocumented private or discarded
investigation, so this is an honest record of **all recoverable prior attempts**,
not a claim that no unrecorded thought occurred before the contract existed.

The test suite checks the table shape, identifiers, dates, source paths,
revisit links and the coverage of all currently curated GIFT identifiers.

## Retrospective evidence audit (2026-10-05)

This is a documentation and provenance audit, not a new expansion attempt or a
biological database release. The analysis is reproducible with
`python3 data-raw/curation_history_audit.py`; it reads the current TSV sources
and tests whether linked repository files exist. Passing GIFT identifiers, for
example `python3 data-raw/curation_history_audit.py adenylate_biosynthesis
lactate_formation`, also prints their current anchors, route steps, accepted
markers and external cross-references. At database 2026.39.1 the coverage audit
gives:

| Attempts opened | Attempts | GIFTs they introduced | GIFTs with a curation document | GIFTs now linked to a script | GIFTs now linked to a result table |
|---|---:|---:|---:|---:|---:|
| Before October 2026 | 25 | 153 | 153 | 1 | 1 |
| October 2026 onward | 13 | 10 | 10 | 7 | 8 |
| All | 38 | 163 | 163 | 8 | 9 |

All 163 current GIFTs occur in a closed attempt and have a curation document;
all attempt and `gift_evidence.tsv` paths resolve. There are 144 biological
change rows. The script and table columns count **current** evidence links for
GIFTs introduced in each period, including later work on those GIFTs. They do
not count scripts or tables known to have existed at the time of introduction.
The recent link density shows what the older records could explain more
clearly, but it is not a measure of historical scientific quality.

The [per-GIFT delimitation index](gift-delimitation-rationales.md) now puts the
current scope, boundary or machinery decision, and supporting record beside
each other in short bullet lists. It is a guide to the current catalogue, not
an amendment to the dated attempt outcomes or the compiled source tables.

As a discoverability check, only 4 of the 25 pre-October attempts currently
link a Markdown source containing an explicit PMID, PubMed URL or DOI. This is
a text search, not a judgement that the other 21 lack literature support:
their `database_changes.tsv` evidence fields, `SOURCES.md`, pinned reference
records or uncited prose may still support particular claims. It shows why a
reader often has to leave the attempt's linked document to find the paper
behind a decision. The count also reflects later additions to shared documents,
so it says nothing about citation coverage on the original attempt date.

Two older decisions show the difference between a document trail and a
reproducible claim:

- **Initial nucleotide boundaries (2026-08-17).** The baseline attempt now
  links both its change entry and
  [`SOURCES.md`](../extdata/database-source/SOURCES.md), which explains the
  nucleotide cuts. The current `gift_anchors.tsv`, `route_reactions.tsv` and
  `gift_xrefs.tsv` corroborate the *present* IMP-to-AMP cut: AMP is the output,
  the route contains `RHEA:15753` and `RHEA:16853`, both required and forward,
  with accepted markers `K01939` and `K01756`. The link to
  [KEGG M00049](https://www.kegg.jp/entry/M00049) is `subset_of` because the
  module continues to ADP and ATP. That is a defensible boundary explanation;
  the current rows alone cannot prove the exact historical database state.
- **Organic acids (2026-08-18).** The
  [original proposal](proposal-organic-acid-formation.md) reports a 59-KO,
  11,855-organism KEGG screen and graph experiments, but §13 says the graph
  work was done in a scratch script that changed no repository file. Neither
  that script nor an organism-by-KO result table is linked. The current pinned
  snapshot checks accessions and reaction chemistry; it does not archive the
  historical organism membership that would reproduce those prevalence
  counts. The later [cycle proposal](proposal-central-metabolic-cycles.md)
  explicitly revisits the initial cycle refusal, so the old refusal must be
  read as a dated decision. A second qualification concerns lactate:
  [Rhea RHEA:23444](https://www.rhea-db.org/rhea/23444) records a reversible
  NAD-dependent reaction, and [Zhao et al. 2013
  (PMID:24251099)](https://pubmed.ncbi.nlm.nih.gov/24251099/) experimentally
  observed its use for lactate oxidation in *Lactococcus lactis*. The
  current route records `RHEA:23444` in reverse with `K00016` as its accepted
  marker; `K29125` is absent from that route's marker mapping. The
  difference between `K00016` and the quinone-dependent lactate dehydrogenase
  supports distinct enzyme chemistry, but does not prove that `K00016` is used
  only to form lactate. The proposal now carries a dated note about that limit.

The practical backfill is **claim by claim**. Keep the dated original and its
outcome, then append a dated reassessment that names the exact claim, resource
release or experimental paper, analysis code, saved inputs and result table,
and whether the new evidence confirms, limits or reverses the old reasoning.
Link a new analysis as retrospective evidence, never as a script supposedly
run in the original attempt. For a numeric historical claim with no saved
input, label it as a reported historical result and run a new, dated screen
with a pinned denominator if the number matters. If reassessment changes a
GIFT definition or marker interpretation, it needs the biological change,
review and database-release procedure; this audit changes no calls. In
particular, the present `lactate_formation` description and the 2026.14.1
change entry still say that `K00016` establishes reaction direction. The
experimental counterexample above makes that wording a priority for a curated
source-table reassessment; a retrospective note alone does not amend the
compiled definition.
