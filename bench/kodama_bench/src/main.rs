use std::env;
use std::fs::File;
use std::io::{self, BufRead};
use std::time::Instant;

use kodama::mst;

fn main() {
    let file = File::open("../distances.txt").unwrap();
    let mut io = io::BufReader::new(file);

    let mut line = String::new();
    io.read_line(&mut line).expect("Could not read header");
    let observations: usize = line.trim_end().parse().expect("Invalid size at header");
    let condensed_size = (observations * (observations - 1)) / 2;
    let mut condensed_mat: Vec<f64> = Vec::with_capacity(condensed_size);
    for line in io.lines() {
        for num in line.unwrap().split_whitespace() {
            condensed_mat.push(num.parse().unwrap());
        }
    }

    let repeats = match env::var("BENCH_REPEATS") {
        Ok(val) => val.parse::<usize>().unwrap(),
        Err(_) => 10_000,
    };

    let best_time = (0..repeats)
        .map(|_| {
            let mut data = condensed_mat.clone();
            let start = Instant::now();
            let _dendrogram = mst(&mut data, observations);
            return start.elapsed().as_micros();
        })
        .min()
        .unwrap();
    println!("{:.11}", (best_time as f64) / 1000.0);
}
