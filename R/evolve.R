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
    funcs = lapply(c(list(func), list(...)), smartfunc, arg_metadata = arg_metadata)

    function (...)
    {
        # TODO: For development
        i = 1
        f = funcs[[i]]

        out = f(...)

        timings = get_timings(f)

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
    # We wait until the model will be used to update it.
    update(f)
    fenv = environment(f)
    fitted_model = get("fitted_model", envir = fenv)

    # If the model is NULL, then this implementation hasn't yet been tried.
    # Convenient to return -Inf since this will be a minimum
    if(is.null(fitted_model)) return(-Inf)

    arg_metadata = get("arg_metadata", envir = environment(f))
    predict(fitted_model, arg_metadata(...))
}


#' Update The Model Predicting Wall Time
#' 
#' Updates the model in place through the environment. Not sure if this is
#' ideal.
update.smartfunc = function(f)
{
    fenv = environment(f)
    model_current = get("model_current", envir = fenv)
    if(model_current) return()

    model = get("model", envir = fenv)
    timings = get("timings", envir = fenv)

    fitted_model = model(nanoseconds ~ ., data = timings)

    assign("fitted_model", fitted_model, fenv)
    assign("model_current", TRUE, fenv)
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
smartfunc = function (func, arg_metadata = length_first_arg, model = lm)
{
    timings = NULL
    fitted_model = NULL
    # This flag records whether the model has been fitted to the most recently
    # observed data
    model_current = TRUE
    wrapped_func = function (...)
    {
        time = microbenchmark::microbenchmark(out <- func(...), times = 1L)$time
        metadata = arg_metadata(...)

        # Record the observation that was just made
        obs = data.frame(nanoseconds = time, metadata)
        timings <<- rbind(timings, obs)
        model_current <<- FALSE

        out
    }
    class(wrapped_func) = c("smartfunc", class(wrapped_func))
    wrapped_func
}
