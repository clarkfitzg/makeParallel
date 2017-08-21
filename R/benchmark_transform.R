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


#' Transform Program To Parallel Based On Benchmarks
#' 
#' @param input_file string naming a slow R script
#' @param output_file where to save the parallelized script
#' @param nbenchmarks number of benchmarks to run
#' @param threshold_time seconds if serial version runs under this time then don't
#'      even bother with a comparison to parallel
#' @param threshold_pvalue used for t test decision to choose parallel
#'      over serial.
#' @return transformed program
#' @export
benchmark_transform = function(input_file, output_file = NULL
        , nbenchmarks = 5L, threshold_time = 0.001
        , threshold_pvalue = 0.01)
{

    program = CodeDepends::readScript(input_file)

    # Probably want to use this later:
    #inputs = CodeDepends::getInputs(program)
    #funcs = lapply(inputs, function(x) names(x@functions))

    pcode = lapply(program, parallelize_first_apply)

    nonefound = all(sapply(pcode, is.null))

    if(nonefound){
        cat("Did not see top level apply functions. Stopping now.\n")
        return(program)
    }

    newprogram = program

    # Convert to nanoseconds for comparison with microbenchmark
    threshold_time = threshold_time / 1e9

    for(i in seq_along(program)){
        expr = program[[i]]
        pexpr = pcode[[i]]
        cat("\n\n\n\n")
        print(expr)
        if(is.null(pexpr)){
            # Must evaluate in case subsequent expressions depend on this
            eval(expr)
        } else {
            cat("\nBenchmarking serial...\n")
            # TODO consider gc(), global evaluation, writing over args, etc
            ser_time = microbenchmark(list = list(expr), times = nbenchmarks)[, "time"]
            if(max(ser_time) < threshold_time){
                cat("Using serial version since it is faster than threshold.\n")
                next
            }

            cat("Benchmarking parallel...\n")

            par_time = microbenchmark(list = list(pexpr), times = nbenchmarks)[, "time"]

            decision = t.test(ser_time, par_time, alternative = "greater")
            print(decision)

            if(decision$p.value < threshold_pvalue) {
                cat("Using parallel version.\n")
                newprogram[[i]] = pexpr
            } else {
                cat("Using serial version.\n")
            }
        }
    }
 
    if(!is.null(output_file)){
        sink(output_file)
        for(expr in newprogram){
            print(expr)
        }
        sink()
    }

    newprogram
}
