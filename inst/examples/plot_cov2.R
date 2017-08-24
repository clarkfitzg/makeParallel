# Tue Aug 22 16:44:07 PDT 2017
# 
# Does the number of chunks affect the efficiency?

library(microbenchmark)
library(lattice)

source("covariance.R")


# previous work showed a prechunked version was less than 50 percent
# efficient.

# n = 2000, p = 200 means it's not really worth it to go parallel
n = 10000
p = 200
x = matrix(rnorm(n * p), nrow = n)

percent_efficiency = function(nchunks, times = 5L){

    baseline = microbenchmark(cov(x), times = times)$time
    t_chunked = microbenchmark(cov_chunked(x, nchunks), times = times)$time
    t_prechunked = microbenchmark(cov_with_prechunk(x, nchunks), times = times)$time
    t_par_chunked = microbenchmark(cov_with_prechunk_parallel(x, nchunks), times = times)$time

    # Hopefully doing it a few times and taking the best will eliminate
    # things like gc()
    baseline = 100 * min(baseline)
    data.frame(chunked = baseline / min(t_chunked)
               , prechunked = baseline / min(t_prechunked)
               , par_chunked = baseline / min(t_par_chunked)
               )
}

set.seed(2318)

#nchunks = round(seq(from = 2, to = p, length.out = 10))
nchunks = 2:10

times = lapply(nchunks, percent_efficiency)

times = do.call(rbind, times)

png("efficiency_by_chunks.png")

plot(nchunks, times$prechunked
     , ylim = range(times)
     , main = sprintf("Efficiency for chunked cov() on %i x %i matrix", n, p)
     , ylab = "percent efficiency (100% ideal)"
     , xlab = "number of chunks"
     )
points(nchunks, times$chunked, pch = 2)
points(nchunks, times$par_chunked, pch = 3)
legend("topright", c("prechunked", "not prechunked", "parallel"), pch = 1:3)

dev.off()
