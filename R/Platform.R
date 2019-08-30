#' Describe Platform
#'
#' Constructor for \linkS4class{Platform} classes, by default uses the current local platform.
#'
#' @export
#' @param OS.type character, \code{"unix"} or \code{"windows"} 
#' @param nWorkers integer, number of parallel workers
#' @return \linkS4class{Platform}
Platform = function(OS.type = .Platform[["OS.type"]] , nWorkers = parallel::detectCores())
{
    nWorkers = as.integer(nWorkers)
    if(OS.type == "unix"){
        UnixPlatform(nWorkers = nWorkers)
    } else if(OS.type == "windows"){
        Platform(nWorkers = nWorkers)
    } else {
        stop("Unknown operating system type: ", OS.type)
    }
}


#' @export
parallelLocalCluster = function(name = "cls", nWorkers = 2L)
    new("ParallelLocalCluster", name = name, nWorkers = nWorkers)
