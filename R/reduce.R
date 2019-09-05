#' Construct ReduceFun Objects
#'
#' @export
reduceFun = function(reduceFun, summaryFun = reduceFun, combineFun = "c", queryFun = summaryFun)
{
    if(!is.character(reduceFun))
        stop("Expected the name of a reducible function for reduceFun.")

    funClasses = sapply(list(summaryFun, combineFun, queryFun), class)
    if(all(funClasses == "character")){
        return(SimpleReduceFun(reduceFun = reduceFun, summaryFun = summaryFun
                               , combineFun = combineFun, queryFun = queryFun))
    }

    UserDefinedReduceFun(reduceFun = reduceFun, summaryFun = summaryFun
                               , combineFun = combineFun, queryFun = queryFun)
}
