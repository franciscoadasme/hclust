require "./spec_helper"

describe HClust::UnionFind do
  describe "#find" do
    it "finds disjoint clusters" do
      set = HClust::UnionFind.new(5)
      5.times do |i|
        set.find(i).should eq i
      end
    end

    it "finds joint clusters" do
      set = HClust::UnionFind.new(5)
      set.union(1, 3).should eq 5
      set.find(0).should eq 0
      set.find(1).should eq 5
      set.find(2).should eq 2
      set.find(3).should eq 5
      set.find(4).should eq 4
      set.find(5).should eq 5

      set.union(5, 2).should eq 6
      set.find(0).should eq 0
      set.find(1).should eq 6
      set.find(2).should eq 6
      set.find(3).should eq 6
      set.find(4).should eq 4
      set.find(5).should eq 6
      set.find(6).should eq 6

      set.union(0, 4).should eq 7
      set.find(0).should eq 7
      set.find(1).should eq 6
      set.find(2).should eq 6
      set.find(3).should eq 6
      set.find(4).should eq 7
      set.find(5).should eq 6
      set.find(6).should eq 6
      set.find(7).should eq 7

      set.union(6, 7).should eq 8
      (0..8).each do |i|
        set.find(i).should eq 8
      end
    end

    it "returns nil if out of bounds" do
      set = HClust::UnionFind.new(5)
      set.find(8).should be_nil
      set.find(-5).should be_nil
    end
  end

  describe "#union" do
    it "does not union joint clusters" do
      set = HClust::UnionFind.new(5)
      set.union(1, 3).should eq 5
      set.union(1, 3).should be_nil
      set.find(0).should eq 0
      set.find(1).should eq 5
      set.find(2).should eq 2
      set.find(3).should eq 5
      set.find(4).should eq 4
      set.find(5).should eq 5
    end

    it "raises if index out of bounds" do
      expect_raises IndexError do
        HClust::UnionFind.new(5).union(1, 7)
      end
      expect_raises IndexError do
        HClust::UnionFind.new(5).union(8, 3)
      end
      expect_raises IndexError do
        HClust::UnionFind.new(5).union(8, 6)
      end
    end
  end
end
