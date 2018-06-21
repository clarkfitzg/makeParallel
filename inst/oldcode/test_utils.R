test_that("Longest path", {

    skip()

    g = make_graph(c(1, 2, 1, 3, 2, 3))

    expect_equal(longest_path(g), 3)

})


test_that("replacing functions", {

    expr = parse(text = "
        # Testing code:
        n = 1000000L
        p = 20L
        x = matrix(1:(n*p), ncol = p)
        x
        colmaxs = apply(x, 2, max)
        colmaxs2 <- apply(x, 2, max)
        assign('colmaxs3', apply(x, 2, max))
        apply(x, 2, min)
    ")

    sub_one_docall(expr, list(apply = quote(FANCY_APPLY)))

})


test_that("all_symbols", {

    e = quote(plot(x, y))
    actual = sort(all_symbols(e))
    expected = sort(c("plot", "x", "y"))

    expect_equal(actual, expected)

    # Using x as a function also. Yuck!
    e = parse(text = "x(plot(x, y))
              plot(x)")
    actual = sort(all_symbols(e))

    expect_equal(actual, expected)

})


test_that("only_literals", {

    expect_true(only_literals(quote(1:5)))

    expect_true(only_literals(quote(c(1, 4))))

    expect_false(only_literals(quote(f(3))))

    expect_false(only_literals(quote(1:n)))

})


test_that("even_split", {

    actual = even_split(6, 2)    
    expect_equal(actual, c(1, 1, 1, 2, 2, 2))

    actual = even_split(7, 2)    
    expect_equal(actual, c(1, 1, 1, 1, 2, 2, 2))

})


if(FALSE){

expr = parse(text = "
    # Testing code:
    n = 100000L
    p = 10L
    x = matrix(1:(n*p), ncol = p)
    x
    nitenite = function(x) Sys.sleep(0.01)
    colmaxs = apply(x, 2, max)
    apply(x, 2, nitenite)
")

# Seems to work fine
expr_out =  parallelize_script(expr)

e = lapply(expr, CodeDepends::getInputs)

lapply(e, function(x) x@inputs)

}
