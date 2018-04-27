#!/bin/bash

#SBATCH -n 1                               # Request one core
#SBATCH -N 1                               # Request one node
#SBATCH -t 0-01:00                          # Runtime in D-HH:MM format
#SBATCH -p short                           # Partition to run in
#SBATCH --mem=10000                        # Memory total in MB (for all cores)
#SBATCH -o ~/logs/logs_Acq2P/Acq2P_%A_%a.out   # File to which STDOUT will be written, including job ID
#SBATCH -e ~/errs/errs_Acq2P/Acq2P_%A_%a.err   # File to which STDERR will be written, including job ID
#SBATCH --job-name=Acq2P

matlab -nodisplay -r "spmd_test"
