require "./spec_helper"

describe HClust do
  describe ".nn_chain" do
    it_linkages_random HClust.nn_chain, HClust::ChainRule::Single
    it_linkages_random HClust.nn_chain, HClust::ChainRule::Complete
    it_linkages_random HClust.nn_chain, HClust::ChainRule::Weighted
    it_linkages_random HClust.nn_chain, HClust::ChainRule::Ward
    it_linkages_random HClust.nn_chain, HClust::ChainRule::Average
  end
end
