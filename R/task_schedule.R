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
#' @param expressions
#' @param taskgraph data frame as returned from \link{\code{expr_graph}}
#' @param nprocs integer number of processors
#' @param expr_times numeric vector of times it will take each expression to
#'  execute
#' @return schedule
minimize_start_time = function(expressions, taskgraph, nprocs = 2L
    , expr_times = rep(1, length(expressions)))
{

    # Initialize by scheduling the first expression on the first worker.
    schedule = data.frame(processor = 1L
            , type = "eval"
            , start_time = 0
            , end_time = expr_times[1]
            , value = list(task = 1L, expr = expressions[[1]])
            )

    processors = seq(nprocs)
    ntasks = length(expressions)

    # It would be easier if we know every variable that every worker has
    # after every expression and transfer. Then we could see what they
    # need, and where they can possibly get them. SSA could help by
    # eliminating duplicated variable names. For the moment I will assume
    # the variable names are unique.

    for(task in seq(2, ntasks)){
        start_times = sapply(processors, start_time
                , task = task, taskgraph = taskgraph, schedule = schedule)

        earliest_proc = which.min(start_times)

        schedule = update_schedule(earliest_proc, 
                , task = task, taskgraph = taskgraph, schedule = schedule)
    }
    schedule
}


#' Compute start time for task on a processor
start_time = function(processor, task, taskgraph, schedule)
{
}


#' Assign task i to processor j as the last step in the schedule, and
#' return the updated schedule.
update_schedule = function(processor, task, taskgraph, schedule)
{
}


##' Time the processor is ready to begin a new computation, which could be
##' an evaluation or a transfer.
#processor_ready_time = function(schedule, task_times)
#{
#}


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
