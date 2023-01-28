#!/bin/bash

declare -a orders

klee_stats_bin=klee-stats

iter_num=1


orders+=(echo)
orders+=(cat)
orders+=(base32)
orders+=(base64)
orders+=(comm)
orders+=(cut)
orders+=(dirname)
orders+=(expand)
orders+=(fold)
orders+=(join)
orders+=(link)
orders+=(paste)
orders+=(pathchk)

processing_individual_klee() {
  program=$1
  iter_index=$2
  for id in "${!orders[@]}"; do
    filename=klee-${program}
    ${klee_stats_bin} --to-csv --print-all "$filename-${iter_index}" > "$filename-${iter_index}.log"
  done
}

processing_klee() {
  cd klee
  for id in "${!orders[@]}"; do
    program=${orders[$id]}
    for ((i=0; i<${iter_num}; i++)); do
      processing_individual_klee $program $i
    done
    filename=klee-${program}
    head -n1 "$filename-0.log" > "$filename.csv"
    for ((i=0; i<${iter_num}; i++)); do
      tail -q -n 1 "$filename-$i.log" >> "$filename.csv"
    done
  done
  cd  ..
}


processing_individual_gs() {
  iter_index=$1
  for id in "${!orders[@]}"; do
    program=${orders[$id]}
    filename=gs-${program}
    curr_name="$filename-${iter_index}"
    rm -rf ./${program}-tests
    mkdir ${program}-tests
    cd ${curr_name}
    cp ${curr_name}_raw.log ../
    cd gensym-*
    cp -r ./tests/* ../../${program}-tests/
    cd ..
    cd ..
  done
}

processing_gs() {
  cd gs
  for ((i=0; i<${iter_num}; i++)); do
    processing_individual_gs $i
  done
  cd ..
}

processing_klee
processing_gs

#'
