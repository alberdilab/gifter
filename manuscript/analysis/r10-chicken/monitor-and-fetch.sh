#!/usr/bin/env bash
set -euo pipefail

ssh_host=${R10_SSH_HOST:-mjolnirgate.unicph.domain}
project_root=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-chicken
annotation_task="$project_root/tasks/02-drakkar-annotation"
transfer_task="$project_root/tasks/03-result-transfer"
local_dir=manuscript/analysis/.cache/r10-chicken/drakkar
ssh_options=(-o BatchMode=yes -o LogLevel=ERROR)

while ! ssh "${ssh_options[@]}" "$ssh_host" "test -s '$transfer_task/transfer.complete'"; do
  if ! status=$(ssh "${ssh_options[@]}" "$ssh_host" "
    prodigal=0
    if [ -d '$annotation_task/output/annotating/prodigal' ]; then
      prodigal=\$(find '$annotation_task/output/annotating/prodigal' -maxdepth 1 -type f -name '*.faa' | wc -l)
    fi
    kegg=\$(find '$annotation_task/output/annotating/kegg' -maxdepth 1 -type f -name '*.tsv' 2>/dev/null | wc -l)
    cazy=\$(find '$annotation_task/output/annotating/cazy' -mindepth 2 -maxdepth 2 -type f -name 'dbCAN_hmm_results.tsv' 2>/dev/null | wc -l)
    pfam=\$(find '$annotation_task/output/annotating/pfam' -maxdepth 1 -type f -name '*.tsv' 2>/dev/null | wc -l)
    ncbifam=\$(find '$annotation_task/output/annotating/ncbifam' -maxdepth 1 -type f -name '*.tblout' 2>/dev/null | wc -l)
    tigrfam=\$(find '$annotation_task/output/annotating/tigrfam' -maxdepth 1 -type f -name '*.tblout' 2>/dev/null | wc -l)
    final=0
    if [ -d '$annotation_task/output/annotating/final' ]; then
      final=\$(find '$annotation_task/output/annotating/final' -maxdepth 1 -type f -name '*_genes.tsv' | wc -l)
    fi
    if screen -ls 2>/dev/null | grep -q 'r10-gifter-drakkar'; then
      driver=running
    elif [ -s '$transfer_task/transfer-job.id' ]; then
      transfer_job=\$(cat '$transfer_task/transfer-job.id')
      driver=transfer_job_\${transfer_job}
    else
      driver=stopped_without_transfer
    fi
    printf '%s prodigal=%s kegg=%s cazy=%s pfam=%s ncbifam=%s tigrfam=%s final=%s state=%s' \
      \"\$(date -u +'%Y-%m-%dT%H:%M:%SZ')\" \"\$prodigal\" \"\$kegg\" \
      \"\$cazy\" \"\$pfam\" \"\$ncbifam\" \"\$tigrfam\" \"\$final\" \"\$driver\"
  "); then
    printf '%s state=ssh_reconnecting\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" >&2
    sleep 30
    continue
  fi
  printf '%s\n' "$status"
  if [[ "$status" == *"state=stopped_without_transfer"* ]]; then
    ssh "${ssh_options[@]}" "$ssh_host" \
      "tail -n 160 '$annotation_task/logs/screen-driver.log'" >&2
    exit 1
  fi
  sleep 30
done

mkdir -p "$local_dir"

copy_remote() {
  local remote_path=$1
  local attempt
  for attempt in 1 2 3 4 5; do
    if scp "${ssh_options[@]}" "$ssh_host:$remote_path" "$local_dir/"; then
      return 0
    fi
    printf '%s scp_retry=%s path=%s\n' \
      "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$attempt" "$remote_path" >&2
    sleep 30
  done
  return 1
}

copy_remote "$transfer_task/output/gifter_input.tsv.xz"
copy_remote "$transfer_task/output/annotation_manifest.yaml"
copy_remote "$transfer_task/output/annotation_qc.tsv"
copy_remote "$transfer_task/transfer-manifest.tsv"
copy_remote "$transfer_task/transfer.complete"

Rscript manuscript/analysis/21-r10-chicken.R
