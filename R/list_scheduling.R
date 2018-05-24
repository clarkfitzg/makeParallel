# Mon May  7 11:41:11 PDT 2018
#
# This is a direct implementation of Sinnen's definitions in 'Task
# Scheduling for parallel Systems'
#
# I'll try to adhere to the convention that 'time' refers to the relative
# timeline starting with the beginning of the computation at 0, and 'cost'
# means an absolute time required to do some smaller step. 

# TODO: Define standard interface for a scheduler, ie. additional arguments
# for the timings and variable sizes.

#' Minimize expression Start Time
#'
#' Implementation of "list scheduling".
#' This is a greedy algorithm that assigns each expression to the earliest
#' possible processor.
#'
#' See Algorithm 10 in Sinnen's book "Task Scheduling for Parallel
#' Systems".
#'
#' @export
#' @param taskgraph list as returned from \link{\code{task_graph}}
#' @param maxworkers integer maximum number of procs
#' @param expr_times time in seconds to execute each expression
#' @param default_expr_time numeric time in seconds to execute a single
#'  expression. This will only be used if \code{expr_times} is NULL.
#' @param overhead numeric seconds to send any object
#' @param bandwidth numeric speed that the network can transfer an object
#'  between processors in bytes per second. We don't take network
#'  contention into account. This will have to be extended to account for
#'  multiple machines.
#' @return schedule
min_start_time = function(taskgraph, maxworkers = 2L
    , expr_times = taskgraph$expr_times
    , default_expr_time = 10e-6, overhead = 8e-6
    , bandwidth = 1.5e9
){

    procs = seq(maxworkers)
    nnodes = length(taskgraph$input_code)
    tg = taskgraph$task_graph

    if(is.null(expr_times)){
        expr_times = rep(default_expr_time, nnodes)
    }

    # Initialize by scheduling the first expression on the first worker.
    schedule = list(
        eval = data.frame(processor = 1L
            , start_time = 0
            , end_time = expr_times[1]
            , node = 1L
            ),
        transfer = data.frame(start_time_send = numeric()
            , start_time_receive = numeric()
            , end_time_send = numeric()
            , end_time_receive = numeric()
            , proc_send = integer()
            , proc_receive = integer()
            , varname = character()
            , stringsAsFactors = FALSE
        ))
    class(schedule) = c("schedule", class(schedule))

    # It would be easier if we know every variable that every worker has
    # after every expression and transfer. Then we could see what they
    # need, and where they can possibly get them. SSA could help by
    # eliminating duplicated variable names. For the moment I will assume
    # the variable names are unique.

    for(node in seq(2, nnodes)){
        allprocs = lapply(procs, data_ready_time
                , node = node, taskgraph = tg, schedule = schedule
                , overhead = overhead, bandwidth = bandwidth
                )

        start_times = sapply(allprocs, `[[`, "time")

        # Pick the winner, choosing lower numbers in ties
        earliest_proc = which.min(start_times)

        # Update schedule with necessary transfers
        schedule = allprocs[[earliest_proc]]$schedule

        schedule = schedule_node(earliest_proc
                , node = node, schedule = schedule
                , node_time = expr_times[node]
                )
    }

    c(taskgraph, list(schedule = schedule, maxworkers = maxworkers, expr_times = expr_times
                     , overhead = overhead, bandwidth = bandwidth))
}


#' Which Processor Is Assigned to this node in the schedule?
which_processor = function(node, schedule)
{
    e = schedule$eval
    e[e$node == node, "processor"]
}


data_ready_time = function(proc, node, taskgraph, schedule, overhead, bandwidth)
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
                , taskgraph = taskgraph, schedule = schedule
                , overhead = overhead, bandwidth = bandwidth
                )
    }

    # Now the node is ready to run on proc
    # Pass the updated schedule along so we don't need to compute it again.
    list(time = proc_finish_time(proc, schedule), schedule = schedule)
}


#' Time to transfer required data between nodes
#' Def 4.4 p. 77
#' This is the place to include models for latency.
transfer_cost = function(node_from, node_to, taskgraph, overhead, bandwidth)
{
    ss = (taskgraph$from == node_from) & (taskgraph$to == node_to)
    size = taskgraph[ss, "size"]
    if(length(size) > 1) stop("Can't handle multiple edges in task graph.")
    size / bandwidth + overhead
}


#' Time when the processor has finished all scheduled tasks
proc_finish_time = function(proc, schedule)
{

    t_eval = schedule$eval[schedule$eval$processor == proc, "end_time"]
    trans = schedule$transfer
    t_send = trans[trans$proc_send == proc, "end_time_send"]
    t_receive = trans[trans$proc_receive == proc, "end_time_receive"]
    max(t_eval, t_send, t_receive, 0)
}


#' The nodes which must be completed before node can be evaluated
predecessors = function(node, taskgraph)
{
    taskgraph[taskgraph$to == node, "from"]
}


#' Account for the constraint in one edge of a task graph, and return an
#' updated schedule
add_send_receive = function(processor, node_from, node_to, taskgraph, schedule
        , overhead, bandwidth)
{
    # TODO: This will probably break if we evaluate the same node multiple
    # times, but that's a future problem.
    from = schedule$eval[schedule$eval$node == node_from, ]
    proc_receive = processor
    proc_send = from$processor

    # If both nodes are already on the same processor then the data / state
    # is available and this function is a non op.
    if(proc_send == proc_receive){
        return(schedule)
    }

    start_time_send = proc_finish_time(proc_send, schedule)
    tc = transfer_cost(node_from, node_to, taskgraph, overhead, bandwidth)
    ss = (taskgraph$from == node_from) & (taskgraph$to == node_to)
    varname = taskgraph[ss, "value"]

    # TODO: Hardcoding in 0 latency here and other places, come back and fix.
    start_time_receive = max(proc_finish_time(proc_receive, schedule), start_time_send)

    this_transfer = data.frame(start_time_send = start_time_send
            , end_time_send = start_time_send + tc
            , start_time_receive = start_time_receive
            , end_time_receive = start_time_receive + tc
            , proc_send = proc_send
            , proc_receive = proc_receive
            , varname = varname
            , stringsAsFactors = FALSE
            )

    schedule$transfer = rbind(schedule$transfer, this_transfer)
    schedule
}


#' Assign node to processor as the last step in the schedule, and
#' return the updated schedule. All dependencies in the task graph should
#' be satisfied at this point.
schedule_node = function(processor, node, schedule, node_time)
{
    start_time = proc_finish_time(processor, schedule)

    this_task = data.frame(processor = processor
            , start_time = start_time
            , end_time = start_time + node_time
            , node = node
            )

    schedule$eval = rbind(schedule$eval, this_task)
    schedule
}
