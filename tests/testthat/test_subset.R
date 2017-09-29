
test_that("data_read", {

              skip("don't care about these yet")

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


test_that("to_fread", {

    code = quote(read.csv("data.csv"))
    actual = to_fread(code, select = c(2L, 4L))

    expected = quote(data.table::fread("data.csv", select = c(2L, 4L)))

    expect_equal(actual, expected)

})


test_that("basic read_faster", {

    code = parse(text = '
        d = read.csv("data.csv")
        hist(d[, 2])
    ')

    actual = read_faster(code, varname = "d", colnames = letters)

    expected = parse(text = '
        d = data.table::fread("data.csv", select = 2L)
        hist(d[, 1L])
    ')

    expect_equal(actual, expected)

})


test_that("read_faster with nested subsetting and $, [, [[", {

    code = parse(text = '
        d = read.csv("data.csv")
        plot(d$c, d[[1]])
        plot(d[d[, 6] > 5, 5:7])
    ')

    actual = read_faster(code, varname = "d", colnames = letters)

    expected = parse(text = '
        d = data.table::fread("data.csv", select = c(1L, 3L, 5L, 6L, 7L))
        plot(d[, 2L], d[, 1L])
        plot(d[d[, 4L] > 5, 3:5])
    ')

    # The srcref info indicating the lines stays as an attribute.
    attributes(expected) = NULL

    # TODO: This currently works fine. I just need a better utility to test
    # for expression equality.
    skip()
    expect_true(actual == expected)

})
