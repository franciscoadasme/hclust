module HClust
  # TODO: docs
  def self.mst(dism : DistanceMatrix) : Dendrogram
    # keeps updated distances to current nodes
    node_distances = Pointer(Float64).malloc dism.size
    # position 0 is never accessed because the search starts at node 1
    (node_distances + 1).copy_from dism.to_unsafe, dism.size - 1

    active_nodes = Array(Bool).new(dism.size, true)
    n_i = 0 # current node
    Dendrogram.build(dism.size - 1) do |dendrogram|
      n_j = 1 # closest node
      d_ij = Float64::MAX
      active_nodes.unsafe_put n_i, false
      dism.size.times do |n_k|
        next unless active_nodes.unsafe_fetch(n_k)
        d_ik = dism.unsafe_fetch(n_k, n_i) # pairwise distance
        d_jk = node_distances[n_k]         # distance to current node
        node_distances[n_k] = d_jk = Method.single(d_ik, d_jk)
        d_ij, n_j = d_jk, n_k if d_jk < d_ij
      end
      dendrogram << Dendrogram::Step.new(n_i, n_j, d_ij)
      n_i = n_j
    end
  end

  # TODO: docs
  def self.nn_chain(dism : DistanceMatrix,
                    method : ChainMethod,
                    reuse : Bool = false) : Dendrogram
    dism = dism.clone unless reuse
    # dism.map! &.**(2) if method.needs_squared_euclidean? # TODO: do this!!!

    active_nodes = Array(Int32).new(dism.size) { |i| i }
    node_chain = Deque(Int32).new(dism.size)
    node_sizes = Pointer(Int32).malloc dism.size, 1
    Dendrogram.build(dism.size - 1) do |dendrogram|
      if node_chain.size < 4
        node_chain.clear
        node_chain << (n_i = active_nodes.first) # current node
        n_j = active_nodes.min_by do |n_k|       # closest node
          n_k != n_i ? dism.unsafe_fetch(n_k, n_i) : Float64::MAX
        end
      else
        node_chain.pop 2
        n_j = node_chain.pop # closest node
        n_i = node_chain[-1] # current node
      end

      # Construct the nearest neighbor chain by iteratively finding the
      # closest node to the current one
      loop do
        node_chain << (n_i = n_j) # save closest node & update current node
        n_j = active_nodes.min_by do |n_k|
          n_k != n_i ? dism.unsafe_fetch(n_k, n_i) : Float64::MAX
        end
        break if n_j == node_chain[-2]
      end

      # Remove one of the nodes from the active nodes
      n_i, n_j = n_j, n_i if n_j < n_i # select the smallest node
      index = active_nodes.bsearch_index(&.>=(n_i)) || raise "BUG: invalid node"
      active_nodes.delete_at index

      # Update distances. Do not check for the method on every
      # iteration, so put the loop inside the case statement. Use macros
      # to avoid repeating setup and loop code for every method.
      d_ij = dism.unsafe_fetch n_i, n_j
      {% begin %}
        case method
        {% for member in ChainMethod.constants %}
          in .{{member.camelcase.downcase.id}}?
            {% value = ChainMethod.constant(member) %}
            active_nodes.each do |n_k|
              next if n_k == n_j
              d_ik = dism.unsafe_fetch(n_i, n_k)
              d_jk = dism.unsafe_fetch(n_j, n_k)

              {% if value == ChainMethod::Single %}
                new_dist = Method.single(d_ik, d_jk)
              {% elsif value == ChainMethod::Complete %}
                new_dist = Method.complete(d_ik, d_jk)
              {% elsif value == ChainMethod::Average %}
                size_i = node_sizes[n_i]
                size_j = node_sizes[n_j]
                new_dist = Method.average(d_ik, d_jk, size_i, size_j)
              {% elsif value == ChainMethod::Weighted %}
                new_dist = Method.weighted(d_ik, d_jk)
              {% elsif value == ChainMethod::Ward %}
                size_i = node_sizes[n_i]
                size_j = node_sizes[n_j]
                size_k = node_sizes[n_k]
                new_dist = Method.ward(d_ij, d_ik, d_jk, size_i, size_j, size_k)
              {% end %}

              dism.unsafe_put n_j, n_k, new_dist
            end
        {% end %}
        end
      {% end %}

      # Merge nodes n_i and n_j
      node_sizes[n_j] += node_sizes[n_i] if method.average? || method.ward?
      # d_ij = Math.sqrt(d_ij) if method.needs_squared_euclidean? # TODO: do this!!!
      dendrogram << Dendrogram::Step.new(n_i, n_j, d_ij)
    end
  end
end
