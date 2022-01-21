# Stores the pairwise distances between the elements of a set.
#
# A distance matrix is a square, hollow, symmetric, two-dimensional
# matrix of distances. The latter are assumed to be a *metric*, which is
# defined by the properties of non-negativity, identity of
# indiscernibles, and triangle inequality [[1]]. However, these
# properties are not checked.
#
# To avoid redundancy, the matrix is stored in the condensed form, i.e.,
# a one-dimensional array of size `(n * (n - 1)) // 2` that holds the
# upper triangular portion of the matrix. Then, the position of the
# distance between the elements *i* and *j* in the array is computed as
# `((2 * n - 3 - i) * i >> 1) + j - 1` with `i < j`. Refer to the Notes
# section in the SciPy documentation of the `squareform` function [[2]].
# Using the condensed form is useful for implementing optimized
# clustering functions, among others.
#
# ### Example
#
# ```
# # 5x5 distance matrix
# mat = HClust::DistanceMatrix.new(5) do |i, j|
#   # compute distance between elements i and j
#   10 * (i + 1) + j + 1
# end
# mat[0, 0] # => 0.0 (the distance between the same elements is zero)
# mat[1, 1] # => 0.0
# mat[0, 1] # => 12.0
# mat[1, 0] # => 12.0 (symmetry)
# mat[2, 3] # => 34.0
# ```
#
# [1]: https://en.wikipedia.org/wiki/Metric_(mathematics)
# [2]:
#     https://docs.scipy.org/doc/scipy/reference/generated/scipy.spatial.distance.squareform.html
struct HClust::DistanceMatrix
  # Size of the condensed form (one-dimensional array)
  @internal_size : Int32

  # Creates a new `DistanceMatrix` of the given size and invokes the
  # given block once for each pair of elements (indexes), using the
  # block's return value as the distance between the given elements.
  #
  # Raises `ArgumentError` if any distance value is NaN.
  #
  # ```
  # HClust::DistanceMatrix.new(5) do |i, j|
  #   # compute distance between elements i and j
  #   10 * (i + 1) + j + 1
  # end
  # ```
  def initialize(@size : Int32, & : Int32, Int32 -> Number)
    @internal_size = (size * (size - 1)) // 2
    @buffer = Pointer(Float64).malloc(@internal_size)

    k = 0
    (size - 1).times do |i|
      (i + 1).upto(size - 1) do |j|
        value = (yield i, j).to_f
        raise ArgumentError.new("Invalid distance (NaN)") if value.nan?
        @buffer[k] = value
        k += 1
      end
    end
  end

  # Creates a new `DistanceMatrix` from the given condensed distance
  # matrix (one-dimensional array). Raises `ArgumentError` if the given
  # array cannot be interpreted as a condensed matrix (it contains an
  # invalid number of elements) or `Enumerable::EmptyError` if it's
  # empty.
  #
  # NOTE: distance values must be valid (non-NaN).
  def initialize(values : Array(Float64))
    raise Enumerable::EmptyError.new if values.empty?
    size = Math.sqrt(8 * values.size + 1) / 2 + 0.5
    raise ArgumentError.new("Invalid condensed distance matrix") if size.to_i != size
    @size = size.to_i
    @internal_size = values.size
    @buffer = Pointer(Float64).malloc(@internal_size)
    @buffer.copy_from values.to_unsafe, values.size
  end

  # Returns the distance between elements at *i* and *j*. Raises
  # `IndexError` if any of the indexes is out of bounds.
  def [](i : Int, j : Int) : Float64
    self[i, j]? || raise IndexError.new
  end

  # Returns the distance between elements at *i* and *j*, or `nil` if
  # any of the indexes is out of bounds.
  def []?(i : Int, j : Int) : Float64?
    i += size if i < 0
    j += size if j < 0
    if 0 <= i < size && 0 <= j < size
      unsafe_fetch(i, j)
    end
  end

  # Returns the size of the encoded matrix.
  def size : Int32
    @size
  end

  # Returns the condensed distance matrix as an array.
  def to_a : Array(Float64)
    Array(Float64).build(@internal_size) do |buffer|
      buffer.copy_from @buffer, @internal_size
      @internal_size
    end
  end

  # Returns a pointer to the internal buffer.
  def to_unsafe : Pointer(Float64)
    @buffer
  end

  # Returns the distance between the elements at *i* and *j*, without
  # doing any bounds check.
  #
  # This should be called with *i* and *j* within `0...size`. Use
  # `#[](i, j)` and `#[]?(i, j)` instead for bounds checking and support
  # for negative indexes.
  #
  # NOTE: This method should only be directly invoked if you are
  # absolutely sure *i* and *j* are in bounds, to avoid a bounds check
  # for a small boost of performance.
  def unsafe_fetch(i : Int, j : Int) : Float64
    if i != j
      i, j = j, i if j < i
      k = ((2 * @size - 3 - i) * i >> 1) + j - 1
      unsafe_fetch(k)
    else
      0.0
    end
  end

  # Returns the distance at the given index of the condensed distance
  # matrix (one-dimensional), without doing any bounds check.
  #
  # This should be called with *index* within `0...((size * (size - 1))
  # // 2)`.
  #
  # NOTE: This method should only be directly invoked if you are
  # absolutely sure the index is in bounds, to avoid a bounds check for
  # a small boost of performance.
  def unsafe_fetch(index : Int) : Float64
    @buffer[index]
  end
end
