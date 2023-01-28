#!/bin/bash

gcov_src_dir=/icse23/coreutils-src/obj-gcov/src

cd short-running
bash test.sh
bash data_process.sh
bash get_coverage.sh ${gcov_src_dir}
python3 plot.py
cp ./short-running.csv ../
cp ./short-running-table.tex ../
cd ..

#'
