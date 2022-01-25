module Indexable(T)
  # Returns the index of the element with the maximum value in the
  # collection starting from the given *offset*. Raises
  # `Enumerable::EmptyError` if the collection is empty.
  #
  # It compares using `<` so it will work for any type that supports
  # that method, otherwise raises `ArgumentError`.
  #
  # ```
  # [1, 2, 3].argmax        # => 0
  # ["Alice", "Bob"].argmax # => 0
  # ```
  def argmax(offset : Int = 0) : Int32
    argmax_by offset, &.itself
  end

  # Like `argmax` but returns `nil` if the collection is empty.
  def argmax?(offset : Int = 0) : Int32?
    argmax_by? offset, &.itself
  end

  # Returns the index of the element for which the passed block returns
  # with the maximum value starting from the given *offset*.
  #
  # It compares using `<` so it will work for any type that supports
  # that method, otherwise raises `ArgumentError`. Raises
  # `Enumerable::EmptyError` if the collection is empty.
  #
  # ```
  # ["Alice", "Bob"].argmax_by(&.size) # => 1
  # ```
  def argmax_by(offset : Int = 0, & : T -> U) : Int32 forall U
    index = argmax_by?(offset) { |value| yield value }
    index || raise Enumerable::EmptyError.new
  end

  # Like `argmax_by` but returns `nil` if the collection is empty.
  def argmax_by?(offset : Int = 0, & : T -> U) : Int32? forall U
    generate_arg_by ">"
  end

  # Returns the index of the element with the minimum value in the
  # collection starting from the given *offset*. Raises
  # `Enumerable::EmptyError` if the collection is empty.
  #
  # It compares using `<` so it will work for any type that supports
  # that method, otherwise raises `ArgumentError`.
  #
  # ```
  # [1, 2, 3].argmin        # => 0
  # ["Alice", "Bob"].argmin # => 0
  # ```
  def argmin(offset : Int = 0) : Int32
    argmin_by offset, &.itself
  end

  # Like `argmin` but returns `nil` if the collection is empty.
  def argmin?(offset : Int = 0) : Int32?
    argmin_by? offset, &.itself
  end

  # Returns the index of the element for which the passed block returns
  # with the minimum value starting from the given *offset*.
  #
  # It compares using `<` so it will work for any type that supports
  # that method, otherwise raises `ArgumentError`. Raises
  # `Enumerable::EmptyError` if the collection is empty.
  #
  # ```
  # ["Alice", "Bob"].argmin_by(&.size) # => 1
  # ```
  def argmin_by(offset : Int = 0, & : T -> U) : Int32 forall U
    index = argmin_by?(offset) { |value| yield value }
    index || raise Enumerable::EmptyError.new
  end

  # Like `argmin_by` but returns `nil` if the collection is empty.
  def argmin_by?(offset : Int = 0, & : T -> U) : Int32? forall U
    generate_arg_by "<"
  end

  private macro generate_arg_by(operator)
    offset += size if offset < 0

    index = nil
    memo = uninitialized U
    offset.upto(size - 1) do |i|
      value = yield unsafe_fetch(i)
      if i == offset || compare_or_raise(value, memo) {{operator.id}} 0
        memo = value
        index = i
      end
    end

    index
  end
end
