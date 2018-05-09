#' Convert Code Into Parallel
#'
#' Transforms code into a parallel form.
#'
#' @export
#' @param code file name, expression from \code{\link[base]{parse()}}
#' @param runfirst logical, evaluate the code once to gather timings?
#' @return code that will execute in parallel if possible
#' @examples
#' autoparallel("my_slow_serial.R")
#' pcode = autoparallel(parse(text = "lapply(x, f)"))
autoparallel = function(code
    , runfirst = FALSE
    , scheduler = minimize_start_time
    , code_generator = generate_snow_code
    # TODO:
#    , scheduler_args = list()
#    , code_generator_args = list()
    )
{
    expr = if(is.character(code)){
        # Assume it's a file
        parse(code)
    } else {
        as.expression(code)
    }

    taskgraph = expr_graph(expr)
    plan = scheduler(expr, taskgraph)
    out = code_generator(expr, plan)

    if(is.character(code)){
        newcode = paste0("gen_", code)
        writeLines(out, newcode)
        message(sprintf("generated parallel code is in %s", newcode))
    }

    out
}
