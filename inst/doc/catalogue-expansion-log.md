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
