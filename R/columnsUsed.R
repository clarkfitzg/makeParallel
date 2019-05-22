# TODO: Have CodeAnalysis::readFaster use this code.

# find the names of all columns of the data frame `dfname` that code uses.
# See tests for what it currently does and does not handle
columnsUsed = function(code, dfname)
{

    locations = find_var(code, dfname)
    found = character()
    for(loc in locations){
        r = oneUsage(loc, code, dfname)
        status = r[["status"]]
        if(status == "all_columns")
            return(NULL)
        found = c(found, r[["found"]])
        if(status == "complete")
            return(found)
    }
    found
}


# Return a list with the columns used and a status
oneUsage = function(loc, code, dfname, subset_funcs = c("[", "[["), assign_funcs = c("=", "<-"))
{
    out = list(status = "continue", found = NULL)
    ll = length(loc)

    # Handle all possible cases

    parent = code[[loc[-ll]]]
    parent_func = as.character(parent[[1]])
    if(!(parent_func %in% subset_funcs)){
        # We don't know about this function, so assume the worst, that it uses all columns
        out[["status"]] = "all_columns"
        return(out)
    }

    colindex = switch(parent_func, "[" = 4L, "[[" = 3L)

    colcode = parent[[colindex]]
    if(is.character(colcode) || c_with_literals(colcode)){
        # It's just a character vector, safe to evaluate
        out[["found"]] = eval(colcode)
    } else {
        # It's not a simple character vector, so assume the worst, that it uses all columns
        out[["status"]] = "all_columns"
        return(out)
    }

    grandparent = code[[loc[-c(ll-1, ll)]]]
    grandparent_func = as.character(grandparent[[1]])

    # The special case when we reassign into the same variable
    if(grandparent_func %in% assign_funcs){
        varname = as.character(grandparent[[2L]])
        if(varname == dfname){
            out[["status"]] = "complete"
        }
    }

    out
}


# Check if expr creates a character vector from literals, meaning it looks like c("foo", "bar", ...)
c_with_literals = function(expr)
{
    if(as.character(expr[[1]]) != "c")
        return(FALSE)
    for(i in seq(2, length(expr))){
        if(class(expr[[i]]) != "character")
            return(FALSE)
    }
    TRUE
}



if(FALSE){

    find_var = makeParallel:::find_var
    dfname = "x"
    code = parse(text = "
        foo(y)
        bar(x[, 'col'])
    ")
        
}
