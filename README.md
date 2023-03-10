# Compiling Parallel Symbolic Execution with Continuations (Artifact)

This document is the instruction for the ICSE 2023 artifact evaluation for
paper *Compiling Parallel Symbolic Execution with Continuations*.
The paper improves the design and performance of symbolic execution
engine by compiling symbolic execution tasks into continuation-passing style,
a program representation that exposes control. This allows the symbolic
execution to be parallelized and to use heuristics to guide the execution.

The artifact implements the symbolic-execution compiler
[GenSym](https://github.com/Generative-Program-Analysis/GenSym) and provides
instructions and benchmarks to reproduce the empirical experiments (Section VII)
reported in the paper.

This document is also available online at https://github.com/Generative-Program-Analysis/icse23-artifact-evaluation.

Authors: Guannan Wei, Songlin Jia, Ruiqi Gao, Haotian Deng, Shangyin Tan, Oliver Bračevac, Tiark Rompf

<!-- TOC -->

- [Compiling Parallel Symbolic Execution with Continuations Artifact](#compiling-parallel-symbolic-execution-with-continuations-artifact)
  - [Obtaining the Artifact](#obtaining-the-artifact)
    - [Start the Docker Container](#start-the-docker-container)
    - [Build the Docker Image](#build-the-docker-image)
  - [Artifact Overview](#artifact-overview)
    - [Software Dependencies](#software-dependencies)
    - [Directory Structure](#directory-structure)
  - [Hardware Requirements](#hardware-requirements)
  - [Kick-the-Tires](#kick-the-tires)
  - [Benchmarks Description](#benchmarks-description)
  - [Evaluation Instructions](#evaluation-instructions)
    - [RQ1](#rq1)
    - [RQ2](#rq2)
    - [RQ3](#rq3)
    - [RQ4 and RQ5](#rq4-and-rq5)
  - [Try Your Own Programs](#try-your-own-programs)
    - [Use GenSym's Interface](#use-gensyms-interface)
    - [Built-in Test Cases](#built-in-test-cases)
    - [Generated Files](#generated-files)

<!-- /TOC -->

## 1. Obtaining the Artifact

The artifact is available as a pre-built Docker image, which has all
dependencies and third-party tools installed.

To obtain the Docker image (you may need root privilege to run `docker`):

```
$ docker pull guannanwei/gensym:icse23
```

### Start the Docker Container

To instantiate the Docker image, run the following command (we need to use
`ulimit` to increase stack size to avoid stack overflow):

```
sudo docker run --name test --ulimit='stack=268435456:268435456' -it guannanwei/gensym:icse23 bash -c 'source /icse23/sync.sh; bash'
```

Then we should be able to see the prompt of `bash`.
All experiments are conducted within the Docker container.

In case there are up-stream changes of the artifact, you can run the following
command to sync up (which is suggested):
```
# cd /icse23
# bash sync.sh
```

Once running inside the Docker, you can also find this document
at `/icse23/icse23-artifact-evaluation/README.md`.

### Build the Docker Image

The scripts used to build the Docker image can be found at
`/icse23/GenSym/docker-image/Dockerfile` and
`/icse23/GenSym/docker-image/init_script.sh` (also in [GenSym's Github
repository](https://github.com/Generative-Program-Analysis/GenSym/tree/icse23/docker-image)).
Using these scripts, one can rebuild the Docker image from scratch
or install our artifact on a clean Ubuntu 20.04 machine.
To build a Docker image, run the following command:
```
// under the folder with Dockerfile and other initialization scripts
$ docker build -t <image-tag-name> .
```
It is *not* necessary for the artifact evaluation to rebuild the image,
but would be useful for anyone who would like to reuse or deploy GenSym.

## 2. Artifact Overview

The Docker image runs Ubuntu 20.04 and contains [GenSym at the `icse23` branch](https://github.com/Generative-Program-Analysis/GenSym/tree/icse23),
the [LLSC at the `fse21demo` branch](https://github.com/Kraks/sai/tree/fse21demo), and
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

The GenSym compiler relies on the Lightweight Modular Staging (LMS) framework
(`/icse23/GenSym/third-party/lms-clean`). Other Scala dependencies and their
versions are all specified in `/icse23/GenSym/build.sbt`.
GenSym's backend uses a few C++ data structures libraries, including
[immer](https://github.com/arximboldi/immer) and [parallel-hashmap](https://github.com/greg7mdp/parallel-hashmap) (exact version dependencies specified in `.gitmodules`).

In the Docker image, we also installed several third-party libraries and
dependencies system-wide; they are used by GenSym, or KLEE and LLSC:

- Z3 4.8.12
- STP (SMTCOMP2020 release)
- g++ 9.4.0
- clang/clang++/LLVM 11
- Java Virtual Machine 8 (OpenJDK)
- Scala 2.12
- sbt

### Directory Structure

We briefly describe the organization of GenSym's code base, located at `/icse23/GenSym` of the Docker image:

- `benchmarks` contains the C source code and makefiles to generate LLVM IRs of source
- `docker-image` contains scripts to build the Docker image
- `grammar` contains the ANTLR grammar definitions, which is used to generate the parser of textual LLVM IR programs
- `headers` contains the source of GenSym's runtime, which are currently implemented as C++ headers. They will be compiled together with the application code.
- `third-party` contains libraries that are used by GenSym's runtime, including data structures and SMT solvers
- `src/main` is the root directory of GenSym's front-end comiler source code
  - `src/main/java` contains the LLVM IR parser generated by ANTLR
  - `src/main/scala/llvm` contains the Scala adapter of the parser generated by ANTLR
  - `src/main/scala/lms` contains our customization of the Lightweight Modular Staging framework as well as GenSym's code generation facility
  - `src/main/scala/structure` contains algebraic structure definitions that are used to help high-level functional programming
  - `src/main/scala/utils` contains utilities (e.g. timing)
  - `src/main/scala/gensym` is the main directory of GenSym's implementation
    - GenSym implements a few variants of staged symbolic interpreters (i.e. compilers) in `src/main/scala/engines`. The default and most mature compiler is `src/main/scala/engines/ImpCPSEngine.scala` that generates CPS code and uses in-place update when possible. If you want to understand how the staged symbolic
    interpreter works, you can start from this file.
- `src/test` contains the testing infrastructure that is used in Github CI

## 3. Hardware Requirements

The artifact evaluation involves running parallel symbolic execution. Therefore,
to verify the basic functionality of the artifact, we recommend using a machine
with at least 16 physical cores and 32GB of memory.
To verify the full functionality, we recommend using a machine with 16+ cores
and 128GB of memory.

The experiment result reported in the paper is obtained from a machine
with 96 physical cores (192 logical cores) and 3TB of memory (although we
do not use that much memory). Different hardware environment may result in
numbers with different characteristics, but we do expect the trend/ratio to be
similar.

The artifact only supports x86-64 architecture running Linux-based operating systems.

To obtain accurate performance numbers and minimize interference, the evaluation
process also requires exclusive use of the machine.

## 4. Kick-the-Tires

**Expected Time: 15 minutes**

In this Kick-the-Tires step, we make a basic sanity check of the whole compilation pipeline.
We use a simple branching program as example and explain the pipeline.

The first preparation step is to generate GenSym's external models.
Although this step has been performed at image-creation time, we explain
how to do it again here for completeness.
These models simulate symbolic behaviors of external functions, such as
the POSIX file system.
GenSym defines models for external functions in a Scala DSL, which will be used
to generate C++ functions that can be used together with the compiled
application code.

To do this, we perform the following command in the Docker image:

```
# cd /icse23/GenSym
# sbt "runMain gensym.GenerateExternal"
```

The first time running `sbt` downloads dependencies specified in `build.sbt` and
compiles the Scala code to JVM bytecode, which may take a few minutes.
After printing some compilation log, we should see `[success]` in the output.
This generates a C++ file `/icse23/GenSym/headers/gensym/external.hpp`.

Next, we can use GenSym to compile a simple example program. We use a C program,
located at `/icse23/GenSym/benchmarks/llvm/branch.c`:

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
We have mechanized this kick-the-tire compilation process as a test case.
We can run the following command invoking `sbt` to use GenSym to compile
`branch.ll`:

```
// under /icse23/GenSym
# sbt "testOnly icse23.KickTheTires"
```

This step invokes GenSym to (1) compile the LLVM IR input to C++ code
for symbolic execution, (2) compile the C++ code to an executable, and
(3) run the executable to generate test cases.
Symbolically executing this program discovers 4 paths, and we expect to see the
following output from `sbt` at the end,

```
[info] All tests passed.
```

This signals the success of the kick-the-tires compilation process.
The generated C++ program and test cases are located in
`/icse23/GenSym/gs_gen/ImpCPSGS_branch1` for further inspection.

## 4. Benchmarks Description

The paper uses two groups of benchmarks: (1) algorithm programs with finite
numbers of paths, and (2) a subset of GNU Coreutils (v8.32) programs that interact
with the OS file system and command line interface.

We use the algorithm benchmarks in Table I, whose C source code and LLVM IR can
be found in `/icse23/GenSym/benchmarks/icse23/algorithms`.

We use the Coreutils benchmarks for the rest of experiments, including Table {II,
III, IV}.
Their LLVM IR can be found in `/icse23/GenSym/benchmarks/icse23/coreutils`.
The C source code of Coreutils are included in the artifact under
`/icse23/coreutils-src`.
The `gcov`-instrumented Coreutils programs are included in the artifact under
`/icse23/coreutils-src/obj-gcov/src`, which are used to evaluate coverage
of generated test cases.

The generation of Coreutils LLVM IR from their C source code is not
part of the artifact, but can be found in a [separate document](https://github.com/Generative-Program-Analysis/coreutils-testing-instruction) we
prepared.

Further more, these Coreutils benchmarks can be used with different input
configurations. The paper uses two configurations: (1) *short-running*
configurations that have smaller numbers of symbolic inputs and can be
symbolically executed in a few minutes, and (2) *long-running*
configurations that have more numbers of symbolic inputs and take much
longer time to test (each single run for ~1hour).

Both GenSym and KLEE can finish the short-running benchmarks,
with the same set of paths explored. Therefore we can compare the performance
based on the same workload.
The long-running benchmarks are used to evaluate the scalability.
Both engines time out at one hour, and then we compare their throughput,
i.e. the number of paths they explore per second (assuming that paths are homogeneous).

More specifically, the long-running configurations of Coreutils programs
are used in the *lower part* of Table II for RQ2.
All other experiments including the upper part of Table II, Table III, and Table IV
use the short-running configurations.

## 5. Evaluation Instructions

### RQ1

**Expected Time: 30 minutes**

This experiment answers RQ1 and generates Table I of the paper. We will first
examine the benchmarks, then run the experiment using LLSC, GenSym, and
KLEE, and finally generate the digested results.

**Examining Benchmarks**

The set of benchmarks for RQ1 are located in `/icse23/GenSym/benchmarks/icse23/algorithms`.
Both C source code and LLVM IR of them are already included.
The `.ll` files are used by GenSym and LLSC, and the `.bc` files are used by KLEE, as
they are linked with different engine-specific APIs.
A `Makefile` is accompanied with these benchmarks, so a user can modify the C programs
and produce alternative test cases using the same procedure.

- To show the LOC of C source code ("C LOC" column in Table I):

```
# cd /icse23/GenSym/benchmarks/icse23/algorithms
# cloc --by-file *.c
```

- To show the LOC of LLVM IR code ("LLVM LOC" column in Table I):

```
# wc -l *.ll
```

- The number of symbolic inputs (i.e. the "#Sym Args" column in Table I) are
annotated in the C source file. Using `bubblesort.c` as an example, the program
initializes `SIZE` symbolic variables using engine-specific APIs, which is 6 in
this case.

- The number of paths of each benchmark program (i.e. the "#Paths" column in Table I)
is produced by running the program with symbolic execution, which is the next step.

**Running LLSC**

```
# cd /icse23/icse23-artifact-evaluation/table1
# bash run_llsc.sh
```
This step compiles those benchmarks with LLSC, which generates code under
`/icse23/llsc/dev-clean/llsc_gen`, and further generates executable files.
The script then invokes the executables and performs the symbolic execution.
The execution log and raw timing data are stored in
`/icse23/icse23-artifact-evaluation/table1/results`.

**Running GenSym**

```
# cd /icse23/icse23-artifact-evaluation/table1
# bash run_gensym.sh
```
This step compiles those benchmarks with GenSym, which generates code under
`/icse23/GenSym/gs_gen`, and further generates executable files.
The script then invokes the executables and performs the symbolic execution.
The execution log and raw timing data are stored in
`/icse23/icse23-artifact-evaluation/table1/results`.

**Running KLEE**

```
# cd /icse23/icse23-artifact-evaluation/table1
# bash run_klee.sh
```
This step uses KLEE to symbolically interpret those benchmarks and
generate test cases. The output and logs are stored in
`/icse23/icse23-artifact-evaluation/table1/results`.

**Summarizing Results**

Previous steps repeat each engine/benchmark five times and finally generate a `.csv`
file that contains timing data of LLSC, GenSym, and KLEE. We can then summarize the
results and calculate the speedups into a table (which should resembles Table I) by running,

```
# cd /icse23/icse23-artifact-evaluation/table1
# python3 show_table1.py
```

### RQ2

**Expected Time: 30 hours**

This part of the artifact aims to answer RQ2 by reproducing Table II. By running
GenSym and KLEE on the same Coreutils programs, we compare GenSym's performance
with interpretation-based engines. We use two sets of configurations: (1)
*short-running* configurations that have fewer symbolic inputs and will finish
in a few minutes, and (2) *long-running* configurations that have more symbolic
inputs and will timeout for an hour.

The result of *short-running* configurations corresponds to the upper half of
TABLE II, and *long-running* configurations to the lower half of
TABLE II.

**Preparation (~2.5 hours)**

To compile Coreutils benchmarks with GenSym, first we need to generate the C++ code
and the executables by running,
```
# cd /icse23/GenSym
# ./start_sbt
```

and then inside the `sbt` session,
```
sbt:GenSym> testOnly icse23.CompileCoreutilsPOSIX
```
This step invokes GenSym to compile Coreutils LLVM IR to C++ code and
then compile the C++ code to executables.
After the compilation, the C++ code and executables can be found in
`/icse23/GenSym/gs_gen`.

Since the generated code is large, this step may take a while depending
on how many CPU and memory resources are available.
The process of compiling generated C++ programs to executables (i.e. by `g++`) by
default uses half of the CPU cores (logical) in parallel.
For instance, if your machine has only 16 cores and 32GB memory, limiting the number of
parallel `g++` jobs no more than 8 is a good choice (which may take ~2.5
hours).

If you still experience out-of-memory in Docker, please try to decrease the
number of CPU cores (though this will lead to longer compilation time).
With more memory, you may increase the number of parallel `g++` jobs.

To override the default number of parallel `g++` jobs, you need to change the class `CompileCoreutilsPOSIX` in the file
`src/test/scala/icse23/CompileCoreutils.scala` with the `n` of cores you want to use,

```
override val cores: Option[Int] = Some(n)
```

and then re-run `testOnly icse23.CompileCoreutilsPOSIX` in `sbt`.

**Short-Running Benchmark (<1 hour)**

After compiling the executables, we first start the short-running task
(reproducing the upper part of Table II) which will finish within an hour by running,
```
# cd /icse23/icse23-artifact-evaluation/table2
# bash short_run.sh
```
Upon completion, the script will output a CSV file named `short-running.csv` under the `table2` directory.

`short-running.csv` contains the following statistics for both KLEE and GenSym,
```
path, line coverage, query time, solver time, execution time, whole time
```
additionally with "Execution time Speedup" and "Whole Time Speedup of GenSym
over KLEE".

**Long-Running Benchmark (26 hours)**

We can then run the long-running configurations to reproduce the lower part of Table II.
The long-running tasks take ~1 hour for each of the Coreutils programs on both
KLEE and GenSym, and we measure the throughput of each tool.
We will run 13 programs so the total running time is ~26 hours.

We recommend running this benchmark on a machine with *at least 128GB memory*.
The long-running benchmark of Table II reported in our paper is conducted on a
machine with four Intel Xeon 8168 CPUs and 3TB memory.
Using a machine with 32GB memory may result in fewer number of paths from KLEE or
killed processes of GenSym.

To launch the long-running benchmark, run,
```
# cd /icse23/icse23-artifact-evaluation/table2
# bash long_run.sh
```
Upon completion, the script will output a CSV file named `long-running.csv` under the `table2` directory.

`long-running.csv` contains the following statistics for both KLEE and GenSym,
```
path, line coverage, query time, solver time, execution time, whole time
```
additionally with "Path Throughput Ratio of GenSym over KLEE".

### RQ3

**Expected Time: (2 + 20 hours)**

This experiment evaluates the performance of GemSym's parallel execution (Table
III). The experiment consists of two parts: (1) parallel execution with
solver-chain optimizations enabled (left hand side of Table III), and (2)
parallel execution with solver-chain optimizations disabled (right hand side of
Table III).
The reason behind this is that the solver-chain optimizations are replicated in
each worker thread, leading to degraded parallel execution performance.
To evaluate the performance of our continuation-based parallel approach with
no overlapping work among the threads, we disable the solver-chain optimizations.
However, in a realistic scenario, the solver-chain optimizations are
always enabled.

For both parts of the experiment, we run 1/4/8/12 threads using
the short-running configuration of Coreutils benchmarks.

Before proceeding with this step, please make sure that you have already compiled all
Coreutils benchmarks with GenSym (i.e. running `testOnly
icse23.CompileCoreutilsPOSIX` in `sbt` from RQ2).

**Parallel Execution with Solver-Chain Optimizations Enabled (2 hours)**

To run this experiment with solver-chain optimizations enabled,

```
# cd /icse23/icse23-artifact-evaluation/table3
# bash run_with_opt.sh
```

After the experiment finishes, you can use the following command to generate the
left-hand side of Table III,

```
# python3 show_table.py result_opt.csv
```

Note: since this is a short-running experiment with optimizations on,
you may not observe significant speedups using 8 or 12 threads,
as single-thread execution can already be fast enough (e.g. less than 30 seconds).

**Parallel Execution with Solver-Chain Optimizations Disabled (20 hours+)**

To run this experiment with solver-chain optimizations disabled,

```
# cd /icse23/icse23-artifact-evaluation/table3
# bash run_wo_opt.sh
```

After the experiment finishes, you can use the following command to generate the
right-hand side of Table III,

```
# python3 show_table.py result_no_opt.csv
```

We could observe higher efficiency than that with optimizations enabled.

Note: `run_wo_opt.sh` by default will run each experiment only once to save time,
since each run may take >1 hour after disabling all solver-chain optimizations.
You may want to change the `iter_num` variable in the script to a larger number for more
statistically stable results.

**NUMA Machine Instruction**

If you are to run this experiment on a NUMA (non-uniform memory access) machine, you
may need to use additional tools to bind the threads to a NUMA node consistently
during its execution.
Otherwise, OS scheduler may move the threads to different NUMA
nodes, leading to poor performance and unfaithful comparison.
We provide two additional scripts if you are using a NUMA machine:

```
# cd /icse23/icse23-artifact-evaluation/table3
# bash run_with_opt_numa.sh // with solver chain optimizations
# bash run_wo_opt_numa.sh   // without solver chain optimizations
```

The scripts by default bind to the first NUMA node (`numactl -N0 -m0`).
You can change it by updating L96 of the scripts.

After running, you can use the same Python script to generate the table.

### RQ4 and RQ5

**Expected Time: ~5 hours (in 96-core parallel)**

This part of the artifact aims to answer RQ4 and RQ5 by producing Table IV. By
compiling the benchmarks in `/icse/GenSym/benchmarks/coreutils/separate` both
with and without optimizations, we are able to examine the compilation
cost and the effectiveness of our compile-time optimizations.
This step is performed under the separate compilation mode of GenSym: we process the
POSIX/uClibc library and Coreutils benchmarks separately and then link them
together.
Before starting, change the directory to `GenSym`'s root folder,

    cd /icse23/GenSym

**Preparation**

Preparing libraries for separate compilation resembles the steps compiling a
whole-program application. First, we use GenSym to generate code in C++, and second, we
compile the C++ code to executables. In the docker image, the first step has
been baked in to save your time; therefore it is *not* necessary to do it for the artifact
evaluation. To reproduce this step yourself, you may use (this may take more than 3
hours depending on your machine),

    /icse23/icse23-artifact-evaluation/table4/compilation_test.py prepare --no-build

With the C++ code generated, the next step is to generate the executable files, which is
*necessary* for the rest evaluation.
You should run the following command. You can specify `--make-cores <cores>` to
limit the CPU cores consumed. This step can take about >10 hours by a single
thread, around 10 minutes in our fully paralleled setting (96 physical cores):

    /icse23/icse23-artifact-evaluation/table4/compilation_test.py [--make-cores <cores>] prepare --no-codegen

To perform all the preparation steps from scratch at once (again this is *not*
necessary for the artifact evaluation since the first step has been done), you
may use,

    /icse23/icse23-artifact-evaluation/table4/compilation_test.py [--make-cores <cores>] prepare

**Execution**

After preparing the libraries, we can start the compilation benchmark. The
benchmark script will compile each application twice, with and without GenSym's compile-time
optimizations. For each compiled application, the following information will be
recorded,

- the time generating the C++ code (you may observe varied results from run to run due to the variabilities in JVM, while the results given by a single benchmark invocation should remain consistent and valid),
- the size (LOC) of generated C++ code, measured by `cloc`,
- the time building the C++ code in parallel, and
- the time executing the built application with the configuration in Table II (upper part).

The command we are using in this step is,

    /icse23/icse23-artifact-evaluation/table4/compilation_test.py [--make-cores <cores>] run [--repeat-num <num>] [--exclude <app> ...]

The most important options include,

- `--make-cores <cores>`, setting the cores used by parallel g++ compilation, defaulting
  to use all cores,
- `--repeat-num <num>`, setting the number of repetition for each step in the measurement,
  defaulting to 5, and
- `--exclude <app> ...`, specifying the applications not to include in the
  benchmark, separated by a whitespace, defaulting to `false` only.

To get a quick run of this experiment just for `base32`, you may use the
following command assuming you have a 16-core/32GB-memory machine:

    /icse23/icse23-artifact-evaluation/table4/compilation_test.py --make-cores 8 run --repeat-num 1 --exclude base64 cat comm cut dirname echo expand false fold join link paste pathchk true

The numbers reported in the paper uses 96 cores in this step, and testing each
application for one iteration takes roughly around 200 seconds, where there are
15 applications available for testing.
By the end of the benchmark, a LaTeX table will be printed on screen, containing
the results to Table IV in the paper. All reported numbers are based on the
median of all repetitions.

To fully reproduce Table IV with all cores available, you may use the following command,

    /icse23/icse23-artifact-evaluation/table4/compilation_test.py run

At the end of execution, the script will print a table similar to the one in the paper.

## 6. Try Your Own Programs

### Use GenSym's Interface

It is possible to use GenSym's interface to compile your own programs.
One way is to run GenSym's main function in `sbt`:

```
sbt:GenSym> runMain gensym.RunGenSym <ll-filepath> [--entrance=<string>] [--output=<string>] [--nSym=<int>] [--use-argv] [--noOpt] [--engine=<string>] [--main-O0]
```

Running `runMain gensym.RunGenSym --help` in `sbt` prints the help message.

### Built-in Test Cases

`/icse23/GenSym/src/test/scala/gensym/TestCases.scala` contains a number of test
cases that exercise GenSym and examine its correctness. To run the test cases,
run the following command in `sbt`:

```
sbt:GenSym> test
```

This test is also performed in the [Github CI pipeline](https://github.com/Generative-Program-Analysis/GenSym/actions).

### Generated Files

The generated C++ code are placed in `GenSym/gs_gen` with folder name
given in the `--output` option. Under the output folder, a `Makefile` is
provided to compile the generated C++ code.
Each LLVM IR function corresponds to a separate C++ file.

The compiled executable to perform the actual symbolic execution has the same
name as the output folder. There is a number of runtime options available
to tweak the process of symbolic execution. To see the available options,
run the executable with `--help`.
