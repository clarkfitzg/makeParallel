#' Expand Data Description
#'
#' Insert the chunked data loading calls directly into the code, and expand vectorized function calls.
#'
#' @export
#' @rdname scheduleTaskList
expandData = function(graph, data, .vectorfuncs = vectorfuncs)
{
    if(length(data) == 0) return(graph)

    # The code starts out with assignments.
    newcode = Map(initialAssignmentCode, names(data), data)
}


initialAssignmentCode = function(varname, code)
{
    # TODO: check that this name mangling scheme is not problematic.
    nm = paste0(varname, "_", seq_along(code))
    nm = lapply(nm, as.symbol)
    #code = as.list(code)
    out = Map(call, '=', nm, code)
    as.expression(unname(out))
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
