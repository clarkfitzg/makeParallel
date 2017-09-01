#' Create Function That Learns To Make Itself Faster
#' 
#' This assumes that all implementations can share the same model for complexity. For
#' example, computing the mean requires O(n) operations, so a linear model
#' of the form time = a + bn is appropriate.
#' 
#' Each different implementation gets its own model to fit. The model
#' should be capable of fitting with \code{fit = model(y ~ ., data = d)}
#' and subsequently able to predict with \code{predict(fit, newdata)}. It
#' must be capable of fitting and predicting based only a single
#' observation.
#' 
#' @param func reference implementation of the function to be evolved
#' @param ... different implementations of the reference function
#' @param arg_metadata function to be called with the same arguments as the
#'  implementation functions. Should return a single row of a data.frame.
#' @param model function, statistical model of time as a noisy function of complexity.
#' @return evolving function
#' @export
evolve = function (func, ..., arg_metadata = length_first_arg, model = lm)
{
    funcs = lapply(c(list(func), list(...)), track_usage, arg_metadata = arg_metadata)

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
    data.frame(length_first_arg = length(list(...)[[1]]))
}


#' Get Usage Timings From Closure
#' @export
get_timings = function(f)
{
    get("timings", envir = environment(f))
}


#' Predict Time Required To Run
#' @export
predict.smartfunc = function(f, ...)
{
    model = get("model", f)

    # If the model is NULL, then this implementation hasn't yet been tried
    if(is.null(model)) return -Inf

    arg_metadata = get("arg_metadata", envir = environment(f))

    predict(model, arg_metadata(...))
}


#' Put A New Model In Function Environment
update_model = function(f, model)
{
    assign("model", model, environment(f))
}


#' Record Microbenchmarking Data
#' 
#' Create a version of a function which records microbenchmarking data along with
#' argument metadata. Other information relevant to the function may also
#' get put in the closure environment, such as the model.
#' 
#' @param func original function to be timed
#' @param arg_metadata function to be called with the same arguments as
#' func, should return a numeric vector of fixed size
#' @return function that records how it's called
#' @export
track_usage = function (func, arg_metadata)
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
    class(wrapped_func) = c("smartfunc", class(wrapped_func))
    wrapped_func
}
