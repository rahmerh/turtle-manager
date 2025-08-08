local Sidebar = require("display.elements.sidebar")
local Page = require("display.elements.page")

local MonitorHelper = require("display.monitor_helper")

local errors = require("lib.errors")
local printer = require("lib.printer")

local Display = {
    turtles = {}
}
Display.__index = Display

function Display:new(monitor)
    if not monitor then
        return nil, errors.NIL_PARAM
    end

    Display.selected_page = Page.pages.quarries
    local page_switcher = function(page_id, selected_id)
        Display.selected_page = page_id
        Display.selected_id = selected_id
    end

    local monitor_helper = MonitorHelper:new(monitor)
    local _, monitor_height = monitor_helper:get_monitor_size()

    local sidebar = Sidebar:new(monitor_helper, page_switcher)

    -- Boot screen
    local text = "Turtle manager is booting..."
    monitor.setTextColour(colours.black)
    monitor_helper:scroll_text(1, monitor_height, text, 2)

    return setmetatable({
        monitor_helper = monitor_helper,
        sidebar = sidebar,
        page = Page:new(monitor_helper, page_switcher),
    }, self)
end

function Display:render()
    if not self.monitor_helper then
        return nil, errors.NO_MONITOR_ATTACHED
    end

    self.monitor_helper:clear()

    local ok, err
    ok, err = pcall(function()
        self.monitor_helper:render_background()
    end)

    if not ok then
        printer.print_error("[Layout] " .. tostring(err))
    end

    ok, err = pcall(function()
        self.sidebar:render()
    end)

    if not ok then
        printer.print_error("[Sidebar] " .. tostring(err))
    end

    ok, err = pcall(function()
        self.page:render(self.selected_page, {
            turtles = self.turtles,
            selected_id = self.selected_id
        })
    end)

    if not ok then
        printer.print_error("[Page] " .. tostring(err))
    end
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

            local ok, err = pcall(function()
                local click_in_sidebar = self.sidebar:handle_click(x, y)
                if not click_in_sidebar then
                    local click_ok, click_err = pcall(function()
                        self.page:handle_click(self.selected_page, x, y)
                    end)

                    if not click_ok then
                        printer.print_error("[Page Click] " .. tostring(click_err))
                    end
                end
            end)

            if not ok then
                printer.print_error("[Sidebar Click] " .. tostring(err))
            end
        elseif event[1] == "terminate" then
            return
        end
    end
end

return Display
