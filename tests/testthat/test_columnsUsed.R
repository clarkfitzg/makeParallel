# Doesn't (yet) handle:
#
# - created or updated columns
#       dfname[, "col"] = bar()
#       foo(dfname[, "col"])
# - different object writes over dfname
#       dfname = something_completely_different()
#       foo(dfname[, "col"])
# - when dfname is renamed
#       df2 = dfname
#       foo(df2[, "col1"])
# - NSE from `$`
#       foo(dfname$col)
# - column names contained in a variable
#       v = "col1"
#       foo(df2[, v])
# - 

# Does handle:
#
# - single literal for `[`
#       foo(dfname[, "col"])
#       foo(dfname["col"])
# - multiple literals for `[` combined with `c()`
#       foo(dfname[, c("col1", "col2")])
# - redefinitions based on columns. This is a special case when we can quit the analysis early
#       dfname = dfname[, c("col1", "col2")]
#
test_that("single literal for `[[`", {

    e = parse(text = '
        foo(dfname[["col"]])
    ')

    expect_equal(columnsUsed(e), "col")
})


