library(microbenchmark)
library(lattice)

source("covariance.R")


exponents = seq(from = 1, to = 4, length.out = 12)

# Dont' want these to get too huge...
n = round(10^exponents)
p = n[n <= 1000]

np_grid = expand.grid(n = n, p = p)

percent_efficiency = function(n, p, times = 5L, nchunks = 2L){

    x = matrix(rnorm(n * p), nrow = n)
    baseline = microbenchmark(cov(x), times = times)$time

    t_chunked = microbenchmark(cov_chunked(x, nchunks), times = times)$time

    t_parallel_chunked = microbenchmark(cov_with_prechunk_parallel(x), times = times)$time

    xc = split_columns(x, nchunks)
    t_prechunked = microbenchmark(cov_prechunked(xc$chunks, xc$indices), times = times)$time

    # Hopefully doing it a few times and taking the best will eliminate
    # things like gc()
    baseline = 100 * min(baseline)
    data.frame(chunked = baseline / min(t_chunked)
               , prechunked = baseline / min(t_prechunked)
               , parallel_chunked = baseline / min(t_parallel_chunked)
               )
}


time_efficiency = function(n, p, times = 5L, nchunks = 4L){

    x = matrix(rnorm(n * p), nrow = n)
    baseline = microbenchmark(cov(x), times = times)$time

    t_chunked = microbenchmark(cov_chunked(x, nchunks), times = times)$time

    t_parallel_chunked = microbenchmark(cov_with_prechunk_parallel(x), times = times)$time

    xc = split_columns(x, nchunks)
    t_prechunked = microbenchmark(cov_prechunked(xc$chunks, xc$indices), times = times)$time

    # Hopefully doing it a few times and taking the best will eliminate
    # things like gc()
    data.frame(baseline = min(baseline)
               , chunked = min(t_chunked)
               , prechunked = min(t_prechunked)
               , parallel_chunked = min(t_parallel_chunked)
               )
}


set.seed(2318)

times = Map(percent_efficiency, grid$n, grid$p)

grid = cbind(np_grid, do.call(rbind, times))

chunked_plot = levelplot(chunked ~ n * p, grid, scales = list(log = 10)
          , main = "percent efficiency of chunked cov() on n x p matrix")

trellis.device(device="png", filename="cov_chunked_efficiency.png")
print(chunked_plot)
dev.off()

prechunked_plot = levelplot(prechunked ~ n * p, grid, scales = list(log = 10)
          , main = "percent efficiency of pre chunked cov() on n x p matrix")

trellis.device(device="png", filename="cov_prechunked_efficiency.png")
print(prechunked_plot)
dev.off()


# Could use a better color scheme here
parallel_chunked_plot = levelplot(parallel_chunked ~ n * p, grid, scales = list(log = 10)
          , main = "percent efficiency of parallel cov() on n x p matrix")

trellis.device(device="png", filename="cov_prechunked_parallel_eff.png")
print(parallel_chunked_plot)
dev.off()


# For later data analysis
walltimes = Map(time_efficiency, grid$n, grid$p)

w2 = do.call(rbind, walltimes)

cov_times = cbind(np_grid, w2)

write.csv(cov_times, "cov_times.csv")


############################################################
# Generalizing the above
############################################################



plot_pe = function(expr)
{
    exponents = seq(from = 1, to = 4, length.out = 12)
    n = round(10^exponents)
    p = n[n <= 1000]
    grid = expand.grid(n = n, p = p)

    # Pulling this func in because mapply isn't playing nicely with passing in
    # the expression as an argument
    percent_efficiency2 = function(n, p, times = 5L)
    {
        x = matrix(rnorm(n * p), nrow = n)
        baseline = microbenchmark(cov(x), times = times)$time
        alternate = microbenchmark(list = list(expr), times = times)$time
        100 * min(baseline) / min(alternate)
    }

    times = mapply(percent_efficiency2, grid$n, grid$p)

    grid$times = times
    plot = levelplot(times ~ n * p, grid, scales = list(log = 10)
          , main = "percent efficiency of alternate cov() on n x p matrix")
    list(data = grid, plot = plot)
}

pexpr = quote(cov_with_prechunk_parallel(x, nchunks = 4L))

parallel = plot_pe(pexpr)

# TODO: Explain these plots and fit it into a model along with the
# computational complexity of cov.

trellis.device(device="png", filename="cov_prechunked_parallel_eff.png")
print(parallel$plot)
dev.off()
