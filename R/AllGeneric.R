#' @import methods
#' @importFrom stats time
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
#' @param time time to run each expression
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
#'
#' # To specify the time each expression takes:
#' g2 <- inferGraph(g@code, time = c(1.1, 2, 0.5, 6))
setGeneric("inferGraph", function(code, time, ...)
           standardGeneric("inferGraph"))


# # Where to put this parameter?
# #' @param default_size numeric default size of the variables in bytes
# # default_size = object.size(1L), 
# #' @param epsilonTime numeric small positive number used to avoid
# #'  technical difficulties from having 0 time.


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
#' @param graph \linkS4class{DependGraph}, code dependency graph
#' @param data list of data descriptions. 
#'      Each element is a \linkS4class{DataSource}.
#'      The names of the list elements correspond to the variables in the code that these objects are bound to.
#' @param platform \linkS4class{Platform} describing resource to compute on
#' @param ... additional arguments to methods
setGeneric("schedule", function(graph, data, platform, ...)
           standardGeneric("schedule"))

#method.skeleton("schedule", c("DependGraph", "missing"))


#' @export
#' @rdname schedule
setMethod("schedule", "GeneratedCode", function(graph, data, platform, ...)
{
    graph@schedule
})


#' Describe Data Source
#'
#' @export
#' @param expr code or function to load chunks of the data
#' @param args list of arguments to function
#' @param varname name of the variable in the source code
#' @rdname dataSource
#' @param ... additional arguments to methods
setGeneric("dataSource", function(expr, args, varname, ...)
           standardGeneric("dataSource"))


#' Expand Data
#'
#' Updates code to include code to load data
#'
#' @export
#' @inheritParams makeParallel
setGeneric("expandData", function(code, data, platform, ...)
           standardGeneric("expandData"))


#' Expression Run Time
#'
#' Extract a numeric vector of expression run times
#'
#' @export
#' @rdname time
#' @param x object containing expression run times
setMethod("time", "TimedDependGraph", function(x)
{
    x@time
})


#' @export
#' @rdname time
setMethod("time", "Schedule", function(x)
{
    callGeneric(x@graph)
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


#' @export
#' @rdname generate
setMethod("generate", "SerialSchedule", function(schedule, ...)
          GeneratedCode(schedule = schedule, code = schedule@graph@code)
          )


#' Write Generated Code
#'
#' Write the generated code to a file and return the code.
#'
#' @export
#' @inheritParams makeParallel
#' @rdname writeCode
#' @param code object of class \linkS4class{GeneratedCode}
#' @param ... additional arguments to methods
#' @return expression R language object, suitable for further manipulation
#' @seealso \code{\link{generate}} to generate the code from a schedule,
#' \code{\link{makeParallel}} to do everything all at once.
setGeneric("writeCode", function(code, file, ...) 
           standardGeneric("writeCode")
           )


#' Set File for generated code object
#'
#' @export
#' @rdname fileSetter
#' @param description \linkS4class{GeneratedCode}
#' @param value file name to associate with object
setGeneric("file<-", function(description, value)
           standardGeneric("file<-"))
