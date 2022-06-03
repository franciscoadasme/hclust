# Returns the hierarchical clustering based on the pairwise distances
# *dism* using the linkage rule *rule*.
#
# This method simply selects and invokes the optimal algorithm based on
# the given linkage rule as follows:
#
# - The minimum spanning tree (MST) algoritm for the single linkage rule
#   (see `.mst`).
# - The nearest-neighbor-chain (NN-chain) algoritm for the complete,
#   average, weighted, and Ward linkage rules (`.nn_chain`).
# - The generic algoritm for the centroid and median linkage rules
#   (`.generic`).
#
# If *reuse* is `true`, the distance matrix *dism* will be forwarded
# directly to the underlying method, and be potentially modified. If
# *reuse* is `false`, a copy will be created first and then forwarded.
# This can be used to prevent a potentially large memory allocation when
# the distance matrix will not be used after clustering.
def HClust.linkage(
  rule : Rule,
  dism : DistanceMatrix,
  reuse : Bool = false
) : Dendrogram
  dism = dism.clone unless reuse
  case rule
  in .single?
    mst(dism)
  in .average?, .complete?, .ward?, .weighted?
    nn_chain(rule.to_chain, dism)
  in .centroid?, .median?
    generic(rule, dism)
  end
end
