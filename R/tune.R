#' Tune Function For Specific Arguments
#'
#' Return a modified version of the input function 
#'
#' @export
#' @param FUN function to be tuned
#' @param ... arguments to FUN that are being tuned
#' @examples
#' # t is the tuning parameter
#' f = function(x, t){
#'  if(x > 0) Sys.sleep(t^2)
#'  x
#' }
#' # Suppose we plan to call this many times with positive x values
#' f2 = tune(f, x = 100, t = tune_param(list(-0.05, 0.01, 0.1)))
#' # f2 should now have 0.01 as the default argument for t
tune = function(FUN, ...)
{
    args = list(...)
    params_to_tune = sapply(args, function(x) !is.null(attr(x, "tune")))
    if(sum(params_to_tune) > 1) stop("Multiple tuning parameters not yet implemented")

    NEWFUN = FUN
    NEWFUN
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
