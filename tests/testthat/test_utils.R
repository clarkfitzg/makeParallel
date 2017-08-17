library(autoparallel)

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


test_that("find_call", {

    e0 = quote(sapply(x, f))
    expect_equal(find_call(e0, "lapply"), list())

    e1 = quote(lapply(x, f))
    expect_equal(find_call(e1, "lapply"), list(1L))

    e2 = quote(y <- lapply(x, f))
    expect_equal(find_call(e2, "lapply"), list(c(3L, 1L)))

    e3 = quote(y <- c(lapply(x, f1), lapply(x, f2)))
    expect_equal(find_call(e3, "lapply"), list(c(3L, 2L, 1L), c(3L, 3L, 1L)))

    e4 = quote(y <- lapply(lapply(x, f), g))
    expect_equal(find_call(e4, "lapply"), list(c(3L, 1L), c(3L, 2L, 1L)))

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
