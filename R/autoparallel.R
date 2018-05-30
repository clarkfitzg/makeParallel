#' Create Code That Uses Task Parallelism
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
#' @param runfirst logical, evaluate the code once to gather timings?
#' @param ..., additional arguments to scheduler
#' @param gen_script_prefix character added to front of file name
#' @return list of output from each step
#' @examples
#' \dontrun{
#' task_parallel("my_slow_serial.R")
#' }
#' pcode = task_parallel(parse(text = "x = 1:100
#' y = rep(1, 100)
#' z = x + y"))
task_parallel = function(code
    , runfirst = FALSE
    , scheduler = min_start_time
    , code_generator = gen_socket_code
    , ...
#    , code_generator_args = list()
    , gen_script_prefix = "gen_"
    )
{
    taskgraph = task_graph(code)
    if(runfirst) taskgraph = run_and_measure(taskgraph)
    schedule = scheduler(taskgraph, ...)
    out = code_generator(schedule)

    if(is.character(code)){
        # It's a file name
        gen_file_name = file.path(dirname(code), paste0(gen_script_prefix, basename(code)))
        writeLines(out$output_code, gen_file_name)
        message(sprintf("generated parallel code is in %s", gen_file_name))
        out[["gen_file_name"]] = gen_file_name
    }
    out
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
data_parallel = function(code
    , gen_script_prefix = "gen_"
    )
{
}
