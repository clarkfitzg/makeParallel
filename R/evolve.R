#' Create Function That Learns To Make Itself Faster
#' 
#' This assumes that all implementations can share the same model for complexity. For
#' example, computing the mean requires O(n) operations.
#' 
#' Each different implementation gets a model to 
#' 
#' @param func reference implementation of the function to be evolved
#' @param ... different implementations of the reference function
#' @param complexity function to be called with the same arguments as the
#'  implementation functions. Should return a vector which can be converted
#'  to numeric.
#' @param model statistical model of time as a noisy function of complexity.
#' @return evolving function
#' @export
evolve = function (func, ..., complexity = nrow_first_arg, model = "updating_lm")
{
    funcs = c(list(func), list(...))

    times = data.frame(func = integer(), time = numeric())

}


#' Count the number of rows in the first argument
nrow_first_arg = function (...)
{
    nrow(list(...)[[1]])
}


#' Create an updating linear model
updating_lm = function ()
{
}
