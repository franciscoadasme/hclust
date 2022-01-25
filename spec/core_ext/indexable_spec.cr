require "spec"
require "../../src/core_ext/indexable"

describe Indexable do
  describe "argmax" do
    it "returns the index of the maximum value" do
      [5, 4, 2, 1, 3, 6, 0, -1].argmax.should eq 5
    end

    it "returns the index of the maximum value starting at offset" do
      [5, 4, 2, 1, 3, 6, 0, -1].argmax(offset: 6).should eq 6
    end

    it "raises if empty" do
      expect_raises Enumerable::EmptyError do
        ([] of Int32).argmax
      end
    end

    it "raises if offset is out of bounds" do
      expect_raises Enumerable::EmptyError do
        [5, 4, 2, 1, 3, 6, 0, -1].argmax(offset: 10)
      end
    end

    it "raises if not comparable" do
      expect_raises ArgumentError do
        [-1.0, Float64::NAN, -3.0].argmax
      end
    end
  end

  describe "argmax?" do
    it "returns nil if empty" do
      ([] of Int32).argmax?.should be_nil
    end
  end

  describe "argmax_by" do
    it "returns the index of the maximum block-returned value" do
      [5, 4, 2, 1, 3, 6, 0, -1].argmax_by(&.-).should eq 7
    end
  end

  describe "argmax_by?" do
    it "returns nil if empty" do
      ([] of Int32).argmax_by?(&.-).should be_nil
    end
  end

  describe "argmin" do
    it "returns the index of the minimum value" do
      [5, 4, 2, 1, 3, 6].argmin.should eq 3
    end

    it "returns the index of the minimum value starting at offset" do
      [5, 4, 2, 1, 3, 6].argmin(offset: 4).should eq 4
    end

    it "raises if empty" do
      expect_raises Enumerable::EmptyError do
        ([] of Int32).argmin
      end
    end

    it "raises if offset is out of bounds" do
      expect_raises Enumerable::EmptyError do
        [5, 4, 2, 1, 3, 6].argmin(offset: 10)
      end
    end

    it "raises if not comparable" do
      expect_raises ArgumentError do
        [-1.0, Float64::NAN, -3.0].argmin
      end
    end
  end

  describe "argmin?" do
    it "returns nil if empty" do
      ([] of Int32).argmin?.should be_nil
    end
  end

  describe "argmin_by" do
    it "returns the index of the minimum block-returned value" do
      [5, 4, 2, 1, 3, 6].argmin_by(&.-).should eq 5
    end
  end

  describe "argmin_by?" do
    it "returns nil if empty" do
      ([] of Int32).argmin_by?(&.-).should be_nil
    end
  end
end
