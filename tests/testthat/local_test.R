# Tests that should not run on CRAN.

test_that("depend graph plotting through command line graphviz (dot)", {

g = inferGraph("ex.R")
#f = tempfile(pattern = "plot", fileext = ".pdf")
f = "ex_plot.pdf"

plotDOT(g, file = f)

expect_true(file.exists(f))

unlink(f)

})
