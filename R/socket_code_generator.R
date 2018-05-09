snow_manager_template = readLines(
    system.file("templates/snow_manager.R", package = "autoparallel")
)


snow_worker_template = readLines(
    system.file("templates/snow_worker.R", package = "autoparallel")
)


#' Code for a single row in a schedule
row_schedule_code = function(row, expressions)
{
    if(row$type == "eval"){
        expressions[[row$node]]
    } else {
        varname = as.name(row$varname)
        if(row$type == "send"){
            to = row$to
            substitute(serialize(varname, workers[[to]]))
        } else if(row$type == "receive"){
            from = row$from
            substitute(varname <- unserialize(workers[[from]]))
        }
    }
}


#' Code for a single worker
gen_snow_worker = function(schedule, expressions)
{
    schedule = schedule[order(schedule$start_time), ]
    rows = split(schedule, seq(nrow(schedule)))
    lapply(rows, row_schedule_code, expressions = expressions)
} 


#' Generate Task Parallel Code For SNOW Cluster
#'
#' Produces executable code that relies on a SNOW cluster and sockets.
#' 
#' @param socket_start first network socket to use, can possibly use up to n * (n -
#'  1) / 2 subsequent sockets if every pair of n workers must communicate.
#' @param min_timeout timeout for socket connection will be at least this
#'  many seconds.
#' @return code list of scripts
#' @export
generate_snow_code = function(expressions, schedule, socket_start = 33000L, min_timeout = 600)
{
    gen_time = Sys.time()
    version = sessionInfo()$otherPkgs$autoparallel$Version

    byworker = split(schedule, schedule$processor)
    
    out = lapply(byworker, gen_snow_worker, expressions = expressions)

    socket_map = schedule[schedule$type %in% c("send", "receive"), c("from", "to")]
    socket_map$server = apply(socket_map, 1, min)
    socket_map$client = apply(socket_map, 1, max)
    socket_map = unique(socket_map[, c("server", "client")])
    socket_map$socket = seq(from = socket_start, length.out = nrow(socket_map))

    socket_map_csv = textConnection("socket_map_csv", open = "w")
    write.csv(socket_map, socket_map_csv, row.names = FALSE)

    timeout = max(min_timeout, schedule$end_time)
    nworkers = length(unique(schedule$processor))

    out$manager = whisker::whisker.render(snow_manager_template)

    out
}
