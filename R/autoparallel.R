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
    )
{
    taskgraph = task_graph(code)
    schedule = scheduler(taskgraph, ...)
    newcode = code_generator(schedule)

    if(is.character(code)){
        newcode_file = paste0("gen_", code)
        writeLines(newcode, newcode_file)
        message(sprintf("generated parallel code is in %s", newcode_file))
    }

    list(taskgraph = taskgraph, schedule = schedule, code = newcode)
}
