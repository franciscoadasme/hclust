# Fast hierarchical clustering algorithms in pure Crystal

[![Made with Crystal](https://img.shields.io/badge/Made%20with-Crystal-1f425f.svg?logo=crystal)](https://crystal-lang.org)
[![CI status](https://img.shields.io/github/workflow/status/franciscoadasme/hclust/CI)](https://github.com/franciscoadasme/hclust/actions?query=workflow:CI)
[![Docs status](https://img.shields.io/github/workflow/status/franciscoadasme/hclust/Deploy%20docs?label=docs)](https://franciscoadasme.github.io/hclust)
[![Version](https://img.shields.io/github/v/release/franciscoadasme/hclust?label=version)](https://github.com/franciscoadasme/hclust/releases/latest)
[![License](https://img.shields.io/github/license/franciscoadasme/hclust)](https://github.com/franciscoadasme/hclust/blob/master/LICENSE)

This shard provides types and methods for fast hierarchical agglomerative
clustering featuring efficient linkage algorithms.

The current implementation is heavily based on the work of Daniel Müllner [[1]]
and derived from Müllner's own implementation found in the [fastcluster] C++
library [[2]], and parts of the implementation were also inspired by the
[kodama] Rust crate (code for updating distances) and [SciPy] Python library
(code for generating flat clusters).

The runtime performance of this library is on par with the reference implementations (see [benchmark](#benchmark)).

The most relevant types and methods for practical usage are the
following:

- `.cluster` performs hierarchical clustering of a set of elements using the
  pairwise dissimilarities returned by the given block.
- `.linkage` performs hierarchical clustering based on a pairwise
  `DistanceMatrix` returning a `Dendrogram` as output.
- `Rule` is an enum that determines the linkage criterion or rule.
- `Dendrogram` represents a step-wise dendrogram that encodes the
  hierarchy of clusters obtained from hierarchical clustering.
- `Dendrogram#flatten` returns a list of flat clusters.

The available linkage rules are:

- Average or UPGMA method.
- Centroid or UPGMC method.
- Complete or farthest neighbor method.
- Median or WPGMC method.
- Single or nearest neighbor method.
- Ward's minimum variance method
- Weighted or WPGMA method.

This library is released under the MIT license.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     hclust:
       github: franciscoadasme/hclust
   ```

2. Run `shards install`

## Usage

First define the data points to be clustered:

```crystal
coords = [
  [-0.30818828, 2.70462841, 1.84344886],
  [2.9666203, -1.39874721, 4.76223947],
  [3.21737027, 4.09489028, -4.60403434],
  [-3.51140292, -0.83953645, 2.31887739],
  [2.08457843, 4.24960773, -3.91378835],
  [2.88992367, -0.97659082, 0.75464131],
  [0.43808545, 3.70042294, 4.99126146],
  [-1.71676206, 4.93399583, 0.27392482],
  [1.12130963, -1.09646418, 1.45833231],
  [-3.45524705, 0.92812111, 0.15155981],
]
labels = (0...coords.size).to_a # for demonstration purposes

# dissimilarity metric
def euclidean(u, v)
  Math.sqrt (0...u.size).sum { |i| ([i] - v[i])**2 }
end
```

The easiest way is to use the convenience method `.cluster`. The following code
will cluster the data points into groups based on the Euclidean distance with a
distance cutoff of 4 using the single linkage (default so can be omitted):

```crystal
require "hclust"

clusters = HClust.cluster(labels, 4, :single) { |i, j|
  euclidean(coords[i], coords[j])
}
clusters.size # => 3
clusters      # => [[0, 3, 6, 7, 9], [1, 5, 8], [2, 4]]
```

Use the `into:` named argument to limit the number of clusters:

```crystal
clusters = HClust.cluster(labels, into: 2) { |i, j|
  euclidean(coords[i], coords[j])
}
clusters.size # => 2
clusters      # => [[0, 1, 3, 5, 6, 7, 8, 9], [2, 4]]
```

Alternatively, the procedure can be replicated by doing each step manually:

```crystal
dism = DistanceMatrix.new(coords.size) { |i, j|
  euclidean(coords[i], coords[j])
}
dendrogram = linkage(dism, :single)
clusters = dendrogram.flatten(height: 4)
clusters.size # => 2
clusters      # => [[0, 1, 3, 5, 6, 7, 8, 9], [2, 4]]
```

The latter can be useful to avoid recomputing the recomputing the
dissimilarities when testing different clustering arguments, or obtaining the
dendrogram can be useful for visual inspection.

Refer to the [API documentation] for further details.

## Benchmark

A Bash script is used to benchmark the code and be compared against reference implementations. 

The script downloads the required libraries (except for SciPy) to run the
corresponding code. The following programs are expected to be available: `gcc`
for C++, `cargo` for Rust, and `python` for Python (SciPy must be installed in
the current Python environment). Each benchmark will run for a number of times,
and the best time will be printed out.

The following output was obtained on a machine with AMD® Ryzen 9 5950x under
Pop!_OS 22.04 LTS using default benchmark values (see below):

```text
$ bash bench/bench.sh
Testing Fastcluster (C++)...
Testing Kodama (Rust)...
Testing Scipy (Python)...
Testing HClust (Crystal)...
| name         | version | compiler     | time (ms) |
| ------------ | ------- | ------------ | --------- |
| fastcluster  | 1.2.6   | 11.2.0 (gcc) |     0.032 |
| kodama       | 0.2.3   | 1.61.0       |     0.041 |
| scipy        | 1.7.3   | 3.9.12       |     0.094 |
| hclust       | 0.1.0   | 1.4.1        |     0.067 |
```

The benchmark can be configured via the following environment variables:

- `BENCH_SIZE` sets the number of data points to bench (defaults to 100).
- `BENCH_REPEATS` sets the number of times to repeat the code during benchmark
  (defaults to 1000).
- `BENCH_RULE` sets the linkage rule to run: `average`, `centroid`, `complete`,
  `median`, `single`, `ward` (default), or `weighted`.
- `BENCH_METHOD` sets the clustering method to run: `mst`, `chain`, or `generic`
  (default).

## Contributing

1. Fork it (<https://github.com/franciscoadasme/hclust/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Francisco Adasme](https://github.com/franciscoadasme) - creator and maintainer

[1]: https://arxiv.org/abs/1109.2378
[2]: https://doi.org/10.18637/jss.v053.i09
[API documentation]: https://franciscoadasme.github.io/hclust
[fastcluster]: https://github.com/dmuellner/fastcluster
[kodama]: https://github.com/diffeo/kodama
[SciPy]:
    https://docs.scipy.org/doc/scipy/reference/generated/scipy.cluster.hierarchy.fcluster.html