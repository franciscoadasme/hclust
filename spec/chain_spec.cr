require "./spec_helper"

describe HClust::NNChain do
  it_linkages_random HClust::NNChain, HClust::Linkage::Single
  it_linkages_random HClust::NNChain, HClust::Linkage::Complete
  it_linkages_random HClust::NNChain, HClust::Linkage::Weighted
  it_linkages_random HClust::NNChain, HClust::Linkage::Ward
  it_linkages_random HClust::NNChain, HClust::Linkage::Average
end
