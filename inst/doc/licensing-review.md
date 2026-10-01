# Human redistribution review dossier

Status: 2026-10-01. This is a dated record of public, primary-source evidence
and of the exact gifter content that a later human review must consider. It is
not legal advice, a legal interpretation, permission, or a licence grant.

## Scope and invariant

The review is documentation and provenance hardening only. It changes no GIFT,
marker, route, reaction, external-pathway relation, compiled SQLite database,
database version, schema version, or release metadata. This evidence must not
change an UPSTREAM-SOURCES.tsv row to cleared without a documented decision by
an appropriate human reviewer.

The biological invariant for later remediation is unchanged: a replacement
marker must support the same named component at the specificity of the GIFT,
and an omitted marker or pathway reference must remain traceable. Removing an
upstream-derived record is therefore a biological database change, even if it
does not alter a final Boolean call.

## Inventory at database 2026.27.1

| Review subject | Redistributed or repository-tracked material in scope |
| --- | --- |
| KEGG | 753 KO marker identifiers with names and descriptions; 336 KEGG_REACTION reaction cross-references; 99 KEGG_MODULE and 97 KEGG_PATHWAY GIFT references, including names and gifter's boundary relation. |
| dbCAN and CAZy | 520 CAZY marker records: 467 dbCAN-sub cluster identifiers and 53 bare CAZy-family identifiers. The tracked curation inputs are data-raw/reference/fam-substrate-mapping.tsv, cazy-subfamily-ec.tsv, and dbcan_sub_names.txt; data-raw/ is excluded from the R source archive but remains redistributed in the Git repository. |
| InterPro member records | No INTERPRO marker namespace is shipped. InterPro was used to inspect member-record metadata for the one cleared Pfam marker and five legacy unversioned TIGRFAM markers; the latter remain in scope under their own review row. |
| NCBIfam | 78 NCBIFAM marker records with accessions, names, equivalog grades and evidence notes: 57 NF accessions and 21 TIGR accessions distributed through the NCBIfam release. |
| TIGRFAM legacy records | Five unversioned TIGRFAM marker records with accessions, names and descriptions. |
| MetaCyc / BioCyc | 13 METACYC GIFT cross-references with identifiers, pathway names, and gifter-curated boundary relations and notes. |

The counts above are an audit inventory, not an argument that every field has
the same copyright status. Gifter's boundary choices, relation values and
explanatory notes are its own curation; an upstream identifier or title remains
a separate question.

## Evidence and required human decision

### KEGG

Public evidence: [KEGG Copyright and Disclaimer](https://www.genome.jp/kegg/legal.html)
(last updated 2024-10-01; accessed 2026-10-01) describes KEGG as a copyrighted
database product, permits academic use of its website or mirror, requests an
academic service-provider licence for services, and says non-academic use
requires a commercial licence. It does not state a general grant to redistribute
the selected identifiers, titles, descriptions, cross-references or derived
records in this package.

Human decision needed: obtain written permission or a documented resource-owner
or counsel interpretation that explicitly covers the inventory, including
downstream commercial redistribution under gifter's MIT-0 software licence. If
that cannot be documented, a replacement/removal proposal must identify a
specific, equivalently discriminating evidence source for every affected
component. A mechanical KO deletion is not safe: it would change the evidence
layer and may narrow or eliminate calls.

### dbCAN and CAZy

Public evidence: the [AWS Open Data Registry record for run_dbcan](https://github.com/awslabs/open-data-registry/blob/main/datasets/run_dbcan.yaml)
(accessed 2026-10-01) labels the run_dbcan dataset as having no restrictions on
use. It identifies a dataset hosted in the dbcan S3 bucket, but it does not say
whether that statement sublicenses CAZy-origin family definitions, characterised
activities, or derived fields in the pinned files. The [CAZy website](https://www.cazy.org/)
did not expose a resource-level terms page during this audit; current indexed
family pages display a copyright footer. The absence of a located terms page is
not evidence that redistribution is forbidden or permitted.

Human decision needed: confirm with the data steward and, where needed, CAZy
whether the registry statement applies to the three tracked files and to the
520 selected marker records. If it does not, remediation must distinguish
release-specific dbCAN-sub identifiers from stable CAZy families and establish
specific alternative evidence; broad enzyme labels would violate gifter's
specificity invariant.

### InterPro member records

Public evidence: [InterPro's licence page](https://interpro-documentation.readthedocs.io/en/latest/license.html)
(accessed 2026-10-01) places InterPro, Pfam, PRINTS and SFLD downloadable data
under CC0 1.0, while expressly stating that included scanning tools and
signature collections may be subject to different terms. The [InterPro member
database description](https://www.ebi.ac.uk/training/online/courses/interpro-quick-tour/interpro-data/)
identifies NCBIfam, including TIGRFAM, as a member database.

Human decision needed: keep the cleared Pfam assessment separate, and decide
whether API-delivered metadata for NCBIfam/TIGRFAM member signatures may be
redistributed under the member resource's terms. The InterPro CC0 statement
alone is not recorded as clearance for those member records.

### NCBIfam and NCBI distribution

Public evidence: the [NCBI policy](https://www.ncbi.nlm.nih.gov/home/about/policies/)
(accessed 2026-10-01) says NCBI places no restrictions on use or distribution
of molecular data in its databases, but also says it has no rights to transfer
when original submitters may claim rights. The [current NCBI HMM directory](https://ftp.ncbi.nlm.nih.gov/hmm/current/)
identifies the pinned 2026-06-25 HMM release and its metadata files.

Human decision needed: determine whether the accession, family name, grade,
profile-derived annotation and evidence-note fields in the 78 records are within
that molecular-data statement, and whether JCVI-origin records require an
additional permission. Do not infer clearance from public FTP availability.

### TIGRFAM legacy records

Public evidence: the [JCVI TIGRFAMs description](https://www.jcvi.org/research/tigrfams)
identifies TIGRFAMs as curated family definitions with seed alignments, HMMs,
cutoffs and annotations for transfer; the [TIGRFAMs terminology page](https://tigrfams.jcvi.org/cgi-bin/Terms.cgi)
identifies the material as a JCVI-copyrighted resource. These pages explain the
scientific object but do not provide a redistribution grant for the five legacy
records.

Human decision needed: obtain a JCVI/NCBI determination for the legacy
accessions and annotations, including their use through InterPro or NCBIfam. If
removal becomes necessary, separately curate an alternative marker for each
component and retain why a broad substitute does not meet the original claim's
specificity.

### MetaCyc / BioCyc

Public evidence: the [BioCyc terms](https://bioinformatics.ai.sri.com/ptools/licensing/all-reg.shtml)
(accessed 2026-10-01) distinguish limited databases from other BioCyc databases,
state that limited databases may not be redistributed, and prescribe conditions
for distribution of a BioCyc database in original or modified form. The terms do
not expressly resolve whether a small selection of pathway identifiers and
titles, accompanied by gifter's original boundary relation, is redistribution of
a BioCyc database or derived database content.

Human decision needed: request an SRI determination for the 13 identifier/title
references, or have qualified counsel document the applicable interpretation.
If removal is chosen, remove only source-derived identifier and title fields
through a reviewed database change; retain or separately document gifter's
boundary comparison so that traceability is not silently lost. No such removal
is made by this dossier.

## Resolution record required before v1

For each human_review_required row, a human reviewer must record the resource,
release or access date, exact material considered, source-owner permission or
terms interpretation, reviewer and date, and any attribution or redistribution
conditions. If the conclusion is removal or replacement, follow the full
biological-database workflow in AGENTS.md: update provenance and
database_changes.tsv, preserve the claim's specificity and traceability, rebuild
SQLite, run reproducibility validation, and run the complete relevant package
audit.

This dossier neither authorizes external contact nor a DOI/archive deposition.
It does not start v1 release planning.
