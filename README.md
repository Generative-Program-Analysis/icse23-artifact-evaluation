# Compiling Parallel Symbolic Execution with Continuations (Artifact)

This repository is the artifact for the ICSE 2023 paper "Compiling Parallel
Symbolic Execution with Continuations".
The [accompanying paper](#) is included.
The artifact implements the symbolic-execution compiler
[GenSym](https://github.com/Generative-Program-Analysis/GenSym) and provides
instructions and benchmarks to reproduce the empirical experiments reported in
the paper.

Authors: Guannan Wei, Songlin Jia, Ruiqi Gao, Haotian Deng, Shangyin Tan, Oliver Bračevac, Tiark Rompf

TODO: TOC

## 1. Obtaining the Artifact

The artifact is available as a pre-built Docker image, which has all
dependencies and third-party tools installed.

To obtain the Docker image:

```
TODO
```

### Build the Docker Image

The script used to build the Docker image can be found from [here](#).
Following this script, one can rebuild the Docker image from scratch.
It is not the necessary for the artifact evaluation to rebuild the image,
but might be useful for anyone who would like modify or deploy GenSym.

TODO

## 2. Hardware Requirements

The artifact evaluation involves running parallel symbolic execution, therefore we
recommend using a machine with at least 16 physical cores and 32GB of memory.
The artifact only supports x86-64 architecture running Linux-based operating
systems.

To obtain accurate performance numbers and minimize interference, the evaluation
process also requires exclusive use of the machine.

Note: The experiment result reported in the paper is obtained from a machine
with 96 physical cores (192 physical+logical cores) and 3TB memory (although we
will not use that much memory). Different hardware environment may result in
numbers with different characteristics, but we expect the trend/ratio to be
similar.

## 3. Artifact Overview

The Docker image runs Ubuntu 20.04 and contains the [`icse23` branch of GenSym](#),
the [`fse21demo` branch of LLSC](#), and
[KLEE version 2.3](https://github.com/klee/klee/tree/v2.3).
LLSC and KLEE are two similar symbolic execution tools that are compared
with GenSym in the paper.

GenSym itself is written in Scala as a staged symbolic interpreter of
LLVM IR.

LLSC is the predecessor of GenSym. They are similar in that they both use
multi-stage programming and partial evaluation to compile LLVM IR symbolically.
However, LLSC does not generate code in continuation-passing style, which leads
to unsatisfying parallel execution performance and limited capabilities of using
heuristics.

KLEE is a state-of-the-art symbolic execution tool implemented as a interpreter,
in contrast to compilation-based tool such as GenSym.

### Software Dependencies

GenSym itself uses several C++ libraries, including

- Immer (ver?) as the immutable data structure library

Other system-wide installed third-party libraries and dependencies used
in the artifact include

- Z3
- STP
- g++
- LLVM
- sbt
- Java Virtual Machine 8
- Scala 2.10

### Benchmarks

Table 1

Table 2

### Directory Structure

We briefly describe the organization of GenSym's code base.


## 4. Evaluation Instructions

### Kick-the-Tires

**Expected Time: 10 minutes**


### RQ1

**Expected Time:**

table 1

### RQ2

**Expected Time:**

table 2

### RQ3

**Expected Time:**

table 3

numactl

### RQ4

**Expected Time:**

table 4

### RQ5

**Expected Time:**

table 5

### RQ6
**Expected Time:**

table 5

## 5. Try Your Own Programs


