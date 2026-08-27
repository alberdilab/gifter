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

## ko-reaction-specificity.tsv and the three screen outputs

`marker_specificity_screen.R` in the parent directory regenerates all four. They
answer, for the KO namespace, the question invariant 16 asks: how many distinct
reactions can this marker license?

| File | Content |
|---|---|
| `ko-reaction-specificity.tsv` | Every KO carrying an EC, with its ECs, the Rhea masters those ECs reach, a verdict, and how many reviewed UniProt proteins support them |
| `curated-marker-audit.tsv` | Every curated KO marker row, joined to the reaction it is evidence for, with its fan-out, what varies between its reactions, and whether it is the sole marker of its component |
| `route-specificity.tsv` | Every curated route and how many of its required reactions are evidenced by a marker that states one reaction |
| `discovery-candidates.tsv` | Single-reaction KOs that are not curated and whose reaction touches a declared anchor, ranked by how specific that anchor is |

**Read the verdict, not the count.** A marker reaching several reactions is
broad in two different ways and the mapping cannot tell them apart: an ortholog
that groups genes of different activities cannot support a substrate-specific
claim, while a genuinely promiscuous enzyme supports every reaction it performs
including the curated one. The screen finds the rows that need a curator; it
does not decide them. `varying_participants` is the column that usually settles
it — masters differing only in `a quinone` versus `a menaquinone` are one
activity, masters differing in the sugar are not.

**Scope.** KO only. CAZy specificity is measured separately by `ec_fraction`
above; Pfam and TIGRFAM markers are not screened at all, and a reaction
evidenced by them is reported as `not_screened` rather than as unsupported.
1,435 KOs carry a complete EC that Rhea does not cover and 2,017 carry only
partial ECs; those are invisible to the screen, which is not evidence either
way.

The assessment that produced these tables, including the individual reading of
every flagged route, is `inst/doc/proposal-marker-specificity-screen.md`.

Downloaded inputs are cached in `.cache/` and are not committed. Reproduce with:

```sh
Rscript data-raw/marker_specificity_screen.R
```

## The five NCBIfam screen outputs

`ncbifam_equivalog_screen.R` in the parent directory regenerates all five. They
answer for the NCBIfam namespace the question `marker_specificity_screen.R`
answers for KO, and then the comparative question that decides whether admitting
a profile buys anything: does a single-reaction equivalog resolve a curated
reaction that no single-reaction KO resolves?

| File | Content |
|---|---|
| `ncbifam-equivalog-specificity.tsv` | Every equivalog-grade profile carrying a complete EC, with its ECs, the Rhea masters those ECs reach, and a verdict |
| `ncbifam-curated-reaction-gain.tsv` | Every curated reaction a single-reaction equivalog reaches, whether a single-reaction KO already reaches it, the curated components on the reaction, and the candidate profiles |
| `ncbifam-grade-refusals.tsv` | Profiles that reach a curated reaction and are refused on grade alone — what the equivalog filter costs |
| `ncbifam-curated-grades.tsv` | Every `NCBIFAM` accession in the database, with the grade the pinned release gives it |
| `ncbifam-discovery-candidates.tsv` | Equivalog profiles the EC join cannot see, whose product name or gene symbol names a declared anchor |

**The grade is the filter, not a footnote.** NCBIfam's `family_type` column
grades each profile, and only `equivalog` and `equivalog_domain` assert that the
family's members share one function. The screen applies that filter before it
scores anything, because a `subfamily` or `domain` profile on a reaction gifter
curates is exactly the over-broad evidence invariant 16 refuses. 229 profiles
reach a curated reaction and are excluded on grade alone; they are written down
rather than discarded, and a test asserts that none of them is ever a marker.

**Read `ko_already` before reading a candidate.** 266 curated reactions are
reached by a single-reaction equivalog and 24 of them gain markers, because for
the rest a KO already states one reaction and the profile would buy annotation
coverage rather than specificity. The 25 reactions where no single-reaction KO
resolves the chemistry are the release's target set, and it is recomputed by the
script rather than copied from the assessment.

**EC agreement is necessary, never sufficient.** Two profiles can share one EC
and identify different proteins — that is the whole reason the namespace was
admitted, since `NF040708.3` and `NF040707.3` both carry EC 4.1.1.111 and
separate the two subunits `K22225` conflates. It also cuts the other way: four
profiles in the target set passed the grade filter and were refused by a curator
on biology, including a deferrochelatase that shares EC 4.98.1.1 with the
ferrochelatase it runs backwards from. The screen finds the reactions worth
reading; the reading is in `inst/doc/proposal-ncbifam-namespace.md`.

**`ncbifam-discovery-candidates.tsv` joins by name, and that is weaker than
joining by chemistry.** The EC join above is blind to most of the namespace:
8,711 equivalog profiles carry no EC at all, 554 carry only an incomplete one
and 385 carry a complete EC that reaches no Rhea master — 9,650 of 13,888.
`TIGR04546.1` *ahbC* is in the first group, so the EC join would have found two
of the three steps of the route the namespace was admitted for. The discovery
table closes that gap by turning the declared anchor vocabulary into search
terms and matching them against `product_name` and `gene_symbol`.

Three properties of that match decide what the table contains, and the script
argues each of them where it implements it:

- The match is **left-permissive and right-anchored**, because chemical names
  compose by prefixing. `siroheme` must match `12,18-didecarboxysiroheme`, which
  a word-boundary match misses — that one rule is the difference between finding
  *ahbC* and not.
- A term **subsumed** by a longer term matched on the same profile is dropped,
  so a homocysteine methyltransferase does not also read as a cysteine
  candidate.
- A match inside a phrase naming a protein residue or a protein substrate is
  **marked and kept**, not deleted. `histidine kinase` is the largest false
  positive in the raw match and has nothing to do with histidine. Read
  `excluded_because` before reading a row.

Rows are ranked by `anchor_rhea_degree`, computed from Rhea exactly as
`marker_specificity_screen.R` computes it, so the two discovery queues can be
read against each other. Three anchors — `GTP`, `NAD` and `UREA` — have no
search term of five characters or more and are unsearchable by name; the run log
names them, so the blind spot of the blind-spot screen is visible too.

**A string inside a product name is not a reaction.** This table is a reading
queue, not a candidate list: 772 profiles survive the anchor join and the
`comment` column is carried for each of them because reading it is the point.
The assessment that read the top of that queue, and the four verdicts it
reached, is `inst/doc/proposal-ncbifam-discovery.md`.

**`ncbifam-curated-grades.tsv` reads in one direction on purpose.** Its rows
come from the database and its `family_type` column comes from NCBIfam. That
asymmetry is what lets a test assert that every admitted accession is
equivalog-graded in the pinned release without the database being asked to vouch
for itself. An accession absent from the release appears with `in_release=0`,
which is the symptom of an accession copied from an annotator rather than
curated against a pinned release.

Downloaded inputs are cached in `.cache/` and are not committed. Reproduce with:

```sh
Rscript data-raw/ncbifam_equivalog_screen.R
```

## NCBIfam accessions are versioned, and the version is part of the identity

`NF040708.3` is the third build of that profile. A rebuild can change the seed
alignment and the cut-offs, so the accession without its suffix names a family
rather than a model. Release 20.0 alone updated 24 seeds and 35 cut-offs among
persisting models. Two consequences, and they are the eCAMI lesson below reached
from a better starting point:

- **The version suffix is curated, not copied.** Every `NCBIFAM` row records the
  versioned accession and names the release in its `source` column, and the
  compiler refuses an unversioned one. Unlike an eCAMI cluster, the accession
  says which release it came from, so a mismatch is visible rather than silent.
- **An NCBIfam upgrade is a marker-layer migration.** Re-running the screen is
  not enough: the curated rows must be re-read against the new release, because
  a profile that still exists may now match different sequences, and 58 models
  were deprecated outright in the last release.

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
