apply_funcs = data.frame(serial = c("mapply", "lapply", "Map"))
apply_funcs[, "parallel"] = paste0("parallel::", apply_funcs[, "serial"])


#' Convert apply_funcs from serial to parallel version
serial_to_parallel = function(expr, loc){
    # TODO
}


#' Transform Program To Parallel Based On Benchmarks
#' 
#' @param input_file string naming a slow R script
#' @param output_file where to save the parallelized script
#' @return transformed program
#' @export
benchmark_transform = function(input_file, output_file)
{

    program = CodeDepends::readScript(input_file)

    # Probably want to use this later:
    #inputs = CodeDepends::getInputs(program)
    #funcs = lapply(inputs, function(x) names(x@functions))

    apply_locs = sapply(program, apply_location, apply_func = apply_funcs[, "serial"])

    if(sum(apply_locs) == 0){
        message("Did not see top level apply functions")
        return(program)
    }

    newprogram = program

    for(i in seq_along(program)){
        expr = program[[i]]
        apply_loc = apply_locs[i]
        if(apply_loc == 0){
            print(expr)
            # Must evaluate in case subsequent expressions depend on this
            eval(expr, globalenv())
        } else {
            print("Benchmarking:")
            print(expr)
            par_expr = serial_to_parallel(expr, apply_loc)
            # TODO
        }
    }
}


# For developing
input_file = "~/dev/autoparallel/vignettes/simple.R"

#' Find Location Of Functions In Parse Tree
#'
#' Recursively searches the expression to find explicit uses of functions
#'
#' @export
#' @param expr unevaluated R code
#' @param func_names character vector of functions to search for
#' @return TODO: how to represent precise location in parse tree? Need something
#' like a token address. Does this already exist?
findfuncs = function(expr, funcs)
{
   #TODO
}


