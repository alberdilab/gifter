# gifter

[![pkgdown](https://github.com/alberdilab/gifter/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/alberdilab/gifter/actions/workflows/pkgdown.yaml)
[![Documentation](https://img.shields.io/badge/docs-pkgdown-1f425f.svg)](https://alberdilab.github.io/gifter/)
![Status: under development](https://img.shields.io/badge/status-under%20development-orange.svg)
[![License: MIT-0](https://img.shields.io/badge/license-MIT--0-blue.svg)](LICENSE)

MIT-0 covers the software and original documentation. The curated database has
mixed upstream provenance; read [data licensing and review status](inst/DATA-LICENSING.md)
before redistributing it or using it commercially.

gifter infers whether a genome encodes a biologically defined capability, and
shows the curated evidence behind every call.

> [!NOTE]
> **Development status:** gifter is under active development. Its API and
> curated reference database may change as its completeness models and content
> mature.

The intended 1.0 public API, result-field, schema and deprecation guarantees are
spelled out in the [v1 compatibility contract](inst/doc/compatibility.md). The
current 0.7 series enforces those database and result checks before the promise
takes effect.

A genome-inferred functional trait (GIFT) is a biologically meaningful
capability whose genomic support is evaluated through an explicit, curated and
traceable completeness model. Each GIFT declares a `gift_type` naming that
model:

```text
GIFT
├── metabolic     a directed capability between curated molecular anchors
├── structural    the machinery to build a defined cellular structure
├── regulatory    the machinery to sense a signal and execute a response
└── defense       the machinery to execute a defined defense mechanism
```

The packaged database currently contains 153 GIFTs: 143 metabolic, 2
structural, 3 regulatory and 5 defense capabilities. These counts are checked
against the compiled database in the package tests. Examples include the
flagellar apparatus and type IVa pilus; chemotaxis, aspartate chemoreception and
phosphate-response signalling; and restriction-modification, CRISPR-Cas and
chemical-detoxification machinery.

## What gifter does

- Determines whether genomic marker evidence supports a biologically defined
  capability, with the precision of each claim set by its `gift_type` and
  completeness contract.
- Evaluates metabolic routes and structural, regulatory, and defense machinery
  through explicit Boolean models of alternatives and jointly required parts.
- Reports complete calls and the closest incomplete implementation, including
  the missing requirements and the markers and genes behind the result.
- Connects metabolic capabilities only through declared molecular anchors, so
  composition follows curated biological boundaries rather than incidental
  shared intermediates.
- Produces traceable genome- and community-level summaries using declared
  reference frames and explicit denominators.

## What gifter does not

- Infer expression, activity, physiological state, environmental relevance, or
  phenotype from the presence of encoded machinery.
- Model media, nutrient or metabolite availability, concentrations, or whether
  a capability will operate in a particular environment.
- Perform flux balance analysis or model flux, thermodynamics, growth, biomass,
  exchange reactions, or genome-scale stoichiometry and mass balance.
- Infer cellular localisation. Anchors carry only a narrow `extracellular`,
  `cytoplasmic`, or `unspecified` compartment qualifier so that transport
  boundaries can be stated; reactions, intermediates, and markers are not
  compartment-aware.

## The evaluation model

A metabolic GIFT is complete when a curated enzymatic route is complete:

```text
metabolic GIFT    OR  valid routes
route             AND required reactions
reaction          OR  valid enzyme systems
enzyme system     AND required components
component         OR  accepted genomic markers
```

A structural GIFT is complete when a curated architecture is complete, and the
regulatory and defense types follow the same shape under their own names:

```text
structural GIFT   OR  curated architectures
architecture      AND required structural functions
structural fn     OR  valid systems
system            AND required components
component         OR  accepted genomic markers
```

Completeness is discrete in every type. An incomplete call names the closest
implementation and what is missing from it — one reaction, or one structural
function — never a percentage of expected genes.

Only declared anchors connect metabolic GIFTs. Internal reaction participants
are not runtime entities, so an intermediate cannot accidentally create a trait
edge. Structural GIFTs declare no anchors at all: a flagellum has no input
molecule, and inventing one to fit the metabolic schema would be a boundary
claim nobody could defend.

## Evidence specificity bounds every call

The specificity of a claim never exceeds the specificity of the evidence. KEGG
assigns the sodium-driven PomA/PomB stator of *Vibrio* to the same orthologues as
the proton-driven MotA/MotB of *E. coli*, so gifter curates one ion-agnostic
`flagellar_apparatus` rather than two traits its evidence cannot separate.

Where evidence *does* separate two claims, both are curated and kept apart. A
generic chemoreceptor accession is assigned to 34 genes in one *Vibrio cholerae*
genome, so it supports `chemotaxis_signal_transduction` and nothing narrower;
the Tar orthologue is anchored on a characterised ligand, so it additionally
supports `aspartate_chemoreception`. A genome with only the generic receptor
completes the first and not the second, and the fix is never to widen the
generic marker.

Every refusal is recorded in the database changelog and in the type proposals:
[structural](https://github.com/alberdilab/gifter/blob/main/inst/doc/proposal-structural-gifts.md),
[regulatory](https://github.com/alberdilab/gifter/blob/main/inst/doc/proposal-regulatory-gifts.md),
[defense](https://github.com/alberdilab/gifter/blob/main/inst/doc/proposal-defense-gifts.md).

## Install

```r
remotes::install_github("alberdilab/gifter", build_vignettes = TRUE)
library(gifter)
```

## Workflows

Four workflow guides walk through a complete analysis. Start at the first if
gifter is new to you.

```r
vignette("evaluating-a-genome", package = "gifter")   # annotations -> calls -> evidence
vignette("quantitative-traits", package = "gifter")   # calls -> comparable numbers
vignette("community-analysis", package = "gifter")    # many genomes -> distribution and topology
vignette("multi-sample-datasets", package = "gifter") # samples -> detection-aware comparisons
browseVignettes("gifter")
```

| Vignette | Covers |
|---|---|
| [1. Evaluating a genome](https://alberdilab.github.io/gifter/articles/evaluating-a-genome.html) | the input format, which markers were used, reading complete and incomplete calls, why evidence specificity bounds a claim, tracing a call back to genes |
| [2. From calls to quantitative traits](https://alberdilab.github.io/gifter/articles/quantitative-traits.html) | reference frames, richness and breadth, when gifter refuses to give you a fraction, MAG completeness and honest denominators |
| [3. A genome-resolved community](https://alberdilab.github.io/gifter/articles/community-analysis.html) | provider counts and redundancy, presence versus abundance, potential resource handoffs, and why a cytoplasmic molecule never crosses between genomes |
| [4. Many samples over one catalogue](https://alberdilab.github.io/gifter/articles/multi-sample-datasets.html) | one fixed catalogue across samples, detection thresholds, per-sample traits and networks, and traceable exports |

To understand how those capabilities enter the database, read
[How a GIFT is built](https://alberdilab.github.io/gifter/articles/curating-a-gift.html).
The [Glossary](https://alberdilab.github.io/gifter/articles/glossary.html) defines
both analysis concepts and technical curation terms such as equivalog, profile
HMM and gathering threshold.

## Evaluate a genome

The packaged reference database contains the atomic capabilities `PRPP > IMP`,
`IMP > AMP`, `IMP > GMP`, `glutamine + PRPP > UMP`, and `UTP > CTP`. Input is a
marker table with `namespace` and `accession`; `gene_id` is optional but
recommended for evidence tracing.

```r
annotations <- data.frame(
  gene_id = paste0("gene_", 1:9),
  namespace = "KO",
  accession = c(
    "K00764", "K01945", "K00601", "K01952", "K01933",
    "K01587", "K01756", "K00602", "K01939"
  )
)

result <- evaluate_gifts(annotations)
result$gifts[, c(
  "gift_id", "complete", "number_of_complete_routes", "best_route",
  "minimum_missing_reactions"
)]
```

One genome goes in per call. Because a mislabelled gene column and a pooled
collection of genomes both produce calls that look correct, `evaluate_gifts()`
settles both before evaluating: a table without a `gene_id` column has its
first other column proposed for approval (`gene_id = "locus_tag"`,
`gene_id = TRUE`, or `gene_id = FALSE` to number the markers instead), and an
input carrying more than `max_genes` distinct genes is questioned as a possible
collection of genomes.

A table that really does span several genomes goes to
`evaluate_gifts_community()`, which splits it on its `genome_id` column,
evaluates every genome separately and in parallel, and returns the community
container directly:

```r
community <- evaluate_gifts_community(annotations)   # genome_id, gene_id, namespace, accession
community_traits(community)
```

A genome evaluated there is identical to the same genome evaluated alone, and
the number of workers changes wall time and nothing else. A large community
reports its progress at an interactive console, in genomes evaluated out of
genomes to evaluate, with an estimate of the time remaining.

`evaluate_gifts()` returns a transparent list of tibbles: `gifts`, `routes`,
`reactions`, `systems`, `components`, and `evidence`, plus a `structural`,
`regulatory` and `defense` view for the machinery types. Incomplete traits
report the closest route and its missing Rhea reactions; a percentage of
detected genes is not used as the primary call.

One call evaluates a mixed-type database. The `gifts` summary carries
`gift_type` and a type-neutral answer for every GIFT — `best_implementation`,
`minimum_missing_requirements`, `missing_requirements` — beside the metabolic
route columns:

```r
result$gifts[, c(
  "gift_id", "gift_type", "complete", "best_implementation",
  "minimum_missing_requirements", "evidence_confidence"
)]

# Browse by type, and read a non-metabolic GIFT's curated machinery
list_gifts(type = c("regulatory", "defense"))
get_gift_machinery("flagellar_apparatus")
get_gift_machinery("type_i_restriction_modification")

# Trace either kind of call back to the genes responsible
trace_gift(result, "purine_core_biosynthesis")
trace_gift(result, "flagellar_apparatus")
```

Trace a call back to genes:

```r
trace_gift(result, "adenylate_biosynthesis")
```

Inspect the automatically derived composition:

```r
gift_graph()
# purine_core_biosynthesis  --IMP-->  adenylate_biosynthesis
# purine_core_biosynthesis  --IMP-->  guanylate_biosynthesis
```

## Summarise genomes and communities

Calls are the primary result. The quantitative layer summarises sets of them
without changing any, and every number carries the set it was counted over.

```r
traits <- genome_traits(result, genome_id = "MAG_001")
subset(traits$metrics, metric_id == "gift_richness",
       c("reference_frame", "value", "assessable"))

# Why is that number what it is? The trace names the GIFTs behind it.
subset(traits$trace, metric_id == "gift_richness")
```

A fraction of the catalogue is reported only for a frame declared `bounded`,
meaning curation intends to cover it completely. Supporting 12 metabolic GIFTs
does not mean a genome lacks every other possible metabolic capability, so no
fraction of the unbounded metabolic catalogue is offered:

```r
list_reference_frames()  # reusable, versioned frames and recommended metrics

autonomy <- reference_frame(preset = "biomass_essential_anabolism")
genome_traits(result, frames = list(autonomy))
```

The same registry exposes questions such as carbohydrate degradation, plant
fibre utilisation, nitrogen acquisition, fermentation products and vitamin
biosynthesis. Membership is resolved from curated metadata in the current
database release rather than stored as a list of GIFT identifiers:

Browse the searchable [reference-frame chooser](https://alberdilab.github.io/gifter/atlas/#frames)
to compare every preset by biological question, analysis scale, recommended
metrics, denominator status and interpretation limits.

```r
carbohydrate <- reference_frame(preset = "carbohydrate_degradation")
genome_traits(result, frames = list(carbohydrate))
```

For several genomes, evaluate them together — or bind results you already
have — and ask how capability is distributed:

```r
community <- evaluate_gifts_community(annotations)   # one table, split by genome_id
community <- gifter_community(A = result_a, B = result_b, C = result_c)
community_traits(community)          # richness, provider counts, singletons
community_network(community)         # potential resource handoffs
```

A handoff edge means one genome encodes a GIFT whose declared extracellular
output another genome's GIFT consumes. It is a potential compatibility
relationship, not evidence that exchange occurs. If genome completeness is
supplied, absences on fragmented genomes are withheld from every denominator
rather than counted as capabilities the genome lacks:

```r
community_traits(
  gifter_community(A = result_a, B = result_b),
  quality = c(A = 0.98, B = 0.55),
  policy = "completeness", threshold = 0.9
)
```

## Many samples over one catalogue

One MAG catalogue mapped against many samples is a `gifter_dataset`: the
catalogue is evaluated once, and a sample is a restriction of that reading to
its detected genomes and a reweighting by their abundance. Calls are a property
of a genome, so nothing is re-evaluated per sample.

```r
dataset <- gifter_dataset(catalogue, abundance, metadata)   # genome x sample
dataset_traits(dataset)                                     # per sample
dataset_network(dataset)                                    # per sample
sample_community(dataset, "s2")                             # an ordinary community
```

Detection is to samples what assessability is to genomes: both may only move
denominators. Neither can promote an unsupported GIFT to supported, and
`detection` is supplied when the calls are read rather than when the dataset is
built, so one dataset is read at two thresholds without being rebuilt. Every
sample-level richness is reported beside `detected_genomes`, because absence
from a sample may be below detection and gifter models no sequencing depth.

gifter stops there. It runs no test, differential-abundance analysis,
ordination or effect size between groups of samples, and interprets no metadata
column. What it exports instead is an assessability-aware matrix with a declared
reference frame, in which a genome's silence about a capability it was never
well enough observed to assess is `NA` rather than a fabricated zero:

```r
capabilities <- gift_matrix(dataset, quality = quality,
                            policy = "completeness", threshold = 0.9)
coverage <- dataset_matrix(dataset_traits(dataset), "abundance_coverage", fill = 0)
vegan::adonis2(vegan::vegdist(coverage) ~ group, data = metadata)
```

## Inspect the reference database

```r
list_gifts()
get_gift_anchors("purine_core_biosynthesis")
get_gift_routes("purine_core_biosynthesis")
get_gift_reactions("adenylate_biosynthesis")
get_gift_reactions("guanylate_biosynthesis")
get_gift_reactions("pyrimidine_core_biosynthesis")
get_gift_reactions("cytidylate_biosynthesis")
get_reaction_systems("RHEA:17129")
gifter_db_version()
```

Rhea master IDs identify reactions. Reaction direction within a GIFT is stored
separately as `forward` or `reverse`. ChEBI IDs identify only declared boundary
anchors; internal compounds such as GAR, AIR, AICAR, dihydroorotate, and
orotidine 5'-phosphate are intentionally absent from the anchor vocabulary.

## Curating and rebuilding

The biological procedure is described in
[How a GIFT is built](https://alberdilab.github.io/gifter/articles/curating-a-gift.html),
from the initial claim and completeness model through marker-specificity review,
provenance, validation and an implemented, deferred or refused outcome.

The reviewable source of truth is
[`inst/extdata/database-source`](https://github.com/alberdilab/gifter/tree/main/inst/extdata/database-source). The SQLite file
is a compiled artifact, never the hand-curated source.

```r
validate_gifter_sources("inst/extdata/database-source")
build_gifter_database(
  "inst/extdata/database-source",
  "inst/extdata/gifter.sqlite",
  overwrite = TRUE
)
```

Development rebuilds retain the source table's explicit `unreleased` marker.
For a final release artifact, set `GIFTER_SOURCE_COMMIT` to the full commit that
contains the TSV sources, schema and compiler before running
`data-raw/build_database.R`. The build proves that the commit exists, that those
inputs are unchanged from it, and that none has uncommitted work. This permits a
later artifact-only commit without a circular self-reference; the identifier is
never guessed or fabricated.

Generate a self-contained, interactive atlas after curating or rebuilding the
database:

```r
write_gifter_database_html("gifter-database.html", open = TRUE)
```

The current reference atlas is also published at
[alberdilab.github.io/gifter/atlas](https://alberdilab.github.io/gifter/atlas/).
It is generated from the packaged SQLite database by the documentation workflow;
the public page is a view of that versioned artifact, not a separate source of
biological definitions.

The report includes release metadata and row counts, a whole-database network
view drawing every GIFT together with its declared anchors, in which a GIFT is a
large dot and an anchor a small one -- hover a dot for its identifier and
boundaries, click a GIFT to open it, and recolour either kind of dot by the
metadata it carries -- a merged route network for every GIFT, the complete GIFT-to-marker evidence hierarchy, the
curation changelog linked to the traits each change affects, an entity map, and
a searchable browser for every SQLite table.

The biological changelog is part of the database rather than a file beside the
code, so it travels with the compiled artifact:

```r
database_changelog()
database_changelog("pyrimidine_core_biosynthesis")
```

Package and API changes are tracked separately in
[CHANGELOG.md](CHANGELOG.md). The package build script refreshes the compiled
SQLite database. The HTML atlas is generated on demand locally and by the
package website workflow, so the installed package does not carry a second copy
of the same database content.

See [the architecture guide](https://github.com/alberdilab/gifter/blob/main/inst/doc/architecture.md)
for the schema, curation rules, version model, and design boundaries.
Contributors and coding agents should also follow the repository-wide
[agent instructions](https://github.com/alberdilab/gifter/blob/main/AGENTS.md).
