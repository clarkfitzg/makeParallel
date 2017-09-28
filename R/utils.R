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
#' Search the parse tree for an expression, returning a list of locations where
#' the function is called.
#'
#' Implementation based loosely on \code{codetools::walkCode}.
#'
#' @param expr R language expression
#' @param funcname symbol or character naming the function
#' @param loc used for internal recursive calls
#' @param found used for internal recursive calls
#' @return address list of integer vectors, possibly empty
#' @export
find_call = function(expr, funcname, loc = integer(), found = list())
{
    if(length(loc) == 0){
        # This is the first call, ie no recursion has yet taken place
        funcname = as.symbol(funcname)
    }

    if(typeof(expr) != "language"){
        # We're at a leaf node, all done with the search
        return(list())
    }

    if(class(expr) == "call"){
        if(expr[[1]] == funcname){
            found = c(found, list(c(loc, 1L)))
        }
    }

    # Continue recursion
    for(i in seq_along(expr)){
        subexpr = expr[[i]]
        recurse_found = Recall(subexpr, funcname, c(loc, i))
        found = c(found, recurse_found)
    }

    found
}


#' Check if code only contains literal expressions
#'
#' If only literals and functions such as \code{:, c} then code can be
#' evaluated regardless of context.  Assuming those functions haven't been
#' redefined.
only_literals = function(code)
{

    info = CodeDepends::getInputs(code)

    if(length(info@inputs) > 0) {
        return(FALSE)
    }

    funcs = names(info@functions)
    ok = funcs %in% c("c", ":")
    if(any(!ok)) {
        return(FALSE)
    }

    # TODO: Other code can be safely literally evaluated, for example
    # sapply(1:5, function(x) (x %% 2) == 0)
    #
    # So we could relax the above to check for funcs available through R's
    # search path.

    TRUE
}


# TODO: Share implementation of findvar with findcall


#' Find locations of variable use
#'
#' Returns a list of vectors to all uses of the variable.
#'
#' @param expr R language object
#' @param var symbol or character naming the variable
#' @param loc used for internal recursive calls
#' @param found used for internal recursive calls
#' @return address list of integer vectors, possibly empty
#' @export
#' @examples
#' findvar(quote(x + 1))    # 2
#' #findvar(quote(x))       
#' # The above won't work, since x is a symbol not a language object
findvar = function(expr, var, loc = integer(), found = list())
{
    if(length(loc) == 0){
        # This is the first call, ie no recursion has yet taken place
        var = as.symbol(var)
    }

    # Roughly following codetools::walkCode implementation.
    # It would be more trouble than it's worth to use walkCode to maintain
    # current indices.

    if(typeof(expr) != "language"){
        # We're at a leaf node
        if(is.symbol(expr) && expr == var){
            return(list(loc))
        } else {
            return(list())
        }
    }

    # Continue recursion
    for(i in seq_along(expr)){

        # Missing arguments, ie. the third element in x[, 10]
        # Possibly there's a better way to test for this.
        if(expr[[i]] == ""){
            next
        }

        subexpr = expr[[i]]
        recurse_found = Recall(subexpr, var, c(loc, i))
        found = c(found, recurse_found)
    }
    found
}
