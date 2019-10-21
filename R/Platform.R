#' Describe Platform
#'
#' Constructor for \linkS4class{Platform} classes, by default uses the current local platform.
#'
#' @export
#' @param OS.type character, \code{"unix"} or \code{"windows"} 
#' @param nWorkers integer, number of parallel workers
#' @return \linkS4class{Platform}
Platform = function(OS.type = .Platform[["OS.type"]] , nWorkers = parallel::detectCores()
    , name = "cls", scratchDir = ".")
{
    nWorkers = as.integer(nWorkers)
    p = ParallelLocalCluster(name = name, nWorkers = nWorkers, scratchDir = scratchDir)
    if(OS.type == "unix"){
        p = as(p, "UnixPlatform")
    } 
    p
}


# #' @export
# parallelLocalCluster = function(name = "cls", nWorkers = 2L, scratchDir = ".")
#     new("ParallelLocalCluster", name = name, nWorkers = nWorkers, scratchDir = scratchDir)
