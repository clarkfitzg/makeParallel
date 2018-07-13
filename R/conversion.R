# TODO: Ask Duncan. Is it reasonable to define this conversion in this way?
# The idea is to keep igraph a "soft" dependency

setAs("DependGraph", "igraph", function(from)
{
    if(requireNamespace("igraph", quietly = TRUE)){
        igraph::graph_from_data_frame(from@graph)
    } else stop("Install igraph to use this conversion.")
})
