test_that("basic function tuning", {

f = function(x, t=0.1){
    if(x > 0) Sys.sleep(abs(t))
    x
}

f2 = tune(f, x = 100, t = tune_param(list(-0.05, 0.01, 0.1)))

expect_equal(0.01, formals(f2)$t)

})
