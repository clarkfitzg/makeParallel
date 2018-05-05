#' Minimize Node Start Time
#'
#' Implementation of "list scheduling".
#' This is a greedy algorithm that assigns each task to the earliest
#' possible processor.
#'
#' See Algorithm 10 in Sinnen's book "Task Scheduling for Parallel
#' Systems".
#'
#' @export
#' @param ntasks number of expressions
#' @param taskgraph data frame as returned from \link{\code{expr_graph}}
#' @param nprocs integer number of processors
#' @param task_times numeric vector of times it will take each expression to
#'  execute
#' @return schedule
minimize_start_time = function(ntasks, taskgraph, nprocs = 2L
    , task_times = rep(1, ntasks))
{

    # Time the processor is ready for a new computation
    processor_ready = rep(0, nprocs)

    # Initialize by scheduling the first expression on the first worker.
    schedule = list(list(type = "run", expr = 1L, processor = 1L))

    for(task in seq(2, ntasks)){
    }
}


#' Compute start time for task on a processor
start_time = function(processor, task, schedule)
{
}


#' Generate Task Parallel Code For SNOW Cluster
#'
#' Produces executable code.
#' 
#' A code generator must know: when to execute a statement
#' 
#' 
#' @export
generate_snow_code = function(schedule)
{
}
