# Description of what's happening here is currently in inst/pems/notes.md under heading "implementation"


# I'm using this variable as a list of all known vectorized functions.
# It would be better to infer these.
# TODO:
# - Make user extensible
# - Identify which arguments they are vectorized in
.vectorFuncs = c("*", "lapply", "[", "split")


setMethod("expandData", signature(code = "expression", data = "list", platform = "ANY"),
function(code, data, platform, ...)
{
    globals = data
    # This method actually walks the code and expands every statement.
    # Thus this is where the 'partial evaluation' happens.
    # data is a named list. The names are the names of the variables we expect to see in the code.
    # The values either inherit from DataSource or they are known simple values.

    # There's no external chunked data objects, so nothing to do.
    if(length(globals) == 0) return(code)

    # The initial expressions in the generated code will be the data loading calls.
    # At this point all the data values are TableChunkData objects
    out = lapply(globals, slot, "expr")
    #out = lapply(out, as, "expression")
    out = do.call(c, out)

    # Iterate over the actual data analysis code.
    for(statement in code){

        # Which of the three cases are we in?
        statement = toStatementClass(statement, globals)

        # Dispatch to the appropriate case
        code_with_globals = callGeneric(statement, globals, platform, ...)

        # Record the updates
        globals = code_with_globals[["globals"]]
        new_code = as(code_with_globals[["code"]], "expression")
        out = c(out, new_code)
    }
    out
})


# Convert a statement into a formal class
toStatementClass = function(statement, globals)
{
    # TODO: Expand this to handle more cases.

    # TODO: It would be better to use Nick's tools here.
    class(statement) = "language"

    # Order matters
    if(canConvertAssignmentOneVectorFunction(statement, globals)) {
        AssignmentOneVectorFunction(
            statement = statement
            , lhs = as.character(statement[[2]])
            )
    } else if(canConvertKnownAssignment(statement, globals)) {
        rhs = statement[[3L]]
        KnownAssignment(
            statement = statement
            , lhs = as.character(statement[[2]])
            , value = eval(rhs, envir = globals)
            )
    } else {
        Statement(statement = statement)
    }
}


canConvertKnownAssignment = function(statement, globals) {
    if(!isSimpleAssignCall(statement)) return(FALSE)

    # TODO: Handle symbols that are known values in globals.
    # Intentionally keeping this limited for the moment, until we get a more coherent way to do this.
    rhs = statement[[3L]]
    if(c_with_literals(rhs)) TRUE else FALSE
}


canConvertAssignmentOneVectorFunction = function(statement, globals, vectorFuncs = .vectorFuncs){
    if(!isSimpleAssignCall(statement)) return(FALSE)

    rhs = statement[[3L]]
    fname = as.character(rhs[[1L]])
    if(!(fname %in% vectorFuncs)) return(FALSE)

    args = rhs[-1L]
    symbols = sapply(args, is.symbol)
    symbols = as.character(args[symbols])

    ds = sapply(globals, is, "DataSource")
    ds_names = names(globals[ds])
    if(any(symbols %in% ds_names)) TRUE else FALSE
}


setMethod("expandData", signature(code = "AssignmentOneVectorFunction", data = "list", platform = "ANY"),
function(code, data, platform, ...)
{
    # The expression defines a new chunked data object that we add to the globals.
    expr = as(code, "expression")
    globals = data
    varname = code@lhs

    chunked_objects = data[sapply(data, is, "DataSource")]

    vars_to_expand = lapply(chunked_objects, slot, "mangledNames")
    mangledNames = appendNumber(basename = varname, n = length(vars_to_expand[[1]]))

    # TODO: I don't think this allows for different name mangling schemes in the case of reassignment, x = foo(x)
    vars_to_expand[[varname]] = mangledNames
    expanded = expandExpr(expr, vars_to_expand)

    columns = getColumns(code, globals)
    if(is.null(columns)) columns = character()

    # TODO: Generalize this to handle vectors, not just tables.
    new_obj = TableChunkData(varname = code@lhs
                , expr = expanded
                , columns = columns
            # TODO: This assumes there's only one split possible, and that everything is split on the same column
                , splitColumn = chunked_objects[[1]]@splitColumn
                , mangledNames = mangledNames
                , collector = "rbind"
                , collected = FALSE
                )

    globals[[new_obj@varname]] = new_obj
    list(code = new_obj@expr, globals = globals)
})


setMethod("expandData", signature(code = "KnownAssignment", data = "list", platform = "ANY"),
function(code, data, platform, ...)
{
    # These names clarify what these objects actually are in this method
    globals = data
    known_assign = code

    globals[[known_assign@lhs]] = known_assign
    list(code = as(known_assign, "expression"), globals = globals)
})


setMethod("expandData", signature(code = "Statement", data = "list", platform = "ANY"),
function(code, data, platform, ...)
{
    # Any variables that appear in the code and are chunked data objects should be collected,
    # because this is the general case where we don't know anything about what the code will do with them.
    globals = data

    expr = as(code, "expression")
    vars_used = CodeDepends::getInputs(expr)@inputs

    chunked_objects = data[sapply(data, is, "DataSource")]
    uncollected = chunked_objects[!sapply(chunked_objects, slot, "collected")]

    vars_to_collect = intersect(vars_used, names(uncollected))

    # Collect the variables that are used, and then append the new expression
    collected_code = lapply(uncollected[vars_to_collect], collectCode)
    # unname important to avoid crazy behavior: x = x = ...
    collected_code = do.call(c, unname(collected_code))
    new_code = c(collected_code, expr)

    # record them as collected
    for(v in vars_to_collect){
        globals[[v]]@collected = TRUE
    }

    list(code = new_code, globals = globals)
})


# Generate the code to collect a chunked object
collectCode = function(chunk)
{
    # Easier to build the call from the strings.
    args = paste(chunk@mangledNames, collapse = ", ")
    expr = paste(chunk@varname, " = ", chunk@collector, "(", args, ")")
    parse(text = expr)
}


# Determine which columns are used in expr
# Currently this only handles `[`.
# TODO: It needs to propagate through the columns used, as in arithmetic.
getColumns = function(code, globals)
{
    if(!is(code, "AssignmentOneVectorFunction")) stop("expected an object of class AssignmentOneVectorFunction")
    expr = as(code, "expression")[[1]]
    rhs = expr[[3]]
    functionName = as.character(rhs[[1]])

    # Hardcoding `[` as a special case, but it would be better to generalize this as in CodeDepends function handlers.
    if(functionName == "["){
        col_arg = rhs[[4L]]
        if(is.character(col_arg)){
            # A single string literal
            col_arg
        } else if(is.symbol(col_arg) %% is(globals[[col_arg]], "KnownAssignment")){
            globals[[col_arg]]@value
        }
    }
    # Let the NULL come out of this function if these conditions don't hold.
}



# TODO: check that this name mangling scheme is not problematic.
# Also, could parameterize these functions.
# @param data DataSource
appendNumber = function(data, basename = data@varname, n = length(data@expr), sep = "_")
{
    paste0(basename, sep, seq(n))
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
    as(newexpr, "expression")
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

    callGeneric(code, ds, platform, ...)
})
