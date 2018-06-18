#' Create Parallel Code From Serial
#'
#' This function is experimental and unstable. If you're trying to actually
#' speed up your code through parallelism then consider
#' \code{\link{data_parallel}}.
#'
#' This function detects task parallelism in code and rewrites code to use it.
#' Task parallelism means two or more processors run different R
#' expressions simultaneously.
#'
#' @export
#' @param code file name, expression from \code{\link[base]{parse}}
#' @param graph object of class \code{\link{DependGraph}}
#' @param runFirst logical, evaluate the code once to gather timings?
#' @param scheduler, function to produce a \code{\link{Schedule}}
#'  from a \code{\link{DependGraph}}.
#' @param ..., additional arguments to scheduler
#' @param gen_script_prefix character added to front of file name
#' @param output_file character where to write the generated script,
#'  or FALSE to not write anything. If missing and code is a file then use
#'  \code{gen_script_prefix} to make a new name and write a script if
#'  code was a file name.
#' @param overWrite logical write over existing out
#' @return list of output from each step
#' @examples
#' \dontrun{
#' task_parallel("my_slow_serial.R")
#' }
#' pcode = task_parallel(parse(text = "x = 1:100
#' y = rep(1, 100)
#' z = x + y"))
parallelize = function(code
    , graph = DependGraph(code)
    , runFirst = FALSE
    , scheduler = schedule
    , codeGenerator = generate
    , ...
#    , code_generator_args = list()
    , gen_script_prefix = "gen_"
    , output_file
    , overWrite = FALSE
    )
{
    if(runFirst)
        graph = run_and_measure(graph)
    schedule = scheduler(graph, ...)
    out = codeGenerator(schedule)
    finish_code_pipeline(out, gen_script_prefix, output_file)
    out
}

finish_code_pipeline = function(generated, gen_script_prefix, output_file)
{
    if(is.null(output_file))
        # TODO: Come back to this point
    if(is.character(code)){
        # It's a file name
        gen_file_name = file.path(dirname(code), paste0(gen_script_prefix, basename(code)))
        writeLines(out$output_code, gen_file_name)
        message(sprintf("generated parallel code is in %s", gen_file_name))
        out[["gen_file_name"]] = gen_file_name
    }
}


setMethod("writeCode", c("GeneratedCode", "character"), function(x, file, ...)
{
    content = as.character(x@code)
    writeLines(content, file)
})
