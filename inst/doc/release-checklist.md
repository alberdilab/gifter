# Local v1 release checklist

Nothing in this checklist authorizes publishing, tagging, pushing, DOI creation,
or modification of an external service. Those actions require explicit owner
approval.

## Before the candidate build

- Resolve every `human_review_required` row in
  `inst/extdata/UPSTREAM-SOURCES.tsv`, recording permission or removing affected
  redistributed content. Begin with the dated evidence and content inventory in
  `inst/doc/licensing-review.md`; keep the human decision and any conditions
  with that record.
- Confirm package, database, and schema versions independently. Update the
  appropriate changelog: code/API decisions in `CHANGELOG.md`, biological
  decisions in `database_changes.tsv` and `change_gifts.tsv`.
- Confirm all source URLs, pinned releases, citation text, author metadata, and
  all four vignettes.
- Replace the DOI note in `inst/CITATION` only after an archive has actually
  assigned one. Current state: **PENDING EXTERNAL ACTION — no DOI exists**.

## Operational CI maintenance — separate from biological curation

GitHub Actions has issued maintenance warnings about the Node.js 20 migration
for `actions/upload-artifact@v4` and the future `ubuntu-latest` move to Ubuntu
26. These are workflow-maintenance items, not licensing or biological-database
decisions. Address them in a separately scoped compatibility change with a
dedicated CI run; do not use a runner change to reclassify an upstream source or
to plan a v1 release.

## Reproducible database and source commit

1. Commit the final TSV sources, SQL schema, compiler, tests, and documentation.
   Record that full commit as the database source commit.
2. In a clean worktree, set `GIFTER_SOURCE_COMMIT` to that full hash and run
   `Rscript data-raw/build_database.R`. The script refuses dirty relevant inputs
   or any difference between those inputs and the named commit.
3. Run `Rscript data-raw/verify_database.R` and confirm the 41-table comparison,
   integrity check, and foreign-key check.
4. Commit only the reproducibly generated SQLite artifact if it changed. This
   later artifact commit avoids asking the database to name a commit containing
   itself. Rebuilding from it uses the earlier source hash and must reproduce
   the artifact logically.

## Local release audit

Run from a clean checkout with `GIFTER_SOURCE_COMMIT` still set to the recorded
source commit:

```sh
Rscript data-raw/build_database.R
Rscript data-raw/verify_database.R
Rscript -e 'testthat::test_local(".")'
R CMD build .
R CMD check --no-manual gifter_*.tar.gz
```

Inspect the check log and installed size note rather than suppressing it. Verify
that `gifter_db_version()` reports the intended package, database and schema
versions plus the recorded source commit.

## Artifacts, checksums, tag, and DOI

- Keep the built `gifter_<version>.tar.gz` and compute SHA-256 checksums for the
  source archive and packaged SQLite artifact. Store the checksum file beside
  the candidate artifacts.
- Verify a fresh installation from the source archive and run a minimal
  mixed-type evaluation plus `citation("gifter")`.
- With explicit approval, create one annotated version tag on the audited
  artifact commit. Verify the tag target before any push.
- With explicit approval, push the commit and tag and create the release from
  the exact audited archive and checksum file. Do not rebuild after checksums.
- With explicit approval, deposit that exact archive in the chosen repository,
  obtain the DOI, then replace the pending citation note in the next controlled
  metadata update. Never invent or predict a DOI.
