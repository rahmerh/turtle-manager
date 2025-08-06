local Sidebar = require("display.elements.sidebar")
local Page = require("display.elements.page")

local Layout = require("display.layout")

local errors = require("lib.errors")

local Display = {
    turtles = {}
}
Display.__index = Display

local function print_boot_screen(layout)
    local _, height = layout:get_monitor_size()

    local text = "TUMA is booting..."
    layout:scroll_text(1, height, text, 1)
end

function Display:new(monitor)
    if not monitor then
        return nil, errors.NIL_PARAM
    end
    local layout = Layout:new(monitor)
    local sidebar = Sidebar:new(monitor, function(page_id) Display.selected_page = page_id end, layout)
    layout:set_sidebar_width(sidebar.width)

    Display.selected_page = "quarries"

    layout:render_background()
    print_boot_screen(layout)

    return setmetatable({
        monitor = monitor,
        layout = layout,
        sidebar = sidebar,
        page = Page:new(monitor, layout),
    }, self)
end

function Display:render()
    if not self.monitor then
        return nil, errors.NO_MONITOR_ATTACHED
    end

    self.monitor.clear()

    self.layout:render_background()
    self.sidebar:render()
    self.page:render(self.selected_page, self.turtles)
end

function Display:add_or_update_turtle(id, turtle)
    self.turtles[id] = turtle
end

function Display:loop(refresh_rate)
    refresh_rate = refresh_rate or 1
    local last_render = os.clock()

    while true do
        if os.clock() - last_render >= refresh_rate then
            self:render()
            last_render = os.clock()
        end

        local event = { os.pullEventRaw() }

        if event[1] == "monitor_touch" then
            local _, _, x, y = table.unpack(event)
            self.sidebar:handle_click(x, y)
        elseif event[1] == "terminate" then
            self.monitor.clear()
            return
        end
    end
end

return Display
