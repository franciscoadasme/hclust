# An `IndexList` is an ordered collection of contiguous zero-based
# indexes.
#
# It supports efficient iteration and removal so it performs better than
# an `Array` when there are frequent deletions.
#
# Internally, it is implemented as a double-linked list such that
# deleted indexes are marked as inactive, but otherwise kept in memory.
# Therefore, indexing is not supported. Traversal is performed using the
# `#each` methods.
#
# The most typical use case of a `IndexList` is for representing a list
# of nodes, where finding the closest pair is often desired. Hence,
# convenience methods for finding the nearest index based on a given
# distance metric are provided.
class HClust::IndexList
  # Creates a new `IndexList` with indexes in the range `[0, size)`.
  def initialize(@size : Int32)
    # The first active index
    @start = 0
    # Holds the preceding active index for each index `i` if active.
    # pred[i] is unspecified if `i` is inactive. However, these won't be
    # accessed normally. Also, pred[0] is never accessed.
    @pred = Pointer(Int32).malloc(size + 1) { |i| i - 1 }
    # Holds the succeeding active index for each index `i` if active.
    # succ[i] == 0 if `i` is inactive. However, these won't be
    # accessed normally. Also, succ[size] is never accessed.
    @succ = Pointer(Int32).malloc(size + 1) { |i| i + 1 }
  end

  # Yields each index in the list.
  def each(& : Int32 ->) : Nil
    index = @start
    while index < @size
      yield index
      index = @succ[index]
    end
  end

  # Yields each index in the list within the given range.
  def each(*, within range : Range(Int32?, Int32?), & : Int32 ->) : Nil
    start = range.begin || @start
    stop = range.end || @size
    stop += 1 if range.end && !range.exclusive?
    stop = Math.min(stop, @size)
    raise IndexError.new unless @start <= start < @size && start < stop
    until start == stop || start.in?(self)
      start += 1
    end

    index = start
    while index < stop
      yield index
      index = @succ[index]
    end
  end

  # Yields each index except *index*. Useful for iterating in pairs.
  def each(*, omit index : Int32, & : Int32 ->) : Nil
    other = @start
    while other < index
      yield other
      other = @succ[other]
    end

    other = @succ[index] if other == index
    while other < @size
      yield other
      other = @succ[other]
    end
  end

  # Returns the first index. Raises `Enumerable::EmptyError` if the list
  # is empty.
  def first : Int32
    first? || raise Enumerable::EmptyError.new
  end

  # Returns the first index or `nil` if the list is empty.
  def first? : Int32?
    @start if @start < @size
  end

  # Returns `true` if the list includes the given index, else `false`.
  def includes?(index : Int32) : Bool
    @succ[index] > 0
  end

  # Removes the given index from the list if present.
  def delete(index : Int32) : Nil
    return unless includes?(index)
    case index
    when @start
      @start = @succ[index]
    when .>(@start)
      @succ[@pred[index]] = @succ[index]
      @pred[@succ[index]] = @pred[index]
    else
      raise IndexError.new if index < @start
    end
    @succ[index] = 0 # mark as inactive
  end

  # Returns the nearest index to the given index based on the block's
  # returns value.
  def nearest_to(index : Int32, & : Int32 -> T) : {Int32, T} forall T
    nearest_index = @start
    min_dis = T::MAX
    each(omit: index) do |other|
      dis = yield other
      if dis < min_dis
        nearest_index = other
        min_dis = dis
      end
    end
    {nearest_index, min_dis}
  end

  # Returns the nearest index to the given index based on the distance
  # matrix.
  def nearest_to(index : Int32, dism : DistanceMatrix) : {Int32, Float64}
    nearest_to(index, dism) { |_, dis| dis }
  end

  # Returns the nearest index to the given index based on the block's
  # returns value. Both the index and distance taken from the distance
  # matrix are yielded such that the block may compute a new distance if
  # needed.
  def nearest_to(
    index : Int32,
    dism : DistanceMatrix,
    & : Int32, Float64 -> Float64
  ) : {Int32, Float64}
    nearest_index = @start
    min_dis = Float64::MAX

    other = @start
    while other < index
      dis = dism.unsafe_fetch(other, index)
      dis = yield other, dis
      if dis < min_dis
        nearest_index = other
        min_dis = dis
      end
      other = @succ[other]
    end

    other = @succ[index] if other == index
    while other < @size
      dis = dism.unsafe_fetch(index, other)
      dis = yield other, dis
      if dis < min_dis
        nearest_index = other
        min_dis = dis
      end
      other = @succ[other]
    end

    {nearest_index, min_dis}
  end

  # Returns the total number of indexes in the list.
  def size : Int32
    @size
  end

  # Returns an `Array` with all the indexes in the list.
  def to_a : Array(Int32)
    nodes = [] of Int32
    each do |node|
      nodes << node
    end
    nodes
  end

  # Returns the succeeding index to `index`, without doing any bounds
  # check.
  @[AlwaysInline]
  def unsafe_succ(index) : Int32
    @succ[index]
  end
end
