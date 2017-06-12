library(autoparallel)

context("apply")

test_that("convert apply to parallel", {

    x = matrix(1:10, ncol = 2)

    incode = quote(apply(x, 2, max))


})
