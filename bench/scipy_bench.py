import os
import time
import numpy as np
from scipy.cluster.hierarchy import _LINKAGE_METHODS
from scipy.cluster._hierarchy import mst_single_linkage, nn_chain

size = int(os.getenv("BENCH_SIZE", 100))
condensed_size = (size * (size - 1)) // 2
repeats = int(os.getenv("BENCH_REPEATS", 1_000))

best_time = float("inf")
for _ in range(repeats):
    condensed_dism = np.random.rand(condensed_size)
    starttime = time.perf_counter()
    nn_chain(condensed_dism, size, _LINKAGE_METHODS["ward"])
    elapsed = time.perf_counter() - starttime
    best_time = min(best_time, elapsed)

print(f"{best_time * 1000:.6f}")
