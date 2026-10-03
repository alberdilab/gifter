#!/usr/bin/env bash
set -euo pipefail

project_root=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-mfd
acquisition_task="$project_root/tasks/01-input-acquisition"
transfer_task="$project_root/tasks/03-result-transfer"
screen_name=r10-mfd-drakkar

if screen -ls 2>/dev/null | grep -q "[.]${screen_name}[[:space:]]"; then
  printf 'Screen %s is already running\n' "$screen_name" >&2
  exit 1
fi
if [[ -s "$transfer_task/transfer.complete" ]]; then
  printf 'Transfer is already complete; refusing to relaunch\n' >&2
  exit 1
fi

if [[ ! -s "$acquisition_task/manifests/acquisition.complete" ]]; then
  if [[ -s "$acquisition_task/manifests/acquisition-job.id" ]]; then
    job_id=$(cat "$acquisition_task/manifests/acquisition-job.id")
    if ! squeue -h -j "$job_id" | grep -q .; then
      prior_state=$(sacct -n -X -j "$job_id" -o State | awk 'NF {print $1; exit}')
      printf 'Recorded acquisition job %s ended as %s; resubmitting from verified files\n' \
        "$job_id" "${prior_state:-unknown}" >&2
      cd "$acquisition_task"
      job_id=$(sbatch --parsable acquire-inputs.sh)
      printf '%s\n' "$job_id" > "$acquisition_task/manifests/acquisition-job.id"
    fi
  else
    cd "$acquisition_task"
    job_id=$(sbatch --parsable acquire-inputs.sh)
    printf '%s\n' "$job_id" > "$acquisition_task/manifests/acquisition-job.id"
  fi
else
  printf 'complete\n' > "$acquisition_task/manifests/acquisition-job.id"
fi

screen -dmS "$screen_name" bash -lc \
  "exec '$transfer_task/workflow-driver.sh' >> '$transfer_task/logs/workflow-driver.log' 2>&1"
printf 'launched acquisition job %s and detached screen %s\n' \
  "$(cat "$acquisition_task/manifests/acquisition-job.id")" "$screen_name"
