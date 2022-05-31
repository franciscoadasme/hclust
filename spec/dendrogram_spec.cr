require "./spec_helper"

describe HClust::Dendrogram do
  describe "#relabel" do
    it "returns a dendrogram with new labels" do
      dendrogram = HClust::Dendrogram.new(5)
      dendrogram.add 1, 3, 0.01
      dendrogram.add 1, 2, 0.02
      dendrogram.add 0, 4, 0.015
      dendrogram.add 1, 4, 0.03

      dendrogram.relabel(ordered: true)
        .steps
        .map { |step| {*step.nodes, step.distance} }
        .should eq [
          {1, 3, 0.01},
          {2, 5, 0.02},
          {0, 4, 0.015},
          {6, 7, 0.03},
        ]

      dendrogram.relabel(ordered: false)
        .steps
        .map { |step| {*step.nodes, step.distance} }
        .should eq [
          {1, 3, 0.01},
          {0, 4, 0.015},
          {2, 5, 0.02},
          {6, 7, 0.03},
        ]
    end
  end
end
