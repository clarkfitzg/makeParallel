
# Adapted from Hadley Wickham's pryr / Advanced R
sub_one = function(statement, env)
{
    #stopifnot(is.language(statement))
    call <- substitute(substitute(statement, env), list(statement = statement))
    eval(call)
}


# Doesn't work
sub_one_docall = function(expr, env)
{
    e = substitute(expr)
    do.call(substitute, list(e, env))
}


# Substitute Expressions
# 
# Replace code with new code objects in env.
# Handles expression objects as well as single objects.
sub_expr = function(expr, env) {
    if(is.expression(expr)){
        as.expression(lapply(expr, sub_one, env))
    } else {
        sub_one(expr, env)
    }
}


# Check if code only contains literal expressions
#
# If only literals and simple functions such as \code{:, c} then code can be
# evaluated regardless of context.  Assuming those functions haven't been
# redefined.
#
# @param code single R statement
only_literals = function(code, simple_funcs = c("c", ":"))
{

    info = CodeDepends::getInputs(code)

    if(length(info@inputs) > 0) {
        return(FALSE)
    }

    funcs = names(info@functions)
    ok = funcs %in% simple_funcs
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


#' Find All Symbols In Expression
#'
#' @param expr R language object
all_symbols = function(expr)
{
    expr = as.expression(expr)
    symbols = character()
    walker = codetools::makeCodeWalker(leaf = function(e, w){
        if(is.symbol(e)){
            symbols <<- union(symbols, as.character(e))
        }
    })
    lapply(expr, codetools::walkCode, walker)
    symbols
}


#' Approximately Even Split
#'
#' @param n_elements integer number of elements to split
#' @param n_groups integer number of resulting groups
#' @return integer vector for use as splitting factor in \code{\link[base]{split}}
even_split = function(n_elements, n_groups)
{
    splits = rep(seq(n_groups), (n_elements %/% n_groups) + 1)
    sort(splits[1:n_elements])
}
