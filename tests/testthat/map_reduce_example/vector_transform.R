# See clarkfitzthesis/tex/vectorize document to see more details for what's going on, what this is working towards.
#
# WHAT IT DOES:
#
# 1. Uses an explicit data description provided by the user, specifically the data size to balance the load across workers.
# 2. Separates code into either vectorized, or not vectorized.
# 3. Finds the single largest block of top level vectorized expressions that it can and fuses it.
#    This is based on the task graph, so they don't have to be ordered in the script.
# 3. Avoids data movement by keeping the data chunked on the workers.
# 4. Returns the minimum set of chunked objects from the workers to the manager.
#
# WHAT IT DOES NOT DO:
# (and estimated effort levels to implement)
#
# 1. Consider the speed of the parallel worker.
#    All we need to do is use the speed to weight the load balancing.
#    EFFORT: EASY
# 1. Consider a hierarchical platform, with data distributed among different workers.
#    EFFORT: DIFFICULT, we'll need a more sophisticated model for load balancing, model network connections, and add to the code generator.
# 1. Find and modify functions that can be implemented as a reduce.
#    Duncan and I have agreed not to go there right at the moment, because apart from trivial functions that are their own reduces, the user needs to provide reduce implementations.
#    So instead we just pull the whole chunked object when it's needed.
#    EFFORT: MEDIUM
# 1. Work on parallel subexpressions.
#    It could, I can think of a couple ways to implement it, but I haven't done it yet because 1) I don't think it adds much conceptually, and 2) I want to handle subexpression parallelism uniformly across schedulers, which will require breaking most of what I already have.
#    EFFORT: DIFFICULT
# 1. Infer the data description from the user code- that's a separate problem that we will address elsewhere.
#    That is, we'll get infer the data description and use it for other schedulers besides this one.
#    EFFORT: MEDIUM



# The code to do the actual transformation
# The user of makeParallel must write something like the following:

library(makeParallel)


files = c("small1.rds", "big.rds", "small2.rds")
# Can surely do this for the user
sizes = file.info(files)[, "size"]

x_desc = ChunkDataFiles(files = files
	, sizes = sizes
	, readFuncName = "readRDS"
    )

outFile = "pmin.R"

out = makeParallel("

    y = sin(x)
    result = min(y)
    saveRDS(result, 'result.rds')
"
, data = list(x = x_desc)
, nWorkers = 2L
, scheduler = scheduleVector
, known_vector_funcs = "sin"
, outFile = outFile
, overWrite = TRUE
)


# Testing
############################################################

# Check that the load balancing happens.
stopifnot(schedule(out)@assignmentIndices == c(1, 2, 1))

if(FALSE){
}
