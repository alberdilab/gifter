#!/usr/bin/env bash
set -euo pipefail

ssh_host=${R10_MFD_SSH_HOST:-mjolnirgate.unicph.domain}
project_root=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-mfd
acquisition_task="$project_root/tasks/01-input-acquisition"
annotation_task="$project_root/tasks/02-drakkar-annotation"
transfer_task="$project_root/tasks/03-result-transfer"
local_dir=manuscript/analysis/.cache/r10-mfd/remote
ssh_options=(-o BatchMode=yes -o LogLevel=ERROR)

while ! ssh "${ssh_options[@]}" "$ssh_host" "test -s '$transfer_task/transfer.complete'"; do
  if ! status=$(ssh "${ssh_options[@]}" "$ssh_host" "
    archive=0
    if [ -s '$acquisition_task/archives/MFD.ilm_mag.tar.gz.part' ]; then
      archive=\$(stat -c '%s' '$acquisition_task/archives/MFD.ilm_mag.tar.gz.part')
    elif [ -s '$acquisition_task/archives/MFD.ilm_mag.tar.gz' ]; then
      archive=19842326855
    fi
    mags=\$(find '$acquisition_task/mags' -maxdepth 1 -type f -name 'LIB-*.fna.gz' 2>/dev/null | wc -l)
    prodigal=\$(find '$annotation_task/output/annotating/prodigal' -maxdepth 1 -type f -name '*.faa' 2>/dev/null | wc -l)
    kegg=\$(find '$annotation_task/output/annotating/kegg' -maxdepth 1 -type f -name '*.tsv' 2>/dev/null | wc -l)
    cazy=\$(find '$annotation_task/output/annotating/cazy' -mindepth 2 -maxdepth 2 -type f -name 'dbCAN_hmm_results.tsv' 2>/dev/null | wc -l)
    pfam=\$(find '$annotation_task/output/annotating/pfam' -maxdepth 1 -type f -name '*.tsv' 2>/dev/null | wc -l)
    ncbifam=\$(find '$annotation_task/output/annotating/ncbifam' -maxdepth 1 -type f -name '*.tblout' 2>/dev/null | wc -l)
    tigrfam=\$(find '$annotation_task/output/annotating/tigrfam' -maxdepth 1 -type f -name '*.tblout' 2>/dev/null | wc -l)
    final=\$(find '$annotation_task/output/annotating/final' -maxdepth 1 -type f -name '*_genes.tsv' 2>/dev/null | wc -l)
    if screen -ls 2>/dev/null | grep -q '[.]r10-mfd-drakkar[[:space:]]'; then
      driver=running
    elif [ -s '$transfer_task/transfer-job.id' ]; then
      driver=transfer_job_\$(cat '$transfer_task/transfer-job.id')
    else
      driver=stopped_without_transfer
    fi
    printf '%s archive_bytes=%s mags=%s prodigal=%s kegg=%s cazy=%s pfam=%s ncbifam=%s tigrfam=%s final=%s state=%s' \
      \"\$(date -u +'%Y-%m-%dT%H:%M:%SZ')\" \"\$archive\" \"\$mags\" \
      \"\$prodigal\" \"\$kegg\" \"\$cazy\" \"\$pfam\" \
      \"\$ncbifam\" \"\$tigrfam\" \"\$final\" \"\$driver\"
  "); then
    printf '%s state=ssh_reconnecting\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" >&2
    sleep 60
    continue
  fi
  printf '%s\n' "$status"
  if [[ "$status" == *"state=stopped_without_transfer"* ]]; then
    ssh "${ssh_options[@]}" "$ssh_host" \
      "tail -n 200 '$transfer_task/logs/workflow-driver.log'; tail -n 120 '$acquisition_task/logs/'*.err 2>/dev/null" >&2
    exit 1
  fi
  sleep 60
done

mkdir -p "$local_dir"

copy_remote() {
  local remote_path=$1
  local destination=$2
  local attempt
  for attempt in 1 2 3 4 5; do
    if scp "${ssh_options[@]}" "$ssh_host:$remote_path" "$destination"; then
      return 0
    fi
    printf '%s scp_retry=%s path=%s\n' \
      "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$attempt" "$remote_path" >&2
    sleep 60
  done
  return 1
}

copy_remote "$transfer_task/transfer-manifest.tsv" "$local_dir/transfer-manifest.tsv"
copy_remote "$transfer_task/transfer.complete" "$local_dir/transfer.complete"

tail -n +2 "$local_dir/transfer-manifest.tsv" | while IFS=$'\t' read -r file bytes checksum; do
  destination="$local_dir/$file"
  if [[ -s "$destination" ]]; then
    observed=$(shasum -a 256 "$destination" | cut -d' ' -f1)
    observed_bytes=$(wc -c < "$destination" | tr -d ' ')
    if [[ "$observed" == "$checksum" && "$observed_bytes" -eq "$bytes" ]]; then
      continue
    fi
  fi
  copy_remote "$transfer_task/output/$file" "$destination"
  observed=$(shasum -a 256 "$destination" | cut -d' ' -f1)
  observed_bytes=$(wc -c < "$destination" | tr -d ' ')
  [[ "$observed" == "$checksum" && "$observed_bytes" -eq "$bytes" ]] || {
    printf 'Fetched file failed verification: %s\n' "$file" >&2
    exit 1
  }
done

Rscript manuscript/analysis/25-r10-mfd.R
