library(autoparallel)

test_that("find apply calls inside script", {

    expr = parse(text = "
        x = matrix(1:10, ncol = 2)
        x
        colmaxs = apply(x, 2, max)
        colmaxs2 <- apply(x, 2, max)
        assign('colmaxs3', apply(x, 2, max))
        apply(x, 2, min)
    ")

    expect_equal(find_apply(expr), c(FALSE, FALSE, TRUE, TRUE, TRUE, TRUE))

})
