#!/bin/bash
#export OMP_PROC_BIND=spread,close
#export BLIS_NUM_THREADS=1
#read -p "Do you want to clear previous data? (y/n)" yn
#case $yn in
#    [yY] ) echo "Removing data";rm -r output-*; rm -r data-cliff-stability; break;;
#    [nN] ) break;;
#esac
set -e
module load aocc/5.0.0
module load aocl/5.0.0
#sbcl --dynamic-space-size 16000 --load "build.lisp" --quit

export FLOATATION=0.8
export HEIGHT=600
export VISC=FALSE
export REFINE=0.125
export SLOPE=0.00
#export NAME=EKL_FLAT
#sbatch batch_mici.sh
export SLOPE=0.05
export NAME=OCTREE
sbatch batch_mici.sh
