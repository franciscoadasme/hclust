require "bit_array"

# An `IndexPriorityQueue` is a priority queue of contiguous zero-based
# indexes.
#
# It supports efficient access to and removal of the element with
# highest priority (defined as the smallest value). It is designed for
# optimally searching nearest neighbors (priority = dissimilarity).
#
# It is implemented as a min binary heap (where the top is the minimum
# element), where the indexes and priorities are also stored separately.
# Note that deleted indexes are marked as inactive, but otherwise kept
# in memory. Therefore, indexing is not supported.
class HClust::IndexPriorityQueue
  # Returns the number of indexes in the queue.
  getter size : Int32

  # Creates a new `IndexPriorityQueue` with indexes in the range `[0,
  # size)`, invoking the given block for each index and setting its
  # priority to the block's return value.
  def initialize(@size : Int32)
    # A binary heap represented by an array, where the element `i` has
    # children at `2*i + 1` and `2*i + 2`
    @heap = Pointer(Int32).malloc(@size) { |i| i }
    # Maps the index with its current position in the heap
    @elements = Pointer(Int32).malloc(@size) { |i| i }
    # A list of priorities
    @priorities = Pointer(Float64).malloc(@size) { |i| yield i }
    # Marks indexes as active (true) or inactive (false)
    @mask = BitArray.new(@size, true)

    # Arranges the indexes to restore the heap property (i.e., a node is
    # less than or equal to its children) such that the array represents
    # a valid binary heap
    (@size // 2 - 1).downto(0) do |i|
      heapify_down @heap[i]
    end
  end

  # Creates a new `IndexPriorityQueue` from the given priorities with
  # indexes in the range `[0, priorities.size)`.
  def self.new(priorities : Array(Number)) : self
    IndexPriorityQueue.new(priorities.size) do |i|
      priorities.unsafe_fetch(i).to_f
    end
  end

  # Returns the indexes of the two children of *index*. If a child is
  # out of bounds, `nil` is returned for that child.
  private def children_of(index : Int32) : {Int32?, Int32?}
    i = @elements[index]
    left = @heap[2 * i + 1] if 2 * i + 1 < @size
    right = @heap[2 * i + 2] if 2 * i + 2 < @size
    {left, right}
  end

  # Returns `true` if the queue is empty, else `false`.
  def empty? : Bool
    @size == 0
  end

  # Returns the index with highest priority (smallest value). Raises
  # `Enumerable::EmptyError` if the list is empty.
  def first : Int32
    first? || raise Enumerable::EmptyError.new
  end

  # Returns the index with highest priority (smallest value), or `nil`
  # if the queue is empty.
  def first? : Int32?
    @heap[0] unless empty?
  end

  # Recursively compares and possibly swap a node with one of its
  # children to restore the heap property.
  private def heapify_down(index : Int32) : Nil
    loop do
      child = index
      left, right = children_of(index)
      child = left if left && @priorities[left] < @priorities[child]
      child = right if right && @priorities[right] < @priorities[child]
      break if child == index
      swap(index, child)
    end
  end

  # Recursively compares and possibly swap a node with its parent to
  # restore the heap property.
  private def heapify_up(index : Int32) : Nil
    loop do
      break unless pix = parent_of(index)
      break if @priorities[pix] < @priorities[index]
      swap(index, pix)
    end
  end

  # Returns the parent of *index*, or `nil` if out of bounds.
  private def parent_of(index : Int32) : Int32?
    @heap[(@elements[index] - 1) // 2] if @elements[index] > 0
  end

  # Returns the priority of the element at *index*. Raises `IndexError`
  # if *index* is out of bounds or inactive (removed).
  def priority_at(index : Int32) : Float64
    raise IndexError.new unless @mask[index]?
    @priorities[index]
  end

  # Removes and returns the index with highest priority (smallest
  # value), or `nil` if the queue is empty.
  #
  # NOTE: The queue is updated internally to restore the heap property.
  def pop : Int32?
    return if empty?

    swap(@heap[0], @heap[@size - 1]) if @size >= 2

    last = @heap[@size - 1]
    (@heap + @size - 1).clear
    @size -= 1
    @mask.unsafe_put(last, false)

    heapify_down(@heap[0]) if @size >= 2

    last
  end

  # Updates the priority of the element at *index* with the given value.
  #
  # NOTE: The queue is updated internally to restore the heap property.
  def update(index : Int32, priority : Float64) : Nil
    raise IndexError.new unless @mask[index]?
    old_priority = @priorities[index]
    @priorities[index] = priority
    priority < old_priority ? heapify_up(index) : heapify_down(index)
  end

  # Swaps the elements at *i* and *j*.
  private def swap(i : Int32, j : Int32) : Nil
    @heap.swap(@elements[i], @elements[j])
    @elements.swap(i, j)
  end

  # Returns the array representation of the binary heap.
  def to_a : Array(Int32)
    Array(Int32).build(@size) do |buffer|
      buffer.copy_from @heap, @size
      @size
    end
  end
end
