#!/usr/bin/env python

import sys

N = sys.argv[1]

prefix = "llsc"

apps = ["bubblesortTest", "knapsackTest", "kmpmatcherTest", "mergeSortTest", "quicksortTest"]

filename = "result/{}-{}-{}.log"

# Example
# [22.4488s/22.6989s]#blocks: 12/12; #paths: 720;

for app in apps:
    for i in N:
        with open(filename.format(prefix, app, i)) as f:
            for line in f: pass
            last_line = line
            solver_time = last_line.split("/")[0][1:-1]
            whole_time = last_line.split("/")[1].split("]")[0][:-1]
            n_path = last_line.split(":")[-1].strip()[:-1]
            print("LLSC, {}, {}, {}, {}".format(app, solver_time, whole_time, n_path))

# additionally print a dummy data for nqueen
print("LLSC, nqueenTest, 0.0, 0.0, 0")
