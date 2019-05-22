# TODO: Have CodeAnalysis::readFaster use this code.

# find the names of all columns of the data frame `dfname` that code uses.
# See tests for what it currently does and does not handle
columnsUsed = function(code, dfname)
{

    locations = find_var(code, dfname)
    for(loc in locations){
        value = oneUsage(loc, code)
    }

}


oneUsage = function(loc, code, subset_funcs = c("[", "[["), assign_funcs = c("=", "<-"))
{

    ll = length(loc)
    parent = code[[loc[-ll]]]
    grandparent = code[[loc[-c(ll-1, ll)]]]
    parent_func = as.character(parent[[1]])
    grandparent_func = as.character(grandparent[[1]])

}


if(FALSE){

    find_var = makeParallel:::find_var
    dfname = "x"
    code = parse(text = "
        foo(y)
        bar(x[, 'col'])
    ")
        
}
