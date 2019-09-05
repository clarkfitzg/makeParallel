#' Construct ReduceFun Objects
reduceFun = function(original, summaryFun = original, combineFun = "c", queryFun = summaryFun)
{
    ReduceFun(original = original, summaryFun = summaryFun, combineFun = combineFun, queryFun = queryFun)
}
