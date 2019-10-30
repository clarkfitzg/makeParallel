# Defaults

#' @export
#' @rdname schedule
setMethod("schedule", signature(graph = "TaskGraph", data = "ANY", platform = "ANY"), scheduleDataParallel)
