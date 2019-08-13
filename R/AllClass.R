# I'm not quite sure how to organize the slots and inheritance in these
# objects. My current principles are:
#   - Add slots when I realize I need them
#   - Keep the names consistent

# Not necessary, comes from methods package?
# setOldClass("expression")

setOldClass("igraph")

setOldClass("Brace")



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
TaskGraph = setClass("TaskGraph",
    slots = c(code = "expression", graph = "data.frame"))


#' Graph where the run time for each expression is known
#'
#' @export
#' @slot time time in seconds to run each expression
TimedTaskGraph = setClass("TimedTaskGraph",
    slots = c(time = "numeric"),
    contains = "TaskGraph")


#' Graph where the size of each variable that can be transferred is known
#'
#' @export
MeasuredTaskGraph = setClass("MeasuredTaskGraph",
    contains = "TimedTaskGraph")


# Platforms
############################################################

#' Description of a Platform
#'
#' Describes the physical and software infrastructure that we can use to generate parallel code.
#'
#' @export
#' @slot nWorkers number of parallel workers to use
Platform = setClass("Platform",
    slots = c(nWorkers = "integer"))


#' @export
UnixPlatform = setClass("UnixPlatform",
    contains = "Platform")



# Data Descriptions
############################################################

#' Abstract Base Class For Data Descriptions
#'
#' @export
DataSource = setClass("DataSource")


#' Many Files Representing One Object
#'
#' @export
ChunkDataFiles = setClass("ChunkData"
    , slots = c(files = "character"
                , sizes = "numeric"
                , readFuncName = "character"
                , varName = "character"
                )
    , contains = "DataSource"
    )


# Thu Aug  8 14:50:39 PDT 2019
# The data descriptions that follow seem to use the expanding expression idea, which I've now abandoned.

#' Chunked Data Source defined by R expressions
#'
#' Contains information necessary to load chunks of data into an R session.
#'
#' @export
#' @slot expr expression such that evaluating \code{expr[[i]]} produces the ith chunk of data.
#'      May requires evaluating parent expressions first.
#' @slot varname character variable name in the original code
#' @slot mangledNames names of each chunk of data
#' @slot collector name of a function to call to collect all the chunks into one object
#' @slot collected for internal use with \code{expandData}
ExprChunkData = setClass("ExprChunkData"
    , slots = c(expr = "expression"
                , varname = "character"
                , mangledNames = "character"
                , collector = "character"
                , collected = "logical"
                )
    , contains = "DataSource"
    )


#' Chunked Tables
#'
#' @export
#' @slot columns names of the columns
#' @slot splitColumn name of the columns by which the data is split.
#'      \code{NA} means no split.
TableChunkData = setClass("TableChunkData"
    , slots = c(columns = "character"
                , splitColumn = "character"
                )
    , contains = "ExprChunkData"
    )


#' Description of Data Files
#'
#' Contains information necessary to generate a call to read in these data files
#'
#' @export
#' @slot files absolute paths to all the files
#' @slot readDetails list of details to help efficiently and correctly read in the data
TextTableFiles = setClass("TextTableFiles"
    , slots = c(files = "character", readDetails = "list")
    , contains = "TableChunkData"
)
 

# Schedules
############################################################

#' Schedule base class
#'
#' Subclasses of schedule contain an abstract plan to run the code in
#' parallel using various models.
#'
#' @export
#' @slot graph \linkS4class{TaskGraph} used to create the schedule
Schedule = setClass("Schedule", 
    slots = c(graph = "TaskGraph"
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
              , nWorkers = "integer"
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


#' @export
GeneratedCode = function(schedule, code, file = as.character(NA))
{
    new("GeneratedCode", schedule = schedule, code = code, file = file)
}


# Language objects
############################################################
# I would prefer to get these from another package, i.e. CodeDepends or rstatic

#setOldClass("=")


#' Single Top Level Statement
#'
#' Scripts consist of many such statements.
#' This class is necessary to help out with method dispatch in \code{expandData}.
#' We would use expression, but there's already a method for that.
#'
#' @slot statement language object that is the statement
Statement = setClass("Statement", slots = c(statement = "language"))


#' Assignment
#'
#' @slot lhs name of the variable to be assigned
Assignment = setClass("Assignment", slots = c(lhs = "character")
    , contains = "Statement"
)


#' Simple Statement With Known Value
#'
#' @slot value the value that the lhs will be bound to
KnownAssignment = setClass("KnownAssignment", slots = c(value = "ANY")
    , contains = "Assignment"
)


#' Assignment From Single Vectorized Function
#'
#' @slot functionName name of the function that's called
#' @slot args arguments to the function
AssignmentOneVectorFunction = setClass("AssignmentOneVectorFunction"
#    , slots = c(functionName = "character"
#              , args = "list"
#              )
    , contains = "Assignment"
)


# It would be more elegant to have coercion methods between this class and individual statements,
# but I'd rather not build such tools here.


setAs("Statement", "expression", function(from) as.expression(from@statement))
