#' Chunk Based On Columns
#'
#' \code{apply(X, 2, FUN)} becomes \code{apply(X[, columns], 2, FUN)}
#'
#' @param expr where \code{apply} is \code{expr[[1]]}
#' @return outexpr for use in chunked columns
apply_column_chunk = function(expr)
{
    # The first argument to apply
    Xexpr = expr[[2]]
    Xstring = deparse(Xexpr)

    chunk_name_map = list(
        sub_expr(quote(X[, columns, drop = FALSE]), list(X = Xexpr))
    )
    # Not sure if setting name to arbitrary code will always work
    names(chunk_name_map) = Xstring
    sub_expr(expr, chunk_name_map)
}


#' Convert \code{apply} To Parallel
#'
#' Transform a single
#' \code{apply()} function call into a parallel version using mclapply
#'
#' @param statement \code{apply()} function call
#' @return modified parallel code
#' @export
apply_parallel = function(statement)
{

    if(statement[[3]] != 2)
       stop("Only considering explicit MARGIN = 2 at the moment")

    template = parse(text = "
        # TODO: Guarantee we don't overwrite user defined variables

        idx = parallel::splitIndices(ncol(X), NWORKERS)
        parts = parallel::mclapply(idx, function(columns){
            APPLY_COLUMN_CHUNK
        })

        # TODO: handle general case. This assumes a scalar result
        unlist(parts)
    ")

    sub_expr(template, list(X = statement[[2]]
                            , APPLY_COLUMN_CHUNK = apply_column_chunk(statement)
                            , NWORKERS = nworkers()
                            ))
}


#' Run Benchmark To Find Efficient Parallel Code
#'
#' One doesn't know ahead of time if it will be more efficient to run code
#' in serial or in parallel. This function runs the code in both serial and
#' parallel, then returns the faster version based on the median timing.
#'
#' It may be nice to return more, or log the profiling
#'
#' @param statement a single R statment
#' @param times the number of times to run the benchmark
#' @return statement potentially in parallel
#' @export
benchmark_parallel = function(statement, times = 100L)
{

    apply_loc = apply_location(statement)

    # Early exit if unable to find a place to parallelize
    if(apply_loc == 0L)
        return(statement)

    if(apply_loc == 3L)
        serial = statement[[3L]]
    if(apply_loc == 1L)
        serial = statement

    parallel = apply_parallel(serial)

    ser_median = median(microbenchmark(eval(serial), times = times)[, "time"])
    par_median = median(microbenchmark(eval(parallel), times = times)[, "time"])

    if(ser_median < par_median)
        fastest = serial
    else
        fastest = parallel

    if(apply_loc == 3L){
        # Need to put the fast code back into the original code
        tmp = statement
        tmp[[3]] = fastest
        fastest = tmp
    }

    fastest
}



#' Find Location Of Apply In Parse Tree
#'
#' Only looks at the top level expression.
#'
#' @param expr expression
#' @param apply_func vector of apply names
#' @return integer 1 for \code{apply(x, ...}, 3 for \code{y <- apply(x,
#'      ...}, 0 otherwise
apply_location = function(expr, apply_func = "apply")
{
    # A single token on its own line
    if(length(expr) == 1)
        return(0L)

    e1 = deparse(expr[[1]])  

    if(e1 %in% apply_func)
        return(1L)

    assigners = c("<-", "=", "assign")
    if(e1 %in% assigners)
        if(deparse(expr[[3]][[1]]) %in% apply_func)
            return(3L)
    0L
}


#' Find Expressions Using \code{apply}
#'
#' Not sure I need this.
#' Only looks at the top level expression.
#'
#' @param expr expression
#' @return logical locations of apply
#' @export
find_apply = function(expr)
{
    sapply(expr, apply_location)
}


#' Convert A Script To Parallel Through Benchmarking
#'
#' Benchmarking is used to determine if it's worth it go parallel.
#'
#' @param expression serial code
#' @return modified parallel code
#' @export
parallel_empirical = function(expr)
{
    opportunities = sapply(expr, apply_location)
}
