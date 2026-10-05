#!/usr/bin/env bash
#SBATCH --job-name=r10-giftag-transfer
#SBATCH --partition=filetransfer
#SBATCH --qos=filetransfer
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=08:00:00
#SBATCH --output=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-chicken/tasks/04-giftag-benchmark/logs/transfer-%j.out
#SBATCH --error=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-chicken/tasks/04-giftag-benchmark/logs/transfer-%j.err

set -euo pipefail

project=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-chicken
task="$project/tasks/04-giftag-benchmark"
run="$task/full"
giftag_db=/projects/alberdilab/scratch/jpl786/projects/giftag-benchmark-2026/data/giftag-db
transfer="$task/transfer"
output="$transfer/output"

[[ -s "$run/complete" ]]
[[ ! -e "$transfer/transfer.complete" ]] || {
  printf 'Refusing to overwrite a completed giftag transfer\n' >&2
  exit 2
}
sha256sum --check "$run/output-sha256.txt"
mkdir -p "$output"

xz -T4 -c "$run/annotation/giftag_markers.tsv" \
  > "$output/giftag_markers.tsv.xz"
xz -t "$output/giftag_markers.tsv.xz"
cp "$run/annotation/giftag_genomes.tsv" "$output/"
cp "$run/annotation/giftag_run.json" "$output/"
cp "$run/summary.tsv" "$output/"
cp "$run/verified-inputs.tsv" "$output/"
cp "$run/measurement/measure.json" "$output/"
cp "$run/measurement/stdout.log" "$output/giftag-stdout.log"
cp "$run/measurement/stderr.log" "$output/giftag-stderr.log"
cp "$run/started" "$run/finished" "$output/"
cp "$giftag_db/giftag.json" "$output/giftag-db.json"
cp "$giftag_db/markers.tsv" "$output/giftag-db-markers.tsv"

full_job=$(awk -F '\t' '$1 == "full_job_id" {print $2}' "$task/jobs.tsv")
[[ -n "$full_job" ]]
sacct -j "$full_job" --parsable2 \
  --format=JobIDRaw,JobName,State,ElapsedRaw,TotalCPU,UserCPU,SystemCPU,MaxRSS,AllocCPUS,ReqMem,NodeList,Start,End \
  > "$output/slurm-accounting.psv"

{
  printf 'file\tbytes\tsha256\n'
  for path in "$output"/*; do
    printf '%s\t%s\t%s\n' \
      "$(basename "$path")" "$(stat -c '%s' "$path")" \
      "$(sha256sum "$path" | cut -d' ' -f1)"
  done
} > "$transfer/transfer-manifest.tsv.tmp"
mv "$transfer/transfer-manifest.tsv.tmp" "$transfer/transfer-manifest.tsv"

genomes=$(awk -F '\t' '$1 == "genomes" {gsub(/\r/, "", $2); print $2}' "$run/summary.tsv")
rows=$(awk -F '\t' '$1 == "marker_rows" {gsub(/\r/, "", $2); print $2}' "$run/summary.tsv")
[[ "$genomes" -eq 822 && "$rows" -gt 0 ]]
{
  printf 'completed_at_utc\t%s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  printf 'genomes\t%s\n' "$genomes"
  printf 'marker_rows\t%s\n' "$rows"
} > "$transfer/transfer.complete"
