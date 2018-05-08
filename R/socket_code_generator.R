snow_manager_template = readLines(
    system.file("templates/snow_manager.R", package = "autoparallel")
)

snow_worker_template = readLines(
    system.file("templates/snow_worker.R", package = "autoparallel")
)



#' Generate Task Parallel Code For SNOW Cluster
#'
#' Produces executable code that relies on a SNOW cluster and sockets.
#' 
#' @param socket_start first network socket to use, can possibly use up to n * (n -
#'  1) / 2 subsequent sockets if every worker must communicate.
#' @return code list of scripts
#' @export
generate_snow_code = function(expressions, schedule, socket_start = 33000L)
{
}
