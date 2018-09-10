#' Single sequential forks scheduler
#'
#' TODO: Inherit parameters from scheduleTaskList
#'
#' @export
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

    # Indices of expressions that we may want to fork
    expr_to_fork = rep(TRUE, nnodes)
    expr_to_fork[exprTime < overhead] = FALSE

    partialSchedule = data.frame(expression = seq(nnodes), fork = "run")

    for(i in seq_len(sum(expr_to_fork))){
        reduction = sapply(which(expr_to_fork), reductionTime
                            , partialSchedule = partialSchedule, graph = graph, exprTime = exprTime)
        if(all(reduction > 0)){
            break
        }
        partialSchedule = addFork(max(reduction), partialSchedule)
    }


    new("ForkSchedule", graph = graph
            , fork = partialSchedule
            , exprTime = exprTime
            , overhead = overhead
            , bandwidth = bandwidth
            )
}

reductionTime = function()
{
}
