library(microbenchmark)
library(lattice)

source("covariance.R")

npts = 1e6
p = c(5, 10, 20, 50, 100, 250, 1000)

grid = expand.grid(p = p, n = p)

percent_efficiency = function(n, p, times = 5L){

    x = matrix(rnorm(n * p), nrow = n)
    t0 = microbenchmark(cov(x), times = times)$time
    t1 = microbenchmark(cov_chunked(x), times = times)$time

    # Hopefully doing it a few times and taking the best will eliminate
    # things like gc()
    100 * min(t0) / min(t1)
}

set.seed(2318)
grid$eff = Map(percent_efficiency, grid$n, grid$p)

levelplot(eff ~ n * p, grid, scales = list(log = 10)
          , main = "percent efficiency of chunked cov() on n x p matrix")

