test_that("track usage", {

f = function(x) 20

f2 = track_usage(f)

f2(50)

expect_true(is.data.frame(attr(f2, "timings")))

})
