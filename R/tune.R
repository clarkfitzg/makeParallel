#' Tune Function For Specific Arguments
#'
#' Return a modified version of the input function 
#'
#' @export
#' @param FUN function to be tuned
#' @param ... arguments to FUN that are being tuned
#' @param times number of times to run microbenchmark for each call
#' @examples
#' # t is the tuning parameter
#' f = function(x, t){
#'  if(x > 0) Sys.sleep(t^2)
#'  x
#' }
#' # Suppose we plan to call this many times with positive x values
#' f2 = tune(f, x = 100, t = tune_param(list(-0.05, 0.01, 0.1)))
#' # f2 should now have 0.01 as the default argument for t
tune = function(FUN, ..., times = 5L)
{
    NEWFUN = FUN

    args = list(...)
    params_to_tune = which(sapply(args, function(x) !is.null(attr(x, "tune"))))
    
    nparams = length(params_to_tune)
    if(nparams > 1) stop("Multiple tuning parameters not yet implemented")

    # Benchmark all the tuning parameters
    if(nparams == 1){
        params_to_try = args[[params_to_tune]]
        median_times = sapply(params_to_try, function(x){
            timing_args = args
            timing_args[[params_to_tune]] = x
            median_time(FUN, timing_args, times = times)
        })
        fastest_param = params_to_try[[which.min(median_times)]]
        formals(NEWFUN)[[params_to_tune]] = fastest_param
    }

    NEWFUN
}


#' Median Time To Evaluate Function
#'
#' @param FUN function
#' @param args list of arguments to call
#' @param ... additional arguments to microbenchmark
median_time = function(FUN, args, ...)
{
    bm = microbenchmark(do.call(FUN, args), ...)
    median(bm$time)
}


#' Mark Parameter For Tuning
#'
#' @param x list of arguments to time
#' @export
tune_param = function(x)
{
    attr(x, "tune") = TRUE
    x
}

