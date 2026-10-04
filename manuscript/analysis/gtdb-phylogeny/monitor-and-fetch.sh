#!/usr/bin/env bash
set -euo pipefail

ssh_host=${GTDB_PHYLOGENY_SSH_HOST:-mjolnirgate.unicph.domain}
project_root=/projects/alberdilab/scratch/jpl786/projects/gifter-gtdb-phylogeny
annotation_task="$project_root/tasks/02-drakkar-annotation"
transfer_task="$project_root/tasks/03-result-transfer"
local_dir=manuscript/analysis/.cache/gtdb-phylogeny/drakkar
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
    final=\$(find '$annotation_task/output/annotating/final' -maxdepth 1 -type f -name '*_genes.tsv' 2>/dev/null | wc -l)
    if screen -ls 2>/dev/null | grep -q 'gtdb-gifter-drakkar'; then state=running
    elif [ -s '$transfer_task/transfer-job.id' ]; then state=transfer_job_\$(cat '$transfer_task/transfer-job.id')
    else state=stopped_without_transfer
    fi
    printf '%s prodigal=%s kegg=%s cazy=%s pfam=%s ncbifam=%s tigrfam=%s final=%s state=%s' \
      \"\$(date -u +'%Y-%m-%dT%H:%M:%SZ')\" \"\$prodigal\" \"\$kegg\" \
      \"\$cazy\" \"\$pfam\" \"\$ncbifam\" \"\$tigrfam\" \"\$final\" \"\$state\"
  "); then
    printf '%s state=ssh_reconnecting\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" >&2
    sleep 30
    continue
  fi
  printf '%s\n' "$status"
  [[ "$status" != *"state=stopped_without_transfer"* ]] || exit 1
  sleep 30
done

mkdir -p "$local_dir"
for path in \
  "$transfer_task/output/gifter_input.tsv.xz" \
  "$transfer_task/output/annotation_manifest.yaml" \
  "$transfer_task/output/annotation_qc.tsv" \
  "$transfer_task/output/selected-genomes.tsv" \
  "$transfer_task/output/resolved-downloads.tsv" \
  "$transfer_task/output/genome-sha256.tsv" \
  "$transfer_task/output/assembly-summary-sha256.txt" \
  "$transfer_task/output/selected-manifest-sha256.txt" \
  "$transfer_task/transfer-manifest.tsv" \
  "$transfer_task/transfer.complete"; do
  scp "${ssh_options[@]}" "$ssh_host:$path" "$local_dir/"
done
# Present only when a locked genome could not be annotated.
if ssh "${ssh_options[@]}" "$ssh_host" "test -s '$transfer_task/output/excluded-genomes.tsv'"; then
  scp "${ssh_options[@]}" "$ssh_host:$transfer_task/output/excluded-genomes.tsv" "$local_dir/"
fi

Rscript manuscript/analysis/23-gtdb-phylogeny.R
