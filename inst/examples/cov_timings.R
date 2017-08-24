# Tue Jul 11 16:45:01 PDT 2017
# In my summer proposal I mentioned doing a sample covariance calculation in
# parallel.

library(microbenchmark)

library(autoparallel)
source("covariance.R")


n = 1e5
p = 100L
set.seed(38290)
x = matrix(rnorm(n * p), nrow = n)

c0 = cov(x)

cm = cov_matrix(x)
cc = cov_chunked(x)
ccp = cov_chunked_parallel(x)
ccl = cov_loop(x)

xc = split_columns(x, nchunks = 4L)
cpc = cov_prechunked(xc$chunks, xc$indices)

cwpc = cov_with_prechunk(x)

cwpcp = cov_with_prechunk_parallel(x)

max(abs(c0 - cwpcp))

# Recording lower quartile times

bm = function(code, times = 10L, file = "benchmarks.txt"){
    expr = substitute(code)
    bm = microbenchmark(list = list(expr), times = times)
    print(bm)
    obs = data.frame(expr = deparse(expr)
                     , time = bm[, "time"]
                     , n = n
                     , p = p
                     , systime = Sys.time()
                     , sysname = unname(Sys.info()["sysname"])
                     )
    write.table(obs, file, append = TRUE, row.names = FALSE, col.names = FALSE)
}

# 130 ms for n = 1e6, p = 5
# 1.16 s for n = 1e7, p = 5
# 267 ms for n = 1e6, p = 10 Strange- formerly was 812 for same paramaters
# => something I don't understand here.
bm(cov_matrix(x))

# 31 ms for n = 1e6, p = 5
# 0.314 s for n = 1e7, p = 5
# 93 ms for n = 1e6, p = 10 (timings very consistent)
bm(cov(x))

# 78 ms for n = 1e6, p = 5
# 1.14 s for n = 1e7, p = 5
# 326 ms for n = 1e6, p = 10
bm(cov_chunked(x, nchunks = 2L))

# 96 ms for n = 1e6, p = 5
# 0.967 s for n = 1e7, p = 5
# 235 ms for n = 1e6, p = 10
bm(cov_chunked_parallel(x, nchunks = 2L))

# 564 ms for n = 1e6, p = 10
bm(cov_chunked_parallel(x, nchunks = 10L))

# Seems like some other system load happening?
bm(cov_loop(x))

# Together these add up to the time for cov_chunked. But cov_prechunked is
# still twice as slow as regular cov.
bm(split_columns(x, nchunks = 4L))
bm(cov_prechunked(xc$chunks, xc$indices))


# Why is the speed of cov_chunked(x) so much slower than cov(x) for large
# n? I would expect that the time to deal with the blocking is amortized by
# the larger data set.
# Lets explore this further.


Rprof("cov_chunked.out")
#replicate(10, cov_chunked(x))
replicate(10, cov_prechunked(xc$chunks, xc$indices))
Rprof(NULL)

# So it spends an enormous amount of time inside is.data.frame.
summaryRprof("cov_chunked.out")

library(profvis)

# Handier visualization
profvis({
    cc = cov_chunked(x)
})

############################################################

# Figure out how this gets called
newcounter = function()
{
    count = 0
    function() count <<- count + 1
}

count1 = newcounter()

trace(is.data.frame, count1)

cov_chunked(x)

# The chunked version calls is.data.frame 110 times for 10 chunks
# And 6 times for 2 chunks
environment(count1)$count

# While the base version calls it 2 times
cov(x)

# This makes total sense, because a version with k chunks calls
# cov() (k + 1) * k / 2 times => (k + 1) * k calls to is.data.frame.
# Then I can't get around the number of times is.data.frame is called

untrace(is.data.frame)

# Then is is.data.frame() just super slow?
# cov_chunked takes around 265 ms for the 2 chunk case, calling
# is.data.frame 6 times. This means is.data.frame should take around 20 ms:
0.5 * 265 / 6
# Which is absurdly slow. So something else is going on, and I don't know
# what. Some sanity checks:

# Takes less than a microsecond
microbenchmark(is.data.frame(x), times = 10L)

# Takes less than a microsecond
microbenchmark(inherits(x, "data.frame"), times = 10L)
