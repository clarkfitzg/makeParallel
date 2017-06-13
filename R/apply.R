
#' Adapted from Hadley Wickham's pryr / Advanced R
sub_one = function(expr, env)
{
    stopifnot(is.language(expr))
    call <- substitute(substitute(expr, env), list(expr = expr))
    eval(call)
}


#' Handles expression objects as well as single objects
sub_expr = function(expr, env) {
    if(is.expression(expr)){
        as.expression(lapply(expr, sub_one, env))
    } else {
        sub_one(expr, env)
    }
}


#' Chunk Based On Columns
#'
#' \code{apply(X, 2, FUN)} becomes \code{apply(X[, columns], 2, FUN)}
#'
#' @param incode
#' @return outcode
apply_column_chunk = function(incode)
{
    # The first argument to apply
    Xcode = incode[[2]]
    Xstring = deparse(Xcode)

    chunk_name_map = list(
        sub_expr(quote(X[, columns, drop = FALSE]), list(X = Xcode))
    )
    # Not sure if setting name to arbitrary code will always work
    names(chunk_name_map) = Xstring
    sub_expr(incode, chunk_name_map)
}


# Not necessary yet
##' Return code to detect the number of parallel workers
#nworkers = function()
#{
#    quote(floor(parallel::detectCores() / 2))
#}


#' Convert \code{apply} To Parallel
#'
#' Transform a single
#' \code{apply()} function call into a parallel version
#'
#' @param expression \code{apply()} function call
#' @return modified parallel code
#' @export
apply_parallel = function(incode)
{

    if(incode[[3]] != 2)
       stop("Only considering explicit MARGIN = 2 at the moment")

    template = parse(text = "
        n = ncol(X)
        idx = parallel::splitIndices(n, NWORKERS)
        parts = parallel::mclapply(idx, function(columns){
            APPLY_COLUMN_CHUNK
        })

        # TODO: handle general case. This assumes a scalar result
        unlist(parts)
    ")

    sub_expr(template, list(X = incode[[2]]
                            , APPLY_COLUMN_CHUNK = apply_column_chunk(incode)
                            , NWORKERS = quote(floor(parallel::detectCores() / 2))
                            ))
}



