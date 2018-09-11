#setMethod(sort, "DependGraph", sortBottomLevel)


#' Order Nodes By Bottom Level Order
#'
#' Permute the nodes of the graph so that they are ordered in decreasing
#' bottom level precedence order. The bottom level of a node is the length
#' of the longest path starting at that node and going to the end of the
#' program.
#'
#' This permutation respects the partial order of the graph, so
#' executing the permuted code will produce the same result as the original
#' code.
#'
#' There are many possible node precedence orders. Bottom level
#' order provides good average performance. 
#'
#' @references \emph{Task Scheduling for Parallel Systems}, Sinnen, O.
#'
#' @export
#' @param graph object of class \linkS4class{TimedDependGraph}
#' @return integer vector to permute the expressions in \code{x@code}
#' @examples
#' graph <- inferGraph(code = parse(text = "x <- 1:100
#' y <- rep(1, 100)
#' z <- x + y"), time = c(1, 2, 1))
#' bl <- orderBottomLevel(graph)
orderBottomLevel = function(graph)
{
}
