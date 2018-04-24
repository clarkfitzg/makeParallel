library(autoparallel)
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

    # This is more awkward than a nested for loop. But I'm doing it so that
    # I can use lapply and make the easier transform. Something more
    # natural might be to write the for loop and transform that into an
    # lapply type call.
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


cov_with_prechunk = function(x, nchunks = 2L)
{
    xsplit = split_columns(x, nchunks)
    cov_prechunked(xsplit$chunks, xsplit$indices)
}


# Assume chunking has already been handled
# This is faster, but it depends on the ratio of how much computation is
# done relative to copying. Ie, it depends on n and p. I would think that
# this should be as efficient as possible relative to builtin cov, then we
# can do it in parallel.
cov_prechunked = function(xchunks, indices)
{

    p = max(tail(indices, 1)[[1]])
    diagonal_blocks = lapply(xchunks, cov)

    # Equivalent to:
    # for i, 1 <= i <= n
    #   for j, i < j <= n
    ij = combn(length(xchunks), 2, simplify = FALSE)
    upper_right_blocks = lapply(ij, function(x){
        i = x[1]
        j = x[2]
        list(idx1 = indices[[i]]
             , idx2 = indices[[j]]
             , cov = cov(xchunks[[i]], xchunks[[j]])
             )
    })

    # All computation is done, just assemble the results in the right way
    output = matrix(numeric(p*p), nrow = p)
    for(i in seq_along(indices)){
        idx = indices[[i]]
        output[idx, idx] = diagonal_blocks[[i]]
    }
    for(x in upper_right_blocks){
        output[x$idx1, x$idx2] = x$cov
        output[x$idx2, x$idx1] = t(x$cov)
    }
    output
}


cov_chunked_parallel = cov_chunked
body(cov_chunked_parallel) = sub_expr(body(cov_chunked), list(lapply = quote(parallel::mclapply)))


cov_prechunked_parallel = cov_prechunked
body(cov_prechunked_parallel) = sub_expr(body(cov_prechunked), list(lapply = quote(parallel::mclapply)))


cov_with_prechunk_parallel = function(x, nchunks = 2L)
{
    xsplit = split_columns(x, nchunks)
    cov_prechunked_parallel(xsplit$chunks, xsplit$indices)
}


# matrix based calculation
# Naive because it doesn't use the symmetry of the result
cov_matrix = function(x)
{
    n = nrow(x)
    xc = scale(x, center = TRUE, scale = FALSE)
    (t(xc) %*% xc) / (n - 1)
}


# Use the Matrix package
cov_Matrix_pkg = function(x)
{
    require(Matrix)
    n = nrow(x)
    xc = scale(x, center = TRUE, scale = FALSE)
    crossprod(Matrix(xc)) / (n - 1)
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


# loop version, uses symmetry and builtin covariance
cov_loop2 = function(x)
{
    p = ncol(x)

    output = matrix(numeric(p*p), nrow = p)
    for(i in 1:p){
        for(j in i:p){
            covij = cov(x[, i], x[, j])
            output[i, j] = covij
            output[j, i] = covij
        }
    }
    output
}
