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

    local m = MonitorHelper:new(monitor)
    local _, monitor_height = m:get_monitor_size()

    local sidebar = Sidebar:new(m, page_switcher)

    -- Boot screen
    m:render_background()
    local text = "Turtle manager is booting..."
    m:set_fg_colour(colours.black)
    m:scroll_text(1, monitor_height, text, 2)

    return setmetatable({
        m = m,
        sidebar = sidebar,
        page = Page:new(m, page_switcher),
    }, self)
end

function Display:render()
    if not self.m then
        return nil, errors.NO_MONITOR_ATTACHED
    end

    self.m:clear()

    local ok, err
    ok, err = pcall(function()
        self.m:render_background()
    end)

    if not ok then
        printer.print_error("[Layout] " .. tostring(err))
    end

    ok, err = pcall(function()
        self.sidebar:render(self.selected_page)
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
