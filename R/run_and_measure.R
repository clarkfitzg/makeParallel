#' Run and Measure Code
#'
#' Run the code in the task graph and measure how long each expression
#' takes to run as well as the object sizes of each variable that can
#' possibly be transferred.
#'
#' @export
#' @param taskgraph as returned by \code{\link{inferGraph}}
#' @param envir environment to evaluate the code in
#' @param timer function that returns a timestamp. Milliseconds are a
#'  sufficient timing resolution, because this is intended to apply to code
#'  that takes at least several seconds to run completely.
run_and_measure = function(taskgraph, envir = globalenv(), timer = Sys.time)
{
    tg = taskgraph$inferGraph
    code = taskgraph$input_code
    n = length(code)
    times = numeric(n)

    # Eliminate as much overhead for the timing as possible.
    force(envir)

    for(i in seq(n)){
        # This is additional overhead beyond
        # microbenchmark::microbenchmark, so we lose the fine precision, but
        # as long as we have millisecond resolution we'll be fine.
        gc()
        start_time = timer()
        eval(code[[i]], envir)
        end_time = timer()
        times[i] = end_time - start_time

        from_rows = tg$type == "use-def" & tg$from == i
        vars_to_measure = tg[from_rows, "value"]
        for(v in vars_to_measure){
            size = as.numeric(object.size(get(v, envir)))
            tg[from_rows & tg$value == v, "size"] = size
        }
    }
    taskgraph$inferGraph = tg
    taskgraph$expr_times = as.numeric(times)
    taskgraph
}
