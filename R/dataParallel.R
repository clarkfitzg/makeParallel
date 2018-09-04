#' Estimate Time To Execute Function
#'
#' @param maxWorker integer number of parallel workers to use
#' @param sizeInput numeric size of each input element in bytes
#' @param sizeOutput numeric size of each output element in bytes
#' @return list with the following elements:
#' \describe{
#'   \item{serialTime}{Time in seconds to execute the function in serial}
#'   \item{parallelTime}{Time in seconds to execute the function in
#'      parallel}
#'   \item{elementsParallelFaster}{Number of data elements required for a
#'   parallel version with maxWorker workers to be faster than serial. Can
#'   be Inf if parallel will never be faster than serial.}
#'   \item{}{}
#' }
XXX = function()
{
}


#' Create Functions Estimating Data Run Time
#'
#' @param sizeInput numeric size of each input element in bytes
#' @param sizeOutput numeric size of each output element in bytes
#' @return list with functions for estimating time required for serial and
#'  parallel execution. Serial is a function of $n$
