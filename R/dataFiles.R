#' Description of Data Files
#'
#' Contains information necessary to generate a call to read in these data files
#'
#' @export
#' @param dir directory filled exclusively with data files
#' @param files absolute paths to all the files
#' @param format format of the input files
#'      TODO: infer this using the files themselves
#' @param Rclass class of the data object in R, for example, \code{"data.frame"}
#' @param details list of details to help efficiently and correctly read in the data
#' @return \linkS4class{DataFiles}
dataFiles = function(dir, format, Rclass, files = list.files(dir, full.names = TRUE), ...)
{
    DataFiles(files = files
              , format = format
              , Rclass = Rclass
              , details = list(...)
              )
}
