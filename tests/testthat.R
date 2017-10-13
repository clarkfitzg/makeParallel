library(testthat)
# https://github.com/r-lib/testthat/issues/86
Sys.setenv("R_TESTS" = "")

library(codedoctor)

test_check("codedoctor")
