#!/usr/bin/env bash
#SBATCH --job-name=r10-mfd-transfer
#SBATCH --partition=filetransfer
#SBATCH --qos=filetransfer
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=08:00:00
#SBATCH --output=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-mfd/tasks/03-result-transfer/logs/prepare-%j.out
#SBATCH --error=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-mfd/tasks/03-result-transfer/logs/prepare-%j.err

set -euo pipefail

project_root=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-mfd
acquisition_task="$project_root/tasks/01-input-acquisition"
manifest_dir="$acquisition_task/manifests"
public_dir="$acquisition_task/public-data"
annotation_dir="$project_root/tasks/02-drakkar-annotation/output/annotating"
transfer_task="$project_root/tasks/03-result-transfer"
transfer_dir="$transfer_task/output"

full_input="$annotation_dir/gifter_input.tsv.xz"
annotation_manifest="$annotation_dir/annotation_manifest.yaml"
annotation_qc="$annotation_dir/annotation_qc.tsv"
marker_catalogue="$manifest_dir/markers.tsv"
database="$manifest_dir/gifter.sqlite"
representatives="$manifest_dir/representative-genomes.tsv"
selected_samples="$manifest_dir/selected-samples.tsv"

required=(
  "$full_input" "$annotation_manifest" "$annotation_qc" "$marker_catalogue"
  "$database" "$representatives" "$selected_samples"
  "$manifest_dir/source-manifest.tsv" "$manifest_dir/habitat-design.tsv"
  "$manifest_dir/design-audit.tsv" "$manifest_dir/representative-mag-sha256.tsv"
  "$manifest_dir/public-data-sha256.tsv" "$manifest_dir/source-manifest-sha256.txt"
  "$manifest_dir/representative-manifest-sha256.txt"
  "$manifest_dir/selected-samples-sha256.txt"
  "$public_dir/MFD_SRnodrep_tax_relative_abundance.tsv.xz"
  "$public_dir/mags_shallow_all.tsv"
  "$public_dir/2023-10-11_samples_minimal_metadata_collapsed.csv"
  "$public_dir/2025-02-19_mfd_db.xlsx"
)
for path in "${required[@]}"; do
  [[ -s "$path" ]] || { printf 'Missing required transfer input: %s\n' "$path" >&2; exit 1; }
done
xz -t "$full_input"
xz -t "$public_dir/MFD_SRnodrep_tax_relative_abundance.tsv.xz"

read -r full_genomes full_rows < <(
  xzcat "$full_input" | awk -F '\t' '
    NR == 1 {
      sub(/\r$/, "", $4)
      if ($1 != "genome_id" || $2 != "gene_id" ||
          $3 != "namespace" || $4 != "accession") exit 2
      next
    }
    { seen[$1] = 1; rows += 1 }
    END { print length(seen), rows }
  '
)
expected=$(awk 'END {print NR - 1}' "$representatives")
[[ "$expected" -eq 5518 && "$full_genomes" -eq "$expected" ]] || {
  printf 'Expected %s genomes in full Drakkar input, found %s\n' \
    "$expected" "$full_genomes" >&2
  exit 1
}

mkdir -p "$transfer_dir"
filtered="$transfer_dir/gifter_input.catalogue.tsv.xz"
filtered_part="$filtered.part"
xzcat "$full_input" \
  | awk -F '\t' 'BEGIN {OFS="\t"}
      NR == FNR {
        if (FNR > 1) keep[$1 SUBSEP $2] = 1
        next
      }
      FNR == 1 {
        sub(/\r$/, "", $4)
        print $1, $2, $3, $4
        next
      }
      {
        sub(/\r$/, "", $4)
        if (($3 SUBSEP $4) in keep) print $1, $2, $3, $4
      }
    ' "$marker_catalogue" - \
  | xz -T 1 -9 > "$filtered_part"
xz -t "$filtered_part"
mv "$filtered_part" "$filtered"

read -r filtered_genomes filtered_rows < <(
  xzcat "$filtered" | awk -F '\t' '
    NR == 1 { next }
    { seen[$1] = 1; rows += 1 }
    END { print length(seen), rows }
  '
)
[[ "$filtered_genomes" -eq "$expected" && "$filtered_rows" -gt 0 ]] || {
  printf 'Catalogue projection covers %s of %s genomes (%s rows)\n' \
    "$filtered_genomes" "$expected" "$filtered_rows" >&2
  exit 1
}

sha256sum "$full_input" > "$transfer_dir/gifter-input-full-sha256.txt"
sha256sum "$database" > "$transfer_dir/gifter-database-sha256.txt"
sha256sum "$marker_catalogue" > "$transfer_dir/marker-catalogue-sha256.txt"

cp "$annotation_manifest" "$annotation_qc" "$transfer_dir/"
cp "$database" "$marker_catalogue" "$representatives" "$selected_samples" \
   "$manifest_dir/source-manifest.tsv" "$manifest_dir/habitat-design.tsv" \
   "$manifest_dir/design-audit.tsv" "$manifest_dir/representative-mag-sha256.tsv" \
   "$manifest_dir/public-data-sha256.tsv" "$manifest_dir/source-manifest-sha256.txt" \
   "$manifest_dir/representative-manifest-sha256.txt" \
   "$manifest_dir/selected-samples-sha256.txt" "$transfer_dir/"
cp "$public_dir/MFD_SRnodrep_tax_relative_abundance.tsv.xz" \
   "$public_dir/mags_shallow_all.tsv" \
   "$public_dir/2023-10-11_samples_minimal_metadata_collapsed.csv" \
   "$public_dir/2025-02-19_mfd_db.xlsx" "$transfer_dir/"

manifest_tmp="$transfer_task/transfer-manifest.tsv.tmp"
{
  printf 'file\tbytes\tsha256\n'
  find "$transfer_dir" -maxdepth 1 -type f -print0 \
    | sort -z \
    | while IFS= read -r -d '' path; do
        printf '%s\t%s\t%s\n' "$(basename "$path")" "$(stat -c '%s' "$path")" \
          "$(sha256sum "$path" | cut -d' ' -f1)"
      done
} > "$manifest_tmp"
mv "$manifest_tmp" "$transfer_task/transfer-manifest.tsv"

{
  printf 'item\tvalue\n'
  printf 'completed_at_utc\t%s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  printf 'genomes\t%s\n' "$filtered_genomes"
  printf 'full_marker_rows\t%s\n' "$full_rows"
  printf 'catalogue_marker_rows\t%s\n' "$filtered_rows"
  printf 'samples\t360\n'
  printf 'species_clusters\t5518\n'
} > "$transfer_task/transfer.complete"

printf 'prepared %s catalogue marker rows from %s full rows for %s genomes\n' \
  "$filtered_rows" "$full_rows" "$filtered_genomes"
