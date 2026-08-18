# giftr

giftr infers whether a genome encodes a biologically defined enzymatic
capability between curated molecular anchors.

A genome-inferred functional trait (GIFT) is a directed capability with one or
more declared input and output anchors. Reactions describe how those boundaries
are connected; enzyme systems, required protein components, and genomic markers
describe the evidence needed to call the capability. giftr deliberately does
not model media, metabolite availability, flux, thermodynamics, growth,
compartments, or genome-scale stoichiometry.

## The evaluation model

```text
GIFT              OR  valid routes
route             AND required reactions
reaction          OR  valid enzyme systems
enzyme system     AND required components
component         OR  accepted genomic markers
```

Only declared anchors connect GIFTs. Internal reaction participants are not
runtime entities, so an intermediate cannot accidentally create a trait edge.

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
`reactions`, `systems`, `components`, and `evidence`. Incomplete traits report
the closest route and its missing Rhea reactions; a percentage of detected
genes is not used as the primary call.

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

The report includes release metadata and row counts, two whole-database network
views (GIFT composition, and GIFTs drawn together with their declared anchors),
a merged route network for every GIFT, the complete GIFT-to-marker evidence
hierarchy, the curation changelog linked to the traits each change affects, an
entity map, and a searchable browser for every SQLite table.

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
