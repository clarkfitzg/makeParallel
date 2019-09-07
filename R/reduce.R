#' Construct ReduceFun Objects
#'
#' @export
reduceFun = function(reduce, summary = reduce, combine = "c", query = summary, predicate = function(...) TRUE)
{
    if(!is.character(reduce))
        stop("Expected the name of a reducible function for reduce argument.")

    funClasses = sapply(list(summary, combine, query), class)
    if(all(funClasses == "character")){
        return(SimpleReduce(reduce = reduce, summary = summary
                               , combine = combine, query = query
                               , predicate = predicate))
    }

    UserDefinedReduce(reduce = reduce, summary = summary
                               , combine = combine, query = query
                               , predicate = predicate)
}


combine_two_tables = function(x, y)
{
    # Assume not all values will appear in each table
    levels = union(names(x), names(y))
    out = rep(0L, length(levels))
    out[levels %in% names(x)] = out[levels %in% names(x)] + x
    out[levels %in% names(y)] = out[levels %in% names(y)] + y
    names(out) = levels
    as.table(out)
}


#' @export
combine_tables = function(...){
    dots = list(...)
    Reduce(combine_two_tables, dots, init = table(logical()))
}
