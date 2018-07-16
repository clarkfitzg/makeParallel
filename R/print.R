minimalPrint = function(object)
{
    msg = sprintf('An object of class "%s"
Slots: ', class(object))
    slots = paste(slotNames(object), collapse = ", ")
    cat(paste0(msg, slots, "\n\n"))
}


setMethod("show", "Schedule", minimalPrint)

setMethod("show", "GeneratedCode", minimalPrint)
