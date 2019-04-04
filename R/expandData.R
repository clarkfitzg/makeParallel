#' Expand Data Description
#'
#' Insert the chunked data loading calls directly into the code, and expand vectorized function calls.
#'
#' @export
#' @rdname scheduleTaskList
expandData = function(graph, data, .vectorfuncs = vectorfuncs)
{
    if(length(data) == 0) return(graph)

    initial_assignments = mapply(initialAssignmentCode, names(data), data, USE.NAMES = FALSE)

    oldcode = graph@code
    newcode = vector(mode = "list", length = length(oldcode))
    big_objects = names(data)
    for(i in seq_along(oldcode)){

        newcode[[i]] = 
    }
    newcode = c(initial_assignments, newcode)
    inferGraph(newcode)
}


initialAssignmentCode = function(varname, code)
{
    # TODO: check that this name mangling scheme is not problematic.
    nm = paste0(varname, "_", seq_along(code))
    nm = lapply(nm, as.symbol)
    #code = as.list(code)
    out = mapply(call, '=', nm, code, USE.NAMES = FALSE)
    as.expression(out)
}


if(FALSE){
    # developing, will move these to tests eventually

    e = parse(text = "1 + 2
              3 + 4")

    initialAssignmentCode("x", e)

}


# TODO:
# - Make user extensible
# - Identify which arguments they are vectorized in
vectorfuncs = c("*")
