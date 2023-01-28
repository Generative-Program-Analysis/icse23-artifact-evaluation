# Compiling Parallel Symbolic Execution with Continuations (Artifact)

This document is the instruction for the ICSE 2023 artifact evaluation for
paper *Compiling Parallel Symbolic Execution with Continuations*.
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
    - [RQ4](#rq4)
    - [RQ5 and RQ6](#rq5-and-rq6)
  - [Try Your Own Programs](#try-your-own-programs)
    - [Built-in Test Cases](#built-in-test-cases)
    - [Use GenSym's Interface](#use-gensyms-interface)
    - [Generated Files](#generated-files)

<!-- /TOC -->

## 1. Obtaining the Artifact

The artifact is available as a pre-built Docker image, which has all
dependencies and third-party tools installed.

To obtain the Docker image (you may need root privilege to run `docker`):

TODO: update the image tag `dev` -> `icse23`

```
$ docker pull guannanwei/gensym:icse23
```

### Start the Docker Container

Then to instantiate the Docker image, run the following command:

```
docker run --name <container_name> --ulimit='stack=-1:-1' -it guannanwei/gensym:icse23 bash
```

Then we should be able to see the prompt of `bash`.
All experiments are conducted within the Docker container.

In case there are up-stream changes of the artifact, once the container is
started you can run the following command to sync up (which is suggested):
```
# cd /icse23
# bash sync.sh
```

Once running inside the Docker, you can also find this document
at `/icse23/icse23-artifact-evaluation/README.md`.

### Build the Docker Image

The scripts used to build the Docker image can be found at
`/icse23/GenSym/docker-image/Dockerfile` and
`/icse23/GenSym/docker-image/init_script.sh`.
Using these scripts, one can rebuild the Docker image from scratch by
running given a tag name:
```
$ cd /icse23/GenSym/docker-image
$ docker build -t <image-tag-name> .
```
It is *not* necessary for the artifact evaluation to rebuild the image,
but might be useful for anyone who would like to reuse or deploy GenSym.

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
versions are specified in `/icse23/GenSym/build.sbt`.
GenSym's backend uses a few C++ data structures libraries, including
[immer](https://github.com/arximboldi/immer) and [parallel-hashmap](https://github.com/greg7mdp/parallel-hashmap) (exact version dependencies specified in `.gitmodules`).

Other system-wide installed third-party libraries and dependencies used
in the artifact include

- Z3 4.8.12
- STP (SMTCOMP2020 release)
- g++ 9.40
- clang/clang++/LLVM 11
- Java Virtual Machine 8
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

## 3. Hardware Requirements

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


## 4. Kick-the-Tires

**Expected Time: 15 minutes**

In this Kick-the-Tires step, we make a basic sanity check of the whole compilation pipeline.
We use a simple branching program as example and explain the pipeline.

The first preparation step is to generate GenSym's external models.
These models simulate symbolic behaviors of external functions, such as
the POSIX file system.
GenSym defines models for external functions in a Scala DSL, which will be
generated to C++ functions that can be used together with the compiled
application code.
To do this, we start an interactive `sbt` session by running
(`start_sbt` sets necessary parameters for JVM and invokes `sbt`):

```
# cd /icse23/GenSym
# ./start_sbt
```

Then we run the following command in the `sbt` session to generate models for external functions

```
sbt:GenSym> runMain gensym.GenerateExternal
```

The first time running `sbt` downloads dependencies specified in `build.sbt` and
compiles the Scala code to JVM bytecode, which may take a few minutes.
After printing some compilation log, we should see `[success]` in the output.
This generates a C++ file `/icse23/GenSym/headers/gensym/external.hpp`.

TODO: disable logging

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
Then we can exit sbt.  The generated C++ program and tests are located in
`/icse23/GenSym/gs_gen/ImpCPSGS_branch1` for further inspection.

## 4. Benchmarks Description

The paper uses two groups of benchmarks: (1) algorithm programs with finite
numbers of paths, and (2) a subset of GNU Coreutils (v8.32) programs that have interaction
with OS file system and command line interface.

We use the algorithm benchmarks in Table I, whose C source code and LLVM IR can
be found in `/icse23/GenSym/benchmarks/icse23/algorithms`.

We use the Coreutils benchmarks in the rest of experiments, including Table {II,
III, IV, V}.
Their LLVM IR can be found in `/icse23/GenSym/benchmarks/icse23/coreutils`.
The C source code of Coreutils are included in the artifact under
`/icse23/coreutils-src`.
The `gcov`-instrumented Coreutils programs are included in the artifact under
`/icse23/coreutils-src/obj-gcov/src`.
The generation of Coreutils LLVM IR from their C source code is not
part of the artifact, but can be found in a [separate document](https://github.com/Generative-Program-Analysis/coreutils-testing-instruction) we
prepared.

Further more, these Coreutils benchmarks can be used with different input
configurations. The paper uses two configurations: (1) *short-running*
configurations that have smaller number of symbolic inputs and can be
symbolically executed in a few minutes, and (2) *long-running*
configurations that have more number of symbolic inputs and take much
longer time to test.

Both GenSym and KLEE can finish the short-running configuration benchmarks,
and they explore the same set of paths. Therefore we can compare the performance
based on the same workload.
The long-running configuration benchmarks are used to evaluate the scalability.
Both engines time out at 1 hour, and then we can compare the throughput,
i.e. the number of paths they explore per second (assuming that paths are homogeneous).

More specifically, the long-running configuration of Coreutils programs
are used in the *lower part* of Table II for RQ2.
All other experiments including the upper part of Table II, Table III, Table IV, and Table V
all uses the short-running configuration.

## 5. Evaluation Instructions

### RQ1

**Expected Time: 30 minutes**

This experiment answers RQ1 and generates Table I of the paper.  We will first
examine the benchmarks, and then run the experiment using LLSC, GenSym, and
KLEE, and finally generate the digested results.

**Examining Benchmarks**

The set of benchmarks for RQ1 are located in `/icse23/GenSym/benchmarks/icse23/algorithms`.
Both C source code and LLVM IR of them are already included.
The `.ll` files are used by GenSym and LLSC, and `.bc` files are used for KLEE, since
they link with different engine-specific APIs.
A `Makefile` is accompanied with these benchmarks, so a user can modify the program
and produce different test cases using the same process.

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
This steps compiles those benchmarks with LLSC, which generates code under
`/icse23/llsc/dev-clean/llsc_gen`, and further generate executable files.
The script will also invoke the executable and perform the symbolic execution.
The execution log and raw timing data are stored in
`/icse23/icse23-artifact-evaluation/table1/results`.

**Running GenSym**

```
# cd /icse23/icse23-artifact-evaluation/table1
# bash run_gensym.sh
```
This steps compiles those benchmarks with GenSym, which generates code under
`/icse23/GenSym/gs_gen`, and further generate executable files.
The script will also invoke the executable and perform the symbolic execution.
The execution log and raw timing data are stored in
`/icse23/icse23-artifact-evaluation/table1/results`.

**Running KLEE**

```
# cd /icse23/icse23-artifact-evaluation/table1
# bash run_klee.sh
```

**Summarizing Results**

Previous steps also generate a .csv file that contains timing data
of LLSC, GenSym, and KLEE. We then summarize the results and calculate the
speedups into a table by running:

```
# cd /icse23/icse23-artifact-evaluation/table1
# python3 show_table1.py
```

### RQ2

**Expected Time: 30 hours**

This part of the artifact aims to answer RQ2 by producing Table II. By running GenSym and KLEE on the same Coreutils programs, we can validate GenSym's correctness and performance. We use two sets of configurations: (1) *short-running* configurations that have small symbolic inputs that will finish in minutes, and (2) *long-running* configurations that have large symbolic inputs and will timeout for 1hr.

*short-running* configurations correspond to the upper half of TABLE II, *long-running* configurations correspond to the lower half of TABLE II.

**Preparation: ~2.5 hours**

The process of compiling generated C++ programs to executable uses half of the
CPU cores (both physical and logical) by default.
If you only have 32GB memory, limiting the the number of parallel `g++` instances
no more than 8 is a good choice.
If you still experience out-of-memory in Docker, please try to decrease the
number of CPU cores.
With more memory, you may increase the number of parallel `g++` instances.

To compile Coreutils benchmarks with GenSym, we first need to generate the C++ code
and the executables by running:
```
# cd /icse23/GenSym
# ./start_sbt
```

Inside the sbt terminal, run:
```
sbt:GenSym> runMain gensym.GenerateExternal
sbt:GenSym> testOnly icse23.CompileCoreutilsPOSIX
```
The C++ code and executables can be found at `/icse23/GenSym/gs_gen`.


**Short-Running Benchmark: <1 hour**

After compiling the executables, we first start the short-running task which will finish within 1 hour by running:
```
# cd /icse23/icse23-artifact-evaluation/table2
# bash short_run.sh
```
Upon completion, the script will output a csv file named `short-running.csv` under the `table2` directory.

The `short-running.csv` contains the following statistic for both KLEE and GenSym:
```
path, line coverage, query time, solver time, execution time, whole time
```
With the Execution time Speedup and Whole time Speedup of GenSym over KLEE.

**Long-Running Benchmark: 26 hours**

We can start the long-running task which will run about 1 hour for each Coreutils program on both KLEE and GenSym. We will run 13 programs so the total running time is ~26 hours.

The long-running benchmark of TABLE II reported in our paper is conducted on a machine with 4 Intel Xeon 8168 CPUs and 3TB memory.Running this benchmark on 32GB machine will result in fewer path number due to memory limit.

To launch the long-running benchmark, run:
```
# cd /icse23/icse23-artifact-evaluation/table2
# bash long_run.sh
```
Upon completion, the script will output a csv file named `long-running.csv` under the `table2` directory.

The `long-running.csv` contains the following statistic for both KLEE and GenSym:
```
path, line coverage, query time, solver time, execution time, whole time
```
With the Path Throughput of GenSym over KLEE.

### RQ3

TODO: mention this in RQ2
The process of compiling generated C++ programs to executable uses half of the
CPU cores (both physical and logical) by default.
If you only have 32GB memory, limiting the the number of parallel `g++` instances
no more than 8 is a good choice.
If you still experience out-of-memory in Docker, please try to decrease the
number of CPU cores.
With more memory, you may increase the number of parallel `g++` instances.

**Expected Time:**

table 3
This experiment evaluates the performance of GemSym's parallel execution (Table III).

numactl

### RQ4

**Expected Time: 3 hours**

**Running the Experiment**

```
# cd /icse23/icse23-artifact-evaluation/table4
# bash RQ4.sh
```
This step compiles and run both the benchmarks compiled with KLEE's POSIX file system and our meta file system.
Upon completion, the script will output a csv file named `runtime.csv` under the `output` directory. The full logs for both versions can also be found under the `output` directory.

**Results**

This experiment answers RQ4 and generates Table IV of the paper.
The `runtime.csv` file generated by the script contains the following columns:
```
name,option,t-solver-ext,t-solver-int,t-exec,blocks,br,paths,threads,task-in-q,queries
```
The ones relevant are `name`, `t-solver-ext`, `t-solver-int`, and `t-exec`.
- `name` has the form of `h_<hash>_<prg>_<fs>`, where
  - the `<prg>` part denotes the name of the benchmark program (e.g. base32),
  - the `<fs>` part denotes whether it is the POSIX file system or our meta file system. "posix" denotes the POSIX file system, while "uclibc" denotes our meta file system.
- `t-solver-ext` and `t-solver-int` are external and internal solver time used by the program respectively. The T_Solver field in the paper is a sum of external and internal solver time.
- `t-exec` is the total execution time.


Also note that the `paths` column denotes the number of paths explored, which should be the same for the POSIX file system and our meta file system.

To view the output in a table, run `python3 tablize.py` under the `table4` directory.

### RQ5 and RQ6

**Expected Time: ~5 hours (in 96-core parallel)**

This part of the artifact aims to answer RQ5 and RQ6 by producing Table V. By
compiling the benchmarks in `/icse/GenSym/benchmarks/coreutils/separate` in both
with and without optimizations, we are able to examine about the compilation
cost and the effectiveness of our compile-time optimizations.
This step is performed under separate compilation mode of GenSym: we compile the
POSIX/uClibc library and Coreutils benchmarks separately and then link them
together.
Before starting, change the directory to `GenSym`'s root folder,

    cd /icse23/GenSym

**Preparation**

Preparing libraries for separate compilation resembles the steps compiling an
whole-program application. First, we use GenSym to generate code in C++, and second, we
compile the C++ code to executables. In the docker image, the first step has
been baked in to save your time; therefore it is *not* necessary to do it for the artifact
evaluation. To reproduce this step yourself, you may use (this may take more than 3
hours depending on your machine),

    /icse23/icse23-artifact-evaluation/table5/compilation_test.py prepare --no-build

With the C++ code generated, the next step is to generate the executable file, which is
*necessary* for the rest evaluation.
You should run the following command. You can specify `--make-cores <cores>` to
limit the CPU cores consumed. This step can take about >10 hours by a single
thread, around 10 minutes in our fully paralleled setting (96 physical cores):

    /icse23/icse23-artifact-evaluation/table5/compilation_test.py [--make-cores <cores>] prepare --no-codegen

To perform all the preparation steps from scratch at once (again this is *not*
necessary for the artifact evaluation since the first step has been done), you
may use,

    /icse23/icse23-artifact-evaluation/table5/compilation_test.py [--make-cores <cores>] prepare

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

    /icse23/icse23-artifact-evaluation/table5/compilation_test.py [--make-cores <cores>] run [--repeat-num <num>] [--exclude <app> ...]

The most important options include,

- `--make-cores <cores>`, setting the cores used by parallel g++ compilation, defaulting
  to use all cores,
- `--repeat-num <num>`, setting the number of repetition for each step in the measurement,
  defaulting to 5, and
- `--exclude <app> ...`, specifying the applications not to include in the
  benchmark, separated by a whitespace, defaulting to `false` only.

To get a quick run of this experiment just for `base32`, you may use the
following command assuming you have a 16-core/32GB-memory machine:

    /icse23/icse23-artifact-evaluation/table5/compilation_test.py --make-cores 8 run --repeat-num 1 --exclude base64 cat comm cut dirname echo expand false fold join link paste pathchk true

The numbers reported in the paper uses 96 cores in this step, and testing each
application for one iteration takes roughly around 200 seconds, where there are
15 applications available for testing.
By the end of the benchmark, a LaTeX table will be printed on screen, containing
the results to Table V in the paper. All reported numbers are based on the
median of all repetitions.

To fully reproduce Table V with all cores available, you may use the following command,

    /icse23/icse23-artifact-evaluation/table5/compilation_test.py run

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
to see those options, run the executable with `--help` option.
