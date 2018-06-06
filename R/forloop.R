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

    changed = c(deps@outputs, deps@updates)

    if(length(changed) > 0){
        forloop_with_updates(forloop, changed)
    } else {
        forloop_no_updates(forloop)
    }
}


# Easy case: loop doesn't change anything
forloop_no_updates = function(forloop)
{
    out = substitute(lapply(iterator, function(ivar) body)
        , as.list(forloop)
        )
    # The names of the function arguments are special.
    names(out[[c(3, 2)]]) = as.character(forloop$ivar)

    out
}


# Harder case: loop does change things
forloop_with_updates = function(forloop, changed)
{
    # TODO: Experiment with 'method' argument here for more or less
    # aggressive global detection schemes.
    globals = globals::globalsOf(forloop, mustExist=FALSE)
    g_assign = intersect(changed, names(globals))

    # The code doesn't update global variables, so it can be parallelized.
    if(length(g_assign) == 0){
        return(forloop_no_updates(forloop))
    }

    # Case of loop such as: 
    # for(i in ...){
    #   x[i] = ...
    #   y[i] = ...
    # We can do some tings with this, but it isn't a priority, so just
    # give up and return the for loop.
    if(length(g_assign) > 1){
        return(forloop)
    }

    # Verify loop has the form:
    # for(i in ...){
    #   ... g(x[i]) # optionally
    #   x[i] = ...
    # }
    # If it does then we turn it into an lapply, otherwise give up.

    ivar = as.character(forloop$ivar)

    if(!check_usage(expr, g_assign, ivar)){
        return(forloop)
    }

    lastline = forloop$body[[length(forloop$body)]]
    if(!check_assign(lastline, g_assign, ivar)){
        return(forloop)
    }

    # All the checks have passed, we can make the change.

}


# Verify that the only usage of avar in expr is of the form
# avar[[ivar]]
# @param avar character assignment variable
# @param ivar character index variable
check_usage = function(expr, avar, ivar, subset_fun = "[[")
{
}


# Verify that expr has the form
# avar[[ivar]] = ...
check_assign = function(expr, avar, ivar
    , assign_funs = c("=", "<-"), subset_fun = "[[")
{
    expr_i = function(i) as.character(expr[[i]])

    # Relying on short circuit behavior to avoid subscript out of bounds
    # errors.
    if( (expr_i(1) %in% assign_funs)
        && (expr_i(c(2, 1)) == subset_fun)
        && (expr_i(c(2, 2)) == avar)
        && (expr_i(c(2, 3)) == ivar)
    ) TRUE else FALSE
}
