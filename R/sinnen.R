# Mon May  7 11:41:11 PDT 2018
#
# This is a direct implementation of Sinnen's definitions in 'Task
# Scheduling for parallel Systems'
#
# I'll try to adhere to the convention that 'time' refers to the relative
# timeline starting with the beginning of the computation at 0, and 'cost'
# means an absolute time required to do some smaller step. 


#' Minimize Node Start Time
#'
#' Implementation of "list scheduling".
#' This is a greedy algorithm that assigns each node to the earliest
#' possible processor.
#'
#' See Algorithm 10 in Sinnen's book "Task Scheduling for Parallel
#' Systems".
#'
#' @export
#' @param expressions
#' @param taskgraph data frame as returned from \link{\code{expr_graph}}
#' @param nprocs integer number of procs
#' @param node_times numeric vector of times it will take each expression to
#'  execute
#' @return schedule
minimize_start_time = function(expressions, taskgraph, nprocs = 2L
    , node_times = rep(1, length(expressions))
){

    # Initialize by scheduling the first expression on the first worker.
    schedule = data.frame(processor = 1L
            , type = "eval"
            , start_time = 0
            , end_time = node_times[1]
            , value = list(node = 1L, expr = expressions[[1]])
            )

    procs = seq(nprocs)
    nnodes = length(expressions)

    # It would be easier if we know every variable that every worker has
    # after every expression and transfer. Then we could see what they
    # need, and where they can possibly get them. SSA could help by
    # eliminating duplicated variable names. For the moment I will assume
    # the variable names are unique.

    for(node in seq(2, nnodes)){
        start_times = sapply(procs, start_time
                , node = node, taskgraph = taskgraph, schedule = schedule)

        earliest_proc = which.min(start_times)

        schedule = update_schedule(earliest_proc, 
                , node = node, taskgraph = taskgraph, schedule = schedule)
    }
    schedule
}


data_ready_time = function(node, proc, schedule)
{
    finished = predecessors(node)
    
    # Transfer from predecessors to current node
}


#' Time to transfer data from node i to node j.
transfer_cost = function(i, j, taskgraph)
{
}


edge_finish_time = function(node_from, node_to, proc_from, proc_to, taskgraph, schedule)
{
    baseline = max(processor_finish_time(proc_from),
                     processor_finish_time(proc_to))
    extra = if(proc_from == proc_to) 0
        else transfer_cost(i, j, taskgraph)
    baseline + extra
}


predecessors = function(node, schedule)
{
}


#' Assign node i to processor j as the last step in the schedule, and
#' return the updated schedule.
update_schedule = function(processor, node, taskgraph, schedule)
{
}



##' Compute start time for node on a processor
#start_time = function(processor, node, taskgraph, schedule)
#{
#}

##' Time the processor is ready to begin a new computation, which could be
##' an evaluation or a transfer.
#processor_ready_time = function(schedule, node_times)
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
