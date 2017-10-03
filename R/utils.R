#' @importFrom microbenchmark microbenchmark
NULL


# TODO:
#' Test Expressions For Equality
same_expr = function(e1, e2)
{
}


#' Adapted from Hadley Wickham's pryr / Advanced R
sub_one = function(statement, env)
{
    #stopifnot(is.language(statement))
    call <- substitute(substitute(statement, env), list(statement = statement))
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


#' Find Function Call
#'
#' Search the parse tree for an expression, returning a list of locations
#' where the function is called. This only finds functions that are called
#' directly, so it will not find the function \code{f} in \code{lapply(x,
#' f)}, for example.
#'
#' @param expr R language expression
#' @param funcname symbol or character naming the function
find_call = function(expr, funcname)
{
    locs = find_var(expr, funcname)

    # This logic is based on what I've seen: everything in R is a
    # function call and for the function to appear as element 1 it means it
    # must have been called.

    iscall = function(loc) loc[length(loc)] == 1L

    calls = sapply(locs, iscall)
    if(length(calls) == 0L){
        return(list())
    }
    locs[calls]
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


#' Find locations of variable use
#'
#' Returns a list of vectors to all uses of the variable.
#'
#' @param expr R language object
#' @param var symbol or character naming the variable
#' @param loc used for internal recursive calls
#' @param found used for internal recursive calls
#' @return address list of integer vectors, possibly empty
#' @examples
#' find_var(quote(x + 1))    # 2
#' #find_var(quote(x))       
#' # The above won't work, since x is a symbol not a language object
find_var = function(expr, var, loc = integer(), found = list())
{
    if(length(loc) == 0){
        # This is the first call, ie no recursion has yet taken place
        var = as.symbol(var)
    }

    # Roughly following codetools::walkCode implementation.
    # It would be more trouble than it's worth to use walkCode to maintain
    # current indices. Further, walkCode doesn't work on expression
    # objects.

    if(typeof(expr) != "language" && typeof(expr) != "expression" ){
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


#' Approximately Even Split
even_split = function(n_elements, n_groups)
{
}
