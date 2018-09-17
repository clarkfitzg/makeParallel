# Some random data analysis script
library(helperfuncs)
cmp_plots <- function(cmp1, cmp2, ...){
    pdf(plotname(cmp1))
    plot(cmp1, cmp2, ...)
    dev.off()
}
results <- get_results("previous")
results$time_processed <- Sys.time()
params <- get_param()
params["flag"] <- TRUE
for(p in params){
    check_conformance(p)
}
simulated <- simulate(params)
cmp1 <- compare1(results, simulated)
normalized_results <- normalize(results)
simulated[, "y"] <- addy(simulated)
cmp2 <- compare2(normalized_results, simulated)
verify_compare(cmp1, cmp2)
cmp_plots(cmp1, cmp2, col = "blue")
save_sim(simulated)
save_cmp(cmp2)
