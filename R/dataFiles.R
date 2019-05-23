#' Description of Data Files
#'
#' Contains information necessary to generate a call to read in these data files
#'
#' @export
#' @param dir directory filled exclusively with data files
#' @param files absolute paths to all the files
#' @param format format of the input files
#'      TODO: infer this using the files themselves
#' @param varname expected name of the object in code
#' @param Rclass class of the data object in R, for example, \code{"data.frame"}
#' @param ... further details to help efficiently and correctly read in the data
#' @return \linkS4class{DataFiles}
dataFiles = function(dir, format, varname, Rclass, files = list.files(dir, full.names = TRUE), ...)
{
    if(format == "text" && Rclass == "data.frame"){
        TextTableFiles(files = files, varname = varname, details = list(...))
    } else {
        stop("Not yet implemented.")
    }
}
