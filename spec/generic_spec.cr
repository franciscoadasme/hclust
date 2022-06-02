require "./spec_helper"

describe HClust::Generic do
  it_linkages_random HClust::Generic, HClust::Linkage::Single
  it_linkages_random HClust::Generic, HClust::Linkage::Complete
  it_linkages_random HClust::Generic, HClust::Linkage::Average
  it_linkages_random HClust::Generic, HClust::Linkage::Weighted
  it_linkages_random HClust::Generic, HClust::Linkage::Ward
  it_linkages_random HClust::Generic, HClust::Linkage::Median
  it_linkages_random HClust::Generic, HClust::Linkage::Centroid
end
