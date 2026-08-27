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

## Do not run these while the database is being rebuilt

`01-marker-matrix.R` holds one SQLite connection for the length of a run that
takes about ninety minutes, and `evaluate_gifts_community` reads through it
chunk by chunk. A `data-raw/build_database.R` that lands mid-run replaces the
file underneath it, and the result is a `gift-prevalence.tsv` in which some
GIFTs were scored against the old database and some against the new one.

This has happened once, on 2026-08-27: a run spanning the 2026.27.1 rebuild
reported `serine_biosynthesis` at 6 757 genomes, where a clean run against the
finished database gives 6 805 and the database before it gave 6 752. Nothing
errors and nothing looks wrong; the file is simply a blend of two databases, and
it was 48 genomes out on the one GIFT the release touched.

**The check is to re-run against a settled database and compare, on a GIFT whose
evidence the rebuild changed.** Two things that do *not* work:

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
