#!/usr/bin/env Rscript

# 2018-05-21 13:15:48
# Automatically generated from R by autoparallel version 0.0.1

library(parallel)

nworkers = 2
timeout = 600

cls = makeCluster(nworkers, "PSOCK")

# Each worker updates a copy of this object. On worker j workers[[i]] will
# contain an open socket connection between workers j and i.
workers = vector(nworkers, mode = "list")

close.NULL = function(...) NULL


#' Connect workers as peers
connect = function(server, client, port, sleep = 0.1, ...)
{
    if(ID == server){
        con = socketConnection(port = port, server = TRUE
                , blocking = TRUE, open = "a+b", ...)
        workers[[client]] <<- con
    }
    if(ID == client){
        Sys.sleep(sleep)
        con = socketConnection(port = port, server = FALSE
                , blocking = TRUE, open = "a+b", ...)
        workers[[server]] <<- con
    }
    NULL
}


clusterExport(cls, c("workers", "connect", "close.NULL"))

# Each worker has an ID
clusterMap(cls, assign, "ID", seq(nworkers)
        , MoreArgs = list(envir = .GlobalEnv))

# Define the peer to peer connections
socket_map = read.csv(text = '
"server","client","port"
1,2,33000
')

# Open the connections
by(socket_map, seq(nrow(socket_map)), function(x){
    clusterCall(cls, connect, x$server, x$client, x$port, timeout = timeout)
})

worker_code = c(
'if(ID != 1)
    stop(sprintf("Worker is attempting to execute wrong code.
This code is for 1, but manager assigned ID %s", ID))

v1 = "foo1"
x <- paste0(v1, v1)
y <- unserialize(workers[[2]])
xy <- paste0(x, y)
writeLines(xy, "script1.R.log")', 

############################################################

'if(ID != 2)
    stop(sprintf("Worker is attempting to execute wrong code.
This code is for 2, but manager assigned ID %s", ID))

v2 = "foo2"
y <- paste0(v2, v2)
serialize(y, workers[[1]], xdr = FALSE)'
)

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
