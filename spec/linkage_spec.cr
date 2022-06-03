require "./spec_helper"

describe HClust do
  describe ".linkage" do
    dism = HClust::DistanceMatrix.new(20) { rand }
    HClust.linkage(:average, dism).should be_close HClust.nn_chain(:average, dism), 1e-12
    HClust.linkage(:centroid, dism).should be_close HClust.generic(:centroid, dism), 1e-12
    HClust.linkage(:complete, dism).should be_close HClust.nn_chain(:complete, dism), 1e-12
    HClust.linkage(:median, dism).should be_close HClust.generic(:median, dism), 1e-12
    HClust.linkage(:single, dism).should be_close HClust.mst(dism), 1e-12
    HClust.linkage(:ward, dism).should be_close HClust.nn_chain(:ward, dism), 1e-12
    HClust.linkage(:weighted, dism).should be_close HClust.nn_chain(:weighted, dism), 1e-12
  end
end
