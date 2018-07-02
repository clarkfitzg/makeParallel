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

#' @export
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

#' @export
SerialSchedule = setClass("SerialSchedule", contains = "Schedule")

#' @export
TaskSchedule = setClass("TaskSchedule",
    slots = c(transfer = "data.frame"
              , maxWorker = "integer"
              , exprTime = "numeric"
              , overhead = "numeric"
              , bandwidth = "numeric"
    ), contains = "Schedule")

#' @export
MapSchedule = setClass("MapSchedule", contains = "Schedule")


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
