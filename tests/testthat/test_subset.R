code = parse(text = '
    d = read.csv("data.csv")
    hist(d[, 2])
')


test_that("data_read", {

expect_equal(data_read(code[[1]]), quote(d))

expect_null(data_read(quote(f(x))))

})


test_that("update_indices", {

    map = c(11:13, 40)

    code = quote(dframe[condition, 11])
    actual = update_indices(code, list(4), map)

    expect_equal(actual, quote(dframe[condition, 1L]))

    # No locations to update
    expect_equal(update_indices(code, list(), map), code)

    code = quote(dframe[dframe[, 40L] > 10, 11:13])
    actual = update_indices(code, list(4, c(3, 2, 4)), map)

    expect_equal(actual, quote(dframe[dframe[, 4L] > 10, 1:3]))

    code = quote(plot(dframe[, c(11L, 13L)]))
    actual = update_indices(code, list(c(2, 4)), map)

    expect_equal(actual, quote(plot(dframe[, c(1L, 3L)])))

})
