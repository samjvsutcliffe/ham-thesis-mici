#!/bin/bash
#export OMP_PROC_BIND=spread,close
#export BLIS_NUM_THREADS=1
export REFINE=1
read -p "Do you want to clear previous data? (y/n)" yn
case $yn in
    [yY] ) echo "Removing data";rm -r output-*; rm -r data-cliff-stability; break;;
    [nN] ) break;;
esac
set -e
module load aocc/5.0.0
module load aocl/5.0.0
sbcl --dynamic-space-size 16000 --load "build.lisp" --quit

for h in 300 350 400 450 500 550 
do
    for f in 1.0 0.95 0.9 0.85 0.8
    do
        export HEIGHT=$h
        export FLOATATION=$f
        sbatch batch_cliff_stab.sh
    done
done
    
for h in 600 650 700 750 850 900
do
    for f in 1.0 0.95 0.9
    do
        export HEIGHT=$h
        export FLOATATION=$f
        sbatch batch_cliff_stab.sh
    done
done

#export HEIGHT=450
#export FLOATATION=0.9
#sbatch batch_cliff_stab.sh

#export FLOATATION=0.8
#sbatch batch_cliff_stab.sh
#export HEIGHT=600
#export FLOATATION=0.95
#sbatch batch_cliff_stab.sh
#export FLOATATION=0.9
#sbatch batch_cliff_stab.sh

#export HEIGHT=850
#export FLOATATION=1.0
#sbatch batch_cliff_stab.sh
