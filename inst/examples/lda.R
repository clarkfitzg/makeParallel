# Linear Discriminant Analysis

library(Matrix)

source("covariance.R")

# LDA computations

# One component in LDA calc
di = function(i, means, Sigma)
{
    xi = means[i, ]
    # This isn't storing the matrix factorization. Maybe solving for a
    # vector doesn't require this?
    a = solve(Sigma, xi)
    as.numeric(xi %*% a)
}


lda2 = function(X0, groups)
{

    # Each row contains a group mean
    means = by(X0, groups, colMeans)
    means = do.call(rbind, means)
    means = Matrix(means)

    Sigma = cov_Matrix_pkg(X0)

    # Cholesky decompositions are cached. Doing it here so it propagates into
    # the functions.
    chol(Sigma)

    d = sapply(1:k, di, means = means, Sigma = Sigma)
    d = d / 2

    out = list(Sigma = Sigma, d = d, means = means)
    class(out) = "lda2"
    out
}



predict.lda2 = function(fit, X)
{
    Sigma = fit$Sigma
    d = fit$d
    means = fit$means

    Sigma_inv_Xt = solve(Sigma, t(X))
    obj = means %*% Sigma_inv_Xt - d
    maxs = apply(obj, 2, which.max)
    maxs
}


# Testing data:
############################################################

library(MASS)

n = 10000
p = 50
k = 4

set.seed(891234)
X0 = matrix(rnorm(n * p), ncol = p)
colnames(X0) = paste0("X", 1:p)

groups = rep(1:k, length.out = n)

X = Matrix(rnorm(10000 * p), ncol = p)

Xd = as.data.frame(as.matrix(X))
colnames(Xd) = colnames(X0)
X0groups = data.frame(X0, groups)


fit = lda(groups ~ ., X0groups)

p0 = as.integer(predict(fit, Xd)$class)

fit2 = lda2(X0, groups)

p1 = predict(fit2, X)


mean(p0 == p1)
# 1 in 10000 is off, but not sure why.
# This is in the docs:
#
#     This version centres the linear discriminants so that the weighted
#     mean (weighted by ‘prior’) of the group centroids is at the
#     origin.
#


# Timings
############################################################

if(FALSE)
{

library(microbenchmark)

microbenchmark(lda(groups ~ ., X0groups), times = 10L)

microbenchmark(lda2(X0, groups), times = 10L)

# So we get a speedup of 2-3 x

# How much time is spent in covariance calc?
# Over 40%
#
# Also 48% in `by`. Which means it's quite inefficient, considering that
# column means can be computed in place with exactly one loop through the
# data. I'll bet data.table is really good at this.
#
# scale() is also a big offender at 19%, half the time of the covariance
# calc. The inefficient part of scale() is in the sweep() function. All we
# really need to do is subtract the column means

Rprof("lda.out")
replicate(100, lda2(X0, groups))
Rprof(NULL)

summaryRprof("lda.out")

}


