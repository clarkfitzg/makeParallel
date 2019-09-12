library(makeParallel)

# Implementation note- regarding the functions in strings, the code generator can check for :: in the string and generate a call to `::` instead of a symbol.
# We don't want to inline package functions in generated code because they may use package internal objects, as in this case.
# It's also messy.


# Compute the median given a table where the names are the values
tableMedian = function(tbl){

    tbl = tbl[order(as.numeric(names(tbl)))]
    totals = cumsum(tbl)

    n = totals[length(totals)]
    med_count = n / 2

    med = names(tbl)[med_count <= totals][1L]
    as.numeric(med)
}


# For someone to write a predicate function they need to know about how we've implemented resources and propagation.
# This is bad for extensibility.

medianReduce = reduceFun("median"
    , summary = "table"
    , combine = "makeParallel::combine_tables"
    , query = tableMedian
    , predicate = function(r) !is.null(r[["uniqueValueBound"]]) && r[["uniqueValueBound"]] < 1000
    )

files = list.files("single_numeric_few_distinct", pattern = "*.rds", full.names = TRUE)

# Can surely do this for the user
sizes = file.info(files)[, "size"]

x_desc = ChunkDataFiles(varName = "x0"
    , files = files
	, sizes = sizes
	, readFuncName = "readRDS"
    , uniqueValueBound = 500
    )

outFile = "gen/median_reduce.R"

out = makeParallel("
x = sin(x0)
result = median(x)
saveRDS(result, 'gen/result_median_reduce.rds')
"
, data = x_desc
, scheduler = scheduleDataParallel
, platform = parallelLocalCluster()
, chunkFuncs = c("sin")
, reduceFuncs = list(medianReduce)
, outFile = outFile
, overWrite = TRUE
)


# Test code
############################################################
if(identical(Sys.getenv("TESTTHAT"), "true")){

    rr = 'gen/result_median_reduce.rds'
    unlink(rr)
    source(outFile)

    result = readRDS(rr)
    # A cleaner way to test this would be to test that both the serial schedules and the parallel ones get the same result.
    expected = readRDS("expected/result_median_reduce.rds")

    expect_equal(result, expected)

    s = schedule(out)
    block_class = sapply(s@blocks, class)

    expect_true("ReduceBlock" %in% block_class)

}
