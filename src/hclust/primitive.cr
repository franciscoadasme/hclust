# TODO: docs
class HClust::Primitive(L)
  def initialize(@dism : DistanceMatrix, reuse : Bool = false)
    @dism = dism.clone unless reuse
    @dism.map! &.**(2) if L.needs_squared_euclidean?

    @active_nodes = IndexList.new(dism.size)
    @sizes = Pointer(Int32).malloc dism.size, 1
  end

  def linkage : Dendrogram
    dendrogram = Dendrogram.new(@dism.size - 1)
    (@dism.size - 1).times do
      step = next_nearest_clusters                   # find the next nearest clusters
      update_distances *step.nodes                   # update distances upon merge
      @sizes[step.nodes[1]] += @sizes[step.nodes[0]] # update sizes upon merge
      @active_nodes.delete step.nodes[0]             # remove smallest cluster
      step = step.sqrt if L.needs_squared_euclidean?
      dendrogram << step
    end
    dendrogram
  end

  # Searches and returns the next pair of nearest clusters using brute
  # force.
  private def next_nearest_clusters : Dendrogram::Step
    c_i = @active_nodes.first? || raise "BUG: unreachable"
    c_j = @active_nodes.unsafe_succ(c_i)
    d_ij = @dism.unsafe_fetch(c_i, c_j)
    raise "BUG: unreachable" if c_j == 0
    @active_nodes.each do |c_k|
      @active_nodes.each(within: c_k.., skip: 1) do |c_m|
        dis = @dism.unsafe_fetch(c_k, c_m)
        c_i, c_j, d_ij = c_k, c_m, dis if dis < d_ij
      end
    end
    Dendrogram::Step.new(c_i, c_j, d_ij).sort # ensure smallest cluster first
  end

  # Updates the distances upon merging clusters *i* and *j*. In each
  # iteration, it calls the parameterized method *L* along with the
  # pointer to the distance between nodes *j* and *k* in the distance
  # matrix (`ptr_jk`) to be updated.
  private def update_distances(c_i : Int32, c_j : Int32) : Nil
    n_i = @sizes[c_i]
    n_j = @sizes[c_j]
    d_ij = @dism.unsafe_fetch(c_i, c_j)

    # iterate over the indexes in three stages to ensure row < column
    # when fetching a value from the distance matrix
    @active_nodes.each(within: ...c_i) do |c_k|
      d_ik = @dism.unsafe_fetch(c_k, c_i)
      L.update d_ij, d_ik, @dism.to_unsafe(c_k, c_j), n_i, n_j, @sizes[c_k]
    end

    @active_nodes.each(within: c_i...c_j, skip: 1) do |c_k|
      d_ik = @dism.unsafe_fetch(c_i, c_k)
      L.update d_ij, d_ik, @dism.to_unsafe(c_k, c_j), n_i, n_j, @sizes[c_k]
    end

    @active_nodes.each(within: c_j.., skip: 1) do |c_k|
      d_ik = @dism.unsafe_fetch(c_i, c_k)
      L.update d_ij, d_ik, @dism.to_unsafe(c_j, c_k), n_i, n_j, @sizes[c_k]
    end
  end
end
