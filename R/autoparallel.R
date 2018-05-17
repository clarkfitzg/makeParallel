#' Convert Code Into Parallel
#'
#' Transforms code into a parallel form.
#'
#' @export
#' @param code file name, expression from \code{\link[base]{parse()}}
#' @param runfirst logical, evaluate the code once to gather timings?
#' @param ..., additional arguments to scheduler
#' @return list of output from each step
#' @examples
#' autoparallel("my_slow_serial.R")
#' pcode = autoparallel(parse(text = "lapply(x, f)"))
autoparallel = function(code
    , runfirst = FALSE
    , scheduler = minimize_start_time
    , code_generator = generate_snow_code
    , ...
#    , code_generator_args = list()
    , gen_script_prefix = "gen_"
    )
{
    taskgraph = task_graph(code)
    schedule = scheduler(taskgraph, ...)
    out = code_generator(schedule)

    if(is.character(code)){
        outfile = paste0(gen_script_prefix, code)
        writeLines(out$output_code, outfile)
        message(sprintf("generated parallel code is in %s", outfile))
    }
    out
}
