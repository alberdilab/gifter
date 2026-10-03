#!/usr/bin/env bash
if ! type module >/dev/null 2>&1; then
  source /etc/profile.d/modules.sh
fi
module use /opt/shared_software/shared_envmodules/modules
export PATH="/home/jpl786/miniforge3/bin:$PATH"
set -euo pipefail

# Drakkar's legacy guard checks only for screen's STY variable. The active
# workflow is launched by the detached screen wrapper; the fallback also keeps
# a non-interactive Slurm driver from receiving an impossible prompt.
export STY="slurm-${SLURM_JOB_ID:-driver}"

scratch_root=/projects/alberdilab/scratch/jpl786
project_root="$scratch_root/projects/gifter-r10-chicken"
acquisition_task="$project_root/tasks/01-mag-acquisition"
annotation_task="$project_root/tasks/02-drakkar-annotation"
mag_dir="$acquisition_task/mags"
output_dir="$annotation_task/output"
drakkar=/projects/alberdilab/data/environments/conda/drakkar/bin/drakkar
env_dir=/projects/alberdilab/data/environments/drakkar

[[ -x "$drakkar" ]] || { printf 'Missing Drakkar executable: %s\n' "$drakkar" >&2; exit 1; }
[[ -s "$acquisition_task/manifests/download.complete" ]] || {
  printf 'MAG download has not completed verification.\n' >&2
  exit 1
}
count=$(find "$mag_dir" -maxdepth 1 -type f -name 'cmag_*.fna.gz' | wc -l)
[[ "$count" -eq 822 ]] || { printf 'Expected 822 MAGs, found %s\n' "$count" >&2; exit 1; }

printf 'started_at_utc\t%s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" > "$annotation_task/logs/drakkar-driver-metadata.tsv"
printf 'command\t%s\n' "$drakkar annotating -b $mag_dir -o $output_dir --annotation-type gifter -e $env_dir -p slurm --snakemake-jobs 100 --snakemake-rerun-incomplete --snakemake-keep-going" >> "$annotation_task/logs/drakkar-driver-metadata.tsv"

exec "$drakkar" annotating \
  -b "$mag_dir" \
  -o "$output_dir" \
  --annotation-type gifter \
  -e "$env_dir" \
  -p slurm \
  --snakemake-jobs 100 \
  --snakemake-rerun-incomplete \
  --snakemake-keep-going
