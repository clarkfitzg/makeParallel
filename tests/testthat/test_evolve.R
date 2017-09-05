test_that("get_timings", {

f = function(x) 20

f2 = smartfunc(f)

f2(50)

expect_true(is.data.frame(get_timings(f2)))

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

n = 20
p = 2
x = matrix(rnorm(n * p), nrow = n)

trace_timings(cov)

cov(x)
cov(x)

untrace(cov)

timings = .ap$cov
expect_equal(nrow(timings), 2)

timings$

})
