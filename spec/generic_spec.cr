require "./spec_helper"

describe HClust do
  describe ".generic" do
    it_linkages_random HClust.generic, HClust::Rule::Single
    it_linkages_random HClust.generic, HClust::Rule::Complete
    it_linkages_random HClust.generic, HClust::Rule::Average
    it_linkages_random HClust.generic, HClust::Rule::Weighted
    it_linkages_random HClust.generic, HClust::Rule::Ward
    it_linkages_random HClust.generic, HClust::Rule::Median
    it_linkages_random HClust.generic, HClust::Rule::Centroid
  end
end
