plot_one_eval_block = function(row){with(row, {
    rect(start_time, processor - blockwidth
         , end_time, processor + blockwidth
        , border = border, lwd = lwd, density = density, col = eval_color
        )
    text(x = (start_time + end_time) / 2, y = processor, labels = node)
})}


plot_one_transfer = function(row, blockwidth){with(row, {
    rect(start_time_send, proc_send - blockwidth
         , end_time_send, proc_send + blockwidth
        , border = border, lwd = lwd, density = density, col = send_color
        )
    rect(start_time_receive, proc_receive - blockwidth
        , end_time_receive, proc_receive + blockwidth
        , border = border, lwd = lwd, density = density, col = receive_color
        )
    delta = 1.1 * blockwidth
    adj = c(0, 0)
    # Arrows can go up or down
    if(proc_receive > proc_send){
        delta = -delta
        adj = c(0, 1)
    }
    xa_start = (end_time_send - start_time_send) / 2
    ya_end = proc_send - delta
    arrows(xa_start, ya_end
        , (end_time_receive - start_time_receive) / 2, proc_receive + delta
        )
    text(xa_start, ya_end, varname, adj = adj)
})}


#' Gantt chart of a schedule
#'
#' @export
plot.schedule = function(x, blockwidth = 0.25, main = "schedule plot"
    , eval_color = "gray", send_color = "orchid", receive_color = "slateblue"
    , density = NA, border = "black", lwd = 2
    , ...)
{
    run = x$eval

    xlim = c(min(run$start_time), max(run$end_time))
    ylim = c(min(run$processor) - 1, max(run$processor) + 1)
    plot(xlim, ylim, type = "n", xlab = "time", ylab = "processor", main = main, ...)

    by(run, seq(nrow(run)), plot_one_eval_block)

    by(x$transfer, seq(nrow(x$transfer)), plot_one_transfer, blockwidth = blockwidth)

    NULL
}
