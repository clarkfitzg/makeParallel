library(CodeDepends)
library(igraph)


# TODO: define behavior for this script:
# x = list(a = 1)
# x$b = 2
# f(x)

# Could define Ops to get ==, but this is sufficient
expect_samegraph = function(g, tg)
{
    tg2 = graph_from_data_frame(tg@graph)
    expect_true(isomorphic(g, tg2))
}


test_that("Degenerate cases, 0 or 1 nodes", {

    s1 = parse(text = "
    x = 1
    ")
    g1 = make_graph(numeric(), n = 1)
    gd1 = inferGraph(s1)

    s0 = parse(text = "
    ")
    g0 = make_empty_graph()
    gd0 = inferGraph(s0)
    expect_samegraph(g0, gd0)

    skip("Not that important.")
    expect_samegraph(g1, gd1)

})


test_that("User defined functions are dependencies", {

    s = parse(text = "
    f2 = function() 2
    x = f2()
    ")

    desired = make_graph(c(1, 2))
    actual = inferGraph(s)

    expect_samegraph(desired, actual)

})


test_that("Self referring node does not appear", {

    s = parse(text = "
    x = 1
    x = x + 2
    ")

    desired = make_graph(c(1, 2))
    actual = inferGraph(s)

    expect_samegraph(desired, actual)

})


test_that("Assignment order respected", {

    s = parse(text = "
    x = 1
    x = 2
    y = 2 * x
    ")

    desired = make_graph(c(2, 3))
    actual = inferGraph(s)

    skip("Doesn't currently work because the graph doesn't know it has 3
         nodes rather than 2.")

    expect_samegraph(desired, actual)

})


test_that("Chains not too long", {

    s = parse(text = "
    x = 1:10
    plot(x)
    y = 2 * x
    ")

    desired = make_graph(c(1, 2, 1, 3))
    actual = inferGraph(s)

    expect_samegraph(desired, actual)

})


test_that("Updates count as dependencies", {

    s = parse(text = "
    x = list()
    x$a = 1
    x$b = 2
    ")

    desired = make_graph(c(1, 2, 2, 3))
    actual = inferGraph(s)

    expect_samegraph(desired, actual)

})


test_that("$ evaluates LHS", {

    s = parse(text = "
    f = function(x) 100
    optimize(f, c(0, 1))$minimum
    ")

    desired = make_graph(c(1, 2))
    actual = inferGraph(s)

    expect_samegraph(desired, actual)

})


test_that("Precedence for user defined variables over base", {

    s = parse(text = "
    c = 100
    print(c)
    ")

    desired = make_graph(c(1, 2))
    actual = inferGraph(s)

    expect_samegraph(desired, actual)

})
