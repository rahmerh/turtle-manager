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
    sidebar.render(display.monitor)
end

return display
