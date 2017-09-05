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
#' @param f reference implementation of the function to be evolved
#' @param ... different implementations of the reference function
#' @param arg_metadata function to be called with the same arguments as the
#'  implementation functions. Should return a single row of a data.frame.
#' @param model function, statistical model of time as a noisy function of complexity.
#' @return evolving function
#' @export
evolve = function (f, ..., arg_metadata = length_first_arg, model = lm)
{
    funcs = lapply(c(list(f), list(...)), smartfunc
                   , arg_metadata = arg_metadata, model = model)

    function (...)
    {
        expected_times = sapply(funcs, predict, ...)
        fastest_f = funcs[[which.min(expected_times)]]
        fastest_f(...)
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


#' Predict Time Required To Run In Nanoseconds
#' @export
predict.smartfunc = function(f, ...)
{
    # Wait until the model will be used to update it.
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


# Doesn't work
#' @export
init = function()
{
    # Write all these to users global workspace
    assign(".ap", new.env(), globalenv())
    .ap$current_trace <<- 0L
    .ap$timings <<- data.frame()
}


# Not sure if this is the best way to create a mutable variable.
# Nevermind, needs to be run later. Loading the package must override this
# setting.
#unlockBinding("current_trace", environment())


#timings = data.frame()
#timings = data.frame(funcname = character()
#                     , start = as.POSIXct(vector())
#                     , stop = as.POSIXct(vector())
#                     , stringsAsFactors = FALSE)

#' Return tracing functions that use a global variable to issue unique
#' ID's to keep track of which call the function is currently in. Useful
#' for nested calls.
#'
#' @param funcname character
#' @param arg_metadata function
tracer_factory = function (funcname, arg_metadata)
{

    id = if(funcname %in% ls(.ap)){
        # Saves from erasing existing timings
        nrow(.ap[[funcname]])
    } else {
        .ap[[funcname]] <<- data.frame()
        0L
    }

    # Tracer will call these functions:
    list(start = function(){
        id <<- id + 1L
        .ap[[funcname]][id, "start"] <<- Sys.time()
    }, stop = function(){
        .ap[[funcname]][id, "stop"] <<- Sys.time()
    })
}


#' Trace Based Timings For Builtin Functions
#'
#' Can turn off with untrace(func)
#' @export
trace_timings = function (func, arg_metadata = length_first_arg, model = lm)
{
    funcname = substitute(func)
    tracer = tracer_factory(deparse(funcname))
    # TODO: reread the docs
    trace(funcname, tracer = tracer$start, exit = tracer$stop, where = globalenv())
}




#
#arg_grabber = function()
#{
#    #call = match.call()
#    call = match.call(definition = sys.function(sys.parent())
#               , call = sys.call(sys.parent())
#               , expand.dots = TRUE
#               , envir = parent.frame(2L))
#    call
#}
#
#f = function(a = 1, b = 2) arg_grabber()
#
#f(3, 4)
