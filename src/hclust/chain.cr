# TODO: docs
class HClust::NNChain(L)
  def initialize(@dism : DistanceMatrix, reuse : Bool = false)
    {% raise "Unsupported linkage rule #{L} by NNChain" unless L < Linkage::Chain %}
    @dism = @dism.clone unless reuse
    # @dism.map! &.**(2) if L.needs_squared_euclidean? # TODO: do this!!!

    @active_nodes = IndexList.new(@dism.size)    # tracks non-merged clusters
    @chain = Deque(Int32).new(@dism.size)        # nearest neighbor chain
    @sizes = Pointer(Int32).malloc @dism.size, 1 # cluster sizes
  end

  def linkage : Dendrogram
    dendrogram = Dendrogram.new(@dism.size - 1)
    (@dism.size - 1).times do
      step = next_nearest_clusters       # find the next nearest clusters
      @active_nodes.delete step.nodes[0] # remove smallest cluster
      merge_clusters step                # merge nearest clusters
      # step = step.sqrt if L.needs_squared_euclidean? # TODO: do this!!!
      dendrogram << step
    end
    dendrogram
  end

  # Searches and returns the next pair of nearest clusters using the
  # nearest neighbor chain algorithm.
  private def next_nearest_clusters : Dendrogram::Step
    d_ij = Float64::MAX
    if @chain.size < 4
      @chain.clear
      @chain << (c_i = @active_nodes.first)            # current cluster
      c_j, d_ij = @active_nodes.nearest_to(c_i, @dism) # nearest cluster candidate
    else
      @chain.pop 2
      c_j = @chain.pop # nearest cluster candidate
      c_i = @chain[-1] # current cluster
    end

    # Construct the nearest neighbor chain by iteratively finding the
    # nearest cluster to the current one.
    loop do
      @chain << (c_i = c_j) # save nearest cluster & update current cluster
      c_j, d_ij = @active_nodes.nearest_to(c_i, @dism)
      break if c_j == @chain[-2]
    end

    Dendrogram::Step.new(c_i, c_j, d_ij).sort # ensure smallest cluster first
  end

  # Update distances and sizes upon merging the given nodes.
  private def merge_clusters(step : Dendrogram::Step) : Nil
    update_distances *step.nodes, step.distance
    @sizes[step.nodes[1]] += @sizes[step.nodes[0]]
  end

  # Updates the distances upon the merging of nodes *i* and *j*. In each
  # iteration, it calls the parameterized method T along with the
  # pointer to the distance between nodes *j* and *k* in the distance
  # matrix (`ptr_jk`) to be updated.
  private def update_distances(c_i : Int32, c_j : Int32, d_ij : Float64) : Nil
    n_i = @sizes[c_i]
    n_j = @sizes[c_j]

    # iterate over the indexes in three stages to ensure row < column
    # when fetching a value from the distance matrix
    c_k = @active_nodes.first? || return
    while c_k < c_i
      d_ik = @dism.unsafe_fetch(c_k, c_i)
      L.update d_ij, d_ik, @dism.to_unsafe(c_k, c_j), n_i, n_j, @sizes[c_k]
      c_k = @active_nodes.unsafe_succ(c_k)
    end

    c_k = @active_nodes.unsafe_succ(c_k) if c_k == c_i
    while c_k < c_j
      d_ik = @dism.unsafe_fetch(c_i, c_k)
      L.update d_ij, d_ik, @dism.to_unsafe(c_k, c_j), n_i, n_j, @sizes[c_k]
      c_k = @active_nodes.unsafe_succ(c_k)
    end

    c_k = @active_nodes.unsafe_succ(c_k) if c_k == c_j
    while c_k < @active_nodes.size
      d_ik = @dism.unsafe_fetch(c_i, c_k)
      L.update d_ij, d_ik, @dism.to_unsafe(c_j, c_k), n_i, n_j, @sizes[c_k]
      c_k = @active_nodes.unsafe_succ(c_k)
    end
  end
end
