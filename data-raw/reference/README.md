# Curation reference inputs

Evidence files consulted during curation. They are **not** compiled into the
database and are not loaded at runtime; they are kept so that a curation
decision can be re-checked against the exact input that informed it.

## fam-substrate-mapping.tsv

CAZy family and subfamily to substrate and characterised-activity mapping, from
the dbCAN database release `db_v5-2-9_5-5-2026` pinned by
[run_dbcan](https://github.com/bcb-unl/run_dbcan) in
`dbcan/constants/databases_constants.py`. Retrieved 2026-08-18 from
`https://dbcan.s3.us-west-2.amazonaws.com/db_v5-2-9_5-5-2026/fam-substrate-mapping.tsv`.

Columns: `Substrate_high_level`, `Substrate_curated`, `Family`, `Name`,
`EC_Number`. 1017 records across 44 high-level substrate classes.

This is the evidence base for the polysaccharide layer of
`inst/doc/proposal-polysaccharide-degradation.md`. The high-level substrate
classes are the candidate polymer anchors; the `Family` column supplies the
markers, and its subfamily entries are what the marker policy prefers over bare
polyspecific families.

## dbcan_sub_names.txt and cazy-subfamily-ec.tsv

`cazy-subfamily-ec.tsv` maps dbCAN-sub subfamilies to EC numbers with quantified
support. It is derived, not downloaded, and `extract_cazy_subfamilies.R` in the
parent directory regenerates it.

The source is `dbCAN_sub.hmm` from the same dbCAN release, which is **4.9 GB**
and is not pinned here. Only its profile `NAME` lines are needed, and those are
0.1% of the file:

```
NAME AA1_e33.hmm|AA1:85|AA1_1:697|CE4:1|1.10.3.2:77
```

One line carries the dbCAN-sub eCAMI cluster (`AA1_e33`), its parent CAZy family
(`AA1`), any official CAZy subfamilies among its members (`AA1_1`), and the EC
numbers those members carry — each with a member count. Streaming the library
with eight overlapping HTTP range requests and keeping only those lines yields
`dbcan_sub_names.txt` (53,411 profiles, 5 MB), from which the extraction script
produces a 104 KB table.

Reproduce with:

```sh
# see fetch loop in the curation record; then
Rscript data-raw/extract_cazy_subfamilies.R
```

**Read the `ec_fraction` column before using a row as evidence.** The EC
association is co-occurrence within a cluster, not a per-sequence assignment:
`ec_members` of the cluster's `ec_members_total` EC-annotated members carry that
EC. A cluster where one EC accounts for every annotated member is specific
evidence; one where an EC accounts for a fifth of them is not. Two further
filters matter when curating from this table: the CAZy class must match the
chemistry, and CBM families must be excluded, because a binding module catalyses
nothing.

**Curation floor.** Since database 2026.21.1 an eCAMI cluster is not admitted as
a marker below 50% EC agreement. Above it, the grade follows the support: 93% or
better across ten or more annotated members is `curated`, 70% or better is
`high-confidence`, and the remainder is `ambiguous`. The floor exists because a
cluster in which 3 of 96 annotated members carry the claimed EC is not weak
evidence for the assignment — it is quantified evidence against it, which is a
different thing from a polyspecific family that genuinely carries the activity
among others.

## eCAMI cluster identifiers are release-scoped

**A `GH5_e12` from one dbCAN release is not the `GH5_e12` of another.** The
eCAMI clusters are regenerated when the library is rebuilt, and the numbering is
positional, so cluster identity does not survive a release change. Nothing in
the accession says which release it came from.

This matters because most of gifter's CAZy markers are eCAMI clusters rather
than bare families or official CAZy subfamilies. Two consequences:

- **Annotate against the pinned release.** Running a different dbCAN release
  produces accessions that mostly fail to match, and they fail *silently* — an
  unmatched marker is simply an unmatched marker, so the symptom is a genome
  that looks like it lacks capabilities rather than an error. The pinned release
  is `db_v5-2-9_5-5-2026`, named at the top of this file and recorded in the
  `source` column of every CAZy row in `component_markers.tsv`.
- **Re-derive the whole marker layer on any dbCAN upgrade.** Regenerating
  `cazy-subfamily-ec.tsv` is not enough: the existing `component_markers` rows
  must be re-mined against the new clusters and re-graded, because an accession
  that still exists may now describe different sequences. Treat a dbCAN upgrade
  as a marker-layer migration with its own `database_changes.tsv` entry, not as
  a refresh.

Bare CAZy families (`GH28`, `CE8`) and official CAZy subfamilies (`GH5_4`) do
not have this problem — those identifiers are CAZy's own and are stable across
dbCAN releases. Where a family is monoactivity enough to stand alone, preferring
it costs nothing and buys release independence.
