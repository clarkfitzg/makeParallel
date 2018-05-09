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
#' @param expressions from \link{\code{as.expression}}
#' @param taskgraph data frame as returned from \link{\code{task_graph}}
#' @param maxworkers integer maximum number of procs
#' @param node_times numeric vector of times it will take each expression to
#'  execute
#' @return schedule
minimize_start_time = function(expressions, taskgraph, maxworkers = 2L
    , node_times = rep(1, length(expressions))
){

    # Initialize by scheduling the first expression on the first worker.
    schedule = data.frame(processor = 1L
            , type = "eval"
            , start_time = 0
            , end_time = node_times[1]
            , node = 1L
            , from = NA
            , to = NA
            , varname = NA
            )

    procs = seq(maxworkers)
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

        schedule = schedule_node(earliest_proc
                , node = node, taskgraph = taskgraph, schedule = schedule
                , node_time = node_times[node]
                )
    }
    class(schedule) = c("schedule", class(schedule))
    schedule
}


#' Which Processor Is Assigned to this node in the schedule?
which_processor = function(node, schedule)
{
    schedule[schedule$type == "eval" & schedule$node == node, "processor"]
}


data_ready_time = function(proc, node, taskgraph, schedule)
{
    # Transfer from predecessors to current node
    preds = predecessors(node, taskgraph)

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
        schedule = add_send_receive(proc, node_from = p, node_to = node
                , taskgraph = taskgraph, schedule = schedule)
    }

    # Now the node is ready to run on proc
    # Pass the updated schedule along so we don't need to compute it again.
    list(time = proc_finish_time(proc, schedule), schedule = schedule)
}


#' Time to transfer required data between nodes
#' Def 4.4 p. 77
#' This is the place to include models for latency.
transfer_cost = function(node_from, node_to, taskgraph)
{
    ss = (taskgraph$from == node_from) & (taskgraph$to == node_to)
    time = taskgraph[ss, "time"]
    if(length(time) > 1) stop("Can't handle multiple edges in task graph.")
    time
}


#' Time when the processor has finished all scheduled tasks
proc_finish_time = function(proc, schedule)
{
    max(schedule[schedule$processor == proc, "end_time"], 0)
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


#' The nodes which must be completed before node can be evaluated
predecessors = function(node, taskgraph)
{
    taskgraph[taskgraph$to == node, "from"]
}


#' Account for the constraint in one edge of a task graph, and return an
#' updated schedule
add_send_receive = function(processor, node_from, node_to, taskgraph, schedule)
{
    from = schedule[(schedule$type == "eval") & (schedule$node == node_from), ]
    proc_to = processor
    proc_from = from$processor

    # If both nodes are already on the same processor then the data / state
    # is available and this function is a non op.
    if(proc_from == proc_to){
        return(schedule)
    }

    send_start = proc_finish_time(proc_from, schedule)
    tc = transfer_cost(node_from, node_to, taskgraph)
    ss = (taskgraph$from == node_from) & (taskgraph$to == node_to)
    varname = taskgraph[ss, "value"]

    send = data.frame(processor = proc_from
            , type = "send"
            , start_time = send_start
            , end_time = send_start + tc
            , node = NA
            , from = proc_from
            , to = proc_to
            , varname = varname
            )

    # TODO: Hardcoding in 0 latency here and other places, come back and fix.
    receive_start = max(proc_finish_time(proc_to, schedule), send_start)

    receive = data.frame(processor = proc_to
            , type = "receive"
            , start_time = receive_start
            , end_time = receive_start + tc
            , node = NA
            , from = proc_from
            , to = proc_to
            , varname = varname
            )

    rbind(schedule, send, receive)
}


#' Assign node to processor as the last step in the schedule, and
#' return the updated schedule. All dependencies in the task graph should
#' be satisfied at this point.
schedule_node = function(processor, node, taskgraph, schedule, node_time)
{
    start = proc_finish_time(processor, schedule)
    task = data.frame(processor = processor
            , type = "eval"
            , start_time = start
            , end_time = start + node_time
            , node = node
            , from = NA
            , to = NA
            , varname = NA
            )
    rbind(schedule, task)
}
