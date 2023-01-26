# This script tests GenSym with algorithm benchmarks.

# Change this if need to run the executable mutiple times
N=5

# repeat(inputFile, testName)
run () {
  sbt "runMain gensym.RunGenSym /icse23/GenSym/benchmarks/icse23/algorithms/$1 --entrance=main --output=$2 --main-opt=O3"
  cd gs_gen/$2
  make -j4
  for ((i=1; i<=$N; i++))
  do
    echo "running" $2 [$i]
    ./$2 --solver=z3 > /icse23/icse23-artifact-evaluation/table1/result/gensym-$2-$i.log
    echo ""
  done
}

mkdir -p /icse23/icse23-artifact-evaluation/table1/result
cd /icse23/GenSym

sbt "runMain gensym.GenerateExternal"

run "mergesort.ll" "mergeSortTest"
cd ../..

run "nqueen.ll" "nqueenTest"
cd ../..

run "kmpmatcher.ll" "kmpmatcherTest"
cd ../..

run "knapsack.ll" "knapsackTest"
cd ../..

run "bubblesort.ll" "bubblesortTest"
cd ../..

run "quicksort.ll" "quicksortTest"
cd ../..

cd /icse23/icse23-artifact-evaluation/table1
python gensym_collect.py $N >> table1.csv
