#!/usr/bin/env python

import sys

N = sys.argv[1]

prefix = "gensym"

apps = ["bubblesortTest", "knapsackTest", "nqueenTest", "kmpmatcherTest", "mergeSortTest", "quicksortTest"]

filename = "result/{}-{}-{}.log"

# Example
# [11.5792s/11.8349s/0s/11.9317s] #blocks: 16/16; #br: 0/4/4; #paths: 720; #threads: 1; #task-in-q: 0; #queries: 16062/720 (8322)

for app in apps:
    for i in range(1, int(N)+1):
        with open(filename.format(prefix, app, i)) as f:
            for line in f: pass
            last_line = line
            solver_time = last_line.split(" ")[0].split("/")[1][:-1]
            whole_time = last_line.split(" ")[0].split("/")[3][:-2]
            n_path = last_line.split(" ")[6][:-1]
            print("GenSym, {}, {}, {}, {}".format(app, solver_time, whole_time, n_path))
