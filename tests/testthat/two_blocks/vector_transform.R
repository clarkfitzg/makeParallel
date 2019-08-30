# See clarkfitzthesis/tex/vectorize document to see more details for what's going on, what this is working towards.
#


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

outFile = "generated.R"

out = makeParallel("
b = 3                   # general 1
x = log(x0, base = b)   # vector 1
xbar = mean(x)          # reduce 1a
sdx = sd(x)             # reduce 1b
z = (x - xbar) / sdx    # vector 2
"
, data = list(x0 = x_desc)
, nWorkers = 2L
, scheduler = scheduleDataParallel
, chunkableFuncs = c("log", "-", "/")
, outFile = outFile
, overWrite = TRUE
)
