#' Create Function That Learns To Make Itself Faster
#' 
#' This assumes that all implementations can share the same model for complexity. For
#' example, computing the mean requires O(n) operations, so a linear model
#' of the form time = a + bn is appropriate.
#' 
#' Each different implementation gets its own model to fit.
#' 
#' @param func reference implementation of the function to be evolved
#' @param ... different implementations of the reference function
#' @param complexity function to be called with the same arguments as the
#'  implementation functions. Should return a vector which can be converted
#'  to numeric.
#' @param model statistical model of time as a noisy function of complexity.
#' @return evolving function
#' @export
evolve = function (func, ..., complexity = length_first_arg, model = lm)
{
    funcs = lapply(c(list(func), list(...)), track_usage)

    function (...)
    {
        # TODO: For development
        i = 1
        f = funcs[[i]]

        out = f(...)

        timings = get_timings(f)

        newmodel = model(nanoseconds ~ ., data = timings)
        update_model(f, newmodel)

        out
    }
}


#' The length of the first argument
length_first_arg = function (...)
{
    length(list(...)[[1]])
}


#' Get Usage Timings From Closure
#' @export
get_timings = function(f)
{
    get("timings", envir = environment(f))
}


#' Put A New Model In Function Environment
update_model = function(f, model)
{
    assign("model", model, environment(f))
}


#' Record Microbenchmarking Data
#' 
#' Create a version of a function which records microbenchmarking data along with
#' argument metadata. Other information about the function is also stored
#' in the closure environment, such as the model.
#' 
#' @param func original function to be timed
#' @param arg_metadata function to be called with the same arguments as
#' func, should return a numeric vector of fixed size
#' @return function that records how it's called
#' @export
track_usage = function (func, arg_metadata = length_first_arg)
{
    timings = NULL
    model = NULL
    wrapped_func = function (...)
    {
        time = microbenchmark::microbenchmark(out <- func(...), times = 1L)$time
        metadata = arg_metadata(...)

        # Record the observation that was just made
        obs <- data.frame(nanoseconds = time, metadata)
        timings <<- rbind(timings, obs)

        out
    }
    wrapped_func
}
