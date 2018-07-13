setAs("DependGraph", "igraph", function(from)
{
    if(requireNamespace("igraph", quietly = TRUE)){
        igraph::graph_from_data_frame(x@graph)
    } else stop("Install igraph to use this conversion.")
})
