#' Run and Measure Code
#'
#' Will export this once I the full pipeline works.
#'
#' Run the serial code in the task graph and measure how long each expression
#' takes to run as well as the object sizes of each variable that can
#' possibly be transferred.
#'
#' This does naive and biased timing since it doesn't account for the
#' overhead in evaluating a single expression. However, this is fine for
#' this application since the focus is on measuring statements that take at
#' least on the order of 1 second to run. 
#'
#' @param code to be passed into \code{\link{inferGraph}}
#' @param graph object of class \code{DependGraph}
#' @param envir environment to evaluate the code in
#' @param timer function that returns a timestamp.
#' @return graph object of class \code{MeasuredDependGraph}
runMeasure = function(code, graph = inferGraph(code), envir = globalenv(), timer = Sys.time)
{
    expr = graph@code
    n = length(expr)
    times = numeric(n)
    tg = graph@graph

    # Eliminate as much overhead for the timing as possible.
    force(envir)

    for(i in seq(n)){
        gc()
        start_time = timer()
        eval(expr[[i]], envir)
        end_time = timer()
        times[i] = end_time - start_time

        from_rows = which(tg$type == "use-def" & tg$from == i)

        # This is redundant because we may check and store the same object
        # size multiple times. Seems like more trouble than it's worth to
        # do it in a non redundant way.
        for(row_index in from_rows){
            varname = tg[["value"]][[row_index]][["varname"]]
            size = as.numeric(utils::object.size(get(varname, envir)))
            tg[["value"]][[row_index]][["size"]] = size
        }
    }

    new("MeasuredDependGraph", code = expr, graph = tg, time = times)
}
