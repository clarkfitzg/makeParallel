test_that("Longest path", {

    skip()

    g = make_graph(c(1, 2, 1, 3, 2, 3))

    expect_equal(longest_path(g), 3)

})
