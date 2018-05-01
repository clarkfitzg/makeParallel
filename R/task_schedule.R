#' Minimize Node Start Time
#'
#' Greedy algorithm that assigns each task to the earliest possible worker
#' node.
#'
#' See Algorithm 10 in Sinnen's book "Task Scheduling for Parallel
#' Systems".
#'
#' @param tasks list of expressions 
#' @param taskgraph data frame as returned from \link{\code{expr_graph}}
#' @param nprocs integer number of processors
#' @param task_times numeric vector of times it will take each expression to
#'  execute
#' @return schedule
#' @export
minimize_start_time = function(tasks, taskgraph, nprocs = 2L
    , task_times = rep(1, length(tasks)))
{

    # Initialize by scheduling the first expression.
    execute = data.frame(expression = 1L, processor = 1L, time = 0)

    communicate = list()

}
