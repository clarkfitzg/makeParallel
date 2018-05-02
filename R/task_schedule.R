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
#' @param tasks list of expressions 
#' @param taskgraph data frame as returned from \link{\code{expr_graph}}
#' @param nprocs integer number of processors
#' @param task_times numeric vector of times it will take each expression to
#'  execute
#' @return schedule
minimize_start_time = function(tasks, taskgraph, nprocs = 2L
    , task_times = rep(1, length(tasks)))
{

    # Initialize by scheduling the first expression.
    execute = data.frame(expression = 1L, processor = 1L, time = 0)

    communicate = list()

    for(task in seq(2, length(tasks))){
    }
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
