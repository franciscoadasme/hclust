require "spec"
require "../src/hclust"

macro it_linkages(description, method, expected)
  it {{description}} do
    {% precision = expected.map(&.[2].stringify.split(".").last.size).sort.first %}
    {% precision = 11 if precision > 11 %}
    {{method.id}}
      .steps
      .map { |step| {step.nodes[0], step.nodes[1], step.distance.round({{precision}})} }
      .to_a
      .should eq {{expected}}
  end
end

macro it_linkages_random(method, rule, seed = nil)
  it "using the {{rule.id.downcase}} linkage" do
    %random = Random.new{% if seed %}({{seed}}){% end %}
    %dism = HClust::DistanceMatrix.new(20) { %random.rand }

    {{method.id}}({% unless method.stringify.includes?("mst") %}{{rule.id}}, {% end %}%dism).should eq \
      HClust.primitive({{rule.id.gsub(/Chain/, "")}}, %dism)
  end
end
