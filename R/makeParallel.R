
# @param data list with names corresponding to variables in the code and values instances of \linkS4class{ChunkDataSource}

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
#' @param code file name or a string containing code to be parsed
#' @param isFile logical, is the code a file name?
#' @param expr expression, for example from \code{\link[base]{parse}}
#' @param nWorkers integer, number of parallel workers
#' @param platform \linkS4class{Platform} to target for where the generated code will run
#' @param graph object of class \linkS4class{DependGraph}
#' @param run logical, evaluate the code once to gather timings?
#' @param scheduler, function to produce a \linkS4class{Schedule}
#'  from a \linkS4class{DependGraph}.
#' @param ..., additional arguments to scheduler
#' @param generator function to produce \linkS4class{GeneratedCode} from a \linkS4class{Schedule}
#' @param generatorArgs list of named arguments to use with
#'  \code{generator}
#' @param outFile character name of the file to write the generated script. 
#'  If FALSE then don't write anything to disk.
#'  If TRUE and code comes from a file then use \code{prefix} to make a new
#'  name and write a script.
#' @param prefix character added to front of file name
#' @param overWrite logical write over existing generated file
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
#' d <- makeParallel(expr = parse(text = "lapply(mtcars, mean)"))
#'
#' # Examine generated code
#' writeCode(d)
#'
#' # Specify a different scheduler
#' pcode <- makeParallel("x <- 1:100
#' y <- rep(1, 100)
#' z <- x + y", scheduler = scheduleTaskList)
#' 
#' # Some schedules have plotting methods
#' plot(schedule(pcode))
makeParallel = function(code
    , isFile = file.exists(code)
    , expr = if(isFile) parse(code, keep.source = TRUE) else parse(text = code, keep.source = FALSE)
    , data = NULL
    , nWorkers = parallel::detectCores()
    , platform = Platform(nWorkers)
    , graph = inferGraph(expr)
    , run = FALSE
    , scheduler = schedule
    , ...
    , generator = generate
    , generatorArgs = list()
    , outFile = FALSE
    , prefix = "gen_"
    , overWrite = FALSE
    )
{
    if(run)
        graph = runMeasure(graph)

    sc = scheduler(graph, platform, data, ...)
    out = do.call(generator, c(list(sc), generatorArgs))

    originalFile = file(graph)

    if(is.logical(outFile) && outFile && !is.na(originalFile)){
        outFile = prefixFileName(originalFile, prefix)
    }

    if(is.character(outFile)){
        file(out) = outFile
        writeCode(out, outFile, overWrite = overWrite)
    }

    out
}
