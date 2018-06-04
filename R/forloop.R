#' Transfrom For Loop To Lapply
#'
#' Determine if a for loop can be parallelized, and if so transform it into
#' a call to \code{lapply}. This first version will modify loops if and
#' only if the body of the loop does not do any assignments at all.
#' 
#' Recommended use case:
#'
#' The functions in the body of the loop write to different files on each
#' loop iteration.
#' 
#' The generated code WILL FAIL if:
#' 
#' Code in the body of the loop is truly iterative. Functions update global
#' state in any way other than direct assignment.
#' 
#' @param forloop R language object with class \code{for}.
#' @return call R call to \code{parallel::mclapply} if successful,
#'  otherwise the original forloop.
forloop_to_lapply = function(forloop)
{

    names(forloop) = c("for", "ivar", "iterator", "body")

    deps = CodeDepends::getInputs(forloop$body)

    if(length(c(deps@outputs, deps@updates)) > 0){
        return(forloop)
    }

    out = substitute(lapply(iterator, function(ivar) body)
        , as.list(forloop)
        )
    # The names of the function arguments are special.
    names(out[[c(3, 2)]]) = as.character(forloop$ivar)

    out
}
