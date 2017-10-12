#' Create Function That Learns To Make Itself Faster
#' 
#' This assumes that all implementations can share the same model for
#' complexity. For example, computing the mean requires O(n) operations, so
#' a linear model of the form time = a + bn is appropriate.
#' 
#' Each different implementation gets its own model to fit. The call to fit
#' the model must look like \code{fit = model(y ~ ., data = d)} and
#' subsequently able to predict with \code{predict(fit, newdata)}. The
#' model must be capable of fitting and predicting based only a single
#' observation.
#' 
#' @param f reference implementation of the function to be evolved
#' @param ... different implementations of the reference function
#' @param metadata_func function to be called with the same arguments as the
#'  implementation functions. Should return a single row of a data.frame or a vector which
#'  can be coerced to such.
#' @param model function, statistical model of time as a noisy function 
#'  of complexity.
#' @return evolving function
#' @export
evolve = function (f, ..., metadata_func = length_first_param, model = lm)
{
    funcs = lapply(c(list(f), list(...)), smartfunc
                   , metadata_func = metadata_func, model = model)

    function (...)
    {
        expected_times = sapply(funcs, predict, ...)
        fastest_f = funcs[[which.min(expected_times)]]
        fastest_f(...)
    }
}


#' The length of the first formal parameter
#'
#' @export
length_first_param = function (...)
{
    data.frame(length_first_param = length(list(...)[[1]]))
}


#' The length of the first formal parameter
#'
#' This trace based implementation assumes it will be called inside the
#' function. May be able to use dynGet() too.
length_first_param_trace = function ()
{
    func = eval(sys.call(1L)[[1]])
    firstarg = methods::formalArgs(func)[1]
    length(get(firstarg))
}

#
#f = function(x, y)
#{
#    # Should do same thing as length(x)
#    length_first_param_trace()
#}
#
#x = 20
#f(1:5)
#


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

    metadata_func = get("metadata_func", envir = environment(f))
    # TODO: handle vector output
    metadata = metadata_func(...)
    predictor = to_row(metadata)
    predict(fitted_model, predictor)
}


#' Make Into Row Of data.frame
#'
to_row = function(metadata)
{
    if(is.data.frame(metadata) && nrow(metadata) == 1){
        metadata
    }
    else if(is.vector(metadata)){
        as.data.frame(t(metadata))
    } else {
        stop("Not able to convert into data.frame with one row")
    }
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
#' @param metadata_func function to be called with the same arguments as
#' func, should return a numeric vector of fixed size
#' @return function that records how it's called
#' @export
smartfunc = function (func, metadata_func = length_first_param, model = lm)
{
    timings = NULL
    fitted_model = NULL
    # This flag records whether the model has been fitted to the most recently
    # observed data
    model_current = TRUE
    wrapped_func = function (...)
    {
        time = microbenchmark::microbenchmark(out <- func(...), times = 1L)$time
        metadata = metadata_func(...)
        predictor = to_row(metadata)

        # Record the observation that was just made
        obs = data.frame(nanoseconds = time, predictor)
        timings <<- rbind(timings, obs)
        model_current <<- FALSE

        out
    }
    class(wrapped_func) = c("smartfunc", class(wrapped_func))
    wrapped_func
}


env = new.env()
env$timings <- data.frame()



# TODO: I think the trace based one is more general, so I should probably
# prefer that.

#' Trace Based Timings For Builtin Functions
#'
#' Can turn off with untrace(func)
#' @export
trace_timings = function (func, metadata_func = length_first_param_trace, model = lm)
{
    funcname_symbol = substitute(func)
    funcname = deparse(funcname_symbol)

    ss = startstop(funcname, metadata_func, model)

    #trace(funcname_symbol, tracer = start, exit = stop, where = globalenv())
    trace(funcname_symbol, tracer = ss$start, exit = ss$stop, where = globalenv())
}


#' Separating this functionality works around error in hasTsp(x), not sure
#' why that was happening in first place.  May try to reorganize later.
startstop = function(funcname, metadata_func, model){

    if(!(funcname %in% ls(env))){
        assign(funcname, data.frame(start = as.POSIXct(vector())
                     , stop = as.POSIXct(vector())
                     , metadata = numeric()
                     , stringsAsFactors = FALSE)
        , envir = env)
    }

    # This assumes that the signatures match from the metadata_func
    params = lapply(methods::formalArgs(metadata_func), as.symbol)
    metadata_call = as.call(c(as.name("metadata_func"), params))

    start = function(){
        # The actual function evaluation frame
        frame = parent.frame()
        # Stick this function in so evaluation can find it.
        frame$metadata_func = metadata_func
        md = eval(metadata_call, frame)

        # Record it by appending a new row to the timings
        timings = env[[funcname]]
        id = nrow(timings) + 1L
        # TODO: generalize this beyond a scalar here.
        timings[id, "metadata"] = md

        # Conceptually, starting timer should be last step
        timings[id, "start"] = Sys.time()
        assign(funcname, timings, envir = env)
    }

    stop = function(){
        # Conceptually, stopping timer should be first step
        stoptime = Sys.time()

        timings = env[[funcname]]
        # Writing to the last NA should handle nesting
        last_NA = tail(which(is.na(timings$stop)), 1L)
        timings[last_NA, "stop"] = stoptime
        assign(funcname, timings, envir = env)
    }

    list(start = start, stop = stop)
}



#
#arg_grabber = function()
#{
#    call = match.call(definition = sys.function(sys.parent())
#               , call = sys.call(sys.parent())
#               , expand.dots = TRUE
#               , envir = parent.frame(2L))
#    call
#}


#f = function(a, b = 2, ...) NULL
#
#params = lapply(methods::formalArgs(f), as.symbol)
#
#call_list = c(as.name("f"), params)
#
#call = as.call(call_list)
#
#eval(call)
