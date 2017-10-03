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
#' TODO: How to avoid exporting the whole big object to every worker?
#' It's better to just send the subset that it requires in the end.
#'
#' @export
#' @param x An object one wants to perform parallel analysis on.
#' @param cl SNOW cluster
#' @param spec number of workers, see \code{\link[parallel]{makeCluster}}
#' @param ... additional arguments to \code{\link[parallel]{makeCluster}}
#' @return parallel evaluator resembling \code{\link[base]{eval}}
#' @examples
#' x = list(1:10, 20:30)
#' do = parallelize("x")
#' do(lapply(x, head))
#' y = 20
#' do(x + y)
#' parallel::stopCluster(attr(do, "cluster"))
parallelize = function(x = NULL
                       , cl = parallel::makeCluster(spec, ...)
                       , spec = 2L, ...
                       )
{

    varname = deparse(substitute(x))
    indices = assign_workers(cl, varname)

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
            message("Sending the following variables to the cluster:\n"
                    , exports)
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
    attr(evaluator, "indices") = indices
    attr(evaluator, "varname") = varname
    class(evaluator) = c("parallel_evaluator", class(evaluator))
    evaluator
}


#' @export
print.parallel_evaluator = function(x)
{
    cat("parallel evaluator", "\n")
    cat("variable: ", attr(x, "varname"), "\n")
}


#' Assign Variable Subset On Cluster
#'
#' Partition the variable into chunks and distribute each chunk to a
#' parallel worker.
#'
#' @param cl SNOW cluster
#' @param manager_varname string naming variable to be exported
#' @param worker_varname string naming variable to be assigned to the
#'      global workspace of the worker node
#' @return indices list of partitioning indices
assign_workers = function(cl, manager_varname, worker_varname = manager_varname)
{
    #TODO- Don't need for an initial fork cluster
    #TODO- Only send parts necessary for each worker
    parallel::clusterExport(cl, manager_varname)

    big_object = get(manager_varname)

    indices = parallel::splitIndices(length(big_object), length(cl))

    #TODO: Back here
    clusterMap(cl, function(x, value){
        assign(name, value)
        NULL
    })


    # Each worker only sees their own indices
    parallel::clusterApply(cl, indices, assign_one
                 , manager_varname = manager_varname
                 , worker_varname = worker_varname)

    indices
}


assign_one = function(index, manager_varname, worker_varname)
{
    x = get(manager_varname)
    assign(worker_varname, x[index], envir = .GlobalEnv)
    NULL
}
