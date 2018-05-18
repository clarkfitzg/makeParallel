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

    by(run, seq(nrow(run)), function(row){with(row,
        rect(start_time, processor - blockwidth
             , end_time, processor + blockwidth
            , border = border, lwd = lwd, density = density, col = eval_color
            )
        text(x = (start_time + end_time) / 2, y = processor, labels = node)
    )})

    delta = 1.1 * width  # So arrows doesn't actually touch

    by(x$transfer, seq(nrow(x$transfer)), function(row){with(row,
        rect(start_time_send, proc_send - blockwidth
             , end_time_send, proc_send + blockwidth
            , border = border, lwd = lwd, density = density, col = send_color
            )
        rect(start_time_receive, proc_receive - blockwidth
             , end_time_receive, proc_receive + blockwidth
            , border = border, lwd = lwd, density = density, col = receive_color
            )
    )})


    add_one = function(row){
        with(row, {
        type = as.character(type)
        col = switch(type, eval = eval_color, send = send_color, receive = receive_color)
        if(type == "send"){
            # Draw an arrow to the corresponding receive
            receive = x[x$type == "receive" & x$from == from & x$varname == varname, ]
            if(processor < receive$processor) delta = -delta
            arrows(xcenter, processor - delta
                   , with(receive, (start_time + end_time) / 2), receive$processor + delta)
        }
        })
    }

    by(x, seq(nrow(x)), add_one)
}
