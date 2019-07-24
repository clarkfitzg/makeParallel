#!/usr/bin/env Rscript

# {{{gen_time}}}
# Automatically generated from R by makeParallel version {{{version}}}

library(parallel)

nworkers = {{{nworkers}}}
assignments = {{{assignment_list}}}
file_names = {{{file_names}}}

cls = makeCluster(nworkers)

clusterExport(cls, c("assignments", "file_names"))
parLapply(cls, seq(nworkers), function(i) assign("workerID", i, globalenv()))

clusterEvalQ(cls, {
    file_names = file_names[assignments[[workerID]]]
    chunks = lapply(file_names, {{{read_func}}})
    {{{data_varname}}} = do.call({{{combine_func}}}, chunks)

    {{{vector_body}}}

    # Could parameterize this saving function
    saveRDS({{{save_var}}}, file = paste0("{{{save_var}}}_", workerID, ".rds"))
})

{{{remainder}}}
