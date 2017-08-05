#' Parallelized Data Evaluater
#'
#' Distributes data over a cluster and returns a closure capable of
#' evaluating code in parallel. Designed for interactive use.
#'
#' The current version sends all the global functions to the parallel
#' workers each time the evaluator is called. This is useful when
#' iteratively building functions within the global environment.
#' The smarter thing to do is keep track of which functions change, and
#' then send those over. But it's not clear that is worth it.
#'
#' @export
#' @param x An object one wants to perform parallel analysis on
#' @param cl SNOW cluster
#' @param spec number of workers, see \code{\link[parallel]{makeCluster}}
#' @param ... additional arguments to \code{\link[parallel]{makeCluster}}
#' @return closure works similarly as \code{eval}
#' @examples
#' x = list(letters, 1:10)
#' do = parallelize("x")
#' do(lapply(x, head))
parallelize = function(x
                       , cl = parallel::makeCluster(spec, ...)
                       , spec = 2L, ...
                       )
{

    varname = deparse(substitute(x))

    #TODO- Don't need for fork clusters
    #TODO- Only send parts necessary for each worker
    parallel::clusterExport(cl, varname)

    indices = parallel::splitIndices(length(get(varname)), length(cl))

    # Each worker only sees their own indices
    parallel::clusterApply(cl, indices, assign_local_subset
                 , globalname = varname, localname = varname)

    evaluator = function(expr, simplify = c)
    {
        # Send all functions in the global workspace over every time.
        parallel::clusterExport(cl, global_functions())

        # Recover the expression as an object to manipulate
        code = substitute(expr)

        evaluated = parallel::clusterCall(cl, eval, code, env = .GlobalEnv)

        if(is.function(simplify)){
            # Typically expect to flatten a list
            evaluated = do.call(simplify, evaluated)
        }
        evaluated
    }
    attr(evaluator, "cluster") = cl
    attr(evaluator, "indices") = indices
    attr(evaluator, "varname") = varname
    class(evaluator) = c("parallel_evaluator", class(evaluator))
    evaluator
}


#' @export
print.parallel_evaluator = function(x)
{
    cat("parallel evaluator", "\n")
    cat("variable: ", attr(x, "varname"), "\n")
}


assign_local_subset = function(index, globalname, localname)
{
    x = get(globalname)
    assign(localname, x[index], envir = .GlobalEnv)
    NULL
}


#' Return the names of all global functions
global_functions = function()
{
    varnames = ls(.GlobalEnv, all.names = TRUE)
    funcs = sapply(varnames, function(x) is.function(get(x, envir = .GlobalEnv)))
    varnames[funcs]
}
