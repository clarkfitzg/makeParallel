code = parse(text = '
    d = read.csv("data.csv")
    hist(d[, 2])
')


test_that("data_read", {

expect_true(data_read(quote(a <- read.csv("data.csv"))))

expect_false(data_read(quote(f(x))))

})
