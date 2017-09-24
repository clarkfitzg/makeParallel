

test_that("names_to_ssb helper functions", {

    code = quote(dframe$b)
    transformed = dollar_to_ssb(code, letters)$statement
    expect_equal(quote(dframe[, 2L]), transformed)

    code = quote(dframe[["b"]])
    transformed = double_to_ssb(code, letters)$statement
    expect_equal(quote(dframe[, 2L]), transformed)

    code = quote(dframe[[2L]])
    transformed = double_to_ssb(code, letters)$statement
    expect_equal(quote(dframe[, 2L]), transformed)

    code = quote(dframe[, "b"])
    transformed = single_to_ssb(code, letters)$statement
    expect_equal(quote(dframe[, 2L]), transformed)

    code = quote(dframe[, c("b", "c")])
    transformed = single_to_ssb(code, letters)$statement

    expect_equal(quote(dframe[, 2:3]), transformed)

    code = quote(dframe[, c(2L, 4L)])
    transformed = single_to_ssb(code, letters)$statement
    expect_equal(quote(dframe[, c(2L, 4L)]), transformed)

    code = quote(dframe[condition, "b"])
    transformed = single_to_ssb(code, letters)$statement
    expect_equal(quote(dframe[condition, 2L]), transformed)

})


