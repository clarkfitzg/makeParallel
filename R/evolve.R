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


#' Count the number of rows in the first argument
nrow_first_arg = function (...)
{
    nrow(list(...)[[1]])
}
