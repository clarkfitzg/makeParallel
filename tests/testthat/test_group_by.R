library(makeParallel)

files = list.files("iris_csv", pattern = "*.csv", full.names = TRUE)

# Can surely do this for the user
sizes = file.info(files)[, "size"]

x_desc = ChunkDataFiles(varName = "iris2"
    , files = files
	, sizes = sizes
	, readFuncName = "read.csv"
    #, chunkClass = "data.frame"
    )

outFile = "gen/group_by.R"

out = makeParallel("
species = iris2$Species
iris2split = split(x = iris2, f = species)
med_petal = sapply(iris2split, function(grp) median(grp$Petal.Length))
saveRDS(med_petal, 'gen/med_petal.rds')
"
, data = x_desc
, scheduler = scheduleDataParallel
, platform = parallelLocalCluster()
, chunkableFuncs = "sapply"
, outFile = outFile
, overWrite = TRUE
)


# Test code
############################################################
if(identical(Sys.getenv("TESTTHAT"), "true")){

    rr = 'gen/med_petal.rds'
    unlink(rr)
    source(outFile)

    result = readRDS(rr)
    expected = readRDS("expected/med_petal.rds")
    expect_equal(result, expected)

    s = schedule(out)

    block_class = sapply(s@blocks, class)
    expect_true("SplitBlock" %in% block_class)

}
