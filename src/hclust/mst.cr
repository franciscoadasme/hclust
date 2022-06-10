# Perform hierarchical clustering based on the distances stored in
# *dism* using the minimum spanning tree (MST) algorithm.
#
# The MST algorithm keeps track of the distances to the nearest neighbor
# for each cluster after every merge step, which leads to a significant
# speed up as obtaining the next pair of nearest clusters is very
# efficient. By definition, this algorithm can only be used with the
# `Rule::Single` linkage rule.
#
# The merge steps are encoded as an unordered `Dendrogram`, which is
# sorted prior to be returned.
#
# The current implementation is described in section 3.3 of the
# Müllner's article [[1]](https://arxiv.org/abs/1109.2378), which
# includes several optimizations over the classic implementation.
#
# NOTE: Prefer to use the `.linkage` method since it provides a general
# interface and picks the best algorithm depending on the linkage rule.
def HClust.mst(dism : DistanceMatrix) : Dendrogram
  active_nodes = IndexList.new(dism.size) # tracks non-merged clusters
  # keeps updated distances to merged nodes
  merged_dis_ptr = Pointer(Float64).malloc dism.size
  # position 0 is never accessed because the search starts at node 1
  (merged_dis_ptr + 1).copy_from dism.to_unsafe, dism.size - 1

  dendrogram = Dendrogram.new(dism.size)
  n_i = 0 # current node
  (dism.size - 1).times do
    active_nodes.delete n_i
    # find the nearest cluster and update the distances at the same time
    n_j, d_ij = active_nodes.nearest_to(n_i, dism) do |n_k, dis|
      ptr = merged_dis_ptr + n_k
      Rule.single(0, dis, ptr, 0, 0, 0)
      ptr.value
    end
    dendrogram.add(n_i, n_j, d_ij)
    n_i = n_j
  end
  dendrogram.relabel(ordered: true)
end
