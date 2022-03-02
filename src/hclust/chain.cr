# TODO: docs
class HClust::NNChain
  def initialize(@dism : DistanceMatrix,
                 @method : ChainMethod,
                 reuse : Bool = false)
    @dism = @dism.clone unless reuse
    # @dism.map! &.**(2) if method.needs_squared_euclidean? # TODO: do this!!!

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
      # step = step.sqrt if method.needs_squared_euclidean? # TODO: do this!!!
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
    n_i, n_j = step.nodes
    case @method
    in .average?
      size_i = @sizes[n_i]
      size_j = @sizes[n_j]
      update_distances(n_i, n_j) do |_, d_ik, ptr_jk|
        Method.average(d_ik, ptr_jk, size_i, size_j)
      end
    in .complete?
      update_distances(n_i, n_j) do |_, d_ik, ptr_jk|
        Method.complete(d_ik, ptr_jk)
      end
    in .single?
      update_distances(n_i, n_j) do |_, d_ik, ptr_jk|
        Method.single(d_ik, ptr_jk)
      end
    in .ward?
      size_i = @sizes[n_i]
      size_j = @sizes[n_j]
      update_distances(n_i, n_j) do |n_k, d_ik, ptr_jk|
        size_k = @sizes[n_k]
        Method.ward(step.distance, d_ik, ptr_jk, size_i, size_j, size_k)
      end
    in .weighted?
      update_distances(n_i, n_j) do |_, d_ik, ptr_jk|
        Method.weighted(d_ik, ptr_jk)
      end
    end
    @sizes[step.nodes[1]] += @sizes[step.nodes[0]]
  end

  # Updates the distances upon the merging of nodes *i* and *j*. In each
  # iteration, it yields the current index *k* (`n_k`), the distance
  # between the nodes *i* and *k* (`d_ik`), and the pointer to the
  # distance between nodes *j* and *k* in the distance matrix (`ptr_jk`)
  # to be updated.
  private def update_distances(
    n_i : Int32,
    n_j : Int32,
    & : Int32, Float64, Pointer(Float64) ->
  ) : Nil
    dism_ptr = @dism.to_unsafe

    # iterate over the indexes in three stages to ensure i < j when
    # fetching a value from the distance matrix
    n_k = @active_nodes.first? || return
    while n_k < n_i
      ptr = dism_ptr + @dism.matrix_to_condensed_index(n_k, n_j)
      yield n_k, @dism.unsafe_fetch(n_k, n_i), ptr
      n_k = @active_nodes.unsafe_succ(n_k)
    end

    n_k = @active_nodes.unsafe_succ(n_k) if n_k == n_i
    while n_k < n_j
      ptr = dism_ptr + @dism.matrix_to_condensed_index(n_k, n_j)
      yield n_k, @dism.unsafe_fetch(n_i, n_k), ptr
      n_k = @active_nodes.unsafe_succ(n_k)
    end

    n_k = @active_nodes.unsafe_succ(n_k) if n_k == n_j
    while n_k < @active_nodes.size
      ptr = dism_ptr + @dism.matrix_to_condensed_index(n_j, n_k)
      yield n_k, @dism.unsafe_fetch(n_i, n_k), ptr
      n_k = @active_nodes.unsafe_succ(n_k)
    end
  end
end
