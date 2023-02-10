#!/bin/bash

declare -a orders

gcov_dir=$1

klee_replay_bin=klee-replay-11

orders+=(echo)
orders+=(cat)
orders+=(base32)
orders+=(base64)
orders+=(comm)
orders+=(cut)
orders+=(dirname)
orders+=(expand)
orders+=(true)
orders+=(fold)
orders+=(join)
orders+=(link)
orders+=(paste)
orders+=(pathchk)

curr_dir=$(pwd)

cd ${gcov_dir}

for id in "${!orders[@]}"; do
  program=${orders[$id]}
  rm -f *.gcda
  gcov_name=${program}
  if [ $program = "base32" ] || [ $program = "base64"  ]; then
  	gcov_name=${program}-basenc
  fi
  #echo $gcov_name
  ${klee_replay_bin} ./${program} ${curr_dir}/gs/${program}-tests/*.ktest
  gcov $gcov_name > gs_${program}_gcov.log
  cp ./gs_${program}_gcov.log ${curr_dir}/gs/${program}_gcov.log
done


for id in "${!orders[@]}"; do
  program=${orders[$id]}
  rm -f *.gcda
  gcov_name=${program}
  if [ $program = "base32" ] || [ $program = "base64"  ]; then
  	gcov_name=${program}-basenc
  fi
  #echo $gcov_name
  ${klee_replay_bin} ./${program} ${curr_dir}/klee/klee-${program}-0/*.ktest
  gcov $gcov_name > klee_${program}_gcov.log
  cp ./klee_${program}_gcov.log ${curr_dir}/klee/${program}_gcov.log
done


cd ${curr_dir}
