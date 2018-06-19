# I'd like to have some way of allowing user defined code preprocessors
# before we do the inferGraph.


#' Task Dependency Graph
#'
#' Create a data frame of edges representing the expression (task) dependencies
#' implicit in code.
#'
#' @export
#' @param code the file path to a script or an object that can be coerced
#'  to an expression.
#' @return data frame of edges with attribute information suitable for use
#'  with \code{\link[igraph]{graph_from_data_frame}}.
setGeneric("inferGraph", function(code, ...)
           standardGeneric("inferGraph"))


# Where to put this parameter?
#' @param default_size numeric default size of the variables in bytes
# default_size = object.size(1L), 

#' @export
setGeneric("schedule", function(graph, maxWorkers = 2L, epsilonTime = 1e-6, ...)
           standardGeneric("schedule"))


#' @export
setGeneric("generate", function(schedule, ...)
           standardGeneric("generate"))


#' @export
setGeneric("writeCode", function(x, file, ...) 
           standardGeneric("writeCode"))
