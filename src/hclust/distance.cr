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
class HClust::DistanceMatrix
  # Size of the condensed form (one-dimensional array)
  @internal_size : Int32

  # Creates a new `DistanceMatrix` of the given size filled with zeros.
  def initialize(@size : Int32)
    @internal_size = size * (size - 1) >> 1
    @buffer = Pointer(Float64).malloc(@internal_size, 0.0)
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
  def self.new(size : Int32, & : Int32, Int32 -> Number)
    new(size).tap do |mat|
      k = 0
      (size - 1).times do |i|
        (i + 1).upto(size - 1) do |j|
          value = (yield i, j).to_f
          raise ArgumentError.new("Invalid distance (NaN)") if value.nan?
          mat.unsafe_put k, value
          k += 1
        end
      end
    end
  end

  # Returns the distance between the elements at *i* and *j*. Raises
  # `IndexError` if any of the indexes is out of bounds.
  @[AlwaysInline]
  def [](i : Int, j : Int) : Float64
    self[i, j]? || raise IndexError.new
  end

  # Returns the distance between the elements at *i* and *j*, or `nil` if
  # any of the indexes is out of bounds.
  @[AlwaysInline]
  def []?(i : Int, j : Int) : Float64?
    return 0.0 if i == j
    i += size if i < 0
    j += size if j < 0
    if 0 <= i < size && 0 <= j < size
      unsafe_fetch(i, j)
    end
  end

  # Sets the distance between the elements at *i* and *j* to *value*.
  # Returns *value*.
  #
  # Negative indices can be used to start counting from the end of the
  # elements. Raises `IndexError` if either *i* or *j* is out of bounds,
  # or if *i == j* and *value* is not zero.
  @[AlwaysInline]
  def []=(i : Int, j : Int, value : Float64) : Float64
    if i == j
      if value == 0
        return 0.0
      else
        raise IndexError.new("The distances at the diagonal must be zero")
      end
    end

    i += size if i < 0
    j += size if j < 0
    if 0 <= i < size && 0 <= j < size
      unsafe_put(i, j, value)
    else
      raise IndexError.new
    end
  end

  # Returns `true` if the distances of the matrices are equal, else
  # `false`.
  def ==(rhs : self) : Bool
    return false unless @size == rhs.size
    0.upto(@size - 1) do |i|
      return false unless unsafe_fetch(i) == rhs.unsafe_fetch(i)
    end
    true
  end

  # :ditto:
  def ==(rhs) : Bool
    false
  end

  # Returns a new `DistanceMatrix` with the same elements as the matrix
  # (deep copy).
  def clone : self
    {{@type}}.new(size).tap do |mat|
      mat.to_unsafe.copy_from @buffer, @internal_size
    end
  end

  # Returns the condensed matrix index of the distance between the
  # elements at *i* and *j*.
  @[AlwaysInline]
  private def matrix_to_condensed_index(i : Int32, j : Int32) : Int32
    # The matrix is assumed to be symmetric, so `m[i, j] == m[j, i]`,
    # but *i* should be less than *j* since the condensed matrix encodes
    # the upper right triangle.
    i, j = j, i if j < i
    # The formula below is an optimized version of the nominal
    # transformation formula:
    #
    # ((@size * i) + j) - ((i * (i + 1)) / 2) - 1 - i
    ((2 * @size - 3 - i) * i >> 1) + j - 1
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
  # This should be called with *i* and *j* within `0...size` and `i !=
  # j`. Use `#[](i, j)` and `#[]?(i, j)` instead for bounds checking and
  # support for negative indexes.
  #
  # NOTE: This method should only be directly invoked if you are
  # absolutely sure *i* and *j* are in bounds, to avoid a bounds check
  # for a small boost of performance.
  def unsafe_fetch(i : Int32, j : Int32) : Float64
    unsafe_fetch matrix_to_condensed_index(i, j)
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

  # Sets the distance between the elements at *i* and *j* to *value*,
  # without doing any bounds check.
  #
  # This should be called with *i* and *j* within `0...size` and `i !=
  # j`. Use `#[]=(i, j, value)` instead for bounds checking and support
  # for negative indexes.
  #
  # NOTE: This method should only be directly invoked if you are
  # absolutely sure *i* and *j* are in bounds, to avoid a bounds check
  # for a small boost of performance.
  def unsafe_put(i : Int32, j : Int32, value : Float64) : Float64
    unsafe_put matrix_to_condensed_index(i, j), value
  end

  # Sets the distance at the given index of the condensed distance
  # matrix (one-dimensional) to *value*, without doing any bounds check.
  #
  # This should be called with *index* within `0...((size * (size - 1))
  # // 2)`.
  #
  # NOTE: This method should only be directly invoked if you are
  # absolutely sure the index is in bounds, to avoid a bounds check for
  # a small boost of performance.
  def unsafe_put(index : Int32, value : Float64) : Float64
    @buffer[index] = value
  end
end
