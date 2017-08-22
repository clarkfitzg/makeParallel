library(microbenchmark)
library(lattice)

source("covariance.R")


exponents = seq(from = 1, to = 4, length.out = 12)

# Dont' want these to get too huge...
n = round(10^exponents)
p = n[n <= 1000]

grid = expand.grid(n = n, p = p)

percent_efficiency = function(n, p, times = 5L, nchunks = 2L){

    x = matrix(rnorm(n * p), nrow = n)
    baseline = microbenchmark(cov(x), times = times)$time
    t_chunked = microbenchmark(cov_chunked(x, nchunks), times = times)$time

    xc = split_columns(x, nchunks)
    t_prechunked = microbenchmark(cov_prechunked(xc$chunks, xc$indices), times = times)$time

    # Hopefully doing it a few times and taking the best will eliminate
    # things like gc()
    baseline = 100 * min(baseline)
    data.frame(chunked = baseline / min(t_chunked)
               , prechunked = baseline / min(t_prechunked)
               )
}

set.seed(2318)

times = Map(percent_efficiency, grid$n, grid$p)

grid = cbind(grid, do.call(rbind, times))

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
