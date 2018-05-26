
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


