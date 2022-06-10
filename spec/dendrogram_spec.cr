require "./spec_helper"

describe HClust::Dendrogram do
  describe "#flatten" do
    it "returns flat clusters" do
      dendrogram = HClust::Dendrogram.new(20)
      dendrogram.add 6, 12, 0.00438361
      dendrogram.add 7, 16, 0.00989980
      dendrogram.add 1, 5, 0.01000643
      dendrogram.add 4, 11, 0.02448446
      dendrogram.add 9, 19, 0.04289943
      dendrogram.add 13, 24, 0.04747264
      dendrogram.add 10, 22, 0.05136181
      dendrogram.add 20, 26, 0.06133798
      dendrogram.add 8, 15, 0.06546053
      dendrogram.add 21, 27, 0.07880936
      dendrogram.add 0, 29, 0.07920459
      dendrogram.add 17, 30, 0.09371079
      dendrogram.add 25, 31, 0.09517504
      dendrogram.add 23, 32, 0.09733436
      dendrogram.add 2, 33, 0.10275691
      dendrogram.add 3, 34, 0.14312896
      dendrogram.add 14, 28, 0.16196269
      dendrogram.add 35, 36, 0.17977018
      dendrogram.add 18, 37, 0.19431562
      dendrogram.flatten(0.1).should eq [
        [0, 1, 4, 5, 6, 7, 9, 10, 11, 12, 13, 16, 17, 19], [2], [3],
        [8, 15], [14], [18],
      ]
      dendrogram.flatten(0.5).should eq [(0..19).to_a]
      dendrogram.flatten(0.05).should eq [
        [0], [1, 5], [2], [3], [4, 11], [6, 12], [7, 16], [8],
        [9, 13, 19], [10], [14], [15], [17], [18],
      ]
      dendrogram.flatten(0.087).should eq [
        [0, 1, 5, 6, 7, 10, 12, 16], [2], [3], [4, 11], [8, 15],
        [9, 13, 19], [14], [17], [18],
      ]
    end

    it "returns N flat clusters" do
      dendrogram = HClust::Dendrogram.new(20)
      dendrogram.add 6, 12, 0.00438361
      dendrogram.add 7, 16, 0.00989980
      dendrogram.add 1, 5, 0.01000643
      dendrogram.add 4, 11, 0.02448446
      dendrogram.add 9, 19, 0.04289943
      dendrogram.add 13, 24, 0.04747264
      dendrogram.add 10, 22, 0.05136181
      dendrogram.add 20, 26, 0.06133798
      dendrogram.add 8, 15, 0.06546053
      dendrogram.add 21, 27, 0.07880936
      dendrogram.add 0, 29, 0.07920459
      dendrogram.add 17, 30, 0.09371079
      dendrogram.add 25, 31, 0.09517504
      dendrogram.add 23, 32, 0.09733436
      dendrogram.add 2, 33, 0.10275691
      dendrogram.add 3, 34, 0.14312896
      dendrogram.add 14, 28, 0.16196269
      dendrogram.add 35, 36, 0.17977018
      dendrogram.add 18, 37, 0.19431562
      dendrogram.flatten(count: 1).should eq [(0..19).to_a]
      dendrogram.flatten(count: 2).should eq [
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 19],
        [18],
      ]
      dendrogram.flatten(count: 5).should eq [
        [0, 1, 2, 4, 5, 6, 7, 9, 10, 11, 12, 13, 16, 17, 19], [3],
        [8, 15], [14], [18],
      ]
      dendrogram.flatten(count: 11).should eq [
        [0], [1, 5, 6, 10, 12], [2], [3], [4, 11], [7, 16], [8, 15],
        [9, 13, 19], [14], [17], [18],
      ]
      dendrogram.flatten(count: 17).should eq [
        [0], [1, 5], [2], [3], [4], [6, 12], [7, 16], [8], [9], [10],
        [11], [13], [14], [15], [17], [18], [19],
      ]
      dendrogram.flatten(count: 18).should eq [
        [0], [1], [2], [3], [4], [5], [6, 12], [7, 16], [8], [9], [10],
        [11], [13], [14], [15], [17], [18], [19],
      ]
      dendrogram.flatten(count: 19).should eq [
        [0], [1], [2], [3], [4], [5], [6, 12], [7, 16], [8], [9], [10],
        [11], [13], [14], [15], [17], [18], [19],
      ]
      dendrogram.flatten(count: 20).should eq [
        [0], [1], [2], [3], [4], [5], [6, 12], [7, 16], [8], [9], [10],
        [11], [13], [14], [15], [17], [18], [19],
      ]
      dendrogram.flatten(count: 100).should eq [
        [0], [1], [2], [3], [4], [5], [6, 12], [7, 16], [8], [9], [10],
        [11], [13], [14], [15], [17], [18], [19],
      ]
    end
  end

  describe "#relabel" do
    it "returns a dendrogram with new labels" do
      dendrogram = HClust::Dendrogram.new(5)
      dendrogram.add 1, 3, 0.01
      dendrogram.add 1, 2, 0.02
      dendrogram.add 0, 4, 0.015
      dendrogram.add 1, 4, 0.03

      dendrogram.relabel(ordered: false)
        .steps
        .map { |step| {*step.clusters, step.distance} }
        .should eq [
          {1, 3, 0.01},
          {2, 5, 0.02},
          {0, 4, 0.015},
          {6, 7, 0.03},
        ]

      dendrogram.relabel(ordered: true)
        .steps
        .map { |step| {*step.clusters, step.distance} }
        .should eq [
          {1, 3, 0.01},
          {0, 4, 0.015},
          {2, 5, 0.02},
          {6, 7, 0.03},
        ]
    end
  end
end
