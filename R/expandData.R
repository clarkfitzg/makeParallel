# TODO:
# This code doesn't robustly handle reassignments into the same variable.


# TODO:
# - Make user extensible
# - Identify which arguments they are vectorized in
# I'm using this variable as a list of all known vectorized functions.
# It would be better to infer these.
vectorfuncs = c("*", "lapply", "[", "split")


#' Expand Data Description
#'
#' Insert the chunked data loading calls directly into the code, expand vectorized function calls,
#' and collect variables before calling non vectorized function calls.
#'
#' @export
setMethod("expandData", signature(code = "expression", data = "list", platform = "ANY"),
function(code, data, platform, ...)
{
    # This is the method that actually walks the code and expands every statement.
    # Thus this is where the 'partial evaluation' happens.
    # data is a named list. The names are the names of the variables we expect to see in the code.
    # The values either inherit from DataSource or they are known simple values.

    if(length(data) == 0) return(code)

    out = expression()

    for(statement in code){
        newCode = expandData(code, data, platform, ...)
        data = expandVars(statement, data)
        out = c(out, newCode)
    }
    out
})


# TODO: check that this name mangling scheme is not problematic.
# Also, could parameterize these functions.
# @param data DataSource
appendNumber = function(data, basename = data@varname, n = length(data@expr), sep = "_")
{
    paste0(basename, sep, seq(n))
}


# Generate code to do the initial assignment
initialAssignmentCode = function(varname, code)
{
    nm = lapply(varname, as.symbol)
    out = mapply(call, '=', nm, code, USE.NAMES = FALSE)
    as.expression(out)
}


# returns updated versions of vars and expr in a list
# expr is an expression rather than a single call, because this function will turn a single call into many.
expandCollect = function(expr, vars)
{
#    for(v in names(vars$expanded)){
#        found = find_var(expr, v)
#        for(loc in found){
#            usage = expr[[loc[-length(loc)]]]
#            if(is.call(usage) 
#               && as.character(usage[[1]]) %in% vectorfuncs 
#               ){
#                expandVector(expr, v)
#            } else {
#                collectVector(expr, v)
#            }
#        }
#    }
    # Yuck this is a mess.
    # Instead, I can start out just handling statements that look like:
    # y = f(x, z, ...)
    # And preprocess the code to make it look like this.


    vars_in_expr = sapply(names(vars$expanded), function(var){
        finds = find_var(expr, var)
        if(0 < length(finds)) var else NULL
    })
    
    has_vars = 0 < length(vars_in_expr)
    simple_assign = isSimpleAssignCall(expr)

    if(has_vars && simple_assign){
        # Main case of interest when an expression should expanded
        expandVector(expr, vars)
    } else if(!has_vars && simple_assign){
        # Check if it's simple enough to actually evaluate
        tryLimitedEval(expr, vars)
    } else if(has_vars && !simple_assign){
        # Variable appears in the expression, but the expression is not a simple assign,
        # so we treat it as a general function call.
        collectVector(expr, vars)
    } else {
        # Leave it be
        list(vars = vars, expr = expr)
    }
}


tryLimitedEval = function(expr, vars)
{
    # it's a simple assignment of the form v = ...
    rhs = expr[[3L]]
    # Intentionally keeping this limited for the moment, until we get a more coherent way to do this.
    if(c_with_literals(rhs)){
        lhs = expr[[2L]]
        rhs_value = eval(rhs)
        # Use the symbol in lhs as a string. Weird, but seems to work.
        vars[["known"]][[lhs]] = rhs_value
    }
    list(vars = vars, expr = expr)
}


# Take a single vectorized call and expand it into many calls.
expandVector = function(expr, vars)
{
    rhs = expr[[3]]
    function_name = as.character(rhs[[1]])
    if(!function_name %in% vectorfuncs){
        return(collectVector(expr, vars))
    }

    # TODO: Check which arguments it's actually vectorized in.
    function_args = as.character(rhs[-1])
    names_to_expand = intersect(names(vars$expanded), function_args)

    lhs = as.character(expr[[2]])

    # Record the lhs as now being an expanded variable
    # TODO: Check that the variables have the same number of chunks.
    n = length(vars$expanded[[names_to_expand[1]]])
    vars$expanded[[lhs]] = appendNumber(basename = lhs, n = n)

    # Hardcoding `[` as a special case, but it would be better to generalize this as in CodeDepends function handlers.
    col_attr = if(function_name == "["){
        col_arg = rhs[[4L]]
        if(is.character(col_arg)){
            # A single string literal
            col_arg
        } else if(is.symbol(col_arg)){
            # List will return NULL if it isn't here.
            vars$known[[col_arg]]
        }
    }
    # tack this and the split by column on as attributes.
    attr(vars$expanded[[lhs]], "columns") = col_attr

    names_to_expand = c(names_to_expand, lhs)

    newexpr = expandExpr(expr, vars$expanded[names_to_expand])

    list(vars = vars, expr = newexpr)
}


# vars_to_expand is a list like list(a = c("a1", "a2"), b = c("b1", "b2"))
# This function then does the actual expansion.
#
# Before:
# b = f(a)
#
# After:
# b1 = f(a1)    # <-- This is what expand means
# b2 = f(a2)
#
expandExpr = function(expr, vars_to_expand)
{

    iterator = seq_along(vars_to_expand[[1]])

    # Initialize
    newexpr = lapply(iterator, function(...) expr)

    for(i in iterator){
        varname_lookup = lapply(vars_to_expand, function(var) as.symbol(var[i]))
        newexpr[[i]] = substitute_q(expr, varname_lookup)
    }
    as.expression(newexpr)
}


# collect vectorized variables that expr uses and are not already collected.
#
# Before:
# f(x)
#
# After:
# x = c(x1, x2, ..., xk)  # <-- this is what collect means
# f(x)
#
collectVector = function(expr, vars)
{
    vars_used = CodeDepends::getInputs(expr)@inputs
    vars_to_collect = intersect(vars_used, names(vars$expanded))

    # If the variable has already been collected, then we don't need to do it again.
    vars_to_collect = setdiff(vars_to_collect, vars$collected)

    collect_code = Map(collectOneVariable, vars_to_collect, vars$expanded[vars_to_collect])

    collect_code_all_vars = do.call(c, unname(collect_code))

    vars$collected = c(vars$collected, vars_to_collect)

    list(vars = vars, expr = c(collect_code_all_vars, expr))
}


collectOneVariable = function(vname, chunked_varnames)
{
    # Easier to build it from the strings.
    args = paste(chunked_varnames, collapse = ", ")
    expr = paste(vname, "= c(", args, ")")
    parse(text = expr)
}


# Verify that expr has the form
# y = f(x1, x2, ..., xn)
isSimpleAssignCall = function(expr)
{
    result = FALSE
    if(expr[[1]] == "="){
        rhs = expr[[3]]
        if(is.call(rhs) && !any(sapply(rhs, is.call))){
            # rhs is a single, non nested call
            result = TRUE
        }
    }
    result
}


if(FALSE){
    # developing, may move these to tests eventually

    dataLoadExpr = list(x = makeParallel:::ChunkDataSource(expr=parse(text = "1 + 2
              3 + 4")))

    expr = parse(text = "y = x + 2")[[1]]

    find_var = makeParallel:::find_var

    vars = list(a = "alpha", b = "bravo")
    vars = lapply(vars, as.symbol)
    e = quote(a + b)
    substitute_q(e, vars)

vars_to_expand = list(a = c("a1", "a2"), b = c("b1", "b2"))

expandExpr(e, vars_to_expand)

    CodeDepends::getInputs(expr)@inputs

    collectOneVariable("x", c("x_1", "x_2", "x_3"))

}

# https://cran.r-project.org/doc/manuals/r-release/R-lang.html#Substitutions
# http://adv-r.had.co.nz/Computing-on-the-language.html#substitute
substitute_q <- function(x, env) {
      call <- substitute(substitute(y, env), list(y = x))
  eval(call)
}


setMethod("expandData", signature(code = "DependGraph", data = "ANY", platform = "ANY"),
function(code, data, platform, ...)
{
    callGeneric(code@code, data, platform, ...)
})


setMethod("expandData", signature(code = "ANY", data = "NULL", platform = "ANY"),
function(code, data, platform, ...)
{
    # If there's no data description there's nothing to expand
    as(code, "expression")
})


setMethod("expandData", signature(code = "ANY", data = "ExprChunkData", platform = "ANY"),
function(code, data, platform, ...)
{
    callGeneric(as(code, "expression"), list(data), platform, ...)
})


# The interesting case.
setMethod("expandData", signature(code = "expression", data = "TextTableFiles", platform = "UnixPlatform"),
function(code, data, platform, ...)
{
    used = columnsUsed(code, data@varname)
    all_columns = data@details[["colNames"]]
    
    if( !is.null(all_columns) && length(used) < length(all_columns) ){
        return(prepend_data_load(code, data, platform, ...))
    }

    # TODO: Make this more robust by checking that it's not possible for the delimiter to interfere with the behavior of cut.

    message("Generating pipe('cut ...') calls to perform column selection before loading to R.")

    delimiter = data@details[["delimiter"]]
    if(is.null(delimiter)) stop("Specify delimiter in data description details.")


    # TODO: Check if this name mangling scheme is valid.
    #data_names = paste(data@varname, tools::file_path_sans_ext(data@files), sep = "_")

    #read_code = Map(gen_pipe_cut_cmd, data@files, data_names, delimiter = delimiter, used_col = used)

    # When we call expandData with a list, then the names of the list are the variable names, and the values are what to replace them with.
    #data_names = list(data_names)
    #names(data_names) = data@varname


    # Construct the expressions needed to create the objects
    used_indices = which(used %in% all_columns)
    used_col_string = paste(used_indices, collapse = ",")
    cmd = sprintf("cut -d %s -f %s %s", delimiter, used_col_string, data@files)
    ds = dataSource("pipe", cmd, varname = data@varname, splitColumn = data@splitColumn)

    callGeneric(code, ds, platform)
})


#
#
#gen_pipe_cut_cmd = function(fname, varname, delimiter, used_col)
#{
#    used_col_string = paste(used_col, sep = ",")
#    cmd = sprintf("cut -d %s -f %s %s", delimiter, used_col_string, fname)
#    rhs = call("pipe", cmd)
#    #call("=", as.name(varname), rhs)
#}
