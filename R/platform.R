#' Infer Current Platform
#'
#' When generating code in the absence of specific platform information we assume the code will run where it's generated.
#'
#' @export
#' @return \linkS4class{Platform}
inferPlatform = function()
{
    workers = parallel::detectCores()
    os = .Platform[["OS.type"]] 
    platform(os, workers)
}


#' Describe Platform
#'
#' Constructor for Platform classes
#'
#' @export
#' @param OS.type character, \code{"unix"} or \code{"windows"} 
#' @param workers integer, number of parallel workers
#' @return \linkS4class{Platform}
platform = function(OS.type, workers)
{
    workers = parallel::detectCores()
    if(OS.type == "unix"){
        UnixPlatform(workers = workers)
    } else {
        Platform(workers = workers)
    }
}
