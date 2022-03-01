#include <stdio.h>
#include <fenv.h>
#include <limits>
#include <cstring>
#include <chrono>

// Code by Daniel Müllner
// workaround to make it usable as a standalone version (without R)
bool fc_isnan(double x) { return x != x; }
#include "fastcluster_dm.cpp"

int main(int argc, char **argv)
{
    using std::chrono::duration;
    using std::chrono::high_resolution_clock;

    int result;

    const char *datafile = "distances.txt";
    FILE *fp = fopen(datafile, "r");
    if (!fp)
    {
        fprintf(stderr, "Cannot open '%s'\n", datafile);
        return 2;
    }

    size_t size;
    result = fscanf(fp, "%ld\n", &size);
    if (result < 1)
    {
        fprintf(stderr, "Invalid header in '%s'\n", datafile);
        return 2;
    }

    size_t condensed_size = (size * (size - 1)) / 2;
    double *distmat = new double[condensed_size];
    double x;
    for (size_t i = 0; i < condensed_size; i++)
    {
        result = fscanf(fp, "%lf", &x);
        if (result == 1)
        {
            distmat[i] = x;
        }
        else
        {
            fprintf(stderr, "Could not read a number\n");
            return 2;
        }
        result = fscanf(fp, "\n");
    }
    fclose(fp);

    const char *repears_str = getenv("BENCH_REPEATS");
    size_t repeats = repears_str ? strtol(repears_str, nullptr, 10) : 10000;

    double best_time = std::numeric_limits<double>::max();
    for (size_t i = 0; i < repeats; i++)
    {
        double D[condensed_size];
        memcpy(&D, distmat, sizeof(double) * condensed_size);
        cluster_result Z2(size - 1);

        auto start = high_resolution_clock::now();
        MST_linkage_core(size, D, Z2);
        duration<double, std::milli> elapsed = high_resolution_clock::now() - start;

        double elapsed_ms = elapsed.count();
        if (elapsed_ms < best_time)
        {
            best_time = elapsed_ms;
        }
    }
    printf("%.6f\n", best_time);

    // int *merge = new int[2 * (npoints - 1)];
    // double *height = new double[npoints - 1];
    // hclust_fast(npoints, distmat, opt_method, merge, height);
    // delete[] merge;
    // delete[] height;
    // delete[] labels;

    delete[] distmat;

    return 0;
}
