test_that("find apply calls inside script", {

    code = parse(text = "
        x = matrix(1:10, ncol = 2)
        colmaxs = apply(x, 2, max)
        colmaxs_ <- apply(x, 2, max)
        apply(x, 2, min)
    ")

    expect_equal(find_apply, c(FALSE, TRUE, TRUE))

})
