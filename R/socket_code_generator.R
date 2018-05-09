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
#'
#' It's a little strange to go from parsed expressions back to text. I may
#' rethink this.
gen_snow_worker = function(schedule, expressions)
{
    schedule = schedule[order(schedule$start_time), ]
    rows = split(schedule, seq(nrow(schedule)))
    out = lapply(rows, row_schedule_code, expressions = expressions)

    # Template uses these variables
    processor = schedule[1, "processor"]
    code_body = as.character(as.expression(out))
    code_body = paste(code_body, collapse = "\n")
    out = whisker::whisker.render(snow_worker_template)
    out
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
    
    worker_code = sapply(byworker, gen_snow_worker, expressions = expressions)
    # TODO: string escaping, this assumes only double quotes are used
    worker_code = paste(worker_code, collapse = "', \n\n############################################################\n\n'")
    worker_code = paste0("c('", worker_code, "')")

    socket_map = schedule[schedule$type %in% c("send", "receive"), c("from", "to")]
    socket_map$server = apply(socket_map, 1, min)
    socket_map$client = apply(socket_map, 1, max)
    socket_map = unique(socket_map[, c("server", "client")])
    socket_map$socket = seq(from = socket_start, length.out = nrow(socket_map))

    # Ugly code, but the resulting output isn't too difficult to read
    con = textConnection("socket_map_csv_tmp", open = "w", local = TRUE)
    write.csv(socket_map, con, row.names = FALSE)
    socket_map_csv = paste(socket_map_csv_tmp, collapse = "\n")

    timeout = max(min_timeout, schedule$end_time)
    nworkers = length(unique(schedule$processor))

    whisker::whisker.render(snow_manager_template)
}
