# Wed Sep 18 09:15:03 PDT 2019
#
# Why did the pems example fail?
# Can I make a minimal reproducible example?

# Here I'm using R 3.6.


# This is fast because of ALTREP in R 3.6
d1 = data.frame(a = seq(.Machine$integer.max))
d2 = data.frame(a = seq(10))

system.time(
    d12 <- rbind(d1, d2)
)

# Same error, good:

# Error in seq.int(from = nrow + 1L, length.out = ni) :
#   'from' must be a finite number
# In addition: Warning message:
# In nrow + 1L : NAs produced by integer overflow


# Lets see if this fixes it.
system.time(
    d12 <- rbind(d1, d2, deparse.level = 0, make.row.names = FALSE)
)
# Nope, same error.

# Wow, integers overflow to NA?
# That's inconvenient.

a = seq(.Machine$integer.max + 10)
b = as.character(a)

d3 = data.frame(a = a, row.names = b)
# Error in if (nrows[i] > 0L && (nr%%nrows[i] == 0L)) { :
#   missing value where TRUE/FALSE needed
# In addition: Warning message:
# In attributes(.Data) <- c(attributes(.Data), attrib) :
#   NAs introduced by coercion to integer range

# What seems to be going on is that even though R allows long vectors, data frame cannot have more than 2^31 (about 2 billion) rows because it attempts to use integers for the names, and the integers overflow.
# Thus the failure.
# Which means the serial code won't run as it stands, and so must be rewritten.
# It could use a higher performance third party library, or we could be clever and chunk the data frames.
# If we're going to do the latter, then we may as well make it parallel also.
