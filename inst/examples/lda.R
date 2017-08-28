# Linear Discriminant Analysis

library(Matrix)

source("covariance.R")

n = 100
p = 5
X0 = matrix(rnorm(n * p), ncol = p)

groups = rep(1:4, length.out = n)

# Each row contains a group mean
means = by(X0, groups, colMeans)
means = do.call(rbind, means)
means = Matrix(means)

Sigma = cov_Matrix_pkg(X0)

# Cholesky decompositions are cached. Doing it here so it propagates into
# the functions.
chol(Sigma)


# LDA computations

X = Matrix(rnorm(n * p), ncol = p)

# One component in LDA calc
di = function(i, .X = X, .Sigma = Sigma)
{
    xi = .X[1, ]
    a = solve(.Sigma, xi)
    xi %*% a
}

di(1)
