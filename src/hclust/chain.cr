module HClust
  # TODO: docs
  def self.nn_chain(dism : DistanceMatrix,
                    method : ChainMethod,
                    reuse : Bool = false) : Dendrogram
    dism = dism.clone unless reuse
    # dism.map! &.**(2) if method.needs_squared_euclidean? # TODO: do this!!!

    dendrogram = Dendrogram.new(dism.size - 1)
    active_nodes = IndexList.new(dism.size)
    node_chain = Deque(Int32).new(dism.size)
    node_sizes = Pointer(Int32).malloc dism.size, 1
    d_ij = Float64::MAX
    (dism.size - 1).times do
      if node_chain.size < 4
        node_chain.clear
        node_chain << (n_i = active_nodes.first) # current node
        n_j, d_ij = active_nodes.nearest_to(n_i, dism)
      else
        node_chain.pop 2
        n_j = node_chain.pop # closest node
        n_i = node_chain[-1] # current node
      end

      # Construct the nearest neighbor chain by iteratively finding the
      # closest node to the current one
      loop do
        node_chain << (n_i = n_j) # save closest node & update current node
        n_j, d_ij = active_nodes.nearest_to(n_i, dism)
        break if n_j == node_chain[-2]
      end

      # Remove one of the nodes from the active nodes
      n_i, n_j = n_j, n_i if n_j < n_i # select the smallest node
      active_nodes.delete n_i

      # Update distances to the new node from merging *i* and *j*
      case method
      in .average?
        size_i = node_sizes[n_i]
        size_j = node_sizes[n_j]
        update_distances(active_nodes, dism, n_i, n_j) do |_, d_ik, ptr_jk|
          Method.average(d_ik, ptr_jk, size_i, size_j)
        end
      in .complete?
        update_distances(active_nodes, dism, n_i, n_j) do |_, d_ik, ptr_jk|
          Method.complete(d_ik, ptr_jk)
        end
      in .single?
        update_distances(active_nodes, dism, n_i, n_j) do |_, d_ik, ptr_jk|
          Method.single(d_ik, ptr_jk)
        end
      in .ward?
        size_i = node_sizes[n_i]
        size_j = node_sizes[n_j]
        update_distances(active_nodes, dism, n_i, n_j) do |n_k, d_ik, ptr_jk|
          size_k = node_sizes[n_k]
          Method.ward(d_ij, d_ik, ptr_jk, size_i, size_j, size_k)
        end
      in .weighted?
        update_distances(active_nodes, dism, n_i, n_j) do |_, d_ik, ptr_jk|
          Method.weighted(d_ik, ptr_jk)
        end
      end

      # Merge nodes n_i and n_j
      node_sizes[n_j] += node_sizes[n_i] if method.average? || method.ward?
      # d_ij = Math.sqrt(d_ij) if method.needs_squared_euclidean? # TODO: do this!!!
      dendrogram << Dendrogram::Step.new(n_i, n_j, d_ij)
    end
    dendrogram
  end

  # Updates the distances upon the merging of nodes *i* and *j*. In each
  # iteration, it yields the current index *k* (`n_k`), the distance
  # between the nodes *i* and *k* (`d_ik`), and the pointer to the
  # distance between nodes *j* and *k* in the distance matrix (`ptr_jk`)
  # to be updated.
  private def self.update_distances(
    active_nodes : IndexList,
    dism : DistanceMatrix,
    n_i : Int32,
    n_j : Int32,
    & : Int32, Float64, Pointer(Float64) ->
  ) : Nil
    dism_ptr = dism.to_unsafe

    # iterate over the indexes in three stages to ensure i < j when
    # fetching a value from the distance matrix
    n_k = active_nodes.first? || return
    while n_k < n_i
      ptr = dism_ptr + dism.matrix_to_condensed_index(n_k, n_j)
      yield n_k, dism.unsafe_fetch(n_k, n_i), ptr
      n_k = active_nodes.unsafe_succ(n_k)
    end

    n_k = active_nodes.unsafe_succ(n_k) if n_k == n_i
    while n_k < n_j
      ptr = dism_ptr + dism.matrix_to_condensed_index(n_k, n_j)
      yield n_k, dism.unsafe_fetch(n_i, n_k), ptr
      n_k = active_nodes.unsafe_succ(n_k)
    end

    n_k = active_nodes.unsafe_succ(n_k) if n_k == n_j
    while n_k < active_nodes.size
      ptr = dism_ptr + dism.matrix_to_condensed_index(n_j, n_k)
      yield n_k, dism.unsafe_fetch(n_i, n_k), ptr
      n_k = active_nodes.unsafe_succ(n_k)
    end
  end
end
