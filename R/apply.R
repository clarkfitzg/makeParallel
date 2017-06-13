# I'll generalize this later
nworkers = 2


# From Hadley Wickham's pryr / Advanced R
sub_expr <- function(expr, env) {
    stopifnot(is.language(expr))
    call <- substitute(substitute(expr, env), list(expr = expr))
    eval(call)
}


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
        idx = parallel::splitIndices(n, nworkers)
        parts = parallel::mclapply(idx, function(columns){
            APPLY_X_CHUNK
        })

        # TODO: handle general case. This assumes a scalar result
        unlist(parts)
    ")

    # The first argument to apply
    Xcode = incode[[2]]
    Xstring = deparse(Xcode)

    # Transform incode to a form chunked on columns
    # Essentially X becomes X[, columns]
    chunk_name_map = list(
        sub_expr(quote(X[, columns]), list(X = Xcode))
    )
    # Not sure if setting name to arbitrary code will always work
    names(chunk_name_map) = Xstring
    APPLY_X_CHUNK = sub_expr(incode, chunk_name_map)


    sub_expr(template, list(X = Xcode
                            , APPLY_X_CHUNK = APPLY_X_CHUNK
                            ))

}

x = matrix(1:10, ncol = 2)
incode = quote(apply(x, 2, max))

