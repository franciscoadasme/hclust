# TODO: add docs
class HClust::Generic(L)
  def initialize(@dism : DistanceMatrix, reuse : Bool = false)
    @dism = dism.clone unless reuse
    @dism.map! &.**(2) if L.needs_squared_euclidean?

    @active_nodes = IndexList.new(@dism.size)
    @nearest = Pointer(Int32).malloc @dism.size
    @queue = IndexPriorityQueue.new(@dism.size) do |i|
      if i < @dism.size - 1
        @nearest[i] = ((i + 1)...@dism.size).min_by { |j| @dism.unsafe_fetch(i, j) }
        @dism.unsafe_fetch(i, @nearest[i])
      else
        Float64::MAX
      end
    end
    @sizes = Pointer(Int32).malloc @dism.size, 1
  end

  def linkage : Dendrogram
    dendrogram = Dendrogram.new(@dism.size)

    (@dism.size - 1).times do
      update_nearest # unless L.single?

      c_i = @queue.pop || raise "BUG: unreachable"
      c_j = @nearest[c_i]
      d_ij = @dism.unsafe_fetch(c_i, c_j) # always n_i < n_j
      step = Dendrogram::Step.new(c_i, c_j, d_ij)

      update_distances *step.nodes                   # update distances upon merge
      @sizes[step.nodes[1]] += @sizes[step.nodes[0]] # update sizes upon merge
      @active_nodes.delete step.nodes[0]             # remove smallest cluster

      step = step.sqrt if L.needs_squared_euclidean?
      dendrogram << step
    end
    dendrogram.relabel(ordered: L.order_dependent?)
  end

  # Nearest neighbor list may be out of sync due to merging two
  # clusters in the previous step, which updates the distance
  # matrix. In such case, the current priority of node `i` (defined
  # as the distance to its nearest neighbor) will be less than
  # `dism[i, nearest[i]]`, but, by construction, never greater.
  # Consequently, the nearest neighbor list and priority queue must
  # be updated.
  private def update_nearest
    while c_i = @queue.first?
      break if @queue.priority_at(c_i) == @dism.unsafe_fetch(c_i, @nearest[c_i])

      # TODO: move to active_nodes.nearest_to(c_i, forward_only: true) or something
      min_dis = Float64::MAX
      @active_nodes.each(within: c_i.., skip: 1) do |c_j|
        d_ij = @dism.unsafe_fetch(c_i, c_j)
        if d_ij < min_dis
          min_dis = d_ij
          @nearest[c_i] = c_j
        end
      end
      @queue.set_priority_at c_i, min_dis
    end
  end

  private def update_distances(
    c_i : Int32,
    c_j : Int32
  ) : Nil
    n_i = @sizes[c_i]
    n_j = @sizes[c_j]
    d_ij = @dism.unsafe_fetch(c_i, c_j)

    # iterate over the indexes in three stages to ensure row < column
    # when fetching a value from the distance matrix

    @active_nodes.each(within: ...c_i) do |c_k|
      d_ik = @dism.unsafe_fetch(c_k, c_i)
      L.update d_ij, d_ik, @dism.to_unsafe(c_k, c_j), n_i, n_j, @sizes[c_k]
      # TODO: this check can be omitted for all but median and centroid
      if (d_kj = @dism.unsafe_fetch(c_k, c_j)) < @queue.priority_at(c_k)
        @queue.set_priority_at c_k, d_kj
        @nearest[c_k] = c_j
      elsif @nearest[c_k] == c_i
        @nearest[c_k] = c_j
      end
    end

    @active_nodes.each(within: c_i...c_j, skip: 1) do |c_k|
      d_ik = @dism.unsafe_fetch(c_i, c_k)
      L.update d_ij, d_ik, @dism.to_unsafe(c_k, c_j), n_i, n_j, @sizes[c_k]
      if (d_kj = @dism.unsafe_fetch(c_k, c_j)) < @queue.priority_at(c_k)
        @queue.set_priority_at c_k, d_kj
        @nearest[c_k] = c_j
      end
    end

    min_dis = @queue.priority_at(c_j)
    @active_nodes.each(within: c_j.., skip: 1) do |c_k|
      d_ik = @dism.unsafe_fetch(c_i, c_k)
      L.update d_ij, d_ik, @dism.to_unsafe(c_j, c_k), n_i, n_j, @sizes[c_k]
      if (d_jk = @dism.unsafe_fetch(c_j, c_k)) < min_dis
        @queue.set_priority_at c_j, d_jk
        @nearest[c_j] = c_k
        min_dis = d_jk
      end
    end
  end
end
