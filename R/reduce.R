#' Construct ReduceFun Objects
#'
#' @export
reduceFun = function(reduce, summary = reduce, combine = "c", query = summary)
{
    if(!is.character(reduce))
        stop("Expected the name of a reducible function for reduce argument.")

    funClasses = sapply(list(summary, combine, query), class)
    if(all(funClasses == "character")){
        return(SimpleReduce(reduce = reduce, summary = summary
                               , combine = combine, query = query))
    }

    UserDefinedReduce(reduce = reduce, summary = summary
                               , combine = combine, query = query)
}
