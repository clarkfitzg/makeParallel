library(testthat)
# https://github.com/r-lib/testthat/issues/86
#Sys.setenv("R_TESTS" = "")
library(makeParallel)

# Allows parse() to check equality between expressions
#options(keep.source = FALSE)

test_check("makeParallel")
