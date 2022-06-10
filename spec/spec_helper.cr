require "spec"
require "../src/hclust"

module Spec
  struct CloseExpectation(T, D)
    def match(actual_value : HClust::Dendrogram)
      return false unless @expected_value.is_a?(HClust::Dendrogram)
      return false unless actual_value.observations == @expected_value.observations
      actual_value.steps.zip(@expected_value.steps) do |x, y|
        return false unless x.clusters == y.clusters &&
                            (x.distance - y.distance).abs <= @delta
      end
      true
    end
  end
end

macro it_linkages(description, method, expected)
  it {{description}} do
    {% precision = expected.map(&.[2].stringify.split(".").last.size).sort.first %}
    {% precision = 11 if precision > 11 %}
    {{method.id}}
      .steps
      .map { |step| {step.clusters[0], step.clusters[1], step.distance.round({{precision}})} }
      .to_a
      .should eq {{expected}}
  end
end

macro it_linkages_random(method, rule, size = 20, delta = 1e-12, seed = nil)
  it "using the {{rule.id.split("::")[-1].downcase.id}} linkage" do
    %random = Random.new{% if seed %}({{seed}}){% end %}
    %dism = HClust::DistanceMatrix.new({{size}}) { %random.rand }

    {% if method.stringify.includes?("mst") %}
      {{method.id}}(%dism.clone) \
    {% else %}
      {{method.id}}({{rule.id}}, %dism.clone) \
    {% end %}
      .should be_close \
      HClust.primitive({{rule.id.gsub(/Chain/, "")}}, %dism), {{delta}}
  end
end
