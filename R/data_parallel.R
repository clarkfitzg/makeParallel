equivalent_apply = data.frame(serial = c("mapply", "lapply", "Map")
                         , stringsAsFactors = FALSE)
equivalent_apply[, "parallel"] = paste0("parallel::mc", equivalent_functions[, "serial"])


dont_change_in = c("for", "while", "repeat")


# Transform Expression To Parallel
#
# This transforms a single expression to a parallel version by directly
# substituting the variable names. It also prevents nested parallelism.
#
# @param expr 
ser_apply_to_parallel = function(expr, map = equivalent_apply)
{
}


#' Find and parallelize the first use of an apply function
parallelize_first_apply = function(expr
    , ser_funcs = apply_funcs[, "serial"]
    , par_funcs = apply_funcs[, "parallel"]
){
    finds = sapply(ser_funcs, function(fname){
        find_call(expr, fname)
    })

    # list with 0 or 1 elements
    first = lapply(finds, head, 1)
    first = head(do.call(c, first), 1)

    if(length(first) == 0){
        NULL
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
#'      to carefully profile and interface appropriately with compiled code.
#' }
#'
#' @export
#' @param code file name, expression from \code{\link[base]{parse}}
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
data_parallel = function(code, gen_script_prefix = "gen_")
{
}
