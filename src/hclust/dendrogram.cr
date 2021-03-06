require "bit_array"

module HClust
  # A step-wise dendrogram that encodes the arrangement of the clusters
  # produced by hierarchical clustering as a binary tree.
  #
  # A dendrogram consists of a sequence of *N* - 1 merge steps (see
  # `Step`), where *N* is the number of elements or observations that
  # were clustered, and a step corresponds to a merge between two
  # distinct clusters.
  #
  # The labeling of the clusters follows the SciPy convention, where new
  # labels start at *N*:
  #
  # - If a cluster has a single element, the label would be the index of
  #   the element in the original sequence.
  # - If a cluster has more than one elements (two previous clusters
  #   were merged), the label would be *N* + *i*, where *i* is the index
  #   of the merge step that created it.
  #
  # Consequently, the labels of the newly created clusters ranges from
  # *N* to *N + N - 1*.
  class Dendrogram
    # Number of the original elements or observations that were
    # clustered.
    getter observations : Int32

    # Creates a new `Dendrogram` with the given number of original
    # elements or observations.
    def initialize(@observations : Int32)
      @steps = Array(Step).new(@observations - 1)
    end

    # Appends the given merge step. Raises `ArgumentError` if the
    # dendrogram is already full (contains `N - 1` steps).
    def <<(step : Step) : self
      raise ArgumentError.new("Dendrogram is full") unless @steps.size < @observations - 1
      @steps << step
      self
    end

    # Returns `true` if the merge steps are equal to `rhs`'s steps, else
    # `false`.
    def ==(rhs : self) : Bool
      return false if observations != rhs.observations
      @steps.each_with_index do |step, i|
        return false unless step == rhs.steps.unsafe_fetch(i)
      end
      true
    end

    # Creates and appends a merge step between clusters *c_i* and *c_j*
    # with the given distance.
    def add(c_i : Int32, c_j : Int32, distance : Float64) : Step
      step = Step.new(c_i, c_j, distance)
      @steps << step
      step
    end

    # Returns flat clusters of the original observations obtained by
    # cutting the dendrogram at *height* (cophenetic distance).
    def flatten(height : Number) : Array(Array(Int32))
      max_dists = max_dist_for_each_cluster(self)
      labels = cluster_monocrit(self, max_dists, height)
      (0...@observations).to_a.group_by { |i| labels[i] }.values
    end

    # Returns *count* or fewer flat clusters of the original
    # observations. Raises `ArgumentError` if *count* is negative or
    # zero.
    #
    # It internally computes the smallest height at which cutting the
    # dendrogram would generate *count* or fewer clusters, and then
    # flattens the dendrogram at the computed height.
    def flatten(*, count : Int) : Array(Array(Int32))
      raise ArgumentError.new("Negative or zero count") unless count > 0
      max_dists = max_dist_for_each_cluster(self)
      labels = cluster_maxclust_monocrit(self, max_dists, count)
      (0...@observations).to_a.group_by { |i| labels[i] }.values
    end

    # Returns a new `Dendrogram` with relabeled clusters. If *ordered*
    # is `true`, the dendrogram's steps will be sorted by the
    # dissimilarities first.
    #
    # Internally, it uses a `UnionFind` data structure for creating
    # merge steps with the new cluster labels efficiently.
    #
    # NOTE: Cluster labels will follow the SciPy convention, where new
    # clusters start at `N` with `N ` equal to the number of
    # observations (see `UnionFind`).
    def relabel(ordered : Bool = false) : self
      steps = @steps
      steps = steps.sort_by(&.distance) if ordered

      dendrogram = self.class.new @observations
      set = UnionFind.new @observations
      steps.each do |step|
        c_i = set.find(step.clusters[0]).not_nil! # node always exists
        c_j = set.find(step.clusters[1]).not_nil! # node always exists
        set.union c_i, c_j
        dendrogram.add c_i, c_j, step.distance
      end
      dendrogram
    end

    # Returns a view of the merge steps.
    def steps : Array::View(Step)
      @steps.view
    end
  end

  # A single merge step in a dendrogram.
  #
  # A step corresponds to a merge between two distinct clusters. By
  # convention, the indexes of the merged clusters (`#nodes`) are always
  # sorted.
  struct Dendrogram::Step
    # Indexes of the merged clusters. An index can range from 0 to *N +
    # N - 1*, where *N* is the number of original elements or
    # observations and an index equals to or greater than *N* indicates
    # a newly created cluster (refer to the `Dendrogram` documentation).
    getter clusters : Tuple(Int32, Int32)

    # Distance between the merged clusters. This is computed according
    # to the selected linkage rule (see `Rule`) used for the clustering.
    # If both merge clusters have a single element (singleton), the
    # distance is equal to the pairwise distance between the elements.
    getter distance : Float64

    # Creates a new *Step* between the clusters *c_i* and *c_j* with
    # the given distance.
    #
    # NOTE: Cluster indexes are stored sorted.
    def initialize(c_i : Int32, c_j : Int32, @distance : Float64)
      @clusters = c_i < c_j ? {c_i, c_j} : {c_j, c_i}
    end

    # Returns `true` if the step are equal, else `false`.
    #
    # NOTE: Distances are compared within numeric precision (epsilon =
    # 1e-15).
    def ==(rhs : self) : Bool
      @clusters == rhsclusters && (@distance - rhs.distance).abs <= Float64::EPSILON
    end

    # Returns a `Step` with the square root of the distance.
    def sqrt : self
      self.class.new *@clusters, Math.sqrt(@distance)
    end
  end
end

# Returns the labels of *max_count* or fewer flat clusters formed by
# monocrit criterion.
#
# It computes the smallest height at which cutting the dendrogram would
# generate *max_count* or fewer clusters, and then invokes
# `cluster_monocrit` with the computed height.
#
# Adapted from the `scipy.cluster._hierarchy` module.
private def cluster_maxclust_monocrit(
  dendrogram : HClust::Dendrogram,
  mc : Array(Float64),
  max_count : Int
) : Array(Int32)
  visited = BitArray.new(dendrogram.observations * 2 - 1)
  curr_node = Pointer(Int32).malloc(dendrogram.observations)
  threshold = 0.0

  lower_i = 0
  upper_i = dendrogram.observations - 1
  while upper_i - lower_i > 1
    i = (lower_i + upper_i) >> 1
    threshold = mc[i]

    visited.fill false
    count = k = 0
    curr_node[0] = 2 * dendrogram.observations - 2

    while k >= 0
      root = curr_node[k] - dendrogram.observations
      step = dendrogram.steps[root]
      c_i, c_j = step.clusters

      if mc[root] <= threshold # this subtree forms a cluster
        count += 1
        break if count > max_count
        k -= 1
        visited[c_i] = visited[c_j] = true
      elsif !visited[c_i]
        visited[c_i] = true
        if c_i >= dendrogram.observations
          k += 1
          curr_node[k] = c_i
        else # singleton cluster
          count += 1
          break if count > max_count
        end
      elsif !visited[c_j]
        visited[c_j] = true
        if c_j >= dendrogram.observations
          k += 1
          curr_node[k] = c_j
        else # singleton cluster
          count += 1
          break if count > max_count
        end
      else
        k -= 1
      end
    end

    if count > max_count
      lower_i = i
    else
      upper_i = i
    end
  end

  cluster_monocrit(dendrogram, mc, mc[upper_i])
end

# Returns the labels of flat clusters formed by monocrit criterion.
#
# Adapted from the `scipy.cluster._hierarchy` module.
private def cluster_monocrit(
  dendrogram : HClust::Dendrogram,
  mc : Array(Float64),
  cutoff : Number
) : Array(Int32)
  visited = BitArray.new(dendrogram.observations * 2 - 1)
  curr_node = Pointer(Int32).malloc(dendrogram.observations)
  count = 0

  k = 0
  cluster_leader = -1
  curr_node[0] = 2 * dendrogram.observations - 2
  labels = Array(Int32).new(dendrogram.observations, 0)
  while k >= 0
    root = curr_node[k] - dendrogram.observations
    step = dendrogram.steps[root]
    c_i, c_j = step.clusters

    if cluster_leader == -1 && mc[root] <= cutoff # found a cluster
      cluster_leader = root
      count += 1
    end

    if c_i >= dendrogram.observations && !visited[c_i]
      visited[c_i] = true
      k += 1
      curr_node[k] = c_i
    elsif c_j >= dendrogram.observations && !visited[c_j]
      visited[c_j] = true
      k += 1
      curr_node[k] = c_j
    else
      if c_i < dendrogram.observations
        count += 1 if cluster_leader == -1 # singleton cluster
        labels[c_i] = count
      end
      if c_j < dendrogram.observations
        count += 1 if cluster_leader == -1 # singleton cluster
        labels[c_j] = count
      end
      cluster_leader = -1 if cluster_leader == root # back to leader
      k -= 1
    end
  end
  labels
end

# Returns the maximum inconsistency coefficient for each non-singleton
# cluster.
#
# Adapted from the `scipy.cluster._hierarchy` module.
private def max_dist_for_each_cluster(
  dendrogram : HClust::Dendrogram
) : Array(Float64)
  visited = BitArray.new(dendrogram.observations * 2 - 1)
  curr_node = Pointer(Int32).malloc(dendrogram.observations)

  k = 0
  curr_node[0] = 2 * dendrogram.observations - 2
  max_dists = Array.new(dendrogram.observations, 0.0)
  while k >= 0
    root = curr_node[k] - dendrogram.observations
    step = dendrogram.steps[root]
    c_i, c_j = step.clusters

    if c_i >= dendrogram.observations && !visited[c_i]
      visited[c_i] = true
      k += 1
      curr_node[k] = c_i
    elsif c_j >= dendrogram.observations && !visited[c_j]
      visited[c_j] = true
      k += 1
      curr_node[k] = c_j
    else
      max_dist = step.distance
      if c_i >= dendrogram.observations
        max_i = max_dists[c_i - dendrogram.observations]
        max_dist = max_i if max_i > max_dist
      end
      if c_j >= dendrogram.observations
        max_j = max_dists[c_j - dendrogram.observations]
        max_dist = max_j if max_j > max_dist
      end
      max_dists[root] = max_dist
      k -= 1
    end
  end
  max_dists
end
