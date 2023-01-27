#!/usr/bin/env python

import sys

N = sys.argv[1]

filenames = ["bubblesort", "knapsack", "nqueen", "kmpmatcher", "mergesort", "quicksort"]
apps = ["bubblesortTest", "knapsackTest", "nqueenTest", "kmpmatcherTest", "mergeSortTest", "quicksortTest"]

prefix = "klee"
log_filename = "result/{}-{}-{}.log"
csv_filename = "result/{}-{}-{}.csv"

for i in range(0, 6):
    filename = filenames[i]
    app = apps[i]
    with open(log_filename.format(prefix, filename, 1)) as f:
        # get last line and extract the number of path
        for line in f: pass
        last_line = line
        n_path = last_line.split(" ")[-1].strip()
    for i in range(1, int(N)+1):
        with open(csv_filename.format(prefix, filename, i)) as f:
            for line in f: pass
            last_line = line
            solver_time = last_line.split(",")[0].strip()
            whole_time = last_line.split(",")[1].strip()
            print("KLEE, {}, {}, {}, {}".format(app, solver_time, whole_time, n_path))

