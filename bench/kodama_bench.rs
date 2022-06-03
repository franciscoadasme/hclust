use rand::Rng;
use std::env;
use std::time::Instant;

use kodama::{mst, nnchain, MethodChain};

fn main() {
    let mut rng = rand::thread_rng();

    let size = match env::var("BENCH_SIZE") {
        Ok(val) => val.parse::<usize>().unwrap(),
        Err(_) => 100,
    };
    let condensed_size = (size * (size - 1)) / 2;
    let repeats = match env::var("BENCH_REPEATS") {
        Ok(val) => val.parse::<usize>().unwrap(),
        Err(_) => 1_000,
    };

    let best_time = (0..repeats)
        .map(|_| {
            let mut condensed_dism = Vec::<f64>::with_capacity(condensed_size);
            for _ in 0..condensed_size {
                condensed_dism.push(rng.gen());
            }
            let start = Instant::now();
            // let _dendrogram = mst(&mut condensed_dism, observations);
            let _dendrogram = nnchain(&mut condensed_dism, size, MethodChain::Ward);
            return start.elapsed().as_micros();
        })
        .min()
        .unwrap();
    println!("{:.11}", (best_time as f64) / 1000.0);
}
