#!/usr/bin/python3

import csv
import itertools

def split_name(row):
    """split the dict representing row by the 'name' key"""
    items = row['name'].split("_")
    return { 'prg': items[2], 'fs': items[3] }

def get_solver_time(row):
    i = row.get('t-solver-int')
    e = row.get('t-solver-ext')
    if i is not None and e is not None:
        return float(i)
    else:
        return None

with open('output/runtime.csv', 'r') as csvfile:
    reader = csv.DictReader(csvfile, delimiter=",")
    rows = [ { **split_name(row), **row } for row in reader if row['name'].startswith('h_')]
    # print(rows)
    l_prg = lambda r: r['prg']
    by_prg = itertools.groupby(sorted(rows, key=l_prg), l_prg)
    print("| {:20} | {:20} | {:20} | {:20} | {:20} | {:20} |".format("program", "posix T-solver", "posix T-exec", "Gen Meta T-solver", "Gen Meta T-exec", "speedup"))
    for key, grp in by_prg:
        # print(key, list(grp))
        r = list(grp)
        uclibc = next((item for item in r if item['fs'] == 'uclibc'), None)
        posix = next((item for item in r if item['fs'] == 'posix'), None)
        print("-"*25*6)

        posix_solver = get_solver_time(posix) if posix is not None else "x"
        posix_exec = float(posix.get('t-exec')) - posix_solver if posix is not None else "x"
        uclibc_solver = get_solver_time(uclibc) if uclibc is not None else "x"
        uclibc_exec = float(uclibc.get('t-exec')) - uclibc_solver if uclibc is not None else "x"
        speedup = posix_exec / uclibc_exec if posix_exec != "x" and uclibc_exec != "x" else "x"

        print("| {:20} | {:20} | {:20} | {:20} | {:20} | {:20} |".format(key, posix_solver, posix_exec, uclibc_solver, uclibc_exec, speedup))
