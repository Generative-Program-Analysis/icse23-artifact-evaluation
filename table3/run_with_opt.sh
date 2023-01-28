#!/bin/bash

declare -A program_arg
declare -A symloc_strategy
declare -a orders
declare -a threads

iter_num=5

gs_gen_dir=/icse23/GenSym/gs_gen
gs_engine=ImpCPSGS
suffix=linked_posix

gs_option="--output-tests-cov-new --search=random-path --solver=z3 --output-ktest --timeout=7200 --max-sym-array-size=4096 --print-detailed-log=2"

program_arg[base32]="--sym-stdout  --sym-stdin 2 --sym-arg 2 -sym-files 2 2"
program_arg[base64]="--sym-stdout  --sym-stdin 2 --sym-arg 2 -sym-files 2 2"
program_arg[echo]="--sym-stdout --sym-arg 2 --sym-arg 7"
program_arg[cat]="--sym-stdout --sym-stdin 2 --sym-arg 2"
program_arg[comm]="--sym-stdout  --sym-stdin 2 --sym-arg 2  --sym-arg 1 -sym-files 2 2"
program_arg[cut]="--sym-stdout  --sym-stdin 2 --sym-arg 2 --sym-arg  2 -sym-files 2 2"
program_arg[dirname]="--sym-stdout  --sym-stdin 2 --sym-arg 6 --sym-arg 10"
program_arg[expand]="--sym-stdout  --sym-stdin 2 --sym-arg 2 -sym-files 2 2"
program_arg[true]="--sym-stdout  --sym-arg 10"
program_arg[fold]="--sym-stdout  --sym-stdin 2 --sym-arg 2    -sym-files 2 2"
program_arg[join]="--sym-stdout  --sym-stdin 2 --sym-arg 2 --sym-arg 1  -sym-files 2 2"
program_arg[link]="--sym-stdout  --sym-stdin 2 --sym-arg 2   --sym-arg 1  --sym-arg 1  -sym-files 2 2"
program_arg[paste]="--sym-stdout  --sym-stdin 2 --sym-arg 2 --sym-arg 1  -sym-files 2 2"
program_arg[pathchk]="--sym-stdout  --sym-stdin 2 --sym-arg 2 --sym-arg 2 -sym-files 2 2"

symloc_strategy[base32]="all"
symloc_strategy[base64]="all"
symloc_strategy[echo]="all"
symloc_strategy[cat]="all"
symloc_strategy[comm]="all"
symloc_strategy[cut]="all"
symloc_strategy[dirname]="all"
symloc_strategy[expand]="all"
symloc_strategy[true]="all"
symloc_strategy[fold]="all"
symloc_strategy[join]="all"
symloc_strategy[link]="all"
symloc_strategy[paste]="all"
symloc_strategy[pathchk]="all"

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

threads+=(1)
threads+=(4)
threads+=(8)
threads+=(12)

rm -rf empty.env
touch empty.env

folder=gs_opt

rm -rf $folder
mkdir $folder

for id in "${!orders[@]}"; do
  program=${orders[$id]}
  bin_name=${gs_engine}_${program}_${suffix}
  cp ${gs_gen_dir}/${bin_name}/${bin_name} ./${folder}/${program}_gs
done

# running_gs(iter,th)
running_gs() {
  cd $folder
  iter_index=$1
  th=$2
  printf "\n\n# running iteration ${iter_index}\n\n"
  for id in "${!orders[@]}"; do
    program=${orders[$id]}
    arg=${program_arg[${program}]}
    gs_bin=${program}_gs
    curr_name="gs-${program}-${th}th-${iter_index}"
    #echo "$program: ${arg}"
    mkdir ${curr_name}
    cd ${curr_name}
    cp ../${gs_bin} ./
    sym_strategy=${symloc_strategy[${program}]}
    #command_gs="numactl -N0 -m0 ./${gs_bin} ${gs_option} --symloc-strategy=${sym_strategy}"
    command_gs="./${gs_bin} ${gs_option} --symloc-strategy=${sym_strategy} --thread=$th"
    command="${command_gs} --argv=./${program}.bc ${arg}"
    echo "Running ${command}"
    full_command="${command_gs} --argv=\"./${program}.bc ${arg}\" > ${curr_name}_raw.log 2>&1"
    echo "#!/bin/bash" > command.sh
    echo $full_command >> command.sh
    bash command.sh
    echo $program,$th,`python3 ../../extract_time.py ${curr_name}_raw.log` >> ../../result_opt.csv
    cd ..
  done

  cd ..
}

for t in "${!threads[@]}"; do
  for ((i=1; i<=${iter_num}; i++)); do
    running_gs $i ${threads[$t]}
  done
done

