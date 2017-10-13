#!/usr/bin/env Rscript
# Wed Mar  8 16:09:51 PST 2017
#
# pass in an R script to build and visualize a code dependency graph

library(igraph)
library(CodeDepends)

source("depend_graph.R")

script_name = commandArgs(trailingOnly=TRUE)

s = readScript(script_name)
f = tempfile()
outfile = gsub("\\.R", "\\.pdf", script_name)

g = depend_graph(s, add_source = TRUE)
write_graph(g, f, format = "dot")

system2("dot", c("-Tpdf",  f, "-o", outfile))

unlink(f)

message("Processed ", script_name)
