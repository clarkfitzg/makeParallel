setAs("DependGraph", "igraph", function(x)
{
    if(require(igraph)){
        graph_from_data_frame(x@graph)
    } else stop("Install igraph to use this conversion.")
})
