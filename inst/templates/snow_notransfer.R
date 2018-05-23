#!/usr/bin/env Rscript

# {{{gen_time}}}
# Automatically generated from R by autoparallel version {{{version}}}

library(parallel)

nworkers = {{{nworkers}}}

cls = makeCluster(nworkers, "PSOCK")

# Each worker has an ID
clusterMap(cls, assign, "ID", seq(nworkers)
        , MoreArgs = list(envir = .GlobalEnv))

worker_code = {{{worker_code}}}

evalg = function(codestring)
{
    code = parse(text = codestring)
    eval(code, .GlobalEnv)
    NULL
}

# Action!
parLapply(cls, worker_code, evalg)

stopCluster(cls)
