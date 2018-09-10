# Not necessary, comes from methods package?
# setOldClass("expression")

# Basically I use a data frame with specific columns to represent
# several objects:
#
# - task graph
# - evaluation of nodes on processors
# - transfers of objects between processors
#
# Should I specify them formally as subclasses of data frame?
# Probably best to wait until it seems necessary


# Graphs
############################################################

#' Dependency graph between expressions
#'
#' @export
#' @slot code input code
#' @slot graph data frame representing the graph with indices corresponding
#'  to code
DependGraph = setClass("DependGraph",
    slots = c(code = "expression", graph = "data.frame"))


#' Graph where each expression has been executed, timed, and the size of
#' the variables have been measured.
#'
#' Will export once full pipeline works.
#' @slot time time in seconds to run each expression
MeasuredDependGraph = setClass("MeasuredDependGraph",
    slots = c(time = "numeric"),
    # Also attaches variable sizes to the graph
    contains = "DependGraph")


# Schedules
############################################################

#' Schedule base class
#'
#' @export
#' @slot graph \linkS4class{DependGraph} used to create the schedule
#' @slot evaluation data.frame assigning expressions to processors
Schedule = setClass("Schedule", 
    slots = c(graph = "DependGraph"
        , evaluation = "data.frame"
        ))


#' Schedule that contains no parallelism at all
#'
#' @export
SerialSchedule = setClass("SerialSchedule", contains = "Schedule")


#' Task Parallel Schedule
#'
#' @slot transfer transfer variables between processes
#' @slot maxWorker maximum number of processors, similar to \code{mc.cores}
#'  in the parallel package
#' @slot exprTime time in seconds to evaluate each expression
#' @slot overhead minimum time in seconds to evaluate a single expression
#' @slot bandwidth network bandwidth in bytes per second
#' @export
TaskSchedule = setClass("TaskSchedule",
    slots = c(transfer = "data.frame"
              , maxWorker = "integer"
              , exprTime = "numeric"
              , overhead = "numeric"
              , bandwidth = "numeric"
    ), contains = "Schedule")


#' Data parallel schedule
#'
#' Class for schedules that should be parallelized with apply style parallelism
#'
#' @export
MapSchedule = setClass("MapSchedule", contains = "Schedule")


#' Fork based parallel schedule
#'
#' Class for schedules that should be parallelized by forks from one single
#' process
#'
#' @export
ForkSchedule = setClass("ForkSchedule", contains = "Schedule"
              , exprTime = "numeric")


# Generated Code
############################################################

#setClassUnion("LogicalOrCharacter", c("logical", "character"))


#' Generated code ready to write
#'
#' @export
#' @slot schedule contains all information to generate code
#' @slot code executable R code
#' @slot file name of a file where code will be written
setClass("GeneratedCode",
    slots = c(schedule = "Schedule"
              , code = "expression"
              #, file = "LogicalOrCharacter"
              , file = "character"
))


GeneratedCode = function(schedule, code)
{
    new("GeneratedCode", schedule = schedule, code = code
        , file = as.character(NA))
}


setOldClass("igraph")
