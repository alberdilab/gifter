#!/usr/bin/env bash
# Finish the local benchmark automatically when Mjolnir packages the full run.
set -euo pipefail

ssh_host=${R10_SSH_HOST:-mjolnirgate.unicph.domain}
task=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-chicken/tasks/04-giftag-benchmark
state_dir=manuscript/analysis/.cache/r10-chicken/giftag-monitor
job_table=manuscript/analysis/r10-chicken/benchmark/giftag-jobs.tsv
ssh_options=(-o BatchMode=yes -o ConnectTimeout=15 -o LogLevel=ERROR)
full_job=$(awk -F '\t' '$1 == "full_job_id" {print $2}' "$job_table")
transfer_job=$(awk -F '\t' '$1 == "transfer_job_id" {print $2}' "$job_table")
[[ -n "$full_job" && -n "$transfer_job" ]]
mkdir -p "$state_dir"

until ssh "${ssh_options[@]}" "$ssh_host" \
  "test -s '$task/transfer/transfer.complete'"; do
  if state=$(ssh "${ssh_options[@]}" "$ssh_host" \
    "sacct -j '$full_job' --noheader --format=State -P | head -1"); then
    case "$state" in
      FAILED*|CANCELLED*|TIMEOUT*|OUT_OF_MEMORY*)
        printf '%s full giftag job %s ended: %s\n' \
          "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$full_job" "$state" >&2
        exit 1
        ;;
    esac
  else
      printf '%s Mjolnir SSH unavailable; retrying\n' \
      "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" >&2
  fi
  if transfer_state=$(ssh "${ssh_options[@]}" "$ssh_host" \
    "sacct -j '$transfer_job' --noheader --format=State -P | head -1"); then
    case "$transfer_state" in
      FAILED*|CANCELLED*|TIMEOUT*|OUT_OF_MEMORY*)
        printf '%s transfer job %s ended: %s\n' \
          "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$transfer_job" "$transfer_state" >&2
        exit 1
        ;;
    esac
  fi
  sleep 60
done

bash manuscript/analysis/r10-chicken/fetch-and-rerun-giftag.sh
Rscript manuscript/analysis/33-r10-giftag-compare.R
python3 manuscript/analysis/34-r10-giftag-markers.py
python3 manuscript/analysis/35-r10-giftag-resources.py
python3 manuscript/analysis/36-r10-giftag-genome-timing.py
date -u +'%Y-%m-%dT%H:%M:%SZ' > "$state_dir/complete"
