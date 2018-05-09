#' Gantt chart of a schedule
#' @export
plot.schedule = function(x, main = "schedule plot", ...)
{

#    library(ggplot2)
#
#    # https://stackoverflow.com/questions/3550341/gantt-charts-with-r
#    # No, doesn't show break points
#    xm = reshape2::melt(x, measure.vars = c("start_time", "end_time"))
#    xm$processor = as.factor(xm$processor)
#    ggplot(xm, aes(value, processor, color = "type")) +
#        geom_line(size = 6)
#

#    info = list(labels = x$processor
#                , starts = x$start_time
#                , ends = x$end_time
#                )
#
#    vg = sort(unique(c(info$starts, info$ends)))
#
#    plotrix::gantt.chart(info, vgridpos = vg, vgridlab = as.character(vg)
#            , hgrid = TRUE, taskcolors = "lightgray", border.col = "black"
#            , xlab = "time"
#            )
#
#    add_label = function(row)

    xlim = c(0, max(x$end_time))
    ylim = c(0, max(x$processor) + 1)

    plot(xlim, ylim, type = "n", xlab = "time", ylab = "processor", ...)

    eval_color = "gray"
    send_color = "orchid"
    receive_color = "slateblue"
    width = 0.25

    add_one = function(row){
        with(row, {
        type = as.character(type)
        col = switch(type, eval = eval_color, send = send_color, receive = receive_color)
        rect(start_time, processor - width, end_time, processor + width
            , border = "black", lwd = 2, density = NA, col = col
            )
        lab = if(is.na(varname)) node else varname
        xcenter = (start_time + end_time) / 2
        text(xcenter, y = processor, labels = lab)
        if(type == "send"){
            # Draw an arrow to the corresponding receive
            receive = x[x$type == "receive" & x$from == from & x$varname == varname, ]
            delta = 1.1 * width  # So it doesn't actually touch
            if(processor < receive$processor) delta = -delta
            arrows(xcenter, processor - delta
                   , with(receive, (start_time + end_time) / 2), receive$processor + delta)
        }
        })
    }

    by(x, seq(nrow(x)), add_one)
}
