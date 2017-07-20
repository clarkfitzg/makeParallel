# Tue Jul 11 16:45:01 PDT 2017
# In my summer proposal I mentioned doing a sample covariance calculation in
# parallel.

library(microbenchmark)

library(autoparallel)
source("covariance.R")


n = 1e7
p = 5
set.seed(38290)
x = matrix(rnorm(n * p), nrow = n)

c0 = cov(x)

cm = cov_matrix(x)

cc = cov_chunked(x)

ccp = cov_chunked_parallel(x)

# 130 ms for n = 1e6, p = 5
# 1.16 s for n = 1e7, p = 5
microbenchmark(cov_matrix(x), times = 10L)

# 31 ms for n = 1e6, p = 5
# 0.314 s for n = 1e7, p = 5
microbenchmark(cov(x), times = 10L)

# 78 ms for n = 1e6, p = 5
# 1.14 s for n = 1e7, p = 5
microbenchmark(cov_chunked(x), times = 10L)

# 96 ms for n = 1e6, p = 5
# 0.967 s for n = 1e7, p = 5
microbenchmark(cov_chunked_parallel(x), times = 10L)



# Why is the speed of cov_chunked(x) so much slower than cov(x) for large
# n? I would expect that the time to deal with the blocking is amortized by
# the larger data set.
# Lets explore this further.

Rprof("cov_chunked.out")
cov_chunked(x)
Rprof(NULL)

# So it spends an enormous amount of time inside is.data.frame.
summaryRprof("cov_chunked.out")


library(profvis)

# Handier visualization
profvis({
    cc = cov_chunked(x)
})

