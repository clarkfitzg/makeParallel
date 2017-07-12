#' @importFrom microbenchmark microbenchmark
NULL


#' Test Expressions For Equality
same_expr = function(e1, e2)
{
}


#' Adapted from Hadley Wickham's pryr / Advanced R
#' @export
sub_one_eval = function(statement, env)
{
    #stopifnot(is.language(statement))
    call <- substitute(substitute(statement, env), list(statement = statement))
    eval(call)
}


#' @export
sub_one_docall = function(expr, env)
{
    e = substitute(expr)
    do.call(substitute, list(e, env))
}


# TODO: tests to clarify what and how this should work
sub_one = sub_one_eval


#' Substitute Expressions
#' 
#' Replace code with new code objects in env.
#' Handles expression objects as well as single objects.
sub_expr = function(expr, env) {
    if(is.expression(expr)){
        as.expression(lapply(expr, sub_one, env))
    } else {
        sub_one(expr, env)
    }
}


#' Return code to detect the number of parallel workers
nworkers = function()
{
    quote(floor(parallel::detectCores() / 2))
}


