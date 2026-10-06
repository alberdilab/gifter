# gifter package changelog

Code, public API, evaluation logic, and report changes. Newest first.
Timestamps are UTC.

**Biological database changes are not recorded here.** They live in the
database itself, as `inst/extdata/database-source/database_changes.tsv` and
`change_gifts.tsv`, linked to the GIFTs they affect. Read them with
`database_changelog()`, or open the Changes view of the HTML atlas. That
separation is deliberate: a biological decision is versioned with the content
it describes and travels with the compiled database, while a code decision is
versioned with the package.

---

### 2026-10-06T04:44Z — Document incomplete-genome behavior and analysis inputs

**What changed.** A case study now reads the committed gene-subsampling,
assessability and marker-context tables. The quantitative-traits tutorial
explains when a zero assessable denominator omits `supported_fraction`; the
single-genome guide shows how to inspect unmatched markers against pinned
annotation releases. The chicken case study names the source study's distillR
reading and reports a separately pinned gifter resource measurement.

**Why.** The manuscript contained measured behavior under genome
incompleteness and practical annotation and runtime limits that readers could
not yet find together in the documentation.

**Effect.** Documentation only. The case study states its database release and
simulation limits; no GIFT definition, evaluation rule, schema or public API
changes.

---

### 2026-10-06T04:34Z — Highlight case-study summaries

**What changed.** The three Case study articles now place their “In short”
findings in a shared summary box.

**Why.** The main findings should be easy to spot before the detailed analysis.

**Effect.** Documentation layout only; the findings and biological claims are
unchanged.

---

### 2026-10-06T04:20Z — Add phenotype validation as the final case study

**What changed.** The Case studies menu now ends with a page built from the
committed BacDive, MediaDive, Madin and annotation-route result tables. It
shows per-observation recall, disagreement traces, reference consistency and
the catalogue's testable coverage, with a link from the curation article. The
page distinguishes the 44 frame-only GIFTs from 44 independent assays: it
explains nutrient-level tests, alternative routes, conditional cofactor and
nitrogen results, and the one GIFT excluded by the KO-only annotation ceiling.

**Why.** The finished R9 analysis was present in the manuscript but its
results were not available from the documentation's Case studies.

**Effect.** Documentation only. The page identifies the pinned database
release and keeps encoded capability distinct from observed phenotype; no
GIFT definition, call or public API changes.

---

### 2026-10-06T02:32Z — Reanalyse the chicken MAGs with giftag and document the comparison

**What changed.** The verified 822-MAG giftag transfer was evaluated across
the 388 chicken samples against database 2026.39.1. The comparison now reads
the locked MAG manifest so a genome with no supported GIFT remains in the
per-genome denominator. Committed result tables cover call and marker
concordance, sample metrics, age contrasts and annotation resources. The
chicken case-study article reports those results beside the original Drakkar
reading, with both database releases named.

**Why.** A positive-call table omits a zero-call MAG, and the original article
predated the completed giftag annotation. The two annotators must be compared
on the same database without treating concordance as accuracy or handoff
topology as observed exchange.

**Effect.** Documentation and analysis outputs change; no database source,
GIFT definition, package evaluation rule or public API changes. The original
Drakkar case-study results remain pinned to their earlier release.

---

### 2026-10-06T01:47Z — Document the chicken caecal case study

**What changed.** The Case studies menu now links a chicken caecal article
built from the committed R10 result tables. It shows sample-level age
patterns, classifications across all 19 curated frames, the MAG behind the
richness split, exact extracellular handoffs and the later GTDB genome-size
comparison. Figures render from the analysis outputs at site-build time. Both
case studies now use working article cross-links and figure zoom links.

**Why.** The completed 822-MAG, 388-sample analysis was available in the
manuscript and analysis scripts but lacked a documentation entry like the
phylogeny study.

**Effect.** Documentation only. The article keeps the original and later
database releases separate and states the operational detection and evidence
limits. No GIFT call, biological definition or public API changes.

---

### 2026-10-05T15:23Z — Route diagrams open source records

**What changed.** ChEBI links now use the literal-colon record URL, and reaction
and boundary nodes in the atlas route diagrams open their Rhea and ChEBI
records. Linked nodes show an external-link cue and remain keyboard accessible.

**Why.** ChEBI returns 404 for the encoded-colon URL, and route diagrams showed
identifiers without links.

**Effect.** Atlas navigation only. No biological definition, call, source table,
schema or public API changes.

---

### 2026-10-05T14:39Z — Catalogue statistics and reference links follow the database

**What changed.** A successful database rebuild now refreshes the README's
catalogue counts from the compiled SQLite database, and CI checks the counts
before publishing documentation. The atlas links declared ChEBI anchors and
raw table IDs to their compound or reaction records, and uses the same
record-link helper for Rhea reactions.

**Why.** The README's 153-GIFT count lagged behind the current 163-GIFT
catalogue. ChEBI identifiers in the atlas appeared only as tooltip text.

**Effect.** Documentation and atlas navigation only. No biological definitions,
calls, source tables, schema or public API changed.

---

### 2026-10-05T05:05Z — Historical curation evidence is audited retrospectively

**What changed.** A repository-only audit script counts the documents, analysis
scripts and result tables linked to expansion attempts and their GIFTs. The
attempt log now reports its results and explains two older decisions in detail:
the initial nucleotide boundaries and the organic-acid screen. The initial
nucleotide attempt links its existing source rationale directly, and the
organic-acid proposal carries a dated literature-based qualification of its
lactate-direction argument.

**Why.** Every GIFT has a curation document, but most early screens lack retained
code and result tables. A documented historical number and a reproducible
analysis must be distinguishable. Experimental evidence also shows that the
NAD-dependent lactate dehydrogenase can oxidize lactate under some conditions.

**Effect.** Documentation and audit tooling only. No GIFT definition, call,
database source table, schema or public API changes.

---

### 2026-10-05T04:35Z — Each database change has its own page in the atlas

**What changed.** The Changes view of the atlas is now a table that indexes the
changes, and each change opens on its own page at `#changelog/<change_id>`,
showing its release, timestamp, scope, call effect, rationale, evidence, effect
and affected GIFTs. The expanding "Why, evidence and effect" box is gone from
the table and from the change history on a GIFT page, which links to the
change's page instead. A GIFT identifier in a table row still opens that GIFT.

**Why.** Rationale, evidence and effect are paragraphs, and unfolding them
inside a table cell made them hard to read and impossible to link to. Frames
and expansion attempts already had a page each; changes now follow the same
pattern.

**Effect.** Atlas presentation only. A change can be cited by URL. No database
content, call, schema or public function signature changes.

---

### 2026-10-05T03:24Z — The documentation gains a Case studies section, starting with the phylogeny

**What changed.** The site has a new "Case studies" menu after Workflows, and
its first page, `vignettes/articles/phylogeny.Rmd`, presents the 696-genome
GTDB panel: the panel, the calls beside the tree, the genome-size expectation,
deviations by lineage, classes of GIFT against size, phylogenetic signal per
GIFT, origin groups and near misses. The page evaluates nothing. Every number
and figure is read at build time from the tables under
`manuscript/analysis/output/` and `manuscript/analysis/gtdb-phylogeny/`, and
the figures are drawn for the web at 300 dpi, each linking to its
full-resolution file. `vignettes/articles/` is excluded from the package build,
and the site build now needs ggplot2, patchwork, ape and ragg
(`Config/Needs/website`).

The curation guide gains a section, "Refine the catalogue iteratively",
describing how unsupported calls on a broad panel become logged leads, go
through the full curation process and are re-evaluated with the next database
release. It restates existing rules and adds none.

**Why.** The workflows teach the API on small fixtures. The case studies show
what the same calls return on real genomes at scale, which a vignette that must
run at `R CMD check` cannot do.

**Effect.** Documentation only. No package code, database content or analysis
output changed. The host-associated and environmental case studies are still to
be written.

---

### 2026-10-04T16:37Z — Chicken per-MAG repertoire is read against the GTDB size expectation

**What changed.** A new manuscript analysis, `31-r10-size-expectation.R`, gives
each of the 822 chicken caecal MAGs a size expectation fitted to the GTDB panel
for every reference frame, and splits each sample's mean per-MAG richness
exactly into the mean expected from the sizes of its detected MAGs and the mean
deviation from it. The R10 age model is fitted to each part. A second partition
replaces each MAG by the mean of its taxon, from phylum to genus. The MAGs are
evaluated again against database 2026.37.1, the one the GTDB panel used; the
audited R10 outputs are not rewritten. It writes eight tables and Figure S19.

**Why.** Repertoire size follows genome size across GTDB, so the fall in
per-MAG repertoire with age could be smaller genomes replacing larger ones and
nothing else.

**Effect.** Genome size reproduces about two thirds of the fall (63% at day 21
and 66% at day 35), and 80% among MAGs at least 90% complete; the mean
estimated genome size of detected MAGs falls by 0.40 Mb by day 35. A negative
deviation remains in every variant at the three positive detection thresholds.
Amino-acid, biomass-essential and vitamin frames fall about twice as far as
size predicts, fermentation-product and short-chain-fatty-acid frames far more
than it predicts, and cofactor autonomy as far as it predicts. Turnover between
phyla or classes carries under a tenth of the fall and turnover between orders
four fifths. The deviation rises with MAG completeness, so its size is an upper
bound on a biological effect. No call, package API or database content changes.

## Unreleased

### 2026-10-05T04:08Z — R10 gifter resource benchmark

**What changed.** A reproducible analysis script measures input loading,
genome evaluation, dataset assembly, sample traits, and the sample network for
the checksum-verified 822-MAG, 388-sample R10 case. It records stage and total
wall time, CPU time, and sampled peak resident memory in a fresh process.

**Why.** The manuscript needs a technical account of gifter's computational
cost on a realistic catalogue. Annotation and gifter evaluation have different
inputs and resource scopes, so their measurements are reported separately.

**Effect.** The 822-MAG × 388-sample gifter portion took 1,366 s wall time
and peaked at 3.85 GB sampled RSS with one worker. Eight workers reduced wall
time to 852 s, with greater total CPU time; aggregate worker memory was
unavailable in this sandbox. Both runs yielded the same 23,657 supported
genome-GIFT calls. The measurement changes no GIFT call, database content,
schema, or package API.

### 2026-10-05T03:01Z — Chicken giftag rerun and Drakkar resource audit

**What changed.** The R10 analysis accepts checksum-verified giftag marker
tables and writes their results and Figure 7 to separate directories. A
Mjolnir job verifies the original 822 MAG FASTAs, annotates them with giftag
0.2.0, measures wall time, CPU time and memory, and prepares a verified
transfer. Separate scripts compare marker presence, genome-GIFT calls and
sample metrics after both annotations are evaluated against the same current
gifter database. The original Drakkar log is linked to all 5,784 Slurm job
records, including failed attempts and retries.

**Why.** The chicken study provides a realistic nucleotide-input workload for
measuring giftag's practical annotation speed against the completed Drakkar
workflow. Matching MAGs and the gifter marker vocabulary make the timing and
output comparison interpretable.

**Effect.** The original Drakkar analysis and Figure 7 remain available. The
current-database Drakkar reevaluation completed in isolated outputs; the full
giftag run is in progress, so no final speed or call-concordance result is
asserted here. No biological
database, schema, package API or GIFT definition changed.

### 2026-10-04T17:39Z — Marker basis is derived for NCBIfam and CAZy, and NCBIfam grades are checked

**What changed.** `.derive_marker_basis()` now covers NCBIfam profiles and CAZy
markers on enzyme components as well as KOs, comparing the EC numbers the pinned
NCBIfam release or dbCAN gives a marker with those of its reaction. The
`kegg_links` argument of `validate_gifter_sources()` and
`build_gifter_database()`, added earlier today and never released, is now
`marker_links` and takes several extracts. The reference snapshot gains
`marker-accessions.tsv`, and the reference check refuses an NCBIfam or CAZy
accession absent from the pinned release and an NCBIfam grade that differs from
the one the release gives. `data-raw/verify_database.R` passes the committed
`data-raw/reference/marker-links.tsv`, so CI recomputes these two namespaces.

**Why.** Only KO assignments had a derivation, which left 911 of 1,714 marker
assignments unassessed, and the NCBIfam admission rule read a grade the curator
typed into `notes`.

**Effect.** 307 assignments remain unassessed, all of them machinery markers or
Pfam, EC and legacy TIGRFAM rows. All 145 declared NCBIfam grades match the
release. Ten assignments are newly `unsupported`; the database changelog for
2026.39.1 records them. No GIFT call changes.

### 2026-10-04T16:32Z — Curated facts are verified against a pinned reference snapshot

**What changed.** `validate_gifter_sources()` and `build_gifter_database()`
take `reference_dir` and `marker_links`. With a reference directory the source
tables are compared with a pinned extract of Rhea, ChEBI and KEGG held in
`inst/extdata/reference-snapshot`, in the new `R/reference-verification.R`.
`data-raw/reference_snapshot.R` writes that extract and, with `--sync`, fills
the imported and derived source columns. `data-raw/build_database.R` and
`data-raw/verify_database.R` always pass the snapshot. The schema is version 9
and the package opens versions 7, 8 and 9. Independently of any snapshot, the
validator now refuses a `confidence`, `evidence_type` or `basis` outside its
vocabulary, a malformed `reference`, and an `unsupported` marker assignment
recorded above `putative`.

**Why.** Validation was relational only: 49 checks that the tables agreed with
each other and none that an accession existed or that a Rhea identifier was a
master. An audit of the shipped tables against the live resources found no
invented identifier, and did find three non-master Rhea identifiers, seven KEGG
reaction cross-references naming a different or partial reaction, four route
steps oriented against their route, and thirty marker assignments recorded as
curated that KEGG does not support. Every one had compiled cleanly. The
content corrections are recorded in the database changelog for 2026.38.1.

**Effect.** A wrong external fact now fails the build with the record that
contradicts it. No GIFT call changes. `evidence_confidence` falls to `putative`
where one of the thirty unsupported assignments is the best evidence for a
component. No public accessor reads the new columns or tables yet. Three limits
remain and are stated in the architecture guide: the basis derivation covers
only KO markers on enzyme components; the KEGG links it reads are not
redistributed, so CI checks that a basis is recorded but cannot recompute it;
and `gift_reviews.tsv`, the human sign-off, is empty.

### 2026-10-04T15:28Z — GTDB near misses are read by which step is missing

**What changed.** A new manuscript analysis, `30-gtdb-near-miss-steps.R`,
measures for each implementation how concentrated the missing requirement is
over its near-miss genomes, and whether the requirements present are specific
to the GIFT or shared with another GIFT through a reaction, function or marker.
Requirement and marker sharing is read from the database source tables. It
writes three tables and Figure S18.

**Why.** The same step missing everywhere means a correct refusal when the
steps present are shared with other GIFTs, and a curation candidate when they
are specific to the GIFT. Counting near misses alone could not tell these apart.

**Effect.** Of 11,736 near misses, 47% lack the same step while GIFT-specific
steps are present, 29% lack a varying step, and 23% have only shared steps
present. The first group is a ranked list of curation candidates. The sharing
rule does not detect a marker that is biologically broad but accepted once. No
call, package API or database content changes.

### 2026-10-04T15:15Z — GTDB near misses, per-GIFT phylogenetic signal and a quality check

**What changed.** `26-gtdb-repertoire-genome-size.R` now repeats the phylum
reading of the size deviation on isolates only, on genomes of high CheckM2
quality, and with completeness and metagenome origin in the expectation; it
writes `gtdb-size-expectation-sensitivity.tsv` and adds a panel to Figure S10.
A new analysis, `29-gtdb-near-misses-and-gift-signal.R`, counts unsupported
GIFTs whose closest implementation lacks exactly one of at least two
requirements, ranks the requirements most often missing alone by lineage, and
computes Fritz and Purvis's D for each GIFT. It writes six tables and Figures
S16 and S17.

**Why.** Assembly quality shifts the size deviation, so the taxon results
needed a robustness check. The call table already records what each
unsupported GIFT lacks, which separates a lineage that lacks a capability from
a catalogue that lacks the lineage's alternative.

**Effect.** Eight of the eleven deviating phyla keep their direction and
significance under every quality variant in which they can be tested;
Acidobacteriota, Campylobacterota and Chloroflexota each lose significance in
at least one. One in
seven unsupported calls is a near miss, and the most frequent are committing
steps correctly refused. Anabolic GIFTs are more phylogenetically conserved
than catabolic ones. A near miss is never counted as support; no call, package
API or database content changes.

### 2026-10-04T15:05Z — GTDB repertoire is read against origin and assembly annotations

**What changed.** A new manuscript analysis, `28-gtdb-origin-and-annotations.R`,
relates the panel's nonexclusive origin tags and its assembly annotations to
genome size, repertoire size, the size deviation, classes of GIFT and
individual GIFTs. Genome-level and class-level models are phylogenetic
regressions with Pagel's lambda on the pruned GTDB tree; the per-GIFT screen is
Fisher's exact test and is labelled as unadjusted. It writes five tables and
Figures S13 to S15.

**Why.** The panel was built with origin and provenance metadata, and the size
deviation is phylogenetically clustered, so origin effects have to be read
after phylogeny and assembly quality are accounted for.

**Effect.** Few origin effects survive the phylogenetic correction: 11 of 288
origin and class pairs, against 322 of 1,680 unadjusted origin and GIFT pairs.
Metagenome-derived assemblies and lower CheckM2 completeness are associated
with fewer supported GIFTs than size predicts. No call, package API or database
content changes.

### 2026-10-04T14:30Z — GTDB size deviation: phylogenetic signal and GIFT classes

**What changed.** A new manuscript analysis,
`27-gtdb-size-signal-and-gift-classes.R`, measures the phylogenetic signal of
each genome's deviation from the size expectation (Pagel's lambda, Blomberg's K
and a Moran's I correlogram over patristic distance on the pruned GTDB tree),
and the association of genome size with the supported count in each class of
GIFT and with each GIFT. Classes are resolved from `gift_type`, `mode` and the
`physiological_role` and `substrate_class` facets through `list_facets()` and
`gifts_by_facet()`. It writes five tables and Figures S11 and S12.

**Why.** The size deviation differed between phyla, which raised whether it is
phylogenetically structured and whether the size trend is carried by particular
kinds of capability.

**Effect.** The deviation carries strong phylogenetic signal (lambda 0.94,
K 0.71), concentrated among close relatives. Catabolic and carbon-acquisition
GIFTs follow genome size most closely; structural, fermentative-end-product and
aromatic-ring-catabolism GIFTs least. No call, package API or database content
changes.

### 2026-10-04T14:18Z — GTDB repertoire size is read against genome size

**What changed.** A new manuscript analysis, `26-gtdb-repertoire-genome-size.R`,
reads the calls from `23-gtdb-phylogeny.R` and fits a smooth quasi-binomial
expectation of the supported share of the catalogue given log assembly size.
It writes each genome's deviation with a standardised residual and a
Benjamini-Hochberg-adjusted test, phylum and class summaries with a Wilcoxon
signed-rank test, the model record, and Figures S9 and S10.

**Why.** Repertoire size rises with genome size, so a raw count cannot say
which genomes or taxa encode more or fewer curated capabilities than their size
predicts.

**Effect.** No genome departs from the expectation at a false discovery rate of
0.05; 11 of 16 phyla and 14 of 24 classes with at least five genomes do. The
tests treat genomes as independent and are a screen, not a phylogenetically
corrected estimate. No call, package API or database content changes.

### 2026-10-04T13:31Z — Link giftag annotation to gifter evaluation

**What changed.** The website's Workflows menu, README, and first evaluation
guide link to giftag's new documentation and its marker-table handoff.

**Why.** A user starting from FASTA needs a path to produce gifter's input and
to review marker search coverage before interpreting missing evidence.

**Effect.** Documentation and navigation only. GIFT definitions, evaluation
logic, database content, and calls are unchanged.

### 2026-10-04T13:21Z — GTDB phylogeny panel is 696 genomes

**What changed.** `23-gtdb-phylogeny.R --prepare` now removes the genomes
listed in the committed `gtdb-phylogeny/excluded-genomes.tsv` after selection,
without replacement, and stops if a removal would drop a GTDB order. The locked
manifest, tree, selection audit and origin summary therefore describe 696
genomes, and the final analysis requires 696. It also checks that the
transferred Mjolnir manifest minus the transferred exclusion record is exactly
the committed panel. On Mjolnir, `run-drakkar-included.sh` resumes Drakkar on
the selected genomes minus the exclusion record, and `prepare-transfer.sh`
expects that count and ships the record. The manuscript, session notes and
analysis READMEs state 696 throughout. Figure S4 now wraps its subtitle and
caption, collects its legends and abbreviates the non-metabolic type labels,
which were clipped or overlapping. It also names the major phyla beside the
phylum strip and adds a panel with the mean and standard deviation of assembly
size over all GTDB R232 genomes of the species each row represents, read from
the new `species-genome-size.tsv` that `--prepare` writes.

**Why.** KOfam annotation of `GCA_002285495.1` failed all eight attempts across
two Drakkar runs for a cause that was not established. Evaluating it without
KEGG evidence would show unsupported GIFTs that are an annotation gap, so it is
removed rather than called. Stating one panel size everywhere is simpler than
carrying a selected and an analysed count.

**Effect.** Every count and denominator in the GTDB overview is 696. All 49
phyla, 120 classes and 321 orders remain; the food/fermentation group holds 84
of its 85 eligible genomes. No package API, biological database content or
call changes.

### 2026-10-04T11:41Z — Python curation scripts can be indexed as GIFT evidence

**What changed.** Source validation accepts `.py` analysis scripts in
`gift_evidence.tsv`, alongside `.R` scripts.

**Why.** The reproducible serine-deamination marker audit is written in Python;
its script must travel with the GIFT's curation documents and result tables.

**Effect.** Curation provenance only. Evaluation logic and the database schema
are unchanged. The biological marker correction is recorded in
`database_changes.tsv`.

### 2026-10-04T03:51Z — Atlas shows the class of every GIFT type

**What changed.** The GIFT table and detail header now read the required class
facet for metabolic, structural, regulatory and defense GIFTs. Regulatory and
defense classes appear where the atlas previously showed a dash.

**Why.** Every GIFT already carries exactly one class facet for its type, but the
report lookup only read `substrate_class` and `structural_class`.

**Effect.** Presentation only. Class assignments and Boolean calls are unchanged.

### 2026-10-04T03:20Z — Expansion attempts view under the Curation menu

**What changed.** The atlas gains an Expansion attempts view (`#attempts`),
reached from the Curation menu of both the atlas and the pkgdown site. It
renders `inst/doc/catalogue-expansion-attempts.tsv` as shipped with the
installed package: totals of attempts, implemented GIFTs, deferred candidates
and refused claims; an outcome filter; and a table with one row per attempt
(scope, period, GIFT types, outcome counts, result). Each attempt has its own
page at `#attempts/<attempt_id>` listing the implemented GIFTs as links to their
atlas pages, the deferred and refused candidates, every candidate considered,
the attempts it revisits and is revisited by, and its source documents linked
to the repository at the release commit. Breadcrumbs now name the menu a view
belongs to, so this view reads gifter > Curation > Expansion attempts. In both
menus the entry sits below a "History" separator. The curation article, the
architecture guide, the deferral register, the structural proposal and the
attempt-log guide now send readers to this view instead of the raw TSV; only
instructions naming the file a curator edits still give its path.

**Why.** Refusals and deferrals are curation results, but they were only
discoverable by opening a TSV in the repository. The atlas already indexed
GIFTs and frames as browsable tables; the investigation history now has the
same form, with the full argument left in the linked documents.

**Effect.** Presentation only. The attempt log is read as a package document,
not compiled into SQLite, so no schema, database content or call changes. An
implemented GIFT that the rendered database does not contain is shown without
a link.

### 2026-10-04T02:00Z — GTDB phylogeny heatmap is ready for the Drakkar transfer

**What changed.** The locked 697-genome GTDB R11-RS232 analysis now validates
the exact Drakkar 2.6.6 marker, manifest and per-source QC contracts before
evaluation; caches genome calls by the annotation and gifter-database
checksums; evaluates with configurable parallel workers; and retains best
implementations, missing requirements, supporting components, markers and
genes in its call table. Figure S4 aligns the pruned bac120 tree with a phylum
strip, every current GIFT grouped by type, and per-genome repertoire breadth.
The GIFT summary records the exact heatmap-column order.

**Why.** The annotation transfer is large and expensive to reevaluate, and the
phylogenetic overview must show all Boolean GIFT calls without losing their
evidence trail or mistaking incomplete implementations for fractional support.

**Effect.** Once the checksum-verified Mjolnir transfer arrives,
`23-gtdb-phylogeny.R` can run directly. The figure visualises phylogenetically
local differences in encoded functional breadth; it does not infer activity,
phenotype, gain/loss events or ancestral states. No package API or biological
database content changes.

### 2026-10-04T01:56Z — Atlas introduction, a single Atlas menu and breadcrumbs

**What changed.** The atlas now opens on an Introduction view (`#introduction`)
instead of Frames. It states what the atlas is, gives database-wide counts
(GIFTs, anchors, alternatives, systems, components, markers), a table of the
five evaluation layers for each GIFT type, distributions of metabolic modes,
anchor compartments and marker namespaces, a card for each atlas section, and
the release versions. The atlas sections are no longer a separate bar under the
header: the Atlas entry of the site navigation is a dropdown listing
Introduction, Frames, GIFTs and Changes, then Network overview, Data model and
Tables under an "Advanced" label. The pkgdown navbar carries the same dropdown,
linking to each view's hash. The database-wide counts moved from the Network
overview to the introduction, and the overview gained a page heading. Header
dropdowns now close on a click outside them, and on narrow screens they span the
navigation instead of overflowing the screen edge. Every documentation page
except the home page, and every atlas view, now shows a breadcrumb trail
(gifter → section → page, and the open GIFT or frame in the atlas) in a
rounded box 20px below the header and 20px above the page title, which brings
the title closer to the header than before. The home page has no trail and
keeps its spacing. The pkgdown
trail is built by `pkgdown/extra.js` from the navbar, so it follows
`_pkgdown.yml`.

**Why.** Landing on Frames dropped readers into the quantitative-trait chooser
before they knew what the database holds, and a second navigation bar under the
site header made the atlas look like a separate site.

**Effect.** Every number on the introduction is read from the compiled
database, so it follows the catalogue without edits. Links to `atlas/#frames`
and other existing views still resolve; `atlas/` alone now opens the
introduction. No call or database content changes. Tests in `test-database.R`
check the menu order, the landing view and that the per-type counts match the
database.

### 2026-10-03T12:20Z — Curation evidence and source links for every GIFT

**What changed.** Schema version 8 adds a `gift_evidence` source table and
`database_release.source_repository`. Each evidence row links a GIFT to a
repository file of one of three kinds: a curation document that defines and
defends it, an analysis script (R) run to decide it, or a result table that
script wrote. The new export `get_gift_evidence()` returns these with a `url` at
the commit the database was compiled from, or at the repository's default
branch for a development build. `gifter_db_version()` gains
`source_repository`. In the atlas, each GIFT page gains a "Curation evidence"
section with those links, and states when no analysis script is recorded.
Marker accessions, reaction cross-references and related pathways now link to
their public records (KEGG, CAZy, NCBIfam, Pfam, ENZYME, MetaCyc), and each
marker shows the source its acceptance was taken from.

**Why.** The atlas showed what each GIFT is but not where it was worked out or
which public records its identifiers come from. The trail from a definition to
the argument, the code and the numbers behind it existed only in the
catalogue-expansion log, outside the database, and the R code was not
reachable from the atlas at all.

**Effect.** The compiler validates the new table. A location must be a
relative repository path whose file type matches its kind, and the package
tests check that every location exists. The package reads schemas 7 and 8: a
schema 7 database reports no evidence and an `NA` repository, and its atlas says
so. No call changes, and a test confirms that removing all evidence leaves
every call unchanged. The atlas includes `gift_evidence` in its data model and
table browser when the database has it. The database change is
`DBC-20261003-GIFT-EVIDENCE` (database 2026.34.1). New tests are in
`test-gift-evidence.R`.

### 2026-10-03T11:20Z — Each GIFT has its own atlas page

**What changed.** A GIFT's detail no longer opens in a dialog over the
catalogue. Each GIFT has its own page at `#gifts/<gift_id>`, like the frame
pages: selecting a catalogue row, a frame's member row, a changelog GIFT link or
a network-overview dot opens it. The page is laid out on the page itself rather
than inside a box. A bar above it holds "All GIFTs" on the left and, on the
right, previous and next arrows with the position, which step through the GIFTs
the catalogue's current filters keep. The left and right arrow keys step too,
except while typing in a form control. The browser's back button returns to
the previous page, and typing a search on a GIFT page returns to the filtered
catalogue. Printing the atlas prints the catalogue and then every GIFT page.

**Why.** A page can be linked to, bookmarked and reached with the back button,
and the GIFT and frame views now behave the same way.

**Effect.** Report only. `.report_gift_explorer()` returns the catalogue
(`table`) and the pages (`pages`) separately. The dialog markup, styles and
focus handling are removed, and so is the Escape shortcut, which only closed
the dialog. Frame and GIFT pages share the `page-back`, `page-bar` and
`page-step` styles. `test-database.R` checks that there is one GIFT page per
catalogue row, in the same order, and that no dialog remains.

### 2026-10-03T10:40Z — GIFTs view introduction matches the Frames view

**What changed.** The GIFTs view is titled "GIFTs" instead of "Explore GIFTs".
The sentence beside the title is replaced by an introduction in the same layout
as the Frames view: a lead definition of a GIFT, four panels (GIFT types,
evaluation logic, boundaries and composition, reading the catalogue), and a
statement of what a positive call does not indicate. A "Catalogue" heading then
introduces the filters and the table. The per-type GIFT counts in the
introduction are read from the database. Frame pages now report "N GIFTs"
rather than "N current GIFTs".

**Why.** The two main views of the atlas should introduce their content in the
same way, and a reader opening the GIFTs view needs the completeness model
explained before the table is useful.

**Effect.** Report only. The introduction styles are shared as `view-*`
classes, which replace the former `frame-explainer`, `frame-lead`,
`frame-concepts`, `frame-caveat` and `frame-section-title`. `test-database.R`
checks the new title and that the type counts are rendered.

### 2026-10-03T09:30Z — Atlas frames as a table with a page per frame

**What changed.** The atlas Frames view lists the presets in one table — label
and identifier, what the frame covers, current GIFT count, analysis scales and
denominator — and each row opens that frame's own page at `#frames/<frame_id>`.
The page is laid out on the page itself rather than in a card, and carries
the preset call, recommended analyses, interpretation limits and membership
filters, followed by the frame's current member GIFTs in the same table layout
as the GIFTs view. Its rows are rendered from the same cells, and each opens
that GIFT's detail. The scale filters and global search
filter the table rows; typing a search on a frame page returns to the table.
Printing the atlas prints the table and then every frame page. The view is
titled "Frames" and names the concept a frame, with no "formally, a reference
frame" aside. Above the table, an introduction explains what a frame is: it is
defined by metadata rather than a list of GIFTs, it is either open or bounded
(the bounded presets are named from the database), it works at three analysis
scales, and you can use a preset, build your own or rely on the default set. It
ends by stating that a trait describes encoded capability, not activity or
phenotype.

**Why.** Nineteen cards in a two-column grid made the options hard to compare
at a glance; a table shows all of them at once, and a page per frame gives the
detail room and a stable link.

**Effect.** Report only. `.gifter_report_data()` gains `frame_members`, resolved
through `reference_frame(preset = ...)`; `.report_gift_explorer()` now also
returns each GIFT's table cells, and the script finds the GIFTs view's table
within that view, since frame pages carry GIFT tables of their own. `test-database.R` checks that table
rows and pages pair one to one, that a page lists exactly the preset's members,
and that every preset label is sentence case. The one preset label that was
not, `biomass_essential_anabolism`, is corrected in the database as
`DBC-20261003-FRAME-LABEL` (database 2026.33.2).

### 2026-10-03T09:00Z — Atlas changelog shows each change's category again

**What changed.** The Scope cell of the atlas Changes view now pairs a change's
`layer` with its `category` (`addition`, `clarification`, `correction`).

**Why.** When the GIFT `category` facet was renamed `substrate_class`, the
rename also caught the changelog renderer, which reads the change record's own
`category` column. That column has no `substrate_class`, so every row showed an
em dash after the layer, e.g. "gift —".

**Effect.** Report only; no GIFT call or database content changes.
`test-database.R` asserts the chip pairing and the absence of an empty category
chip.

### 2026-10-03T07:10Z — The shared-component rule, and a screen that measures what it predicts

**What changed.** `inst/doc/architecture.md` now states what one accession
accepted on two components means, as a three-way distinction: a fused protein
performing two roles of one machine, a shared protein serving two machines, or an
accession that cannot say which protein it matched. The first two are accepted
and the third is invariant 16. The rule carries a testable consequence — two
structural GIFTs sharing a component accession must each require a function the
other does not — and `test-structural.R` enforces it, together with a registry
assertion so that a new cross-GIFT accession cannot appear unexamined.
`data-raw/t2ss_prevalence.R` is the accompanying screen.

**Why.** The type II secretion system was blocked on this and nothing else. Its
peptidase is not a homologue of the type IVa pilus peptidase but the same enzyme,
so curating the apparatus required deciding what sharing means. Settling it as a
rule rather than per candidate also closed open question 1 of the structural
proposal, which had been waiting since the first structural release for a second
overlapping structural GIFT to exist. Three now do.

**Effect.** No public API changed. Structural GIFTs deliberately do not compose:
sharing is expressed by accepting the accession on each GIFT's own component row,
because a composition table would assert an overlap no evaluation reads, whereas
an anchor is a public biological interface. The screen measures the rule's
prediction and confirms it — requiring the shared peptidase costs 35 genomes out
of 1,571, while the other four functions separate the two machines by several
hundred genomes each way. The biological outcome, `type_ii_secretion_system` in
database 2026.33.1, is recorded in `database_changes.tsv` and
`inst/doc/proposal-structural-gifts.md` section 8.

### 2026-10-03T06:32Z — Documentation starts from analytical tasks and curated concepts

**What changed.** The package website navigation now presents Get started,
Workflows, Atlas, Curation, Glossary and API instead of the pkgdown-default
Reference and Articles labels. Two user-facing guides explain how a GIFT moves
from a candidate claim through completeness, marker-specificity review,
provenance and compilation, and define both analysis concepts and technical
database-generation terms including NCBIfam equivalogs, profile HMMs and
gathering thresholds. The atlas opens on Frames, shortens the navigation label
from Reference frames, and groups its network overview, data model and raw table
browser under Advanced without changing its visual theme.

**Why.** The former navigation exposed documentation formats rather than the
questions readers bring to gifter, and the compilation instructions were easier
to find than the biological curation procedure that must precede them.

**Effect.** Published URLs for existing workflows, the atlas and API reference
remain stable. Frames lead the analytical browsing path but continue to resolve
GIFTs dynamically from curated metadata; they do not store GIFT membership or
change completeness logic. No package API, biological content, schema or
database artifact changed.

### 2026-10-03T06:29Z — An environmental community complement is locked independently of calls

**What changed.** `25-r10-mfd.R` and `manuscript/analysis/r10-mfd/` add a
checksum-pinned Microflora Danica workflow. It maps the deposited
species-representative set one-to-one onto all 5,518 published 95% ANI
secondary clusters and locks 360 abundance-profiled samples before annotation:
45 spatially distributed, reliable-coordinate samples from each of eight exact
field, grassland, forest, greenspace, bog/fen, freshwater-sediment,
saltwater-sediment and wastewater classes. A staged Mjolnir workflow acquires
the 19.8 GB MAG archive, uses the existing Drakkar 2.6.6 environment and returns
a catalogue-filtered marker projection together with its full-input checksum,
the exact database artifact and all cluster, sample and source provenance. The
complete archive index exposes four files labelled `unknown_ilm_asm_binN.fa`
in place of four expected barcoded names. An explicit one-to-one crosswalk
records all four distinct matching bin numbers, including the three selected
representatives, and acquisition verifies every extracted FASTA against its
published genome length before annotation.

**Why.** The completed chicken analysis is host-associated and temporally
structured. A second example needs to exercise many samples across genuinely
different environmental communities without treating overlapping MAGs as
independent providers or selecting samples after seeing GIFT calls.

**Effect.** The planned reading is descriptive across six database-defined
reference frames and three detection thresholds. Published non-dereplicated
MAG abundances are summed by species cluster before they are attached to the
one representative. Detection, abundance, habitat and genome completeness
cannot change a call; cluster abundance does not establish accessory-trait
identity across strains, and no result is interpreted as activity, flux,
nitrification or ecological effect. No package API, evaluation behaviour,
biological source, compiled database or schema changed.

### 2026-10-03T05:48Z — An exact KO/NCBIfam screen resolves what the archaellum orthologies collect

**What changed.** `data-raw/archaellum_ncbifam_prevalence.R` fetches every
protein KEGG assigns to an archaellum orthology in the stored frame (5,093
sequences) and searches each one with the archaellum NCBIfam equivalogs and
with contrast profiles for the homologous archaeal pilus and bindosome
machinery and two Pfam families. It then evaluates the curated `archaellum`
hierarchy exactly as the source TSVs define it over the frame's KO assignments,
and runs five named reference genomes through `evaluate_gifts()`, stopping if
the two evaluators disagree. Seven aggregate tables are written to
`data-raw/reference/archaellum-*.tsv`.

**Why.** The screen that recommended the archaellum could not say what the 192
archaea carrying FlaI or FlaJ without an archaellum core encode, and assumed
archaeal type IV pili. Whether K07332 and K07333 may stay inside the
conjunction, and at what confidence, turns on that answer, so it had to be
measured protein by protein rather than read from KO definitions.

**Effect.** No package code or public API changed. Prevalence is reported
against the KEGG-hierarchy archaeal and bacterial denominators, never the
frame's genus-filtered `prokaryote` flag. Contrast profiles only identify
proteins and are never admitted as evidence. The biological outcome is the
`archaellum` GIFT in database 2026.32.1, recorded as
`DBC-20261003-ARCHAELLUM`.

### 2026-10-03T06:05Z — A reproducible marker-specificity screen for homologous secretion machines

**What changed.** `data-raw/secretion_system_prevalence.R` screens the type III
and type VI secretion candidates over the stored KEGG frame and writes four
aggregate tables to `data-raw/reference/`. It does three things no earlier
screen did. It measures marker specificity against a homologue directly, by
counting genomes that complete the flagellar export apparatus while supporting
no injectisome role and by searching whole control proteomes. It tests a KEGG
accession before accepting it, searching the proteins KEGG assigns to it against
the role's NCBIfam equivalog, so a system-named orthology is admitted on
evidence rather than on its name. And it carries named reference strains with
what each is established to encode, marking as `unverified` any strain whose
expectation was not checked.

**Why.** The standing refusal of both systems was that an unordered marker set
cannot establish system identity without gene-cluster context. That is two
claims, and only one of them — marker specificity — is required by the
completeness contract. Testing it needed a script, because the argument turns on
counts and profile searches rather than on reading definitions.

**Effect.** No package code or public API changed; the screen is curation
evidence, reproducible online and then re-runnable from the pinned cache with
`--offline`. The biological outcome, two structural GIFTs in database 2026.31.1,
is recorded in `database_changes.tsv` and
`inst/doc/proposal-structural-gifts.md` section 7. New tests in
`test-structural.R` assert the accessory TssJ function, the alternative TssA and
TssE orthologies, the refused `K11918`, the needle-or-Hrp-pilus alternative and,
in both directions, that flagellar and injectisome evidence do not substitute
for one another.

### 2026-10-03T05:01Z — R10 temporal results are resolved at curated frame scale

**What changed.** A checksum-pinned follow-up now reads all 19 named reference
frames from the database over the existing R10 calls. It models community
richness, mean per-MAG richness and bounded coverage separately, repeats the
reading across four detection thresholds and with ambiguous evidence withheld,
and uses equivalence tests to distinguish supported stability from a merely
nonsignificant contrast. Figure S5 and its source tables retain every frame's
database-derived GIFT membership. Figure S6 adds population-standardised
adjusted values and 95% confidence intervals across days 7, 21 and 35; an
internal assertion requires its two differences from day 7 to reproduce the
heatmap contrasts exactly. Figure S7 then selects the frames classified as
decreasing beyond the margin at both later ages, verifies that member-GIFT
carrier fractions sum exactly to the frame metric per sample, and presents the
six largest descriptive GIFT-level declines per frame while retaining every
member trajectory in its source tables. It adds no per-GIFT hypothesis tests.
Figure S8 repeats the frame analysis after summing per-GIFT abundance coverage,
with abundance closed over detected MAGs. All six focal associations retain a
negative direction and five remain beyond the one-GIFT margin; vitamin
biosynthesis at day 21 becomes magnitude-uncertain. Its source tables also
compare equal-weight carrier fractions with abundance-weighted carrier shares
for every detailed GIFT.

**Effect.** Fifteen frame-level community unions are stable within one GIFT and
two are invariant; aromatic catabolism and carbon acquisition remain
detection-sensitive. All bounded-frame community coverages stay within five
percentage points. Mean per-MAG repertoires decline beyond one GIFT for
amino-acid autonomy, combined biomass-essential anabolism and vitamin
biosynthesis at both later ages at the operational threshold; all six retain
their direction across detection thresholds and their larger-than-margin result
when ambiguous evidence is withheld, while their magnitude attenuates under
more permissive detection. Carbon acquisition at day 35 is age-associated but
its interval crosses the one-GIFT boundary, so its magnitude is uncertain.
Frames aggregate unchanged calls and do not become composite GIFTs; the result
is encoded capability distribution, not expression, activity or flux. No
package API, evaluation behaviour, biological source, compiled database or
schema changed.

### 2026-10-03T05:56Z — A GTDB-wide phylogenetic panel is locked before annotation

**What changed.** A checksum-pinned manuscript analysis now selects 697
bacterial species representatives from the official GTDB R11-RS232 bac120
tree. Eligibility requires NCBI `Complete Genome` assembly level and `full`
representation plus assignment to at least one reviewed origin group from the
raw isolation-source field. This retains 4,116 of the 12,094 genomes meeting
the assembly criteria. One phylogenetic medoid per each of 321 eligible orders
guarantees taxonomic breadth. The complete 85-genome food/fermentation group
defines the common target for every sufficiently large origin group, smaller
groups are retained exhaustively, and marginal rooted Faith phylogenetic
diversity decides among balance-compatible additions. Panel size is therefore
an outcome rather than a preset input. The committed manifest retains every
source tree accession, all GTDB ranks, BioSample and BioProject accessions,
available origin fields and assembly-quality metadata. Reviewable rules retain
the raw isolation-source text while assigning nonexclusive origin groups,
including separate animal- and plant-associated fields. Mjolnir acquisition,
Drakkar annotation, transfer verification and Figure S4 scripts are prepared,
and the run has been submitted. Genome acquisition records NCBI or ENA as the
source for every accession; the ENA assembly-FASTA endpoint is used only when a
pinned R232 GCA accession is absent from the current NCBI GenBank assembly
summary, with every downloaded FASTA checksum retained.

**Effect.** The future overview is fixed independently of annotations and GIFT
calls and preserves the identifiers needed for later origin-metadata
enrichment. The selected panel contains only classified origins, spans all 49
eligible phyla, 120 classes and 321 orders, and retains 52.6% of the
origin-classified eligible tree's rooted Faith diversity. All sufficiently
large groups contain 85 selected genomes except aquatic origin at 87 because of
unavoidable multi-label overlap; fungal, air/built-environment and algal groups
are exhaustive at 6, 49 and 51. It will describe encoded capabilities in a
deliberately phylogenetically and origin-balanced panel, not activity,
phenotype, ancestral state or population prevalence. No package API, evaluation
behaviour, biological source, compiled database or schema changed.

### 2026-10-03T03:49Z — R10 handoff claims are bounded and its richness modes resolved

**What changed.** A checksum-pinned follow-up now enumerates all three exact
extracellular handoff links in database 2026.30.1, separates provider and
recipient presence from their abundance coverage, repeats topology across four
detection thresholds and a high-confidence floor, and compares primary samples
with 499 random catalogue communities matched for detected-MAG count. A second
diagnostic defines the observed richness modes by their largest gap, screens
all 822 MAGs without a prespecified taxon, removes the selected driver in
silico, and renders Figure S3.

**Effect.** No reading supports increasing encoded handoff potential with age;
normalized compatibility instead declines, and the catalogue currently bounds
that statement to three extracellular links. Detection of *Escherichia coli*
MAG `cmag_510` at the operational 0.001 threshold exactly separates the 78
lower-richness from 310 upper-richness samples. The split disappears at lower
thresholds of zero and 10^-5, and contracts to four lower samples at 10^-4; it
is not described as two biological community states. These are
encoded compatibility and threshold-sensitivity results, not evidence of
exchange, cooperation, expression or activity. No package API, evaluation
behaviour, biological source, compiled database or schema changed.

### 2026-10-03T03:13Z — The R10 chicken case study is reproducible

**What changed.** The exact 822 bacterial MAGs from 388 chicken caecal samples
were checksum-verified, reannotated with Drakkar 2.6.6's gifter projection and
evaluated against database 2026.30.1. A committed analysis now produces the
input audit, marker counts, supported calls, bounded-frame gaps, detection and
confidence sensitivities, adjusted age contrasts, exact plant-fibre topology
summaries and Figure 7. The Mjolnir run uses a dedicated project/task layout
under `/projects/alberdilab/scratch/jpl786/` and the existing shared Drakkar
conda environment; it performs no Drakkar installation.

**Effect.** R10 now distinguishes stable community capability richness from a
declining mean encoded repertoire per detected MAG, while retaining the GIFTs,
genomes and anchors responsible for each result. The missing original breadth
matrix is explicit: 0.001 relative abundance is an operational figure
threshold backed by sensitivity analyses, not a reproduction of the source
study's detection rule. Completeness changes absence denominators only, and
network edges remain potential extracellular-anchor compatibilities rather
than observed interactions. No package API, evaluation behaviour, biological
source, compiled database or schema changed.

### 2026-10-02T19:44Z — A chemistry-specific LTA structure becomes callable

**What changed.** Database 2026.30.1 adds
`diglucosyl_diacylglycerol_anchored_lipoteichoic_acid` as one structural
architecture with separately required anchor synthesis, LtaA translocation and
LtaS polymerisation functions. Only three equivalog-grade NCBIfam profiles are
admitted; K03429 and K19005 remain diagnostic proxies rather than shortcuts.

**Effect.** A genome completes the GIFT only with all three resolved roles. The
call does not generalise to broad, Listeria-type, Bacillus-type or non-type-I
LTA, and the independently reassessed peptidoglycan sacculus remains deferred.
The schema and public API are unchanged; the full decision is recorded in
`DBC-20261002-GLC2DAG-LTA` inside the database changelog.

### 2026-10-02T13:32Z — Candidate-specific NCBIfam prevalence is reproducible

**What changed.** A curation-only screen now intersects the full stored KEGG
frame on every required wall-teichoic-acid KO and runs the two lineage-resolving
NCBIfam profiles on the exact KO-assigned polymerase sequences in that complete
candidate set. It retains aggregate results and an exhaustive 168-type TagF
marker audit under `data-raw/reference/` while keeping the per-genome matrix and
downloaded sequences in the ignored cache.

**Effect.** The Staphylococcus-type ribitol-WTA architecture is now measured at
48 marker-resolved genomes rather than left unquantified. The W23 architecture
remains at 22, and no equivalog separates the 168-type glycerol-WTA TagF from
the W23 non-WTA homologue. All three candidates remain deferred; no biological
database source, SQLite artifact, schema, package API or runtime call changed.

### 2026-10-02T11:29Z — The canonical LptA--G apparatus is a structural GIFT

**What changed.** Database 2026.28.1 adds
`lpt_lipopolysaccharide_export_apparatus`, represented by three jointly required
functions and seven component roles. Public catalogue, evaluation, trace,
changelog and atlas views expose the new structural capability through their
existing type-neutral interfaces.

**Effect.** A call requires the complete canonical LptB/C/F/G extractor, LptA
bridge and LptD/E translocon. It does not report lipopolysaccharide synthesis,
activity, phenotype or a generic outer membrane. The addition changes no schema
or API; the biological decision and marker evidence are recorded in
`DBC-20261002-LPT-APPARATUS` inside the database changelog.

### 2026-10-02T06:18Z — Catalogue expansion attempts become append-only and searchable

**What changed.** A repository-wide catalogue-expansion log now indexes every
recoverable prior effort, including successful, deferred, refused and
no-new-GIFT outcomes. The curation contract requires a new attempt row before
evidence work begins, a linked row for every re-investigation, and closure with
the exact implemented identifiers and all unresolved or rejected candidates.
Tests validate the log and require its completed attempts to account for every
currently curated GIFT.

**Effect.** A request to expand the catalogue now starts by searching one
chronological record and reading the linked evidence, rather than rediscovering
work scattered across proposals, the deferral register and database changes.
The log is curation-process documentation, not ontology or runtime evidence;
no GIFT, call, database release, schema, API or compiled artifact changes.

### 2026-10-02T04:02Z — The non-data-blocked manuscript core is reproducible

**What changed.** A new public-API analysis generates Figures 1–5 in PDF and
PNG form together with the exact purine evidence trace, reference-frame
metrics, community metrics and potential-handoff edge list behind their worked
examples. The manuscript now contains the corresponding R2, R4 and R5
walkthroughs, full curation and evaluation methods, figure captions, and
primary citations for the Background.

**Effect.** The figures and prose are pinned to database `2026.27.1` and
explicitly label their marker profiles and four-genome community as controlled
fixtures rather than empirical organisms or the undecided R10 case study.
Discussion, Conclusions and M6 remain open until R8 and R10 are resolved. No
package API, evaluation behaviour, biological source, compiled SQLite artifact
or schema changed.

### 2026-10-01T18:35Z — Validation is explicitly database-only and coverage is auditable

**What changed.** The biological-validation plan now limits this project to
existing phenotype/genome databases, deposited genomes and checksum-pinned
annotations. The prospective assay registry and flagellar TEM plan are archived
templates, not active work. A new R9 coverage runner pins the committed
BacDive/MediaDive and Madin results plus the SQLite database, expands
reaction-level observations to their GIFTs, and writes per-GIFT evidence,
coverage and summary tables.

**Effect.** At database `2026.27.1`, 17 GIFTs have individually
recall-usable public observations and 44 more are testable only through a
bounded anabolic-frame aggregate. `flagellar_apparatus` has related motility
context only; the three regulatory and five defense GIFTs have no admissible
public observation in these sources. A missing record is not an absence call,
and refused proxies—such as gelatin for collagen cleavage—remain visibly
refused. No laboratory observation, synthetic biological control, biological
database, SQLite artifact, schema, package API or runtime code changed.

### 2026-10-01T16:42Z — A future direct flagellar microscopy test is specified, not observed

**What changed.** The Priority 3 structural pilot now has a dated,
pre-registry specification for a direct PAO1 flagellar microscopy test. It
locks a negative-stain TEM endpoint, paired mid-exponential LB culture and grid
preparation, randomised blinded image scoring, three biological replicates and
an isogenic real `Delta fliC` loss-of-required-function control. It carries
forward the checksum-pinned PAO1 annotation manifest and `trace_gift()` output
without changing either.

**Effect.** A visible external filament would be a condition-specific structural
observation related to the full genomic GIFT, not proof of every curated
component, assembly in general, motility, rotation or a stator coupling ion.
No physical PAO1 parent/control pair, stock identity sequencing,
independently verified control, stock-specific annotation or microscopy data is
present, so no registry row, biological denominator or outcome exists. A
synthetic annotation deletion is explicitly excluded as a biological control.
No biological database, SQLite artifact, schema, package API or runtime code
changed.

### 2026-10-01T16:11Z — Priority 3 starts with a checksum-pinned structural candidate audit

**What changed.** The prospective analyses now include a narrow Priority 3
flagellar-apparatus candidate record and runner for the exact PAO1 assembly
`GCF_000006765.1`. The runner verifies the pre-recorded protein FASTA SHA-256,
derives the current all-required component contract from the pinned database,
applies the KOfam adaptive thresholds, and retains all marker hits, input/model
hashes and the component-level `trace_gift()` output.

**Effect.** The deposited PAO1 protein annotation completes the two curated
flagellar architectures, with the diderm architecture selected as best. This is
annotation evidence only for encoded structural machinery: it neither images
flagella nor establishes their assembly, ion coupling, motility, chemotaxis,
activity or phenotype. No protocol, strain-matched working stock, biological
replicate, or real independently verified required-function-loss control has
been locked, so no prospective registry row or biological denominator exists.
No biological database, SQLite artifact, schema, package API or runtime code
changed.

### 2026-10-01T16:00Z — A checksum-pinned matched isolate / MAG-like draft audit tests Priority 2

**What changed.** The prospective analyses now contain a candidate ascertainment
record and reproducible runner for one defensibly matched *E. coli* K-12 MG1655
pair: complete isolate assembly `GCA_000801205.1` and PacBio WGS run
`SRR1284073`, which share BioSample and BioProject. The runner verifies the
ENA raw-read and NCBI assembly checksums, then pins every source/profile/tool/database digest and version,
reannotates the exact isolate plus one deterministic, de-novo reassembled
MAG-like read-subset draft, and retains marker rows, calls and `trace_gift()`
output for every source. It also writes each call transition and executes
source-labelled fixed-annotation removal and assessability-contract checks.

**Effect.** A draft difference is reported only as an annotation/assembly
change—never as biological gain or loss. No actual MAG, bin, contaminated or
mixed input is created or interpreted as one genome, and the audit neither
measures MAG quality nor observes an assay, growth, activity, phenotype or
ecological outcome. The prior collagen evidence-stress exercise remains a
synthetic non-MAG test. No prospective registry, biological database, SQLite
artifact, schema, package API or runtime code changed.

### 2026-10-01T13:00Z — The Type I-E machinery contrast pins complete and partial architecture

**What changed.** The prospective analysis now contains an exact-assembly,
checksum-pinned KOfam audit of `type_i_e_crispr_cas_machinery`. It records the
curated five-component Cascade, fused Cas3 and accessory Cas1/Cas2 contract,
profile thresholds, individual hits and gene-level traces for MG1655 and the
incomplete-machinery type-material control *Alkalilimnicola ehrlichii* MLHE-1.

**Effect.** MG1655 completes the protein-only Type I-E architecture. MLHE-1
retains Cas1/Cas2, Cas3 and partial Cascade evidence, but lacks CasA and CasE;
the jointly required Cascade system and GIFT correctly remain incomplete. The
audit cannot detect a CRISPR array or establish interference, defence, activity
or phenotype. It is not a prospective outcome and changes no registry,
biological database, SQLite artifact, schema or package API.

### 2026-10-01T12:30Z — The starch-specificity audit exposes broad-family route completion

**What changed.** The prospective analysis now contains an exact-assembly,
checksum-pinned KOfam/dbCAN audit of `starch_degradation`. It records the
curated two-reaction route, profile thresholds, individual hits and gene-level
traces for a *Bacillus licheniformis* DSM 13 resolving-evidence candidate and a
*Hydrogenobacter thermophilus* TK-6 broad-family control; a contaminated
one-`GH13` candidate is explicitly excluded.

**Effect.** TK-6's broad `GH13` and `GH57` hits currently complete the named
starch GIFT at ambiguous confidence even though no resolving marker supports
either required reaction. The audit makes that curation failure reviewable and
states that generic CAZy/family evidence cannot support the named substrate
claim. It is not an activity, growth, polymer-degradation or phenotype result;
no prospective registry, biological database, SQLite artifact, schema or
package API changed.

### 2026-10-01T08:28Z — The Tar specificity contrast has exact candidate assemblies and traces

**What changed.** The prospective analysis now records a strain-matched MG1655
candidate, a PAO1 generic-MCP control, a checksum-pinned seven-profile KOfam
audit and both regulatory GIFT traces. The exact audit completes the
Tar-dependent aspartate circuit in MG1655, while PAO1 completes the generic
chemotaxis core but lacks Tar and remains one required function short.

**Effect.** Broad MCP evidence is demonstrably insufficient for the
ligand-specific claim even in a complete core circuit. The historical response
studies and this genomic audit remain selection/evidence records only: no
receptor assay, phenotype, prospective result, biological database, schema,
SQLite artifact or package API changed.

### 2026-10-01T08:22Z — Candidate M9 evidence loss and mixing are explicit

**What changed.** The prospective analysis now stress-tests the exact collagen
candidate annotation rows under one-gene loss, complete M9-evidence loss, and a
deliberately labelled PAO1/*Hathewaya* evidence mixture. It retains the full
gifter trace for each input rather than reducing the mixed result to a PAO1
label.

**Effect.** The expected alternative-marker OR logic is demonstrated, and the
synthetic mixture visibly completes only because it carries foreign M9 evidence.
It is not a MAG experiment, phenotype observation, prospective-study result or
database change; package API, schema, biological source and SQLite artifact are
unchanged.

### 2026-10-01T08:06Z — The first collagen specificity contrast is checksum-pinned and re-annotated

**What changed.** The prospective-analysis record now contains a small runner,
exact NCBI protein-input manifest, input hashes, marker-hit table and gene-level
gifter traces for the two Priority 1 collagen candidates. It reruns KOfam
`K01387` at its adaptive threshold and Pfam `PF01752` at its gathering threshold
against the exact assemblies. The *Hathewaya histolytica* candidate completes
the M9 route; PAO1 does not, while its exact FASTA identifies the deliberately
separate LasB broad-protease control.

**Effect.** The planned genomic marker contrast is independently reproducible
without promoting LasB, a generic protease, or a historical phenotype into a
collagen call. These are candidate annotation-audit records only: no wet-lab
observation, prospective registry result, GIFT marker, database, schema, SQLite
artifact or package API changed.

### 2026-10-01T07:48Z — Priority 1 collagen candidate ascertainment starts without scoring historical data

**What changed.** The prospective-analysis record now has an assay-first,
strain-matched candidate roster for the collagen-specificity challenge. It
admits the type-strain-linked *Hathewaya histolytica* M9 candidate and PAO1 as
a broad-LasB marker control, while documenting why a published *Vibrio*
observation cannot be joined to a different strain's genome. A pre-existing
annotation-cache call is recorded only as an excluded audit.

**Effect.** The work starts the biological analysis without mistaking literature
selection evidence, denatured-collagen observations, or unversioned cached
annotations for prospective results. No GIFT call, marker, database, schema,
SQLite artifact or package API changes.

### 2026-10-01T07:30Z — Prospective biological validation has a locked, traceable analysis contract

**What changed.** The manuscript analyses now include a version-pinned
prospective-study registry, empty input templates and a runner for deposited
strain annotations and assay observations. It checks the protocol lock,
assembly and annotation provenance, biological replicate, assay conditions,
observation/claim relation and exact database release; evaluates samples
separately; and writes GIFT or reaction traces to genes.

**Effect.** Prospective observations stay distinct from the committed
retrospective analyses. The runner reports the planned asymmetric counts,
denominators, lineages and broad-marker-only control count, while refusing
planned or post-lock-inconsistent data. It does not add a package API, change
any GIFT definition, call, database, schema or SQLite artifact, and does not
compute accuracy, precision, F1, AUC or a catalogue-wide score.

### 2026-10-01T06:15Z — CI uses maintained Actions runtime and a stable Ubuntu image

**The problem.** GitHub Actions has removed Node 20 and is moving the
`ubuntu-latest` label from Ubuntu 24.04 to Ubuntu 26.04. The check-artifact
upload still used the Node-20 `actions/upload-artifact@v4` line, and the
current-R, database-reproducibility and pkgdown jobs would otherwise change OS
during that rollout.

**What changed.** Check-result uploads now use `actions/upload-artifact@v7`,
which runs on Node 24. The Linux release-R matrix entry, database
reproducibility job, and pkgdown build and deploy jobs are pinned to
`ubuntu-24.04`; the supported R 4.1 matrix entry remains on `ubuntu-22.04`.

**Effect.** CI keeps the same R-version/platform coverage and artifact inputs
while avoiding the retired JavaScript runtime and an untested Ubuntu 26.04
transition. Package code, biological content, database, SQLite artifact,
schema, licensing statuses, release metadata, DOI and deployments are
unchanged.

### 2026-10-01T05:53Z — Human redistribution review is evidence-backed without legal clearance

**What changed.** `inst/doc/licensing-review.md` records public primary-source
evidence and the exact gifter inventory for each unresolved KEGG, dbCAN/CAZy,
InterPro-member, NCBIfam/TIGRFAM and MetaCyc/BioCyc review. The data-licensing
statement and release checklist now point to that dossier. The checklist also
records the separate GitHub Actions maintenance warnings for
`actions/upload-artifact@v4` and `ubuntu-latest`.

**Effect.** No upstream row is cleared; no database content, SQLite artifact,
schema, package API, release metadata, DOI, tag or external service changed.
The dossier makes the next human permission, terms-interpretation, removal or
replacement decision reviewable without treating public access as permission.

## 0.7.3 — 2026-10-01

### 2026-10-01T05:10Z — Interaction-type refusal is tested across supported R versions

**The problem.** R 4.1 and current R use different connective wording in the
base `match.arg()` error for an unsupported community interaction type. The
test asserted the newer full phrase even though both errors name the same sole
accepted value.

**What changed.** The refusal test now matches the stable
`metabolic_handoff` value rather than version-specific base-R prose.

**Effect.** The supported R 4.1 lane tests the same API refusal without making
base error wording part of gifter's contract. Runtime behavior, the database,
biological content, API and completeness models are unchanged from 0.7.2.

## 0.7.2 — 2026-10-01

### 2026-10-01T04:37Z — The Windows fallback test retains its evaluated result

**The problem.** The 0.7.1 Windows check correctly observed the documented
sequential-fallback warning, but that runner's testthat version returned
`NULL` from `expect_warning()`. The assertion then compared `NULL` rather than
the successful community evaluation with the one-worker result.

**What changed.** The test now assigns the evaluation inside the warning
expectation, so warning verification cannot discard the value being tested.

**Effect.** Windows checks exercise both the fallback warning and identical
calls. Runtime behavior, the database, biological content, API and completeness
models are unchanged from 0.7.1.

## 0.7.1 — 2026-10-01

### 2026-10-01T03:52Z — Community evaluation checks are portable to Windows

**The problem.** The first post-release Windows check exercised fork-only test
expectations on a platform where `evaluate_gifts_community()` deliberately
falls back to sequential evaluation. It also exposed that the immutable SQLite
snapshot was unlinked before its read-only connection was closed, which Unix
permits but Windows refuses.

**What changed.** Snapshot teardown now closes its connection before removing
the temporary database. Fork-specific tests skip or use their sequential
equivalent on Windows, while the worker-equivalence test explicitly verifies
the documented fallback warning and identical calls.

**Effect.** Community evaluation retains the same calls, ordering and evidence
on every platform, and its temporary database is removed after success, error
or interruption on Windows as well as Unix. The released package archive,
database artifact, biological content, API, tag and checksums are unchanged.

### 2026-10-01T03:26Z — Database CI declares its verifier prerequisites

**The problem.** The first post-release database-reproducibility job installed
gifter and its check dependencies, but the standalone verifier also loads the
source tree through `devtools`, which was not part of that bootstrap set. Once
installed, the verifier correctly refused the default one-commit shallow clone
because it could not resolve the earlier commit recorded by the database.

**What changed.** The database CI job now requests `devtools` explicitly and
checks out full Git history before running `data-raw/verify_database.R`.

**Effect.** A fresh runner can execute the same non-mutating 41-table comparison
used locally and prove that the database's source commit exists and contains
the compiled inputs. The released package archive, database artifact,
biological content, API, tag and checksums are unchanged.

## 0.7.0 — 2026-10-01

### 2026-10-01T02:17Z — Citation and data terms are visible, including unresolved blockers

**The problem.** The software licence could be read as covering the compiled
biological database, there was no package citation or release checklist, and no
single manifest connected shipped upstream content to versions, terms and
redistribution status.

**What changed.** `inst/CITATION` now supplies a local software citation and an
explicitly pending post-release DOI action. `inst/DATA-LICENSING.md` separates the
MIT-0 software scope from the mixed-provenance database, and
`inst/extdata/UPSTREAM-SOURCES.tsv` records every upstream resource, pin/date,
URL, terms link, use and review status. A local checklist covers the source
commit, audit, archive checksums, tag and DOI steps without performing any
external action.

**Effect.** Rhea, ChEBI, Pfam and citation-only literature use have documented
terms. KEGG, dbCAN/CAZy, InterPro member records, NCBIfam/TIGRFAM and
MetaCyc/BioCyc are explicitly retained as human-review release blockers rather
than being declared redistributable without evidence. No data was relicensed,
published, tagged or uploaded.

### 2026-10-01T02:17Z — The v1 compatibility boundary is explicit and enforced

**The problem.** Package, database and schema versions were described as
independent, but a custom database with an obsolete or missing schema failed
only when a later SQL query happened to touch an incompatible table. The
repository also had no bounded promise distinguishing stable result fields from
incidental internal columns.

**What changed.** Every database connection is now checked for one readable
release row and a schema version in the package's supported set, currently
schema 7, with actionable errors. `inst/doc/compatibility.md` defines the
intended v1 guarantees for exported functions and named arguments, nine result
classes and their stable core fields, independent versioning, custom databases,
and deprecation. Contract tests cover representative signatures, fields,
traceability columns and failure messages.

**Effect.** Compatible biological releases remain independently updatable under
schema 7; incompatible custom databases fail before evaluation. The policy
does not freeze SQLite primary keys or undocumented diagnostic columns, and it
does not alter any completeness model or call.

### 2026-10-01T02:17Z — Public metadata describes the four implemented models

**The problem.** `DESCRIPTION` still described only enzymatic routes between
anchors, the README understated the metabolic catalogue and listed three of
four vignettes, and two quantitative examples embedded an obsolete catalogue
count. Release metadata also had an override for `source_commit` but no safe
procedure proving that the value named the sources being compiled.

**What changed.** Package metadata now names metabolic, structural, regulatory
and defense capabilities and states the encoded-capability claim boundary. The
README reports the database-tested 153-GIFT breakdown and lists the
multi-sample tutorial. Count-sensitive prose no longer hard-codes incidental
denominators. A release-only `GIFTER_SOURCE_COMMIT` path now accepts only a full,
existing hash whose database sources, schema and compiler exactly match the
clean worktree; ordinary development builds retain `unreleased`. The source
commit can precede an artifact-only commit, avoiding a circular self-reference.

**Effect.** Public descriptions match the implementation, while a future
release artifact can carry a real, auditable source commit without changing the
package, database or schema version in advance.

### 2026-10-01T02:17Z — A community evaluation is pinned to one database snapshot

**The problem.** Replacing the packaged SQLite file during a long
`evaluate_gifts_community()` run could make later worker connections read a
newer release than earlier workers. The calls remained individually valid but
the community silently combined two biological catalogues.

**What changed.** At the start of a community evaluation, SQLite's online
backup API now creates one run-specific snapshot from either the packaged
database or a custom SQLite connection. The parent and every forked worker open
that same file read-only; it is removed on success, worker failure, and
interruption. Non-SQLite custom DBI connections retain their existing
single-connection sequential path. The community constructor also refuses
genome results whose full database metadata differ even when their release
number happens to match.

**Effect.** One call cannot combine releases, does not retry against a database
that appeared later, and remains deterministic across worker counts. The
guarantee concerns the database artifact only and changes no GIFT completeness
logic or biological claim.

### 2026-10-01T02:17Z — Release checks now gate code and database reproducibility

**The problem.** The only GitHub Actions workflow built the documentation site
and database atlas. A pull request could therefore merge without running the
package tests, checking a built source archive, or proving that the packaged
SQLite database still compiled exactly from the reviewable TSV source.

**What changed.** A package-check workflow now checks a built tarball on current
R for Linux, macOS and Windows, plus the declared minimum R 4.1 on Linux, with
cached dependencies. A separate database gate validates every TSV source,
compiles to a temporary database, compares every table logically with the
packaged artifact, and checks SQLite integrity and foreign keys for both files.
The gate never writes to `inst/extdata/gifter.sqlite`.

**Effect.** CI now refuses code, schema or curation changes that fail the
package contract or leave the compiled database out of sync with its source.
No biological claim, package API, schema, database version or packaged artifact
changed.

### 2026-08-25T04:50Z — The NCBIfam screen gains the discovery product it lacked

**The problem.** The NCBIfam screen reached its profiles through their EC
numbers, and most NCBIfam profiles do not have one. 8,711 of the 13,888
equivalog-grade profiles carry no EC at all, 554 carry only an incomplete one
and 385 carry a complete EC that reaches no Rhea master — 9,650 of 13,888 were
invisible to it. `TIGR04546.1` *ahbC* is one of them, so the screen would have
found two of the three steps of the Ahb route and missed the one in the middle.
The KO screen has a discovery product, `discovery-candidates.tsv`; this one had
none, and could not have had one built the same way, because a profile with no
EC reaches no reaction and therefore no ChEBI participant to join an anchor on.

**What changed.** `data-raw/ncbifam_equivalog_screen.R` gains a second join and
a fifth output, `data-raw/reference/ncbifam-discovery-candidates.tsv`: the
declared anchor vocabulary is turned into search terms and matched against
`product_name` and `gene_symbol`. The match is left-permissive and
right-anchored so that `siroheme` matches `12,18-didecarboxysiroheme`; a term
subsumed by a longer term on the same profile is dropped; and a match inside a
phrase naming a protein residue or substrate is marked in an
`excluded_because` column rather than deleted. Rows carry the profile's
`comment`, because the release that admitted the namespace refused four of 57
profiles on biology after reading it. Ranking uses the anchor's Rhea degree,
computed exactly as `marker_specificity_screen.R` computes it, so the two
discovery queues can be read against each other; the screen therefore reads two
further cached Rhea inputs. The grade filter is untouched — the two equivalog
grades remain the admission rule, and widening them stays a separate
architectural decision.

**Effect.** 772 profiles survive the anchor join, 130 of them on an anchor of
Rhea degree 20 or less. The method check is that the screen rediscovers
`TIGR04546.1` on the `SIROHEME` anchor and marks it as already curated. No GIFT,
marker, route, schema table or runtime behaviour changed, and no database
release: the assessment that read the queue is
`inst/doc/proposal-ncbifam-discovery.md`, and what it deferred or refused is
indexed in `inst/doc/deferral-register.md`.

### 2026-08-23T14:30Z — NCBIfam accessions are recognised on input, suffix and all

**The problem.** `NCBIFAM` markers are unusable if a user has to name the
namespace by hand. Worse, the accessions collide with an identity gifter already
holds: `TIGR04545.1` is a JCVI profile as the pinned NCBIfam release publishes
it, while the five existing `TIGRFAM` rows are the same library recorded from
InterPro without a version suffix. Read one as the other and the marker
silently becomes a different marker.

**What changed.** `.infer_marker_namespace()` reads `NF######.#` and
`TIGR#####.#` as `NCBIFAM`, leaving bare `TIGR#####` as `TIGRFAM`, so the
version suffix is what decides the namespace. `.normalize_marker_accession()`
upper-cases `NCBIFAM` accessions. An unversioned `NF040708` is inferred as
nothing and errors, rather than being promoted to the versioned marker — a loud
failure, because the quiet one is a genome that looks as though it lacks a
capability.

**Effect.** Bare accession vectors and annotation tables from PGAP,
AMRFinderPlus, bakta and InterProScan now resolve without an explicit
`namespace` column. No existing inference changed: every pattern that resolved
before resolves to the same namespace.

### 2026-08-23T10:00Z — The compiler curates the NCBIfam grade, and a screen recomputes what the namespace resolves

**The problem.** NCBIfam grades every profile in a `family_type` column, and
only `equivalog` and `equivalog_domain` assert that a family's members share one
function. Every other grade groups sequences more loosely than a function, which
is the over-broad evidence invariant 16 refuses. A namespace admitted without
that grade curated would import the breadth silently, one accession at a time,
with nothing to notice. NCBIfam accessions are also versioned, and `NF040708`
is not guaranteed to be the profile `NF040708.3` names — an unversioned
accession is a marker pinned to nothing.

**What changed.** Two things, neither of them a schema change.

`R/database-build.R` gains an admission rule for the `NCBIFAM` namespace,
applied to `component_markers` and to all three typed evidence tables. A marker
row in that namespace must carry a versioned accession, must declare
`family_type=<grade>` inside its `notes` — in the same sentence as the curator's
reasoning, rather than in a column that can drift away from it — and the grade
must be one of the two admitted ones. `.gifter_ncbifam_grades` is a named
constant, so widening it is a visible edit.

`data-raw/ncbifam_equivalog_screen.R` is the NCBIfam counterpart of the KO
specificity screen. It composes NCBIfam's profile-to-EC assignment with Rhea's
EC-to-reaction mapping, applies the grade filter first, and answers the
comparative question that decides whether a profile buys anything: does a
single-reaction equivalog resolve a curated reaction that no single-reaction KO
resolves? It emits four reference tables into `data-raw/reference/`, including
the profiles refused on grade alone and the grade the pinned release gives every
accession the database admits.

**Effect.** No runtime behaviour, public API or evaluation logic changed. The
validator is stricter for one namespace and unchanged for every other. The
biological content it admits is recorded in the database as
`DBC-20260823-NCBIFAM-NAMESPACE`; the reasoning is in
`inst/doc/proposal-ncbifam-namespace.md`.

### 2026-08-22T17:25Z — A computable specificity screen for the KO marker layer

**The problem.** Invariant 16 — that a claim's specificity may not exceed its
evidence's — was enforced entirely by hand, one accession at a time, across
eight curation proposals. Nothing re-checked a marker admitted in an earlier
release, and nothing could answer "which curated route rests on evidence too
broad to name its substrate" without a curator reading every route.

**What changed.** `data-raw/marker_specificity_screen.R` computes the
measurement behind the invariant for the KO namespace, by composing KEGG's
KO-to-EC assignment with Rhea's EC-to-reaction mapping and reaction
participants. It emits four reference tables into `data-raw/reference/`: the
reaction fan-out of every EC-bearing KO, an audit of every curated KO marker
row, a route-level reading of the same evidence, and a ranked list of
uncurated single-reaction KOs whose reaction touches a declared anchor.

**Effect.** No package code, database content or runtime behaviour changed.
The audit of the current database closes with no change: of 204 curated routes,
23 have no required reaction evidenced by a single-reaction KO, and all 23 were
read individually and found to rest on genuine enzyme promiscuity, cofactor
variation, a Rhea master recorded at two granularities, or a deliberately broad
claim already argued in an earlier proposal. The reasoning, the limits of what
the screen can establish, and the discovery queue are recorded in
`inst/doc/proposal-marker-specificity-screen.md`.

### 2026-08-22T17:25Z — A computable specificity screen for the KO marker layer

**The problem.** Invariant 16 — that a claim's specificity may not exceed its
evidence's — was enforced entirely by hand, one accession at a time, across
eight curation proposals. Nothing re-checked a marker admitted in an earlier
release, and nothing could answer "which curated route rests on evidence too
broad to name its substrate" without a curator reading every route.

**What changed.** `data-raw/marker_specificity_screen.R` computes the
measurement behind the invariant for the KO namespace, by composing KEGG's
KO-to-EC assignment with Rhea's EC-to-reaction mapping and reaction
participants. It emits four reference tables into `data-raw/reference/`: the
reaction fan-out of every EC-bearing KO, an audit of every curated KO marker
row, a route-level reading of the same evidence, and a ranked list of
uncurated single-reaction KOs whose reaction touches a declared anchor.

**Effect.** No package code, database content or runtime behaviour changed.
The audit of the current database closes with no change: of 204 curated routes,
23 have no required reaction evidenced by a single-reaction KO, and all 23 were
read individually and found to rest on genuine enzyme promiscuity, cofactor
variation, a Rhea master recorded at two granularities, or a deliberately broad
claim already argued in an earlier proposal. The reasoning, the limits of what
the screen can establish, and the discovery queue are recorded in
`inst/doc/proposal-marker-specificity-screen.md`.

### 2026-08-22T18:05Z — Two curation assessments, and a refusal that held

**What changed.** Documentation only. `inst/doc/proposal-ncbifam-namespace.md`
assesses NCBIfam as a marker namespace and recommends it, unimplemented;
`inst/doc/deferral-register.md` indexes every standing refusal with what would
unblock it; `inst/doc/proposal-respiration-electron-acceptors.md` reopens the
electron-acceptor boundary and recommends a design. `AGENTS.md` now requires a
register row from any proposal that defers or refuses a candidate.

**Effect.** No package code, database content or runtime behaviour changed. A
respiration layer was curated during the assessment and reverted: the four
GIFTs validated and compiled, and `test-nitrogen.R` rejected them, which is what
that test is for. The refusal in the nitrogen proposal said reversing it needs
its own proposal and probably its own `gift_type`; the assessment agrees, and
the proposal is the deliverable rather than the content.

---

---

## Package 0.7.0

Released 2026-08-22. A minor version: one new export, one new metric family and
a curated facet that reached no trait until now. No behaviour change to
anything that existed — every metric `genome_traits()`, `community_traits()`,
`dataset_traits()` and the network functions reported is the number it was.

### 2026-08-22T15:20Z — Where a resource comes from

**The problem.** `resource_origin` is curated on anchors, with seven values
over the anchor vocabulary, and `.gift_classifications()` read only GIFT facets
and the `gift_profile` view. A genome could therefore be read for the substrate
class it degrades but not for where that substrate arrives from — the axis that
separates a genome opening plant- or host-derived resources from one living on
what other members release.

**What changed.** Anchor facets join the classifications through the anchors a
GIFT declares, split by the role the anchor plays: `input_resource_origin` and
`output_resource_origin`. They stay two facets rather than one because
consuming a `microbially_derived` compound and releasing one are opposite
positions, and a single `resource_origin` count would add them together. They
flow into `breadth_*` and the trace like any other classification, so nothing
special reads them.

**And a count beside the breadth.** `breadth_<facet>` counts the values a
genome reaches; `supported_gifts_<facet>:<value>` counts the GIFTs it reaches
them by, over the assessable GIFTs carrying that value. A genome supporting one
plant-derived entry and one supporting twelve had the same breadth and
different diets. The denominator is the GIFTs carrying the value and never the
frame, which would read as a fraction of the catalogue; a value the genome
reaches nothing of is not reported here, because it is already counted in the
breadth denominator, exactly as `provider_count` reports only represented
GIFTs.

The value goes in the metric identifier beside the facet that `breadth_`
already carries there, so every row of a one-genome result still names that
genome as its target. A facet value is a breakdown of the genome's traits, not
another thing the traits are about — an existing test asserted that invariant
and caught the first attempt, which had introduced a `facet_value` target type.

**What it is not.** A trophic level. A trophic level is a statement about flux
through a realised food web; these counts say what a genome encodes the
capability to act on, never what it eats, whether the resource is present, or
whether anything is expressed when the two meet. Rule 18 keeps an ecological
description derived from primary typed GIFTs rather than becoming one, and the
documentation says so where the metric is defined rather than only in the
architecture guide.

Anchor facets do not build frames. `reference_frame(facet = )` still resolves
the GIFT facet vocabulary only, so "GIFTs entering on plant-derived anchors" is
readable as a metric and not yet declarable as a denominator. That is a
frame-resolution change with its own schema keys and it is not taken here.

### 2026-08-22T15:20Z — Repertoire distance, and the tree gifter does not cut

**The problem.** `community_traits()` computes the Jaccard index of every pair
of genomes' supported GIFTs and reports it as `repertoire_overlap` in long
form. Every routine that would consume it — `hclust()`, `cmdscale()`,
`vegan::adonis2()` — wants a `dist`, and reshaping long rows back into one is
work the caller should not have to get right.

**What changed.** `repertoire_distance()` returns one minus that overlap as a
`stats::dist`, computed from `gift_matrix()` by the same cross-product the
traits layer uses. A test asserts the two agree pair by pair: a second
implementation that quietly disagreed with the first would be worse than no
second implementation. A dataset delegates to its catalogue, because a pair
shares what it shares in every sample both are detected in.

Two genomes that support nothing have `NA` rather than 1, which would say they
were compared and found to share nothing. A genome supporting nothing against
one supporting something is a different case and is 1.

**No assessability policy, deliberately.** A Jaccard index reads supported
sets, and a GIFT a genome does not support is outside its set whether the call
was a confident negative or an indeterminate one. `policy`, `quality` and
`threshold` therefore could not move the number, and the function does not
accept them: an argument that does nothing is worse than one that is absent,
because a reader assumes it worked. `min_confidence` is accepted and does move
it, by removing a weakly evidenced positive from the set being compared.

**Where it stops.** gifter returns the distance and fits no clustering, chooses
no linkage, cuts no tree and names no groups. All three are the analyst's
choices and none is defensible from the calls. Nor would the groups be guilds:
a guild is a set of organisms exploiting a resource in the same way, which is a
claim about resource use in situ, and §8 refusal 4 of the quantitative traits
proposal refuses lighter ecological claims than that one. This is the boundary
0.6.0 drew for groups of samples, drawn again for groups of genomes.

`stats` joins Imports. It was already used — `stats::setNames` throughout the
community layer — and `stats::as.dist` makes the omission load-bearing rather
than latent.

---

## Package 0.6.0

Released 2026-08-22. A minor version: four new exports and no behaviour change
to anything that existed. Every metric `community_traits()`,
`genome_traits()` and `community_network()` reported is the number it was, and
the new layer is checked against them rather than beside them.

### 2026-08-22T04:04Z — One genome catalogue observed across many samples

**The problem.** `gifter_community` is one sample. Users hold one MAG catalogue
mapped against many samples, with different genomes detected at different
abundances in each. There was no container for that, and building one by binding
N communities would have evaluated the same genomes N times for calls that
cannot differ, and would have permitted inconsistent call sets between samples —
the failure the release check in `.gifter_community()` guards against one level
up.

**The organising insight.** A call is a property of a genome. `evaluate_gifts()`
reads markers; it has never seen a sample. Across a dataset only two things
vary: which genomes are members of a sample's community, and how much of it they
represent. So the catalogue is evaluated **once**, a dataset holds one call
matrix, and every per-sample distributional metric is a matrix product over all
samples simultaneously — three products per reference frame answer every
sample and every GIFT. A loop calling `community_traits()` per sample would
repeat a community's whole quadratic walk for each one.

**New.** `gifter_dataset()` composes a `gifter_community` with a genome by
sample abundance matrix and optional sample metadata, `sample_id()` and
`sample_community()` read it, and `sample_community()` hands any existing
function an ordinary community of one sample's detected genomes — which is why
nothing else in the package needed a dataset-aware variant.

`dataset_traits()` reports per sample: `community_richness`,
`community_coverage`, `mean_genome_richness`, `assessable_fraction`,
`singleton_fraction`, `detected_genomes`, `provider_count`,
`provider_fraction`, `abundance_coverage`, `unique_contribution` and
`mean_repertoire_overlap`. `trace_sample()` derives one sample's trace.
`dataset_network()` restricts the catalogue's handoff edges to each sample and
recounts the degrees, density, chain coverage and cycle closure.

`gift_matrix()`, `dataset_matrix()` and `as.data.frame()` are the export
surface.

**The invariant this layer establishes.** *Detection is to samples what
assessability is to genomes.* Both may only move denominators: assessability
decides whether a genome's silence about a GIFT is informative, detection
decides whether a genome is part of a sample's community at all. Neither may
promote an unsupported GIFT to supported, neither may change a call, and both
are resolved per genome. It extends invariant 21 — presence in a genome,
presence in a sample and abundance in a sample are three axes and never one
number — and it is tested directly rather than asserted.

`detection` is therefore an argument of the readers, not of the container, on
exactly the terms that put `threshold` on `community_traits()` rather than on
`gifter_community()`. Abundance is closed within each sample's **detected** set,
after detection, so `abundance_coverage` is a share of the community actually
being described; above `detection = 0` that differs from closing over the whole
catalogue, deliberately.

**Two metric tables, not one nullable column.** `gift_richness` and
`repertoire_overlap` cannot vary between samples: a genome supports the same
GIFTs wherever it is detected, and two genomes share the same repertoire
wherever both are. They live in `catalogue_metrics` with no `sample_id` column,
and the absence of the column is the claim. Re-emitting the pair metric per
sample would have made the one quadratic quantity quadratic again, months after
0.5.0 removed it.

**The decisive test.** For every sample, everything `dataset_traits()` reports
equals what `community_traits()` reports on `sample_community()` of that sample
with that sample's abundance — and the same for `dataset_network()` against
`community_network()`. The layer is checked against the engine it extends, over
all fourteen default frames, rather than against hand-computed expectations
of its own.

**Where gifter stops, and why it is a decision rather than an omission.** gifter
emits per-sample traits joined to sample metadata and interprets no metadata
column. It runs no hypothesis test, differential-abundance analysis, ordination
or effect size between groups of samples. §8 refusal 4 of the quantitative
traits proposal already refuses lighter ecological claims than a group
difference; its refusal 3 refuses a user-supplied vector multiplied through the
call matrix and presented as a gifter inference, and a group label is exactly
such a vector. What vegan, lme4, MaAsLin and ALDEx2 lack is an
assessability-aware matrix with a declared reference frame, and `gift_matrix()`
is that: three-state, `NA` where a genome was never observed well enough for its
silence to be read. A zero there is a fabricated absence that every model fitted
on it inherits.

Also refused, with reasons recorded in the proposal so they are not silently
reopened: depth correction, rarefaction and detection imputation; any claim that
a GIFT is more active where its carriers are more abundant; and any per-sample
re-evaluation of calls.

**One internal change to existing code.** `.warn_thin_denominators()` gains an
optional argument naming what the thin readings are counted in, defaulting to
the current text, because a dataset reports one `assessable_fraction` per sample
per frame. `.distributed_cycles()` now takes the enumerated cycles rather
than enumerating them, so a reader asking the same question of many samples
enumerates once. Neither changes what any existing function returns, and a test
checks the single-community warning is unchanged.

**No database or schema change.** Nothing here is curation. Every number is a
re-reading of existing calls, the compiled artifact is untouched, and no Boolean
call moved.

---

## Package 0.5.0

Released 2026-08-22. A minor version because one default changed: the per-pair
trace is no longer carried unless it is asked for. Every metric is the number it
always was, the default reference frames are the same fourteen, and the only
code that has to change is code that read `$trace` for a genome pair.

### 2026-08-22T14:40Z — Reading a community stops being quadratic in wall time and memory

**The problem.** `community_traits()` on 418 genomes ran for tens of minutes and
held gigabytes, while the evaluation that produced those genomes took under
three. Nothing about the arithmetic was expensive. Two things were:

- every pair of genomes was intersected and given its own one-row tibble, and
  the pair count is quadratic — 418 genomes are 87,153 pairs, 2,000 are two
  million — so a run spent its time in `tibble()` calls, roughly 0.65 ms each,
  once per pair per frame;
- the per-pair trace carried one row per pair per shared GIFT, which is tens of
  millions of rows and gigabytes at a few hundred genomes.

**Change.** `repertoire_overlap` is computed for every pair at once. One
cross-product of the call matrix holds every shared count there is, the union
sizes follow from the row sums, and one tibble carries all the pairs of a
frame. The values, their numerators and denominators, their order and the
withholding of an undefined overlap between two empty repertoires are all
exactly what the per-pair loop produced; a test now checks the two against each
other over a community large enough for them to disagree.

`community_traits()` gains `pair_trace`, defaulting to `FALSE`. The pair trace
is the only part of the output that is quadratic in rows rather than in
arithmetic, and the overlap values it justifies are unchanged without it. Asked
for, it is built per GIFT rather than per pair — every pair sharing a GIFT is
every pair of its providers — so it arrives grouped by GIFT: the same evidence
in a different order. The community, GIFT and genome traces are recorded as they
always were.

`community_traits()` also gains `pairwise`, defaulting to `TRUE`. The pair
metric is the one quantity that is quadratic in the community; everything
reported per GIFT and per genome is not. Separating them is what lets a large
community keep the full set of reference frames: 418 genomes within all
fourteen is 12,999 non-pair rows and 1,174,481 pair rows, and 2,000 genomes is
57,295 against 27 million. `pairwise = FALSE` drops the second number and
touches nothing else. Asking for `pair_trace = TRUE` alongside it is refused
rather than ignored.

**The default set of frames is unchanged.** Reading a community within the
catalogue-wide frame alone was considered and rejected: it is 94% metabolic,
so every richness and overlap taken over it is a metabolic quantity wearing a
general name, and `community_coverage` — defined only for a bounded frame —
would have disappeared from the default output entirely. What made the fourteen
expensive was the pair metric, and `pairwise` addresses that directly.

**Measured**, on synthetic communities over the default frames:

| genomes | reading | time | metric rows | held |
|--------:|---------|-----:|------------:|-----:|
| 418 | catalogue-wide frame alone | 1.1 s | 88,291 | 15 MB |
| 418 | default, all fourteen | 13.7 s | 1,184,011 | 102 MB |
| 418 | default, `pairwise = FALSE` | 12.0 s | 12,999 | 6 MB |
| 1,000 | default, all fourteen | 34.5 s | 6,758,648 | 567 MB |
| 2,000 | default, all fourteen | 88.5 s | 27,003,904 | 2,251 MB |
| 2,000 | default, `pairwise = FALSE` | 53.9 s | 57,295 | 25 MB |

`pairwise = FALSE` is what the memory column is for; it is not yet much of a
time saving at two thousand genomes, because with the pairs gone the remaining
54 s is the per-GIFT and per-genome loops, which still build one tibble per row
-- 84,000 of them across fourteen frames. Those were left alone here: they
are linear in the community and were nowhere near the cost the pairs were.

The per-pair loop this replaces took 192 s over a *single* frame at 418
genomes — 185 s building rows and 7 s combining them — which is roughly three
quarters of an hour for the fourteen-frame default. The synthetic communities
share less between genomes than real ones do, so the trace figures are
conservative.

**No metric change.** Every value, numerator, denominator, derivation method and
reference frame is what it was. What changed is whether the pair trace is
carried.

---

## Package 0.4.1

Released 2026-08-22. A patch version because nothing about the traits changed:
the addition is an optional display argument that defaults to what the console
was already doing, and every call written against 0.4.0 returns the same object
it always did.

### 2026-08-22T09:10Z — Reading a community reports its progress too

**Change.** `community_traits()` gains a `progress` argument and shows the same
cli progress bar `evaluate_gifts_community()` already showed, counting
reference frames summarised out of frames to summarise, with a bar, a
percentage and an estimate of the time remaining. It defaults to `TRUE` at an
interactive console reading more than one frame and to `FALSE` otherwise, so
scripts, knitted documents and `R CMD check` stay silent. A malformed request
is refused before any frame is built.

The display and the rule for whether there is one moved to `R/progress.R`, so
both long-running functions report through one object rather than two
implementations of the same bar. `.resolve_progress()` now names its second
argument `units` instead of `genomes`; the genome bar is unchanged in what it
counts or how it reads.

**No metric change.** The metrics, their trace and their order are exactly what
they were, with the display on or off.

**Why.** Evaluating a community was the slow half only until the community got
large. Reading one walks every reference frame over every GIFT, every genome
and every pair of genomes, and the pairwise term grows with the square of the
membership: a thousand-genome community is half a million pairs per frame,
across a default set of fourteen. A run of that length with a silent console is
indistinguishable from a hung one, which was the whole argument for the bar in
the evaluation, and it applies unchanged here.

Frames are the unit because they are what the caller supplied and what every
returned metric is reported within. They are not equal units of work — one
spanning the catalogue takes longer than a narrow one — so the estimate is
coarser than a genome count, which is the price of counting the work the caller
asked for rather than the genome pairs it happened to require.

## Package 0.4.0

Released 2026-08-21. A minor version because four arguments moved between
functions: calls that supplied `abundance`, `quality`, `policy` or `threshold`
to `gifter_community()` or `evaluate_gifts_community()` must supply them to
`community_traits()` instead. No call is evaluated differently.

### 2026-08-21T16:20Z — Marker confidence can gate what a trait counts

**Change.** `genome_traits()` and `community_traits()` take `min_confidence`,
the weakest marker confidence a positive call may rest on and still be counted.
A supported GIFT below the floor becomes **indeterminate, not negative**, so it
leaves the richness count and the assessable denominator together.

```r
# richness over capabilities evidenced by more than a polyspecific family
genome_traits(result, min_confidence = "high-confidence")
```

**Why.** `evidence_confidence` was computed and then discarded: no metric read
it. `gift_richness`, `breadth_*`, `community_richness`, `provider_count` and
`abundance_coverage` all counted `complete` alone, so a capability called from
an ambiguous polyspecific CAZy family was indistinguishable from one called from
curated orthology. Five families carried by nearly every gut Bacteroidetes
genome returned a full-marks carbohydrate richness on no real evidence. Weak
evidence is not evidence of absence, which is why the floor produces an
indeterminate call rather than a negative one.

**Compatibility.** The default is `NULL`, which counts every positive call. No
existing result changes.

### 2026-08-21T16:25Z — Handoffs out of extracellular chemistry are marked inexact

**Change.** The `gift_graph` view no longer reports an edge as `exact` when the
upstream GIFT declares an extracellular input and the shared anchor leaves the
compartment unresolved. Such edges become `compartment_inexact`, which
`gift_graph()`, `community_network()` and the atlas already understand.

**Why.** A secreted glycosidase releases its sugar outside the cell and a
catabolic GIFT consumes it inside. Where no transporter evidence licensed
splitting that sugar into compartment variants, both GIFTs name one unsplit
anchor and the membrane between them disappeared from the graph, collapsing the
degrader-versus-forager distinction the compartment model exists to carry. The
chain stays traversable — breaking it would turn a missing transporter marker
into a false negative for the whole capability — but the assumption is now
visible. Three edges are reclassified and 214 are unaffected. No call changes.

### 2026-08-21T14:10Z — Abundance and completeness are supplied where the calls are read

**Change.** `abundance`, `quality`, `policy` and `threshold` are now arguments
of `community_traits()`. They are no longer accepted by `gifter_community()` or
`evaluate_gifts_community()`, which supplying them to raises an error naming
where they went.

```r
# before
community <- evaluate_gifts_community(markers, abundance = weights,
                                      quality = checkm, policy = "completeness",
                                      threshold = 90)
traits <- community_traits(community)

# now
community <- evaluate_gifts_community(markers)
traits <- community_traits(community, abundance = weights, quality = checkm,
                           policy = "completeness", threshold = 90)
```

A `gifter_community` is now calls and nothing else: it no longer carries
`abundance`, `abundance_supplied` or `assessability`, and its `matrix` holds the
calls as they were made rather than the calls as read under a policy, so it no
longer contains `NA`. The normalised and supplied abundance vectors and the
assessability policy are reported by the `gifter_traits` object that used them,
where they describe the reading they belong to.

`community_network()` and the cycle layer are unaffected: they always tested the
matrix for `TRUE`, which reads the calls identically.

**No evaluation logic change.** Nothing about a call or its evidence changed,
and no trait value changes for an analysis that supplies the same arguments in
the new place. Assessability is still resolved per genome, still moves only
denominators, and still cannot promote an unsupported GIFT.

**Why.** `genome_traits()` already took `quality`, `policy` and `threshold`,
because how far an absence may be read is a property of the reading and not of
the genome. The community path asked for the same information two layers
earlier, at the container or at the evaluation, which made the two paths
inconsistent and had two costs. A community bound under one threshold could not
be read under another without rebuilding it, and rebuilding it from
`evaluate_gifts_community()` meant re-evaluating every genome — minutes for a
418-genome community, hours for a large one — to change a number that never
entered a single call. Abundance was the same argument in a different guise: a
weight a reader chooses, carried by an object that had no use for it.

**Effect.** Evaluation produces calls; reading them is a separate, cheap,
repeatable step that states its own assumptions. One community can be read under
several completeness thresholds, or with and without abundance weighting,
without being evaluated twice.

### 2026-08-21T13:26Z — A nonsensical worker request is refused before the evaluation

**Change.** `evaluate_gifts_community()` now checks the shape of `workers`
before it evaluates a single genome. It was previously checked where the request
is resolved, which is after the annotation table has been split and after the
single-genome guardrail has had its chance to stop and ask about a large genome.
A default taken from the `mc.cores` option is checked on the same terms as a
request, rather than trusted for having come from an option.

`limit` is checked where a cycle enumeration is asked for rather than only where
it is run, so `community_network()` reports a nonsensical limit before building
the graph, the handoff edges and the chain coverage it would have been used
after.

The refusal of an unnamed numeric `abundance` now says how to supply the genome
identifiers, as the equivalent `quality` refusal already did.

**No evaluation logic change.** An argument that was accepted is accepted and
one that was refused is refused with the same message, sooner.

**Effect.** A malformed argument costs a message rather than a wait.

---

## Package 0.3.1

Released 2026-08-21. A patch version because no argument, function or return
value changed: the change widens what an existing argument accepts, and every
call written against 0.3.0 is read exactly as it was.

### 2026-08-21T06:36Z — Genome completeness may be stated as a percentage

**Change.** `quality` in `genome_traits()`, `gifter_community()` and
`evaluate_gifts_community()`, and the `threshold` they are compared against,
are now read on either scale. A set of completeness values whose largest member
exceeds 1 is read as percentages and divided by 100; a set that stays at or
below 1 is read as proportions, so `1` remains a complete genome rather than a
1% one. The scale is decided once over every value supplied, not per genome, and
a `threshold` is read the same way, so `quality = c(MAG = 55), threshold = 90`
and `quality = c(MAG = 0.55), threshold = 0.9` are the same analysis.

A percentage table that also holds a value strictly between 0 and 1 now warns:
under the table's own scale that genome is almost empty, which is a hundredfold
different from the proportion it may have been meant as, and the reading is
stated rather than chosen silently. Values above 100, below 0, or missing are
still refused, with an error naming both accepted scales.

An unnamed numeric `quality` is still refused — the names are what say which
genome each value belongs to, and aligning by position would assign one
genome's fragmentation to another — but the refusal now names that case and
shows how to supply the identifiers, instead of describing the accepted shapes.

**No assessability change.** Completeness still informs the reading of absence
and nothing else, on either scale: no policy promotes an unsupported GIFT to
supported, and indeterminacy is still resolved per genome.

**Why.** CheckM, BUSCO, GTDB and every MAG quality table in circulation report
completeness as a percentage, so `quality = quality_table$completeness` is the
natural call and it failed on the scale check. A proportion cannot exceed 1,
which makes the two scales distinguishable from the values themselves; refusing
to read a table that says what it means was pedantry, not rigour, and the
guessing it avoided was never real.

**Effect.** Callers working from a MAG quality table pass its completeness
column unchanged, in whichever unit it was reported in. Existing proportional
calls are untouched. The single ambiguity the rule cannot resolve — a genome
below 1% inside a percentage table — is reported rather than assumed.

---

## Package 0.3.0

Released 2026-08-21. A minor version because the change adds an argument
and a display to an existing function without altering a single call: code
written against 0.2.0 behaves identically, and the community it gets back is
the same object it always was.

### 2026-08-21T12:20Z — A community evaluation reports its progress

**Change.** `evaluate_gifts_community()` gains a `progress` argument and shows
a cli progress bar while it runs: genomes evaluated out of genomes to evaluate,
with a bar, a percentage and an estimate of the time remaining. It defaults to
`TRUE` at an interactive console evaluating more than one genome and to `FALSE`
otherwise, so scripts, knitted documents and `R CMD check` stay silent.

The forked path was rebuilt around `parallel::mcparallel()` and
`parallel::mccollect()` in place of `parallel::mclapply()`. Each block is still
one child holding its own read-only connection, and blocks are still returned to
the positions they were split from; what changed is that the parent now collects
the children as they finish instead of blocking until the last one returns, and
so has time between results to redraw the display. Children report the count
through a file, one appended byte per genome evaluated, since a forked child has
no console of its own. Abandoned children are killed rather than left running.

**No evaluation logic change.** The calls, their evidence, their order and the
assembled community are exactly what they were, at any number of workers and
with the display on or off.

**Why.** Parallel evaluation exists in this function for one reason — a
community of thousands of genomes takes minutes to hours — and a run of that
length with a silent console is indistinguishable from a hung one. Nothing in
the old design could say how far along it was: `mclapply()` holds the parent
until every child returns, and a child cannot write to the parent's console.

**Effect.** Progress is reported in genomes, the unit the caller asked for,
never in workers started or blocks finished, which are an implementation detail
of how the same work was spread out. The count therefore reads the same at one
worker and at thirty-two. A run that aborts clears the bar rather than leaving
one behind that claims to have finished.

---

## Package 0.2.0

Released 2026-08-21. Renumbered from 0.1.2, which was never released. The
removal of the giftr names and the renaming of the genome result class are the
first changes that break code written against a published gifter version, which
a patch number would not have said.

### 2026-08-21T04:55Z — The giftr names are removed

**Change.** The pre-rename aliases are gone: the exported functions
`giftr_community()`, `giftr_db_connect()`, `giftr_db_disconnect()`,
`giftr_db_version()`, `validate_giftr_sources()`, `build_giftr_database()` and
`write_giftr_database_html()`; the secondary `giftr_*` S3 classes carried by
every result, community, frame, traits and network object, with their print
methods; and the `giftr_db_version` column duplicated into `gifter_db_version()`.
`test-package-rename.R` now asserts their absence instead of their presence.
**No biological, schema, database or evaluation logic change:** every remaining
name behaves exactly as before.

**Why.** A compatibility alias is a promise to code that already exists. This
package was never published as giftr, so the aliases carried that promise to
nobody while doubling the public surface, the class vector of every object, and
the columns of a version report that is read programmatically.

**Effect.** Code written against the `gifter_*` names is unaffected. Anything
matching on `giftr_` — a class test, an export, or the duplicated version
column — has nothing left to match, which is the intent.

### 2026-08-21T04:55Z — A genome result is a gifter_genome

**Change.** The class of an `evaluate_gifts()` result is `gifter_genome`, not
`gifter_result`, and it prints as `<gifter_genome>`. `trace_gift()`,
`genome_traits()`, `evaluate_gift_cycles()` and `gifter_community()` accept the
new class. `gifter_reaction_result`, which `evaluate_reactions()` returns, is
unchanged. **No biological, schema, database, evaluation logic or
result-structure change:** the same list of tibbles under a different class.

**Why.** The result layer now has two members, one genome and one community.
`gifter_result` named neither: beside `gifter_community` it read as *the*
result rather than as one genome's, which is the distinction the whole
community layer rests on.

**Effect.** `inherits(x, "gifter_result")` no longer matches. Nothing else that
reads a result is affected, since every accessor was updated with the class.

### 2026-08-21T04:55Z — evaluate_gifts_community() evaluates a table of genomes

**Change.** New exported `evaluate_gifts_community(annotation_table, namespace,
db, genome_id, gene_id, max_genes, workers, abundance, quality, policy,
threshold)`. It splits a multi-genome annotation table on its `genome_id`
column, evaluates every genome separately through the same evaluator as
`evaluate_gifts()`, and returns the `gifter_community()` the quantitative trait
layer reads. Genomes are evaluated in forked workers, one read-only database
connection each, defaulting to `getOption("mc.cores")` or one fewer than the
number of physical cores and capped at the number of genomes; forking is
unavailable on Windows and for a connection with no file behind it, where the
genomes are evaluated one after another. A worker that fails or dies is refused
rather than passed off as a result, and reports the error the failing genome
raised. The single-genome guardrail is applied
to each genome separately and names the genome it suspects. `parallel` is added
to `Imports`, and `gifter_community()`'s body moves to an internal constructor
taking a list, so that a genome named `policy` or `abundance` cannot be
mistaken for an argument. **No biological, schema, database or evaluation logic
change:** a genome evaluated in a community is identical to the same genome
evaluated alone.

**Why.** The single-genome guardrail added in 0.1.1 points at a function that
did not exist. Markers pooled across genomes complete routes that no member
encodes, so a collection needed a supported way in rather than a warning to
work around — and the split, being per genome, is embarrassingly parallel.

**Effect.** A community is built from one table in one call. The genome column
is required and, unlike the gene column, is never proposed from column order: a
misread gene column mislabels evidence inside a genome, while a misread genome
column redraws the genomes themselves and leaves no call looking wrong. Workers
change wall time only — the calls, their order and the assembled community are
identical at any number, which `test-evaluate-community.R` asserts along with
the per-genome identity against `evaluate_gifts()` and the pooled call the
split prevents.

### 2026-08-21T04:25Z — Guardrail messages are readable at any console width

**Change.** The input guardrails of `evaluate_gifts()`, and the argument errors
around them, report through cli instead of `warning()` and `stop()`. Each
message now wraps to the console width and separates the concern, its reason,
and the ways out onto their own bullets, and the proposed gene column is shown
with the values it actually holds. The interactive prompt is bounded to three
attempts and treats an empty line as no answer, falling through to the
non-interactive behaviour. cli is added to `Imports`. **No biological, schema,
database, evaluation logic, result-structure or public API change:** the
guardrails decide the same inputs on the same terms.

**Why.** `warning()` and `stop()` emit a paragraph as a single unbroken line
however narrow the console, so a guardrail long enough to explain what it
suspects and how to answer it could not be read in an RStudio console. A
guardrail the user cannot read is a guardrail that does not work. The unbounded
retry loop had the same character of fault: at end of input `readline()` returns
an empty line forever, so a session with nobody left to answer would have hung
rather than falling back.

**Effect.** Both guardrails state their case in a form that fits the console
they are printed in. cli is already a hard dependency of tibble, which gifter
imports, so no additional package is installed. The package-version assertion in
`test-database.R` tracks the version bumped in 0.1.1.

## Package 0.1.1

### 2026-08-21T04:10Z — evaluate_gifts() questions inputs it cannot verify

**Change.** `evaluate_gifts()` gains `gene_id` and `max_genes` and runs two
input guardrails before evaluating. A table without a `gene_id` column no longer
silently numbers its markers when another column could be the gene identifier:
the first column that is neither `namespace` nor `accession` is proposed for
approval, adopted with `gene_id = TRUE` or `gene_id = "column"`, refused with
`gene_id = FALSE`, and left unresolved — an error — when there is nobody to ask.
An input carrying more than `max_genes` distinct gene identifiers (5,000 by
default) is questioned as a possible collection of genomes, declined with an
error pointing at `evaluate_gifts_community()`, and reported as a warning when
non-interactive, since a large genome is a legitimate input. `max_genes = Inf`
skips the check. A table of markers alone, a named marker vector, and a table
that already carries `gene_id` are evaluated unquestioned. **No biological,
schema, database, evaluation logic or result-structure change:** the guardrails
decide which input is evaluated, never what the calls are.

**Why.** Both mistakes yield a well-formed result that answers a question the
user never asked, and neither is visible in the calls. Adopting the wrong column
attaches correct calls to the wrong loci, breaking every trace down to genes
while nothing looks wrong. Pooling several genomes into one call completes
routes from reactions drawn from different organisms, reporting a capability of
the collection as a capability of a genome.

**Effect.** An ambiguous gene column is settled by the user rather than by column
order, and a pooled collection is caught at the input rather than published as a
genome's capabilities. `map_markers()` and `evaluate_reactions()` are unchanged.

## Package 0.1.0

### 2026-08-20T12:19Z — Reference-frame atlas guides analytical choice

**Change.** The HTML atlas adds a searchable Reference frames view generated
from the curated registry. It presents every preset by biological question,
current membership, open or bounded denominator, genome/community/network
scope, recommended metrics and their rationales, interpretation limit, filter
definition, and runnable `reference_frame()` call. The quantitative-traits
tutorial includes a complete registry table and a short metric-selection guide,
and the README links directly to the atlas chooser. **No biological, schema,
database, evaluation, metric, or public API change.**

**Why.** The registry made recurring analytical scopes machine-discoverable,
but researchers unfamiliar with gifter still had to interpret a wide tibble or
inspect three raw database tables before they could choose a suitable frame
and analysis scale.

**Effect.** Researchers can now begin with their biological question, narrow
the available frames by data scale or valid coverage denominator, and see
which metrics to report and which interpretations to avoid. Because the view is
rendered from the database, future curated frames and recommendations appear
without a second hand-maintained catalogue.

### 2026-08-20T11:35Z — Named reference frames make recurring analyses reusable

**Change.** Schema 7 and biological database 2026.20.4 add a normalized registry
of 19 named reference frames, their metadata filters, boundedness claims,
interpretation limits and scope-specific metric recommendations. The new
`list_reference_frames()` accessor discovers them, and
`reference_frame(preset = ...)` resolves a preset against the current database
release. Documentation now demonstrates the carbohydrate-degradation and
biomass-essential-anabolism presets. **No GIFT definition, evaluation logic or
Boolean call changes.**

**Why.** Questions such as carbohydrate degradation, nitrogen acquisition,
fermentation-product formation and vitamin biosynthesis were already expressible
with `reference_frame()`, but every analysis had to restate their biological
scope. A versioned registry makes those scopes easy to find and consistent
between genome and community analyses without hard-coding GIFT identifiers.

**Effect.** Preset filters are ORed within a metadata key and ANDed across keys;
membership therefore follows `gift_type`, `mode`, curated facets and the derived
`gift_profile` as the catalogue changes. Open presets cannot be promoted to
bounded at runtime. Only biomass-essential anabolism and its amino-acid,
nucleotide and cofactor subsets ship as bounded. Cycle closure and community
handoffs remain graph-derived rather than being reduced to set membership.

### 2026-08-20T09:35Z — Documentation and Atlas share one navigation model

**Change.** The package website and GIFT Atlas now expose the same primary
destinations: API reference, ordered tutorial articles, and the Atlas. The
Atlas keeps its Overview, GIFT explorer, Changelog, SQL schema, and Tables
controls as a separate local navigation row. The article index and menu now
declare the intended tutorial sequence explicitly: 1, 2, then 3. **No
biological, schema, database, evaluation, or public API change.**

**Why.** Atlas-only controls previously occupied the position used for global
documentation navigation, leaving no direct route back to the API reference or
vignettes. Pkgdown also inferred article order from filenames, which displayed
tutorial 3 before tutorials 1 and 2.

**Effect.** Users can move between the reference, articles, and Atlas from the
same place on either surface, while Atlas views remain close at hand. Both the
article landing page and its menu present the tutorials in reading order.

### 2026-08-20T09:03Z — Website adopts the gifter gear logo

**Change.** The supplied three-gear SVG is now the package website and database
atlas logo, with its oversized source artboard cropped at the SVG `viewBox` so
that the artwork scales cleanly in the navigation bars and pkgdown page headers.
The top-left wordmark now renders `gift` in forest green and `er` in the theme's
muted grey. **No biological, schema, database, evaluation, or public API
change.**

**Effect.** The documentation site and self-contained atlas use the new logo at
every viewport size and keep the full `gifter` name as one accessible home or
overview link while presenting the requested two-color wordmark.

### 2026-08-20T08:35Z — Documentation and atlas share one visual environment

**Change.** The pkgdown website now uses the database atlas's palette,
typography, brand mark, header proportions, segmented navigation, search
control, content surfaces, and responsive spacing across the home, tutorial,
and API reference pages. Pkgdown's generated structure, navigation, search,
table of contents, and reference content are unchanged. **No biological,
schema, database, evaluation, or public API change.**

**Why.** The documentation and reference atlas are adjacent parts of the same
published site, but the former used the default Bootstrap presentation while
the latter had its own complete visual system. Moving the documentation into
that system makes transitions between explanation and database exploration
feel continuous and gives future pages a common layout environment.

**Effect.** Documentation pages and the atlas now share a warm paper ground,
forest and mint controls, serif display headings, compact rounded navigation,
and the same responsive visual rhythm. The atlas remains a self-contained
offline-capable report, and the documentation remains standard generated
pkgdown output.

### 2026-08-20T08:02Z — Database atlas published with the package website

**Change.** The package now has a pkgdown website deployed to GitHub Pages by
GitHub Actions. The workflow installs the package, builds its reference and
vignette documentation, and generates `atlas/index.html` from the SQLite
database in that same installation. The atlas is checked on pull requests and
deployed from `main`. **No schema, database content, or evaluation change.**

**Why.** The 8.7 MB self-contained atlas was installed beside the 1.6 MB SQLite
database from which it can be reproduced. That duplicated database content,
inflated every installation, and gave a generated report the appearance of a
second packaged source artifact.

**Effect.** The current atlas is browsable at
`https://alberdilab.github.io/gifter/atlas/`. Users can still create an offline
or shareable report with `write_gifter_database_html()`, but
`inst/extdata/gifter-database.html` is no longer shipped. The curated TSV
sources remain authoritative and the SQLite database remains the compiled
runtime artifact.

### 2026-08-20T06:16Z — Package renamed from giftr to gifter

**Change.** The R package is now named `gifter`, avoiding the
case-insensitive CRAN name collision with the archived package `GIFTr`.
Package loading, qualified calls, help aliases, S3 classes, internal
package-prefixed identifiers, tests, vignettes, development files, and the
packaged database/schema/report filenames now use `gifter`. The
package-prefixed database release column is `gifter_db_version`; its value and
the independent biological database and schema versions are unchanged.

**Compatibility.** The exported functions `giftr_community()`,
`giftr_db_connect()`, `giftr_db_disconnect()`, `giftr_db_version()`,
`validate_giftr_sources()`, `build_giftr_database()`, and
`write_giftr_database_html()` remain as documented aliases of their `gifter_*`
replacements. Returned objects carry their former `giftr_*` S3 class as a
secondary class, and version metadata retains a deprecated
`giftr_db_version` field mirroring `gifter_db_version`.

**Effect.** New code installs and loads `gifter` and should use the canonical
`gifter_*` names. GIFT definitions, routes, marker evidence, evaluation logic,
database release, and schema version do not change. The repository now lives at
`https://github.com/alberdilab/gifter` following its separate external rename.

### 2026-08-19T06:10Z — Three tutorial vignettes covering a complete analysis

**Change.** A new `vignettes/` directory with three executed `.Rmd` tutorials,
`knitr` and `rmarkdown` added to `Suggests` with `VignetteBuilder: knitr`, a
*Tutorials* section in `README.md`, and a row in the AGENTS work table. **No
code, schema or database change.**

**Why.** The package had reference documentation and design records but no path
in. A newcomer holding an annotation table could not find out, from anything
shipped, how to get from that table to a call, or what a call was allowed to
mean once they had one.

**Effect.** `evaluating-a-genome` covers the input format, which markers gifter
could use, reading complete and incomplete calls, and tracing a call to genes.
`quantitative-traits` covers reference frames and why a count without one is
not a result. `community-analysis` covers provider counts, presence versus
abundance, and the handoff network.

They are `.Rmd` rather than static markdown so that every chunk is executed at
`R CMD build` and re-executed at `R CMD check`. A tutorial whose output is
pasted in by hand starts drifting from the package the day it is written; these
cannot, because the check fails first.

**The vignettes teach the refusals, not only the API.** Each one is built around
a case where gifter declines to answer, because those are the places a newcomer
will otherwise misread the output: the genome that completes
`chemotaxis_signal_transduction` and not `aspartate_chemoreception`, on a
generic chemoreceptor accession that cannot license a ligand-specific claim; the
absent `supported_fraction` over an open catalogue; the 55%-complete MAG whose
fraction rises to 1.0 while its richness does not move; and the two genomes that
each encode xylose uptake and xylose catabolism and still produce no edge
between them, because `XYLOSE_IN` is cytoplasmic.

The illustrative genomes are labelled as fixtures built from the curated
database, not presented as annotation output from named organisms, and the AGENTS
work table now records that as the standard for tutorial content. The
arabinoxylan community is the same curated chain the community tests use.

`R CMD check --no-manual` on the built tarball, vignettes included: one NOTE,
the pre-existing installed size. `Config/build/clean-inst-doc: FALSE` keeps the
design proposals in `inst/doc` alongside the built vignettes.

### 2026-08-19T05:25Z — The quantitative layer is documented and its invariants are rules

**Change.** Documentation only. `inst/doc/architecture.md` gains a
**Quantitative traits** section and three quick-index entries; `AGENTS.md`
gains invariants 20-23, a row in *Work in the correct files* and a testing
bullet; `README.md` gains a *Summarise genomes and communities* section;
`inst/doc/proposal-quantitative-traits.md` becomes accepted and implemented and
carries the implementation record. **No code, schema or database change.**
This is phase 5 of that proposal.

**Why.** The layer's four constraints are not conventions an author could
reasonably choose otherwise about: a frame built in R rather than from
curated metadata, a fraction of an open catalogue, a quality policy that
promotes a call, or an edge that hands a cytoplasmic molecule between organisms
are each a defect rather than a style. Constraints of that kind belong in the
invariant list, where they are checked before a change ships, and not only in
the roxygen of the function that happens to enforce them today.

**Effect.** Invariant 20 requires a declared reference frame built from
curated metadata and forbids a fraction of the catalogue unless the frame was
declared bounded. Invariant 21 keeps presence, abundance and context apart and
fixes genome quality as informing absence only, per genome. Invariant 22 bounds
interaction edges to existing compatibility semantics, requires them to inherit
`edge_quality`, and requires an `extracellular` anchor to cross organisms.
Invariant 23 requires traceability and prefers interpretable components to
composite indices.

The implementation record states both departures from the plan. The first
changes results: a cross-genome edge needs an extracellular anchor, which the
plan did not anticipate and the arabinoxylan fixture found. The second is that
the externally drafted source proposal was **not** copied into `inst/doc/`, as
the plan had said it would be; §2, §3 and §8 of the superseding document already
record what it got right, every duplication and gap with evidence, and every
refusal with a reason, and 1400 further lines saying the same thing less
accurately would make the design record harder to read rather than more
complete.

`R CMD check --no-manual` on the built tarball: one NOTE, the pre-existing
installed size of the compiled database and HTML atlas. Full suite green at
3566.

### 2026-08-19T05:05Z — Assessability: when a negative call may enter a denominator

**Change.** A new internal layer in `R/assessability.R`, and `quality`,
`policy` and `threshold` arguments on `genome_traits()` and
`gifter_community()`. Two new metrics, `assessable_fraction` and
`provider_fraction`. **No schema, database content or evaluation change.**
This is phase 4 of `inst/doc/proposal-quantitative-traits.md`, and the gap that
made the externally drafted proposal unimplementable as written.

**Why.** `evaluate_gifts()` answers one question — do the observed markers
support a complete curated implementation — and answers it identically for a
closed isolate genome and a 60%-complete MAG, because the markers are all it
sees. That is right for a call and wrong for a denominator: a genome that was
never fully observed has not been shown to lack anything. Every proportion in
this layer was resting on that conflation.

**Effect.** A third state sits on top of the Boolean call under an explicitly
named policy. `"none"` is the default and declares nothing indeterminate, so
existing behaviour is unchanged and `assessable_fraction` states the assumption
in the output rather than leaving it implied. `"completeness"` requires a
genome completeness estimate and an explicit threshold, and treats every
negative call on a genome below that threshold as indeterminate, removing it
from every denominator while leaving every positive call exactly as it was.

Two constraints bind every policy that will ever be added here, and both are
tested. No policy may promote an unsupported GIFT to supported: quality informs
the reading of absence and nothing else. And indeterminacy is resolved per
genome, so a fragmented member's silence is withheld from a provider
denominator while a complete member's is not — which is what `provider_fraction`
now divides by.

Three refusals. The `"completeness"` policy has **no default threshold**,
because how complete a genome must be before its silence is informative is the
analyst's declared choice and a package default would be read as a
recommendation. The policy is deliberately blunt — it does not try to guess
which capability a fragmented assembly lost — because gifter has no validated
model of gene loss and a finer rule would imply a precision it cannot support;
the graduated `"near_miss"` policy stays recorded as a candidate rather than
shipped. And a proportion computed over a frame that has quietly collapsed
now warns: at 30% completeness a supported fraction of 1.0 over one assessable
GIFT is arithmetically fine and biologically empty, so the reader is pointed at
`assessable_fraction` before they quote it.

28 new tests in `test-assessability.R`; full suite green at 3566.

### 2026-08-19T04:45Z — Community resource-handoff topology, bounded by the compartment model

**Change.** One new exported function, `community_network()`, in the new
`R/community-network.R`. **No schema, database content or evaluation change.**
This is phase 3 of `inst/doc/proposal-quantitative-traits.md`.

**Why.** `gift_graph` already decides when one GIFT's declared output anchor
reaches another's declared input. Projecting that decision onto a pair of
genomes is the whole of community topology, and inventing a second
compatibility rule for it would put a biological definition in two places.

**Effect.** A directed edge means one genome supports a GIFT whose output anchor
another genome's supported GIFT consumes. Edges carry the `from_gift`,
`to_gift`, `shared_anchor` and the `edge_quality` of the GIFT edge beneath them,
so a handoff resting on an unlicensed compartment reads as
`compartment_inexact` rather than as an ordinary edge. `chain_coverage`
classifies every curated composition link as completed `within_genome`,
completed only `community_distributed`, `not_transferable`, or
`not_represented`, retaining the genomes behind each. `cycle_coverage` asks the
same question of the elementary cycles of the anchor graph.

**One rule was added that the plan did not anticipate, and it changes results.**
A cross-genome edge requires the producing GIFT's output anchor to be declared
`extracellular`. Without it, the arabinoxylan fixture produced edges C → D and
D → C through `XYLOSE_IN` — a **cytoplasmic** anchor — which asserts that one
organism hands another a molecule that never leaves a cell. A `cytoplasmic`
anchor is inside one cell by construction and an `unspecified` one was never
evidenced as leaving it, so neither licenses a transfer. The same link inside a
single genome is an ordinary composition step and is still reported as one,
which is why `chain_coverage` gained the `not_transferable` status: when the two
halves of an internal link fall in different genomes, nothing completes it, and
calling that distributed would be exactly the error the anchor compartment
qualifier exists to prevent. Distributed cycle closure carries the same
restriction and therefore reports `not_closed` for the oxidative citric acid
cycle however the community is composed, because central metabolism runs on
intermediates that never leave a cell.

With the rule in place the fixture yields the three edges the design predicted —
A → B, B → C, B → D — and no others.

49 new tests in `test-community-network.R`; full suite green at 3538.

### 2026-08-19T04:20Z — Genome-resolved communities and distributional traits

**Change.** Two new exported functions, `gifter_community()` and
`community_traits()`, in the new `R/community.R`. **No schema, database content
or evaluation change.** This is phase 2 of
`inst/doc/proposal-quantitative-traits.md`.

**Why.** Every community question — how redundantly is a capability provided,
which genome is its only provider, how much of the sampled abundance carries it
— needs a container that holds several genomes' calls at once, and
`evaluate_gifts()` evaluates one annotation table. The externally drafted
proposal assumed such an object into existence without defining it, which is
why defining it is a phase of its own rather than a detail of the metrics.

**Effect.** `gifter_community()` binds named results into one call matrix and
refuses two comparisons that are not comparable: genomes evaluated against
different database releases, because a provider count over two releases counts
capabilities that were not offered to every genome, and an abundance vector
that does not name exactly the supplied genomes. A GIFT missing from a genome's
result is not supported, so a filtered evaluation cannot claim a capability it
never tested.

`community_traits()` reports `community_richness`, `community_coverage` for
bounded frames, `mean_genome_richness` beside it rather than divided into
it, `provider_count` per GIFT, `abundance_coverage` per GIFT when abundance was
supplied, `singleton_fraction`, `unique_contribution` per genome and
`repertoire_overlap` per genome pair — all within every supplied frame, in
the same long-form shape phase 1 established, with `target_type` distinguishing
community, GIFT, genome and genome-pair rows.

Presence and abundance never merge. `provider_count` and `abundance_coverage`
are separate rows with separate units, because how many genomes encode a
capability and how much of the observed abundance they represent answer
different questions and neither is a statement about activity. Overlap is
computed within a frame rather than only across the catalogue: 94% of the
GIFTs are metabolic, so an unstratified Jaccard index is a metabolic overlap
under a general name. Where both genomes of a pair hold nothing in a frame
the overlap is withheld rather than reported as zero, since reporting zero
would say two repertoires were compared and found to share nothing.

The arabinoxylan chain is the integration fixture and it is curated, not
invented: `arabinoxylan_debranching -> xylan_degradation -> xylose_uptake_abc ->
xylose_degradation_isomerase` are already connected in `gift_graph`. Its marker
sets are chosen so each genome completes exactly the intended capabilities,
which the first test checks rather than assumes — several CAZy families
evidence both debranching and backbone cleavage, and a careless fixture would
give one genome two capabilities and destroy every expected provider count.

54 new tests in `test-community-traits.R`; full suite green at 3489.

### 2026-08-19T03:55Z — Reference frames and quantitative genome traits

**Change.** Two new exported functions, `reference_frame()` and
`genome_traits()`, in the new `R/frame.R` and `R/traits.R`. **No schema,
database content or evaluation change**: the database is byte-identical and no
call moves. This is phase 1 of
`inst/doc/proposal-quantitative-traits.md`.

**Why.** The architecture guide's *Derived capabilities* section already
promised this layer — "a derived layer would read their calls rather than
adding a fifth type" — and invariant 18 requires higher-order descriptions to
be derived from primary typed GIFTs rather than curated as one. With 130 GIFTs
the question "how many, of what kind, how distributed" is now worth asking, and
asking it without a declared denominator is what makes such numbers
untrustworthy. A count of supported GIFTs is meaningless without the set it was
counted over, and that set changes between releases.

**Effect.** `reference_frame()` builds a reference frame from curated metadata
only — `gift_type`, `mode`, the registered facet vocabulary, and the derived
`gift_profile` view. A frame may not be a list of `gift_id`s written in R,
which is invariant 10 applied one layer up. `genome_traits()` reports
`gift_richness`, `breadth_*` over every facet and profile classification,
`handoff_out_degree` and `handoff_in_degree` from `gift_graph`,
`multi_implementation_gifts` and `closed_cycles`, each within every supplied
frame, as a long-form table carrying `numerator`, `denominator`,
`assessable`, `reference_frame` and `database_version`, plus a `trace` table
naming the GIFTs behind every row.

Three refusals are built into the behaviour rather than left to documentation.
`supported_fraction` is reported **only** for a frame explicitly declared
`bounded`, because a fraction of an open and growing catalogue reads as the
share of microbial function a genome carries; the default set bounds exactly
one frame, the biomass-essential anabolic GIFTs, over which the fraction is
biosynthetic capability coverage. Handoff degrees are withheld from a frame
that does not reach the metabolic model, because a structural GIFT declares no
anchors and reporting zero would imply a test the genome failed. And traits
computed against a database version other than the one that produced the calls
are an error, not a warning.

`assessable` currently equals the size of the frame: gifter accepts no
genome-quality information, so every member is treated as assessed. That column
exists now so its shape is stable when phase 4 adds the assessability policy.
Nothing in this layer can change a Boolean call, and `closed_cycles` reads
`evaluate_gift_cycles()`, which already guarantees the same.

81 new tests in `test-frames.R` and `test-genome-traits.R`; full suite green
at 3435.

### 2026-08-19T13:10Z — Mercury detoxification curated: the first defense GIFT that is not anti-phage

**Change.** Database version **2026.19.1**, schema unchanged at 6, **no R code
change**. One defense GIFT, `mercury_detoxification`, with one mechanism
(`MECH_MER_HG`), four defense functions, six systems, seven components and eight
markers, plus the `defense_class` value `chemical_detoxification`. 129 GIFTs
become 130.

**Why.** The assessment is `inst/doc/proposal-aromatic-degradation.md` §8.8, its
class decision §10.6, and its implementation record §17. Hg(II) reduction has a
Rhea master but no honest `mode`: it is not a directed conversion between
nutrient anchors, and a fifth mode invented for one trait would put mercury into
the anchor graph as edges through metal-ion anchors that mean nothing. The
defense contract already covers a chemical challenge, and the machinery model
supplies the required-and-accessory distinction the *mer* operon needs.

**Effect.** MerA alone completes the call, because a genome carrying *merA*
detoxifies the Hg(II) that reaches its cytoplasm; requiring *merT* and *merP*
would refuse the genomes whose operon is built around *merC* or *merE*. Delivery,
induction and organomercurial lysis are accessory and report as unsupported
without changing the call. `TIGR02053` stands beside `K00520` as an alternative
at `high-confidence`, so a genome hit only by the NCBIfam family calls the GIFT
complete at the weaker confidence. Three refusals are recorded rather than left
implicit: `NF033555` and the InterPro entries, because the evidence layer
normalises KO, EC, Pfam, TIGRFAM, CAZy and custom HMMs only and an unmatchable
accession reads as evidence; `K19057` (MerD), because it is a co-regulator and
evidence rows are alternatives, so it would let a genome with no activator claim
induction; and mercury methylation (*hgcAB*), which makes mercury more toxic and
is a different capability. Three `database_changes.tsv` records carry the
decisions. Five new tests in `test-regulatory-defense.R` and four inventory
expectations updated; full suite green at 3354.

### 2026-08-19T12:30Z — Assessment: the mercury defense class is named for the mechanism

**Change.** Documentation only. `inst/doc/proposal-aromatic-degradation.md`
gains §10.6 and resolves its open question §14.3: the `defense_class` value
§8.8 needs is **`chemical_detoxification`**, not `metal_detoxification` and not
a resistance class. **No code, schema, database content or facet registration** —
mercury is still uncurated, and a facet vocabulary is registered when the first
content needing it is curated.

**Why.** `defense_class` is single-valued and partitions the defense type, so
the name is the bucket every future defense GIFT falls into exactly once, and
the way to choose it is to write out what each candidate would have to hold.
A resistance class fails three ways: its roster is mostly *not* defense GIFTs
(metal efflux is transport, MerR and CmtR are regulatory, lipid A modification
is structural); resistance is an outcome, which `proposal-defense-gifts.md`
refuses twice and which §15 of the aromatic proposal already disclaims for this
very GIFT; and invariant 18 puts phenotypic descriptions in a derived layer. The
curated vocabulary says the same thing already — `restriction_modification` and
`crispr_cas` are both anti-phage and were deliberately not merged into
`phage_resistance`. `metal_detoxification` fails differently: it holds three
curatable members ever, because ArsM has no orthology group, ChrR's group is a
generic NAD(P)H:quinone dehydrogenase, and ArsC's product is *more* toxic than
its substrate.

**Effect.** Mercury will be curated with `defense_class = chemical_detoxification`
when §8.8 is implemented. The class is defined by a mechanism test — enzymatic
conversion of a toxic chemical into a less harmful species — which excludes
efflux, sequestration and repair by construction, and admits a populated roster
of markable future members: SOD and catalase, AhpC and Ohr, Hmp and NorV, GloAB,
FrmAB, TehB and CueO. Two follow-ons are recorded rather than decided: a
separate multi-valued `challenge_class` facet if the "against what" axis is ever
needed, and the §10.3 test applied a second time to formaldehyde, which is
detoxification in most organisms and carbon metabolism in methylotrophs.

### 2026-08-19T05:10Z — `gift_cycles()` stops reporting direction reversals as cycles

**Change.** `gift_cycles()` excludes any elementary cycle whose members include
both an `anabolic` and a `catabolic` GIFT, alongside the two-node
`interconversion` loop it already excluded. `evaluate_gift_cycles()` follows,
because it reads what `gift_cycles()` derives. The accessor documents both
exclusions, and `R/cycles.R` records why.

**Why.** The amino acid layer curates both directions for arginine, proline,
threonine, cysteine and methionine, and every such pair closes a ring in the
composition graph. A ring that alternates modes says a genome can both build a
metabolite and break it down — which the composition rule already treats as
expected, and is why the source validator checks acyclicity per mode — so it is
not circular metabolism. It is also not harmless to report: the mixed rings
combine, and before the exclusion the enumeration returned a truncated list of
100 in which the oxidative citric acid cycle appeared at position 34.

**Effect.** `gift_cycles()` returns one cycle for the curated database, the
oxidative citric acid cycle, as it did before the amino acid layer. No GIFT call
changes: closure never fed back into a call. Edges are untouched — the exclusion
is about what counts as a cycle, not about what counts as composition.

### 2026-08-19T05:00Z — Amino acid metabolism curated: 28 GIFTs

**Change.** Database version **2026.19.1**. The fifteen proteinogenic amino
acids gifter did not cover are curated as eighteen composable biosynthesis GIFTs,
and amino acid degradation arrives with ten more. Schema unchanged at 6; no R
change other than the cycle exclusion above.

**Why.** The assessment is `inst/doc/proposal-amino-acid-metabolism.md`, whose
§16 records where the implementation departed from it. Six boundaries are
gifter's own rather than KEGG's, each at a branchpoint where genomes measurably
differ — meso-diaminopimelate, the two branched-chain 2-oxo acids, threonine
deamination as catabolism, glutamine as its own capability, and the widened
aromatic transaminase.

**Effect.** 89 GIFTs become 129 and 109 anchors become 140. Four boundaries that
were declared inputs with no producer gain one — L-aspartate, L-glutamine,
3-methyl-2-oxobutanoate and hydrogen sulfide — so pantothenate, pyrimidine,
pyridoxal phosphate and the two sulfide-dependent biosynthesis GIFTs stop
hanging off the graph. `auxotrophy_indicator` now reports on all twenty amino
acids rather than five. No existing GIFT call changes: no curated route, system,
component or marker was edited, with one correction: L-aspartate and
L-glutamine were marked `biomass_essential = no` from when they existed only as
input boundaries, and both are proteinogenic. Seven `database_changes.tsv`
records carry the biological decisions, including that correction, the
deliberate under-call of cysteine desulfidation and the promotion of acetyl
phosphate to an anchor.

### 2026-08-19T11:20Z — Aerobic aromatic ring catabolism curated; mercury carved out

The assessment is `inst/doc/proposal-aromatic-degradation.md`, whose §16 records
the implementation. **No code change and no schema change** — this is a content
release, database version 2026.19.1, and the proposal's first claim was that the
layer needed neither.

Twelve metabolic GIFTs, twelve anchors, thirty reactions and forty-nine markers.
Three peripheral entries (benzoate, anthranilate, phenol) converge on catechol,
both cleavage strategies leave it, the aerobic phenylacetate route joins at the
3-oxoadipyl-CoA thioester, and the phenylpropanoid node feeds the shared lower
route. Thirteen composition edges, all through declared anchors.

**Mercury was carved out** at the user's direction and is being assessed
separately, so no defense GIFT and no `defense_class` facet value were
added. Fourteen of the twenty-four candidates assessed stay refused, nine of
them because no marker in any namespace resolves which ring a Rieske dioxygenase
hydroxylates; the register is `DBC-20260819-AROMATIC-REFUSALS`.

Four decisions worth reading in the proposal's §16.

- **Where KEGG bundles, gifter cuts.** The lower *meta* route that five modules
  duplicate is curated once as `oxopentenoate_degradation`; the thiolysis that
  ends both the ortho funnel and the phenylacetate route is curated once as
  `oxoadipyl_coa_thiolysis`; and M00545, which ORs two different input
  substrates into one module, becomes three GIFTs around a shared anchor,
  because a route must connect its own GIFT's boundaries.
- **`K07104` is refused** as evidence of catechol 2,3-dioxygenase: 2081 genomes,
  led by Firmicutes that do not degrade aromatics, only 276 of which carry any
  lower *meta* gene. A test pins the refusal in both branches.
- **Shared Rieske ferredoxin and reductase subunits are deliberately not curated
  as components**, because `enzyme_component` has no `required` flag and those
  subunits are annotated two to three times less often than the subunits they
  serve. The omission is stated in each system description, and a test proves the
  excluded reductase is inert.
- **One predicted broadening did not happen.** Adding MhpF and XylQ as
  alternative systems of the acetaldehyde dehydrogenase reaction was expected to
  broaden `ethanol_formation`; measurement showed it does not, because that
  route's second reaction rests on AdhE alone. The change record was corrected
  from `broadens` to `none`.

`tests/testthat/test-aromatic.R` adds 209 assertions. Two existing tests were
updated because the new content is genuinely visible to them: `test-scfa.R` now
expects the aromatic funnel among acetyl-CoA producers, and `test-organic-acid.R`
admits one non-cycle producer of succinate while keeping its guard that no
`_formation` trait may produce it.

### 2026-08-19T00:20Z — Shikimate-derived aromatic biosynthesis curated

The assessment is `inst/doc/proposal-shikimate-aromatics.md`. Three metabolic
GIFTs added, one candidate refused, database version **2026.17.1**.

**Change.** `chorismate_biosynthesis` (PEP + erythrose 4-phosphate to
chorismate, 7644 of 10 151 bacteria and 90 of 470 archaea),
`salicylate_biosynthesis` (chorismate to salicylate, 646 bacteria) and
`indole_3_acetate_biosynthesis` (L-tryptophan to the auxin, 86 bacteria) are
curated over ten new reactions, all with Rhea masters. `gallate_biosynthesis` is
refused. A `biosynthetic_family` facet is registered and
`shikimate_derived_aromatic` assigned to the three new GIFTs and to
`paba_biosynthesis` and `menaquinone_biosynthesis`. No schema migration and no R
change.

**Four decisions are worth reading.**

- **The family is a facet, not a GIFT.** "Aromatic compound biosynthesis" cannot
  be one capability: two of the four candidates do not have chorismate on either
  side of the arrow, so a single GIFT would have to declare boundaries no route
  connects. `substrate_class` was deliberately not reused for the grouping —
  the five GIFTs carrying the new value hold two different substrate classes
  between them, which is the demonstration that the facets are orthogonal rather
  than redundant.
- **The shikimate dehydrogenase step is curated as not required.** `K00014`
  reaches 5585 bacteria where every other step of the pathway reaches 8461 to
  9149, and requiring it removes 201 of 213 Cyanobacteriota and 1061 of 1642
  Actinomycetota. *M. tuberculosis* Rv2552c and *Synechocystis* slr1559 are
  annotated shikimate 5-dehydrogenase in RefSeq and carry no KO at all. This is
  the vitamin layer's orphan-step rule applied to a marker with a taxonomic hole
  rather than a specificity problem, and `TIGR00507` is added alongside `K00014`
  so an InterPro-annotated genome can satisfy the step — the first metabolic
  marker added for coverage rather than for specificity.
- **MbtI is a system, not a route.** The bifunctional salicylate synthases run
  the same two transformations as PchA and PchB, with the isochorismate
  enzyme-bound rather than released, so they belong at the system layer exactly
  as the bifunctional PabBC already does. Because systems attach to reactions
  rather than routes, accepting PchA and MbtI for `RHEA:18985` also reaches the
  menaquinone route; that was measured before the decision and adds 7 genomes.
- **Three of four auxin routes are refused.** The indole-3-pyruvate, tryptamine
  and nitrile routes are real chemistry whose markers cannot distinguish auxin
  formation from ordinary transamination, decarboxylation or aldehyde oxidation.
  `K04103` is the sharpest case: 417 of its 648 bacterial carriers are
  Enterobacteria and KEGG assigns it in *Salmonella* to a protein annotated only
  as a putative thiamine pyrophosphate enzyme.

**Gallate fails earlier than the specificity question.** Rhea records gallate in
nine reactions and **none forms it from 3-dehydroshikimate**; there is no EC
number for the transformation and no KO, TIGRFAM or Pfam family for a
gallate-forming dehydrogenase. With no reaction identity there is nothing to
curate, and the only enzymes described as doing it are plant shikimate
dehydrogenases whose markers are the AroE markers of the core pathway. A curated
`CUSTOM_HMM` could not rescue it today either: the characterised sequences are
plant, so there is nothing bacterial to train on. Gallate release from
hydrolysable tannins by tannase (`K10759`, EC 3.1.1.20) is different chemistry
between different boundaries and is deferred, not refused.

**Effect.** `paba_biosynthesis` and `menaquinone_biosynthesis` gain an upstream
neighbour and move from `entry` to `intermediate` in `gift_profile`; `CHORISMATE`
is the first of the four orphan input anchors named in the amino acid assessment
to close. `indole_3_acetate_biosynthesis` reports as `isolated`, which is the
correct answer while nothing in gifter produces tryptophan. Three inventory
assertions in `test-database.R` — the GIFT roster, the shared-anchor set and the
database version — were refreshed against the compiled database.

### 2026-08-19T00:05Z — Assessment: the rest of amino acid metabolism

The assessment is `inst/doc/proposal-amino-acid-metabolism.md`. **No code,
schema or biological content change** — this entry records that the layer was
tested and what the test found.

**Change.** The fifteen proteinogenic amino acids gifter does not curate, plus
amino acid degradation and microbial transformation for all twenty, were tested
against KEGG orthology over the 10 151 bacterial genomes of KEGG, Rhea 141 and
ChEBI 253. Twenty biosynthesis GIFTs and ten degradation or transformation GIFTs
are recommended, six candidates are deferred pending a boundary decision
elsewhere, and six are refused as named. No schema migration and no R change is
required by any of it.

**Four findings are worth reading even if the layer is never curated.**

- **The amino-donor rule.** Glutamate is a co-substrate of nearly every reaction
  in the layer. Declaring it an anchor wherever it is consumed would give
  sixteen new GIFTs an edge from one node and turn `gift_graph()` into a star.
  The rule — the nitrogen donor of a transamination is never an anchor, the
  nitrogen source of an assimilation always is — is the nitrogen analogue of the
  sulfur split the methionine and cysteine GIFTs already encode.
- **An assimilatory cycle cannot be decomposed by anchors.** GS and GOGAT form a
  genuine cycle between two anabolic capabilities, and `.find_graph_cycle()`
  rejects anabolic cycles by design. The citric acid cycle could be cut only
  because two of its four segments are `interconversion`; here the cycle has to
  live inside one GIFT. This is the first case where real biology collides with
  the acyclicity rule rather than exposing a bad boundary.
- **KEGG's amino acid modules under-call by construction, measurably.** The four
  lysine modules score 51.4%, 5.6%, 6.8% and 17.2% separately and 75.3% as
  alternative routes of one capability. Requiring KEGG's aromatic
  aminotransferase calls phenylalanine biosynthesis in 2296 genomes where the
  discriminating aryl skeleton is present in 7796; widening the marker set to
  the aspartate and branched-chain aminotransferases recovers 7733, which shows
  the step carries no information rather than that it is missing.
- **Four orphan input anchors close.** `ASPARTATE`, `CHORISMATE`, `GLUTAMINE`
  and `OXOISOVALERATE` are declared as inputs today and produced by nothing, so
  pantothenate, folate, menaquinone and the aspartate family currently hang off
  the composition graph.

**Effect.** Documentation only. The assessment also reconciles two overlaps with
the assessments filed the same day: it adopts the nitrogen-anchor rule of
`proposal-nitrogen-compound-catabolism.md` unchanged, recommends that
`ammonium_assimilation` and `glutamate_biosynthesis` be one GIFT under one name,
corrects that assessment's ammonium assimilation prevalence from 9482 to 8686
genomes — glutamine synthetase without a glutamate synthase is not a net
assimilation route, and 796 genomes have exactly that — and records that the
`ACETYL_PHOSPHATE` anchor question can no longer be deferred, because glycine
reductase has no other product to declare and the validator requires an output
anchor.

### 2026-08-18T23:40Z — The overview networks become dots you point at

**Change.** The two networks on the atlas overview are no longer layered
diagrams of labelled boxes. Both are now drawn by `.report_dot_network_svg()`:
a GIFT is a large coral dot, an anchor a small mint dot, edges are hairlines,
and **nothing in the drawing carries text**. Pointing at a dot dims every node
and edge it is not connected to and opens a card next to it with the name, the
identifier, the declared boundaries, and the route and reaction counts;
clicking a GIFT dot opens it in the GIFT explorer, the same detail the summary
table opens. Dots are placed by `.report_force_layout()`, a deterministic
Fruchterman-Reingold sweep seeded on a golden-angle spiral, so the drawing is
identical between builds without carrying a random seed. Gravity is stronger
along the short axis, which settles the layout into an ellipse shaped like the
frame instead of a disc that has to be squashed into it.

**Why.** Both views were laid out in longest-path columns of 246-pixel boxes.
With 72 GIFTs and 89 anchors that is a canvas several thousand pixels wide,
scrolled sideways, where reading a name meant finding the box and reading the
structure meant losing it. The overview asks one question -- *how do these
traits connect* -- and the shape of the graph is the answer to it. Every label
that was printed on the canvas is still there, one hover away, and the layer
that actually names things, the GIFT explorer, is now one click from any dot.

**Effect.** Presentation only: no query, no call, and no curated row changed.
The per-GIFT route networks are untouched, and still draw labelled reaction
boxes, because there the labels *are* the content. Edge tooltips are gone from
the two overview networks -- what an edge asserts is now read off the two dots
it joins -- so the anchor network is tested through its `data-edge-from` and
`data-edge-to` attributes instead of through edge titles.

### 2026-08-18T23:10Z — Assessment: aromatic degradation and mercury, 21 requested capabilities

The assessment is `inst/doc/proposal-aromatic-degradation.md`. **No code, schema
or biological content change** — this is a recorded evaluation, and its main
result is a register of refusals.

The request was the 21 capabilities of KEGG's *Xenobiotics biodegradation*
module category plus mercury. Twenty-four candidates were tested against KEGG
orthology prevalence (11 949 genomes), Rhea, and InterPro/NCBIfam. Six are
recommended for curation, two conditionally, two deferred, and **fourteen
refused** — nine of them for one reason: substrate specificity in
ring-hydroxylating dioxygenases is not resolvable by any marker gifter can use,
and unlike the butyrate case in the SCFA proposal, no namespace change rescues
them. The families available are `IPR001663` and `PS00570`, which are the family
signature itself.

Four findings are worth reading even if the layer is never curated.

- **A KEGG module is not a GIFT, demonstrated twice by chemistry.** M00538
  attaches the *tmo* ring monooxygenase system to toluene → benzyl alcohol, but
  Rhea's master for the EC KEGG itself assigns that system is toluene →
  4-methylphenol; side-chain hydroxylation is a different enzyme in a different
  module. M00548 attaches a phenol 2-monooxygenase to benzene oxidation. Both
  were found only because gifter requires a Rhea master per reaction.
- **`enzyme_component` has no `required` flag, and this layer is the first
  content to want one.** Rieske ferredoxin and reductase subunits are shared,
  interchangeable and annotated 2–3× less often than the catalytic subunits they
  serve, so curating them under AND converts an annotation gap into a false
  negative. The proposal recommends solving it in curation rather than migrating
  the schema, and records the case as the strongest reason to revisit that.
- **Mercury belongs to the `defense` type, not to a fifth `mode`.** Hg(II)
  reduction is neither anabolic, catabolic, transport nor interconversion; the
  defense contract already covers a chemical challenge, and the machinery model
  already expresses the accessory *merTP*, *merR* and *merB* functions.
- **`K07104` is an over-broad marker** assigned in 2081 genomes dominated by
  Firmicutes that do not degrade aromatics, only 276 of which carry any lower
  *meta* pathway gene. The route logic would hide the damage inside one GIFT; the
  marker would still be in the database for the next one.

### 2026-08-18T23:50Z — Nitrogen compound catabolism curated

Database **2026.18.1**, schema 6 unchanged. **No code changed**; this entry
records the content release and the two architecture rules it required, both now
in `inst/doc/architecture.md`. The assessment is
`inst/doc/proposal-nitrogen-compound-catabolism.md`, whose §17 records the
implementation and every point where it departed from the proposal.

**Content.** Fourteen GIFTs: `urate_degradation`, `allantoin_degradation`,
`urea_hydrolysis`, `nitrate_assimilation`, `betaine_demethylation`,
`sarcosine_demethylation`, `creatinine_degradation`,
`carnitine_degradation_trimethylamine`, `carnitine_to_betaine`,
`methylamine_degradation`, `taurine_desulfonation_aerobic`,
`taurine_degradation_sulfoacetaldehyde`, `taurine_uptake_abc` and
`ammonium_assimilation`. Sixteen anchors, seven facet terms, 26 routes, 37
reactions, 39 enzyme systems, 55 components, 57 markers. `glcnac_degradation`
and `neuac_degradation` gained `AMMONIUM` as an output anchor, which changes no
call: both already ended at the deaminase that liberates it.

**Two rules are now in the architecture guide.** The **nitrogen-anchor rule**
admits ammonium as an anchor only where the reaction's purpose is to liberate or
assimilate it, and it sits beside the cofactor-anchor rule under *Keeping the
anchor vocabulary small*. The **electron-acceptor rule** is now an explicit item
in *What gifter deliberately does not model*, generalising the refusal that was
previously recorded only on the `FUMARATE` anchor.

**Three departures from the proposal, all found by checking Rhea before
curating.** The carnitine dehydrogenase route yields glycine betaine, not
trimethylamine — `RHEA:47044` makes the betainyl thioester and `RHEA:45716`
hydrolyses it — so it became its own GIFT and the trimethylamine claim narrowed
from 972 genomes to 271. The anaerobic taurine GIFT declares no ammonium,
because its two routes dispose of the nitrogen differently (alanine from the
transaminase, ammonium from the dehydrogenase) and a GIFT anchor must hold for
every route. `allantoin_degradation` declares none either, for the same reason.

**Tests.** `tests/testthat/test-nitrogen.R` adds 101 assertions, including the
negative cases that eleven respiratory accessions match no marker at all and
that a primary-amine oxidase does not fire a phenylethylamine trait. Four
existing inventory assertions moved for the new content: the compartment-split
molecule list, the no-external-link GIFT list, the dual-specificity importer
test (which filtered on `mode == "transport"` and so swept in the new taurine
importer), and the sugar-degradation downstream assertion, which now protects
what it was actually for — that no *carbon* anchor reaches a biosynthesis GIFT
— rather than forbidding the legitimate catabolic-to-anabolic ammonium edge.

### 2026-08-18T23:15Z — Nitrogen compound catabolism assessed

The assessment is `inst/doc/proposal-nitrogen-compound-catabolism.md`. **No
content was curated and no code changed**; this entry records that the layer was
tested, what the test found, and the two rules the layer cannot be curated
without.

**Change.** The twelve compounds of distillR 1.x bundle D06, "Nitrogen compound
degradation" — nitrate, urea, urate, GlcNAc, allantoin, creatinine, betaine,
L-carnitine, methylamine, phenylethylamine, hypotaurine and taurine — were
tested against KEGG orthology, Rhea 141, ChEBI 253 and the installed distillR
`GIFT_db`, over all 10 151 bacterial genomes in KEGG. Eleven GIFTs are
recommended and two more conditionally; two existing GIFTs gain an output
anchor; six traits and two routes are refused.

**Two rules are proposed, and the layer cannot be curated without either.** The
**nitrogen-anchor rule** admits `AMMONIUM` as an anchor only where a reaction
exists to liberate or assimilate it; applied to the database as it stands it
admits one of the four existing NH4+ reactions and rejects three, which is what
stops riboflavin and menaquinone biosynthesis becoming nitrogen sources and NAD
biosynthesis becoming a nitrogen sink. The **electron-acceptor rule** generalises
the refusal already recorded on the `FUMARATE` anchor: a capability whose
completion needs an external terminal electron acceptor is out of scope, which
refuses nitrate respiration, denitrification, DNRA and "taurine to hydrogen
sulfide" architecturally rather than evidentially.

**Two findings bear on how much weight the legacy database should carry.**
distillR's `D0613 Taurine` is defined in part by EC 2.5.1.55, which is KDO
8-phosphate synthase (`kdsA`, K01627), a lipopolysaccharide enzyme present in
5537 of 10 151 bacteria — almost certainly a transposed digit for 2.5.1.76,
cysteate synthase, at 39. And `D0612 Hypotaurine` is defined by a taurine
enzyme plus a generic aldehyde dehydrogenase, so it cannot distinguish the two
compounds. Neither is an argument against distillR, which used a different
primitive; both are arguments for the existing rule that the legacy database is
a coverage checklist and never an evidence source.

**One correction is owed to `SOURCES.md`.** MetaCyc is reachable again through
`websvc.biocyc.org/getxml` for records addressed by ID, so the recorded reason
for not citing it — subscription gating — is now wrong. gifter still cites no
MetaCyc row, and the proposal's §4 gives the structural reason that does not
depend on access.

### 2026-08-18T21:30Z — Circular central metabolism, and a scope fix for the acyclicity check

The assessment is `inst/doc/proposal-central-metabolic-cycles.md`. It recommends
option 1 of the three it evaluates: atomic segment GIFTs plus **derived** cycle
detection, with no schema migration and no circuit table. The schema stays at
version 6.

**The within-mode acyclicity check is now scoped to the directed modes.** This
is a bug fix and is independent of any citric acid cycle content. The
`interconversion` mode requires every anchor to be declared in both roles, so
two interconversion GIFTs that share one anchor produce an edge in each
direction *by construction*; the check reported that as a circular composition
error. Two synthetic reversible GIFTs sharing one fixture anchor reproduce it
with no biology involved. `.gifter_directed_gift_modes` now names the three modes
that declare a direction, and the scan iterates those. Loops in `anabolic`,
`catabolic` and `transport` are still errors, which `test-composition.R` asserts
alongside the new exemption.

**`gift_cycles()` derives the elementary cycles of the composition graph.** It
is graph code with no biology in it: the oxidative citric acid cycle falls out
of four curated anchor declarations, and the same function will find the
reductive cycle, the glyoxylate bypass or the Calvin cycle when those are
curated. A two-node loop between two reversible GIFTs is excluded, for the same
reason the validator exempts it. Enumeration is bounded by `limit` and warns
rather than running unbounded.

**`evaluate_gift_cycles()` reports closure for a genome** — `closed`, `open`
with the unsupported members named, or `absent` — from an `evaluate_gifts()`
result. It never changes a call. A segment is complete on its own routes and
markers whether or not its neighbours are, and a `closed` cycle is a statement
about encoded chemistry rather than about flux, direction or expression.

The only curated part of a cycle is its name, which is a new multi-valued GIFT
facet, `metabolic_cycle`. Structure is derived and naming is curated, so the two
cannot drift apart.

`R/cycles.R` is new. `R/database-build.R` gained the mode constant and the
scoped scan. `inst/doc/architecture.md` gained a "Cycles in the composition
graph" section and AGENTS.md invariant 8 was rewritten. Biological content is
recorded separately, as `DBC-20260818-CENTRAL-CYCLE-LAYER`.

### 2026-08-18T20:30Z — Vitamin biosynthesis curated

The assessment is `inst/doc/proposal-vitamin-biosynthesis.md`, whose §14 records
what implementation changed. **No schema and no R change** — the layer is a
content release, 2026.15.1, and the proposal's first claim was that it could be.

**Change.** Twenty GIFTs covering vitamins B1, B2, B3, B5, B6, B7, B9, B12 and
K2: 31 anchors, 26 routes, 94 Rhea-mastered reactions, 104 enzyme systems and
151 marker assignments. `substrate_class` gains `cofactor`,
`physiological_role` gains `vitamin_biosynthesis`, and `resource_origin` gains
`microbially_derived` for the precursors a genome acquires from its neighbours.
Thirteen `database_changes` entries accompany it, eleven of which record a
refusal or a boundary decision rather than an addition.

**What the layer refuses to say.** A single "produces vitamin B12" trait is
refused twice over. 4139 of 10 151 bacterial genomes complete the cobamide
nucleotide loop and 3044 of those encode no corrin ring at all, so the loop is
curated as its own capability and a positive call on it is not a production
claim; and of the 1081 genomes that do complete ring, cobinamide arm and loop,
only 538 carry BluB, without which the product is a cobamide rather than the
vitamin. `dmb_biosynthesis_aerobic` is therefore separate, and a negative call
on it is explicitly not evidence that the genome cannot make the ligand, because
the anaerobic route has no orthology group.

**The orphan-step rule, and why it needed a test.** Four reactions in the layer
are certain chemistry with no marker at the specificity of the step. They are
curated with `required = 0` rather than deleted or evidenced by a widened
marker: requiring the riboflavin phosphatase would drop that trait from 7943 to
2682 bacterial genomes, and requiring the folate pyrophosphatase would drop
folate from 5898 to 1634. Two of the four — MenH and the DHNA-CoA thioesterase —
were curated as required in the first pass, which made *Bacteroides*-profile
genomes menaquinone-negative, and `tests/testthat/test-vitamins.R` caught it.

**Effect on users.** Twenty new callable GIFTs and 13 new composition edges, all
internal to the layer. `gift_profile()` reports `cross_feeding_output` as 0 and
`resource_strategy` as `private` for all twenty, because no vitamin transporter
is evidenceable, and `auxotrophy_indicator` as 1 for the twelve whose output is
a biomass-essential boundary. No existing GIFT call changes. `list_gifts()`
returns 68 rows, and the packaged database is version 2026.15.1.

### 2026-08-18T18:00Z — Organic acid formation curated

The assessment is `inst/doc/proposal-organic-acid-formation.md`. **No code
changed and the schema stays at 6**; this entry records what the content release
2026.14.1 added and, more usefully, what it refused.

**Change.** Six GIFTs: `lactate_formation`, `lactate_racemisation`,
`malolactic_fermentation`, `citrate_fermentation`, `ethanol_formation` and
`acetoin_formation`. Five anchors, nine Rhea-mastered reactions, twelve KO
markers. `substrate_class` gains `organic_acid` and
`neutral_fermentation_product`; `physiological_role` `fermentative_end_product`
is broadened from short-chain fatty acids to fermentation end products
generally.

**Why the request split in half.** The layer began as a request to express the
capacity to form fumarate, succinate, citrate and lactate. Those four are not
one class. Lactate is a fermentation end product a genome can be said to
release; the other three are citric acid cycle intermediates, consumed by the
pathway that makes them and present in every genome that has the cycle. Five
candidates are refused and the refusals are in `database_changes.tsv`:

- *Succinate.* On `frdABCD` it calls *Vibrio*, *Escherichia* and *Klebsiella*
  positive — fumarate respirers — and *Bacteroides*, *Prevotella* and
  *Fibrobacter* negative. Allowing the fused group instead fires in 7276 of
  11 855 organisms including *Chlamydia*. KEGG names that group `sdhA, frdA`.
- *Fumarate.* `K01756` is in 11 115 organisms, and gifter already curates the
  fumarate-releasing chemistry inside `purine_core_biosynthesis` and
  `adenylate_biosynthesis`.
- *Citrate synthesis.* `K01647` is in 8467 organisms; the trait would mean "has
  a citric acid cycle". The catabolic direction is curated instead.
- *Formate.* Refused on architecture, not evidence: `gift_anchor` is keyed on
  gift, role and ordinal, so declaring `FORMATE` on `pyruvate_to_acetyl_coa`
  would claim that all three of its routes produce it.
- *D-lactate formation.* Deferred; the (R)-lactate anchor is reached through the
  racemase, which is what the acrylate-route organisms actually do.

**The one result worth carrying forward.** `lactate_formation` is the first
fermentation end product in gifter whose direction is *evidenced* rather than
asserted. Acetate had to become an interconversion because Pta–AckA runs both
ways on one pair of genes; lactate does not, because forming it is an
NADH-consuming reduction and consuming it feeds a quinone or a cytochrome, and
KEGG gives those different orthology groups. 4143 organisms carry `K00016` and
3388 carry `K29125`, but only 573 carry both.

**A structural finding that outlives the layer.** Anchoring the citric acid
cycle closes a within-mode loop in anchor-derived composition and the build
fails — checked against `.find_graph_cycle()`, not predicted. There is no weak
boundary to demote the way `HOMOCYSTEINE` was, because no acid in the cycle is
only ever consumed. The constructive half is that a metabolite does not need an
anchor to be modelled: `citrate_fermentation` passes through oxaloacetate
without anchoring it, and malate and citrate enter as input-only boundaries.
`tests/testthat/test-organic-acid.R` asserts that no cycle metabolite is a
declared output anchor, which is the only durable protection against the
finding being rediscovered the expensive way.

**Tests that had to move.** `test-sugar-degradation.R` asserted the exact set of
GIFTs downstream of sugar catabolism; that set grows whenever a
pyruvate-consuming capability is curated, so it now asserts what the test was
actually protecting — the shared anchors and the downstream mode. Four
inventory assertions in `test-database.R`, one in `test-pathway-links.R` and one
in `test-scfa.R` were updated for the new content.

### 2026-08-18T17:00Z — Vitamin biosynthesis assessed

The assessment is `inst/doc/proposal-vitamin-biosynthesis.md`. **No content was
curated and no code changed**; this entry records that the layer was tested and
what the test found, so the next content release starts from the evidence rather
than from KEGG's module list.

**Change.** Candidate vitamin biosynthesis traits spanning twelve vitamins —
B1, B2, B3, B5, B6, B7, B9, B12, K2, C, E and provitamin A — were tested against
KEGG orthology, KEGG modules, Rhea, ChEBI and Pfam, over all 10 151 bacterial
genomes in KEGG and a panel of 18 reference genomes. Nineteen GIFTs are
recommended across nine vitamins; twelve further candidates are refused or
deferred. The proposal's five open questions were resolved the same day and are
recorded as §13 of the document: `GTP` is accepted as an input-only anchor and
the `GMP` link is deliberately left open, matching the `UMP`/`UTP` gap the
curated content already carries; the layer takes `substrate_class = cofactor`
with `physiological_role = vitamin_biosynthesis`, since the build enforces the
first as single-valued; menaquinone gets one anchor and a required MenG step;
the flavin kinase step stays uncurated; and `namn_salvage_nicotinate` is in the
first release.

**Why it is worth reading before the next content release.** The layer needs no
schema migration and no R change, and it is the first candidate layer whose
binding constraint is *per-step* evidence rather than per-trait evidence:

- *KEGG module definitions are not curatable boundaries here.* M00125 defines
  riboflavin completeness without lumazine synthase or riboflavin synthase,
  M00119 defines pantothenate without PanC or PanD, and M00127 defines thiamine
  as ThiF+ThiS+ThiI. Three of nine vitamins have a module whose `DEFINITION`
  omits the step the pathway is named for.
- *The orphan step is a new failure mode with a measured cost.* Four reactions
  in the layer are certainly present and have no marker at the specificity of
  the step. Requiring the riboflavin phosphatase drops that trait from 7943
  bacterial genomes to 2682; requiring the folate dihydroneopterin triphosphate
  pyrophosphatase drops folate from 5898 to 1634. The proposal recommends
  `route_reaction.required = 0`, which the schema already allows and three
  curated rows already use, and refuses the alternative of widening the marker —
  alkaline phosphatase (K01077, 3202 bacteria) is not evidence of a folate step.
- *"Produces vitamin B12" must be refused as named.* 4139 genomes complete the
  nucleotide loop and 3044 of them have no corrin ring, so a single trait would
  call salvagers producers; and of the 1081 that do complete ring, cobinamide
  and loop, only 538 carry BluB, without which the product is a cobamide rather
  than cobalamin. Four narrower GIFTs are proposed instead, including the first
  curated use of `gift_route.oxygen_requirement = 'aerobic'` for the aerobic
  corrin ring.
- *One architectural rule has to be set before the first anchor is added.* A
  cofactor may be declared an input anchor only where the reaction consumes it —
  FMNH2 by BluB — and never where it is recycled catalytically. Without it, THF,
  PLP and NAD become input anchors across the database and the anabolic
  acyclicity check stops describing biosynthetic composition.

**Effect on users.** None yet. No GIFT, route, reaction, marker or call changed.

### 2026-08-18T15:30Z — The atlas draws a reversible boundary as reversible

**Change.** `R/database-visualization.R` gains `.report_boundary_sides()`, which
decides what to draw on each side of a metabolic GIFT and which arrow to put
between them. For a directed GIFT nothing changes. For an interconversion GIFT
each anchor is drawn **once**, on the side where it was declared first, the
arrow becomes `&harr;`, the side labels become "Inputs / outputs" and
"Outputs / inputs", and the chips are coloured as shared boundaries rather than
as an input and an output.

**Why.** Declaring both directions made the renderer print the roles verbatim:

```text
before   ACETYL_COA ACETATE  ->  ACETATE ACETYL_COA
after    ACETYL_COA          <->  ACETATE
```

The old rendering was not merely redundant. A one-way arrow between two
identical sets asserts exactly the direction the mode exists to deny, so the
picture contradicted the data it was drawn from.

**The same defect in two other places.** In the whole-database anchor network an
interconversion GIFT was drawing two opposing edges between the same pair of
nodes, which reads as a contradiction rather than as reversibility. `.graph_edges()`
now takes a `bidirectional` flag, every graph defines a mirrored arrowhead
alongside its forward one, and the pair collapses to a single edge with a head
at each end, titled "is an input and output boundary of". The per-GIFT route
network carries the flag through the whole chain, so a reversible capability is
drawn boundary to boundary in both directions rather than pointing one way while
its own boundary display points both.

Each reaction keeps its `forward` / `reverse` badge, and the caption now says
why that is not a contradiction: the badge is the step's orientation relative to
its own Rhea master equation, which is a different question from which way the
capability runs.

**Effect.** Presentation only: no query, no call, no curated row changed. The
anchor filter chips still key on the declared roles, so an interconversion GIFT
is found by searching either boundary in either direction.

### 2026-08-18T15:00Z — The interconversion mode gains a boundary contract

**Change.** `R/database-build.R` now separates three ways a molecule can appear
on both sides of a boundary, and uses `mode` to say which is meant:

```text
same anchor, so one molecule in one compartment   reversible node   interconversion only
different anchors of one molecule, two compartments   translocation   transport
neither                                               directed chemistry
```

Two rules follow, both enforced: a GIFT that is not an interconversion may not
declare an anchor as both input and output, and an interconversion GIFT must
declare **every** anchor that way. `acetate_formation` is renamed
`acetate_interconversion` and now declares `ACETYL_COA` and `ACETATE` in both
roles. The SQL schema is unchanged at version 6 — this is a source-contract
rule, not DDL.

**Why.** `interconversion` had been a `CHECK` value with nothing behind it and
no written meaning. Curating the first GIFT that uses it is the point at which
the contract has to exist, and the honest contract turned out to be
bidirectional boundaries: the phosphotransacetylase and acetate kinase pair runs
both ways in different organisms, and no marker says which, so declaring one
direction asserts what the evidence cannot support while splitting the GIFT in
two asserts a distinction the same genes cannot make.

**What was at risk and how it was kept.** The rule being relaxed was doing real
work: "the same molecule is input and output" was the *definition* of transport,
and that is what makes transport required to reach the cytoplasm. Keying
translocation on a compartment *difference* preserves it and sharpens it, so a
reversible node in one compartment can never be mistaken for a transporter.
Four fixtures in `test-compartment.R` pin all four cases, including the negative
ones.

**Effect.** One new edge in `gift_graph`: `acetate_interconversion` now reaches
`butyrate_formation` through `ACETYL_COA` as well as `ACETATE`. No call changes,
no route changes, and no mirrored route was added — a flipped copy would
complete on identical markers and make closest-route selection
non-deterministic, so direction stays in the anchors for composition and in
`route_reaction.orientation` for chemistry. `inst/doc/architecture.md` documents
the split, including the point that `orientation` is relative to how Rhea writes
each equation and not to the direction of the GIFT.

### 2026-08-18T14:30Z — Short-chain fatty acid formation curated

**Change.** Six GIFTs are curated: `pyruvate_to_acetyl_coa`, `acetate_interconversion`,
`butyrate_formation`, `propanediol_formation`,
`propionate_formation_propanediol` and `propionate_formation_acrylate`.
Database version moves to 2026.13.1. **The SQL schema is unchanged at version
6.** One R change went with it, described in the entry below; the curated
content itself needed none. The biological decisions, their evidence and their effect
are in `database_changes.tsv`, readable with `database_changelog()`; the source
provenance and the four refusals are in
`inst/extdata/database-source/SOURCES.md`.

**Code.** None for the content itself, which is the entry's most useful line.
The layer needed a marker namespace the metabolic content had never used
(`TIGRFAM`), a GIFT mode the schema declared but nothing had exercised
(`interconversion`), and a reaction with no Rhea master — and all three were
already supported. `.infer_marker_namespace()` has recognised `^TIGR[0-9]{5}$`
since the evaluator was written, `marker.namespace` has never carried a `CHECK`,
and `rhea_master` became nullable for the polysaccharide layer. The one R change
this release does carry is the `interconversion` boundary contract, below, and
it came from writing that mode's meaning down rather than from the SCFA content.

**Tests.** A new `test-scfa.R` (98 assertions) covers the layer's biology: that
the chain-length-generic core markers do **not** complete `butyrate_formation`,
that neither `K01034`/`K01035` nor the butyrate kinase pair completes it, that
`TIGR03948` does; that adding the generic electron-transfer flavoprotein changes
no call; that the dehydrogenase complex has two E1 architectures and the
ferredoxin oxidoreductase two subunit architectures; that a two-of-three PduCDE
holoenzyme is incomplete; that the acrylate route reports its unannotated
reductase as a missing reaction rather than scoring it away; and that declaring
acetyl-CoA an anchor creates no edge from the biosynthesis GIFTs that consume it
internally.

**Three existing tests changed, and one of them mattered.**
`test-sugar-degradation.R` asserted that "a degradation GIFT is never upstream of
anything". That was an accident of coverage, not an invariant: nothing
downstream of pyruvate or lactaldehyde had been curated. It now asserts what the
test was actually protecting — that a degradation GIFT is never upstream of a
*biosynthesis* GIFT, and that its only outgoing edges run through the declared
anchors `PYRUVATE` and `LACTALDEHYDE`. The other two are roster and row-count
updates in `test-database.R` and `test-gift-types.R`; the latter became a
containment check so that the 29 pre-migration metabolic GIFTs are still
protected from changing type without freezing the set they belong to.

**Effect on users.** Six new callable GIFTs, and the composition graph now runs
from polysaccharide saccharification through sugar catabolism to a named
fermentation product. `gift_profile()` reports `cross_feeding_output` as 0 for
the whole layer and `resource_strategy` as `private`, which is deliberate: no
SCFA transporter marker licenses the extracellular anchor that cross-feeding
would need, so the model declines to claim it. No existing GIFT call changes.

### 2026-08-18T14:00Z — SCFA formation assessed, then curated

The assessment is `inst/doc/proposal-scfa-biosynthesis.md`; the content it
recommended is release 2026.13.1, described in the entry below. **No schema and
no R change** — this is a content release, and the proposal's first claim was
that it could be.

**Change.** Eight candidate short-chain fatty acid formation traits were tested
against the evidence available in KEGG, Rhea, ChEBI, MetaCyc and
InterPro/NCBIfam. Three are recommended for curation, one conditionally, and
four are refused. A prerequisite `pyruvate_to_acetyl_coa` GIFT is recommended
alongside them, because gifter's catabolic content currently ends at `PYRUVATE`
and the SCFA layer would otherwise be an island in `gift_graph`.

**Why it is worth reading before the next content release.** The layer needs no
schema migration and no R change, and it is the first candidate layer where the
*evidence* rather than the ontology is the binding constraint, in two ways the
existing proposals had not met:

- *KEGG orthology is insufficient for butyrate, measurably.* A KO-evidenced
  butyrate trait calls *Faecalibacterium prausnitzii*, *Roseburia intestinalis*
  and *Agathobacter rectalis* negative, and *Bacillus subtilis* positive; of 366
  KEGG organisms completing the core plus a terminal KO, 120 are *Bacillus*. The
  marker that does carry the claim is NCBIfam `TIGR03948` — which
  `.infer_marker_namespace()` already recognises and no curated row has ever
  used. The refusal is a marker-namespace gap, not an ontology gap, and the fix
  is the same one the collagenase `PFAM PF01752` row already took.
- *Fermentative end-product markers are direction-blind.* Every trait gifter
  carries today is directionally unambiguous. Pta–AckA runs both ways, and the
  methylmalonyl-CoA genes of the propionate succinate route are the same genes
  KEGG module M00741 uses to degrade propanoyl-CoA. The proposal adds a second
  clause to the specificity test for this, and recommends `mode =
  'interconversion'` — the schema's fourth mode value, so far unused — for the
  acetate node.

**Effect.** None on behaviour. The document records four refusals with their
evidence and their trigger conditions, so that the next reader who finds `buk`
missing from the database learns why rather than adding it.

### 2026-08-18T12:00Z — Regulatory and defense models gain curated content

**Change.** Five GIFTs are curated, filling the two typed models that shipped
with schema only: `chemotaxis_signal_transduction`, `aspartate_chemoreception`
and `phosphate_starvation_response` (regulatory), and
`type_i_restriction_modification` and `type_i_e_crispr_cas_machinery`
(defense). Database version moves to 2026.12.3. **The schema is unchanged at
version 6** — this is a content release, which is the point: adding a
capability of an existing type is a data change plus tests, not an R branch.

**Code.** One line: `.gifter_required_gift_facets` now requires
`regulatory_class` of regulatory GIFTs and `defense_class` of defense ones, and
`facet_terms.tsv` registers the four values those two vocabularies use. Each
vocabulary was registered when the first content of its type was curated, not
ahead of it. No evaluator, validator or accessor change was needed.

**Why these five.** They were the sequence the type proposals recommended, and
each was blocked on a question that was then answered by measurement rather than
assumption:

- *Chemotaxis* needed no evidence the marker model lacks, and immediately
  exercises the specificity invariant. Requiring the generic chemoreceptor
  accession K03406 would have called *Escherichia coli* K-12 receptor-less — it
  carries none, its four receptors being assigned to characterised groups —
  while *Vibrio cholerae* carries 34. The reception function therefore accepts a
  generic *or* a characterised chemoreceptor.
- *Phosphate response* was blocked on whether orthology distinguishes a cognate
  PhoR/PhoB pair from a genome full of paralogous kinases and regulators. Gene
  counts across nine reference genomes showed the sensor single-copy where
  present and the two regulator groups mutually exclusive, with the *Bacillus*
  pair adjacent in the genome. That answer split one capability into two circuits
  sharing a sensor rather than one circuit that would have called *B. subtilis*
  negative.
- *Type I restriction-modification* was the cleanest multisubunit requirement
  available, and the KEGG groups are defined as type I subunits, so the type is
  part of the group definition rather than an inference from it.
- *Type I-E CRISPR-Cas* was curated under the narrowed claim its proposal
  recommended: encoded machinery, not interference, because an array is a
  structural feature no protein accession evidences.

**Refusals recorded with the content**, each enforced by a test:

- ligand-specific chemoreception beyond aspartate, because K05876 covers ribose
  and galactose in one group and K03406 covers everything;
- K07660, which shares the gene name *phoP* with the phosphate regulator and is
  the magnesium-sensing PhoP/PhoQ regulator, a different protein with the
  opposite genome distribution;
- the target sequence a type I system recognises, because HsdS specificity comes
  from variable target recognition domains an orthology group does not resolve;
- K07475, the HD module of a split Cas3, as evidence of the complete
  nuclease-helicase;
- CheV as a substitute for CheW.

**Effect on other types: none.** The 29 metabolic GIFTs and the two structural
ones are unchanged; the no-regression test now strips every non-metabolic model
rather than only the structural one.

**Report.** The atlas renders regulatory circuits and defense mechanisms through
the same machinery view the structural type already used, and the GIFT type
grouping axis now separates four groups.

**A note on what did not happen.** The first structural and regulatory GIFTs are
now both curated, so `flagellar_apparatus` + `chemotaxis_signal_transduction`
could be fused into a `motility` trait. They are not, and the architecture guide
says why: a derived statement should read the primary calls rather than hide
which half of it a genome satisfies.

### 2026-08-18T10:00Z — GIFT becomes an umbrella concept with an explicit type

**Change.** A GIFT is redefined as a biologically meaningful capability whose
genomic support is evaluated through an explicit, curated and traceable
completeness model, and every GIFT now declares a core `gift_type`:
`metabolic`, `structural`, `regulatory` or `defense`. Schema version moves from
5 to 6.

`gift_type` is not a facet. A facet classifies a call; the type decides which
completeness model produces one, which source tables may attach to the GIFT, and
what a positive call is allowed to mean. That is a change to the relational
contract, hence a migration rather than a new column.

**Reason.** A genome encodes capabilities that are not chemistry. Modelling a
flagellum or a restriction-modification system as a directed route between
molecular anchors would have required inventing input and output molecules the
structure does not have, and the call would then rest on a boundary claim nobody
could defend. Each type states its own completeness contract instead.

**Effect on the metabolic model: none.** All 29 previously curated GIFTs became
`gift_type = metabolic` with no change to their anchors, routes, reactions,
systems, components, markers, calls, traces, graph edges or derived profile.
`test-gift-types.R` proves this by compiling a database with the structural
content removed and comparing every metabolic call and trace against the shipped
one.

**Structural model.** Implemented in full, with its own biologically named
tables: `gift_architecture`, `architecture_function`, `structural_function`,
`structural_system`, `structural_component`, `structural_component_marker`. A
structural GIFT is complete when any curated architecture has every required
structural function supported; an incomplete call names the closest architecture
and the functions missing from it, never a fraction of expected genes.
`required = 0` marks an accessory function.

**Regulatory and defense models.** Schema and evaluator implemented under
`gift_circuit`/`circuit_function`/`regulatory_*` and
`gift_mechanism`/`mechanism_function`/`defense_*`; both ship with no curated
content, and their Boolean semantics are fixed by synthetic fixtures in
`test-regulatory-defense.R`. The design questions that block curation —
cognate sensor/regulator pairing, and whether a CRISPR claim needs evidence
beyond protein markers — are written down in the type proposals rather than
answered by convenient curation.

The three non-metabolic models are kept as parallel table families rather than
merged into one generic set. Their Boolean shape is identical; a structural
function, a regulatory function and a defense function are not the same
biological object, and a source row is reviewable because of what it is called.
Only the operations whose semantics genuinely are identical are shared in code:
marker matching, component support, system AND logic, confidence ordering,
deterministic tie-breaking and result assembly. Whether the data model should
converge is left for after all three carry curated content.

**Public API.**

- `list_gifts()` gains a `type` argument and returns `gift_type`;
- `get_gift()` returns `gift_type`; `gifts_by_facet()` returns it too;
- `evaluate_gifts()` evaluates a mixed-type database in one call. Its `gifts`
  summary gains `gift_type` and a type-neutral answer — `best_implementation`,
  `number_of_complete_implementations`, `minimum_missing_requirements`,
  `missing_requirements`, `completeness_score` — beside the unchanged metabolic
  route columns, which are `NA` for non-metabolic GIFTs. New `structural`,
  `regulatory` and `defense` members carry the type-specific detail under
  biological names (`best_architecture`, `missing_functions_best_architecture`);
- `trace_gift()` dispatches on the type and gains an `implementation` argument
  for the machinery types; passing `route_id` for a non-metabolic GIFT, or
  `implementation` for a metabolic one, is an error rather than being ignored;
- `map_markers()` searches every model and gains `gift_type` and `function_id`.
  Component keys are unique only within a model, so they must be compared
  together with the type;
- new `get_gift_machinery()` returns the implementation, function, system,
  component and marker hierarchy of a non-metabolic GIFT;
- `gift_profile()` is documented and implemented as metabolic-only, because
  every field it derives comes from declared anchors.

**Validation.** Unknown or missing types are rejected. `mode`, anchors and
routes are refused on non-metabolic GIFTs and required on metabolic ones. An
implementation may not name a GIFT of another type. Required facets are scoped
by type, and a facet required of one type may not classify another. Function,
system, component and implementation identifiers must be unique across models,
because a trace prints them without naming their table. An implementation with
no required function is rejected. A separate fix makes the composition cycle
check skip a GIFT whose mode is missing rather than failing on an unnamed node.

**Report.** The atlas renders non-metabolic GIFTs as their alternative
implementations over the functions they share, with accessory functions dashed,
and offers GIFT type as a grouping axis. The new tables appear in the schema and
table browsers.

### 2026-08-19T00:30Z — Package renamed from distillR to giftr

The package is renamed to `giftr` and developed in its own repository. Every
identifier that carried the old name follows: `build_giftr_database()`,
`validate_giftr_sources()`, `write_giftr_database_html()`, `giftr_db_connect()`,
`giftr_db_disconnect()` and `giftr_db_version()`; the result classes
`giftr_result` and `giftr_reaction_result`; the packaged artefacts
`inst/extdata/giftr.sqlite`, `inst/extdata/giftr-database.html` and
`inst/schema/giftr.sql`; and the `database_release.giftr_db_version` column.

Calling this work distillR 2.0 implied continuity with a package built on a
different primitive — fullness scores over curated gene bundles. The
evaluation model, schema, public API and biological claims are all new and no
1.x code path survives, so a distinct name states plainly what the software is.
The package version starts afresh at 0.1.0. References to distillR that
describe the predecessor are kept as such in the architecture guide, the
curation proposals and the manuscript.

**Effect.** No change to evaluation logic, schema, or database content. The
database version is unaffected and remains 2026.12.1 at schema 5. Code written
against the unreleased distillR 2.0 development branch must rename the
identifiers above.

**Also.** `DESCRIPTION` gains `Config/build/clean-inst-doc: FALSE`. `inst/doc`
holds developer documentation rather than built vignettes, and the build tooling
clears that directory by default.

### 2026-08-18T23:59Z — Schema 5: facet classification and derived profile

**Change.** Schema version 5 replaces the free-text `gift.category` column with
a registered facet vocabulary, and adds a derived profile view.

`facet_term` registers every `(facet, value)` pair with the target it applies to
and a definition. `gift_facet` and `anchor_facet` carry the assignments; the
build rejects any pair that is not registered, any facet attached to the wrong
target, a GIFT without exactly one `substrate_class`, a GIFT without at least
one `physiological_role`, and an anchor without `molecular_tier` or
`biomass_essential`. `gift_route` gains a required `oxygen_requirement`, which
is a route property rather than a GIFT property because alternative routes to
the same anchors genuinely differ.

The `gift_profile` view derives `substrate_tier`, `resource_strategy`,
`network_position`, `cross_feeding_output` and `auxotrophy_indicator` from
declared anchors, anchor facets and the composition graph. Nothing in it is
curated. Facets and profile classify a call; neither enters the completeness
logic that produces one.

**API.** New: `list_facets()`, `get_facets()`, `gifts_by_facet()`,
`gift_profile()`. `list_gifts()`, `get_gift()` and `evaluate_gifts()` no longer
return `category`; `evaluate_gifts()` returns `substrate_class` instead.

**Effect.** No GIFT call changes. `resource_strategy` makes the
degrader-versus-forager distinction directly readable: `uptake`, `public_good`,
`private`, or `unresolved` where a compartment was never licensed.

**Migration note.** Consumers reading `category` should read `substrate_class`,
either from `evaluate_gifts()` or via `get_facets(gift_id)`.

### 2026-08-18T21:00Z — Polysaccharide content restructured; no code change

Database 2026.10.2 replaces six single-reaction polysaccharide GIFTs with three
substrate-level capabilities. The decision and its effect on calls are in
`database_changes.tsv`; this entry records only that a published shape was
retracted.

The first polysaccharide release made a GIFT equivalent to a reaction, which is
the marker-checklist shape the ontology exists to avoid, and left the
substrate-level question unanswerable by any single trait. `xylan_degradation`
now spans endo- and exo-acting chemistry with acetyl de-blocking as an accessory
reaction, and a genome carrying only one side reports an incomplete capability
naming the missing reaction.

**Migration note.** `xylan_depolymerisation`,
`xylooligosaccharide_saccharification`, `arabinoxylan_arabinofuranose_release`,
`starch_depolymerisation`, `starch_debranching` and
`maltooligosaccharide_saccharification` no longer exist. Use
`xylan_degradation`, `arabinoxylan_debranching` and `starch_degradation`. The
`XYLOOLIGOSACCHARIDE` and `MALTOOLIGOSACCHARIDE` anchors are withdrawn.

### 2026-08-18T18:00Z — Confidence follows the Boolean structure

**Change.** `evidence_confidence` is now computed as the *best* confidence among
the alternative markers supporting each component, then the *weakest* across the
components a route requires. It previously took the weakest across all
supporting markers.

**Why.** Alternative markers for one component are OR. Under the old rule,
adding a weak marker alongside a strong one made the call look worse — a genome
annotated with both the polyspecific CAZy family GH5 and the specific orthologue
K01181 reported `ambiguous`, when the specific evidence was present and
sufficient. Components are AND, so the weakest-wins rule is correct there and is
retained.

**Effect.** Confidence can only improve or stay equal for a given genome. No
Boolean call changes. Newly visible on database 2026.10.1, which is the first
content mixing curated orthology with polyspecific sequence families.

**Migration note.** Reaction identity is `reaction_id`, and `rhea_master` is now
`NA` for the polymer-acting reactions. Code filtering results with
`reactions$rhea_master == x` will return `NA` rows; filter on `reaction_id`.

### 2026-08-18T14:00Z — `mode` reaches the evaluation result

**Change.** The `gifts` tibble returned by `evaluate_gifts()` now carries
`mode`, matching `list_gifts()` and `get_gift()`. Filtering a result down to
transport or catabolic traits previously required a second lookup.

**Effect.** Additive; no call changes. Database 2026.09.4 adds the first two
transport GIFTs and the first compartment-split anchors, so the column now
distinguishes rows that were all `anabolic` before.

### 2026-08-18T10:00Z — Sugar degradation content; no code change

Database 2026.09.3 adds nine catabolic GIFTs. This entry is a pointer only: the
biological decisions, their evidence and their effect on calls are recorded in
`database_changes.tsv` and readable with `database_changelog()`. No package
behaviour changed, and no existing GIFT call changed.

The content exercises schema 4 for the first time: `mode = catabolic` on all
nine, and `reaction_id` carrying identity for 29 new reactions. Compartment
remains `unspecified` throughout, because no uptake GIFT is curated yet and the
splitting licence requires substrate-specific transporter evidence first.

### 2026-08-17T21:30Z — Schema 4: reaction identity, compartment, and GIFT mode

Infrastructure for the polysaccharide and sugar degradation layer described in
`inst/doc/proposal-polysaccharide-degradation.md`. No biological content is
added here and no existing GIFT call changes.

**Change.** Schema version 4 makes four structural changes.

*Reaction identity.* `reaction` gains a stable `reaction_id`, and `rhea_master`
becomes optional. `reactions.tsv` gains a `reaction_id` column, and
`route_reactions.tsv`, `enzyme_systems.tsv` and `reaction_xrefs.tsv` reference
it in place of `rhea_master`. For all content curated so far `reaction_id`
equals the Rhea master, so no reference changed value. A reaction curated
without a Rhea master must carry at least one `reaction_xrefs` entry.

*Anchor compartment.* `anchor` gains `molecule`, a stable key shared by the
compartment variants of one substance, and `compartment`, one of
`extracellular`, `cytoplasmic`, `unspecified`. `UNIQUE (molecule, compartment)`
becomes the natural key and `chebi_id` is no longer unique, because two location
states of one molecule carry the same ChEBI identifier. Every existing anchor is
`unspecified` with `molecule` equal to its `anchor_id`.

*GIFT mode.* `gift` gains `mode`, one of `anabolic`, `catabolic`, `transport`,
`interconversion`. The composition cycle check now runs per mode: a cycle within
one mode is still an error, a cycle between modes is not. All existing content
is `anabolic`.

*Graph edge quality.* The `gift_graph` view matches on `molecule` and reports
`edge_quality`. An edge is `exact` when both GIFTs declare the same anchor, and
`compartment_inexact` when they declare the same molecule and exactly one side
is `unspecified`. Two anchors whose compartments are both specified and
different are not connected, so a transport GIFT is required to cross that
boundary. `gift_graph()` gains a `quality` filter and returns `to_anchor`,
`shared_molecule` and `edge_quality` alongside the existing columns.

**Validation.** New errors: an invalid mode or compartment, a repeated
molecule/compartment pair, an empty `molecule`, a transport GIFT whose anchors
do not translocate one molecule, a malformed or duplicated Rhea master, and a
reaction with neither a Rhea master nor a cross-reference. New warning: a GIFT
that translocates a molecule without declaring `mode = transport`.

**Evaluation.** `evaluate_gifts()` reports `evidence_confidence` per GIFT — the
weakest qualitative confidence among the markers supporting the best route, so a
call resting on ambiguous evidence is distinguishable from one resting on
curated orthology. `trace_gift()` gains `reaction_id`. Route
`supporting_reactions` and `missing_reactions` now carry `reaction_id`, which is
never null.

**Markers.** CAZy accessions are recognised without an explicit namespace
(`GH5`, `GH5_4`, `PL1`, `CE8`, `AA9`, `CBM6`). A subfamily is a distinct
accession and never implies its parent family.

**API.** `get_reaction()` and `get_reaction_systems()` take `reaction`, matching
either a `reaction_id` or a Rhea master; `get_reaction(15753)` still resolves.
`list_gifts()` and `get_gift()` return `mode`; `get_gift_anchors()` returns
`molecule` and `compartment`; `get_gift_reactions()` returns `reaction_id`.

**Reason.** Rhea does not cover polymer-acting chemistry, catabolism and
biosynthesis legitimately close loops through shared metabolites, and the
degrader/forager/cross-feeder distinction is invisible without compartment.
Each was a blocker for curating carbohydrate degradation honestly.

**Effect.** No change to any existing GIFT call; 531 tests pass. Compartment
remains a curated boundary claim rather than a genomic inference — the scope
statements in `AGENTS.md` and `inst/doc/architecture.md` were amended to say so
and to enumerate what stays out of scope.

### 2026-08-17T20:10Z — GIFTs can be linked to related external pathways

**Change.** Schema version 3 adds the `gift_xref` table, compiled from the new
source `gift_xrefs.tsv`. Two accessors read it: `get_gift_pathways(gift_id,
namespace = NULL)` lists the external pathways related to a GIFT, and
`gifts_for_pathway(accession, namespace = NULL)` resolves a pathway identifier
back to the GIFTs that relate to it. Every reference carries a `relation` from
the closed vocabulary `equivalent`, `subset_of`, `superset_of`, `overlaps`,
`related`. Source validation rejects an unknown relation, a link to an unknown
GIFT, a duplicate GIFT/namespace/accession triple, and an empty namespace,
accession or name. The HTML atlas gains a `Related pathways` section on every
GIFT, with the relation spelled out in words, and pathway accessions are
searchable from the GIFT explorer.

**Why.** Users arrive from the resource they already know, but a GIFT is a
curated capability between declared anchors and is usually not the same object
as a pathway record. A bare cross-reference would imply an equivalence that is
false for most GIFTs — gifter splits KEGG M00018 across three traits and
merges M00338 with part of M00609. Storing the set relation makes the link
useful without weakening the claim. The namespace is deliberately open so that
resources beyond KEGG can be linked without a schema change.

**Effect.** No GIFT call changes. `gifter_db_version()` reports schema
version 3. Consumers reading `gift_xref` should treat `namespace` as an open
vocabulary and `relation` as closed.

---

### 2026-08-17T18:05Z — Curation history stored in the database and published in the atlas

**Change.** Schema version 2 adds the `database_change` and `change_gift`
tables, compiled from `database_changes.tsv` and `change_gifts.tsv`. New
accessor `database_changelog(gift_id = NULL)` returns the history, newest
first, with the affected GIFTs as a list column. The HTML atlas gains a
`Changelog` view rendering the history as a table — release, UTC timestamp,
hierarchy layer, category, effect on calls, the decision with its rationale,
evidence and effect, and the GIFT identifiers it affects. Selecting a GIFT
identifier opens that trait in the GIFT explorer, and every GIFT detail now
carries its own change history.

**Why.** Biological decisions were recorded in a Markdown file next to the
code, where they were invisible to anyone holding only the compiled database,
unlinked from the traits they changed, and mixed in with code history.

**Design decisions.** The history is curated source data, not documentation, so
it passes the same validation as the rest of the database: controlled
vocabularies for layer, category and effect on calls; ISO 8601 UTC timestamps;
and a foreign key from every entry to the GIFTs it affects. Validation requires
that link for changes to biological layers, and allows provenance and schema
entries to stand alone. `call_effect` is a first-class field rather than prose
because whether a change broadens or narrows calls is the question a user
re-running an analysis actually has.

**Effect.** No change to evaluation. Schema version 1 to 2; database release
2026.08.2 to 2026.08.3.

### 2026-08-17T16:49Z — Network visualisations in the database atlas

**Change.** `write_gifter_database_html()` now renders three inline SVG
network views: the existing directed GIFT composition graph, a new network
drawing GIFTs together with their declared anchors, and a merged route network
for every GIFT. A shared layered-graph engine in `R/database-visualization.R`
backs all three; the composition graph was moved onto it without changing its
appearance.

**Why.** The atlas described the evaluation hierarchy in tables and nested
disclosure but never showed the two structures that curation decisions actually
turn on: where alternative routes diverge and reconverge inside one GIFT, and
which anchors are the boundaries where GIFTs meet.

**Design decisions.** Route networks merge alternative routes onto shared
reaction nodes, so a parallel branch is a genuine route alternative and edge
thickness reports how many routes traverse a step. Anchors are drawn once in
the anchor network, so an anchor with both an incoming and an outgoing edge is
exactly the boundary where two GIFTs compose. Both networks are built strictly
from `gift_anchor` and `route_reaction`; no node exists that is not a declared
anchor or a curated route reaction, so a drawing can never imply a boundary
that curation did not declare. Graphs render at natural size and scroll
horizontally rather than being scaled down, which keeps long routes legible.

**Effect.** No change to evaluation or to the database. Tests assert the node
accounting of both networks, the route overlay counts, and marker-ID
uniqueness across the report.
