#!/usr/bin/env python

import sys
import pandas as pd

cols = ['engine', 'benchmark', 'solverTime', 'wholeTime', 'pathNum']
df = pd.read_csv('table1.csv', names=cols)
df['execTime'] = df['wholeTime'] - df['solverTime']
df = df.groupby(['engine', 'benchmark']).agg('mean')
df = df.reset_index()
df = df.pivot(index='benchmark', columns='engine', values=['solverTime', 'wholeTime', 'pathNum', 'execTime'])
df = df.reorder_levels(order=[1, 0], axis=1)
df = df.sort_index(axis=1)
df['execSpeedup-vs-LLSC'] = df[('LLSC', 'execTime')] / df[('GenSym', 'execTime')]
df['execSpeedup-vs-KLEE'] = df[('KLEE', 'execTime')] / df[('GenSym', 'execTime')]
print(df)

