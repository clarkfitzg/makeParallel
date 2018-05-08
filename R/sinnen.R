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
        allprocs = lapply(procs, data_ready_time
                , node = node, taskgraph = taskgraph, schedule = schedule)

        start_times = sapply(allprocs, `[[`, "time")

        # Pick the winner, choosing lower numbers in ties
        earliest_proc = which.min(start_times)

        # Update schedule with necessary transfers
        schedule = allprocs[[earliest_proc]]$schedule

        schedule = schedule_node(earliest_proc, 
                , node = node, taskgraph = taskgraph, schedule = schedule)
    }
    schedule
}


data_ready_time = function(proc, node, taskgraph, schedule)
{
    # Transfer from predecessors to current node
    preds = predecessors(node)

    # Not sure we need this
    # No predecessors
    #if(length(preds) == 0L){
    #    return(proc_finish_time(proc, schedule))
    #}

    other_procs = sapply(preds, which_processor, schedule)

    # Let the processors that aren't busy start transferring first
    busy_last = order(sapply(other_procs, proc_finish_time, schedule))
    preds = preds[busy_last]
    other_procs = other_procs[busy_last]

    # Update the schedule
    for(p in preds){
        schedule = schedule_edge(proc, node_from = p, node_to = node
                , taskgraph = taskgraph, schedule = schedule)
    }

    # Now the node is ready to run on proc
    # Pass the updated schedule along so we don't need to compute it again.
    list(time = proc_finish_time(proc, schedule), schedule = schedule)
}


#' Time to transfer data from node i to node j.
transfer_cost = function(node_from, node_to, taskgraph)
{
}


#' Time when the processor has finished all scheduled tasks
proc_finish_time = function(proc, schedule)
{
}


edge_finish_time = function(node_from, node_to, proc_from, proc_to, taskgraph, schedule)
{
    baseline = max(proc_finish_time(proc_from, schedule),
                     proc_finish_time(proc_to, schedule))
    # TODO: Later I can change this to handle cases when data has already
    # been transferred in a previous step
    transfer = if(proc_from == proc_to) 0
        else transfer_cost(node_from, node_to, taskgraph)
    baseline + transfer
}


predecessors = function(node, schedule)
{
}


#' Account for the constraint in one edge of a task graph, and return the
#' updated schedule
schedule_edge = function(processor, node_from, node_to, taskgraph, schedule)
{
}


#' Assign node to processor as the last step in the schedule, and
#' return the updated schedule.
schedule_node = function(processor, node, taskgraph, schedule)
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
