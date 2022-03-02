module HClust
  # TODO: docs
  class Dendrogram
    def initialize(initial_capacity : Int)
      @steps = Array(Step).new(initial_capacity)
    end

    def <<(step : Step) : self
      @steps << step
      self
    end

    def steps : Slice(Step)
      Slice(Step).new @steps.to_unsafe, @steps.size, read_only: true
    end
  end

  struct Dendrogram::Step
    getter nodes : Tuple(Int32, Int32)
    getter distance : Float64

    def initialize(n_i : Int32, n_j : Int32, @distance : Float64)
      @nodes = {n_i, n_j}
    end

    def sort : self
      n_i = @nodes.unsafe_fetch(0)
      n_j = @nodes.unsafe_fetch(1)
      n_i, n_j = n_j, n_i if n_j < n_i
      Dendrogram::Step.new n_i, n_j, @distance
    end
  end
end
