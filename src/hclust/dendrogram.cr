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

    def steps : Array::View(Step)
      @steps.view
    end
  end

  struct Dendrogram::Step
    getter nodes : Tuple(Int32, Int32)
    getter distance : Float64

    def initialize(c_i : Int32, c_j : Int32, @distance : Float64)
      @nodes = {c_i, c_j}
    end

    def sqrt : self
      self.class.new *@nodes, Math.sqrt(@distance)
    end

    def sort : self
      c_i = @nodes.unsafe_fetch(0)
      c_j = @nodes.unsafe_fetch(1)
      c_i, c_j = c_j, c_i if c_j < c_i
      Dendrogram::Step.new c_i, c_j, @distance
    end
  end
end
