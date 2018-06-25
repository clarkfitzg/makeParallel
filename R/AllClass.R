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

DependGraph = setClass("DependGraph",
    slots = c(code = "expression", graph = "data.frame"))

MeasuredDependGraph = setClass("MeasuredDependGraph",
    slots = c(time = "numeric"),
    # Also attaches variable sizes to the graph
    contains = "DependGraph")


# Schedules
############################################################

Schedule = setClass("Schedule", 
    slots = c(graph = "DependGraph"
        , evaluation = "data.frame"
        ))

SerialSchedule = setClass("SerialSchedule", contains = "Schedule")

TaskSchedule = setClass("TaskSchedule",
    slots = c(transfer = "data.frame"
              , maxWorker = "integer"
              , exprTime = "numeric"
              , overhead = "numeric"
              , bandwidth = "numeric"
    ), contains = "Schedule")

MapSchedule = setClass("MapSchedule", contains = "Schedule")


# Generated Code
############################################################

#setClassUnion("LogicalOrCharacter", c("logical", "character"))


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
