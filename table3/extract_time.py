#!/usr/bin/env python3

import sys

filename = sys.argv[1]
with open(filename) as f:
    for line in f: pass
    last_line = line
    whole_time = last_line.split(" ")[0].split("/")[3][:-2]
    print(whole_time, end="")
