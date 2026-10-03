#!/usr/bin/env bash
set -euo pipefail

project_root=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-mfd
acquisition_task="$project_root/tasks/01-input-acquisition"
annotation_task="$project_root/tasks/02-drakkar-annotation"
transfer_task="$project_root/tasks/03-result-transfer"
job_file="$acquisition_task/manifests/acquisition-job.id"

[[ -s "$job_file" ]] || { printf 'Missing acquisition job id\n' >&2; exit 1; }
job_id=$(cat "$job_file")

while [[ ! -s "$acquisition_task/manifests/acquisition.complete" ]]; do
  state=$(squeue -h -j "$job_id" -o '%T' | head -n 1)
  if [[ -z "$state" ]]; then
    final_state=""
    for attempt in 1 2 3 4 5 6; do
      final_state=$(sacct -n -X -j "$job_id" -o State | awk 'NF {print $1; exit}')
      [[ -n "$final_state" && "$final_state" != "RUNNING" ]] && break
      sleep 10
    done
    printf 'Acquisition job %s ended as %s without a completion sentinel\n' \
      "$job_id" "${final_state:-unknown}" >&2
    exit 1
  fi
  printf '%s acquisition_job=%s state=%s\n' \
    "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$job_id" "$state"
  sleep 60
done

"$annotation_task/run-drakkar.sh"

cd "$transfer_task"
sbatch --parsable prepare-transfer.sh > transfer-job.id
