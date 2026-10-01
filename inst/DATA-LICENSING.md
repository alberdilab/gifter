# Software, curated data, and upstream terms

This file records scope; it is not legal advice.

## Software

The MIT No Attribution licence in `LICENSE` applies to gifter's original
software code and documentation. It does not purport to relicense identifiers,
descriptions, classifications, or other material obtained from upstream data
resources.

## Curated reference database

The reviewable TSV files in `inst/extdata/database-source/` contain gifter's
curated boundary choices, Boolean completeness structures, provenance notes,
and selected upstream identifiers and metadata. `inst/extdata/gifter.sqlite` is
a compiled form of those files. The package and database versions are
independent, and the software licence is not a blanket licence for this mixed-
provenance database.

Every upstream resource used by shipped content is listed in
`inst/extdata/UPSTREAM-SOURCES.tsv`, with the pinned release or access date,
source and terms URLs, the material used, and the current redistribution
assessment. `inst/extdata/database-source/SOURCES.md` remains the detailed
record of biological derivation and boundary decisions.

Rhea and ChEBI state CC BY 4.0 terms, and Pfam states CC0. Those sources must
still be cited as recorded in the manifest. Public access is not treated as a
licence for any other resource.

## Human review required before v1 publication

The manifest deliberately marks KEGG, dbCAN/CAZy, InterPro member records,
NCBIfam/TIGRFAM, and MetaCyc/BioCyc as `human_review_required`. Their public
terms either restrict use, do not clearly grant redistribution, distinguish
software from data, or do not clearly address the selected identifiers and
metadata shipped here.

This is a release blocker, not a conclusion that distribution is forbidden.
Before publishing v1, a human must document permission or a defensible terms
interpretation for each marked row, or remove/replace the affected redistributed
material and rerun the database validation, reproducibility check, and package
tests. Do not change a manifest row to `cleared` merely because the resource is
free to browse or accessible through an API.

## User responsibilities

Downstream users are responsible for complying with applicable upstream terms,
especially for commercial use. Cite gifter through `citation("gifter")` and
cite the upstream resources supporting the capabilities used in an analysis.
The manifest and `SOURCES.md` provide the starting point; neither transfers
rights held by upstream providers or publication authors.
