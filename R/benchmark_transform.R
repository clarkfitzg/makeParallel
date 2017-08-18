apply_funcs = data.frame(serial = c("mapply", "lapply", "Map")
                         , stringsAsFactors = FALSE)
apply_funcs[, "parallel"] = paste0("parallel::mc", apply_funcs[, "serial"])


#' Find and paralleize the first use of an apply function
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

    if(0 == length(first)){
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
#' @return transformed program
#' @export
benchmark_transform = function(input_file, output_file)
{

    program = CodeDepends::readScript(input_file)

    # Probably want to use this later:
    #inputs = CodeDepends::getInputs(program)
    #funcs = lapply(inputs, function(x) names(x@functions))

    found = lapply(program, first_apply)

    nonefound = all(sapply(found, `[[`, "nonefound"))

    if(nonefound){
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


