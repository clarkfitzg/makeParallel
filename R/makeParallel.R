#' Create Parallel Code From Serial
#'
#' This is the most important function in the package, it performs all the
#' steps required to generate parallel code. Change the default arguments
#' to customize how this happens.
#' By default it writes generated code to a file, pass \code{file = FALSE}
#' to prevent this.
#'
#' For more details see the \code{vignette("makeParallel-concepts")}.
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
#' @param prefix character added to front of file name
#' @param file character where to write the generated script. If this is a
#'  logical TRUE and code is a file then use \code{prefix} to make a new
#'  name and write a script if code was a file name. If logical FALSE then
#'  don't write anything to disk.
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
    , prefix = "gen_"
    , file = TRUE
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
