#' @import methods
NULL


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
#' @param epsilonTime numeric small positive number used to avoid
#'  difficulties which would arise 


#' Schedule Dependency Graph
#'
#' Creates the schedule for a dependency graph. The schedule is the
#' assignment of the expressions to different processors at different
#' times. There are many possible scheduling algorithms. The default is a
#' simple map reduce using R's apply family of functions.
#'
#' @references See \emph{Task Scheduling for Parallel Systems}, Sinnen, O.
#' for a thorough treatment of what it means to have a valid schedule.
#' 
#' @export
#' @param graph object of class \linkS4class{DependGraph}
#' @param maxWorkers integer maximum number of parallel workers
#' 
setGeneric("schedule", function(graph, maxWorkers = 2L, ...)
           standardGeneric("schedule"))


#' @export
setMethod("schedule", "GeneratedCode", function(graph, ...)
{
    graph@schedule
})


#' @export
setGeneric("generate", function(schedule, ...)
           standardGeneric("generate"))


#' Write Generated Code
#'
#' This writes the 
#'
#' @param x object of class \linkS4class{GeneratedCode}
#' @param file character name of a file to write the code. missing or NULL
#'  arguments here will return an R expression object with the generated
#'  code.
#' @return expression R language object, ie. the same thing returned from
#'  \link{\code{parse}}.
#' @export
setGeneric("writeCode", function(x, file, ...) 
           standardGeneric("writeCode"))


# Match parameter names with base::file. I don't know if there's a better
# way.
setGeneric("file<-", function(description, value, ...)
           standardGeneric("file<-"))


# Seems like I shouldn't need this.
setGeneric("file")


#' @importFrom graphics plot
# TODO:* Is this the correct way to make plot a generic so that I can set a
# method for it?
setGeneric("plot")
