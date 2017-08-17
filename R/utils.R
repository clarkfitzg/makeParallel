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
#' Performs a breadth first search of the parse tree, returning the
#' location of the first time the function is called.
#'
#' @param expr expression
#' @param funcname character
#' @return address integer vector giving address of found function call,
#'      and NULL if no such function calls found
find_call = function(expr, funcname)
{

}
