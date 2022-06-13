require "views"

# The `HClust` module provides methods for fast hierarchical
# agglomerative clustering featuring efficient linkage algorithms.
#
# Cluster analysis or [clustering] arrange a set of objects into
# distinct groups or clusters such that the elements within a cluster
# are more similar to each other than those in other clusters based on a
# given criterion. The latter is defined as a measure of dissimilarity
# between the objects, and it's usually encoded in a `DistanceMatrix`.
# Hierarchical agglomerative clustering builds a hierarchy of clusters,
# where each object or element starts in its own cluster, and then they
# are progressively merged forming a hierarchy among them. The
# dissimilarities bewteen a newly-created cluster and all other clusters
# are updated after each merging step. The dissimilarity between two
# clusters is dictated by the chosen linkage criterion or rule. The
# obtained hierarchy is often encoded as a `Dendrogram`, which can be
# cut at a given dissimilarity value to obtain flat clusters such that
# the elements of a flat cluster have a cophenetic distance no greater
# than the given value (see `Dendrogram#flatten`).
#
# The standard algorithm has a time complexity of Θ(*N*³), which is
# implemented by the `.primitive` method. However, optimal algorithms
# are provided based on the work of Daniel Müllner [[1]], which
# describes several optimizations over the standard algorithm
# (implemented by the `.generic` method), and fast methods for special
# cases such as the minimum spanning tree (MST) method (`.mst`) for
# single linkage and nearest-neighbor-chain (NN-chain) method
# (`.nn_chain`) for average, complete, Ward's, and weighted linkage.
# Thus, the best-case complexity can be reduced to Θ(*N*²), where, in
# practice, the runtime of the general case is close to this.
#
# The current implementation is heavily based on Müllner's own
# implementation found in the [fastcluster] C++ library, and parts of
# the implementation were also inspired by the [kodama] Rust crate (code
# for updating distances) and [SciPy] Python library (code for
# generating flat clusters).
#
# The most relevant types and methods for practical usage are the
# following:
#
# - `.cluster` performs hierarchical clustering of a set of elements
#   using the pairwise dissimilarities returned by the given block.
# - `.linkage` performs hierarchical clustering based on a pairwise
#   `DistanceMatrix` returning a `Dendrogram` as output.
# - `Rule` is an enum that determines the linkage criterion or rule.
# - `Dendrogram` represents a step-wise dendrogram that encodes the
#   hierarchy of clusters obtained from hierarchical clustering.
# - `Dendrogram#flatten` returns a list of flat clusters.
#
# The available linkage rules are:
#
# - `Rule::Average` or UPGMA method.
# - `Rule::Centroid` or UPGMC method.
# - `Rule::Complete` or farthest neighbor method.
# - `Rule::Median` or WPGMC method.
# - `Rule::Single` or nearest neighbor method.
# - `Rule::Ward`'s minimum variance method
# - `Rule::Weighted` or WPGMA method.
#
# See `Rule` documentation for details.
#
# ### Clustering example
#
# Let's first define a list of random coordinates in 3D space as an
# example case:
#
# ```
# coords = [
#   [-0.30818828, 2.70462841, 1.84344886],
#   [2.9666203, -1.39874721, 4.76223947],
#   [3.21737027, 4.09489028, -4.60403434],
#   [-3.51140292, -0.83953645, 2.31887739],
#   [2.08457843, 4.24960773, -3.91378835],
#   [2.88992367, -0.97659082, 0.75464131],
#   [0.43808545, 3.70042294, 4.99126146],
#   [-1.71676206, 4.93399583, 0.27392482],
#   [1.12130963, -1.09646418, 1.45833231],
#   [-3.45524705, 0.92812111, 0.15155981],
# ]
# labels = (0...coords.size).to_a # for demonstration purposes
# ```
#
# We'd like to group them by the proximity to each other defined by
# Euclidean distance:
#
# ```
# def euclidean(u, v)
#   Math.sqrt (0...u.size).sum { |i| (u[i] - v[i])**2 }
# end
# ```
#
# Let's say we want to split the coordinates into groups with a distance
# no more than 4. The easiest way is to use the `.cluster` convenience
# method:
#
# ```
# clusters = HClust.cluster(labels, 4) { |i, j| euclidean(coords[u], coords[v]) }
# clusters.size # => 3
# clusters      # => [[0, 3, 6, 7, 9], [1, 5, 8], [2, 4]]
# ```
#
# The method receives the elements to be clustered, a distance cutoff,
# and a block that receives two of the elements and must return the
# dissimilarity between them. We observe that the coordinates can be
# grouped into 3 distinct clusters containing 5, 3, and 2 elements,
# respectively. The order of the clusters is arbitrary and depends on
# the order of the elements.
#
# Alternatively, one can set the maximum number of clusters to be
# generated instead of a distance cutoff using the named argument
# `into:`:
#
# ```
# clusters = HClust.cluster(labels, into: 2) { |i, j| euclidean(coords[i], coords[j]) }
# clusters.size # => 2
# clusters      # => [[0, 1, 3, 5, 6, 7, 8, 9], [2, 4]]
# ```
#
# As stated above, the linkage rule dictates how the dissimilarities are
# updated upon merging two clusters during the clustering procedure.
# Therefore, the clustering output will depend on the selected rule. In
# turn, the choice of the linkage rule depends both on the problem
# domain and performance requirements. By default, the single linkage is
# used throughout the code but it can be given as the third (optional)
# argument to the cluster methods if required.
#
# ```
# clusters = HClust.cluster(labels, 2, :centroid) { |i, j|
#   euclidean(coords[i], coords[j])
# }
# clusters.size # => 5
# clusters      # => [[0, 7], [1, 5, 8], [2, 4], [3, 9], [6]]
# ```
#
# Note the different number of clusters and composition obtained with
# the centroid linkage comparted to the previous result using the single
# linkage.
#
# ### Advanced usage
#
# Using the `.cluster` methods is enough in most cases, albeit obtaining
# the dendrogram can be useful for visualization purposes or testing
# different clustering arguments without recomputing the
# dissimilarities.
#
# Under the hood, the `.cluster` methods construct a `DistanceMatrix`
# with the given block, invoke the `.linkage` method, and then call
# `Dendrogram#flatten` on the obtained dendrogram with the given
# argument. The latter returns an array of clusters, each containing a
# list of indexes that can be used to fetch the original elements. The
# equivalent code to the above example would be:
#
# ```
# dism = DistanceMatrix.new(coords.size) { |i, j| euclidean(coords[i], coords[j]) }
# dendrogram = linkage(dism)
# clusters = dendrogram.flatten(4)
# ```
#
# The dendrogram represents the hierarchy as a series of merge steps,
# which contain the merged clusters and computed dissimilarity. For
# instance, let's see what the dendrogram looks like:
#
# ```
# pp dendrogram.steps.map { |s| [s.clusters[0], s.clusters[1], s.distance, 0.0] }
# ```
#
# will print:
#
# ```text
# # cluster1, cluster2, dissimilarity, size (unused)
# [[2, 4, 1.3355127737375514, 0.0],
#  [5, 8, 1.9072352420201895, 0.0],
#  [3, 9, 2.7973259058854163, 0.0],
#  [0, 7, 3.068805125647255, 0.0],
#  [6, 13, 3.384856775520168, 0.0],
#  [1, 11, 3.796359969884454, 0.0],
#  [12, 14, 3.9902939298123274, 0.0],
#  [15, 16, 4.079225895869359, 0.0],
#  [10, 17, 5.696974476555648, 0.0]]
# ```
#
# The output can be copied into a Python terminal and visualized using
# the [dendrogram] function in [SciPy] or similar software. It would
# look something like:
#
# ```text
#   |       ________________
# 5 |      |                |
#   |      |                |
# 4 |      |         _______|_______
#   |      |      __|__         ____|___
# 3 |      |     |     |       |      __|__
#   |      |     |     |      _|_    |    _|_
# 2 |      |     |    _|_    |   |   |   |   |
#   |      |     |   |   |   |   |   |   |   |
# 1 |     _|_    |   |   |   |   |   |   |   |
#   |    |   |   |   |   |   |   |   |   |   |
# 0 |    2   4   1   5   8   3   9   6   0   7
# ```
#
# Using this graph, one can deduce the optimal cutoff for generating
# flat clusters, where a cutoff = 4 would produce indeed two clusters as
# shown above.
#
# [1]: https://arxiv.org/abs/1109.2378
# [clustering]: https://en.wikipedia.org/wiki/Cluster_analysis
# [fastcluster]: https://github.com/dmuellner/fastcluster
# [kodama]: https://github.com/diffeo/kodama
# [SciPy]:
#     https://docs.scipy.org/doc/scipy/reference/generated/scipy.cluster.hierarchy.fcluster.html
# [dendrogram]:
#     https://docs.scipy.org/doc/scipy/reference/generated/scipy.cluster.hierarchy.dendrogram.html
module HClust
end

require "./hclust/rule"
require "./hclust/**"
