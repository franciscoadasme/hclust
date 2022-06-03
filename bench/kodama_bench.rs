use rand::Rng;
use std::env;
use std::str::FromStr;
use std::time::Instant;

use kodama::{generic, mst, nnchain, Method};

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
    let rule = match env::var("BENCH_RULE") {
        Ok(val) => Method::from_str(&val).expect("Invalid rule"),
        Err(_) => Method::Ward,
    };
    let method = match env::var("BENCH_RULE") {
        Ok(val) => val,
        Err(_) => "generic".to_string(),
    };

    let best_time = (0..repeats)
        .map(|_| {
            let mut condensed_dism = Vec::<f64>::with_capacity(condensed_size);
            for _ in 0..condensed_size {
                condensed_dism.push(rng.gen());
            }
            let start = Instant::now();
            match method.as_str() {
                "mst" => mst(&mut condensed_dism, size),
                "chain" => nnchain(
                    &mut condensed_dism,
                    size,
                    rule.into_method_chain().expect("Invalid chain rule"),
                ),
                _ => generic(&mut condensed_dism, size, rule),
            };
            return start.elapsed().as_micros();
        })
        .min()
        .unwrap();
    println!("{:.11}", (best_time as f64) / 1000.0);
}
