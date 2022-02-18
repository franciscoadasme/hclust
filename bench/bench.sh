#!/usr/bin/env bash

FASTCLUSTER_URL="https://raw.githubusercontent.com/dmuellner/fastcluster/master/src/fastcluster.cpp"
FASTCLUSTER_API_IRL="https://api.github.com/repos/dmuellner/fastcluster/releases/latest"
BENCH_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

abort() {
    >&2 echo "error: $1"
    exit 1
}

declare -A timings
declare -A package_versions
declare -A compilers

# fastcluster
gcc_version=$(gcc --version 2>/dev/null | head -n 1 | awk '{print $NF}')
[ $? -ne 0 ] && abort "gcc not available"
compilers[fastcluster]="$gcc_version (gcc)"

release_info=$(curl -H "Accept: application/vnd.github.v3+json" -s $FASTCLUSTER_API_IRL)
[ $? -ne 0 ] && abort "Could not fetch fastcluster repository information"
tag=$(echo "$release_info" | grep tag_name | awk '{print $2}' | sed 's/[v",]//g')
[ -z "$tag" ] && abort "Could not locate fastcluster repository"
package_versions[fastcluster]="$tag"

wget -q -O $BENCH_DIR/fastcluster_dm.cpp $FASTCLUSTER_URL \
    || abort "Could not download fastcluster.cpp from $FASTCLUSTER_URL"
gcc -O3 -o $BENCH_DIR/fastcluster_bench $BENCH_DIR/fastcluster_bench.cpp -lstdc++ 2>/dev/null \
    || abort "Compilation of fastcluster benchmark failed"
timings[fastcluster]=$($BENCH_DIR/fastcluster_bench)
[ $? -ne 0 ] && abort "Fastcluster (C++) benchmark failed"
rm $BENCH_DIR/fastcluster_dm.cpp $BENCH_DIR/fastcluster_bench || abort "Something went wrong"

# kodama
compilers[kodama]=$(cargo --version | awk '{print $2}')
[ $? -ne 0 ] && abort "rust not available"
workdir=$BENCH_DIR/kodama_bench
timings[kodama]=$(cd $workdir && cargo run --release 2>/dev/null)
[ $? -ne 0 ] && abort "Kodama (Rust) benchmark failed"
package_versions[kodama]=$(grep -A 1 'name = "kodama"' $workdir/Cargo.lock | grep version | awk '{print $3}' | sed 's/"//g')
(cd $workdir && cargo clean && rm Cargo.lock)

# scipy
compilers[scipy]=$(python --version | awk '{print $2}')
[ $? -ne 0 ] && abort "python not available"
package_versions[scipy]=$(python -c 'import scipy; print(scipy.__version__)')
[ $? -ne 0 ] && abort "scipy not available"
timings[scipy]=$(python $BENCH_DIR/scipy_bench.py)
[ $? -ne 0 ] && abort "Scipy (Python) benchmark failed"
rm -r $BENCH_DIR/__pycache__ 2>/dev/null

# hclust.cr
compilers[hclust]=$(crystal --version | head -n 1 | awk '{print $2}')
[ $? -ne 0 ] && abort "crystal not available"
package_versions[hclust]=$(shards version $BENCH_DIR/..)
timings[hclust]=$(crystal run --release $BENCH_DIR/hclust_bench.cr)
[ $? -ne 0 ] && abort "HClust (Crystal) benchmark failed"

echo "| name         | version | compiler     | time (ms) |"
echo "| ------------ | ------- | ------------ | --------- |"
for name in fastcluster kodama scipy hclust; do
    printf "| %-12s | %-7s | %-12s | %9.3f |\n" \
        "$name" \
        "${package_versions[$name]}" \
        "${compilers[$name]}" \
        ${timings[$name]}
done
