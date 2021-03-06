#!/usr/bin/env Rscript

# {{{gen_time}}}
# Automatically generated from R by autoparallel version {{{version}}}

library(parallel)

nworkers = {{{nworkers}}}
timeout = {{{timeout}}}

cls = makeCluster(nworkers, "PSOCK")

# Each worker updates a copy of this object. On worker j workers[[i]] will
# contain an open socket connection between workers j and i.
workers = vector(nworkers, mode = "list")

close.NULL = function(...) NULL


#' Connect workers as peers
connect = function(server, client, port, timeout, sleep = 0.1, ...)
{
    if(ID == server){
        con = socketConnection(port = port, server = TRUE
                , blocking = TRUE, open = "a+b", timeout = timeout, ...)
        workers[[client]] <<- con
    }
    if(ID == client){
        Sys.sleep(sleep)
        con = socketConnection(port = port, server = FALSE
                , blocking = TRUE, open = "a+b", timeout = timeout, ...)
        workers[[server]] <<- con
    }
    NULL
}

# Setting environment so that <<- in `connect` works correctly and to avoid
# transferring potentially large amounts of data in case the user evaluates
# this code from within an environment, ie. a function.
environment(connect) = environment(close.NULL) = .GlobalEnv

clusterExport(cls, c("workers", "connect", "close.NULL"), envir = environment())

# Each worker has an ID
clusterMap(cls, assign, "ID", seq(nworkers)
        , MoreArgs = list(envir = .GlobalEnv))

# Define the peer to peer connections
socket_map = read.csv(text = '
{{{socket_map_csv}}}
')

# Open the connections
by(socket_map, seq(nrow(socket_map)), function(x){
    clusterCall(cls, connect, x$server, x$client, x$port, timeout = timeout)
})

worker_code = {{{worker_code}}}

evalg = function(codestring)
{
    code = parse(text = codestring)
    eval(code, .GlobalEnv)
    NULL
}

# Action!
parLapply(cls, worker_code, evalg)

# Close peer to peer connections
clusterEvalQ(cls, lapply(workers, close))

stopCluster(cls)
