f <- function(x) g(x)
g <- function(x) {
    h(x)
}
h <- function(x) {
      k1(x) + k2(x) + my_var
}
my_var <- 1
