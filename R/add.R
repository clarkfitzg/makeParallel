#' Add together two numbers
#'
#' From the roxygen2 vignette
#'
#' @param x A number
#' @param y A number
#' @return The sum of \code{x} and \code{y}
#' @examples
#' add(1, 1)
#' add(10, 1)
#' @export
add <- function(x, y) {
    # Using a package dependency
    model <- MASS::rlm
    x + y
}
