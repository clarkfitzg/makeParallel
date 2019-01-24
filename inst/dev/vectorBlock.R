library(makeParallel)

# This is a list that says which parameters a function is vectorized in.
vecfuncs = list(qnorm = c("p", "mean", "sd")
                , exp = "x"
                )

# This will be easiest if we have the code in a particular form:
# single lines of function calls with only named arguments.
# No nesting.
# This will be an issue with ... args, but we can deal with that later.

code = parse(text = "
x = seq(from = 0, to = 1, length.out = 100)
y = qnorm(p = x)
z = exp(x = y)
result = sum(z)
")

g = inferGraph(code)
e = g@code[[2]]

# We basically want to follow the flow of the large vector x, and any derivative vectors, through the dependency graph.

is_vectorized = function(e, .vecfuncs = vecfuncs)
{
    # Assuming it's the RHS of an expression.
    call = e[[3]]
    if(is.call(call)){
        func_name = as.character(call[[1]])
        func_name %in% names(.vecfuncs)
    }
}

v = which(sapply(g@code, is_vectorized))
gdf = g@graph
vblock_condition = (gdf[, "from"] %in% v) & (gdf[, "to"] %in% v)

vector_block_edges = gdf[vblock_condition, ]

vector_block_edges

# "being a large vector / object" is a property of a variable.
# Edges come from variable usage.
# Nodes are function calls.
# A function call is vectorized in some of its parameters.
# We can consider a node to be a vectorized function call if that function is vectorized in all of the parameters where a large vector is passed.

