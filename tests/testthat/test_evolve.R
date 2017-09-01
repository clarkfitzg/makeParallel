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

f2(50)

time_expected = predict(f2, 20)

expect_lt(time_expected, sleeptime + epsilon)

expect_gt(time_expected, sleeptime - epsilon)

})
