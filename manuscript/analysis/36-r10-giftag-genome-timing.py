#!/usr/bin/env python3
"""Extract giftag per-MAG elapsed time beside Drakkar per-MAG CPU accounting."""

import csv
import re
import statistics
from pathlib import Path


ROOT = Path("manuscript/analysis")
GIFTAG = ROOT / ".cache/r10-chicken/giftag"
CASE = ROOT / "r10-chicken"
OUTPUT = ROOT / "output/r10-giftag"
LINE = re.compile(
    r"\]\s+\d+/822\s+(cmag_\d{3}) · ([\d,]+) proteins · "
    r"([\d,]+) markers · (\S+)"
)


def duration(value):
    match = re.fullmatch(r"(?:(\d+)h)?(?:(\d+)m)?([\d.]+)s", value)
    if not match:
        raise ValueError(f"Invalid giftag duration: {value}")
    hours, minutes, seconds = match.groups()
    return 3600 * int(hours or 0) + 60 * int(minutes or 0) + float(seconds)


def table(path, key):
    with path.open(newline="") as handle:
        rows = list(csv.DictReader(handle, delimiter="\t"))
    if len(rows) != 822:
        raise SystemExit(f"Expected 822 rows in {path}, found {len(rows)}")
    indexed = {row[key]: row for row in rows}
    if len(indexed) != 822:
        raise SystemExit(f"Duplicate {key} in {path}")
    return indexed


def main():
    giftag = table(GIFTAG / "giftag_genomes.tsv", "genome_id")
    drakkar = table(CASE / "benchmark/drakkar-genome-resources.tsv", "genome_id")
    inputs = table(GIFTAG / "verified-inputs.tsv", "genome_id")
    timings = {}
    for line in (GIFTAG / "giftag-stderr.log").read_text().splitlines():
        match = LINE.search(line)
        if match:
            genome, proteins, markers, elapsed = match.groups()
            if genome in timings:
                raise SystemExit(f"Duplicate giftag time for {genome}")
            timings[genome] = (int(proteins.replace(",", "")),
                               int(markers.replace(",", "")), duration(elapsed))
    if set(timings) != set(giftag) or set(drakkar) != set(giftag):
        raise SystemExit("Per-MAG timing and resource tables do not match")

    OUTPUT.mkdir(parents=True, exist_ok=True)
    rows = []
    for genome in sorted(giftag):
        proteins, markers, elapsed = timings[genome]
        row = giftag[genome]
        if proteins != int(row["proteins"]) or markers != int(row["markers"]):
            raise SystemExit(f"Giftag log and table disagree for {genome}")
        rows.append((
            genome, int(inputs[genome]["bytes"]), int(row["length_bp"]),
            proteins, markers, elapsed,
            int(drakkar[genome]["jobs"]),
            int(drakkar[genome]["completed_jobs"]),
            float(drakkar[genome]["actual_cpu_seconds"]),
        ))
    with (OUTPUT / "r10-giftag-genome-timing.tsv").open(
        "w", newline=""
    ) as handle:
        writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
        writer.writerow((
            "genome_id", "input_bytes_compressed", "length_bp", "giftag_proteins",
            "giftag_markers", "giftag_annotation_seconds", "drakkar_jobs",
            "drakkar_completed_jobs", "drakkar_actual_cpu_seconds",
        ))
        writer.writerows(rows)
    seconds = sorted(row[5] for row in rows)
    per_1000 = sorted(1000 * row[5] / row[3] for row in rows if row[3])
    with (OUTPUT / "r10-giftag-genome-timing-summary.tsv").open(
        "w", newline=""
    ) as handle:
        writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
        writer.writerow(("metric", "value"))
        for metric, value in (
            ("genomes", len(rows)),
            ("median_annotation_seconds", statistics.median(seconds)),
            ("p95_annotation_seconds", seconds[int(0.95 * (len(seconds) - 1))]),
            ("maximum_annotation_seconds", max(seconds)),
            ("median_seconds_per_1000_proteins", statistics.median(per_1000)),
        ):
            writer.writerow((metric, value))
    print(f"Extracted {len(rows)} per-MAG giftag times")


if __name__ == "__main__":
    main()
