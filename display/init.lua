local sidebar = require("display.sidebar")

local errors = require("lib.errors")

local display = {}

function display.set_monitor(monitor)
    if not monitor then
        return nil, errors.NIL_PARAM
    end

    display.monitor = monitor
end

function display.render()
    if not display.monitor then
        return nil, errors.NO_MONITOR_ATTACHED
    end

    display.monitor.clear()
    sidebar.render(display.monitor)
end

function display.loop(refresh_rate)
    refresh_rate = refresh_rate or 1

    while true do
        display.render()
        sleep(refresh_rate)
    end
end

return display
