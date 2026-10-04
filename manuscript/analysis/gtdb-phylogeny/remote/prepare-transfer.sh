#!/usr/bin/env bash
#SBATCH --job-name=gtdb-gifter-transfer
#SBATCH --partition=filetransfer
#SBATCH --qos=filetransfer
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=04:00:00
#SBATCH --output=/projects/alberdilab/scratch/jpl786/projects/gifter-gtdb-phylogeny/tasks/03-result-transfer/logs/prepare-%j.out
#SBATCH --error=/projects/alberdilab/scratch/jpl786/projects/gifter-gtdb-phylogeny/tasks/03-result-transfer/logs/prepare-%j.err

set -euo pipefail

project_root=/projects/alberdilab/scratch/jpl786/projects/gifter-gtdb-phylogeny
acquisition_dir="$project_root/tasks/01-genome-acquisition/manifests"
annotation_dir="$project_root/tasks/02-drakkar-annotation/output/annotating"
transfer_task="$project_root/tasks/03-result-transfer"
transfer_dir="$transfer_task/output"

gifter_input="$annotation_dir/gifter_input.tsv.xz"
annotation_manifest="$annotation_dir/annotation_manifest.yaml"
annotation_qc="$annotation_dir/annotation_qc.tsv"

for path in "$gifter_input" "$annotation_manifest" "$annotation_qc" \
            "$acquisition_dir/selected-genomes.tsv" \
            "$acquisition_dir/resolved-downloads.tsv" \
            "$acquisition_dir/genome-sha256.tsv" \
            "$acquisition_dir/assembly-summary-sha256.txt" \
            "$acquisition_dir/selected-manifest-sha256.txt"; do
  [[ -s "$path" ]] || { printf 'Missing Drakkar output: %s\n' "$path" >&2; exit 1; }
done
xz -t "$gifter_input"

read -r genomes rows < <(
  xzcat "$gifter_input" | awk -F '\t' '
    NR == 1 {
      sub(/\r$/, "", $4)
      if ($1 != "genome_id" || $2 != "gene_id" || $3 != "namespace" || $4 != "accession") exit 2
      next
    }
    { seen[$1] = 1; rows += 1 }
    END { print length(seen), rows }
  '
)
expected=$(awk 'END {print NR - 1}' "$acquisition_dir/selected-genomes.tsv")
# Genomes dropped after selection are recorded in excluded-genomes.tsv.
excluded_genomes="$acquisition_dir/excluded-genomes.tsv"
if [[ -s "$excluded_genomes" ]]; then
  expected=$(( expected - $(awk 'END {print NR - 1}' "$excluded_genomes") ))
fi
[[ "$expected" -gt 0 && "$genomes" -eq "$expected" ]] || {
  printf 'Expected %s genomes, found %s\n' "$expected" "$genomes" >&2
  exit 1
}

mkdir -p "$transfer_dir"
if [[ -s "$excluded_genomes" ]]; then cp "$excluded_genomes" "$transfer_dir/"; fi
cp "$gifter_input" "$annotation_manifest" "$annotation_qc" "$transfer_dir/"
cp "$acquisition_dir/selected-genomes.tsv" \
   "$acquisition_dir/resolved-downloads.tsv" \
   "$acquisition_dir/genome-sha256.tsv" \
   "$acquisition_dir/assembly-summary-sha256.txt" \
   "$acquisition_dir/selected-manifest-sha256.txt" \
   "$transfer_dir/"

manifest_tmp="$transfer_task/transfer-manifest.tsv.tmp"
{
  printf 'file\tbytes\tsha256\n'
  for path in "$transfer_dir/gifter_input.tsv.xz" \
              "$transfer_dir/annotation_manifest.yaml" \
              "$transfer_dir/annotation_qc.tsv" \
              "$transfer_dir/selected-genomes.tsv" \
              "$transfer_dir/resolved-downloads.tsv" \
              "$transfer_dir/genome-sha256.tsv" \
              "$transfer_dir/assembly-summary-sha256.txt" \
              "$transfer_dir/selected-manifest-sha256.txt" \
              "$transfer_dir/excluded-genomes.tsv"; do
    [[ -e "$path" ]] || continue
    checksum=$(sha256sum "$path" | cut -d' ' -f1)
    printf '%s\t%s\t%s\n' "$(basename "$path")" "$(stat -c '%s' "$path")" "$checksum"
  done
} > "$manifest_tmp"
mv "$manifest_tmp" "$transfer_task/transfer-manifest.tsv"

{
  printf 'item\tvalue\n'
  printf 'completed_at_utc\t%s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  printf 'genomes\t%s\n' "$genomes"
  printf 'marker_rows\t%s\n' "$rows"
} > "$transfer_task/transfer.complete"

printf 'prepared %s marker rows for %s genomes\n' "$rows" "$genomes"
