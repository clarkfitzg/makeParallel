

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

    code = quote(dframe[, 4:7])
    transformed = single_to_ssb(code, letters)$statement
    expect_equal(quote(dframe[, 4:7]), transformed)

    code = quote(dframe[, c(2L, 4L)])
    transformed = single_to_ssb(code, letters)$statement
    expect_equal(quote(dframe[, c(2L, 4L)]), transformed)

    code = quote(dframe[condition, "b"])
    transformed = single_to_ssb(code, letters)$statement
    expect_equal(quote(dframe[condition, 2L]), transformed)

})


test_that("canon_form", {

# Wait until I have a reason to use this
#    code = quote(dframe[condition, "b"])
#    actual = canon_form(code, "dframe", letters)
#    expect_true(actual$found)
#
#    code = quote(xxx[condition, "b"])
#    actual = canon_form(code, "dframe", letters)
#    expect_false(actual$found)

    code = quote(dframe[condition, "b"])
    actual = canon_form(code, "dframe", letters)

    expect_equal(actual$statement, quote(dframe[condition, 2:3]))
    expect_equal(actual$column_indices, 2:3)

    code = quote(xxx[condition, "b"])
    actual = canon_form(code, "dframe", letters)
    expect_equal(actual$statement, code)
    expect_null(actual$column_indices)

    code = quote(dframe[dframe[, "d"] > 10, "b"])
    actual = canon_form(code, "dframe", letters)

    expect_equal(actual$statement, quote(dframe[dframe[, 4] > 10, 2]))
    expect_equal(actual$column_indices, c(2, 4))

})
