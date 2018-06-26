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
#' @param run logical, evaluate the code once to gather timings?
#' @param scheduler, function to produce a \code{\link{Schedule}}
#'  from a \code{\link{DependGraph}}.
#' @param ..., additional arguments to scheduler
#' @param prefix character added to front of file name
#' @param file character where to write the generated script. If this is a
#'  logical TRUE and code is a file then use \code{prefix} to make a new
#'  name and write a script if code was a file name. If logical FALSE then
#'  don't write anything.
#' @param overWrite logical write over existing generated file
#' @return code object of class \code{\link{GeneratedCode}}
#' @examples
#' \dontrun{
#' task_parallel("my_slow_serial.R")
#' }
#' pcode = task_parallel(parse(text = "x = 1:100
#' y = rep(1, 100)
#' z = x + y"))
makeParallel = function(code
    , graph = inferGraph(code)
    , run = FALSE
    , scheduler = schedule
    , codeGenerator = generate
    , ...
#    , code_generator_args = list()
    , prefix = "gen_"
    , file = TRUE
    , overWrite = FALSE
    )
{
    if(run)
        graph = runMeasure(graph)
    sc = scheduler(graph, ...)
    out = codeGenerator(sc)

    originalFile = file(graph)

    if(is.logical(file) && file && !is.na(originalFile)){
        file = prefixFileName(originalFile, prefix)
    }

    if(is.character(file)){
        file(out) = file
        writeCode(out, file, overWrite = overWrite)
    }

    out
}
