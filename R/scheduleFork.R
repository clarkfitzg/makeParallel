# TODO: I haven't limited the number of processors yet- so this assumes we
# have unlimited processors. Not a huge deal.


#' Single sequential forks scheduler
#'
#' TODO: Inherit parameters from scheduleTaskList
#'
#' @export
#' @inheritParams scheduleTaskList
#' @param graph object of class \code{DependGraph} as returned from \code{\link{inferGraph}}
#'  expression. This will only be used if \code{exprTime} is NULL.
#' @param exprTime numeric time to execute each expression
#' @return schedule object of class \code{ForkSchedule}
scheduleFork = function(graph
    , exprTime
    , overhead = 1e3
    , bandwidth = 1.5e9
){

    nnodes = length(graph@code)

    might_fork = seq(nnodes)
    might_fork = might_fork[exprTime > overhead]

    partialSchedule = data.frame(expression = seq(nnodes), fork = "run", time = exprTime)

    # I imagine this pattern generalizes to other greedy algorithms.
    # But I'm not going to generalize it now.
    for(i in seq_len(might_fork)){
        reduction = sapply(might_fork, forkTimeReduction
                       , partialSchedule = partialSchedule
                       , graph = graph
                       )
        if(all(reduction < 0)){
            break
        }
        node_to_fork = might_fork[which.max(reduction)]
        might_fork = setdiff(might_fork, node_to_fork)
        partialSchedule = scheduleOne(node_to_fork, partialSchedule, graph)
    }

    new("ForkSchedule", graph = graph
            , fork = partialSchedule
            , exprTime = exprTime
            , overhead = overhead
            , bandwidth = bandwidth
            )
}


# How long does the partial schedule take to complete if we fork one node?
forkTimeReduction = function(node_to_fork, partialSchedule, graph)
{
    newSchedule = scheduleOne(node_to_fork, partialSchedule, graph)
    runTime(partialSchedule) - runTime(newSchedule)
}


# How long does the partial schedule take to complete?
runTime = function(partialSchedule)
{
    sum(partialSchedule[, "time"])
}

scheduleOne = function(node_to_fork, partialSchedule, graph)
{
}

