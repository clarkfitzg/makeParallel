
#' Adapted from Hadley Wickham's pryr / Advanced R
sub_one = function(expr, env)
{
    stopifnot(is.language(expr))
    call <- substitute(substitute(expr, env), list(expr = expr))
    eval(call)
}


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


