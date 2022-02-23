module HClust
  # A method that dictates how the distance between two clusters is
  # computed.
  #
  # The method is used when computing the distances of a newly formed
  # cluster *I ∪ J* by the union of clusters *I* and *J* and every other
  # existing cluster *K* (*d(*I ∪ J*, K)*) during the clustering
  # procedure. Note that *d(X, Y)* expands to all distances between the
  # nodes *x ∈ X* and *y ∈ Y* (*d(x, y)*).
  #
  # Implementation of the update formula associated to each method is
  # provided as a class method such as `.single`, `.complete`, etc.
  # These methods receive as arguments the pre-computed distances *d(I,
  # J)*, *d(I, K)*, and *d(J, K)*, and cluster sizes (|*I*|, |*J*|, and
  # |*K*|) if applicable.
  enum Method
    # Defines the distance between the cluster *I ∪ J* and cluster *K*
    # as the arithmetic mean of all distances from every node *i ∈ I*
    # and *j ∈ J* to *k ∈ K*:
    #
    #     d(I ∪ J) = (|I| * d(I, K) + |J| * d(J, K)) / (|I| + |J|)
    #
    # This is also called the UPGMA method.
    Average

    # Defines the distance between the cluster *I ∪ J* and cluster *K*
    # as the distance between the cluster centroids or means:
    #
    #     d(I ∪ J) = sqrt((|I| * d(I, K)² + |J| * d(J, K))²) / (|I| + |J|)
    #                     - (|I| * |J| * d(I, J)²) / (|I| + |J|)²)
    #
    # This is also called the UPGMC method.
    #
    # WARNING: This method requires that the initial node distances are
    # (proportional to) squared Euclidean distance.
    Centroid

    # Defines the distance between the cluster *I ∪ J* and cluster *K*
    # as the largest distance from every node *i ∈ I* and *j ∈ J* to *k
    # ∈ K*:
    #
    #     d(I ∪ J) = max(d(I, K), d(J, K))
    #
    # This is also called the farthest neighbor method.
    Complete

    # Defines the distance between the cluster *I ∪ J* and cluster *K*
    # as the distance between the cluster centroids or means, where the
    # centroid of *I ∪ J* is simply defined as the average of the
    # centroids of *I* and *J*:
    #
    #     d(I ∪ J) = sqrt((d(I, K) + d(J, K)) / 2 - d(I, J) / 4)
    #
    # This is also called the WPGMC method.
    #
    # WARNING: This method requires that the initial node distances must be
    # (proportional to) squared Euclidean distance.
    Median

    # Defines the distance between the cluster *I ∪ J* and cluster *K*
    # as the smallest distance from every node *i ∈ I* and *j ∈ J* to *k
    # ∈ K*:
    #
    #     d(I ∪ J) = max(d(I, K), d(J, K))
    #
    # This is also called the nearest neighbor method.
    Single

    # Ward's minimum variance criterion minimizes the total
    # intra-cluster variance. It defines the distance between the
    # cluster *I ∪ J* and cluster *K* as the weighted squared distance
    # between cluster centers. Using the Lance–Williams formula, the
    # distance can be expressed as
    #
    #     d(I ∪ J) = sqrt((|I| + |K|) * d(I, K)²
    #                     + (|J| + |K|) * d(J, K)²
    #                     - |K| * d(I, J)²)
    #
    # WARNING: This method requires that the initial node distances are
    # (proportional to) squared Euclidean distance.
    Ward

    # Defines the distance between the cluster *I ∪ J* and cluster *K*
    # as the arithmetic mean of the average distances between clusters
    # *I* and *K* (*d(I, K)*) and clusters *J* and *K* (*d(J, K)*):
    #
    #     d(I ∪ J) = (da(I, K) + da(J, K)) / 2
    #
    # where *da(X, Y)* means the average distance between *X* and *Y*.
    # This is also called the WPGMA method.
    Weighted

    # Update formula for the average linkage method (see above for
    # details). The distance is computed between the newly formed
    # cluster *I ∪ J* and *K* from the pre-computed distances between
    # the clusters *I*, *J*, and *K*, and cluster sizes.
    @[AlwaysInline]
    def self.average(d_ik : Float64, d_jk : Float64,
                     size_i : Int32, size_j : Int32) : Float64
      ptr = pointerof(d_jk)
      average d_ik, ptr, size_i, size_j
      ptr.value
    end

    # :ditto:
    @[AlwaysInline]
    def self.average(d_ik : Float64, ptr_jk : Pointer(Float64),
                     size_i : Int32, size_j : Int32) : Nil
      ptr_jk.value = (size_i * d_ik + size_j * ptr_jk.value) / (size_i + size_j)
    end

    # Update formula for the centroid linkage method (see above for
    # details). The distance is computed between the newly formed
    # cluster *I ∪ J* and *K* from the pre-computed distances between
    # the clusters *I*, *J*, and *K*, and cluster sizes.
    #
    # WARNING: The distances must be (proportional to) squared Euclidean
    # distance.
    @[AlwaysInline]
    def self.centroid(d_ij : Float64, d_ik : Float64, d_jk : Float64,
                      size_i : Int32, size_j : Int32) : Float64
      ptr = pointerof(d_jk)
      centroid d_ij, d_ik, ptr, size_i, size_j
      ptr.value
    end

    # :ditto:
    @[AlwaysInline]
    def self.centroid(d_ij : Float64, d_ik : Float64, ptr_jk : Pointer(Float64),
                      size_i : Int32, size_j : Int32) : Nil
      size_kj = size_k + size_j
      ptr_jk.value = (size_k * d_ik + size_j * ptr_jk.value) / size_kj -
                     size_i * size_j * d_ij / size_kj**2
    end

    # Update formula for the complete linkage method (see above for
    # details). The distance is computed between the newly formed
    # cluster *I ∪ J* and *K* from the pre-computed distances between
    # the clusters *I*, *J*, and *K*.
    @[AlwaysInline]
    def self.complete(d_ik : Float64, d_jk : Float64) : Float64
      ptr = pointerof(d_jk)
      complete d_ik, ptr
      ptr.value
    end

    # :ditto:
    @[AlwaysInline]
    def self.complete(d_ik : Float64, ptr_jk : Pointer(Float64)) : Nil
      if d_ik > ptr_jk.value
        ptr_jk.value = d_ik
      end
    end

    # Update formula for the median linkage method (see above for
    # details). The distance is computed between the newly formed
    # cluster *I ∪ J* and *K* from the pre-computed distances between
    # the clusters *I*, *J*, and *K*.
    #
    # WARNING: The distances must be (proportional to) squared Euclidean
    # distance.
    @[AlwaysInline]
    def self.median(d_ij : Float64, d_ik : Float64, d_jk : Float64) : Float64
      ptr = pointerof(d_jk)
      median d_ij, d_ik, ptr
      ptr.value
    end

    # :ditto:
    @[AlwaysInline]
    def self.median(d_ij : Float64, d_ik : Float64, ptr_jk : Pointer(Float64)) : Nil
      ptr_jk.value = (d_ik + ptr_jk.value) * 0.5 - d_ij * 0.25
    end

    # Update formula for the single linkage method (see above for
    # details). The distance is computed between the newly formed
    # cluster *I ∪ J* and *K* from the pre-computed distances between
    # the clusters *I*, *J*, and *K*.
    @[AlwaysInline]
    def self.single(d_ik : Float64, d_jk : Float64) : Float64
      ptr = pointerof(d_jk)
      single d_ik, ptr
      ptr.value
    end

    # :ditto:
    @[AlwaysInline]
    def self.single(d_ik : Float64, ptr_jk : Pointer(Float64)) : Nil
      if d_ik < ptr_jk.value
        ptr_jk.value = d_ik
      end
    end

    # Update formula for the Ward's linkage method (see above for
    # details). The distance is computed between the newly formed
    # cluster *I ∪ J* and *K* from the pre-computed distances between
    # the clusters *I*, *J*, and *K*, and cluster sizes.
    #
    # WARNING: The distances must be (proportional to) squared Euclidean
    # distance.
    @[AlwaysInline]
    def self.ward(d_ij : Float64, d_ik : Float64, d_jk : Float64,
                  size_i : Int32, size_j : Int32, size_k : Int32) : Float64
      ptr = pointerof(d_jk)
      ward d_ij, d_ik, ptr, size_i, size_j, size_k
      ptr.value
    end

    # :ditto:
    @[AlwaysInline]
    def self.ward(d_ij : Float64, d_ik : Float64, ptr_jk : Pointer(Float64),
                  size_i : Int32, size_j : Int32, size_k : Int32) : Nil
      ptr_jk.value = ((size_i + size_k) * d_ik +
                      (size_j + size_k) * ptr_jk.value -
                      size_k * d_ij) /
                     (size_i + size_j + size_k)
    end

    # Update formula for the weighted linkage method (see above for
    # details). The distance is computed between the newly formed
    # cluster *I ∪ J* and *K* from the pre-computed distances between
    # the clusters *I*, *J*, and *K*.
    @[AlwaysInline]
    def self.weighted(d_ik : Float64, d_jk : Float64) : Float64
      ptr = pointerof(d_jk)
      weighted d_ik, ptr
      ptr.value
    end

    # :ditto:
    @[AlwaysInline]
    def self.weighted(d_ik : Float64, ptr_jk : Pointer(Float64)) : Nil
      ptr_jk.value = (d_ik + ptr_jk.value) * 0.5
    end

    # Returns `true` if the linkage method requires that the initial
    # node distances are (proportional to) squared Euclidean distance,
    # else `false`.
    def needs_squared_euclidean? : Bool
      case self
      when .centroid?, .median?, .ward? then true
      else                                   false
      end
    end

    # Returns the distance between newly formed cluster *I ∪ J* and *K*
    # from the pre-computed distances between the clusters *I*, *J*, and
    # *K*, and cluster sizes using the corresponding method.
    def update(d_ij : Float64, d_ik : Float64, d_jk : Float64,
               size_i : Number, size_j : Number, size_k : Number) : Float64
      case self
      when .single?   then {{@type}}.single(d_ik, d_jk)
      when .complete? then {{@type}}.complete(d_ik, d_jk)
      when .average?  then {{@type}}.average(d_ik, d_jk, size_i, size_j)
      when .weighted? then {{@type}}.weighted(d_ik, d_jk)
      when .ward?     then {{@type}}.ward(d_ij, d_ik, d_jk, size_i, size_j, size_k)
      else                 raise "BUG: #{self} not implemented"
      end
    end

    # :ditto:
    def update(d_ij : Float64, d_ik : Float64, ptr_jk : Pointer(Float64),
               size_i : Number, size_j : Number, size_k : Number) : Nil
      case self
      when .single?   then {{@type}}.single(d_ik, ptr_jk)
      when .complete? then {{@type}}.complete(d_ik, ptr_jk)
      when .average?  then {{@type}}.average(d_ik, ptr_jk, size_i, size_j)
      when .weighted? then {{@type}}.weighted(d_ik, ptr_jk)
      when .ward?     then {{@type}}.ward(d_ij, d_ik, ptr_jk, size_i, size_j, size_k)
      else                 raise "BUG: #{self} not implemented"
      end
    end
  end

  enum ChainMethod
    Single
    Complete
    Average
    Weighted
    Ward

    def needs_squared_euclidean? : Bool
      to_method.needs_squared_euclidean?
    end

    def to_method : Method
      case self
      in .single?   then Method::Single
      in .complete? then Method::Complete
      in .average?  then Method::Average
      in .weighted? then Method::Weighted
      in .ward?     then Method::Ward
      end
    end
  end
end
