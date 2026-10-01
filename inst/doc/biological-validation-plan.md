# Prospective biological validation

Status: proposed 2026-10-01. This is a study plan, not a new GIFT definition or
a condition for distributing the current database. The existing retrospective
analyses are in `proposal-phenotype-validation.md` and
`manuscript/analysis/`; their committed outputs must remain distinguishable
from observations collected under this plan.

## What is already measured

- `03-phenotype.R`, `04-auxotrophy.R` and `07-madin.R` compare calls with
  independently recorded strain or species observations. They report recall
  against observed positive phenotypes only where a reviewed crosswalk says
  the observation matches the curated claim. Most GIFTs have no such external
  observation. The coverage count must be regenerated with the database used
  for publication.
- `05-annotation-route.R` compares KEGG's KO assignments, KofamScan, and a
  pinned multi-namespace annotation pipeline on the same assemblies. It
  measures how annotation affects calls; it is not independent biological
  evidence for a function.
- `02-incompleteness.R` removes genes from reference genomes and checks both
  call retention and assessability. `10-block-drop.R` additionally tests
  contiguous loss. Neither substitutes for a matched real MAG and isolate.

The next study should target questions these analyses cannot answer. Its unit
is a **strain with a matched genome**, annotation, and observation. Keep the
assembly accession, strain identifier, annotation pipeline and version, GIFT
database version, crosswalk relation, and assay conditions on every result.
Choose strains before looking at the gifter calls where possible, and keep the
remaining selection rule and exclusions in the analysis record. Include
distinct lineages and report them beside each denominator; multiple strains
of one genus are not independent breadth across biology.

## Priority 1: challenge claim specificity

Choose a small set of claims for which a related but broader marker is known
to be dangerous. The current curation supplies candidate contrasts:

| Claim to challenge | Specific positive evidence | Related negative control | Observation that can adjudicate the marker claim |
| --- | --- | --- | --- |
| `collagen_cleavage` | M9 collagenase evidence | Generic proteases that cleave several host proteins | Cleavage of intact collagen substrate, with a separate generic protease assay and gene-level confirmation of the catalytic family |
| `aspartate_chemoreception` | Characterised Tar receptor evidence and the required chemotaxis circuit | Generic MCP or a serine receptor with the same downstream circuit | Receptor ligand response under a matched assay, plus receptor identity; motility alone does not identify the ligand |
| Substrate-specific carbohydrate degradation | Accepted subfamily or orthologue and the complete curated route | Broad CAZy family hits, or a route missing its substrate-resolving step | Activity on the named polymer and adjacent substrates, with the relevant enzyme identities checked separately |
| Type I-E CRISPR-Cas machinery | The complete curated protein architecture | Generic Cas proteins or incomplete machinery | Presence of the specific protein complex; record array/context separately because it is not part of this GIFT claim |

For each contrast, evaluate the deposited genome with the published annotation
pipeline, then inspect `trace_gift()` down to genes. Confirm discordant marker
assignments by an independent sequence or domain analysis before proposing a
database change. If a broad marker completes a substrate- or ligand-specific
GIFT, that is a curation defect even if the organism also performs the
activity through another route: the marker itself still cannot license the
specific claim. Preserve the negative results, including excluded accessions.

## Priority 2: matched genome and MAG robustness

Take isolate genomes with matched metagenome assemblies or construct MAG-like
drafts from reads of the same strain. Run two comparisons at the same GIFT
database version: remove genes from a fixed full-genome annotation table to
test evaluation logic, then reannotate every draft with the same pinned
pipeline to measure annotation changes. Record which genes, components and
required reactions were lost or gained with each call. Vary assembly
completeness and contamination separately; a mixed or contaminated bin must
not be treated as a single genome's complete machinery.

For the fixed-annotation gene-loss series, the primary checks are mechanistic:
no unsupported full-genome call becomes supported by removing genes; every
lost supported call identifies a missing requirement; and the assessability
policy changes only which absences contribute to a denominator. In the
reannotated series, record any gained call as an annotation change rather than
an evaluation gain. Analyse contamination separately as a source of falsely
combined evidence. Compare these results with the
random and contiguous loss analyses already committed. Report the number of
matched strains and independent lineages at every quality level.

## Priority 3: direct tests of underrepresented types

For each type, test the machinery named by the GIFT and the required parts of
its curated implementation. Structural examples are a flagellar apparatus or
type IVa pilus observed by microscopy, with a strain missing one required
assembly function as a control. Regulatory examples are a receptor or sensor
response to the stated signal with the cognate regulator and downstream
readout checked; a generic stress response is insufficient. Defense examples
are type I restriction and methylation functions or direct conversion of a
named toxic chemical, with each required component inspected. Assays of
motility, chemotactic behavior, phage survival or resistance may provide useful
context, but they do not replace the machinery or chemistry test.

## Priority 4: an observed auxotrophy panel

MediaDive supplies growth on defined media but no matched *failure* to grow
without a nutrient. A controlled nutrient dropout and rescue experiment on
genome-matched strains would test the other direction of the anabolic claim.
Record a baseline medium, one omitted nutrient, growth/no-growth and rescue by
readdition, with identical conditions across strains. Restrict the primary
comparison to curated bounded anabolic frames and to nutrients whose pathway
boundary matches the omission. A positive call in a non-growing strain merits
investigation of regulation, transport and assay conditions; it is not by
itself proof that the encoded route is absent.

## Analysis and decision rules

Pre-register the exact GIFTs, assemblies, assay endpoints, crosswalk relations,
annotation versions, inclusion criteria and biological replicates before
scoring. Keep reaction-level observations separate from whole-GIFT phenotypes.
For equivalent observation/claim pairs, report the count of observed positives
that lack a supported call, the denominator, taxonomic spread, and each
missing requirement. Report supported calls without an observed phenotype as
a separate, permitted cell. Do not combine those cells into accuracy, F1, AUC
or one catalogue-wide score. For a substrate-specific marker challenge, also
report the count of broad-marker-only genomes that complete the specific GIFT;
the expected value is zero under the current curation contract.

Investigate disagreements in this order: strain–assembly identity, assay and
crosswalk boundary, annotation, marker specificity, then route or machinery
curation. A resulting biological change needs a decision in
`database_changes.tsv`, affected GIFT links in `change_gifts.tsv`, source
provenance, rebuilt SQLite and the corresponding regression test. A refusal
or unresolved case belongs in `deferral-register.md` with its retrigger.

## Repository implementation

The first implementation is a study registry and runner in
`manuscript/analysis/prospective/` and
`manuscript/analysis/11-prospective-validation.R`. It supplies empty,
reviewable TSV templates rather than invented study rows. The runner refuses to
score a planned or post-hoc protocol, a database release other than the one
pre-registered, missing assembly/annotation/assay provenance, or observations
that predate the protocol lock. It evaluates each deposited annotation on its
own, writes a GIFT or reaction trace to its genes, and keeps observation,
negative control class, assay condition and biological replicate in the result.
Its output is intentionally counts and denominators only: it cannot emit
accuracy, precision, F1, AUC or a catalogue-wide score.

## Initial candidate ascertainment

Priority 1 begins with an assay-first collagen-specificity screen in
[`manuscript/analysis/prospective/priority-1-collagen-candidate-ascertainment.md`](../../manuscript/analysis/prospective/priority-1-collagen-candidate-ascertainment.md).
It records one strain-matched M9-positive candidate, one broad-protease marker
control, and refuses a same-species genome substitution where the historical
assay strain has no established assembly. The candidate record now also links a
content-addressed exact-assembly M9 audit: it records both raw proteome and
profile/database checksums, hit-level thresholds and the resulting gene trace.
The audit establishes the planned genomic contrast, not an assay outcome. Its
follow-on synthetic loss/mixing test confirms the expected alternative-marker
logic and makes the contaminated-bin failure mode visible with source-labelled
genes; it is explicitly not a MAG result. Neither enters the registry or changes
any GIFT claim.

The same approach has begun for the regulatory specificity contrast in
[`priority-1-aspartate-chemoreception-candidate-ascertainment.md`](../../manuscript/analysis/prospective/priority-1-aspartate-chemoreception-candidate-ascertainment.md).
It pairs MG1655's strain-matched historical aspartate response with PAO1's
generic-MCP control, pins both exact assemblies and verifies that Tar plus the
complete circuit is present only in MG1655. The historical motility observation
and the genomic audit are not prospective outcomes; the endpoint still must be
locked as a receptor/pathway response before collection.

The carbohydrate contrast is now recorded in
[`priority-1-starch-candidate-ascertainment.md`](../../manuscript/analysis/prospective/priority-1-starch-candidate-ascertainment.md).
It selects the exact *Bacillus licheniformis* DSM 13 assembly as a
route-complete resolving-evidence candidate and exact *Hydrogenobacter
thermophilus* TK-6 as a broad-CAZy control, while excluding a contaminated
one-`GH13` assembly before audit. The content-addressed KOfam/dbCAN audit finds
that TK-6's broad `GH13` and `GH57` hits complete `starch_degradation` in the
unmodified database even though its resolving-marker input lacks both required
reactions. This is the failure condition the plan says must be zero: generic
CAZy/family evidence cannot support a named substrate claim. It is an
annotation-audit finding requiring separate biological curation review, not an
assay outcome, registry row, GIFT redefinition or database change.
