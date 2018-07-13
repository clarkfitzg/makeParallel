#' @import methods
NULL


# I'd like to have some way of allowing user defined code preprocessors
# before we do the inferGraph.


#' Infer Task Dependency Graph
#'
#' Statically analyze code to determine implicit dependencies
#'
#' @export
#' @rdname inferGraph
#' @param code the file path to a script or an object that can be coerced
#'  to an expression.
#' @param ... additional arguments to methods
#' @return object of class \linkS4class{DependGraph}
#' @examples
#' g <- inferGraph(parse(text = "
#'   a <- 1
#'   b <- 2
#'   c <- a + b
#'   d <- b * c
#' "))
#'
#' ig <- as(g, "igraph")
#' plot(ig)
setGeneric("inferGraph", function(code, ...)
           standardGeneric("inferGraph"))


# # Where to put this parameter?
# #' @param default_size numeric default size of the variables in bytes
# # default_size = object.size(1L), 
# #' @param epsilonTime numeric small positive number used to avoid
# #'  difficulties which would arise 


#' Schedule Dependency Graph
#'
#' Creates the schedule for a dependency graph. The schedule is the
#' assignment of the expressions to different processors at different
#' times. There are many possible scheduling algorithms. The default is
#' \code{\link{mapSchedule}}, which does
#' simple map parallelism using R's apply family of functions.
#'
#' @references See \emph{Task Scheduling for Parallel Systems}, Sinnen, O.
#' for a thorough treatment of what it means to have a valid schedule.
#' 
#' @export
#' @rdname schedule
#' @param graph object of class \linkS4class{DependGraph}
#' @param maxWorker integer maximum number of parallel workers
#' @param ... additional arguments to methods
setGeneric("schedule", function(graph, maxWorker = 2L, ...)
           standardGeneric("schedule"))


#' @export
#' @rdname schedule
setMethod("schedule", "GeneratedCode", function(graph, ...)
{
    graph@schedule
})


# TODO:* Should the documentation for all these things live together?
# TODO:* Eliminate ... from all method signatures where the don't belong?


#' Generate Code From A Schedule
#'
#' @export
#' @rdname generate
#' @param schedule object inheriting from class \linkS4class{Schedule}
#' @param ... additional arguments to methods
#' @return x object of class \linkS4class{GeneratedCode}
#' @seealso \code{\link{schedule}} generic function to create
#' \linkS4class{Schedule}, \code{\link{writeCode}} to write and extract the
#' actual code, and
#' \code{\link{makeParallel}} to do everything all at once.
setGeneric("generate", function(schedule, ...)
           standardGeneric("generate"))


#' Write Generated Code
#'
#' Write the generated code to a file and return the code.
#'
#' @export
#' @rdname writeCode
#' @param code object of class \linkS4class{GeneratedCode}
#' @param file character name of a file to write the code, possibly
#' missing.
#' @param ... additional arguments to methods
#' @return expression R language object, suitable for further manipulation
#' @seealso \code{\link{generate}} to generate the code from a schedule,
#' \code{\link{makeParallel}} to do everything all at once.
setGeneric("writeCode", function(code, file, ...) 
           standardGeneric("writeCode"))


#' Set File for generated code object
#'
#' @export
#' @rdname fileSetter
#' @param description \linkS4class{GeneratedCode}
#' @param value file name to associate with object
setGeneric("file<-", function(description, value)
           standardGeneric("file<-"))
