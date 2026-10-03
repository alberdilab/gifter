#!/usr/bin/env bash
set -euo pipefail

scratch_root=/projects/alberdilab/scratch/jpl786
project_root="$scratch_root/projects/gifter-r10-chicken"
drakkar_env=/projects/alberdilab/data/environments/conda/drakkar

mkdir -p \
  "$scratch_root/projects" \
  "$scratch_root/tasks" \
  "$scratch_root/software" \
  "$scratch_root/environments" \
  "$scratch_root/cache" \
  "$scratch_root/logs" \
  "$scratch_root/tmp" \
  "$project_root/tasks/01-mag-acquisition/manifests" \
  "$project_root/tasks/01-mag-acquisition/mags" \
  "$project_root/tasks/01-mag-acquisition/logs" \
  "$project_root/tasks/02-drakkar-annotation/output" \
  "$project_root/tasks/02-drakkar-annotation/logs" \
  "$project_root/tasks/03-result-transfer/output" \
  "$project_root/tasks/03-result-transfer/logs"

if [[ -e "$HOME/scratch" || -L "$HOME/scratch" ]]; then
  resolved=$(readlink -f "$HOME/scratch")
  canonical_root=$(readlink -f "$scratch_root")
  if [[ "$resolved" != "$canonical_root" ]]; then
    printf 'Refusing to replace existing %s (resolves to %s)\n' "$HOME/scratch" "$resolved" >&2
    exit 1
  fi
else
  ln -s "$scratch_root" "$HOME/scratch"
fi

if [[ ! -x "$drakkar_env/bin/drakkar" ]]; then
  printf 'Missing existing Drakkar executable: %s\n' "$drakkar_env/bin/drakkar" >&2
  printf 'This setup script deliberately does not install or update Drakkar.\n' >&2
  exit 1
fi
version=$("$drakkar_env/bin/drakkar" --version)
[[ "$version" == *'drakkar 2.6.6'* ]] || {
  printf 'Expected existing drakkar 2.6.6, observed: %s\n' "$version" >&2
  exit 1
}

printf '%s\n' "$project_root" > "$project_root/PROJECT_ROOT"
printf 'scratch setup complete: %s\n' "$project_root"
