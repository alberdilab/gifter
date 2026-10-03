#!/usr/bin/env bash
set -euo pipefail

ssh_host=${R10_MFD_SSH_HOST:-mjolnirgate.unicph.domain}
project_root=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-mfd
case_dir=manuscript/analysis/r10-mfd
remote_dir="$case_dir/remote"
acquisition_task="$project_root/tasks/01-input-acquisition"
annotation_task="$project_root/tasks/02-drakkar-annotation"
transfer_task="$project_root/tasks/03-result-transfer"
ssh_options=(-o BatchMode=yes -o LogLevel=ERROR)

required=(
  "$case_dir/source-manifest.tsv" "$case_dir/habitat-design.tsv"
  "$case_dir/archive-aliases.tsv"
  "$case_dir/representative-genomes.tsv" "$case_dir/selected-samples.tsv"
  "$case_dir/design-audit.tsv" "inst/extdata/gifter.sqlite"
  "inst/extdata/database-source/markers.tsv"
)
for path in "${required[@]}"; do
  [[ -s "$path" ]] || { printf 'Missing local workflow input: %s\n' "$path" >&2; exit 1; }
done
[[ $(awk 'END {print NR - 1}' "$case_dir/representative-genomes.tsv") -eq 5518 ]] || {
  printf 'Representative panel is not locked at 5,518 genomes\n' >&2
  exit 1
}
[[ $(awk 'END {print NR - 1}' "$case_dir/selected-samples.tsv") -eq 360 ]] || {
  printf 'Sample panel is not locked at 360 samples\n' >&2
  exit 1
}

if ssh "${ssh_options[@]}" "$ssh_host" "test -e '$project_root'"; then
  printf 'Remote project already exists; refusing to overwrite %s\n' "$project_root" >&2
  exit 1
fi

ssh "${ssh_options[@]}" "$ssh_host" "mkdir -p '$project_root/bootstrap'"
scp "${ssh_options[@]}" "$remote_dir/setup-scratch.sh" \
  "$ssh_host:$project_root/bootstrap/setup-scratch.sh"
ssh "${ssh_options[@]}" "$ssh_host" \
  "chmod 750 '$project_root/bootstrap/setup-scratch.sh' && '$project_root/bootstrap/setup-scratch.sh'"

scp "${ssh_options[@]}" \
  "$case_dir/source-manifest.tsv" "$case_dir/habitat-design.tsv" \
  "$case_dir/archive-aliases.tsv" \
  "$case_dir/representative-genomes.tsv" "$case_dir/selected-samples.tsv" \
  "$case_dir/design-audit.tsv" "inst/extdata/gifter.sqlite" \
  "inst/extdata/database-source/markers.tsv" \
  "$ssh_host:$acquisition_task/manifests/"
scp "${ssh_options[@]}" "$remote_dir/acquire-inputs.sh" \
  "$ssh_host:$acquisition_task/acquire-inputs.sh"
scp "${ssh_options[@]}" "$remote_dir/run-drakkar.sh" \
  "$ssh_host:$annotation_task/run-drakkar.sh"
scp "${ssh_options[@]}" \
  "$remote_dir/workflow-driver.sh" "$remote_dir/launch-workflow.sh" \
  "$remote_dir/prepare-transfer.sh" \
  "$ssh_host:$transfer_task/"
scp "${ssh_options[@]}" "$remote_dir/scratch-AGENTS.md" \
  "$remote_dir/scratch-README.md" "$ssh_host:$project_root/"

ssh "${ssh_options[@]}" "$ssh_host" \
  "chmod 750 '$acquisition_task/acquire-inputs.sh' '$annotation_task/run-drakkar.sh' '$transfer_task/workflow-driver.sh' '$transfer_task/launch-workflow.sh' '$transfer_task/prepare-transfer.sh'; '$transfer_task/launch-workflow.sh'"

printf 'submitted Microflora Danica workflow at %s\n' "$project_root"
