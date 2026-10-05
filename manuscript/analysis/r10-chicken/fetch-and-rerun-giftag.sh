#!/usr/bin/env bash
set -euo pipefail

ssh_host=${R10_SSH_HOST:-mjolnirgate.unicph.domain}
task=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-chicken/tasks/04-giftag-benchmark
remote="$task/transfer"
local_dir=manuscript/analysis/.cache/r10-chicken/giftag
ssh_options=(-o BatchMode=yes -o LogLevel=ERROR)

ssh "${ssh_options[@]}" "$ssh_host" "test -s '$remote/transfer.complete'" || {
  printf 'The full giftag transfer is not complete on Mjolnir.\n' >&2
  exit 1
}
mkdir -p "$local_dir"
scp "${ssh_options[@]}" "$ssh_host:$remote/transfer-manifest.tsv" "$local_dir/"
scp "${ssh_options[@]}" "$ssh_host:$remote/transfer.complete" "$local_dir/"

while IFS=$'\t' read -r file bytes checksum; do
  [[ "$file" == file ]] && continue
  [[ "$file" =~ ^[A-Za-z0-9._-]+$ && -n "$checksum" ]] || {
    printf 'Invalid transfer manifest row: %s\n' "$file" >&2
    exit 1
  }
  scp "${ssh_options[@]}" "$ssh_host:$remote/output/$file" "$local_dir/"
  observed_bytes=$(stat -f '%z' "$local_dir/$file")
  observed_sha=$(shasum -a 256 "$local_dir/$file" | cut -d' ' -f1)
  [[ "$observed_bytes" == "$bytes" && "$observed_sha" == "$checksum" ]] || {
    printf 'Transfer checksum or size mismatch: %s\n' "$file" >&2
    exit 1
  }
done < "$local_dir/transfer-manifest.tsv"

R10_ANNOTATOR=giftag \
R10_OUTPUT_DIR=manuscript/analysis/output/r10-giftag \
R10_FIGURE_DIR=manuscript/figures/r10-giftag \
Rscript manuscript/analysis/21-r10-chicken.R
