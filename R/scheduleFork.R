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


# Add a single node to the partial schedule. The problem is how to permute
# the expressions to make it fast. What do we allow to permute? Can't be
# everything, because that's n! permutations every time, takes too long.
# Then we need some way to say what parts of the partial schedule are
# fixed.
#
# The most naive way is to just replace the actual execution of the
# statement with the fork start, and insert the return statement
# immediately before the first statement that needs the result. This never
# permutes statements, so it's essentially equivalent to replacing all assignments
# with future assignments like %<-% everywhere the future version will be
# faster.
#
# A naive way is to push the existing statements as far away as possible
# from each other so that the new one has the maximum amount of time to run
# in parallel before the results are needed. But if we do that on every
# iteration then it's likely that we'll slow down and interfere with what
# we did on the previous iterations.
#
# Somewhat less naive is to push the existing statements far away from each
# other while preserving the work that has already been done.

# I feel like it would be helpful to phrase this in terms of independence.
#
# Another way to look at this is to first identify all the statements to
# parallelize, then look at all feasible permutations. This gets expensive
# fast, because there are (2^n)n! possibilities in general. 2^n for
# choosing whether to run each one in parallel or not. For n = 10 that's
# 3.7 billion possibilities.

scheduleOne = function(node_to_fork, partialSchedule, graph)
{
}

# Let's do a couple common sense cases
