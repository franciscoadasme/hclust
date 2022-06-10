# Returns the hierarchical clustering based on the pairwise distances
# *dism* using the linkage rule *rule*.
#
# This method simply selects and invokes the optimal algorithm based on
# the given linkage rule as follows:
#
# - The minimum spanning tree (MST) algoritm for the `Rule::Single`
#   linkage rule (see `.mst`).
# - The nearest-neighbor-chain (NN-chain) algoritm for the
#   `Rule::Complete`, `Rule::Average`, `Rule::Weighted`, and
#   `Rule::Ward` linkage rules (`.nn_chain`).
# - The generic algoritm for the `Rule::Centroid` and `Rule::Median`
#   linkage rules (`.generic`).
#
# If *reuse* is `true`, the distance matrix *dism* will be forwarded
# directly to the underlying method, and be potentially modified. If
# *reuse* is `false`, a copy will be created first and then forwarded.
# This can be used to prevent a potentially large memory allocation when
# the distance matrix will not be used after clustering.
def HClust.linkage(
  dism : DistanceMatrix,
  rule : Rule,
  reuse : Bool = false
) : Dendrogram
  dism = dism.clone unless reuse
  case rule
  in .single?
    mst(dism)
  in .average?, .complete?, .ward?, .weighted?
    nn_chain(dism, rule.to_chain)
  in .centroid?, .median?
    generic(dism, rule)
  end
end
