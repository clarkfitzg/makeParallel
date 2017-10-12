#' Doesn't work
sub_one_docall = function(expr, env)
{
    e = substitute(expr)
    do.call(substitute, list(e, env))
}


# Keeping this around just in case:
#' The current version sends all the global functions to the parallel
#' workers each time the evaluator is called. This is useful when
#' iteratively building functions within the global environment.
#' The smarter thing to do is keep track of which functions change, and
#' then send those over. But it's not clear that is worth it.
#' Return the names of all global functions
#global_functions = function()
#{
#    varnames = ls(.GlobalEnv, all.names = TRUE)
#    funcs = sapply(varnames, function(x) is.function(get(x, envir = .GlobalEnv)))
#    varnames[funcs]
#}


# 5. Transform the `read.csv(...)` call into `data.table::fread(..., select =
#    usedcolumns)`
# @xport
to_fread = function(statement, select, remove_col.names = TRUE)
{
    transformed = statement
    transformed[[1]] = quote(data.table::fread)
    # Sometimes R just makes things too easy! So happy with this:
    transformed[["select"]] = as.integer(select)
    if(remove_col.names && !is.null(transformed[["col.names"]])){
        transformed[["col.names"]] = NULL
    }
    transformed
}


