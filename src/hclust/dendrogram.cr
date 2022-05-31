module HClust
  # TODO: docs
  class Dendrogram
    getter observations : Int32

    def initialize(@observations : Int32)
      @steps = Array(Step).new(@observations)
    end

    def <<(step : Step) : self
      @steps << step
      self
    end

    # Creates and appends a merge step between clusters *c_i* and *c_j*
    # separated bu *distance*.
    def add(c_i : Int32, c_j : Int32, distance : Float64) : Step
      step = Step.new(c_i, c_j, distance).sort
      @steps << step
      step
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
