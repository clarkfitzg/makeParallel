#' Make Parallel Code From Serial
#'
#' \code{makeParallel} is a high level function that performs all the steps
#' to generate parallel code, namely:
#'
#' \enumerate{
#'  \item Infer the task graph
#'  \item Schedule the statements
#'  \item Generate parallel code
#' }
#'
#' The arguments allow the user to control every aspect of this process.
#' For more details see \code{vignette("makeParallel-concepts")}.
#'
#' @export
#' @param code file name or expression from \code{\link[base]{parse}}
#' @param data list with names corresponding to variables in the code and values instances of \linkS4class{ChunkDataSource}
#' @param graph object of class \linkS4class{DependGraph}
#' @param run logical, evaluate the code once to gather timings?
#' @param scheduler, function to produce a \linkS4class{Schedule}
#'  from a \linkS4class{DependGraph}.
#' @param ..., additional arguments to scheduler
#' @param generator function to produce \linkS4class{GeneratedCode} from a \linkS4class{Schedule}
#' @param generatorArgs list of named arguments to use with
#'  \code{generator}
#' @param file character name of the file to write the generated script. 
#'  If FALSE then don't write anything to disk.
#'  If TRUE and code comes from a file then use \code{prefix} to make a new
#'  name and write a script.
#' @param prefix character added to front of file name
#' @param overWrite logical write over existing generated file
#' @param OS.type "unix" or "windows", see \code{.Platform}
#' @return code object of class \linkS4class{GeneratedCode}
#' @examples
#' # Make an existing R script parallel
#' script <- system.file("examples/mp_example.R", package = "makeParallel")
#' makeParallel(script)
#'
#' # Write generated code to a new file
#' newfile <- tempfile()
#' makeParallel(script, file = newfile)
#'
#' # Clean up
#' unlink(newfile)
#'
#' # Pass in code directly
#' d <- makeParallel(parse(text = "lapply(mtcars, mean)"))
#'
#' # Now we can examine generated code
#' writeCode(d)
#'
#' # Specify a different scheduler
#' pcode <- makeParallel(parse(text = "x <- 1:100
#' y <- rep(1, 100)
#' z <- x + y"), scheduler = scheduleTaskList)
#' 
#' # Some schedules have plotting methods
#' plot(schedule(pcode))
makeParallel = function(code
    , data = list()
    , graph = expandData(inferGraph(code), data)
    , run = FALSE
    , scheduler = schedule
    , ...
    , generator = generate
    , generatorArgs = list()
    , file = FALSE
    , prefix = "gen_"
    , overWrite = FALSE
    , OS.type = .Platform["OS.type"]
    )
{
    # TODO: Add data and platform arguments in here, this is where they actually belong.
    if(run)
        graph = runMeasure(graph)

    sc = scheduler(graph, ...)
    out = do.call(generator, c(list(sc), generatorArgs))

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
