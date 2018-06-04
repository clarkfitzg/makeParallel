equivalent_apply = data.frame(serial = c("mapply", "lapply", "Map")
                         , stringsAsFactors = FALSE)
equivalent_apply[, "parallel"] = paste0("parallel::mc", equivalent_apply[, "serial"])


# Apply preprocessing steps to code
preprocess = function(code)
{
    for(i in seq_along(code)){
        if(class(code[[i]]) == "for"){
            code[[i]] = forloop_to_mclapply(code[[i]]) 
        }
    }
    code
}


# Transform Expression To Parallel
#
# This transforms a single expression to a parallel version by directly
# substituting the variable names. It also prevents nested parallelism.
#
# @param expr language object
# @value new_expr language object modified to parallel
ser_apply_to_parallel = function(expr, map = equivalent_apply)
{
    # An alternative implementation could mutate the AST in place during a
    # traversal
}


#' Find and parallelize the first use of an apply function
parallelize_first_apply = function(expr
    , ser_funcs = equivalent_apply[, "serial"]
    , par_funcs = equivalent_apply[, "parallel"]
){
    finds = sapply(ser_funcs, function(fname){
        find_call(expr, fname)
    })

    # list with 0 or 1 elements
    first = lapply(finds, head, 1)
    first = head(do.call(c, first), 1)

    if(length(first) == 0){
        expr
    } else {
        index = first[[1]]
        parexpr = expr
        pcode = par_funcs[ser_funcs == names(first)]
        pcode = parse(text = pcode)[[1]]
        parexpr[[index]] = pcode
        parexpr
    }
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
#'      x2 = 1:10
#'      for(i in x2) x2[i] = exp(x2[i])
#' ")
#'
#' parallel_code = data_parallel(serial_code)
#'
#' eval(serial_code)
#' x1
#' x2
#' rm(x1, x2)
#' 
#' # x1 and x2 should now be back and the same as they were for serial
#' eval(parallel_code)
#' x1
#' x2
data_parallel = function(code, map = equivalent_apply, gen_script_prefix = "gen_")
{
    expr = as.expression(code)
    pp_expr = preprocess(expr)
    pcode = lapply(pp_expr, parallelize_first_apply)
    list(output_code = as.expression(pcode))
}
