# Clusters *elements* using the linkage rule *rule* based on the
# distances computed by the given block. The clusters are generated such
# that the cophenetic distance between any two elements in a cluster is
# less than or equal to *cutoff*.
def HClust.cluster(
  elements : Indexable(T),
  cutoff : Number,
  rule : Rule = :single,
  & : T, T -> Float64
) : Array(Array(T)) forall T
  dism = DistanceMatrix.new(elements) do |a, b|
    yield a, b
  end
  dendrogram = linkage(dism, rule, reuse: true)
  dendrogram.flatten(cutoff).map do |idxs|
    idxs.map do |i|
      elements.unsafe_fetch(i)
    end
  end
end

# Clusters *elements* into *count* clusters or fewer using the linkage
# rule *rule* based on the distances computed by the given block.
def HClust.cluster(
  elements : Indexable(T),
  *,
  into count : Int,
  rule : Rule = :single,
  & : T, T -> Float64
) : Array(Array(T)) forall T
  dism = DistanceMatrix.new(elements) do |a, b|
    yield a, b
  end
  dendrogram = linkage(dism, rule, reuse: true)
  dendrogram.flatten(count: count).map do |idxs|
    idxs.map do |i|
      elements.unsafe_fetch(i)
    end
  end
end
