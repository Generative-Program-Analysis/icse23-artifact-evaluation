cd /icse23/llsc/dev-clean

sbt "runMain sai.llsc.RunLLSC /icse23/GenSym/benchmarks/icse23/algorithms/mergesort_llsc.ll mergeSortTest @main"
cd llsc_gen/mergeSortTest
make -j4
./mergeSortTest 1
cd ../..

sbt "runMain sai.llsc.RunLLSC /icse23/GenSym/benchmarks/icse23/algorithms/nqueen_llsc.ll nqueenTest @main"
cd llsc_gen/nqueenTest
make -j4
./nqueenTest 1
cd ../..

sbt "runMain sai.llsc.RunLLSC /icse23/GenSym/benchmarks/icse23/algorithms/kmpmatcher_llsc.ll kmpmatcherTest @main"
cd llsc_gen/kmpmatcherTest
make -j4
./kmpmatcherTest 1
cd ../..

sbt "runMain sai.llsc.RunLLSC /icse23/GenSym/benchmarks/icse23/algorithms/knapsack_llsc.ll knapsackTest @main"
cd llsc_gen/knapsackTest
make -j4
./knapsackTest 1
cd ../..

sbt "runMain sai.llsc.RunLLSC /icse23/GenSym/benchmarks/icse23/algorithms/bubblesort_llsc.ll bubblesortTest @main"
cd llsc_gen/bubblesortTest
make -j4
./bubblesortTest 1
cd ../..

sbt "runMain sai.llsc.RunLLSC /icse23/GenSym/benchmarks/icse23/algorithms/quicksort_llsc.ll quicksortTest @main"
cd llsc_gen/quicksortTest
make -j4
./quicksortTest 1
