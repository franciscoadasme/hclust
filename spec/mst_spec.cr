require "./spec_helper"

describe HClust do
  describe ".mst" do
    it_linkages_random HClust.mst, HClust::Rule::Single
  end
end
