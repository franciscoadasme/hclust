# Perform hierarchical clustering based on the distances stored in
# *dism* using the nearest-neighbor-chain (NN-chain) algorithm with the
# given linkage rule.
#
# The NN-chain algorithm follows paths in the nearest neighbor graph of
# the clusters to find a pair of clusters that are nearest neighbors of
# each other, which are merged into a new cluster. The algorithm uses a
# stack data structure (`Deque`) to store the paths, which can lead to a
# speed up by re-using parts of the existing path efficiently.
#
# By definition, the NN-chain algorithm can only be used with the
# following linkage rules: `Rule::Single`, `Rule::Complete`,
# `Rule::Average`, `Rule::Weighted`, and `Rule::Ward`. Consequently,
# this method accepts a `ChainRule` enum (not `Rule`), which only
# contains these methods to ensure safety during compilation.
#
# The merge steps are encoded as an unordered `Dendrogram`, which is
# sorted prior to be returned.
#
# The current implementation is described in section 3.2 of the
# Müllner's article [[1]](https://arxiv.org/abs/1109.2378).
#
# NOTE: Prefer to use the `.linkage` method since it provides a general
# interface and picks the best algorithm depending on the linkage rule.
def HClust.nn_chain(dism : DistanceMatrix, rule : ChainRule) : Dendrogram
  rule = rule.to_rule
  dism.map! &.**(2) if rule.needs_squared_euclidean?

  active_nodes = IndexList.new(dism.size)    # tracks non-merged clusters
  sizes = Pointer(Int32).malloc dism.size, 1 # cluster sizes
  chain = Deque(Int32).new(dism.size)        # nearest neighbor chain

  dendrogram = Dendrogram.new(dism.size)
  (dism.size - 1).times do
    step = next_merge(active_nodes, dism, chain)

    {% begin %}
      case rule
      {% for rule in HClust::ChainRule.constants.map(&.id.downcase) %}
        when .{{rule}}?
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

# Searches and returns the next pair of nearest clusters using the
# nearest neighbor chain algorithm.
private def next_merge(active_nodes, dism, chain)
  d_ij = Float64::MAX
  if chain.size < 4
    chain.clear
    chain << (c_i = active_nodes.first)            # current cluster
    c_j, d_ij = active_nodes.nearest_to(c_i, dism) # nearest cluster candidate
  else
    chain.pop 2
    c_j = chain.pop # nearest cluster candidate
    c_i = chain[-1] # current cluster
  end

  # Construct the nearest neighbor chain by iteratively finding the
  # nearest cluster to the current one.
  loop do
    chain << (c_i = c_j) # save nearest cluster & update current cluster
    c_j, d_ij = active_nodes.nearest_to(c_i, dism)
    break if c_j == chain[-2]
  end

  HClust::Dendrogram::Step.new(c_i, c_j, d_ij)
end

{% for rule in HClust::ChainRule.constants.map(&.id.downcase) %}
  # Updates the distances upon the merging of nodes *i* and *j*. In each
  # iteration, it calls the parameterized method T along with the
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
