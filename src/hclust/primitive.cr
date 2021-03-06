# Perform hierarchical clustering based on the distances stored in
# *dism* using the classic algorithm with the given linkage rule.
#
# The classic or primitive algorithm iteratively finds a pair of
# clusters that are nearest neighbors of each other, which are merged
# into a new cluster. Then, the distances stored in *dism* are updated
# by computing the distances to the newly-created cluster according to
# the linkage rule. The procedure is repeated for *N* - 1 times, where
# *N* is the number of elements or observations. Since all pairwise
# distances are searched in each iteration, the time complexity of this
# algorithm is Θ(*N*³).
#
# This algorithm can deal with inversions in the dendrogram, so it can
# be used with any linkage rule including `Rule::Centroid` and
# `Rule::Median`.
#
# The merge steps are encoded as an unordered `Dendrogram`, which is
# sorted prior to be returned.
#
# The current implementation is described in section 2.4 of the
# Müllner's article [[1]](https://arxiv.org/abs/1109.2378).
#
# WARNING: This method is painfully slow and should not be used for
# production. It is only used as reference to test other methods. Prefer
# to use the `.linkage` method since it provides a general interface and
# picks the best algorithm depending on the linkage rule.
def HClust.primitive(dism : DistanceMatrix, rule : Rule) : Dendrogram
  dism.map! &.**(2) if rule.needs_squared_euclidean?

  active_nodes = IndexList.new(dism.size)    # tracks non-merged clusters
  sizes = Pointer(Int32).malloc dism.size, 1 # cluster sizes

  dendrogram = Dendrogram.new(dism.size)
  (dism.size - 1).times do
    step = next_merge(active_nodes, dism)

    {% begin %}
      case rule
      {% for rule in HClust::Rule.constants.map(&.id.downcase) %}
        in .{{rule}}?
          update_distances_{{rule}}(active_nodes, dism, sizes, *step.clusters)
      {% end %}
      end
    {% end %}

    sizes[step.clusters[1]] += sizes[step.clusters[0]]
    active_nodes.delete step.clusters[0] # remove smallest cluster
    step = step.sqrt if rule.needs_squared_euclidean?
    dendrogram << step
  end
  dendrogram.relabel(ordered: !rule.order_dependent?)
end

# Searches and returns the next pair of nearest clusters using brute
# force.
private def next_merge(active_nodes, dism)
  c_i = active_nodes.first? || raise "BUG: unreachable"
  c_j = active_nodes.unsafe_succ(c_i)
  d_ij = dism.unsafe_fetch(c_i, c_j)
  raise "BUG: unreachable" if c_j == 0
  active_nodes.each do |c_k|
    active_nodes.each(within: c_k.., skip: 1) do |c_m|
      dis = dism.unsafe_fetch(c_k, c_m)
      c_i, c_j, d_ij = c_k, c_m, dis if dis < d_ij
    end
  end
  HClust::Dendrogram::Step.new(c_i, c_j, d_ij)
end

{% for rule in HClust::Rule.constants.map(&.id.downcase) %}
  # Updates the distances upon merging clusters *i* and *j*. In each
  # iteration, it calls the parameterized method *L* along with the
  # pointer to the distance between nodes *j* and *k* in the distance
  # matrix (`ptr_jk`) to be updated.
  private def update_distances_{{rule}}(active_nodes, dism, sizes, c_i, c_j)
    n_i = sizes[c_i]
    n_j = sizes[c_j]
    d_ij = dism.unsafe_fetch(c_i, c_j)

    # iterate over the indexes in three stages to ensure row < column
    # when fetching a value from the distance matrix
    active_nodes.each(within: ...c_i) do |c_k|
      d_ik = dism.unsafe_fetch(c_k, c_i)
      HClust::Rule.{{rule}} d_ij, d_ik, dism.to_unsafe(c_k, c_j), n_i, n_j, sizes[c_k]
    end

    active_nodes.each(within: c_i...c_j, skip: 1) do |c_k|
      d_ik = dism.unsafe_fetch(c_i, c_k)
      HClust::Rule.{{rule}} d_ij, d_ik, dism.to_unsafe(c_k, c_j), n_i, n_j, sizes[c_k]
    end

    active_nodes.each(within: c_j.., skip: 1) do |c_k|
      d_ik = dism.unsafe_fetch(c_i, c_k)
      HClust::Rule.{{rule}} d_ij, d_ik, dism.to_unsafe(c_j, c_k), n_i, n_j, sizes[c_k]
    end
  end
{% end %}
