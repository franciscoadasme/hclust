#include <stdio.h>
#include <fenv.h>
#include <limits>
#include <cstring>
#include <chrono>
#include <random>

// Code by Daniel Müllner
// workaround to make it usable as a standalone version (without R)
bool fc_isnan(double x) { return x != x; }
#include "fastcluster_dm.cpp"

int main(int argc, char **argv)
{
    using std::chrono::duration;
    using std::chrono::high_resolution_clock;

    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_real_distribution<> uniform(0.0, 1.0);

    const char *size_str = getenv("BENCH_SIZE");
    size_t size = size_str ? strtol(size_str, nullptr, 10) : 100;
    size_t condensed_size = (size * (size - 1)) / 2;

    const char *repears_str = getenv("BENCH_REPEATS");
    size_t repeats = repears_str ? strtol(repears_str, nullptr, 10) : 1000;

    double best_time = std::numeric_limits<double>::max();
    for (size_t i = 0; i < repeats; i++)
    {
        double *distmat = new double[condensed_size];
        for (size_t i = 0; i < condensed_size; i++)
        {
            distmat[i] = uniform(gen);
        }
        cluster_result Z2(size - 1);
        double *members = new double[size];
        for (int i = 0; i < size; i++)
            members[i] = 1;

        auto start = high_resolution_clock::now();
        // MST_linkage_core(size, D, Z2);
        NN_chain_core<METHOD_METR_WARD, t_float>(size, distmat, members, Z2);
        duration<double, std::milli> elapsed = high_resolution_clock::now() - start;

        double elapsed_ms = elapsed.count();
        if (elapsed_ms < best_time)
        {
            best_time = elapsed_ms;
        }

        delete[] distmat;
    }
    printf("%.6f\n", best_time);

    // int *merge = new int[2 * (npoints - 1)];
    // double *height = new double[npoints - 1];
    // hclust_fast(npoints, distmat, opt_method, merge, height);
    // delete[] merge;
    // delete[] height;
    // delete[] labels;

    return 0;
}
