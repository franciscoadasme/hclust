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
  def self.from_condensed(values : Array(Float64)) : self
    raise Enumerable::EmptyError.new if values.empty?
    size = Math.sqrt(8 * values.size + 1) / 2 + 0.5
    raise ArgumentError.new("Invalid condensed distance matrix") if size.to_i != size
    new(size.to_i).tap do |dmat|
      dmat.to_unsafe.copy_from values.to_unsafe, values.size
    end
  end

  # Creates a new `DistanceMatrix` from the given elements by invoking
  # the given block once for each pair of elements, using the block's
  # return value as the distance between the elements.
  #
  # Raises `Enumerable::EmptyError` if *elements* is empty or
  # `ArgumentError` if any distance value is NaN.
  #
  # ```
  # dm = HClust::DistanceMatrix.new([1, 2, 3, 4]) { |a, b| 10 * a + b }
  # dm.to_a # => [12.0, 13.0, 14.0, 23.0, 24.0, 34.0]
  # ```
  def self.new(elements : Indexable(T), & : T -> Number) : self forall T
    raise Enumerable::EmptyError.new if elements.empty?
    new(elements.size) do |i, j|
      a = elements.unsafe_fetch(i)
      b = elements.unsafe_fetch(j)
      (yield a, b).to_f
    end
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

  # Returns the submatrix containing the distances between the elements
  # at the given indexes. Raises `Enumerable::EmptyError` if *indexes*
  # is empty or `IndexError` if any of the indexes is out of bounds.
  def [](indexes : Indexable(Int)) : self
    raise Enumerable::EmptyError.new unless indexes.size > 0
    self[indexes]? || raise IndexError.new
  end

  # Returns the distance between the elements at *i* and *j*, or `nil` if
  # any of the indexes is out of bounds.
  def []?(i : Int, j : Int) : Float64?
    return 0.0 if i == j
    i += size if i < 0
    j += size if j < 0
    if 0 <= i < size && 0 <= j < size
      i, j = j, i if j < i
      unsafe_fetch(i, j)
    end
  end

  # Returns the submatrix containing the distances between the elements
  # at the given indexes, or `nil` if *indexes* is empty or any of the
  # indexes is out of bounds.
  def []?(indexes : Indexable(Int)) : self?
    return unless indexes.size > 0
    indexes = indexes.map { |i| i < 0 ? i + size : i }
    return unless indexes.all? { |i| 0 <= i < size }
    self.class.new(indexes.size).tap do |mat|
      k = 0
      indexes.each_with_index do |ii, i|
        indexes.each(within: (i + 1)..) do |jj|
          mat.unsafe_put k, unsafe_fetch(ii, jj)
          k += 1
        end
      end
    end
  end

  # Sets the distance between the elements at *i* and *j* to *value*.
  # Returns *value*.
  #
  # Negative indices can be used to start counting from the end of the
  # elements. Raises `IndexError` if either *i* or *j* is out of bounds,
  # or if *i == j* and *value* is not zero.
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
      i, j = j, i if j < i
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

  # Returns the index of the element with the smallest average distance
  # to all others.
  def centroid : Int32
    accum = Array.new size, 0.0
    i = 0
    j = i + 1
    @internal_size.times do |k|
      if j == size
        i += 1
        j = i + 1
      end
      distance = unsafe_fetch(k)
      accum.unsafe_put i, accum.unsafe_fetch(i) + distance
      accum.unsafe_put j, accum.unsafe_fetch(j) + distance
      j += 1
    end
    (0...size).min_by { |x| accum.unsafe_fetch(x) / size }
  end

  # Returns a new `DistanceMatrix` with the results of running the block
  # against each element of the matrix.
  def map(& : Float64 -> Float64) : self
    clone.map! { |distance| yield distance }
  end

  # Invokes the given block for each element of the distance matrix,
  # replacing the element with the value returned by the block. Returns
  # `self`.
  def map!(& : Float64 -> Float64) : self
    @internal_size.times do |i|
      unsafe_put(i, yield unsafe_fetch(i))
    end
    self
  end

  # Returns the condensed matrix index of the distance between the
  # elements at *i* and *j*.
  @[AlwaysInline]
  def matrix_to_condensed_index(row : Int32, col : Int32) : Int32
    {% if !flag?(:release) %}
      # The condensed matrix encodes the upper right triangle, so `row < col`.
      raise ArgumentError.new("row >= column") if row >= col
    {% end %}
    # The formula below is an optimized version of the nominal
    # transformation formula:
    #
    # ((@size * row) + col) - ((row * (row + 1)) / 2) - 1 - row
    ((2 * @size - 3 - row) * row >> 1) + col - 1
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

  # Returns a pointer to the internal buffer placed at the specified
  # location.
  def to_unsafe(row : Int32, col : Int32) : Pointer(Float64)
    @buffer + matrix_to_condensed_index(row, col)
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
  @[AlwaysInline]
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
  @[AlwaysInline]
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
  @[AlwaysInline]
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
  @[AlwaysInline]
  def unsafe_put(index : Int32, value : Float64) : Float64
    @buffer[index] = value
  end
end
