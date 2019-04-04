#' Expand Data Description
#'
#' Inserts the chunked data loading calls directly into the code, and expands vectorized function calls.
#'
#' @export
#' @rdname scheduleTaskList
expandData = function(graph, data, .vectorfuncs = vectorfuncs)
{
    if(length(data) == 0) return(graph)
}


# TODO:
# - Make user extensible
# - Identify which arguments they are vectorized in
vectorfuncs = c("*")
