plot_one_eval_block = function(row, blockwidth, rect_aes)
{with(row, {
    rect_args = list(xleft = start_time
        , ybottom = processor - blockwidth
        , xright = end_time
        , ytop = processor + blockwidth
        )
    do.call(rect, c(rect_args, rect_aes))

    text(x = (start_time + end_time) / 2, y = processor, labels = node)
})}


plot_one_transfer = function(row, blockwidth, rect_aes, send_color, receive_color
                             , text_adj = 1.2)
{with(row, {
    send_rect_args = list(xleft = start_time_send
        , ybottom = proc_send - blockwidth
        , xright = end_time_send
        , ytop = proc_send + blockwidth
        )
    rect_aes[["col"]] = rect_aes[["border"]] = send_color
    do.call(rect, c(send_rect_args, rect_aes))

    receive_rect_args = list(xleft = start_time_receive
        , ybottom = proc_receive - blockwidth
        , xright = end_time_receive
        , ytop = proc_receive + blockwidth
        )
    rect_aes[["col"]] = rect_aes[["border"]] = receive_color
    do.call(rect, c(receive_rect_args, rect_aes))

    delta = 1.1 * blockwidth
    adj = c(text_adj, text_adj)
    # Arrows can go up or down
    if(proc_receive > proc_send){
        delta = -delta
        adj = c(text_adj, 0)
    }
    x_send = mean(c(end_time_send, start_time_send))
    y_send = proc_send - delta
    arrows(x0 = x_send, y0 = y_send
        , x1 = mean(c(end_time_receive, start_time_receive))
        , y1 = proc_receive + delta
        )
    text(x_send, y_send, varname, adj = adj)
})}


#' Gantt chart of a schedule
#'
#' @export
#' @param rect_aes list of additional arguments for \code{rect}.
#' @param ... additional arguments to \code{plot}
setMethod(plot, "TaskSchedule", function(x, blockwidth = 0.25, main = "schedule plot"
    , eval_color = "gray", send_color = "orchid", receive_color = "slateblue"
    , rect_aes = list(density = NA, border = "black", lwd = 2)
    , ...)
{
    run = x@evaluation

    xlim = c(min(run$start_time), max(run$end_time))
    ylim = c(min(run$processor) - 1, max(run$processor) + 1)
    plot(xlim, ylim, type = "n", xlab = "time", ylab = "processor", main = main, ...)

    rect_aes[["col"]] = eval_color
    by(run, seq(nrow(run)), plot_one_eval_block
        , blockwidth = blockwidth
        , rect_aes = rect_aes
        )

    by0(x$transfer, seq(nrow(x$transfer)), plot_one_transfer
        , blockwidth = blockwidth
        , rect_aes = rect_aes
        , send_color = send_color
        , receive_color = receive_color
        )

    NULL
})
