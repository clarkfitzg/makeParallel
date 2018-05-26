#' Convert Code Into Parallel
#'
#' Detects task parallelism in code and rewrites code to use it.
#'
#' @export
#' @param code file name, expression from \code{\link[base]{parse()}}
#' @param runfirst logical, evaluate the code once to gather timings?
#' @param ..., additional arguments to scheduler
#' @return list of output from each step
#' @examples
#' \dontrun{
#' autoparallel("my_slow_serial.R")
#' }
#' pcode = autoparallel(parse(text = "lapply(x, f)"))
autoparallel = function(code
    , runfirst = FALSE
    , scheduler = min_start_time
    , code_generator = gen_snow_code
    , ...
#    , code_generator_args = list()
    , gen_script_prefix = "gen_"
    )
{
    taskgraph = task_graph(code)
    if(runfirst) taskgraph = run_and_measure(taskgraph)
    schedule = scheduler(taskgraph, ...)
    out = code_generator(schedule)

    if(is.character(code)){
        # It's a file name
        gen_file_name = file.path(dirname(code), paste0(gen_script_prefix, basename(code)))
        writeLines(out$output_code, gen_file_name)
        message(sprintf("generated parallel code is in %s", gen_file_name))
        out[["gen_file_name"]] = gen_file_name
    }
    out
}
