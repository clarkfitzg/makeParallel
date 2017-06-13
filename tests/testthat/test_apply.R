library(autoparallel)

context("apply")

test_that("convert apply to parallel", {

    x = matrix(1:10, ncol = 2)

    incode = quote(apply(x, 2, max))


})


# Testing code:
n = 100000L
p = 20L

x = matrix(1:10, ncol = 2)
incode = quote(apply(x, 2, max))
parcode = apply_parallel(incode)

eval(incode)
eval(parcode)

library(microbenchmark)

bm = microbenchmark(eval(incode), eval(parcode))

# Distribution of these timings?
# Most are small, with just a few high outliers (likely GC)
# Right skew

par(mfrow = c(2, 2))

tapply(bm$time, bm$expr, function(x){
           qqnorm(x)
           qqline(x)
        })
tapply(bm$time, bm$expr, hist)

