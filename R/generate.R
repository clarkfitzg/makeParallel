# Code for a single row in a schedule
row_schedule_code = function(row, expressions)
{
    if(row$type == "eval"){
        expressions[[row$node]]
    } else {
        varname = as.name(row$varname)
        if(row$type == "send"){
            to = row$to
            substitute(serialize(varname, workers[[to]], xdr = FALSE))
        } else if(row$type == "receive"){
            from = row$from
            substitute(varname <- unserialize(workers[[from]]))
        }
    }
}


# Generate a single expression to transfer a variable
gen_send_code = function(row)
{
    varname = as.name(row$varname)
    proc_receive = row$proc_receive
    substitute(serialize(varname, workers[[proc_receive]], xdr = FALSE))
}


# Generate a single expression to transfer a variable
gen_receive_code = function(row)
{
    varname = as.name(row$varname)
    proc_send = row$proc_send
    substitute(varname <- unserialize(workers[[proc_send]]))
}



# Code for a single worker
gen_snow_worker = function(processor, schedule)
{
    work = schedule@evaluation
    work = work[work$processor == processor, ]
    # The original code
    work$code = as.character(schedule@graph@code[work$node])

    trans = schedule@transfer

    send = trans[trans$proc_send == processor, ]
    send$code = as.character(by0(send, seq(nrow(send)), gen_send_code))
    send$start_time = send$start_time_send

    receive = trans[trans$proc_receive == processor, ]
    receive$code = as.character(by0(receive, seq(nrow(receive)), gen_receive_code))
    receive$start_time = receive$start_time_receive

    cols = c("start_time", "code")
    allcode = rbind(work[, cols], send[, cols], receive[, cols])

    # We could do a sanity check here that the operations don't overlap. But
    # if they do that's the fault of the scheduler. If it becomes an
    # issue a better idea is probably to have a `verify_schedule()`
    # function, then we can also check that it respects the task graph.
    allcode = allcode[order(allcode$start_time), ]

    template = readLines(
        system.file("templates/snow_worker.R", package = "makeParallel"))

    whisker::whisker.render(template,
        list(processor = processor
            , code_body = paste(allcode$code, collapse = "\n")
    ))
} 

# TODO:* Collect the names of all the formals for every publicly exported
# function and check them for uniformity.

#' Generate Task Parallel Code For SNOW Cluster
#'
#' Produces executable code that relies on a SNOW cluster on a single
#' machine and sockets.
#' 
#' @export
#' @rdname generate
#' @param portStart first local port to use, can possibly use up to n * (n -
#'  1) / 2 subsequent ports if every pair of n workers must communicate.
#' @param minTimeout timeout for socket connection will be at least this
#'  many seconds.
setMethod("generate", "TaskSchedule", function(schedule, portStart = 33000L, minTimeout = 600)
{
    if(nrow(schedule@transfer) == 0){
        gen_socket_code_no_comm(schedule)
    } else {
        gen_socket_code_comm(schedule, portStart, minTimeout)
    }
})


gen_socket_code_no_comm = function(schedule)
{
    workers = unique(schedule@evaluation$processor)
    
    worker_code = sapply(workers, gen_snow_worker, schedule = schedule)

    # TODO: string escaping, this assumes only double quotes are used
    worker_code = paste(worker_code, collapse = "', \n\n############################################################\n\n'")

    template = readLines(
        system.file("templates/snow_notransfer.R", package = "makeParallel"))

    output_code = whisker::whisker.render(template, list(
        gen_time = Sys.time()
        , version = utils::sessionInfo()$otherPkgs$makeParallel$Version
        , nworkers = length(unique(schedule@evaluation$processor))
        , worker_code = paste0("c(\n'", worker_code, "'\n)")
    ))

    GeneratedCode(schedule = schedule, code = parse(text = output_code))
}


gen_socket_code_comm = function(schedule, portStart, minTimeout)
{
    workers = unique(schedule@evaluation$processor)
    
    worker_code = sapply(workers, gen_snow_worker, schedule = schedule)

    # TODO: string escaping, this assumes only double quotes are used
    worker_code = paste(worker_code, collapse = "', \n\n############################################################\n\n'")

    socket_map = schedule@transfer[, c("proc_send", "proc_receive")]
    socket_map$server = apply(socket_map, 1, min)
    socket_map$client = apply(socket_map, 1, max)
    socket_map = unique(socket_map[, c("server", "client")])
    socket_map$port = seq(from = portStart, length.out = nrow(socket_map))

    # Ugly code, but the generated output is easy to read
    socket_map_csv_tmp = ""
    con = textConnection("socket_map_csv_tmp", open = "w", local = TRUE)
    utils::write.csv(socket_map, con, row.names = FALSE)

    template = readLines(
        system.file("templates/snow_manager.R", package = "makeParallel"))

    output_code = whisker::whisker.render(template, list(
        gen_time = Sys.time()
        , version = utils::sessionInfo()$otherPkgs$makeParallel$Version
        , nworkers = length(unique(schedule@evaluation$processor))
        , timeout = max(minTimeout, timeFinish(schedule))
        , socket_map_csv = paste(socket_map_csv_tmp, collapse = "\n")
        , worker_code = paste0("c(\n'", worker_code, "'\n)")
    ))

    GeneratedCode(schedule = schedule, code = parse(text = output_code))
}
