#' Construct ReduceFun Objects
simpleReduceFun = function(reducibleFunName, summaryFun = reducibleFunName, combineFun = "c", queryFun = summaryFun)
{
    SimpleReduceFun(reducibleFunName = reducibleFunName, summaryFun = summaryFun, combineFun = combineFun, queryFun = queryFun)
}
