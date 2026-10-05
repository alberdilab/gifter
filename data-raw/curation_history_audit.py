#!/usr/bin/env python3
"""Audit links between current GIFTs, expansion attempts, and curation files.

This inspects the current source tree. It cannot reconstruct the code or inputs
used in an older analysis that were not retained in the repository.
"""

import csv
import re
import sys
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def rows(path):
    with (ROOT / path).open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def values(cell):
    return [value.strip() for value in cell.split(";") if value.strip()]


def main():
    attempts = rows("inst/doc/catalogue-expansion-attempts.tsv")
    evidence = rows("inst/extdata/database-source/gift_evidence.tsv")
    gifts = {row["gift_id"] for row in rows("inst/extdata/database-source/gifts.tsv")}
    changes = rows("inst/extdata/database-source/database_changes.tsv")
    by_gift = defaultdict(set)
    for row in evidence:
        by_gift[row["gift_id"]].add(row["evidence_kind"])

    citation_pattern = re.compile(r"PMID:?\s*\d{7,8}|pubmed\.ncbi\.nlm\.nih\.gov/\d+|doi\.org/|DOI:\s*10\.", re.I)

    def linked_document_cites_publication(attempt):
        return any(
            citation_pattern.search((ROOT / path).read_text(encoding="utf-8"))
            for path in values(attempt["source"])
            if path.endswith(".md") and (ROOT / path).is_file()
        )

    print("period\tattempts\timplemented_gifts\tgifts_with_document\tgifts_with_script\tgifts_with_result\tattempts_with_script_source\tattempts_with_analysis_result_source\tattempts_with_publication_identifier_in_linked_document")
    for name, selected in (
        ("before_2026_10", [a for a in attempts if a["started_at"] < "2026-10-01"]),
        ("from_2026_10", [a for a in attempts if a["started_at"] >= "2026-10-01"]),
        ("all", attempts),
    ):
        implemented = {gift for attempt in selected for gift in values(attempt["implemented_gifts"])}
        counts = [
            name,
            len(selected),
            len(implemented),
            sum("curation_document" in by_gift[gift] for gift in implemented),
            sum("analysis_script" in by_gift[gift] for gift in implemented),
            sum("result_table" in by_gift[gift] for gift in implemented),
            sum(any(path.endswith((".R", ".py")) for path in values(a["source"])) for a in selected),
            sum(any(
                path.startswith(("data-raw/", "manuscript/analysis/"))
                and path.endswith((".tsv", ".csv", ".txt"))
                for path in values(a["source"])
            ) for a in selected),
            sum(linked_document_cites_publication(a) for a in selected),
        ]
        print("\t".join(map(str, counts)))

    missing_gifts = sorted(gifts - {gift for a in attempts for gift in values(a["implemented_gifts"])})
    missing_documents = sorted(gift for gift in gifts if "curation_document" not in by_gift[gift])
    missing_paths = sorted({
        path
        for path in (
            row["location"] for row in evidence
        )
        if not (ROOT / path).is_file()
    } | {
        path
        for attempt in attempts
        for path in values(attempt["source"])
        if not (ROOT / path).is_file()
    })
    print(f"# biological_change_rows={len(changes)}")
    print(f"# gifts_missing_attempt={','.join(missing_gifts) or 'none'}")
    print(f"# gifts_missing_document={','.join(missing_documents) or 'none'}")
    print(f"# missing_source_paths={','.join(missing_paths) or 'none'}")

    if len(sys.argv) > 1:
        anchors = rows("inst/extdata/database-source/gift_anchors.tsv")
        routes = rows("inst/extdata/database-source/gift_routes.tsv")
        route_reactions = rows("inst/extdata/database-source/route_reactions.tsv")
        xrefs = rows("inst/extdata/database-source/gift_xrefs.tsv")
        systems = rows("inst/extdata/database-source/enzyme_systems.tsv")
        components = rows("inst/extdata/database-source/enzyme_components.tsv")
        markers = rows("inst/extdata/database-source/component_markers.tsv")
        for gift_id in sys.argv[1:]:
            if gift_id not in gifts:
                raise SystemExit(f"Unknown GIFT: {gift_id}")
            print(f"# gift={gift_id}")
            print("# anchors=" + ";".join(
                f'{row["role"]}:{row["anchor_id"]}'
                for row in anchors if row["gift_id"] == gift_id
            ))
            gift_routes = [row for row in routes if row["gift_id"] == gift_id]
            reaction_ids = set()
            for route in gift_routes:
                steps = sorted(
                    (row for row in route_reactions if row["route_id"] == route["route_id"]),
                    key=lambda row: int(row["step_order"]),
                )
                reaction_ids.update(row["reaction_id"] for row in steps)
                print(f'# route={route["route_id"]} ' + ";".join(
                    f'{row["reaction_id"]}:{row["orientation"]}:required={row["required"]}'
                    for row in steps
                ))
            system_ids = {row["system_id"] for row in systems if row["reaction_id"] in reaction_ids}
            component_ids = {row["component_id"] for row in components if row["system_id"] in system_ids}
            print("# markers=" + ";".join(sorted({
                f'{row["namespace"]}:{row["accession"]}'
                for row in markers if row["component_id"] in component_ids
            })))
            print("# xrefs=" + ";".join(sorted(
                f'{row["namespace"]}:{row["accession"]}:{row["relation"]}'
                for row in xrefs if row["gift_id"] == gift_id
            )))


if __name__ == "__main__":
    main()
