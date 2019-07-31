# TODO: Ask Duncan. Is it reasonable to define this conversion in this way?
# The idea is to keep igraph a "soft" dependency

setAs("TaskGraph", "igraph", function(from)
{
    if(requireNamespace("igraph", quietly = TRUE)){
        g = igraph::graph_from_data_frame(from@graph)
        # From https://stackoverflow.com/questions/17433402/r-igraph-rename-vertices
        igraph::V(g)$label = as(from@code, "character")
        g
    } else stop("Install igraph to use this conversion.")
})


# It might make more sense to have a class for a filename
setAs("character", "expression", function(from)
{
    # This means that to do a single string literal we'll need to coerce it to a string literal.
    # For example, as.expression("foo")
    if(length(from) == 1){
        parse(from, keep.source = TRUE)
    } else {
        stop("Expected a single file name.")
    }
})
