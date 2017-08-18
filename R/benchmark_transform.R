apply_funcs = data.frame(serial = c("mapply", "lapply", "Map")
                         , stringsAsFactors = FALSE)
apply_funcs[, "parallel"] = paste0("parallel::mc", apply_funcs[, "serial"])


#' Find and parallelize the first use of an apply function
parallelize_first_apply = function(expr
    , ser_funcs = apply_funcs[, "serial"]
    , par_funcs = apply_funcs[, "parallel"]
){
    finds = sapply(ser_funcs, function(fname){
        find_call(expr, fname)
    })

    # list with 0 or 1 elements
    first = lapply(finds, head, 1)
    first = head(do.call(c, first), 1)

    if(length(first) == 0){
        NULL
    } else {
        index = first[[1]]
        parexpr = expr
        pcode = par_funcs[ser_funcs == names(first)]
        pcode = parse(text = pcode)[[1]]
        parexpr[[index]] = pcode
        parexpr
    }
}


# For developing
input_file = "~/dev/autoparallel/vignettes/simple.R"


#' Transform Program To Parallel Based On Benchmarks
#' 
#' @param input_file string naming a slow R script
#' @param output_file where to save the parallelized script
#' @param nbenchmarks number of benchmarks to run
#' @param threshold_time seconds if code runs under this time then don't
#'      even bother with a comparison to parallel code
#' @return transformed program
#' @export
benchmark_transform = function(input_file, output_file
        , nbenchmarks = 3L, threshold_time = 0.001)
{

    program = CodeDepends::readScript(input_file)

    # Probably want to use this later:
    #inputs = CodeDepends::getInputs(program)
    #funcs = lapply(inputs, function(x) names(x@functions))

    pcode = lapply(program, parallelize_first_apply)

    nonefound = all(sapply(pcode, is.null))

    if(nonefound){
        print("Did not see top level apply functions. Stopping now.\n")
        return(program)
    }

    newprogram = program

    # Convert to nanoseconds for comparison with microbenchmark
    threshold_time = threshold_time / 1e9

    for(i in seq_along(program)){
        expr = program[[i]]
        pexpr = pcode[[i]]
        if(is.null(pexpr)){
            print(expr)
            # Must evaluate in case subsequent expressions depend on this
            eval(expr)
        } else {
            print("Benchmarking:")
            print(expr)
            # TODO consider gc(), global evaluation, writing over args, etc
            ser_time = microbenchmark(list = expr, times = nbenchmarks)[, "time"]
            if(max(ser_time) < threshold_time){
                print("Serial code is faster than threshold.")
                next
            }

            par_time = microbenchmark(list = pexpr, times = nbenchmarks)[, "time"]

            decision = t.test(ser_time, par_time, alternative = "less")

        }
    }
}
