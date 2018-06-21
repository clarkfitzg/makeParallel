# How to combine multiple use def chains?
library(igraph)


df1 = data.frame(from = c(1, 1)
                 , to = c(2, 3)
                 , edgetype = "use-def"
                 , var = "x"
                 )

g1 = graph_from_data_frame(df1)


df2 = data.frame(from = 2
                 , to = 3
                 , edgetype = "use-def"
                 , var = "y"
                 )

g2 = graph_from_data_frame(df2)


g = union(g1, g2, byname = TRUE)



g1 = make_empty_graph(n = 3)
g1 = add_edges(g1, c(1, 2, 1, 3), type = "use-def", var = "x")

edge_attr(g1)

g2 = make_empty_graph(n = 3)
g2 = add_edges(g2, c(2, 3), type = "use-def", var = "y")

g = union(g1, g2, byname = TRUE)

edge_attr(g)


# Thinking of a more elegant way to make the use-def chain

def = c(1, 10, Inf)
use = c(2, 3, 7, 10, 13)

# Ninja level R programming here.
def[cut(use, breaks = def)]
