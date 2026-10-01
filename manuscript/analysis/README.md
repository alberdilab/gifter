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
| `11-prospective-validation.R` | A locked prospective-study registry evaluated against deposited annotations, with raw assay rows and traces | prospective validation |
| `12-priority1-collagen-annotation.R` | Checksum-pinned M9/domain audit of the exact collagen-specificity candidate assemblies; no assay input | prospective validation |
| `13-priority2-collagen-evidence-stress.R` | Synthetic loss and deliberate evidence-mixture stress test of the exact collagen audit; not a MAG | prospective validation |
| `14-priority1-aspartate-chemoreception-annotation.R` | Checksum-pinned Tar/circuit audit of the exact receptor-specificity candidates; no assay input | prospective validation |
| `15-priority1-starch-annotation.R` | Checksum-pinned KOfam/dbCAN audit of exact starch-specificity candidates, including the broad-family failure check; no assay input | prospective validation |
| `16-priority1-type-ie-crispr-annotation.R` | Checksum-pinned KOfam audit of exact Type I-E machinery candidates, including incomplete-Cascade logic; no array or assay input | prospective validation |

The curated inputs live with the other consulted evidence, in
`data-raw/reference/`: `phenotype-crosswalk.tsv` maps an observation to
something gifter claims, and `chebi-anchor-aliases.tsv` lets a metabolite
record find its anchor. `read_phenotype_crosswalk()` validates both on load and
refuses a row whose target no longer exists.

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

## output/

Committed derived tables. `kegg-genome-set.tsv` is the reference genome set —
every KEGG genome with its NCBI taxon and GenBank assembly, which is the key an
external phenotype record joins on. `gift-prevalence.tsv` is how many of those
genomes carry a complete implementation of each GIFT, with the denominator
stated in the table rather than assumed. `marker-reach.tsv` is per curated
marker, how many genomes carry it, and `NA` where the namespace is not reachable
through KEGG at all.

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
