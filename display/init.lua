local Sidebar = require("display.elements.sidebar")
local Page = require("display.elements.page")
local Container = require("display.elements.container")
local Background = require("display.elements.background")
local Ruler = require("display.elements.ruler")

local MonitorHelper = require("display.monitor_helper")
local TaskRunner = require("display.task_runner")

local errors = require("lib.errors")
local printer = require("lib.printer")

local Display = {
    turtles = {},
    debug = false
}
Display.__index = Display

local function traceback(err)
    return debug.traceback(tostring(err), 2)
end

local function log_error(tag, message)
    fs.makeDir("logs")

    local timestamp = textutils.formatTime(os.epoch("utc") / 1000, true)
    local filename = ("logs/error_%s_%d.log"):format(
        timestamp:gsub("[: ]", "-"),
        math.random(1000, 9999)
    )

    local file = fs.open(filename, "w")
    if file then
        file.writeLine(("[%s] %s"):format(tag, message))
        file.close()
    end
end

local function guard(tag, fn)
    local ok, err = xpcall(fn, traceback)
    if not ok then
        printer.print_error(("[%s] %s"):format(tag, err))
        log_error(tag, err)
        return false, err
    end
    return true
end

function Display:new(monitor)
    if not monitor then return nil, errors.NIL_PARAM end

    local m = MonitorHelper:new(monitor)
    Display.selected_page = Page.pages.quarries

    local task_runner = TaskRunner:new()

    local result
    guard("Boot", function()
        local monitor_width, monitor_height = m:get_monitor_size()
        local background = Background:new(m, { width = monitor_width, height = monitor_height })
        background:solid(colours.lightGrey)
        background:render(1, 1)

        m:set_fg_colour(colours.black)
        m:scroll_text(1, monitor_height, "Turtle manager is booting...", 2)

        result = setmetatable({ m = m, task_runner = task_runner, turtles = {} }, Display)
        result:on_resize()
    end)

    return result
end

function Display:on_resize()
    local monitor_width, monitor_height = self.m:get_monitor_size()
    self.m:reset_text_scale()

    local size = { width = monitor_width, height = monitor_height }
    local monitor_container = Container:new(self.m, Container.layouts.manual, size)

    local background = Background:fill_container(monitor_container, false)
    background:solid(colours.lightGrey)
    monitor_container:add_element(background)

    local sidebar_size = {
        width = 15,
        height = monitor_height
    }

    local page_switcher = function(page_id, selected_id)
        self.selected_page = page_id
        self.selected_id = selected_id
    end

    local sidebar = Sidebar:new(self.m, sidebar_size, page_switcher)
    monitor_container:add_element(sidebar)

    local page_size = {
        width = monitor_width - sidebar_size.width,
        height = monitor_height
    }

    local page = Page:new(self.m, page_size, page_switcher, self.task_runner)
    monitor_container:add_element(page, {
        x_offset = sidebar.size.width
    })

    self.monitor_container = monitor_container
end

function Display:render()
    if not self.m then
        return nil, errors.NO_MONITOR_ATTACHED
    end

    local data = {
        turtles = self.turtles,
        selected_id = self.selected_id,
        selected_page = self.selected_page,
    }

    self.m:clear()

    guard("Render", function()
        self.monitor_container:render(1, 1, data)
    end)

    if self.debug then
        guard("Ruler", function()
            local ruler = Ruler:new(self.m)
            ruler:render()
        end)
    end
end

function Display:add_or_update_turtle(id, turtle)
    self.turtles[id] = turtle
end

function Display:loop(refresh_rate)
    refresh_rate = refresh_rate or 1
    local timer_id = os.startTimer(refresh_rate)

    while true do
        local event, p1, p2, p3 = os.pullEventRaw()
        if event == "timer" and p1 == timer_id then
            self:render()
            timer_id = os.startTimer(refresh_rate)
        elseif event == "monitor_touch" then
            guard("Click", function()
                self.monitor_container:handle_click(p2, p3)
            end)
        elseif event == "monitor_resize" then
            self:on_resize()
        elseif event == "terminate" then
            return
        end
    end
end

return Display
