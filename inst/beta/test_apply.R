library(codedoctor)

context("apply")

test_that("convert single apply to parallel", {

    x = matrix(1:10, ncol = 2)

    code = quote(apply(x, 2, max))
    parcode = apply_parallel(code)

    expect_identical(eval(code), eval(parcode))

})


if(FALSE)
{

# Testing code:
n = 1000000L
p = 20L

x = matrix(1:(n*p), ncol = p)

incode = quote(apply(x, 2, max))
parcode = apply_parallel(incode)

system.time(eval(incode))
system.time(eval(parcode))

fast = benchmark_parallel(incode, times = 10L)




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
}
