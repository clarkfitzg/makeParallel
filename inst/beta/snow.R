#' Make A SNOW Cluster Act Like A Unix Fork
#'
#' Evaluate code that appears before a call to lapply
#'
#' @export
snow_fork = function(code)
{

    #TODO: Implement me
    find_call(code, "lapply")

}
