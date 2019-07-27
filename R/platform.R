#' Describe Platform
#'
#' Constructor for \linkS4class{Platform} classes, by default uses the current local platform.
#'
#' @export
#' @param OS.type character, \code{"unix"} or \code{"windows"} 
#' @param nWorkers integer, number of parallel workers
#' @return \linkS4class{Platform}
platform = function(OS.type = .Platform[["OS.type"]] , nWorkers = parallel::detectCores())
{
    if(OS.type == "unix"){
        UnixPlatform(nWorkers = nWorkers)
    } else {
        Platform(nWorkers = nWorkers)
    }
}
