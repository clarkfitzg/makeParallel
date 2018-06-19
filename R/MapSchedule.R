mclapplyNames = c("mapply", "lapply", "Map")
names(mclapplyNames) = paste0("parallel::mc", mclapplyNames)


# Apply preprocessing steps to code
# I'll likely come back and generalize this
preprocess = function(code)
{
    for(i in seq_along(code)){
        if(class(code[[i]]) == "for"){
            code[[i]] = forLoopToLapply(code[[i]]) 
        }
    }
    code
}


# Use index position to remove calls that are nested underneath others.
removeNested = function(locs)
{
    # Function calls always end in a 1. Chopping off the 1 and adding zeros
    # to the front allows us to more easily detect the nested structure.
    parentloc = function(loc, frontpad = 0) c(frontpad, loc[-length(loc)])
    locs2 = lapply(locs, parentloc)
    nested = hasAncestors(locs2)
    locs[!nested]
}


# Transform Expression To Parallel
#
# This transforms a single expression to a parallel version by directly
# substituting the variable names. It also prevents nested parallelism.
#
# @param expr language object
# @param map named character vector where values are serial apply
#  functions and the corresponding names are the equivalent parallel apply
#  functions.
# @value new_expr language object modified to parallel
replaceApply = function(expr, map = mclapplyNames)
{
    finds = lapply(map, function(fname){
        find_call(expr, fname)
    })
    finds = do.call(c, finds)
    finds = removeNested(finds)

    # Build the parallel expression based on the original one. Here we only
    # directly swap functions, so we're not changing the actual structure
    # of the tree. If we did we would have to be more careful that the
    # locations don't change as we update.
    parexpr = expr
    for(loc in finds){
        basefunc = as.character(parexpr[[loc]])
        parfunc = names(map[map == basefunc])
        parfunc = parse(text = parfunc)[[1]]
        parexpr[[loc]] = parfunc
    }

    parexpr
}

# Try to use codetools to do this by traversing the AST and updating in
# place. This would be a nice blog post- how to use codetools!
replaceApply2 = function(expr, map = mclapplyNames)
{

    walker = codetools::makeCodeWalker()

}



#' Create Code That Uses Data Parallelism
#'
#' This function transforms R code from serial into parallel.
#' It detects parallelism through the use of top level calls to R's
#' apply family of functions and through analysis of \code{for} loops.
#' Currently supported apply style functions include
#' \code{\link[base]{lapply}} and \code{\link[base]{mapply}}. It doesn't
#' parallelize all for loops that can be parallelized, but it does do the
#' common ones listed in the example.
#'
#' Consider using this if: 
#'
#' \itemize{
#'  \item \code{code} is slow
#'  \item \code{code} uses for loops or one of the apply functions mentioned above
#'  \item You have access to machine with multiple cores that supports
#'      \code{\link[parallel]{makeForkCluster}} (Any UNIX variant should work,
#'      ie. Mac)
#'  \item You're unfamiliar with parallel programming in R
#' }
#'
#' Don't use this if:
#'
#' \itemize{
#'  \item \code{code} is fast enough for your application
#'  \item \code{code} is already parallel, either explicitly with a package
#'      such as parallel, or implicitly, say through a multi threaded BLAS
#'  \item You need maximum performance at all costs. In this case you need
#'      to carefully profile and interface appropriately with a high
#'      performance library.
#' }
#'
#' Currently this function support \code{for} loops that update 0 or 1
#' global variables. For those that update a single variable the update
#' must be on the last line of the loop body, so the for loop should have
#' the following form:
#'
#' \code{
#' for(i in ...){
#'   ... 
#'   x[i] <- ...
#' }
#' }
#'
#' If the last line doesn't update the variable then it's not clear that
#' the loop can be parallelized.
#'
#' Road map of features to implement:
#'
#' \itemize{
#'  \item Prevent from parallelizing calls that are themselves in the body
#'  of a loop.
#' }
#'
#' @export
#' @param code file name, expression from \code{\link[base]{parse}}
#' @param map data frame with corresponding serial and parallel columns
#' @param gen_script_prefix character added to front of file name
#' @examples
#' \dontrun{
#' data_parallel("my_slow_serial.R")
#' }
#'
#' # Each iteration of the for loop writes to a different file- good!
#' # If they write to the same file this will break.
#' data_parallel(parse(text = "
#'      fnames = paste0(1:10, '.txt')
#'      for(f in fname){
#'          writeLines("testing...", f)
#'      }"))
#'
#' # A couple examples in one script
#' serial_code = parse(text = "
#'      x1 = lapply(1:10, exp)
#'      n = 10
#'      x2 = rep(NA, n)
#'      for(i in seq(n)) x2[[i]] = exp(i + 1)
#' ")
#'
#' p = data_parallel(serial_code)
#'
#' eval(serial_code)
#' x1
#' x2
#' rm(x1, x2)
#' 
#' # x1 and x2 should now be back and the same as they were for serial
#' eval(p$output_code)
#' x1
#' x2
#setMethod("schedule", "DependGraph", function(graph, maxWorkers, epsilonTime, ...)
setMethod("schedule", "DependGraph", function(graph, ...)
{

    # TODO: 
    # - Use maxworkers argument
    # - actually put evaluation schedule in here.
    # - Allow users to choose fork or SNOW clusters, and default to
    #   whatever their current system is.
    new("MapSchedule", graph = graph, evaluation = data.frame())
})


setMethod("generate", "MapSchedule", function(sched, ...)
{
    pp_expr = preprocess(sched@graph@code)
    pcode = lapply(pp_expr, replaceApply)
    pcode = as.expression(pcode)
    new("GeneratedCode", schedule = sched, code = pcode)
})


# We could put some OO structure on these, but I'll wait until I have a
# compelling reason. For this one I also need to add a column saying if the
# expression can be parallelized.
firstEvaluation = function(endTime) data.frame(processor = 1L
    , start_time = 0
    , end_time = endTime
    , node = 1L
    )
