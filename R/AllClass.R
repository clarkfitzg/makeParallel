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
#' Subclasses of this class contain all the information that we know about
#' the code and the problem, such as the time to run each expression and
#' the variable sizes.
#'
#' @export
#' @slot code input code
#' @slot graph data frame representing the graph with indices corresponding
#'  to code
DependGraph = setClass("DependGraph",
    slots = c(code = "expression", graph = "data.frame"))


#' Graph where the run time for each expression is known
#'
#' @export
#' @slot time time in seconds to run each expression
TimedDependGraph = setClass("TimedDependGraph",
    slots = c(time = "numeric"),
    contains = "DependGraph")


#' Graph where the size of each variable that can be transferred is known
#'
#' @export
MeasuredDependGraph = setClass("MeasuredDependGraph",
    contains = "TimedDependGraph")



# Schedules
############################################################
# I'm not quite sure how to organize the slots and inheritance in these
# objects. My current principles are:
#   - Add slots when I realize I need them
#   - Keep the names consistent


#' Schedule base class
#'
#' Subclasses of schedule contain an abstract plan to run the code in
#' parallel using various models.
#'
#' @export
#' @slot graph \linkS4class{DependGraph} used to create the schedule
Schedule = setClass("Schedule", 
    slots = c(graph = "DependGraph"
        ))


#' Schedule that contains no parallelism at all
#'
#' @export
SerialSchedule = setClass("SerialSchedule", contains = "Schedule")


#' Task Parallel Schedule
#'
#' @slot transfer transfer variables between processes
#' @slot evaluation data.frame assigning expressions to processors
#' @slot maxWorker maximum number of processors, similar to \code{mc.cores}
#'  in the parallel package
#' @slot overhead minimum time in seconds to evaluate a single expression
#' @slot bandwidth network bandwidth in bytes per second
#' @export
TaskSchedule = setClass("TaskSchedule"
    , slots = c(transfer = "data.frame"
              , evaluation = "data.frame"
              , maxWorker = "integer"
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
#' @slot sequence vector of statement indices
#' @export
ForkSchedule = setClass("ForkSchedule"
    , slots = c(sequence = "integer")
    , contains = "TaskSchedule")


# Generated Code
############################################################

#setClassUnion("LogicalOrCharacter", c("logical", "character"))


#' Generated code ready to write
#'
#' This class contains code that is ready to run and execute, as well as
#' the steps taken to generate this code.
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
