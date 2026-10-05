#!/usr/bin/env bash
#SBATCH --job-name=r10-giftag
#SBATCH --partition=cpuqueue
#SBATCH --qos=normal
#SBATCH --cpus-per-task=8
#SBATCH --mem=20G
#SBATCH --time=2-00:00:00
#SBATCH --output=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-chicken/tasks/04-giftag-benchmark/logs/giftag-%j.out
#SBATCH --error=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-chicken/tasks/04-giftag-benchmark/logs/giftag-%j.err

set -euo pipefail

project=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-chicken
acquisition="$project/tasks/01-mag-acquisition"
task="$project/tasks/04-giftag-benchmark"
giftag_project=/projects/alberdilab/scratch/jpl786/projects/giftag-benchmark-2026
python="$giftag_project/environments/giftag/bin/python"
db="$giftag_project/data/giftag-db"
mode=${BENCH_MODE:-full}

case "$mode" in
  pilot) input="$acquisition/mags/cmag_001.fna.gz" ;;
  full) input="$acquisition/mags" ;;
  *) printf 'BENCH_MODE must be pilot or full\n' >&2; exit 2 ;;
esac

run="$task/$mode"
mkdir -p "$run" "$task/logs"
[[ ! -e "$run/complete" && ! -e "$run/started" ]] || {
  printf 'Refusing to overwrite an existing run: %s\n' "$run" >&2
  exit 2
}
[[ -s "$acquisition/manifests/download.complete" ]]
[[ -x "$python" && -s "$db/giftag.json" ]]
printf '%s  %s\n' \
  552fc134bb989ed37e0223ce05a17e0632a217416a197fbd6e36ce1d536667b9 \
  "$giftag_project/data/gifter-markers.tsv" | sha256sum --check

# Check the exact input FASTAs before starting the timed annotation. The
# checksum ledger was written by the completed Drakkar acquisition task.
"$python" - "$acquisition/manifests/mag-manifest.tsv" \
  "$acquisition/manifests/mag-sha256.tsv" "$acquisition/mags" "$mode" \
  "$run/verified-inputs.tsv" <<'PY'
import csv
import hashlib
import sys
from pathlib import Path

catalogue, checksums, mag_dir, mode, output = sys.argv[1:]
with open(catalogue, newline="") as handle:
    expected = {row["genome_id"] for row in csv.DictReader(handle, delimiter="\t")}
if len(expected) != 822:
    raise SystemExit(f"Expected 822 catalogue MAGs, found {len(expected)}")
with open(checksums, newline="") as handle:
    ledger = list(csv.DictReader(handle, delimiter="\t"))
if {Path(row["path"]).name[:-7] for row in ledger} != expected:
    raise SystemExit("MAG checksum ledger differs from catalogue")
if {p.name[:-7] for p in Path(mag_dir).glob("cmag_*.fna.gz")} != expected:
    raise SystemExit("FASTA directory differs from catalogue")
if mode == "pilot":
    ledger = [row for row in ledger if Path(row["path"]).name == "cmag_001.fna.gz"]
with open(output, "w", newline="") as handle:
    writer = csv.writer(handle, delimiter="\t")
    writer.writerow(("genome_id", "bytes", "sha256", "path"))
    for row in ledger:
        path = Path(row["path"])
        digest = hashlib.sha256()
        with path.open("rb") as stream:
            for block in iter(lambda: stream.read(1024 * 1024), b""):
                digest.update(block)
        if digest.hexdigest() != row["sha256"]:
            raise SystemExit(f"Checksum mismatch: {path}")
        writer.writerow((path.name[:-7], path.stat().st_size, row["sha256"], path))
print(f"Verified {len(ledger)} input MAGs")
PY

{
  printf 'mode\t%s\n' "$mode"
  printf 'job_id\t%s\n' "${SLURM_JOB_ID:-}"
  printf 'allocated_cpus\t%s\n' "${SLURM_CPUS_PER_TASK:-}"
  printf 'giftag_version\t%s\n' "$("$python" -m giftag version)"
  printf 'giftag_source_commit\t%s\n' "$(cat "$giftag_project/provenance/giftag-git-head.txt")"
  printf 'database_sha256\t%s\n' "$(sha256sum "$db/giftag.json" | cut -d' ' -f1)"
  printf 'markers_sha256\t%s\n' "$(sha256sum "$db/markers.tsv" | cut -d' ' -f1)"
  printf 'started_at_utc\t%s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  printf 'command\t%s\n' "$python -m giftag annotate -i $input -o $run/annotation --db $db --input-type nucleotide --mode auto --threads 8"
} > "$run/started"

set +e
"$python" "$giftag_project/source/benchmarks/measure.py" \
  --outdir "$run/measurement" --tool giftag --scope subset \
  --threads 8 --version "$("$python" -m giftag version)" \
  --database "$db/giftag.json" -- \
  "$python" -m giftag annotate \
    -i "$input" -o "$run/annotation" --db "$db" \
    --input-type nucleotide --mode auto --threads 8 \
    > "$run/stdout.log" 2> "$run/stderr.log"
status=$?
set -e
printf 'exit_code\t%s\nfinished_at_utc\t%s\n' \
  "$status" "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" > "$run/finished"
[[ "$status" -eq 0 ]] || exit "$status"

"$python" - "$run/verified-inputs.tsv" "$run/annotation" "$run/summary.tsv" <<'PY'
import csv
import json
import sys
from collections import Counter
from pathlib import Path

ledger, annotation, summary_path = sys.argv[1:]
with open(ledger, newline="") as handle:
    expected = {row["genome_id"] for row in csv.DictReader(handle, delimiter="\t")}
with open(Path(annotation) / "giftag_genomes.tsv", newline="") as handle:
    genomes = list(csv.DictReader(handle, delimiter="\t"))
if len(genomes) != len(expected) or {row["genome_id"] for row in genomes} != expected:
    raise SystemExit("giftag genome output differs from verified MAG panel")
run = json.loads((Path(annotation) / "giftag_run.json").read_text())
if run["genomes"] != len(expected):
    raise SystemExit("giftag run manifest has an unexpected genome count")
counts = Counter()
rows = 0
with open(Path(annotation) / "giftag_markers.tsv", newline="") as handle:
    reader = csv.DictReader(handle, delimiter="\t")
    if not {"genome_id", "gene_id", "namespace", "accession"}.issubset(reader.fieldnames):
        raise SystemExit("giftag marker table lacks gifter input columns")
    for row in reader:
        if row["genome_id"] not in expected or not row["gene_id"] or not row["accession"]:
            raise SystemExit("Invalid giftag marker row")
        counts[row["namespace"]] += 1
        rows += 1
if rows != run["rows"]:
    raise SystemExit("giftag marker rows differ from run manifest")
with open(summary_path, "w", newline="") as handle:
    writer = csv.writer(handle, delimiter="\t")
    writer.writerow(("metric", "value"))
    writer.writerow(("genomes", len(expected)))
    writer.writerow(("proteins", sum(int(row["proteins"]) for row in genomes)))
    writer.writerow(("marker_rows", rows))
    for namespace, count in sorted(counts.items()):
        writer.writerow((f"rows_{namespace}", count))
PY

sha256sum "$run/annotation/giftag_run.json" \
  "$run/annotation/giftag_genomes.tsv" \
  "$run/annotation/giftag_markers.tsv" \
  "$run/measurement/measure.json" \
  "$run/summary.tsv" > "$run/output-sha256.txt"
date -u +'%Y-%m-%dT%H:%M:%SZ' > "$run/complete"
