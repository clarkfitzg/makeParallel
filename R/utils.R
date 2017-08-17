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
#' Implementation based loosely on \code{codetools::walkCode}.
#'
#' @param expr R language expression
#' @param funcname symbol or character naming the function
#' @param loc used for internal recursive calls
#' @param found used for internal recursive calls
#' @return address list of integer vectors, possibly empty
find_call = function(expr, funcname, loc = integer(), found = list())
{
    if(length(loc) == 0){
        # Not a recursive call
        funcname = as.symbol(funcname)
    }

    for(i in seq_along(expr)){
        loc = c(loc, i)
        e = expr[[i]]

        if(typeof(e) == "language"){
        # Otherwise it will be a leaf node, so can be ignored
            if(class(e) == "call"){
                if(e[[1]] == funcname){
                    found = c(found, c(loc, 1L))
                }
            }
            # Continue recursion
            for(subexpr in e){
                recurse_found = Recall(subexpr, funcname, loc)
                found = c(found, recurse_found)
            }
        }
    }
    found
}
