test_that("basic ordering", 
{

graph <- inferGraph(code = parse(text = "x <- 1:100
y <- rep(1, 100)
z <- x + y"), time = c(1, 2, 5))
bl <- orderBottomLevel(graph)

# 2nd statement takes longer, so it should come before 1st.
expect_equal(bl, c(2, 1, 3))


graph <- inferGraph(code = parse(text = "x <- 1:100
y <- f(x)
g(x)"), time = c(1, 2, 5))
bl <- bottomLevel(graph)

expect_equal(bl, c(6, 2, 5))

})
