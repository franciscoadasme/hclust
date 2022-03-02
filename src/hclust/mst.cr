# TODO: docs
class HClust::MST
  def initialize(@dism : DistanceMatrix)
    @active_nodes = IndexList.new(dism.size)
    # keeps updated distances to merged nodes
    @merged_dis_ptr = Pointer(Float64).malloc dism.size
    # position 0 is never accessed because the search starts at node 1
    (@merged_dis_ptr + 1).copy_from dism.to_unsafe, dism.size - 1
  end

  def linkage : Dendrogram
    dendrogram = Dendrogram.new(@dism.size - 1)
    n_i = 0 # current node
    (@dism.size - 1).times do
      @active_nodes.delete n_i
      # find the nearest cluster and update the distances at the same time
      n_j, d_ij = @active_nodes.nearest_to(n_i, @dism) do |n_k, dis|
        ptr = @merged_dis_ptr + n_k
        Method.single(dis, ptr)
        ptr.value
      end
      dendrogram << Dendrogram::Step.new(n_i, n_j, d_ij)
      n_i = n_j
    end
    dendrogram
  end
end
