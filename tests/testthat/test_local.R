# Tests that should not run on CRAN.
# This includes the plotting that requires the command line graphviz (dot)
# install.

test_that("descendant removal", {

g = inferGraph("ex.R")
#f = tempfile(pattern = "plot", fileext = ".pdf")
f = "ex_plot.pdf"

plotDOT(g, file = f)

expect_true(file.exists(f))

unlink(f)

})
