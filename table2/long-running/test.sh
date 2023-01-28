#!/bin/bash

# Run this script in a folder with *.bc file for KLEE

# The srcipt
# - runs klee with .bc for N time, keeps raw log of each run,
# - then extracts statistics from `klee-stats` into a single file for each run,
# - finally takes the final result of each statistics and combines all
#   N final results into a single CSV file.

declare -A program_arg
declare -A symloc_strategy
declare -a orders

klee_bin=klee

iter_num=1

gs_gen_dir=/icse23/GenSym/gs_gen

klee_posix_dir=/icse23/GenSym/benchmarks/coreutils/klee_posix

gs_engine=ImpCPSGS
suffix=linked_posix

klee_option="--max-memory=3096120 --only-output-states-covering-new  --search=random-path  --solver-backend=z3 --external-calls=all  --use-cex-cache --use-branch-cache=true --rewrite-equalities=true --equality-substitution=true  --use-independent-solver --switch-type=simple  --max-sym-array-size=4096  --stats-write-interval=1s  --max-solver-time=30s --max-time=60min --use-batching-search --batch-instructions=10000 --watchdog --env-file=empty.env"

gs_option="--output-tests-cov-new  --thread=1  --search=random-path  --solver=z3   --output-ktest --timeout=3600  --max-sym-array-size=4096 --print-detailed-log=2"

true_gs_option="--output-tests-cov-new  --solver=z3   --output-ktest --timeout=3600  --max-sym-array-size=4096 --print-detailed-log=2"

program_arg[echo]="--sym-stdout --sym-arg 4 --sym-arg 8"
program_arg[cat]="--sym-stdout --sym-stdin 3 --sym-arg 3"
program_arg[base32]="--sym-stdout  --sym-stdin 4 --sym-arg 4 -sym-files 2 2"
program_arg[base64]="--sym-stdout  --sym-stdin 4 --sym-arg 4 -sym-files 2 2"
program_arg[comm]="--sym-stdout  --sym-stdin 3 --sym-arg 3  --sym-arg 1 -sym-files 2 2"
program_arg[cut]="--sym-stdout  --sym-stdin 3 --sym-arg 3 --sym-arg  3 -sym-files 2 2"
program_arg[dirname]="--sym-stdout  --sym-stdin 6 --sym-arg 9 --sym-arg 15"
program_arg[expand]="--sym-stdout  --sym-stdin 3 --sym-arg 3 -sym-files 2 2"
program_arg[fold]="--sym-stdout  --sym-stdin 3 --sym-arg 3    -sym-files 2 2"
program_arg[join]="--sym-stdout  --sym-stdin 3 --sym-arg 3 --sym-arg 3  -sym-files 2 2"
program_arg[link]="--sym-stdout  --sym-stdin 3 --sym-arg 3   --sym-arg 3  --sym-arg 3  -sym-files 2 2"
program_arg[paste]="--sym-stdout  --sym-stdin 3 --sym-arg 3 --sym-arg 3  -sym-files 2 2"
program_arg[pathchk]="--sym-stdout  --sym-stdin 3 --sym-arg 3 --sym-arg 3 -sym-files 2 2"

symloc_strategy[echo]="all"
symloc_strategy[cat]="all"
symloc_strategy[base32]="feasible"
symloc_strategy[base64]="feasible"
symloc_strategy[comm]="all"
symloc_strategy[cut]="all"
symloc_strategy[dirname]="all"
symloc_strategy[expand]="one"
symloc_strategy[fold]="all"
symloc_strategy[join]="one"
symloc_strategy[link]="one"
symloc_strategy[paste]="one"
symloc_strategy[pathchk]="all"


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


rm empty.env

touch empty.env

rm -rf klee

rm -rf gs

mkdir klee

mv ./empty.env ./klee/

mkdir gs

for id in "${!orders[@]}"; do
  program=${orders[$id]}
  cp ${klee_posix_dir}/${program}.ll ./klee/${program}_klee.ll
  bin_name=${gs_engine}_${program}_${suffix}
  cp ${gs_gen_dir}/${bin_name}/${bin_name} ./gs/${program}_gs
done


running_klee() {
  cd klee
  iter_index=$1
  for id in "${!orders[@]}"; do
    program=${orders[$id]}
    arg=${program_arg[${program}]}
    ll_name=${program}_klee.ll
    filename=klee-${program}
    command="${klee_bin} --output-dir=$filename-${iter_index} ${klee_option} ./${ll_name} ${arg}"
    echo "Running ${command}"
    ${command} > "$filename-${iter_index}_raw.log" 2>&1
  done

  cd ..
}

running_gs() {
  cd gs
  iter_index=$1
  for id in "${!orders[@]}"; do
    program=${orders[$id]}
    arg=${program_arg[${program}]}
    gs_bin=${program}_gs
    filename=gs-${program}
    curr_name="$filename-${iter_index}"
    sym_strategy=${symloc_strategy[${program}]}
    mkdir ${curr_name}
    cd ${curr_name}
    cp ../${gs_bin} ./
    run_gs_option=${gs_option}
    if [ ${program} = "true" ]; then
      run_gs_option=${true_gs_option}
    fi
    command_gs="./${gs_bin} ${run_gs_option} --symloc-strategy=${sym_strategy}"
    command_klee_fs="--argv=./${program}.bc   ${arg}"
    command="${command_gs} ${command_klee_fs}"
    echo "Running ${command}"
    full_command="${command_gs} --argv=\"./${program}.bc   ${arg}\" > ${curr_name}_raw.log 2>&1"
    echo "#!/bin/bash" > command.sh
    echo $full_command >> command.sh
    echo "#'" >> command.sh
    bash command.sh
    cd ..
  done

  cd ..
}

for ((i=0; i<${iter_num}; i++)); do
  running_gs $i
  running_klee $i
done

#'
