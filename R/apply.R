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
#' @param expression \code{apply()} function call
#' @return modified parallel code
#' @export
apply_parallel = function(expr)
{

    if(expr[[3]] != 2)
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

    sub_expr(template, list(X = expr[[2]]
                            , APPLY_COLUMN_CHUNK = apply_column_chunk(expr)
                            , NWORKERS = nworkers()
                            ))
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
#' Only looks at the top level expression.
#'
#' @param expr expression
#' @return logical locations of apply
#' @export
find_apply = function(expr)
{
    sapply(expr, apply_location) != 0L
}
