#!/bin/bash

# Request resources:
#SBATCH --time=20:00:0  # 6 hours (hours:minutes:seconds)
#SBATCH -p shared
#SBATCH -n 1                # number of MPI ranks
#SBATCH --cpus-per-task=16   # number of MPI ranks per CPU socket
#SBATCH --mem-per-cpu=1G
#SBATCH -N 1-1                    # number of compute nodes.

module load aocc/5.0.0
module load aocl/5.0.0

export MV2_ENABLE_AFFINITY=0
echo "Running code"
rm output/*

sbcl --dynamic-space-size 64000  --disable-debugger --load "template.lisp" --quit
