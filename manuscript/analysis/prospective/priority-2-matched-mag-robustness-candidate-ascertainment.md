# Priority 2 candidate ascertainment: matched isolate and MAG-like draft

Status: candidate ascertainment and annotation/assembly audit completed
2026-10-01T16:00Z. This record is neither a MAG catalogue nor a prospective
assay outcome. It adds no row to the prospective registry and changes no GIFT
definition.

## Question and invariant

The Priority 2 question is narrowly computational: when one exact isolate
assembly and one genuinely reassembled, lower-read-input draft come from the same
identified isolate read source, which gifter annotations and calls change? A
change is an **annotation/assembly change**. It is never a gain or loss of a
capability in the strain.

The audit preserves three boundaries:

1. The deposited complete isolate, each MAG-like draft and any future MAG must
   be separate annotation inputs and separate `source_id` values.
2. No mixed or contaminated input can be called one genome's complete
   machinery. This audit introduces no foreign read, performs no binning and
   therefore contains no MAG or contaminated/mixed bin at all.
3. Fixed annotation-table gene removal is a separate synthetic evaluator check,
   labelled as such. It is not a read assembly, MAG, assay, or biological
   observation.

## Eligibility rule and decision

An eligible pair requires all of the following before a draft is created:

- a complete, isolate-derived assembly with an explicit strain designation;
- an unambiguous WGS/GENOMIC read run from the same BioSample and BioProject;
- a public raw-read URL with a published checksum; and
- de-novo reassembly from reads of that single isolate, without a reference or
  reads from another organism.

The standard MG1655 reference `GCA_000005845.2` was rejected for this purpose.
Its assembly-to-SRA links resolve to ChIP/ChIP-exo data, rather than a
whole-genome assembly read source. A familiar reference name is not sufficient
provenance for a matched reassembly.

The accepted pair is *Escherichia coli* K-12 substr. MG1655:

| Record | Evidence that licenses its use | Role here |
| --- | --- | --- |
| [`GCA_000801205.1`](https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/801/205/GCA_000801205.1_ASM80120v1/GCA_000801205.1_ASM80120v1_assembly_report.txt) | NCBI reports a one-contig, 4,636,831-base complete genome, 85x coverage, BioSample `SAMN02743420`, BioProject `PRJNA237120`, strain K-12 substr. MG1655 and Pacific Biosciences submission. NCBI's `md5checksums.txt` gives genomic-FASTA MD5 `1211f39561b395ed30c216dab20e6fa6`. | exact deposited isolate assembly |
| [`SRR1284073`](https://www.ebi.ac.uk/ena/browser/view/SRR1284073) | ENA reports a PacBio RS II `WGS`/`GENOMIC`/`RANDOM`, single-read library titled “Escherichia coli MG1655 strain for PacBio P5C3 sequencing”, with the same BioSample and BioProject. The published FASTQ MD5 is `c7bfee38f9fd6d427026060e3e857694`. | sole raw-read source for the MAG-like draft |

The raw inputs and matching rule are stored in
[`matched-mag-robustness-inputs.tsv`](matched-mag-robustness-inputs.tsv). A
future candidate that fails any element of the rule is excluded rather than
being relabelled as a matched MAG.

## Audit design — annotation evidence only

[`17-priority2-matched-mag-robustness.R`](../17-priority2-matched-mag-robustness.R)
checks the ENA and NCBI MD5s before use, records SHA-256 digests for every raw
input, deterministic read subset, profile library, generated assembly and the
exact gifter SQLite database, then
uses these three distinct sources:

| `source_id` | `genome_role` | Input | Interpretation |
| --- | --- | --- | --- |
| `MG1655_exact_isolate` | isolate | deposited `GCA_000801205.1` | exact-isolate reannotation |
| `MG1655_draft_reads_20pct` | MAG-like draft | deterministic 20% subset of `SRR1284073` reads | genuinely reassembled matched draft; not a MAG |

Flye reassembles only the deterministic read subset de novo. Because the public
run repeats subread labels, the selected FASTQ replaces only each first header
token with a deterministic source-and-record identifier; the original header
follows after whitespace, and no sequence or quality value is changed. Prodigal uses the same
`-p meta` invocation for the isolate and draft. The same gifter-oriented,
multi-namespace HMM pipeline then searches KOfam, NCBIfam/TIGRFAM/Pfam and
dbCAN evidence. It records KOfam adaptive score type and threshold; HMMER
`--cut_ga` for NCBIfam/TIGRFAM/Pfam; and dbCAN independent E-value below
`1e-15` plus profile coverage above `0.35`, retaining the full-library count
for `-Z`. The two current EC markers have no profile source in this pinned
pipeline and are deliberately not supplied to gifter; that scope limitation is
recorded in the threshold table rather than silently treated as a negative
annotation.

The audit preserves each source's accepted marker rows and runs `trace_gift()`
for every GIFT, whether supported or not. It writes every isolate/draft call
pair to a transition table. `supported_to_unsupported` means missing draft
annotation evidence, and `unsupported_to_supported` means newly recovered
draft annotation evidence; neither phrase licenses biological loss or gain.

For a separate fixed-table invariant check, the runner removes all traced
accepted genes for each isolate-supported GIFT, re-evaluates every GIFT, and
stops if removal promotes an unsupported call or if a lost call has no missing
requirement. Its final assessability exercise uses an explicitly synthetic
policy input solely to demonstrate that a policy withholds absence denominators
without changing calls. It does not estimate or report MAG completeness or
quality.

## Results — annotation evidence only

The checksum-verified deposited assembly has one 4,636,831-base contig. The
20% deterministic read subset reassembled de novo into seven contigs totalling
4,661,755 bases. Under the same annotation pipeline, the isolate had 97
supported GIFT calls and the draft had 64. Of 153 paired calls, 33 were
`supported_to_unsupported_annotation_assembly_change`, 120 had no call change,
and none were `unsupported_to_supported`.

The 97 fixed-annotation removal scenarios yielded zero unsupported-to-supported
promotions. They produced 130 supported-to-unsupported calls, each with at
least one reported missing requirement, as the runner requires. In the
separate synthetic assessability exercise, the bounded biomass-essential
anabolic frame retained the same supported numerator (35) while its denominator
changed from 44 to 35. The policy value is intentionally synthetic and is not a
MAG-quality measurement.

These are annotation/evaluator results only. They neither identify a change in
the organism nor establish a biological outcome.

## Outputs and limitations

The generated directory
[`matched-mag-robustness-audit/`](matched-mag-robustness-audit/) contains the
input and tool manifests, profile thresholds, source-separated assemblies and
marker hits, full calls and `trace_gift()` evidence, call transitions, fixed
annotation gene-removal results and their missing-requirement traces, and the
assessability-invariant table.

This one-strain, one-lineage, one-draft-level exercise is a reproducibility and annotation
robustness case study. It does not measure MAG quality, bin contamination,
organismal abundance, expression, activity, phenotype, growth or any ecological
outcome. It does not establish robustness across lineages. A later study that
uses real MAGs must add independent read/assembly provenance, an explicit
binning and contamination protocol, source-separated annotation inputs, and
one or more additional lineages before reporting a broader denominator.
