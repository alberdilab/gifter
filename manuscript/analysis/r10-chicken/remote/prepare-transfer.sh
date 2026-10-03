#!/usr/bin/env bash
#SBATCH --job-name=r10-prepare-transfer
#SBATCH --partition=filetransfer
#SBATCH --qos=filetransfer
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=04:00:00
#SBATCH --output=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-chicken/tasks/03-result-transfer/logs/prepare-%j.out
#SBATCH --error=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-chicken/tasks/03-result-transfer/logs/prepare-%j.err

set -euo pipefail

project_root=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-chicken
annotation_dir="$project_root/tasks/02-drakkar-annotation/output/annotating"
transfer_task="$project_root/tasks/03-result-transfer"
transfer_dir="$transfer_task/output"

gifter_input="$annotation_dir/gifter_input.tsv.xz"
annotation_manifest="$annotation_dir/annotation_manifest.yaml"
annotation_qc="$annotation_dir/annotation_qc.tsv"

for path in "$gifter_input" "$annotation_manifest" "$annotation_qc"; do
  [[ -s "$path" ]] || { printf 'Missing Drakkar output: %s\n' "$path" >&2; exit 1; }
done
xz -t "$gifter_input"

read -r genomes rows < <(
  xzcat "$gifter_input" \
    | awk -F '\t' '
        NR == 1 {
          sub(/\r$/, "", $4)
          if ($1 != "genome_id" || $2 != "gene_id" || $3 != "namespace" || $4 != "accession") exit 2
          next
        }
        { seen[$1] = 1; rows += 1 }
        END { print length(seen), rows }
      '
)
[[ "$genomes" -eq 822 ]] || {
  printf 'Expected 822 genomes in gifter_input.tsv.xz, found %s\n' "$genomes" >&2
  exit 1
}

mkdir -p "$transfer_dir"
cp "$gifter_input" "$annotation_manifest" "$annotation_qc" "$transfer_dir/"

manifest_tmp="$transfer_task/transfer-manifest.tsv.tmp"
{
  printf 'file\tbytes\tsha256\n'
  for path in "$transfer_dir/gifter_input.tsv.xz" \
              "$transfer_dir/annotation_manifest.yaml" \
              "$transfer_dir/annotation_qc.tsv"; do
    checksum=$(sha256sum "$path" | cut -d' ' -f1)
    printf '%s\t%s\t%s\n' "$(basename "$path")" "$(stat -c '%s' "$path")" "$checksum"
  done
} > "$manifest_tmp"
mv "$manifest_tmp" "$transfer_task/transfer-manifest.tsv"

{
  printf 'completed_at_utc\t%s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  printf 'genomes\t%s\n' "$genomes"
  printf 'marker_rows\t%s\n' "$rows"
} > "$transfer_task/transfer.complete"

printf 'prepared %s marker rows for %s genomes\n' "$rows" "$genomes"
