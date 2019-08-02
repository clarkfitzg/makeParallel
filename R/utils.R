# TODO: Many of these could probably go into the CodeAnalysis package.


# Identify those nodes that have ancestors within the set of nodes
#
# This algorithm is quadratic in length(nodes). I'll fix it if it
# becomes a problem. This is another example where using a proper tree
# data structure might provide better ways to do this.
#
# @param locs list of integer vectors corresponding to an AST
# @return vector of positions 
hasAncestors = function(locs)
{
    N = length(locs)

    if(N == 0){
        return(locs)
    }

    # This is safe because they're integers
    strings = sapply(locs, paste0, collapse = ",")

    anc = rep(FALSE, N)
    for(i in seq(N)){
        child = strings[i]
        matches = startsWith(child, strings)
        # Always matches itself, so we need more than 1
        if(sum(matches) > 1){
            anc[i] = TRUE
        }
    }
    anc
}
 

# Test Expressions For Equality
same_expr = function(e1, e2)
{
    all(mapply(`==`, e1, e2))
}


# Return code to detect the number of parallel workers
nworkers = function()
{
    quote(floor(parallel::detectCores() / 2))
}


# Find Function Call
#
# Search the parse tree for an expression, returning a list of locations
# where the function is called. This only finds functions that are called
# directly, so it will not find the function \code{f} in \code{lapply(x,
# f)}, for example.
#
# @param expr R language expression
# @param funcname symbol or character naming the function
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



# Find locations of variable use
#
# Returns a list of vectors to all uses of the variable.
#
# @param expr R language object
# @param var symbol or character naming the variable
# @param loc used for internal recursive calls
# @param found used for internal recursive calls
# @return address list of integer vectors, possibly empty
# @examples
# find_var(quote(x + 1))    # 2
# #find_var(quote(x))       
# # The above won't work, since x is a symbol not a language object
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

    # branch means anything other than a leaf node here.
    branch_types = c("language", "expression", "pairlist")
    branch = typeof(expr) %in% branch_types
    if(!branch){
        # We're at a leaf node
        if(is.symbol(expr) && expr == var){
            return(list(loc))
        } else {
            return(list())
        }
    }

    # Continue recursion
    for(i in seq_along(expr)){
        ei = expr[[i]]

        # Missing arguments, ie. the third element in x[, 10]
        if(missing(ei)){
            next
        }

        recurse_found = Recall(ei, var, c(loc, i))
        found = c(found, recurse_found)
    }
    found
}


# How long does it take for the schedule to complete?
timeFinish = function(schedule)
{
    # There shouldn't be any transfers after the final evaluation.
    max(schedule@evaluation$end_time)
}


# wrapper for by() that handles empty data frames
by0 = function(x, ...){
    if(nrow(x) == 0)
        logical()
    else
        by(x, ...)
}


# https://cran.r-project.org/doc/manuals/r-release/R-lang.html#Substitutions
# http://adv-r.had.co.nz/Computing-on-the-language.html#substitute
# Currently this doesn't allow injecting actual expressions in, i.e. blocks of code.
# I could hack around this using c() on expressions, or with braces, but I think I'll take the rstatic route instead.
substitute_language1 = function(expr, env)
{
    if(is(expr, "expression")){
        out = lapply(expr, substitute_language1, env)
        as.expression(out)
    } else {
        call <- substitute(substitute(y, env), list(y = expr))
        eval(call)
    }
}


as.expression.Brace = function(x)
{
    statements = lapply(x$contents, rstatic::as_language)
    as.expression(statements)
}


as.expression.ASTNode = function(x)
{
    as.expression(rstatic::as_language(x))
}


substitute_language2 = function(expr, env, ast = rstatic::to_ast(expr))
{
    replacer = function(node){
        if(is(node, "Symbol") && node$value %in% names(env)){
            rstatic::to_ast(env[[node$value]])
        } else {
            node
        }
    }
    rstatic::replace_nodes(ast, replacer, in_place = TRUE)
    as.expression(ast)
}


substitute_language = substitute_language2


# TODO: Is there a better way to do this?
# look at dput, substitute
convert_object_to_language = function(x)
{
    parse(text = deparse(x))[[1L]]
}


if(FALSE){


    # Minimal example of what the code substition should support.
    # BLOCK is an arbitrary block of code.
    template = parse(text = "
        VARNAME = VALUE
        foo(VARNAME)
        BLOCK
    ")

    v = as.symbol("x")
    l = list(1:2, 3:4)
    b = parse(text = "
              bar(1)
              1 + 2
              ")

    # Works, puts a brace { in, which isn't a big deal.
    substitute_language2(template, list(VARNAME = v,
        VALUE = convert_object_to_language(l),
        BLOCK = b
        ))

    # Doesn't work with the BLOCK, gives nested expressions
    substitute_language1(template, list(VARNAME = v,
        VALUE = l,
        BLOCK = b
        ))

    # Doesn't work because rstatic doesn't convert a list to an AST.
    # rstatic's behavior here is reasonable.
    substitute_language2(template, list(VARNAME = v,
        VALUE = l,
        BLOCK = b
        ))

}
