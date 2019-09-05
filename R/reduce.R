#' Construct ReduceFun Objects
#' @export
simpleReduceFun = function(reduceFun, summaryFun = reduceFun, combineFun = "c", queryFun = summaryFun)
{
    SimpleReduceFun(reduceFun = reduceFun, summaryFun = summaryFun, combineFun = combineFun, queryFun = queryFun)
}
