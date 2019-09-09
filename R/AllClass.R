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


#' Placeholder for local \code{cluster} objects from the parallel package, for example, those produced by \code{parallel::makeCluster}.
#'
#' @export
#' @slot name symbol to use for the cluster name when generating code
#' @slot scratchDir place to write intermediate data files
ParallelLocalCluster = setClass("ParallelLocalCluster"
    , slots = c(name = "character", scratchDir = "character")
    , contains = "Platform"
    )


#' @export
UnixPlatform = setClass("UnixPlatform",
    contains = "Platform")



# Data Descriptions
############################################################

#' Abstract Base Class For Data Descriptions
#'
#' @slot varName name of the variable in the code
#' @slot nDistinctUpper upper bound for number of distinct values
#' @export
DataSource = setClass("DataSource", slots = c(varName = "character", nDistinctUpper = "numeric"))


#' Data Unspecified
NoDataSource = setClass("NoDataSource", contains = "DataSource")


#' Many Files Representing One Object
#'
#' @export ChunkDataFiles
#' @exportClass ChunkDataFiles
ChunkDataFiles = setClass("ChunkDataFiles"
    , slots = c(files = "character"
                , sizes = "numeric"
                , readFuncName = "character"
                )
    , contains = "DataSource"
    )


# #' @export ChunkLoadFunc
# #' @exportClass ChunkLoadFunc
# #' @slot read_func_name for example, "read.csv".
# #'      Using a character means that the function must be available, which in practice probably means it ships with R.
# #'      We should generalize this to allow functions from packages and user defined functions.
# #' @slot read_args arguments to read the function, probably the names of files.
# #'      It could accept a general vector, but I'll need to think more carefully about how to generate code with an object that's not a character.
# #'      One way is to serialize the object right into the script.
# #'      Another way is to deparse and parse.
# ChunkLoadFunc = setClass("ChunkLoadFunc", contains = "DataSource",
#          slots = c(read_func_name = "character", read_args = "character", varname = "character", combine_func_name = "character"))
# 
# 
# setValidity("ChunkLoadFunc", function(object)
# {
#     if(length(object@read_args) == 0) "No files specified" 
#     else TRUE
# })



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



# DataParallelSchedule machinery
# Most of these classes are used to implement the scheduler and code generator
############################################################

#' Abstract base class for blocks comprising a DataParallelSchedule
#'
#' These are NOT basic blocks in the sense of compilers, because they may contain control flow.
#'
#' @slot code to evaluate in serial on the manager.
CodeBlock = setClass("CodeBlock", slots = c(code = "expression"))


#' Initialize the platform
InitPlatformBlock = setClass("InitPlatformBlock", contains = "CodeBlock")


#' Shut down the platform
StopPlatformBlock = setClass("StopPlatformBlock", contains = "CodeBlock")


#' Load Data
DataLoadBlock = setClass("DataLoadBlock", contains = "CodeBlock")


#' Code to run in serial
#'
#' @slot collect names of objects to collect from the workers to the manager.
SerialBlock = setClass("SerialBlock", contains = "CodeBlock",
         slots = c(collect = "character"))


#' Code to run in parallel
#'
#' @slot export names of objects to export from manager to workers.
ParallelBlock = setClass("ParallelBlock", contains = "CodeBlock",
         slots = c(export = "character"))


#' Split one chunked object using another as a factor
#' 
#' GROUP BY style code becomes a split followed by an lapply, and both are parallel blocks.
#' The semantic meaning of this in a schedule is that the data will be grouped, ready for an lapply on the groups.
#'
#' @slot groupData names of chunked variables to split according to groupIndex
#' @slot groupIndex names of chunked variables that define the split
#' @slot lhs name of the chunked variable that holds the result of the split.
#'          This doesn't necessarily need to be here, but we use it to generate code.
SplitBlock = setClass("SplitBlock", contains = "ParallelBlock",
         slots = c(groupData = "character"
                   , groupIndex = "character"
                   , lhs = "character"
                   ))


#' Abstract base class for reducible function implementations
#'
#' @slot reduce name of a reducible function 
#' @slot predicate function that takes in a resource and returns TRUE if this particular resource can be reduced using this ReduceFun, and FALSE otherwise.
#'  TODO: Define resource and make it more user accessible if users are expected to compute on it.
ReduceFun = setClass("ReduceFun", slots = c(reduce = "character", predicate = "function"))


#' Implementation for a reducible function using function names only
#'
#' This assumes that all of the summary, combine and query functions are defined and available in the R environment where it will run.
#' See \linkS4class{UserDefinedReduce} to define and use your own functions.
#'
#' @slot summary name of a function that each worker will call on their chunk of the data.
#'		This produces an intermediate result.
#' @slot combine name of a function to combine many intermediate results into a single intermediate results
#' @slot query name of a function to produce the actual final result from an intermediate result
SimpleReduce = setClass("SimpleReduce", contains = "ReduceFun",
        slots = c(summary = "character"
                  , combine = "character"
                  , query = "character"
                  ))


UserDefinedReduce = setClass("UserDefinedReduce", contains = "ReduceFun",
        slots = c(summary = "function"
                  , combine = "function"
                  , query = "function"
                  ))


#' Reduce in parallel on the workers
#'
#' @slot objectToReduce name of the object to apply the reduce to
#' @slot resultName name of the object to save the result as
#' @slot reduceFun implementation of a reduce to use
ReduceBlock = setClass("ReduceBlock", contains = "CodeBlock",
         slots = c(objectToReduce = "character"
                   , resultName = "character"
                   , reduceFun = "ReduceFun"
                   ))


#' @slot assignmentIndices assigns each data chunk to a worker. For example, c(2, 1, 1) assigns the 1st chunk to worker 2, and chunks 2 and 3 to worker 1.
#' @slot blocks list with every object an instance of a CodeBlock
#' @export
DataParallelSchedule = setClass("DataParallelSchedule", contains = "Schedule",
         slots = c(assignmentIndices = "integer"
                   , nWorkers = "integer"
                   , blocks = "list"
                   ))


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
