# I'll generalize this later
nworkers = 2


#' Convert \code{apply} To parallel
#'
#' Transform the top level of a single 
#' \code{apply()} function call into a parallel version
#'
#' @param expression \code{apply()} function call
#' @return modified parallel code
#' @export
apply_parallel = function(incode)
{

    if(incode[[3]] != 2)
       stop("Only considering explicit MARGIN = 2 at the moment")

    # Split initial data
    firstpart = expression(
        n <- ncol(X)
        , idx <- parallel::splitIndices(n, nworkers)
    )



    # Evaluate in parallel

    # Recombine result


}

x = matrix(1:10, ncol = 2)
incode = quote(apply(x, 2, max))

