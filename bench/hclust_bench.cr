require "../src/hclust"

size = ENV["BENCH_SIZE"]?.try(&.to_i) || 100
repeats = ENV["BENCH_REPEATS"]?.try(&.to_i) || 1_000
rule = ENV["BENCH_RULE"]?.try { |str| HClust::Rule.parse(str) } || HClust::Rule::Ward
method = ENV["BENCH_METHOD"]? || "generic"

best_time = (0...repeats).min_of do
  dism = HClust::DistanceMatrix.new(size) { rand }
  Time.measure do
    case method
    when "mst"   then HClust.mst(dism)
    when "chain" then HClust.nn_chain(rule.to_chain, dism)
    else              HClust.generic(rule, dism)
    end
  end
end

printf "%.6f\n", best_time.total_milliseconds
