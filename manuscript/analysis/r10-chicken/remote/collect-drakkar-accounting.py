#!/usr/bin/env python3
"""Collect Slurm resources for exactly the jobs in the completed R10 Drakkar log."""

import csv
import re
import subprocess
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path


FIELDS = (
    "JobIDRaw", "JobName", "State", "ElapsedRaw", "CPUTimeRAW", "TotalCPU",
    "MaxRSS", "AllocCPUS", "ReqMem", "Start", "End", "NodeList",
)


def seconds(value):
    if not value:
        return 0.0
    days = 0
    if "-" in value:
        prefix, value = value.split("-", 1)
        days = int(prefix)
    parts = value.split(":")
    return days * 86400 + sum(
        float(part) * 60 ** power
        for power, part in enumerate(reversed(parts))
    )


def rss_bytes(value):
    match = re.fullmatch(r"([0-9.]+)([KMGTP]?)", value or "")
    if not match:
        return 0
    units = {"": 1, "K": 1024, "M": 1024 ** 2, "G": 1024 ** 3,
             "T": 1024 ** 4, "P": 1024 ** 5}
    return int(float(match.group(1)) * units[match.group(2)])


def main():
    log = Path(sys.argv[1])
    output = Path(sys.argv[2])
    output.mkdir(parents=True, exist_ok=True)
    matches = re.findall(
        r"SLURM jobid (\d+) \(log: ([^)]+)\)", log.read_text(errors="replace")
    )
    jobs = {}
    for job_id, path in matches:
        rule = re.search(r"/slurm_logs/rule_([^/]+)/", path)
        genome = re.search(r"/(cmag_\d{3})/", path)
        jobs[job_id] = (
            rule.group(1) if rule else "unknown",
            genome.group(1) if genome else "",
        )
    if len(jobs) < 5700:
        raise SystemExit(f"Expected the completed 5,758-step run; found {len(jobs)} job IDs")

    records = {}
    steps = defaultdict(list)
    ids = list(jobs)
    for start in range(0, len(ids), 400):
        result = subprocess.run(
            ["sacct", "--noheader", "--parsable2", "-j", ",".join(ids[start:start + 400]),
             "--format=" + ",".join(FIELDS)],
            check=True, text=True, capture_output=True,
        )
        for line in result.stdout.splitlines():
            values = line.split("|")
            if len(values) != len(FIELDS):
                raise SystemExit(f"Unexpected sacct row: {line}")
            row = dict(zip(FIELDS, values))
            root = row["JobIDRaw"].split(".", 1)[0]
            if root not in jobs:
                continue
            if row["JobIDRaw"] == root:
                records[root] = row
            else:
                steps[root].append(row)
    missing = set(jobs) - set(records)
    if missing:
        raise SystemExit(f"sacct did not return {len(missing)} Drakkar jobs")

    columns = ("job_id", "rule", "genome_id", *FIELDS[1:],
               "peak_step_rss_bytes")
    with (output / "drakkar-job-accounting.tsv").open("w", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
        writer.writerow(columns)
        for job_id in sorted(jobs, key=int):
            row = records[job_id]
            peak = max((rss_bytes(step["MaxRSS"]) for step in steps[job_id]),
                       default=0)
            writer.writerow((job_id, *jobs[job_id],
                             *(row[field] for field in FIELDS[1:]), peak))

    by_rule = defaultdict(list)
    by_genome = defaultdict(list)
    for job_id, (rule, genome) in jobs.items():
        by_rule[rule].append(records[job_id])
        if genome:
            by_genome[genome].append(records[job_id])
    with (output / "drakkar-rule-resources.tsv").open("w", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
        writer.writerow(("rule", "jobs", "completed_jobs", "elapsed_job_seconds",
                         "allocated_core_seconds", "actual_cpu_seconds"))
        for rule, rows in sorted(by_rule.items()):
            writer.writerow((
                rule, len(rows), sum(row["State"].startswith("COMPLETED") for row in rows),
                round(sum(float(row["ElapsedRaw"] or 0) for row in rows), 3),
                round(sum(float(row["CPUTimeRAW"] or 0) for row in rows), 3),
                round(sum(seconds(row["TotalCPU"]) for row in rows), 3),
            ))
        all_rows = list(records.values())
        writer.writerow((
            "ALL", len(all_rows),
            sum(row["State"].startswith("COMPLETED") for row in all_rows),
            round(sum(float(row["ElapsedRaw"] or 0) for row in all_rows), 3),
            round(sum(float(row["CPUTimeRAW"] or 0) for row in all_rows), 3),
            round(sum(seconds(row["TotalCPU"]) for row in all_rows), 3),
        ))
    if len(by_genome) != 822:
        raise SystemExit(f"Expected 822 MAGs in Slurm job paths, found {len(by_genome)}")
    with (output / "drakkar-genome-resources.tsv").open("w", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
        writer.writerow(("genome_id", "jobs", "completed_jobs",
                         "elapsed_job_seconds", "allocated_core_seconds",
                         "actual_cpu_seconds"))
        for genome, rows in sorted(by_genome.items()):
            writer.writerow((
                genome, len(rows),
                sum(row["State"].startswith("COMPLETED") for row in rows),
                round(sum(float(row["ElapsedRaw"] or 0) for row in rows), 3),
                round(sum(float(row["CPUTimeRAW"] or 0) for row in rows), 3),
                round(sum(seconds(row["TotalCPU"]) for row in rows), 3),
            ))
    starts = [row["Start"] for row in records.values()
              if row["Start"].startswith("2026-")]
    ends = [row["End"] for row in records.values()
            if row["End"].startswith("2026-")]
    first, last = min(starts), max(ends)
    span = (datetime.fromisoformat(last) -
            datetime.fromisoformat(first)).total_seconds()
    with (output / "drakkar-run-summary.tsv").open("w", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t", lineterminator="\n")
        writer.writerow(("metric", "value"))
        for metric, value in (
            ("slurm_jobs", len(records)),
            ("completed_jobs", sum(row["State"].startswith("COMPLETED")
                                   for row in records.values())),
            ("failed_or_cancelled_jobs", sum(not row["State"].startswith("COMPLETED")
                                             for row in records.values())),
            ("first_slurm_start", first),
            ("last_slurm_end", last),
            ("slurm_workflow_span_seconds", int(span)),
            ("sum_elapsed_job_seconds", int(sum(float(row["ElapsedRaw"] or 0)
                                                for row in records.values()))),
            ("sum_allocated_core_seconds", int(sum(float(row["CPUTimeRAW"] or 0)
                                                  for row in records.values()))),
            ("sum_actual_cpu_seconds", round(sum(seconds(row["TotalCPU"])
                                                 for row in records.values()), 3)),
        ):
            writer.writerow((metric, value))
    print(f"Collected accounting for {len(jobs)} Drakkar jobs")


if __name__ == "__main__":
    main()
