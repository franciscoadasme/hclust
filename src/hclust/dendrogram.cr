module HClust
  # TODO: docs
  class Dendrogram
    getter observations : Int32

    def initialize(@observations : Int32)
      @steps = Array(Step).new(@observations - 1)
    end

    def <<(step : Step) : self
      @steps << step
      self
    end

    # Returns `true` if the merge steps are equal to `rhs`'s steps, else
    # `false`.
    def ==(rhs : self) : Bool
      return false if observations != rhs.observations
      @steps.each_with_index do |step, i|
        return false unless step == rhs.steps.unsafe_fetch(i)
      end
      true
    end

    # Creates and appends a merge step between clusters *c_i* and *c_j*
    # separated bu *distance*.
    def add(c_i : Int32, c_j : Int32, distance : Float64) : Step
      step = Step.new(c_i, c_j, distance).sort
      @steps << step
      step
    end

    # Returns a new `Dendrogram` with relabeled clusters. If *ordered*
    # is `false`, the dendrogram's steps will be sorted by the
    # dissimilarities first.
    #
    # Internally, it uses a `UnionFind` data structure for creating
    # merge step with the new cluster labels efficiently.
    #
    # NOTE: Cluster labels will follow the SciPy convention, where new
    # clusters start at `N` with `N ` equal to the number of
    # observations (see `UnionFind`).
    def relabel(ordered : Bool = true) : self
      steps = @steps
      steps = steps.sort_by(&.distance) unless ordered

      dendrogram = self.class.new @observations
      set = UnionFind.new @observations
      steps.each do |step|
        c_i = set.find(step.nodes[0]).not_nil! # node always exists
        c_j = set.find(step.nodes[1]).not_nil! # node always exists
        set.union c_i, c_j
        dendrogram.add c_i, c_j, step.distance
      end
      dendrogram
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

    def ==(rhs : self) : Bool
      @nodes == rhs.nodes && (@distance - rhs.distance).abs <= Float64::EPSILON
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
