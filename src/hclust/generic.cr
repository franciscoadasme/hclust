# TODO: add docs
def HClust.generic(rule : Rule, dism : DistanceMatrix) : Dendrogram
  dism.map! &.**(2) if rule.needs_squared_euclidean?

  active_nodes = IndexList.new(dism.size)          # tracks non-merged clusters
  sizes = Pointer(Int32).malloc dism.size, 1       # cluster sizes
  nearest = Pointer(Int32).malloc dism.size        # tracks nearest clusters
  queue = IndexPriorityQueue.new(dism.size) do |i| # sorted clusters by priority
    if i < dism.size - 1
      nearest[i] = ((i + 1)...dism.size).min_by { |j| dism.unsafe_fetch(i, j) }
      dism.unsafe_fetch(i, nearest[i])
    else
      Float64::MAX
    end
  end

  dendrogram = Dendrogram.new(dism.size)
  (dism.size - 1).times do
    update_nearest(active_nodes, dism, nearest, queue) unless rule.single?
    step = next_merge(dism, nearest, queue)

    {% begin %}
      case rule
      {% for rule in HClust::Rule.constants.map(&.id.downcase) %}
        in .{{rule}}?
          update_distances_{{rule}}(active_nodes, dism, sizes, nearest, queue, *step.nodes)
      {% end %}
      end
    {% end %}

    sizes[step.nodes[1]] += sizes[step.nodes[0]]
    active_nodes.delete step.nodes[0] # remove smallest cluster
    step = step.sqrt if rule.needs_squared_euclidean?
    dendrogram << step
  end
  dendrogram.relabel(ordered: !rule.order_dependent?)
end

# Searches and returns the next pair of nearest clusters using the
# nearest neighbor chain algorithm.
private def next_merge(dism, nearest, queue)
  c_i = queue.pop || raise "BUG: unreachable"
  c_j = nearest[c_i]
  d_ij = dism.unsafe_fetch(c_i, c_j) # always n_i < n_j
  HClust::Dendrogram::Step.new(c_i, c_j, d_ij)
end

# Nearest neighbor list may be out of sync due to merging two
# clusters in the previous step, which updates the distance
# matrix. In such case, the current priority of node `i` (defined
# as the distance to its nearest neighbor) will be less than
# `dism[i, nearest[i]]`, but, by construction, never greater.
# Consequently, the nearest neighbor list and priority queue must
# be updated.
private def update_nearest(active_nodes, dism, nearest, queue)
  while c_i = queue.first?
    break if queue.priority_at(c_i) == dism.unsafe_fetch(c_i, nearest[c_i])

    min_dis = Float64::MAX
    active_nodes.each(within: c_i.., skip: 1) do |c_j|
      d_ij = dism.unsafe_fetch(c_i, c_j)
      if d_ij < min_dis
        min_dis = d_ij
        nearest[c_i] = c_j
      end
    end
    queue.set_priority_at c_i, min_dis
  end
end

{% for rule in HClust::Rule.constants.map(&.id.downcase) %}
  # Updates the distances upon the merging of nodes *i* and *j*. In each
  # iteration, it calls the parameterized method T along with the
  # pointer to the distance between nodes *j* and *k* in the distance
  # matrix (`ptr_jk`) to be updated.
  private def update_distances_{{rule}}(active_nodes, dism, sizes, nearest, queue, c_i, c_j)
    n_i = sizes[c_i]
    n_j = sizes[c_j]
    d_ij = dism.unsafe_fetch(c_i, c_j)

    # iterate over the indexes in three stages to ensure row < column
    # when fetching a value from the distance matrix

    active_nodes.each(within: ...c_i) do |c_k|
      d_ik = dism.unsafe_fetch(c_k, c_i)
      HClust::Rule.{{rule}} d_ij, d_ik, dism.to_unsafe(c_k, c_j), n_i, n_j, sizes[c_k]
      {% if %w(centroid median).includes? rule.stringify %}
        # This branch can be omitted for other than centroid and median
        if (d_kj = dism.unsafe_fetch(c_k, c_j)) < queue.priority_at(c_k)
          queue.set_priority_at c_k, d_kj
          nearest[c_k] = c_j
        els{% end %}if nearest[c_k] == c_i
        nearest[c_k] = c_j
      end
    end

    active_nodes.each(within: c_i...c_j, skip: 1) do |c_k|
      d_ik = dism.unsafe_fetch(c_i, c_k)
      HClust::Rule.{{rule}} d_ij, d_ik, dism.to_unsafe(c_k, c_j), n_i, n_j, sizes[c_k]
      if (d_kj = dism.unsafe_fetch(c_k, c_j)) < queue.priority_at(c_k)
        queue.set_priority_at c_k, d_kj
        nearest[c_k] = c_j
      end
    end

    min_dis = queue.priority_at(c_j)
    active_nodes.each(within: c_j.., skip: 1) do |c_k|
      d_ik = dism.unsafe_fetch(c_i, c_k)
      HClust::Rule.{{rule}} d_ij, d_ik, dism.to_unsafe(c_j, c_k), n_i, n_j, sizes[c_k]
      if (d_jk = dism.unsafe_fetch(c_j, c_k)) < min_dis
        queue.set_priority_at c_j, d_jk
        nearest[c_j] = c_k
        min_dis = d_jk
      end
    end
  end
{% end %}
