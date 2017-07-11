#' Parallelized Data Evaluater
#'
#' Distributes data over a cluster and returns a closure capable of
#' evaluating code in parallel. Designed for interactive use.
#'
#' The current version sends all the global functions to the parallel
#' workers each time the evaluator is called. This is useful when
#' iteratively building functions within the global environment.
#'
#' @export
#' @param varname character name of an existing list that one expects to use parallel
#'      code such as \code{lapply} on
#' @param cl SNOW cluster
#' @param spec number of workers, see \code{\link[parallel]{makeCluster}}
#' @param ... additional arguments to \code{\link[parallel]{makeCluster}}
#' @return closure works similarly as \code{eval}
#' @examples
#' x = list(letters, 1:10)
#' do = parallelize("x")
#' do(lapply(x, head))
parallelize = function(varname
                       , cl = parallel::makeCluster(spec, ...)
                       , spec = 2L, ...
                       )
{

    #TODO- Don't need for fork clusters
    #TODO- Only send parts necessary for each worker
    parallel::clusterExport(cl, varname)

    indices = parallel::splitIndices(length(get(varname)), length(cl))

    # Each worker only sees their own indices
    parallel::clusterApply(cl, indices, assign_local_subset
                 , globalname = varname, localname = varname)

    evaluator = function(expr, simplify = TRUE)
    {
        # Send all functions in the global workspace over every time.
        parallel::clusterExport(cl, global_functions())

        # Recover the expression as an object to manipulate
        code = parse(text = deparse(substitute(expr)))

        evaluated = parallel::clusterCall(cl, eval, code, env = .GlobalEnv)

        if(simplify){
            # Assume we're 'flattening' a list 
            evaluated = do.call(c, evaluated)
        }
        evaluated
    }
    attr(evaluator, "cluster") = cl
    attr(evaluator, "indices") = indices
    attr(evaluator, "varname") = varname
    evaluator
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
