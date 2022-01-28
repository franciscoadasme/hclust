require "./spec_helper"

describe HClust::DistanceMatrix do
  describe "#new" do
    it "creates a zero matrix" do
      mat = HClust::DistanceMatrix.new(5)
      mat.to_a.should eq [0.0] * 10
    end

    it "creates a matrix with block" do
      mat = HClust::DistanceMatrix.new(5) do |i, j|
        10 * (i + 1) + j + 1
      end
      mat.to_a.should eq [12, 13, 14, 15, 23, 24, 25, 34, 35, 45]
    end

    it "creates a matrix from an array" do
      mat = HClust::DistanceMatrix.new([12.0, 13.0, 14.0, 23.0, 24.0, 34.0])
      mat.size.should eq 4
      mat[0, 1].should eq 12
      mat[0, 2].should eq 13
      mat[2, 1].should eq 23
    end

    it "raises if array is invalid" do
      expect_raises(ArgumentError, "Invalid condensed distance matrix") do
        HClust::DistanceMatrix.new([12.0, 13.0])
      end
    end

    it "raises if array is empty" do
      expect_raises(Enumerable::EmptyError) do
        HClust::DistanceMatrix.new([] of Float64)
      end
    end

    it "raises if distance is nan" do
      expect_raises(ArgumentError, "Invalid distance (NaN)") do
        HClust::DistanceMatrix.new(5) do
          Float64::NAN
        end
      end
    end
  end

  describe "#[]" do
    it "raises if out of bounds" do
      expect_raises(IndexError) do
        HClust::DistanceMatrix.new(5)[5, 3]
      end
    end
  end

  describe "#[]?" do
    it "returns distance between two elements" do
      mat = HClust::DistanceMatrix.new(5) do |i, j|
        10 * (i + 1) + j + 1
      end
      mat[0, 1]?.should eq 12
      mat[2, 3]?.should eq 34
      mat[3, 2]?.should eq 34
    end

    it "returns zero for diagonal" do
      mat = HClust::DistanceMatrix.new(5) do |i, j|
        10 * (i + 1) + j + 1
      end
      mat[0, 0]?.should eq 0
      mat[1, 1]?.should eq 0
      mat[2, 2]?.should eq 0
      mat[3, 3]?.should eq 0
      mat[4, 4]?.should eq 0
    end

    it "returns nil if out of bounds" do
      mat = HClust::DistanceMatrix.new(5)
      mat[0, 10]?.should be_nil
      mat[40, 3]?.should be_nil
      mat[11, 6]?.should be_nil
    end
  end

  describe "#[]=" do
    it "sets the distance between two elements" do
      mat = HClust::DistanceMatrix.new(5) do |i, j|
        10 * (i + 1) + j + 1
      end
      (mat[1, 1] = 0).should eq 0
      mat[2, 3].should eq 34
      mat[2, 3] = -0.457
      mat[2, 3].should eq -0.457
      mat[3, 2].should eq -0.457
      mat[4, 1] = -2.301
      mat[1, 4].should eq -2.301
      mat[4, 1].should eq -2.301
    end

    it "raises if elements are the same" do
      expect_raises(IndexError, "The distances at the diagonal must be zero") do
        mat = HClust::DistanceMatrix.new(5)
        mat[3, 3] = 123
      end
    end

    it "raises if out of bounds" do
      expect_raises(IndexError) do
        mat = HClust::DistanceMatrix.new(5)
        mat[5, 3] = 25
      end
    end
  end

  describe "#==" do
    it "compares two matrices" do
      mat = HClust::DistanceMatrix.new(5) { |i, j| 10 * (i + 1) + j + 1 }
      mat.should eq mat
      mat.should eq HClust::DistanceMatrix.new(5) { |i, j| 10 * (i + 1) + j + 1 }
      mat.should_not eq HClust::DistanceMatrix.new(5)
    end
  end

  describe "#clone" do
    it "returns a clone of the matrix" do
      mat = HClust::DistanceMatrix.new(5) { |i, j| 10 * (i + 1) + j + 1 }
      other = mat.clone
      other.should_not be mat
      other.should eq mat
    end
  end

  describe "#map" do
    it "returns a new distance matrix with the elements returned by the block" do
      dism = HClust::DistanceMatrix.new(5) do |i, j|
        10 * (i + 1) + j + 1
      end
      other = dism.map &.*(2)
      other.should_not be dism
      other.to_a.should eq [24, 26, 28, 30, 46, 48, 50, 68, 70, 90]
    end
  end

  describe "#map!" do
    it "replaces the elements with the values returned by the given block" do
      dism = HClust::DistanceMatrix.new(5) do |i, j|
        10 * (i + 1) + j + 1
      end
      other = dism.map! &.*(2)
      other.should be dism
      dism.to_a.should eq [24, 26, 28, 30, 46, 48, 50, 68, 70, 90]
    end
  end

  describe "#to_a" do
    it "returns a flatten array" do
      mat = HClust::DistanceMatrix.new(5)
      mat.to_a.should eq Array(Float64).new(10, 0)
    end
  end

  describe "#to_unsafe" do
    it "returns a pointer to the internal array" do
      mat = HClust::DistanceMatrix.new(5) do |i, j|
        10 * (i + 1) + j + 1
      end
      ptr = mat.to_unsafe
      ptr.should be_a Pointer(Float64)
      ptr[0].should eq 12
      ptr[2].should eq 14
      ptr[8].should eq 35
    end
  end

  describe "#unsafe_fetch" do
    it "returns the distance between two elements (one index)" do
      mat = HClust::DistanceMatrix.new(5) do |i, j|
        10 * (i + 1) + j + 1
      end
      mat.unsafe_fetch(0).should eq 12
      mat.unsafe_fetch(1).should eq 13
      mat.unsafe_fetch(7).should eq 34
    end

    it "returns the distance between two elements" do
      mat = HClust::DistanceMatrix.new(5) do |i, j|
        10 * (i + 1) + j + 1
      end
      mat.unsafe_fetch(0, 1).should eq 12
      mat.unsafe_fetch(2, 3).should eq 34
      mat.unsafe_fetch(3, 2).should eq 34
    end
  end

  describe "#unsafe_put" do
    it "sets the distance between two elements (one index)" do
      mat = HClust::DistanceMatrix.new(5) do |i, j|
        10 * (i + 1) + j + 1
      end
      mat.unsafe_fetch(6).should eq 25
      mat.unsafe_put 6, 2.5
      mat.unsafe_fetch(6).should eq 2.5
    end

    it "sets the distance between two elements" do
      mat = HClust::DistanceMatrix.new(5) do |i, j|
        10 * (i + 1) + j + 1
      end
      mat[2, 3].should eq 34
      mat.unsafe_put 2, 3, -0.457
      mat[2, 3].should eq -0.457
      mat[3, 2].should eq -0.457
      mat.unsafe_put 4, 1, -2.301
      mat[1, 4].should eq -2.301
      mat[4, 1].should eq -2.301
    end
  end
end
