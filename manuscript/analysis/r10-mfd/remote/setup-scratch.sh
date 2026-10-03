#!/usr/bin/env bash
set -euo pipefail

scratch_root=/projects/alberdilab/scratch/jpl786
project_root="$scratch_root/projects/gifter-r10-mfd"
drakkar_env=/projects/alberdilab/data/environments/conda/drakkar

mkdir -p \
  "$project_root/tasks/01-input-acquisition/archives" \
  "$project_root/tasks/01-input-acquisition/manifests" \
  "$project_root/tasks/01-input-acquisition/mags" \
  "$project_root/tasks/01-input-acquisition/public-data" \
  "$project_root/tasks/01-input-acquisition/logs" \
  "$project_root/tasks/02-drakkar-annotation/output" \
  "$project_root/tasks/02-drakkar-annotation/logs" \
  "$project_root/tasks/03-result-transfer/output" \
  "$project_root/tasks/03-result-transfer/logs"

[[ -x "$drakkar_env/bin/drakkar" ]] || {
  printf 'Missing existing Drakkar executable: %s\n' "$drakkar_env/bin/drakkar" >&2
  exit 1
}
version=$("$drakkar_env/bin/drakkar" --version)
[[ "$version" == *'drakkar 2.6.6'* ]] || {
  printf 'Expected existing drakkar 2.6.6, observed: %s\n' "$version" >&2
  exit 1
}

printf '%s\n' "$project_root" > "$project_root/PROJECT_ROOT"
printf 'scratch setup complete: %s\n' "$project_root"
