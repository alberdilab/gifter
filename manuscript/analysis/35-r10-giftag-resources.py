#!/usr/bin/env python3
"""Summarize the measured chicken annotation resources and their scope."""

import csv
import json
from pathlib import Path


ROOT = Path("manuscript/analysis")
CASE = ROOT / "r10-chicken"
GIFTAG = ROOT / ".cache/r10-chicken/giftag"
OUTPUT = ROOT / "output/r10-giftag"


def key_values(path, key="metric", value="value"):
    with path.open(newline="") as handle:
        return {row[key]: row[value] for row in csv.DictReader(handle, delimiter="\t")}


def main():
    measure = json.loads((GIFTAG / "measure.json").read_text())
    run = json.loads((GIFTAG / "giftag_run.json").read_text())
    summary = key_values(GIFTAG / "summary.tsv")
    drakkar = key_values(CASE / "benchmark/drakkar-run-summary.tsv")
    with (CASE / "transfer.complete").open(newline="") as handle:
        drakkar_transfer = dict(csv.reader(handle, delimiter="\t"))
    with (GIFTAG / "verified-inputs.tsv").open(newline="") as handle:
        inputs = list(csv.DictReader(handle, delimiter="\t"))
    with (GIFTAG / "giftag_genomes.tsv").open(newline="") as handle:
        genomes = list(csv.DictReader(handle, delimiter="\t"))
    with (ROOT / ".cache/r10-chicken/drakkar/annotation_qc.tsv").open(
        newline=""
    ) as handle:
        drakkar_proteins = sum(
            int(row["retained_records"])
            for row in csv.DictReader(handle, delimiter="\t")
            if row["level"] == "gene" and row["source"] == "prodigal"
        )
    if len(inputs) != len(genomes) or len(genomes) != 822:
        raise SystemExit("Expected 822 verified input MAGs and giftag genome rows")
    if measure["exit_code"] != 0 or run["genomes"] != 822:
        raise SystemExit("Full giftag annotation did not complete successfully")
    if int(summary["marker_rows"]) != run["rows"]:
        raise SystemExit("Giftag row count differs between summary and run manifest")

    giftag_wall = float(measure["wall_seconds"])
    giftag_cpu = float(measure["user_cpu_seconds"]) + float(
        measure["system_cpu_seconds"]
    )
    drakkar_span = int(drakkar["slurm_workflow_span_seconds"])
    drakkar_cpu = float(drakkar["sum_actual_cpu_seconds"])
    rows = [
        ("genomes", 822, "MAG", "same checksum-verified nucleotide FASTAs"),
        ("input_bytes_compressed", sum(int(row["bytes"]) for row in inputs), "byte",
         "same FASTAs for both annotation workflows"),
        ("input_length_bp", sum(int(row["length_bp"]) for row in genomes), "bp",
         "giftag input nucleotide length"),
        ("giftag_proteins", sum(int(row["proteins"]) for row in genomes), "protein",
         "pyrodigal, auto mode"),
        ("drakkar_proteins", drakkar_proteins, "protein",
         "Drakkar annotation_qc.tsv prodigal rows"),
        ("giftag_marker_rows", int(summary["marker_rows"]), "row",
         "only gifter marker vocabulary"),
        ("drakkar_marker_rows", int(drakkar_transfer["marker_rows"]), "row",
         "Drakkar gifter_input.tsv.xz; includes non-gifter markers"),
        ("giftag_annotation_wall_seconds", giftag_wall, "second",
         "measure.py timed annotate only; 8 requested CPUs"),
        ("giftag_annotation_cpu_seconds", giftag_cpu, "CPU second",
         "child user plus system CPU time"),
        ("giftag_peak_child_rss_bytes", measure["peak_child_rss_bytes"], "byte",
         "largest child process; not whole Slurm job peak"),
        ("drakkar_slurm_workflow_span_seconds", drakkar_span, "second",
         "first to last of 5,784 Slurm submissions; up to 100 concurrent jobs"),
        ("drakkar_actual_cpu_seconds", drakkar_cpu, "CPU second",
         "sum Slurm TotalCPU, including failed attempts"),
        ("drakkar_allocated_core_seconds",
         int(drakkar["sum_allocated_core_seconds"]), "core second",
         "Slurm CPUTimeRAW; some threaded jobs report one allocated CPU"),
        ("annotation_wall_span_ratio_drakkar_to_giftag",
         drakkar_span / giftag_wall, "ratio",
         "practical workflows with different parallelism and source scope"),
        ("actual_cpu_ratio_drakkar_to_giftag", drakkar_cpu / giftag_cpu, "ratio",
         "practical workflows with different source scope"),
        ("giftag_mag_per_hour", 822 * 3600 / giftag_wall, "MAG/hour",
         "annotation stage only"),
        ("giftag_mbp_per_hour",
         sum(int(row["length_bp"]) for row in genomes) * 3600 / giftag_wall / 1e6,
         "Mbp/hour", "annotation stage only"),
    ]
    OUTPUT.mkdir(parents=True, exist_ok=True)
    with (OUTPUT / "r10-giftag-resource-summary.tsv").open(
        "w", newline=""
    ) as handle:
        writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
        writer.writerow(("metric", "value", "unit", "scope"))
        writer.writerows(rows)
    print(f"Measured {giftag_wall / 3600:.2f} h giftag annotation for 822 MAGs")


if __name__ == "__main__":
    main()
