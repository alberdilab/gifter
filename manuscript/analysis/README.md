# Manuscript analyses

Scripts that produce the results sections. The standing rule of
`manuscript/manuscript.md` is that **nothing in R7–R10 may be written as prose
before a committed script here has produced it**, so every number in those
sections traces back to a file in this directory.

Nothing here is part of the gifter package. These scripts consume the public
API and the compiled database exactly as a user would; if one of them starts
needing a change in `R/` or in the schema, that is a signal the analysis has
begun asking gifter to claim something it does not claim.

| File | Produces | Section |
|---|---|---|
| `_common.R` | Shared caching, KEGG and BacDive access, the agreement helper | all |
| `00-slice-urea.R` | The R9 feasibility slice on one capability | R9 |
| `01-marker-matrix.R` | The reference genome set, its calls, and the KO-only ceiling | R7, R8, R9 |
| `02-incompleteness.R` | Call retention under progressive gene subsampling, and the assessability policy against a naive denominator | R7 |
| `03-phenotype.R` | R9's catabolic half: BacDive against the call and the reaction | R9 |
| `04-auxotrophy.R` | R9's anabolic half: defined media against the bounded frames | R9 |
| `05-annotation-route.R` | The same genomes annotated three ways, and the delta | R9 |
| `06-figure-phenotype.R` | Figure 8, and the reference-consistency measurement | R9 |
| `07-madin.R` | R9's second reference: species-level trait records, and what the species join costs | R9 |
| `08-figure-incompleteness.R` | Figure 6 | R7 |
| `09-cooccurrence.R` | Whether marker context licenses filling a gap: per-context co-occurrence on the reference panel | exploratory |
| `10-block-drop.R` | The same question under contiguous gene loss: conditional dropout measured rather than assumed | exploratory |
| `11-prospective-validation.R` | Archived prospective-study registry template; it is not run or populated in this database-only project | archived template |
| `12-priority1-collagen-annotation.R` | Checksum-pinned M9/domain audit of the exact collagen-specificity candidate assemblies; no assay input | database-only evidence |
| `13-priority2-collagen-evidence-stress.R` | Synthetic loss and deliberate evidence-mixture stress test of the exact collagen audit; not a MAG | database-only evidence |
| `14-priority1-aspartate-chemoreception-annotation.R` | Checksum-pinned Tar/circuit audit of the exact receptor-specificity candidates; no assay input | database-only evidence |
| `15-priority1-starch-annotation.R` | Checksum-pinned KOfam/dbCAN audit of exact starch-specificity candidates, including the broad-family failure check; no assay input | database-only evidence |
| `16-priority1-type-ie-crispr-annotation.R` | Checksum-pinned KOfam audit of exact Type I-E machinery candidates, including incomplete-Cascade logic; no array or assay input | database-only evidence |
| `17-priority2-matched-mag-robustness.R` | Checksum-pinned matched-isolate reassembly and annotation audit: exact isolate plus one de-novo MAG-like read-subset draft, full traces and fixed-table invariants; no MAG, bin or assay | database-only evidence |
| `18-priority3-flagellar-annotation.R` | Checksum-pinned structural-pilot audit of PAO1's complete flagellar-marker evidence and component trace; no microscopy, motility or assay input | database-only evidence |
| `19-phenotype-validation-coverage.R` | Checksum-pinned audit of which GIFTs have usable, frame-only, related, refused or no current public phenotype/genome evidence; no new score | R9 validation scope |
| `20-figures-core.R` | Figures 1–5 plus the purine, frame and four-genome community trace tables; all values are derived through the public API | R1–R5, M4 |
| `21-r10-chicken.R` | Figure 7 and the 822-MAG × 388-sample chicken caecal case study: checksum-verified Drakkar or giftag marker input, completeness-aware traits, detection sensitivity, age contrasts and exact extracellular-anchor-compatible topology | R10 |
| `22-r10-handoff-bimodality.R` | R10 follow-up: every exact extracellular handoff, provider/recipient presence and abundance axes, confidence and detection sensitivity, detected-count-matched null, and the `cmag_510` richness-mode diagnostic with Figure S3 | R10 |
| `23-gtdb-phylogeny.R` | A locked 696-genome, origin-balanced panel from the GTDB R232 bac120 tree, current GIFT calls after Drakkar annotation, and Figure S4 | R6.1 |
| `24-r10-reference-frame-time.R` | R10 follow-up across all 19 database-defined reference frames: temporal change, equivalence-based stability, detection and confidence sensitivity, the classification heatmap (Figure S5), adjusted three-day trajectories (Figure S6), frame-to-GIFT decomposition (Figure S7), and carrier-abundance sensitivity (Figure S8) | R10 |
| `25-r10-mfd.R` | Environmental complement to R10: a locked, spatially distributed 360-sample Microflora Danica panel, one deposited representative per 95% ANI cluster, habitat-descriptive reference-frame readings and detection/confidence sensitivity | R10b |
| `26-gtdb-repertoire-genome-size.R` | GTDB overview follow-up: supported GIFTs against the size of the evaluated assembly, a smooth quasi-binomial expectation, per-genome deviations with an outlier test, phylum and class summaries, and Figures S9 and S10 | R6.1 |
| `27-gtdb-size-signal-and-gift-classes.R` | GTDB overview follow-up: phylogenetic signal of the size deviation (Pagel's λ, Blomberg's K, a Moran's I correlogram over patristic distance), the association of genome size with each class of GIFT and with each GIFT, and Figures S11 and S12 | R6.1 |
| `28-gtdb-origin-and-annotations.R` | GTDB overview follow-up: origin tags and assembly annotations against genome size, repertoire, the size deviation, classes of GIFT (phylogenetic regressions) and individual GIFTs (unadjusted screen), and Figures S13 to S15 | R6.1 |
| `29-gtdb-near-misses-and-gift-signal.R` | GTDB overview follow-up: unsupported GIFTs one requirement short, by lineage and by missing requirement, as ranked curation candidates; Fritz and Purvis's D for each GIFT; and Figures S16 and S17 | R6.1 |
| `30-gtdb-near-miss-steps.R` | GTDB overview follow-up: for each implementation, whether its near misses lack the same requirement, and whether the requirements present are specific to the GIFT or shared with others (read from the database source); ranked curation candidates and Figure S18 | R6.1 |
| `31-r10-size-expectation.R` | R10 follow-up joining the GTDB overview: a per-frame size expectation fitted to the GTDB panel is applied to the 822 chicken MAGs, each sample's mean per-MAG richness is split into a size-expected part and a deviation, the R10 age model is fitted to each, and the contrast is partitioned by taxonomic rank (Figure S19) | R10, R6.1 |
| `33-r10-giftag-compare.R` | Compare the Drakkar and giftag R10 GIFT calls and sample metrics after both are evaluated with the same gifter database | R10 benchmark |
| `34-r10-giftag-markers.py` | Compare per-MAG marker presence within the exact gifter marker vocabulary; preserve the genome rather than gene as the comparison unit | R10 benchmark |
| `35-r10-giftag-resources.py` | Summarize measured wall time, actual CPU time, throughput, memory and Drakkar job accounting for the same 822-MAG annotation workload | R10 benchmark |
| `36-r10-giftag-genome-timing.py` | Extract giftag elapsed time per MAG and join each MAG to the original Drakkar Slurm CPU and retry accounting | R10 benchmark |
| `36-r10-gifter-resources.R` | Measure uncached gifter input loading, genome evaluation, dataset assembly, sample traits and sample network on the 822-MAG × 388-sample R10 case; `_r10-gifter-benchmark-worker.R` runs the workload in a fresh process | M5 technical benchmark |

The curated inputs live with the other consulted evidence, in
`data-raw/reference/`: `phenotype-crosswalk.tsv` maps an observation to
something gifter claims, and `chebi-anchor-aliases.tsv` lets a metabolite
record find its anchor. `read_phenotype_crosswalk()` validates both on load and
refuses a row whose target no longer exists.

## R8 scope

R8 is a controlled comparison of gifter, KEGG module completeness and DRAM
distillation from a common per-gene marker table. METABOLIC is deliberately not
an R8 comparator: its native workflow requires genome or protein FASTA and
reruns profile annotation and motif validation before creating summaries, so it
cannot consume the common marker table. No METABOLIC version, parameter set or
tool run is pending for R8. Its retained raw gene-level KO or profile hits can
be normalised into gifter's `gene_id`, `namespace`, `accession` input, whereas
METABOLIC pathway and module summaries are already distillations and must never
be ingested as gifter evidence.

`05-annotation-route.R` needs HMMER on the path, or `GIFTER_HMMER` pointing at
the directory that holds `hmmsearch`, `hmmscan` and `hmmpress`. It is the only
script here with an external binary dependency, and it is also the only one that
downloads gigabytes: the pinned KOfam, NCBIfam and dbCAN profile libraries, from
which it keeps just the profiles gifter curates. Budget several hours on a first
run. Everything is cached, so a second run is minutes.

`11-prospective-validation.R` has no network dependency and produces no result
until a real study has been locked. Its four input templates live in
`prospective/`; the accompanying README specifies the required assembly,
pipeline, database-version, marker-control and assay fields. It refuses a
planned protocol or an observation dated before the protocol lock, evaluates
each submitted sample independently, and writes the raw observation beside the
call and gene-level trace. The summary deliberately reports asymmetric counts
and denominators rather than accuracy, F1, AUC or a catalogue-wide score.

`12-priority1-collagen-annotation.R` is the completed first computational
tranche of that plan. It downloads no inputs itself: the two exact NCBI protein
FASTAs named in `prospective/collagen-annotation-inputs.tsv` are retrieved into
the local cache, then the script pins every raw input by SHA-256, applies the
KOfam `K01387` adaptive threshold and Pfam `PF01752` gathering threshold, and
passes only accepted M9 markers to gifter. It records PAO1 LasB from the exact
FASTA header as a broad-protease control but never treats it as a collagen
marker. Its committed audit is genomic evidence only, not a registry row or
phenotype result.

`13-priority2-collagen-evidence-stress.R` takes those accepted marker rows and
removes them one at a time, then adds one labelled *Hathewaya* marker to PAO1's
M9-empty input. It makes the expected alternative-marker retention and the
contaminated-bin failure mode reviewable at the gene level. A synthetic mixture
is never called a PAO1 genome, and these tables neither estimate MAG quality nor
substitute for matched metagenome assemblies.

`14-priority1-aspartate-chemoreception-annotation.R` performs the parallel
regulatory contrast. It reads the six required Tar-circuit markers from the
pinned database and adds generic MCP `K03406` only as a diagnostic. The generic
marker may complete the core chemotaxis GIFT, but it is never allowed to
complete `aspartate_chemoreception`; the retained gene-level traces make that
distinction inspectable. Its output is a candidate annotation audit, not an
assay or a claim of chemotactic behaviour.

`15-priority1-starch-annotation.R` performs the corresponding substrate
specificity contrast from the exact, strain-matched *Bacillus licheniformis*
DSM 13 and *Hydrogenobacter thermophilus* TK-6 proteomes. It derives the
required route and markers from the pinned database, applies KOfam adaptive
thresholds plus dbCAN's independent-E-value/profile-coverage filter, and
records each hit and trace to its protein. The control has only broad `GH13`
and `GH57` family evidence, yet those rows currently complete
`starch_degradation` with ambiguous confidence; the resolving-marker
diagnostic leaves both required reactions missing. That is an explicit
curation problem, not a starch-degradation observation or a licence to make
the named claim. No prospective registry, database, SQLite artifact, schema or
package API changes follow from the audit.

`16-priority1-type-ie-crispr-annotation.R` performs the machinery-specific
contrast from exact MG1655 and *Alkalilimnicola ehrlichii* MLHE-1 proteomes. It
derives the five jointly required Cascade components, fused Cas3, and accessory
Cas1/Cas2 from the pinned database, applies the KOfam adaptive thresholds, and
retains every hit and trace to its protein. MG1655 completes the protein-only
Type I-E claim; MLHE-1 has Cas1/Cas2, Cas3 and partial Cascade evidence but
lacks CasA and CasE, so the Cascade system and GIFT remain incomplete. The
audit does not detect a CRISPR array and cannot support interference, defense,
activity or phenotype. It creates no registry, database, SQLite, schema or API
change.

`17-priority2-matched-mag-robustness.R` is the first real read-reassembly
exercise for Priority 2. It rejects MG1655's standard assembly/SRA linkage
because those linked records are ChIP data, then requires a complete isolate
assembly and WGS read run that share BioSample and BioProject. The accepted
PacBio MG1655 pair is checksum-verified, its exact assembly and one deterministic
read-subset draft are gene-called and searched under the same pinned
KOfam/NCBIfam/TIGRFAM/Pfam/dbCAN pipeline, and every GIFT call and trace is
retained per source. The draft is MAG-like only; no metagenome, binning,
contamination estimate, MAG-quality estimate or foreign read is used. Its
transition table calls only annotation/assembly differences, while its separate
fixed-table deletion and assessability rows test evaluator invariants rather
than genome or biological change. It produces no assay or phenotype result and
does not modify the package, schema, biological source or SQLite artifact.

`18-priority3-flagellar-annotation.R` starts the next unresolved priority only
as a structural candidate annotation audit. It requires the pre-pinned exact
PAO1 protein FASTA, extracts all current flagellar KOfam models, applies their
adaptive thresholds, and writes every hit alongside the component-level
`trace_gift()` output. The deposited annotation completes both curated
architectures, with the diderm architecture selected as best; that supports
only encoded machinery. It is not a microscopy or motility observation.

The paired [microscopy plan](prospective/priority-3-flagellar-microscopy-test.md)
is archived because this project uses existing phenotype/genome information
only. The annotation audit is retained, but it cannot be extended with a
synthetic annotation deletion, motility proxy or ion-coupling inference.

`19-phenotype-validation-coverage.R` is the next database-only validation
audit. It reads the committed BacDive/MediaDive and Madin agreement tables,
pins each input and the database by SHA-256, expands reaction observations to
their owning GIFTs, and writes one evidence/status row per GIFT. It separates
individual recall-usable evidence from bounded-frame aggregates, low-n records,
related context and explicitly refused proxies. That distinction makes the
manuscript's coverage claim auditable without treating a missing record as a
negative phenotype or creating another score.

`09-cooccurrence.R` is exploratory and feeds no section yet. It asks whether the
assessability layer could be sharpened from a genome-wide rule into a per-GIFT
one: instead of declaring every absence in a 70%-complete genome indeterminate,
declare indeterminate only those absences the panel says are probably artefacts.
It estimates, for every curated context the hierarchy already defines, the
probability that a target is supported given the rest of its context is —
`pi` — together with the lift over the target's own base rate, a Wilson lower
bound, and the same estimate recomputed over one genome per genus. It fills
nothing and moves no call; invariant 21 is not at stake in it. Calibrating a
posterior against known truth belongs to the drop simulation in
`02-incompleteness.R`, not here.

`10-block-drop.R` is what decides whether `09` means anything. The posterior in
`09` assumes that losing one gene says nothing about whether its neighbour was
lost, which is false: a recovered genome is missing contigs, and a contig is a
run of adjacent genes. So the assumption is replaced by a measurement. Gene
order comes from KEGG's per-organism gene list, one request per genome, which
carries a replicon and coordinates for every gene — contiguity among curated
genes alone is not contiguity on a chromosome. Runs of adjacent genes are
removed until the target loss is reached, clipped at replicon boundaries, with
the mean run length swept from one gene (the unlinked model, sampled
independently through the same code) to fifty.

The statistic is `d_conditional`, the chance a target is unobserved given its
context still is, and it is compared against the same quantity at a run length
of one rather than against the genome's marginal loss. The two differ even
under independent loss, because conditioning on the context selects genomes
with more redundancy behind their components; attributing that offset to
linkage would overstate the effect this script exists to measure.

`07-madin.R` is separate from `03-phenotype.R` rather than folded into it
because the two references join differently. BacDive supplies an assembly
accession per strain; Madin supplies a species name, so a representative genome
has to be chosen and the within-species variation absorbed. Putting both behind
one recall column would hide which confound a disagreement belongs to. The
script measures the cost of its own join instead of asserting it away: how often
the several reference genomes of one species disagree about a call, and how far
each recall moves across 100 independent draws of the representative. That range
is a sensitivity to a choice the reference cannot make, and it is not a
confidence interval.

It is also the only script whose input is not fetched. The Madin condensed trait
table is a single release-tagged file rather than a service, so
`condensed_traits_NCBI.csv` has to be placed at
`manuscript/analysis/.cache/madin/` by hand; the script stops with that
instruction if it is missing.

`05-annotation-route.R` rebuilds both R9 test sets from the cached sweeps rather
than reading the tables `03` and `04` wrote. That is deliberate. A BacDive sweep
grows between runs, so a recall figure is only comparable with another measured
on the same sweep; scoring all three routes inside one run is what makes the
delta between them mean something.

## R10 chicken caecal case study

`21-r10-chicken.R` evaluates the exact 822 bacterial MAGs in the public Marcos
et al. chicken caecal catalogue across 388 samples. Remote acquisition,
annotation and transfer scripts live under `r10-chicken/`; their README pins the
Zenodo snapshot, Git commit, MAG identities, Mjolnir layout and Drakkar
workflow. The remote run uses the existing shared Drakkar 2.6.6 conda
environment. It does not install or update Drakkar.

The giftag rerun uses the same MAG checksum ledger on Mjolnir and an existing
giftag 0.2.0 environment. Its eight-CPU full annotation, Slurm accounting,
verified transfer and isolated local rerun are documented in
`r10-chicken/README.md`. The original Drakkar run is reevaluated against the
same current gifter database in a separate output directory before output
concordance is calculated.

The fetched `gifter_input.tsv.xz`, generated annotation manifest and QC table
live in the ignored `.cache/r10-chicken/drakkar/` directory. The script verifies
their sizes and SHA-256 hashes before evaluation, checks that marker evidence
covers exactly the 822 manifest genomes, and records those hashes in
`output/r10-input-audit.tsv`. Heavy community, dataset-trait and exact-network
objects remain cached locally; the reviewable summaries and GIFT-level traces
are written to `output/`.

The archive lacks the original per-sample 30% breadth matrix. Consequently the
script repeats community metrics at relative-abundance detection thresholds of
0, 10^-5, 10^-4 and 10^-3, and labels 10^-3 as an operational threshold rather
than an equivalent replacement. Completeness below 90% moves unsupported calls
to indeterminate only. A separate high-confidence-floor sensitivity tests the
dependence on ambiguous family evidence. Exact plant-fibre network edges cross
genomes only through declared extracellular anchors and are potential
compatibilities, never observations of exchange or activity.

`22-r10-handoff-bimodality.R` reads those checksum-pinned cached calls without
re-evaluating a genome. It enumerates every exact graph link whose shared
anchor is explicitly extracellular, keeps provider and recipient presence and
abundance coverage as separate axes, repeats topology across the four detection
thresholds and the high-confidence floor, and compares each primary sample to
499 random catalogue communities with the same detected-MAG count. Its null
controls the number of opportunities to form a pair; it does not turn a
compatibility into an interaction.

The same script defines the two primary-threshold richness modes by the largest
empty gap, screens all 822 MAGs for detection-mode agreement, and removes the
best-matching MAG computationally to count its unique contribution. This
identified `cmag_510` rather than assuming an organism in advance. Figure S3
shows why the operational 0.001 threshold converts its continuous abundance
into a discrete community-richness split.

`24-r10-reference-frame-time.R` reads the same audited calls across every
curated reference-frame preset rather than selecting individual GIFTs after
seeing their effects. It reconstructs only community richness, mean per-genome
richness and bounded coverage from the cached call and detection matrices, and
asserts exact equality with `dataset_traits()` for every frame the primary
analysis already read. Temporal models retain the R10 fixed effects and pen
random intercept. A count is called stable only when equivalence within one
GIFT is supported at both later ages and all four detection thresholds;
bounded coverage analogously uses five percentage points. Directional results
outside those margins use complementary minimum-effect tests, so an estimate
whose interval crosses a margin is reported as magnitude-uncertain. Figure S5
keeps the community union, per-genome distribution and bounded denominator as
separate panels. Figure S6 plots population-standardised adjusted means for all
three sampling days on metric-specific shared scales; its lines connect model
estimates and are not individual-bird trajectories. Figure S7 selects frames
classified as decreasing beyond the margin at both later ages, verifies that
their member-GIFT carrier fractions sum to the frame metric in every sample,
and shows the six largest descriptive GIFT-level declines per frame. It does
not perform per-GIFT hypothesis tests. Figure S8 repeats the frame models after
summing member-GIFT `abundance_coverage`, with abundance closed within each
sample's detected MAGs, and compares equal-weight carrier-prevalence changes
with abundance-weighted carrier-share changes for the displayed GIFTs.
Reference frames remain analytical groupings of unchanged calls, not new
composite GIFTs. The script refuses a database whose checksum differs from the
R10 audit; if the working database has advanced, `R10_DB_PATH` can point to the
archived, hash-matching SQLite artifact.

`31-r10-size-expectation.R` asks how much of the fall in per-MAG repertoire the
GTDB size relation predicts. It refits the quasi-binomial expectation of
`26-gtdb-repertoire-genome-size.R` for every reference frame, applies it to
each MAG at its length divided by reported completeness, and splits a sample's
mean per-MAG richness exactly into the mean expectation and the mean deviation.
Because the GTDB panel was evaluated against a later database than the audited
R10 calls, the script evaluates the MAGs again against the database named in
the GTDB audit and refuses any other; `R10_DB_PATH` can point to that archived
artifact. It reuses the audited detection and abundance matrices, which do not
depend on the database, and it rewrites no `21`, `22` or `24` output. Its
observed contrasts therefore differ slightly from those in R10, which stand on
database 2026.30.1. MAG incompleteness lowers the observed count but not the
expectation, so the deviation is read beside the variant restricted to MAGs at
least 90% complete, the raw-length variant and the quality-adjusted expectation.

## R10b Microflora Danica environmental complement

`25-r10-mfd.R --prepare` locks an environmental panel independently of marker
annotations and calls. It joins the atlas's 19,253-MAG quality table to all
5,518 deposited representatives of its 95% ANI `secondary_cluster` values, and
selects 45 samples from each of eight exact habitat classes. Samples must have
a published abundance profile, reliable coordinates and a distinct 10-km grid
cell within their class. A deterministic geographic maximin rule gives 360
spatially distributed samples spanning field, grassland, forest, greenspace,
bog/fen, freshwater-sediment, saltwater-sediment and wastewater communities.
The manifests and every selection decision are committed under `r10-mfd/`.

The case-specific remote workflow acquires the checksum-pinned Zenodo
archives, extracts only those 5,518 representatives and annotates them with the
existing shared Drakkar 2.6.6 environment on Mjolnir. The full Drakkar
projection remains in scratch. A lossless projection against the exact copied
gifter marker catalogue, its full-input checksum, the compiled SQLite artifact,
quality/cluster metadata and selected abundance table form the verified local
transfer. This keeps calls reproducible against one database release without
loading tens of millions of irrelevant annotation rows into R.

The final analysis collapses the published non-dereplicated Sylph MAG profiles
by `secondary_cluster` before joining the one representative. It reads carbon
acquisition, aromatic catabolism, nitrogen acquisition, sulfur acquisition,
chemical detoxification and bounded biomass-essential anabolism across
positive, 0.01% and 0.1% detection thresholds. Habitat summaries are
descriptive; no significance test, differential-abundance analysis or
ordination is run. Genome completeness changes only the reading of negative
calls, and cluster abundance does not establish that every strain carries a
representative's accessory capability. The supporting archive is named for the
atlas nitrifier analysis, but no nitrification claim is made because the
current catalogue has no such reference frame.

## GTDB-wide phylogenetic overview

`23-gtdb-phylogeny.R --prepare` pins the official GTDB R11-RS232 bac120 tree,
metadata, taxonomy, metadata schema and checksum manifest. Eligible genomes
must be species representatives present as tips in that main tree and must be
labelled `Complete Genome` and `full` in the NCBI-derived GTDB fields. Of the
12,094 genomes meeting those assembly criteria, eligibility further requires
at least one reviewed origin-group assignment from the raw isolation-source
field. The resulting 4,116 genomes span 49 phyla, 120 classes and 321 orders.
Selection takes one phylogenetic medoid per eligible order, takes the 85
candidates assigned to the food/fermentation origin group, and uses that count
as the common target for every origin group with enough eligible genomes.
Smaller groups are retained exhaustively. Balance is advanced before marginal
rooted Faith phylogenetic diversity, with accession as the final tie-break. The
resulting 696-genome panel retains every eligible phylum, class and order.
Annotation or GIFT values never enter selection. One food/fermentation genome
the procedure chose could not be annotated and is removed in `--prepare`
through `gtdb-phylogeny/excluded-genomes.tsv`, so that group holds 84.

The committed panel manifest retains the GTDB tree-tip accession, BioSample,
BioProject, isolation source, genome category, geography, dates, submitter,
strain and taxon identifiers, including blank raw fields. Every selected
genome has BioSample and BioProject accessions, so richer origin attributes can
later be joined without guessing from names or altering the panel. The local
cache contains only pinned GTDB sources and, once the run is authorised and
complete, the checksum-verified Drakkar projection. The case-specific README
documents the Mjolnir workflow and the limits of the eventual overview.
Reviewable, nonexclusive origin rules produce separate animal-associated and
plant-associated fields rather than a combined host field; the corresponding
summary table reports 84 food/fermentation, 85 animal-associated and 85
plant-associated genomes in the selected panel. Fungal, air/built-environment
and algal origins are included exhaustively because fewer than 85 are eligible.

## output/

Committed derived tables. `kegg-genome-set.tsv` is the reference genome set —
every KEGG genome with its NCBI taxon and GenBank assembly, which is the key an
external phenotype record joins on. `gift-prevalence.tsv` is how many of those
genomes carry a complete implementation of each GIFT, with the denominator
stated in the table rather than assumed. `marker-reach.tsv` is per curated
marker, how many genomes carry it, and `NA` where the namespace is not reachable
through KEGG at all.

The four `worked-example-*.tsv` files are the numeric and evidential source for
Figures 1, 4 and 5. `worked-example-purine-trace.tsv` follows the complete AMP
route to its two supplied gene identifiers;
`worked-example-frame-metrics.tsv` records the bounded/unbounded and
assessability contrasts; and the two community files record the metric values
and three exact extracellular edges of the four-genome arabinoxylan fixture.
These are controlled illustrations assembled from accepted database markers,
not annotations of named organisms or substitutes for the empirical R10 case
study.

The `r10-*` outputs are the durable evidence for R10 and Figure 7.
`r10-input-audit.tsv` pins the dataset, annotation and database identities;
`r10-drakkar-marker-counts.tsv` records retained markers by genome and
namespace; `r10-detection-sensitivity.tsv` and
`r10-confidence-sensitivity.tsv` expose the two predeclared sensitivity axes;
`r10-age-summary.tsv` and `r10-age-contrasts.tsv` contain the descriptive and
adjusted temporal results; `r10-bounded-anabolism-gaps.tsv` retains every
bounded-frame GIFT over the high-completeness MAGs; and the network and chain
tables retain the exact plant-fibre topology summaries. Large row-level tables
are stored as `.tsv.xz`: supported calls, sample traits, genome traits, and the
per-genome resource/autonomy metrics and GIFT-level trace.

The follow-up tables use the `r10-handoff-*`, `r10-richness-mode-*` and
`r10-followup-audit.tsv` prefixes. Compact summaries and adjusted contrasts are
plain TSVs. The sample-level compatibility, anchor, chain-status and null
tables are compressed as `.tsv.xz`. `r10-handoff-graph.tsv` is the complete
three-link claim boundary for this analysis; no unlisted extracellular edge is
inferred. `r10-richness-mode-driver.tsv` records the data-selected driver and
`r10-richness-mode-gifts.tsv` retains every GIFT it supports and how often it
was the sole detected provider.

The coarse temporal follow-up uses the `r10-frame-time-*` prefix.
`r10-frame-membership.tsv` is the trace from every frame to its database-derived
GIFT members; the compressed sample table retains each value used by the
models; `r10-frame-time-adjusted-means.tsv` contains the three fitted values and
confidence intervals plotted in Figure S6;
`r10-frame-time-gift-adjusted-means.tsv` retains trajectories for every GIFT in
the clearly changing frames; `r10-frame-time-gift-detail.tsv` records the
descriptive Figure S7 selection; the `r10-frame-time-abundance-weighted-*`
tables contain the weighted sample values, models and classifications;
`r10-frame-time-gift-abundance-weighted-adjusted-means.tsv` and
`r10-frame-time-gift-weighting-sensitivity.tsv` retain the GIFT-level Figure S8
comparison; and the remaining summary, contrast, confidence-sensitivity and
classification tables distinguish a directional association,
equivalence-supported stability, detection sensitivity, magnitude uncertainty
and absence of a detected association. The audit pins both cached readings,
the margins and the multiple-testing correction.

The size follow-up uses the `r10-size-expectation-*` prefix. `-mags.tsv` holds
each MAG's estimated size, supported count, expectation, deviation and
prevalence by age; `-frame-models.tsv` records the GTDB fit behind each frame;
`-age-contrasts.tsv` holds the observed, size-expected and deviation contrasts
for every frame, detection threshold and sensitivity variant, with the share
the expectation reproduces; `-genome-size-contrasts.tsv` is the age model of
mean estimated genome size; `-taxon-partition.tsv` splits each contrast into
turnover between and within taxa at five ranks; `-mag-associations.tsv` and
`-completeness.tsv` are the MAG-level checks; and `-audit.tsv` pins the
database, annotation and model.

`madin-agreement.tsv` carries the same columns as `phenotype-agreement.tsv`
plus the representative-draw range, so the two can be read side by side without
being pooled. `madin-attrition.tsv` is per target the share of multi-genome
species whose genomes agree on the call.
`incompleteness-assessability.tsv` is per genome, gene-content level, bounded
frame and quality policy, the numerator and denominator of `supported_fraction`
and `assessable_fraction`. Invariant 21 is checked on every one of its cells
rather than asserted: if the completeness policy ever moved a numerator,
`02-incompleteness.R` stops.

`cooccurrence-contexts.tsv` is one row per curated context — a component within
its enzyme system, or a required unit within its route, mechanism, architecture
or circuit — with the panel counts behind every proportion in it, including
`gaps_in_panel`: the reference genomes that satisfy the context and lack the
target anyway. That column is the irreducible false-fill rate, and it is in the
table rather than in a summary because it is the number that decides whether any
of this is usable.

`block-drop-contexts.tsv` is one row per context per run length, carrying the
conditioned and unconditioned trial counts behind both dropout rates and the
posterior recomputed from each, so the assumed and measured versions of the same
number sit in one table.

`madin-substrate-frequency.tsv` is coverage read the other way: every carbon
substrate the record measures, ranked by genome-backed species, with whether any
curated boundary can be tested against it. It ranks curation candidates by the
external testability their absence costs, which is a different ordering from the
one genomic prevalence gives.

`gift-prevalence.tsv` supersedes the ad-hoc per-KO counts the curation proposals
quote. Those were computed one accession at a time against
`rest.kegg.jp/link/genes/ko:`; this is the same measurement made once, for every
GIFT, through the route logic rather than through a single marker — which is a
different and better number, because a GIFT is complete when a route is, not
when one of its markers is present.

## Database consistency during long evaluations

`evaluate_gifts_community()` now takes one SQLite online-backup snapshot before
it evaluates the first genome. Sequential evaluation and every forked worker
open that same read-only, run-specific file; it is removed on success, failure,
or interruption. A `data-raw/build_database.R` that lands mid-run can therefore
replace the original file without changing any call already in progress, and
the evaluator never retries against the newer database.

The race this guarantee closes happened once, on 2026-08-27: a run spanning the 2026.27.1 rebuild
reported `serine_biosynthesis` at 6 757 genomes, where a clean run against the
finished database gives 6 805 and the database before it gave 6 752. Nothing
errors and nothing looks wrong; the file is simply a blend of two databases, and
it was 48 genomes out on the one GIFT the release touched.

The affected historical output still has to be re-run against a settled
database and compared on a GIFT whose evidence the rebuild changed. Two
diagnostics that do *not* establish consistency are:

- *Probing a few hundred genomes for call disagreements.* A release that moves 48
  genomes out of 11 908 will not appear in a 300-genome probe, so a clean result
  means nothing. This was tried first and it gave a confident false negative.
- *Comparing against the counts in the `database_changes.tsv` entry.* Those are
  often hand-computed marker conjunctions rather than route evaluations, and the
  two disagree by tens of genomes in both directions — 2026.26.1 estimated 3 157
  for `glcnac_degradation` where the pipeline gives 3 189, and 2026.27.1
  estimated 6 764 for `serine_biosynthesis` where it gives 6 805. The *deltas*
  are sound; the absolutes are not, which is the reason this table exists.

## The cache

Everything downloaded lands in `.cache/`, one file per request, and is
gitignored. Re-running an analysis must not re-hit a public service — both out
of courtesy and because a benchmark whose inputs move underneath it is not
reproducible. Commit derived summaries; never commit the cache.

Licences differ and matter. BacDive and MediaDive are CC BY 4.0. KEGG's REST
service is for academic use and its derived tables must not be redistributed,
so a KO × genome matrix stays in the cache and only summaries leave it.

## The agreement helper

`agreement()` in `_common.R` exists to make the wrong statistic hard to compute.
Under invariant 15 a positive call is a necessary, not sufficient, condition for
a phenotype, so the two disagreements are not symmetric: an organism that
encodes a capability but does not show it is *permitted*, while an organism that
shows a capability the genome does not encode is a failure. The helper reports
both cells separately and a recall against observed positives, and there is
deliberately no accuracy, F1 or AUC to reach for. `polarity = "falsifying"` is
for anabolic capabilities, where growth without a nutrient makes a positive call
refutable and both directions carry information.

The reasoning behind all of it is
[the phenotype validation assessment](../../inst/doc/proposal-phenotype-validation.md).
