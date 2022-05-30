# A `UnionFind` is a data structure that stores a partition of a set
# into disjoint subsets encoded as contiguous zero-based indexes.
#
# This is a specialized implementation of a union–find data structure
# for linkage, where subsets correspond to cluster labels. It supports
# efficient lookups and frequent unions.
#
# Internally, it is implemented as an array of size `N + N - 1` such
# that each element points to the enclosing cluster label of the
# corresponding cluster. Disjoint clusters (root) are labeled with 0.
# Labels of the newly created clusters follows the SciPy convention,
# where new labels start at N.
class HClust::UnionFind
  # Creates a new `UnionFind` with the cluster labels in the range `[0,
  # size * size - 1)`.
  def initialize(size : Int32)
    # A map from cluster label to its parent. If zero, the cluster is
    # considered a root or disjoint.
    @parents = size > 0 ? Array(Int32).new(2 * size - 1, 0) : [] of Int32
    # The cluster label upon next union. Follows the SciPy convention,
    # where new labels start at N.
    @next_parent = size.to_i
  end

  # Returns the root cluster for the given cluster label, or `nil` if
  # out of bounds.
  #
  # Iteratively goes through all parent elements until a root (parent =
  # 0) is found. To make subsequent lookups faster, the label for the
  # given cluster and all its parents is updated with the found root
  # element.
  def find(index : Int) : Int32?
    return unless 0 <= index < @next_parent
    parent = index
    until (p = @parents[parent]).zero?
      parent = p
    end

    # trick to speed up subsequent calls
    until (p = @parents[index]).zero?
      @parents[index] = parent
      index = p
    end

    parent
  end

  # Joins two clusters with the given labels and returns the label of
  # the newly created cluster, or `nil` if the two clusters are already
  # joined. Raises `IndexError` if either *i* or *j* is out of bounds.
  #
  # If the two clusters belongs to the same parent cluster, this method
  # does nothing.
  def union(i : Int, j : Int) : Int32?
    raise IndexError.new unless i < @next_parent && j < @next_parent
    return if find(i) == find(j) # skip if already joined
    raise "BUG: unreachable" unless @next_parent < @parents.size
    @parents[i] = @parents[j] = @next_parent
    @next_parent += 1
    @parents[i]
  end
end
