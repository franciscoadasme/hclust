require "../src/hclust"

size = ENV["BENCH_SIZE"]?.try(&.to_i) || 100
repeats = ENV["BENCH_REPEATS"]?.try(&.to_i) || 1_000

best_time = (0...repeats).min_of do
  dism = HClust::DistanceMatrix.new(size) { rand }
  Time.measure do
    # HClust.mst(dism)
    HClust.nn_chain(:ward, dism)
  end
end

printf "%.6f\n", best_time.total_milliseconds
