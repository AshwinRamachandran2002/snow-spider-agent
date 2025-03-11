#!/bin/bash
#SBATCH --job-name=data-pre
#SBATCH --output=data-pre-%j.out
#SBATCH --error=data-pre-%j.err
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=224
#SBATCH --mem=2063800M
#SBATCH --time=100:00:00

python -u -m utils.ashwin_data_processing