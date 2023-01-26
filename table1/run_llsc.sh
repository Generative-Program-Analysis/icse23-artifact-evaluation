# This script tests LLSC with algorithm benchmarks.

# Change this if need to run the executable mutiple times
N=5

# repeat(inputFile, testName)
run () {
  sbt "runMain sai.llsc.RunLLSC /icse23/GenSym/benchmarks/icse23/algorithms/$1 $2 @main"
  cd llsc_gen/$2
  make -j4
  for ((i=1; i<=$N; i++))
  do
    echo "running" $2 [$i]
    ./$2 1 > /icse23/icse23-artifact-evaluation/table1/result/llsc-$2-$i.log
    echo ""
  done
}

mkdir -p /icse23/icse23-artifact-evaluation/table1/result
cd /icse23/llsc/dev-clean

run "mergesort_llsc.ll" "mergeSortTest"
cd ../..

run "kmpmatcher_llsc.ll" "kmpmatcherTest"
cd ../..

run "knapsack_llsc.ll" "knapsackTest"
cd ../..

run "bubblesort_llsc.ll" "bubblesortTest"
cd ../..

run "quicksort_llsc.ll" "quicksortTest"
cd ../..

cd /icse23/icse23-artifact-evaluation/table1
python llsc_collect.py $N >> table1.csv
