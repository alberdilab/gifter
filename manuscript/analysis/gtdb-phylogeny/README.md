# GTDB-wide GIFT overview

This analysis is the phylogenetic overview proposed for Figure S4. It uses the
GTDB R11-RS232 bacterial reference tree and metadata. It does **not** reuse the
legacy DistillR matrix in the adjacent staged-genome project: those values are
fractional marker fullness under an older database and do not satisfy gifter's
current Boolean completeness contract.

The biological invariant is that a coloured cell means that the selected
genome has marker support for one complete, current GIFT implementation. It
does not mean expression, activity, flux, phenotype, ecological importance or
an ancestral-state reconstruction. An unsupported cell is likewise not proof
of biological absence.

Figure S4 is an overview rather than an ancestral-state analysis. Every one of
the 697 locked genomes is a row ordered by the pruned GTDB bac120 tree. The
panels show that tree, a phylum strip, one heatmap column for every current GIFT
grouped by `gift_type`, and the total supported and high-confidence-or-curated
GIFT counts for each genome. Heatmap values remain Boolean completeness calls;
colour separates the confidence of positive calls and does not turn partial
routes or machinery into fractional support. This makes phylogenetically local
changes in encoded repertoire breadth visible without claiming that the figure
reconstructs gains, losses or ancestral states.

## Locked panel

The official source files, release URLs and SHA-256 checksums are recorded in
`source-manifest.tsv`. The starting population is the 12,094 R232 bacterial
species representatives that occur as tips in the main bac120 reference tree
and whose NCBI metadata says both `assembly_level = Complete Genome` and
`genome_representation = full`. Eligibility additionally requires assignment
to at least one reviewed origin group from the raw isolation-source field. This
retains 4,116 genomes across 49 phyla, 120 classes and 321 orders and excludes
7,978 without a classified origin. “Complete Genome” is an assembly-level
filter; it does not imply that every assembly originated from an isolate.

The panel size is an outcome rather than a preset target. Selection first takes
the phylogenetic medoid of each of the 321 eligible GTDB orders. It then uses 85
genomes—the size of the complete food/fermentation group—as the common balance
target for every origin group with at least 85 eligible members and retains all
members of smaller groups. At each step it advances the least-represented group,
avoids increasing a group whose target is already complete where possible, and
chooses the genome with the greatest marginal rooted Faith phylogenetic
diversity. Accession is the deterministic tie-break. This produces 697 genomes:
321 order medoids and 376 balance-aware additions. Selection uses no annotation,
marker, GIFT call or phenotype. The resulting `selected-genomes.tsv`,
`selected-genomes.tree` and `selection-audit.tsv` lock the panel before
annotation. It retains all 49 phyla, 120 classes and 321 eligible orders and
164.564 of the eligible tree's 312.792 branch-length units (52.6%).

`selected-genomes.tsv` retains the exact GTDB tree-tip accession and an
explicit tree-membership flag. It also carries every origin field available in
the pinned GTDB metadata: NCBI BioSample and BioProject accessions, isolate and
isolation source, genome category, country, coordinates, submission and
sequence-release dates, submitter, strain identifiers, taxon identifiers and
WGS master accession. These raw fields and cross-references are retained even
when blank. GTDB R232 has no dedicated host or collection-date column; richer
BioSample attributes can therefore be joined later through the retained
BioSample accession without changing or guessing the locked selection.

The reviewable regular-expression rules in `origin-group-rules.tsv` map the raw
isolation-source field to nonexclusive origin tags. In particular,
`animal_associated` and `plant_associated` are separate columns; there is no
combined `host_associated` category. Fungal and algal associations are also
kept separate. The raw isolation-source text remains in the manifest, and the
derived tags are coarse metadata groupings rather than claims about ecological
function. `origin-group-summary.tsv` reports eligible and selected counts plus
the balance target and taxonomic spread of every group. Food/fermentation,
animal-associated, plant-associated and the other sufficiently large groups
each contribute 85 genomes; aquatic origin contributes 87 because of
unavoidable nonexclusive overlap. The smaller fungal, air/built-environment and
algal groups are represented exhaustively by 6, 49 and 51 genomes,
respectively. Counts are nonexclusive, so they do not sum to the panel size.

Prepare or reproduce the panel from the repository root:

```sh
Rscript manuscript/analysis/23-gtdb-phylogeny.R --prepare
```

The script downloads pinned inputs into the ignored
`manuscript/analysis/.cache/gtdb-phylogeny/sources/` directory when needed.

## Mjolnir annotation

Scratch layout:

```text
/projects/alberdilab/scratch/jpl786/projects/gifter-gtdb-phylogeny/
  tasks/01-genome-acquisition/{manifests,genomes,logs}/
  tasks/02-drakkar-annotation/{output,logs}/
  tasks/03-result-transfer/{output,logs}/
```

Copy `selected-genomes.tsv` to
`tasks/01-genome-acquisition/manifests/`. Copy each script in `remote/` to the
task implied by its name, making the scripts executable. Then:

1. run `setup-scratch.sh`;
2. submit `download-genomes.sh` with `sbatch`;
3. inspect `download.complete`, `resolved-downloads.tsv` and
   `genome-sha256.tsv`; these compact acquisition records are included in the
   final checksum-verified transfer;
4. place `run-drakkar.sh` in task 02 and `screen-driver.sh` plus
   `prepare-transfer.sh` in task 03;
5. launch task 03's `screen-driver.sh` in a detached `screen` session;
6. run `monitor-and-fetch.sh` locally; after checksum-verifying the transfer,
   it launches the final analysis.

The final evaluation follows the proven R10 chicken ingestion path: it checks
the four-column Drakkar marker schema, the six expected per-genome annotation-QC
records, Drakkar version and manifest schema, the locked panel identity, and
every transferred checksum before calling any GIFT. Genome calls are cached by
the annotation and gifter-database checksums, so a plotting retry cannot silently
reuse calls from another input or database. Set `GTDB_PHYLOGENY_WORKERS` to
control evaluation parallelism; the default is eight.

The run uses the existing shared Drakkar environment and its `gifter`
annotation mode. It does not install or update Drakkar. The generated
`annotation_manifest.yaml`, rather than this README, is authoritative for tool,
database and threshold versions.

Genome acquisition resolves each GCA accession against the current NCBI
GenBank bacterial assembly summary. If an R232 accession is absent there, the
script retrieves the same INSDC assembly accession from the official ENA
Browser API instead. `resolved-downloads.tsv` records the source and exact URL
per genome, and `genome-sha256.tsv` pins every downloaded FASTA.

## Outputs

The final script writes:

- `gtdb-phylogeny-input-audit.tsv`, with source, annotation, database and
  analysis checksums;
- `gtdb-phylogeny-calls.tsv.xz`, one current call per genome and GIFT, retaining
  the best implementation, missing requirements, supporting components,
  markers and genes;
- `gtdb-phylogeny-genome-summary.tsv`, repertoire counts retaining every
  genome and taxonomic rank;
- `gtdb-phylogeny-gift-summary.tsv`, panel prevalence with an explicit
  denominator of 697 and the heatmap column order;
- `gtdb-phylogeny-phylum-summary.tsv`, descriptive genome-level ranges;
- `figure-s4-gtdb-phylogeny.{pdf,png}`.

The panel intentionally overrepresents lineages relative to their abundance in
GTDB. Its summaries describe these 697 selected complete assemblies; they are
not estimates of prevalence among bacterial genomes, organisms or communities.
