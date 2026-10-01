# Priority 1 candidate ascertainment: aspartate chemoreception

Status: candidate ascertainment and exact-assembly annotation audit completed
2026-10-01T08:28Z. This is neither a prospective assay result nor a GIFT
redefinition. The candidate roster is
[`aspartate-chemoreception-candidates.tsv`](aspartate-chemoreception-candidates.tsv).

## Question and invariant

`aspartate_chemoreception` is a regulatory GIFT. A positive call means that a
genome encodes Tar (`KO:K05875`) and the required CheA/CheW, CheY and CheB/CheR
functions. It means an aspartate-responsive chemosensory input is encoded; it
does not mean the cell swims toward aspartate. A generic MCP (`KO:K03406`),
motility, or an MCP-dependent response to some other ligand cannot supply the
Tar function.

Historical chemotaxis experiments are candidate-selection evidence only. They
are not copied into `observations.tsv`, and the planned experiment must measure
a ligand-specific receptor/pathway response under a locked protocol rather than
using motility alone as the outcome.

## Candidates admitted to a protocol draft

### Specific-positive candidate: *Escherichia coli* K-12 MG1655

An agarose-plug and in-situ assay study measured robust MG1655 accumulation to
L-aspartate and alpha-methyl-aspartate
([source study](https://pmc.ncbi.nlm.nih.gov/articles/PMC6121982/)). NCBI's
MG1655 BioProject identifies the matching complete reference assembly
[`GCF_000005845.2`](https://www.ncbi.nlm.nih.gov/bioproject/57779). The
published cell-accumulation observation entails a working motor and assay
conditions in addition to the GIFT's encoded signalling machinery, so it is
`related` selection evidence rather than an equivalent prospective endpoint.

### Broad-marker control: *Pseudomonas aeruginosa* PAO1

PAO1 has many generic MCPs; for example, KEGG assigns PA4915 to `K03406`
([record](https://www.kegg.jp/entry/pae%3APA4915)). It has also been measured
responding to 4-chloroaniline through an MCP-dependent chemotaxis system
([CtpL study](https://pmc.ncbi.nlm.nih.gov/articles/PMC3837763/)). Neither
fact identifies L-aspartate reception. PAO1 is therefore a broad-marker genetic
control, not an expected negative for any future aspartate-response phenotype:
the planned assay must measure its own endpoint.

## Exact-assembly circuit audit — not a prospective outcome

[`14-priority1-aspartate-chemoreception-annotation.R`](../14-priority1-aspartate-chemoreception-annotation.R)
searched the two exact NCBI protein FASTAs with the seven relevant KOfam
profiles. Its [input manifest](aspartate-chemoreception-annotation-audit/input-manifest.tsv)
content-addresses both proteomes, the KOfam source, the threshold table, every
extracted profile and gifter database `2026.27.1`. All retained hits and both
the ligand-specific and generic-core traces are in
[`aspartate-chemoreception-annotation-audit/`](aspartate-chemoreception-annotation-audit/).

| Exact assembly | Tar-specific evidence | Generic-core result | Aspartate GIFT result |
| --- | --- | --- | --- |
| MG1655 `GCF_000005845.2` | `NP_416400.1` passes `K05875`; CheA/CheW, CheY and CheB/CheR each have accepted support | complete | complete; zero missing functions |
| PAO1 `GCF_000006765.1` | no accepted `K05875` | complete through 27 accepted `K03406` proteins and its required downstream functions | incomplete; exactly the Tar reception function is missing |

The generic KOfam MCP model also reports several MG1655 receptors, including
Tar. That overlap is expected for a broad signalling-domain model and does not
make the generic accession ligand-specific. The audit classifies MG1655 through
its separate `K05875` hit, while PAO1 remains `broad_marker_only` precisely
because it has no accepted Tar hit.

This audit says nothing about receptor expression, ligand binding in the assay,
gradient formation, flagellar motors, cell movement or phenotype. It remains
outside the prospective registry.

## What must happen before the runner is used

1. Lock a receptor/pathway endpoint that distinguishes an L-aspartate response
   from generic chemotaxis and record why its relation to the machinery claim
   is `equivalent`, `subset_of`, or `related`.
2. Lock culture conditions, ligand concentrations, no-ligand and non-aspartate
   controls, biological replicate count, signal-exclusion rule, and whether a
   motor-independent readout is used.
3. Retain the checksum-pinned annotation rows and traces; separately state how
   Tar identity is confirmed in the experimental strain.
4. Only after the protocol is locked and matched assays exist, add registry rows
   and run `11-prospective-validation.R`.

No GIFT marker, biological source, SQLite artifact, schema or package API
changes follow from this candidate screen or audit.
