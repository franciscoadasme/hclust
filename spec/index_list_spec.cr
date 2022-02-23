require "./spec_helper"

describe HClust::IndexList do
  describe "#each" do
    it "yields each index" do
      indexes = HClust::IndexList.new(10)

      arr = [] of Int32
      indexes.each { |index| arr << index }
      arr.should eq [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    end

    it "yields each neighboring index" do
      indexes = HClust::IndexList.new(10)
      arr = [] of Int32
      indexes.each(omit: 4) { |i| arr << i }
      arr.should eq [0, 1, 2, 3, 5, 6, 7, 8, 9]
    end

    it "yields each neighboring index after deletion" do
      indexes = HClust::IndexList.new(10)
      indexes.delete 3
      indexes.delete 8
      indexes.delete 1

      arr = [] of Int32
      indexes.each(omit: 3) { |i| arr << i }
      arr.should eq [0, 2, 4, 5, 6, 7, 9]
    end
  end

  describe "#delete" do
    it "deletes a index" do
      indexes = HClust::IndexList.new(5)
      indexes.to_a.should eq [0, 1, 2, 3, 4]
      indexes.delete 2
      indexes.to_a.should eq [0, 1, 3, 4]
      indexes.delete 4
      indexes.to_a.should eq [0, 1, 3]
      indexes.delete 0
      indexes.to_a.should eq [1, 3]
      indexes.delete 3
      indexes.to_a.should eq [1]
      indexes.delete 1
      indexes.to_a.should eq([] of Int32)
    end
  end

  describe "#includes?" do
    it "returns true if index is active" do
      indexes = HClust::IndexList.new(10)
      10.times do |i|
        indexes.includes?(i).should be_true
      end
      indexes.delete 0
      indexes.includes?(0).should be_false
      indexes.delete 5
      indexes.includes?(5).should be_false
    end
  end

  describe "#nearest_to" do
    it "returns the nearest index using the block's return value" do
      indexes = HClust::IndexList.new(10)
      index, distance = indexes.nearest_to(5) do |index|
        (index - 5) ** 2 + index
      end
      index.should eq 4
      distance.should eq 5
    end

    it "returns the nearest index using a distance matrix" do
      indexes = HClust::IndexList.new(10)
      dism = HClust::DistanceMatrix.new(10) do |i, j|
        ((i - j) ** 2 + i + j)
      end
      index, distance = indexes.nearest_to(5, dism)
      index.should eq 4
      distance.should eq 10
    end
  end

  describe "#to_a" do
    it "returns an array of indexes" do
      HClust::IndexList.new(5).to_a.should eq [0, 1, 2, 3, 4]
    end
  end
end
