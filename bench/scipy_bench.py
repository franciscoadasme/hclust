import os
import time
import numpy as np
from scipy.cluster.hierarchy import _LINKAGE_METHODS
from scipy.cluster._hierarchy import mst_single_linkage, nn_chain, fast_linkage

size = int(os.getenv("BENCH_SIZE", 100))
condensed_size = (size * (size - 1)) // 2
repeats = int(os.getenv("BENCH_REPEATS", 1_000))
rule = _LINKAGE_METHODS[os.getenv("BENCH_RULE", "ward")]
method = os.getenv("BENCH_METHOD", "generic")

best_time = float("inf")
for _ in range(repeats):
    condensed_dism = np.random.rand(condensed_size)
    starttime = time.perf_counter()
    if method == "mst":
        mst_single_linkage(condensed_dism, size)
    elif method == "chain":
        nn_chain(condensed_dism, size, rule)
    else: # generic
        fast_linkage(condensed_dism, size, rule)

    elapsed = time.perf_counter() - starttime
    best_time = min(best_time, elapsed)

print(f"{best_time * 1000:.6f}")
