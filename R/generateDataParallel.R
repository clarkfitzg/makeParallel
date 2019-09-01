#' @export
setMethod("generate", signature(schedule = "DataParallelSchedule", platform = "ParallelLocalCluster", data = "ANY"),
function(schedule, platform, data, ...)
{
# Idea:
# We can generate all the code independently for each block, and then just stick it all together to make the complete program.
# Assuming it's all R code, of course.

    # localInitBlock could be a method, and this would work more generally.
    # Or we could dispatch generate on an InitBlock object, but then we'd have to do some contortions to avoid infinite recursion.
    initBlock = localInitBlock(schedule, platform)
    newcode = lapply(schedule@blocks, generate, platform = platform, data = data, ...)
    newcode = do.call(c, newcode)
    GeneratedCode(schedule = schedule, code = c(initBlock, newcode))
})


# The following methods for the platform = "ParallelLocalCluster" are designed to work together.
# I'm not thinking about name collisions at all right now.

localInitBlock = function(schedule, platform
         , message = sprintf("This code was generated from R by makeParallel version %s at %s", packageVersion("makeParallel"), Sys.time())
         , template = parse(text = '
message(`_MESSAGE`)

library(parallel)

assignments = `_ASSIGNMENT_INDICES`
nWorkers = `_NWORKERS`

`_CLUSTER_NAME` = makeCluster(nWorkers)

# TODO: This is a hack until we have a more robust way to specify and infer combining functions.
c.data.frame = rbind
# It will break code that tries to use the list method for c() on a data.frame

clusterExport(`_CLUSTER_NAME`, c("assignments", "c.data.frame"))
parLapply(cls, seq(nWorkers), function(i) assign("workerID", i, globalenv()))

clusterEvalQ(`_CLUSTER_NAME`, {
    assignments = which(assignments == workerID)
    NULL
})
'), ...){
    substitute_language(template, list(`_MESSAGE` = message
        , `_NWORKERS` = schedule@nWorkers
        , `_ASSIGNMENT_INDICES` = schedule@assignmentIndices
        , `_CLUSTER_NAME` = as.symbol(platform@name)
        ))
}


setMethod("generate", signature(schedule = "DataLoadBlock", platform = "ParallelLocalCluster", data = "ChunkDataFiles"),
function(schedule, platform, data
         , combine_func = as.symbol("c") # TODO: Use rbind if it's a data.frame
         , template = parse(text = '
clusterEvalQ(`_CLUSTER_NAME`, {
    read_args = `_READ_ARGS`
    read_args = read_args[assignments]
    chunks = lapply(read_args, `_READ_FUNC`)
    `_DATA_VARNAME` = do.call(`_COMBINE_FUNC`, chunks)
    NULL
})
'), ...){
    substitute_language(template, list(`_CLUSTER_NAME` = as.symbol(platform@name)
        , `_READ_ARGS` = data@files
        , `_READ_FUNC` = data@readFuncName 
        , `_DATA_VARNAME` = data@varName
        , `_COMBINE_FUNC` = combine_func
        ))
})


setMethod("generate", signature(schedule = "SerialBlock", platform = "ParallelLocalCluster", data = "ANY"),
function(schedule, platform, data
         , combine_func = as.symbol("c") # TODO: Use rbind if it's a data.frame
         , template = parse(text = '
collected = clusterEvalQ(`_CLUSTER_NAME`, {
    `_OBJECTS_RECEIVE_FROM_WORKERS`
})

# Unpack and assemble the objects
vars_to_collect = names(collected[[1]])
for(i in seq_along(vars_to_collect)){
    varname = vars_to_collect[i]
    chunks = lapply(collected, `[[`, i)
    value = do.call(`_COMBINE_FUNC`, chunks)
    assign(varname, value)
}
'), ...){
    if(1 <= length(schedule@collect)){
        first = substitute_language(template, list(`_CLUSTER_NAME` = as.symbol(platform@name)
            , `_OBJECTS_RECEIVE_FROM_WORKERS` = char_to_symbol_list(schedule@collect)
            , `_COMBINE_FUNC` = combine_func
            ))
    } else {
        first = expression()
    }
    c(first, schedule@code)
})


setMethod("generate", signature(schedule = "ParallelBlock", platform = "ParallelLocalCluster", data = "ANY"),
function(schedule, platform
         , export_template = parse(text = '
clusterExport(`_CLUSTER_NAME`, `_EXPORT`)
')
         , run_template = parse(text = '
clusterEvalQ(`_CLUSTER_NAME`, {
    `_BODY`
    NULL
})
'), ...){
    
    part1 = if(0 == length(schedule@export)){
        expression()
    } else {
        substitute_language(export_template, list(
            `_CLUSTER_NAME` = as.symbol(platform@name)
            , `_EXPORT` = schedule@export
            ))
    }

    part2 = substitute_language(run_template, list(`_CLUSTER_NAME` = as.symbol(platform@name)
        , `_BODY` = schedule@code
        ))

    c(part1, part2)
})


setMethod("generate", signature(schedule = "SplitBlock", platform = "ParallelLocalCluster", data = "ANY"),
function(schedule, platform
         , template = parse(text = '
# Copied from ~/projects/clarkfitzthesis/Chap1Examples/range_date_by_station/date_range_par.R
#
# See shuffle section in clarkfitzthesis/scheduleVector for explanation and comparison of different approaches.
# This is the disk based, naive version that writes everything out to disk.

# Reminds me of the SerDe interface in Hive
# https://cwiki.apache.org/confluence/display/Hive/DeveloperGuide#DeveloperGuide-HiveSerDe

group_by_var = `_GROUP_BY_VAR`

write_one = function(grp
        , serializer = saveRDS
        , group_by_var = group_by_var
){
    group_element = grp[1L, group_by_var]
    group_dir = file.path(group_by_var, group_element)
    # Directory creation is a non-op if the directory already exists.
    dir.create(group_dir, recursive = TRUE, showWarnings = FALSE)
    path = file.path(group_dir, workerID)

    serializer(grp, file = path)
}

clusterExport(cls, c("write_one", "group_by_var"))

# Write the groups out to disk and say how large each group is.
group_counts_each_worker = clusterEvalQ(cls, {
    group_col = d[, group_by_var]
    by(d, group_col, write_one)
    table(group_col)
})

# Combine all the tables together.
add_table = function(x, y)
{
    # Assume not all values will appear in each table
    levels = union(names(x), names(y))
    out = rep(0L, length(levels))
    out[levels %in% names(x)] = out[levels %in% names(x)] + x
    out[levels %in% names(y)] = out[levels %in% names(y)] + y
    names(out) = levels
    as.table(out)
}

group_counts = Reduce(add_table, group_counts_each_worker, init = table(logical()))

# Balance the load based on how large each group is.
assignments = makeParallel:::greedy_assign(group_counts, nworkers)

read_args = names(group_counts)

COMBINER = rbind

read_one_group = function(group_name, group_dir = file.path(group_by_var, group_name)
                    , deserializer = readRDS, combiner = COMBINER)
{
    files = list.files(group_dir, full.names = TRUE)
    group_chunks = lapply(files, deserializer)
    group = do.call(combiner, group_chunks)
}


# We are re reusing these variable names, but that should be OK.
clusterExport(cls, c("assignments", "read_args", "read_one_group", "COMBINER"))

clusterEvalQ(cls, {

    assignments = which(assignments == workerID)
    read_args = read_args[assignments]

    chunks = lapply(read_args, read_one_group)
    d = do.call(COMBINER, chunks)
})
'), ...){

    # Assumes there are not multiple variables to split by.
    # Not sure what will happen if this is a list.
    group_by_var
    
    substitute_language(template, list(`_CLUSTER_NAME` = as.symbol(platform@name)
        , `_GROUP_BY_VAR` = as.symbol(group_by_var)
        ))
})
