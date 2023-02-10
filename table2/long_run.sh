#!/bin/bash

gcov_src_dir=/scratch1/gao606/coreutils-testing-pipeline/coreutils/obj-gcov/src

cd long-running
bash test.sh
bash data_process.sh
bash get_coverage.sh ${gcov_src_dir}
python3 plot.py
cp ./long-running.csv ../
cp ./long-running-table.tex ../
cd ..

#'
