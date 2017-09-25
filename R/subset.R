# Mon Sep 25 12:12:58 PDT 2017
#
# Implementing method described in transpile vignette:
#
# 1. Infer that a data frame `d` is created by a call to `read.csv()`
# 2. Identify all calls which subset `d` and transform them into a common
#    form.
# 4. Find `usedcolumns` the set of all columns which are used
# 5. Transform the `read.csv(...)` call into `data.table::fread(..., select =
#    usedcolumns)`
# 6. Transform the calls which subset `d` into new indices.


# For testing
code = parse(text = '
    d = read.csv("data.csv")
    hist(d[, 2])
')


info = lapply(code, CodeDepends::getInputs)

# The CodeDepends output says when `read.csv` func is called, which is
# helpful. But it doesn't let me see if the result of `read.csv` is
# assigned to a variable, which is what I need.

code2 = quote(x <- rnorm(n = read.csv("data.csv")))

CodeDepends::getInputs(code2)


#' 1. Infer that a data frame is created by a call to `read.csv()`
#'
#' @return logical Is this a top level call reading data and creating a data.frame?
data_read = function(statement, assigners = c("<-", "=", "assign")
                     , readers = c("read.csv", "read.table"))
{
    if(as.character(statement[[1]]) %in% assigners){
        funcname = as.character(statement[[c(3, 1)]])
        if(funcname %in% readers) return(TRUE)
    }
    FALSE
}



library(testthat)


expect_true(data_read(quote(a <- read.csv("data.csv"))))

expect_false(data_read(quote(f(x))))
