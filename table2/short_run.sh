#!/bin/bash

gcov_src_dir=/scratch1/gao606/coreutils-testing-pipeline/coreutils/obj-gcov/src

cd short-running
bash test.sh
bash data_process.sh
bash get_coverage.sh ${gcov_src_dir}
python3 plot.py
cp ./short-running.csv ../
cp ./short-running-table.tex ../
cd ..

#'
