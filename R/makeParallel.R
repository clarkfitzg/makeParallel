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
#' @return code object of class \linkS4class{GeneratedCode}
#' @examples
#' # Try running this on an existing R script to create "gen_script.R"
#' \dontrun{makeParallel("script.R")}
#'
#' # All the defaults
#' d <- makeParallel(parse(text = "lapply(mtcars, mean)"))
#' writeCode(d)
#'
#' # Select a different scheduling function
#' pcode <- makeParallel(parse(text = "x <- 1:100
#' y <- rep(1, 100)
#' z <- x + y"), scheduler = scheduleTaskList)
#' 
#' plot(schedule(pcode))
makeParallel = function(code
    , graph = inferGraph(code)
    , run = FALSE
    , scheduler = schedule
    , ...
    , generator = generate
    , generatorArgs = list()
    , file = FALSE
    , prefix = "gen_"
    , overWrite = FALSE
    )
{
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
