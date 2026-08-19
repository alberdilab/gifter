# giftr

giftr infers whether a genome encodes a biologically defined capability, and
shows the curated evidence behind every call.

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

All four carry curated content: 61 metabolic capabilities, the flagellar
apparatus and type IVa pilus, chemotaxis and phosphate-response signalling, and
type I restriction-modification and type I-E CRISPR-Cas machinery.

"Functional" is intentionally broad; the precision comes from the type and from
the completeness contract it carries. giftr deliberately does not model media,
metabolite availability, flux, thermodynamics, growth, compartments, or
genome-scale stoichiometry.

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

## What a positive call does not mean

A call says the genome encodes the curated machinery. It does not say the
machinery is expressed, active, or consequential. `flagellar_apparatus` is not
motility; `type_iva_pilus` is not twitching, competence or adhesion.

The same limit applies to specificity: the specificity of a claim never exceeds
the specificity of the evidence. KEGG assigns the sodium-driven PomA/PomB stator
of *Vibrio* to the same orthologues as the proton-driven MotA/MotB of *E. coli*,
so giftr curates one ion-agnostic `flagellar_apparatus` rather than two traits
its evidence cannot separate.

Where evidence *does* separate two claims, both are curated and kept apart. A
generic chemoreceptor accession is assigned to 34 genes in one *Vibrio cholerae*
genome, so it supports `chemotaxis_signal_transduction` and nothing narrower;
the Tar orthologue is anchored on a characterised ligand, so it additionally
supports `aspartate_chemoreception`. A genome with only the generic receptor
completes the first and not the second, and the fix is never to widen the
generic marker.

Every refusal is recorded in the database changelog and in the type proposals:
[structural](inst/doc/proposal-structural-gifts.md),
[regulatory](inst/doc/proposal-regulatory-gifts.md),
[defense](inst/doc/proposal-defense-gifts.md).

## Install

```r
remotes::install_github("alberdilab/giftr")
library(giftr)
```

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
       c("reference_universe", "value", "assessable"))

# Why is that number what it is? The trace names the GIFTs behind it.
subset(traits$trace, metric_id == "gift_richness")
```

A fraction of the catalogue is reported only for a universe declared `bounded`,
meaning curation intends to cover it completely. Supporting 12 of 122 metabolic
GIFTs does not mean a genome lacks 110 capabilities, so no such fraction is
offered:

```r
autonomy <- gift_universe(
  mode = "anabolic", auxotrophy_indicator = TRUE, bounded = TRUE,
  label = "biomass-essential anabolic GIFTs"
)
genome_traits(result, universes = list(autonomy))
```

For several genomes, bind them into a community and ask how capability is
distributed:

```r
community <- giftr_community(A = result_a, B = result_b, C = result_c)
community_traits(community)          # richness, provider counts, singletons
community_network(community)         # potential resource handoffs
```

A handoff edge means one genome encodes a GIFT whose declared extracellular
output another genome's GIFT consumes. It is a potential compatibility
relationship, not evidence that exchange occurs. If genome completeness is
supplied, absences on fragmented genomes are withheld from every denominator
rather than counted as capabilities the genome lacks:

```r
giftr_community(
  A = result_a, B = result_b,
  quality = c(A = 0.98, B = 0.55),
  policy = "completeness", threshold = 0.9
)
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
giftr_db_version()
```

Rhea master IDs identify reactions. Reaction direction within a GIFT is stored
separately as `forward` or `reverse`. ChEBI IDs identify only declared boundary
anchors; internal compounds such as GAR, AIR, AICAR, dihydroorotate, and
orotidine 5'-phosphate are intentionally absent from the anchor vocabulary.

## Curating and rebuilding

The reviewable source of truth is
[`inst/extdata/database-source`](inst/extdata/database-source). The SQLite file
is a compiled artifact, never the hand-curated source.

```r
validate_giftr_sources("inst/extdata/database-source")
build_giftr_database(
  "inst/extdata/database-source",
  "inst/extdata/giftr.sqlite",
  overwrite = TRUE
)
```

Generate a self-contained, interactive atlas after curating or rebuilding the
database:

```r
write_giftr_database_html("giftr-database.html", open = TRUE)
```

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
[CHANGELOG.md](CHANGELOG.md). The package build script also refreshes the
packaged snapshot at `inst/extdata/giftr-database.html`.

See [the architecture guide](inst/doc/architecture.md) for the schema, curation
rules, version model, and design boundaries. Contributors and coding agents
should also follow the repository-wide [agent instructions](AGENTS.md).
