#!/usr/bin/env bash
#SBATCH --job-name=r10-mfd-acquire
#SBATCH --partition=filetransfer
#SBATCH --qos=filetransfer
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=2-00:00:00
#SBATCH --output=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-mfd/tasks/01-input-acquisition/logs/acquire-%j.out
#SBATCH --error=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-mfd/tasks/01-input-acquisition/logs/acquire-%j.err

set -euo pipefail

project_root=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-mfd
task_root="$project_root/tasks/01-input-acquisition"
archive_dir="$task_root/archives"
manifest_dir="$task_root/manifests"
mag_dir="$task_root/mags"
public_dir="$task_root/public-data"
source_manifest="$manifest_dir/source-manifest.tsv"
representatives="$manifest_dir/representative-genomes.tsv"
selected_samples="$manifest_dir/selected-samples.tsv"
archive_aliases="$manifest_dir/archive-aliases.tsv"
jobs=${ACQUISITION_JOBS:-1}

mkdir -p "$archive_dir" "$manifest_dir" "$mag_dir" "$public_dir"
for path in "$source_manifest" "$representatives" "$selected_samples" "$archive_aliases"; do
  [[ -s "$path" ]] || { printf 'Missing locked manifest: %s\n' "$path" >&2; exit 1; }
done

verify_file() {
  local path=$1
  local bytes=$2
  local algorithm=$3
  local expected=$4
  local observed_size observed
  observed_size=$(stat -c '%s' "$path")
  [[ "$observed_size" -eq "$bytes" ]] || return 1
  case "$algorithm" in
    md5) observed=$(md5sum "$path" | cut -d' ' -f1) ;;
    sha256) observed=$(sha256sum "$path" | cut -d' ' -f1) ;;
    *) printf 'Unsupported checksum algorithm: %s\n' "$algorithm" >&2; return 1 ;;
  esac
  [[ "$observed" == "$expected" ]]
}

tail -n +2 "$source_manifest" | while IFS=$'\t' read -r file url bytes algorithm checksum role local_prepare; do
  destination="$archive_dir/$file"
  part="$destination.part"
  if ! [[ -s "$destination" ]] || ! verify_file "$destination" "$bytes" "$algorithm" "$checksum"; then
    curl --fail --location --show-error --retry 8 --retry-delay 10 \
      --connect-timeout 60 --continue-at - --output "$part" "$url"
    verify_file "$part" "$bytes" "$algorithm" "$checksum" || {
      printf 'Downloaded source failed verification: %s\n' "$file" >&2
      exit 1
    }
    mv "$part" "$destination"
  fi
done

mag_archive="$archive_dir/MFD.ilm_mag.tar.gz"
support_archive="$archive_dir/Nitrifiers.tar.gz"
[[ -s "$mag_archive" && -s "$support_archive" ]] || {
  printf 'Required archives were not acquired\n' >&2
  exit 1
}

extract_member() {
  local member=$1
  local destination=$2
  local part="$destination.part"
  if [[ ! -s "$destination" ]]; then
    tar -xOf "$support_archive" "$member" > "$part"
    [[ -s "$part" ]] || { printf 'Empty archive member: %s\n' "$member" >&2; exit 1; }
    mv "$part" "$destination"
  fi
}

extract_member ./Nitrifiers/data/mags_shallow_all.tsv "$public_dir/mags_shallow_all.tsv"
extract_member \
  ./Nitrifiers/metadata/2023-10-11_samples_minimal_metadata_collapsed.csv \
  "$public_dir/2023-10-11_samples_minimal_metadata_collapsed.csv"
extract_member \
  ./Nitrifiers/metadata/2025-02-19_mfd_db.xlsx \
  "$public_dir/2025-02-19_mfd_db.xlsx"

abundance="$public_dir/MFD_SRnodrep_tax_relative_abundance.tsv.xz"
if [[ ! -s "$abundance" ]] || ! xz -t "$abundance" 2>/dev/null; then
  abundance_part="$abundance.part"
  tar -xOf "$support_archive" \
    ./Nitrifiers/data/MFD_SRnodrep_tax_relative_abundance.tsv \
    | xz -T "$jobs" -6 > "$abundance_part"
  xz -t "$abundance_part"
  mv "$abundance_part" "$abundance"
fi

[[ $(awk 'END {print NR - 1}' "$public_dir/mags_shallow_all.tsv") -eq 19253 ]] || {
  printf 'MAG quality table does not contain 19,253 rows\n' >&2
  exit 1
}
[[ $(awk 'END {print NR - 1}' "$representatives") -eq 5518 ]] || {
  printf 'Representative manifest does not contain 5,518 rows\n' >&2
  exit 1
}
[[ $(awk 'END {print NR - 1}' "$selected_samples") -eq 360 ]] || {
  printf 'Selected-sample manifest does not contain 360 rows\n' >&2
  exit 1
}

archive_members="$manifest_dir/mag-archive-members.txt"
archive_paths="$manifest_dir/representative-archive-paths.txt"
archive_map="$manifest_dir/representative-archive-map.tsv"
if [[ ! -s "$archive_members" ]]; then
  tar -tzf "$mag_archive" > "$archive_members.part"
  mv "$archive_members.part" "$archive_members"
fi
[[ $(wc -l < "$archive_members") -eq 19254 ]] || {
  printf 'MAG archive index does not contain one directory and 19,253 MAGs\n' >&2
  exit 1
}
[[ $(awk 'END {print NR - 1}' "$archive_aliases") -eq 4 ]] || {
  printf 'Archive-alias crosswalk does not contain four rows\n' >&2
  exit 1
}
awk -F '\t' '
  NR == FNR {
    if (FNR == 1) {
      for (i = 1; i <= NF; i++) {
        if ($i == "expected_archive_basename") expected_col = i
        if ($i == "actual_archive_basename") actual_col = i
      }
      if (!expected_col || !actual_col) exit 2
      next
    }
    expected[++n] = $expected_col
    actual[n] = $actual_col
    next
  }
  {
    base = $0
    sub(/\r$/, "", base)
    sub(/^.*\//, "", base)
    observed[base]++
  }
  END {
    failed = 0
    for (i = 1; i <= n; i++) {
      if (observed[expected[i]] != 0 || observed[actual[i]] != 1) {
        print "Archive-alias evidence no longer holds: " expected[i] " -> " actual[i] > "/dev/stderr"
        failed = 1
      }
    }
    if (failed) exit 3
  }
' "$archive_aliases" "$archive_members"

awk -F '\t' -v paths="$archive_paths.tmp" -v mapping="$archive_map.tmp" '
  NR == FNR {
    if (FNR == 1) {
      for (i = 1; i <= NF; i++) {
        if ($i == "genome_id") genome = i
        if ($i == "archive_basename") archive = i
      }
      if (!genome || !archive) exit 2
      next
    }
    if ($archive in wanted) {
      print "Duplicate requested archive basename: " $archive > "/dev/stderr"
      exit 3
    }
    wanted[$archive] = $genome
    order[++n] = $archive
    next
  }
  {
    path = $0
    sub(/\r$/, "", path)
    base = path
    sub(/^.*\//, "", base)
    if (base in wanted) {
      if (seen[base]++) {
        print "Duplicate archive member for " base > "/dev/stderr"
        exit 4
      }
      print path > paths
      print wanted[base] "\t" path > mapping
    }
  }
  END {
    missing = 0
    for (i = 1; i <= n; i++) if (!(order[i] in seen)) {
      print "Missing representative archive member: " order[i] > "/dev/stderr"
      missing++
    }
    if (missing) exit 5
  }
' "$representatives" "$archive_members"
mv "$archive_paths.tmp" "$archive_paths"
{
  printf 'genome_id\tarchive_member\n'
  sort -t $'\t' -k1,1 "$archive_map.tmp"
} > "$archive_map"
rm "$archive_map.tmp"

[[ $(wc -l < "$archive_paths") -eq 5518 ]] || {
  printf 'Archive mapping did not resolve 5,518 representatives\n' >&2
  exit 1
}

extract_dir="$task_root/representative-extract"
mkdir -p "$extract_dir"
tar -xzf "$mag_archive" -C "$extract_dir" --files-from "$archive_paths"

compress_representative() {
  local line=$1
  local genome member source destination part
  IFS=$'\t' read -r genome member <<< "$line"
  source="$extract_dir/${member#./}"
  destination="$mag_dir/$genome.fna.gz"
  part="$destination.part"
  if [[ -s "$destination" ]] && gzip -t "$destination" 2>/dev/null; then return 0; fi
  [[ -s "$source" ]] || { printf 'Missing extracted representative: %s\n' "$source" >&2; return 1; }
  if [[ "$source" == *.gz ]]; then
    gzip -t "$source"
    cp "$source" "$part"
  else
    gzip -c "$source" > "$part"
  fi
  gzip -t "$part"
  mv "$part" "$destination"
}
export -f compress_representative
export extract_dir mag_dir

tail -n +2 "$archive_map" \
  | xargs -d '\n' -P "$jobs" -n 1 bash -c 'compress_representative "$1"' _

observed=$(find "$mag_dir" -maxdepth 1 -type f -name 'LIB-*.fna.gz' | wc -l)
[[ "$observed" -eq 5518 ]] || {
  printf 'Expected 5,518 representative FASTAs, found %s\n' "$observed" >&2
  exit 1
}
find "$mag_dir" -maxdepth 1 -type f -name 'LIB-*.fna.gz' -print0 \
  | sort -z | xargs -0 -P "$jobs" -n 1 gzip -t

genome_sizes="$manifest_dir/representative-genome-sizes.tsv"
awk -F '\t' 'BEGIN {OFS="\t"}
  NR == 1 {
    for (i = 1; i <= NF; i++) {
      if ($i == "genome_id") genome = i
      if ($i == "genome_size") size = i
    }
    if (!genome || !size) exit 2
    next
  }
  {print $genome, $size}
' "$representatives" > "$genome_sizes"

validate_representative_size() {
  local line=$1
  local genome expected path observed
  IFS=$'\t' read -r genome expected <<< "$line"
  path="$mag_dir/$genome.fna.gz"
  observed=$(gzip -cd "$path" | awk '!/^>/ {gsub(/[[:space:]]/, ""); n += length($0)} END {print n + 0}')
  [[ "$observed" -eq "$expected" ]] || {
    printf 'Genome-size mismatch for %s: expected %s, observed %s\n' \
      "$genome" "$expected" "$observed" >&2
    return 1
  }
}
export -f validate_representative_size
export mag_dir
xargs -d '\n' -P "$jobs" -n 1 bash -c \
  'validate_representative_size "$1"' _ < "$genome_sizes"

checksum_tmp="$manifest_dir/representative-mag-sha256.tsv.tmp"
{
  printf 'sha256\tpath\n'
  find "$mag_dir" -maxdepth 1 -type f -name 'LIB-*.fna.gz' -print0 \
    | sort -z | xargs -0 sha256sum | awk 'BEGIN {OFS="\t"} {print $1, $2}'
} > "$checksum_tmp"
mv "$checksum_tmp" "$manifest_dir/representative-mag-sha256.tsv"

public_checksum_tmp="$manifest_dir/public-data-sha256.tsv.tmp"
{
  printf 'file\tbytes\tsha256\n'
  for path in "$public_dir/MFD_SRnodrep_tax_relative_abundance.tsv.xz" \
              "$public_dir/mags_shallow_all.tsv" \
              "$public_dir/2023-10-11_samples_minimal_metadata_collapsed.csv" \
              "$public_dir/2025-02-19_mfd_db.xlsx"; do
    printf '%s\t%s\t%s\n' "$(basename "$path")" "$(stat -c '%s' "$path")" \
      "$(sha256sum "$path" | cut -d' ' -f1)"
  done
} > "$public_checksum_tmp"
mv "$public_checksum_tmp" "$manifest_dir/public-data-sha256.tsv"

sha256sum "$source_manifest" > "$manifest_dir/source-manifest-sha256.txt"
sha256sum "$archive_aliases" > "$manifest_dir/archive-aliases-sha256.txt"
sha256sum "$representatives" > "$manifest_dir/representative-manifest-sha256.txt"
sha256sum "$selected_samples" > "$manifest_dir/selected-samples-sha256.txt"
date -u +'%Y-%m-%dT%H:%M:%SZ' > "$manifest_dir/acquisition.complete"
printf 'acquired and verified %s species representatives and 360 samples\n' "$observed"
