library(autoparallel)

test_that("find apply calls inside script", {

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

    #expect_equal(find_apply(expr), c(0, 0, 3, 3, 3, 1))


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
