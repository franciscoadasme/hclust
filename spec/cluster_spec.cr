require "./spec_helper"

describe HClust do
  describe ".centroids" do
    it "returns N clusters' centroids" do
      positions = fake_positions

      dism = HClust::DistanceMatrix.new(positions) { |u, v| euclidean(u, v) }
      dendrogram = HClust.linkage(dism, :centroid)
      clusters = dendrogram.flatten(count: 3)
      expected = clusters.map { |idxs| positions[idxs[dism[idxs].centroid]] }

      actual = HClust.centroids(positions, 3, :centroid) { |u, v| euclidean(u, v) }
      actual.should eq expected
    end

    it "returns clusters' centroids by distance cutoff" do
      positions = fake_positions

      dism = HClust::DistanceMatrix.new(positions) { |u, v| euclidean(u, v) }
      dendrogram = HClust.linkage(dism, :centroid)
      clusters = dendrogram.flatten(height: 1)
      expected = clusters.map { |idxs| positions[idxs[dism[idxs].centroid]] }

      actual = HClust.centroids(positions, cutoff: 1) { |u, v| euclidean(u, v) }
      actual.should eq expected
    end
  end

  describe ".cluster" do
    it "returns grouped values" do
      positions = fake_positions
      HClust.cluster(positions, cutoff: 4) { |u, v| euclidean(u, v) }.should eq [
        [0, 3, 6, 7, 9].map { |i| positions[i] },
        [1, 5, 8].map { |i| positions[i] },
        [2, 4].map { |i| positions[i] },
      ]
    end
  end

  describe ".cluster" do
    it "returns N grouped values" do
      positions = fake_positions
      HClust.cluster(positions, 2) { |u, v| euclidean(u, v) }.should eq [
        [0, 1, 3, 5, 6, 7, 8, 9].map { |i| positions[i] },
        [2, 4].map { |i| positions[i] },
      ]
    end
  end
end

private def fake_positions
  [
    [-0.30818828, 2.70462841, 1.84344886],
    [2.9666203, -1.39874721, 4.76223947],
    [3.21737027, 4.09489028, -4.60403434],
    [-3.51140292, -0.83953645, 2.31887739],
    [2.08457843, 4.24960773, -3.91378835],
    [2.88992367, -0.97659082, 0.75464131],
    [0.43808545, 3.70042294, 4.99126146],
    [-1.71676206, 4.93399583, 0.27392482],
    [1.12130963, -1.09646418, 1.45833231],
    [-3.45524705, 0.92812111, 0.15155981],
  ]
end

private def euclidean(u, v)
  Math.sqrt (0...u.size).sum { |i| (u[i] - v[i])**2 }
end
