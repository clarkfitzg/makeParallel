#' Determine if a for loop can be parallelized, and if so transform it into
#' a call to mclapply. This first version will parallelize loops if and
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
#' @export
forloop_to_mclapply = function(forloop)
{

    names(forloop) = c("for", "ivar", "iterator", "body")

    deps = CodeDepends::getInputs(forloop$body)

    if(c(deps@outputs, deps@updates) > 0){
        return(forloop)
    }

    # Build the function
    f = function(ivar) NULL
    args = list(NULL)
    names(args) = as.character(forloop$ivar)

    formals(f) = args
    body(f) = forloop$body

    out = substitute(parallel::mclapply(iterator, f)
        , list(iterator = forloop$iterator, f = get("f"))
        )

}
