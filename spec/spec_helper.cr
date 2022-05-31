require "spec"
require "../src/hclust"

macro it_linkages(description, method, expected)
  it {{description}} do
    {% precision = expected.map(&.[2].stringify.split(".").last.size).sort.first %}
    {% precision = 11 if precision > 11 %}
    {{method.id}}
      .linkage
      .steps
      .map { |step| {step.nodes[0], step.nodes[1], step.distance.round({{precision}})} }
      .to_a
      .should eq {{expected}}
  end
end

macro it_linkages_random(method, rule)
  it "using the {{rule.id.downcase}} linkage" do
    %dism = HClust::DistanceMatrix.new(20) { rand }
    {{method.id}}{% unless method.stringify.includes?("MST") %}({{rule.id}}){% end %}.new(%dism).linkage.should eq \
      HClust::Primitive({{rule.id}}).new(%dism).linkage
  end
end
