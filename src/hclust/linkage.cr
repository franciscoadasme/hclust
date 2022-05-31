# Module containing linkage rules that dictate how the distances should
# be updated upon merging two clusters.
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
#
# Available rules:
#
# - `Average`
# - `Centroid`
# - `Complete`
# - `Median`
# - `Single`
# - `Ward`
# - `Weighted`
module HClust::Linkage
  # Boilerplate for defining a new module that can be used as a linkage
  # rule. *use_square* indicates whether the rule requires squared
  # Euclidean distances. The given block will correspond to the body of
  # the in-place `#update` method, which accepts the distance between
  # the clusters *J* and *K* as a pointer that can be modified.
  macro gen_rule(name, use_square = false, order_dependent = true)
    module Linkage::{{name.id.camelcase}}
      # Update formula for the linkage rule (see above for details).
      # The distance is computed between the newly formed cluster *I ∪
      # J* and *K* from the pre-computed distances between the
      # clusters *I*, *J*, and *K*, and cluster sizes.
      #
      # NOTE: The value at *ptr_jk* will be modified according to the
      # linkage rule.
      @[AlwaysInline]
      def self.update(
        d_ij : Float64, d_ik : Float64, ptr_jk : Pointer(Float64),
        n_i : Int32, n_j : Int32, n_k : Int32
      ) : Nil
        {{yield}}
      end

      # Returns the new distance between the the newly formed cluster
      # *I ∪ J* and *K*. The distance is computed from the
      # pre-computed distances between the clusters *I*, *J*, and *K*,
      # and cluster sizes.
      def self.update(
        d_ij : Float64, d_ik : Float64, d_jk : Float64,
        n_i : Number, n_j : Number, n_k : Number
      ) : Float64
        ptr = pointerof(d_jk)
        update d_ij, d_ik, ptr, n_i, n_j, n_k
        ptr.value
      end

      # Returns `true` if the linkage rule requires that the initial
      # cluster distances are (proportional to) squared Euclidean
      # distance, else `false`.
      def self.needs_squared_euclidean? : Bool
        {{use_square}}
      end

      # Returns `true` if the distance formula depends on the order
      # which the clusters were formed by merging, else `false`.
      #
      # This is used in the cluster relabeling after linkage. See
      # `Dendrogram#relabel`.
      def self.order_dependent? : Bool
        {{order_dependent}}
      end
    end
  end

  macro finished
    # :nodoc:
    alias All = {{@type.constants.join('|').id}}
    # :nodoc:
    alias Chain = Average | Complete | Single | Ward | Weighted
  end

  # Returns the type that implements the given linkage rule. Raises
  # ArgumentError if no such rule exists. The comparison is made by
  # using `String#camelcase` and `String#downcase` between *rule* and
  # the known type names, so a type named "FortyTwo" or "FORTY_TWO" is
  # found with any of these strings: "forty_two", "FortyTwo",
  # "FORTY_TWO", "FORTYTWO", "fortytwo".
  def self.parse(rule : String) : All
    parse?(rule) || raise ArgumentError.new("Unknown linkage rule: #{rule}")
  end

  # Returns the type that implements the given linkage rule, or `nil` if
  # no such rule exists. The comparison is made by using
  # `String#camelcase` and `String#downcase` between *rule* and the
  # known type names, so a type named "FortyTwo" or "FORTY_TWO" is found
  # with any of these strings: "forty_two", "FortyTwo", "FORTY_TWO",
  # "FORTYTWO", "fortytwo".
  def self.parse?(rule : String) : All
    {% begin %}
      case rule.camelcase.downcase
      {% for member in @type.constants %}
        {% if @type.constant(member).module? %} # ignore aliases and more
          when {{member.stringify.camelcase.downcase}}
            {{@type.constant(member)}}
        {% end %}
      {% end %}
      else
        nil
      end
    {% end %}
  end

  # Defines the distance between the cluster *I ∪ J* and cluster *K* as
  # the arithmetic mean of all distances from every cluster *i ∈ I* and
  # *j ∈ J* to *k ∈ K*:
  #
  #     d(I ∪ J) = (|I| * d(I, K) + |J| * d(J, K)) / (|I| + |J|)
  #
  # This is also called the UPGMA method.
  gen_rule Average, order_dependent: false do
    ptr_jk.value = (n_i * d_ik + n_j * ptr_jk.value) / (n_i + n_j)
  end

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
  gen_rule Centroid, use_square: true do
    n_ij = n_i + n_j
    ptr_jk.value = (n_i * d_ik + n_j * ptr_jk.value) / n_ij -
                   n_i * n_j * d_ij / n_ij**2
  end

  # Defines the distance between the cluster *I ∪ J* and cluster *K* as
  # the largest distance from every cluster *i ∈ I* and *j ∈ J* to *k ∈
  # K*:
  #
  #     d(I ∪ J) = max(d(I, K), d(J, K))
  #
  # This is also called the farthest neighbor method.
  gen_rule Complete, order_dependent: false do
    if d_ik > ptr_jk.value
      ptr_jk.value = d_ik
    end
  end

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
  gen_rule Median, use_square: true do
    ptr_jk.value = (d_ik + ptr_jk.value) * 0.5 - d_ij * 0.25
  end

  # Defines the distance between the cluster *I ∪ J* and cluster *K* as
  # the smallest distance from every cluster *i ∈ I* and *j ∈ J* to *k ∈
  # K*:
  #
  #     d(I ∪ J) = max(d(I, K), d(J, K))
  #
  # This is also called the nearest neighbor method.
  gen_rule Single, order_dependent: false do
    if d_ik < ptr_jk.value
      ptr_jk.value = d_ik
    end
  end

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
  gen_rule Ward, use_square: true, order_dependent: false do
    ptr_jk.value = ((n_i + n_k) * d_ik +
                    (n_j + n_k) * ptr_jk.value -
                    n_k * d_ij) /
                   (n_i + n_j + n_k)
  end

  # Defines the distance between the cluster *I ∪ J* and cluster *K* as
  # the arithmetic mean of the average distances between clusters *I*
  # and *K* (*d(I, K)*) and clusters *J* and *K* (*d(J, K)*):
  #
  #     d(I ∪ J) = (da(I, K) + da(J, K)) / 2
  #
  # where *da(X, Y)* means the average distance between *X* and *Y*.
  # This is also called the WPGMA method.
  gen_rule Weighted, order_dependent: false do
    ptr_jk.value = (d_ik + ptr_jk.value) * 0.5
  end
end
