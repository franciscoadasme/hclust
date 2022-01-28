module HClust
  # TODO: docs
  def self.mst(dism : DistanceMatrix) : Dendrogram
    # keeps updated distances to current nodes
    node_distances = Pointer(Float64).malloc dism.size
    # position 0 is never accessed because the search starts at node 1
    (node_distances + 1).copy_from dism.to_unsafe, dism.size - 1

    active_nodes = Array(Int32).new(dism.size - 1) { |i| i + 1 }
    n_i = 0 # current node
    n_j = 1 # closest node
    d_ij = node_distances[n_j]
    Dendrogram.build(dism.size - 1) do |dendrogram|
      active_nodes.each do |n_k|
        d_ik = dism.unsafe_fetch(n_k, n_i) # pairwise distance
        d_jk = node_distances[n_k]         # distance to current node
        node_distances[n_k] = d_jk = Method.single(d_ik, d_jk)
        d_ij, n_j = d_jk, n_k if d_jk < d_ij
      end
      dendrogram << Dendrogram::Step.new(n_i, n_j, d_ij)

      index = active_nodes.bsearch_index(&.>=(n_j)) || raise "BUG: invalid node"
      active_nodes.delete_at index
      n_i = n_j
      n_j = active_nodes.unsafe_fetch(0)
      d_ij = node_distances[n_j]
    end
  end
end
