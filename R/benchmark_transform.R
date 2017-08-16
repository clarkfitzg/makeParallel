#' Transform Program To Parallel Based On Benchmarks
#' 
#' @param input_file string naming a slow R script
#' @param output_file where to save the parallelized script
#' @return transformed program
#' @export
benchmark_transform = function(input_file, output_file)
{
    program = CodeDepends::readScript(input_file)

    # If we can't find any place to parallelize then take the easy out
    apply_locs = sapply(expr, apply_location, apply_)
}


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


