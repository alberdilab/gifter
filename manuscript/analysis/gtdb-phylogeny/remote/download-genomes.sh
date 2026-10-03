#!/usr/bin/env bash
#SBATCH --job-name=gtdb-gifter-download
#SBATCH --partition=filetransfer
#SBATCH --qos=filetransfer
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=2-00:00:00
#SBATCH --output=/projects/alberdilab/scratch/jpl786/projects/gifter-gtdb-phylogeny/tasks/01-genome-acquisition/logs/download-%j.out
#SBATCH --error=/projects/alberdilab/scratch/jpl786/projects/gifter-gtdb-phylogeny/tasks/01-genome-acquisition/logs/download-%j.err

set -euo pipefail

project_root=/projects/alberdilab/scratch/jpl786/projects/gifter-gtdb-phylogeny
task_root="$project_root/tasks/01-genome-acquisition"
manifest="$task_root/manifests/selected-genomes.tsv"
genome_dir="$task_root/genomes"
status_dir="$task_root/manifests"
jobs=${DOWNLOAD_JOBS:-8}

mkdir -p "$genome_dir" "$status_dir"
[[ -s "$manifest" ]] || { printf 'Missing manifest: %s\n' "$manifest" >&2; exit 1; }

genbank_summary="$status_dir/assembly_summary_genbank_bacteria.txt"
if [[ ! -s "$genbank_summary" ]]; then
  summary_part="$genbank_summary.part"
  curl --fail --location --silent --show-error --retry 6 \
    --output "$summary_part" \
    https://ftp.ncbi.nlm.nih.gov/genomes/genbank/bacteria/assembly_summary.txt
  mv "$summary_part" "$genbank_summary"
fi

resolved_tmp="$status_dir/resolved-downloads.tsv.tmp"
printf 'genome_id\tassembly_accession\tdownload_source\tdownload_url\tremote_filename\n' > "$resolved_tmp"

requested_tmp="$status_dir/requested-downloads.tsv.tmp"
awk -F '\t' 'BEGIN { OFS = "\t" }
  NR == 1 {
    for (i = 1; i <= NF; i++) {
      if ($i == "genome_id") genome = i
      if ($i == "remote_filename") filename = i
    }
    if (!genome || !filename) exit 2
    next
  }
  $genome !~ /^GCA_/ {
    print "Expected a GenBank GCA accession, observed " $genome > "/dev/stderr"
    exit 3
  }
  { print $genome, $filename }
' "$manifest" > "$requested_tmp"

# Join all selected accessions in one pass over NCBI's large assembly summary.
awk -F '\t' 'BEGIN { OFS = "\t" }
  NR == FNR {
    ids[++n] = $1
    filename[$1] = $2
    next
  }
  $1 == "#assembly_accession" {
    for (i = 1; i <= NF; i++) {
      name = $i
      sub(/^#/, "", name)
      if (name == "assembly_accession") accession_column = i
      if (name == "ftp_path") ftp_column = i
    }
    next
  }
  $1 ~ /^#/ { next }
  accession_column && ftp_column &&
      ($accession_column in filename) && $ftp_column != "na" {
    path = $ftp_column
    sub(/\/$/, "", path)
    ftp[$accession_column] = path
    count = split(path, part, "/")
    base[$accession_column] = part[count]
  }
  END {
    if (!accession_column || !ftp_column) {
      print "Could not resolve named columns in the NCBI assembly summary" > "/dev/stderr"
      exit 4
    }
    for (i = 1; i <= n; i++) {
      id = ids[i]
      if (!(id in ftp)) {
        print id, id, "ENA Browser API assembly FASTA", \
          "https://www.ebi.ac.uk/ena/browser/api/fasta/" id "?download=true&gzip=true", \
          filename[id]
      } else {
        print id, id, "NCBI GenBank assembly summary", \
          ftp[id] "/" base[id] "_genomic.fna.gz", filename[id]
      }
    }
  }
' "$requested_tmp" "$genbank_summary" >> "$resolved_tmp"
rm "$requested_tmp"

expected=$(awk 'END {print NR - 1}' "$manifest")
resolved=$(awk 'END {print NR - 1}' "$resolved_tmp")
[[ "$expected" -gt 0 && "$resolved" -eq "$expected" ]] || {
  printf 'Manifest and resolved genome counts differ: %s and %s\n' "$expected" "$resolved" >&2
  exit 1
}
mv "$resolved_tmp" "$status_dir/resolved-downloads.tsv"

download_line() {
  local line=$1
  local genome_id assembly_accession download_source url filename
  IFS=$'\t' read -r genome_id assembly_accession download_source url filename <<< "$line"
  local dest="$genome_dir/$filename"
  local part="$dest.part"
  if [[ -s "$dest" ]] && gzip -t "$dest" 2>/dev/null; then return 0; fi
  curl --fail --location --silent --show-error \
    --retry 6 --retry-delay 5 --connect-timeout 30 \
    --output "$part" "$url"
  gzip -t "$part"
  mv "$part" "$dest"
}
export -f download_line
export genome_dir

tail -n +2 "$status_dir/resolved-downloads.tsv" \
  | xargs -d '\n' -P "$jobs" -n 1 bash -c 'download_line "$1"' _

observed=$(find "$genome_dir" -maxdepth 1 -type f -name 'GC[AF]_*.fna.gz' | wc -l)
[[ "$observed" -eq "$expected" ]] || {
  printf 'Expected %s genomes, found %s\n' "$expected" "$observed" >&2
  exit 1
}

find "$genome_dir" -maxdepth 1 -type f -name 'GC[AF]_*.fna.gz' -print0 \
  | sort -z | xargs -0 -P "$jobs" -n 1 gzip -t

checksum_tmp="$status_dir/genome-sha256.tsv.tmp"
{
  printf 'sha256\tpath\n'
  find "$genome_dir" -maxdepth 1 -type f -name 'GC[AF]_*.fna.gz' -print0 \
    | sort -z | xargs -0 sha256sum | awk 'BEGIN {OFS="\t"} {print $1, $2}'
} > "$checksum_tmp"
mv "$checksum_tmp" "$status_dir/genome-sha256.tsv"
sha256sum "$genbank_summary" > "$status_dir/assembly-summary-sha256.txt"
sha256sum "$manifest" > "$status_dir/selected-manifest-sha256.txt"

date -u +'%Y-%m-%dT%H:%M:%SZ' > "$status_dir/download.complete"
ena_fallbacks=$(awk -F '\t' '$3 == "ENA Browser API assembly FASTA" {n++} END {print n + 0}' \
  "$status_dir/resolved-downloads.tsv")
printf 'downloaded and verified %s genomes (%s ENA fallbacks)\n' \
  "$observed" "$ena_fallbacks"
