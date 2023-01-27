#!/bin/bash

# Run this script in a folder with *.bc file for KLEE

# The srcipt first
# - runs klee with .bc for N time, keeps raw log of each run,
# - then extracts statistics from `klee-stats` into a single file for each run,
# - finally takes the final result of each statistics and combines all
#   N final results into a single CSV file.

# bubblesort.bc  kmpmatcher.bc  knapsack.bc  mergesort.bc  nqueen.bc  quicksort.bc

mkdir -p /icse23/icse23-artifact-evaluation/table1/result

N=1

prefix=/icse23/icse23-artifact-evaluation/table1/result/klee-

for filename in /icse23/GenSym/benchmarks/icse23/algorithms/*.bc; do
  app=`basename $filename .bc`
  for ((i=1; i<=$N; i++)); do
    echo "Running klee --solver-backend=z3 --output-dir=$prefix$app-$i $filename"
    #numactl -N1 -m1
    klee --solver-backend=z3 --output-dir="$prefix$app-$i" "$filename" > result/klee-"$app-$i.log" 2>&1
    klee-stats --table-format csv  --print-columns "TSolver(s),Time(s)" "$prefix$app-$i" > result/klee-"$app-$i.csv"
  done
done

cd /icse23/icse23-artifact-evaluation/table1
python klee_collect.py $N >> table1.csv
