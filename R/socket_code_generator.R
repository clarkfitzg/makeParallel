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
    lapply(rows, row_schedule_code)
} 


#' Generate Task Parallel Code For SNOW Cluster
#'
#' Produces executable code that relies on a SNOW cluster and sockets.
#' 
#' @param socket_start first network socket to use, can possibly use up to n * (n -
#'  1) / 2 subsequent sockets if every pair of n workers must communicate.
#' @return code list of scripts
#' @export
generate_snow_code = function(expressions, schedule, socket_start = 33000L)
{
    gen_time = Sys.time()
    version = sessionInfo()$otherPkgs$autoparallel$Version

    byworker = split(schedule, schedule$processor)
    
    out = lapply(byworker, gen_snow_worker)

    # TODO: Come back here, not working yet
    comms = schedule[schedule$type %in% c("send", "receive"), c("from", "to")]
    comms = split(comms, seq(nrow(comms)))
    comms = lapply(comms, sort)
    comms = unique(comms)
    comms = Map(c, comms, seq(from = socket_start, length.out = length(comms)))
    comms = lapply(comms, setNames, nm = c("from", "to", "socket"))


    manager = whisker::whisker.render(snow_manager_template, data = list(
        version = version
        , 
    ))


    udaf_dot_R = paste0(base_name, ".R")
    # Pulls variables from parent environment
    sqlcode = whisker::whisker.render(sql_template)

    if(!is.null(include_script)){
        include_script = paste0(readLines(include_script), collapse = "\n")
    }

    # This just drops R code into an R script using mustache templating. An
    # alternative way is to save all these objects into a binary file and
    # send that file to the workers.
    Rcode = whisker::whisker.render(R_template, data = list(include_script = include_script
        , verbose = verbose
        , rows_per_chunk = rows_per_chunk
        , cluster_by = deparse(cluster_by)
        , sep = sep
        , input_cols = deparse(input_cols)
        , input_classes = deparse(input_classes)
        , try = try
        , f = paste0(capture.output(print.function(f)), collapse = "\n")
        , gen_time = gen_time
        , version = version
    ))

    writeLines(sqlcode, udaf_dot_sql)
    writeLines(Rcode, udaf_dot_R)


}
