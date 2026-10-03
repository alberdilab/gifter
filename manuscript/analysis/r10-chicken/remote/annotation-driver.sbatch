#!/usr/bin/env bash
#SBATCH --job-name=r10-drakkar-driver
#SBATCH --partition=cpuqueue
#SBATCH --qos=normal
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=7-00:00:00
#SBATCH --output=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-chicken/tasks/02-drakkar-annotation/logs/driver-%j.out
#SBATCH --error=/projects/alberdilab/scratch/jpl786/projects/gifter-r10-chicken/tasks/02-drakkar-annotation/logs/driver-%j.err

set -euo pipefail

exec /projects/alberdilab/scratch/jpl786/projects/gifter-r10-chicken/tasks/02-drakkar-annotation/run-drakkar.sh
