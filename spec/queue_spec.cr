require "./spec_helper"

describe HClust::IndexPriorityQueue do
  describe "#new" do
    it "creates a queue" do
      queue = HClust::IndexPriorityQueue.new([2.0, 1.0, 10.0, 5.0, 4.0, 4.5])
      queue.to_a.should eq [1, 0, 5, 3, 4, 2]
    end
  end

  describe "#empty?" do
    it "tells if the queue is empty" do
      HClust::IndexPriorityQueue.new(0, &.to_f).empty?.should be_true
      HClust::IndexPriorityQueue.new([2.0, 1.0, 10.0, 5.0, 4.0, 4.5]).empty?.should be_false
    end
  end

  describe "#first" do
    it "raises if empty" do
      expect_raises Enumerable::EmptyError do
        HClust::IndexPriorityQueue.new(0, &.to_f).first
      end
    end
  end

  describe "#first?" do
    it "returns the element with highest priority" do
      queue = HClust::IndexPriorityQueue.new([2.0, 1.0, 10.0, 5.0, 4.0, 4.5])
      queue.first?.should eq 1
    end

    it "returns nil if empty" do
      HClust::IndexPriorityQueue.new(0, &.to_f).first?.should be_nil
    end
  end

  describe "#pop" do
    it "removes and returns the item with highest priority" do
      queue = HClust::IndexPriorityQueue.new([2.0, 1.0, 10.0, 5.0, 4.0, 4.5])
      queue.pop.should eq 1
      queue.to_a.should eq [0, 4, 5, 3, 2]
      queue.pop.should eq 0
      queue.to_a.should eq [4, 3, 5, 2]
      queue.pop.should eq 4
      queue.to_a.should eq [5, 3, 2]
      queue.pop.should eq 5
      queue.to_a.should eq [3, 2]
      queue.pop.should eq 3
      queue.to_a.should eq [2]
      queue.pop.should eq 2
      queue.to_a.should eq([] of Int32)
      queue.pop.should be_nil
    end
  end

  describe "#priority_at" do
    it "returns the priority" do
      queue = HClust::IndexPriorityQueue.new([2.0, 1.0, 10.0, 5.0, 4.0, 4.5])
      queue.priority_at(2).should eq 10
      queue.priority_at(0).should eq 2
    end

    it "raises if index is out of bounds" do
      expect_raises IndexError do
        HClust::IndexPriorityQueue.new(4, &.to_f).priority_at(10)
      end
    end

    it "raises if index is removed" do
      queue = HClust::IndexPriorityQueue.new([2.0, 1.0, 10.0, 5.0, 4.0, 4.5])
      queue.pop.should eq 1
      expect_raises IndexError do
        queue.priority_at(1) # 1 was removed
      end
    end
  end

  describe "#set_priority_at" do
    it "updates the queue with the given priority" do
      queue = HClust::IndexPriorityQueue.new(6) { Float64::MAX }
      [2, 1, 10, 5, 4, 4.5].each_with_index do |priority, i|
        queue.set_priority_at i, priority.to_f
      end
      queue.to_a.should eq [1, 0, 5, 3, 4, 2]
    end
  end
end
