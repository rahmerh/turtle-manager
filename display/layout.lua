local layout = {}

function layout.get_monitor_size(monitor)
    local width, height = monitor.getSize()
    return width, height
end

return layout
