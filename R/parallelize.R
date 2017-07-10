#' Parallelized Data Evaluater
#'
#' Distributes data over a cluster and returns a closure capable of
#' evaluating code in parallel.
#'
#' @param varname name of an existing list that one expects to use \code{lapply} on
#' @param cluster an existing SNOW cluster, or NULL
#' @param ... additional arguments to code{\link[parallel]{makeCluster}}
#' @return closure works similarly as \code{eval}
#' @examples
#' x = list(letters, 1:10)
#' do = parallelize(x)
#' do(lapply(x, head))
parallelize = function(varname, cluster = NULL, ...)
{

    if(is.null(cluster)){
        cl = parallel::makeCluster(...)
    } else {
        cl = cluster
    }

    #TODO- Don't need for fork clusters
    #TODO- Only send parts necessary for each worker
    clusterExport(cl, varname)

    indices = splitIndices(length(get(varname)), length(cl))

    # Each worker only sees their own indices
    clusterApply(cl, indices, assign_local_subset
                 , globalname = varname, localname = varname)

    function(expr, simplify = TRUE)
    {
        evaluated = clusterEvalQ(cl, expr)
        if(simplify){
            # Assume we're combining elements of a list
            evaluated = do.call(c, evaluated)
        }
        evaluated
    }
}


assign_local_subset = function(index, globalname, localname)
{
    x = get(globalname)
    assign(localname, x[index], envir = .GlobalEnv)
    NULL
}
