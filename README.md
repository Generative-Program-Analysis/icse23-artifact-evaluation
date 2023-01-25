# Compiling Parallel Symbolic Execution with Continuations (Artifact)

This repository is the artifact for the ICSE 2023 paper *Compiling Parallel
Symbolic Execution with Continuations*.
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

The script used to build the Docker image can be found from
`/icse23/GenSym/docker-image/Dockerfile` and
`/icse23/GenSym/docker-image/init_script.sh`.
Following these scripts, one can rebuild the Docker image from scratch by
running given a tag name:
```
$ cd /icse23/GenSym/docker-image
$ docker build -t <image-tag-name> .
```
It is not the necessary for the artifact evaluation to rebuild the image,
but might be useful for anyone who would like modify or deploy GenSym.

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

The Docker image runs Ubuntu 20.04 and contains [GenSym at the `icse23` branch](#),
the [LLSC at the `fse21demo` branch](#), and
[KLEE of version 2.3](https://github.com/klee/klee/tree/v2.3).
LLSC and KLEE are two similar symbolic execution tools that are compared
with GenSym in the paper.

GenSym itself is written in Scala as a staged symbolic interpreter of
LLVM IR. Given an LLVM IR program, GenSym generates a C++ program that embeds
the parallel symbolic execution semantics of the input program.
Compiling and running this C++ program then perform symbolic execution
and test case generation.

LLSC is the predecessor of GenSym. They are similar in that they both use
multi-stage programming and partial evaluation to compile LLVM IR symbolically.
However, LLSC does not generate code in continuation-passing style, which leads
to unsatisfying parallel execution performance and limited capabilities of using
heuristics.

KLEE is a state-of-the-art symbolic execution tool implemented as a interpreter,
in contrast to compilation-based tool such as GenSym.

### Software Dependencies

GenSym itself uses a few data structures libraries, including
[immer](https://github.com/arximboldi/immer) and [parallel-hashmap](https://github.com/greg7mdp/parallel-hashmap).
Other system-wide installed third-party libraries and dependencies used
in the artifact include

- Z3 4.8.12
- STP 2.3.3
- g++ 9.10
- LLVM 11
- Java Virtual Machine 11
- Scala 2.12
- sbt

### Directory Structure

We briefly describe the organization of GenSym's code base, located at `/icse23/GenSym` of the Docker image:

- `benchmarks` contains the C source code and makefiles to generate LLVM IRs of them
- `docker-image` contains scripts to build the docker image
- `grammar` contains the ANTLR grammar definitions, which is used to generate the parser of textual LLVM IR programs
- `runtime` contains the source of GenSym's runtime, which are currently implemented as C++ headers
- `third-party` contains libraries that are used by GenSym's runtime, including data structures and SMT solvers
- `src/main` is the root directory of GenSym's front-end source code
  - `src/main/java` contains the LLVM IR parser generated by ANTLR
  - `src/main/scala/llvm` contains the Scala adapter of the parser generated by ANTLR
  - `src/main/scala/lms` contains customization of the Lightweight Modular Staging framework as well as GenSym's code generation facility
  - `src/main/scala/structure` contains algebraic structure definitions that are used to help high-level functional programming
  - `src/main/scala/utils` contains utilities
  - `src/main/scala/gensym` is the main directory of GenSym's implementation
    - GenSym implements a few variants staged symbolic interpreters (i.e. compilers), which are contained in `src/main/scala/engines`. The default and most mature compile is `src/main/scala/engines/ImpCPSEngine.scala` that generates CPS code and uses in-place update when possible.
- `src/test` contains testing infrastructure that are used in Github CI

## 4. Kick-the-Tires

**Expected Time: <15 minutes**

In this Kick-the-Tires step, we make a basic sanity check of the whole compilation pipeline.
We use a simple branching program as example and explain the pipeline.

The first preparation step is to generate GenSym's external models.  GenSym
defines models for external functions in a Scala DSL, which will be generated
to C++ functions that can be used together with compiled application code.
To do this, we start an interactive `sbt` session by running
(`start_sbt` sets necessary parameters for JVM and invokes `sbt`):

```
# cd /icse23/GenSym
# ./start_sbt
```

Then we run the following command in the `sbt` session to generate models for external functions:
```
sbt:GenSym> runMain gensym.GenerateExternal
```
The first time running `sbt` downloads dependencies specified in `build.sbt` and
compiles the Scala code to JVM bytecode, which may take a few minutes.
After printing some compilation log, we should see `[success]` in the output.
(TODO: disable logging)
This generates a C++ file `/icse23/GenSym/headers/gensym/external.hpp`.

Next, we can use GenSym to compile a simple example program. We use a C program,
which is stored in `/icse23/GenSym/benchmarks/llvm/branch.c`:

```
int f(int x, int y) {
  if (x <= 0 || y <= 0) return -1;
  if (x * x + y * y == 25) {
    return 1;
  }
  return 0;
}
```

Its LLVM IR file can be found in `/icse23/GenSym/benchmarks/llvm/branch.ll`.
We have mechanized this kick-the-tire compilation process as a test case. We
can run the following command in `sbt` to use GenSym to compile:

```
sbt:GenSym> testOnly icse23.KickTheTires
```

This step invokes GenSym to (1) compile the LLVM IR input to C++ code
for symbolic execution, (3) compile the C++ code to an executable, and
(4) run the executable to generate test cases.
Symbolically executing this program discovers 4 paths, and we expect to see the
following output from `sbt` at the end:

```
[info] All tests passed.
```

This signals the success of the kick-the-tires compilation process.
The generated C++ program and tests are located in
`/icse23/GenSym/gs_gen/ImpCPSGS_branch1` for further inspection.

## 4. Evaluation Instructions

### Benchmarks

The paper uses two groups of benchmarks: (1) algorithm programs with finite
numbers of paths, and (2) a subset of GNU Coreutils programs that have interaction
with OS file system and command line interface.

Further more, these Coreutils benchmarks can be used with different input
configurations.  The paper uses two configurations: (1) short-running
configurations that have smaller number of symbolic inputs and can be
symbolically executed in a few minutes, and (2) long-running
configurations that have more number of symbolic inputs and take much
longer time to test.

We use the algorithm benchmarks in Table I, whose C source code and LLVM IR
can be found in `TODO`.

The short-running benchmark configuration of Coreutils programs
are used in Table II, TODO

We use the long-running configuration in TODO

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

### Use GenSym's Interface

It is possible to use GenSym's interface to compile your own programs.
One way is to run GenSym's main function in `sbt`:

```
```

### The Structure of Generated Files