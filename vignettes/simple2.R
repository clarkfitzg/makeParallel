ffast = function(x) rnorm(1)
fslow = function(x) {
    Sys.sleep(0.1)
    rnorm(1)
}
z = 1:10
r1 = lapply(z, ffast)
r2 = lapply(z, fslow)
