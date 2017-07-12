# Tue Jul 11 16:45:01 PDT 2017
# In my summer proposal I mentioned doing this covariance calculation in
# parallel.


# Compute covariance for columns of a matrix
cov_outer = function(x)
{
    sumsquares = apply(x*x, 2, sum)
}


n = 10
x = matrix(rnorm(n * n), nrow = n)


