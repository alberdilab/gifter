#!/usr/bin/env bash
set -euo pipefail

project_root=/projects/alberdilab/scratch/jpl786/projects/gifter-gtdb-phylogeny
annotation_task="$project_root/tasks/02-drakkar-annotation"
transfer_task="$project_root/tasks/03-result-transfer"

"$annotation_task/run-drakkar.sh"

cd "$transfer_task"
sbatch --parsable prepare-transfer.sh > transfer-job.id
