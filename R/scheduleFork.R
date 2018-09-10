#' Single sequential forks scheduler
#'
#' TODO: Inherit parameters from scheduleTaskList
#'
#' @export
#' @param graph object of class \code{DependGraph} as returned from \code{\link{inferGraph}}
#' @param exprTime time in seconds to execute each expression
#' @param exprTimeDefault numeric time in seconds to execute a single
#'  expression. This will only be used if \code{exprTime} is NULL.
#' @return schedule object of class \code{ForkSchedule}
scheduleFork = function(graph
    , exprTime = NULL
    , exprTimeDefault = 10e-6
){


new("ForkSchedule", graph = graph
        , exprTime = exprTime
        )
}
