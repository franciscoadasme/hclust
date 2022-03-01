import os
import timeit
import numpy as np
from scipy.cluster._hierarchy import mst_single_linkage

with open("distances.txt") as fp:
    size = int(next(fp))
    condensed_mat = np.zeros((size * (size - 1)) // 2)
    i = 0
    for line in fp:
        for token in line.split():
            condensed_mat[i] = float(token)

best_time = min(
    timeit.repeat("mst_single_linkage(condensed_mat, size)",
    number=1,
    repeat=int(os.getenv("BENCH_REPEATS", 10)),
    globals=dict(
            mst_single_linkage=mst_single_linkage,
            condensed_mat=condensed_mat,
            size=size,
        ),
    )
)

print(f"{best_time * 1000:.6f}")
