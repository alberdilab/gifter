#!/usr/bin/env bash
if ! type module >/dev/null 2>&1; then source /etc/profile.d/modules.sh; fi
module use /opt/shared_software/shared_envmodules/modules
export PATH="/home/jpl786/miniforge3/bin:$PATH"
set -euo pipefail

export STY="${STY:-r10-mfd-driver}"

project_root=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-mfd
acquisition_task="$project_root/tasks/01-input-acquisition"
annotation_task="$project_root/tasks/02-drakkar-annotation"
mag_dir="$acquisition_task/mags"
manifest="$acquisition_task/manifests/representative-genomes.tsv"
output_dir="$annotation_task/output"
drakkar=/projects/alberdilab/data/environments/conda/drakkar/bin/drakkar
env_dir=/projects/alberdilab/data/environments/drakkar

[[ -x "$drakkar" ]] || { printf 'Missing Drakkar executable: %s\n' "$drakkar" >&2; exit 1; }
[[ -s "$acquisition_task/manifests/acquisition.complete" ]] || {
  printf 'Input acquisition has not completed verification.\n' >&2
  exit 1
}
expected=$(awk 'END {print NR - 1}' "$manifest")
count=$(find "$mag_dir" -maxdepth 1 -type f -name 'LIB-*.fna.gz' | wc -l)
[[ "$expected" -eq 5518 && "$count" -eq "$expected" ]] || {
  printf 'Expected %s representative genomes, found %s\n' "$expected" "$count" >&2
  exit 1
}

printf 'started_at_utc\t%s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
  > "$annotation_task/logs/drakkar-driver-metadata.tsv"
printf 'command\t%s\n' \
  "$drakkar annotating -b $mag_dir -o $output_dir --annotation-type gifter -e $env_dir -p slurm --snakemake-jobs 100 --snakemake-rerun-incomplete --snakemake-keep-going" \
  >> "$annotation_task/logs/drakkar-driver-metadata.tsv"

exec "$drakkar" annotating \
  -b "$mag_dir" \
  -o "$output_dir" \
  --annotation-type gifter \
  -e "$env_dir" \
  -p slurm \
  --snakemake-jobs 100 \
  --snakemake-rerun-incomplete \
  --snakemake-keep-going
