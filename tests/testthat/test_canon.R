

test_that("names_to_ssb helper functions", {

    code = quote(dframe$b)
    transformed = dollar_to_ssb(code, letters)$statement
    expect_identical(quote(dframe[, 2L]), transformed)

    code = quote(dframe[["b"]])
    transformed = double_to_ssb(code, letters)$statement
    expect_identical(quote(dframe[, 2L]), transformed)

    code = quote(dframe[[2L]])
    transformed = double_to_ssb(code, letters)$statement
    expect_identical(quote(dframe[, 2L]), transformed)

    code = quote(dframe[, "b"])
    transformed = single_to_ssb(code, letters)$statement
    expect_identical(quote(dframe[, 2L]), transformed)

    code = quote(dframe[, c("b", "c")])
    transformed = single_to_ssb(code, letters)$statement

    expect_identical(quote(dframe[, c(2L, 3L)]), transformed)

    code = quote(dframe[, c(2L, 3L)])
    transformed = single_to_ssb(code, letters)$statement
    expect_identical(quote(dframe[, c(2L, 3L)]), transformed)

    code = quote(dframe[condition, "b"])
    transformed = single_to_ssb(code, letters)$statement
    expect_identical(quote(dframe[condition, 2L]), transformed)

})


