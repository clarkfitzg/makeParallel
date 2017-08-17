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


#' Replace Call With Expression
#'
#' @export
#' @examples
#' e1 = quote(rnorm(10))
#' replace_call(e1, "rnorm", 
replace_call = function(input, function_name, replacement)
{
}


sub_one = sub_one_eval

#' Substitute Expressions
#' 
#' Replace code with new code objects in env.
#' Handles expression objects as well as single objects.
#' @export
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


#' Find Function Call
#'
#' Search a parse tree, returning a list of locations where
#' the function is called.
#'
#' Implementation based loosely on \code{codeDepends::walkCode}.
#'
#' @param expr R language expression
#' @param funcname symbol or character naming the function
#' @param loc used for internal recursive calls
#' @param found used for internal recursive calls
#' @return address list of integer vectors, possibly empty
find_call = function(expr, funcname, state = NULL)
{
    if(is.null(state)){
        # Not a recursive call
        state = 1L
        funcname = as.symbol(funcname)
    }
    for(e in expr){
        if(typeof(e) == "language"){
            if(class(e) == "call"){
                if(e[[1]] == funcname)
                    NULL
            }
        }

    }
}
