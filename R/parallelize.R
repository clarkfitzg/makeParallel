#' Parallelized Data Evaluator
#'
#' Distributes data over a cluster and returns a closure capable of
#' evaluating code in parallel. Designed for interactive use.
#'
#' The resulting object (called the evaluator) checks which variables are used in the code
#' before it evaluates them. It searches for these variables in the global
#' environment and exports all that it finds
#' to the cluster. An exception is the variable that the evaluator was
#' created with; this is assumed to be large, so it will only be exported
#' to the cluster once when the evaluator is created. 
#'
#' @export
#' @param x An object to split and run parallel code on. Typically a large
#' data frame or list. Data frames are split into groups of rows, lists on
#' elements.
#' @param cl SNOW cluster
#' @param spec number of workers, see \code{\link[parallel]{makeCluster}}
#' @param ... additional arguments to \code{\link[parallel]{makeCluster}}
#' @return parallel evaluator resembling \code{\link[base]{eval}}
#' @examples
#' x = list(1:10, 21:30)
#' do = parallelize(x)
#' do(lapply(x, head))
#' y = 20
#' do(x[[1]][1] + y, verbose = TRUE)
#' do(1:3, simplify = rbind)
#' do(1:3, simplify = FALSE)
#' print(do)
#' print.function(do)  # See parameters and attributes
#' parallel::stopCluster(attr(do, "cluster"))
parallelize = function(x = NULL
                       , cl = parallel::makeCluster(spec, ...)
                       , spec = 2L, ...
                       )
{

    varname = deparse(substitute(x))
    splits = assign_workers(cl, x, varname)

    evaluator = function(expr, simplify = c, verbose = FALSE)
    {
        # Recover the expression as an object to manipulate
        code = substitute(expr)
        codeinfo = CodeDepends::getInputs(code, recursive = TRUE)

        # Send variables and functions to the cluster
        used = c(codeinfo@inputs, names(codeinfo@functions))

        # But not varname, which is presumed to be large and used
        # frequently
        used = used[used != varname]
        exports = intersect(ls(globalenv()), used)

        if(verbose){
            message("Sending these variables to the cluster:\n"
                    , paste(exports, collapse = ", "))
        }
        parallel::clusterExport(cl, exports, env = globalenv())

        # TODO: Is there any difference between using .GlobalEnv and
        # globalenv()? Probably should read up on this.
        evaluated = parallel::clusterCall(cl, eval, code, env = globalenv())

        if(is.function(simplify)){
            # Typically expect to flatten a list
            evaluated = do.call(simplify, evaluated)
        }
        evaluated
    }
    attr(evaluator, "cluster") = cl
    attr(evaluator, "splits") = splits
    attr(evaluator, "varname") = varname
    class(evaluator) = c("parallel_evaluator", class(evaluator))
    evaluator
}


#' @export
print.parallel_evaluator = function(x, ...)
{
    cat("parallel evaluator", "\n")
    cat("variable: ", attr(x, "varname"), "\n")
}


#' Assign Variable Subset On Cluster
#'
#' Partition the object into chunks and distribute each chunk to a
#' parallel worker.
#'
#' @param cl SNOW cluster
#' @param x object to partition
#' @param worker_varname string naming variable to be assigned to the
#'      global workspace of the worker node
#' @return indices list of partitioning indices
assign_workers = function(cl, x, worker_varname)
{

    N = if(is.data.frame(x)) nrow(x) else length(x)

    indices = even_split(N, length(cl))

    chunks = split(x, indices)

    # This can be done more efficiently for a fork cluster, but that's a
    # 2nd order consideration.

    parallel::clusterMap(cl, function(x, value){
        assign(x, value, envir = .GlobalEnv)
        NULL
    }, worker_varname, chunks)

    indices
}
