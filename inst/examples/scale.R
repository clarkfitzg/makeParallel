# Mon Aug 28 16:33:46 PDT 2017
#
# sweep() used to implement scale() is inefficient. Profiling shows that
# only 2% of the time is spent in colMeans. The only other thing to do is
# subtract the mean, which should be fast, but isn't because memory
# layout requires a transpose to use recycling (broadcasting).
#
# But I don't know how to do any better short of writing in C

library(microbenchmark)

n = 10000
p = 100

x = matrix(rnorm(n * p), nrow = n)


# This isn't any better!!
scale2 = function (x)
{
    n = nrow(x)
    mu = colMeans(x)
    #mu_broadcasted = matrix(rep(mu, each = n), nrow = n)
    mu_broadcasted = rep(mu, each = n)
    x - mu_broadcasted
}


# Takes about the same time as base::scale.default
scale3 = function (x)
{
    n = nrow(x)
    mu = colMeans(x)
    # Tricky broadcasting
    t(t(x) - mu)
}


# Bad again
scale4 = function (x)
{
    n = nrow(x)
    mu = colMeans(x)
    t(apply(x, 1L, `-`, mu))
}



s1 = scale(x, center = TRUE, scale = FALSE)
s2 = scale2(x)
s3 = scale3(x)
s4 = scale4(x)

max(abs(s1 - s2))
max(abs(s1 - s3))
max(abs(s1 - s4))

microbenchmark(scale(x, center = TRUE, scale = FALSE), times = 10L)

microbenchmark(scale2(x), times = 10L)

microbenchmark(scale3(x), times = 10L)

microbenchmark(scale4(x), times = 10L)

Rprof()
replicate(100, scale(x))
Rprof(NULL)

summaryRprof()
