require "./spec_helper"

describe HClust do
  describe ".linkage" do
    dism = HClust::DistanceMatrix.new(20) { rand }
    HClust.linkage(dism, :average).should be_close HClust.nn_chain(dism, :average), 1e-12
    HClust.linkage(dism, :centroid).should be_close HClust.generic(dism, :centroid), 1e-12
    HClust.linkage(dism, :complete).should be_close HClust.nn_chain(dism, :complete), 1e-12
    HClust.linkage(dism, :median).should be_close HClust.generic(dism, :median), 1e-12
    HClust.linkage(dism, :single).should be_close HClust.mst(dism), 1e-12
    HClust.linkage(dism, :ward).should be_close HClust.nn_chain(dism, :ward), 1e-12
    HClust.linkage(dism, :weighted).should be_close HClust.nn_chain(dism, :weighted), 1e-12
  end
end
