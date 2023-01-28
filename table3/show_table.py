#!/usr/bin/env python3

import sys

filename = sys.argv[1]

def rq3_parallel(fn):
    colnames = 'app threads time'.split()
    df = pd.read_csv(fn, names=colnames)
    df = df.pivot_table(index='app', columns='threads', values='time')
    for th in df.columns:
        if th != 1:
            df[th] = df[1] / df[th]
    df = df.drop(1, axis=1)
    avg = df.agg('mean')
    df = pd.concat([df, avg.to_frame('average').T])
    return df

df = rq3_parallel(filename)
print(df)
