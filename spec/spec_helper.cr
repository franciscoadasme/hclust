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
