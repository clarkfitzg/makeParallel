# Doesn't (yet) handle:
#
# - created or updated columns
#       x[, "col"] = bar()
#       foo(x[, "col"])
# - different object writes over x
#       x = something_completely_different()
#       foo(x[, "col"])
# - when x is renamed
#       df2 = x
#       foo(df2[, "col1"])
# - NSE from `$`
#       foo(x$col)
# - column names contained in a variable
#       v = "col1"
#       foo(df2[, v])
# - 

test_that("single literal for `[[`", {

    e = parse(text = '
        foo(x[["col"]])
    ')
    expect_equal(columnsUsed(e, "x"), "col")
})


test_that("single literal for `[`", {

    e1 = parse(text = '
        foo(x[, "col"])
    ')
    expect_equal(columnsUsed(e1, "x"), "col")

    e2 = parse(text = '
        foo(x["col"])
    ')
    expect_equal(columnsUsed(e2, "x"), "col")

})


test_that("multiple literals for `[` combined with `c()`", {

    e = parse(text = '
       foo(x[, c("col1", "col2")])
    ')
    expect_equal(columnsUsed(e, "x"), c("col1", "col2"))
})


test_that("redefinitions based on columns", {
# This is a special case when we can quit the analysis early.

    e = parse(text = '
       x = x[, c("col1", "col2")]
       foo(x)
    ')
    expect_equal(columnsUsed(e, "x"), c("col1", "col2"))
})


test_that("undetermined usage", {

    e = parse(text = '
       foo(x)
    ')
    expect_null(columnsUsed(e, "x"))
})
