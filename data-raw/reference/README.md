# Curation reference inputs

Evidence files consulted during curation. They are **not** compiled into the
database and are not loaded at runtime; they are kept so that a curation
decision can be re-checked against the exact input that informed it.

## serine-deamination-gene-audit.tsv and serine-deamination-genome-audit.tsv

`data-raw/serine_deamination_marker_audit.py` regenerates both tables from
KEGG K01752/K17989 gene links and NCBIfam `hmm_PGAP/20.0` profiles. It uses
the repository's fixed KEGG genome frame, samples 40 genomes in each K01752
copy-count stratum by SHA256 rank, and adds *E. coli* and *B. subtilis*
controls. The gene table preserves KEGG protein identifiers and NCBIfam profile
scores at published gathering thresholds. The genome table reports whether
the audited K01752 proteins support a complete single-chain or two-subunit
system, or the genome has K17989. The `prokaryote` flag used for this frame is
not a reliable taxonomy filter. This sample is evidence for marker specificity,
not a full-frame NCBIfam prevalence or exact mixed-input call delta. Downloaded
KEGG links, sequences and HMMs stay in the ignored cache. Reproduce online
once, then verify with `python3 data-raw/serine_deamination_marker_audit.py
--offline` (requires HMMER `hmmsearch`).

## lta-peptidoglycan-prevalence.tsv and lta-peptidoglycan-marker-audit.tsv

These tables retain the 2026-10-02 dedicated reassessment of lipoteichoic acid
and the peptidoglycan sacculus. The denominator is the stored 11,908-genome
prokaryotic KEGG frame. KO counts use current KEGG gene links. Boolean proxy
sets explicitly account for the MurE/MurF and Alr/MurF fusions; they are
diagnostics, not GIFT architectures.

For the narrow LTA candidate, the screen first intersected `K19005` and
`K03429`, searched the exact KO-assigned proteins with NCBIfam 20.0 profiles
`NF053595.1` and `NF010134.0`, and then searched the 128 available NCBI protein
sets from the 129-profile intersection with `NF047396.1` LtaA. The resulting
three-profile set supports the narrow, curated diglucosyldiacylglycerol-anchored
poly(glycerol-phosphate) LTA architecture. It includes Gram-negative
*Sulfitobacter donghicola*, whose three proteins pass the profiles at or above
the scores of the Staphylococcus controls. That genome is retained as positive:
taxonomy and neighbourhood were not used to reinterpret admitted marker
evidence. One *Staphylococcus pseudintermedius* proteome lacked LtaA evidence
and one *S. aureus* assembly had no downloadable protein package, so neither
was silently promoted. The 127 three-profile genomes are therefore an observed
minimum, not an exact full-frame NCBIfam prevalence.

The peptidoglycan proxies separately measure meso-DAP and lysine precursor
chemistries, an intentionally unsafe extended meso-DAP set, and a
lysine/pentaglycine set. Their failures are the result: `K03588` merges FtsW,
RodA and SpoVE; the pinned NCBIfam Amj profile is `PfamAutoEq`, not an admitted
equivalog; and no marker inventory resolves all flippase, polymerase and
cross-linking alternatives. The underlying KEGG assignments and NCBI protein
packages remain uncommitted because only aggregate diagnostic results are
redistributable here.

## structural-machines-*.tsv

`structural_machines_prevalence.R` in the parent directory regenerates three
tables for the 2026-10-03 initial assessment of nine candidate structural
machines (archaellum, Tad pilus, type II secretion, gas vesicles, BAM, curli,
chaperone-usher pili, type IV secretion, microcompartments).
`structural-machines-ko-prevalence.tsv` counts genomes per KO;
`structural-machines-proxy-prevalence.tsv` counts genomes completing each proxy
function set, those exactly one function short, and which function they miss;
`structural-machines-homology-overlap.tsv` compares homologous KOs and proxy
sets across machines. Every set is a KO diagnostic and none is a curated
architecture. Domain and phylum come from the KEGG organism hierarchy
`br08601`, because the frame's `prokaryote` flag still admits 1,290 eukaryotes;
the bacterial and archaeal denominators are written beside the frame size.

## archaellum-*.tsv

`archaellum_ncbifam_prevalence.R` in the parent directory regenerates seven
tables for the 2026-10-03 archaellum curation (attempt
`GEA-20261003-ARCHAELLUM`). `archaellum-ncbifam-profiles.tsv` lists the
candidate equivalogs and the contrast profiles with their grade and taxonomic
range. `archaellum-ko-ncbifam-agreement.tsv` counts KO-assigned proteins and
genomes by orthology, genome class and best-scoring candidate and contrast
profile. `archaellum-role-agreement.tsv` counts, per role, the genomes in which
at least one KO-assigned protein passes that role's equivalog. The remaining
four evaluate the curated hierarchy as the source TSVs define it:
`archaellum-prevalence.tsv` (complete genomes over 470 archaea and 10,143
bacteria), `archaellum-one-short.tsv` (missing function by lineage),
`archaellum-accessory.tsv` (accessory support among complete genomes) and
`archaellum-controls.tsv` (five named reference genomes evaluated by
`evaluate_gifts()`). Contrast profiles identify proteins only and are never
gifter evidence.

## t2ss-*.tsv

`t2ss_prevalence.R` in the parent directory regenerates the three tables behind
the 2026-10-03 type II secretion curation. `t2ss-roles.tsv` lists each Gsp role
with its KO, its equivalog and the frame genomes carrying it, plus the shared
peptidase row. `t2ss-prevalence.tsv` is a single row of counts built to answer
three questions: whether the Gsp inventory identifies a machine distinct from the
type IVa pilus, whether the shared peptidase does any discriminating work, and
which function near-complete genomes lack. `t2ss-controls.tsv` holds twelve named
strains with what each is established to encode beside the marker result;
`unverified` marks a strain whose expectation was not checked.

Two numbers carry the curation decision. Requiring the shared peptidase costs 35
genomes out of 1,571, so a role both machines satisfy with the same protein does
almost no discriminating work -- while 703 genomes complete this apparatus
without the pilus and 674 the pilus without it, so the other four functions do.
And 1,319 of the 1,536 complete architectures reach the peptidase through PilD
rather than GspO, which is why refusing the shared accession was not an option.
Downloaded KO links, HMMs and NCBI protein packages stay in the ignored cache.

Reproduce online once, then verify from the pinned cache:

```sh
Rscript data-raw/t2ss_prevalence.R
Rscript data-raw/t2ss_prevalence.R --offline
```

## wta-ncbifam-prevalence.tsv and wta-tagf-marker-audit.tsv

`wta_ncbifam_prevalence.R` in the parent directory regenerates both tables for
the wall-teichoic-acid structural assessment. The prevalence screen is exact
over the stored KEGG frame without annotating all 11,949 proteomes: it first
intersects every required KO proxy, then searches the lineage-resolving
NCBIfam profiles against the exact polymerase sequences KEGG assigned in every
genome in that complete candidate set. A safe
NCBIfam-complete architecture can only be a subset of the KO-complete set, so
this preserves the full-frame denominator and never substitutes taxonomy for a
marker. Only aggregate counts are retained here; the KEGG-derived per-genome
matrix and downloaded amino-acid sequences remain in the ignored cache.

The marker audit records the exhaustive result of seeking an admitted 168-type
TagF profile in NCBIfam `hmm_PGAP/20.0`. `NF016357.7` is a domain spanning the
TagF-like family and cannot distinguish polymerases from primases;
`NF041712.1` is an equivalog for the *Staphylococcus aureus* TarF primase in the
separate ribitol-WTA architecture. Neither licenses the 168-type polymerase.

Reproduce online once, then verify from the pinned cache:

```sh
Rscript data-raw/wta_ncbifam_prevalence.R
Rscript data-raw/wta_ncbifam_prevalence.R --offline
```

## secretion-system-*.tsv

`secretion_system_prevalence.R` in the parent directory regenerates the four
tables behind the 2026-10-03 type III and type VI secretion assessment.

`secretion-system-roles.tsv` is the role inventory: every component role of both
architectures with the KEGG orthologies and NCBIfam equivalogs accepted for it
and the number of frame genomes carrying each. `secretion-system-prevalence.tsv`
counts complete and near-complete architectures over the stored
11,908-prokaryote frame, names the role that near-misses lack, and reports the
overlap with a complete flagellar export apparatus — the homologue the
injectisome has to be distinguished from. `secretion-system-marker-audit.tsv`
records the accessions tested against a role equivalog before acceptance,
including the one refused for failing it. `secretion-system-controls.tsv` holds
17 named reference strains with what each is established to carry beside what
the markers call; the expectation column is compared with the marker result and
never used to produce it, and strains whose expectation was not checked are
marked `unverified`.

The decisive numbers are the specificity ones. 4,399 frame genomes complete the
flagellar export apparatus while supporting no injectisome role, and the three
flagellated controls encoding neither secretion system support no role of either
architecture, so the shared ancestry of the two export apparatuses does not
reach the accepted accessions. Per-genome KEGG assignments, downloaded HMMs,
protein sequences and NCBI protein packages remain in the ignored cache because
they are not redistributable here.

Reproduce online once, then verify from the pinned cache:

```sh
Rscript data-raw/secretion_system_prevalence.R
Rscript data-raw/secretion_system_prevalence.R --offline
```

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
including the curated one. The screen finds the rows that need to be read; it
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

## phenotype-crosswalk.tsv

The curated mapping from an external phenotype observation to something gifter
claims. It is the crux of R9 and the only part of that analysis that is
judgment rather than engineering, so it is a reviewed table rather than a
lookup buried in a script.

One row is one (source field, term, kind-of-test) mapped to one target, with an
explicit `relation` drawn from the vocabulary `gift_xrefs` already uses. The
`layer` column says what the target is, because the observations reach three
different depths: an EC-resolved enzyme assay tests a curated **reaction**, a
substrate-use record tests a **gift**, and growth on a defined medium tests a
whole bounded **frame**.

**Read the relation before using a row.** Only `equivalent` and `subset_of` let
the observation imply the target, so only those may enter a recall table.
`superset_of` and `overlaps` rows are kept rather than deleted because they
still bound the permitted cell and because a mapping that was considered and
declined should stay findable — the deferral register's argument, applied to a
reference set. `refused` marks a mapping that must never be used and says why;
`voids` marks a medium ingredient whose presence makes a test inapplicable
rather than negative.

The `kinds` column is not metadata. BacDive records *how* a metabolite was
tested, and the same metabolite maps differently depending: "carbon source"
for L-arabinose is `equivalent` to the degradation GIFT, while "builds acid
from" is `subset_of` it. A crosswalk that ignored the column would silently
promote an acidification test into a catabolic-route claim.

The reasoning behind every refusal is
`inst/doc/proposal-phenotype-validation.md`. The reader that enforces the
vocabulary and checks that every target still exists is
`read_phenotype_crosswalk()` in `manuscript/analysis/_common.R`.

## chebi-anchor-aliases.tsv and chebi-anchor-alias-candidates.tsv

`chebi_anchor_aliases.R` in the parent directory regenerates both.

gifter's anchors carry Rhea's participant identifiers, which are charge- and
anomer-resolved. Every external record uses the parent instead: BacDive records
L-arabinose as `CHEBI:30849` against the anchor's `CHEBI:17535`, and MediaDive
lists L-Tryptophan as `CHEBI:16828` against `CHEBI:57912`. Of the 196 distinct
metabolite identifiers in a 400-strain BacDive probe, 21 matched an anchor
outright. Without a bridge the crosswalk cannot join at all.

The bridge is split in two on purpose.

**Derived rows** come from ChEBI relations that preserve chemical identity by
definition — `is tautomer of`, `is protonated form of`, `is deprotonated form
of` — and are regenerated on every run. 144 of them.

**Curated rows** are the anomeric step, from `beta-D-galactose` to
`D-galactose`, and that step is *not* derived. It cannot be: the ChEBI parent of
an anomer is sometimes the sugar (`L-rhamnopyranose` to `L-rhamnose`) and
sometimes another anomeric class (`beta-D-galactose` to `D-galactopyranose`),
and the parent of a specific compound is sometimes a genuine widening carrying
an identical molecular formula (`N-acetyl-D-glucosamine` to
`N-acetyl-D-hexosamine`). No label or formula rule separates those, which is
the assessment's point restated: a traversal that goes one step too far turns a
specific anchor into a compound class. So every `subClassOf` step is written to
`chebi-anchor-alias-candidates.tsv` for review, and an accepted one
is added with `status = curated`. Reruns carry curated rows through untouched.

The candidates file is worth reading beside the accepted one, because it shows
both at once: `GLCNAC` proposes `N-acetylglucosamine` and `N-acetyl-D-hexosamine`
as siblings, and only the first is a name for the same molecule.

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

## The external reference cache and the packaged snapshot

`data-raw/reference_snapshot.R` downloads Rhea, ChEBI and KEGG into
`.cache/external/`, which is ignored, and writes two things. The pinned extract
the validator reads goes to `inst/extdata/reference-snapshot/` and is shipped
with the package: Rhea and ChEBI records in the detail the checks need, and for
KEGG only the list of cited accessions confirmed current. It also writes
`marker-links.tsv` in this directory: the EC numbers the pinned NCBIfam release
gives each cited profile, and those dbCAN gives each cited CAZy family or
subfamily, derived from `hmm_PGAP.tsv` and from `cazy-subfamily-ec.tsv` and
`fam-substrate-mapping.tsv` above. A subfamily is listed with an EC number only
where at least half of its annotated members carry it. `kegg-ko-links.tsv`,
the orthologue-to-reaction, EC and module links from which marker `basis` is
derived, stays in the cache because KEGG content is not redistributed. Run the
script with `--sync` after changing any external accession, and with
`--offline` to reuse the cache. Deleting a cached download makes the next run
fetch it again, which is how the pin is moved to a newer release.

`chebi-anchor-aliases.tsv` and `chebi-anchor-alias-candidates.tsv` were
regenerated on 2026-10-04 after sixteen anchors moved to the ChEBI entity Rhea
writes in database 2026.38.1. For thirteen of them the identifier used before is now a derived alias, so
an external record keyed by it still finds the anchor. For `GTP`, `TMP` and
`QUINOLINATE` it is not: ChEBI relates the old and new entities by more than
one identity step or not at all, and the walk takes one step.
