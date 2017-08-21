# Compute sample covariance for columns of a matrix


# Split x into chunks of columns. This approach is amenable to automatic
# parallelization because the core of the computation happens within 
# `lapply` calls, ie. computing the covariance blocks, which are relatively
# small objects to return to the manager (assuming n >> p)
#
# However, it explicitly splits the indices to do the chunking aspect.
# This index splitting should really be considered as a parameter to be
# tuned for performance reasons. As a first pass I think it's reasonable to
# attempt to automatically parallelize this.
cov_chunked = function(x, nchunks = 2L)
{

    p = ncol(x)
    indices = parallel::splitIndices(p, nchunks)

    diagonal_blocks = lapply(indices, function(idx) cov(x[, idx, drop = FALSE]))

    upper_right_indices = combn(indices, 2, simplify = FALSE)

    upper_right_blocks = lapply(upper_right_indices, function(index){
            cov(x[, index[[1]]], x[, index[[2]]])
    })

    # All computation is done, just assemble the results in the right way
    output = matrix(numeric(p*p), nrow = p)
    for(i in seq_along(indices)){
        idx = indices[[i]]
        output[idx, idx] = diagonal_blocks[[i]]
    }
    for(i in seq_along(upper_right_indices)){
        index = upper_right_indices[[i]]
        output[index[[1]], index[[2]]] = upper_right_blocks[[i]]
        output[index[[2]], index[[1]]] = t(upper_right_blocks[[i]])
    }
    output
}


split_columns = function(x, nchunks = 2L)
{
    p = ncol(x)
    indices = parallel::splitIndices(p, nchunks)

    chunks = lapply(indices, function(idx) x[, idx, drop = FALSE])

    list(indices = indices, chunks = chunks)
}


# Chunking has already been handled
# I'm hoping that prechunking, and referencing that, will be faster
# indices is redundant here, can be computed from xchunks
cov_prechunked = function(xchunks, indices)
{

    diagonal_blocks = lapply(xchunks, cov)

    # TODO: come back here
    upper_right_indices = combn(length(xchunks), 2, simplify = FALSE)

    upper_right_blocks = lapply(upper_right_indices, function(index){
            cov(x[, index[[1]]], x[, index[[2]]])
    })


    p = max(tail(indices, 1)[[1]])

    # All computation is done, just assemble the results in the right way
    output = matrix(numeric(p*p), nrow = p)
    for(i in seq_along(indices)){
        idx = indices[[i]]
        output[idx, idx] = diagonal_blocks[[i]]
    }
    for(i in seq_along(upper_right_indices)){
        index = upper_right_indices[[i]]
        output[index[[1]], index[[2]]] = upper_right_blocks[[i]]
        output[index[[2]], index[[1]]] = t(upper_right_blocks[[i]])
    }
    output
}


cov_chunked_parallel = cov_chunked
body(cov_chunked_parallel) = sub_expr(body(cov_chunked), list(lapply = quote(parallel::mclapply)))


# matrix based calculation
# Naive because it doesn't use the symmetry of the result
cov_matrix = function(x)
{
    n = nrow(x)
    xc = scale(x, center = TRUE, scale = FALSE)
    (t(xc) %*% xc) / (n - 1)
}


# loop version, uses symmetry
cov_loop = function(x)
{
    p = ncol(x)
    n = nrow(x)

    # Center x:
    for(i in 1:p){
        x[, i] = x[, i] - mean(x[, i])
    }

    output = matrix(numeric(p*p), nrow = p)
    for(i in 1:p){
        for(j in i:p){
            covij = sum(x[, i] * x[, j]) / (n - 1)
            output[i, j] = covij
            output[j, i] = covij
        }
    }
    output
}
