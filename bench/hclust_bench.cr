require "../src/hclust"

path = ARGV[0]? || abort "error: Missing test file"
condensed_arr = File.open(path) do |io|
  size = io.read_line.to_i
  Array(Float64).new((size * (size - 1)) // 2).tap do |arr|
    io.each_line do |line|
      line.split do |token|
        arr << token.to_f
      end
    end
  end
end

repeats = ENV["BENCH_REPEATS"]?.try(&.to_i) || 10_000
best_time = (0...repeats).min_of do
  dism = HClust::DistanceMatrix.new condensed_arr
  Time.measure do
    HClust.mst(dism)
  end
end

printf "%.6f\n", best_time.total_milliseconds
