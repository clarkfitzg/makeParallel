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
    g = globals::globalsOf(forloop, mustExist = FALSE, method = "liberal")
    g_assign = intersect(changed, names(g))

    # The code doesn't update global variables, so it can be parallelized.
    if(length(g_assign) == 0){
        return(forloop_no_updates(forloop))
    }

    # Case of loop such as: 
    # for(i in ...){
    #   x[i] = ...
    #   y[i] = ...
    # We can potentially work with this, but it isn't a priority, so just
    # give up and return the for loop.

    if(length(g_assign) > 1){
        return(forloop)
    }

    # Verify loop has the form:
    # for(i in ...){
    #   ... g(x[i]) # It's ok if this kind of thing happens
    #   x[i] = ...
    # }

    ivar = as.character(forloop$ivar)
    body = forloop$body

    if(!right_kind_of_usage(body, g_assign, ivar)){
        return(forloop)
    }

    lastline = forloop$body[[length(forloop$body)]]
    if(!right_kind_of_assign(lastline, g_assign, ivar)){
        return(forloop)
    }

    # All the checks have passed, we can make the change.

    # Transform the for loop body into the function body
    ll = length(body)
    rhs_of_lastline = body[[c(ll, 3)]]
    body[[ll]] = rhs_of_lastline

    out = substitute(output[iterator] <- lapply(iterator, function(ivar) body)
        , list(output = as.symbol(g_assign)
               , iterator = forloop$iterator
               , ivar = forloop$ivar
               , body = body
        ))
    # The names of the function arguments are special.
    names(out[[c(3, 2)]]) = as.character(forloop$ivar)

    out
}


# Verify that the only usage of avar in expr is of the form
# avar[[ivar]]
# @param avar character assignment variable
# @param ivar character index variable
right_kind_of_usage = function(expr, avar, ivar)
{
    locs = find_var(expr, avar)

    for(loc in locs){
        lo = loc[-length(loc)]
        if(!is_index(expr[[lo]], avar, ivar)){
            return(FALSE)
        }
    }
    TRUE
}


# Verify that expr has the form
# avar[[ivar]]
is_index = function(expr, avar, ivar, subset_fun = "[[")
{
    if((length(expr) == 3)
        && (expr[[1]] == subset_fun)
        && (expr[[2]] == avar)
        && (expr[[3]] == ivar)
    ) TRUE else FALSE
}


# Verify that expr has the form
# avar[[ivar]] = ...
right_kind_of_assign = function(expr, avar, ivar
    , assign_funs = c("=", "<-"))
{
    f = as.character(expr[[1]])
    if(!(f %in% assign_funs)){
        return(FALSE)
    }

    lhs = expr[[2]]
    is_index(lhs, avar, ivar)
}
