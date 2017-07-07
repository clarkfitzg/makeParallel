#' Parallelize Data On Implicit Cluster
#'
#' Creates an implicit cluster and returns a closure capable of evaluating
#' code in parallel.
#'
#' @param data list that one expects to use \code{lapply} on
#' @param nworkers number of parallel workers
#' @return closure works similarly as \code{eval}
parallelize = function(data, nworkers = 2L)
{

    cl = parallel::makeCluster(nworkers)

    clusterExport(cl, data)
    #TODO
}
