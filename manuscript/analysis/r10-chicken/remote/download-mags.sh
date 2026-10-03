#!/usr/bin/env bash
#SBATCH --job-name=r10-mag-download
#SBATCH --partition=filetransfer
#SBATCH --qos=filetransfer
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=2-00:00:00
#SBATCH --output=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-chicken/tasks/01-mag-acquisition/logs/download-%j.out
#SBATCH --error=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-chicken/tasks/01-mag-acquisition/logs/download-%j.err

set -euo pipefail

project_root=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-chicken
task_root="$project_root/tasks/01-mag-acquisition"
manifest="$task_root/manifests/mag-manifest.tsv"
mag_dir="$task_root/mags"
status_dir="$task_root/manifests"
jobs=${DOWNLOAD_JOBS:-8}

mkdir -p "$mag_dir" "$status_dir"
[[ -s "$manifest" ]] || { printf 'Missing manifest: %s\n' "$manifest" >&2; exit 1; }

download_line() {
  local line=$1
  local genome source_bin ena_analysis assembly url filename
  IFS=$'\t' read -r genome source_bin ena_analysis assembly url filename <<< "$line"
  local dest="$mag_dir/$filename"
  local part="$dest.part.gz"

  if [[ -s "$dest" ]] && gzip -t "$dest" 2>/dev/null; then
    return 0
  fi

  curl --fail --location --silent --show-error \
    --retry 6 --retry-delay 5 --connect-timeout 30 \
    --output "$part" "$url"
  gzip -t "$part"
  mv "$part" "$dest"
}
export -f download_line
export mag_dir

tail -n +2 "$manifest" | xargs -d '\n' -P "$jobs" -n 1 bash -c 'download_line "$1"' _

expected=$(awk 'END {print NR - 1}' "$manifest")
observed=$(find "$mag_dir" -maxdepth 1 -type f -name 'cmag_*.fna.gz' | wc -l)
if [[ "$expected" -ne 822 || "$observed" -ne "$expected" ]]; then
  printf 'Expected 822 MAGs from manifest; found %s of %s\n' "$observed" "$expected" >&2
  exit 1
fi

find "$mag_dir" -maxdepth 1 -type f -name 'cmag_*.fna.gz' -print0 \
  | sort -z \
  | xargs -0 -P "$jobs" -n 1 gzip -t

checksum_tmp="$status_dir/mag-sha256.tsv.tmp"
{
  printf 'sha256\tpath\n'
  find "$mag_dir" -maxdepth 1 -type f -name 'cmag_*.fna.gz' -print0 \
    | sort -z \
    | xargs -0 sha256sum \
    | awk 'BEGIN {OFS="\t"} {print $1, $2}'
} > "$checksum_tmp"
mv "$checksum_tmp" "$status_dir/mag-sha256.tsv"

date -u +'%Y-%m-%dT%H:%M:%SZ' > "$status_dir/download.complete"
printf 'downloaded and verified %s MAGs\n' "$observed"
