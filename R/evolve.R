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
evolve = function (func, ..., complexity = nrow_first_arg, model = lm)
{
    funcs = c(list(func), list(...))

    # Start out with lists of NULL
    models = vector(length(funcs), mode = "list")
    timings = vector(length(funcs), mode = "list")

    # TODO: Better design may be to separate this into separate functions
    # that record how they are used.

    function (...)
    {
        # For development
        i = 1

        t = microbenchmark::microbenchmark(out <- funcs[[i]](...), times = 1L)$time

        # Record the observation that was just made
        obs <- data.frame(time = t, complexity = complexity)
        timings[[i]] <<- rbind(timings[[i]], obs)

        # Update the corresponding model
        models[[i]] <<- model(time ~ ., data = timings[[i]])
    }
}


#' The length of the first argument
length_first_arg = function (...)
{
    length(list(...)[[1]])
}


#' Record Microbenchmarking Data
#' 
#' Create a version of a function which records microbenchmarking data along with
#' argument metadata
#' 
#' @param func original function to be timed
#' @param arg_metadata function to be called with the same arguments as
#' func, should return a numeric vector of fixed size
#' @return function that records how it's called
#' @export
track_usage = function (func, arg_metadata = length_first_arg)
{
    timings = NULL
    newfunc = function (...)
    {
        time = microbenchmark::microbenchmark(out <- func(...), times = 1L)$time
        metadata = arg_metadata(...)

        # Record the observation that was just made
        obs <- data.frame(nanoseconds = time, metadata)
        timings <<- rbind(timings, obs)

        # The function updates itself
        attr(newfunc, "timings") <<- timings

        out
    }
    newfunc
}
