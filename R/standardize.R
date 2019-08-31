#' schedulers expect to see the data in a standard form
#'
#' @export
standardizeData = function(data)
{
    # TODO: Implement more checks and different interfaces here.
    if(!is(data, "DataSource"))
        stop("Expected a DataSource here")
    data
}
