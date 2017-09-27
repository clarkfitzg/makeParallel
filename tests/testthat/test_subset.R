code = parse(text = '
    d = read.csv("data.csv")
    hist(d[, 2])
')


test_that("data_read", {

expect_equal(data_read(code[[1]]), quote(d))

expect_null(data_read(quote(f(x))))

})
