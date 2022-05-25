require "./spec_helper"
require "spec/helpers/iterate"

describe HClust::IndexList do
  describe "#each" do
    it "yields each index" do
      assert_iterates_yielding (0..9).to_a, HClust::IndexList.new(10).each
    end

    it "yields each neighboring index" do
      assert_iterates_yielding [0, 1, 2, 3, 5, 6, 7, 8, 9],
        HClust::IndexList.new(10).each(omit: 4)
    end

    it "yields each neighboring index after deletion" do
      indexes = HClust::IndexList.new(10)
      indexes.delete 3
      indexes.delete 8
      indexes.delete 1
      assert_iterates_yielding [0, 2, 4, 5, 6, 7, 9], indexes.each(omit: 3)
    end

    it "does not yield if empty" do
      assert_iterates_yielding [] of Int32, HClust::IndexList.new(0).each
    end

    it "does not yield after full deletion" do
      indexes = HClust::IndexList.new(10)
      (0...10).to_a.shuffle.each { |i| indexes.delete i }
      assert_iterates_yielding [] of Int32, indexes.each
    end

    it "yields each index within range" do
      assert_iterates_yielding [2, 3, 4, 5], HClust::IndexList.new(10).each(within: 2..5)
      assert_iterates_yielding [8, 9], HClust::IndexList.new(10).each(within: 8..15)
      assert_iterates_yielding [2, 3, 4], HClust::IndexList.new(10).each(within: 2...5)
      assert_iterates_yielding [5, 6, 7, 8, 9], HClust::IndexList.new(10).each(within: 5..)
      assert_iterates_yielding [5, 6, 7, 8, 9], HClust::IndexList.new(10).each(within: 5...)
      assert_iterates_yielding [0, 1, 2], HClust::IndexList.new(10).each(within: ..2)
      assert_iterates_yielding [0, 1], HClust::IndexList.new(10).each(within: ...2)

      indexes = HClust::IndexList.new(10)
      indexes.delete 3
      indexes.delete 4
      indexes.delete 8
      indexes.delete 1
      assert_iterates_yielding [2, 5], indexes.each(within: 2..5)
      assert_iterates_yielding [5], indexes.each(within: 3..5)
      assert_iterates_yielding [5, 6, 7], indexes.each(within: 3..8)
      assert_iterates_yielding [5, 6, 7, 9], indexes.each(within: 3..9)
      assert_iterates_yielding [5, 6, 7], indexes.each(within: 3...9)
    end

    it "raises if range if out of bounds" do
      expect_raises(IndexError) { HClust::IndexList.new(5).each(within: 10..) { } }
    end
  end

  describe "#first" do
    it "raises if empty" do
      expect_raises Enumerable::EmptyError do
        HClust::IndexList.new(0).first
      end
    end
  end

  describe "#first?" do
    it "returns the first index" do
      indexes = HClust::IndexList.new(10)
      indexes.first?.should eq 0
      indexes.delete 0
      indexes.delete 7
      indexes.delete 2
      indexes.first?.should eq 1
      indexes.delete 1
      indexes.first?.should eq 3
    end

    it "returns nil if empty" do
      HClust::IndexList.new(0).first?.should be_nil
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
      index, distance = indexes.nearest_to(5) do |i|
        (i - 5) ** 2 + i
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

    it "returns the nearest index using a distance matrix and block" do
      indexes = HClust::IndexList.new(10)
      dism = HClust::DistanceMatrix.new(10) do |i, j|
        ((i - j) ** 2 + i + j)
      end
      index, distance = indexes.nearest_to(5, dism) { |i, dis| dis + i }
      index.should eq 4
      distance.should eq 14
    end
  end

  describe "#to_a" do
    it "returns an array of indexes" do
      HClust::IndexList.new(5).to_a.should eq [0, 1, 2, 3, 4]
    end
  end
end
