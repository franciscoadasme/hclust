# An enum that provides linkage rules that dictate how the distances
# should be updated upon merging two clusters.
#
# A linkage rule is used when computing the distances of a newly formed
# cluster *I ∪ J* by the union of clusters *I* and *J* and every other
# existing cluster *K* (*d(*I ∪ J*, K)*) during the clustering
# procedure. Note that *d(X, Y)* expands to all distances between the
# clusters *x ∈ X* and *y ∈ Y* (*d(x, y)*).
#
# A rule is implemented as a module containing the `#update` and
# `#needs_squared_euclidean?` class methods. The former accepts as
# arguments the pre-computed distances *d(I, J)*, *d(I, K)*, and *d(J,
# K)*, and cluster sizes (|*I*|, |*J*|, and |*K*|). There are in-place
# and non-modifying methods of the update formula. Use the `gen_rule`
# macro for generating additional rules if needed.
enum HClust::Rule
  # Defines the distance between the cluster *I ∪ J* and cluster *K* as
  # the arithmetic mean of all distances from every cluster *i ∈ I* and
  # *j ∈ J* to *k ∈ K*:
  #
  #     d(I ∪ J) = (|I| * d(I, K) + |J| * d(J, K)) / (|I| + |J|)
  #
  # This is also called the UPGMA method.
  Average

  # Defines the distance between the cluster *I ∪ J* and cluster *K* as
  # the distance between the cluster centroids or means:
  #
  #     d(I ∪ J) = sqrt((|I| * d(I, K)² + |J| * d(J, K))²) / (|I| + |J|)
  #                     - (|I| * |J| * d(I, J)²) / (|I| + |J|)²)
  #
  # This is also called the UPGMC method.
  #
  # WARNING: This method requires that the initial cluster distances are
  # (proportional to) squared Euclidean distance.
  Centroid

  # Defines the distance between the cluster *I ∪ J* and cluster *K* as
  # the largest distance from every cluster *i ∈ I* and *j ∈ J* to *k ∈
  # K*:
  #
  #     d(I ∪ J) = max(d(I, K), d(J, K))
  #
  # This is also called the farthest neighbor method.
  Complete

  # Defines the distance between the cluster *I ∪ J* and cluster *K* as
  # the distance between the cluster centroids or means, where the
  # centroid of *I ∪ J* is simply defined as the average of the
  # centroids of *I* and *J*:
  #
  #     d(I ∪ J) = sqrt((d(I, K) + d(J, K)) / 2 - d(I, J) / 4)
  #
  # This is also called the WPGMC method.
  #
  # WARNING: This method requires that the initial cluster distances
  # must be (proportional to) squared Euclidean distance.
  Median

  # Defines the distance between the cluster *I ∪ J* and cluster *K* as
  # the smallest distance from every cluster *i ∈ I* and *j ∈ J* to *k ∈
  # K*:
  #
  #     d(I ∪ J) = max(d(I, K), d(J, K))
  #
  # This is also called the nearest neighbor method.
  Single

  # Ward's minimum variance criterion minimizes the total intra-cluster
  # variance. It defines the distance between the cluster *I ∪ J* and
  # cluster *K* as the weighted squared distance between cluster
  # centers. Using the Lance–Williams formula, the distance can be
  # expressed as
  #
  #     d(I ∪ J) = sqrt((|I| + |K|) * d(I, K)²
  #                     + (|J| + |K|) * d(J, K)²
  #                     - |K| * d(I, J)²)
  #
  # WARNING: This method requires that the initial cluster distances are
  # (proportional to) squared Euclidean distance.
  Ward

  # Defines the distance between the cluster *I ∪ J* and cluster *K* as
  # the arithmetic mean of the average distances between clusters *I*
  # and *K* (*d(I, K)*) and clusters *J* and *K* (*d(J, K)*):
  #
  #     d(I ∪ J) = (da(I, K) + da(J, K)) / 2
  #
  # where *da(X, Y)* means the average distance between *X* and *Y*.
  # This is also called the WPGMA method.
  Weighted

  # Update formula for the average linkage rule. The distance is
  # computed between the newly formed cluster *I ∪ J* and *K* from the
  # pre-computed distances between the clusters *I*, *J*, and *K*, and
  # cluster sizes.
  #
  # NOTE: The value at *ptr_jk* will be modified according to the
  # linkage rule.
  @[AlwaysInline]
  def self.average(
    d_ij : Float64, d_ik : Float64, ptr_jk : Pointer(Float64),
    n_i : Int32, n_j : Int32, n_k : Int32
  ) : Nil
    ptr_jk.value = (n_i * d_ik + n_j * ptr_jk.value) / (n_i + n_j)
  end

  # Update formula for the centroid linkage rule. The distance is
  # computed between the newly formed cluster *I ∪ J* and *K* from the
  # pre-computed distances between the clusters *I*, *J*, and *K*, and
  # cluster sizes.
  #
  # NOTE: The value at *ptr_jk* will be modified according to the
  # linkage rule.
  @[AlwaysInline]
  def self.centroid(
    d_ij : Float64, d_ik : Float64, ptr_jk : Pointer(Float64),
    n_i : Int32, n_j : Int32, n_k : Int32
  ) : Nil
    n_ij = n_i + n_j
    ptr_jk.value = (n_i * d_ik + n_j * ptr_jk.value) / n_ij -
                   n_i * n_j * d_ij / n_ij**2
  end

  # Update formula for the complete linkage rule. The distance is
  # computed between the newly formed cluster *I ∪ J* and *K* from the
  # pre-computed distances between the clusters *I*, *J*, and *K*, and
  # cluster sizes.
  #
  # NOTE: The value at *ptr_jk* will be modified according to the
  # linkage rule.
  @[AlwaysInline]
  def self.complete(
    d_ij : Float64, d_ik : Float64, ptr_jk : Pointer(Float64),
    n_i : Int32, n_j : Int32, n_k : Int32
  ) : Nil
    ptr_jk.value = d_ik if d_ik > ptr_jk.value
  end

  # Update formula for the median linkage rule. The distance is
  # computed between the newly formed cluster *I ∪ J* and *K* from the
  # pre-computed distances between the clusters *I*, *J*, and *K*, and
  # cluster sizes.
  #
  # NOTE: The value at *ptr_jk* will be modified according to the
  # linkage rule.
  @[AlwaysInline]
  def self.median(
    d_ij : Float64, d_ik : Float64, ptr_jk : Pointer(Float64),
    n_i : Int32, n_j : Int32, n_k : Int32
  ) : Nil
    ptr_jk.value = (d_ik + ptr_jk.value) * 0.5 - d_ij * 0.25
  end

  # Update formula for the single linkage rule. The distance is
  # computed between the newly formed cluster *I ∪ J* and *K* from the
  # pre-computed distances between the clusters *I*, *J*, and *K*, and
  # cluster sizes.
  #
  # NOTE: The value at *ptr_jk* will be modified according to the
  # linkage rule.
  @[AlwaysInline]
  def self.single(
    d_ij : Float64, d_ik : Float64, ptr_jk : Pointer(Float64),
    n_i : Int32, n_j : Int32, n_k : Int32
  ) : Nil
    ptr_jk.value = d_ik if d_ik < ptr_jk.value
  end

  # Update formula for the ward linkage rule. The distance is
  # computed between the newly formed cluster *I ∪ J* and *K* from the
  # pre-computed distances between the clusters *I*, *J*, and *K*, and
  # cluster sizes.
  #
  # NOTE: The value at *ptr_jk* will be modified according to the
  # linkage rule.
  @[AlwaysInline]
  def self.ward(
    d_ij : Float64, d_ik : Float64, ptr_jk : Pointer(Float64),
    n_i : Int32, n_j : Int32, n_k : Int32
  ) : Nil
    ptr_jk.value = ((n_i + n_k) * d_ik +
                    (n_j + n_k) * ptr_jk.value -
                    n_k * d_ij) /
                   (n_i + n_j + n_k)
  end

  # Update formula for the weighted linkage rule. The distance is
  # computed between the newly formed cluster *I ∪ J* and *K* from the
  # pre-computed distances between the clusters *I*, *J*, and *K*, and
  # cluster sizes.
  #
  # NOTE: The value at *ptr_jk* will be modified according to the
  # linkage rule.
  @[AlwaysInline]
  def self.weighted(
    d_ij : Float64, d_ik : Float64, ptr_jk : Pointer(Float64),
    n_i : Int32, n_j : Int32, n_k : Int32
  ) : Nil
    ptr_jk.value = (d_ik + ptr_jk.value) * 0.5
  end

  # Returns `true` if the linkage rule requires that the initial
  # cluster distances are (proportional to) squared Euclidean
  # distance, else `false`.
  def needs_squared_euclidean? : Bool
    case self
    when .centroid?, .median?, .ward?
      true
    else
      false
    end
  end

  # Returns `true` if the distance formula depends on the order
  # which the clusters were formed by merging, else `false`.
  #
  # This is used in the cluster relabeling after linkage. See
  # `Dendrogram#relabel`.
  def order_dependent? : Bool
    case self
    when .centroid?, .median?
      true
    else
      false
    end
  end
end

# An enum that provides linkage rules supported by the
# nearest-neighbor-chain (`HClust.nn_chain`) algorithm. See `Rule` for
# details.
enum HClust::ChainRule
  Average
  Complete
  Single
  Ward
  Weighted

  # Returns the corresponding linkage rule.
  def to_rule : Rule
    {% begin %}
      case self
      {% for rule in @type.constants %}
        in .{{rule.downcase.id}}?
          Rule::{{rule.id}}
      {% end %}
      end
    {% end %}
  end
end
