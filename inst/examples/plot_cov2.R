# Tue Aug 22 16:44:07 PDT 2017
# 
# Does the number of chunks affect the efficiency?

library(microbenchmark)
library(lattice)

source("covariance.R")


# previous work showed a prechunked version was less than 50 percent
# efficient.
n = 2000
p = 200
x = matrix(rnorm(n * p), nrow = n)

percent_efficiency = function(nchunks, times = 5L){

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

nchunks = round(seq(from = 2, to = p, length.out = 10))

times = lapply(nchunks, percent_efficiency)

times = do.call(rbind, times)

png("efficiency_by_chunks.png")

plot(nchunks, times$prechunked
     , main = sprintf("Efficiency for chunked cov() on %i x %i matrix", n, p)
     , ylab = "percent efficiency (100% ideal)"
     , xlab = "number of chunks"
     )
points(nchunks, times$chunked, pch = 2)
legend("topright", c("prechunked", "not prechunked"), pch = 1:2)

dev.off()
