local layout = require("display.layout")

local errors = require("lib.errors")

local sidebar = {}

function sidebar.render(monitor)
    local monitor_width, monitor_height = layout.get_monitor_size(monitor)
    if monitor_width < 18 or monitor_height < 12 then
        return nil, errors.INVALID_MONITOR
    end

    local sidebar_width = monitor_width / 10

    print(sidebar_width)

    monitor.setCursorPos(1, 1)
    monitor.setBackgroundColour(colours.grey)
    for _ = 1, monitor_height do
        monitor.write(string.rep(" ", sidebar_width) .. "\n")
    end

    monitor.setBackgroundColour(colours.black)
end

return sidebar
