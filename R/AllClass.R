# This design "nests" the objects together, so Graph is a slot in Schedule
# and Schedule is a slot in GeneratedCode. 
#
# If I wanted "flatter" objects I could make each class inherit from
# another. But this has disadvantages:
#
#   1. They're conceptually quite different objects
#   2. When I define a new class extending the first class (DependGraph)
#       then how do I propagate the new slots through to the subclasses?
#   3. How can I easily call say the `plot()` method for the first class,
#       if all the others have plot methods? I would actually like to do
#       this.

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

GeneratedCode = setClass("GeneratedCode",
    slots = c(schedule = "Schedule", code = "expression"))
