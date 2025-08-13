local Sidebar = require("display.elements.sidebar")
local Container = require("display.elements.container")
local Background = require("display.elements.background")
local Ruler = require("display.elements.ruler")

local Page = require("display.pages.page")

local MonitorHelper = require("display.monitor_helper")
local TaskRunner = require("display.task_runner")
local Notifier = require("display.notifier")

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
        printer.print_error(("[%s] An error occured, see logs/"):format(tag))
        log_error(tag, err)
        return false, err
    end
    return true
end

function Display:new(monitor)
    if not monitor then return nil, errors.NIL_PARAM end

    local m = MonitorHelper:new(monitor)

    local notifier = Notifier:new(m)
    local task_runner = TaskRunner:new(notifier)

    local result
    guard("Boot", function()
        local monitor_width, monitor_height = m:get_monitor_size()
        local background = Background:new(m, { width = monitor_width, height = monitor_height })
        background:solid(colours.lightGrey)
        background:render(1, 1)

        m:set_fg_colour(colours.black)
        m:scroll_text(1, monitor_height, "Turtle manager is booting...", 2)

        result = setmetatable({
            m = m,
            task_runner = task_runner,
            notifier = notifier,
            turtles = {},
            selected_page = Page.pages.quarries
        }, Display)
        result:on_resize()
    end)

    return result
end

function Display:on_resize()
    self.m:clear()

    local monitor_width, monitor_height = self.m:get_monitor_size()
    self.m:reset_text_scale()

    local size = { width = monitor_width, height = monitor_height }
    local monitor_container = Container:new(self.m, Container.layouts.manual, size)

    local background = Background:fill_container(monitor_container, false)
    background:solid(colours.lightGrey)
    monitor_container:add_background(background)

    local sidebar_size = {
        width = 15,
        height = monitor_height
    }

    local page_switcher = function(page_id, selected_id)
        self.selected_page = page_id
        self.selected_id = selected_id
    end

    local sidebar = Sidebar:new(self.m, sidebar_size, page_switcher)
    monitor_container:add_element(2, sidebar)

    local page_size = {
        width = monitor_width - sidebar_size.width,
        height = monitor_height
    }

    local page = Page:new(self.m, page_size, page_switcher, self.task_runner)
    monitor_container:add_element(3, page, {
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

        if self.notifier:has_notifications() then
            self.notifier:render()
        end
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
    os.queueEvent("ui:render")
end

function Display:delete_turtle(id)
    self.turtles[id] = nil
    os.queueEvent("ui:render")
end

function Display:loop()
    local idle_fps = 2
    local active_fps = 10

    local should_render = true

    local function next_delay()
        return 1 / (self.notifier:is_animating() and active_fps or idle_fps)
    end

    local delay = next_delay()
    local timer = os.startTimer(delay)

    while true do
        local event, p1, p2, p3 = os.pullEventRaw()

        if event == "timer" and p1 == timer then
            self.notifier:update(os.clock())
            if self.notifier:has_notifications() then
                should_render = true
            end

            if should_render then
                self:render()
                should_render = false
            end

            delay = next_delay()
            timer = os.startTimer(delay)
        elseif event == "monitor_touch" then
            guard("Click", function()
                self.monitor_container:handle_click(p2, p3)
            end)
            should_render = true
        elseif event == "monitor_resize" then
            self:on_resize()
            should_render = true
        elseif event == "terminate" then
            return
        elseif event == "ui:render" then
            should_render = true
        end
    end
end

return Display
