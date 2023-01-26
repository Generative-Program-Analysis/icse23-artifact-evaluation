# This script tests LLSC with algorithm benchmarks.

# Change this if need to run mutiple times (default=1)
N=1

repeat() {
for ((i=1; i<=$N; i++))
do
  echo $1 [$i]
  ./$1 1 > /icse23/icse23-artifact-evaluation/table1/result/llsc-$1-$i.log
  echo ""
done
}

cd /icse23/llsc/dev-clean
mkdir -p /icse23/icse23-artifact-evaluation/table1/result

sbt "runMain sai.llsc.RunLLSC /icse23/GenSym/benchmarks/icse23/algorithms/mergesort_llsc.ll mergeSortTest @main"
cd llsc_gen/mergeSortTest
make -j4
repeat "mergeSortTest"
cd ../..

sbt "runMain sai.llsc.RunLLSC /icse23/GenSym/benchmarks/icse23/algorithms/kmpmatcher_llsc.ll kmpmatcherTest @main"
cd llsc_gen/kmpmatcherTest
make -j4
repeat "kmpmatcherTest"
cd ../..

sbt "runMain sai.llsc.RunLLSC /icse23/GenSym/benchmarks/icse23/algorithms/knapsack_llsc.ll knapsackTest @main"
cd llsc_gen/knapsackTest
make -j4
repeat "knapsackTest"
cd ../..

sbt "runMain sai.llsc.RunLLSC /icse23/GenSym/benchmarks/icse23/algorithms/bubblesort_llsc.ll bubblesortTest @main"
cd llsc_gen/bubblesortTest
make -j4
repeat "bubblesortTest"
cd ../..

sbt "runMain sai.llsc.RunLLSC /icse23/GenSym/benchmarks/icse23/algorithms/quicksort_llsc.ll quicksortTest @main"
cd llsc_gen/quicksortTest
make -j4
repeat "quicksortTest"

python llsc_collect.py $N > table1.csv
