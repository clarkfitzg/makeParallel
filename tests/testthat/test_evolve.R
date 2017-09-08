
# Include y to match the signature for crossprod()
crossprod_flops = function(x, y)
{
    n = nrow(x)
    p = ncol(x)
    (2*n - 1) * p * (p + 1) / 2
}

n = 20
p = 2
x = matrix(rnorm(n * p), nrow = n)
x2 = matrix(rnorm(2 * n * p), nrow = n)
 


############################################################

test_that("get_timings", {

f = function(x) 20

f2 = smartfunc(f)

f2(50)

timings = get("timings", environment(f2))

expect_true(is.data.frame(timings))

})



test_that("smartfunc with metadata function", {

cp = smartfunc(crossprod, crossprod_flops)

replicate(10, cp(x))
replicate(10, cp(x2))

predict(cp, x)

environment(cp)

})



test_that("prediction of smartfunc", {

sleeptime = 0.1
epsilon = sleeptime / 2

f = function(x)
{
    Sys.sleep(sleeptime)
}

f2 = smartfunc(f)

# This is an implementation detail, I hesitate to test it.
expect_equal(predict(f2, 100), -Inf)

# Order important here! Function call forces a timing
f2(50)

# Prediction time is in nanoseconds
time_expected = predict(f2, 100) / 1e9

expect_gt(time_expected, sleeptime - epsilon)
expect_lt(time_expected, sleeptime + epsilon)

})


test_that("evolve with multiple implementations", {

ffast = function(x) "fast"
fslow = function(x){
    Sys.sleep(0.001)
    "slow"
}

f = evolve(fslow, ffast)

f(1)
f(2)
f(3)
f(4)

expect_equal(f(5), "fast")


})



# All details subject to change
test_that(".ap global variable is populated", {

# This will likely change to something more automatic.
autoparallel::init()

#debug(autoparallel:::startstop)

trace_timings(crossprod, metadata_func = crossprod_flops)

crossprod(x)

crossprod(x)

untrace(crossprod)

timings = .ap$crossprod

expect_equal(nrow(timings), 2)

expect_gte(ncol(timings), 3)

})


test_that("defaults for trace_timings", {

skip("The way I'm using parent.frame() and eval() internally is not
     compatible with testthat I believe")

n = 20
x = rnorm(n)
y = rnorm(n)

trace_timings(cov)

cov(x, y)

untrace(cov)

autoparallel::init()
timings = .ap$cov

expect_equal(timings$metadata, length(x))

})
