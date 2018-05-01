# Tue May  1 12:02:56 PDT 2018
#
# Basic test of task graph

library(autoparallel)

script = parse(text = "
    datadir = '~/data'                      # A
    x = read.csv(paste0(datadir, 'x.csv'))  # B
    y = read.csv(paste0(datadir, 'y.csv'))  # C
    xy = merge(x, y)                        # D
")

tg = expr_graph(script)


