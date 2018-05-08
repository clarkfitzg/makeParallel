#!/usr/bin/env Rscript

# {{{gen_time}}}
# Automatically generated from R by autoparallel version {{{version}}}

library(parallel)

N = {{{nworkers}}}
TIMEOUT = {{{timeout}}}

cls = makeCluster(N, "PSOCK")

# Each worker updates this to hold peer to peer socket connections
workers = vector(N, mode = "list")

close.NULL = function(...) NULL


#' Connect workers as peers
connect = function(from, to, port, sleep = 0.1, timeout = TIMEOUT)
{
    if(ID == from){
        con = socketConnection(port = port, server = TRUE
                , blocking = TRUE, open = "w+", timeout = timeout)
        workers[[to]] <<- con
    }
    if(ID == to){
        Sys.sleep(sleep)
        con = socketConnection(port = port, server = FALSE
                , blocking = TRUE, open = "w+", timeout = timeout)
        workers[[from]] <<- con
    }
    NULL
}


clusterExport(cls, c("workers", "connect", "close.NULL"))

# Each worker has an ID
clusterMap(cls, assign, "ID", seq(n)
        , MoreArgs = list(envir = .GlobalEnv))


# Initialize all necessary connections
conns = list({{{}}})

for(x in conns){
    clusterCall(cls, connect, x$from, x$to, x$port)
}

scripts = {{{}}}

# Action!
parLapply(cls, scripts, source)

# Close peer to peer connections
clusterEvalQ(cls, lapply(workers, close))

stopCluster(cls)
