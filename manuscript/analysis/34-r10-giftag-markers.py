#!/usr/bin/env python3
"""Compare R10 marker presence per MAG within gifter's marker vocabulary."""

import csv
import lzma
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path("manuscript/analysis")
OUTPUT = ROOT / "output" / "r10-giftag"
MARKERS = Path("inst/extdata/database-source/markers.tsv")
INPUTS = {
    "drakkar": ROOT / ".cache/r10-chicken/drakkar/gifter_input.tsv.xz",
    "giftag": ROOT / ".cache/r10-chicken/giftag/giftag_markers.tsv.xz",
}
GENOMES = ROOT / ".cache/r10-chicken/giftag/giftag_genomes.tsv"
DRAKKAR_QC = ROOT / ".cache/r10-chicken/drakkar/annotation_qc.tsv"


def write_table(path, columns, rows):
    with path.open("w", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
        writer.writerow(columns)
        writer.writerows(rows)


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    with MARKERS.open(newline="") as handle:
        vocabulary = {
            (row["namespace"], row["accession"])
            for row in csv.DictReader(handle, delimiter="\t")
        }
    if len(vocabulary) != 1576:
        raise SystemExit("Unexpected gifter marker vocabulary")
    presence = {}
    summaries = []
    for caller, path in INPUTS.items():
        all_rows = Counter()
        target_rows = Counter()
        observed = defaultdict(set)
        with lzma.open(path, "rt", newline="") as handle:
            reader = csv.DictReader(handle, delimiter="\t")
            for row in reader:
                namespace = row["namespace"]
                all_rows[namespace] += 1
                marker = (namespace, row["accession"])
                if marker in vocabulary:
                    target_rows[namespace] += 1
                    observed[namespace].add((row["genome_id"], row["accession"]))
        presence[caller] = observed
        for namespace in sorted(all_rows):
            pairs = observed[namespace]
            summaries.append((
                caller, namespace, all_rows[namespace], target_rows[namespace],
                len({genome for genome, _ in pairs}), len(pairs),
            ))
    write_table(
        OUTPUT / "r10-giftag-marker-scope.tsv",
        ("caller", "namespace", "all_rows", "gifter_vocabulary_rows",
         "genomes_with_vocabulary_marker", "unique_genome_markers"),
        summaries,
    )

    rows = []
    for namespace in sorted(set(presence["drakkar"]) | set(presence["giftag"])):
        d = presence["drakkar"].get(namespace, set())
        g = presence["giftag"].get(namespace, set())
        common = len(d & g)
        union = len(d | g)
        rows.append((namespace, common, len(d - g), len(g - d), union,
                     common / union if union else ""))
    write_table(
        OUTPUT / "r10-giftag-marker-concordance.tsv",
        ("namespace", "shared_genome_markers", "drakkar_only",
         "giftag_only", "union_genome_markers", "jaccard"),
        rows,
    )
    by_genome = defaultdict(lambda: [set(), set()])
    for caller, slot in (("drakkar", 0), ("giftag", 1)):
        for namespace, pairs in presence[caller].items():
            for genome, accession in pairs:
                by_genome[genome][slot].add((namespace, accession))
    if len(by_genome) != 822:
        raise SystemExit(f"Expected 822 MAGs, found {len(by_genome)}")
    rows = []
    for genome, (d, g) in sorted(by_genome.items()):
        common = len(d & g)
        union = len(d | g)
        rows.append((genome, len(d), len(g), common, len(d - g), len(g - d),
                     common / union if union else ""))
    write_table(
        OUTPUT / "r10-giftag-marker-genomes.tsv",
        ("genome_id", "drakkar_markers", "giftag_markers", "shared_markers",
         "drakkar_only", "giftag_only", "jaccard"),
        rows,
    )
    with DRAKKAR_QC.open(newline="") as handle:
        drakkar_proteins = {
            row["mag"]: int(row["retained_records"])
            for row in csv.DictReader(handle, delimiter="\t")
            if row["level"] == "gene" and row["source"] == "prodigal"
        }
    with GENOMES.open(newline="") as handle:
        giftag_proteins = {
            row["genome_id"]: int(row["proteins"])
            for row in csv.DictReader(handle, delimiter="\t")
        }
    if set(drakkar_proteins) != set(giftag_proteins) or len(giftag_proteins) != 822:
        raise SystemExit("Gene-prediction summaries do not cover the same 822 MAGs")
    write_table(
        OUTPUT / "r10-giftag-gene-counts.tsv",
        ("genome_id", "drakkar_proteins", "giftag_proteins", "difference"),
        ((genome, drakkar_proteins[genome], giftag_proteins[genome],
          giftag_proteins[genome] - drakkar_proteins[genome])
         for genome in sorted(giftag_proteins)),
    )
    print("Compared gifter-vocabulary marker presence in 822 MAGs")


if __name__ == "__main__":
    main()
