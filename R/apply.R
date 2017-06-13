#' Chunk Based On Columns
#'
#' \code{apply(X, 2, FUN)} becomes \code{apply(X[, columns], 2, FUN)}
#'
#' @param code where \code{apply} is \code{code[[1]]}
#' @return outcode for use in chunked columns
apply_column_chunk = function(code)
{
    # The first argument to apply
    Xcode = code[[2]]
    Xstring = deparse(Xcode)

    chunk_name_map = list(
        sub_expr(quote(X[, columns, drop = FALSE]), list(X = Xcode))
    )
    # Not sure if setting name to arbitrary code will always work
    names(chunk_name_map) = Xstring
    sub_expr(code, chunk_name_map)
}


#' Convert \code{apply} To Parallel
#'
#' Transform a single
#' \code{apply()} function call into a parallel version using mclapply
#'
#' @param expression \code{apply()} function call
#' @return modified parallel code
#' @export
apply_parallel = function(code)
{

    if(code[[3]] != 2)
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

    sub_expr(template, list(X = code[[2]]
                            , APPLY_COLUMN_CHUNK = apply_column_chunk(code)
                            , NWORKERS = nworkers()
                            ))
}


#' Find Expressions Using \code{apply}
#'
#' Only looks at the top level expression.
#'
#' @param code expression
#' @return logical locations of apply
#' @export
find_apply = function(code)
{

    toplevel = sapply(code, `[[`, 1)

}
