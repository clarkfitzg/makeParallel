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


DependGraph = setClass("DependGraph",
    slots = c(code = "expression", graph = "data.frame"))


MeasuredDependGraph = setClass("MeasuredDependGraph",
    slots = c(time = "numeric"),
    # Also attaches variable sizes to the graph
    contains = "DependGraph")


# Maybe have this be a virtual class?
Schedule = setClass("Schedule", 
    slots = c(evaluation = "data.frame", transfer = "data.frame"))


SerialSchedule = setClass("SerialSchedule", contains = "Schedule")
TaskSchedule = setClass("TaskSchedule", contains = "Schedule")
MapSchedule = setClass("MapSchedule", contains = "Schedule")
